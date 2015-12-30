CREATE TABLE [dbo].[ServerUpgradeHistory] (
    [UpgradeID]     BIGINT         IDENTITY (1, 1) NOT NULL,
    [ServerVersion] NVARCHAR (25)  NULL,
    [User]          NVARCHAR (128) DEFAULT (suser_sname()) NULL,
    [DateTime]      DATETIME       DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_ServerUpgradeHistory] PRIMARY KEY CLUSTERED ([UpgradeID] DESC)
);

