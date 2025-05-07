variable "vm_name" {
  description = "Nome della VM"
  type        = string
}

variable "node_name" {
  description = "Nome del nodo Proxmox"
  type        = string
}

variable "vm_id" {
  description = "ID della VM"
  type        = number
}

variable "template_id" {
  description = "ID del template da usare per la VM (mutualmente esclusivo con cloud_image_id)"
  type        = number
  default     = null
}

variable "cloud_image_id" {
  description = "ID dell'immagine cloud da usare per la VM (mutualmente esclusivo con template_id)"
  type        = string
  default     = null
}

variable "datastore_id" {
  description = "ID del datastore dove salvare la VM"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Bridge di rete da utilizzare"
  type        = string
  default     = "vmbr0"
}

variable "network_model" {
  description = "Modello della scheda di rete"
  type        = string
  default     = "virtio"
}

variable "mac_address" {
  description = "MAC address personalizzato per la VM"
  type        = string
  default     = null  # Se null, verrà generato automaticamente
}

variable "ip_config" {
  description = "Configurazione IP della VM"
  type = object({
    ipv4_address = string
    gateway      = string
  })
  default = {
    ipv4_address = "dhcp"
    gateway      = ""
  }
}

variable "packages" {
  description = "Lista di pacchetti aggiuntivi da installare"
  type        = list(string)
  default     = []
}

variable "custom_scripts" {
  description = "Script personalizzati da eseguire post-installazione"
  type        = list(string)
  default     = []
}

variable "ssh_public_key" {
  description = "Chiave SSH pubblica per l'accesso"
  type        = string
}

variable "base_cloud_init" {
  description = "Configurazione cloud-init base comune a tutte le VM"
  type        = string
  default     = ""  # Se vuoto, verrà usato il template di default del modulo
}

variable "memory" {
  description = "Memoria RAM dedicata in MB"
  type        = number
  default     = 2048
}

variable "cores" {
  description = "Numero di core CPU"
  type        = number
  default     = 2
}

variable "cpu_type" {
  description = "Tipo di CPU"
  type        = string
  default     = "x86-64-v2-AES"
}

variable "disk_size" {
  description = "Dimensione del disco in GB"
  type        = number
  default     = 20
}

variable "disk_iothread" {
  description = "Abilita IOThread per il disco"
  type        = bool
  default     = true
}

variable "description" {
  description = "Descrizione della VM"
  type        = string
  default     = "VM creata con OpenTofu"
}

variable "tags" {
  description = "Tag da assegnare alla VM"
  type        = list(string)
  default     = []
}

variable "agent_timeout" {
  description = "Timeout per l'attesa dell'agente QEMU"
  type        = string
  default     = "15m"
}

variable "start_on_boot" {
  description = "Avvia automaticamente la VM all'avvio del nodo"
  type        = bool
  default     = false
}

variable "ssh_private_key" {
  description = "Chiave SSH privata per il provisioning"
  type        = string
  default     = ""  # Default vuoto per renderla opzionale
  sensitive   = true
}

variable "keuboad_layout" {
  description = "Layout della tastiera"
  type        = string
  default     = "it"
}
