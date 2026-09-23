using './main.bicep'

param environment = 'prod'
param location = 'swedencentral'

param acrSku = 'Standard'

param containerCpu = '0.5'
param containerMemory = '1Gi'

param minReplicas = 1
param maxReplicas = 5
