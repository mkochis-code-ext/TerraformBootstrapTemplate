variable "state_storage_account_name" {
  description = "Name of the storage account used for Terraform remote state. Created by bootstrap-setup.yml and imported into state. Must be globally unique, 3–24 lowercase alphanumeric characters."
  type        = string
}

variable "alz_storage_account_names" {
  description = "Set of ALZ subscription storage account names. Deployed in the bootstrap VNet alongside the state storage account. Each name must be globally unique, 3–24 lowercase alphanumeric characters."
  type        = set(string)
}

variable "project_storage_account_names" {
  description = "Set of project landing zone storage account names. Deployed in the project VNet, isolated from the bootstrap network segment. Each name must be globally unique, 3–24 lowercase alphanumeric characters."
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

variable "project_vnet_name" {
  description = "Name of the project landing zone virtual network"
  type        = string
}

variable "project_vnet_address_space" {
  description = "Address space for the project landing zone VNet. Must not overlap with the bootstrap VNet."
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "project_subnet_name" {
  description = "Name of the project landing zone subnet"
  type        = string
  default     = "project"
}

variable "project_subnet_address_prefixes" {
  description = "Address prefixes for the project landing zone subnet"
  type        = list(string)
  default     = ["10.1.1.0/24"]
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}

