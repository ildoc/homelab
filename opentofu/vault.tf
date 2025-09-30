# Configurazione provider Vault
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

# Variabili Vault
variable "vault_addr" {
  description = "Indirizzo del server Vault"
  type        = string
}

variable "vault_approle_role_id" {
  description = "Role ID per autenticazione AppRole"
  type        = string
  sensitive   = true
}

variable "vault_approle_secret_id" {
  description = "Secret ID per autenticazione AppRole"
  type        = string
  sensitive   = true
}

variable "vault_retry" {
  description = "Numero di tentativi per Vault"
  type        = number
  default     = 2
}

# Recupero dell'API token Pi-hole da Vault
data "vault_kv_secret_v2" "pihole" {
  mount = "opentofu"  # Modifica con il mount del tuo KV engine
  name  = "pihole"  # Modifica con il path del tuo secret
}
