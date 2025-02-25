variable "subscription_id" {
  description = "The Azure subscription ID"
}

variable "ssh_public_key" {
  description = "The SSH public key"
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC/t3J2DHue9lf3Y6BttZ3fulrFHiWuJAL8xFJFNLy+kTi9X8gYNLFwzBEQ0bkCD6OovTw9ZtOHqPVJ/0x26kcSSwyFNH0IKuxv/stcFGKlSN3T6VSc7N57Ajz8O9kY48sO8J8gAkFTl1u4ZhgNAJNPaIVcXUk+i3xakAyXJe95yBtaqewKfWyzEBqEZfY7WsqHyZ0zmm+E5Lhjdv7r0FRxOQkRHa2UnaFOCn3LIveYPQ4CcoD1Nssxw7OfLmoZCgBFuON2MvGz2Lgv6Cc/z6AC5wR/+Yofx+wz/Gwzx0Mzs+1fHVn0rTdh2wqXiIn4756/w/5HIfl5DJxQCnV9rsyFh+nobjZN8cxBTCtkR4S8cmW4yaXmlmFDS8xqbAm8bpbemcAIBWVCKG5vHkzDe8we/1siA4Yl3/JavzFkx6v+5hqI85G4DXyUqJo39CRV4Ac/3wZe7iaFCCCxcd9B1B4sCqH/LBig+DHB+ze+s7xJ6o9XZrXbdQbbdFjUIoTNttM= tevfik.aksoy@canonical.com"
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
