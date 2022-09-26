# Azure Container Apps - API & Dapr Actors Sample

This quick demo shows how to host an API using Azure Container Apps. The API invokes Dapr actors hosted on sidecar container. Both the API and Actors runtime are scaled based on number of concurrent HTTP requests

## Getting Started

1. Fork this repository

2. (optional) Create a Container Apps Environment if no one exists: https://docs.microsoft.com/en-us/azure/container-apps/microservices-dapr?tabs=bash#create-an-environment

3. Create GitHub secret for
    - "REGISTRY_USERNAME": Docker Hub username
    - "REGISTRY_PASSWORD": Docker Hub password
    - "CLIENT_ID": Client ID of Azure AD application. This demo uses Workload Identity Federation. Please read more on how to set it up: https://docs.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation-create-trust-github?tabs=azure-portal
    - "TENANT_ID": Id of Azure AD tenant where the demo will be deployed to
    - "SUB_ID": Id of subscription where the demo will be deployed to


4. Make a change like adding a comment to a solution file. This will trigger an application deployment through a GitHub workflow. The GitHub workflow uses a bicep template to deploy the Container App as well as a Cosmos DB account for saving actors' state

## Trying out the app

1. Using Postman or an HTTP client make an HTTP POST request to https://(container-app-url)/weatherforecast using this payload:

```json
{
        "date": "2021-07-16T19:04:05.7257911-06:00",
        "temperatureC": 45,
        "temperatureF": 125,
        "summary": "Mild",
        "city": "cairo"
}
```

2. Using a browser or an HTTP client make an HTTP Get request to https://(container-app-url)/weatherforecast/cairo. This will return number of data points and highest temperature recorded for this city. Try submitting more POST requests to this city and other cities. 

Note: Every city here is represented as a Virtual Actor

