param profileName string = 'afd-enterprise-dr'
resource afd 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: profileName
  location: 'Global'
  sku: { name: 'Premium_AzureFrontDoor' }
}
