#!/bin/bash
# =============================================================================
# TERRAFORM STATE BACKEND SETUP SCRIPT
# Creates Azure Storage Account for Terraform state management
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP_NAME="${TF_BACKEND_RG:-tfstate-rg}"
STORAGE_ACCOUNT_NAME="${TF_BACKEND_SA:-tfstate$(openssl rand -hex 4)}"
CONTAINER_NAME="${TF_BACKEND_CONTAINER:-tfstate}"
LOCATION="${TF_BACKEND_LOCATION:-eastus2}"

echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}Terraform Backend Setup${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
echo "Resource Group: $RESOURCE_GROUP_NAME"
echo "Storage Account: $STORAGE_ACCOUNT_NAME"
echo "Container: $CONTAINER_NAME"
echo "Location: $LOCATION"
echo ""

# Check if logged in to Azure
echo -e "${YELLOW}Checking Azure login status...${NC}"
if ! az account show &>/dev/null; then
    echo -e "${RED}Not logged in to Azure. Please run 'az login' first.${NC}"
    exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo -e "${GREEN}Using subscription: $SUBSCRIPTION_ID${NC}"

# Create resource group
echo -e "${YELLOW}Creating resource group...${NC}"
az group create \
    --name "$RESOURCE_GROUP_NAME" \
    --location "$LOCATION" \
    --tags "Purpose=TerraformState" "ManagedBy=Script" \
    --output none

echo -e "${GREEN}Resource group created: $RESOURCE_GROUP_NAME${NC}"

# Create storage account with security best practices
# NOTE: Created with Allow initially, locked down after container creation
echo -e "${YELLOW}Creating storage account...${NC}"
az storage account create \
    --name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --location "$LOCATION" \
    --sku Standard_ZRS \
    --kind StorageV2 \
    --https-only true \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --allow-shared-key-access true \
    --default-action Allow \
    --tags "Purpose=TerraformState" "ManagedBy=Script" \
    --output none

echo -e "${GREEN}Storage account created: $STORAGE_ACCOUNT_NAME${NC}"

# Enable versioning for state file protection
echo -e "${YELLOW}Enabling blob versioning...${NC}"
az storage account blob-service-properties update \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --enable-versioning true \
    --enable-delete-retention true \
    --delete-retention-days 30 \
    --output none

echo -e "${GREEN}Blob versioning enabled${NC}"

# Get storage account key
STORAGE_KEY=$(az storage account keys list \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --query '[0].value' \
    --output tsv)

# Create container
echo -e "${YELLOW}Creating blob container...${NC}"
az storage container create \
    --name "$CONTAINER_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --account-key "$STORAGE_KEY" \
    --output none

echo -e "${GREEN}Container created: $CONTAINER_NAME${NC}"

# Add current user's IP to firewall
echo -e "${YELLOW}Adding current IP to storage firewall...${NC}"
CURRENT_IP=$(curl -s https://api.ipify.org)
az storage account network-rule add \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --ip-address "$CURRENT_IP" \
    --output none 2>/dev/null || true

echo -e "${GREEN}Added IP $CURRENT_IP to firewall${NC}"

# Now lock down the storage account
echo -e "${YELLOW}Locking down storage account network access...${NC}"
az storage account update \
    --name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --default-action Deny \
    --output none

echo -e "${GREEN}Storage account network access locked down${NC}"

# Enable resource lock
echo -e "${YELLOW}Creating delete lock...${NC}"
az lock create \
    --name "tfstate-lock" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --lock-type CanNotDelete \
    --notes "Protect Terraform state storage" \
    --output none

echo -e "${GREEN}Delete lock created${NC}"

# Output configuration
echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}Backend Configuration Complete!${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
echo "Add these to your GitHub repository:"
echo ""
echo "Repository Variables (Settings > Secrets and variables > Actions > Variables):"
echo "  TF_BACKEND_RESOURCE_GROUP = $RESOURCE_GROUP_NAME"
echo "  TF_BACKEND_STORAGE_ACCOUNT = $STORAGE_ACCOUNT_NAME"
echo ""
echo "For local development, add to your backend.tf:"
echo ""
echo "terraform {"
echo "  backend \"azurerm\" {"
echo "    resource_group_name  = \"$RESOURCE_GROUP_NAME\""
echo "    storage_account_name = \"$STORAGE_ACCOUNT_NAME\""
echo "    container_name       = \"$CONTAINER_NAME\""
echo "    key                  = \"<env>/terraform.tfstate\""
echo "  }"
echo "}"
echo ""
echo -e "${GREEN}Done!${NC}"
