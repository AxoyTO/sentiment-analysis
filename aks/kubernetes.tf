resource "kubernetes_deployment" "proper_model" {
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
          image = "axoy/sentiment-analysis-proper_model:latest"
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


resource "kubernetes_service" "proper-model" {
  metadata {
    name = "proper-model"
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

    type                    = "LoadBalancer"
    external_traffic_policy = "Cluster"
  }
}

resource "kubernetes_service" "fallback-model" {
  metadata {
    name = "fallback-model"
  }
  spec {
    selector = {
      app = kubernetes_deployment.fallback_model.metadata.0.labels.app
    }
    port {
      protocol    = "TCP"
      port        = 80
      target_port = 8000
    }

    type = "ClusterIP"
  }
}


resource "kubernetes_service" "sentiment-lb" {
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

    type                    = "LoadBalancer"
    external_traffic_policy = "Cluster"
  }
}

resource "kubernetes_service_account" "failover" {
  metadata {
    name = "failover-sa"
  }
}

resource "kubernetes_role" "failover" {
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