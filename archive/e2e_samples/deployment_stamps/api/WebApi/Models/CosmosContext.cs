using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace WebApi.Models
{
    /// <summary>
    /// This is the CosmosContext class
    /// </summary>
    public class CosmosContext : DbContext
    {
        private const string ConfigKeyCosmosContainerTenantDetails = "Cosmos:ContainerNameTenantDetails";
        private const string ConfigKeyCosmosContainerDefault = "Cosmos:ContainerNameDefault";

        private readonly IConfiguration configuration;

        /// <summary>
        /// Initializes a new instance of the <see cref="CosmosContext"/> class.
        /// </summary>
        /// <param name="options">Represents a implementation of DbContextOptions.</param>
        /// <param name="configuration">Represents a implementation of IConfiguration.</param>
        public CosmosContext(DbContextOptions<CosmosContext> options, IConfiguration configuration)
            : base(options)
        {
            this.configuration = configuration;
        }

        /// <summary>
        /// Represents Devices.
        /// </summary>
        public DbSet<Device> Devices { get; set; }

        
        /// <summary>
        /// Creating a Entity Framework Model.
        /// </summary>
        /// <param name="modelBuilder">The builder being used to construct the model for this context.</param>
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.HasDefaultContainer(this.configuration.GetValue<string>(ConfigKeyCosmosContainerDefault));
            modelBuilder.Entity<Device>()
                .ToContainer(this.configuration.GetValue<string>(ConfigKeyCosmosContainerTenantDetails))
                .HasPartitionKey(c => c.TenantId)
                .HasDiscriminator<string>(nameof(Device.Type));

            modelBuilder.Entity<Device>().Property(p => p.Id).ToJsonProperty("id");
            modelBuilder.Entity<Device>().Property(p => p.DeviceId).ToJsonProperty("deviceId");
            modelBuilder.Entity<Device>().Property(p => p.TenantId).ToJsonProperty("tenantId");
            modelBuilder.Entity<Device>().Property(p => p.DeviceName).ToJsonProperty("deviceName");
            modelBuilder.Entity<Device>().Property(p => p.DeviceType).ToJsonProperty("deviceType");
            modelBuilder.Entity<Device>().Property(p => p.Type).ToJsonProperty("type");
        }
    }
}
