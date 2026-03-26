terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Replace the placeholder values below with the outputs from terraform/prereq
  # or pass them via a backend config file: terraform init -backend-config=backend.tfvars
  backend "azurerm" {
    resource_group_name  = "<resource_group_name>"
    storage_account_name = "<storage_account_name>"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
