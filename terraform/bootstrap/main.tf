terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Backend is configured at init time via -backend-config flags or a generated backend.tf.
  # See the CI/CD workflows for how backend values are injected from secrets.
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
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
}

