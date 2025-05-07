# Timestamp del deployment
output "deployment_timestamp" {
  description = "Timestamp dell'ultimo deployment"
  value       = timestamp()
}

# Riepilogo dell'infrastruttura - completamente dinamico
output "infrastructure_summary" {
  description = "Riepilogo dello stato delle risorse"
  value = {
    vms = {
      for name, vm in module.vms : 
        name => try(vm.vm_status, "") != "" ? "deployed" : "failed"
    },
    lxcs = {
      for name, lxc in module.lxcs : 
        name => try(lxc.container_status, "") != "" ? "deployed" : "failed"
    }
  }
}

# Dettagli di tutte le VM - completamente dinamico
output "vm_details" {
  description = "Dettagli di tutte le VM deployate"
  value = {
    for name, vm in module.vms : 
      name => try(vm.vm_name != "", false) ? {
        name        = vm.vm_name
        id          = vm.vm_id
        ip_address  = vm.ip_address
        mac_address = vm.mac_address
        status      = vm.vm_status
      } : null
  }
}

# Dettagli di tutti i container LXC - completamente dinamico
output "lxc_details" {
  description = "Dettagli di tutti i container LXC deployati"
  value = {
    for name, lxc in module.lxcs : 
      name => try(lxc.container_name != "", false) ? {
        name        = lxc.container_name
        id          = lxc.container_id
        mac_address = lxc.mac_address
        status      = lxc.container_status
      } : null
  }
}

# Output individuale per ogni VM per facile accesso
output "vms" {
  description = "Accesso diretto a tutte le VM per nome"
  value = {
    for name, vm in module.vms : name => {
      name        = try(vm.vm_name, "")
      id          = try(vm.vm_id, "")
      ip_address  = try(vm.ip_address, [])
      status      = try(vm.vm_status, "")
    }
  }
}

# Output individuale per ogni container LXC per facile accesso
output "lxcs" {
  description = "Accesso diretto a tutti i container LXC per nome"
  value = {
    for name, lxc in module.lxcs : name => {
      name        = try(lxc.container_name, "")
      id          = try(lxc.container_id, "")
      status      = try(lxc.container_status, "")
    }
  }
}
