terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">=0.77.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.8.0"
    }
  }
}

provider "vault" {
  address = var.vault_addr
  
  # Configurazione per autenticazione AppRole
    auth_login {
      path = "auth/approle/login"
      
      parameters = {
        role_id   = var.vault_approle_role_id
        secret_id = var.vault_approle_secret_id
      }
    }
  
  skip_tls_verify = true
  max_retries = var.vault_retry
}

provider "proxmox" {
  endpoint      = var.proxmox_endpoint
  insecure      = var.proxmox_insecure
  
  api_token = "${local.proxmox_credentials.token_id}=${local.proxmox_credentials.token_secret}"

#   ssh {
#     agent = true
#     username = "root"
#   }
}
