const { EventHubProducerClient } = require("@azure/event-hubs");
const { AzureNamedKeyCredential } = require("@azure/core-auth");

class EventHubBatchSender {
    constructor(eventHubNamespace, eventHubName) {
        const EH_SAS_KEY_NAME = process.env.EH_SAS_KEY_NAME;
        const EH_SAS_KEY_TOKEN = process.env.EH_SAS_KEY_TOKEN;
        const credential = new AzureNamedKeyCredential(
          EH_SAS_KEY_NAME,
          EH_SAS_KEY_TOKEN
        );
        const fullyQualifiedNamespace = `${eventHubNamespace}.servicebus.windows.net`;
        console.log(`Sending messages to ${fullyQualifiedNamespace}/${eventHubName}`);
        this.producer = new EventHubProducerClient(
          fullyQualifiedNamespace,
          eventHubName,
          credential
        );
        this.currentBatch = null; // Placeholder for the current batch
        this.sendPromises = []; // Track ongoing send operations
    }

    async initializeBatch() {
        if (!this.currentBatch) {
            this.currentBatch = await this.producer.createBatch();
        }
    }

    async addMessage(message) {
        await this.initializeBatch();

        // Try adding the message to the current batch
        if (!this.currentBatch.tryAdd({ body: message })) {
            // If the batch is full, send it and start a new one
            this.sendPromises.push(this.producer.sendBatch(this.currentBatch));
            console.log("Batch sent successfully.");
            this.currentBatch = await this.producer.createBatch(); // Create a new batch
            this.currentBatch.tryAdd({ body: message }); // Add the message to the new batch
        }
    }

    async flush() {
        // Send the final batch if it has messages
        if (this.currentBatch && this.currentBatch.count > 0) {
            this.sendPromises.push(this.producer.sendBatch(this.currentBatch));
            console.log("Final batch sent successfully.");
            this.currentBatch = null;
        }

        // Wait for all send operations to complete
        await Promise.all(this.sendPromises);

        // Close the producer
        await this.producer.close();
        console.log("Producer closed. All messages sent.");
    }
}

module.exports = EventHubBatchSender;
