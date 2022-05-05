CREATE EXTERNAL DATA SOURCE [AzureDataLakeStorage]
    WITH (
    TYPE = HADOOP,
    LOCATION = N'$(ADLSLocation)',
    CREDENTIAL = [ADLSCredentialKey]
    );







