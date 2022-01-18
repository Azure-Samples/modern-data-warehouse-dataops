param
(
    [parameter(Mandatory = $false)] [String] $rootFolder='/home/vsts/work/1/s/e2e_samples/parking_sensors_synapse/synapse/workspace/sqlscript',
    [parameter(Mandatory = $false)] [String] $armTemplate
)

# Delete contents from existing deploy_sql file.
if (Test-Path -Path "$rootFolder/extracted_sql"){
    Clear-Content "$rootFolder/extracted_sql/deploy_sql.sql"
}

$sqlfiles = Get-ChildItem -PATH "$rootFolder/"drop_external_tables.json
write-host $($sqlfiles)
foreach ( $filename in $sqlfiles.name)
{   
    
    $jsonfile = Get-Content -PATH "$rootFolder/$filename" | ConvertFrom-Json
    $sqlscript = $($jsonfile.properties.content.query)
    $scriptFolderName = $($jsonfile.properties.folder.name)
    #Serverless/Drop_Statements

    if (Test-Path -Path "$rootFolder/extracted_sql"){

        }else {
            New-Item -ItemType Directory -Force -Path "$rootFolder/extracted_sql"
        }

        $sqlscript >> "$rootFolder/extracted_sql/deploy_sql.sql"
     
    
}

$sqlfiles = Get-ChildItem -PATH "$rootFolder/"drop_external_datasources.json
write-host $($sqlfiles)
foreach ( $filename in $sqlfiles.name)
{   
    
    $jsonfile = Get-Content -PATH "$rootFolder/$filename" | ConvertFrom-Json
    $sqlscript = $($jsonfile.properties.content.query)
    $scriptFolderName = $($jsonfile.properties.folder.name)
    #Serverless/Drop_Statements

    if (Test-Path -Path "$rootFolder/extracted_sql"){

        }else {
            New-Item -ItemType Directory -Force -Path "$rootFolder/extracted_sql"
        }

        $sqlscript >> "$rootFolder/extracted_sql/deploy_sql.sql"
     
    
}

$sqlfiles = Get-ChildItem -PATH "$rootFolder/"drop_database_scoped_credentials.json
write-host $($sqlfiles)
foreach ( $filename in $sqlfiles.name)
{   
    
    $jsonfile = Get-Content -PATH "$rootFolder/$filename" | ConvertFrom-Json
    $sqlscript = $($jsonfile.properties.content.query)
    $scriptFolderName = $($jsonfile.properties.folder.name)
    #Serverless/Drop_Statements

    if (Test-Path -Path "$rootFolder/extracted_sql"){

        }else {
            New-Item -ItemType Directory -Force -Path "$rootFolder/extracted_sql"
        }

        $sqlscript >> "$rootFolder/extracted_sql/deploy_sql.sql"
     
}

$sqlfiles = Get-ChildItem -PATH "$rootFolder/"drop_external_file_formats.json
write-host $($sqlfiles)
foreach ( $filename in $sqlfiles.name)
{   
    
    $jsonfile = Get-Content -PATH "$rootFolder/$filename" | ConvertFrom-Json
    $sqlscript = $($jsonfile.properties.content.query)
    $scriptFolderName = $($jsonfile.properties.folder.name)
    #Serverless/Drop_Statements

    if (Test-Path -Path "$rootFolder/extracted_sql"){

        }else {
            New-Item -ItemType Directory -Force -Path "$rootFolder/extracted_sql"
        }

        $sqlscript >> "$rootFolder/extracted_sql/deploy_sql.sql"
     
}

# Get Security Objects Definiation

$sqlfiles = Get-ChildItem -PATH "$rootFolder/"*.json
foreach ( $filename in $sqlfiles.name)
{   
    
    $jsonfile = Get-Content -PATH "$rootFolder/$filename" | ConvertFrom-Json
    $sqlscript = $($jsonfile.properties.content.query)
    $scriptFolderName = $($jsonfile.properties.folder.name)
    #Serverless/Drop_Statements

    if ($scriptFolderName -eq 'Serverless/Security')
    {
        write-host $($filename)
        $scriptName = $($jsonfile.name)
         
        if (Test-Path -Path "$rootFolder/extracted_sql"){

        }else {
            New-Item -ItemType Directory -Force -Path "$rootFolder/extracted_sql"
        }

        $sqlscript >> "$rootFolder/extracted_sql/deploy_sql.sql"
    } 
    
}

# Get External Sources Definiation

$sqlfiles = Get-ChildItem -PATH "$rootFolder/"*.json
foreach ( $filename in $sqlfiles.name)
{   
    
    $jsonfile = Get-Content -PATH "$rootFolder/$filename" | ConvertFrom-Json
    $sqlscript = $($jsonfile.properties.content.query)
    $scriptFolderName = $($jsonfile.properties.folder.name)
    #Serverless/Drop_Statements

    if ($scriptFolderName -eq 'Serverless/External Resources')
    {
        write-host $($filename)
        $scriptName = $($jsonfile.name)
         
        if (Test-Path -Path "$rootFolder/extracted_sql"){

        }else {
            New-Item -ItemType Directory -Force -Path "$rootFolder/extracted_sql"
        }

        $sqlscript >> "$rootFolder/extracted_sql/deploy_sql.sql"
    } 
    
}

# Get External tables , views create statements

$sqlfiles = Get-ChildItem -PATH "$rootFolder/"*.json
foreach ( $filename in $sqlfiles.name)
{   
    
    $jsonfile = Get-Content -PATH "$rootFolder/$filename" | ConvertFrom-Json
    $sqlscript = $($jsonfile.properties.content.query)
    $scriptFolderName = $($jsonfile.properties.folder.name)
    #Serverless/Drop_Statements

    if ($scriptFolderName -eq 'Serverless')
    {
        write-host $($filename)
        $scriptName = $($jsonfile.name)
         
        if (Test-Path -Path "$rootFolder/extracted_sql"){

        }else {
            New-Item -ItemType Directory -Force -Path "$rootFolder/extracted_sql"
        }

        $sqlscript >> "$rootFolder/extracted_sql/deploy_sql.sql"
    } 
    
}