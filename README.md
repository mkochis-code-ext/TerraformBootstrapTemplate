# TerraformBootstrapTemplate

A Terraform repository demonstrating how to create and set up a bootstrap repo for Terraform state management using Azure.

## Repository Structure

```
.github/
└── workflows/
    ├── prereq.yml           # CI/CD pipeline for prereq (plan on PRs; plan→approve→apply on push/dispatch)
    ├── bootstrap-ci.yml     # CI pipeline for bootstrap (plan only on PRs)
    └── bootstrap-cd.yml     # CD pipeline for bootstrap (plan→approve→apply on push/dispatch)
terraform/
├── prereq/                          # One-time setup: deploys the Terraform state storage account (no backend)
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── bootstrap/                       # Main infrastructure entry point: uses remote state backend
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
└── modules/
    └── azurerm/
        ├── resource_group/          # Reusable resource group module
        │   ├── main.tf
        │   ├── outputs.tf
        │   └── variables.tf
        └── storage_account/         # Reusable storage account module (includes tfstate container)
            ├── main.tf
            ├── outputs.tf
            └── variables.tf
```

## Getting Started

### Step 1: Deploy the Prerequisites (`prereq`)

The `prereq` folder contains a standalone Terraform configuration that deploys a single Azure Storage Account for Terraform remote state. It uses **no remote backend** — its state is stored locally and must not be committed.

The storage account name is derived automatically from your project name:

```
stpreq<project_name>
```

For example, `project_name = "myproject"` → storage account `stpreqmyproject`.

1. Navigate to the `prereq` folder:
   ```bash
   cd terraform/prereq
   ```

2. Copy and fill in the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
   Required variables (no defaults — must be set):
   | Variable               | Description                                                   |
   |------------------------|---------------------------------------------------------------|
   | `project_name`         | 1–16 lowercase alphanumeric chars; used to name the storage account |
   | `resource_group_name`  | Name of the resource group for the storage account            |
   | `location`             | Azure region                                                  |

3. Initialize and apply:
   ```bash
   terraform init
   terraform apply
   ```

4. Note the `storage_account_name` and `resource_group_name` outputs for the next step.

### Step 2: Configure the Bootstrap Entry Point (`bootstrap`)

The `bootstrap` folder is the main infrastructure entry point. It uses the storage account created in Step 1 as its remote backend, and manages bootstrap-level storage accounts via `for_each`.

The backend is configured at init time via `-backend-config` flags (see CI/CD workflows). For local usage:

```bash
cd terraform/bootstrap
cp terraform.tfvars.example terraform.tfvars
terraform init \
  -backend-config="resource_group_name=<prereq_resource_group>" \
  -backend-config="storage_account_name=<prereq_storage_account>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=bootstrap.terraform.tfstate"
terraform apply
```

Required variables (no defaults — must be set):
| Variable                | Description                                                           |
|-------------------------|-----------------------------------------------------------------------|
| `storage_account_names` | Set of storage account names to create (one per item, tracked independently) |
| `resource_group_name`   | Resource group to deploy the storage accounts into                    |
| `location`              | Azure region                                                          |

## CI/CD Pipelines

All pipelines authenticate to Azure using the `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_SUBSCRIPTION_ID`, and `ARM_TENANT_ID` repository secrets.

### Prereq pipeline (`prereq.yml`)

| Trigger               | Jobs run                                         |
|-----------------------|--------------------------------------------------|
| `workflow_dispatch` (manual only) | **CD Plan** → approval gate → **CD Apply** |

The approval gate is enforced by the **`prereq-apply`** GitHub environment (configure required reviewers in *Settings → Environments*).

Secrets required:
| Secret                       | Description                                  |
|------------------------------|----------------------------------------------|
| `PREREQ_PROJECT_NAME`        | Value for `var.project_name`                 |
| `PREREQ_RESOURCE_GROUP_NAME` | Value for `var.resource_group_name`          |
| `PREREQ_LOCATION`            | Value for `var.location`                     |

### Bootstrap CI pipeline (`bootstrap-ci.yml`)

| Trigger               | Jobs run                                         |
|-----------------------|--------------------------------------------------|
| Pull request to `main`| **CI Plan** — fmt check, validate, plan, PR comment |

### Bootstrap CD pipeline (`bootstrap-cd.yml`)

| Trigger               | Jobs run                                         |
|-----------------------|--------------------------------------------------|
| Push to `main` / `workflow_dispatch` | **CD Plan** → approval gate → **CD Apply** |

The approval gate is enforced by the **`bootstrap-apply`** GitHub environment.

Secrets required for both Bootstrap pipelines:
| Secret                              | Description                                             |
|-------------------------------------|---------------------------------------------------------|
| `TF_STATE_STORAGE_ACCOUNT`          | Prereq storage account name (from Step 1 output)        |
| `TF_STATE_RESOURCE_GROUP`           | Prereq resource group name (from Step 1 output)         |
| `BOOTSTRAP_LOCATION`                | Value for `var.location`                                |
| `BOOTSTRAP_RESOURCE_GROUP_NAME`     | Value for `var.resource_group_name`                     |
| `BOOTSTRAP_STORAGE_ACCOUNT_NAMES`   | JSON array of storage account names, e.g. `["st1","st2"]` |

## Modules

### `modules/azurerm/resource_group`

Creates an Azure Resource Group.

| Variable   | Description          | Type          | Required |
|------------|----------------------|---------------|----------|
| `name`     | Resource group name  | `string`      | Yes      |
| `location` | Azure region         | `string`      | Yes      |
| `tags`     | Tags for the resource| `map(string)` | No       |

### `modules/azurerm/storage_account`

Creates an Azure Storage Account with a single blob container named `tfstate`.

| Variable               | Description                                     | Type          | Required |
|------------------------|-------------------------------------------------|---------------|----------|
| `name`                 | Storage account name (globally unique, 3-24 chars) | `string`  | Yes      |
| `resource_group_name`  | Resource group to deploy into                   | `string`      | Yes      |
| `location`             | Azure region                                    | `string`      | Yes      |
| `tags`                 | Tags for the resource                           | `map(string)` | No       |

