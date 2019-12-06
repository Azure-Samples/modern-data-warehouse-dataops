CREATE TABLE [dbo].[ErrorLog] (
    [ErrorLogID]     INT             IDENTITY (1, 1) NOT NULL,
    [ErrorTime]      DATETIME        CONSTRAINT [DF_ErrorLog_ErrorTime] DEFAULT (getdate()) NOT NULL,
    [UserName]       [sysname]       NOT NULL,
    [ErrorNumber]    INT             NOT NULL,
    [ErrorSeverity]  INT             NULL,
    [ErrorState]     INT             NULL,
    [ErrorProcedure] NVARCHAR (126)  NULL,
    [ErrorLine]      INT             NULL,
    [ErrorMessage]   NVARCHAR (4000) NOT NULL,
    CONSTRAINT [PK_ErrorLog_ErrorLogID] PRIMARY KEY CLUSTERED ([ErrorLogID] ASC)
);

