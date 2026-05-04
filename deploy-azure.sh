#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#  Nicky's Game Lounge — Azure App Service Deployment
#  Platform: macOS ARM64 (Apple Silicon M4 Max)
# ═══════════════════════════════════════════════════════════════
#
#  PREREQUISITES (run these once if you haven't already):
#
#    # Install Homebrew (if not installed)
#    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#
#    # Install Azure CLI (ARM64 native via Homebrew)
#    brew update && brew install azure-cli
#
#    # Verify
#    az --version
#
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# ── Configuration — edit these to suit your needs ──
RESOURCE_GROUP="rg-nickys-game-lounge"
LOCATION="canadacentral"                # Canadian region 🇨🇦
APP_NAME="nickys-game-lounge"           # must be globally unique — adjust if taken
APP_SERVICE_PLAN="plan-nickys-games"
SKU="F1"                                # F1 = Free tier, B1 = Basic ($13/mo)
NODE_VERSION="20-lts"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)" # path to your extracted project

# ── Colours for output ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_step() { echo -e "\n${CYAN}══ $1 ══${NC}"; }
print_ok()   { echo -e "${GREEN}✓ $1${NC}"; }
print_warn() { echo -e "${YELLOW}⚠ $1${NC}"; }

# ═══════════════════════════════════════
#  Step 1: Login to Azure
# ═══════════════════════════════════════
print_step "Step 1: Authenticating with Azure"

if az account show &>/dev/null; then
    CURRENT_ACCOUNT=$(az account show --query name -o tsv)
    print_ok "Already logged in as: $CURRENT_ACCOUNT"
else
    echo "Opening browser for Azure login..."
    az login
fi

# Show current subscription
echo -e "Active subscription: ${GREEN}$(az account show --query '{name:name, id:id}' -o tsv)${NC}"
echo ""
read -p "Use this subscription? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    echo "Available subscriptions:"
    az account list --query '[].{Name:name, ID:id, Default:isDefault}' -o table
    read -p "Enter subscription ID to use: " SUB_ID
    az account set --subscription "$SUB_ID"
    print_ok "Switched to: $(az account show --query name -o tsv)"
fi

# ═══════════════════════════════════════
#  Step 2: Create Resource Group
# ═══════════════════════════════════════
print_step "Step 2: Creating Resource Group"

if az group show --name "$RESOURCE_GROUP" &>/dev/null; then
    print_ok "Resource group '$RESOURCE_GROUP' already exists"
else
    az group create \
        --name "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --output none
    print_ok "Created resource group '$RESOURCE_GROUP' in $LOCATION"
fi

# ═══════════════════════════════════════
#  Step 3: Create App Service Plan
# ═══════════════════════════════════════
print_step "Step 3: Creating App Service Plan"

if az appservice plan show --name "$APP_SERVICE_PLAN" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    print_ok "App Service Plan '$APP_SERVICE_PLAN' already exists"
else
    az appservice plan create \
        --name "$APP_SERVICE_PLAN" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --sku "$SKU" \
        --is-linux \
        --output none
    print_ok "Created Linux App Service Plan ($SKU tier)"
fi

# ═══════════════════════════════════════
#  Step 4: Create Web App
# ═══════════════════════════════════════
print_step "Step 4: Creating Web App"

if az webapp show --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    print_ok "Web App '$APP_NAME' already exists"
else
    az webapp create \
        --name "$APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --plan "$APP_SERVICE_PLAN" \
        --runtime "NODE|$NODE_VERSION" \
        --output none
    print_ok "Created Web App '$APP_NAME'"
fi

# ═══════════════════════════════════════
#  Step 5: Configure App Settings
# ═══════════════════════════════════════
print_step "Step 5: Configuring App Settings"

az webapp config appsettings set \
    --name "$APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --settings \
        WEBSITE_NODE_DEFAULT_VERSION="~20" \
        NODE_ENV="production" \
        PORT="8080" \
        SCM_DO_BUILD_DURING_DEPLOYMENT="true" \
    --output none

# Set startup command
az webapp config set \
    --name "$APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --startup-file "node server.js" \
    --output none

print_ok "App settings configured"

# ═══════════════════════════════════════
#  Step 6: Prepare & Deploy Code
# ═══════════════════════════════════════
print_step "Step 6: Deploying Code"

# Check project directory exists
if [[ ! -d "$PROJECT_DIR" ]]; then
    echo -e "${RED}✗ Project directory '$PROJECT_DIR' not found.${NC}"
    echo "  Make sure you've extracted the tar.gz:"
    echo "    tar xzf nickys-game-lounge.tar.gz"
    exit 1
fi

# Navigate to project
cd "$PROJECT_DIR"

# Create .deployment file for Azure build
cat > .deployment <<EOF
[config]
SCM_DO_BUILD_DURING_DEPLOYMENT=true
EOF

# Create web.config for proper routing (optional fallback)
cat > web.config <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<configuration>
    <system.webServer>
        <handlers>
            <add name="iisnode" path="server.js" verb="*" modules="iisnode"/>
        </handlers>
        <rewrite>
            <rules>
                <rule name="StaticContent">
                    <action type="Rewrite" url="public{REQUEST_URI}"/>
                </rule>
                <rule name="DynamicContent">
                    <conditions>
                        <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="True"/>
                    </conditions>
                    <action type="Rewrite" url="server.js"/>
                </rule>
            </rules>
        </rewrite>
    </system.webServer>
</configuration>
EOF

# Ensure PORT is read from environment in production
# (Azure sets PORT=8080, our server.js already uses process.env.PORT)

# Create zip for deployment (exclude node_modules — Azure will run npm install)
print_warn "Creating deployment package..."
rm -f ../deploy.zip
zip -r ../deploy.zip . \
    -x "node_modules/*" \
    -x ".git/*" \
    -x "*.tar.gz" \
    > /dev/null

print_ok "Deployment package created"

# Deploy via zip deploy
print_warn "Uploading to Azure (this may take 1-2 minutes)..."
az webapp deploy \
    --name "$APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --src-path "../deploy.zip" \
    --type zip \
    --output none

print_ok "Code deployed successfully"

# Go back to original directory
cd - > /dev/null

# ═══════════════════════════════════════
#  Step 7: Verify Deployment
# ═══════════════════════════════════════
print_step "Step 7: Verifying Deployment"

SITE_URL="https://${APP_NAME}.azurewebsites.net"

# Wait a moment for the app to start
echo "Waiting for app to start..."
sleep 10

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$SITE_URL" 2>/dev/null || echo "000")

if [[ "$HTTP_STATUS" == "200" ]]; then
    print_ok "Site is live and returning 200 OK"
else
    print_warn "Site returned HTTP $HTTP_STATUS — it may still be starting up"
    echo "  Azure can take up to 60 seconds for cold start on Free tier"
    echo "  Check logs with: az webapp log tail --name $APP_NAME --resource-group $RESOURCE_GROUP"
fi

# ═══════════════════════════════════════
#  Done!
# ═══════════════════════════════════════
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  🎮 Nicky's Game Lounge is deployed!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "  URL:            ${CYAN}${SITE_URL}${NC}"
echo -e "  Resource Group: ${RESOURCE_GROUP}"
echo -e "  App Service:    ${APP_NAME}"
echo -e "  Region:         ${LOCATION}"
echo -e "  Tier:           ${SKU}"
echo ""
echo -e "  ${YELLOW}Useful commands:${NC}"
echo ""
echo "  # Stream live logs"
echo "  az webapp log tail --name $APP_NAME --resource-group $RESOURCE_GROUP"
echo ""
echo "  # Restart the app"
echo "  az webapp restart --name $APP_NAME --resource-group $RESOURCE_GROUP"
echo ""
echo "  # Redeploy after changes"
echo "  cd $PROJECT_DIR && zip -r ../deploy.zip . -x 'node_modules/*' && \\"
echo "  az webapp deploy --name $APP_NAME --resource-group $RESOURCE_GROUP --src-path ../deploy.zip --type zip"
echo ""
echo "  # Open in browser"
echo "  open $SITE_URL"
echo ""
echo "  # Tear down everything (deletes all resources)"
echo "  az group delete --name $RESOURCE_GROUP --yes --no-wait"
echo ""