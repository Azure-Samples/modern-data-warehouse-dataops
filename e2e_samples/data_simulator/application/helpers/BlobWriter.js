const { BlobServiceClient } = require("@azure/storage-blob");
const fs = require("fs");

class BlobWriter {
  containerClient = null;

  constructor(config) {
    // get environment variable
    const sasToken = process.env.SASTOKEN;
    const sasUrl = `https://${process.env.BLOBSTORAGEACCOUNT}.blob.core.windows.net/${process.env.BLOBSTORAGECONTAINER}?${sasToken}`;
    const blobServiceClient = new BlobServiceClient(sasUrl);
    this.containerClient = blobServiceClient.getContainerClient(
      process.env.BLOBSTORAGECONTAINER
    );
  }

  async uploadFileToBlob(filename) {
    const blockBlobClient = this.containerClient.getBlockBlobClient(filename);

    const filePath = filename;
    const fileStream = fs.createReadStream(filePath);

    await blockBlobClient.uploadStream(fileStream, fileStream.length, 5, {
      blobHTTPHeaders: { blobContentType: "application/octet-stream" },
    });

    console.log("File uploaded successfully");
  }

  destroy() {
    this.containerClient = null;
  }
}

module.exports = BlobWriter;
