using System;
using System.Net;
using System.Net.Http;
using System.Reflection;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Logging;
using WebApi.Controllers;

namespace WebApi.Filters
{
    /// <summary>
    /// HttpRequestException Filter
    /// </summary>
    public class HttpRequestExceptionFilter : IActionFilter
    {
        private readonly ILogger<HttpRequestExceptionFilter> logger;

        /// <summary>
        /// Initializes a new instance of the <see cref="HttpRequestExceptionFilter"/> class.
        /// </summary>
        /// <param name="logger">Represents a implementation of Ilogger used to perform logging.</param>
        public HttpRequestExceptionFilter(ILogger<HttpRequestExceptionFilter> logger)
        {
            this.logger = logger;
        }

        /// <summary>
        /// Called before the action method is invoked.
        /// </summary>
        /// <param name="context">Instance of ActionExecutingContext.</param>
        public void OnActionExecuting(ActionExecutingContext context)
        {
        }

        /// <summary>
        /// Called after the action method executes.
        /// </summary>
        /// <param name="context">Instance of ActionExecutedContext.</param>
        public void OnActionExecuted(ActionExecutedContext context)
        {
            if (context.Exception is null)
            {
                return;
            }

            if (context.Exception is HttpRequestException ex && context.Controller.GetType().IsSubclassOf(typeof(ControllerBase)))
            {
                switch (ex.StatusCode)
                {
                    case HttpStatusCode.BadRequest:
                        this.logger.LogError(ex.InnerException, "400 Bad Request throwed in {Controller}.", context.Controller.GetType());
                        context.Result = new BadRequestObjectResult("The server can't or will not process the request due to something that is perceived to be a client error (e.g., malformed request syntax, invalid request message framing, or deceptive request routing).");
                        break;
                    case HttpStatusCode.NotFound:
                        this.logger.LogError(ex.InnerException, "404 Not Found throwed in {Controller}.", context.Controller.GetType());
                        context.Result = new NotFoundObjectResult("The server can't find the requested resouce.");
                        break;
                    case HttpStatusCode.Conflict:
                        this.logger.LogError(ex.InnerException, "409 Conflict throwed in {Controller}.", context.Controller.GetType());
                        context.Result = new ConflictObjectResult("A request conflict with current state of the target resource.");
                        break;
                    case HttpStatusCode.ServiceUnavailable:
                        // Use ObjectResult as there is no ServiceUnavailable equivalent ObjectResult class.
                        this.logger.LogError(ex.InnerException, "503 Service Unavailable throwed in {Controller}.", context.Controller.GetType());
                        context.Result = new ObjectResult("The server is busy or temporaly unavailable.")
                        {
                            StatusCode = (int)ex.StatusCode,
                        };
                        break;
                    default:
                        this.logger.LogError(ex.InnerException, "500 Internal Server Error throwed in {Controller}.", context.Controller.GetType());
                        context.Result = new ObjectResult("The server encountered an unexpected condition that prevented it from fulfilling the request.")
                        {
                            StatusCode = (int)HttpStatusCode.InternalServerError,
                        };
                        break;
                }
            }
            else if (context.Exception is TargetInvocationException)
            {
                Exception exception = context.Exception.InnerException is null ?
                    context.Exception : context.Exception.InnerException;

                switch (exception.GetType().Name)
                {
                    case nameof(CosmosException):
                        if (exception.Message.Contains("The order by query does not have a corresponding composite index"))
                        {
                            context.Result = new ObjectResult("Orderby is not supported for the field you specified. Please try different field or change asc/desc.")
                            {
                                StatusCode = (int)HttpStatusCode.InternalServerError,
                            };
                        }
                        else
                        {
                            context.Result = new ObjectResult("The server encountered an unexpected condition that prevented it from fulfilling the request.")
                            {
                                StatusCode = (int)HttpStatusCode.InternalServerError,
                            };
                        }

                        break;
                    default:
                        context.Result = new ObjectResult("The server encountered an unexpected condition that prevented it from fulfilling the request.")
                        {
                            StatusCode = (int)HttpStatusCode.InternalServerError,
                        };
                        break;
                }
            }
            else
            {
                this.logger.LogError(context.Exception.InnerException, "500 Internal Server Error throwed.");
                context.Result = new ObjectResult("The server encountered an unexpected condition that prevented it from fulfilling the request.")
                {
                    StatusCode = (int)HttpStatusCode.InternalServerError,
                };
            }

            context.ExceptionHandled = true;
        }
    }
}