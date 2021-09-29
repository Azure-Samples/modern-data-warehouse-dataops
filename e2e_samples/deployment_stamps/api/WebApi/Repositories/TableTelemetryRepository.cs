using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using WebApi.Models;
using Microsoft.Azure.Cosmos.Table;
using Newtonsoft.Json;

namespace WebApi.Repositories
{
    /// <summary>
    /// TableTelemetryRepository implementaion of IRepositry
    /// </summary>
    public partial class Repository : IRepository
    {
        /// <summary>
        /// Storage Table Name Prefix.
        /// </summary>
        private static readonly string StorageTableNamePrefix = "telemetry";

        private readonly CloudTableClient tableClient;


        /// <summary>
        /// Get telemetries filtered for corresponding deviceId
        /// </summary>
        /// <param name="deviceId">DeviceId.</param>
        /// <param name="top">Top number to take telemetries.</param>
        /// <returns>Telemetries.</returns>
        public IEnumerable<Telemetry> GetTelemetries(string deviceId, int top)
        {
            DateTime dateTimeNow = DateTime.UtcNow;
            var firstRes = this.GetTelemetriesOfSpecificDateTime(deviceId, top, dateTimeNow);

            int firtstCount = firstRes.Count();

            if (firtstCount < top)
            {
                // Check previous table.
                DateTime dateTimeBefore10min = dateTimeNow.AddMinutes(-10);

                return firstRes.Union(this.GetTelemetriesOfSpecificDateTime(deviceId, top - firtstCount, dateTimeBefore10min));
            }
            else
            {
                return firstRes;
            }
        }

        /// <summary>
        /// Get telemetries filtered by required device id, saved between datetime to (datetime - 10 mins).
        /// </summary>
        /// <param name="deviceId">DeeviceId.</param>
        /// <param name="top">Top number to take telemetries.</param>
        /// <param name="dateTime">Datetime to take telemetries.</param>
        /// <returns>Telemetries.</returns>
        internal IEnumerable<Telemetry> GetTelemetriesOfSpecificDateTime(string deviceId, int top, DateTime dateTime)
        {
            if (top <= 0)
            {
                return new List<Telemetry>();
            }

            try
            {
                CloudTable table = this.tableClient.GetTableReference("telemetry");

                var telemtriesQuery = new TableQuery<TelemetryEntity>()
                    .Where(TableQuery.GenerateFilterCondition(
                        nameof(TelemetryEntity.PartitionKey),
                        QueryComparisons.Equal,
                        deviceId))
                    .Take(top);

                return table.ExecuteQuery(telemtriesQuery).Select(x => JsonConvert.DeserializeObject<Telemetry>(x.Data));
            }
            catch (StorageException ex)
            {
                HttpStatusCode statusCode = HttpStatusCode.InternalServerError;
                if (Enum.IsDefined(typeof(HttpStatusCode), ex.RequestInformation.HttpStatusCode))
                {
                    statusCode = (HttpStatusCode)Enum.ToObject(typeof(HttpStatusCode), ex.RequestInformation.HttpStatusCode);
                }

                throw new HttpRequestException(ex.Message, ex, statusCode);
            }
        }
    }
}
