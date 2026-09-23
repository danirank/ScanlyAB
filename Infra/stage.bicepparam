using './main.bicep'
param storageSku = 'Standard_LRS'
param environment = 'stage'
param location = 'swedencentral'

param acrSku = 'Basic'

param containerCpu = '0.25'
param containerMemory = '0.5Gi'

param minReplicas = 1
param maxReplicas = 1
