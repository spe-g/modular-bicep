# Modular Bicep: Subscription-scope Deployment

This folder contains a subscription-scope Bicep deployment:
- `main.bicep` orchestrates modules and creates the target resource group at subscription scope.
- `.bicepparam` files hold all template parameters under `bicepparams/`: `dev.bicepparam` and `prod.bicepparam`.
- `deploy.sh` runs the deployment using Azure CLI with no parameters passed in the script.

## Prerequisites
- Azure CLI installed and signed in: `az login`
- Appropriate subscription selected: `az account set --subscription <SUBSCRIPTION_ID_OR_NAME>` (optional)
- Bash shell (WSL, Git Bash, or Azure Cloud Shell). On Windows PowerShell, use WSL/Git Bash to run the script.

## Deploy
The script deploys at subscription scope (required when creating a resource group in the template).

Quick start (runs dev then prod if both param files exist):
```bash
cd /mnt/c/Users/EsperlynGuanco/Codes/modular-bicep
chmod +x ./deploy.sh
./deploy.sh --location eastus
```

Run a single environment:
```bash
# dev only
./deploy.sh --only dev --location eastus
# prod only
./deploy.sh --only prod --location eastus
```

Run with a custom .bicepparam file:
```bash
./deploy.sh --param ./bicepparams/prod.bicepparam --location westeurope --name custom-$(date +%Y%m%d)
```

Flags:
- `--location, -l` Azure region for the subscription deployment record (required)
- `--only, -o` dev | prod (optional)
- `--param, -p` path to a single .bicepparam to deploy once (optional)
- `--name, -n` base deployment name; script appends `-dev`/`-prod` (optional)
- Env var: `AZ_DEPLOYMENT_LOCATION` can be used instead of `--location`

## Expected output
- The script prints lines like:
  - `=== Submitting deployment: bicep-deploy-YYYYMMDDHHMMSS-dev | Params: dev.bicepparam ===`
  - Azure CLI JSON with a top-level `properties.provisioningState`.
- Success indicator: `"provisioningState": "Succeeded"` appears in the CLI output for each deployment and the script prints a completion note.
- Two subscription-scope deployments may be created (when running both): `<base>-dev` and `<base>-prod`.
- The template creates the resource group defined by your parameters and then deploys networking and a VM inside it.

## Troubleshooting
- Missing param file: ensure `dev.bicepparam` / `prod.bicepparam` exist or use `--param` with a valid path.
- Not logged in: run `az login` and re-try.
- Wrong scope errors: the script uses `az deployment sub create` because `main.bicep` manages a resource group. Do not use `az deployment group create` for this template.
- Location required: pass `--location <region>` or export `AZ_DEPLOYMENT_LOCATION`.

## Notes
- The script intentionally does not pass template parameters; all values come from your `.bicepparam` files.
- To switch subscriptions, use `az account set` before running the script.
