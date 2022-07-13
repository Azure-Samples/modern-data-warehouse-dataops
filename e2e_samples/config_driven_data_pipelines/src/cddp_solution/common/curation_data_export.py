from cddp_solution.common.export.export_job import AbstractExportJob
from cddp_solution.common.export.export_postgresql import ExportToPostgreSQL
from cddp_solution.common.export.export_csv import ExportToCSV


class AbstractCurationDataExport(AbstractExportJob):
    export_action = None

    def __init__(self, config):
        super().__init__(config)

        export_target_type = self.config["export_target_type"]
        if export_target_type == "csv":
            self.export_action = ExportToCSV(self.config)
        elif export_target_type == "postgresql":
            self.export_action = ExportToPostgreSQL(self.config)

    def export(self, idx=0):
        """
        Exports event data by export actions defined under "export_target_type" of config.json

        Parameters
        ----------
        idx : int
            --, by default 0

        """
        transform_list = self.config["event_data_curation"]
        target_table_path = self.config["serving_data_storage_path"]
        for data_transform in transform_list:
            transform_target = data_transform["target"]
            target_table_path = self.serving_data_storage_path+"/"+transform_target
            transformed_data = self.spark.read.format("delta").load(target_table_path)
            df = transformed_data.toPandas()
            self.export_action.export(df)
