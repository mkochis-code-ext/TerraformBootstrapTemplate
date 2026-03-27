output "state_storage_account_name" {
  description = "Name of the Terraform state storage account"
  value       = azurerm_storage_account.state.name
}

output "state_tfstate_container_name" {
  description = "Name of the blob container for Terraform state files"
  value       = azurerm_storage_container.tfstate.name
}

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

output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.virtual_network.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.virtual_network.name
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = module.subnet.id
}

output "private_dns_zone_blob_id" {
  description = "ID of the blob private DNS zone"
  value       = module.private_dns_zone_blob.id
}
