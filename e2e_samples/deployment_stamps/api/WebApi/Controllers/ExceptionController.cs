using Microsoft.AspNet.OData;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;

namespace WebApi.Controllers
{
    /// <summary>
    /// ExceptionController
    /// </summary>
    [AllowAnonymous]
    [ApiController]
    public class ExceptionController : ODataController
    {
        /// <summary>
        /// Exception Handler
        /// </summary>
        /// <returns>Problem</returns>
        [Route("/exception")]
        public IActionResult Exception()
        {
            // Return only error message without detailed exception info.
            return this.Problem(title: this.HttpContext.Features.Get<IExceptionHandlerFeature>().Error.Message);
        }
    }
}