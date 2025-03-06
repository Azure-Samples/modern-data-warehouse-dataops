#!/bin/bash

# Variables
RESOURCE_GROUP=$1
SQL_SERVER=$2
DATABASE=$3
FUNCTION_APP=$4

# Get Principal ID of the Managed Identity
PRINCIPAL_ID=$(az webapp show --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --query identity.principalId -o tsv)

echo "Principal ID: $PRINCIPAL_ID"
echo "sql server: $SQL_SERVER"
echo "database: $DATABASE"

# Run SQL commands to assign roles
sqlcmd -S "$SQL_SERVER.database.windows.net" -d $DATABASE -G -l 30 -Q "
    CREATE USER [$PRINCIPAL_ID] FROM EXTERNAL PROVIDER;
    ALTER ROLE db_datareader ADD MEMBER [$PRINCIPAL_ID];
    ALTER ROLE db_datawriter ADD MEMBER [$PRINCIPAL_ID];
"
