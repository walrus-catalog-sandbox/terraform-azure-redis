terraform {
  required_version = ">= 1.0"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.88.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# create resource group.

resource "azurerm_resource_group" "example" {
  name     = "myResourceGroup"
  location = "eastus"
}

# create virtual network.

resource "azurerm_virtual_network" "example" {
  name                = "myVnet"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
}

# create subnet.

resource "azurerm_subnet" "example" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

# create redis service.

module "this" {
  source = "../.."

  infrastructure = {
    resource_group  = azurerm_resource_group.example.name
    virtual_network = azurerm_virtual_network.example.name
    subnet          = azurerm_subnet.example.name
  }

  resources = {
    class = "Premium"
  }

  depends_on = [azurerm_subnet.example]
}

output "context" {
  description = "The input context, a map, which is used for orchestration."
  value       = module.this.context
}

output "refer" {
  value = nonsensitive(module.this.refer)
}

output "connection" {
  value = module.this.connection
}

output "connection_readonly" {
  value = module.this.connection_readonly
}

output "address" {
  value = module.this.address
}

output "address_readonly" {
  value = module.this.address_readonly
}

output "port" {
  value = module.this.port
}

output "password" {
  value = nonsensitive(module.this.password)
}

output "passwords_readonly" {
  value = nonsensitive(module.this.passwords_readonly)
}