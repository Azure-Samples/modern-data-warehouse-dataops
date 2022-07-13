from .export_job import AbstractExportJob
from pathlib import Path


class ExportToCSV(AbstractExportJob):
    def export(self, df, idx=0):
        export_file_name = self.config["export_file_name"]
        output_dir = Path(self.export_data_storage_csv_path)
        output_dir.mkdir(parents=True, exist_ok=True)
        output_file = export_file_name + ".csv"
        df.to_csv(output_dir / output_file, index=False)
