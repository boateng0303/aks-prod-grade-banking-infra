#!/bin/bash
# =============================================================================
# AZURE OIDC SETUP FOR GITHUB ACTIONS
# Creates Azure AD App Registration and Federated Credentials
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
APP_NAME="${APP_NAME:-github-actions-terraform}"
GITHUB_ORG="${GITHUB_ORG:-}"
GITHUB_REPO="${GITHUB_REPO:-}"

echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}Azure OIDC Setup for GitHub Actions${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""

# Check required inputs
if [ -z "$GITHUB_ORG" ] || [ -z "$GITHUB_REPO" ]; then
    echo -e "${YELLOW}Usage: GITHUB_ORG=<org> GITHUB_REPO=<repo> ./setup-oidc.sh${NC}"
    echo ""
    read -p "Enter GitHub Organization/Username: " GITHUB_ORG
    read -p "Enter GitHub Repository Name: " GITHUB_REPO
fi

echo "GitHub Repository: $GITHUB_ORG/$GITHUB_REPO"
echo "App Name: $APP_NAME"
echo ""

# Check Azure login
if ! az account show &>/dev/null; then
    echo -e "${RED}Not logged in to Azure. Please run 'az login' first.${NC}"
    exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

# Explicitly set the subscription context
echo -e "${YELLOW}Setting subscription context...${NC}"
az account set --subscription "$SUBSCRIPTION_ID"

echo -e "${GREEN}Subscription: $SUBSCRIPTION_ID${NC}"
echo -e "${GREEN}Tenant: $TENANT_ID${NC}"
echo ""

# Create Azure AD Application
echo -e "${YELLOW}Creating Azure AD Application...${NC}"
APP_ID=$(az ad app create \
    --display-name "$APP_NAME" \
    --query appId \
    --output tsv)

echo -e "${GREEN}Application created: $APP_ID${NC}"

# Create Service Principal
echo -e "${YELLOW}Creating Service Principal...${NC}"
SP_ID=$(az ad sp create \
    --id "$APP_ID" \
    --query id \
    --output tsv)

echo -e "${GREEN}Service Principal created: $SP_ID${NC}"

# Wait for propagation
echo -e "${YELLOW}Waiting for Azure AD propagation...${NC}"
sleep 30

# Assign Contributor role at subscription level
echo -e "${YELLOW}Assigning Contributor role...${NC}"
az role assignment create \
    --assignee-object-id "$SP_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "Contributor" \
    --scope "/subscriptions/$SUBSCRIPTION_ID" \
    --output none

echo -e "${GREEN}Contributor role assigned${NC}"

# Assign User Access Administrator for RBAC assignments
echo -e "${YELLOW}Assigning User Access Administrator role...${NC}"
az role assignment create \
    --assignee-object-id "$SP_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "User Access Administrator" \
    --scope "/subscriptions/$SUBSCRIPTION_ID" \
    --output none

echo -e "${GREEN}User Access Administrator role assigned${NC}"

# Create Federated Credentials for main branch
echo -e "${YELLOW}Creating federated credential for main branch...${NC}"
az ad app federated-credential create \
    --id "$APP_ID" \
    --parameters "{
        \"name\": \"github-main\",
        \"issuer\": \"https://token.actions.githubusercontent.com\",
        \"subject\": \"repo:$GITHUB_ORG/$GITHUB_REPO:ref:refs/heads/main\",
        \"description\": \"GitHub Actions - main branch\",
        \"audiences\": [\"api://AzureADTokenExchange\"]
    }" \
    --output none

echo -e "${GREEN}Federated credential created for main branch${NC}"

# Create Federated Credentials for pull requests
echo -e "${YELLOW}Creating federated credential for pull requests...${NC}"
az ad app federated-credential create \
    --id "$APP_ID" \
    --parameters "{
        \"name\": \"github-pr\",
        \"issuer\": \"https://token.actions.githubusercontent.com\",
        \"subject\": \"repo:$GITHUB_ORG/$GITHUB_REPO:pull_request\",
        \"description\": \"GitHub Actions - Pull Requests\",
        \"audiences\": [\"api://AzureADTokenExchange\"]
    }" \
    --output none

echo -e "${GREEN}Federated credential created for pull requests${NC}"

# Create Federated Credentials for environments
for ENV in dev staging production; do
    echo -e "${YELLOW}Creating federated credential for $ENV environment...${NC}"
    az ad app federated-credential create \
        --id "$APP_ID" \
        --parameters "{
            \"name\": \"github-env-$ENV\",
            \"issuer\": \"https://token.actions.githubusercontent.com\",
            \"subject\": \"repo:$GITHUB_ORG/$GITHUB_REPO:environment:$ENV\",
            \"description\": \"GitHub Actions - $ENV environment\",
            \"audiences\": [\"api://AzureADTokenExchange\"]
        }" \
        --output none 2>/dev/null || echo "  (skipped - may already exist)"
done

echo -e "${GREEN}Federated credentials created for environments${NC}"

# Output configuration
echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}OIDC Setup Complete!${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
echo "Add these secrets to your GitHub repository:"
echo "(Settings > Secrets and variables > Actions > Secrets)"
echo ""
echo "  AZURE_CLIENT_ID = $APP_ID"
echo "  AZURE_TENANT_ID = $TENANT_ID"
echo "  AZURE_SUBSCRIPTION_ID = $SUBSCRIPTION_ID"
echo ""
echo "Note: No client secret is needed with OIDC!"
echo ""
echo -e "${GREEN}Done!${NC}"
