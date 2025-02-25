resource "azurerm_resource_group" "rg" {
  name     = "aks-resource-group"
  location = var.resource_group_location

  tags = {
    environment = "MDS"
  }
}

resource "azurerm_kubernetes_cluster" "aks" {
  location            = azurerm_resource_group.rg.location
  name                = var.k8s_cluster_name
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "mdsdevopsdns"

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = "Standard_D2s_v3" # 2 vCPU, 8GB RAM per node
  }
  linux_profile {
    admin_username = var.username

    ssh_key {
      key_data = file("~/.ssh/id_rsa.pub")
    }
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "MDS"
  }
}

/* resource "azurerm_public_ip" "aks_lb_ip" {
  name                = "aks-lb-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"

  tags = {
    environment = "MDS"
  }
} */

/* resource "azurerm_network_security_group" "aks_nsg" {
  name                = "aks-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
} */

/* resource "azurerm_network_security_rule" "allow_http" {
  name                        = "Allow-HTTP"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.aks_nsg.name
}

resource "azurerm_network_security_rule" "allow_https" {
  name                        = "Allow-HTTPS"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.aks_nsg.name
}

resource "azurerm_network_security_rule" "allow_k8s_api" {
  name                        = "Allow-K8s-API"
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "6443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.aks_nsg.name
} */

resource "terraform_data" "get_kube_config" {
  provisioner "local-exec" {
    command = "az aks get-credentials --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_kubernetes_cluster.aks.name} --overwrite-existing"
  }
  depends_on = [azurerm_kubernetes_cluster.aks]
}

resource "terraform_data" "juju_add_k8s" {

  provisioner "local-exec" {
    command    = "juju add-k8s ${var.k8s_cluster_name} --client"
    on_failure = continue
  }
  depends_on = [terraform_data.get_kube_config]

  provisioner "local-exec" {
    when       = destroy
    command    = "rm ~/.kube/config"
    on_failure = continue
  }
}
