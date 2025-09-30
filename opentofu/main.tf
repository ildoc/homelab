terraform {
  required_providers {
    pihole = {
      source  = "ryanwholey/pihole"
      version = "2.0.0-beta.1"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "5.3.0"
    }
  }
  required_version = ">= 1.6.0"
}

provider "pihole" {
  url       = var.pihole_url
  password = data.vault_kv_secret_v2.pihole.data["password"]
}

# Variabili di configurazione
variable "pihole_url" {
  description = "URL del server Pi-hole"
  type        = string
  default     = "http://192.168.0.145"
}
