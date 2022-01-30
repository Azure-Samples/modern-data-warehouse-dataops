/****** Object:  ExternalDataSource [tpcds_msi]    Script Date: 24/08/2021 10:20:34 ******/
IF  EXISTS (Select * from sys.external_data_sources WHERE name = 'INTERIM_Zone')
    DROP EXTERNAL DATA SOURCE [INTERIM_Zone]