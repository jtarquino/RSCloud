CREATE EXTERNAL TABLE [dbo].[ReportServerTempDB_TempCatalog] (
    [EditSessionID]           VARCHAR (32)     NOT NULL,
    [TempCatalogID]           UNIQUEIDENTIFIER NOT NULL,
    [ContextPath]             NVARCHAR (425)   NOT NULL,
    [Name]                    NVARCHAR (425)   NOT NULL,
    [Content]                 VARBINARY (8000)  NULL,
    [Description]             NVARCHAR (MAX)   NULL,
    [Intermediate]            UNIQUEIDENTIFIER NULL,
    [IntermediateIsPermanent] BIT              NOT NULL,
    [Property]                NVARCHAR (MAX)   NULL,
    [Parameter]               NVARCHAR (MAX)   NULL,
    [OwnerID]                 UNIQUEIDENTIFIER NOT NULL,
    [CreationTime]            DATETIME         NOT NULL,
    [ExpirationTime]          DATETIME         NOT NULL,
    [DataCacheHash]           VARBINARY (64)   NULL
)
WITH ( 	DATA_SOURCE = ReportServerTempDB,	SCHEMA_Name='dbo',	Object_name='TempCatalog' ) 






