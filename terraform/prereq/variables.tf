variable "create_resource_group" {
  description = "Set to true to create a new resource group for the storage account, false to use an existing one"
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Name of the resource group for the Terraform state storage account"
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account for Terraform remote state (must be globally unique, 3-24 lowercase alphanumeric characters)"
  type        = string
}

variable "location" {
  description = "Azure region for the resources"
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Purpose   = "TerraformState"
  }
}
