variable "juju_username" {
  type =string
  sensitive = true
}
variable "juju_password" {
  type = string
  sensitive = true
}

variable "rsa" {
  type = string
  description = "RSA public key"
}

variable "ed25519" {
  type = string
  description = "ED25519 public key"
}