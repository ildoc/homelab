variable "container_name" {
  description = "Nome del container LXC"
  type        = string
}

variable "container_id" {
  description = "ID del container LXC"
  type        = number
}

variable "node_name" {
  description = "Nome del nodo Proxmox"
  type        = string
}

variable "template_id" {
  description = "ID del template LXC da usare"
  type        = string
  default     = null
}

variable "ostemplate_url" {
  description = "URL del template OS da scaricare se non è già presente"
  type        = string
  default     = null
}

variable "datastore_id" {
  description = "ID del datastore dove salvare il container"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Bridge di rete da utilizzare"
  type        = string
  default     = "vmbr0"
}

variable "mac_address" {
  description = "MAC address personalizzato per il container"
  type        = string
  default     = null  # Se null, verrà generato automaticamente
}

variable "firewall" {
  description = "Firewall"
  type        = bool
  default     = true
}

variable "ip_config" {
  description = "Configurazione IP del container"
  type = object({
    ipv4_address = string
    gateway      = string
  })
  default = {
    ipv4_address = "dhcp"
    gateway      = ""
  }
}

variable "dns_servers" {
  description = "Elenco di server DNS"
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
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

variable "ssh_private_key" {
  description = "Chiave SSH privata per il provisioning"
  type        = string
  sensitive   = true
}

variable "root_password" {
  description = "Password per l'utente root (opzionale)"
  type        = string
  default     = null
  sensitive   = true
}

variable "base_cloud_init" {
  description = "Configurazione cloud-init base per il container"
  type        = string
  default     = ""
}

variable "memory" {
  description = "Memoria RAM dedicata in MB"
  type        = number
  default     = 512
}

variable "swap_memory" {
  description = "Memoria swap in MB"
  type        = number
  default     = 512
}

variable "cores" {
  description = "Numero di core CPU"
  type        = number
  default     = 1
}

variable "cpu_units" {
  description = "Unità CPU (1-10000)"
  type        = number
  default     = 1024
}

variable "cpu_architecture" {
  description = "Architettura CPU (x86_64, aarch64)"
  type        = string
  default     = "amd64"
}

variable "disk_size" {
  description = "Dimensione del disco in GB"
  type        = number
  default     = 8
}

variable "description" {
  description = "Descrizione del container"
  type        = string
  default     = "Container LXC creato con OpenTofu"
}

variable "tags" {
  description = "Tag da assegnare al container"
  type        = list(string)
  default     = []
}

variable "start_on_boot" {
  description = "Avvia automaticamente il container all'avvio del nodo"
  type        = bool
  default     = false
}

variable "unprivileged" {
  description = "Crea un container unprivileged"
  type        = bool
  default     = true
}

variable "feature_fuse" {
  description = "Abilita supporto FUSE"
  type        = bool
  default     = false
}

variable "feature_keyctl" {
  description = "Abilita supporto keyctl"
  type        = bool
  default     = false
}

variable "feature_nesting" {
  description = "Abilita il nesting (per Docker dentro LXC)"
  type        = bool
  default     = false
}
