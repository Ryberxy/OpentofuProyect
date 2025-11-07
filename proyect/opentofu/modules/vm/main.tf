# Disco principal (clon ligero)
resource "libvirt_volume" "disk_main" {
  name           = "${var.name}-linked.qcow2"
  pool           = var.pool_name
  base_volume_id = "${var.pool_path}/${var.base_image}"
  format         = "qcow2"
}

# Discos adicionales
resource "libvirt_volume" "extra_disks" {
  for_each = { for d in var.disks : d.name => d }
  name     = "${var.name}-${each.value.name}.qcow2"
  pool     = var.pool_name
  format   = "qcow2"

  # solo si se define tamaño
  size = try(each.value.size, null)
}

# Cloud-init
resource "libvirt_cloudinit_disk" "cloudinit" {
  count          = var.user_data != null ? 1 : 0
  name           = "${var.name}-cloudinit.iso"
  pool           = var.pool_name
  user_data      = join("\n", ["#cloud-config", yamlencode(local.merged)])
  network_config = var.network_config != null ? file(var.network_config) : null
}

# Dominio (VM)
resource "libvirt_domain" "vm" {
  name   = var.name
  memory = var.memory
  vcpu   = var.vcpu

  # Interfaces de red
  dynamic "network_interface" {
    for_each = var.networks
    content {
      network_name   = network_interface.value.network_name
      wait_for_lease = try(network_interface.value.wait_for_lease, false)

    }
  }

  # Disco principal
  disk {
    volume_id = libvirt_volume.disk_main.id
  }

  # Discos adicionales
  dynamic "disk" {
    for_each = libvirt_volume.extra_disks
    content {
      volume_id = disk.value.id
    }
  }

  # Cloud-init si existe
  cloudinit = var.user_data != null ? libvirt_cloudinit_disk.cloudinit[0].id : null
}
