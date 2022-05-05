# Input bindings are passed in via param block.
param([Byte[]] $inputBlob, $triggerMetadata )

# write-output "ENVIRONMENT VARIABLES"
# $result = ls env: | out-string
# write-output $result

# Get the current universal time in the default string format.
$currentUTCtime = (Get-Date).ToUniversalTime()
$blobPath = $triggerMetadata.BlobTrigger

[int]$maxRetries = 3
[int]$retryDelay = 5


# Write an information log with the current time.
Write-Information "PowerShell blob trigger function ran! TIME (UTC): $currentUTCtime"
Write-Information "Triggered by: $blobPath"
# Description: This script shows how to post Az.Storage Analytics logs to Azure Log Analytics workspace
#
# Before running this script:
#     - Create or have a storage account, and enable analytics logs
#     - Create Azure Log Analytics workspace
#     - Change the following values:
#           - $CustomerId
#           - $SharedKey
#           - $LogType
#
# What this script does:
#     - Use Storage Powershell to enumerate all log blobs in $logs container in a storage account
#     - Use Storage Powershell to read all log blobs
#     - Convert each log line in the log blob to JSON payload
#     - Use Log Analytics HTTP Data Collector API to post JSON payload to Log Analytics workspace

#
# Reference:
#     - Log Analytics Data Collector API: https://docs.microsoft.com/en-us/azure/log-analytics/log-analytics-data-collector-api
#

#Login-AzAccount


# Replace with your Workspace Id
# Find in: Azure Portal > Log Analytics > {Your workspace} > Advanced Settings > Agents Management > WORKSPACE ID
$CustomerId = $env:LOGANALYTICS_WORKSPACEID

# Replace with your Primary Key
# Find in: Azure Portal > Log Analytics > {Your workspace} > Advanced Settings > Agents Management > PRIMARY KEY
$SharedKey = $env:LOGANALYTICS_KEY

# Specify the name of the record type that you'll be creating
# After logs are sent to the workspace, you will use "MyStorageLogs1_CL" as stream to query.
$LogType = "DataLakeLogs"

# You can use an optional field to specify the timestamp from the data.
# If the time field is not specified, Log Analytics assumes the time is the message ingestion time
$TimeStampField = ""

#
# Create the function to create the authorization signature
#
Function Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
{
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)

    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId,$encodedHash
    return $authorization
}

#
# Create the function to create and post the request
#
Function Publish-LogAnalyticsData($customerId, $sharedKey, $body, $logType)
{
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $body.Length
    $signature = Build-Signature `
        -customerId $customerId `
        -sharedKey $sharedKey `
        -date $rfc1123date `
        -contentLength $contentLength `
        -method $method `
        -contentType $contentType `
        -resource $resource
    $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

    $headers = @{
        "Authorization" = $signature;
        "Log-Type" = $logType;
        "x-ms-date" = $rfc1123date;
        "time-generated-field" = $TimeStampField;
    }

    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
    return $response.StatusCode
}

# Submit the data to the API endpoint
#Publish-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $logType

#
# Convert ; to "%3B" between " in the csv line to prevent wrong values output after split with ;
#
Function ConvertSemicolonToURLEncoding([String] $InputText)
{
    $ReturnText = ""
    $chars = $InputText.ToCharArray()
    $StartConvert = $false

    foreach($c in $chars)
    {
        if($c -eq '"') {
            $StartConvert = ! $StartConvert
        }

        if($StartConvert -eq $true -and $c -eq ';')
        {
            $ReturnText += "%3B"
        } else {
            $ReturnText += $c
        }
    }

    return $ReturnText
}

#
# If a text doesn't start with ", add "" for json value format
# If a text contains "%3B", replace it back to ";"
#
Function FormalizeJsonValue($Text)
{
    $Text1 = ""
    if($Text.IndexOf("`"") -eq 0) { $Text1=$Text } else {$Text1="`"" + $Text+ "`""}

    if($Text1.IndexOf("%3B") -ge 0) {
        $ReturnText = $Text1.Replace("%3B", ";")
    } else {
        $ReturnText = $Text1
    }
    return $ReturnText
}

Function ConvertLogLineToJson([String] $logLine)
{
    #Convert semicolon to %3B in the log line to avoid wrong split with ";"
    $logLineEncoded = ConvertSemicolonToURLEncoding($logLine)

    $elements = $logLineEncoded.split(';')

    $FormattedElements = New-Object System.Collections.ArrayList

    foreach($element in $elements)
    {
        # Validate if the text starts with ", and add it if not
        $NewText = FormalizeJsonValue($element)

        $FormattedElements.Add($NewText) | Out-Null
    }

    $Columns = (
        "version-number",
        "request-start-time",
        "operation-type",
        "request-status",
        "http-status-code",
        "end-to-end-latency-in-ms",
        "server-latency-in-ms",
        "authentication-type",
        "requester-account-name",
        "owner-account-name",
        "service-type",
        "request-url",
        "requested-object-key",
        "request-id-header",
        "operation-count",
        "requester-ip-address",
        "request-version-header",
        "request-header-size",
        "request-packet-size",
        "response-header-size",
        "response-packet-size",
        "request-content-length",
        "request-md5",
        "server-md5",
        "etag-identifier",
        "last-modified-time",
        "conditions-used",
        "user-agent-header",
        "referrer-header",
        "client-request-id"
    )

    # Propose json payload
    $logJson = "[{";
    For($i = 0; $i -lt $Columns.Length; $i++)
    {
        $logJson += "`"" + $Columns[$i] + "`":" + $FormattedElements[$i]
        if($i -lt $Columns.Length - 1) {
            $logJson += ","
        }
    }
    $logJson += "}]";

    return $logJson
}

$successPost = 0
$failedPost = 0
$lines = [System.Text.Encoding]::UTF8.GetString($inputBlob)
# Enumerate log lines in each log blob
$lineCount = 0;
foreach($line in $lines.Split("`n"))
{
    $lineCount++
    if ([string]::IsNullOrWhiteSpace($line)) {
        continue
    }
    $json = ConvertLogLineToJson($line)

    $stopRetries = $false
    [int]$retryCount = 0
    do {
        $response = Publish-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $logType
        if ($response -eq "200") {
            $successPost++
            break
        } else {
            if ($retryCount -gt $maxRetries) {
                Write-Error "> Failed to post one line to Log Analytics workspace: line number $lineCount"
                $failedPost++
                $stopRetries = $true
            } else {
                Write-Warning "> Failed to post one line to Log Analytics workspace: line number $lineCount. Retrying"
                Start-Sleep -Seconds $retryDelay
                $retryCount++
            }
        }
    } while ($stopRetries -eq $false)
}
if ($failedPost -eq 0) {
    Write-Information "> Log lines posted to Log Analytics workspace: success = $successPost lines"
} else {
    Write-Error "> Log lines posted to Log Analytics workspace: success = $successPost lines, failure = $failedPost lines"
}