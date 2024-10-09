param name string
param env string
param location string
param sku object = {
  name: 'S1'
  capacity: 1
}

resource iotHubs 'Microsoft.Devices/IotHubs@2020-04-01' = {
  name: 'iot-${name}-${env}'
  location: location
  sku: sku
}

output iotHubsName string = iotHubs.name 
