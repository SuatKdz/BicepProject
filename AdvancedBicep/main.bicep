@description('The Azure regions into which the resources should be deployed')
param locations array = [
  'westeurope'
  'eastus2'
  'eastasia'
]
@secure()
@description('The admin login username for the SQL server')
param sqlServerAdminUsername string
@secure()
@description('The admin login password for the SQL server')
param sqlServerAdminPassword string
@description('The IP address range for all virtual networks to use.')
param vNetAddressPrefix string = '10.10.0.0/16'
@description('The name and IP address range for each subnet in the virtual networks')
param subnets array = [
  {
    name: 'frontend'
    ipAddressRange: '10.10.5.0/24'
  }
  {
    name: 'backend'
    ipAddressRange: '10.10.10.0/24'
  }
]

var subnetProperties = [for subnet in subnets: {
  name: subnet.name
  properties: {
    addressPrefix: subnet.ipAddressRange
  }
} ]

module databases 'modules/database.bicep' = [for location in locations: {
  name: 'database-${location}'
  params: {
    location: location
    sqlServerAdminUsername: sqlServerAdminUsername
    sqlServerAdminPassword: sqlServerAdminPassword
  }
}]

resource vNetworks 'Microsoft.Network/virtualNetworks@2021-02-01' = [for location in locations: {
  name: 'teddybear-${location}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNetAddressPrefix
      ]
    }
    subnets: subnetProperties
  }
}]

output serverInfo array = [for i in range(0, length(locations)): {
  name: databases[i].outputs.serverName
  location: databases[i].outputs.location
  fullyQualifiedDomainName: databases[i].outputs.serverFullyQualifiedDomainName
}]

