using System.Collections.Generic;
using System.Net.Mime;
using Microsoft.AspNet.OData;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;
using WebApi.CustomAttributes;
using WebApi.Models;
using WebApi.Repositories;

namespace WebApi.Controllers
{
    /// <summary>
    /// TelemetriesControllerのimpl
    /// </summary>
    [ApiExplorerSettings(IgnoreApi = false)]
    [AuthorizeByTenantId(Roles = "TenantAdministrator,User")]
    [ValidateDevice]
    [SwaggerResponse(StatusCodes.Status400BadRequest, Description = "Bad Request")]
    [SwaggerResponse(StatusCodes.Status401Unauthorized, Description = "Unauthorized")]
    [SwaggerResponse(StatusCodes.Status403Forbidden, Description = "Forbidden")]
    [SwaggerResponse(StatusCodes.Status404NotFound, Description = "Telemetry Not Found")]
    [SwaggerResponse(StatusCodes.Status500InternalServerError, Description = "Internal Server Error")]
    [SwaggerResponse(StatusCodes.Status503ServiceUnavailable, Description = "Service Unavailable")]
    public class TelemetriesController : ODataController
    {
        private readonly IRepository repository;

        /// <summary>
        /// Initializes a new instance of the <see cref="TelemetriesController"/> class.
        /// </summary>
        /// <param name="repository">Repository impl</param>
        public TelemetriesController(IRepository repository)
        {
            this.repository = repository;
        }

        /// <summary>
        /// Get telemtries for specified device.
        /// </summary>
        /// <remarks>
        /// Sample request:
        ///
        ///     GET /v1/029057f6-21e2-40d2-8bce-da1a70825118/devices/0b3cf02e-8eb1-4b61-a8ec-c42e085af3bb/telemetries
        /// </remarks>
        /// <param name="deviceId">DeviceId.</param>
        /// <returns>list of Telemetry data.</returns>
        [HttpGet("v{version}/{tenantId}/devices/{deviceId}/[controller]")]
        [EnableQuery(PageSize = 100)]
        [Produces(MediaTypeNames.Application.Json)]
        [SwaggerResponse(StatusCodes.Status200OK, Type = typeof(List<Telemetry>), Description = "Success")]
        public IActionResult Get([FromRoute] string deviceId)
        {
            // Get Telemetries.
            // If top query parameter is not set, get current top 1 telemetry.
            int top;
            var topStringValue = this.HttpContext.Request.Query["$top"];
            if (string.IsNullOrEmpty(topStringValue) || !int.TryParse(topStringValue, out top))
            {
                top = 1;
            }

            return this.Ok(this.repository.GetTelemetries(deviceId, top));
        }
    }
}
