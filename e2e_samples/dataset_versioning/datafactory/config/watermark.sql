-- Create Watermark table
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WaterMark](
	[TableName] [varchar](50) NULL UNIQUE,
	[WaterMarkVal] [datetime] NULL
) ON [PRIMARY]
GO

-- Insert initial value
INSERT [dbo].[WaterMark] ([TableName], [WaterMarkVal]) VALUES (N'source', CAST(N'1900-01-01T00:00:00.000' AS DateTime))
GO

-- Create procedure
CREATE PROCEDURE [dbo].[usp_UpdateWatermark] @LastModifiedtime varchar(100), @TableName varchar(100)
AS
BEGIN
    UPDATE [dbo].[WaterMark]
    SET WaterMarkVal = CAST(@LastModifiedtime as datetime) 
	WHERE TableName = @TableName
END
GO

-- Truncate table when you want to reset data in dbo.WaterMark
Truncate table dbo.WaterMark