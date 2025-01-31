const sensorTypeRegistry = {};

function registerSensorType(type, sensorClass) {
  sensorTypeRegistry[type] = sensorClass;
}

module.exports = {
  sensorTypeRegistry,
  registerSensorType,
};
