terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  # No backend configured - state is stored locally and not committed
}

provider "azurerm" {
  features {}
}

# Optionally create a resource group for the storage account
module "resource_group" {
  source = "../modules/azurerm/resource_group"
  count  = var.create_resource_group ? 1 : 0

  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Deploy one storage account per name in var.storage_account_names.
# for_each ensures each storage account is tracked independently — removing a name
# from the set only destroys that specific storage account and its tfstate container.
module "storage_account" {
  source   = "../modules/azurerm/storage_account"
  for_each = var.storage_account_names

  name                = each.key
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  depends_on = [module.resource_group]
}
