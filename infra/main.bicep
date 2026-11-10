@description('Location for primary disaster recovery orchestrator resources')
param location string = 'uksouth'

@description('Standby disaster recovery target location')
param standbyLocation string = 'ukwest'

@description('Base name for disaster recovery co-worker infrastructure')
param appName string = 'dr-failover-coworker'

@description('Cosmos DB account name for replicated state')
param cosmosAccountName string = 'cosmos-resilience-${uniqueString(resourceGroup().id)}'

// User-Assigned Managed Identity for Least-Privilege Execution
resource drIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${appName}-${location}'
  location: location
}

// Log Analytics Workspace for Pre-Flight KQL Assertions
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'law-${appName}-${location}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Multi-Region Azure Cosmos DB with explicit UK South & UK West replication stamps
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: cosmosAccountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
      maxStalenessPrefix: 100
      maxIntervalInSeconds: 5
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: true
      }
      {
        locationName: standbyLocation
        failoverPriority: 1
        isZoneRedundant: true
      }
    ]
    enableAutomaticFailover: false // Gated by Autonomous Co-Worker circuit breaker
  }
}

// Azure Container Apps Environment for isolated Co-Worker runtime
resource containerAppEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: 'cae-${appName}-${location}'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

// Autonomous DR Co-Worker Container App
resource drContainerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'app-${appName}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${drIdentity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      activeRevisionsMode: 'Single'
    }
    template: {
      containers: [
        {
          name: 'dr-coworker'
          image: 'mcr.microsoft.com/powershell:7.4-alpine-3.18'
          resources: {
            cpu: json('0.5')
            memory: '1.0Gi'
          }
          env: [
            {
              name: 'COSMOS_ACCOUNT_NAME'
              value: cosmosAccount.name
            }
            {
              name: 'STANDBY_REGION'
              value: standbyLocation
            }
            {
              name: 'MAX_RPO_LAG_SECONDS'
              value: '30.0'
            }
          ]
        }
      ]
    }
  }
}

output identityPrincipalId string = drIdentity.properties.principalId
output cosmosEndpoint string = cosmosAccount.properties.documentEndpoint
output containerAppFqdn string = drContainerApp.properties.configuration.ingress.fqdn
