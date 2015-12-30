CREATE EXTERNAL TABLE [dbo].[ReportServerTempDB_ChunkData] (
    [ChunkID]        UNIQUEIDENTIFIER NOT NULL,
    [SnapshotDataID] UNIQUEIDENTIFIER NOT NULL,
    [ChunkFlags]     TINYINT          NULL,
    [ChunkName]      NVARCHAR (260)   NULL,
    [ChunkType]      INT              NULL,
    [Version]        SMALLINT         NULL,
    [MimeType]       NVARCHAR (260)   NULL,
    [Content]        IMAGE            NULL
)
WITH 
( 
	DATA_SOURCE = ReportServerTempDB,
	SCHEMA_Name='dbo',
	Object_name='ChunkData'
) 



