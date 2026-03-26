output "id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "tfstate_container_name" {
  description = "Name of the tfstate container"
  value       = azurerm_storage_container.tfstate.name
}
