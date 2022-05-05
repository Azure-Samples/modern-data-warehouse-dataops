using System.Collections.Generic;
using System.Linq;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Identity.Web.Resource;

namespace WebApi.CustomAttributes
{
    /// <summary>
    /// Authorize by Tenant Id.
    /// </summary>
    public class AuthorizeByTenantIdAttribute : AuthorizeAttribute, IAuthorizationFilter
    {
        /// <summary>
        /// Roles.
        /// </summary>
        public new string Roles { get; set; }

        /// <summary>
        /// OnAuthorization.
        /// </summary>
        /// <param name="context">AuthorizationFilterContext.</param>
        public void OnAuthorization(AuthorizationFilterContext context)
        {
            string tenantId = context.HttpContext.Request.RouteValues["tenantId"]?.ToString();
            if (string.IsNullOrEmpty(tenantId))
            {
                context.Result = new UnauthorizedResult();
                return;
            }

            // Check if the user is authenticated in expected tenant
            string claimType = "http://schemas.microsoft.com/identity/claims/identityprovider";
            if(!context.HttpContext.User.Claims.Any(x => x.Type == claimType)){
                claimType = "iss";
            }
           
            if (context.HttpContext.User.Claims
                .Where(x => x.Type == claimType
                && x.Value.Contains(tenantId.ToString()))
                .Count() == 0)
            {
                // If a user doesn't belongs to the tenant specified in URI, then return unauthorized status code.
                context.Result = new UnauthorizedResult();
                return;
            }
           
            
            // Combine roles from method and controller, then flatten them.
            List<string> rolesList = context.ActionDescriptor.EndpointMetadata
                .Where(x => x.ToString() == typeof(AuthorizeByTenantIdAttribute).FullName)
                .Select(x => (x as AuthorizeByTenantIdAttribute).Roles)
                .Where(roles => !string.IsNullOrEmpty(roles)).SelectMany(x => x.Split(',')).ToList();
            context.HttpContext.ValidateAppRole(rolesList.ToArray());

            return;
        }
    }
}