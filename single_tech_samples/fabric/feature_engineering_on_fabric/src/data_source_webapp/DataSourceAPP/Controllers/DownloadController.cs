using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.VisualBasic;
using System.Diagnostics;
using System.Xml.Linq;

namespace DataSourceAPP.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DownloadController : ControllerBase
    {
        //GET api/download/12345abc
        [HttpGet("{FileName}")]
        public IActionResult Download(string FileName)
        {
            var folder = "SourceFiles/TLC Trip Record Data";
            var filePath = Path.Combine(Directory.GetCurrentDirectory(), folder, FileName);
            var fileContents = System.IO.File.ReadAllBytes(filePath);
            var contentType = "text/plain";
            var fileDownloadName = FileName;
            return File(fileContents, contentType, fileDownloadName);

            // https://learn.microsoft.com/en-us/azure/app-service/deploy-configure-credentials?tabs=portal
            //az resource update--resource - group fsd1--name ftp --namespace Microsoft.Web --resource-type basicPublishingCredentialsPolicies --parent sites/fsd1-webapp --set properties.allow=true
            //az resource update --resource-group fsd1 --name scm --namespace Microsoft.Web --resource-type basicPublishingCredentialsPolicies --parent sites/fsd1-webapp --set properties.allow=true
        }
    }
}
