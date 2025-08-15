// FIX: Moved into bicepparams/ and updated path to main.bicep
using '../main.bicep'
param location = 'East US'
param environment = 'dev'
param resourceGroupName = '${environment}-rg'
param vmName = '${environment}-vm'
param adminUsername = 'azureuser'
param adminPassword = 'P@ssw0rd123'
