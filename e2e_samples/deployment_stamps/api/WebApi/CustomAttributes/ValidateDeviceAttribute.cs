using System;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Logging;
using WebApi.Filters;
using WebApi.Repositories;

namespace WebApi.CustomAttributes
{
    /// <summary>
    /// Validate if a device exists in tenant by using {tenantId} and {deviceId} route vaule.
    /// </summary>
    public class ValidateDeviceAttribute : Attribute, IFilterFactory
    {
        /// <summary>
        /// IsReusable
        /// </summary>
        public bool IsReusable
        {
            get
            {
                return false;
            }
        }

        /// <summary>
        /// CreateInstance of ValidateDeviceFilter
        /// </summary>
        /// <param name="serviceProvider">serviceProvider</param>
        /// <returns>IFilterMetadata</returns>
        public IFilterMetadata CreateInstance(IServiceProvider serviceProvider)
        {
            IRepository repository = (IRepository)serviceProvider.GetService(typeof(IRepository));
            ILoggerFactory loggerFactory = (ILoggerFactory)serviceProvider.GetService(typeof(ILoggerFactory));
            return new ValidateDeviceFilter(repository, loggerFactory.CreateLogger<ValidateDeviceFilter>());
        }
    }
}
