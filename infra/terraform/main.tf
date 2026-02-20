terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.30"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}


provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_droplet" "pg" {
  name   = var.droplet_name
  region = var.droplet_region
  size   = var.droplet_size
  image  = "ubuntu-22-04-x64"

  ssh_keys   = [var.ssh_fingerprint]
  backups    = true
  monitoring = true

  user_data = templatefile("${path.module}/cloud-init.yml.tpl", {
    username       = var.username
    ssh_public_key = var.ssh_public_key
  })
}

resource "digitalocean_firewall" "pg_fw" {
  name = "${var.droplet_name}-fw"

  droplet_ids = [digitalocean_droplet.pg.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "6432"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "local_file" "ansible_inventory" {
  content = <<EOT
[pg]
${digitalocean_droplet.pg.ipv4_address} ansible_user=${var.username}
EOT

  filename = "${path.module}/../../ansible/inventory.ini"
}
