param environmentName string
param location string = resourceGroup().location
param revisionMode string = 'Single'
param imageNameActorApi string
param imageNameActor string
param cosmosMasterKey string

resource StorageAccount_Name_resource 'Microsoft.Storage/storageAccounts@2021-01-01' = {
  name: replace('${resourceGroup().name}-dapr-store', '-', '')
  location: location
  sku: {
    name: 'Standard_LRS'    
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
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
          value: cosmosMasterKey
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
                value: 'https://grworkflow.documents.azure.com:443/'
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
                value:'daprstore'
              }
            ]
          }
        ]
      }
    }
  }
}
