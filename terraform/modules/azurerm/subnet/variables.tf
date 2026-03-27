variable "name" {
  description = "Name of the subnet"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group containing the virtual network"
  type        = string
}

variable "virtual_network_name" {
  description = "Name of the virtual network to create the subnet in"
  type        = string
}

variable "address_prefixes" {
  description = "Address prefixes for the subnet"
  type        = list(string)
}

variable "service_endpoints" {
  description = "List of service endpoints to enable on the subnet"
  type        = list(string)
  default     = []
}
