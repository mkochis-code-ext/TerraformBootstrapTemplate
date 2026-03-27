# TerraformBootstrapTemplate

A template repository that bootstraps Terraform state management in Azure. It solves the classic chicken-and-egg problem — the storage account that holds Terraform state is itself managed by Terraform — using a one-time setup workflow that creates resources via Azure CLI, imports them into state, and then hands off to normal CI/CD from that point forward.

All storage accounts are deployed inside a VNet with private endpoints and deny-by-default network rules. CI/CD runners temporarily allowlist their public IP during each workflow run.

## Repository Structure

```
.github/
└── workflows/
    ├── bootstrap-setup.yml  # One-time setup: creates state resources, imports into Terraform
    ├── bootstrap-ci.yml     # CI pipeline: plan on PRs with PR comment
    └── bootstrap-cd.yml     # CD pipeline: plan → approval gate → apply on push/dispatch
terraform/
├── bootstrap/               # Main Terraform configuration
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
└── modules/
    └── azurerm/
        ├── private_dns_zone/                    # Azure Private DNS Zone
        ├── private_dns_zone_virtual_network_link/ # VNet link for private DNS
        ├── resource_group/                      # Azure Resource Group
        ├── storage_account/                     # Storage account with private endpoint & tfstate container
        ├── subnet/                              # Subnet with service endpoints
        └── virtual_network/                     # Virtual Network
```

## How It Works

### The Bootstrap Problem

Terraform needs a storage account to store its remote state, but that storage account is defined in the Terraform configuration itself. You can't `terraform apply` because the backend doesn't exist yet.

### The Solution

The `bootstrap-setup.yml` workflow solves this in a single automated run:

```
┌─────────────────────────────────────────────────────────────────┐
│  bootstrap-setup.yml (run once)                                 │
│                                                                 │
│  1. Azure CLI creates:                                          │
│     • Resource group                                            │
│     • State storage account                                     │
│     • tfstate blob container                                    │
│                                                                 │
│  2. Runner IP added to storage firewall (temporary)             │
│                                                                 │
│  3. terraform init (backend now exists)                         │
│                                                                 │
│  4. terraform import (RG + storage account + container          │
│     brought into state, skipped if already tracked)             │
│                                                                 │
│  5. terraform apply (creates remaining resources:               │
│     VNet, subnet, DNS zones, project storage accounts, etc.)    │
│                                                                 │
│  6. Runner IP removed from storage firewall                     │
└─────────────────────────────────────────────────────────────────┘
```

After the setup workflow completes, all resources — including the state storage account itself — are fully managed in Terraform state. Future changes go through the normal CI/CD pipelines.

### Network Security Model

All storage accounts are locked down:

- **Default action**: Deny all traffic
- **VNet access**: Allowed via subnet service endpoints
- **Private endpoints**: Each storage account gets a blob private endpoint linked to a private DNS zone
- **CI/CD access**: Runners temporarily add their public IP to `ip_rules` at the start of each workflow, and remove it at the end (even on failure, via `if: always()`)
- **Terraform compatibility**: `lifecycle { ignore_changes = [network_rules[0].ip_rules] }` prevents Terraform from reverting dynamically managed runner IPs
- **Azure services**: Allowed via `bypass = ["AzureServices"]`

## Getting Started

### Prerequisites

- An Azure subscription
- A service principal with Contributor access to the subscription (or target resource group)
- A GitHub repository with the following secrets configured

### Step 1: Configure GitHub Secrets

| Secret                            | Description                                                              |
|-----------------------------------|--------------------------------------------------------------------------|
| `ARM_CLIENT_ID`                   | Service principal application (client) ID                                |
| `ARM_CLIENT_SECRET`               | Service principal secret                                                 |
| `ARM_SUBSCRIPTION_ID`             | Azure subscription ID                                                    |
| `ARM_TENANT_ID`                   | Azure AD tenant ID                                                       |
| `BOOTSTRAP_RESOURCE_GROUP_NAME`   | Name for the bootstrap resource group (e.g. `rg-bootstrap-myworkload`)   |
| `BOOTSTRAP_LOCATION`              | Azure region (e.g. `eastus`)                                             |
| `TF_STATE_STORAGE_ACCOUNT`        | Name for the state storage account (e.g. `stbootstrapstate`)             |
| `BOOTSTRAP_STORAGE_ACCOUNT_NAMES` | JSON array of project storage account names (e.g. `["stmyworkload1"]`)   |

### Step 2: Configure GitHub Environments

Create the following environment in **Settings → Environments**:

- **`bootstrap-apply`** — Add required reviewers to gate CD applies

### Step 3: Run the Bootstrap Setup

1. Go to **Actions → Bootstrap Setup → Run workflow**
2. The workflow will:
   - Create the resource group, state storage account, and tfstate container via Azure CLI
   - Initialize Terraform with the remote backend
   - Import the CLI-created resources into Terraform state
   - Run `terraform apply` to create the remaining infrastructure (VNet, subnet, DNS zones, project storage accounts)
3. Verify the run succeeds with no errors

### Step 4: Normal Development Workflow

From this point forward, all changes go through the standard CI/CD pipelines:

- **Pull requests** → `bootstrap-ci.yml` runs `terraform plan` and posts results as a PR comment
- **Merge to main** → `bootstrap-cd.yml` runs plan, waits for approval in the `bootstrap-apply` environment, then applies

## Terraform Configuration

### Variables

| Variable                     | Type           | Required | Default          | Description                                              |
|------------------------------|----------------|----------|------------------|----------------------------------------------------------|
| `state_storage_account_name` | `string`       | Yes      | —                | State storage account name (3–24 lowercase alphanumeric) |
| `storage_account_names`      | `set(string)`  | Yes      | —                | Project storage account names (tracked via `for_each`)   |
| `resource_group_name`        | `string`       | Yes      | —                | Resource group name                                      |
| `location`                   | `string`       | Yes      | —                | Azure region                                             |
| `vnet_name`                  | `string`       | Yes      | —                | Virtual network name                                     |
| `vnet_address_space`         | `list(string)` | No       | `["10.0.0.0/16"]`  | VNet address space                                    |
| `subnet_name`                | `string`       | No       | `"default"`      | Subnet name                                              |
| `subnet_address_prefixes`    | `list(string)` | No       | `["10.0.1.0/24"]`  | Subnet address prefixes                               |
| `tags`                       | `map(string)`  | No       | `{ManagedBy = "Terraform"}` | Tags applied to all resources              |

### Outputs

| Output                        | Description                                               |
|-------------------------------|-----------------------------------------------------------|
| `state_storage_account_name`  | Name of the Terraform state storage account               |
| `state_tfstate_container_name`| Name of the state blob container                          |
| `storage_account_names`       | Map of project storage account names                      |
| `resource_group_name`         | Name of the resource group                                |
| `tfstate_container_names`     | Map of tfstate container names per project storage account |
| `vnet_id`                     | ID of the virtual network                                 |
| `vnet_name`                   | Name of the virtual network                               |
| `subnet_id`                   | ID of the subnet                                          |
| `private_dns_zone_blob_id`    | ID of the blob private DNS zone                           |

### Resources Created

| Resource | Description |
|----------|-------------|
| Resource Group | Contains all bootstrap resources |
| State Storage Account | Holds Terraform remote state; VNet-restricted with private endpoint |
| State Blob Container (`tfstate`) | Container for `.tfstate` files |
| Virtual Network | Network boundary for private endpoints |
| Subnet | Subnet with `Microsoft.Storage` service endpoint |
| Private DNS Zone (`privatelink.blob.core.windows.net`) | DNS resolution for private endpoints |
| Private DNS Zone VNet Link | Links the DNS zone to the VNet |
| State Storage Private Endpoint | Private endpoint for the state storage account |
| Project Storage Accounts (N) | One per entry in `storage_account_names`, each with private endpoint and tfstate container |

## CI/CD Pipelines

### `bootstrap-setup.yml` — One-Time Setup

| Trigger | What it does |
|---------|-------------|
| `workflow_dispatch` (manual) | Creates state backend via CLI → imports into Terraform → applies full config |

Run this **once** to bootstrap the repository. Safe to re-run — all steps are idempotent.

### `bootstrap-ci.yml` — Pull Request Validation

| Trigger | What it does |
|---------|-------------|
| PR to `main` (paths: `terraform/bootstrap/**`) | Format check → validate → plan → post PR comment |

### `bootstrap-cd.yml` — Continuous Deployment

| Trigger | What it does |
|---------|-------------|
| Push to `main` / `workflow_dispatch` | Plan → approval gate (`bootstrap-apply` environment) → apply |

### Runner Network Access

All three workflows follow the same pattern for accessing the VNet-restricted state storage:

1. **Azure Login** — authenticates the runner
2. **Add runner IP** — `curl -s https://api.ipify.org` gets the public IP, `az storage account network-rule add` allows it through the firewall, then waits 30s for propagation
3. **Terraform operations** — init, plan, apply, etc.
4. **Remove runner IP** — `az storage account network-rule remove` with `if: always()` guarantees cleanup even on failure

## Modules

### `modules/azurerm/resource_group`

Creates an Azure Resource Group.

### `modules/azurerm/virtual_network`

Creates an Azure Virtual Network.

### `modules/azurerm/subnet`

Creates a subnet with configurable service endpoints.

### `modules/azurerm/private_dns_zone`

Creates an Azure Private DNS Zone.

### `modules/azurerm/private_dns_zone_virtual_network_link`

Links a Private DNS Zone to a Virtual Network.

### `modules/azurerm/storage_account`

Creates an Azure Storage Account with:
- Private endpoint for blob access
- `tfstate` blob container
- VNet network rules (deny by default)
- Private DNS zone integration

