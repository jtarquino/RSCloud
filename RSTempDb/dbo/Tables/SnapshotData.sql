CREATE EXTERNAL TABLE [dbo].[ReportServerTempDB_SnapshotData] (
    [SnapshotDataID]    UNIQUEIDENTIFIER NOT NULL,
    [CreatedDate]       DATETIME         NOT NULL,
    [ParamsHash]        INT              NULL,
    [QueryParams]       NVARCHAR(MAX)            NULL,
    [EffectiveParams]   NVARCHAR(MAX)            NULL,
    [Description]       NVARCHAR (512)   NULL,
    [DependsOnUser]     BIT              NULL,
    [PermanentRefcount] INT              NOT NULL,
    [TransientRefcount] INT              NOT NULL,
    [ExpirationDate]    DATETIME         NOT NULL,
    [PageCount]         INT              NULL,
    [HasDocMap]         BIT              NULL,
    [Machine]           NVARCHAR (512)   NOT NULL,
    [PaginationMode]    SMALLINT         NULL,
    [ProcessingFlags]   INT              NULL,
    [IsCached]          BIT              NULL
)
WITH ( 	DATA_SOURCE = ReportServerTempDB,	SCHEMA_Name='dbo',	Object_name='SnapshotData' ) 

