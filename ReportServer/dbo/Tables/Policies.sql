CREATE TABLE [dbo].[Policies] (
    [PolicyID]   UNIQUEIDENTIFIER NOT NULL,
    [PolicyFlag] TINYINT          NULL,
    CONSTRAINT [PK_Policies] PRIMARY KEY CLUSTERED ([PolicyID] ASC)
);

