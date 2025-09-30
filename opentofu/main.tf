terraform {
  required_providers {
    pihole = {
      source  = "ryanwholey/pihole"
      version = "~> 0.2.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "4.8.0"
    }
  }
}

provider "pihole" {
  url       = var.pihole_url
  api_token = data.vault_kv_secret_v2.pihole.data["api_token"]  # API token recuperato da Vault
}

# Variabili di configurazione
variable "pihole_url" {
  description = "URL del server Pi-hole"
  type        = string
  default     = "http://192.168.0.145"
}
