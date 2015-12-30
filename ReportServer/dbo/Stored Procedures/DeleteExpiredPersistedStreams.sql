
CREATE PROCEDURE [dbo].[DeleteExpiredPersistedStreams]
AS
SET NOCOUNT OFF
SET DEADLOCK_PRIORITY LOW
declare @now as datetime = GETDATE();
delete top (10) p
from dbo.ReportServerTempDB_PersistedStream p with(readpast)
where p.RefCount = 0 AND p.ExpirationDate < @now;
