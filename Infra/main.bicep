targetScope = 'resourceGroup'

param environment string
param location string = resourceGroup().location
param projectName string = 'scanly'


var prefix = '${projectName}-${environment}'
var acrName = replace('${projectName}${environment}acr', '-', '')
var containerAppName = '${prefix}-api'
var containerAppEnvironmentName = '${prefix}-env'

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param acrSku string
param containerCpu string
param containerMemory string

param minReplicas int
param maxReplicas int


@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
])
param storageSku string
var storageAccountName = replace('${projectName}${environment}storage', '-', '')

module acr 'modules/acr.bicep' = {
  name: 'deploy-acr'
  params: {
    name: acrName
    location: location
    acrsku: acrSku
  }
}

module containerApp 'modules/containerApp.bicep' = {
  name: 'deploy-container-app'
  params: {
    name: containerAppName
    environmentName: containerAppEnvironmentName
    location: location
    cpu: containerCpu
    memory: containerMemory
    minReplicas: minReplicas
    maxReplicas: maxReplicas
  }
}

module acrRole 'modules/acrRole.bicep' = {
  name: 'assign-acr-pull'
  params: {
    acrName: acrName
    containerAppName: containerAppName
    principalId: containerApp.outputs.principalId
  }
}

module storage 'modules/storage.bicep' = {
  name: 'deploy-storage'
  params: {
    name: storageAccountName
    location: location
    skuName: storageSku
  }
}


module storageRole 'modules/storageRole.bicep' = {
  name: 'assign-storage-role'
  params: {
    storageAccountName: storageAccountName
    containerAppName: containerAppName
    principalId: containerApp.outputs.principalId
  }
}


output containerAppUrl string = containerApp.outputs.url
output acrLoginServer string = acr.outputs.loginServer
