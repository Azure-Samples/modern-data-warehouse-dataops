using System.ComponentModel.DataAnnotations;
using WebApi.Models.CustomAttributes;
using Newtonsoft.Json;

namespace WebApi.Models
{
    /// <summary>
    /// Device Model.
    /// </summary>
    public class Device : DeviceInfo
    {
        /// <summary>
        /// Gets or sets Cosmos DB unique Id. As we cannot inherit multiple class, we cannot inherit CosmosEntity.
        /// </summary>
        [JsonProperty("id")]
        public string Id { get; set; }

        /// <summary>
        /// Gets or sets TenantId.
        /// </summary>
        [Required]
        [GuidFormat]
        [JsonProperty("tenantId")]
        public string TenantId { get; set; }

        /// <summary>
        /// Gets Type.
        /// </summary>
        [JsonProperty("type")]
        public string Type { get; } = nameof(Device);
    }
}