
CREATE PROCEDURE [dbo].[LockPersistedStream]
@SessionID varchar(32),
@Index int
AS

SELECT [Index] FROM dbo.ReportServerTempDB_PersistedStream WITH (XLOCK) WHERE SessionID = @SessionID AND [Index] = @Index
