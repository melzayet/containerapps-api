param environmentName string
param location string = resourceGroup().location
param revisionMode string = 'Single'
param imageName string


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
  name: 'todoapi'
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
          name: 'storage-key'
          value: '${StorageAccount_Name_resource.listKeys().keys[0].value}'
        }
      ]        
    }
    template: {
      containers: [
        {
          image: imageName
          name: 'demoactor'                   
        }
        {
          image: '${imageName}api'
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
        appId: 'demoactorapi'       
        appPort: 5005
        components: [
          {
            name: 'statestore'
            type: 'state.azure.blobstorage'
            version: 'v1'
            metadata: [
              {
                name: 'accountName'
                value: '${StorageAccount_Name_resource.name}'
              }
              {
                name: 'accountKey'
                secretRef: 'storage-key'
              }
              {
                name: 'containerName'
                value:'dapr-store'
              }
            ]
          }
        ]
      }
    }
  }
}
