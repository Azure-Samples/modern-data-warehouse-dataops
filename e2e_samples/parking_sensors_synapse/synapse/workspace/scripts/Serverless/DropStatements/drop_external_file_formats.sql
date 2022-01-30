IF  EXISTS (Select * from sys.external_file_formats WHERE name = 'SynapseParquetFormat')
    DROP EXTERNAL FILE FORMAT [SynapseParquetFormat]