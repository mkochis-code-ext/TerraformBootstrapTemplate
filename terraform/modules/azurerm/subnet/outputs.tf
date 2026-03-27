output "id" {
  description = "ID of the subnet"
  value       = azurerm_subnet.main.id
}

output "name" {
  description = "Name of the subnet"
  value       = azurerm_subnet.main.name
}
