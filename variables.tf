#
# Contextual Fields
#

variable "context" {
  description = <<-EOF
Receive contextual information. When Walrus deploys, Walrus will inject specific contextual information into this field.

Examples:
```
context:
  project:
    name: string
    id: string
  environment:
    name: string
    id: string
  resource:
    name: string
    id: string
```
EOF
  type        = map(any)
  default     = {}
}

#
# Infrastructure Fields
#

variable "infrastructure" {
  description = <<-EOF
Specify the infrastructure information for deploying.

Examples:
```
infrastructure:
  resource_group: string             # the resource group name where to deploy the Redis Server
  virtual_network: string, optional  # the virtual network name where to deploy the Redis Server
  subnet: string, optional           # the subnet name under the virtual network where to deploy the Redis Server
  publicly_accessible: bool          # whether the Redis service is publicly accessible
```
EOF
  type = object({
    resource_group      = string
    virtual_network     = optional(string)
    subnet              = optional(string)
    publicly_accessible = optional(bool, false)
  })
}

#
# Deployment Fields
#

variable "architecture" {
  description = <<-EOF
Specify the deployment architecture, select from standalone or replication.
EOF
  type        = string
  default     = "standalone"
  validation {
    condition     = var.architecture == "" || contains(["standalone", "replication"], var.architecture)
    error_message = "Invalid architecture"
  }
}

variable "replication_readonly_replicas" {
  description = <<-EOF
Specify the number of read-only replicas under the replication deployment.
EOF
  type        = number
  default     = 1
  validation {
    condition     = var.replication_readonly_replicas == 0 || contains([1, 3, 5], var.replication_readonly_replicas)
    error_message = "Invalid number of read-only replicas"
  }
}

variable "engine_version" {
  description = <<-EOF
Specify the deployment engine version of the Redis Server to use. Possible values are 6.0, and 4.0.
EOF
  type        = string
  default     = "6.0"
  validation {
    condition     = var.engine_version == "" || contains(["6.0", "4.0"], var.engine_version)
    error_message = "Invalid version"
  }
}

variable "resources" {
  description = <<-EOF
Specify the computing resources.
Please note that the resources class is only available for the Basic, Standard, and Premium pricing tiers.
See https://docs.microsoft.com/en-us/azure/azure-cache-for-redis/cache-overview#pricing for more information.
Examples:
```
resources:
  class: string, optional            # sku
```
EOF
  type = object({
    class = optional(string, "Basic")
  })
  default = {
    class = "Basic"
  }

  validation {
    condition     = var.resources == null || contains(["Basic", "Standard", "Premium"], var.resources.class)
    error_message = "Invalid resources class"
  }
}

variable "storage" {
  description = <<-EOF
The storage size of the Redis cache. Valid values for a SKU family of C (Basic/Standard) are 0, 1, 2, 3, 4, 5, 6, and for P (Premium) family are 1, 2, 3, 4, 5
EOF
  type = object({
    size = optional(number, 1)
  })
  default = {
    size = 1
  }
  validation {
    condition     = var.storage.size == 0 || contains([0, 1, 2, 3, 4, 5, 6], var.storage.size)
    error_message = "Invalid storage size"
  }
}
