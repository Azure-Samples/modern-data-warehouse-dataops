using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.Azure.Cosmos.Table;
using Newtonsoft.Json;

namespace WebApi.Models
{
    /// <summary>
    /// TelemetryEntity Model which is stored in Table Storage.
    /// </summary>
    [Table("Telemetry")]
    public class TelemetryEntity : TableEntity
    {
        /// <summary>
        /// Gets or sets Telemetry Data.
        /// </summary>
        [JsonProperty("data")]
        public string Data { get; set; }
    }
}