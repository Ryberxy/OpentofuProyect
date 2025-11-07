########################################
# Crear redes a partir del escenario
########################################

module "network" {
  source = "../../terraform/modules/network"
  for_each = local.networks

  name      = each.value.name
  mode      = each.value.mode
  domain    = lookup(each.value, "domain", null)
  addresses = lookup(each.value, "addresses", [])
  bridge    = lookup(each.value, "bridge", null)
  dhcp      = lookup(each.value, "dhcp", false)
  dns       = lookup(each.value, "dns", false)
  autostart = lookup(each.value, "autostart", false)
}

########################################
# Crear VMs a partir del escenario
########################################

module "server" {
  source   = "../../terraform/modules/vm"
  for_each = local.servers

  name           = each.value.name
  memory         = each.value.memory
  vcpu           = each.value.vcpu
  pool_name      = var.libvirt_pool_name
  pool_path      = var.libvirt_pool_path
  base_image     = each.value.base_image
  disks          = lookup(each.value, "disks", [])
  user_data      = each.value.user_data
  network_config = each.value.network_config

  networks = [
    for n in each.value.networks : {
      network_id     = module.network[n.network_name].id
      wait_for_lease = lookup(n, "wait_for_lease", false)
    }
  ]
}
