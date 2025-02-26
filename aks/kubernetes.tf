resource "kubernetes_deployment" "proper_model" {
  depends_on = [terraform_data.get_kube_config]
  metadata {
    name = "proper-model"
    labels = {
      app = "proper-model"
    }
  }
  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "proper-model"
      }
    }

    template {
      metadata {
        labels = {
          app = "proper-model"
        }
      }

      spec {
        container {
          image = "axoy/sentiment-analysis-proper-model:cors-middleware"
          name  = "proper-model"

          resources {
            limits = {
              cpu    = "500m"
              memory = "1Gi"
            }
            requests = {
              cpu    = "200m"
              memory = "512Mi"
            }
          }

          port {
            container_port = 8000
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8000

              /*               http_header {
                name  = "X-Custom-Header"
                value = "status"
              } */
            }
            initial_delay_seconds = 3
            period_seconds        = 5
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "fallback_model" {
  depends_on = [terraform_data.get_kube_config]
  metadata {
    name = "fallback-model"
    labels = {
      app = "fallback-model"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "fallback-model"
      }
    }

    template {
      metadata {
        labels = {
          app = "fallback-model"
        }
      }

      spec {
        container {
          image = "axoy/sentiment-analysis-fallback_model:latest"
          name  = "fallback-model"

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }

          port {
            container_port = 8000
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "web-ui" {
  depends_on = [terraform_data.get_kube_config]
  metadata {
    name = "web-ui"
    labels = {
      app = "web-ui"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "web-ui"
      }
    }

    template {
      metadata {
        labels = {
          app = "web-ui"
        }
      }

      spec {
        container {
          image = "axoy/sentiment-web-ui:latest"
          image_pull_policy = "Always"
          name  = "web-ui"

          resources {
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "proper-model" {
  depends_on = [terraform_data.get_kube_config]
  metadata {
    name = "proper-model"
  }
  spec {
    selector = {
      app = kubernetes_deployment.proper_model.metadata.0.labels.app
    }
    port {
      protocol    = "TCP"
      port        = 8000
      target_port = 8000
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_service" "fallback-model" {
  depends_on = [terraform_data.get_kube_config]
  metadata {
    name = "fallback-model"
  }
  spec {
    selector = {
      app = kubernetes_deployment.fallback_model.metadata.0.labels.app
    }
    port {
      protocol    = "TCP"
      port        = 8000
      target_port = 8000
    }

    type = "ClusterIP"
  }
}


resource "kubernetes_service" "sentiment-lb" {
  depends_on = [terraform_data.get_kube_config]
  metadata {
    name = "sentiment-lb"
  }
  spec {
    selector = {
      app = kubernetes_deployment.proper_model.metadata.0.labels.app
    }
    port {
      protocol    = "TCP"
      port        = 80
      target_port = 8000
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_service" "web-ui" {
  depends_on = [terraform_data.get_kube_config]
  metadata {
    name = "web-ui"
  }
  spec {
    selector = {
      app = kubernetes_deployment.web-ui.metadata.0.labels.app
    }
    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_service_account" "failover" {
  depends_on = [terraform_data.get_kube_config]
  metadata {
    name = "failover-sa"
  }
}

resource "kubernetes_role" "failover" {
  depends_on = [terraform_data.get_kube_config]
  metadata {
    name = "failover-role"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services"]
    verbs      = ["get", "list", "patch"]
  }
}

resource "kubernetes_role_binding" "failover" {
  depends_on = [terraform_data.get_kube_config]
  metadata {
    name      = "failover-rolebinding"
    namespace = "default"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "failover-role"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.failover.metadata.0.name
    namespace = "default"
  }
}


locals {
  command_raw = <<-EOT
    CURRENT_TARGET=""
    while true; do
    if [ $(kubectl get pods -l app=proper-model 2> /dev/null | grep Running | wc -l) -ge 1 ] && \
        [ $(kubectl get pods -l app=proper-model | grep Running | awk '{print $2}' | grep 0 | wc -l) -eq 0 ]; then
        NEW_TARGET="proper-model"
    else
        NEW_TARGET="fallback-model"
    fi
    
    CURRENT_SELECTOR=$(kubectl get service sentiment-lb -o=jsonpath='{.spec.selector.app}')
    
    if [ "$CURRENT_SELECTOR" != "$NEW_TARGET" ]; then
        echo "$(date '+%d/%m/%Y %H:%M:%S') — Traffic switching: $CURRENT_SELECTOR -> $NEW_TARGET"
        kubectl patch service sentiment-lb -p "{\"spec\":{\"selector\":{\"app\":\"$NEW_TARGET\"}}}"
    fi
    
    sleep 10
    done
    EOT
  command     = chomp(replace(local.command_raw, "\r", ""))
}


resource "kubernetes_job" "failover" {
  depends_on = [terraform_data.get_kube_config]
  metadata {
    name = "failover-job"
  }
  spec {
    template {
      metadata {}
      spec {
        service_account_name = kubernetes_service_account.failover.metadata.0.name
        restart_policy       = "Never"
        container {
          name  = "failover"
          image = "bitnami/kubectl"
          command = [
            "/bin/sh",
            "-c",
            local.command
          ]
        }
      }
    }
  }
  wait_for_completion = false
}


resource "terraform_data" "nginx-ingress" {
  depends_on = [terraform_data.get_kube_config]
  provisioner "local-exec" {
    command = "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml"
  }
}

resource "kubernetes_ingress" "web-ui-ingress" {
  depends_on             = [terraform_data.nginx-ingress]
  wait_for_load_balancer = true
  metadata {
    name = "web-ui-ingress"
    annotations = {
      "nginx.ingress.kubernetes.io/cors-allow-origin" : "*",
      "nginx.ingress.kubernetes.io/cors-allow-methods" : "GET, POST, OPTIONS",
      "nginx.ingress.kubernetes.io/cors-allow-headers" : "Content-Type"
    }
  }
  spec {
    rule {
      http {
        path {
          path = "/"
          backend {
            service_name = kubernetes_service.web-ui.metadata.0.name
            service_port = 80
          }
        }

        path {
          path = "/predict"
          backend {
            service_name = kubernetes_service.sentiment-lb.metadata.0.name
            service_port = 80
          }
        }
      }
    }
  }
}