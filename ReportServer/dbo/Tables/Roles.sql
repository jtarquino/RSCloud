CREATE TABLE [dbo].[Roles] (
    [RoleID]      UNIQUEIDENTIFIER NOT NULL,
    [RoleName]    NVARCHAR (260)   NOT NULL,
    [Description] NVARCHAR (512)   NULL,
    [TaskMask]    NVARCHAR (32)    NOT NULL,
    [RoleFlags]   TINYINT          NOT NULL,
    CONSTRAINT [PK_Roles] PRIMARY KEY NONCLUSTERED ([RoleID] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_Roles]
    ON [dbo].[Roles]([RoleName] ASC);

