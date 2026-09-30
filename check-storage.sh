#!/bin/bash
set -e

RESOURCE_GROUP="RG-Daniel-Rank-64f115-DotNetCloudDeveloper-VT-Mars-Goteborg"
CONTAINER_APP="scanly-stage-api"

PRINCIPAL_ID=$(az containerapp show \
  --name "$CONTAINER_APP" \
  --resource-group "$RESOURCE_GROUP" \
  --query identity.principalId \
  -o tsv)

az role assignment list \
  --assignee "$PRINCIPAL_ID" \
  --all \
  --query "[?roleDefinitionName=='Storage Blob Data Contributor'].{
    Role:roleDefinitionName,
    Scope:scope
  }" \
  -o table