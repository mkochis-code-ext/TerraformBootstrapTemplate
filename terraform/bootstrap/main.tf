terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Backend is configured via a generated backend.tf file.
  # See the CI/CD workflows for how backend values are injected from secrets.
  # Run bootstrap-setup.yml first to create the state storage account.
}

provider "azurerm" {
  features {}
}

module "resource_group" {
  source = "../modules/azurerm/resource_group"

  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# State storage account for Terraform remote state. Network-restricted to the VNet.
# Created by bootstrap-setup.yml via Azure CLI, then imported into state on the first run.
# CI/CD runners temporarily add their IP to ip_rules (managed outside Terraform).
resource "azurerm_storage_account" "state" {
  name                          = var.state_storage_account_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  min_tls_version               = "TLS1_2"
  public_network_access_enabled = true
  tags                          = var.tags

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [module.subnet.id]
    bypass                     = ["AzureServices"]
  }

  # ip_rules are managed by CI/CD pipelines (runner IP allow/remove).
  # Terraform must not revert dynamically added runner IPs.
  lifecycle {
    ignore_changes = [network_rules[0].ip_rules]
  }

  depends_on = [module.resource_group, module.subnet]
}

resource "azurerm_private_endpoint" "state_blob" {
  name                = "pe-${var.state_storage_account_name}-blob"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = module.subnet.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.state_storage_account_name}-blob"
    private_connection_resource_id = azurerm_storage_account.state.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [module.private_dns_zone_blob.id]
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.state.name
  container_access_type = "private"
}

module "virtual_network" {
  source = "../modules/azurerm/virtual_network"

  name                = var.vnet_name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.vnet_address_space
  tags                = var.tags

  depends_on = [module.resource_group]
}

module "subnet" {
  source = "../modules/azurerm/subnet"

  name                 = var.subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = module.virtual_network.name
  address_prefixes     = var.subnet_address_prefixes
  service_endpoints    = ["Microsoft.Storage"]
}

module "private_dns_zone_blob" {
  source = "../modules/azurerm/private_dns_zone"

  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags

  depends_on = [module.resource_group]
}

module "private_dns_zone_vnet_link_blob" {
  source = "../modules/azurerm/private_dns_zone_virtual_network_link"

  name                  = "${var.vnet_name}-blob-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = module.private_dns_zone_blob.name
  virtual_network_id    = module.virtual_network.id
}

# Deploy one ALZ storage account per name in var.alz_storage_account_names.
# These live in the bootstrap subnet alongside the state storage account.
# Used for ALZ subscription Terraform state (Management, Identity, Connectivity, etc.).
module "alz_storage_account" {
  source   = "../modules/azurerm/storage_account"
  for_each = var.alz_storage_account_names

  name                       = each.key
  resource_group_name        = var.resource_group_name
  location                   = var.location
  subnet_ids                 = [module.subnet.id]
  private_endpoint_subnet_id = module.subnet.id
  private_dns_zone_blob_id   = module.private_dns_zone_blob.id
  tags                       = var.tags
}

# ─────────────────────────────────────────────────────────────────────────────
# Project Landing Zone Network
# Separate VNet and subnet for ALZ project storage accounts.
# Isolates project workloads from the bootstrap/state infrastructure to limit
# blast radius. VNet peering allows private DNS resolution across both networks.
# ─────────────────────────────────────────────────────────────────────────────

module "project_virtual_network" {
  source = "../modules/azurerm/virtual_network"

  name                = var.project_vnet_name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.project_vnet_address_space
  tags                = var.tags

  depends_on = [module.resource_group]
}

module "project_subnet" {
  source = "../modules/azurerm/subnet"

  name                 = var.project_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = module.project_virtual_network.name
  address_prefixes     = var.project_subnet_address_prefixes
  service_endpoints    = ["Microsoft.Storage"]
}

# Link the project VNet to the blob private DNS zone so private endpoints
# deployed in the project subnet resolve correctly.
module "private_dns_zone_vnet_link_blob_project" {
  source = "../modules/azurerm/private_dns_zone_virtual_network_link"

  name                  = "${var.project_vnet_name}-blob-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = module.private_dns_zone_blob.name
  virtual_network_id    = module.project_virtual_network.id
}

# Bi-directional VNet peering between bootstrap and project networks.
# Allows cross-network private endpoint resolution while keeping the
# network segments isolated at the NSG / subnet level.
resource "azurerm_virtual_network_peering" "bootstrap_to_project" {
  name                      = "${var.vnet_name}-to-${var.project_vnet_name}"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = module.virtual_network.name
  remote_virtual_network_id = module.project_virtual_network.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
}

resource "azurerm_virtual_network_peering" "project_to_bootstrap" {
  name                      = "${var.project_vnet_name}-to-${var.vnet_name}"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = module.project_virtual_network.name
  remote_virtual_network_id = module.virtual_network.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
}

# Deploy one project storage account per name in var.project_storage_account_names.
# These live in the project subnet, isolated from the bootstrap state network.
# Used for project/workload Terraform state.
module "project_storage_account" {
  source   = "../modules/azurerm/storage_account"
  for_each = var.project_storage_account_names

  name                       = each.key
  resource_group_name        = var.resource_group_name
  location                   = var.location
  subnet_ids                 = [module.project_subnet.id]
  private_endpoint_subnet_id = module.project_subnet.id
  private_dns_zone_blob_id   = module.private_dns_zone_blob.id
  tags                       = var.tags
}

