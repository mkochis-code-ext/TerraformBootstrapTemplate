# TerraformBootstrapTemplate

A Terraform repository demonstrating how to create and set up a bootstrap repo for Terraform state management using Azure.

## Repository Structure

```
terraform/
├── prereq/                          # One-time setup: deploys storage account for remote state (no backend)
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── bootstrap/                       # Main entry point: connects to remote state backend
│   ├── main.tf
│   ├── variables.tf
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

The `prereq` folder contains a standalone Terraform configuration that deploys the Azure Storage Account used for remote Terraform state. It does **not** use a remote backend — state is stored locally and should not be committed.

1. Navigate to the `prereq` folder:
   ```bash
   cd terraform/prereq
   ```

2. Copy the example variables file and fill in your values:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Initialize and apply:
   ```bash
   terraform init
   terraform apply
   ```

   This will create:
   - (Optionally) a Resource Group for the storage accounts
   - One Storage Account per name in `storage_account_names`, each with a blob container named `tfstate`
   - Each storage account is tracked independently via `for_each`, so adding or removing a name only affects that specific account

4. Note the output values (`storage_account_names`, `resource_group_name`) for the next step.

### Step 2: Configure the Bootstrap Entry Point (`bootstrap`)

The `bootstrap` folder is the main entry point for your Terraform deployments. It uses the storage account created in Step 1 as the remote backend.

1. Navigate to the `bootstrap` folder:
   ```bash
   cd terraform/bootstrap
   ```

2. Update `main.tf` with the backend values from Step 1:
   ```hcl
   backend "azurerm" {
     resource_group_name  = "<your_resource_group_name>"
     storage_account_name = "<your_storage_account_name>"
     container_name       = "tfstate"
     key                  = "terraform.tfstate"
   }
   ```

3. Copy the example variables file and fill in your values:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

4. Initialize and apply:
   ```bash
   terraform init
   terraform apply
   ```

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
