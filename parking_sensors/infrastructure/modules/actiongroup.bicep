param project string
@allowed([
  'dev'
  'stg'
  'prod'
])
param env string
param deployment_id string
param email_id string

resource actiongroup 'Microsoft.Insights/actionGroups@2021-09-01' = {
  name: '${project}-emailactiongroup-${env}-${deployment_id}'
  location: 'global'
  tags: {
    DisplayName: 'Action Group'
    Environment: env
  }
  properties: {
    groupShortName: 'emailgroup'
    emailReceivers: [
      {
        emailAddress: email_id
        name: 'emailaction'
        useCommonAlertSchema: true
      }
    ]
    enabled: true
  }
}

output actiongroup_id string = actiongroup.id
