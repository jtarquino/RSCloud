
CREATE PROCEDURE [dbo].[CleanExpiredCache]
AS
SET NOCOUNT OFF
DECLARE @now as datetime
SET @now = DATEADD(minute, -1, GETDATE())

UPDATE SN
SET
   PermanentRefcount = PermanentRefcount - 1
FROM
   dbo.ReportServerTempDB_SnapshotData AS SN
   INNER JOIN dbo.ReportServerTempDB_ExecutionCache AS EC ON SN.SnapshotDataID = EC.SnapshotDataID
WHERE
   EC.AbsoluteExpiration < @now
   
DELETE EC
FROM
   dbo.ReportServerTempDB_ExecutionCache AS EC
WHERE
   EC.AbsoluteExpiration < @now
