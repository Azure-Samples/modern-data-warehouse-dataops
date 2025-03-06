#!/bin/bash

# Variables
RESOURCE_GROUP=$1
SQL_SERVER=$2
DATABASE=$3
FUNCTION_APP=$4

echo "Principal: $FUNCTION_APP"
echo "sql server: $SQL_SERVER"
echo "database: $DATABASE"

# Run SQL commands to assign roles
sqlcmd -S "$SQL_SERVER.database.windows.net" -d $DATABASE -G -l 30 -Q "
    CREATE USER [$FUNCTION_APP] FROM EXTERNAL PROVIDER;
    ALTER ROLE db_datareader ADD MEMBER [$FUNCTION_APP];
    ALTER ROLE db_datawriter ADD MEMBER [$FUNCTION_APP];
"
