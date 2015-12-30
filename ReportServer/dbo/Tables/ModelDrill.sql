CREATE TABLE [dbo].[ModelDrill] (
    [ModelDrillID] UNIQUEIDENTIFIER NOT NULL,
    [ModelID]      UNIQUEIDENTIFIER NOT NULL,
    [ReportID]     UNIQUEIDENTIFIER NOT NULL,
    [ModelItemID]  NVARCHAR (425)   NOT NULL,
    [Type]         TINYINT          NOT NULL,
    CONSTRAINT [PK_ModelDrill] PRIMARY KEY NONCLUSTERED ([ModelDrillID] ASC),
    CONSTRAINT [FK_ModelDrillModel] FOREIGN KEY ([ModelID]) REFERENCES [dbo].[Catalog] ([ItemID]) ON DELETE CASCADE,
    CONSTRAINT [FK_ModelDrillReport] FOREIGN KEY ([ReportID]) REFERENCES [dbo].[Catalog] ([ItemID])
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_ModelDrillModelID]
    ON [dbo].[ModelDrill]([ModelID] ASC, [ReportID] ASC, [ModelDrillID] ASC);

