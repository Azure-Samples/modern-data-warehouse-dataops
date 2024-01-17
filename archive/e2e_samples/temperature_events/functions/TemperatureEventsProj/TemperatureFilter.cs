using Microsoft.Azure.EventHubs;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Models;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TemperatureEventsProj
{
    public static class TemperatureFilter
    {
        [FunctionName("TemperatureFilter")]
        public static async Task Run([EventHubTrigger("%FilteredDevicesEvh%", Connection = "FilteredDevicesEvhConnection")] EventData[] events,
            [EventHub("%AnalyticsEvh%", Connection = "AnalyticsEvhConnection")] IAsyncCollector<DeviceEvent> analyticsEvh,
            [EventHub("%OutOfBoundsTemperatureEvh%", Connection = "OutOfBoundsTemperatureEvhConnection")] IAsyncCollector<DeviceEvent> outOfBoundsEvh,
            ILogger log)
        {
            var exceptions = new List<Exception>();

            foreach (EventData eventData in events)
            {
                try
                {
                    string messageBody = Encoding.UTF8.GetString(eventData.Body.Array, eventData.Body.Offset, eventData.Body.Count);
                    var deviceEvent = JsonConvert.DeserializeObject<DeviceEvent>(messageBody);
                    if (deviceEvent.Temperature < 100)
                    {
                        await analyticsEvh.AddAsync(deviceEvent);
                    }
                    else
                    {
                        await outOfBoundsEvh.AddAsync(deviceEvent);
                    }
                }
                catch (Exception e)
                {
                    // We need to keep processing the rest of the batch - capture this exception and continue.
                    // Also, consider capturing details of the message that failed processing so it can be processed again later.
                    exceptions.Add(e);
                }
            }

            // Once processing of the batch is complete, if any messages in the batch failed processing throw an exception so that there is a record of the failure.

            if (exceptions.Count > 1)
                throw new AggregateException(exceptions);

            if (exceptions.Count == 1)
                throw exceptions.Single();
        }
    }
}
