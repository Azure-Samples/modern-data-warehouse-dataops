param project string
@allowed([
  'dev'
  'stg'
  'prod'
])
param env string
param location string = resourceGroup().location
param deployment_id string
param datafactory_name string
param sql_server_name string
param sql_database_name string

resource dashboard 'Microsoft.Portal/dashboards@2020-09-01-preview' = {
  name: '${project}-dashboard-${env}-${deployment_id}'
  location: location
  tags: {
    DisplayName: 'Azure Dashboard'
    Environment: env
  }
  properties: {
    lenses: [
      {
        order: 0
        parts: [
          {
            position: {
              x: 0
              y: 0
              rowSpan: 4
              colSpan: 6
            }
            metadata: {
              inputs: [
                {
                  name: 'options'
                  isOptional: true
                }
                {
                  name: 'sharedTimeRange'
                  isOptional: true
                }
              ]
              #disable-next-line BCP036
              type: 'Extension/HubsExtension/PartType/MonitorChartPart'
              settings: {
                content: {
                  options: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DataFactory/factories/${datafactory_name}'
                          }
                          name: 'PipelineFailedRuns'
                          aggregationType: 1
                          namespace: 'microsoft.datafactory/factories'
                          metricVisualization: {
                            displayName: 'Failed pipeline runs metrics'
                            resourceDisplayName: datafactory_name
                          }
                        }
                      ]
                      title: 'Count Failed activity runs metrics for ${datafactory_name}'
                      titleKind: 1
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                        disablePinning: true
                      }
                    }
                  }
                }
              }
            }
          }
          {
            position: {
              x: 6
              y: 0
              rowSpan: 4
              colSpan: 6
            }
            metadata: {
              inputs: [
                {
                  name: 'options'
                  isOptional: true
                }
                {
                  name: 'sharedTimeRange'
                  isOptional: true
                }
              ]
              #disable-next-line BCP036
              type: 'Extension/HubsExtension/PartType/MonitorChartPart'
              settings: {
                content: {
                  options: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DataFactory/factories/${datafactory_name}'
                          }
                          name: 'PipelineSucceededRuns'
                          aggregationType: 1
                          namespace: 'microsoft.datafactory/factories'
                          metricVisualization: {
                            displayName: 'Succeeded pipeline runs metrics'
                            resourceDisplayName: datafactory_name
                          }
                        }
                      ]
                      title: 'Sum Succeeded pipeline runs metrics for ${datafactory_name}'
                      titleKind: 1
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                        disablePinning: true
                      }
                    }
                  }
                }
              }
            }
          }
          {
            position: {
              x: 0
              y: 4
              rowSpan: 4
              colSpan: 6
            }
            metadata: {
              inputs: [
                {
                  name: 'options'
                  isOptional: true
                }
                {
                  name: 'sharedTimeRange'
                  isOptional: true
                }
              ]
              #disable-next-line BCP036
              type: 'Extension/HubsExtension/PartType/MonitorChartPart'
              settings: {
                content: {
                  options: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Sql/servers/${sql_server_name}/databases/${sql_database_name}'
                          }
                          name: 'cpu_percent'
                          aggregationType: 4
                          namespace: 'microsoft.sql/servers/databases'
                          metricVisualization: {
                            displayName: 'CPU percentage'
                          }
                        }
                        {
                          resourceMetadata: {
                            id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Sql/servers/${sql_server_name}/databases/${sql_database_name}'
                          }
                          name: 'connection_failed'
                          aggregationType: 1
                          namespace: 'microsoft.sql/servers/databases'
                          metricVisualization: {
                            displayName: 'Failed Connections'
                          }
                        }
                      ]
                      title: 'Avg CPU percentage and Sum Failed Connections for ${sql_database_name}'
                      titleKind: 1
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                        disablePinning: true
                      }
                    }
                  }
                }
              }
            }
          }
        ]
      }
    ]
    metadata: {
      model: {}
    }
  }
}
