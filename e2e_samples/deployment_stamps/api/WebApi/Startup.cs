using System;
using System.IO;
using System.Linq;
using System.Reflection;
using WebApi.Models;
using Microsoft.AspNet.OData.Builder;
using Microsoft.AspNet.OData.Extensions;
using Microsoft.AspNet.OData.Routing.Conventions;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Formatters;
using Microsoft.Azure.Cosmos.Table;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Identity.Web;
using Microsoft.Net.Http.Headers;
using Microsoft.OData.Edm;
using Microsoft.OpenApi.Models;
using WebApi.Filters;
using WebApi.Repositories;

namespace WebApi
{
    /// <summary>
    /// This is the startup class.
    /// </summary>
    public class Startup
    {

        /// <summary>
        /// Cosmos Connection String.
        /// </summary>
        public const string ConfigKeyCosmosConnString = "CosmosConnectionString";

        /// <summary>
        /// Storage Connection String
        /// </summary>
        public const string ConfigKeyStorageConnString = "StorageConnectionString";

        /// <summary>
        /// Cosmos DB Name.
        /// </summary>
        public const string ConfigKeyCosmosDbName = "Cosmos:DbName";

        private ILogger logger;

        /// <summary>
        /// Initializes a new instance of the <see cref="Startup"/> class.
        /// </summary>
        /// <param name="configuration">Represents a implementation of IDeviceRepository.</param>
        public Startup(IConfiguration configuration)
        {
            this.Configuration = configuration;
        }

        /// <summary>
        /// Configuration of this startup
        /// </summary>
        public IConfiguration Configuration { get; }

        /// <summary>
        /// This method gets called by the runtime. Use this method to add services to the container.
        /// </summary>
        /// <param name="services">Represents a implementation of IServiceCollection.</param>
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddControllers(options =>
                options.Filters.Add<HttpRequestExceptionFilter>()).AddNewtonsoftJson();

            // Authentication
            services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
                .AddMicrosoftIdentityWebApi(this.Configuration.GetSection("AzureAd"));

            services.AddSwaggerGen(c =>
            {
                c.SwaggerDoc("v1", new OpenApiInfo { Title = "WebApi", Version = "v1" });
                var xmlFile = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
                var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
                c.IncludeXmlComments(xmlPath);
                c.EnableAnnotations();
            });

            // Table Storage
            CloudStorageAccount account = CloudStorageAccount.Parse(this.Configuration.GetConnectionString(ConfigKeyStorageConnString));
            CloudTableClient client = account.CreateCloudTableClient();
            services.AddSingleton<CloudTableClient>(sp => client);
            services.AddHttpClient();
            services.AddDbContext<CosmosContext>(
                options =>
                    options.UseCosmos(
                        this.Configuration.GetConnectionString(ConfigKeyCosmosConnString),
                        databaseName: this.Configuration.GetValue<string>(ConfigKeyCosmosDbName)));

            // The followings have to be "Scoped" due to DbContext which is not recommended to use as a singleton.
            // https://docs.microsoft.com/ja-jp/ef/core/dbcontext-configuration/
            services.AddScoped<IRepository, Repository>();

            services.AddOData();
            services.AddMemoryCache();
            services.AddMvcCore(options =>
            {
                foreach (var outputFormatter in options.OutputFormatters.OfType<OutputFormatter>().Where(x => x.SupportedMediaTypes.Count == 0))
                {
                    outputFormatter.SupportedMediaTypes.Add(new MediaTypeHeaderValue("application/prs.odatatestxx-odata"));
                }

                foreach (var inputFormatter in options.InputFormatters.OfType<InputFormatter>().Where(x => x.SupportedMediaTypes.Count == 0))
                {
                    inputFormatter.SupportedMediaTypes.Add(new MediaTypeHeaderValue("application/prs.odatatestxx-odata"));
                }
            });
        }

        /// <summary>
        /// This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        /// </summary>
        /// <param name="app">Represents a implementation of IApplicationBuilder.</param>
        /// <param name="env">Represents a implementation of IWebHostEnvironment.</param>
        /// <param name="logger">Represents a implementation of IWebHostEnvironment.</param>
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env, ILogger<Startup> logger)
        {
            this.logger = logger;
            this.logger.LogInformation($"Configure.");

            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
                app.UseSwagger();
                app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "CoreApi v1"));
            }
            else
            {
                app.UseExceptionHandler("/exception");
            }

            app.UseHttpsRedirection();

            app.UseRouting();
            app.UseAuthentication();
            app.UseAuthorization();
            app.UseEndpoints(endpoints =>
            {
                endpoints.EnableDependencyInjection();
                endpoints.Select().Filter().MaxTop(int.MaxValue).OrderBy();
                endpoints.MapODataRoute("v1", "v1", GetEdmModel(), new TenantIdHandler(), ODataRoutingConventions.CreateDefault());
            });
        }

        private static IEdmModel GetEdmModel()
        {
            ODataConventionModelBuilder builder = new ();
            builder.EntitySet<Device>("devices");
            builder.EntitySet<Telemetry>("telemetries");
            builder.EnableLowerCamelCase();
            return builder.GetEdmModel();
        }
    }
}
