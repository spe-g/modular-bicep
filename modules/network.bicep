param location string
param vnetName string
param subnetName string
param nsgName string

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-SSH'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// FIX: Add a delete lock on the NSG to prevent accidental deletion
resource nsgDeleteLock 'Microsoft.Authorization/locks@2016-09-01' = {
  name: 'nsg-delete-lock'
  scope: nsg
  properties: {
    level: 'CanNotDelete'
    notes: 'Prevents accidental deletion of the network security group'
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

// FIX: Add a delete lock on the VNet to prevent accidental deletion
resource vnetDeleteLock 'Microsoft.Authorization/locks@2016-09-01' = {
  name: 'vnet-delete-lock'
  scope: vnet
  properties: {
    level: 'CanNotDelete'
    notes: 'Prevents accidental deletion of the virtual network'
  }
}

// FIX: Add a delete lock on the Subnet to prevent accidental deletion
// Declare the subnet as an existing child resource to use as scope for the lock
resource subnetRef 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  parent: vnet // FIX: Use parent reference for child resource
  name: subnetName
}

resource subnetDeleteLock 'Microsoft.Authorization/locks@2016-09-01' = {
  name: 'subnet-delete-lock'
  scope: subnetRef
  properties: {
    level: 'CanNotDelete'
    notes: 'Prevents accidental deletion of the subnet'
  }
}

output subnetId string = vnet.properties.subnets[0].id
