using System.Threading;
using System.Threading.Tasks;
using Azure.Data.Tables;

namespace TelemetryProcessor.Services
{
    /// <summary>
    /// TableClientService interface.
    /// </summary>
    public interface ITableClientService
    {
        /// <summary>
        /// AddEntity Wrapper.
        /// </summary>
        /// <param name="tableName">TableName.</param>
        /// <param name="entity">Entity.</param>
        /// <param name="cancellationToken">CancellationToken.</param>
        /// <returns>Response</returns>
        public Task<Azure.Response> AddEntityAsync(string tableName, TableEntity entity, CancellationToken cancellationToken = default);
    }
}