param accountName string = 'cosmos-dr-state'
param primaryRegion string = 'uksouth'
param secondaryRegion string = 'ukwest'
resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' = {
  name: accountName
  location: primaryRegion
  properties: {
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
    locations: [
      { locationName: primaryRegion, failoverPriority: 0, isZoneRedundant: true }
      { locationName: secondaryRegion, failoverPriority: 1, isZoneRedundant: true }
    ]
  }
}
