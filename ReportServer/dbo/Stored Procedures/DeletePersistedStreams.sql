
CREATE PROCEDURE [dbo].[DeletePersistedStreams]
@SessionID varchar(32)
AS
SET NOCOUNT OFF
delete top (10) p
from dbo.ReportServerTempDB_PersistedStream p
where p.SessionID = @SessionID;
