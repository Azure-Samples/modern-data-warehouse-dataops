IF  EXISTS (Select * from sys.database_credentials WHERE name = 'SynapseIdentity')
    DROP DATABASE SCOPED CREDENTIAL SynapseIdentity

IF  EXISTS (Select * from sys.database_credentials WHERE name = 'WorkspaceIdentity')
    DROP DATABASE SCOPED CREDENTIAL WorkspaceIdentity