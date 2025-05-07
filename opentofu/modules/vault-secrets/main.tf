# Recupero delle credenziali Proxmox
data "vault_generic_secret" "proxmox_credentials" {
  path = var.proxmox_credentials_path
}

# Recupero delle chiavi SSH
data "vault_generic_secret" "ssh_key" {
  path = var.ssh_keys_path
}

# Struttura i dati per il modulo principale
locals {
  proxmox_credentials = {
    token_id     = lookup(data.vault_generic_secret.proxmox_credentials.data, "token_id", null)
    token_secret = lookup(data.vault_generic_secret.proxmox_credentials.data, "token_secret", null)
  }
  
  ssh_public_key = data.vault_generic_secret.ssh_key.data["public_key"]
  ssh_private_key = data.vault_generic_secret.ssh_key.data["private_key"]
}
