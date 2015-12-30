CREATE EXTERNAL TABLE [dbo].[ReportServerTempDB_Segment] (
    [SegmentId] UNIQUEIDENTIFIER  NOT NULL,
    [Content]   VARBINARY (8000)  NULL
	)
WITH ( 	DATA_SOURCE = ReportServerTempDB,	SCHEMA_Name='dbo',	Object_name='Segment' ) 

