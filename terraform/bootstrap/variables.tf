variable "storage_account_names" {
  description = "Set of storage account names to create. Each name must be globally unique and 3–24 lowercase alphanumeric characters. Using a set with for_each ensures each account is tracked independently."
  type        = set(string)
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy the storage accounts into"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}

