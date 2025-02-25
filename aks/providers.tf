terraform {
  required_version = ">=1.0"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~>1.5"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.9.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~>2.35.0"
    }

  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

provider "kubernetes" {
  config_path = "~/.kube/config"
  /*   client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
  host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
  password               = azurerm_kubernetes_cluster.aks.kube_config.0.password
  username               = azurerm_kubernetes_cluster.aks.kube_config.0.username */
}
