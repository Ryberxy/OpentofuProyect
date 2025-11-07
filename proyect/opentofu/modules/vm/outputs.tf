output "vm_info" {
  description = "Información de la máquina virtual: nombre e IPs asignadas"
  value = {
    nombre = libvirt_domain.vm.name
    ips = [
      for iface in libvirt_domain.vm.network_interface :
      try(iface.addresses[0], "No disponible")
    ]

  }
}