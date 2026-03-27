variable "state_storage_account_name" {
  description = "Name of the storage account used for Terraform remote state. Created by bootstrap-setup.yml and imported into state. Must be globally unique, 3–24 lowercase alphanumeric characters."
  type        = string
}

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

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
  default     = "default"
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for the subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}

