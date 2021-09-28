using Newtonsoft.Json;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using TelemetryProcessor.Models.CustomAttributes;

namespace TelemetryProcessor.Models
{
    /// <summary>
    /// Telemetry Model.
    /// </summary>
    public class Telemetry
    {
        /// <summary>
        /// Gets or sets DeviceId.
        /// </summary>
        [Required]
        [GuidFormat]
        [JsonProperty("deviceId")]

        public string DeviceId { get; set; }
        /// <summary>
        /// Gets or sets TelemetryData.
        /// </summary>
        [JsonProperty("telemetryData")]
        public Dictionary<string, object> TelemetryData { get; set; }
    }
}