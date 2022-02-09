param environmentName string
param location string = resourceGroup().location
param revisionMode string = 'Single'
param imageNameActorApi string
param imageNameActor string

@description('Cosmos DB account name, max length 44 characters, lowercase')
param accountName string = 'sql-${uniqueString(resourceGroup().id)}'
var accountName_var = toLower(accountName)

@description('Maximum throughput for the container')
@minValue(4000)
@maxValue(1000000)
param autoscaleMaxThroughput int = 4000

resource accountName_resource 'Microsoft.DocumentDB/databaseAccounts@2021-01-15' = {
  name: accountName_var
  kind: 'GlobalDocumentDB'
  location: 'NorthEurope'
  properties: {  
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        failoverPriority: 0
        isZoneRedundant: false
        locationName: 'NorthEurope'
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
    options: {
      autoscaleSettings: {
        maxThroughput: autoscaleMaxThroughput
      }
    }
  }
}

resource httpApiResource 'Microsoft.Web/containerApps@2021-03-01' = {
  name: 'demoactorapi'
  kind: 'containerapp'
  location: location
  properties: {
    kubeEnvironmentId: resourceId('Microsoft.Web/kubeEnvironments', environmentName)
    configuration: {
      activeRevisionsMode: revisionMode
      ingress: {
        external: true
        targetPort: 5005
      }      
      secrets: [
        {
          name: 'master-key'
          value: accountName_resource.listKeys().primaryMasterKey
        }
      ]        
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
        minReplicas: 1
        maxReplicas: 2
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
      dapr: {
        enabled: true      
        appId: 'demoactor'       
        appPort: 5000
        components: [
          {
            name: 'statestore'
            type: 'state.azure.cosmosdb'
            version: 'v1'
            metadata: [
              {
                name: 'url'
                value: 'https://daprstore.documents.azure.com:443/'
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
          }
        ]
      }
    }
  }
}
