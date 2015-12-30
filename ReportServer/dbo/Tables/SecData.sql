CREATE TABLE [dbo].[SecData] (
    [SecDataID]          UNIQUEIDENTIFIER NOT NULL,
    [PolicyID]           UNIQUEIDENTIFIER NOT NULL,
    [AuthType]           INT              NOT NULL,
    [XmlDescription]     NTEXT            NOT NULL,
    [NtSecDescPrimary]   IMAGE            NOT NULL,
    [NtSecDescSecondary] NTEXT            NULL,
    CONSTRAINT [PK_SecData] PRIMARY KEY NONCLUSTERED ([SecDataID] ASC),
    CONSTRAINT [FK_SecDataPolicyID] FOREIGN KEY ([PolicyID]) REFERENCES [dbo].[Policies] ([PolicyID]) ON DELETE CASCADE
);


GO
EXECUTE sp_tableoption @TableNamePattern = N'[dbo].[SecData]', @OptionName = N'text in row', @OptionValue = N'256';


GO
CREATE UNIQUE CLUSTERED INDEX [IX_SecData]
    ON [dbo].[SecData]([PolicyID] ASC, [AuthType] ASC);

