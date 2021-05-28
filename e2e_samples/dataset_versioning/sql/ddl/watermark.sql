
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Create Watermark table
CREATE TABLE [dbo].[WaterMark](
	TableName varchar(50) NOT NULL UNIQUE,
	WaterMarkVal datetime NOT NULL
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

-- Create Source Table
CREATE TABLE [dbo].[source](
	id int NOT NULL UNIQUE,
	loan_amnt float NULL,
	annual_inc float NULL,
	dti float NULL,
	delinq_2yrs float NULL,
	total_acc float NULL,
	total_pymnt float NULL,
	issue_d date NULL,
	earliest_cr_line date NULL,
	loan_status nvarchar(max) NULL
)