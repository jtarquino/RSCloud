
CREATE PROCEDURE [dbo].[DeletePersistedStream]
@SessionID varchar(32),
@Index int
AS

delete from dbo.ReportServerTempDB_PersistedStream where SessionID = @SessionID and [Index] = @Index
