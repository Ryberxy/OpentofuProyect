##############################################
# escenario.tf — Escenario proxy + backend
##############################################

locals {

  ##############################################
  # Redes a crear
  ##############################################

  networks = {
    red-externa = {
      name      = "red-externa"
      mode      = "nat"
      domain    = "example.com"
      addresses = ["192.168.200.0/24"]
      bridge    = "br-ex"
      dhcp      = true
      dns       = true
      autostart = true
    }

    red-conf = {
      name      = "red-conf"
      mode      = "none" # sin conectividad
      addresses = ["192.168.201.0/24"]
      bridge    = "br-conf"
      autostart = true
    }

    red-datos = {
      name      = "red-datos"
      mode      = "none" # sin conectividad
      bridge    = "br-datos"
      autostart = true
    }
  }

  ##############################################
  # Máquinas virtuales a crear
  ##############################################

  servers = {
    apache2 = {
      name       = "apache2"
      memory     = 1024
      vcpu       = 1
      base_image = "debian13-base.qcow2"

      networks = [
        { network_name = "red-externa", wait_for_lease = true },
        { network_name = "red-conf" },
        { network_name = "red-datos" }
      ]

      user_data      = "${path.module}/cloud-init/server1/user-data.yaml"
      network_config = "${path.module}/cloud-init/server1/network-config.yaml"
    }

    mariadb = {
      name       = "mariadb"
      memory     = 1024
      vcpu       = 1
      base_image = "ubuntu2404-base.qcow2"

      networks = [
        { network_name = "red-externa", wait_for_lease = true },
        { network_name = "red-conf" },
        { network_name = "red-datos" }
      ]

      user_data      = "${path.module}/cloud-init/server2/user-data.yaml"
      network_config = "${path.module}/cloud-init/server2/network-config.yaml"
    }
  }
}
