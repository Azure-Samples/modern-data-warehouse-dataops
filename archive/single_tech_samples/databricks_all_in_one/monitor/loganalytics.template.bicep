param logAnalyticsWkspName string = toLower('spark-monitoring-${uniqueString(resourceGroup().name)}')
param logAnalyticsWkspLocation string = resourceGroup().location
@allowed([
  'Free'
  'Standalone'
  'PerNode'
  'PerGB2018'
])
@description('Service Tier: Free, Standalone, PerNode, or PerGB2018')
param logAnalyticsWkspSku string = 'Standalone'

@minValue(7)
@maxValue(730)
@description('Number of days of retention. Free plans can only have 7 days, Standalone and Log Analytics plans include 30 days for free')
param logAnalyticsWkspRentationDays int = 30

var queries = [
  {
    displayName: 'Stage Latency Per Stage (Stage Duration)'
    query: 'let results=SparkListenerEvent_CL\n|  where  Event_s  contains "SparkListenerStageSubmitted"\n| extend metricsns=columnifexists("Properties_spark_metrics_namespace_s",Properties_spark_app_id_s)\r\n| extend apptag=iif(isnotempty(metricsns),metricsns,Properties_spark_app_id_s)\r\n| project Stage_Info_Stage_ID_d,apptag,TimeGenerated,Properties_spark_databricks_clusterUsageTags_clusterName_s\n| order by TimeGenerated asc  nulls last \n| join kind= inner (\n    SparkListenerEvent_CL\n    |  where Event_s contains "SparkListenerStageCompleted"  \n    | extend stageDuration=Stage_Info_Completion_Time_d - Stage_Info_Submission_Time_d\n) on Stage_Info_Stage_ID_d;\nresults\n | extend slice = strcat(Properties_spark_databricks_clusterUsageTags_clusterName_s,"-",apptag," ",Stage_Info_Stage_Name_s) \n| extend stageDuration=Stage_Info_Completion_Time_d - Stage_Info_Submission_Time_d \n| summarize percentiles(stageDuration,10,30,50,90)  by bin(TimeGenerated,  1m), slice\n| order by TimeGenerated asc nulls last\n\n'
  }
  {
    displayName: 'Stage Throughput Per Stage'
    query: 'let results=SparkListenerEvent_CL\n|  where  Event_s  contains "SparkListenerStageSubmitted"\n| extend metricsns=columnifexists("Properties_spark_metrics_namespace_s",Properties_spark_app_id_s)\r\n| extend apptag=iif(isnotempty(metricsns),metricsns,Properties_spark_app_id_s)\r\n| project \nStage_Info_Stage_ID_d,apptag,TimeGenerated,Properties_spark_databricks_clusterUsageTags_clusterName_s\n| order by TimeGenerated asc  nulls last \n| join kind= inner (\n    SparkListenerEvent_CL\n    |  where Event_s contains "SparkListenerStageCompleted"  \n) on Stage_Info_Stage_ID_d;\nresults\n | extend slice = strcat("# StagesCompleted ",Properties_spark_databricks_clusterUsageTags_clusterName_s,"-",\napptag," ",Stage_Info_Stage_Name_s) \n| summarize StagesCompleted=count(Event_s) by bin(TimeGenerated,1m), slice\n| order by TimeGenerated asc nulls last\n\n'
  }
  {
    displayName: 'Tasks Per Stage'
    query: 'let results=SparkListenerEvent_CL\n|  where  Event_s  contains "SparkListenerStageSubmitted"\n| extend metricsns=columnifexists("Properties_spark_metrics_namespace_s",Properties_spark_app_id_s)\r\n| extend apptag=iif(isnotempty(metricsns),metricsns,Properties_spark_app_id_s)\r\n| project \nStage_Info_Stage_ID_d,apptag,TimeGenerated,Properties_spark_databricks_clusterUsageTags_clusterName_s\n| order by TimeGenerated asc  nulls last \n| join kind= inner (\n    SparkListenerEvent_CL\n    |  where Event_s contains "SparkListenerStageCompleted"  \n) on Stage_Info_Stage_ID_d;\nresults\n | extend slice = strcat("# StagesCompleted ",Properties_spark_databricks_clusterUsageTags_clusterName_s,"-",apptag," ",Stage_Info_Stage_Name_s)\n| extend slice=strcat(Properties_spark_databricks_clusterUsageTags_clusterName_s,"-",apptag," ",Stage_Info_Stage_Name_s) \n| project Stage_Info_Number_of_Tasks_d,slice,TimeGenerated \n| order by TimeGenerated asc nulls last\n\n'
  }
  {
    displayName: '% Serialize Time Per Executor'
    query: 'let results = SparkMetric_CL\n|  where name_s contains "executor.resultserializationtime" \n| extend sname=split(name_s, ".") \n| extend executor=strcat(sname[0],".",sname[1])\n| project TimeGenerated , setime=count_d , executor ,name_s\n| join kind= inner (\nSparkMetric_CL\n|  where name_s contains "executor.RunTime"\n| extend sname=split(name_s, ".") \n| extend executor=strcat(sname[0],".",sname[1])\n| project TimeGenerated , runTime=count_d , executor ,name_s\n) on executor, TimeGenerated;\nresults\n| extend serUsage=(setime/runTime)*100\n| summarize SerializationCpuTime=percentile(serUsage,90) by bin(TimeGenerated, 1m), executor\n| order by TimeGenerated asc nulls last\n| render timechart '
  }
  {
    displayName: 'Shuffle Bytes Read Per Executor'
    query: 'let results=SparkMetric_CL\n|  where  name_s  contains "executor.shuffleTotalBytesRead"\n| extend sname=split(name_s, ".") \n| extend executor=strcat(sname[0],".",sname[1])\n| summarize MaxShuffleWrites=max(count_d)  by bin(TimeGenerated,  1m), executor \n| order by TimeGenerated asc  nulls last \n| join kind= inner (\n    SparkMetric_CL\n    |  where name_s contains "executor.shuffleTotalBytesRead"\n    | extend sname=split(name_s, ".") \n    | extend executor=strcat(sname[0],".",sname[1])\n| summarize MinShuffleWrites=min(count_d)  by bin(TimeGenerated,  1m), executor\n) on executor, TimeGenerated;\nresults\n| extend ShuffleBytesWritten=MaxShuffleWrites-MinShuffleWrites \n| summarize max(ShuffleBytesWritten)   by bin(TimeGenerated,  1m), executor\n| order by TimeGenerated asc nulls last\n'
  }
  {
    displayName: 'Error Traces (Bad Record Or Bad Files)'
    query: 'SparkListenerEvent_CL\r\n| where Level contains "Error"\r\n| project TimeGenerated , Message  \r\n'
  }
  {
    displayName: 'Task Shuffle Bytes Written'
    query: 'let result=SparkListenerEvent_CL\n| where  Event_s  contains "SparkListenerStageSubmitted"\n| extend metricsns=columnifexists("Properties_spark_metrics_namespace_s",Properties_spark_app_id_s)\r\n| extend apptag=iif(isnotempty(metricsns),metricsns,Properties_spark_app_id_s)\r\n| project Stage_Info_Stage_ID_d,Stage_Info_Stage_Name_s,Stage_Info_Submission_Time_d,Event_s,TimeGenerated,Properties_spark_databricks_clusterUsageTags_clusterName_s,apptag\n| order by TimeGenerated asc  nulls last \n| join kind= inner (\n    SparkListenerEvent_CL\n    |  where Event_s contains "SparkListenerTaskEnd"\n    | where Task_End_Reason_Reason_s contains "Success"\n    | project Task_Info_Launch_Time_d,Stage_ID_d,Task_Info_Task_ID_d,Event_s,\n              Task_Metrics_Executor_Deserialize_Time_d,Task_Metrics_Shuffle_Read_Metrics_Fetch_Wait_Time_d,\n              Task_Metrics_Executor_Run_Time_d,Task_Metrics_Shuffle_Write_Metrics_Shuffle_Write_Time_d,\n              Task_Metrics_Result_Serialization_Time_d,Task_Info_Getting_Result_Time_d,\n              Task_Metrics_Shuffle_Read_Metrics_Remote_Bytes_Read_d,Task_Metrics_Shuffle_Write_Metrics_Shuffle_Bytes_Written_d,\n              Task_Metrics_JVM_GC_Time_d,TimeGenerated\n) on $left.Stage_Info_Stage_ID_d == $right.Stage_ID_d;\nresult\n| extend schedulerdelay = Task_Info_Launch_Time_d - Stage_Info_Submission_Time_d\n| extend name=strcat("SchuffleBytesWritten ",Properties_spark_databricks_clusterUsageTags_clusterName_s,"-",apptag," ",Stage_Info_Stage_Name_s)\n| summarize percentile(Task_Metrics_Shuffle_Write_Metrics_Shuffle_Bytes_Written_d,90) by bin(TimeGenerated,1m),name\n| order by TimeGenerated asc nulls last;\n\n'
  }
  {
    displayName: 'Task Input Bytes Read'
    query: 'let result=SparkListenerEvent_CL\n| where Event_s  contains "SparkListenerStageSubmitted"\n| extend metricsns=columnifexists("Properties_spark_metrics_namespace_s",Properties_spark_app_id_s)\r\n| extend apptag=iif(isnotempty(metricsns),metricsns,Properties_spark_app_id_s)\r\n| project Stage_Info_Stage_ID_d,Stage_Info_Stage_Name_s,Stage_Info_Submission_Time_d,Event_s,TimeGenerated,Properties_spark_databricks_clusterUsageTags_clusterName_s,apptag\n| order by TimeGenerated asc  nulls last \n| join kind= inner (\n    SparkListenerEvent_CL\n    |  where Event_s contains "SparkListenerTaskEnd"\n    | where Task_End_Reason_Reason_s contains "Success"\n    | project Task_Info_Launch_Time_d,Stage_ID_d,Task_Info_Task_ID_d,Event_s,\n              Task_Metrics_Executor_Deserialize_Time_d,Task_Metrics_Shuffle_Read_Metrics_Fetch_Wait_Time_d,\n              Task_Metrics_Executor_Run_Time_d,Task_Metrics_Shuffle_Write_Metrics_Shuffle_Write_Time_d,\n              Task_Metrics_Result_Serialization_Time_d,Task_Info_Getting_Result_Time_d,\n              Task_Metrics_Shuffle_Read_Metrics_Remote_Bytes_Read_d,Task_Metrics_Shuffle_Write_Metrics_Shuffle_Bytes_Written_d,\n              Task_Metrics_JVM_GC_Time_d,Task_Metrics_Input_Metrics_Bytes_Read_d,TimeGenerated\n) on $left.Stage_Info_Stage_ID_d == $right.Stage_ID_d;\nresult\n| extend name=strcat("InputBytesRead ",Properties_spark_databricks_clusterUsageTags_clusterName_s,"-",apptag," ",Stage_Info_Stage_Name_s)\n| summarize percentile(Task_Metrics_Input_Metrics_Bytes_Read_d,90) by bin(TimeGenerated,1m),name\n| order by TimeGenerated asc nulls last;\n\n'
  }
  {
    displayName: 'Sum Task Execution Per Host'
    query: 'SparkListenerEvent_CL\n|  where Event_s contains "taskend" \n| extend taskDuration=Task_Info_Finish_Time_d-Task_Info_Launch_Time_d \n| summarize sum(taskDuration) by bin(TimeGenerated,  1m), Task_Info_Host_s\n| order by TimeGenerated asc nulls last '
  }
  {
    displayName: '% CPU Time Per Executor'
    query: 'let results = SparkMetric_CL \n|  where name_s contains "executor.cpuTime" \n| extend sname=split(name_s, ".")\n| extend executor=strcat(sname[0],".",sname[1])\n| project TimeGenerated , cpuTime=count_d/1000000  ,  executor ,name_s\n| join kind= inner (\n    SparkMetric_CL\n|  where name_s contains "executor.RunTime"\n| extend sname=split(name_s, ".") \n| extend executor=strcat(sname[0],".",sname[1])\n| project TimeGenerated , runTime=count_d  ,  executor ,name_s\n) on executor, TimeGenerated;\nresults\n| extend cpuUsage=(cpuTime/runTime)*100\n| summarize ExecutorCpuTime = percentile(cpuUsage,90) by bin(TimeGenerated, 1m), executor\n| order by TimeGenerated asc nulls last   \n'
  }
  {
    displayName: 'Job Throughput'
    query: 'let results=SparkListenerEvent_CL\n| where  Event_s  contains "SparkListenerJobStart"\n| extend metricsns=columnifexists("Properties_spark_metrics_namespace_s",Properties_spark_app_id_s)\n| extend apptag=iif(isnotempty(metricsns),metricsns,Properties_spark_app_id_s)\n| project Job_ID_d,apptag,Properties_spark_databricks_clusterUsageTags_clusterName_s,TimeGenerated\n| order by TimeGenerated asc  nulls last \n| join kind= inner (\n    SparkListenerEvent_CL\n    | where Event_s contains "SparkListenerJobEnd"\n    | where Job_Result_Result_s contains "JobSucceeded"\n    | project Event_s,Job_ID_d,TimeGenerated\n) on Job_ID_d;\nresults\n| extend slice=strcat("#JobsCompleted ",Properties_spark_databricks_clusterUsageTags_clusterName_s,"-",apptag)\n| summarize count(Event_s)   by bin(TimeGenerated,  1m),slice\n| order by TimeGenerated asc nulls last'
  }
  {
    displayName: 'Shuffle Disk Bytes Spilled Per Executor'
    query: 'let results=SparkMetric_CL\r\n| where  name_s  contains "executor.diskBytesSpilled"\r\n| extend sname=split(name_s, ".") \r\n| extend executor=strcat("executorid:",sname[1])\r\n| summarize MaxShuffleWrites=max(count_d)  by bin(TimeGenerated,  1m), executor \r\n| order by TimeGenerated asc  nulls last \r\n| join kind= inner (\r\n    SparkMetric_CL\r\n    | where name_s contains "executor.diskBytesSpilled"\r\n    | extend sname=split(name_s, ".") \r\n    | extend executor=strcat("executorid:",sname[1])\r\n| summarize MinShuffleWrites=min(count_d)  by bin(TimeGenerated,  1m), executor\r\n) on executor, TimeGenerated;\r\nresults\r\n| extend ShuffleBytesWritten=MaxShuffleWrites-MinShuffleWrites \r\n| summarize any(ShuffleBytesWritten)   by bin(TimeGenerated,  1m), executor\r\n| order by TimeGenerated asc nulls last\r\n'
  }
  {
    displayName: 'Task Shuffle Read Time'
    query: 'let result=SparkListenerEvent_CL\n| where Event_s  contains "SparkListenerStageSubmitted"\n| extend metricsns=columnifexists("Properties_spark_metrics_namespace_s",Properties_spark_app_id_s)\r\n| extend apptag=iif(isnotempty(metricsns),metricsns,Properties_spark_app_id_s)\r\n| project Stage_Info_Stage_ID_d,Stage_Info_Stage_Name_s,Stage_Info_Submission_Time_d,Event_s,TimeGenerated,Properties_spark_databricks_clusterUsageTags_clusterName_s,apptag\n| order by TimeGenerated asc  nulls last \n| join kind= inner (\n    SparkListenerEvent_CL\n    |  where Event_s contains "SparkListenerTaskEnd"\n    | where Task_End_Reason_Reason_s contains "Success"\n    | project Task_Info_Launch_Time_d,Stage_ID_d,Task_Info_Task_ID_d,Event_s,\n              Task_Metrics_Executor_Deserialize_Time_d,Task_Metrics_Shuffle_Read_Metrics_Fetch_Wait_Time_d,\n              Task_Metrics_Executor_Run_Time_d,Task_Metrics_Shuffle_Write_Metrics_Shuffle_Write_Time_d,\n              Task_Metrics_Result_Serialization_Time_d,Task_Info_Getting_Result_Time_d,\n              Task_Metrics_Shuffle_Read_Metrics_Remote_Bytes_Read_d,Task_Metrics_Shuffle_Write_Metrics_Shuffle_Bytes_Written_d,\n              Task_Metrics_JVM_GC_Time_d,TimeGenerated\n) on $left.Stage_Info_Stage_ID_d == $right.Stage_ID_d;\nresult\n| extend name=strcat("TaskShuffleReadTime ",Properties_spark_databricks_clusterUsageTags_clusterName_s,"-",apptag," ",Stage_Info_Stage_Name_s)\n| summarize percentile(Task_Metrics_Shuffle_Read_Metrics_Fetch_Wait_Time_d,90) by bin(TimeGenerated,1m),name\n| order by TimeGenerated asc nulls last;\n\n'
  }
  {
    displayName: 'Shuffle Heap Memory Per Executor'
    query: 'SparkMetric_CL\n|  where  name_s  contains "shuffle-client.usedHeapMemory"\n| extend sname=split(name_s, ".")\n| extend executor=strcat(sname[0],".",sname[1])\n| summarize percentile(value_d,90)  by bin(TimeGenerated,  1m), executor\n| order by TimeGenerated asc  nulls last'
  }
  {
    displayName: 'Job Errors Per Job'
    query: 'let results=SparkListenerEvent_CL\r\n| where  Event_s  contains "SparkListenerJobStart"\r\n| project Job_ID_d,Properties_callSite_short_s,TimeGenerated\r\n| order by TimeGenerated asc  nulls last \r\n| join kind= inner (\r\n    SparkListenerEvent_CL\r\n    | where Event_s contains "SparkListenerJobEnd"\r\n    | where Job_Result_Result_s !contains "JobSucceeded"\r\n    | project Event_s,Job_ID_d,TimeGenerated\r\n) on Job_ID_d;\r\nresults\r\n| extend slice=strcat("JobErrors ",Properties_callSite_short_s)\r\n| summarize count(Event_s)   by bin(TimeGenerated,  1m),slice\r\n| order by TimeGenerated asc nulls last'
  }
  {
    displayName: 'Task Errors Per Stage'
    query: 'let result=SparkListenerEvent_CL\n| where  Event_s  contains "SparkListenerStageCompleted"\n| project Stage_Info_Stage_ID_d,Stage_Info_Stage_Name_s,Event_s,TimeGenerated\n| order by TimeGenerated asc  nulls last \n| join kind= inner (\n    SparkListenerEvent_CL\n    | where Event_s contains "SparkListenerTaskEnd"\n    | where Task_End_Reason_Reason_s !contains "Success"\n    | project Stage_ID_d,Task_Info_Task_ID_d,Task_End_Reason_Reason_s,\n              TaskEvent=Event_s,TimeGenerated\n) on $left.Stage_Info_Stage_ID_d == $right.Stage_ID_d;\nresult\n| extend slice=strcat("#TaskErrors ",Stage_Info_Stage_Name_s)\n| summarize count(TaskEvent)  by bin(TimeGenerated,1m),slice\n| order by TimeGenerated asc nulls last\n'
  }
  {
    displayName: 'Streaming Latency Per Stream'
    query: '\r\n\r\nSparkListenerEvent_CL\r\n| where Event_s contains "queryprogressevent"\r\n| extend sname=strcat(progress_name_s,"-","triggerexecution") \r\n| summarize percentile(progress_durationMs_triggerExecution_d,90)  by bin(TimeGenerated, 1m), sname\r\n| order by  TimeGenerated   asc  nulls last \r\n'
  }
  {
    displayName: 'Task Shuffle Write Time'
    query: 'let result=SparkListenerEvent_CL\r\n| where  Event_s  contains "SparkListenerStageCompleted"\r\n| project Stage_Info_Stage_ID_d,Stage_Info_Stage_Name_s,Stage_Info_Submission_Time_d,Event_s,TimeGenerated\r\n| order by TimeGenerated asc  nulls last \r\n| join kind= inner (\r\n    SparkListenerEvent_CL\r\n    | where Event_s contains "SparkListenerTaskEnd"\r\n    | where Task_End_Reason_Reason_s contains "Success"\r\n    | project Task_Info_Launch_Time_d,Stage_ID_d,Task_Info_Task_ID_d,Event_s,\r\n              Task_Metrics_Executor_Deserialize_Time_d,Task_Metrics_Shuffle_Read_Metrics_Fetch_Wait_Time_d,\r\n              Task_Metrics_Executor_Run_Time_d,Task_Metrics_Shuffle_Write_Metrics_Shuffle_Write_Time_d,\r\n              Task_Metrics_Result_Serialization_Time_d,Task_Info_Getting_Result_Time_d,\r\n              Task_Metrics_Shuffle_Read_Metrics_Remote_Bytes_Read_d,Task_Metrics_Shuffle_Write_Metrics_Shuffle_Bytes_Written_d,\r\n              Task_Metrics_JVM_GC_Time_d,TimeGenerated\r\n) on $left.Stage_Info_Stage_ID_d == $right.Stage_ID_d;\r\nresult\r\n| extend ShuffleWriteTime=Task_Metrics_Shuffle_Write_Metrics_Shuffle_Write_Time_d/1000000\r\n| extend name=strcat("TaskShuffleWriteTime ",Stage_Info_Stage_Name_s)\r\n| summarize percentile(ShuffleWriteTime,90) by bin(TimeGenerated,1m),name\r\n| order by TimeGenerated asc nulls last;\r\n\r\n'
  }
  {
    displayName: 'Task Deserialization Time'
    query: 'let result=SparkListenerEvent_CL\n| where  Event_s  contains "SparkListenerStageSubmitted"\n| extend metricsns=columnifexists("Properties_spark_metrics_namespace_s",Properties_spark_app_id_s)\r\n| extend apptag=iif(isnotempty(metricsns),metricsns,Properties_spark_app_id_s)\r\n| project Stage_Info_Stage_ID_d,Stage_Info_Stage_Name_s,Stage_Info_Submission_Time_d,Event_s,TimeGenerated,Properties_spark_databricks_clusterUsageTags_clusterName_s,apptag\n| order by TimeGenerated asc  nulls last \n| join kind= inner (\n    SparkListenerEvent_CL\n    |  where Event_s contains "SparkListenerTaskEnd"\n    | where Task_End_Reason_Reason_s contains "Success"\n    | project Task_Info_Launch_Time_d,Stage_ID_d,Task_Info_Task_ID_d,Event_s,\n              Task_Metrics_Executor_Deserialize_Time_d,Task_Metrics_Shuffle_Read_Metrics_Fetch_Wait_Time_d,\n              Task_Metrics_Executor_Run_Time_d,Task_Metrics_Shuffle_Write_Metrics_Shuffle_Write_Time_d,\n              Task_Metrics_Result_Serialization_Time_d,Task_Info_Getting_Result_Time_d,\n              Task_Metrics_Shuffle_Read_Metrics_Remote_Bytes_Read_d,Task_Metrics_Shuffle_Write_Metrics_Shuffle_Bytes_Written_d,\n              Task_Metrics_JVM_GC_Time_d,Task_Metrics_Input_Metrics_Bytes_Read_d,TimeGenerated\n) on $left.Stage_Info_Stage_ID_d == $right.Stage_ID_d;\nresult\n| extend name=strcat("TaskDeserializationTime ",Properties_spark_databricks_clusterUsageTags_clusterName_s,"-",apptag," ",Stage_Info_Stage_Name_s)\n| summarize percentile(Task_Metrics_Executor_Deserialize_Time_d,90) by bin(TimeGenerated,1m),name\n| order by TimeGenerated asc nulls last;\n\n'
  }
  {
    displayName: 'Task Result Serialization Time'
    query: 'let result=SparkListenerEvent_CL\n| where  Event_s  contains "SparkListenerStageSubmitted"\n| extend metricsns=columnifexists("Properties_spark_metrics_namespace_s",Properties_spark_app_id_s)\r\n| extend apptag=iif(isnotempty(metricsns),metricsns,Properties_spark_app_id_s)\r\n| project Stage_Info_Stage_ID_d,Stage_Info_Stage_Name_s,Stage_Info_Submission_Time_d,Event_s,TimeGenerated,Properties_spark_databricks_clusterUsageTags_clusterName_s,apptag\n| order by TimeGenerated asc  nulls last  \n| join kind= inner (\n    SparkListenerEvent_CL\n    |  where Event_s contains "SparkListenerTaskEnd"\n    | where Task_End_Reason_Reason_s contains "Success"\n    | project Task_Info_Launch_Time_d,Stage_ID_d,Task_Info_Task_ID_d,Event_s,\n              Task_Metrics_Executor_Deserialize_Time_d,Task_Metrics_Shuffle_Read_Metrics_Fetch_Wait_Time_d,\n              Task_Metrics_Executor_Run_Time_d,Task_Metrics_Shuffle_Write_Metrics_Shuffle_Write_Time_d,\n              Task_Metrics_Result_Serialization_Time_d,Task_Info_Getting_Result_Time_d,\n              Task_Metrics_Shuffle_Read_Metrics_Remote_Bytes_Read_d,Task_Metrics_Shuffle_Write_Metrics_Shuffle_Bytes_Written_d,\n              Task_Metrics_JVM_GC_Time_d,TimeGenerated\n) on $left.Stage_Info_Stage_ID_d == $right.Stage_ID_d;\nresult\n| extend name=strcat("TaskResultSerializationTime ",Properties_spark_databricks_clusterUsageTags_clusterName_s,"-",apptag," ",Stage_Info_Stage_Name_s)\n| summarize percentile(Task_Metrics_Result_Serialization_Time_d,90) by bin(TimeGenerated,1m),name\n| order by TimeGenerated asc nulls last;\n\n'
  }
  {
    displayName: 'File System Bytes Read Per Executor'
    query: 'SparkMetric_CL\n|  extend sname=split(name_s, ".")\n| extend executor=strcat(sname[0],".",sname[1])\n| where  name_s  contains "executor.filesystem.file.read_bytes" \n| summarize FileSystemReadBytes=percentile(value_d,90)  by bin(TimeGenerated,  1m), executor\n| order by TimeGenerated asc  nulls last'
  }
  {
    displayName: 'Streaming Throughput Processed Rows/Sec'
    query: 'SparkListenerEvent_CL\r\n| where Event_s   contains "progress"\r\n| extend sname=strcat(progress_name_s,"-ProcRowsPerSecond") \r\n| extend status = todouble(extractjson("$.[0].processedRowsPerSecond", progress_sources_s))\r\n| summarize percentile(status,90) by bin(TimeGenerated,  1m) , sname\r\n| order by  TimeGenerated   asc  nulls last '
  }
  {
    displayName: '% Deserialize Time Per Executor'
    query: 'let results = SparkMetric_CL \n|  where name_s contains "executor.deserializetime" \n| extend sname=split(name_s, ".") \n| extend executor=strcat(sname[0],".",sname[1])\n| project TimeGenerated , desetime=count_d , executor ,name_s\n| join kind= inner (\nSparkMetric_CL\n|  where name_s contains "executor.RunTime"\n| extend sname=split(name_s, ".") \n| extend executor=strcat(sname[0],".",sname[1])\n| project TimeGenerated , runTime=count_d , executor ,name_s\n) on executor, TimeGenerated;\nresults\n| extend deseUsage=(desetime/runTime)*100\n| summarize deSerializationCpuTime=percentiles(deseUsage,90) by bin(TimeGenerated, 1m), executor\n| order by TimeGenerated asc nulls last '
  }
  {
    displayName: 'Tasks Per Executor (Sum Of Tasks Per Executor)'
    query: 'SparkMetric_CL\n| extend sname=split(name_s, ".")\n| extend executor=strcat(sname[0],".",sname[1]) \n| where name_s contains "threadpool.activeTasks" \n| summarize percentile(value_d,90)  by bin(TimeGenerated, 1m),executor\n| order by TimeGenerated asc  nulls last'
  }
  {
    displayName: 'File System Bytes Write Per Executor'
    query: 'SparkMetric_CL\n|  extend sname=split(name_s, ".")\n| extend executor=strcat(sname[0],".",sname[1])\n| where  name_s  contains "executor.filesystem.file.write_bytes" \n| summarize FileSystemWriteBytes=percentile(value_d,90)  by bin(TimeGenerated,  1m), executor\n| order by TimeGenerated asc  nulls last '
  }
  {
    displayName: 'Task Scheduler Delay Latency'
    query: 'let result=SparkListenerEvent_CL\n| where  Event_s  contains "SparkListenerStageSubmitted"\n| extend metricsns=columnifexists("Properties_spark_metrics_namespace_s",Properties_spark_app_id_s)\r\n| extend apptag=iif(isnotempty(metricsns),metricsns,Properties_spark_app_id_s)\r\n| project Stage_Info_Stage_ID_d,Stage_Info_Stage_Name_s,Stage_Info_Submission_Time_d,Event_s,TimeGenerated,Properties_spark_databricks_clusterUsageTags_clusterName_s,apptag\n| order by TimeGenerated asc  nulls last \n| join kind= inner (\n    SparkListenerEvent_CL\n    |  where Event_s contains "SparkListenerTaskEnd"\n    | where Task_End_Reason_Reason_s contains "Success"\n    | project Task_Info_Launch_Time_d,Stage_ID_d,Task_Info_Task_ID_d,Event_s,\n              Task_Metrics_Executor_Deserialize_Time_d,Task_Metrics_Shuffle_Read_Metrics_Fetch_Wait_Time_d,\n              Task_Metrics_Executor_Run_Time_d,Task_Metrics_Shuffle_Write_Metrics_Shuffle_Write_Time_d,\n              Task_Metrics_Result_Serialization_Time_d,Task_Info_Getting_Result_Time_d,\n              Task_Metrics_Shuffle_Read_Metrics_Remote_Bytes_Read_d,Task_Metrics_Shuffle_Write_Metrics_Shuffle_Bytes_Written_d,\n              Task_Metrics_JVM_GC_Time_d,TimeGenerated\n) on $left.Stage_Info_Stage_ID_d == $right.Stage_ID_d;\nresult\n| extend schedulerdelay = Task_Info_Launch_Time_d - Stage_Info_Submission_Time_d\n| extend name=strcat("SchedulerDelayTime ",Properties_spark_databricks_clusterUsageTags_clusterName_s,"-",apptag," ",Stage_Info_Stage_Name_s)\n| summarize percentile(schedulerdelay,90) , percentile(Task_Metrics_Executor_Run_Time_d,90) by bin(TimeGenerated,1m),name\n| order by TimeGenerated asc nulls last;\n\n'
  }
  {
    displayName: 'Streaming Errors Per Stream'
    query: 'SparkListenerEvent_CL\r\n| extend slice = strcat("CountExceptions",progress_name_s) \r\n| where Level contains "Error"\r\n| summarize count(Level) by bin(TimeGenerated, 1m), slice \r\n'
  }
  {
    displayName: 'Shuffle Client Memory Per Executor'
    query: 'SparkMetric_CL\r\n| where  name_s  contains "shuffle-client.usedDirectMemory"\r\n| extend sname=split(name_s, ".")\r\n| extend executor=strcat("executorid:",sname[1])\r\n| summarize percentile(value_d,90)  by bin(TimeGenerated,  1m), executor\r\n| order by TimeGenerated asc  nulls last'
  }
  {
    displayName: 'Job Latency Per Job (Batch Duration)'
    query: 'let results=SparkListenerEvent_CL\r\n| where  Event_s  contains "SparkListenerJobStart"\r\n| extend metricsns=columnifexists("Properties_spark_metrics_namespace_s",Properties_spark_app_id_s)\r\n| extend apptag=iif(isnotempty(metricsns),metricsns,Properties_spark_app_id_s)\r\n| project Job_ID_d,apptag,Properties_spark_databricks_clusterUsageTags_clusterName_s,\r\nSubmission_Time_d,TimeGenerated\r\n| order by TimeGenerated asc  nulls last \r\n| join kind= inner (\r\n    SparkListenerEvent_CL\r\n    | where Event_s contains "SparkListenerJobEnd"\r\n    | where Job_Result_Result_s contains "JobSucceeded"\r\n    | project Event_s,Job_ID_d,Completion_Time_d,TimeGenerated\r\n) on Job_ID_d;\r\nresults\r\n| extend slice=strcat(Properties_spark_databricks_clusterUsageTags_clusterName_s,"-",apptag)\r\n| extend jobDuration=Completion_Time_d - Submission_Time_d \r\n| summarize percentiles(jobDuration,10,30,50,90)  by bin(TimeGenerated,  1m), slice\r\n| order by TimeGenerated asc nulls last'
  }
  {
    displayName: 'Task Executor Compute Time (Data Skew Time)'
    query: 'let result=SparkListenerEvent_CL\n| where Event_s  contains "SparkListenerStageSubmitted"\n| extend metricsns=columnifexists("Properties_spark_metrics_namespace_s",Properties_spark_app_id_s)\r\n| extend apptag=iif(isnotempty(metricsns),metricsns,Properties_spark_app_id_s)\r\n| project Stage_Info_Stage_ID_d,Stage_Info_Stage_Name_s,Stage_Info_Submission_Time_d,Event_s,TimeGenerated,Properties_spark_databricks_clusterUsageTags_clusterName_s,apptag\n| order by TimeGenerated asc  nulls last\n| join kind= inner (\n    SparkListenerEvent_CL\n    |  where Event_s contains "SparkListenerTaskEnd"\n    | where Task_End_Reason_Reason_s contains "Success"\n    | project Task_Info_Launch_Time_d,Stage_ID_d,Task_Info_Task_ID_d,Event_s,\n              Task_Metrics_Executor_Deserialize_Time_d,Task_Metrics_Shuffle_Read_Metrics_Fetch_Wait_Time_d,\n              Task_Metrics_Executor_Run_Time_d,Task_Metrics_Shuffle_Write_Metrics_Shuffle_Write_Time_d,\n              Task_Metrics_Result_Serialization_Time_d,Task_Info_Getting_Result_Time_d,\n              Task_Metrics_Shuffle_Read_Metrics_Remote_Bytes_Read_d,Task_Metrics_Shuffle_Write_Metrics_Shuffle_Bytes_Written_d,\n              Task_Metrics_JVM_GC_Time_d,TimeGenerated\n) on $left.Stage_Info_Stage_ID_d == $right.Stage_ID_d;\nresult\n| extend name=strcat("ExecutorComputeTime ",Properties_spark_databricks_clusterUsageTags_clusterName_s,"-",apptag," ",Stage_Info_Stage_Name_s)\n| summarize percentile(Task_Metrics_Executor_Run_Time_d,90) by bin(TimeGenerated,1m),name\n| order by TimeGenerated asc nulls last;\n\n'
  }
  {
    displayName: 'Streaming Throughput Input Rows/Sec'
    query: 'SparkListenerEvent_CL\r\n| where Event_s   contains "progress"\r\n| extend sname=strcat(progress_name_s,"-inputRowsPerSecond") \r\n| extend status = todouble(extractjson("$.[0].inputRowsPerSecond", progress_sources_s))\r\n| summarize percentile(status,90) by bin(TimeGenerated,  1m) , sname\r\n| order by  TimeGenerated   asc  nulls last \n'
  }
  {
    displayName: 'Task Shuffle Bytes Read'
    query: 'let result=SparkListenerEvent_CL\n| where Event_s  contains "SparkListenerStageSubmitted"\n| extend metricsns=columnifexists("Properties_spark_metrics_namespace_s",Properties_spark_app_id_s)\r\n| extend apptag=iif(isnotempty(metricsns),metricsns,Properties_spark_app_id_s)\r\n| project Stage_Info_Stage_ID_d,Stage_Info_Stage_Name_s,Stage_Info_Submission_Time_d,Event_s,TimeGenerated,Properties_spark_databricks_clusterUsageTags_clusterName_s,apptag\n| order by TimeGenerated asc  nulls last\n| join kind= inner (\n    SparkListenerEvent_CL\n    |  where Event_s contains "SparkListenerTaskEnd"\n    | where Task_End_Reason_Reason_s contains "Success"\n    | project Task_Info_Launch_Time_d,Stage_ID_d,Task_Info_Task_ID_d,Event_s,\n              Task_Metrics_Executor_Deserialize_Time_d,Task_Metrics_Shuffle_Read_Metrics_Fetch_Wait_Time_d,\n              Task_Metrics_Executor_Run_Time_d,Task_Metrics_Shuffle_Write_Metrics_Shuffle_Write_Time_d,\n              Task_Metrics_Result_Serialization_Time_d,Task_Info_Getting_Result_Time_d,\n              Task_Metrics_Shuffle_Read_Metrics_Remote_Bytes_Read_d,Task_Metrics_Shuffle_Write_Metrics_Shuffle_Bytes_Written_d,\n              Task_Metrics_JVM_GC_Time_d,TimeGenerated\n) on $left.Stage_Info_Stage_ID_d == $right.Stage_ID_d;\nresult\n| extend name=strcat("SchuffleBytesRead ",Properties_spark_databricks_clusterUsageTags_clusterName_s,"-",apptag," ",Stage_Info_Stage_Name_s)\n| summarize percentile(Task_Metrics_Shuffle_Read_Metrics_Remote_Bytes_Read_d,90) by bin(TimeGenerated,1m),name\n| order by TimeGenerated asc nulls last;\n\n'
  }
  {
    displayName: 'Shuffle Memory Bytes Spilled Per Executor'
    query: 'let results=SparkMetric_CL\n|  where  name_s  contains "executor.memoryBytesSpilled"\n| extend sname=split(name_s, ".") \n| extend executor=strcat(sname[0],".",sname[1])\n| summarize MaxShuffleWrites=max(count_d)  by bin(TimeGenerated,  1m), executor \n| order by TimeGenerated asc  nulls last \n| join kind= inner (\n    SparkMetric_CL\n    |  where name_s contains "executor.memoryBytesSpilled"\n    | extend sname=split(name_s, ".") \n    | extend executor=strcat(sname[0],".",sname[1])\n| summarize MinShuffleWrites=min(count_d)  by bin(TimeGenerated,  1m), executor\n) on executor, TimeGenerated;\nresults\n| extend ShuffleBytesWritten=MaxShuffleWrites-MinShuffleWrites \n| summarize any(ShuffleBytesWritten)   by bin(TimeGenerated,  1m), executor\n| order by TimeGenerated asc nulls last\n'
  }
  {
    displayName: '% JVM Time Per Executor'
    query: 'let results = SparkMetric_CL\n|  where name_s contains "executor.jvmGCTime" \n| extend sname=split(name_s, ".")\n| extend executor=strcat(sname[0],".",sname[1])\n| project TimeGenerated , jvmgcTime=count_d , executor ,name_s\n| join kind= inner (\nSparkMetric_CL\n|  where name_s contains "executor.RunTime"\n| extend sname=split(name_s, ".")\n| extend executor=strcat(sname[0],".",sname[1])\n| project TimeGenerated , runTime=count_d , executor ,name_s\n) on executor, TimeGenerated;\nresults\n| extend JvmcpuUsage=(jvmgcTime/runTime)*100\n| summarize JvmCpuTime = percentile(JvmcpuUsage,90) by bin(TimeGenerated, 1m), executor\n| order by TimeGenerated asc nulls last\n| render timechart  \n'
  }
  {
    displayName: 'Running Executors'
    query: 'SparkMetric_CL\n|  where name_s !contains "driver" \n| where name_s contains "executor"\n| extend sname=split(name_s, ".")\n| extend executor=strcat(sname[1]) \n| extend app=strcat(sname[0])\n| summarize NumExecutors=dcount(executor)  by bin(TimeGenerated,  1m),app\n| order by TimeGenerated asc  nulls last'
  }
  {
    displayName: 'Shuffle Bytes Read To Disk Per Executor'
    query: 'let results=SparkMetric_CL\r\n| where  name_s  contains "executor.shuffleRemoteBytesReadToDisk"\r\n| extend sname=split(name_s, ".") \r\n| extend executor=strcat("executorid:",sname[1])\r\n| summarize MaxShuffleWrites=max(count_d)  by bin(TimeGenerated,  1m), executor \r\n| order by TimeGenerated asc  nulls last \r\n| join kind= inner (\r\n    SparkMetric_CL\r\n    | where name_s contains "executor.shuffleRemoteBytesReadToDisk"\r\n    | extend sname=split(name_s, ".") \r\n    | extend executor=strcat("executorid:",sname[1])\r\n| summarize MinShuffleWrites=min(count_d)  by bin(TimeGenerated,  1m), executor\r\n) on executor, TimeGenerated;\r\nresults\r\n| extend ShuffleBytesWritten=MaxShuffleWrites-MinShuffleWrites \r\n| summarize any(ShuffleBytesWritten)   by bin(TimeGenerated,  1m), executor\r\n| order by TimeGenerated asc nulls last\r\n'
  }
  {
    displayName: 'Task Latency Per Stage (Tasks Duration)'
    query: 'let result=SparkListenerEvent_CL\n| where  Event_s  contains "SparkListenerStageSubmitted"\n| extend metricsns=columnifexists("Properties_spark_metrics_namespace_s",Properties_spark_app_id_s)\r\n| extend apptag=iif(isnotempty(metricsns),metricsns,Properties_spark_app_id_s)\r\n| project Stage_Info_Stage_ID_d,Stage_Info_Stage_Name_s,apptag,Properties_spark_databricks_clusterUsageTags_clusterName_s,Event_s,TimeGenerated\n| order by TimeGenerated asc  nulls last \n| join kind= inner (\n    SparkListenerEvent_CL\n    |  where Event_s contains "SparkListenerTaskEnd"\n    | where Task_End_Reason_Reason_s contains "Success"\n    | project Task_Info_Launch_Time_d,Stage_ID_d,Task_Info_Task_ID_d,Event_s,\n              Task_Info_Finish_Time_d\n              ) on $left.Stage_Info_Stage_ID_d == $right.Stage_ID_d;\nresult\n| extend TaskLatency =  Task_Info_Finish_Time_d - Task_Info_Launch_Time_d\n| extend slice=strcat(Properties_spark_databricks_clusterUsageTags_clusterName_s,"-",apptag,"-",Stage_Info_Stage_Name_s)\n| summarize percentile(TaskLatency,90)  by bin(TimeGenerated,1m),slice\n| order by TimeGenerated asc nulls last;\n'
  }
  {
    displayName: 'Task Throughput (Sum Of Tasks Per Stage)'
    query: 'let result=SparkListenerEvent_CL\n| where Event_s  contains "SparkListenerStageSubmitted"\n| extend metricsns=columnifexists("Properties_spark_metrics_namespace_s",Properties_spark_app_id_s)\r\n| extend apptag=iif(isnotempty(metricsns),metricsns,Properties_spark_app_id_s)\r\n| project Stage_Info_Stage_ID_d,Stage_Info_Stage_Name_s,Stage_Info_Submission_Time_d,Event_s,TimeGenerated,Properties_spark_databricks_clusterUsageTags_clusterName_s,apptag\n| order by TimeGenerated asc  nulls last \n| join kind= inner (\n    SparkListenerEvent_CL\n    |  where Event_s contains "SparkListenerTaskEnd"\n    | where Task_End_Reason_Reason_s contains "Success"\n    | project Stage_ID_d,Task_Info_Task_ID_d,\n              TaskEvent=Event_s,TimeGenerated\n) on $left.Stage_Info_Stage_ID_d == $right.Stage_ID_d;\nresult\n| extend slice=strcat("#TasksCompleted ",Properties_spark_databricks_clusterUsageTags_clusterName_s,"-",apptag," ",Stage_Info_Stage_Name_s)\n| summarize count(TaskEvent)  by bin(TimeGenerated,1m),slice\n| order by TimeGenerated asc nulls last\n'
  }
  {
    displayName: 'Shuffle Client Direct Memory'
    query: 'SparkMetric_CL\n|  where  name_s  contains "shuffle-client.usedDirectMemory"\n| extend sname=split(name_s, ".")\n| extend executor=strcat(sname[0],".",sname[1])\n| summarize percentile(value_d,90)  by bin(TimeGenerated,  1m), executor\n| order by TimeGenerated asc  nulls last'
  }
  {
    displayName: 'Disk Bytes Spilled'
    query: 'let results=SparkMetric_CL\n|  where  name_s  contains "executor.diskBytesSpilled"\n| extend sname=split(name_s, ".") \n| extend executor=strcat(sname[0],".",sname[1])\n| summarize MaxShuffleWrites=max(count_d)  by bin(TimeGenerated,  1m), executor \n| order by TimeGenerated asc  nulls last \n| join kind= inner (\n    SparkMetric_CL\n    |  where name_s contains "executor.diskBytesSpilled"\n    | extend sname=split(name_s, ".") \n    | extend executor=strcat(sname[0],".",sname[1])\n| summarize MinShuffleWrites=min(count_d)  by bin(TimeGenerated,  1m), executor\n) on executor, TimeGenerated;\nresults\n| extend ShuffleBytesWritten=MaxShuffleWrites-MinShuffleWrites \n| summarize any(ShuffleBytesWritten)   by bin(TimeGenerated,  1m), executor\n| order by TimeGenerated asc nulls last\n'
  }
  {
    displayName: 'Shuffle Bytes Read'
    query: 'let results=SparkMetric_CL\n|  where  name_s  contains "executor.shuffleRemoteBytesReadToDisk"\n| extend sname=split(name_s, ".") \n| extend executor=strcat(sname[0],".",sname[1])\n| summarize MaxShuffleWrites=max(count_d)  by bin(TimeGenerated,  1m), executor \n| order by TimeGenerated asc  nulls last \n| join kind= inner (\n    SparkMetric_CL\n    |  where name_s contains "executor.shuffleRemoteBytesReadToDisk"\n    | extend sname=split(name_s, ".") \n    | extend executor=strcat(sname[0],".",sname[1])\n| summarize MinShuffleWrites=min(count_d)  by bin(TimeGenerated,  1m), executor\n) on executor, TimeGenerated;\nresults\n| extend ShuffleBytesWritten=MaxShuffleWrites-MinShuffleWrites \n| summarize any(ShuffleBytesWritten)   by bin(TimeGenerated,  1m), executor\n| order by TimeGenerated asc nulls last\n'
  }
]

resource Wksp 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: logAnalyticsWkspName
  location: logAnalyticsWkspLocation
  properties: {
    sku: {
      name: logAnalyticsWkspSku
    }
    retentionInDays: logAnalyticsWkspRentationDays
    features: {
      enableDataExport: true
    }
  }
}

resource WkspSearch 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = [for (item, i) in queries: {
  parent: Wksp
  name: '${guid('${resourceGroup().id}${deployment().name}${i}')}'
  properties: {
    category: 'Spark Metrics'
    displayName: item.displayName
    query: item.query
    etag: '*'
  }
}]

var keyObj = listKeys(resourceId('Microsoft.OperationalInsights/workspaces', logAnalyticsWkspName), '2020-10-01')

// output logAnalyticsWkspId string = Wksp.id
output logAnalyticsWkspId string = Wksp.properties.customerId
output primarySharedKey string = keyObj.primarySharedKey
output secondarySharedKey string = keyObj.secondarySharedKey
