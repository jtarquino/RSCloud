CREATE TABLE [dbo].[Keys] (
    [MachineName]    NVARCHAR (256)   NULL,
    [InstallationID] UNIQUEIDENTIFIER NOT NULL,
    [InstanceName]   NVARCHAR (32)    NULL,
    [Client]         INT              NOT NULL,
    [PublicKey]      IMAGE            NULL,
    [SymmetricKey]   IMAGE            NULL,
    CONSTRAINT [PK_Keys] PRIMARY KEY CLUSTERED ([InstallationID] ASC, [Client] ASC)
);

