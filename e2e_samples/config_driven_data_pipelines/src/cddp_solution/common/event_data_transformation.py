from cddp_solution.common.utils.spark_job import AbstractSparkJob
from cddp_solution.common.utils.DataProcessingPhase import DataProcessingPhase
from cddp_solution.common.utils import sink_data_helper
from cddp_solution.common.utils.env import getEnv, isRunningOnDatabricks
from cddp_solution.common.utils.module_helper import find_class
from abc import abstractmethod
from pathlib import Path
from pyspark.sql import functions as F
import datetime
import logging
import re
import os
import inspect


class AbstractEventDataTransformation(AbstractSparkJob):
    def __init__(self, config):
        super().__init__(config)

    def load_master_data(self):
        """
        Loads master from targets defined under "master_data_transform" of config.json

        """
        self.logger.log(logging.INFO, f"## Job Started: {inspect.currentframe().f_code.co_name}")

        master_data_transform = self.config["master_data_transform"]
        for transform in master_data_transform:
            table_name = transform["target"]
            self.load_storage_to_tempview(self.master_data_storage_path, table_name)

        self.logger.log(logging.INFO, f"## Job Ended: {inspect.currentframe().f_code.co_name}")
        return

    def load_event_data(self):
        """
        Loads event from data sources defined under "event_data_source" of config.json

        """
        self.logger.log(logging.INFO, f"## Job Started: {inspect.currentframe().f_code.co_name}")

        if 'event_data_source' in self.config:
            for data_source in self.config['event_data_source']:
                if data_source['type'] == 'event-hub':
                    self.read_event_data_from_event_hub(data_source)
                elif data_source['type'].lower() == 'local' or data_source['type'].lower() == 'cloudfiles':
                    self.read_event_data_from_files(data_source)

        self.logger.log(logging.INFO, f"## Job Ended: {inspect.currentframe().f_code.co_name}")
        return

    def read_event_data_from_event_hub(self, data_source):
        secret = data_source["secret"]
        table_name = data_source["table_name"]
        partition_keys = data_source["partition_keys"]

        # Assign default event data bad records path if it's not set explicitly in config.json
        bad_records_path = data_source.get("badRecordsPath",
                                           f'{self.event_data_bad_records_storage_path}/{table_name}')

        sc = self.spark.sparkContext
        connectionString = getEnv(secret)
        ehConf = {
            'eventhubs.connectionString': sc._jvm.org.apache.spark.eventhubs.EventHubsUtils.encrypt(connectionString)
        }

        schema = self.get_event_schema(data_source)

        df = self.spark \
            .readStream \
            .option('badRecordsPath', bad_records_path)\
            .format("eventhubs") \
            .options(**ehConf) \
            .load() \
            .selectExpr("CAST(body AS STRING)") \
            .withColumn("json", F.from_json("body", schema))\
            .select(F.col('json.*'))
        # Add audit columns
        df = self.add_audit_columns(df, DataProcessingPhase.EVENT_LANDING_TO_STAGING)
        # Save events data to STAGING zone
        df, db_tablename = self.__save_events_data_to_staging_zone(df, table_name, partition_keys=partition_keys)
        df.createOrReplaceTempView(table_name)

        self.logger.log(logging.INFO, f"Events streaming data is saving to staging zone '{db_tablename}' properly")
        return

    def read_event_data_from_files(self, data_source):
        self.logger.log(logging.INFO, f"## Job Started: {inspect.currentframe().f_code.co_name}")

        table_name = data_source["table_name"]
        source_system = self.config["domain"]
        location = data_source["location"]
        partition_keys = data_source["partition_keys"]
        resources_base_path = self.config["resources_base_path"]

        location = Path(resources_base_path, f"{source_system}_customers", location).as_posix()
        bad_records_path = data_source.get("badRecordsPath",
                                           f'{self.event_data_bad_records_storage_path}/{table_name}')

        # if type is cloudFiles we will have cloudFiles specific readstream()
        type = data_source["type"]
        format = data_source["format"]

        # Set ADLS landing path when running on Databricks cluster
        if isRunningOnDatabricks():
            location = f"{self.landing_data_storage_path}/{table_name}/"
            self.logger.log(logging.INFO, f"Fact/Event data will be picked up from Landing: {location}")
        else:
            # Update current timestamp to mock events in events.json file
            if format == "json":
                location = self.__prepare_events_data(location)                    
            self.logger.log(logging.INFO, f"Fact/Event data will be picked up from Landing <local system>: {location}")

        schema = self.get_event_schema(data_source)

        # Based on the data source specif readstream will be applied
        if data_source['type'].lower() == 'local':
            df = self.get_events_from_local_files(format, bad_records_path, schema, location)
        elif data_source['type'].lower() == 'cloudfiles':
            df = self.get_events_from_cloud_files(type, format, bad_records_path, schema, location)

        # Add audit columns
        df = self.add_audit_columns(df, DataProcessingPhase.EVENT_LANDING_TO_STAGING)
        # Save events data to STAGING zone
        df, db_tablename = self.__save_events_data_to_staging_zone(df, table_name, partition_keys=partition_keys)

        # Make delta data avialable as view
        df.createOrReplaceTempView(table_name)

        self.logger.log(logging.INFO, f"Events streaming data is saving to staging zone '{db_tablename}' properly")
        self.logger.log(logging.INFO, f"## Job Ended: {inspect.currentframe().f_code.co_name}")
        return

    def save_invalid_records(self, df, data_validate):
        """ Save the invalid records into delta table
            Parameters
                df: invalid records dataframe
                data_validate: data validation config read from config.json
        """
        self.logger.log(logging.INFO, "Saving invalid records for retry")
        invalid_target = data_validate["invalid_target"]

        # Concat columns into one 'record' column
        columns = []
        for sf in df.schema.fields:
            columns.append(sf.name)

        df = df.withColumn('record', F.to_json(F.struct(F.col("*"))))
        # Add additional information
        invalid_data = df.drop(*columns) \
                         .withColumn("rule", F.lit(data_validate["valid_sql"])) \
                         .withColumn("reason", F.lit(data_validate["reason"])) \
                         .withColumn("status", F.lit("retryable")) \
                         .withColumn("retry_attempt", F.lit(0)) \
                         .withColumn("retry_attempt_limit", F.lit(3)) \
                         .withColumn("created_at", F.current_timestamp())

        db_tablename = f"{self.pz_dbname}.{invalid_target}"
        target_table_path = Path(self.event_data_invalid_records_storage_path, invalid_target).as_posix()
        target_table_checkpoint_path = Path(self.event_data_storage_path,
                                            self.checkpoint_name,
                                            f"{invalid_target}_chkpt").as_posix()

        sink_data_helper.save_as_streaming_delta_table(
            invalid_data,
            target_table_path,
            target_table_checkpoint_path,
            db_tablename,
            data_validate["partition_keys"]
            )

        self.logger.log(logging.INFO, f"Data updated to {db_tablename} | Path: {target_table_path}")

    def validate_event_data(self):
        """
        Valide invalid_data records

        """
        if "event_data_validate" not in self.config:
            return
        for event_data_validate in self.config["event_data_validate"]:
            if 'valid_sql' in event_data_validate and 'invalid_sql' in event_data_validate:
                # Get the valid records
                valid_records = self.spark.sql(event_data_validate["valid_sql"])

                valid_records.createOrReplaceTempView(event_data_validate["valid_target"])
                # Get and save the invalid records
                invalid_records = self.spark.sql(event_data_validate["invalid_sql"])
                # Add Audit Columns
                valid_records = self.add_audit_columns(valid_records, DataProcessingPhase.EVENT_LANDING_TO_STAGING)
                self.save_invalid_records(invalid_records, event_data_validate)

    def get_event_schema(self, data_source):
        """
        To support the event schema defined at customer level, it is allowed to define the
        schema could be defined in config.json, the key is 'schema' under the 'event_data_source' block;
        if the schema is not set in config, we will use the default schema defined in the
        get_default_event_schema at application level.


        Parameters
        ----------
        data_source : dict
            configs of data sources


        Returns
        ----------
        DataStructure
            schema
        """
        self.logger.log(logging.INFO, f"## Job Started: {inspect.currentframe().f_code.co_name}")

        if "schema" in data_source:
            schemaClz = find_class(data_source['schema'], "DataSchema")
            schemaInstance = schemaClz(self.config)
            return schemaInstance.get_schema()
        else:
            return self.get_default_event_schema()

    # FIXME : Need more understanding
    # This is the function to get default event schema, it need to be implemented at application level.
    @abstractmethod
    def get_default_event_schema(self):
        pass

    def transform(self):
        """
        Event data transformation

        Returns
        ----------
        streaming query
        """
        self.logger.log(logging.INFO, f"## Job Started: {inspect.currentframe().f_code.co_name}")

        queries = []
        for event_data_transform in self.config["event_data_transform"]:
            if 'function' in event_data_transform:
                transform_module = event_data_transform['function']
                jobClz = find_class(transform_module, "Function")
                job = jobClz(self.config, event_data_transform)
                queries.append(job.execute())
            elif 'sql' in event_data_transform:
                sql = event_data_transform["sql"]
                event_data_table_name = event_data_transform["target"]
                partition_keys = event_data_transform["partition_keys"]

                streaming_data = self.spark.sql(sql)

                # Add audit columns
                streaming_data = self.add_audit_columns(streaming_data, DataProcessingPhase.EVENT_STAGING_TO_STANDARD)
                # Save events data to Standard zone
                db_tablename = f"{self.pz_dbname}.{event_data_table_name}"
                target_table_path = Path(self.event_data_storage_path, event_data_table_name).as_posix()
                target_table_checkpoint_path = Path(self.event_data_storage_path,
                                                    self.checkpoint_name,
                                                    event_data_table_name).as_posix()

                streaming_query = sink_data_helper.save_as_streaming_delta_table(
                    streaming_data,
                    target_table_path,
                    target_table_checkpoint_path,
                    db_tablename,
                    partition_keys=partition_keys)

                queries.append(streaming_query)

                self.logger.log(logging.INFO, f"Data updated to {db_tablename} | Path: {target_table_path}")

        self.logger.log(logging.INFO, f"## Job Ended: {inspect.currentframe().f_code.co_name}")
        return queries

    def __prepare_events_data(self, mock_events_template_path):
        event_time = datetime.datetime.now() + datetime.timedelta(hours=1)
        event_time_str = event_time.strftime("%Y-%m-%d %H:%M:%S.%f")

        # Set event time to mock events data
        mock_events_path = Path(mock_events_template_path, "temp").as_posix()
        os.makedirs(mock_events_path, exist_ok=True)
        with open(Path(mock_events_template_path, "events.json").as_posix()) as f:
            events = f.read()
            with open(Path(mock_events_path, "events.json").as_posix(), "w") as new_events_file:
                updated_events = re.sub('{timestamp}', event_time_str, events)
                new_events_file.write(updated_events)
        return mock_events_path

    def __save_events_data_to_staging_zone(self, events, table_name, partition_keys=None):
        """
        Save events data to staging zone (staging data storage path) as streaming delta table
        Returns dataframe since audit column added in this method and table name with schema.

        Parameters
        ----------
        events : Dataframe
        table_name : str
            table name
        partition_keys : array[str]
            list of partition keys, by default None
        """

        self.logger.log(logging.INFO, f"## Job Started: {inspect.currentframe().f_code.co_name}")
        db_tablename = f"{self.rz_dbname}.staging_{table_name}"
        target_table_path = Path(self.staging_data_storage_path, table_name).as_posix()
        target_table_checkpoint_path = Path(self.staging_data_storage_path, self.checkpoint_name, table_name).as_posix()

        sink_data_helper.save_as_streaming_delta_table(
                    events,
                    target_table_path,
                    target_table_checkpoint_path,
                    db_tablename,
                    partition_keys=partition_keys)

        self.logger.log(logging.INFO, f"Data updated to {db_tablename} | Path: {target_table_path}")
        self.logger.log(logging.INFO, f"## Job Ended: {inspect.currentframe().f_code.co_name}")

        return events, db_tablename

    def get_events_from_local_files(self, format, bad_records_path, schema, location):
        """
        vanila spark structured streaming to support(UT) CI/CD automate pipeline which will return a dataframe

        Parameters
        ----------
        format : str
            file format such as parquet , csv, avro etc

        bad_records_path : str

        schema : DataStructure
            custom schmea for data present in landing location

        location : str
            Landing path


        Returns
        ----------
        Dataframe
            streaming data in batches
        """

        self.logger.log(logging.INFO, f"## Job Started: {inspect.currentframe().f_code.co_name}")
        self.logger.log(logging.INFO, f"Event data processing in local mode:- Format: {format} | Location: {location}")

        df = self.spark.readStream\
            .option('badRecordsPath', bad_records_path)\
            .format(format) \
            .schema(schema) \
            .option("multiline", "true") \
            .load(location)

        self.logger.log(logging.INFO, f"## Job Ended: {inspect.currentframe().f_code.co_name}")
        return df

    def get_events_from_cloud_files(self, type, format, bad_records_path, schema, location):
        """
        databricks auto loader with structured streaming which will return a dataframe

        Parameters
        ----------
        type : str
            cloudFiles

        format : str
            file format such as parquet, csv, avro etc

        bad_records_path : str

        schema : DataStructure
            custom schmea for data present in landing location

        location : str
            Landing path


        Returns
        ----------
        Dataframe
            streaming data in batches
        """

        self.logger.log(logging.INFO, f"## Job Started: {inspect.currentframe().f_code.co_name}")
        self.logger.log(logging.INFO, (f"Event data processing in autoloader mode:- Type: {type} "
                                       f"| Format: {format} | Location: {location}"))

        df = (self.spark.readStream
              .format(type)
              .option('cloudFiles.format', format)
              .option('header', 'true')
              .option('badRecordsPath', bad_records_path)
              .schema(schema)
              .option("multiline", "true")
              .load(location))

        self.logger.log(logging.INFO, f"## Job Ended: {inspect.currentframe().f_code.co_name}")
        return df
