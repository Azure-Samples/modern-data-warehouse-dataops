using System.Net;
using System.Net.Http;
using WebApi.Models;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Logging;
using WebApi.Repositories;

namespace WebApi.Filters
{
    /// <summary>
    /// Validate if a device exists in tenant by using {tenantId} and {deviceId} route vaule.
    /// </summary>
    public class ValidateDeviceFilter : IActionFilter
    {
        private readonly IRepository repository;
        private readonly ILogger<ValidateDeviceFilter> logger;

        /// <summary>
        /// Initializes a new instance of the <see cref="ValidateDeviceFilter"/> class.
        /// </summary>
        /// <param name="repository">repository service.</param>
        /// <param name="logger">Represents a implementation of Ilogger used to perform logging.</param>
        public ValidateDeviceFilter(IRepository repository, ILogger<ValidateDeviceFilter> logger)
        {
            this.repository = repository;
            this.logger = logger;
        }

        /// <summary>
        /// OnActionExecuting
        /// </summary>
        /// <param name="context">context</param>
        public void OnActionExecuting(ActionExecutingContext context)
        {
            this.logger.LogInformation("OnActionExecuting");

            if (!context.HttpContext.Request.RouteValues.TryGetValue("tenantId", out object tenantId))
            {
                throw new HttpRequestException("Invalid url", null, HttpStatusCode.BadRequest);
            }

            if (!context.HttpContext.Request.RouteValues.TryGetValue("deviceId", out object deviceId))
            {
                throw new HttpRequestException("Invalid url", null, HttpStatusCode.BadRequest);
            }

            // Get device by using deviceId and tenantId
            Device device = this.repository.GetDeviceAsync(tenantId as string, deviceId as string).ConfigureAwait(false).GetAwaiter().GetResult();
            if (device is null)
            {
                this.logger.LogError($"Device is not found: deviceId = {deviceId}");
                throw new HttpRequestException($"Device is not found: deviceId = {deviceId}", null, HttpStatusCode.NotFound);
            }
            else
            {
                return;
            }
        }

        /// <summary>
        /// OnActionExecuted
        /// </summary>
        /// <param name="context">context</param>
        public void OnActionExecuted(ActionExecutedContext context)
        {
            this.logger.LogInformation("OnActionExecuted");
        }
    }
}
