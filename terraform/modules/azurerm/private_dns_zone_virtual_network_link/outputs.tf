output "id" {
  description = "ID of the virtual network link"
  value       = azurerm_private_dns_zone_virtual_network_link.main.id
}

output "name" {
  description = "Name of the virtual network link"
  value       = azurerm_private_dns_zone_virtual_network_link.main.name
}
