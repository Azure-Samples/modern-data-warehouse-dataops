param workbookDisplayName string = 'DQ Report'
param workbookType string = 'workbook'
param appinsights_name string
param location string = resourceGroup().location
var workbookSourceId = subscriptionResourceId('microsoft.insights/components', '${appinsights_name}')
var workbookId = guid(workbookSourceId)
var serializedData = '{"version":"Notebook/1.0","items":[{"type":3,"content":{"version":"KqlItem/1.0","query":"traces\\r\\n| where message==\\"verifychecks\\"\\r\\n| where customDimensions.check_name==\\"Parkingbay Data DQ\\" or customDimensions.check_name==\\"Transformed Data\\" \\r\\n| where severityLevel==\\"1\\" or severityLevel==\\"3\\"\\r\\n| where notempty(customDimensions.pipelinerunid)\\r\\n| project Status = iif(severityLevel==\\"1\\", \\"success\\", \\"failed\\"),CheckName=customDimensions.check_name,RunID = customDimensions.pipelinerunid, Details=customDimensions,Timestamp=timestamp","size":0,"aggregation":3,"timeContext":{"durationMs":604800000},"queryType":0,"resourceType":"microsoft.insights/components","visualization":"table","gridSettings":{"formatters":[{"columnMatch":"Status","formatter":11},{"columnMatch":"status","formatter":11}]}},"name":"query - 0"},{"type":3,"content":{"version":"KqlItem/1.0","query":"traces\\r\\n| where message==\\"verifychecks\\"\\r\\n| where customDimensions.check_name==\\"DQ checks\\"\\r\\n| where severityLevel==\\"1\\" or severityLevel==\\"3\\"\\r\\n| where notempty(customDimensions.pipelinerunid)\\r\\n| project Status = iif(severityLevel==\\"1\\", \\"Success\\", \\"Failed\\"),CheckName=customDimensions.check_name,RunID = customDimensions.pipelinerunid, Details=customDimensions,Timestamp=timestamp\\r\\n| summarize count() by Status \\r\\n| render piechart","size":0,"timeContext":{"durationMs":604800000},"queryType":0,"resourceType":"microsoft.insights/components","visualization":"piechart","tileSettings":{"showBorder":false,"titleContent":{"columnMatch":"Status","formatter":1},"leftContent":{"columnMatch":"count_","formatter":12,"formatOptions":{"palette":"auto"},"numberFormat":{"unit":17,"options":{"maximumSignificantDigits":3,"maximumFractionDigits":2}}}},"graphSettings":{"type":0,"topContent":{"columnMatch":"Status","formatter":1},"centerContent":{"columnMatch":"count_","formatter":1,"numberFormat":{"unit":17,"options":{"maximumSignificantDigits":3,"maximumFractionDigits":2}}}},"chartSettings":{"seriesLabelSettings":[{"seriesName":"success","label":"","color":"greenDark"},{"seriesName":"failed","color":"red"}]},"mapSettings":{"locInfo":"LatLong","sizeSettings":"count_","sizeAggregation":"Sum","legendMetric":"count_","legendAggregation":"Sum","itemColorSettings":{"type":"heatmap","colorAggregation":"Sum","nodeColorField":"count_","heatmapPalette":"greenRed"}}},"name":"query - 1"}],"fallbackResourceIds":["/subscriptions/XXX-XXX-XXX-XX-XXX/resourceGroups/XXXX/providers/microsoft.insights/components/XXXX"],"$schema":"https://github.com/Microsoft/Application-Insights-Workbooks/blob/master/schema/workbook.json"}'
var parsedData = json(serializedData)
var updatedWorkbookData = {
  version: parsedData.version
  items: parsedData.items
  fallbackResourceIds: [
    workbookSourceId
  ]
}
var reserializedData = string(updatedWorkbookData)

resource data_quality_workbook_resource 'microsoft.insights/workbooks@2022-04-01' = {
  name: workbookId
  location: location
  kind: 'shared'
  properties: {
    displayName: workbookDisplayName
    serializedData: reserializedData
    version: '1.0'
    sourceId: workbookSourceId
    category: workbookType
  }
  dependsOn: []
}

output workbookId string = data_quality_workbook_resource.id
