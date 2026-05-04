# 🎮 Nicky's Game Lounge — Azure Deployment Guide

**Platform:** macOS ARM64 (Apple Silicon M4 Max)
**Target:** Azure App Service (Linux, Node.js 20)

---

## Quick Start (TL;DR)

```bash
	# 1. Install Azure CLI (one-time)
brew install azure-cli

# 2. Extract the project
tar xzf nickys-game-lounge.tar.gz

# 3. Run the deploy script
chmod +x deploy-azure.sh
./deploy-azure.sh

# 4. Open your site
open https://nickys-game-lounge.azurewebsites.net
```

That's it! The script handles everything. Details below if you want to customize.

---

## Prerequisites

### Azure CLI (ARM64 native)

```bash
# Install via Homebrew — this gets you the native ARM64 build
brew update
brew install azure-cli

# Verify installation
az --version
# Should show: azure-cli 2.x.x (arm64)
```

### Node.js (for local testing only — not required for deploy)

```bash
brew install node@20
```

---

## What the Script Does

| Step | What                      | Azure Resource                  |
| ---- | ------------------------- | ------------------------------- |
| 1    | Authenticates via browser | —                              |
| 2    | Creates resource group    | `rg-nickys-game-lounge`       |
| 3    | Creates App Service Plan  | `plan-nickys-games` (Free F1) |
| 4    | Creates Web App           | `nickys-game-lounge`          |
| 5    | Sets Node.js config       | Environment variables           |
| 6    | Zips & deploys code       | Zip deploy                      |
| 7    | Verifies site is live     | Health check                    |

---

## Configuration

Edit the top of `deploy-azure.sh` to customize:

```bash
RESOURCE_GROUP="rg-nickys-game-lounge"
LOCATION="canadacentral"        # Change region if needed
APP_NAME="nickys-game-lounge"   # Must be globally unique
SKU="F1"                        # F1=Free, B1=Basic (~$13/mo)
```

### Available Regions (close to Canada)

- `canadacentral` — Toronto
- `canadaeast` — Quebec City
- `eastus` — Virginia
- `eastus2` — Virginia

### Pricing Tiers

| SKU    | Name     | Cost    | Notes                                |
| ------ | -------- | ------- | ------------------------------------ |
| `F1` | Free     | $0      | 60 min CPU/day, no custom domain SSL |
| `B1` | Basic    | ~$13/mo | Custom domains, always on            |
| `S1` | Standard | ~$73/mo | Auto-scale, staging slots            |

---

## If the App Name is Taken

Azure App Service names must be globally unique. If `nickys-game-lounge` is taken:

```bash
# Check availability
az webapp list --query "[?name=='nickys-game-lounge']" --output table

# Just change APP_NAME in the script, e.g.:
APP_NAME="nickys-game-lounge-2025"
```

---

## Post-Deployment Commands

```bash
# Stream live logs (great for debugging)
az webapp log tail \
    --name nickys-game-lounge \
    --resource-group rg-nickys-game-lounge

# Restart the app
az webapp restart \
    --name nickys-game-lounge \
    --resource-group rg-nickys-game-lounge

# Quick redeploy after code changes
cd nickys-game-lounge
zip -r ../deploy.zip . -x 'node_modules/*'
az webapp deploy \
    --name nickys-game-lounge \
    --resource-group rg-nickys-game-lounge \
    --src-path ../deploy.zip \
    --type zip

# Open in browser
open https://nickys-game-lounge.azurewebsites.net

# SSH into the container
az webapp ssh \
    --name nickys-game-lounge \
    --resource-group rg-nickys-game-lounge
```

---

## Adding a Custom Domain

```bash
# 1. Add the domain
az webapp config hostname add \
    --webapp-name nickys-game-lounge \
    --resource-group rg-nickys-game-lounge \
    --hostname www.nickysgamelounge.com

# 2. Bind SSL (requires B1 tier or higher)
az webapp config ssl bind \
    --name nickys-game-lounge \
    --resource-group rg-nickys-game-lounge \
    --certificate-thumbprint <THUMBPRINT> \
    --ssl-type SNI
```

---

## Tear Down (Delete Everything)

```bash
# This deletes the resource group and ALL resources inside it
az group delete --name rg-nickys-game-lounge --yes --no-wait
```

---

## Troubleshooting

**App shows "Application Error" page**

```bash
# Check the logs
az webapp log tail --name nickys-game-lounge --resource-group rg-nickys-game-lounge

# Common fix: restart
az webapp restart --name nickys-game-lounge --resource-group rg-nickys-game-lounge
```

**Slow cold start on Free tier**

- F1 tier shuts down after ~20 min of inactivity
- First request after idle takes 10-30 seconds
- Upgrade to B1 and enable "Always On" to fix this

**Deploy fails with "conflict" error**

- The app name is taken globally — change `APP_NAME` in the script

**Node modules not installing**

- Ensure `SCM_DO_BUILD_DURING_DEPLOYMENT=true` is set (the script does this)
- Check Kudu build logs: `https://nickys-game-lounge.scm.azurewebsites.net`
