param name string
param env string
param sku object = {
  name: 'S1'
  capacity: 1
}

resource asa_tech_sample_iot 'Microsoft.Devices/IotHubs@2020-04-01' = {
  name: 'iot-${name}-${env}'
  location: resourceGroup().location
  sku: sku
}

output sharedAccessPolicy object = {
  name: listKeys(asa_tech_sample_iot.id, '2020-04-01').value[0].keyName
  key: listKeys(asa_tech_sample_iot.id, '2020-04-01').value[0].primaryKey
}

