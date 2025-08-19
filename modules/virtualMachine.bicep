param location string
param vmName string
param adminUsername string
@secure()
param adminPassword string
param subnetId string

resource vm 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
  }
}

// FIX: Add a delete lock on the VM to prevent accidental deletion
resource vmDeleteLock 'Microsoft.Authorization/locks@2016-09-01' = {
  name: 'vm-delete-lock'
  scope: vm
  properties: {
    level: 'CanNotDelete'
    notes: 'Prevents accidental deletion of the virtual machine'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// FIX: Add a delete lock on the NIC to prevent accidental deletion
resource nicDeleteLock 'Microsoft.Authorization/locks@2016-09-01' = {
  name: 'nic-delete-lock'
  scope: nic
  properties: {
    level: 'CanNotDelete'
    notes: 'Prevents accidental deletion of the network interface'
  }
}
