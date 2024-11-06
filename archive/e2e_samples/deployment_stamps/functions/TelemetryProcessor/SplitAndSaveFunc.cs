using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Azure.Data.Tables;
using TelemetryProcessor.Models;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using TelemetryProcessor.Services;

namespace TelemetryProcessor
{
    /// <summary>
    /// Function to split incoming telemetory and save to table storage.
    /// </summary>
    public class SplitAndSaveFunc
    {
        private readonly ITableClientService tableClientService;

        /// <summary>
        /// Initializes a new instance of the <see cref="SplitAndSaveFunc"/> class.
        /// </summary>
        /// <param name="tableClientService">ITableClientService.</param>
        public SplitAndSaveFunc(ITableClientService tableClientService)
        {
            this.tableClientService = tableClientService;
        }

        /// <summary>
        /// Main.
        /// </summary>
        /// <param name="events">EventHub Items.</param>
        /// <param name="context">FunctionContext.</param>
        /// <returns>Task</returns>
        [Function("SplitAndSave")]
        public async Task Run(
            [EventHubTrigger("evh-tel", Connection = "EventHubConnectionString")] string[] events,
            FunctionContext context)
        {
            ILogger logger = context.GetLogger(nameof(SplitAndSaveFunc));
            List<Exception> exceptions = new ();

            foreach (string eventData in events)
            {
                try
                {
                    Telemetry telemetry = JsonConvert.DeserializeObject<Telemetry>(eventData);

                    string partitionKey = telemetry.DeviceId.ToString();
                    string rowKey = string.Format("{0:D19}", DateTime.MaxValue.Ticks - DateTime.Now.Ticks);
                    string currentHour = DateTime.Now.ToUniversalTime().ToString("yyyyMMddHH");
                    int currentMinute = DateTime.Now.ToUniversalTime().Minute / 10;
                    string tableName = "telemetry";
                    
                    TableEntity entity = new (partitionKey, rowKey)
                    {
                        { "Data", JsonConvert.SerializeObject(telemetry) },
                    };

                    await this.tableClientService.AddEntityAsync(tableName, entity).ConfigureAwait(false);
                    
                }
                catch (Exception ex)
                {
                    if (ex is JsonSerializationException || ex is JsonReaderException || ex is NullReferenceException)
                    {
                        logger.LogError("An exception occurred when reading input json data. "
                            + $"Exception message:{ex.Message}");
                        exceptions.Add(new ArgumentException(ex.Message));
                    }
                    else
                    {
                        logger.LogError("An exception occurred when accessing the azure data table. "
                            + $"Exception message:{ex.Message}");
                        exceptions.Add(ex);
                    }
                }
            }

            if (exceptions.Count > 1)
            {
                throw new AggregateException(exceptions);
            }

            if (exceptions.Count == 1)
            {
                throw exceptions.Single();
            }
        }
    }
}
