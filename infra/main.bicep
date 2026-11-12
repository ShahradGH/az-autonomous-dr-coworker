@description('Primary Azure region for deployment')
param location string = resourceGroup().location

@description('Environment identifier')
param environmentName string = 'prod'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'law-sovereign-${environmentName}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 90
  }
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-policy-gate-${environmentName}'
  location: location
}

output workspaceId string = logAnalytics.id
output principalId string = managedIdentity.properties.principalId
