locals {
  # Usa il base cloud-init fornito o quello predefinito
  base_cloud_init = var.base_cloud_init != "" ? var.base_cloud_init : templatefile("${path.module}/templates/base-cloud-init.yaml", {
    ssh_pub_key = var.ssh_public_key
    hostname    = var.vm_name
  })
  
  # Genera la parte personalizzata del cloud-init
  custom_cloud_init = templatefile("${path.module}/templates/custom-packages.yaml.tpl", {
    packages = var.packages
    scripts  = var.custom_scripts
  })
  
  # Combina le configurazioni cloud-init
  cloud_init_rendered = templatefile("${path.module}/templates/combine.tpl", {
    base_config   = local.base_cloud_init
    hostname      = var.vm_name
    ssh_pub_key   = var.ssh_public_key
    custom_config = local.custom_cloud_init
  })
}

resource "proxmox_virtual_environment_vm" "vm" {
  name        = var.vm_name
  node_name   = var.node_name
  vm_id       = var.vm_id
  description = var.description
  tags        = var.tags

  cpu {
    cores = var.cores
    type  = var.cpu_type
  }

  memory {
    dedicated = var.memory
  }

  # Configurazione del disco usando un'immagine cloud
  disk {
    datastore_id = var.datastore_id
    file_id      = var.cloud_image_id
    interface    = "scsi0"
    size         = var.disk_size
    iothread     = var.disk_iothread
  }
  
  # Configurazione di rete con MAC address personalizzato
  network_device {
    bridge      = var.network_bridge
    mac_address = var.mac_address
    model       = var.network_model
  }

  initialization {
    datastore_id = var.datastore_id
    
    ip_config {
      ipv4 {
        address = var.ip_config.ipv4_address != "" ? var.ip_config.ipv4_address : "dhcp"
        gateway = var.ip_config.gateway != "" ? var.ip_config.gateway : null
      }
    }
    
    # Configurazione dell'account utente
    user_account {
      keys     = [var.ssh_public_key]
    }

    user_data = local.cloud_init_rendered
    keyboad_layout = var.keyboad_layout
  }

  operating_system {
    type = "l26" # Linux kernel 2.6+
  }

  agent {
    enabled = true
    timeout = var.agent_timeout
  }
  
  # Opzioni di avvio
  on_boot = var.start_on_boot
  started = true

  # Gestione ciclo di vita
  lifecycle {
    ignore_changes = [
      initialization[0].user_data_file_id
    ]
  }
  
  # Dipendenze
  depends_on = [
    var.cloud_image_id,
    var.template_id
  ]
}
