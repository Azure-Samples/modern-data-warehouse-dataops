using System.ComponentModel.DataAnnotations;
using WebApi.Models.CustomAttributes;
using Newtonsoft.Json;
using Newtonsoft.Json.Converters;

namespace WebApi.Models
{
    /// <summary>
    /// DeviceInfo Model.
    /// </summary>
    public class DeviceInfo
    {
        /// <summary>
        /// Gets or sets DeviceId.
        /// </summary>
        [Key]
        [Required]
        [GuidFormat]
        [JsonProperty("deviceId")]
        public string DeviceId { get; set; }

        /// <summary>
        /// Gets or sets DeviceName.
        /// </summary>
        [StringLength(256)]
        [JsonProperty("deviceName")]
        public string DeviceName { get; set; }

        /// <summary>
        /// Gets or sets DeviceType.
        /// </summary>
        [JsonProperty("deviceType")]
        public string DeviceType { get; set; }

    }
}
