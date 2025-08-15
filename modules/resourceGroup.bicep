targetScope = 'subscription' // FIX: Set targetScope to subscription for resource group deployment

param resourceGroupName string
param location string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}
