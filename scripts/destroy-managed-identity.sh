#!/bin/bash
# Destroy ARO cluster with managed identities (AzAPI cluster resource, or legacy ARM template)
# Usage: destroy-managed-identity.sh [--auto-approve]

set -e

AUTO_APPROVE="-auto-approve"

SUBSCRIPTION_ID=$(az account show --query id --output tsv)

AZAPI_TARGET='module.aro_cluster_azapi[0].azapi_resource.aro_cluster'
LEGACY_TARGET='azurerm_resource_group_template_deployment.cluster_managed_identity'

echo "Destroying ARO cluster resources (managed identity)..."
echo "Step 1: Destroying cluster (if exists)..."

STATE_LIST=$(terraform state list 2>/dev/null || true)
# BSD grep: -c exits 1 when count is 0; avoid empty integer compares
if echo "${STATE_LIST}" | grep -Fq "${AZAPI_TARGET}"; then
  HAS_AZAPI=1
else
  HAS_AZAPI=0
fi
if echo "${STATE_LIST}" | grep -Fq "${LEGACY_TARGET}"; then
  HAS_LEGACY=1
else
  HAS_LEGACY=0
fi

if [ "${HAS_AZAPI}" -eq 1 ]; then
  echo "Destroying AzAPI cluster: ${AZAPI_TARGET}"
  set +e
  TERRAFORM_OUTPUT=$(terraform destroy -target="${AZAPI_TARGET}" \
    -var "subscription_id=${SUBSCRIPTION_ID}" ${AUTO_APPROVE} 2>&1)
  TERRAFORM_EXIT=$?
  set -e
  if [ ${TERRAFORM_EXIT} -ne 0 ]; then
    echo "⚠ Warning: Cluster destroy had errors; continuing..."
    echo "${TERRAFORM_OUTPUT}" | tail -25
  fi
elif [ "${HAS_LEGACY}" -eq 1 ]; then
  echo "Destroying legacy ARM template deployment: ${LEGACY_TARGET}"
  set +e
  terraform destroy -target="${LEGACY_TARGET}" \
    -var "subscription_id=${SUBSCRIPTION_ID}" ${AUTO_APPROVE} 2>&1 | tail -40
  set -e
else
  echo "No managed identity cluster in state, skipping cluster-only destroy"
fi

echo ""
echo "Waiting for cluster to be fully deleted (when applicable)..."

CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "")
RESOURCE_GROUP=$(terraform output -raw resource_group_name 2>/dev/null || echo "")

if [ -n "${CLUSTER_NAME}" ] && [ -n "${RESOURCE_GROUP}" ]; then
  MAX_WAIT=600
  WAITED=0
  while [ ${WAITED} -lt ${MAX_WAIT} ]; do
    if ! az aro show --name "${CLUSTER_NAME}" --resource-group "${RESOURCE_GROUP}" --output none 2>/dev/null; then
      echo "✓ Cluster confirmed deleted"
      break
    fi
    echo "  Waiting for cluster deletion... (${WAITED}/${MAX_WAIT} seconds)"
    sleep 10
    WAITED=$((WAITED + 10))
  done
  if [ ${WAITED} -ge ${MAX_WAIT} ]; then
    echo "⚠ Warning: Cluster deletion check timed out after ${MAX_WAIT} seconds"
  fi
else
  sleep 15
fi

echo "Step 2: Destroying all remaining resources (managed identities, networks, etc.)..."
terraform destroy -var "subscription_id=${SUBSCRIPTION_ID}" ${AUTO_APPROVE}
