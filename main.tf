locals {
  project_name     = coalesce(try(var.context["project"]["name"], null), "default")
  project_id       = coalesce(try(var.context["project"]["id"], null), "default_id")
  environment_name = coalesce(try(var.context["environment"]["name"], null), "test")
  environment_id   = coalesce(try(var.context["environment"]["id"], null), "test_id")
  resource_name    = coalesce(try(var.context["resource"]["name"], null), "example")
  resource_id      = coalesce(try(var.context["resource"]["id"], null), "example_id")

  namespace = join("-", [local.project_name, local.environment_name])

  tags = {
    "Name" = join("-", [local.namespace, local.resource_name])

    "walrus.seal.io-catalog-name"     = "terraform-azure-redis"
    "walrus.seal.io-project-id"       = local.project_id
    "walrus.seal.io-environment-id"   = local.environment_id
    "walrus.seal.io-resource-id"      = local.resource_id
    "walrus.seal.io-project-name"     = local.project_name
    "walrus.seal.io-environment-name" = local.environment_name
    "walrus.seal.io-resource-name"    = local.resource_name
  }

  architecture = coalesce(var.architecture, "standalone")
}

# create resource group.

resource "azurerm_resource_group" "default" {
  count = var.infrastructure.resource_group == null ? 1 : 0

  name     = "default"
  location = "eastus"
}

#
# Ensure
#
data "azurerm_resource_group" "selected" {
  name = var.infrastructure.resource_group != null ? var.infrastructure.resource_group : azurerm_resource_group.default[0].name

  lifecycle {
    postcondition {
      condition     = self.id != null
      error_message = "Resource group is not avaiable"
    }
  }
}

data "azurerm_virtual_network" "selected" {
  count               = var.infrastructure.virtual_network != null ? 1 : 0
  name                = var.infrastructure.virtual_network
  resource_group_name = data.azurerm_resource_group.selected.name

  lifecycle {
    postcondition {
      condition     = self.id != null
      error_message = "Virtual network is not avaiable"
    }
  }
}

data "azurerm_subnet" "selected" {
  count = var.infrastructure.subnet != null && var.infrastructure.virtual_network != null ? 1 : 0
  name  = var.infrastructure.subnet

  virtual_network_name = data.azurerm_virtual_network.selected[0].name
  resource_group_name  = data.azurerm_resource_group.selected.name
}

#
# Random
#

# create the name with a random suffix.

resource "random_string" "name_suffix" {
  length  = 10
  special = false
  upper   = false
}

#
# Deployment
#

# create server.

locals {
  name     = join("-", [local.resource_name, random_string.name_suffix.result])
  fullname = join("-", [local.namespace, local.name])
  version  = coalesce(try(split(".", var.engine_version)[0], null), "6")

  replication_readonly_replicas = var.replication_readonly_replicas == 0 ? 1 : var.replication_readonly_replicas
}

resource "azurerm_redis_cache" "primary" {
  name = local.fullname
  tags = local.tags

  resource_group_name = data.azurerm_resource_group.selected.name
  location            = data.azurerm_resource_group.selected.location

  subnet_id = try(data.azurerm_subnet.selected[0].id, null)

  sku_name = var.resources.class
  family   = var.resources.class == "Premium" ? "P" : "C"
  capacity = var.storage.size

  redis_version = local.version

  enable_non_ssl_port           = true
  public_network_access_enabled = var.infrastructure.publicly_accessible
}

resource "azurerm_redis_cache" "secondary" {
  count = var.architecture == "replication" ? local.replication_readonly_replicas : 0

  name = join("-", [local.fullname, "secondary", tostring(count.index)])
  tags = local.tags

  resource_group_name = data.azurerm_resource_group.selected.name
  location            = data.azurerm_resource_group.selected.location

  subnet_id = try(data.azurerm_subnet.selected[0].id, null)

  sku_name = var.resources.class
  family   = var.resources.class == "Premium" ? "P" : "C"
  capacity = var.storage.size

  redis_version = local.version

  enable_non_ssl_port           = true
  public_network_access_enabled = var.infrastructure.publicly_accessible
}

resource "azurerm_redis_linked_server" "link" {
  count = var.architecture == "replication" ? local.replication_readonly_replicas : 0

  target_redis_cache_name = azurerm_redis_cache.primary.name
  server_role             = "Secondary"

  resource_group_name         = data.azurerm_resource_group.selected.name
  linked_redis_cache_location = data.azurerm_resource_group.selected.location

  linked_redis_cache_id = azurerm_redis_cache.secondary[count.index].id
}
