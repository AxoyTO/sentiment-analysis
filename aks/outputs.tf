/* output "aks_lb_ip" {
  value = azurerm_public_ip.aks_lb_ip.ip_address
} */

output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "value of the resource group name"
}

output "kubernetes_cluster_name" {
  value       = azurerm_kubernetes_cluster.aks.name
  description = "value of the kubernetes cluster name"
}

output "client_certificate" {
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate
  description = "value of the client certificate"
  sensitive   = true
}

output "client_key" {
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].client_key
  description = "value of the client key"
  sensitive   = true
}

output "cluster_ca_certificate" {
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate
  description = "value of the cluster ca certificate"
  sensitive   = true
}

output "cluster_password" {
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].password
  description = "value of the cluster password"
  sensitive   = true
}

output "cluster_username" {
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].username
  description = "value of the cluster username"
  sensitive   = true
}

output "host" {
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].host
  description = "value of the host"
  sensitive   = true
}

output "kube_config" {
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  description = "value of the kube config"
  sensitive   = true
}

output "sentiment-lb-ip" {
  value       = kubernetes_service.sentiment-lb.status.0.load_balancer.0.ingress.0.ip
  description = "value of the sentiment-lb service IP"
}
