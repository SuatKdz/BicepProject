@description('The Azure region into which the resources should be deployed')
param location string
@secure()
@description('The admin login username for the SQL server')
param sqlServerAdminUsername string
@secure()
@description('The admin login password for the SQL server')
param sqlServerAdminPassword string
@description('The name and tier of the SQL database SKU.')
param sqlDatabaseSku object = {
  name: 'Standard'
  tier: 'Standard'
}
@description('The name of the environment. This must be Development or Production')
@allowed([
  'Development'
  'Production'
])
param envName string= 'Development'
@description('The name of the audit storage account SKU')
param auditStorageAccountSkuName string = 'Standard_LRS'

var sqlServerName = 'teddy${location}${uniqueString(resourceGroup().id)}'
var sqlDatabaseName = 'TeddyBear'
var auditingEnabled = envName == 'Production'
var auditStorageAccountName = '${take('bearaudit${location}${uniqueString(resourceGroup().id)}', 24)}'

resource sqlServer 'Microsoft.Sql/servers@2021-02-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlServerAdminUsername
    administratorLoginPassword: sqlServerAdminPassword
  }
  
}
resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-02-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: sqlDatabaseSku
  
}
resource auditStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = if (auditingEnabled) {
  name: auditStorageAccountName
  location: location
  sku: {
    name: auditStorageAccountSkuName
  }
  kind: 'StorageV2'
  
}

resource sqlServerAudit 'Microsoft.Sql/servers/auditingSettings@2021-02-01-preview' = if (auditingEnabled) {
  parent: sqlServer
  name: 'default'
  properties: {
    state: 'Enabled'
    storageEndpoint: envName == 'Production' ? auditStorageAccount.properties.primaryEndpoints.blob : ''
    storageAccountAccessKey: envName == 'Production' ? listKeys(auditStorageAccount.id, auditStorageAccount.apiVersion).keys[0].value : ''
  }
}

output serverName string = sqlServer.name
output location string = location
output serverFullyQualifiedDomainName string = sqlServer.properties.fullyQualifiedDomainName
