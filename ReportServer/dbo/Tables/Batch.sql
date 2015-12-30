CREATE TABLE [dbo].[Batch] (
    [BatchID]    UNIQUEIDENTIFIER NOT NULL,
    [AddedOn]    DATETIME         NOT NULL,
    [Action]     VARCHAR (32)     NOT NULL,
    [Item]       NVARCHAR (425)   NULL,
    [Parent]     NVARCHAR (425)   NULL,
    [Param]      NVARCHAR (425)   NULL,
    [BoolParam]  BIT              NULL,
    [Content]    IMAGE            NULL,
    [Properties] NTEXT            NULL
);


GO
CREATE CLUSTERED INDEX [IX_Batch]
    ON [dbo].[Batch]([BatchID] ASC, [AddedOn] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Batch_1]
    ON [dbo].[Batch]([AddedOn] ASC);

