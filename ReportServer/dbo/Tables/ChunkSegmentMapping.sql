CREATE TABLE [dbo].[ChunkSegmentMapping] (
    [ChunkId]          UNIQUEIDENTIFIER NOT NULL,
    [SegmentId]        UNIQUEIDENTIFIER NOT NULL,
    [StartByte]        BIGINT           NOT NULL,
    [LogicalByteCount] INT              NOT NULL,
    [ActualByteCount]  INT              NOT NULL,
    CONSTRAINT [PK_ChunkSegmentMapping] PRIMARY KEY CLUSTERED ([ChunkId] ASC, [SegmentId] ASC),
    CONSTRAINT [Positive_ActualByteCount] CHECK ([ActualByteCount]>=(0)),
    CONSTRAINT [Positive_LogicalByteCount] CHECK ([LogicalByteCount]>=(0)),
    CONSTRAINT [Positive_StartByte] CHECK ([StartByte]>=(0))
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UNIQ_ChunkId_StartByte]
    ON [dbo].[ChunkSegmentMapping]([ChunkId] ASC, [StartByte] ASC)
    INCLUDE([ActualByteCount], [LogicalByteCount]);


GO
CREATE NONCLUSTERED INDEX [IX_ChunkSegmentMapping_SegmentId]
    ON [dbo].[ChunkSegmentMapping]([SegmentId] ASC);

