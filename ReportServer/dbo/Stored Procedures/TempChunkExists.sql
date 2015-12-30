
CREATE PROC [dbo].[TempChunkExists]
	@ChunkId uniqueidentifier
AS
BEGIN
	SELECT COUNT(1) FROM dbo.ReportServerTempDB_SegmentedChunk
	WHERE ChunkId = @ChunkId
END
