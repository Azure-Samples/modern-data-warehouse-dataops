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

