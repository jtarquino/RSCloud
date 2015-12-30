CREATE EXTERNAL TABLE [dbo].[ReportServerTempDB_TempDataSets] (
    [ID]     UNIQUEIDENTIFIER NOT NULL,
    [ItemID] UNIQUEIDENTIFIER NOT NULL,
    [LinkID] UNIQUEIDENTIFIER NULL,
    [Name]   NVARCHAR (260)   NOT NULL
)
WITH ( 	DATA_SOURCE = ReportServerTempDB,	SCHEMA_Name='dbo',	Object_name='TempDataSets' ) 
