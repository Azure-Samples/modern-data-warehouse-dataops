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

const dotenv = require('dotenv');
const fs = require("fs");
const path = require("path");
const { sensorTypeRegistry } = require("./helpers/sensorTypeRegistry");
const express = require('express');
const app = express();

dotenv.config();

// Dynamically load sensor types
const sensorsDir = path.join(__dirname, "sensors");
fs.readdirSync(sensorsDir).forEach((file) => {
  if (file.endsWith(".js")) {
    require(path.join(sensorsDir, file));
  }
});

// Load the sensor JSON file specified in the config
const sensorsJson = JSON.parse(fs.readFileSync(process.env.SENSORFILE, "utf-8"));
const sensors = sensorsJson
  .map((sensorData) => {
    const SensorClass =
      sensorTypeRegistry[sensorData.type] ||
      sensorTypeRegistry[process.env.DEFAULTDATACLASS];
    if (!SensorClass || SensorClass === undefined) {
      console.warn(
        `Unknown sensor type '${sensorData.type}' encountered. Skipping.`
      );
      return null; // Skip unknown types
    }
    return new SensorClass(sensorData);
  })
  .filter((sensor) => sensor !== null); // Filter out null values

StartSimulations = () => {
  // Start the simulation for each sensor
  console.log("Starting simulations...");
  for (const sensor of sensors) {
    sensor.startSimulation();
  }
};

const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});

(async () => {
    StartSimulations();
})();

app.get('/', (req, res) => {
  res.redirect('/sensors');
});

app.get('/sensors', (req, res) => {
  if (process.env.WRITETEMPLATE == "true") {
    console.log(process.env.WRITETEMPLATE);
    res.send(sensors[0].outputForFile(sensors));
  }
  else {
    res.send(sensors.map((sensor) => sensor.output()));
  }
});

app.get('/locations', (req, res) => {
  // send file in ./collections/sensorLocations.json
  res.sendFile('./collections/sensorLocations.json', { root: __dirname });
});
