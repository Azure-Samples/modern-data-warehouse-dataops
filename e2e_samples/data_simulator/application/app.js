const dotenv = require('dotenv');
const date = require("date-and-time");
const fs = require("fs");
const path = require("path");
const { sensorTypeRegistry } = require("./helpers/sensorTypeRegistry");
const BlobWriter = require("./helpers/BlobWriter");
const EventHubBatchSender = require("./helpers/eventHubBatchSender");
const express = require('express');
const app = express();

dotenv.config();
var fileWriteInterval = null;
var blobWriter = null;
var sender = null;

if (process.env.WRITEBLOB === "true") {
  blobWriter = new BlobWriter();
}

StartFileWriting = () => {
  fileWriteInterval = setInterval(() => {
    WriteFile(sensors);
  }, process.env.FILEDELAY * 1000);
};

StopFileWriting = () => {
  console.log("Stopping file writing");
  clearInterval(fileWriteInterval);
};

WriteFile = async (sensors) => {
  // Generate a timestamp for the output removing the slashes
  const currentDate = new Date();

  // Retrieve individual components
  fileTimestamp = date.format(currentDate, "YYYY-MM-DDTHH-mm-ss");
  const outputFilename = `${process.env.OUTPUTFILEPREFIX}-${fileTimestamp}.json`;
  console.log(`Writing output to file ${outputFilename}`);
  if (process.env.WRITETEMPLATE == true) {
    // get first sensor of the array as the template
    data = sensors[0].outputForFile(sensors);
  }
  else {
    data = sensors.map((sensor) => sensor.output())
  }
  // Write the output to the file specified in the config
  fs.writeFileSync(outputFilename, JSON.stringify(data, null, 2));
  if (process.env.WRITEBLOB === "true") {
    blobWriter.uploadFileToBlob(outputFilename).then(() => {
      if (!process.env.WRITEFILE) {
        fs.unlinkSync(outputFilename);
      }
    });
  }
};

StreamEvent = async (data) => {
  if (process.env.WRITECONSOLE === "true") {
    console.log(JSON.stringify(data));
  }
  if (process.env.WRITESTREAM === "true") {
    await sender.addMessage(data);
  }
};

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

if (process.env.WRITEBLOB === "true" || process.env.WRITEFILE === "true") {
  StartFileWriting();
}

StartSimulations = () => {
  // Start the simulation for each sensor
  console.log("Starting simulations...");
  for (const sensor of sensors) {
    sensor.startSimulation();
    if (process.env.WRITESTREAM === "true" || process.env.WRITECONSOLE === "true") {
      sensor.on("stateChanged", StreamEvent);
    }
  }
};

const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});

(async () => {
  if (process.env.WRITESTREAM === "true") {
    sender = new EventHubBatchSender(
      process.env.EVENTHUBNAMESPACE,
      process.env.EVENTHUBNAME
    );
  }

  if (process.env.SIMULATIONLENGTH > 0 && process.env.SIMULATIONLENGTH <= 2147483) {
    duration = date.addMilliseconds(new Date(), process.env.SIMULATIONLENGTH * 1000);
    console.log(`Simulations running until ${duration}`);
    StartSimulations();
    setTimeout(async () => {
      if (fileWriteInterval != null) {
        StopFileWriting();
      }
      for (const sensor of sensors) {
        sensor.stopSimulation();
        sensor.removeListener("stateChanged", StreamEvent);
      }
      console.log("Simulations stopped.");
      if (sender != null) {
        await sender.flush();
      }
      server.close(() => {
        console.log("Server closed.");
        process.exit(0); // Exit with success
      });
    }, process.env.SIMULATIONLENGTH * 1000);
  } else {
    console.log("SimulationLength needs to be configured.");
  }
})();

app.get('/', (req, res) => {
  if (process.env.WRITETEMPLATE == "true") {
    console.log(process.env.WRITETEMPLATE);
    res.send(sensors[0].outputForFile(sensors));
  }
  else {
    res.send(sensors.map((sensor) => sensor.output()));
  }
});

// Handle shutdown signals
process.on('SIGINT', () => {
  console.log('SIGINT signal received: closing server.');
  server.close(() => {
    console.log('Server closed.');
    process.exit(0); // Exit with success
  });
});

process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing server.');
  server.close(() => {
    console.log('Server closed.');
    process.exit(0); // Exit with success
  });
});
