output "storage_account_names" {
  description = "Map of storage account names created by the bootstrap, keyed by storage account name"
  value       = { for k, v in module.storage_account : k => v.name }
}

output "resource_group_name" {
  description = "Name of the resource group containing the bootstrap storage accounts"
  value       = var.resource_group_name
}

output "tfstate_container_names" {
  description = "Map of tfstate container names keyed by storage account name"
  value       = { for k, v in module.storage_account : k => v.tfstate_container_name }
}
