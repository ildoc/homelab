locals {
  # Usa il base cloud-init fornito o quello predefinito
  base_cloud_init = var.base_cloud_init != "" ? var.base_cloud_init : templatefile("${path.module}/templates/base-lxc-config.yaml", {
    ssh_pub_key = var.ssh_public_key
    hostname    = var.container_name
  })
  
  # Genera la parte personalizzata del cloud-init
  custom_cloud_init = templatefile("${path.module}/templates/custom-packages.yaml.tpl", {
    packages = var.packages
    scripts  = var.custom_scripts
  })
  
  # Combina le configurazioni cloud-init
  cloud_init_rendered = templatefile("${path.module}/templates/combine.tpl", {
    base_config   = local.base_cloud_init
    hostname      = var.container_name
    ssh_pub_key   = var.ssh_public_key
    custom_config = local.custom_cloud_init
  })
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

  initialization {
    hostname = var.container_name
    
    # dns {
    #   servers = var.dns_servers
    # }
    
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
  
  # Provisioner per cloud-init
  provisioner "file" {
    content     = local.cloud_init_rendered
    destination = "/tmp/cloud-init-custom.yaml"
    
    connection {
      type        = "ssh"
      user        = "root"
      host        = "${var.container_name}.lan"
      private_key = var.ssh_private_key
    }
  }
  
  # Provisioner per configurazione aggiuntiva
  provisioner "remote-exec" {
    inline = [
      "if command -v cloud-init >/dev/null 2>&1; then",
      "  cp /tmp/cloud-init-custom.yaml /etc/cloud/cloud.cfg.d/99-custom.cfg",
      "  cloud-init clean && cloud-init init",
      "  rm /tmp/cloud-init-custom.yaml",
      "else",
      "  # Fallback per container senza cloud-init",
      "  bash -c 'grep -q \"^AllowTcpForwarding\" /etc/ssh/sshd_config && sed -i \"s/^AllowTcpForwarding.*/AllowTcpForwarding yes/\" /etc/ssh/sshd_config || echo \"AllowTcpForwarding yes\" >> /etc/ssh/sshd_config'",
      "  # Installa pacchetti specificati manualmente",
      "  if command -v apt-get >/dev/null 2>&1; then",
      "    apt-get update && apt-get install -y ${join(" ", var.packages)}",
      "  elif command -v yum >/dev/null 2>&1; then", 
      "    yum -y install ${join(" ", var.packages)}",
      "  fi",
      "  # Esegui script personalizzati",
      "  ${join("\n  ", var.custom_scripts)}",
      "fi"
    ]
    
    connection {
      type        = "ssh"
      user        = "root"
      host        = "${var.container_name}.lan"
      private_key = var.ssh_private_key
    }
  }
}
