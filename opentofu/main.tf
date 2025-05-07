# Recupero delle credenziali centralizzato
module "vault_secrets" {
  source = "./modules/vault-secrets"
  
  proxmox_credentials_path = var.vault_proxmox_credentials_path
  ssh_keys_path            = var.vault_ssh_keys_path
}

# Definizione di locals per semplificare l'accesso ai segreti e alle configurazioni condivise
locals {
  proxmox_credentials = module.vault_secrets.proxmox_credentials
  ssh_public_key      = module.vault_secrets.ssh_public_key
  ssh_private_key     = module.vault_secrets.ssh_private_key
  
  # Configurazione cloud-init base comune a tutte le VM
  base_cloud_init = templatefile("${path.module}/cloud-init/base-cloud-init.yaml", {
    ssh_pub_key = local.ssh_public_key
  })
  
  # Scansione dei file di configurazione JSON per le VM e gli LXC
  vm_files = fileset("${path.module}/config/vms/", "*.json")
  lxc_files = fileset("${path.module}/config/lxcs/", "*.json")
  
  # Carichiamo i file JSON e li convertiamo in mappe di configurazione
  vm_configs = {
    for file in local.vm_files :
      trimsuffix(basename(file), ".json") => jsondecode(file("${path.module}/config/vms/${file}"))
  }
  
  lxc_configs = {
    for file in local.lxc_files :
      trimsuffix(basename(file), ".json") => jsondecode(file("${path.module}/config/lxcs/${file}"))
  }
}

# Definizione dell'immagine Cloud Ubuntu più recente (una sola definizione)
resource "proxmox_virtual_environment_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = var.iso_datastore
  node_name    = var.default_node

  source_file {
    path = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    # Non specifichiamo il checksum per sempre prendere l'immagine più recente
  }
}

# Creazione delle VM dai file di configurazione
module "vms" {
  source   = "./modules/proxmox-vm"
  for_each = local.vm_configs
  
  # Parametri di base comuni
  ssh_public_key    = local.ssh_public_key
  ssh_private_key   = local.ssh_private_key
  base_cloud_init   = local.base_cloud_init
  cloud_image_id    = proxmox_virtual_environment_file.ubuntu_cloud_image.id
  
  # Parametri specifici dalla configurazione JSON
  vm_name           = each.value.vm_name
  vm_id             = each.value.vm_id
  node_name         = lookup(each.value, "node_name", var.default_node)
  description       = lookup(each.value, "description", "VM ${each.key}")
  tags              = lookup(each.value, "tags", [each.key])
  memory            = lookup(each.value, "memory", 2048)
  cores             = lookup(each.value, "cores", 2)
  disk_size         = lookup(each.value, "disk_size", 10)
  network_bridge    = lookup(each.value, "network_bridge", var.network_bridge)
  mac_address       = lookup(each.value, "mac_address", null)
  ip_config         = lookup(each.value, "ip_config", { ipv4_address = "dhcp", gateway = "" })
  datastore_id      = lookup(each.value, "datastore_id", var.default_datastore)
  packages          = lookup(each.value, "packages", [])
  custom_scripts    = lookup(each.value, "custom_scripts", [])
  start_on_boot     = lookup(each.value, "start_on_boot", [])
}

# Creazione degli LXC dai file di configurazione
module "lxcs" {
  source   = "./modules/proxmox-lxc"
  for_each = local.lxc_configs
  
  # Parametri di base comuni
  ssh_public_key    = local.ssh_public_key
  ssh_private_key   = local.ssh_private_key
  ostemplate_url    = var.default_lxc_template
  
  # Parametri specifici dalla configurazione JSON
  container_name    = each.value.container_name
  container_id      = each.value.container_id
  node_name         = lookup(each.value, "node_name", var.default_node)
  description       = lookup(each.value, "description", "Container LXC ${each.key}")
  tags              = lookup(each.value, "tags", [each.key])
  memory            = lookup(each.value, "memory", 2048)
  cores             = lookup(each.value, "cores", 2)
  disk_size         = lookup(each.value, "disk_size")
  network_bridge    = lookup(each.value, "network_bridge", var.network_bridge)
  mac_address       = lookup(each.value, "mac_address", null)
  ip_config         = lookup(each.value, "ip_config", { ipv4_address = "dhcp", gateway = "" })
  datastore_id      = lookup(each.value, "datastore_id", var.default_datastore)
  feature_nesting   = lookup(each.value, "feature_nesting", false)
  unprivileged      = lookup(each.value, "unprivileged", true)
  packages          = lookup(each.value, "packages", [])
  custom_scripts    = lookup(each.value, "custom_scripts", [])
  start_on_boot     = lookup(each.value, "start_on_boot", [])
}
