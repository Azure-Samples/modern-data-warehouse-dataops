using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using WebApi.Models;
using Microsoft.Azure.Devices;
using Microsoft.Azure.Devices.Shared;

namespace WebApi.Repositories
{
    /// <summary>
    /// This is the Repository interface.
    /// </summary>
    public interface IRepository
    {
        /// <summary>
        /// Get all devices correspond to tenantId.
        /// </summary>
        /// <param name="tenantId">TenantId.</param>
        /// <returns>Device</returns>
        public Task<List<WebApi.Models.Device>> GetDevicesAsync(string tenantId);

        /// <summary>
        /// Get a device correspond to tenantId and deviceId.
        /// </summary>
        /// <param name="tenantId">TenantId.</param>
        /// <param name="deviceId">DeviceId.</param>
        /// <returns>Device</returns>
        public Task<WebApi.Models.Device> GetDeviceAsync(string tenantId, string deviceId);

        /// <summary>
        /// Get Telemetries.
        /// </summary>
        /// <param name="deviceId">DeviceId.</param>
        /// <param name="top">top to take telemetries</param>
        /// <returns>telementry data</returns>
        public IEnumerable<Telemetry> GetTelemetries(string deviceId, int top);

    }
}
