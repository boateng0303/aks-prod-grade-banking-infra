# Reuel Banking Infrastructure

Enterprise-grade Azure infrastructure for the Reuel Banking application, built with Terraform following Infrastructure as Code (IaC) best practices.

![Reuel Banking Architecture](./Images/Secure%20Bank%20Architecture.gif)

## Overview

This repository contains the complete Azure infrastructure configuration for deploying a secure, scalable banking application. The infrastructure supports a DevSecOps pipeline with comprehensive monitoring, security scanning, and multi-environment deployments.

### Key Features

- **Multi-Environment Support**: Separate configurations for Development, Staging, and Production
- **Modular Architecture**: Reusable Terraform modules for consistent deployments
- **Security-First Design**: Private endpoints, Key Vault integration, network isolation
- **Comprehensive Monitoring**: Log Analytics, Application Insights, and metric alerts
- **GitOps Ready**: OIDC authentication for GitHub Actions CI/CD pipelines
- **Cost Optimization**: Configurable SKUs and optional components per environment

## Architecture

| Component | Description |
|-----------|-------------|
| **Azure Kubernetes Service (AKS)** | Managed Kubernetes cluster with workload identity, Azure RBAC, and Microsoft Defender |
| **Azure Container Registry (ACR)** | Private container registry with geo-replication (Premium) |
| **Azure Key Vault** | Secrets management with RBAC authorization |
| **Virtual Network** | Isolated network with dedicated subnets for AKS, databases, and private endpoints |
| **Log Analytics Workspace** | Centralized logging with Container Insights |
| **Application Insights** | Application performance monitoring |
| **NAT Gateway** | Outbound internet connectivity for AKS |
| **Azure Bastion** | Secure VM access (Production only) |

## Project Structure

```
Infrastructure/
└── azure/
    ├── environments/
    │   ├── dev/                    # Development environment
    │   │   ├── backend.tf          # Terraform state backend config
    │   │   ├── main.tf             # Main infrastructure definition
    │   │   ├── variables.tf        # Input variables
    │   │   ├── outputs.tf          # Output values
    │   │   └── terraform.tfvars    # Variable values
    │   ├── staging/                # Staging environment
    │   └── prod/                   # Production environment
    ├── modules/
    │   ├── aks/                    # Azure Kubernetes Service module
    │   ├── acr/                    # Azure Container Registry module
    │   ├── keyvault/               # Azure Key Vault module
    │   ├── monitoring/             # Log Analytics, App Insights, Alerts
    │   ├── networking/             # VNet, Subnets, NSGs, NAT Gateway
    │   └── resource-group/         # Resource Group with optional locks
    └── scripts/
        ├── setup-backend.sh        # Create Terraform state storage
        └── setup-oidc.sh           # Configure GitHub Actions OIDC
```

## Prerequisites

Install these tools on your **local machine**:

- [Terraform](https://www.terraform.io/downloads) >= 1.5.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.50.0
- [Git](https://git-scm.com/downloads)
- Azure subscription with required permissions:
  - Contributor (for resource creation)
  - User Access Administrator (for RBAC assignments)
- GitHub account (for CI/CD)

## Getting Started

> **Note**: All commands in this section are run on your **local machine** unless otherwise specified.

### 1. Clone the Repository

Run on your **local machine**:

```bash
git clone https://github.com/your-org/reuel-banking-infra.git
cd reuel-banking-infra/Infrastructure/azure
```

### 2. Authenticate with Azure

Run on your **local machine** to authenticate with your Azure subscription:

```bash
az login
az account set --subscription "<subscription-id>"
```

### 3. Setup Terraform Backend (One-Time Setup)

Run on your **local machine** to create an Azure Storage Account for Terraform state management:

```bash
# Set environment variables (optional)
export TF_BACKEND_RG="tfstate-rg"
export TF_BACKEND_LOCATION="eastus"

# Run the setup script
chmod +x scripts/setup-backend.sh
./scripts/setup-backend.sh
```

This creates the following resources in your Azure subscription:
- Resource Group for state storage
- Storage Account with versioning and soft delete
- Blob container for state files
- Network rules and delete locks for protection

The script will output values you'll need for the next steps.

### 4. Setup GitHub Actions OIDC (One-Time Setup)

Run on your **local machine** to configure passwordless authentication for CI/CD:

```bash
# Replace with your GitHub organization/username and repository name
export GITHUB_ORG="your-org"
export GITHUB_REPO="reuel-banking-infra"

chmod +x scripts/setup-oidc.sh
./scripts/setup-oidc.sh
```

This script creates Azure AD resources that allow GitHub Actions to authenticate without storing secrets.

**After the script completes**, go to your **GitHub repository** (in your browser):
1. Navigate to **Settings** > **Secrets and variables** > **Actions**
2. Add these repository secrets with the values from the script output:
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`

### 5. Deploy Infrastructure

Run on your **local machine** (or via CI/CD pipeline after setup):

```bash
cd environments/dev

# Initialize Terraform (replace <storage-account> with your actual storage account name from step 3)
terraform init \
  -backend-config="resource_group_name=tfstate-rg" \
  -backend-config="storage_account_name=<storage-account>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=dev/terraform.tfstate"

# Review the plan
terraform plan -out=tfplan

# Apply the configuration
terraform apply tfplan
```

> **Tip**: After initial setup, you can let GitHub Actions handle deployments automatically when you push to `main`.

## Environment Comparison

| Feature | Dev | Staging | Prod |
|---------|-----|---------|------|
| AKS SKU Tier | Free | Standard | Premium |
| AKS Private Cluster | ❌ | ✅ | ✅ |
| ACR SKU | Standard | Premium | Premium |
| ACR Private Endpoint | ❌ | ✅ | ✅ |
| ACR Geo-Replication | ❌ | ❌ | ✅ |
| Key Vault SKU | Standard | Standard | Premium |
| Key Vault Purge Protection | ❌ | ✅ | ✅ |
| Log Retention (days) | 30 | 60 | 365 |
| Security Insights | ❌ | ❌ | ✅ |
| Azure Bastion | ❌ | ❌ | ✅ |
| Azure Policy | ❌ | ✅ | ✅ |
| Recovery Services Vault | ❌ | ❌ | ✅ |

## Terraform Modules

### AKS Module (`modules/aks/`)

Deploys Azure Kubernetes Service with:
- User-assigned managed identity
- System, User, and Spot node pools (configurable)
- Azure AD RBAC integration
- Workload identity support
- Key Vault secrets provider
- Microsoft Defender for Containers
- OMS agent for monitoring

### ACR Module (`modules/acr/`)

Deploys Azure Container Registry with:
- Configurable SKU (Basic, Standard, Premium)
- Private endpoint support
- Geo-replication (Premium)
- Content trust and retention policies
- Scope maps for granular access
- Webhook support

### Key Vault Module (`modules/keyvault/`)

Deploys Azure Key Vault with:
- RBAC or access policy authorization
- Private endpoint support
- Soft delete and purge protection
- Network ACLs
- Diagnostic settings

### Monitoring Module (`modules/monitoring/`)

Deploys comprehensive monitoring:
- Log Analytics Workspace
- Container Insights solution
- Security Insights (optional)
- Application Insights
- Action groups for alerts (email, SMS, webhook/Slack)
- Metric alerts for AKS and MySQL
- Log query alerts for container restarts and errors
- Azure Portal dashboard

### Networking Module (`modules/networking/`)

Deploys network infrastructure:
- Virtual Network with configurable address space
- Subnets: AKS, Database, Application Gateway, Private Endpoints, Bastion
- Network Security Groups with security rules
- NAT Gateway for outbound connectivity
- Private DNS Zones for Azure services

### Resource Group Module (`modules/resource-group/`)

Deploys Azure Resource Group with:
- Configurable location and tags
- Optional delete lock for production protection

## Configuration

### Input Variables

Key variables to configure in `terraform.tfvars`:

```hcl
project_name = "banking"
location     = "eastus"
cost_center  = "development"
owner_email  = "devops@company.com"

kubernetes_version = "1.32"

# Azure AD group IDs for AKS administrators
aks_admin_group_ids = ["<group-id>"]

# Object IDs for Key Vault administrators
keyvault_admin_object_ids = ["<object-id>"]

# Alert receivers
alert_email_receivers = [
  {
    name  = "DevOps Team"
    email = "devops@company.com"
  }
]
```

### Environment Variables

For sensitive values, set these on your **local machine** before running Terraform:

```bash
export TF_VAR_slack_webhook_url="https://hooks.slack.com/..."
```

For **GitHub Actions CI/CD**, add these as repository secrets instead:
- `SLACK_WEBHOOK_URL` - For Slack alert notifications

The `ARM_USE_OIDC=true` variable is automatically set in GitHub Actions workflows when using OIDC authentication.

## Outputs

After deployment, run these commands on your **local machine** to retrieve important values:

```bash
# Navigate to the environment directory
cd Infrastructure/azure/environments/dev

# Get the command to configure kubectl
terraform output get_credentials_command

# Example output:
# az aks get-credentials --resource-group banking-dev-rg --name banking-dev-aks

# View other outputs
terraform output resource_group_name
terraform output aks_cluster_name
terraform output acr_login_server
terraform output keyvault_uri
```

To connect to the AKS cluster, run the output command on your **local machine**:

```bash
az aks get-credentials --resource-group banking-dev-rg --name banking-dev-aks
kubectl get nodes  # Verify connection
```

## Security Features

### Network Security
- **Private AKS clusters** (Staging/Prod) with no public API access
- **Private endpoints** for ACR and Key Vault
- **Network Security Groups** with least-privilege rules
- **NAT Gateway** for controlled outbound traffic
- **Service endpoints** for Azure services

### Identity & Access
- **Azure RBAC** for AKS authorization
- **Workload Identity** for pod-level Azure access
- **Managed Identities** (no stored credentials)
- **OIDC federation** for GitHub Actions (no secrets)

### Secrets Management
- **Azure Key Vault** for centralized secrets
- **Key Vault secrets provider** for AKS
- **Automatic secret rotation**

### Compliance
- **Microsoft Defender** for container security
- **Azure Policy** for governance (Staging/Prod)
- **Audit logging** to Log Analytics
- **PCI-DSS** compliance tagging (Production)

## Monitoring & Alerting

### Built-in Alerts

| Alert | Description | Severity |
|-------|-------------|----------|
| AKS CPU High | Node CPU > 80% | Warning |
| AKS Memory High | Node memory > 85% | Warning |
| AKS Node Not Ready | Nodes in NotReady state | Critical |
| Container Restarts | Pods restarting > 10 times | Warning |
| Application Errors | Error count > 50 in 15min | Warning |
| MySQL CPU High | CPU > 80% | Warning |
| MySQL Storage Low | Storage > 80% | Warning |

### Alert Channels

- Email notifications
- SMS alerts (Production)
- Slack webhooks
- Custom webhooks (PagerDuty, etc.)

## CI/CD Integration

> **Note**: This section describes automated workflows that run on **GitHub Actions** (not your local machine). You create these workflow files locally and push them to your repository.

This infrastructure is designed to work with GitHub Actions. Create a file `.github/workflows/terraform.yml` in your repository:

```yaml
# This runs on GitHub Actions, NOT on your local machine
name: Terraform Apply

on:
  push:
    branches: [main]

jobs:
  apply:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.5.0
      
      - name: Terraform Apply
        working-directory: Infrastructure/azure/environments/dev
        run: |
          terraform init -backend-config=...
          terraform apply -auto-approve
```

### Infracost Integration

Enable cost estimation in Pull Requests to see infrastructure cost changes before merging:

1. Get your API key from [infracost.io](https://www.infracost.io/)
2. Go to your **GitHub repository** (in your browser):
   - Navigate to **Settings** > **Secrets and variables** > **Actions**
   - Add a new repository secret: `INFRACOST_API_KEY`

Once configured, Infracost will automatically comment on PRs with cost breakdowns showing:
- Monthly cost estimate for new infrastructure
- Cost difference compared to the current state
- Detailed breakdown by resource

## Troubleshooting

> **Note**: Run these troubleshooting commands on your **local machine**.

### Common Issues

**State Lock Error** - If Terraform state is locked (e.g., previous run crashed):
```bash
terraform force-unlock <lock-id>
```

**Provider Registration** - If Azure providers are not registered in your subscription:
```bash
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.OperationalInsights
```

**AKS Credential Issues** - If kubectl can't connect to the cluster:
```bash
az aks get-credentials --resource-group <rg> --name <cluster> --overwrite-existing
```

**Permission Denied** - Ensure you have the required roles on your Azure subscription:
```bash
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv) --output table
```

## Contributing

All development work is done on your **local machine**:

1. Create a feature branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. Make changes and test in the `dev` environment
3. Format and validate your Terraform code:
   ```bash
   terraform fmt -recursive
   terraform validate
   ```
4. Commit and push your changes:
   ```bash
   git add .
   git commit -m "Description of changes"
   git push origin feature/your-feature-name
   ```
5. Create a pull request on **GitHub** (in your browser)
6. CI/CD checks will run automatically on GitHub Actions
7. Merge after approval and passing checks

## License

This project is proprietary to Reuel Banking. All rights reserved.

## Support

For issues or questions, contact the DevOps team at devops@company.com.
