variable "name" {
  description = "Name of the private DNS zone (e.g. privatelink.blob.core.windows.net)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy the DNS zone into"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the resource"
  type        = map(string)
  default     = {}
}
