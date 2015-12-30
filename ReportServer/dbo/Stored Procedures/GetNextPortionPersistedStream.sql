
CREATE PROCEDURE [dbo].[GetNextPortionPersistedStream]
@DataPointer binary(16),
@DataIndex int,
@Length int
AS

READTEXT dbo.ReportServerTempDB_PersistedStream.Content @DataPointer @DataIndex @Length
