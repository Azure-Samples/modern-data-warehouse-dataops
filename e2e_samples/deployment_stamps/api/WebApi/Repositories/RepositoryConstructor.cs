using Microsoft.Azure.Cosmos.Table;
using Microsoft.Azure.Devices;
using WebApi.Models;

namespace WebApi.Repositories
{
    /// <summary>
    /// This is the Repository constructor
    /// </summary>
    public partial class Repository : IRepository
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="Repository"/> class.
        /// </summary>
        /// <param name="cosmosContext">Instance of CosmosContext.</param>
        /// <param name="tableClient">Instance of CloudTableClient.</param>
        public Repository(CosmosContext cosmosContext, CloudTableClient tableClient)
        {
            this.cosmosContext = cosmosContext;
            this.tableClient = tableClient;
        }
    }
}
