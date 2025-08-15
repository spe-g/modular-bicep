#!/usr/bin/env bash
# Purpose: Trigger deployment of main.bicep using .bicepparam files (no template params in the script)
# Notes:
# - Uses subscription-scope deployment since the template deploys a resource group at subscription scope.
# - Requires a deployment location for the subscription deployment record (this is NOT a template parameter).
# - FIX: By default, runs BOTH bicepparams/dev.bicepparam and bicepparams/prod.bicepparam sequentially if present.
# - You can restrict to one environment with --only dev|prod, or deploy a custom single .bicepparam via --param.

set -euo pipefail

# --- Config & Defaults ---
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
TEMPLATE_FILE="$SCRIPT_DIR/main.bicep"
DEV_PARAM_FILE="$SCRIPT_DIR/bicepparams/dev.bicepparam"   # FIX: updated location
PROD_PARAM_FILE="$SCRIPT_DIR/bicepparams/prod.bicepparam" # FIX: updated location
SINGLE_PARAM_FILE=""                           # if provided, deploy a single param file instead of both
DEPLOYMENT_LOCATION=""                         # required for subscription deployment; pass via --location or env
DEPLOYMENT_NAME_BASE="bicep-deploy-$(date +%Y%m%d%H%M%S)" # base; env suffix will be added per run
ONLY_ENV=""                                     # "dev" or "prod" to limit runs

# Allow environment override for location (optional)
: "${AZ_DEPLOYMENT_LOCATION:=${DEPLOYMENT_LOCATION}}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--param <path-to-bicepparam> | --only <dev|prod>] --location <azure-region> [--name <base-deployment-name>]

Options:
  --param, -p     Path to a single .bicepparam file (runs one deployment)
  --only, -o      Limit to one env: dev or prod (default: run both if present)
  --location, -l  Azure region for subscription deployment record (e.g., eastus, westeurope) [required]
  --name, -n      Base deployment name; script appends -dev / -prod (default: $DEPLOYMENT_NAME_BASE)
  -h, --help      Show this help

Examples:
  $(basename "$0") --location eastus                       # runs dev then prod if files exist
  $(basename "$0") --only dev -l eastus                    # runs dev only
  $(basename "$0") -p "$SCRIPT_DIR/bicepparams/prod.bicepparam" -l westeurope -n custom-$(date +%Y%m%d)

Notes:
  - No template parameters are passed in this script; they are sourced from .bicepparam files.
  - Ensure you are logged in: az login
  - Optionally set subscription: az account set --subscription <SUBSCRIPTION_ID_OR_NAME>
EOF
}

# --- Parse args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--param)
      SINGLE_PARAM_FILE="$2"; shift 2;;
    -o|--only)
      ONLY_ENV="$2"; shift 2;;
    -l|--location)
      DEPLOYMENT_LOCATION="$2"; shift 2;;
    -n|--name)
      DEPLOYMENT_NAME_BASE="$2"; shift 2;;
    -h|--help)
      usage; exit 0;;
    *)
      echo "Unknown argument: $1" >&2; usage; exit 1;;
  esac
done

# Allow env var fallback if user exported AZ_DEPLOYMENT_LOCATION
if [[ -z "${DEPLOYMENT_LOCATION}" && -n "${AZ_DEPLOYMENT_LOCATION}" ]]; then
  DEPLOYMENT_LOCATION="${AZ_DEPLOYMENT_LOCATION}"
fi

# --- Validations ---
command -v az >/dev/null 2>&1 || { echo "Azure CLI (az) not found in PATH" >&2; exit 1; }
[[ -f "$TEMPLATE_FILE" ]] || { echo "Template not found: $TEMPLATE_FILE" >&2; exit 1; }
[[ -n "$DEPLOYMENT_LOCATION" ]] || { echo "--location is required (or export AZ_DEPLOYMENT_LOCATION)" >&2; exit 1; }

# If single param file provided, validate it exists
if [[ -n "$SINGLE_PARAM_FILE" && ! -f "$SINGLE_PARAM_FILE" ]]; then
  echo ".bicepparam not found: $SINGLE_PARAM_FILE" >&2; exit 1
fi

# If running both (default), ensure at least one env file exists
if [[ -z "$SINGLE_PARAM_FILE" && -z "$ONLY_ENV" ]]; then
  if [[ ! -f "$DEV_PARAM_FILE" && ! -f "$PROD_PARAM_FILE" ]]; then
    echo "Neither dev nor prod bicepparam files found at: $DEV_PARAM_FILE, $PROD_PARAM_FILE" >&2; exit 1
  fi
fi

# --- Function: deploy with a given param file ---
deploy_with_param() {
  local param_file="$1"
  local env_name="$2"   # dev|prod|custom
  local deployment_name="$DEPLOYMENT_NAME_BASE"
  if [[ -n "$env_name" ]]; then
    deployment_name="${DEPLOYMENT_NAME_BASE}-${env_name}"
  fi

  echo "\n=== Submitting deployment: ${deployment_name} | Params: ${param_file} ==="
  # FIX: Use subscription-scope deployment since main.bicep deploys a resource group at subscription scope
  az deployment sub create \
    --name "$deployment_name" \
    --location "$DEPLOYMENT_LOCATION" \
    --template-file "$TEMPLATE_FILE" \
    --parameters "@$param_file"
}

# --- Orchestrate runs ---
if [[ -n "$SINGLE_PARAM_FILE" ]]; then
  # Single run with custom param file
  deploy_with_param "$SINGLE_PARAM_FILE" "custom"
  echo "\nDone: single deployment completed."
  exit 0
fi

case "$ONLY_ENV" in
  dev)
    [[ -f "$DEV_PARAM_FILE" ]] || { echo "dev.bicepparam not found at: $DEV_PARAM_FILE" >&2; exit 1; }
    deploy_with_param "$DEV_PARAM_FILE" "dev"
    echo "\nDone: dev deployment completed."
    ;;
  prod)
    [[ -f "$PROD_PARAM_FILE" ]] || { echo "prod.bicepparam not found at: $PROD_PARAM_FILE" >&2; exit 1; }
    deploy_with_param "$PROD_PARAM_FILE" "prod"
    echo "\nDone: prod deployment completed."
    ;;
  "")
    # Default: run both if present
    if [[ -f "$DEV_PARAM_FILE" ]]; then
      deploy_with_param "$DEV_PARAM_FILE" "dev"
    else
      echo "Skipping dev: file not found -> $DEV_PARAM_FILE"
    fi
    if [[ -f "$PROD_PARAM_FILE" ]]; then
      deploy_with_param "$PROD_PARAM_FILE" "prod"
    else
      echo "Skipping prod: file not found -> $PROD_PARAM_FILE"
    fi
    echo "\nDone: all requested deployments completed."
    ;;
  *)
    echo "Invalid value for --only: $ONLY_ENV (expected dev or prod)" >&2; usage; exit 1
    ;;
esac
