terraform {
  required_providers {
    juju = {
      version = "0.16.0"
      source  = "juju/juju"
    }
  }
}

provider "juju" {
  username = var.juju_username
  password = var.juju_password
}

resource "juju_model" "microk8s-model" {
  name = "microk8s-model"

  cloud {
    name   = "azure"
    region = "germanywestcentral"
  }

  config = {
    logging-config              = "<root>=DEBUG"
    update-status-hook-interval = "1m"
  }
}

resource "juju_ssh_key" "rsa" {
  model   = juju_model.microk8s-model.name
  payload = var.rsa
  depends_on = [
    juju_model.microk8s-model
  ]
}

resource "juju_ssh_key" "ed25519" {
  model   = juju_model.microk8s-model.name
  payload = var.ed25519
  depends_on = [
    juju_model.microk8s-model
  ]
}

resource "juju_application" "microk8s" {
  name = "microk8s"

  model = juju_model.microk8s-model.name

  charm {
    name    = "microk8s"
    channel = "1.28/stable"
    base    = "ubuntu@22.04"
  }

  units = 1
}

resource "juju_kubernetes_cloud" "microk8s-cloud" {
  name  = "microk8s-cloud"
  kubernetes_config = file("~/.kube/config")
}

#resource ""