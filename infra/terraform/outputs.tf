output "droplet_ip" {
  description = "Public IP address of the PostgreSQL droplet"
  value       = digitalocean_droplet.pg.ipv4_address
}

output "droplet_id" {
  description = "ID of the droplet"
  value       = digitalocean_droplet.pg.id
}

output "firewall_id" {
  description = "ID of the firewall"
  value       = digitalocean_firewall.pg_fw.id
}

output "connection_string" {
  description = "PgBouncer connection endpoint"
  value       = "${digitalocean_droplet.pg.ipv4_address}:6432"
}

output "ssh_command" {
  description = "SSH command to connect to the droplet"
  value       = "ssh ${var.username}@${digitalocean_droplet.pg.ipv4_address}"
}

output "ssh_user" {
  description = "The username created on the droplet"
  value       = var.username
}
