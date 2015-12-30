
CREATE PROCEDURE [dbo].[DeleteDataSets]
@ItemID [uniqueidentifier]
AS
DELETE
FROM [DataSets]
WHERE [ItemID] = @ItemID
DELETE
FROM dbo.ReportServerTempDB_TempDataSets
WHERE [ItemID] = @ItemID
