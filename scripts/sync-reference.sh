#!/usr/bin/env bash
# Populate gitignored reference/ trees for terraform init (managed identities path).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

clone_shallow() {
  local url="$1"
  local dest="$2"
  local ref="${3:-}"
  rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  if [[ -n "$ref" ]]; then
    git clone --depth 1 --branch "$ref" "$url" "$dest"
  else
    git clone --depth 1 "$url" "$dest"
  fi
}

if [[ -z "${REFERENCE_ARO_AZAPI_URL:-}" ]]; then
  echo "error: REFERENCE_ARO_AZAPI_URL is not set (git URL with modules/managed_identity, modules/aro_role_assignments, …)." >&2
  echo "  Example: REFERENCE_ARO_AZAPI_URL=https://github.com/your-org/terraform-aro-reference-aro-azapi.git make reference-sync" >&2
  echo "  Organization CI: set GitHub Actions variable REFERENCE_ARO_AZAPI_URL on this repository." >&2
  exit 1
fi

clone_shallow "$REFERENCE_ARO_AZAPI_URL" "$ROOT/reference/aro-azapi" "${REFERENCE_ARO_AZAPI_REF:-}"

if [[ ! -f "$ROOT/reference/aro-azapi/modules/managed_identity/main.tf" ]]; then
  echo "error: clone did not produce reference/aro-azapi/modules/managed_identity/main.tf" >&2
  exit 1
fi

if [[ "${REFERENCE_SYNC_AVM:-1}" == "1" ]]; then
  AVM_URL="${REFERENCE_AVM_URL:-https://github.com/Azure/terraform-azurerm-avm-res-redhatopenshift-openshiftcluster.git}"
  clone_shallow "$AVM_URL" "$ROOT/reference/terraform-azurerm-avm-res-redhatopenshift-openshiftcluster" "${REFERENCE_AVM_REF:-}"
fi

echo "reference/ trees updated under $ROOT/reference"
