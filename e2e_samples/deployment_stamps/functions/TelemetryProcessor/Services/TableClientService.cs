using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Azure;
using Azure.Data.Tables;
using Azure.Data.Tables.Models;
using Microsoft.Extensions.Caching.Memory;
using TelemetryProcessor.Models;

namespace TelemetryProcessor.Services
{
    /// <summary>
    /// TableClientService implementation.
    /// </summary>
    public class TableClientService : ITableClientService
    {
        private readonly TableStorageConfig tableStorageConfig;
        private readonly IMemoryCache memoryCache;

        /// <summary>
        /// Initializes a new instance of the <see cref="TableClientService"/> class.
        /// </summary>
        /// <param name="tableStorageConfig">TableStorageConfig.</param>
        /// <param name="memoryCache">MemoryCache.</param>
        public TableClientService(TableStorageConfig tableStorageConfig, IMemoryCache memoryCache)
        {
            this.tableStorageConfig = tableStorageConfig;
            this.memoryCache = memoryCache;
        }

        /// <summary>
        /// AddEntity Wrapper.
        /// </summary>
        /// <param name="tableName">TableName.</param>
        /// <param name="entity">Entity.</param>
        /// <param name="cancellationToken">CancellationToken.</param>
        /// <returns>Response</returns>
        public async Task<Azure.Response> AddEntityAsync(string tableName, TableEntity entity, CancellationToken cancellationToken = default)
        {
            TableClient tableClient;

            // Look for cache key.
            if (!this.memoryCache.TryGetValue(tableName, out tableClient))
            {
                await this.CreateTableIfNotExistsAsync(tableName).ConfigureAwait(false);

                tableClient = new TableClient(
                  this.tableStorageConfig.ConnectionString,
                  tableName);

                // Save data in cache.
                this.memoryCache.Set(tableName, tableClient);
            }

            Azure.Response res = tableClient.AddEntity(entity, cancellationToken);
            return res;
        }

        private async Task CreateTableIfNotExistsAsync(string tableName)
        {
            TableServiceClient tableServiceClient = new (this.tableStorageConfig.ConnectionString);
            Pageable<TableItem> queryResults = tableServiceClient.GetTables(filter: $"TableName eq '{tableName}'");
            if (queryResults.Count() == 0)
            {
                await tableServiceClient.CreateTableAsync(tableName).ConfigureAwait(false);
            }
        }
    }
}
