variable "name" {
  description = "Name of the virtual network"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy the virtual network into"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "tags" {
  description = "Tags to apply to the resource"
  type        = map(string)
  default     = {}
}
