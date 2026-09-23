@description('Name of the Azure Container Registry')
param name string

@description('Azure region')
param location string

param acrsku string

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: name
  location: location
  sku: {
    name: acrsku
  }
  properties: {
    adminUserEnabled: false
  }
}

output acrId string = acr.id
output loginServer string = acr.properties.loginServer
output acrName string = acr.name
