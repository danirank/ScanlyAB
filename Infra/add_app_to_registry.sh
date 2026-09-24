#!/bin/bash
set -e


az containerapp registry set \
  --name scanly-stage-api \
  --resource-group "RG-Daniel-Rank-64f115-DotNetCloudDeveloper-VT-Mars-Goteborg" \
  --server scanlystageacr.azurecr.io \
  --identity system