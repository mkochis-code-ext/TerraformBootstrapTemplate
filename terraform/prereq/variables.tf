variable "create_resource_group" {
  description = "Set to true to create a new resource group for the storage account, false to use an existing one"
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Name of the resource group for the Terraform state storage account"
  type        = string
}

variable "storage_account_names" {
  description = "Set of storage account names to create for Terraform remote state. Each name must be globally unique and 3-24 lowercase alphanumeric characters. Using a set ensures for_each can track each account independently."
  type        = set(string)
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
