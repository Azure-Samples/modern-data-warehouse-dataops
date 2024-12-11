const { registerSensorType } = require('../helpers/sensorTypeRegistry');
const Sensor = require('./Sensor');

// Schema for ParkingBaySensor
// {
//   "total_count":6272,
//   "results":[
//     {
//       "lastupdated":"2023-12-14T04:45:34+00:00",
//       "status_timestamp":"2023-12-14T03:41:25+00:00",
//       "zone_number":7695,
//       "status_description":"Unoccupied",
//       "kerbsideid":22959,
//       "location":{
//         "lon":144.95938672872117,
//         "lat":-37.81844776554182
//       }
//     },
//     {...}
//   ]
// }


class ParkingBaySensor extends Sensor {
  constructor(data) {
    super(data);
  }

  getMinutes(low, high) {
    return (Math.floor(Math.random() * high) + low) * 1000;// * 60;
  }

  updateState() {
    this.data.status_timestamp = new Date().toISOString();
    clearInterval(this.interval);      
    if (this.data.status_description == "Occupied") {
      this.data.status_description = "Unoccupied";
      this.interval = setInterval(() => {
        this.updateState();
        this.emit("stateChanged", this.output());
      }, this.getMinutes(1, 5));
    }
    else {
      this.data.status_description = "Occupied";
      this.interval = setInterval(() => {
        this.updateState();
        this.emit("stateChanged", this.output());
      }, this.getMinutes(5, 30));
    }
  }

  output() {
    this.data.lastupdated = new Date().toISOString();
    return this.data;
  }

  outputForFile(outputData) {
    const template = { "total_count": "int", "results": "array" };
    template.total_count = outputData.length;
    template.results = outputData.map((sensor) => sensor.output());
    return template;
  }
}

registerSensorType('kerbsidesensor', ParkingBaySensor);
