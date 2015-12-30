﻿CREATE TABLE [dbo].[DataSets] (
    [ID]     UNIQUEIDENTIFIER NOT NULL,
    [ItemID] UNIQUEIDENTIFIER NOT NULL,
    [LinkID] UNIQUEIDENTIFIER NULL,
    [Name]   NVARCHAR (260)   NOT NULL,
    CONSTRAINT [PK_DataSet] PRIMARY KEY NONCLUSTERED ([ID] ASC),
    CONSTRAINT [FK_DataSetItemID] FOREIGN KEY ([ItemID]) REFERENCES [dbo].[Catalog] ([ItemID]),
    CONSTRAINT [FK_DataSetLinkID] FOREIGN KEY ([LinkID]) REFERENCES [dbo].[Catalog] ([ItemID])
);


GO
CREATE CLUSTERED INDEX [IX_DataSet_ItemID_Name]
    ON [dbo].[DataSets]([ItemID] ASC, [Name] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_DataSetLinkID]
    ON [dbo].[DataSets]([LinkID] ASC);

