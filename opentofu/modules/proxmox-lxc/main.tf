locals {
  # Genera script di inizializzazione per LXC
  init_script = templatefile("${path.module}/templates/init-script.sh.tpl", {
    default_user  = var.default_user
    ssh_pub_key   = var.ssh_public_key
    hostname      = var.container_name
    packages      = join(" ", var.packages)
    custom_scripts = var.custom_scripts
  })

  hook_file_name = "${var.container_id}-${var.container_name}-hook.sh"
}

# Crea script di hook come snippet su Proxmox
resource "proxmox_virtual_environment_file" "lxc_hook_script" {
  content_type = "snippets"
  datastore_id = var.snippets_datastore_id
  node_name    = var.node_name

  file_mode    = "0700"
  
  source_raw {
    data      = local.init_script
    file_name = local.hook_file_name
  }
}

resource "proxmox_virtual_environment_container" "lxc" {
  node_name   = var.node_name
  vm_id       = var.container_id
  description = var.description
  tags        = var.tags

  # Configurazione del tipo di container
  operating_system {
    template_file_id = var.template_id != null ? var.template_id : var.ostemplate_url
    type             = "ubuntu"  # o il tipo appropriato
  }
  
  # Hook script da eseguire dopo la creazione
  hook_script_file_id = proxmox_virtual_environment_file.lxc_hook_script.id
  
  # Risorse
  cpu {
    cores        = var.cores
    architecture = var.cpu_architecture
  }

  memory {
    dedicated = var.memory
    swap      = var.swap_memory
  }

  # Configurazione del disco
  disk {
    datastore_id = var.datastore_id
    size         = var.disk_size
  }
  
  # Configurazione di rete con MAC address personalizzato
  network_interface {
    name        = "eth0"
    bridge      = var.network_bridge
    mac_address = var.mac_address
    firewall    = var.firewall
  }

  # Configurazione iniziale del container
  initialization {
    hostname = var.container_name
    
    ip_config {
      ipv4 {
        address = var.ip_config.ipv4_address
        gateway = var.ip_config.gateway != "" ? var.ip_config.gateway : null
      }
    }
    
    # Configurazione dell'account utente
    user_account {
      keys     = [var.ssh_public_key]
      password = var.root_password
    }
  }
  
  features {
    fuse    = var.feature_fuse
    keyctl  = var.feature_keyctl
    nesting = var.feature_nesting
  }

  # Opzioni di start/shutdown automatico
  start_on_boot = var.start_on_boot
  unprivileged  = var.unprivileged
  started       = true
}
