locals {
  base = yamldecode(file("${path.module}/base.yaml"))
  user = try(yamldecode(file(var.user_data)), {})

  merged = merge(
    local.base,
    local.user,
    {
      # Combinar listas en lugar de sobrescribirlas
      packages    = concat(lookup(local.base, "packages", []), lookup(local.user, "packages", []))
      runcmd      = concat(lookup(local.base, "runcmd", []), lookup(local.user, "runcmd", []))
      write_files = concat(lookup(local.base, "write_files", []), lookup(local.user, "write_files", []))
    }
  )
}