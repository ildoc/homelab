terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.78.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "4.8.0"
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
  
  # api_token = "${local.proxmox_credentials.token_id}=${local.proxmox_credentials.token_secret}"
  auth_ticket           = var.proxmox_auth_ticket
  csrf_prevention_token = var.proxmox_csrf_prevention_token

  ssh {
    agent       = false
    username    = "root"
    private_key = module.vault_secrets.proxmox_ssh_private_key
  }
}
