param environment string
param location string
param resourceGroupName string
param vmName string
param adminUsername string
@secure()
param adminPassword string

module resourceGroupModule './modules/resourceGroup.bicep' = {
  name: 'resourceGroupDeployment'
  scope: subscription() // FIX: Set scope back to subscription() for resource group deployment
  params: {
    location: location
    resourceGroupName: resourceGroupName
  }
}

module virtualMachineModule './modules/virtualMachine.bicep' = {
  name: 'virtualMachineDeployment'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    vmName: vmName
    adminUsername: adminUsername
    adminPassword: adminPassword
    subnetId: networkModule.outputs.subnetId
  }
}

module networkModule './modules/network.bicep' = {
  name: 'networkDeployment'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    vnetName: '${environment}-vnet'
    subnetName: '${environment}-subnet'
    nsgName: '${environment}-nsg'
  }
}
