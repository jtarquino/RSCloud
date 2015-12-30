
CREATE VIEW [dbo].ExtendedDataSets
AS 
SELECT 
	ID, LinkID, [Name], ItemID
FROM DataSets
UNION ALL
SELECT
	ID, LinkID, [Name], ItemID
FROM dbo.ReportServerTempDB_TempDataSets
