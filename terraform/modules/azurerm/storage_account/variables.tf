variable "name" {
  description = "Name of the storage account (must be globally unique, 3-24 lowercase alphanumeric characters)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy the storage account into"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the resource"
  type        = map(string)
  default     = {}
}

variable "subnet_ids" {
  description = "List of subnet IDs allowed to access the storage account"
  type        = list(string)
  default     = []
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for the private endpoint"
  type        = string
}

variable "private_dns_zone_blob_id" {
  description = "ID of the privatelink.blob.core.windows.net private DNS zone"
  type        = string
}
