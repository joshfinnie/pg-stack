variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "ssh_fingerprint" {
  description = "SSH key fingerprint registered with DigitalOcean"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key content to add to the droplet user"
  type        = string
}

variable "username" {
  description = "Username to create on the droplet"
  type        = string
  default     = "josh"
}

variable "droplet_name" {
  description = "Name of the droplet"
  type        = string
  default     = "pg-core"
}

variable "droplet_region" {
  description = "DigitalOcean region for the droplet"
  type        = string
  default     = "nyc3"
}

variable "droplet_size" {
  description = "Droplet size slug"
  type        = string
  default     = "s-1vcpu-1gb"
}
