param environmentName string
param location string = resourceGroup().location
param revisionMode string = 'Single'


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
      revisionSuffix: 'green'
      containers: [
        {
          image: ' melzayet/containerapps-api:v0.1'
          name: 'httpapi'                     
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
        appId: 'todoapi'       
        appPort: 5000 
      }
    }
  }
}
