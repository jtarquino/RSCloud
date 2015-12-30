CREATE EXTERNAL TABLE [dbo].[ReportServerTempDB_SegmentedChunk] (
    [ChunkId]          UNIQUEIDENTIFIER NOT NULL,
    [SnapshotDataId]   UNIQUEIDENTIFIER NOT NULL,
    [ChunkFlags]       TINYINT          NOT NULL,
    [ChunkName]        NVARCHAR (260)   NOT NULL,
    [ChunkType]        INT              NOT NULL,
    [Version]          SMALLINT         NOT NULL,
    [MimeType]         NVARCHAR (260)   NULL,
    [Machine]          NVARCHAR (512)   NOT NULL,
    [SegmentedChunkId] BIGINT           
)    
WITH ( 	DATA_SOURCE = ReportServerTempDB,	SCHEMA_Name='dbo',	Object_name='SegmentedChunk' ) 
