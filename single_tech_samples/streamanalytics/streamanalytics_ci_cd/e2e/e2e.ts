import * as chai from 'chai';
import { Mqtt } from 'azure-iot-device-mqtt';
import { Client, Message } from 'azure-iot-device';
import { BlobItem, ContainerClient } from '@azure/storage-blob';
chai.use(require('chai-subset'));

const EVENT_SINK_CONTAINER = 'bloboutput';
const EXPECTED_E2E_LATENCY_MS = 1500;
const TEST_TIMEOUT_MS = 3000;
const DEVICE_ID = 'modern-data-warehouse-dataops/single_tech_samples/streamanalytics/e2e'

describe('Send to IoT Hub', () => {
    let iotClient: Client;
    let containerClient: ContainerClient;

    before(() => {
        chai.expect(process.env.DEVICE_CONNECTION_STRING).to.be.not.empty;
        chai.expect(process.env.AZURE_STORAGE_CONNECTION_STRING).to.be.not.empty;
    });

    before(async () => {
        iotClient = Client.fromConnectionString(process.env.DEVICE_CONNECTION_STRING as string, Mqtt);
        await iotClient.open();
    });

    before(() => {
        containerClient = new ContainerClient(process.env.AZURE_STORAGE_CONNECTION_STRING as string, EVENT_SINK_CONTAINER);
    });

    before(async () => {
        await deleteAllBlobs();
    });

    after(async () => {
        await iotClient.close();
    });

    afterEach(async () => {
        await deleteAllBlobs();
    });

    async function send(message: Message) {
        await iotClient.sendEvent(message);
    };

    async function deleteAllBlobs() {
        for await (const blob of containerClient.listBlobsFlat()) {
            await containerClient.deleteBlob(blob.name);
        }
    }

    async function getAllBlobs(): Promise<BlobItem[]> {
        const blobItems: BlobItem[] = []
        for await (const blob of containerClient.listBlobsFlat()) {
            blobItems.push(blob);
        }
        return blobItems;
    }

    async function getBlobData(blob: BlobItem): Promise<string> {
        const client = containerClient.getBlockBlobClient(blob.name);
        const response = await client.download();
        return (await streamToBuffer(response.readableStreamBody!)).toString();
    }

    function convertBlobData(blobData: string): any[] {
        return blobData.split('\n').map(entry => JSON.parse(entry));
    }

    // A helper method used to read a Node.js readable stream into a Buffer
    async function streamToBuffer(readableStream: NodeJS.ReadableStream): Promise<Buffer> {
        return new Promise((resolve, reject) => {
            const chunks: Buffer[] = [];
            readableStream.on("data", (data: Buffer | string) => {
                chunks.push(data instanceof Buffer ? data : Buffer.from(data));
            });
            readableStream.on("end", () => {
                resolve(Buffer.concat(chunks));
            });
            readableStream.on("error", reject);
        });
    }

    async function delay() {
        await new Promise(resolve => setTimeout(resolve, EXPECTED_E2E_LATENCY_MS));
    }

    describe('payload with temperature', () => {
        describe('greater than 27 degrees', () => {
            it('should contain entry in blob', async () => {
                const data = {
                    deviceId: DEVICE_ID,
                    temperature: 27.1
                };
                const message = new Message(JSON.stringify(data));
                
                await send(message);
                await delay();
                const blobs = await getAllBlobs();

                chai.expect(blobs).to.have.length(1);
                const blobData = await getBlobData(blobs[0]);
                const entries = convertBlobData(blobData);                                
                chai.expect(entries).to.have.length(1);
                chai.expect(entries).to.containSubset([data]);
            }).timeout(TEST_TIMEOUT_MS);
        });

        describe('equal to 27 degrees', () => {
            it('should not contain entry in blob', async () => {
                const data = {
                    deviceId: DEVICE_ID,
                    temperature: 27
                };
                const message = new Message(JSON.stringify(data));

                await send(message);
                await delay();
                const blobs = await getAllBlobs();

                chai.expect(blobs).to.be.empty;
            }).timeout(TEST_TIMEOUT_MS);
        });

        describe('less than 27 degrees', () => {
            it('should not contain entry in blob', async () => {
                const data = {
                    deviceId: DEVICE_ID,
                    temperature: 26.9
                };
                const message = new Message(JSON.stringify(data));

                await send(message);
                await delay();
                const blobs = await getAllBlobs();

                chai.expect(blobs).to.be.empty;
            }).timeout(TEST_TIMEOUT_MS);
        });
    });
});
