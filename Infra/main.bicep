targetScope = 'resourceGroup'

param environment string
param location string = resourceGroup().location
param projectName string = 'scanly'


var prefix = '${projectName}-${environment}'
var acrName = replace('${projectName}${environment}acr', '-', '')
var containerAppName = '${prefix}-api'
var containerAppEnvironmentName = '${prefix}-cae'

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
    acrLoginServer: acr.outputs.loginServer
    cpu: containerCpu
    memory: containerMemory
    minReplicas: minReplicas
    maxReplicas: maxReplicas
  }
}



output containerAppUrl string = containerApp.outputs.url
output acrLoginServer string = acr.outputs.loginServer
