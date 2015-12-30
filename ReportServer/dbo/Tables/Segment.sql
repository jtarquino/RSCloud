CREATE TABLE [dbo].[Segment] (
    [SegmentId] UNIQUEIDENTIFIER CONSTRAINT [DF_Segment_SegmentId] DEFAULT (newsequentialid()) NOT NULL,
    [Content]   VARBINARY (MAX)  NULL,
    CONSTRAINT [PK_Segment] PRIMARY KEY CLUSTERED ([SegmentId] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_SegmentMetadata]
    ON [dbo].[Segment]([SegmentId] ASC);

