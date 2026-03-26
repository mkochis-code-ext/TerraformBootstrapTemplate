output "storage_account_name" {
  description = "Name of the Terraform state storage account created for this project"
  value       = module.storage_account.name
}

output "resource_group_name" {
  description = "Name of the resource group containing the Terraform state storage account"
  value       = var.resource_group_name
}

output "tfstate_container_name" {
  description = "Name of the blob container for Terraform state files"
  value       = module.storage_account.tfstate_container_name
}
