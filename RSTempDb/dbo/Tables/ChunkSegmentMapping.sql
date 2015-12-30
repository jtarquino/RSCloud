CREATE EXTERNAL TABLE [dbo].[ReportServerTempDB_ChunkSegmentMapping] (
    [ChunkId]          UNIQUEIDENTIFIER NOT NULL,
    [SegmentId]        UNIQUEIDENTIFIER NOT NULL,
    [StartByte]        BIGINT           NOT NULL,
    [LogicalByteCount] INT              NOT NULL,
    [ActualByteCount]  INT              NOT NULL
) WITH ( 	DATA_SOURCE = ReportServerTempDB,	SCHEMA_Name='dbo',	Object_name='ChunkSegmentMapping' ) 

