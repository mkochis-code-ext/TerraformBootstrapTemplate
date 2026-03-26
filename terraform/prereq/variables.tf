variable "project_name" {
  description = "Short, lowercase alphanumeric project identifier (max 16 characters). Used to build the prereq storage account name: stpreq<project_name>."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{1,16}$", var.project_name))
    error_message = "project_name must be 1–16 lowercase alphanumeric characters with no spaces or special characters."
  }
}

variable "create_resource_group" {
  description = "Set to true to create a new resource group for the storage account, false to use an existing one"
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Name of the resource group for the Terraform state storage account"
  type        = string
}

variable "location" {
  description = "Azure region for the resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Purpose   = "TerraformState"
  }
}
