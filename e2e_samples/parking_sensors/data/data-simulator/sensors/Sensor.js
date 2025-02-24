const EventEmitter = require("events");

class Sensor extends EventEmitter{
  interval = null;

  constructor(data) {
    super();
    this.data = data;
    this.delay = this.data.delay || 1000;
  }

  startSimulation() {
    this.interval = setInterval(() => {
      this.updateState();
      this.emit("stateChanged", this.output());
    }, this.delay); // Trigger every second
  }

  stopSimulation() {
    if (this.interval) {
      clearInterval(this.interval);
      this.interval = null;
    }
  }

  updateState() {
    this.data.timestamp = new Date().toISOString();
  }

  output() {
    return { type: "default", data: this.data };
  }
}

module.exports = Sensor;
