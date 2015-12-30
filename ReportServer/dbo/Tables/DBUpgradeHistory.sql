CREATE TABLE [dbo].[DBUpgradeHistory] (
    [UpgradeID] BIGINT         IDENTITY (1, 1) NOT NULL,
    [DbVersion] NVARCHAR (25)  NULL,
    [User]      NVARCHAR (128) DEFAULT (suser_sname()) NULL,
    [DateTime]  DATETIME       DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_DBUpgradeHistory] PRIMARY KEY CLUSTERED ([UpgradeID] DESC)
);

