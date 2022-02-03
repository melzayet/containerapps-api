# Azure Container Apps - API Sample

This quick demo shows how to build an API using Azure Container Apps.

## Getting Started

1. Fork this repository

2. (optional) Create a Container Apps Environment if no one exists: https://docs.microsoft.com/en-us/azure/container-apps/microservices-dapr?tabs=bash#create-an-environment

3. Deploy the application resources using Bicep

    ``az deployment group create -g <name-of-existing-resource-group> --template-file .\templates\resources.bicep --parameters environmentName=<name-of-existing-container-app-environment>``

4. Deploy the application using GitHub action
