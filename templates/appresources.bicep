@description('Specifies the location for resources.')

param environmentName string = 'capp-env-actors-demo'
param location string = resourceGroup().location
param revisionMode string = 'Single'
param imageNameActorApi string
param imageNameActor string

@description('Cosmos DB account name, max length 44 characters, lowercase')
param accountName string = 'sql-${uniqueString(resourceGroup().id)}'
var accountName_var = toLower(accountName)

resource accountName_resource 'Microsoft.DocumentDB/databaseAccounts@2021-01-15' = {
  name: accountName_var
  kind: 'GlobalDocumentDB'
  location: location
  properties: {  
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        failoverPriority: 0
        isZoneRedundant: false
        locationName: location
      }
    ]
    capabilities: [
      {
        name: 'EnableServerless'
      }    
    ] 
  }
}

resource accountName_databaseName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-01-15' = {
  parent: accountName_resource
  name: 'store'
  properties: {
    resource: {
      id: 'store'
    }
  }
}

resource accountName_databaseName_containerName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-01-15' = {
  parent: accountName_databaseName
  name: 'dapr'
  properties: {
    resource: {
      id: 'dapr'
      partitionKey: {
        paths: [
          '/partitionKey'
        ]
        kind: 'Hash'
      }                  
    }   
  }
}

var logAnalyticsWorkspaceName = 'logs-${environmentName}'
var appInsightsName = 'appins-${environmentName}'

resource logAnalyticsWorkspace'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}
resource environment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: environmentName
  location: location
  properties: {
    daprAIInstrumentationKey: reference(appInsights.id, '2020-02-02').InstrumentationKey
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: reference(logAnalyticsWorkspace.id, '2021-06-01').customerId
        sharedKey: listKeys(logAnalyticsWorkspace.id, '2021-06-01').primarySharedKey
      }
    }
  }
  resource daprComponent 'daprComponents@2022-03-01' = {
    name: 'statestore'
    properties: {
      componentType: 'state.azure.cosmosdb'
      ignoreErrors: false
      initTimeout: '5s'
      version: 'v1'
      secrets: [
        {
          name: 'master-key'
          value: accountName_resource.listKeys().primaryMasterKey
        }
      ]
      metadata: [
        {
          name: 'url'
          value: 'https://${accountName_resource.name}.documents.azure.com:443/'
        }
        {
          name: 'masterKey'
          secretRef: 'master-key'
        }
        {
          name: 'database'
          value:'store'
        }
        {
          name: 'collection'
          value:'dapr'
        }
        {
          name: 'actorStateStore'
          value: 'true'
        }              
      ]
      scopes: [
        'demoactor'
      ]
    }
  }
}

resource httpApiResource 'Microsoft.App/containerApps@2022-03-01' = {
  name: 'demoactor'
  location: location
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      activeRevisionsMode: revisionMode
      ingress: {
        external: true
        targetPort: 5005
      }
      dapr: {
        enabled: true      
        appId: 'demoactor'
        appPort: 5000
      }
    }
    template: {
      containers: [
        {
          image: imageNameActor
          name: 'demoactor'                   
        }
        {
          image: imageNameActorApi
          name: 'demoactorapi'
        }
      ]
      scale: {
        minReplicas: 2
        maxReplicas: 4
        rules: [
          {
            name: 'httpscalingrule'
            http: {
                    metadata: {
                      concurrentRequests: '10'
                  }
              }
          }
        ]
      }
    }
  }
}
