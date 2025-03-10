// Access granted under MIT Open Source License: https://en.wikipedia.org/wiki/MIT_License
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense, # and/or sell copies of the Software,
// and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions
// of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
// TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
// CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.


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
    return (Math.floor(Math.random() * high) + low) * 1000 * 60;
  }

  updateState() {
    this.data.status_timestamp = new Date().toISOString();
    clearInterval(this.interval);
    if (this.data.status_description == "Present") {
      this.data.status_description = "Unoccupied";
      this.interval = setInterval(() => {
        this.updateState();
        this.emit("stateChanged", this.output());
      }, this.getMinutes(1, 5));
    }
    else {
      this.data.status_description = "Present";
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
