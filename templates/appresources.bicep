param environmentName string
param location string = resourceGroup().location
param revisionMode string = 'Single'
param imageName string

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
        targetPort: 5000
      }      
      
    }
    template: {
      containers: [
        {
          image: imageName
          name: 'todoapi'
          env: [
            {
              name: 'DAPR_HTTP_PORT'
              value: 3500
            }            
          ]              
        }
      ]
      scale: {
        minReplicas: 2
        maxReplicas: 3
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
        appId: 'todoapi'       
        appPort: 5000 
      }
    }
  }
}
