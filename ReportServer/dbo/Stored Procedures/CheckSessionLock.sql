
CREATE PROCEDURE [dbo].[CheckSessionLock]
@SessionID as varchar(32),
@LockVersion  int OUTPUT
AS
DECLARE @Selected nvarchar(32)
SELECT @Selected=SessionID, @LockVersion = LockVersion FROM dbo.ReportServerTempDB_SessionLock WITH (ROWLOCK) WHERE SessionID = @SessionID
