output "username_value" {
  description = "value of the username"
  value       = var.juju_username
  sensitive   = true
}
output "password_value" {
  description = "value of the password"
  value       = var.juju_password
  sensitive   = true
}

output "charms" {
  description = "List of charms"
  value       = juju_application.microk8s.charm
}