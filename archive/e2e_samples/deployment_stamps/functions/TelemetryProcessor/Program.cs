using System;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using TelemetryProcessor.Models;
using TelemetryProcessor.Services;

namespace TelemetryProcessor
{
    /// <summary>
    /// Main Program
    /// </summary>
    public class Program
    {
        private static readonly string StorageConnectionString = Environment.GetEnvironmentVariable("StorageConnectionString");

        /// <summary>
        /// Main
        /// </summary>
        public static void Main()
        {
            TableStorageConfig tableStorageConfig = new ()
            {
                ConnectionString = StorageConnectionString,
            };

            IHost host = new HostBuilder()
                .ConfigureFunctionsWorkerDefaults()
                .ConfigureServices(s =>
                {
                    s.AddSingleton(s => tableStorageConfig);
                    s.AddSingleton<ITableClientService, TableClientService>();
                    s.AddMemoryCache();
                })
                .Build();

            host.Run();
        }
    }
}