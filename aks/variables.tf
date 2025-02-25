variable "subscription_id" {
  description = "The Azure subscription ID"
}

variable "k8s_cluster_name" {
  type        = string
  description = "The name of the AKS cluster"
}

variable "resource_group_location" {
  type        = string
  description = "The location of the resource group"
}

variable "node_count" {
  type        = number
  description = "The number of nodes in the AKS cluster"
  default     = 1
}

variable "username" {
  type        = string
  description = "The admin username for the new cluster."
  default     = "aksadmin"
}
