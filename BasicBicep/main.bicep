@description('The name of the environment. This must be dev, test, or prod.')
@allowed([
  'dev'
  'test'
  'prod'
])
param envName string = 'dev'
@description('The unique name of the solution. This is used to ensure that resource names are unique')
@minLength(6)
@maxLength(25)
param solutionName string = 'toyhr${uniqueString(resourceGroup().id)}'
@description('The number of App Service plan instances.')
@minValue(1)
@maxValue(5)
param appServicePlanInstanceCount int = 1
@description('The name and tier of the App Service plan SKU')
param appServicePlanSku object
@description('The Azure region into which the resources should be deployed.')
param location string = resourceGroup().location
@secure()
@description('The admin login username for SQL server.')
param sqlServerAdminLogin string
@secure()
@description('The admin login password for SQL server')
param sqlServerAdminPassword string
@description('The name and tier of the SQL database SKU.')
param sqlDatabaseSku object

var appServicePlanName = '${envName}-${solutionName}-plan'
var appServiceAppName = '${envName}-${solutionName}-app'
var sqlServerName = '${envName}-${solutionName}-sql'
var sqlDatabaseName = 'Employees'

resource appServicePlan 'Microsoft.Web/serverfarms@2021-01-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanSku.name
    tier: appServicePlanSku.tier
    capacity: appServicePlanInstanceCount
  }
}
resource appServiceApp 'Microsoft.Web/sites@2021-01-01' = {
  name: appServiceAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
  }
  
}
resource sqlServer 'Microsoft.Sql/servers@2021-02-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlServerAdminLogin
    administratorLoginPassword: sqlServerAdminPassword
  }
  
}
resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-02-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: {
    name: sqlDatabaseSku.name
    tier: sqlDatabaseSku.tier
  }
}

