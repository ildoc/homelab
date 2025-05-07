output "container_id" {
  description = "ID del container creato"
  value       = proxmox_virtual_environment_container.lxc.id
}

output "container_name" {
  description = "Nome del container creato"
  value       = proxmox_virtual_environment_container.lxc.initialization[0].hostname
}

output "mac_address" {
  description = "MAC address dell'interfaccia di rete"
  value       = proxmox_virtual_environment_container.lxc.network_interface[0].mac_address
}

output "container_status" {
  description = "Stato corrente del container"
  value       = proxmox_virtual_environment_container.lxc.started ? "running" : "stopped"
}
