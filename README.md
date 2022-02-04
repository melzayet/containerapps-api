# Azure Container Apps - API Sample

This quick demo shows how to build an API using Azure Container Apps.

## Getting Started

1. Fork this repository

2. (optional) Create a Container Apps Environment if no one exists: https://docs.microsoft.com/en-us/azure/container-apps/microservices-dapr?tabs=bash#create-an-environment

3. Create GitHub secret for
    - "CA_ENV": Container Apps Environment name
    - "TODO_RG": Azure Resource Group for Container Apps Environment
    - "REGISTRY_USERNAME": Docker Hub username
    - "REGISTRY_PASSWORD": Docker Hub password
    - "AZURE_CREDENTIALS": JSON string returned by 'az ad sp create-for-rbac' command. As an enhancement, it's recommended to replace this method in GitHub workflow with Workload Identity Federation: https://docs.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation-create-trust-github?tabs=azure-portal

4. Make a change like adding a comment to a solution file. This will trigger an application deployment through a GitHub workflow
