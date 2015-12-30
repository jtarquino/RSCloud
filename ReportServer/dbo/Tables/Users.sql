CREATE TABLE [dbo].[Users] (
    [UserID]       UNIQUEIDENTIFIER NOT NULL,
    [Sid]          VARBINARY (85)   NULL,
    [UserType]     INT              NOT NULL,
    [AuthType]     INT              NOT NULL,
    [UserName]     NVARCHAR (260)   NULL,
    [ServiceToken] NTEXT            NULL,
    [Setting]      NTEXT            NULL,
    CONSTRAINT [PK_Users] PRIMARY KEY NONCLUSTERED ([UserID] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_Users]
    ON [dbo].[Users]([Sid] ASC, [UserName] ASC, [AuthType] ASC);

