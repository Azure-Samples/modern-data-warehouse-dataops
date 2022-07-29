-- Create Parquet Format [SynapseParquetFormat]
IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name = 'SynapseParquetFormat')
	CREATE EXTERNAL FILE FORMAT [SynapseParquetFormat]
	WITH ( FORMAT_TYPE = parquet)