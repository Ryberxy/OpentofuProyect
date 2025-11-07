output "vms" {
  description = "Información de todas las máquinas virtuales creadas"
  value = {
    for name, mod in module.server : name => mod.vm_info
  }
}
