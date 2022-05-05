using System;
using System.Linq;
using System.Text.RegularExpressions;
using Microsoft.AspNet.OData.Routing;
using Microsoft.OData;

namespace WebApi
{
    /// <summary>
    /// TenantId Path Handler
    /// </summary>
    public class TenantIdHandler : DefaultODataPathHandler
    {
        /// <summary>
        /// Parse URI.
        /// </summary>
        /// <param name="serviceRoot">serviceRoot.</param>
        /// <param name="odataPath">odataPath.</param>
        /// <param name="requestContainer">requestContainer.</param>
        /// <returns>ODataPath.</returns>
        public override ODataPath Parse(string serviceRoot, string odataPath, IServiceProvider requestContainer)
        {
            odataPath = this.ParseOdataPath(serviceRoot, odataPath, requestContainer);

            var path = base.Parse(serviceRoot, odataPath, requestContainer);
            return path;
        }

        /// <summary>
        /// Convert an instance of ODataPath to Link.
        /// </summary>
        /// <param name="path">odataPath.</param>
        /// <returns>OData Link.</returns>
        public override string Link(ODataPath path)
        {
            return base.Link(path);
        }

        /// <summary>
        /// Parse OdataPath
        /// </summary>
        /// <param name="serviceRoot">serviceRoot.</param>
        /// <param name="odataPath">odataPath.</param>
        /// <param name="requestContainer">requestContainer.</param>
        /// <returns>Handled URI</returns>
        internal string ParseOdataPath(string serviceRoot, string odataPath, IServiceProvider requestContainer)
        {
            string guidPattern = @"(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{12}(\}){0,1}";

            Match tenantIdMatch = Regex.Match(odataPath, guidPattern, RegexOptions.IgnoreCase);
            if (tenantIdMatch.Success)
            {
                odataPath = odataPath.Split('?')[0];
                odataPath = odataPath.Replace(tenantIdMatch.Value + "/", string.Empty);

                while (true)
                {
                    try
                    {
                        ODataPath path = base.Parse(serviceRoot, odataPath, requestContainer);
                        if (!path.PathTemplate.EndsWith("unresolved"))
                        {
                            break;
                        }
                    }
                    catch (ODataException)
                    {
                        // Ignore parse error to continue next route
                    }

                    odataPath = odataPath.Replace(odataPath.Split("/").First(), string.Empty);
                    var idMatch = Regex.Match(odataPath, guidPattern, RegexOptions.IgnoreCase);
                    if (idMatch.Success)
                    {
                        odataPath = odataPath.Replace("/" + idMatch.Value, string.Empty);
                    }
                    else
                    {
                        break;
                    }
                }

                return odataPath;
            }
            else
            {
                return odataPath;
            }
        }
    }
}
