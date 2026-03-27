variable "name" {
  description = "Name of the virtual network link"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group containing the private DNS zone"
  type        = string
}

variable "private_dns_zone_name" {
  description = "Name of the private DNS zone to link"
  type        = string
}

variable "virtual_network_id" {
  description = "ID of the virtual network to link to the DNS zone"
  type        = string
}
