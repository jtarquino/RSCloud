CREATE EXTERNAL TABLE [dbo].[ReportServerTempDB_TempDataSources] (
    [DSID]                                 UNIQUEIDENTIFIER NOT NULL,
    [ItemID]                               UNIQUEIDENTIFIER NOT NULL,
    [Name]                                 NVARCHAR (260)   NULL,
    [Extension]                            NVARCHAR (260)   NULL,
    [Link]                                 UNIQUEIDENTIFIER NULL,
    [CredentialRetrieval]                  INT              NULL,
    [Prompt]                               nvarchar(max)            NULL,
    [ConnectionString]                     IMAGE            NULL,
    [OriginalConnectionString]             IMAGE            NULL,
    [OriginalConnectStringExpressionBased] BIT              NULL,
    [UserName]                             IMAGE            NULL,
    [Password]                             IMAGE            NULL,
    [Flags]                                INT              NULL,
    [Version]                              INT              NOT NULL
)WITH ( 	DATA_SOURCE = ReportServerTempDB,	SCHEMA_Name='dbo',	Object_name='TempDataSources' ) 

