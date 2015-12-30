CREATE EXTERNAL TABLE [dbo].[ReportServerTempDB_DBUpgradeHistory] (
    [UpgradeID] BIGINT         NOT NULL,
    [DbVersion] NVARCHAR (25)  NULL,
    [User]      NVARCHAR (128) NULL,
    [DateTime]  DATETIME       NULL
)
WITH ( 	DATA_SOURCE = ReportServerTempDB,	SCHEMA_Name='dbo',	Object_name='DBUpgradeHistory' ) 

