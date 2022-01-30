IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[parking_bay_ext]') AND type in (N'U'))
    DROP EXTERNAL TABLE [dbo].[parking_bay_ext]
