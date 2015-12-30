CREATE EXTERNAL TABLE [dbo].[ReportServerTempDB_SessionLock] (
    [SessionID]   VARCHAR (32) NOT NULL,
    [LockVersion] INT       NOT NULL
	)
WITH ( 	DATA_SOURCE = ReportServerTempDB,	SCHEMA_Name='dbo',	Object_name='SessionLock' ) 

