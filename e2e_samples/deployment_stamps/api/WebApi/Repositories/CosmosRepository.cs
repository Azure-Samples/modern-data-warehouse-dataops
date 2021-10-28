using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.Azure.Cosmos;
using Microsoft.EntityFrameworkCore;
using WebApi.Models;

namespace WebApi.Repositories
{
    /// <summary>
    /// This is the repository class to process Connector data in Azure Cosmos DB.
    /// </summary>
    public partial class Repository : IRepository
    {
        // Cosmos DB Context
        private readonly CosmosContext cosmosContext;


        /// <summary>
        /// Get all devices correspond to tenantId.
        /// </summary>
        /// <param name="tenantId">TenantId.</param>
        /// <returns>Device.</returns>
        public async Task<List<Device>> GetDevicesAsync(string tenantId)
        {
            if (string.IsNullOrEmpty(tenantId))
            {
                throw new ArgumentNullException(nameof(tenantId), $"{nameof(tenantId)} must not be null in {nameof(this.GetDeviceAsync)}");
            }

            try
            {
                return await this.cosmosContext.Devices.Where<Device>(c => c.TenantId == tenantId).ToListAsync().ConfigureAwait(false);
            }
            catch (CosmosException ex)
            {
                throw new HttpRequestException(ex.Message, ex, ex.StatusCode);
            }
            catch (Exception ex)
            {
                throw new HttpRequestException(ex.Message, ex, HttpStatusCode.ServiceUnavailable);
            }
        }

        /// <summary>
        /// Get Device correspond to tenantId and deviceId.
        /// </summary>
        /// <param name="tenantId">TenantId.</param>
        /// <param name="deviceId">DeviceId.</param>
        /// <returns>Device.</returns>
        public async Task<Device> GetDeviceAsync(string tenantId, string deviceId)
        {
            if (string.IsNullOrEmpty(tenantId))
            {
                throw new ArgumentNullException(nameof(tenantId), $"{nameof(tenantId)} must not be null in {nameof(this.GetDeviceAsync)}");
            }

            if (string.IsNullOrEmpty(deviceId))
            {
                throw new ArgumentNullException(nameof(deviceId), $"{nameof(deviceId)} must not be null in {nameof(this.GetDeviceAsync)}");
            }

            try
            {
                return await this.cosmosContext.Devices.Where<Device>(c => c.TenantId == tenantId && c.DeviceId == deviceId).FirstOrDefaultAsync<Device>().ConfigureAwait(false);
            }
            catch (CosmosException ex)
            {
                throw new HttpRequestException(ex.Message, ex, ex.StatusCode);
            }
            catch (Exception ex)
            {
                throw new HttpRequestException(ex.Message, ex, HttpStatusCode.ServiceUnavailable);
            }
        }
    }
}
