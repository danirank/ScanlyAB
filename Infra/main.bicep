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

var acrPullRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '7f951dda-4ed3-4680-a7ca-43fe172d538d'
)

resource acrResource 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = {
  name: acrName
}

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(
    acrResource.id,
    containerAppName,
    acrPullRoleDefinitionId
  )
  scope: acrResource
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: containerApp.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

output containerAppUrl string = containerApp.outputs.url
output acrLoginServer string = acr.outputs.loginServer
