locals {
  port = 6379
  hosts = [
    format("%s", azurerm_redis_cache.primary.hostname)
  ]
  hosts_readonly = local.architecture == "replication" ? flatten([
    azurerm_redis_cache.secondary[*].hostname
  ]) : []

  endpoints = [
    for c in local.hosts : format("%s:%d", c, local.port)
  ]
  endpoints_readonly = [
    for c in(local.hosts_readonly != null ? local.hosts_readonly : []) : format("%s:%d", c, local.port)
  ]

  password = azurerm_redis_cache.primary.primary_access_key
  passwords_readonly = local.architecture == "replication" ? flatten([
    azurerm_redis_cache.secondary[*].primary_access_key
  ]) : []
}

output "context" {
  description = "The input context, a map, which is used for orchestration."
  value       = var.context
}

output "refer" {
  description = "The refer, a map, including hosts, ports and account, which is used for dependencies or collaborations."
  sensitive   = true
  value = {
    schema = "azure:redis"
    params = {
      selector           = local.tags
      hosts              = local.hosts
      hosts_readonly     = local.hosts_readonly
      port               = local.port
      endpoints          = local.endpoints
      endpoints_readonly = local.endpoints_readonly
      password           = nonsensitive(local.password)
      passwords_readonly = nonsensitive(join(",", local.passwords_readonly))
    }
  }
}

output "connection" {
  description = "The connection, a string combined host and port, might be a comma separated string or a single string."
  value       = join(",", local.endpoints)
}

output "connection_readonly" {
  description = "The readonly connection, a string combined host and port, might be a comma separated string or a single string."
  value       = join(",", local.endpoints_readonly)
}

output "address" {
  description = "The address, a string only has host, might be a comma separated string or a single string."
  value       = join(",", local.hosts)
}

output "address_readonly" {
  description = "The readonly address, a string only has host, might be a comma separated string or a single string."
  value       = join(",", local.hosts_readonly)
}

output "port" {
  description = "The port of the service."
  value       = local.port
}

output "password" {
  description = "The password of the account to access the database."
  value       = local.password
  sensitive   = true
}

output "passwords_readonly" {
  description = "The readonly passwords of the account to access the database."
  value       = join(",", local.passwords_readonly)
  sensitive   = true
}