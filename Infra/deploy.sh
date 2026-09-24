#!/bin/bash
set -euo pipefail

RESOURCE_GROUP="RG-Daniel-Rank-64f115-DotNetCloudDeveloper-VT-Mars-Goteborg"

echo "Deploying infrastructure..."

CONTAINER_APP_URL=$(az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "main.bicep" \
  --parameters "stage.bicepparam" \
  --query "properties.outputs.containerAppUrl.value" \
  --output tsv)

if [ -z "$CONTAINER_APP_URL" ]; then
  echo "Could not retrieve containerAppUrl from Bicep output."
  exit 1
fi

echo "Container App URL: $CONTAINER_APP_URL"

echo "Configuring Container App registry..."
./add_app_to_registry.sh

echo "Running health check..."

curl --fail \
  --retry 5 \
  --retry-delay 5 \
  "${CONTAINER_APP_URL}/health"

echo
echo "Deployment and health check completed successfully."