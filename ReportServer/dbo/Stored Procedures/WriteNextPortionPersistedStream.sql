
CREATE PROCEDURE [dbo].[WriteNextPortionPersistedStream]
@DataPointer binary(16),
@DataIndex int,
@DeleteLength int,
@Content image
AS

UPDATETEXT dbo.ReportServerTempDB_PersistedStream.Content @DataPointer @DataIndex @DeleteLength @Content
