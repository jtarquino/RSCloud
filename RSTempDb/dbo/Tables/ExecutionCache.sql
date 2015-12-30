CREATE EXTERNAL TABLE [dbo].[ReportServerTempDB_ExecutionCache] (
    [ExecutionCacheID]   UNIQUEIDENTIFIER NOT NULL,
    [ReportID]           UNIQUEIDENTIFIER NOT NULL,
    [ExpirationFlags]    INT              NOT NULL,
    [AbsoluteExpiration] DATETIME         NULL,
    [RelativeExpiration] INT              NULL,
    [SnapshotDataID]     UNIQUEIDENTIFIER NOT NULL,
    [LastUsedTime]       DATETIME          NOT NULL,
    [ParamsHash]         INT              NOT NULL
)
WITH ( 	DATA_SOURCE = ReportServerTempDB,	SCHEMA_Name='dbo',	Object_name='ExecutionCache' ) 

