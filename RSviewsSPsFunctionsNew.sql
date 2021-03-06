
CREATE FUNCTION [dbo].[ExtendedCatalog]
    (@OwnerID as uniqueidentifier, 
     @Path as nvarchar(425), 
     @EditSessionID as varchar(32))
RETURNS TABLE 
AS RETURN 
(
SELECT TOP 1 * FROM (
SELECT 
    C.[ItemID], 
    C.[PolicyID],
    C.[Path],
    C.[Name],
    C.[Description], 
    C.[Property],
    C.[Type], 
    C.[ExecutionFlag], 
    C.[Parameter], 
    C.[Intermediate], 
    CONVERT(BIT, 1) AS IntermediateIsPermanent, 
    C.[SnapshotDataID], 
    C.[LinkSourceID], 
    C.[ExecutionTime], 
    C.[SnapshotLimit],
    C.[CreatedByID], 
    C.[ModifiedByID],
    C.[CreationDate],
    C.[ModifiedDate], 
    C.[MimeType],
    C.[Content],
    C.[Hidden],
    NULL AS [EditSessionID], 
    C.[SubType],
    C.[ComponentID]
FROM [Catalog] C
WHERE C.Path = @Path AND @EditSessionID IS NULL
UNION ALL
SELECT 
    TC.[TempCatalogID], 
    NULL as [PolicyID],
    TC.[ContextPath],
    TC.[Name],
    TC.[Description], 
    TC.[Property],
    2 as [Type], 
    1 as [ExecutionFlag],
    TC.[Parameter], 
    TC.[Intermediate], 
    TC.[IntermediateIsPermanent],
    NULL as [SnapshotDataID], 
    NULL as [LinkSourceID], 
    NULL as [ExecutionTime], 
    0 as [SnapshotLimit],
    TC.[OwnerID] as [CreatedByID],
    TC.[OwnerID] as [ModifiedByID],
    TC.[CreationTime] as [CreationDate],
    TC.[CreationTime] as [ModifiedDate],
    NULL as [MimeType],
    TC.Content,
    convert(bit, 0) as [Hidden],
    TC.[EditSessionID] AS [EditSessionID], 
    NULL as [SubType],
    NULL as [ComponentID]
FROM dbo.ReportServerTempDB_TempCatalog TC
WHERE	TC.OwnerID = @OwnerID AND
        TC.ContextPath = @Path AND
        TC.EditSessionID = @EditSessionID
) A )

GO
/****** Object:  View [dbo].[ExecutionLog]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[ExecutionLog]
AS
SELECT
    [InstanceName], 
    [ReportID], 
    [UserName], 
    CASE ([RequestType])
        WHEN 1 THEN CONVERT(BIT, 1)
        ELSE CONVERT(BIT, 0)
    END AS [RequestType],
    [Format],
    [Parameters],
    [TimeStart],
    [TimeEnd],
    [TimeDataRetrieval],
    [TimeProcessing],
    [TimeRendering],
    CASE([Source])
        WHEN 6 THEN 3
        ELSE [Source]
    END AS Source,      -- Session source doesn't exist in yukon, mark source as snapshot
                        -- for in-session requests
    [Status],
    [ByteCount],
    [RowCount]
FROM [ExecutionLogStorage] WITH (NOLOCK)
WHERE [ReportAction] = 1 -- Backwards compatibility log only contains render requests

GO
/****** Object:  View [dbo].[ExecutionLog2]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[ExecutionLog2]
AS
SELECT 
	InstanceName, 
	COALESCE(C.Path, 'Unknown') AS ReportPath, 
	UserName,
	ExecutionId, 
	CASE(RequestType)
		WHEN 0 THEN 'Interactive'
		WHEN 1 THEN 'Subscription'
		ELSE 'Unknown'
		END AS RequestType, 
	-- SubscriptionId, 
	Format, 
	Parameters, 
	CASE(ReportAction)		
		WHEN 1 THEN 'Render'
		WHEN 2 THEN 'BookmarkNavigation'
		WHEN 3 THEN 'DocumentMapNavigation'
		WHEN 4 THEN 'DrillThrough'
		WHEN 5 THEN 'FindString'
		WHEN 6 THEN 'GetDocumentMap'
		WHEN 7 THEN 'Toggle'
		WHEN 8 THEN 'Sort'
		ELSE 'Unknown'
		END AS ReportAction,
	TimeStart, 
	TimeEnd, 
	TimeDataRetrieval, 
	TimeProcessing, 
	TimeRendering,
	CASE(Source)
		WHEN 1 THEN 'Live'
		WHEN 2 THEN 'Cache'
		WHEN 3 THEN 'Snapshot' 
		WHEN 4 THEN 'History'
		WHEN 5 THEN 'AdHoc'
		WHEN 6 THEN 'Session'
		WHEN 7 THEN 'Rdce'
		ELSE 'Unknown'
		END AS Source,
	Status,
	ByteCount,
	[RowCount],
	AdditionalInfo
FROM ExecutionLogStorage EL WITH(NOLOCK)
LEFT OUTER JOIN Catalog C WITH(NOLOCK) ON (EL.ReportID = C.ItemID)

GO
/****** Object:  View [dbo].[ExecutionLog3]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[ExecutionLog3]
AS
SELECT 
    InstanceName,
	COALESCE(CASE(ReportAction)
        WHEN 11 THEN AdditionalInfo.value('(AdditionalInfo/SourceReportUri)[1]', 'nvarchar(max)')
        ELSE C.Path
        END, 'Unknown') AS ItemPath, 
    UserName,
    ExecutionId, 
    CASE(RequestType)
        WHEN 0 THEN 'Interactive'
        WHEN 1 THEN 'Subscription'
        WHEN 2 THEN 'Refresh Cache'
        ELSE 'Unknown'
        END AS RequestType, 
    -- SubscriptionId, 
    Format, 
    Parameters, 
    CASE(ReportAction)		
        WHEN 1 THEN 'Render'
        WHEN 2 THEN 'BookmarkNavigation'
        WHEN 3 THEN 'DocumentMapNavigation'
        WHEN 4 THEN 'DrillThrough'
        WHEN 5 THEN 'FindString'
        WHEN 6 THEN 'GetDocumentMap'
        WHEN 7 THEN 'Toggle'
        WHEN 8 THEN 'Sort'
        WHEN 9 THEN 'Execute'
        WHEN 10 THEN 'RenderEdit'
        WHEN 11 THEN 'ExecuteDataShapeQuery'
        ELSE 'Unknown'
        END AS ItemAction,
    TimeStart, 
    TimeEnd, 
    TimeDataRetrieval, 
    TimeProcessing, 
    TimeRendering,
    CASE(Source)
        WHEN 1 THEN 'Live'
        WHEN 2 THEN 'Cache'
        WHEN 3 THEN 'Snapshot' 
        WHEN 4 THEN 'History'
        WHEN 5 THEN 'AdHoc'
        WHEN 6 THEN 'Session'
        WHEN 7 THEN 'Rdce'
        ELSE 'Unknown'
        END AS Source,
    Status,
    ByteCount,
    [RowCount],
    AdditionalInfo
FROM ExecutionLogStorage EL WITH(NOLOCK)
LEFT OUTER JOIN Catalog C WITH(NOLOCK) ON (EL.ReportID = C.ItemID)

GO
/****** Object:  View [dbo].[ExtendedDataSets]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[ExtendedDataSets]
AS 
SELECT 
	ID, LinkID, [Name], ItemID
FROM DataSets
UNION ALL
SELECT
	ID, LinkID, [Name], ItemID
FROM dbo.ReportServerTempDB_TempDataSets

GO
/****** Object:  View [dbo].[ExtendedDataSources]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[ExtendedDataSources]
AS 
SELECT 
	DSID, ItemID, SubscriptionID, Name, Extension, Link, 
	CredentialRetrieval, Prompt, ConnectionString, 
	OriginalConnectionString, OriginalConnectStringExpressionBased, 
	UserName, Password, Flags, Version
FROM DataSource
UNION ALL
SELECT
	DSID, ItemID, NULL as [SubscriptionID], Name, Extension, Link, 
	CredentialRetrieval, Prompt, ConnectionString, 
	OriginalConnectionString, OriginalConnectStringExpressionBased, 
	UserName, Password, Flags, Version
FROM dbo.ReportServerTempDB_TempDataSources

GO
/****** Object:  StoredProcedure [dbo].[AddBatchRecord]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddBatchRecord]
@BatchID uniqueidentifier,
@UserName nvarchar(260),
@Action varchar(32),
@Item nvarchar(425) = NULL,
@Parent nvarchar(425) = NULL,
@Param nvarchar(425) = NULL,
@BoolParam bit = NULL,
@Content image = NULL,
@Properties ntext = NULL
AS

IF @Action='BatchStart' BEGIN
   INSERT
   INTO [Batch] (BatchID, AddedOn, [Action], Item, Parent, Param, BoolParam, Content, Properties)
   VALUES (@BatchID, GETUTCDATE(), @Action, @UserName, @Parent, @Param, @BoolParam, @Content, @Properties)
END ELSE BEGIN
   IF EXISTS (SELECT * FROM Batch WHERE BatchID = @BatchID AND [Action] = 'BatchStart' AND Item = @UserName) BEGIN
      INSERT
      INTO [Batch] (BatchID, AddedOn, [Action], Item, Parent, Param, BoolParam, Content, Properties)
      VALUES (@BatchID, GETUTCDATE(), @Action, @Item, @Parent, @Param, @BoolParam, @Content, @Properties)
   END ELSE BEGIN
      RAISERROR( 'Batch does not exist', 16, 1 )
   END
END

GO
/****** Object:  StoredProcedure [dbo].[AddDataSet]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddDataSet]
@ID [uniqueidentifier],
@ItemID [uniqueidentifier],
@EditSessionID varchar(32) = NULL,
@Name [nvarchar] (260), 
@LinkID [uniqueidentifier] = NULL, -- link id is trusted, if it is provided - we use it
@LinkPath [nvarchar] (425) = NULL, -- if LinkId is not provided we try to look up LinkPath
@AuthType [int]
AS

DECLARE @ActualLinkID uniqueidentifier
SET @ActualLinkID = NULL

IF (@LinkID is NULL) AND (@LinkPath is not NULL) BEGIN
   SELECT
      ItemID, NtSecDescPrimary
   FROM
      Catalog LEFT OUTER JOIN SecData ON Catalog.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
   WHERE
      Path = @LinkPath AND Type = 8
   SET @ActualLinkID = (SELECT ItemID FROM Catalog WHERE Path = @LinkPath AND Type = 8)
END
ELSE BEGIN
   SET @ActualLinkID = @LinkID
END

IF(@EditSessionID is not null)
BEGIN
    INSERT 
        INTO dbo.ReportServerTempDB_TempDataSets
            (ID, ItemID, [Name], LinkID)
        VALUES
            (@ID, @ItemID, @Name, @ActualLinkID)
    
    EXEC ExtendEditSessionLifetime @EditSessionID
END
ELSE
BEGIN
INSERT
    INTO DataSets
            (ID, ItemID, [Name], LinkID)
        VALUES
            (@ID, @ItemID, @Name, @ActualLinkID)
END

GO
/****** Object:  StoredProcedure [dbo].[AddDataSource]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddDataSource]
@DSID [uniqueidentifier],
@ItemID [uniqueidentifier] = NULL, -- null for future suport dynamic delivery
@SubscriptionID [uniqueidentifier] = NULL,
@EditSessionID varchar(32) = NULL,
@Name [nvarchar] (260) = NULL, -- only for scoped data sources, MUST be NULL for standalone!!!
@Extension [nvarchar] (260) = NULL,
@LinkID [uniqueidentifier] = NULL, -- link id is trusted, if it is provided - we use it
@LinkPath [nvarchar] (425) = NULL, -- if LinkId is not provided we try to look up LinkPath
@CredentialRetrieval [int],
@Prompt [ntext] = NULL,
@ConnectionString [image] = NULL,
@OriginalConnectionString [image] = NULL,
@OriginalConnectStringExpressionBased [bit] = NULL,
@UserName [image] = NULL,
@Password [image] = NULL,
@Flags [int],
@AuthType [int],
@Version [int]
AS

DECLARE @ActualLinkID uniqueidentifier
SET @ActualLinkID = NULL

IF (@LinkID is NULL) AND (@LinkPath is not NULL) BEGIN
   SELECT
      Type, ItemID, NtSecDescPrimary
   FROM
      Catalog LEFT OUTER JOIN SecData ON Catalog.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
   WHERE
      Path = @LinkPath
   SET @ActualLinkID = (SELECT ItemID FROM Catalog WHERE Path = @LinkPath)
END
ELSE BEGIN
   SET @ActualLinkID = @LinkID
END

IF(@EditSessionID is not null)
BEGIN
    INSERT 
        INTO dbo.ReportServerTempDB_TempDataSources
            (DSID, ItemID, [Name], Extension, Link, CredentialRetrieval, 
            Prompt, ConnectionString, OriginalConnectionString, OriginalConnectStringExpressionBased, 
            UserName, Password, Flags, Version)
        VALUES
            (@DSID, @ItemID, @Name, @Extension, @ActualLinkID,
            @CredentialRetrieval, @Prompt,
            @ConnectionString, @OriginalConnectionString, @OriginalConnectStringExpressionBased,
            @UserName, @Password, @Flags, @Version)
    
    EXEC ExtendEditSessionLifetime @EditSessionID
END
ELSE
BEGIN
INSERT
    INTO DataSource
        ([DSID], [ItemID], [SubscriptionID], [Name], [Extension], [Link],
        [CredentialRetrieval], [Prompt],
        [ConnectionString], [OriginalConnectionString], [OriginalConnectStringExpressionBased], 
        [UserName], [Password], [Flags], [Version])
    VALUES
        (@DSID, @ItemID, @SubscriptionID, @Name, @Extension, @ActualLinkID,
        @CredentialRetrieval, @Prompt,
        @ConnectionString, @OriginalConnectionString, @OriginalConnectStringExpressionBased,
        @UserName, @Password, @Flags, @Version)
   
END

GO
/****** Object:  StoredProcedure [dbo].[AddEvent]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddEvent] 
@EventType nvarchar (260),
@EventData nvarchar (260)
AS

insert into [Event] 
    ([EventID], [EventType], [EventData], [TimeEntered], [ProcessStart], [BatchID]) 
values
    (NewID(), @EventType, @EventData, GETUTCDATE(), NULL, NULL)

GO
/****** Object:  StoredProcedure [dbo].[AddExecutionLogEntry]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddExecutionLogEntry]
@InstanceName nvarchar(38),
@Report nvarchar(260),
@UserSid varbinary(85) = NULL,
@UserName nvarchar(260),
@AuthType int,
@RequestType tinyint,
@Format nvarchar(26),
@Parameters ntext,
@TimeStart DateTime,
@TimeEnd DateTime,
@TimeDataRetrieval int,
@TimeProcessing int,
@TimeRendering int,
@Source tinyint,
@Status nvarchar(40),
@ByteCount bigint,
@RowCount bigint,
@ExecutionId nvarchar(64) = null,
@ReportAction tinyint, 
@AdditionalInfo xml = null
AS

-- Unless is is specifically 'False', it's true
if exists (select * from ConfigurationInfo where [Name] = 'EnableExecutionLogging' and [Value] like 'False')
begin
return
end

Declare @ReportID uniqueidentifier
select @ReportID = ItemID from Catalog with (nolock) where Path = @Report

insert into ExecutionLogStorage
(InstanceName, ReportID, UserName, ExecutionId, RequestType, [Format], Parameters, ReportAction, TimeStart, TimeEnd, TimeDataRetrieval, TimeProcessing, TimeRendering, Source, Status, ByteCount, [RowCount], AdditionalInfo)
Values
(@InstanceName, @ReportID, @UserName, @ExecutionId, @RequestType, @Format, @Parameters, @ReportAction, @TimeStart, @TimeEnd, @TimeDataRetrieval, @TimeProcessing, @TimeRendering, @Source, @Status, @ByteCount, @RowCount, @AdditionalInfo)

GO
/****** Object:  StoredProcedure [dbo].[AddHistoryRecord]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- add new record to History table
CREATE PROCEDURE [dbo].[AddHistoryRecord]
@HistoryID uniqueidentifier,
@ReportID uniqueidentifier,
@SnapshotDate datetime,
@SnapshotDataID uniqueidentifier,
@SnapshotTransientRefcountChange int
AS
INSERT
INTO History (HistoryID, ReportID, SnapshotDataID, SnapshotDate)
VALUES (@HistoryID, @ReportID, @SnapshotDataID, @SnapshotDate)

IF @@ERROR = 0
BEGIN
   UPDATE SnapshotData
   -- Snapshots, when created, have transient refcount set to 1. Here create permanent reference
   -- here so we need to increase permanent refcount and decrease transient refcount. However,
   -- if it was already referenced by the execution snapshot, transient refcount was already
   -- decreased. Hence, there's a parameter @SnapshotTransientRefcountChange that is 0 or -1.
   SET PermanentRefcount = PermanentRefcount + 1, TransientRefcount = TransientRefcount + @SnapshotTransientRefcountChange
   WHERE SnapshotData.SnapshotDataID = @SnapshotDataID
END

GO
/****** Object:  StoredProcedure [dbo].[AddModelPerspective]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddModelPerspective]
@ModelID as uniqueidentifier,
@PerspectiveID as ntext,
@PerspectiveName as ntext = null,
@PerspectiveDescription as ntext = null
AS

INSERT
INTO [ModelPerspective]
    ([ID], [ModelID], [PerspectiveID], [PerspectiveName], [PerspectiveDescription])
VALUES
    (newid(), @ModelID, @PerspectiveID, @PerspectiveName, @PerspectiveDescription)

GO
/****** Object:  StoredProcedure [dbo].[AddPersistedStream]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddPersistedStream]
@SessionID varchar(32),
@Index int
AS

DECLARE @RefCount int
DECLARE @id varchar(32)
DECLARE @ExpirationDate datetime

set @RefCount = 0
set @ExpirationDate = DATEADD(day, 2, GETDATE())

set @id = (select SessionID from dbo.ReportServerTempDB_SessionData where SessionID = @SessionID)

if @id is not null
begin
set @RefCount = 1
end

INSERT INTO dbo.ReportServerTempDB_PersistedStream (SessionID, [Index], [RefCount], [ExpirationDate]) VALUES (@SessionID, @Index, @RefCount, @ExpirationDate)

GO
/****** Object:  StoredProcedure [dbo].[AddReportSchedule]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddReportSchedule]
@ScheduleID uniqueidentifier,
@ReportID uniqueidentifier,
@SubscriptionID uniqueidentifier = NULL,
@Action int
AS

-- VSTS #139366: SQL Deadlock in AddReportSchedule stored procedure
-- Hold lock on [Schedule].[ScheduleID] to prevent deadlock
-- with Schedule_UpdateExpiration Schedule's after update trigger
select 1 from [Schedule] with (HOLDLOCK) where [Schedule].[ScheduleID] = @ScheduleID

Insert into ReportSchedule ([ScheduleID], [ReportID], [SubscriptionID], [ReportAction]) values (@ScheduleID, @ReportID, @SubscriptionID, @Action)

GO
/****** Object:  StoredProcedure [dbo].[AddReportToCache]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddReportToCache]
@ReportID as uniqueidentifier,
@ExecutionDate datetime,
@SnapshotDataID uniqueidentifier,
@CacheLimit int = 0,
@EditSessionTimeout int = NULL,
@QueryParamsHash int,
@ExpirationDate datetime OUTPUT,
@ScheduleID uniqueidentifier OUTPUT
AS
DECLARE @ExpirationFlags as int
DECLARE @Timeout as int

SET @ExpirationDate = NULL
SET @ScheduleID = NULL
SET @ExpirationFlags = (SELECT ExpirationFlags FROM CachePolicy WHERE ReportID = @ReportID)
IF @EditSessionTimeout IS NOT NULL
BEGIN
    SET @ExpirationFlags = 1 -- use timeout based expiration
    SET @Timeout = @EditSessionTimeout
    SET @ExpirationDate = DATEADD(n, @Timeout, @ExecutionDate)
END
ELSE IF @ExpirationFlags = 1 -- timeout based
BEGIN
    SET @Timeout = (SELECT CacheExpiration FROM CachePolicy WHERE ReportID = @ReportID)
    SET @ExpirationDate = DATEADD(n, @Timeout, @ExecutionDate)
END
ELSE IF @ExpirationFlags = 2 -- schedule based
BEGIN
    SELECT @ScheduleID=s.ScheduleID, @ExpirationDate=s.NextRunTime 
    FROM Schedule s WITH(UPDLOCK) INNER JOIN ReportSchedule rs ON rs.ScheduleID = s.ScheduleID and rs.ReportAction = 3 WHERE rs.ReportID = @ReportID
END
ELSE
BEGIN
    -- Ignore NULL case. It means that a user set the Report not to be cached after the report execution fired.
    IF @ExpirationFlags IS NOT NULL
    BEGIN
        RAISERROR('Invalid cache flags', 16, 1)
    END
    RETURN
END

-- mark any existing entries for this parameter combination to expire very soon in the future
-- note that we do not explicitly delete them here to avoid a race with execution sessions which 
-- have discovered these cache entries but have not as of yet increased their transient refcounts
DECLARE @NewExpirationTime DATETIME ;
SELECT @NewExpirationTime = DATEADD(n, 1, GETDATE()) ;

BEGIN TRANSACTION

UPDATE	dbo.ReportServerTempDB_ExecutionCache 
SET		AbsoluteExpiration = @NewExpirationTime
WHERE	AbsoluteExpiration > @NewExpirationTime AND
		ReportID = @ReportID AND 
		ParamsHash = @QueryParamsHash

-- add to the report cache
INSERT INTO dbo.ReportServerTempDB_ExecutionCache
(ExecutionCacheID, ReportID, ExpirationFlags, AbsoluteExpiration, RelativeExpiration, SnapshotDataID, LastUsedTime, ParamsHash)
VALUES
(newid(), @ReportID, @ExpirationFlags, @ExpirationDate, @Timeout, @SnapshotDataID, @ExecutionDate, @QueryParamsHash)

UPDATE dbo.ReportServerTempDB_SnapshotData
SET PermanentRefcount = PermanentRefcount + 1,
    IsCached = CONVERT(BIT, 1), 
    TransientRefcount = CASE 
                        WHEN @EditSessionTimeout IS NOT NULL THEN TransientRefcount - 1
                        ELSE TransientRefCount
                        END
WHERE SnapshotDataID = @SnapshotDataID;   
EXEC EnforceCacheLimits @ReportID, @CacheLimit ;

COMMIT

GO
/****** Object:  StoredProcedure [dbo].[AddRunningJob]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddRunningJob]
@JobID as nvarchar(32),
@StartDate as datetime,
@ComputerName as nvarchar(32),
@RequestName as nvarchar(425),
@RequestPath as nvarchar(425),
@UserSid varbinary(85) = NULL,
@UserName nvarchar(260),
@AuthType int,
@Description as ntext  = NULL,
@Timeout as int,
@JobAction as smallint,
@JobType as smallint,
@JobStatus as smallint
AS
SET NOCOUNT OFF
DECLARE @UserID uniqueidentifier
EXEC GetUserID @UserSid, @UserName, @AuthType, @UserID OUTPUT

INSERT INTO RunningJobs (JobID, StartDate, ComputerName, RequestName, RequestPath, UserID, Description, Timeout, JobAction, JobType, JobStatus )
VALUES             (@JobID, @StartDate, @ComputerName,  @RequestName, @RequestPath, @UserID, @Description, @Timeout, @JobAction, @JobType, @JobStatus)

GO
/****** Object:  StoredProcedure [dbo].[AddSubscriptionToBeingDeleted]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddSubscriptionToBeingDeleted] 
@SubscriptionID uniqueidentifier
AS
-- Delete subscription if it is already in this table
-- Delete orphaned subscriptions, based on the age criteria: > 10 minutes
delete from [SubscriptionsBeingDeleted] 
where (SubscriptionID = @SubscriptionID) or (DATEDIFF( minute, [CreationDate], GetUtcDate() ) > 10)

-- Add subscription being deleted into the DeletedSubscription table
insert into [SubscriptionsBeingDeleted] VALUES(@SubscriptionID, GetUtcDate())

GO
/****** Object:  StoredProcedure [dbo].[AnnounceOrGetKey]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AnnounceOrGetKey]
@MachineName nvarchar(256),
@InstanceName nvarchar(32),
@InstallationID uniqueidentifier,
@PublicKey image,
@NumAnnouncedServices int OUTPUT
AS

-- Acquire lock
IF NOT EXISTS (SELECT * FROM [dbo].[Keys] WITH(XLOCK) WHERE [Client] < 0)
BEGIN
    RAISERROR('Keys lock row not found', 16, 1)
    RETURN
END

-- Get the number of services that have already announced their presence
SELECT @NumAnnouncedServices = count(*)
FROM [dbo].[Keys]
WHERE [Client] = 1

DECLARE @StoredInstallationID uniqueidentifier
DECLARE @StoredInstanceName nvarchar(32)

SELECT @StoredInstallationID = [InstallationID], @StoredInstanceName = [InstanceName]
FROM [dbo].[Keys]
WHERE [InstallationID] = @InstallationID AND [Client] = 1

IF @StoredInstallationID IS NULL -- no record present
BEGIN
    INSERT INTO [dbo].[Keys]
        ([MachineName], [InstanceName], [InstallationID], [Client], [PublicKey], [SymmetricKey])
    VALUES
        (@MachineName, @InstanceName, @InstallationID, 1, @PublicKey, null)
END
ELSE
BEGIN
    IF @StoredInstanceName IS NULL
    BEGIN
        UPDATE [dbo].[Keys]
        SET [InstanceName] = @InstanceName
        WHERE [InstallationID] = @InstallationID AND [Client] = 1
    END
END

SELECT [MachineName], [SymmetricKey], [PublicKey]
FROM [Keys]
WHERE [InstallationID] = @InstallationID and [Client] = 1

GO
/****** Object:  StoredProcedure [dbo].[ChangeStateOfDataSource]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ChangeStateOfDataSource]
@ItemID [uniqueidentifier],
@Enable bit
AS
IF @Enable != 0 BEGIN
   UPDATE [DataSource]
      SET
         [Flags] = [Flags] | 1
   WHERE [ItemID] = @ItemID
END
ELSE
BEGIN
   UPDATE [DataSource]
      SET
         [Flags] = [Flags] & 0x7FFFFFFE
   WHERE [ItemID] = @ItemID
END

GO
/****** Object:  StoredProcedure [dbo].[CheckSessionLock]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CheckSessionLock]
@SessionID as varchar(32),
@LockVersion  int OUTPUT
AS
DECLARE @Selected nvarchar(32)
SELECT @Selected=SessionID, @LockVersion = LockVersion FROM dbo.ReportServerTempDB_SessionLock WITH (ROWLOCK) WHERE SessionID = @SessionID

GO
/****** Object:  StoredProcedure [dbo].[CleanAllHistories]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- delete snapshots exceeding # of snapshots for the whole system
CREATE PROCEDURE [dbo].[CleanAllHistories]
@SnapshotLimit int
AS
SET NOCOUNT OFF
DELETE FROM History
WHERE HistoryID in 
    (SELECT HistoryID
     FROM History JOIN Catalog AS ReportJoinSnapshot ON ItemID = ReportID
     WHERE SnapshotLimit IS NULL and SnapshotDate < 
        (SELECT MIN(SnapshotDate)
         FROM 
            (SELECT TOP (@SnapshotLimit) SnapshotDate
             FROM History AS InnerSnapshot
             WHERE InnerSnapshot.ReportID = ReportJoinSnapshot.ItemID
             ORDER BY SnapshotDate DESC
            ) AS TopSnapshots
        )
    )

GO
/****** Object:  StoredProcedure [dbo].[CleanBatchRecords]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CleanBatchRecords]
@MaxAgeMinutes int
AS
SET NOCOUNT OFF
DELETE FROM [Batch]
where BatchID in
   ( SELECT BatchID
     FROM [Batch]
     WHERE AddedOn < DATEADD(minute, -(@MaxAgeMinutes), GETUTCDATE()) )

GO
/****** Object:  StoredProcedure [dbo].[CleanBrokenSnapshots]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CleanBrokenSnapshots]
@Machine nvarchar(512),
@SnapshotsCleaned int OUTPUT,
@ChunksCleaned int OUTPUT,
@TempSnapshotID uniqueidentifier OUTPUT
AS
    SET DEADLOCK_PRIORITY LOW
    DECLARE @now AS datetime
    SELECT @now = GETDATE()
    
    CREATE TABLE #tempSnapshot (SnapshotDataID uniqueidentifier)
    INSERT INTO #tempSnapshot SELECT TOP 1 SnapshotDataID 
    FROM SnapshotData  WITH (NOLOCK) 
    where SnapshotData.PermanentRefcount <= 0 
    AND ExpirationDate < @now
    SET @SnapshotsCleaned = @@ROWCOUNT

    DELETE ChunkData FROM ChunkData INNER JOIN #tempSnapshot
    ON ChunkData.SnapshotDataID = #tempSnapshot.SnapshotDataID
    SET @ChunksCleaned = @@ROWCOUNT

    DELETE SnapshotData FROM SnapshotData INNER JOIN #tempSnapshot
    ON SnapshotData.SnapshotDataID = #tempSnapshot.SnapshotDataID
    
    TRUNCATE TABLE #tempSnapshot

    INSERT INTO #tempSnapshot SELECT TOP 1 SnapshotDataID 
    FROM dbo.ReportServerTempDB_SnapshotData  WITH (NOLOCK) 
    where dbo.ReportServerTempDB_SnapshotData.PermanentRefcount <= 0 
    AND dbo.ReportServerTempDB_SnapshotData.ExpirationDate < @now
    AND dbo.ReportServerTempDB_SnapshotData.Machine = @Machine
    SET @SnapshotsCleaned = @SnapshotsCleaned + @@ROWCOUNT

    SELECT @TempSnapshotID = (SELECT SnapshotDataID FROM #tempSnapshot)

    DELETE dbo.ReportServerTempDB_ChunkData FROM dbo.ReportServerTempDB_ChunkData INNER JOIN #tempSnapshot
    ON dbo.ReportServerTempDB_ChunkData.SnapshotDataID = #tempSnapshot.SnapshotDataID
    SET @ChunksCleaned = @ChunksCleaned + @@ROWCOUNT

    DELETE dbo.ReportServerTempDB_SnapshotData FROM dbo.ReportServerTempDB_SnapshotData INNER JOIN #tempSnapshot
    ON dbo.ReportServerTempDB_SnapshotData.SnapshotDataID = #tempSnapshot.SnapshotDataID

GO
/****** Object:  StoredProcedure [dbo].[CleanEventRecords]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CleanEventRecords] 
@MaxAgeMinutes int
AS
-- Reset all notifications which have been add over n minutes ago
Update [Event] set [ProcessStart] = NULL, [ProcessHeartbeat] = NULL
where [EventID] in
   ( SELECT [EventID]
     FROM [Event]
     WHERE [ProcessHeartbeat] < DATEADD(minute, -(@MaxAgeMinutes), GETUTCDATE()) )

GO
/****** Object:  StoredProcedure [dbo].[CleanExpiredCache]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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

GO
/****** Object:  StoredProcedure [dbo].[CleanExpiredEditSessions]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CleanExpiredEditSessions]
    @MaxToClean int = 10, 
    @NumCleaned int OUTPUT
AS BEGIN
    SET DEADLOCK_PRIORITY LOW 
    
    declare @now datetime;
    select @now = GETDATE();
    
    declare @DeletedItems table (ItemID uniqueidentifier not null primary key, Intermediate uniqueidentifier null)
    declare @DeletedCacheSnapshots table (SnapshotDataID uniqueidentifier null)
            
    begin transaction
        insert into @DeletedItems 
        select top(@MaxToClean) TempCatalogID, Intermediate
        from dbo.ReportServerTempDB_TempCatalog TC WITH(UPDLOCK)
        where ExpirationTime < @now and not exists (
            select 1 
            from dbo.ReportServerTempDB_SessionData SD WITH (INDEX (IX_EditSessionID)) 
            where SD.EditSessionID = TC.EditSessionID ) ;
        
        delete from dbo.ReportServerTempDB_TempDataSources	
        where ItemID in (
            select ItemID from @DeletedItems ) ;

        delete from dbo.ReportServerTempDB_TempDataSets	
        where ItemID in (
            select ItemID from @DeletedItems ) ;
            
        delete from dbo.ReportServerTempDB_TempCatalog
        where TempCatalogID in (
            select ItemID from @DeletedItems ) ;
            
        delete from dbo.ReportServerTempDB_ExecutionCache		
        output deleted.SnapshotDataID into @DeletedCacheSnapshots(SnapshotDataID)
        where ReportID in (
            select ItemID from @DeletedItems );
            
        update dbo.ReportServerTempDB_SnapshotData
        set PermanentRefcount = PermanentRefcount - 1
        where SnapshotData.SnapshotDataID in 
            (select Intermediate from @DeletedItems 
             union 
             select SnapshotDataID from @DeletedCacheSnapshots) ;
    commit
    
    select @NumCleaned = count(1) from @DeletedItems ;
END

GO
/****** Object:  StoredProcedure [dbo].[CleanExpiredJobs]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CleanExpiredJobs]
AS
SET NOCOUNT OFF
DELETE FROM RunningJobs WHERE DATEADD(s, Timeout, StartDate) < GETDATE()

GO
/****** Object:  StoredProcedure [dbo].[CleanExpiredServerParameters]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CleanExpiredServerParameters]
@ParametersCleaned INT OUTPUT
AS
  DECLARE @now as DATETIME
  SET @now = GETDATE()

DELETE FROM [dbo].[ServerParametersInstance] 
WHERE ServerParametersID IN 
(  SELECT TOP 20 ServerParametersID FROM [dbo].[ServerParametersInstance]
  WHERE Expiration < @now
)

SET @ParametersCleaned = @@ROWCOUNT

GO
/****** Object:  StoredProcedure [dbo].[CleanExpiredSessions]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CleanExpiredSessions]
@SessionsCleaned int OUTPUT
AS
SET DEADLOCK_PRIORITY LOW

set @SessionsCleaned = 0;
declare @maxCleanCount int = 200;
declare @rc int;
declare @now as datetime = GETDATE();
declare @DeletedSessions table (
  SessionID varchar(32) collate Latin1_General_CI_AS_KS_WS primary key,
  SnapshotDataID uniqueidentifier,
  CompiledDefinition uniqueidentifier
);

-- Delete expired sessions
--
-- In this session, we attempt to delete the first batch of expired 
-- sessions. A session is considered expired if its Expiration date 
-- and time is reached and that there are no locks on its corresponding 
-- row in the SessionLock table. As you can see we ensure that there 
-- are no locks on the corresponding SessionLock row by providing the 
-- READPAST hint. The ROWLOCK hint here ensures that we only take ROWLOCKS
--
-- Delete operation is executed in the batches of 20 to avoid lock 
-- escalations. See http://support.microsoft.com/kb/323630 for more 
-- details.
while @SessionsCleaned < @maxCleanCount
begin
  
  -- Delete the locks first
  delete top(20) sl
  output s.SessionID, s.SnapshotDataID, s.CompiledDefinition into @DeletedSessions
  from dbo.ReportServerTempDB_SessionLock sl with(rowlock, readpast)
  join dbo.ReportServerTempDB_SessionData s with(readpast) on sl.SessionID = s.SessionID
  where s.Expiration <= @now;
  
  set @rc = @@ROWCOUNT;
  if @rc = 0 break;
  set @SessionsCleaned = @SessionsCleaned + @rc;

  -- Now delete the sessions that correspond to those locks
  delete top(20) l
  from dbo.ReportServerTempDB_SessionData l
  join @DeletedSessions s on s.SessionID = l.SessionID;
end

-- Delete sessions with no corresponding locks (orphaned sessions)
--
-- In this section we attempt to find and delete any SessionData 
-- rows that do not have a corresponding SessionLock row. 
-- These rows are considered orphan and should be deleted. 
-- As you can see below, the SessionData table is queried using 
-- the READPAST hint. This means that SessionData rows that have 
-- locks on do not prevent this query from being executed. Also 
-- note that SessionLock is read using NOLOCK instead of READPAST. 
-- This is important because we need a true view on all rows that 
-- exists in the SessionLock table whether they are locked or not.
--
-- Delete operation is executed in the batches of 20 to avoid lock 
-- escalations. See http://support.microsoft.com/kb/323630 for more 
-- details.
while @SessionsCleaned < @maxCleanCount
begin
  delete top(20) s
  output deleted.SessionID, deleted.SnapshotDataID, deleted.CompiledDefinition into @DeletedSessions
  from dbo.ReportServerTempDB_SessionData s with(readpast)
  left join dbo.ReportServerTempDB_SessionLock sl with(nolock) on sl.SessionID = s.SessionID
  where sl.SessionID is null and s.Expiration <= @now;
  
  set @rc = @@ROWCOUNT;
  set @SessionsCleaned = @SessionsCleaned + @rc;
  if @rc < 20 break;
end

-- Was there anything to clean-up?
if @SessionsCleaned = 0 return;

-- Delete persisted streams
--
-- Delete operation is executed in the batches of 20 to avoid lock 
-- escalations. See http://support.microsoft.com/kb/323630 for more 
-- details.
deletePersistedStreams:
delete top(20) ps
from dbo.ReportServerTempDB_PersistedStream as ps
join @DeletedSessions sd on ps.SessionID = sd.SessionID;
if @@ROWCOUNT = 20 goto deletePersistedStreams;

-- Update ref counts
UPDATE SN
SET
   TransientRefcount = TransientRefcount-1
FROM
   dbo.ReportServerTempDB_SnapshotData AS SN
   JOIN @DeletedSessions AS SE ON SN.SnapshotDataID = SE.CompiledDefinition;

UPDATE SN
SET
   TransientRefcount = TransientRefcount-
      (SELECT COUNT(*)
       FROM @DeletedSessions AS SE1
       WHERE SE1.SnapshotDataID = SN.SnapshotDataID)
FROM
   SnapshotData AS SN
   JOIN @DeletedSessions AS SE ON SN.SnapshotDataID = SE.SnapshotDataID;

UPDATE SN
SET
   TransientRefcount = TransientRefcount-
      (SELECT COUNT(*)
       FROM @DeletedSessions AS SE1
       WHERE SE1.SnapshotDataID = SN.SnapshotDataID)
FROM
   dbo.ReportServerTempDB_SnapshotData AS SN
   JOIN @DeletedSessions AS SE ON SN.SnapshotDataID = SE.SnapshotDataID;

GO
/****** Object:  StoredProcedure [dbo].[CleanHistoryForReport]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- delete snapshots exceeding # of snapshots. won't work if @SnapshotLimit = 0
CREATE PROCEDURE [dbo].[CleanHistoryForReport]
@SnapshotLimit int,
@ReportID uniqueidentifier
AS
SET NOCOUNT OFF
DELETE FROM History
WHERE ReportID = @ReportID and SnapshotDate < 
    (SELECT MIN(SnapshotDate)
     FROM 
        (SELECT TOP (@SnapshotLimit) SnapshotDate
         FROM History
         WHERE ReportID = @ReportID
         ORDER BY SnapshotDate DESC
        ) AS TopSnapshots
    )

GO
/****** Object:  StoredProcedure [dbo].[CleanNotificationRecords]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CleanNotificationRecords] 
@MaxAgeMinutes int
AS
-- Reset all notifications which have been add over n minutes ago
Update [Notifications] set [ProcessStart] = NULL, [ProcessHeartbeat] = NULL, [Attempt] = 1
where [NotificationID] in
   ( SELECT [NotificationID]
     FROM [Notifications]
     WHERE [ProcessHeartbeat] < DATEADD(minute, -(@MaxAgeMinutes), GETUTCDATE()) and [Attempt] is NULL )

Update [Notifications] set [ProcessStart] = NULL, [ProcessHeartbeat] = NULL, [Attempt] = [Attempt] + 1
where [NotificationID] in
   ( SELECT [NotificationID]
     FROM [Notifications]
     WHERE [ProcessHeartbeat] < DATEADD(minute, -(@MaxAgeMinutes), GETUTCDATE()) and [Attempt] is not NULL )

GO
/****** Object:  StoredProcedure [dbo].[CleanOrphanedPolicies]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Cleaning orphan policies
CREATE PROCEDURE [dbo].[CleanOrphanedPolicies]
AS
SET NOCOUNT OFF
DELETE
   [Policies]
WHERE
   [Policies].[PolicyFlag] = 0
   AND
   NOT EXISTS (SELECT ItemID FROM [Catalog] WHERE [Catalog].[PolicyID] = [Policies].[PolicyID])

DELETE
   [Policies]
FROM
   [Policies]
   INNER JOIN [ModelItemPolicy] ON [ModelItemPolicy].[PolicyID] = [Policies].[PolicyID]
WHERE
   NOT EXISTS (SELECT ItemID
               FROM [Catalog] 
               WHERE [Catalog].[ItemID] = [ModelItemPolicy].[CatalogItemID])

GO
/****** Object:  StoredProcedure [dbo].[CleanOrphanedSnapshots]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CleanOrphanedSnapshots]
@Machine nvarchar(512),
@PermanentSnapshotCount int, 
@TemporarySnapshotCount int,
@PermanentChunkCount int, 
@TemporaryChunkCount int, 
@PermanentMappingCount int, 
@TemporaryMappingCount int, 
@PermanentSegmentCount int, 
@TemporarySegmentCount int,
@SnapshotsCleaned int OUTPUT,
@ChunksCleaned int OUTPUT,
@MappingsCleaned int OUTPUT,
@SegmentsCleaned int OUTPUT
AS 
    SELECT	@SnapshotsCleaned = 0, 
        @ChunksCleaned = 0, 
        @MappingsCleaned = 0, 
        @SegmentsCleaned = 0 ;
    
    -- use readpast rather than NOLOCK.  using 
    -- nolock could cause us to identify snapshots
    -- which have had the refcount decremented but
    -- the transaction is uncommitted which is dangerous.
    
    SET DEADLOCK_PRIORITY LOW
    
    -- cleanup of segmented chunk information happens 
    -- top->down.  meaning we delete chunk metadata, then 
    -- mappings, then segment data.  the reason for doing
    -- this is because it minimizes the io read cost since
    -- each delete step tells us the work that we need to 
    -- do in the next step.  however, there is the potential 
    -- for failure at any step which can leave orphaned data 
    -- structures.  we have another cleanup tasks 
    -- which will scavenge this orphaned data and clean it up
    -- so we don't need to be 100% robust here.  this also 
    -- means that we can play tricks like using readpast in the 
    -- dml operations so that concurrent deletes will minimize
    -- blocking of each other.	
    -- also, we optimize this cleanup for the scenario where the chunk is
    -- not shared.  this means that if we detect that a chunk is shared
    -- we will not delete any of its mappings.  there is potential for this
    -- to miss removing a chunk because it is shared and we are concurrently
    -- deleting the other snapshot (both see the chunk as shared...).  however
    -- we don't deal with that case here, and will instead orphan the chunk
    -- mappings and segments.  that is ok, we will just remove them when we 
    -- scan for orphaned mappings/segments.
    	
    declare @cleanedSnapshots table (SnapshotDataId uniqueidentifier primary key) ;
    declare @cleanedChunks table (ChunkId uniqueidentifier) ; 
    declare @cleanedChunks2 table (ChunkId uniqueidentifier primary key) ; 
    declare @cleanedSegments table (ChunkId uniqueidentifier, SegmentId uniqueidentifier) ;   	
    declare @deleteCount int ;   	   	
    
    begin transaction
    -- remove the actual snapshot entry
    -- we do this transacted with cleaning up chunk 
    -- data because we do not lazily clean up old ChunkData table.
    -- we also do this before cleaning up segmented chunk data to 
    -- get this SnapshotData record out of the table so another parallel 
    -- cleanup task does not attempt to delete it which would just cause 
    -- contention and reduce cleanup throughput.	
    DELETE TOP (@PermanentSnapshotCount) SnapshotData 
    output deleted.SnapshotDataID into @cleanedSnapshots (SnapshotDataId)
    FROM SnapshotData with(readpast) 
    WHERE   SnapshotData.PermanentRefCount <= 0 AND
            SnapshotData.TransientRefCount <= 0 ; 
    SET @SnapshotsCleaned = @@ROWCOUNT ;    
    
    -- clean up RS2000/RS2005 chunks
    set @deleteCount = 20;
    while (@deleteCount = 20)
    begin
        delete top(20) c
        from ChunkData c
        join @cleanedSnapshots cs ON c.SnapshotDataID = cs.SnapshotDataId;
        
        set @deleteCount = @@ROWCOUNT;
        SET @ChunksCleaned = @ChunksCleaned + @deleteCount;
    end
    commit
   	
   	-- clean up chunks
   	set @deleteCount = @PermanentChunkCount;
   	while (@deleteCount = @PermanentChunkCount)
   	begin		
   	    delete top (@PermanentChunkCount) SC 
   	    output deleted.ChunkId into @cleanedChunks(ChunkId)
   	    from SegmentedChunk SC with (readpast)	
   	    join @cleanedSnapshots cs on SC.SnapshotDataId = cs.SnapshotDataId ;	
   	    set @deleteCount = @@ROWCOUNT ; 
   	    set @ChunksCleaned =  @ChunksCleaned + @deleteCount ;
   	end ;

    -- This is added based on the Execution Plan. It should speed 
    -- up the "clean up unused mapping" operation below.
    insert into @cleanedChunks2
    select distinct ChunkId from @cleanedChunks;
	
	-- clean up unused mappings
    set @deleteCount = @PermanentMappingCount;
    while (@deleteCount = @PermanentMappingCount)
    begin		
        delete top(@PermanentMappingCount) CSM
        output deleted.ChunkId, deleted.SegmentId into @cleanedSegments (ChunkId, SegmentId)
        from ChunkSegmentMapping CSM with (readpast)
        join @cleanedChunks2 cc ON CSM.ChunkId = cc.ChunkId
        where not exists (
            select 1 from SegmentedChunk SC with(nolock)
            where SC.ChunkId = cc.ChunkId ) 
        and not exists (
            select 1 from dbo.ReportServerTempDB_SegmentedChunk TSC with(nolock)
            where TSC.ChunkId = cc.ChunkId ) ;
        set @deleteCount = @@ROWCOUNT ;
        set @MappingsCleaned = @MappingsCleaned + @deleteCount ;
    end ;
	
    -- clean up segments
    set @deleteCount = @PermanentSegmentCount;
    while (@deleteCount = @PermanentSegmentCount)
    begin
        delete top (@PermanentSegmentCount) S
        from Segment S with (readpast)
        join @cleanedSegments cs on S.SegmentId = cs.SegmentId
        where not exists (
            select 1 from ChunkSegmentMapping csm with (nolock)
            where csm.SegmentId = cs.SegmentId ) ;
        set @deleteCount = @@ROWCOUNT ;
        set @SegmentsCleaned = @SegmentsCleaned + @deleteCount ;
    end
    
    DELETE FROM @cleanedSnapshots ;
    DELETE FROM @cleanedChunks ;
    DELETE FROM @cleanedSegments ;
       	
    begin transaction	
    DELETE TOP (@TemporarySnapshotCount) dbo.ReportServerTempDB_SnapshotData 
    output deleted.SnapshotDataID into @cleanedSnapshots(SnapshotDataId)
    FROM dbo.ReportServerTempDB_SnapshotData with(readpast) 
    WHERE   dbo.ReportServerTempDB_SnapshotData.PermanentRefCount <= 0 AND
            dbo.ReportServerTempDB_SnapshotData.TransientRefCount <= 0 AND
            dbo.ReportServerTempDB_SnapshotData.Machine = @Machine ;
    SET @SnapshotsCleaned = @SnapshotsCleaned + @@ROWCOUNT ;
    
    DELETE dbo.ReportServerTempDB_ChunkData FROM dbo.ReportServerTempDB_ChunkData 
	INNER JOIN @cleanedSnapshots cs
    ON dbo.ReportServerTempDB_ChunkData.SnapshotDataID = cs.SnapshotDataId
    SET @ChunksCleaned = @ChunksCleaned + @@ROWCOUNT	
    commit
     
   	set @deleteCount = 1 ; 
   	while (@deleteCount > 0)
   	begin		
		delete SC 
		output deleted.ChunkId into @cleanedChunks(ChunkId)
		from dbo.ReportServerTempDB_SegmentedChunk SC with (readpast)	
		join @cleanedSnapshots cs on SC.SnapshotDataId = cs.SnapshotDataId ;	
		set @deleteCount = @@ROWCOUNT ; 
		set @ChunksCleaned =  @ChunksCleaned + @deleteCount ;
	end ;
	
	-- clean up unused mappings
	set @deleteCount = 1 ;	
	while (@deleteCount > 0)
	begin		
		delete top(@TemporaryMappingCount) CSM
		output deleted.ChunkId, deleted.SegmentId into @cleanedSegments (ChunkId, SegmentId)
		from dbo.ReportServerTempDB_ChunkSegmentMapping CSM with (readpast)
		join @cleanedChunks cc ON CSM.ChunkId = cc.ChunkId
		where not exists (
			select 1 from dbo.ReportServerTempDB_SegmentedChunk SC
			where SC.ChunkId = cc.ChunkId ) ;
		set @deleteCount = @@ROWCOUNT ;
		set @MappingsCleaned = @MappingsCleaned + @deleteCount ;
	end ;
		
	select distinct ChunkId from @cleanedSegments ;
		
	-- clean up segments
	set @deleteCount = 1
	while (@deleteCount > 0)
	begin
		delete top (@TemporarySegmentCount) S
		from dbo.ReportServerTempDB_Segment S with (readpast)
		join @cleanedSegments cs on S.SegmentId = cs.SegmentId
		where not exists (
			select 1 from dbo.ReportServerTempDB_ChunkSegmentMapping csm
			where csm.SegmentId = cs.SegmentId ) ;
		set @deleteCount = @@ROWCOUNT ;
		set @SegmentsCleaned = @SegmentsCleaned + @deleteCount ;
	end

GO
/****** Object:  StoredProcedure [dbo].[ClearScheduleConsistancyFlags]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ClearScheduleConsistancyFlags]
AS
update [Schedule] with (tablock, xlock) set [ConsistancyCheck] = NULL

GO
/****** Object:  StoredProcedure [dbo].[ClearSessionSnapshot]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ClearSessionSnapshot]
@SessionID as varchar(32),
@OwnerSid as varbinary(85) = NULL,
@OwnerName as nvarchar(260),
@AuthType as int,
@Expiration as datetime
AS

DECLARE @OwnerID uniqueidentifier
EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT

EXEC DereferenceSessionSnapshot @SessionID, @OwnerID

UPDATE SE
SET
   SE.SnapshotDataID = null,
   SE.IsPermanentSnapshot = null,
   SE.SnapshotExpirationDate = null,
   SE.ShowHideInfo = null,
   SE.HasInteractivity = null,
   SE.AutoRefreshSeconds = null,
   SE.Expiration = @Expiration
FROM
   dbo.ReportServerTempDB_SessionData AS SE
WHERE
   SE.SessionID = @SessionID AND
   SE.OwnerID = @OwnerID

GO
/****** Object:  StoredProcedure [dbo].[CopyChunks]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CopyChunks]
	@OldSnapshotId UNIQUEIDENTIFIER, 
	@NewSnapshotId UNIQUEIDENTIFIER,
	@IsPermanentSnapshot BIT
AS
BEGIN
	IF(@IsPermanentSnapshot = 1) BEGIN	
		-- copy non-segmented chunks
		INSERT [dbo].[ChunkData] (
			ChunkId, 
			SnapshotDataId, 
			ChunkFlags, 
			ChunkName, 
			ChunkType,
			Version, 
			MimeType, 
			Content
			)
		SELECT 
			NEWID(), 
			@NewSnapshotId, 
			[c].[ChunkFlags], 
			[c].[ChunkName], 
			[c].[ChunkType],
			[c].[Version], 
			[c].[MimeType], 
			[c].[Content]
		FROM [dbo].[ChunkData] [c] WHERE [c].[SnapshotDataId] = @OldSnapshotId
		
		-- copy segmented chunks... real easy just add the mapping
		INSERT [dbo].[SegmentedChunk](
			ChunkId, 
			SnapshotDataId, 
			ChunkName, 
			ChunkType,
			Version,
			MimeType,
			ChunkFlags
			)
		SELECT 
			ChunkId,
			@NewSnapshotId,
			ChunkName,
			ChunkType,
			Version,
			MimeType,
			ChunkFlags
		FROM [dbo].[SegmentedChunk] WITH (INDEX (UNIQ_SnapshotChunkMapping))
		WHERE [SnapshotDataId] = @OldSnapshotId
	END
	ELSE BEGIN
		-- copy non-segmented chunks
		INSERT dbo.ReportServerTempDB_[ChunkData] (
			ChunkId, 
			SnapshotDataId, 
			ChunkFlags, 
			ChunkName, 
			ChunkType,
			Version, 
			MimeType, 
			Content
			)
		SELECT 
			NEWID(), 
			@NewSnapshotId, 
			[c].[ChunkFlags], 
			[c].[ChunkName], 
			[c].[ChunkType],
			[c].[Version], 
			[c].[MimeType], 
			[c].[Content]
		FROM dbo.ReportServerTempDB_[ChunkData] [c] WHERE [c].[SnapshotDataId] = @OldSnapshotId
				
		-- copy segmented chunks... real easy just add the mapping
		INSERT [ReportServerTempDB].[dbo].[SegmentedChunk](
			ChunkId, 
			SnapshotDataId, 
			ChunkName, 
			ChunkType,
			Version,
			MimeType,
			ChunkFlags, 
			Machine
			)
		SELECT 
			ChunkId,
			@NewSnapshotId,
			ChunkName,
			ChunkType,
			Version,
			MimeType,
			ChunkFlags, 
			Machine
		FROM dbo.ReportServerTempDB_[SegmentedChunk] WITH (INDEX (UNIQ_SnapshotChunkMapping))
		WHERE [SnapshotDataId] = @OldSnapshotId
	END
END

GO
/****** Object:  StoredProcedure [dbo].[CopyChunksOfType]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CopyChunksOfType]
@FromSnapshotID uniqueidentifier,
@FromIsPermanent bit,
@ToSnapshotID uniqueidentifier,
@ToIsPermanent bit,
@ChunkType int, 
@ChunkName nvarchar(260) = NULL, 
@TargetChunkName nvarchar(260) = NULL
AS

DECLARE @Machine nvarchar(512)

IF @FromIsPermanent != 0 AND @ToIsPermanent = 0 BEGIN

	-- copy the contiguous chunks
    INSERT INTO dbo.ReportServerTempDB_ChunkData
        (ChunkID, SnapshotDataID, ChunkName, ChunkType, MimeType, Version, ChunkFlags, Content)
    SELECT
         newid(), @ToSnapshotID, COALESCE(@TargetChunkName, S.ChunkName), S.ChunkType, S.MimeType, S.Version, S.ChunkFlags, S.Content
    FROM
        ChunkData AS S
    WHERE   
        S.SnapshotDataID = @FromSnapshotID AND
        (S.ChunkType = @ChunkType OR @ChunkType IS NULL) AND
        (S.ChunkName = @ChunkName OR @ChunkName IS NUll) AND
    NOT EXISTS(
        SELECT T.ChunkName
        FROM dbo.ReportServerTempDB_ChunkData AS T -- exclude the ones in the target
        WHERE
            T.ChunkName = COALESCE(@TargetChunkName, S.ChunkName) AND
            T.ChunkType = S.ChunkType AND
            T.SnapshotDataID = @ToSnapshotID)
     

	-- the chunks will be cleaned up by the machine in which they are being allocated to
	select @Machine = Machine from dbo.ReportServerTempDB_SnapshotData SD where SD.SnapshotDataID = @ToSnapshotID
		
	INSERT INTO dbo.ReportServerTempDB_SegmentedChunk
		(SnapshotDataId, ChunkId, ChunkFlags, ChunkName, ChunkType, Version, MimeType, Machine)	
	SELECT
		@ToSnapshotID, SC.ChunkId, SC.ChunkFlags | 0x4, COALESCE(@TargetChunkName, SC.ChunkName), SC.ChunkType, SC.Version, SC.MimeType, @Machine
	FROM SegmentedChunk SC WITH(INDEX (UNIQ_SnapshotChunkMapping))
	WHERE 
		SC.SnapshotDataId = @FromSnapshotID AND
		(SC.ChunkType = @ChunkType OR @ChunkType IS NULL) AND
		(SC.ChunkName = @ChunkName OR @ChunkName IS NULL) AND
		NOT EXISTS(
			-- exclude chunks already in the target
			SELECT TSC.ChunkName
			FROM dbo.ReportServerTempDB_SegmentedChunk TSC
			-- JOIN dbo.ReportServerTempDB_SnapshotChunkMapping TSCM ON (TSC.ChunkId = TSCM.ChunkId)
			WHERE 
				TSC.ChunkName = COALESCE(@TargetChunkName, SC.ChunkName) AND
				TSC.ChunkType = SC.ChunkType AND
				TSC.SnapshotDataId = @ToSnapshotID
			)

 END ELSE IF @FromIsPermanent = 0 AND @ToIsPermanent = 0 BEGIN	
	-- the chunks exist on the node in which they were originally allocated on, they should
	-- be cleaned up by that node
	select @Machine = Machine from dbo.ReportServerTempDB_SnapshotData SD where SD.SnapshotDataID = @FromSnapshotID

    INSERT INTO dbo.ReportServerTempDB_ChunkData
        (ChunkId, SnapshotDataID, ChunkName, ChunkType, MimeType, Version, ChunkFlags, Content)
    SELECT
        newid(), @ToSnapshotID, COALESCE(@TargetChunkName, S.ChunkName), S.ChunkType, S.MimeType, S.Version, S.ChunkFlags, S.Content
    FROM
        dbo.ReportServerTempDB_ChunkData AS S
    WHERE   
        S.SnapshotDataID = @FromSnapshotID AND
        (S.ChunkType = @ChunkType OR @ChunkType IS NULL) AND
        (S.ChunkName = @ChunkName OR @ChunkName IS NULL) AND
        NOT EXISTS(
            SELECT T.ChunkName
            FROM dbo.ReportServerTempDB_ChunkData AS T -- exclude the ones in the target
            WHERE
                T.ChunkName = COALESCE(@TargetChunkName, S.ChunkName) AND
                T.ChunkType = S.ChunkType AND
                T.SnapshotDataID = @ToSnapshotID)
                            
    -- copy the segmented chunks, copying the segmented
    -- chunks really just needs to update the mappings        
    INSERT INTO dbo.ReportServerTempDB_SegmentedChunk
		(SnapshotDataId, ChunkId, ChunkName, ChunkType, Version, ChunkFlags, MimeType, Machine)
	SELECT 
		@ToSnapshotID, ChunkId, COALESCE(@TargetChunkName, C.ChunkName), C.ChunkType, C.Version, C.ChunkFlags, C.MimeType, @Machine	
	FROM dbo.ReportServerTempDB_SegmentedChunk C WITH(INDEX (UNIQ_SnapshotChunkMapping))
	WHERE	C.SnapshotDataId = @FromSnapshotID AND
			(C.ChunkType = @ChunkType OR @ChunkType IS NULL) AND	
			(C.ChunkName = @ChunkName OR @ChunkName IS NULL) AND
			NOT EXISTS(
				-- exclude chunks that are already mapped into this snapshot
				SELECT T.ChunkId
				FROM dbo.ReportServerTempDB_SegmentedChunk T
				WHERE	T.SnapshotDataId = @ToSnapshotID and 
						T.ChunkName = COALESCE(@TargetChunkName, C.ChunkName) and 
						T.ChunkType = C.ChunkType
				)

END ELSE IF @FromIsPermanent != 0 AND @ToIsPermanent != 0 BEGIN

    INSERT INTO ChunkData
        (ChunkID, SnapshotDataID, ChunkName, ChunkType, MimeType, Version, ChunkFlags, Content)
    SELECT
        newid(), @ToSnapshotID, COALESCE(@TargetChunkName, S.ChunkName), S.ChunkType, S.MimeType, S.Version, S.ChunkFlags, S.Content
    FROM
        ChunkData AS S
    WHERE   
        S.SnapshotDataID = @FromSnapshotID AND
        (S.ChunkType = @ChunkType OR @ChunkType IS NULL) AND
        (S.ChunkName = @ChunkName OR @ChunkName IS NULL) AND
        NOT EXISTS(
            SELECT T.ChunkName
            FROM ChunkData AS T -- exclude the ones in the target
            WHERE
                T.ChunkName = COALESCE(@TargetChunkName, S.ChunkName) AND
                T.ChunkType = S.ChunkType AND
                T.SnapshotDataID = @ToSnapshotID)
                
    -- copy the segmented chunks, copying the segmented
    -- chunks really just needs to update the mappings
    INSERT INTO SegmentedChunk
		(SnapshotDataId, ChunkId, ChunkName, ChunkType, Version, ChunkFlags, C.MimeType)
	SELECT 
		@ToSnapshotID, ChunkId, COALESCE(@TargetChunkName, C.ChunkName), C.ChunkType, C.Version, C.ChunkFlags, C.MimeType	
	FROM SegmentedChunk C WITH(INDEX (UNIQ_SnapshotChunkMapping))
	WHERE	C.SnapshotDataId = @FromSnapshotID AND
			(C.ChunkType = @ChunkType OR @ChunkType IS NULL) AND	
			(C.ChunkName = @ChunkName OR @ChunkName IS NULL) AND
			NOT EXISTS(
				-- exclude chunks that are already mapped into this snapshot
				SELECT T.ChunkId
				FROM SegmentedChunk T
				WHERE	T.SnapshotDataId = @ToSnapshotID and 
						T.ChunkName = COALESCE(@TargetChunkName, C.ChunkName) and 
						T.ChunkType = C.ChunkType
				)

END ELSE IF @FromIsPermanent = 0 AND @ToIsPermanent != 0 BEGIN
    INSERT INTO ChunkData
        (ChunkId, SnapshotDataID, ChunkName, ChunkType, MimeType, Version, ChunkFlags, Content)
    SELECT
        newid(), @ToSnapshotID, COALESCE(@TargetChunkName, S.ChunkName), S.ChunkType, S.MimeType, S.Version, S.ChunkFlags, S.Content
    FROM
        dbo.ReportServerTempDB_ChunkData AS S
    WHERE   
        S.SnapshotDataID = @FromSnapshotID AND
        (S.ChunkType = @ChunkType OR @ChunkType IS NULL) AND
        (S.ChunkName = @ChunkName OR @ChunkName IS NULL) AND
        NOT EXISTS(
            SELECT T.ChunkName
            FROM ChunkData AS T -- exclude the ones in the target
            WHERE
                T.ChunkName = COALESCE(@TargetChunkName, S.ChunkName) AND
                T.ChunkType = S.ChunkType AND
                T.SnapshotDataID = @ToSnapshotID)
                            
    declare @mapping_temp table (ChunkId uniqueidentifier not null primary key)
    
    INSERT INTO SegmentedChunk
        (SnapshotDataId, ChunkId, ChunkName, ChunkType, Version, ChunkFlags, MimeType)
    OUTPUT inserted.ChunkId INTO @mapping_temp
    SELECT 
        @ToSnapshotID, ChunkId, COALESCE(@TargetChunkName, C.ChunkName), C.ChunkType, C.Version, C.ChunkFlags, C.MimeType
    FROM dbo.ReportServerTempDB_SegmentedChunk C WITH(INDEX (UNIQ_SnapshotChunkMapping))
    WHERE   
        C.SnapshotDataId = @FromSnapshotID AND
        (C.ChunkType = @ChunkType OR @ChunkType IS NULL) AND    
        (C.ChunkName = @ChunkName OR @ChunkName IS NULL)  AND
        NOT EXISTS(
            -- exclude chunks that are already mapped into this snapshot
            SELECT T.ChunkId
            FROM SegmentedChunk T
            WHERE    T.SnapshotDataId = @ToSnapshotID and 
               T.ChunkName = COALESCE(@TargetChunkName, C.ChunkName) and 
               T.ChunkType = C.ChunkType
        )
            
     declare @segment_temp table (SegmentId uniqueidentifier not null primary key)            
     
     INSERT INTO ChunkSegmentMapping
         (ChunkId, SegmentId, StartByte, LogicalByteCount, ActualByteCount)
     OUTPUT inserted.SegmentId INTO @segment_temp
     SELECT CM.ChunkId, SegmentId, StartByte, LogicalByteCount, ActualByteCount
     FROM dbo.ReportServerTempDB_ChunkSegmentMapping CM 
     INNER JOIN @mapping_temp as MT on MT.ChunkId = CM.ChunkId 
     WHERE 
        NOT EXISTS(
			-- exclude segment mappings that already exist in the target snapshot
            SELECT CMT.ChunkId
            FROM ChunkSegmentMapping CMT
            WHERE 
               CMT.ChunkId = CM.ChunkId 
               and CMT.SegmentId = CM.SegmentId
        )
           
     INSERT INTO Segment
         (SegmentId, Content)
     SELECT CS.SegmentId, Content
     FROM dbo.ReportServerTempDB_Segment CS
     INNER JOIN @segment_temp as ST ON CS.SegmentId = ST.SegmentId
     WHERE 
        NOT EXISTS(
			-- exclude segments that already exist in the target snapshot
            SELECT CST.SegmentId
            FROM Segment CST
            WHERE 
               CST.SegmentId = CS.SegmentId
        )
END

GO
/****** Object:  StoredProcedure [dbo].[CreateCacheUpdateNotifications]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateCacheUpdateNotifications] 
@ReportID uniqueidentifier,
@LastRunTime datetime
AS

update [Subscriptions]
set
    [LastRunTime] = @LastRunTime
from
    [Subscriptions] S 
where 
    S.[Report_OID] = @ReportID and S.EventType = 'SnapshotUpdated' and InactiveFlags = 0


-- Find all valid subscriptions for the given report and create a new notification row for
-- each subscription
insert into [Notifications] 
    (
    [NotificationID], 
    [SubscriptionID],
    [ActivationID],
    [ReportID],
    [ReportZone],
    [SnapShotDate],
    [ExtensionSettings],
    [Locale],
    [Parameters],
    [NotificationEntered],
    [SubscriptionLastRunTime],
    [DeliveryExtension],
    [SubscriptionOwnerID],
    [IsDataDriven],
    [Version]
    ) 
select 
    NewID(),
    S.[SubscriptionID],
    NULL,
    S.[Report_OID],
    S.[ReportZone],
    NULL,
    S.[ExtensionSettings],
    S.[Locale],
    S.[Parameters],
    GETUTCDATE(), 
    S.[LastRunTime],
    S.[DeliveryExtension],
    S.[OwnerID],
    0,
    S.[Version]
from 
    [Subscriptions] S  inner join Catalog C on S.[Report_OID] = C.[ItemID]
where 
    C.[ItemID] = @ReportID and S.EventType = 'SnapshotUpdated' and InactiveFlags = 0 and
    S.[DataSettings] is null

-- Create any data driven subscription by creating a data driven event
insert into [Event]
    (
    [EventID],
    [EventType],
    [EventData],
    [TimeEntered]
    )
select
    NewID(),
    'DataDrivenSubscription',
    S.SubscriptionID,
    GETUTCDATE()
from
    [Subscriptions] S  inner join Catalog C on S.[Report_OID] = C.[ItemID]
where 
    C.[ItemID] = @ReportID and S.EventType = 'SnapshotUpdated' and InactiveFlags = 0 and
    S.[DataSettings] is not null

GO
/****** Object:  StoredProcedure [dbo].[CreateChunkAndGetPointer]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateChunkAndGetPointer]
@SnapshotDataID uniqueidentifier,
@IsPermanentSnapshot bit,
@ChunkName nvarchar(260),
@ChunkType int,
@MimeType nvarchar(260) = NULL,
@Version smallint,
@Content image,
@ChunkFlags tinyint = NULL,
@ChunkPointer binary(16) OUTPUT
AS

DECLARE @ChunkID uniqueidentifier
SET @ChunkID = NEWID()

IF @IsPermanentSnapshot != 0 BEGIN

    DELETE ChunkData
    WHERE
        SnapshotDataID = @SnapshotDataID AND
        ChunkName = @ChunkName AND
        ChunkType = @ChunkType

    INSERT
    INTO ChunkData
        (ChunkID, SnapshotDataID, ChunkName, ChunkType, MimeType, Version, ChunkFlags, Content)
    VALUES
        (@ChunkID, @SnapshotDataID, @ChunkName, @ChunkType, @MimeType, @Version, @ChunkFlags, @Content)

    SELECT @ChunkPointer = TEXTPTR(Content)
                FROM ChunkData
                WHERE ChunkData.ChunkID = @ChunkID

END ELSE BEGIN

    DELETE dbo.ReportServerTempDB_ChunkData
    WHERE
        SnapshotDataID = @SnapshotDataID AND
        ChunkName = @ChunkName AND
        ChunkType = @ChunkType

    INSERT
    INTO dbo.ReportServerTempDB_ChunkData
        (ChunkID, SnapshotDataID, ChunkName, ChunkType, MimeType, Version, ChunkFlags, Content)
    VALUES
        (@ChunkID, @SnapshotDataID, @ChunkName, @ChunkType, @MimeType, @Version, @ChunkFlags, @Content)

    SELECT @ChunkPointer = TEXTPTR(Content)
                FROM dbo.ReportServerTempDB_ChunkData AS CH
                WHERE CH.ChunkID = @ChunkID
END   

GO
/****** Object:  StoredProcedure [dbo].[CreateChunkSegment]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[CreateChunkSegment]
	@SnapshotId			uniqueidentifier,	
	@IsPermanent		bit, 
	@ChunkId			uniqueidentifier,
	@Content			varbinary(max) = 0x0,
	@StartByte			bigint, 
	@Length				int = 0,
	@LogicalByteCount	int = 0,
	@SegmentId			uniqueidentifier out
as begin
	declare @output table (SegmentId uniqueidentifier, ActualByteCount int) ;
	declare @ActualByteCount int ;
	if(@IsPermanent = 1) begin	
		insert Segment(Content) 
		output inserted.SegmentId, datalength(inserted.Content) into @output
		values (substring(@Content, 1, @Length)) ;
		
		select top 1    @SegmentId = SegmentId, 
		                @ActualByteCount = ActualByteCount
		from @output ;
		
		insert ChunkSegmentMapping(ChunkId, SegmentId, StartByte, LogicalByteCount, ActualByteCount)
		values (@ChunkId, @SegmentId, @StartByte, @LogicalByteCount, @ActualByteCount) ;
	end
	else begin
		insert dbo.ReportServerTempDB_Segment(Content) 
		output inserted.SegmentId, datalength(inserted.Content) into @output
		values (substring(@Content, 1, @Length)) ;
		
		select top 1    @SegmentId = SegmentId, 
		                @ActualByteCount = ActualByteCount
		from @output ;
		
		insert dbo.ReportServerTempDB_ChunkSegmentMapping(ChunkId, SegmentId, StartByte, LogicalByteCount, ActualByteCount)
		values (@ChunkId, @SegmentId, @StartByte, @LogicalByteCount, @ActualByteCount) ;
	end
end

GO
/****** Object:  StoredProcedure [dbo].[CreateDataDrivenNotification]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateDataDrivenNotification]
@SubscriptionID uniqueidentifier,
@ActiveationID uniqueidentifier,
@ReportID uniqueidentifier,
@ReportZone int,
@ExtensionSettings ntext,
@Locale nvarchar(128),
@Parameters ntext,
@LastRunTime datetime,
@DeliveryExtension nvarchar(260),
@OwnerSid varbinary (85) = null,
@OwnerName nvarchar(260),
@OwnerAuthType int,
@Version int
AS

declare @OwnerID as uniqueidentifier

EXEC GetUserID @OwnerSid,@OwnerName, @OwnerAuthType, @OwnerID OUTPUT

-- Verify if subscription is being deleted
if exists (select 1 from [dbo].[SubscriptionsBeingDeleted] where [SubscriptionID]=@SubscriptionID)
BEGIN
    RAISERROR( N'The subscription is being deleted', 16, 1)
    return;
END

-- Verify if subscription was deleted or deactivated
if not exists (select 1 from [dbo].[Subscriptions] where [SubscriptionID]=@SubscriptionID and [InactiveFlags] = 0)
BEGIN
    RAISERROR( N'The subscription was deleted or deactivated', 16, 1)
    return;
END

-- Insert into the notification table
insert into [Notifications] 
    (
    [NotificationID], 
    [SubscriptionID],
    [ActivationID],
    [ReportID],
    [ReportZone],
    [SnapShotDate],
    [ExtensionSettings],
    [Locale],
    [Parameters],
    [NotificationEntered],
    [SubscriptionLastRunTime],
    [DeliveryExtension],
    [SubscriptionOwnerID],
    [IsDataDriven],
    [Version]
    )
values
    (
    NewID(),
    @SubscriptionID,
    @ActiveationID,
    @ReportID,
    @ReportZone,
    NULL,
    @ExtensionSettings,
    @Locale,
    @Parameters,
    GETUTCDATE(),
    @LastRunTime,
    @DeliveryExtension,
    @OwnerID,
    1,
    @Version
    )

GO
/****** Object:  StoredProcedure [dbo].[CreateEditSession]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[CreateEditSession]
    @EditSessionID varchar(32),
    @ContextPath nvarchar(440), 	
    @Name nvarchar(440),	
    @OwnerSid varbinary(85) = NULL, 
    @OwnerName nvarchar(260), 
    @Content varbinary(max), 
    @Description nvarchar(max) = NULL, 
    @Intermediate uniqueidentifier,
    @Property nvarchar(max), 
    @Parameter nvarchar(max),
    @AuthType int, 
    @Timeout int, 
    @DataCacheHash varbinary(64) = NULL,
    @NewItemID uniqueidentifier out
as begin
    DECLARE @OwnerID uniqueidentifier ;
    EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT ;	
    
    UPDATE dbo.ReportServerTempDB_SnapshotData
    SET  PermanentRefcount = PermanentRefcount + 1, TransientRefcount = TransientRefcount - 1 
    WHERE SnapshotData.SnapshotDataID = @Intermediate	
    
    SELECT @NewItemID = NEWID();
    
    -- copy in the report metadata
    insert into dbo.ReportServerTempDB_TempCatalog (
        EditSessionID, 
        TempCatalogID, 
        ContextPath, 
        [Name],		
        Content, 
        Description,
        Intermediate, 
        IntermediateIsPermanent,
        Property, 
        Parameter,
        OwnerID, 
        CreationTime, 
        ExpirationTime, 
        DataCacheHash )	
    values (			 
        @EditSessionID, 
        @NewItemID, 
        @ContextPath, 
        @Name,		
        @Content, 
        @Description,
        @Intermediate, 
        convert(bit, 0),
        @Property, 
        @Parameter,
        @OwnerID, 
        GETDATE(), 
        DATEADD(n, @Timeout, GETDATE()), 
        @DataCacheHash)
END		

GO
/****** Object:  StoredProcedure [dbo].[CreateNewActiveSubscription]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateNewActiveSubscription]
@ActiveID uniqueidentifier,
@SubscriptionID uniqueidentifier
AS


-- Insert into the activesubscription table
insert into [ActiveSubscriptions] 
    (
    [ActiveID], 
    [SubscriptionID],
    [TotalNotifications],
    [TotalSuccesses],
    [TotalFailures]
    )
values
    (
    @ActiveID,
    @SubscriptionID,
    NULL,
    0,
    0
    )

GO
/****** Object:  StoredProcedure [dbo].[CreateNewSnapshotVersion]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateNewSnapshotVersion]
	@OldSnapshotId UNIQUEIDENTIFIER, 
	@NewSnapshotId UNIQUEIDENTIFIER,
	@IsPermanentSnapshot BIT, 
	@Machine NVARCHAR(512)
AS
BEGIN
	IF(@IsPermanentSnapshot = 1) BEGIN	
		INSERT [dbo].[SnapshotData] (
			SnapshotDataId, 
			CreatedDate, 
			ParamsHash, 
			QueryParams, 
			EffectiveParams, 
			Description, 
			DependsOnUser, 
			PermanentRefCount, 
			TransientRefCount, 
			ExpirationDate, 
			PageCount, 
			HasDocMap, 
			PaginationMode, 
			ProcessingFlags
			)
		SELECT 
			@NewSnapshotId,
			[sn].CreatedDate, 
			[sn].ParamsHash,
			[sn].QueryParams, 
			[sn].EffectiveParams, 
			[sn].Description, 
			[sn].DependsOnUser, 	
			0,
			1,		-- always create with transient refcount of 1
			[sn].ExpirationDate,
			[sn].PageCount, 
			[sn].HasDocMap, 
			[sn].PaginationMode,
			[sn].ProcessingFlags
		FROM [dbo].[SnapshotData] [sn] 
		WHERE [sn].SnapshotDataId = @OldSnapshotId
	END
	ELSE BEGIN	
		INSERT dbo.ReportServerTempDB_[SnapshotData] (
			SnapshotDataId, 
			CreatedDate, 
			ParamsHash, 
			QueryParams, 
			EffectiveParams, 
			Description, 
			DependsOnUser, 
			PermanentRefCount, 
			TransientRefCount, 
			ExpirationDate, 
			PageCount, 
			HasDocMap, 
			PaginationMode, 
			ProcessingFlags,
			Machine,
			IsCached
			)
		SELECT 
			@NewSnapshotId,
			[sn].CreatedDate, 
			[sn].ParamsHash,
			[sn].QueryParams, 
			[sn].EffectiveParams, 
			[sn].Description, 
			[sn].DependsOnUser, 	
			0,
			1,		-- always create with transient refcount of 1
			[sn].ExpirationDate,
			[sn].PageCount, 
			[sn].HasDocMap, 
			[sn].PaginationMode, 
			[sn].ProcessingFlags,
			@Machine,
			[sn].IsCached
		FROM dbo.ReportServerTempDB_[SnapshotData] [sn] 
		WHERE [sn].SnapshotDataId = @OldSnapshotId
	END
	
	EXEC [dbo].[CopyChunks] 
		@OldSnapshotId = @OldSnapshotId, 
		@NewSnapshotId = @NewSnapshotId, 
		@IsPermanentSnapshot = @IsPermanentSnapshot
END

GO
/****** Object:  StoredProcedure [dbo].[CreateObject]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- This SP should never be called with a policy ID unless it is guarenteed that
-- the parent will not be deleted before the insert (such as while running this script)
CREATE PROCEDURE [dbo].[CreateObject]
@ItemID uniqueidentifier,
@Name nvarchar (425),
@Path nvarchar (425),
@ParentID uniqueidentifier,
@Type int,
@Content image = NULL,
@Intermediate uniqueidentifier = NULL,
@LinkSourceID uniqueidentifier = NULL,
@Property ntext = NULL,
@Parameter ntext = NULL,
@Description ntext = NULL,
@Hidden bit = NULL,
@CreatedBySid varbinary(85) = NULL,
@CreatedByName nvarchar(260),
@AuthType int,
@CreationDate datetime,
@ModificationDate datetime,
@MimeType nvarchar (260) = NULL,
@SnapshotLimit int = NULL,
@PolicyRoot int = 0,
@PolicyID uniqueidentifier = NULL,
@ExecutionFlag int = 1, -- allow live execution, don't keep history
@SubType nvarchar(128) = NULL,
@ComponentID uniqueidentifier = NULL
AS

DECLARE @CreatedByID uniqueidentifier
EXEC GetUserID @CreatedBySid, @CreatedByName, @AuthType, @CreatedByID OUTPUT

UPDATE Catalog
SET ModifiedByID = @CreatedByID, ModifiedDate = @ModificationDate
WHERE ItemID = @ParentID

-- If no policyID, use the parent's
IF @PolicyID is NULL BEGIN
   SET @PolicyID = (SELECT PolicyID FROM [dbo].[Catalog] WHERE Catalog.ItemID = @ParentID)
END

-- If there is no policy ID then we are guarenteed not to have a parent
IF @PolicyID is NULL BEGIN
RAISERROR ('Parent Not Found', 16, 1)
return
END

INSERT INTO Catalog (ItemID,  Path,  Name,  ParentID,  Type,  Content,  Intermediate,  LinkSourceID,  Property,  Description,  Hidden,  CreatedByID,  CreationDate,  ModifiedByID,  ModifiedDate,  MimeType,  SnapshotLimit,  [Parameter],  PolicyID,  PolicyRoot, ExecutionFlag, SubType, ComponentID)
VALUES             (@ItemID, @Path, @Name, @ParentID, @Type, @Content, @Intermediate, @LinkSourceID, @Property, @Description, @Hidden, @CreatedByID, @CreationDate, @CreatedByID,  @ModificationDate, @MimeType, @SnapshotLimit, @Parameter, @PolicyID, @PolicyRoot , @ExecutionFlag, @SubType, @ComponentID)

IF @Intermediate IS NOT NULL AND @@ERROR = 0 BEGIN
   UPDATE SnapshotData
   SET PermanentRefcount = PermanentRefcount + 1, TransientRefcount = TransientRefcount - 1
   WHERE SnapshotData.SnapshotDataID = @Intermediate
END

GO
/****** Object:  StoredProcedure [dbo].[CreateRdlChunk]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateRdlChunk]
	@ItemId UNIQUEIDENTIFIER, 
	@SnapshotId UNIQUEIDENTIFIER, 
	@IsPermanentSnapshot BIT, 
	@ChunkName NVARCHAR(260), 
	@ChunkFlags TINYINT, 
	@ChunkType INT, 
	@Version SMALLINT, 
	@MimeType NVARCHAR(260) = NULL
AS
BEGIN

-- If the chunk already exists then bail out early
IF EXISTS (
    SELECT 1 
    FROM [SegmentedChunk]
    WHERE   SnapshotDataId = @SnapshotId AND 
            ChunkName = @ChunkName AND 
            ChunkType = @ChunkType
    )
    RETURN ;

-- This is a 3-step process.  First we need to get the RDL out of the Catalog
-- table where it is stored in the Content row.  Note the join to make sure
-- that if ItemId is a Linked Report we go back to the main report to get the RDL.
-- Once we have the RDL stored in @SegmentData, we then invoke the CreateSegmentedChunk
-- stored proc which will create an empty segmented chunk for us and return the ChunkId.
-- finally, once we have a ChunkId, we can invoke CreateChunkSegment to actually put the 
-- content into the chunk.  Note that we do not every actually break the chunk into multiple
-- sgements but instead we always use one.  
DECLARE @SegmentData VARBINARY(MAX) ;
DECLARE @SegmentByteCount INT ;
SELECT @SegmentData = CONVERT(VARBINARY(MAX), ISNULL(Linked.Content, Original.Content))
FROM [Catalog] Original
LEFT OUTER JOIN [Catalog] Linked WITH (INDEX(PK_Catalog)) ON (Original.LinkSourceId = Linked.ItemId)
WHERE [Original].[ItemId] = @ItemId ;

SELECT @SegmentByteCount = DATALENGTH(@SegmentData) ;

DECLARE @ChunkId UNIQUEIDENTIFIER ;
EXEC [CreateSegmentedChunk]
    @SnapshotId = @SnapshotId,
    @IsPermanent = @IsPermanentSnapshot,
    @ChunkName = @ChunkName, 
    @ChunkFlags = @ChunkFlags, 
    @ChunkType = @ChunkType,
    @Version = @Version,
    @MimeType = @MimeType,
    @Machine = NULL,
    @ChunkId = @ChunkId out ;

DECLARE @SegmentId UNIQUEIDENTIFIER ; 
EXEC [CreateChunkSegment]
    @SnapshotId = @SnapshotId, 
    @IsPermanent = @IsPermanentSnapshot,
    @ChunkId = @ChunkId, 
    @Content = @SegmentData,
    @StartByte = 0, 
    @Length = @SegmentByteCount,
    @LogicalByteCount = @SegmentByteCount,
    @SegmentId = @SegmentId out
END

GO
/****** Object:  StoredProcedure [dbo].[CreateRole]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateRole]
@RoleID as uniqueidentifier,
@RoleName as nvarchar(260),
@Description as nvarchar(512) = null,
@TaskMask as nvarchar(32),
@RoleFlags as tinyint
AS
INSERT INTO Roles
(RoleID, RoleName, Description, TaskMask, RoleFlags)
VALUES
(@RoleID, @RoleName, @Description, @TaskMask, @RoleFlags)

GO
/****** Object:  StoredProcedure [dbo].[CreateSegmentedChunk]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[CreateSegmentedChunk]
	@SnapshotId		uniqueidentifier,
	@IsPermanent	bit, 
	@ChunkName		nvarchar(260),
	@ChunkFlags		tinyint, 
	@ChunkType		int, 
	@Version		smallint, 
	@MimeType		nvarchar(260) = null, 
	@Machine		nvarchar(512),
	@ChunkId		uniqueidentifier out
as begin
	declare @output table (ChunkId uniqueidentifier) ;
	if (@IsPermanent = 1) begin
		delete SegmentedChunk
		where SnapshotDataId = @SnapshotId and ChunkName = @ChunkName and ChunkType = @ChunkType
		
		delete ChunkData
		where SnapshotDataID = @SnapshotId and ChunkName = @ChunkName and ChunkType = @ChunkType
							
		insert SegmentedChunk(SnapshotDataId, ChunkFlags, ChunkName, ChunkType, Version, MimeType)
		output inserted.ChunkId into @output
		values (@SnapshotId, @ChunkFlags, @ChunkName, @ChunkType, @Version, @MimeType) ;
	end
	else begin
		delete dbo.ReportServerTempDB_SegmentedChunk
		where SnapshotDataId = @SnapshotId and ChunkName = @ChunkName and ChunkType = @ChunkType
		
		delete dbo.ReportServerTempDB_ChunkData
		where SnapshotDataID = @SnapshotId and ChunkName = @ChunkName and ChunkType = @ChunkType

		insert dbo.ReportServerTempDB_SegmentedChunk(SnapshotDataId, ChunkFlags, ChunkName, ChunkType, Version, MimeType, Machine)
		output inserted.ChunkId into @output
		values (@SnapshotId, @ChunkFlags, @ChunkName, @ChunkType, @Version, @MimeType, @Machine) ;
	end
	select top 1 @ChunkId = ChunkId from @output
end

GO
/****** Object:  StoredProcedure [dbo].[CreateSession]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Writes or updates session record
CREATE PROCEDURE [dbo].[CreateSession]
@SessionID as varchar(32),
@CompiledDefinition as uniqueidentifier = NULL,
@SnapshotDataID as uniqueidentifier = NULL,
@IsPermanentSnapshot as bit = NULL,
@ReportPath as nvarchar(464) = NULL,
@Timeout as int,
@AutoRefreshSeconds as int = NULL,
@DataSourceInfo as image = NULL,
@OwnerName as nvarchar (260),
@OwnerSid as varbinary (85) = NULL,
@AuthType as int,
@EffectiveParams as ntext = NULL,
@HistoryDate as datetime = NULL,
@PageHeight as float = NULL,
@PageWidth as float = NULL,
@TopMargin as float = NULL,
@BottomMargin as float = NULL,
@LeftMargin as float = NULL,
@RightMargin as float = NULL,
@AwaitingFirstExecution as bit = NULL,
@EditSessionID as varchar(32) = NULL,
@SitePath as nvarchar(440) = NULL,
@SiteZone as int,
@DataSetInfo as varbinary(max) = NULL,
@ReportDefinitionPath as nvarchar(464) = NULL
AS

UPDATE PS
SET PS.RefCount = 1
FROM
    dbo.ReportServerTempDB_PersistedStream as PS
WHERE
    PS.SessionID = @SessionID	
    
UPDATE SN
SET TransientRefcount = TransientRefcount + 1
FROM
   SnapshotData AS SN
WHERE
   SN.SnapshotDataID = @SnapshotDataID
   
UPDATE SN
SET TransientRefcount = TransientRefcount + 1
FROM
   dbo.ReportServerTempDB_SnapshotData AS SN
WHERE
   SN.SnapshotDataID = @SnapshotDataID

DECLARE @OwnerID uniqueidentifier
EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT

DECLARE @now datetime
SET @now = GETDATE()

INSERT
   INTO dbo.ReportServerTempDB_SessionData (
      SessionID,
      CompiledDefinition,
      SnapshotDataID,
      IsPermanentSnapshot,
      ReportPath,
      Timeout,
      AutoRefreshSeconds,
      Expiration,
      DataSourceInfo,
      OwnerID,
      EffectiveParams,
      CreationTime,
      HistoryDate,
      PageHeight,
      PageWidth,
      TopMargin,
      BottomMargin,
      LeftMargin,
      RightMargin,
      AwaitingFirstExecution,
      EditSessionID,
      SitePath,
      SiteZone,
      DataSetInfo,
      ReportDefinitionPath )      
   VALUES (
      @SessionID,
      @CompiledDefinition,
      @SnapshotDataID,
      @IsPermanentSnapshot,
      @ReportPath,
      @Timeout,
      @AutoRefreshSeconds,
      DATEADD(s, @Timeout, @now),
      @DataSourceInfo,
      @OwnerID,
      @EffectiveParams,
      @now,
      @HistoryDate,
      @PageHeight,
      @PageWidth,
      @TopMargin,
      @BottomMargin,
      @LeftMargin,
      @RightMargin,
      @AwaitingFirstExecution, 
      @EditSessionID,
      @SitePath,
      @SiteZone,
      @DataSetInfo,
      @ReportDefinitionPath )
      
INSERT INTO dbo.ReportServerTempDB_SessionLock(SessionID)
VALUES (@SessionID)

GO
/****** Object:  StoredProcedure [dbo].[CreateSnapShotNotifications]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateSnapShotNotifications] 
@HistoryID uniqueidentifier,
@LastRunTime datetime
AS
update [Subscriptions]
set
    [LastRunTime] = @LastRunTime
from
    History SS inner join [Subscriptions] S on S.[Report_OID] = SS.[ReportID]
where 
    SS.[HistoryID] = @HistoryID and S.EventType = 'ReportHistorySnapshotCreated' and InactiveFlags = 0


-- Find all valid subscriptions for the given report and create a new notification row for
-- each subscription
insert into [Notifications] 
    (
    [NotificationID], 
    [SubscriptionID],
    [ActivationID],
    [ReportID],
    [ReportZone],
    [SnapShotDate],
    [ExtensionSettings],
    [Locale],
    [Parameters],
    [NotificationEntered],
    [SubscriptionLastRunTime],
    [DeliveryExtension],
    [SubscriptionOwnerID],
    [IsDataDriven],
    [Version]
    ) 
select 
    NewID(),
    S.[SubscriptionID],
    NULL,
    S.[Report_OID],
    S.[ReportZone],
    NULL,
    S.[ExtensionSettings],
    S.[Locale],
    S.[Parameters],
    GETUTCDATE(), 
    S.[LastRunTime],
    S.[DeliveryExtension],
    S.[OwnerID],
    0,
    S.[Version]
from 
    [Subscriptions] S with (READPAST) inner join History H on S.[Report_OID] = H.[ReportID]
where 
    H.[HistoryID] = @HistoryID and S.EventType = 'ReportHistorySnapshotCreated' and InactiveFlags = 0 and
    S.[DataSettings] is null

-- Create any data driven subscription by creating a data driven event
insert into [Event]
    (
    [EventID],
    [EventType],
    [EventData],
    [TimeEntered]
    )
select
    NewID(),
    'DataDrivenSubscription',
    S.SubscriptionID,
    GETUTCDATE()
from
    [Subscriptions] S with (READPAST) inner join History H on S.[Report_OID] = H.[ReportID]
where 
    H.[HistoryID] = @HistoryID and S.EventType = 'ReportHistorySnapshotCreated' and InactiveFlags = 0 and
    S.[DataSettings] is not null

GO
/****** Object:  StoredProcedure [dbo].[CreateSubscription]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateSubscription]
@id uniqueidentifier,
@Locale nvarchar (128),
@Report_Name nvarchar (425),
@ReportZone int,
@OwnerSid varbinary (85) = NULL,
@OwnerName nvarchar(260),
@OwnerAuthType int,
@DeliveryExtension nvarchar (260) = NULL,
@InactiveFlags int,
@ExtensionSettings ntext = NULL,
@ModifiedBySid varbinary (85) = NULL,
@ModifiedByName nvarchar(260),
@ModifiedByAuthType int,
@ModifiedDate datetime,
@Description nvarchar(512) = NULL,
@LastStatus nvarchar(260) = NULL,
@EventType nvarchar(260),
@MatchData ntext = NULL,
@Parameters ntext = NULL,
@DataSettings ntext = NULL,
@Version int

AS

-- Create a subscription with the given data.  The name must match a name in the
-- Catalog table and it must be a report type (2) or linked report (4)

DECLARE @Report_OID uniqueidentifier
DECLARE @OwnerID uniqueidentifier
DECLARE @ModifiedByID uniqueidentifier
DECLARE @TempDeliveryID uniqueidentifier

--Get the report id for this subscription
select @Report_OID = (select [ItemID] from [Catalog] where [Catalog].[Path] = @Report_Name and ([Catalog].[Type] = 2 or [Catalog].[Type] = 4 or [Catalog].[Type] = 8))

EXEC GetUserID @OwnerSid, @OwnerName, @OwnerAuthType, @OwnerID OUTPUT
EXEC GetUserID @ModifiedBySid, @ModifiedByName, @ModifiedByAuthType, @ModifiedByID OUTPUT

if (@Report_OID is NULL)
begin
RAISERROR('Report Not Found', 16, 1)
return
end

Insert into Subscriptions
    (
        [SubscriptionID], 
        [OwnerID],
        [Report_OID], 
        [ReportZone],
        [Locale],
        [DeliveryExtension],
        [InactiveFlags],
        [ExtensionSettings],
        [ModifiedByID],
        [ModifiedDate],
        [Description],
        [LastStatus],
        [EventType],
        [MatchData],
        [LastRunTime],
        [Parameters],
        [DataSettings],
    [Version]
    )
values
    (@id, @OwnerID, @Report_OID, @ReportZone, @Locale, @DeliveryExtension, @InactiveFlags, @ExtensionSettings, @ModifiedByID, @ModifiedDate,
     @Description, @LastStatus, @EventType, @MatchData, NULL, @Parameters, @DataSettings, @Version)

GO
/****** Object:  StoredProcedure [dbo].[CreateTask]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateTask]
@ScheduleID uniqueidentifier,
@Name nvarchar (260),
@StartDate datetime,
@Flags int,
@NextRunTime datetime = NULL,
@LastRunTime datetime = NULL,
@EndDate datetime = NULL,
@RecurrenceType int = NULL,
@MinutesInterval int = NULL,
@DaysInterval int = NULL,
@WeeksInterval int = NULL,
@DaysOfWeek int = NULL,
@DaysOfMonth int = NULL,
@Month int = NULL,
@MonthlyWeek int = NULL,
@State int = NULL,
@LastRunStatus nvarchar (260) = NULL,
@ScheduledRunTimeout int = NULL,
@UserSid varbinary (85) = null,
@UserName nvarchar(260),
@AuthType int,
@EventType nvarchar (260),
@EventData nvarchar (260),
@Type int ,
@Path nvarchar (425) = NULL
AS

DECLARE @UserID uniqueidentifier

EXEC GetUserID @UserSid, @UserName, @AuthType, @UserID OUTPUT

-- Create a task with the given data. 
Insert into Schedule 
    (
        [ScheduleID], 
        [Name],
        [StartDate],
        [Flags],
        [NextRunTime],
        [LastRunTime], 
        [EndDate], 
        [RecurrenceType], 
        [MinutesInterval],
        [DaysInterval],
        [WeeksInterval],
        [DaysOfWeek], 
        [DaysOfMonth], 
        [Month], 
        [MonthlyWeek],
        [State], 
        [LastRunStatus],
        [ScheduledRunTimeout],
        [CreatedById],
        [EventType],
        [EventData],
        [Type],
        [Path]
    )
values
    (@ScheduleID, @Name, @StartDate, @Flags, @NextRunTime, @LastRunTime, @EndDate, @RecurrenceType, @MinutesInterval,
     @DaysInterval, @WeeksInterval, @DaysOfWeek, @DaysOfMonth, @Month, @MonthlyWeek, @State, @LastRunStatus,
     @ScheduledRunTimeout, @UserID, @EventType, @EventData, @Type, @Path)

GO
/****** Object:  StoredProcedure [dbo].[CreateTimeBasedSubscriptionNotification]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateTimeBasedSubscriptionNotification]
@SubscriptionID uniqueidentifier,
@LastRunTime datetime,
@LastStatus nvarchar(260)
as

insert into [Notifications] 
    (
    [NotificationID], 
    [SubscriptionID],
    [ActivationID],
    [ReportID],
    [ReportZone],
    [SnapShotDate],
    [ExtensionSettings],
    [Locale],
    [Parameters],
    [NotificationEntered],
    [SubscriptionLastRunTime],
    [DeliveryExtension],
    [SubscriptionOwnerID],
    [IsDataDriven],
    [Version]
    ) 
select 
    NewID(),
    S.[SubscriptionID],
    NULL,
    S.[Report_OID],
    S.[ReportZone],
    NULL,
    S.[ExtensionSettings],
    S.[Locale],
    S.[Parameters],
    GETUTCDATE(), 
    @LastRunTime,
    S.[DeliveryExtension],
    S.[OwnerID],
    0,
    S.[Version]
from 
    [Subscriptions] S 
where 
    S.[SubscriptionID] = @SubscriptionID and InactiveFlags = 0 and
    S.[DataSettings] is null


-- Create any data driven subscription by creating a data driven event
insert into [Event]
    (
    [EventID],
    [EventType],
    [EventData],
    [TimeEntered]
    )
select
    NewID(),
    'DataDrivenSubscription',
    S.SubscriptionID,
    GETUTCDATE()
from
    [Subscriptions] S 
where 
    S.[SubscriptionID] = @SubscriptionID and InactiveFlags = 0 and
    S.[DataSettings] is not null

update [Subscriptions]
set
    [LastRunTime] = @LastRunTime,
    [LastStatus] = @LastStatus
where 
    [SubscriptionID] = @SubscriptionID and InactiveFlags = 0

GO
/****** Object:  StoredProcedure [dbo].[CreateTimeBasedSubscriptionSchedule]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateTimeBasedSubscriptionSchedule]
@SubscriptionID as uniqueidentifier,
@ScheduleID uniqueidentifier,
@Schedule_Name nvarchar (260),
@ItemPath nvarchar (425),
@Action int,
@StartDate datetime,
@Flags int,
@NextRunTime datetime = NULL,
@LastRunTime datetime = NULL,
@EndDate datetime = NULL,
@RecurrenceType int = NULL,
@MinutesInterval int = NULL,
@DaysInterval int = NULL,
@WeeksInterval int = NULL,
@DaysOfWeek int = NULL,
@DaysOfMonth int = NULL,
@Month int = NULL,
@MonthlyWeek int = NULL,
@State int = NULL,
@LastRunStatus nvarchar (260) = NULL,
@ScheduledRunTimeout int = NULL,
@UserSid varbinary (85) = NULL,
@UserName nvarchar(260),
@AuthType int,
@EventType nvarchar (260),
@EventData nvarchar (260),
@Path nvarchar (425) = NULL
AS

EXEC CreateTask @ScheduleID, @Schedule_Name, @StartDate, @Flags, @NextRunTime, @LastRunTime, 
        @EndDate, @RecurrenceType, @MinutesInterval, @DaysInterval, @WeeksInterval, @DaysOfWeek, 
        @DaysOfMonth, @Month, @MonthlyWeek, @State, @LastRunStatus, 
        @ScheduledRunTimeout, @UserSid, @UserName, @AuthType, @EventType, @EventData, 1 /*scoped type*/, @Path

if @@ERROR = 0
begin
	-- add a row to the reportSchedule table
	declare @ItemID uniqueidentifier
	select @ItemID = [ItemID] from [Catalog] with (HOLDLOCK) where [Catalog].[Path] = @ItemPath and ([Catalog].[Type] = 2 or [Catalog].[Type] = 4 or [Catalog].[Type] = 8)
	EXEC AddReportSchedule @ScheduleID, @ItemID, @SubscriptionID, @Action
end

GO
/****** Object:  StoredProcedure [dbo].[DecreaseTransientSnapshotRefcount]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DecreaseTransientSnapshotRefcount]
@SnapshotDataID as uniqueidentifier,
@IsPermanentSnapshot as bit
AS
SET NOCOUNT OFF
if @IsPermanentSnapshot = 1
BEGIN
   UPDATE SnapshotData
   SET TransientRefcount = TransientRefcount - 1
   WHERE SnapshotDataID = @SnapshotDataID
END ELSE BEGIN
   UPDATE dbo.ReportServerTempDB_SnapshotData
   SET TransientRefcount = TransientRefcount - 1
   WHERE SnapshotDataID = @SnapshotDataID
END

GO
/****** Object:  StoredProcedure [dbo].[DeepCopySegment]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[DeepCopySegment]
	@ChunkId		uniqueidentifier,
	@IsPermanent	bit,
	@SegmentId		uniqueidentifier,
	@NewSegmentId	uniqueidentifier out
as
begin
	select @NewSegmentId = newid() ;
	if (@IsPermanent = 1) begin
		insert Segment(SegmentId, Content)
		select @NewSegmentId, seg.Content
		from Segment seg
		where seg.SegmentId = @SegmentId ;
				
		update ChunkSegmentMapping
		set SegmentId = @NewSegmentId
		where ChunkId = @ChunkId and SegmentId = @SegmentId ;
	end
	else begin
		insert dbo.ReportServerTempDB_Segment(SegmentId, Content)
		select @NewSegmentId, seg.Content
		from dbo.ReportServerTempDB_Segment seg
		where seg.SegmentId = @SegmentId ;
		
		update dbo.ReportServerTempDB_ChunkSegmentMapping
		set SegmentId = @NewSegmentId
		where ChunkId = @ChunkId and SegmentId = @SegmentId ; 
	end
end

GO
/****** Object:  StoredProcedure [dbo].[DeleteActiveSubscription]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteActiveSubscription]
@ActiveID uniqueidentifier
AS

delete from ActiveSubscriptions where ActiveID = @ActiveID

GO
/****** Object:  StoredProcedure [dbo].[DeleteAllHistoryForReport]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- delete all snapshots for a report
CREATE PROCEDURE [dbo].[DeleteAllHistoryForReport]
@ReportID uniqueidentifier
AS
SET NOCOUNT OFF
DELETE
FROM History
WHERE HistoryID in
   (SELECT HistoryID
    FROM History JOIN Catalog on ItemID = ReportID
    WHERE ReportID = @ReportID
   )

GO
/****** Object:  StoredProcedure [dbo].[DeleteAllModelItemPolicies]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteAllModelItemPolicies]
@Path as nvarchar(450)
AS 

DELETE Policies
FROM
   Policies AS P
   INNER JOIN ModelItemPolicy AS MIP ON P.PolicyID = MIP.PolicyID
   INNER JOIN Catalog AS C ON MIP.CatalogItemID = C.ItemID
WHERE
   C.[Path] = @Path

GO
/****** Object:  StoredProcedure [dbo].[DeleteBatchRecords]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteBatchRecords]
@BatchID uniqueidentifier
AS
SET NOCOUNT OFF
DELETE
FROM [Batch]
WHERE BatchID = @BatchID

GO
/****** Object:  StoredProcedure [dbo].[DeleteDataSets]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteDataSets]
@ItemID [uniqueidentifier]
AS
DELETE
FROM [DataSets]
WHERE [ItemID] = @ItemID
DELETE
FROM dbo.ReportServerTempDB_TempDataSets
WHERE [ItemID] = @ItemID

GO
/****** Object:  StoredProcedure [dbo].[DeleteDataSources]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteDataSources]
@ItemID [uniqueidentifier]
AS

DELETE
FROM [DataSource]
WHERE [ItemID] = @ItemID or [SubscriptionID] = @ItemID 
DELETE
FROM dbo.ReportServerTempDB_TempDataSources
WHERE [ItemID] = @ItemID

GO
/****** Object:  StoredProcedure [dbo].[DeleteDrillthroughReports]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteDrillthroughReports]
@ModelID uniqueidentifier,
@ModelItemID nvarchar(425)
AS
 DELETE ModelDrill WHERE ModelID = @ModelID and ModelItemID = @ModelItemID

GO
/****** Object:  StoredProcedure [dbo].[DeleteEncryptedContent]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteEncryptedContent]
AS

-- Remove the encryption keys
delete from keys where client >= 0

-- Remove the encrypted content
update datasource
set CredentialRetrieval = 1, -- CredentialRetrieval.Prompt
    ConnectionString = null,
    OriginalConnectionString = null,
    UserName = null,
    Password = null

GO
/****** Object:  StoredProcedure [dbo].[DeleteEvent]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteEvent] 
@ID uniqueidentifier
AS
delete from [Event] where [EventID] = @ID

GO
/****** Object:  StoredProcedure [dbo].[DeleteExpiredPersistedStreams]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteExpiredPersistedStreams]
AS
SET NOCOUNT OFF
SET DEADLOCK_PRIORITY LOW
declare @now as datetime = GETDATE();
delete top (10) p
from dbo.ReportServerTempDB_PersistedStream p with(readpast)
where p.RefCount = 0 AND p.ExpirationDate < @now;

GO
/****** Object:  StoredProcedure [dbo].[DeleteHistoriesWithNoPolicy]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- delete all snapshots for all reports that inherit system History policy
CREATE PROCEDURE [dbo].[DeleteHistoriesWithNoPolicy]
AS
SET NOCOUNT OFF
DELETE
FROM History
WHERE HistoryID in
   (SELECT HistoryID
    FROM History JOIN Catalog on ItemID = ReportID
    WHERE SnapshotLimit is null
   )

GO
/****** Object:  StoredProcedure [dbo].[DeleteHistoryRecord]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- delete one historical snapshot
CREATE PROCEDURE [dbo].[DeleteHistoryRecord]
@ReportID uniqueidentifier,
@SnapshotDate DateTime
AS
SET NOCOUNT OFF
DELETE
FROM History
WHERE ReportID = @ReportID AND SnapshotDate = @SnapshotDate

GO
/****** Object:  StoredProcedure [dbo].[DeleteKey]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteKey]
@InstallationID uniqueidentifier
AS

if (@InstallationID = '00000000-0000-0000-0000-000000000000')
RAISERROR('Cannot delete reserved key', 16, 1)

-- Remove the encryption keys
delete from keys where InstallationID = @InstallationID and Client = 1

GO
/****** Object:  StoredProcedure [dbo].[DeleteModelItemPolicy]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteModelItemPolicy]
@CatalogItemID as uniqueidentifier,
@ModelItemID as nvarchar(425)
AS 
SET NOCOUNT OFF
DECLARE @PolicyID uniqueidentifier
SELECT @PolicyID = (SELECT PolicyID FROM ModelItemPolicy WHERE CatalogItemID = @CatalogItemID AND ModelItemID = @ModelItemID)
DELETE Policies FROM Policies WHERE Policies.PolicyID = @PolicyID

GO
/****** Object:  StoredProcedure [dbo].[DeleteModelPerspectives]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteModelPerspectives]
@ModelID as uniqueidentifier
AS

DELETE
FROM [ModelPerspective]
WHERE [ModelID] = @ModelID

GO
/****** Object:  StoredProcedure [dbo].[DeleteNotification]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteNotification] 
@ID uniqueidentifier
AS
delete from [Notifications] where [NotificationID] = @ID

GO
/****** Object:  StoredProcedure [dbo].[DeleteObject]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteObject]
@Path nvarchar (425),
@Prefix nvarchar (850),
@EditSessionID varchar(32) = NULL,
@OwnerSid as varbinary(85) = NULL, 
@OwnerName as nvarchar(260) = NULL,
@AuthType int
AS

SET NOCOUNT OFF

IF(@EditSessionID is null)
BEGIN
-- Remove reference for intermediate formats
UPDATE SnapshotData
SET PermanentRefcount = PermanentRefcount - 1,
    -- to fix VSTS 384486 keep shared dataset compiled definition for 14 days
    ExpirationDate = case when R.Type = 8 then DATEADD(d, 14, GETDATE()) ELSE ExpirationDate END,
    TransientRefcount = TransientRefcount + case when R.Type = 8 then 1 ELSE 0 END
FROM
   Catalog AS R WITH (XLOCK)
   INNER JOIN [SnapshotData] AS SD ON R.Intermediate = SD.SnapshotDataID
WHERE
   (R.Path = @Path OR R.Path LIKE @Prefix ESCAPE '*')

-- Remove reference for execution snapshots
UPDATE SnapshotData
SET PermanentRefcount = PermanentRefcount - 1
FROM
   Catalog AS R WITH (XLOCK)
   INNER JOIN [SnapshotData] AS SD ON R.SnapshotDataID = SD.SnapshotDataID
WHERE
   (R.Path = @Path OR R.Path LIKE @Prefix ESCAPE '*')

-- Remove history for deleted reports and linked report
DELETE History
FROM
   [Catalog] AS R
   INNER JOIN [History] AS S ON R.ItemID = S.ReportID
WHERE
   (R.Path = @Path OR R.Path LIKE @Prefix ESCAPE '*')
   
-- Remove model drill reports
DELETE ModelDrill
FROM
   [Catalog] AS C
   INNER JOIN [ModelDrill] AS M ON C.ItemID = M.ReportID
WHERE
   (C.Path = @Path OR C.Path LIKE @Prefix ESCAPE '*')
      

-- Adjust data sources
UPDATE [DataSource]
   SET
      [Flags] = [Flags] & 0x7FFFFFFD, -- broken link
      [Link] = NULL
FROM
   [Catalog] AS C
   INNER JOIN [DataSource] AS DS ON C.[ItemID] = DS.[Link]
WHERE
   (C.Path = @Path OR C.Path LIKE @Prefix ESCAPE '*')

-- Clean all data sources
DELETE [DataSource]
FROM
    [Catalog] AS R
    INNER JOIN [DataSource] AS DS ON R.[ItemID] = DS.[ItemID]
WHERE    
    (R.Path = @Path OR R.Path LIKE @Prefix ESCAPE '*')

        -- Adjust temp editsession data sources
        UPDATE dbo.ReportServerTempDB_TempDataSources
           SET
              Flags = Flags & 0x7FFFFFFD, -- broken link
              Link = NULL
        FROM
           [Catalog] AS C
           INNER JOIN dbo.ReportServerTempDB_TempDataSources AS DS ON C.[ItemID] = DS.Link
        WHERE
           (C.Path = @Path OR C.Path LIKE @Prefix ESCAPE '*')

-- Adjust shared datasets
UPDATE [DataSets]
   SET
      [LinkID] = NULL
FROM
   [Catalog] AS C
   INNER JOIN [DataSets] AS DS ON C.[ItemID] = DS.[LinkID]
WHERE
   (C.Path = @Path OR C.Path LIKE @Prefix ESCAPE '*')

-- Adjust temp shared datasets
UPDATE dbo.ReportServerTempDB_TempDataSets
   SET
      [LinkID] = NULL
FROM
   [Catalog] AS C
   INNER JOIN dbo.ReportServerTempDB_TempDataSets AS DS ON C.[ItemID] = DS.[LinkID]
WHERE
   (C.Path = @Path OR C.Path LIKE @Prefix ESCAPE '*')
   
-- Clean shared datasets
DELETE [DataSets]
FROM
    [Catalog] AS R
    INNER JOIN [DataSets] AS DS ON R.[ItemID] = DS.[ItemID]
WHERE    
    (R.Path = @Path OR R.Path LIKE @Prefix ESCAPE '*')


-- Update linked reports
UPDATE LR
   SET
      LR.LinkSourceID = NULL
FROM
   [Catalog] AS R INNER JOIN [Catalog] AS LR ON R.ItemID = LR.LinkSourceID
WHERE
   (R.Path = @Path OR R.Path LIKE @Prefix ESCAPE '*')
   AND
   (LR.Path NOT LIKE @Prefix ESCAPE '*')

-- Remove references for cache entries
UPDATE SN
SET
   PermanentRefcount = PermanentRefcount - 1
FROM
   dbo.ReportServerTempDB_SnapshotData AS SN
   INNER JOIN dbo.ReportServerTempDB_ExecutionCache AS EC on SN.SnapshotDataID = EC.SnapshotDataID
   INNER JOIN Catalog AS C ON EC.ReportID = C.ItemID
WHERE
   (Path = @Path OR Path LIKE @Prefix ESCAPE '*')
   
-- Clean cache entries for items to be deleted   
DELETE EC
FROM
   dbo.ReportServerTempDB_ExecutionCache AS EC
   INNER JOIN Catalog AS C ON EC.ReportID = C.ItemID
WHERE
   (Path = @Path OR Path LIKE @Prefix ESCAPE '*')

-- Finally delete items
DELETE
FROM
   [Catalog]
WHERE
   (Path = @Path OR Path LIKE @Prefix ESCAPE '*')

EXEC CleanOrphanedPolicies
END
ELSE
BEGIN
        DECLARE @OwnerID uniqueidentifier
        EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT
        
        -- Remove reference for intermediate formats
        UPDATE dbo.ReportServerTempDB_SnapshotData
        SET PermanentRefcount = PermanentRefcount - 1
        FROM
           dbo.ReportServerTempDB_TempCatalog AS R WITH (XLOCK)
           INNER JOIN dbo.ReportServerTempDB_SnapshotData AS SD ON R.Intermediate = SD.SnapshotDataID
        WHERE
           R.ContextPath = @Path
           AND R.EditSessionID = @EditSessionID
           AND R.OwnerID = @OwnerID

        -- Clean all data sources
        DELETE dbo.ReportServerTempDB_TempDataSources
        FROM
            dbo.ReportServerTempDB_TempCatalog AS R
            INNER JOIN dbo.ReportServerTempDB_TempDataSources AS DS ON R.TempCatalogID = DS.ItemID
        WHERE    
            R.ContextPath = @Path
            AND R.EditSessionID = @EditSessionID
            AND R.OwnerID = @OwnerID

		-- Clean shared data sets
        DELETE dbo.ReportServerTempDB_TempDataSets
        FROM
            dbo.ReportServerTempDB_TempCatalog AS R
            INNER JOIN dbo.ReportServerTempDB_TempDataSets AS DS ON R.TempCatalogID = DS.ItemID
        WHERE    
            R.ContextPath = @Path
            AND R.EditSessionID = @EditSessionID
            AND R.OwnerID = @OwnerID
            
        -- Remove references for cache entries
        UPDATE SN
        SET
           PermanentRefcount = PermanentRefcount - 1
        FROM
           dbo.ReportServerTempDB_SnapshotData AS SN
           INNER JOIN dbo.ReportServerTempDB_ExecutionCache AS EC on SN.SnapshotDataID = EC.SnapshotDataID
           INNER JOIN dbo.ReportServerTempDB_TempCatalog AS C ON EC.ReportID = C.TempCatalogID
        WHERE
           ContextPath = @Path
           AND C.EditSessionID = @EditSessionID
           AND C.OwnerID = @OwnerID
           
        -- Clean cache entries for items to be deleted   
        DELETE EC
        FROM
           dbo.ReportServerTempDB_ExecutionCache AS EC
           INNER JOIN dbo.ReportServerTempDB_TempCatalog AS C ON EC.ReportID = C.TempCatalogID
        WHERE
            ContextPath = @Path
            AND C.EditSessionID = @EditSessionID
            AND C.OwnerID = @OwnerID

        -- Finally delete items
        DELETE
        FROM
           dbo.ReportServerTempDB_TempCatalog
        WHERE
            ContextPath = @Path
            AND EditSessionID = @EditSessionID
            AND OwnerID = @OwnerID
END

GO
/****** Object:  StoredProcedure [dbo].[DeleteOneChunk]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteOneChunk]
@SnapshotID uniqueidentifier,
@IsPermanentSnapshot bit,
@ChunkName nvarchar(260),
@ChunkType int
AS
SET NOCOUNT OFF
-- for segmented chunks we just need to 
-- remove the mapping, the cleanup thread
-- will pick up the rest of the pieces
IF @IsPermanentSnapshot != 0 BEGIN

DELETE ChunkData
WHERE   
    SnapshotDataID = @SnapshotID AND
    ChunkName = @ChunkName AND
    ChunkType = @ChunkType
    
DELETE	SegmentedChunk
WHERE 	
	SnapshotDataId = @SnapshotID AND
	ChunkName = @ChunkName AND
	ChunkType = @ChunkType
    
END ELSE BEGIN

DELETE dbo.ReportServerTempDB_ChunkData
WHERE   
    SnapshotDataID = @SnapshotID AND
    ChunkName = @ChunkName AND
    ChunkType = @ChunkType

DELETE	dbo.ReportServerTempDB_SegmentedChunk
WHERE 	
	SnapshotDataId = @SnapshotID AND
	ChunkName = @ChunkName AND
	ChunkType = @ChunkType

END    

GO
/****** Object:  StoredProcedure [dbo].[DeletePersistedStream]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeletePersistedStream]
@SessionID varchar(32),
@Index int
AS

delete from dbo.ReportServerTempDB_PersistedStream where SessionID = @SessionID and [Index] = @Index

GO
/****** Object:  StoredProcedure [dbo].[DeletePersistedStreams]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeletePersistedStreams]
@SessionID varchar(32)
AS
SET NOCOUNT OFF
delete top (10) p
from dbo.ReportServerTempDB_PersistedStream p
where p.SessionID = @SessionID;

GO
/****** Object:  StoredProcedure [dbo].[DeletePolicy]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeletePolicy]
@ItemName as nvarchar(425)
AS 
SET NOCOUNT OFF
DECLARE @OldPolicyID uniqueidentifier
SELECT @OldPolicyID = (SELECT PolicyID FROM Catalog WHERE Catalog.Path = @ItemName)
UPDATE Catalog SET PolicyID = 
(SELECT Parent.PolicyID FROM Catalog Parent, Catalog WHERE Parent.ItemID = Catalog.ParentID AND Catalog.Path = @ItemName),
PolicyRoot = 0
WHERE Catalog.PolicyID = @OldPolicyID
DELETE Policies FROM Policies WHERE Policies.PolicyID = @OldPolicyID 

GO
/****** Object:  StoredProcedure [dbo].[DeleteReportSchedule]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteReportSchedule]
@ScheduleID uniqueidentifier,
@ReportID uniqueidentifier,
@SubscriptionID uniqueidentifier = NULL,
@ReportAction int
AS

IF @SubscriptionID is NULL
BEGIN
delete from ReportSchedule where ScheduleID = @ScheduleID and ReportID = @ReportID and ReportAction = @ReportAction
END
ELSE
BEGIN
delete from ReportSchedule where ScheduleID = @ScheduleID and ReportID = @ReportID and ReportAction = @ReportAction and SubscriptionID = @SubscriptionID
END

GO
/****** Object:  StoredProcedure [dbo].[DeleteRole]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Delete all policies associated with this role
CREATE PROCEDURE [dbo].[DeleteRole]
@RoleName nvarchar(260)
AS
SET NOCOUNT OFF
-- if you call this, you must delete/reconstruct all policies associated with this role
DELETE FROM Roles WHERE RoleName = @RoleName

GO
/****** Object:  StoredProcedure [dbo].[DeleteSnapshotAndChunks]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteSnapshotAndChunks]
@SnapshotID uniqueidentifier,
@IsPermanentSnapshot bit
AS

-- Delete from Snapshot, ChunkData and SegmentedChunk table.
-- Shared segments are not deleted.
-- TODO: currently this is being called from a bunch of places that handles exceptions.
-- We should try to delete the segments in some of all of those cases as well.
IF @IsPermanentSnapshot != 0 BEGIN

    DELETE ChunkData
    WHERE ChunkData.SnapshotDataID = @SnapshotID
    
    DELETE SegmentedChunk
    WHERE SegmentedChunk.SnapshotDataId = @SnapshotID
    
    DELETE SnapshotData
    WHERE SnapshotData.SnapshotDataID = @SnapshotID
   
END ELSE BEGIN

    DELETE dbo.ReportServerTempDB_ChunkData
    WHERE SnapshotDataID = @SnapshotID
       
    DELETE dbo.ReportServerTempDB_SegmentedChunk
    WHERE SnapshotDataId = @SnapshotID

    DELETE dbo.ReportServerTempDB_SnapshotData
    WHERE SnapshotDataID = @SnapshotID

END   

GO
/****** Object:  StoredProcedure [dbo].[DeleteSubscription]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteSubscription] 
@SubscriptionID uniqueidentifier
AS
    -- Delete the subscription
    delete from [Subscriptions] where [SubscriptionID] = @SubscriptionID
    -- Delete it from the SubscriptionsBeingDeleted
    EXEC RemoveSubscriptionFromBeingDeleted @SubscriptionID

GO
/****** Object:  StoredProcedure [dbo].[DeleteTask]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteTask]
@ScheduleID uniqueidentifier
AS
SET NOCOUNT OFF
-- Delete the task with the given task id
DELETE FROM Schedule
WHERE [ScheduleID] = @ScheduleID

GO
/****** Object:  StoredProcedure [dbo].[DeleteTimeBasedSubscriptionSchedule]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteTimeBasedSubscriptionSchedule]
@SubscriptionID as uniqueidentifier
as

delete ReportSchedule from ReportSchedule RS inner join Subscriptions S on S.[SubscriptionID] = RS.[SubscriptionID]
where
    S.[SubscriptionID] = @SubscriptionID

GO
/****** Object:  StoredProcedure [dbo].[DeliveryRemovedInactivateSubscription]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeliveryRemovedInactivateSubscription] 
@DeliveryExtension nvarchar(260),
@Status nvarchar(260)
AS
update 
    Subscriptions
set
    [DeliveryExtension] = '',
    [InactiveFlags] = [InactiveFlags] | 1, -- Delivery Provider Removed Flag == 1
    [LastStatus] = @Status
where
    [DeliveryExtension] = @DeliveryExtension

GO
/****** Object:  StoredProcedure [dbo].[DereferenceSessionSnapshot]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DereferenceSessionSnapshot]
@SessionID as varchar(32),
@OwnerID as uniqueidentifier
AS

UPDATE SN
SET TransientRefcount = TransientRefcount - 1
FROM
   SnapshotData AS SN
   INNER JOIN dbo.ReportServerTempDB_SessionData AS SE ON SN.SnapshotDataID = SE.SnapshotDataID
WHERE
   SE.SessionID = @SessionID AND
   SE.OwnerID = @OwnerID
   
UPDATE SN
SET TransientRefcount = TransientRefcount - 1
FROM
   dbo.ReportServerTempDB_SnapshotData AS SN
   INNER JOIN dbo.ReportServerTempDB_SessionData AS SE ON SN.SnapshotDataID = SE.SnapshotDataID
WHERE
   SE.SessionID = @SessionID AND
   SE.OwnerID = @OwnerID

GO
/****** Object:  StoredProcedure [dbo].[EnforceCacheLimits]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[EnforceCacheLimits]
    @ItemID uniqueidentifier, 
    @Cap int = 0
AS
BEGIN
    IF (@Cap > 0)
    BEGIN
        DECLARE @AffectedSnapshots TABLE (SnapshotDataID UNIQUEIDENTIFIER) ;
        DECLARE @Now DATETIME ;
        SELECT @Now = GETDATE() ;
        BEGIN TRANSACTION		
            -- remove entries which are not in the top N based on the last used time
            -- don't count expired entries, don't purge them either (allow cleanup thread to handle expired entries)
            DELETE FROM dbo.ReportServerTempDB_ExecutionCache
            OUTPUT DELETED.SnapshotDataID INTO @AffectedSnapshots(SnapshotDataID)
            WHERE	ExecutionCache.ReportID = @ItemID AND 
                    ExecutionCache.AbsoluteExpiration > @Now AND
                    ExecutionCache.ExecutionCacheID NOT IN (
                        SELECT TOP (@Cap) EC.ExecutionCacheID
                        FROM dbo.ReportServerTempDB_ExecutionCache EC
                        WHERE	EC.ReportID = @ItemID AND 
                                EC.AbsoluteExpiration > @Now
                        ORDER BY EC.LastUsedTime DESC) ;
            
            UPDATE dbo.ReportServerTempDB_SnapshotData
            SET PermanentRefCount = PermanentRefCount - 1
            WHERE SnapshotData.SnapshotDataID in (SELECT SnapshotDataID FROM @AffectedSnapshots) ;
        COMMIT				
    END
END

GO
/****** Object:  StoredProcedure [dbo].[ExpireExecutionLogEntries]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ExpireExecutionLogEntries]
AS
SET NOCOUNT OFF
-- -1 means no expiration
if exists (select * from ConfigurationInfo where [Name] = 'ExecutionLogDaysKept' and CAST(CAST(Value as nvarchar) as integer) = -1)
begin
return
end

delete from ExecutionLogStorage
where DateDiff(day, TimeStart, getdate()) >= (select CAST(CAST(Value as nvarchar) as integer) from ConfigurationInfo where [Name] = 'ExecutionLogDaysKept')

GO
/****** Object:  StoredProcedure [dbo].[ExtendEditSessionLifetime]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ExtendEditSessionLifetime]
    @EditSessionID varchar(32), 
    @Minutes int = NULL
AS
BEGIN
    if(@Minutes is null)
    begin
        declare @v nvarchar(max) ;
        select @v = convert(nvarchar(max), [Value]) from [dbo].[ConfigurationInfo] where [Name] = 'EditSessionTimeout' ;
        select @Minutes = convert(int, @v) / 60;  -- timeout stored in seconds
        
        if (@Minutes is null)
        begin
            select @Minutes = 120 ;
        end
        
        if(@Minutes < 1)
        begin
            select @Minutes = 1;
        end
    end
        
    update dbo.ReportServerTempDB_TempCatalog
    set ExpirationTime = DATEADD(n, @Minutes, GETDATE()) 
    where EditSessionID = @EditSessionID ;
END

GRANT EXECUTE ON [dbo].[ExtendEditSessionLifetime] TO RSExecRole

GO
/****** Object:  StoredProcedure [dbo].[FindItemsByDataSet]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FindItemsByDataSet]
@ItemID uniqueidentifier,
@AuthType int
AS
SELECT 
    C.Type,
    C.PolicyID,
    SD.NtSecDescPrimary,
    C.Name, 
    C.Path, 
    C.ItemID,
    DATALENGTH( C.Content ) AS [Size],
    C.Description,
    C.CreationDate, 
    C.ModifiedDate,
    SUSER_SNAME(CU.Sid), 
    CU.UserName,
    SUSER_SNAME(MU.Sid),
    MU.UserName,
    C.MimeType,
    C.ExecutionTime,
    C.Hidden,
    C.SubType,
    C.ComponentID
FROM
   Catalog AS C 
   INNER JOIN Users AS CU ON C.CreatedByID = CU.UserID
   INNER JOIN Users AS MU ON C.ModifiedByID = MU.UserID
   LEFT OUTER JOIN SecData AS SD ON C.PolicyID = SD.PolicyID AND SD.AuthType = @AuthType
   INNER JOIN DataSets AS DS ON C.ItemID = DS.ItemID
WHERE
   DS.LinkID = @ItemID

GO
/****** Object:  StoredProcedure [dbo].[FindItemsByDataSource]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FindItemsByDataSource]
@ItemID uniqueidentifier,
@AuthType int
AS
SELECT 
    C.Type,
    C.PolicyID,
    SD.NtSecDescPrimary,
    C.Name, 
    C.Path, 
    C.ItemID,
    DATALENGTH( C.Content ) AS [Size],
    C.Description,
    C.CreationDate, 
    C.ModifiedDate,
    SUSER_SNAME(CU.Sid), 
    CU.UserName,
    SUSER_SNAME(MU.Sid),
    MU.UserName,
    C.MimeType,
    C.ExecutionTime,
    C.Hidden,
    C.SubType,
    C.ComponentID
FROM
   Catalog AS C 
   INNER JOIN Users AS CU ON C.CreatedByID = CU.UserID
   INNER JOIN Users AS MU ON C.ModifiedByID = MU.UserID
   LEFT OUTER JOIN SecData AS SD ON C.PolicyID = SD.PolicyID AND SD.AuthType = @AuthType
   INNER JOIN DataSource AS DS ON C.ItemID = DS.ItemID
WHERE
   DS.Link = @ItemID

GO
/****** Object:  StoredProcedure [dbo].[FindItemsByDataSourceRecursive]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FindItemsByDataSourceRecursive]
@ItemID uniqueidentifier,
@AuthType int
AS
SELECT 
    C.Type,
    C.PolicyID,
    SD.NtSecDescPrimary,
    C.Name, 
    C.Path, 
    C.ItemID,
    DATALENGTH( C.Content ) AS [Size],
    C.Description,
    C.CreationDate, 
    C.ModifiedDate,
    SUSER_SNAME(CU.Sid), 
    CU.UserName,
    SUSER_SNAME(MU.Sid),
    MU.UserName,
    C.MimeType,
    C.ExecutionTime,
    C.Hidden,
    C.SubType,
    C.ComponentID
FROM
   Catalog AS C 
   INNER JOIN Users AS CU ON C.CreatedByID = CU.UserID
   INNER JOIN Users AS MU ON C.ModifiedByID = MU.UserID
   LEFT OUTER JOIN SecData AS SD ON C.PolicyID = SD.PolicyID AND SD.AuthType = @AuthType
   INNER JOIN 
   (
		SELECT ItemID FROM DataSource 
		WHERE Link = @ItemID 
		UNION 
		SELECT ItemID FROM DataSets
		WHERE LinkID IN
		(
			SELECT D1.ItemID
			FROM DataSource D1
			WHERE D1.Link = @ItemID
		)
	)
   AS DS ON C.ItemID = DS.ItemID

GO
/****** Object:  StoredProcedure [dbo].[FindObjectsByLink]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FindObjectsByLink]
@Link uniqueidentifier,
@AuthType int
AS
SELECT 
    C.Type, 
    C.PolicyID,
    SD.NtSecDescPrimary,
    C.Name, 
    C.Path, 
    C.ItemID, 
    DATALENGTH( C.Content ) AS [Size], 
    C.Description,
    C.CreationDate, 
    C.ModifiedDate, 
    SUSER_SNAME(CU.Sid),
    CU.UserName,
    SUSER_SNAME(MU.Sid),
    MU.UserName,
    C.MimeType,
    C.ExecutionTime,
    C.Hidden,
    C.SubType,
    C.ComponentID
FROM
   Catalog AS C
   INNER JOIN Users AS CU ON C.CreatedByID = CU.UserID
   INNER JOIN Users AS MU ON C.ModifiedByID = MU.UserID
   LEFT OUTER JOIN SecData AS SD ON C.PolicyID = SD.PolicyID AND SD.AuthType = @AuthType
WHERE C.LinkSourceID = @Link

GO
/****** Object:  StoredProcedure [dbo].[FindObjectsNonRecursive]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FindObjectsNonRecursive]
@Path nvarchar (425),
@AuthType int
AS
SELECT 
    C.Type,
    C.PolicyID,
    SD.NtSecDescPrimary,
    C.Name, 
    C.Path, 
    C.ItemID,
    DATALENGTH( C.Content ) AS [Size],
    C.Description,
    C.CreationDate, 
    C.ModifiedDate,
    SUSER_SNAME(CU.Sid), 
    CU.[UserName],
    SUSER_SNAME(MU.Sid),
    MU.[UserName],
    C.MimeType,
    C.ExecutionTime,
    C.Hidden, 
    C.SubType,
    C.ComponentID
FROM
   Catalog AS C 
   INNER JOIN Catalog AS P ON C.ParentID = P.ItemID
   INNER JOIN Users AS CU ON C.CreatedByID = CU.UserID
   INNER JOIN Users AS MU ON C.ModifiedByID = MU.UserID
   LEFT OUTER JOIN SecData SD ON C.PolicyID = SD.PolicyID AND SD.AuthType = @AuthType
WHERE P.Path = @Path

GO
/****** Object:  StoredProcedure [dbo].[FindObjectsRecursive]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FindObjectsRecursive]
@Prefix nvarchar (850),
@AuthType int
AS
SELECT 
    C.Type,
    C.PolicyID,
    SD.NtSecDescPrimary,
    C.Name,
    C.Path,
    C.ItemID,
    DATALENGTH( C.Content ) AS [Size],
    C.Description,
    C.CreationDate,
    C.ModifiedDate,
    SUSER_SNAME(CU.Sid),
    CU.UserName,
    SUSER_SNAME(MU.Sid),
    MU.UserName,
    C.MimeType,
    C.ExecutionTime,
    C.Hidden,
    C.SubType,
    C.ComponentID
from
   Catalog AS C
   INNER JOIN Users AS CU ON C.CreatedByID = CU.UserID
   INNER JOIN Users AS MU ON C.ModifiedByID = MU.UserID
   LEFT OUTER JOIN SecData AS SD ON C.PolicyID = SD.PolicyID AND SD.AuthType = @AuthType
WHERE C.Path LIKE @Prefix ESCAPE '*'

GO
/****** Object:  StoredProcedure [dbo].[FindParents]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FindParents]
@Path nvarchar (425),
@AuthType int
AS
WITH Parents (ItemID, ParentID)
AS
(
    SELECT ItemID, ParentID
    FROM Catalog WHERE Path = @Path
    UNION ALL
    SELECT C.ItemID, C.ParentID
    FROM Catalog C
    JOIN Parents P ON (C.ItemID = P.ParentID)
)
SELECT 
    C.Type,
    C.PolicyID,
    SD.NtSecDescPrimary,
    C.Name, 
    C.Path, 
    C.ItemID,
    DATALENGTH( C.Content ) AS [Size],
    C.Description,
    C.CreationDate, 
    C.ModifiedDate,
    SUSER_SNAME(CU.Sid), 
    CU.[UserName],
    SUSER_SNAME(MU.Sid),
    MU.[UserName],
    C.MimeType,
    C.ExecutionTime,
    C.Hidden,
    C.SubType,
    C.ComponentID
FROM
   Catalog AS C
   INNER JOIN Parents P ON (C.ItemID = P.ItemID)
   INNER JOIN Users AS CU ON C.CreatedByID = CU.UserID
   INNER JOIN Users AS MU ON C.ModifiedByID = MU.UserID
   LEFT OUTER JOIN SecData SD ON C.PolicyID = SD.PolicyID AND SD.AuthType = @AuthType
WHERE C.Path <> @Path -- Exclude the target item from the output list
ORDER BY DATALENGTH(C.Path) DESC

GO
/****** Object:  StoredProcedure [dbo].[FlushCacheByID]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FlushCacheByID]
@ItemID as uniqueidentifier
AS
BEGIN

DECLARE @AffectedSnapshots table (SnapshotDataID uniqueidentifier)

DELETE FROM dbo.ReportServerTempDB_ExecutionCache
OUTPUT DELETED.SnapshotDataID into @AffectedSnapshots
WHERE ReportID = @ItemID

UPDATE dbo.ReportServerTempDB_SnapshotData
SET PermanentRefcount = PermanentRefcount - 1
WHERE SnapshotDataID IN (SELECT SnapshotDataID FROM @AffectedSnapshots)

END

GO
/****** Object:  StoredProcedure [dbo].[FlushReportFromCache]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FlushReportFromCache]
@Path as nvarchar(425)
AS

SET DEADLOCK_PRIORITY LOW

-- VSTS #139360: SQL Deadlock in GetReportForexecution stored procedure
-- Use temporary table to keep the same order of accessing the ExecutionCache
-- and SnapshotData tables as GetReportForExecution does, that is first
-- delete from the ExecutionCache, then update the SnapshotData 
CREATE TABLE #tempSnapshot (SnapshotDataID uniqueidentifier)
INSERT INTO #tempSnapshot SELECT SN.SnapshotDataID 
FROM
   dbo.ReportServerTempDB_SnapshotData AS SN WITH (UPDLOCK)
   INNER JOIN dbo.ReportServerTempDB_ExecutionCache AS EC WITH (UPDLOCK) ON SN.SnapshotDataID = EC.SnapshotDataID
   INNER JOIN Catalog AS C ON EC.ReportID = C.ItemID
WHERE C.Path = @Path

DELETE EC
FROM
   dbo.ReportServerTempDB_ExecutionCache AS EC
   INNER JOIN #tempSnapshot ON #tempSnapshot.SnapshotDataID = EC.SnapshotDataID

UPDATE SN
   SET SN.PermanentRefcount = SN.PermanentRefcount - 1
FROM
   dbo.ReportServerTempDB_SnapshotData AS SN
   INNER JOIN #tempSnapshot ON #tempSnapshot.SnapshotDataID = SN.SnapshotDataID

GO
/****** Object:  StoredProcedure [dbo].[Get_sqlagent_job_status]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Get_sqlagent_job_status]
  -- Individual job parameters
  @job_id                     UNIQUEIDENTIFIER = NULL,  -- If provided will only return info about this job
                                                        --   Note: Only @job_id or @job_name needs to be provided    
  @job_name                   sysname          = NULL,  -- If provided will only return info about this job 
  @owner_login_name           sysname          = NULL   -- If provided will only return jobs for this owner
AS
BEGIN
  DECLARE @retval           INT
  DECLARE @job_owner_sid    VARBINARY(85)
  DECLARE @is_sysadmin      INT

  SET NOCOUNT ON

  -- Remove any leading/trailing spaces from parameters (except @owner_login_name)
  SELECT @job_name         = LTRIM(RTRIM(@job_name)) 

  -- Turn [nullable] empty string parameters into NULLs
  IF (@job_name         = N'') SELECT @job_name = NULL


  -- Verify the job if supplied. This also checks if the caller has rights to view the job 
  IF ((@job_id IS NOT NULL) OR (@job_name IS NOT NULL))
  BEGIN
    EXECUTE @retval = msdb..sp_verify_job_identifiers '@job_name',
                                                      '@job_id',
                                                       @job_name OUTPUT,
                                                       @job_id   OUTPUT
    IF (@retval <> 0)
      RETURN(1) -- Failure

  END
  
  -- If the login name isn't given, set it to the job owner or the current caller 
  IF(@owner_login_name IS NULL)
  BEGIN
        
    SET @owner_login_name = (SELECT SUSER_SNAME(sj.owner_sid) FROM msdb.dbo.sysjobs sj where sj.job_id = @job_id)

    SET @is_sysadmin = ISNULL(IS_SRVROLEMEMBER(N'sysadmin', @owner_login_name), 0)

  END
  ELSE
  BEGIN
    -- Check owner
    IF (SUSER_SID(@owner_login_name) IS NULL)
    BEGIN
      RAISERROR(14262, -1, -1, '@owner_login_name', @owner_login_name)
      RETURN(1) -- Failure
    END

    --only allow sysadmin types to specify the owner
    IF ((ISNULL(IS_SRVROLEMEMBER(N'sysadmin'), 0) <> 1) AND
        (ISNULL(IS_MEMBER(N'SQLAgentAdminRole'), 0) = 1) AND
        (SUSER_SNAME() <> @owner_login_name))
    BEGIN
      --TODO: RAISERROR(14525, -1, -1)
      RETURN(1) -- Failure
    END

    SET @is_sysadmin = 0
  END


  IF (@job_id IS NOT NULL)
  BEGIN
    -- Individual job...
    EXECUTE @retval =  master.dbo.xp_sqlagent_enum_jobs @is_sysadmin, @owner_login_name, @job_id
    IF (@retval <> 0)
      RETURN(1) -- Failure

  END
  ELSE
  BEGIN
    -- Set of jobs...
    EXECUTE @retval =  master.dbo.xp_sqlagent_enum_jobs @is_sysadmin, @owner_login_name
    IF (@retval <> 0)
      RETURN(1) -- Failure

  END

  RETURN(0) -- Success
END

GO
/****** Object:  StoredProcedure [dbo].[GetAllConfigurationInfo]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetAllConfigurationInfo]
AS
SELECT [Name], [Value]
FROM [ConfigurationInfo]

GO
/****** Object:  StoredProcedure [dbo].[GetAllProperties]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetAllProperties]
@Path nvarchar (425),
@EditSessionID varchar(32) = NULL,
@OwnerSid as varbinary(85) = NULL, 
@OwnerName as nvarchar(260) = NULL,
@AuthType int
AS
BEGIN

DECLARE @OwnerID uniqueidentifier
if(@EditSessionID is not null)
BEGIN
    EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT
END

select
   Property,
   Description,
   Type,
   DATALENGTH( Content ),
   ItemID, 
   SUSER_SNAME(C.Sid),
   C.UserName,
   CreationDate,
   SUSER_SNAME(M.Sid),
   M.UserName,
   ModifiedDate,
   MimeType,
   ExecutionTime,
   NtSecDescPrimary,
   [LinkSourceID],
   Hidden,
   ExecutionFlag,
   SnapshotLimit, 
   [Name], 
   SubType,
   ComponentID
FROM ExtendedCatalog(@OwnerID, @Path, @EditSessionID) Catalog
   INNER JOIN Users C ON Catalog.CreatedByID = C.UserID
   INNER JOIN Users M ON Catalog.ModifiedByID = M.UserID
   LEFT OUTER JOIN SecData ON Catalog.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
END

GO
/****** Object:  StoredProcedure [dbo].[GetAnnouncedKey]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetAnnouncedKey]
@InstallationID uniqueidentifier
AS

select PublicKey, MachineName, InstanceName
from Keys
where InstallationID = @InstallationID and Client = 1

GO
/****** Object:  StoredProcedure [dbo].[GetAReportsReportAction]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetAReportsReportAction]
@ReportID uniqueidentifier,
@ReportAction int
AS
select 
        RS.[ReportAction],
        RS.[ScheduleID],
        RS.[ReportID],
        RS.[SubscriptionID],
        C.[Path],
        C.[Type]
from
    [ReportSchedule] RS Inner join [Catalog] C on RS.[ReportID] = C.[ItemID]
where
    C.ItemID = @ReportID and RS.[ReportAction] = @ReportAction

GO
/****** Object:  StoredProcedure [dbo].[GetBatchRecords]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetBatchRecords]
@BatchID uniqueidentifier
AS
SELECT [Action], Item, Parent, Param, BoolParam, Content, Properties
FROM [Batch]
WHERE BatchID = @BatchID
ORDER BY AddedOn

GO
/****** Object:  StoredProcedure [dbo].[GetCacheOptions]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetCacheOptions]
@Path as nvarchar(425)
AS
    SELECT ExpirationFlags, CacheExpiration, 
    S.[ScheduleID],
    S.[Name],
    S.[StartDate],
    S.[Flags],
    S.[NextRunTime],
    S.[LastRunTime],
    S.[EndDate],
    S.[RecurrenceType],
    S.[MinutesInterval],
    S.[DaysInterval],
    S.[WeeksInterval],
    S.[DaysOfWeek],
    S.[DaysOfMonth],
    S.[Month],
    S.[MonthlyWeek],
    S.[State], 
    S.[LastRunStatus],
    S.[ScheduledRunTimeout],
    S.[EventType],
    S.[EventData],
    S.[Type],
    S.[Path]
    FROM CachePolicy INNER JOIN Catalog ON Catalog.ItemID = CachePolicy.ReportID
    LEFT outer join reportschedule rs on catalog.itemid = rs.reportid and rs.reportaction = 3
    LEFT OUTER JOIN [Schedule] S ON S.ScheduleID = rs.ScheduleID
    LEFT OUTER JOIN [Users] Owner on Owner.UserID = S.[CreatedById]
    WHERE Catalog.Path = @Path 

GO
/****** Object:  StoredProcedure [dbo].[GetCacheSchedule]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetCacheSchedule] 
@ReportID uniqueidentifier
AS
SELECT
    S.[ScheduleID],
    S.[Name],
    S.[StartDate], 
    S.[Flags],
    S.[NextRunTime],
    S.[LastRunTime], 
    S.[EndDate], 
    S.[RecurrenceType],
    S.[MinutesInterval],
    S.[DaysInterval],
    S.[WeeksInterval],
    S.[DaysOfWeek], 
    S.[DaysOfMonth], 
    S.[Month], 
    S.[MonthlyWeek], 
    S.[State], 
    S.[LastRunStatus],
    S.[ScheduledRunTimeout],
    S.[EventType],
    S.[EventData],
    S.[Type],
    S.[Path],
    SUSER_SNAME(Owner.[Sid]),
    Owner.[UserName],
    Owner.[AuthType],
    RS.ReportAction
FROM
    Schedule S with (XLOCK) inner join ReportSchedule RS on S.ScheduleID = RS.ScheduleID
    inner join [Users] Owner on S.[CreatedById] = Owner.[UserID]
WHERE
    (RS.ReportAction = 1 or RS.ReportAction = 3) and -- 1 == UpdateCache, 3 == Invalidate cache
    RS.[ReportID] = @ReportID

GO
/****** Object:  StoredProcedure [dbo].[GetChildrenBeforeDelete]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetChildrenBeforeDelete]
@Prefix nvarchar (850),
@AuthType int
AS
SELECT C.PolicyID, C.Type, SD.NtSecDescPrimary
FROM
   Catalog AS C LEFT OUTER JOIN SecData AS SD ON C.PolicyID = SD.PolicyID AND SD.AuthType = @AuthType
WHERE
   C.Path LIKE @Prefix ESCAPE '*'  -- return children only, not item itself

GO
/****** Object:  StoredProcedure [dbo].[GetChunkInformation]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetChunkInformation]
@SnapshotDataID uniqueidentifier,
@IsPermanentSnapshot bit,
@ChunkName nvarchar(260),
@ChunkType int
AS
IF @IsPermanentSnapshot != 0 BEGIN

    SELECT
       MimeType
    FROM
       ChunkData AS CH WITH (HOLDLOCK, ROWLOCK)
    WHERE
       SnapshotDataID = @SnapshotDataID AND
       ChunkName = @ChunkName AND
       ChunkType = @ChunkType      
       
END ELSE BEGIN

    SELECT
       MimeType
    FROM
       dbo.ReportServerTempDB_ChunkData AS CH WITH (HOLDLOCK, ROWLOCK)
    WHERE
       SnapshotDataID = @SnapshotDataID AND
       ChunkName = @ChunkName AND
       ChunkType = @ChunkType      

END

GO
/****** Object:  StoredProcedure [dbo].[GetChunkPointerAndLength]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetChunkPointerAndLength]
@SnapshotDataID uniqueidentifier,
@IsPermanentSnapshot bit,
@ChunkName nvarchar(260),
@ChunkType int
AS
IF @IsPermanentSnapshot != 0 BEGIN

    SELECT
       TEXTPTR(Content),
       DATALENGTH(Content),
       MimeType,
       ChunkFlags,
       Version
    FROM
       ChunkData AS CH 
    WHERE
       SnapshotDataID = @SnapshotDataID AND
       ChunkName = @ChunkName AND
       ChunkType = @ChunkType      
       
END ELSE BEGIN

    SELECT
       TEXTPTR(Content),
       DATALENGTH(Content),
       MimeType,
       ChunkFlags,
       Version
    FROM
       dbo.ReportServerTempDB_ChunkData AS CH 
    WHERE
       SnapshotDataID = @SnapshotDataID AND
       ChunkName = @ChunkName AND
       ChunkType = @ChunkType      

END

GO
/****** Object:  StoredProcedure [dbo].[GetCompiledDefinition]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- used to create snapshots
CREATE PROCEDURE [dbo].[GetCompiledDefinition]
@Path nvarchar (425),
@EditSessionID varchar(32) = NULL,
@OwnerSid as varbinary(85) = NULL, 
@OwnerName as nvarchar(260) = NULL,
@AuthType int
AS
BEGIN

DECLARE @OwnerID uniqueidentifier
if(@EditSessionID is not null)
BEGIN
    EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT
END

    SELECT
       MainItem.Type,
       MainItem.Intermediate,
       MainItem.LinkSourceID,
       MainItem.Property,
       MainItem.Description,
       SecData.NtSecDescPrimary,
       MainItem.ItemID,         
       MainItem.ExecutionFlag,  
       LinkTarget.Intermediate,
       LinkTarget.Property,
       LinkTarget.Description,
       MainItem.[SnapshotDataID], 
       MainItem.IntermediateIsPermanent
    FROM ExtendedCatalog(@OwnerID, @Path, @EditSessionID) MainItem
    LEFT OUTER JOIN SecData ON MainItem.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
    LEFT OUTER JOIN Catalog LinkTarget with (INDEX(PK_Catalog)) on MainItem.LinkSourceID = LinkTarget.ItemID
END				

GO
/****** Object:  StoredProcedure [dbo].[GetDataSetForExecution]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetDataSetForExecution]
@ItemID uniqueidentifier,
@ParamsHash int
AS
DECLARE @now AS datetime
SET @now = GETDATE()
SELECT
    SN.SnapshotDataID,
    SN.EffectiveParams,
    SN.QueryParams,
    (SELECT CachePolicy.ExpirationFlags FROM CachePolicy WHERE CachePolicy.ReportID = Cat.ItemID),
    Cat.Property
FROM
    Catalog AS Cat
    LEFT OUTER JOIN
    (
        SELECT 
        TOP 1
            ReportID, 
            SN.SnapshotDataID, 
            EffectiveParams, 
            QueryParams
        FROM dbo.ReportServerTempDB_ExecutionCache AS EC 
        INNER JOIN dbo.ReportServerTempDB_SnapshotData AS SN ON EC.SnapshotDataID = SN.SnapshotDataID AND EC.ParamsHash = SN.ParamsHash
        WHERE
            AbsoluteExpiration > @now 
            AND SN.ParamsHash = @ParamsHash
            AND EC.ReportID = @ItemID
        ORDER BY SN.CreatedDate DESC
    ) as SN ON Cat.ItemID = SN.ReportID
WHERE
    Cat.ItemID = @ItemID

GO
/****** Object:  StoredProcedure [dbo].[GetDataSets]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  PROCEDURE [dbo].[GetDataSets]
@ItemID [uniqueidentifier],
@AuthType int
AS
BEGIN

SELECT 
	DS.ID, 
	DS.LinkID,
	DS.[Name],
	C.Path,
	SD.NtSecDescPrimary,
	C.Intermediate,
	C.[Parameter]
FROM
   ExtendedDataSets AS DS 
   LEFT OUTER JOIN Catalog C ON DS.[LinkID] = C.[ItemID]
   LEFT OUTER JOIN [SecData] AS SD ON C.[PolicyID] = SD.[PolicyID] AND SD.AuthType = @AuthType
WHERE
   DS.[ItemID] = @ItemID
END

GO
/****** Object:  StoredProcedure [dbo].[GetDataSourceForUpgrade]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetDataSourceForUpgrade]
@CurrentVersion int
AS
SELECT 
    [DSID]
FROM 
    [DataSource]
WHERE
    [Version] != @CurrentVersion

GO
/****** Object:  StoredProcedure [dbo].[GetDatasourceInfoForReencryption]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetDatasourceInfoForReencryption]
@DSID as uniqueidentifier
AS

SELECT
    [ConnectionString],
    [OriginalConnectionString],
    [UserName],
    [Password],
    [CredentialRetrieval],
    [Version]
FROM [dbo].[DataSource]
WHERE [DSID] = @DSID

GO
/****** Object:  StoredProcedure [dbo].[GetDataSources]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  PROCEDURE [dbo].[GetDataSources]
@ItemID [uniqueidentifier],
@AuthType int
AS
BEGIN

SELECT -- select data sources and their links (if they exist)
    DS.[DSID],      -- 0
    DS.[ItemID],    -- 1
    DS.[Name],      -- 2
    DS.[Extension], -- 3
    DS.[Link],      -- 4
    DS.[CredentialRetrieval], -- 5
    DS.[Prompt],    -- 6
    DS.[ConnectionString], -- 7
    DS.[OriginalConnectionString], -- 8
    DS.[UserName],  -- 9
    DS.[Password],  -- 10
    DS.[Flags],     -- 11
    DSL.[DSID],     -- 12
    DSL.[ItemID],   -- 13
    DSL.[Name],     -- 14
    DSL.[Extension], -- 15
    DSL.[Link],     -- 16
    DSL.[CredentialRetrieval], -- 17
    DSL.[Prompt],   -- 18
    DSL.[ConnectionString], -- 19
    DSL.[UserName], -- 20
    DSL.[Password], -- 21
    DSL.[Flags],	-- 22
    C.Path,         -- 23
    SD.NtSecDescPrimary, -- 24
    DS.[OriginalConnectStringExpressionBased], -- 25
    DS.[Version], -- 26
    DSL.[Version], -- 27
    (SELECT 1 WHERE EXISTS (SELECT * from [ModelItemPolicy] AS MIP WHERE C.[ItemID] = MIP.[CatalogItemID])) -- 28
FROM
   ExtendedDataSources AS DS 
   LEFT OUTER JOIN 
    (DataSource AS DSL
     INNER JOIN Catalog C ON DSL.[ItemID] = C.[ItemID]
       LEFT OUTER JOIN [SecData] AS SD ON C.[PolicyID] = SD.[PolicyID] AND SD.AuthType = @AuthType)
   ON DS.[Link] = DSL.[ItemID]
WHERE
   DS.[ItemID] = @ItemID or DS.[SubscriptionID] = @ItemID
END

GO
/****** Object:  StoredProcedure [dbo].[GetDBVersion]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

    CREATE PROCEDURE [dbo].[GetDBVersion]
    @DBVersion nvarchar(32) OUTPUT
    AS
    SET @DBVersion = (select top(1) [ServerVersion] from [dbo].[ServerUpgradeHistory] ORDER BY [UpgradeID] DESC)
GO
/****** Object:  StoredProcedure [dbo].[GetDrillthroughReport]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetDrillthroughReport]
@ModelPath nvarchar(425),
@ModelItemID nvarchar(425),
@Type tinyint
AS
 SELECT 
 CatRep.Path
 FROM ModelDrill 
 INNER JOIN Catalog CatMod ON ModelDrill.ModelID = CatMod.ItemID
 INNER JOIN Catalog CatRep ON ModelDrill.ReportID = CatRep.ItemID
 WHERE CatMod.Path = @ModelPath
 AND ModelItemID = @ModelItemID 
 AND ModelDrill.[Type] = @Type

GO
/****** Object:  StoredProcedure [dbo].[GetDrillthroughReports]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetDrillthroughReports]
@ModelID uniqueidentifier,
@ModelItemID nvarchar(425)
AS
 SELECT 
 ModelDrill.Type, 
 Catalog.Path
 FROM ModelDrill INNER JOIN Catalog ON ModelDrill.ReportID = Catalog.ItemID
 WHERE ModelID = @ModelID
 AND ModelItemID = @ModelItemID 

GO
/****** Object:  StoredProcedure [dbo].[GetExecutionOptions]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetExecutionOptions]
@Path nvarchar(425)
AS
    SELECT ExecutionFlag, 
    S.[ScheduleID],
    S.[Name],
    S.[StartDate],
    S.[Flags],
    S.[NextRunTime],
    S.[LastRunTime],
    S.[EndDate],
    S.[RecurrenceType],
    S.[MinutesInterval],
    S.[DaysInterval],
    S.[WeeksInterval],
    S.[DaysOfWeek],
    S.[DaysOfMonth],
    S.[Month],
    S.[MonthlyWeek],
    S.[State], 
    S.[LastRunStatus],
    S.[ScheduledRunTimeout],
    S.[EventType],
    S.[EventData],
    S.[Type],
    S.[Path]
    FROM Catalog 
    LEFT OUTER JOIN ReportSchedule ON Catalog.ItemID = ReportSchedule.ReportID AND ReportSchedule.ReportAction = 1
    LEFT OUTER JOIN [Schedule] S ON S.ScheduleID = ReportSchedule.ScheduleID
    LEFT OUTER JOIN [Users] Owner on Owner.UserID = S.[CreatedById]
    WHERE Catalog.Path = @Path 

GO
/****** Object:  StoredProcedure [dbo].[GetFirstPortionPersistedStream]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetFirstPortionPersistedStream]
@SessionID varchar(32)
AS

SELECT 
    TOP 1
    TEXTPTR(P.Content), 
    DATALENGTH(P.Content), 
    P.[Index],
    P.[Name], 
    P.MimeType, 
    P.Extension, 
    P.Encoding,
    P.Error
FROM 
    dbo.ReportServerTempDB_PersistedStream P WITH (XLOCK)
WHERE 
    P.SessionID = @SessionID

GO
/****** Object:  StoredProcedure [dbo].[GetIDPairsByLink]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetIDPairsByLink]
@Link uniqueidentifier
AS
SELECT LinkSourceID, ItemID
FROM Catalog
WHERE LinkSourceID = @Link

GO
/****** Object:  StoredProcedure [dbo].[GetModelDefinition]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetModelDefinition]
@CatalogItemID as uniqueidentifier
AS

SELECT
    C.[Content]
FROM
    [Catalog] AS C
WHERE
    C.[ItemID] = @CatalogItemID

GO
/****** Object:  StoredProcedure [dbo].[GetModelItemInfo]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetModelItemInfo]
@Path nvarchar (425),
@UseUpdateLock bit
AS
	IF(@UseUpdateLock = 0) 
	BEGIN
		SELECT
			C.[Intermediate]
		FROM
			[Catalog] AS C
		WHERE
			C.[Path] = @Path
	END
	ELSE BEGIN
		-- acquire update lock, this means that the operation is being performed in a 
		-- different transaction context which will be committed before trying to 
		-- perform the actual load, to prevent deadlock in the case where we have to 
		-- republish, this new transaction will acquire and hold upgrade locks
		SELECT
			C.[Intermediate]
		FROM
			[Catalog] AS C WITH(UPDLOCK ROWLOCK)
		WHERE
			C.[Path] = @Path
	END

	SELECT
		MIP.[ModelItemID], SD.[NtSecDescPrimary], SD.[XmlDescription]
	FROM
		[Catalog] AS C
		INNER JOIN [ModelItemPolicy] AS MIP ON C.[ItemID] = MIP.[CatalogItemID]
		LEFT OUTER JOIN [SecData] AS SD ON MIP.[PolicyID] = SD.[PolicyID]
	WHERE
		C.[Path] = @Path

GO
/****** Object:  StoredProcedure [dbo].[GetModelPerspectives]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetModelPerspectives]
@Path nvarchar (425),
@AuthType int
AS

SELECT
    C.[Type],
    SD.[NtSecDescPrimary],
    C.[Description]
FROM
    [Catalog] as C
    LEFT OUTER JOIN [SecData] AS SD ON C.[PolicyID] = SD.[PolicyID] AND SD.[AuthType] = @AuthType
WHERE
    [Path] = @Path

SELECT
    P.[PerspectiveID],
    P.[PerspectiveName],
    P.[PerspectiveDescription]
FROM
    [Catalog] as C
    INNER JOIN [ModelPerspective] as P ON C.[ItemID] = P.[ModelID]
WHERE
    [Path] = @Path

GO
/****** Object:  StoredProcedure [dbo].[GetModelsAndPerspectives]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetModelsAndPerspectives]
@AuthType int,
@SitePathPrefix nvarchar(520) = '%'
AS

SELECT
    C.[PolicyID],
    SD.[NtSecDescPrimary],
    C.[ItemID],
    C.[Path],
    C.[Description],
    P.[PerspectiveID],
    P.[PerspectiveName],
    P.[PerspectiveDescription]
FROM
    [Catalog] as C
    LEFT OUTER JOIN [ModelPerspective] as P ON C.[ItemID] = P.[ModelID]
    LEFT OUTER JOIN [SecData] AS SD ON C.[PolicyID] = SD.[PolicyID] AND SD.[AuthType] = @AuthType
WHERE
    C.Path like @SitePathPrefix AND C.[Type] = 6 -- Model
ORDER BY
    C.[Path]    

GO
/****** Object:  StoredProcedure [dbo].[GetMyRunningJobs]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetMyRunningJobs]
@ComputerName as nvarchar(32),
@JobType as smallint
AS
SELECT JobID, StartDate, ComputerName, RequestName, RequestPath, SUSER_SNAME(Users.[Sid]), Users.[UserName], Description, 
    Timeout, JobAction, JobType, JobStatus, Users.[AuthType]
FROM RunningJobs INNER JOIN Users 
ON RunningJobs.UserID = Users.UserID
WHERE ComputerName = @ComputerName
AND JobType = @JobType

GO
/****** Object:  StoredProcedure [dbo].[GetNameById]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetNameById]
@ItemID uniqueidentifier
AS
SELECT Path
FROM Catalog
WHERE ItemID = @ItemID

GO
/****** Object:  StoredProcedure [dbo].[GetNextPortionPersistedStream]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetNextPortionPersistedStream]
@DataPointer binary(16),
@DataIndex int,
@Length int
AS

READTEXT dbo.ReportServerTempDB_PersistedStream.Content @DataPointer @DataIndex @Length

GO
/****** Object:  StoredProcedure [dbo].[GetObjectContent]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetObjectContent]
@Path nvarchar (425),
@AuthType int
AS
SELECT Type, Content, LinkSourceID, MimeType, SecData.NtSecDescPrimary, ItemID
FROM Catalog
LEFT OUTER JOIN SecData ON Catalog.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
WHERE Path = @Path

GO
/****** Object:  StoredProcedure [dbo].[GetOneConfigurationInfo]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetOneConfigurationInfo]
@Name nvarchar (260)
AS
SELECT [Value]
FROM [ConfigurationInfo]
WHERE [Name] = @Name

GO
/****** Object:  StoredProcedure [dbo].[GetParameters]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetParameters]
@Path nvarchar (425),
@AuthType int
AS
SELECT
   Type,
   [Parameter],
   ItemID,
   SecData.NtSecDescPrimary,
   [LinkSourceID],
   [ExecutionFlag]
FROM Catalog 
LEFT OUTER JOIN SecData ON Catalog.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
WHERE Path = @Path

GO
/****** Object:  StoredProcedure [dbo].[GetPoliciesForRole]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetPoliciesForRole]
@RoleName as nvarchar(260),
@AuthType as int
AS 
SELECT
    Policies.PolicyID,
    SecData.XmlDescription, 
    Policies.PolicyFlag,
    Catalog.Type,
    Catalog.Path,
    ModelItemPolicy.CatalogItemID,
    ModelItemPolicy.ModelItemID,
    RelatedRoles.RoleID,
    RelatedRoles.RoleName,
    RelatedRoles.TaskMask,
    RelatedRoles.RoleFlags
FROM
    Roles
    INNER JOIN PolicyUserRole ON Roles.RoleID = PolicyUserRole.RoleID
    INNER JOIN Policies ON PolicyUserRole.PolicyID = Policies.PolicyID
    INNER JOIN PolicyUserRole AS RelatedPolicyUserRole ON Policies.PolicyID = RelatedPolicyUserRole.PolicyID
    INNER JOIN Roles AS RelatedRoles ON RelatedPolicyUserRole.RoleID = RelatedRoles.RoleID
    LEFT OUTER JOIN SecData ON Policies.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
    LEFT OUTER JOIN Catalog ON Policies.PolicyID = Catalog.PolicyID AND Catalog.PolicyRoot = 1
    LEFT OUTER JOIN ModelItemPolicy ON Policies.PolicyID = ModelItemPolicy.PolicyID
WHERE
    Roles.RoleName = @RoleName
ORDER BY
    Policies.PolicyID

GO
/****** Object:  StoredProcedure [dbo].[GetPolicy]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetPolicy]
@ItemName as nvarchar(425),
@AuthType int
AS 
SELECT SecData.XmlDescription, Catalog.PolicyRoot , SecData.NtSecDescPrimary, Catalog.Type
FROM Catalog 
INNER JOIN Policies ON Catalog.PolicyID = Policies.PolicyID 
LEFT OUTER JOIN SecData ON Policies.PolicyID = SecData.PolicyID AND AuthType = @AuthType
WHERE Catalog.Path = @ItemName
AND PolicyFlag = 0

GO
/****** Object:  StoredProcedure [dbo].[GetPolicyRoots]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetPolicyRoots]
AS
SELECT 
    [Path],
    [Type]
FROM 
    [Catalog] 
WHERE 
    [PolicyRoot] = 1

GO
/****** Object:  StoredProcedure [dbo].[GetPrincipalID]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- looks up a principal, if not there looks up regular users and turns them into principals
-- if not, it creates a principal
CREATE PROCEDURE [dbo].[GetPrincipalID]
@UserSid varbinary(85) = NULL,
@UserName nvarchar(260),
@AuthType int,
@UserID uniqueidentifier OUTPUT
AS
-- windows auth
IF @AuthType = 1
BEGIN
    -- is this a principal?
    SELECT @UserID = (SELECT UserID FROM Users WHERE Sid = @UserSid AND UserType = 1 AND AuthType = @AuthType)
END
ELSE
BEGIN
    -- is this a principal?
    SELECT @UserID = (SELECT UserID FROM Users WHERE UserName = @UserName AND UserType = 1 AND AuthType = @AuthType)
END
IF @UserID IS NULL
   BEGIN
        IF @AuthType = 1 -- Windows
        BEGIN
            -- Is this a regular user
            SELECT @UserID = (SELECT UserID FROM Users WHERE Sid = @UserSid AND UserType = 0 AND AuthType = @AuthType)
        END
        ELSE
        BEGIN
            -- Is this a regular user
            SELECT @UserID = (SELECT UserID FROM Users WHERE UserName = @UserName AND UserType = 0 AND AuthType = @AuthType)
        END
      -- No, create a new principal
      IF @UserID IS NULL
         BEGIN
            SET @UserID = newid()
            INSERT INTO Users
            (UserID, Sid,   UserType, AuthType, UserName)
            VALUES 
            (@UserID, @UserSid, 1,    @AuthType, @UserName)
         END 
      ELSE
         BEGIN
             UPDATE Users SET UserType = 1 WHERE UserID = @UserID
         END
    END

GO
/****** Object:  StoredProcedure [dbo].[GetReportForExecution]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- gets either the intermediate format or snapshot from cache
CREATE PROCEDURE [dbo].[GetReportForExecution]
@Path nvarchar (425),
@EditSessionID varchar(32) = NULL,
@ParamsHash int,
@OwnerSid as varbinary(85) = NULL, 
@OwnerName as nvarchar(260) = NULL,
@AuthType int
AS
DECLARE @OwnerID uniqueidentifier
if(@EditSessionID is not null)
BEGIN
    EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT
END

DECLARE @now AS datetime
SET @now = GETDATE()

IF ( NOT EXISTS (
    SELECT TOP 1 1
        FROM
            ExtendedCatalog(@OwnerID, @Path, @EditSessionID) AS C
            INNER JOIN dbo.ReportServerTempDB_ExecutionCache AS EC ON C.ItemID = EC.ReportID
        WHERE
            EC.AbsoluteExpiration > @now AND
            EC.ParamsHash = @ParamsHash
   ) ) 
BEGIN   -- no cache
    SELECT
        Cat.Type,
        Cat.LinkSourceID,
        Cat2.Path,
        Cat.Property,
        Cat.Description,
        SecData.NtSecDescPrimary,
        Cat.ItemID,
        CAST (0 AS BIT), -- not found,
        Cat.Intermediate,
        Cat.ExecutionFlag,
        SD.SnapshotDataID,
        SD.DependsOnUser,
        Cat.ExecutionTime,
        (SELECT Schedule.NextRunTime
         FROM
             Schedule WITH (XLOCK)
             INNER JOIN ReportSchedule ON Schedule.ScheduleID = ReportSchedule.ScheduleID 
         WHERE ReportSchedule.ReportID = Cat.ItemID AND ReportSchedule.ReportAction = 1), -- update snapshot
        (SELECT Schedule.ScheduleID
         FROM
             Schedule
             INNER JOIN ReportSchedule ON Schedule.ScheduleID = ReportSchedule.ScheduleID 
         WHERE ReportSchedule.ReportID = Cat.ItemID AND ReportSchedule.ReportAction = 1), -- update snapshot
        (SELECT CachePolicy.ExpirationFlags FROM CachePolicy WHERE CachePolicy.ReportID = Cat.ItemID),
        Cat2.Intermediate,
        SD.ProcessingFlags,
        Cat.IntermediateIsPermanent
    FROM
        ExtendedCatalog(@OwnerID, @Path, @EditSessionID) AS Cat
        LEFT OUTER JOIN SecData ON Cat.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
        LEFT OUTER JOIN Catalog AS Cat2 on Cat.LinkSourceID = Cat2.ItemID
        LEFT OUTER JOIN SnapshotData AS SD ON Cat.SnapshotDataID = SD.SnapshotDataID
END
ELSE
BEGIN   -- use cache
    SELECT TOP 1
        Cat.Type,
        Cat.LinkSourceID,
        Cat2.Path,
        Cat.Property,
        Cat.Description,
        SecData.NtSecDescPrimary,
        Cat.ItemID,
        CAST (1 AS BIT), -- found,
        SN.SnapshotDataID,
        SN.DependsOnUser,
        SN.EffectiveParams,  -- offset 10
        SN.CreatedDate,
        EC.AbsoluteExpiration,
        (SELECT CachePolicy.ExpirationFlags FROM CachePolicy WHERE CachePolicy.ReportID = Cat.ItemID),
        (SELECT Schedule.ScheduleID
         FROM
             Schedule WITH (XLOCK)
             INNER JOIN ReportSchedule ON Schedule.ScheduleID = ReportSchedule.ScheduleID 
             WHERE ReportSchedule.ReportID = Cat.ItemID AND ReportSchedule.ReportAction = 1), -- update snapshot
        SN.QueryParams,  -- offset 15
        SN.ProcessingFlags, 
        Cat.IntermediateIsPermanent,
        Cat.Intermediate
    FROM
        ExtendedCatalog(@OwnerID, @Path, @EditSessionID) AS Cat
        INNER JOIN dbo.ReportServerTempDB_ExecutionCache AS EC ON Cat.ItemID = EC.ReportID
        INNER JOIN dbo.ReportServerTempDB_SnapshotData AS SN ON EC.SnapshotDataID = SN.SnapshotDataID AND EC.ParamsHash = SN.ParamsHash
        LEFT OUTER JOIN SecData ON Cat.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
        LEFT OUTER JOIN Catalog AS Cat2 on Cat.LinkSourceID = Cat2.ItemID
    WHERE
        AbsoluteExpiration > @now 
        AND SN.ParamsHash = @ParamsHash
    ORDER BY SN.CreatedDate DESC
END

GO
/****** Object:  StoredProcedure [dbo].[GetReportParametersForExecution]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- gets either the intermediate format or snapshot from cache
CREATE PROCEDURE [dbo].[GetReportParametersForExecution]
@Path nvarchar (425),
@HistoryID DateTime = NULL,
@AuthType int, 
@OwnerSid as varbinary(85) = NULL, 
@OwnerName as nvarchar(260) = NULL,
@EditSessionID varchar(32) = NULL
AS
BEGIN

DECLARE @OwnerID uniqueidentifier
if(@EditSessionID is not null)
BEGIN
    EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT
END

SELECT
   C.[ItemID],
   C.[Type],
   C.[ExecutionFlag],
   [SecData].[NtSecDescPrimary],
   C.[Parameter],
   C.[Intermediate],
   C.[SnapshotDataID],
   [History].[SnapshotDataID],
   L.[Intermediate],
   C.[LinkSourceID],
   C.[ExecutionTime], 
   C.IntermediateIsPermanent
FROM
   ExtendedCatalog(@OwnerID, @Path, @EditSessionID) AS C
   LEFT OUTER JOIN [SecData] ON C.[PolicyID] = [SecData].[PolicyID] AND [SecData].AuthType = @AuthType
   LEFT OUTER JOIN [History] ON ( C.[ItemID] = [History].[ReportID] AND [History].[SnapshotDate] = @HistoryID )
   LEFT OUTER JOIN [Catalog] AS L WITH (INDEX(PK_Catalog)) ON C.[LinkSourceID] = L.[ItemID]
end

GO
/****** Object:  StoredProcedure [dbo].[GetRoles]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetRoles]
@RoleFlags as tinyint = NULL
AS
SELECT
    RoleName,
    Description,
    TaskMask
FROM
    Roles
WHERE
    (@RoleFlags is NULL) OR
    (RoleFlags = @RoleFlags)

GO
/****** Object:  StoredProcedure [dbo].[GetSchedulesReports]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetSchedulesReports] 
@ID uniqueidentifier
AS

select 
    C.Path
from
    ReportSchedule RS inner join Catalog C on (C.ItemID = RS.ReportID)
where
    ScheduleID = @ID

GO
/****** Object:  StoredProcedure [dbo].[GetServerParameters]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetServerParameters]
@ServerParametersID nvarchar(32)
AS
DECLARE @now as DATETIME
SET @now = GETDATE()
SELECT Child.Path, Child.ParametersValues, Parent.ParametersValues
FROM [dbo].[ServerParametersInstance] Child
LEFT OUTER JOIN [dbo].[ServerParametersInstance] Parent
ON Child.ParentID = Parent.ServerParametersID
WHERE Child.ServerParametersID = @ServerParametersID 
AND Child.Expiration > @now

GO
/****** Object:  StoredProcedure [dbo].[GetSessionData]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Get record from session data, update session and snapshot
CREATE PROCEDURE [dbo].[GetSessionData]
@SessionID as varchar(32),
@OwnerSid as varbinary(85) = NULL,
@OwnerName as nvarchar(260),
@AuthType as int,
@SnapshotTimeoutMinutes as int
AS

DECLARE @ExpirationDate as datetime
DECLARE @now as datetime
SET @now = GETDATE()

DECLARE @DBSessionID varchar(32)
DECLARE @SnapshotDataID uniqueidentifier
DECLARE @IsPermanentSnapshot bit
DECLARE @LockVersion int

EXEC CheckSessionLock @SessionID, @LockVersion OUTPUT

DECLARE @ActualOwnerID uniqueidentifier 
DECLARE @OwnerID uniqueidentifier
EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT

SELECT
    @DBSessionID = SE.SessionID,
    @SnapshotDataID = SE.SnapshotDataID,
    @IsPermanentSnapshot = SE.IsPermanentSnapshot,
    @ActualOwnerID = SE.OwnerID,
    @ExpirationDate = SE.Expiration
    
FROM
    dbo.ReportServerTempDB_SessionData AS SE WITH (XLOCK)
WHERE
    SE.SessionID = @SessionID
    
IF (@DBSessionID IS NULL)
RAISERROR ('Invalid or Expired Session: %s', 16, 1, @SessionID)

IF (@ActualOwnerID <> @OwnerID)
RAISERROR ('Session %s does not belong to %s', 16, 1, @SessionID, @OwnerName)

IF (@ExpirationDate <= @now)
RAISERROR ('Expired Session: %s', 16, 1, @SessionID)

IF @IsPermanentSnapshot != 0 BEGIN -- If session has snapshot and it is permanent

SELECT
    SN.SnapshotDataID,
    SE.ShowHideInfo,
    SE.DataSourceInfo,
    SN.Description,
    SE.EffectiveParams,
    SN.CreatedDate,
    SE.IsPermanentSnapshot,
    SE.CreationTime,
    SE.HasInteractivity,
    SE.Timeout,
    SE.SnapshotExpirationDate,
    SE.ReportPath,
    SE.HistoryDate,
    SE.CompiledDefinition,
    SN.PageCount,
    SN.HasDocMap,
    SE.Expiration,
    SN.EffectiveParams,
    SE.PageHeight,
    SE.PageWidth,
    SE.TopMargin,
    SE.BottomMargin,
    SE.LeftMargin,
    SE.RightMargin,
    SE.AutoRefreshSeconds,
    SE.AwaitingFirstExecution,
    SN.[DependsOnUser], 
	SN.PaginationMode, 
	SN.ProcessingFlags, 
	NULL, -- No compiled definition in tempdb to get flags from
	CONVERT(BIT, 0) AS [FoundInCache], -- permanent snapshot is never from Cache
	SE.SitePath,
	SE.SiteZone,
	SE.DataSetInfo,
	SE.ReportDefinitionPath,
	@LockVersion
FROM
    dbo.ReportServerTempDB_SessionData AS SE
    INNER JOIN SnapshotData AS SN ON SN.SnapshotDataID = SE.SnapshotDataID
WHERE
   SE.SessionID = @DBSessionID

UPDATE SnapshotData
SET ExpirationDate = DATEADD(n, @SnapshotTimeoutMinutes, @now)
WHERE SnapshotDataID = @SnapshotDataID

END ELSE IF @IsPermanentSnapshot = 0 BEGIN -- If session has snapshot and it is temporary

SELECT
    SN.SnapshotDataID,
    SE.ShowHideInfo,
    SE.DataSourceInfo,
    SN.Description,
    SE.EffectiveParams,
    SN.CreatedDate,
    SE.IsPermanentSnapshot,
    SE.CreationTime,
    SE.HasInteractivity,
    SE.Timeout,
    SE.SnapshotExpirationDate,
    SE.ReportPath,
    SE.HistoryDate,
    SE.CompiledDefinition,
    SN.PageCount,
    SN.HasDocMap,
    SE.Expiration,
    SN.EffectiveParams,
    SE.PageHeight,
    SE.PageWidth,
    SE.TopMargin,
    SE.BottomMargin,
    SE.LeftMargin,
    SE.RightMargin,
    SE.AutoRefreshSeconds,
    SE.AwaitingFirstExecution,
    SN.[DependsOnUser], 
    SN.PaginationMode, 
    SN.ProcessingFlags, 
    COMP.ProcessingFlags,

   
    -- If we are AwaitingFirstExecution, then we haven't executed a 
    -- report and therefore have not been bound to a cached snapshot 
    -- because that binding only happens at report execution time.
    CASE SE.AwaitingFirstExecution WHEN 1 THEN CONVERT(BIT, 0) ELSE SN.IsCached END,
    SE.SitePath,
    SE.SiteZone,
    SE.DataSetInfo,
    SE.ReportDefinitionPath,
    @LockVersion
FROM
    dbo.ReportServerTempDB_SessionData AS SE
    INNER JOIN dbo.ReportServerTempDB_SnapshotData AS SN ON SN.SnapshotDataID = SE.SnapshotDataID  
    LEFT OUTER JOIN dbo.ReportServerTempDB_SnapshotData AS COMP ON SE.CompiledDefinition = COMP.SnapshotDataID      
WHERE
   SE.SessionID = @DBSessionID
   
UPDATE dbo.ReportServerTempDB_SnapshotData
SET ExpirationDate = DATEADD(n, @SnapshotTimeoutMinutes, @now)
WHERE SnapshotDataID = @SnapshotDataID

END ELSE BEGIN -- If session doesn't have snapshot

SELECT
    null,
    SE.ShowHideInfo,
    SE.DataSourceInfo,
    null,
    SE.EffectiveParams,
    null,
    SE.IsPermanentSnapshot,
    SE.CreationTime,
    SE.HasInteractivity,
    SE.Timeout,
    SE.SnapshotExpirationDate,
    SE.ReportPath,
    SE.HistoryDate,
    SE.CompiledDefinition,
    null,
    null,
    SE.Expiration,
    null,
    SE.PageHeight,
    SE.PageWidth,
    SE.TopMargin,
    SE.BottomMargin,
    SE.LeftMargin,
    SE.RightMargin,
    SE.AutoRefreshSeconds,
    SE.AwaitingFirstExecution,
    null, 
    null, 
    null, 
    COMP.ProcessingFlags,
    CONVERT(BIT, 0) AS [FoundInCache], -- no snapshot, so it can't be from the cache
    SE.SitePath,
    SE.SiteZone,
    SE.DataSetInfo,
    SE.ReportDefinitionPath,
    @LockVersion
FROM
    dbo.ReportServerTempDB_SessionData AS SE
    LEFT OUTER JOIN dbo.ReportServerTempDB_SnapshotData AS COMP ON (SE.CompiledDefinition = COMP.SnapshotDataID)
WHERE
   SE.SessionID = @DBSessionID

END


-- We need this update to keep session around while we process it.
UPDATE
   SE 
SET
   Expiration = DATEADD(s, Timeout, GetDate())
FROM
   dbo.ReportServerTempDB_SessionData AS SE
WHERE
   SE.SessionID = @DBSessionID

GO
/****** Object:  StoredProcedure [dbo].[GetSharePointPathsForUpgrade]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetSharePointPathsForUpgrade]
AS
BEGIN
SELECT DISTINCT SUBSTRING([Path], 1, LEN([Path])-LEN([Name]) - 1) as Prefix, LEN([Path])-LEN([Name]) as PrefixLen
  FROM [Catalog]
  WHERE LEN([Path]) > 0 AND [Path] NOT LIKE '/{%'
  ORDER BY PrefixLen DESC
END

GO
/****** Object:  StoredProcedure [dbo].[GetSharePointSchedulePathsForUpgrade]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetSharePointSchedulePathsForUpgrade]
AS
BEGIN
SELECT DISTINCT [Path], LEN([Path])
  FROM [Schedule]
  WHERE [Path] IS NOT NULL AND [Path] NOT LIKE '/{%'
  ORDER BY LEN([Path]) DESC
END

GO
/****** Object:  StoredProcedure [dbo].[GetSnapshotChunks]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetSnapshotChunks]
@SnapshotDataID uniqueidentifier,
@IsPermanentSnapshot bit
AS

IF @IsPermanentSnapshot != 0 BEGIN

SELECT ChunkName, ChunkType, ChunkFlags, MimeType, Version, datalength(Content)
FROM ChunkData
WHERE   
    SnapshotDataID = @SnapshotDataID
    
END ELSE BEGIN

SELECT ChunkName, ChunkType, ChunkFlags, MimeType, Version, datalength(Content)
FROM dbo.ReportServerTempDB_ChunkData
WHERE   
    SnapshotDataID = @SnapshotDataID
END    

GO
/****** Object:  StoredProcedure [dbo].[GetSnapshotFromHistory]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetSnapshotFromHistory]
@Path nvarchar (425),
@SnapshotDate datetime,
@AuthType int
AS
SELECT
   Catalog.ItemID,
   Catalog.Type,
   SnapshotData.SnapshotDataID, 
   SnapshotData.DependsOnUser,
   SnapshotData.Description,
   SecData.NtSecDescPrimary,
   Catalog.[Property], 
   SnapshotData.ProcessingFlags
FROM 
   SnapshotData 
   INNER JOIN History ON History.SnapshotDataID = SnapshotData.SnapshotDataID
   INNER JOIN Catalog ON History.ReportID = Catalog.ItemID
   LEFT OUTER JOIN SecData ON Catalog.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
WHERE 
   Catalog.Path = @Path 
   AND History.SnapshotDate = @SnapshotDate

GO
/****** Object:  StoredProcedure [dbo].[GetSnapshotPromotedInfo]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetSnapshotPromotedInfo]
@SnapshotDataID as uniqueidentifier,
@IsPermanentSnapshot as bit
AS

-- We don't want to hold shared locks if even if we are in a repeatable
-- read transaction, so explicitly use READCOMMITTED lock hint
IF @IsPermanentSnapshot = 1
BEGIN
   SELECT PageCount, HasDocMap, PaginationMode, ProcessingFlags
   FROM SnapshotData WITH (READCOMMITTED)
   WHERE SnapshotDataID = @SnapshotDataID
END ELSE BEGIN
   SELECT PageCount, HasDocMap, PaginationMode, ProcessingFlags
   FROM dbo.ReportServerTempDB_SnapshotData WITH (READCOMMITTED)
   WHERE SnapshotDataID = @SnapshotDataID
END      

GO
/****** Object:  StoredProcedure [dbo].[GetSnapShotSchedule]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetSnapShotSchedule] 
@ReportID uniqueidentifier
AS

select
    S.[ScheduleID],
    S.[Name],
    S.[StartDate], 
    S.[Flags],
    S.[NextRunTime],
    S.[LastRunTime], 
    S.[EndDate], 
    S.[RecurrenceType],
    S.[MinutesInterval],
    S.[DaysInterval],
    S.[WeeksInterval],
    S.[DaysOfWeek], 
    S.[DaysOfMonth], 
    S.[Month], 
    S.[MonthlyWeek], 
    S.[State], 
    S.[LastRunStatus],
    S.[ScheduledRunTimeout],
    S.[EventType],
    S.[EventData],
    S.[Type],
    S.[Path],
    SUSER_SNAME(Owner.[Sid]),
    Owner.[UserName],
    Owner.[AuthType]
from
    Schedule S with (XLOCK) inner join ReportSchedule RS on S.ScheduleID = RS.ScheduleID
    inner join [Users] Owner on S.[CreatedById] = Owner.[UserID]
where
    RS.ReportAction = 2 and -- 2 == create snapshot
    RS.ReportID = @ReportID

GO
/****** Object:  StoredProcedure [dbo].[GetSubscription]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetSubscription]
@SubscriptionID uniqueidentifier
AS

-- Grab all of the-- subscription properties given a id 
select 
        S.[SubscriptionID],
        S.[Report_OID],
        S.[ReportZone],
        S.[Locale],
        S.[InactiveFlags],
        S.[DeliveryExtension], 
        S.[ExtensionSettings],
        SUSER_SNAME(Modified.[Sid]), 
        Modified.[UserName],
        S.[ModifiedDate], 
        S.[Description],
        S.[LastStatus],
        S.[EventType],
        S.[MatchData],
        S.[Parameters],
        S.[DataSettings],
        A.[TotalNotifications],
        A.[TotalSuccesses],
        A.[TotalFailures],
        SUSER_SNAME(Owner.[Sid]),
        Owner.[UserName],
        CAT.[Path],
        S.[LastRunTime],
        CAT.[Type],
        SD.NtSecDescPrimary,
        S.[Version],
        Owner.[AuthType]
from
    [Subscriptions] S inner join [Catalog] CAT on S.[Report_OID] = CAT.[ItemID]
    inner join [Users] Owner on S.OwnerID = Owner.UserID
    inner join [Users] Modified on S.ModifiedByID = Modified.UserID
    left outer join [SecData] SD on CAT.PolicyID = SD.PolicyID AND SD.AuthType = Owner.AuthType
    left outer join (select top(1) * from [ActiveSubscriptions] with(NOLOCK) where [SubscriptionID] = @SubscriptionID) A on S.[SubscriptionID] = A.[SubscriptionID]
where
    S.[SubscriptionID] = @SubscriptionID

GO
/****** Object:  StoredProcedure [dbo].[GetSubscriptionInfoForReencryption]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetSubscriptionInfoForReencryption]
@SubscriptionID as uniqueidentifier
AS

SELECT [DeliveryExtension], [ExtensionSettings], [Version]
FROM [dbo].[Subscriptions]
WHERE [SubscriptionID] = @SubscriptionID

GO
/****** Object:  StoredProcedure [dbo].[GetSubscriptionsForUpgrade]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetSubscriptionsForUpgrade]
@CurrentVersion int
AS
SELECT 
    [SubscriptionID]
FROM 
    [Subscriptions]
WHERE
    [Version] != @CurrentVersion

GO
/****** Object:  StoredProcedure [dbo].[GetSystemPolicy]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetSystemPolicy]
@AuthType int
AS 
SELECT SecData.NtSecDescPrimary, SecData.XmlDescription
FROM Policies 
LEFT OUTER JOIN SecData ON Policies.PolicyID = SecData.PolicyID AND AuthType = @AuthType
WHERE PolicyFlag = 1

GO
/****** Object:  StoredProcedure [dbo].[GetTaskProperties]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetTaskProperties]
@ScheduleID uniqueidentifier
AS
-- Grab all of a tasks properties given a task id
select 
        S.[ScheduleID],
        S.[Name],
        S.[StartDate], 
        S.[Flags],
        S.[NextRunTime],
        S.[LastRunTime], 
        S.[EndDate], 
        S.[RecurrenceType],
        S.[MinutesInterval],
        S.[DaysInterval],
        S.[WeeksInterval],
        S.[DaysOfWeek], 
        S.[DaysOfMonth], 
        S.[Month], 
        S.[MonthlyWeek], 
        S.[State], 
        S.[LastRunStatus],
        S.[ScheduledRunTimeout],
        S.[EventType],
        S.[EventData],
        S.[Type],
        S.[Path],
        SUSER_SNAME(Owner.[Sid]),
        Owner.[UserName],
        Owner.[AuthType]
from
    [Schedule] S with (XLOCK) 
    Inner join [Users] Owner on S.[CreatedById] = Owner.UserID
where
    S.[ScheduleID] = @ScheduleID

GO
/****** Object:  StoredProcedure [dbo].[GetTimeBasedSubscriptionReportAction]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetTimeBasedSubscriptionReportAction]
@SubscriptionID uniqueidentifier
AS
select 
        RS.[ReportAction],
        RS.[ScheduleID],
        RS.[ReportID],
        RS.[SubscriptionID],
        C.[Path],
        C.[Type]
from
    [ReportSchedule] RS Inner join [Catalog] C on RS.[ReportID] = C.[ItemID]
where
    RS.[SubscriptionID] = @SubscriptionID

GO
/****** Object:  StoredProcedure [dbo].[GetTimeBasedSubscriptionSchedule]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetTimeBasedSubscriptionSchedule]
@SubscriptionID as uniqueidentifier
AS

select
    S.[ScheduleID],
    S.[Name],
    S.[StartDate], 
    S.[Flags],
    S.[NextRunTime],
    S.[LastRunTime], 
    S.[EndDate], 
    S.[RecurrenceType],
    S.[MinutesInterval], 
    S.[DaysInterval],
    S.[WeeksInterval],
    S.[DaysOfWeek], 
    S.[DaysOfMonth], 
    S.[Month], 
    S.[MonthlyWeek], 
    S.[State], 
    S.[LastRunStatus],
    S.[ScheduledRunTimeout],
    S.[EventType],
    S.[EventData],
    S.[Type],
    S.[Path],
    SUSER_SNAME(Owner.[Sid]),
    Owner.[UserName],
    Owner.[AuthType]
from
    [ReportSchedule] R inner join Schedule S with (XLOCK) on R.[ScheduleID] = S.[ScheduleID]
    Inner join [Users] Owner on S.[CreatedById] = Owner.UserID
where
    R.[SubscriptionID] = @SubscriptionID

GO
/****** Object:  StoredProcedure [dbo].[GetUpgradeItems]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetUpgradeItems]
AS
SELECT 
    [Item],
    [Status]
FROM 
    [UpgradeInfo]

GO
/****** Object:  StoredProcedure [dbo].[GetUserID]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- looks up any user name, if not it creates a regular user - uses Sid
CREATE PROCEDURE [dbo].[GetUserID]
@UserSid varbinary(85) = NULL,
@UserName nvarchar(260),
@AuthType int,
@UserID uniqueidentifier OUTPUT
AS
    IF @AuthType = 1 -- Windows
    BEGIN
        EXEC GetUserIDBySid @UserSid, @UserName, @AuthType, @UserID OUTPUT
    END
    ELSE
    BEGIN
        EXEC GetUserIDByName @UserName, @AuthType, @UserID OUTPUT
    END

GO
/****** Object:  StoredProcedure [dbo].[GetUserIDByName]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- looks up any user name by its User Name, if not it creates a regular user
CREATE PROCEDURE [dbo].[GetUserIDByName]
@UserName nvarchar(260),
@AuthType int,
@UserID uniqueidentifier OUTPUT
AS
SELECT @UserID = (SELECT UserID FROM Users WHERE UserName = @UserName AND AuthType = @AuthType)
IF @UserID IS NULL
   BEGIN
      SET @UserID = newid()
      INSERT INTO Users
      (UserID, Sid, UserType, AuthType, UserName)
      VALUES 
      (@UserID, NULL, 0,    @AuthType, @UserName)
   END 

GO
/****** Object:  StoredProcedure [dbo].[GetUserIDBySid]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- looks up any user name by its SID, if not it creates a regular user
CREATE PROCEDURE [dbo].[GetUserIDBySid]
@UserSid varbinary(85),
@UserName nvarchar(260),
@AuthType int,
@UserID uniqueidentifier OUTPUT
AS
SELECT @UserID = (SELECT UserID FROM Users WHERE Sid = @UserSid AND AuthType = @AuthType)
IF @UserID IS NULL
   BEGIN
      SET @UserID = newid()
      INSERT INTO Users
      (UserID, Sid, UserType, AuthType, UserName)
      VALUES 
      (@UserID, @UserSid, 0, @AuthType, @UserName)
   END 

GO
/****** Object:  StoredProcedure [dbo].[GetUserServiceToken]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetUserServiceToken]
@UserSid as varbinary(85) = NULL, 
@UserName as nvarchar(260) = NULL,
@AuthType int
AS
BEGIN

DECLARE @UserID uniqueidentifier
EXEC GetUserID @UserSid, @UserName, @AuthType, @UserID OUTPUT

if (@UserID is not null)
	BEGIN
		SELECT ServiceToken FROM Users WHERE UserId = @UserID
	END
END

GO
/****** Object:  StoredProcedure [dbo].[GetUserSettings]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetUserSettings]
@UserSid as varbinary(85) = NULL, 
@UserName as nvarchar(260) = NULL,
@AuthType int
AS
BEGIN

DECLARE @UserID uniqueidentifier
EXEC GetUserID @UserSid, @UserName, @AuthType, @UserID OUTPUT

if (@UserID is not null)
	BEGIN
		SELECT Setting FROM Users WHERE UserId = @UserID
	END
END

GO
/****** Object:  StoredProcedure [dbo].[IncreaseTransientSnapshotRefcount]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IncreaseTransientSnapshotRefcount]
@SnapshotDataID as uniqueidentifier,
@IsPermanentSnapshot as bit,
@ExpirationMinutes as int
AS
SET NOCOUNT OFF
DECLARE @soon AS datetime
SET @soon = DATEADD(n, @ExpirationMinutes, GETDATE())

if @IsPermanentSnapshot = 1
BEGIN
   UPDATE SnapshotData
   SET ExpirationDate = @soon, TransientRefcount = TransientRefcount + 1
   WHERE SnapshotDataID = @SnapshotDataID
END ELSE BEGIN
   UPDATE dbo.ReportServerTempDB_SnapshotData
   SET ExpirationDate = @soon, TransientRefcount = TransientRefcount + 1
   WHERE SnapshotDataID = @SnapshotDataID
END

GO
/****** Object:  StoredProcedure [dbo].[InsertUnreferencedSnapshot]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertUnreferencedSnapshot]
@ReportID as uniqueidentifier = NULL,
@EffectiveParams as ntext = NULL,
@QueryParams as ntext = NULL,
@ParamsHash as int = NULL,
@CreatedDate as datetime,
@Description as nvarchar(512) = NULL,
@SnapshotDataID as uniqueidentifier,
@IsPermanentSnapshot as bit,
@ProcessingFlags as int,
@SnapshotTimeoutMinutes as int,
@Machine as nvarchar(512) = NULL
AS
DECLARE @now datetime
SET @now = GETDATE()

IF @IsPermanentSnapshot = 1
BEGIN
   INSERT INTO SnapshotData
      (SnapshotDataID, CreatedDate, EffectiveParams, QueryParams, ParamsHash, Description, PermanentRefcount, TransientRefcount, ExpirationDate, ProcessingFlags)
   VALUES
      (@SnapshotDataID, @CreatedDate, @EffectiveParams, @QueryParams, @ParamsHash, @Description, 0, 1, DATEADD(n, @SnapshotTimeoutMinutes, @now), @ProcessingFlags)
END ELSE BEGIN
   INSERT INTO dbo.ReportServerTempDB_SnapshotData
      (SnapshotDataID, CreatedDate, EffectiveParams, QueryParams, ParamsHash, Description, PermanentRefcount, TransientRefcount, ExpirationDate, Machine, ProcessingFlags)
   VALUES
      (@SnapshotDataID, @CreatedDate, @EffectiveParams, @QueryParams, @ParamsHash, @Description, 0, 1, DATEADD(n, @SnapshotTimeoutMinutes, @now), @Machine, @ProcessingFlags)
END      

GO
/****** Object:  StoredProcedure [dbo].[InvalidateSubscription]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InvalidateSubscription] 
@SubscriptionID uniqueidentifier,
@Flags int,
@LastStatus nvarchar(260)
AS

-- Mark all subscriptions for this report as inactive for the given flags
update 
    Subscriptions 
set 
    [InactiveFlags] = S.[InactiveFlags] | @Flags,
    [LastStatus] = @LastStatus
from 
    Subscriptions S 
where 
    SubscriptionID = @SubscriptionID

GO
/****** Object:  StoredProcedure [dbo].[IsSegmentedChunk]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[IsSegmentedChunk]
	@SnapshotId			uniqueidentifier,
	@IsPermanent		bit, 
	@ChunkName			nvarchar(260), 
	@ChunkType			int, 
	@IsSegmented		bit out
as begin
	-- segmented chunks are read w/nolock
	-- we don't really care about locking in this scenario
	-- we just need to get some metadata which never changes (if it is segmented or not)
	if (@IsPermanent = 1) begin
		select top 1 @IsSegmented = IsSegmented
		from 
		(
			select convert(bit, 0)
			from [ChunkData] c
			where c.ChunkName = @ChunkName and c.ChunkType = @ChunkType and c.SnapshotDataId = @SnapshotId
			union all
			select convert(bit, 1)
			from [SegmentedChunk] c WITH(NOLOCK)			
			where c.ChunkName = @ChunkName and c.ChunkType = @ChunkType and c.SnapshotDataId = @SnapshotId
		) A(IsSegmented)
	end
	else begin
		select top 1 @IsSegmented = IsSegmented
		from 
		(
			select convert(bit, 0)
			from dbo.ReportServerTempDB_[ChunkData] c
			where c.ChunkName = @ChunkName and c.ChunkType = @ChunkType and c.SnapshotDataId = @SnapshotId
			union all
			select convert(bit, 1)
			from dbo.ReportServerTempDB_[SegmentedChunk] c WITH(NOLOCK)
			where c.ChunkName = @ChunkName and c.ChunkType = @ChunkType and c.SnapshotDataId = @SnapshotId
		) A(IsSegmented)
	end
end

GO
/****** Object:  StoredProcedure [dbo].[ListHistory]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- list all historical snapshots for a specific report
CREATE PROCEDURE [dbo].[ListHistory]
@ReportID uniqueidentifier
AS
SELECT
   S.SnapshotDate,
   ISNULL((SELECT SUM(DATALENGTH( CD.Content ) ) FROM ChunkData AS CD WHERE CD.SnapshotDataID = S.SnapshotDataID ), 0) + 
   ISNULL(
	(
	 SELECT SUM(DATALENGTH( SEG.Content) ) 	
	 FROM Segment SEG WITH(NOLOCK)
	 JOIN ChunkSegmentMapping CSM WITH(NOLOCK) ON (CSM.SegmentId = SEG.SegmentId)
	 JOIN SegmentedChunk C WITH(NOLOCK) ON (C.ChunkId = CSM.ChunkId AND C.SnapshotDataId = S.SnapshotDataId)
	), 0)	
FROM
   History AS S -- skipping intermediate table SnapshotData
WHERE
   S.ReportID = @ReportID

GO
/****** Object:  StoredProcedure [dbo].[ListInfoForReencryption]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ListInfoForReencryption]
AS

SELECT [DSID]
FROM [dbo].[DataSource] WITH (XLOCK, TABLOCK)

SELECT [SubscriptionID]
FROM [dbo].[Subscriptions] WITH (XLOCK, TABLOCK)

SELECT [InstallationID], [PublicKey]
FROM [dbo].[Keys] WITH (XLOCK, TABLOCK)
WHERE [Client] = 1 AND ([SymmetricKey] IS NOT NULL)

GO
/****** Object:  StoredProcedure [dbo].[ListInstallations]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ListInstallations]
AS

SELECT
    [MachineName],
    [InstanceName],
    [InstallationID],
    CASE WHEN [SymmetricKey] IS null THEN 0 ELSE 1 END
FROM [dbo].[Keys]
WHERE [Client] = 1

GO
/****** Object:  StoredProcedure [dbo].[ListRunningJobs]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ListRunningJobs]
AS
SELECT JobID, StartDate, ComputerName, RequestName, RequestPath, SUSER_SNAME(Users.[Sid]), Users.[UserName], Description, 
    Timeout, JobAction, JobType, JobStatus, Users.[AuthType]
FROM RunningJobs 
INNER JOIN Users 
ON RunningJobs.UserID = Users.UserID

GO
/****** Object:  StoredProcedure [dbo].[ListScheduledReports]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ListScheduledReports]
@ScheduleID uniqueidentifier
AS
-- List all reports for a schedule
select 
        RS.[ReportAction],
        RS.[ScheduleID],
        RS.[ReportID],
        RS.[SubscriptionID],
        C.[Path],
        C.[Type],
        C.[Name],
        C.[Description],
        C.[ModifiedDate],
        SUSER_SNAME(U.[Sid]),
        U.[UserName],
        DATALENGTH( C.Content ),
        C.ExecutionTime,
        S.[Type],
        SD.[NtSecDescPrimary],
        SU.[ReportZone]

from
    [ReportSchedule] RS Inner join [Catalog] C on RS.[ReportID] = C.[ItemID]
    Inner join [Schedule] S on RS.[ScheduleID] = S.[ScheduleID]
    Inner join [Users] U on C.[ModifiedByID] = U.UserID
    left outer join [SecData] SD on SD.[PolicyID] = C.[PolicyID] AND SD.AuthType = U.AuthType    
    left outer join [Subscriptions] SU on SU.[SubscriptionID] = RS.[SubscriptionID]
where
    RS.[ScheduleID] = @ScheduleID 

GO
/****** Object:  StoredProcedure [dbo].[ListSubscriptionIDs]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ListSubscriptionIDs]
AS

SELECT [SubscriptionID]
FROM [dbo].[Subscriptions] WITH (XLOCK, TABLOCK)

GO
/****** Object:  StoredProcedure [dbo].[ListSubscriptionsUsingDataSource]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ListSubscriptionsUsingDataSource]
@DataSourceName nvarchar(450)
AS
select 
    S.[SubscriptionID],
    S.[Report_OID],
    S.[ReportZone],
    S.[Locale],
    S.[InactiveFlags],
    S.[DeliveryExtension], 
    S.[ExtensionSettings],
    SUSER_SNAME(Modified.[Sid]),
    Modified.[UserName],
    S.[ModifiedDate], 
    S.[Description],
    S.[LastStatus],
    S.[EventType],
    S.[MatchData],
    S.[Parameters],
    S.[DataSettings],
    A.[TotalNotifications],
    A.[TotalSuccesses],
    A.[TotalFailures],
    SUSER_SNAME(Owner.[Sid]),
    Owner.[UserName],
    CAT.[Path],
    S.[LastRunTime],
    CAT.[Type],
    SD.NtSecDescPrimary,
    S.[Version],
    Owner.[AuthType]
from
    [DataSource] DS inner join Catalog C on C.ItemID = DS.Link
    inner join Subscriptions S on S.[SubscriptionID] = DS.[SubscriptionID]
    inner join [Catalog] CAT on S.[Report_OID] = CAT.[ItemID]
    inner join [Users] Owner on S.OwnerID = Owner.UserID
    inner join [Users] Modified on S.ModifiedByID = Modified.UserID
    left join [SecData] SD on SD.[PolicyID] = CAT.[PolicyID] AND SD.AuthType = Owner.AuthType
    left outer join [ActiveSubscriptions] A with (NOLOCK) on S.[SubscriptionID] = A.[SubscriptionID]
where 
    C.Path = @DataSourceName 

GO
/****** Object:  StoredProcedure [dbo].[ListTasks]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ListTasks]
@Path nvarchar (425) = NULL,
@Prefix nvarchar (425) = NULL
AS

select 
        S.[ScheduleID],
        S.[Name],
        S.[StartDate],
        S.[Flags],
        S.[NextRunTime],
        S.[LastRunTime],
        S.[EndDate],
        S.[RecurrenceType],
        S.[MinutesInterval],
        S.[DaysInterval],
        S.[WeeksInterval],
        S.[DaysOfWeek],
        S.[DaysOfMonth],
        S.[Month],
        S.[MonthlyWeek],
        S.[State], 
        S.[LastRunStatus],
        S.[ScheduledRunTimeout],
        S.[EventType],
        S.[EventData],
        S.[Type],
        S.[Path],
        SUSER_SNAME(Owner.[Sid]),
        Owner.[UserName],
        Owner.[AuthType],
        (select count(*) from ReportSchedule where ReportSchedule.ScheduleID = S.ScheduleID)
from
    [Schedule] S  inner join [Users] Owner on S.[CreatedById] = Owner.UserID
where
    S.[Type] = 0 /*Type 0 is shared schedules*/ and
    ((@Path is null) OR (S.Path = @Path) or (S.Path like @Prefix escape '*'))

GO
/****** Object:  StoredProcedure [dbo].[ListTasksForMaintenance]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ListTasksForMaintenance]
AS

declare @date datetime
set @date = GETUTCDATE()

update
    [Schedule]
set
    [ConsistancyCheck] = @date
from 
(
  SELECT TOP 20 [ScheduleID] FROM [Schedule] WITH(UPDLOCK) WHERE [ConsistancyCheck] is NULL
) AS t1
WHERE [Schedule].[ScheduleID] = t1.[ScheduleID]

select top 20
        S.[ScheduleID],
        S.[Name],
        S.[StartDate],
        S.[Flags],
        S.[NextRunTime],
        S.[LastRunTime],
        S.[EndDate],
        S.[RecurrenceType],
        S.[MinutesInterval],
        S.[DaysInterval],
        S.[WeeksInterval],
        S.[DaysOfWeek],
        S.[DaysOfMonth],
        S.[Month],
        S.[MonthlyWeek],
        S.[State], 
        S.[LastRunStatus],
        S.[ScheduledRunTimeout],
        S.[EventType],
        S.[EventData],
        S.[Type],
        S.[Path]
from
    [Schedule] S
where
    [ConsistancyCheck] = @date

GO
/****** Object:  StoredProcedure [dbo].[ListUsedDeliveryProviders]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ListUsedDeliveryProviders] 
AS
select distinct [DeliveryExtension] from Subscriptions where [DeliveryExtension] <> ''

GO
/****** Object:  StoredProcedure [dbo].[LoadForDefinitionCheck]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- For loading compiled definitions to check for internal republishing, this is
-- done before calling GetCompiledDefinition or GetReportForExecution
CREATE PROCEDURE [dbo].[LoadForDefinitionCheck]
@Path					nvarchar(425), 
@AcquireUpdateLocks	bit,
@AuthType				int
AS
IF(@AcquireUpdateLocks = 0) BEGIN
SELECT 
		CompiledDefinition.SnapshotDataID,
		CompiledDefinition.ProcessingFlags,
		SecData.NtSecDescPrimary
	FROM Catalog MainItem
	LEFT OUTER JOIN SecData ON (MainItem.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType)
	LEFT OUTER JOIN Catalog LinkTarget WITH (INDEX = PK_CATALOG) ON (MainItem.LinkSourceID = LinkTarget.ItemID)
	JOIN SnapshotData CompiledDefinition ON (CompiledDefinition.SnapshotDataID = COALESCE(LinkTarget.Intermediate, MainItem.Intermediate))	
	WHERE MainItem.Path = @Path AND (MainItem.Type = 2 /* Report */ OR MainItem.Type = 4 /* Linked Report */)  
END
ELSE BEGIN
	-- acquire upgrade locks, this means that the check is being perform in a 
	-- different transaction context which will be committed before trying to 
	-- perform the actual load, to prevent deadlock in the case where we have to 
	-- republish this new transaction will acquire and hold upgrade locks
SELECT 
		CompiledDefinition.SnapshotDataID,
		CompiledDefinition.ProcessingFlags,
		SecData.NtSecDescPrimary
	FROM Catalog MainItem WITH(UPDLOCK ROWLOCK)
	LEFT OUTER JOIN SecData ON (MainItem.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType)
	LEFT OUTER JOIN Catalog LinkTarget WITH (UPDLOCK ROWLOCK INDEX = PK_CATALOG) ON (MainItem.LinkSourceID = LinkTarget.ItemID)
	JOIN SnapshotData CompiledDefinition WITH(UPDLOCK ROWLOCK) ON (CompiledDefinition.SnapshotDataID = COALESCE(LinkTarget.Intermediate, MainItem.Intermediate))	
	WHERE MainItem.Path = @Path AND (MainItem.Type = 2 /* Report */ OR MainItem.Type = 4 /* Linked Report */)  
END

GO
/****** Object:  StoredProcedure [dbo].[LoadForRepublishing]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Loads a report's RDL for republishing
CREATE PROCEDURE [dbo].[LoadForRepublishing]
@Path		nvarchar(425)
AS
SELECT 
	COALESCE(LinkTarget.Content, MainItem.Content) AS [Content], 
	CompiledDefinition.SnapshotDataID, 
	CompiledDefinition.ProcessingFlags
FROM Catalog MainItem
LEFT OUTER JOIN Catalog LinkTarget WITH (INDEX = PK_CATALOG) ON (MainItem.LinkSourceID = LinkTarget.ItemID)
JOIN SnapshotData CompiledDefinition ON (CompiledDefinition.SnapshotDataID = COALESCE(LinkTarget.Intermediate, MainItem.Intermediate))
WHERE MainItem.Path = @Path

GO
/****** Object:  StoredProcedure [dbo].[LockPersistedStream]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[LockPersistedStream]
@SessionID varchar(32),
@Index int
AS

SELECT [Index] FROM dbo.ReportServerTempDB_PersistedStream WITH (XLOCK) WHERE SessionID = @SessionID AND [Index] = @Index

GO
/****** Object:  StoredProcedure [dbo].[LockSnapshotForUpgrade]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[LockSnapshotForUpgrade]
@SnapshotDataID as uniqueidentifier,
@IsPermanentSnapshot as bit
AS
if @IsPermanentSnapshot = 1
BEGIN
   SELECT ChunkName from ChunkData with (XLOCK)
   WHERE SnapshotDataID = @SnapshotDataID
END ELSE BEGIN
   SELECT ChunkName from dbo.ReportServerTempDB_ChunkData with (XLOCK)
   WHERE SnapshotDataID = @SnapshotDataID
END

GO
/****** Object:  StoredProcedure [dbo].[MarkSnapshotAsDependentOnUser]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[MarkSnapshotAsDependentOnUser]
@SnapshotDataID as uniqueidentifier,
@IsPermanentSnapshot as bit
AS
SET NOCOUNT OFF
if @IsPermanentSnapshot = 1
BEGIN
   UPDATE SnapshotData
   SET DependsOnUser = 1
   WHERE SnapshotDataID = @SnapshotDataID
END ELSE BEGIN
   UPDATE dbo.ReportServerTempDB_SnapshotData
   SET DependsOnUser = 1
   WHERE SnapshotDataID = @SnapshotDataID
END

GO
/****** Object:  StoredProcedure [dbo].[MigrateExecutionLog]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[MigrateExecutionLog] @updatedRow int output
as
begin
	set @updatedRow = 0 ;
    if exists (select id from dbo.sysobjects where id = object_id(N'[dbo].[ExecutionLog_Old]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
    begin
        SET DEADLOCK_PRIORITY LOW ;
        SET NOCOUNT OFF ;
        
        insert into [dbo].[ExecutionLogStorage]
            ([InstanceName],
             [ReportID],
             [UserName],
             [ExecutionId],
             [RequestType],
             [Format],
             [Parameters],
             [ReportAction],
             [TimeStart],
             [TimeEnd],
             [TimeDataRetrieval],
             [TimeProcessing],
             [TimeRendering],
             [Source],
             [Status],
             [ByteCount],
             [RowCount],
             [AdditionalInfo])
        select top (1024) with ties
            [InstanceName],
            [ReportID],
            [UserName],
            null,
            [RequestType],
            [Format],
            [Parameters],
            1,      --Render
            [TimeStart],
            [TimeEnd],
            [TimeDataRetrieval],
            [TimeProcessing],
            [TimeRendering],
            [Source],
            [Status],
            [ByteCount],
            [RowCount],        
            null
         from [dbo].[ExecutionLog_Old] WITH (XLOCK)
         order by TimeStart ;
         
         delete from [dbo].[ExecutionLog_Old]
         where [TimeStart] in (select top (1024) with ties [TimeStart] from [dbo].[ExecutionLog_Old] order by [TimeStart]) ;
         
         set @updatedRow = @@ROWCOUNT ;
         
	     IF @updatedRow = 0
	     begin
            drop table [dbo].[ExecutionLog_Old]
         end
     end
end

GO
/****** Object:  StoredProcedure [dbo].[MoveObject]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[MoveObject]
@OldPath nvarchar (425),
@OldPrefix nvarchar (850),
@NewName nvarchar (425),
@NewPath nvarchar (425),
@NewParentID uniqueidentifier,
@RenameOnly as bit,
@MaxPathLength as int
AS

DECLARE @LongPath nvarchar(425)
SET @LongPath =
  (SELECT TOP 1 Path
   FROM Catalog
   WHERE
      LEN(Path)-LEN(@OldPath)+LEN(@NewPath) > @MaxPathLength AND
      Path LIKE @OldPrefix ESCAPE '*')
   
IF @LongPath IS NOT NULL BEGIN
   SELECT @LongPath
   RETURN
END

IF @RenameOnly = 0 -- if this a full-blown move, not just a rename
BEGIN
    -- adjust policies on the top item that gets moved
    DECLARE @OldInheritedPolicyID as uniqueidentifier
    SELECT @OldInheritedPolicyID = (SELECT PolicyID FROM Catalog with (XLOCK) WHERE Path = @OldPath AND PolicyRoot = 0)
    IF (@OldInheritedPolicyID IS NOT NULL)
       BEGIN -- this was not a policy root, change it to inherit from target folder
         DECLARE @NewPolicyID as uniqueidentifier
         SELECT @NewPolicyID = (SELECT PolicyID FROM Catalog with (XLOCK) WHERE ItemID = @NewParentID)
         -- update item and children that shared the old policy
         UPDATE Catalog SET PolicyID = @NewPolicyID WHERE Path = @OldPath 
         UPDATE Catalog SET PolicyID = @NewPolicyID 
            WHERE Path LIKE @OldPrefix ESCAPE '*' 
            AND Catalog.PolicyID = @OldInheritedPolicyID
     END
END

-- Update item that gets moved (Path, Name, and ParentId)
update Catalog
set Name = @NewName, Path = @NewPath, ParentID = @NewParentID
where Path = @OldPath
-- Update all its children (Path only, Names and ParentIds stay the same)
update Catalog
set Path = STUFF(Path, 1, LEN(@OldPath), @NewPath )
where Path like @OldPrefix escape '*'

GO
/****** Object:  StoredProcedure [dbo].[ObjectExists]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ObjectExists]
@Path nvarchar (425),
@EditSessionID varchar(32) = NULL,
@OwnerSid as varbinary(85) = NULL, 
@OwnerName as nvarchar(260) = NULL,
@AuthType int
AS
BEGIN
DECLARE @OwnerID uniqueidentifier
if(@EditSessionID is not null)
BEGIN
    EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT
END

SELECT Type, ItemID, SnapshotLimit, NtSecDescPrimary, ExecutionFlag, Intermediate, [LinkSourceID], SubType, ComponentID
FROM ExtendedCatalog(@OwnerID, @Path, @EditSessionID)
LEFT OUTER JOIN SecData
ON ExtendedCatalog.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
END

GO
/****** Object:  StoredProcedure [dbo].[OpenSegmentedChunk]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[OpenSegmentedChunk]
	@SnapshotId		uniqueidentifier,
	@IsPermanent	bit,
	@ChunkName		nvarchar(260), 
	@ChunkType		int, 
	@ChunkId        uniqueidentifier out, 
	@ChunkFlags     tinyint out
as begin    
	if (@IsPermanent = 1) begin		
		select	@ChunkId = ChunkId,
				@ChunkFlags = ChunkFlags
		from dbo.SegmentedChunk chunk
		where chunk.SnapshotDataId = @SnapshotId and chunk.ChunkName = @ChunkName and chunk.ChunkType = @ChunkType
		
		select	csm.SegmentId, 				
				csm.LogicalByteCount as LogicalSegmentLength, 
				csm.ActualByteCount as ActualSegmentLength		
		from ChunkSegmentMapping csm		
		where csm.ChunkId = @ChunkId
		order by csm.StartByte asc
	end
	else begin
		select	@ChunkId = ChunkId,
				@ChunkFlags = ChunkFlags
		from dbo.ReportServerTempDB_SegmentedChunk chunk
		where chunk.SnapshotDataId = @SnapshotId and chunk.ChunkName = @ChunkName and chunk.ChunkType = @ChunkType

		if @ChunkFlags & 0x4 > 0 begin
			-- Shallow copy: read chunk segments from catalog 
			select	csm.SegmentId, 				
					csm.LogicalByteCount as LogicalSegmentLength, 
					csm.ActualByteCount as ActualSegmentLength		
			from ChunkSegmentMapping csm		
			where csm.ChunkId = @ChunkId
			order by csm.StartByte asc
		end
		else begin
			-- Regular copy: read chunk segments from temp db
			select	csm.SegmentId, 				
					csm.LogicalByteCount as LogicalSegmentLength, 
					csm.ActualByteCount as ActualSegmentLength		
			from dbo.ReportServerTempDB_ChunkSegmentMapping csm		
			where csm.ChunkId = @ChunkId
			order by csm.StartByte asc
		end
	end
end

GO
/****** Object:  StoredProcedure [dbo].[PromoteSnapshotInfo]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PromoteSnapshotInfo]
@SnapshotDataID as uniqueidentifier,
@IsPermanentSnapshot as bit,
@PageCount as int,
@HasDocMap as bit, 
@PaginationMode as smallint, 
@ProcessingFlags as int
AS

-- HasDocMap: Processing engine may not 
-- compute this flag in all cases, which 
-- can lead to it being false when passed into
-- this proc, however the server needs this 
-- flag to be true if it was ever set to be 
-- true in order to communicate that there is a 
-- document map to the viewer control.

IF @IsPermanentSnapshot = 1
BEGIN
   UPDATE SnapshotData SET 
	PageCount = @PageCount, 
	HasDocMap = COALESCE(@HasDocMap | HasDocMap, @HasDocMap),
	PaginationMode = @PaginationMode,
	ProcessingFlags = @ProcessingFlags
   WHERE SnapshotDataID = @SnapshotDataID
END ELSE BEGIN
   UPDATE dbo.ReportServerTempDB_SnapshotData SET 
	PageCount = @PageCount, 
	HasDocMap = COALESCE(@HasDocMap | HasDocMap, @HasDocMap), 
	PaginationMode = @PaginationMode,
	ProcessingFlags = @ProcessingFlags
   WHERE SnapshotDataID = @SnapshotDataID
END      

GO
/****** Object:  StoredProcedure [dbo].[ReadChunkPortion]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ReadChunkPortion]
@ChunkPointer binary(16),
@IsPermanentSnapshot bit,
@DataIndex int,
@Length int
AS

IF @IsPermanentSnapshot != 0 BEGIN
    READTEXT ChunkData.Content @ChunkPointer @DataIndex @Length
END ELSE BEGIN
    READTEXT dbo.ReportServerTempDB_ChunkData.Content @ChunkPointer @DataIndex @Length
END

GO
/****** Object:  StoredProcedure [dbo].[ReadChunkSegment]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[ReadChunkSegment]
	@ChunkId		uniqueidentifier,
	@SegmentId		uniqueidentifier,
	@IsPermanent	bit, 
	@DataIndex		int,
	@Length			int
as begin
	if(@IsPermanent = 1) begin	
		select substring(seg.Content, @DataIndex + 1, @Length) as [Content]
		from Segment seg
		join ChunkSegmentMapping csm on (csm.SegmentId = seg.SegmentId)
		where csm.ChunkId = @ChunkId and csm.SegmentId = @SegmentId
	end
	else begin
		select substring(seg.Content, @DataIndex + 1, @Length) as [Content]
		from dbo.ReportServerTempDB_Segment seg
		join dbo.ReportServerTempDB_ChunkSegmentMapping csm on (csm.SegmentId = seg.SegmentId)
		where csm.ChunkId = @ChunkId and csm.SegmentId = @SegmentId
	end
end

GO
/****** Object:  StoredProcedure [dbo].[ReadRoleProperties]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ReadRoleProperties]
@RoleName as nvarchar(260)
AS 
SELECT Description, TaskMask, RoleFlags FROM Roles WHERE RoleName = @RoleName

GO
/****** Object:  StoredProcedure [dbo].[RebindDataSet]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Republishing generates new ID and stores those in the object model, 
-- in order to resolve the data sets we need to rebind the old 
-- data set definition to the current ID
CREATE PROCEDURE [dbo].[RebindDataSet]
@ItemId		uniqueidentifier, 
@Name		nvarchar(260), 
@NewID	uniqueidentifier
AS
UPDATE DataSets
SET ID = @NewID
WHERE ItemID = @ItemId AND [Name] = @Name

GO
/****** Object:  StoredProcedure [dbo].[RebindDataSource]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Republishing generates new DSID and stores those in the object model, 
-- in order to resolve the data sources we need to rebind the old 
-- data source definition to the current DSID
CREATE PROCEDURE [dbo].[RebindDataSource]
@ItemId		uniqueidentifier, 
@Name		nvarchar(260), 
@NewDSID	uniqueidentifier
AS
UPDATE DataSource
SET DSID = @NewDSID
WHERE ItemID = @ItemId AND [Name] = @Name

GO
/****** Object:  StoredProcedure [dbo].[RemoveReportFromSession]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[RemoveReportFromSession]
@SessionID as varchar(32),
@ReportPath as nvarchar(440), 
@OwnerSid as varbinary(85) = NULL,
@OwnerName as nvarchar(260),
@AuthType as int
AS

DECLARE @OwnerID uniqueidentifier
EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT

EXEC DereferenceSessionSnapshot @SessionID, @OwnerID
   
DELETE
   SE
FROM
   dbo.ReportServerTempDB_SessionData AS SE
WHERE
   SE.SessionID = @SessionID AND
   SE.ReportPath = @ReportPath AND
   SE.OwnerID = @OwnerID
   
DELETE FROM dbo.ReportServerTempDB_SessionLock WHERE SessionID=@SessionID
   
-- Delete any persisted streams associated with this session
UPDATE PS
SET
    PS.RefCount = 0,
    PS.ExpirationDate = GETDATE()
FROM
    dbo.ReportServerTempDB_PersistedStream AS PS
WHERE
    PS.SessionID = @SessionID

GO
/****** Object:  StoredProcedure [dbo].[RemoveRunningJob]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[RemoveRunningJob]
@JobID as nvarchar(32)
AS
SET NOCOUNT OFF
DELETE FROM RunningJobs WHERE JobID = @JobID

GO
/****** Object:  StoredProcedure [dbo].[RemoveSegment]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[RemoveSegment]
	@DeleteCountPermanent int, 
	@DeleteCountTemp int
as
begin
	SET DEADLOCK_PRIORITY LOW
	
	-- Locking:
	-- Similar idea as in RemovedSegmentedMapping.  Readpast
	-- any Segments which are currently locked and run the 
	-- inner scan with nolock.	
	declare @numDeleted int;
	declare @toDeleteMapping table (
		SegmentId uniqueidentifier );
	
	insert into @toDeleteMapping (SegmentId)	
	select top (@DeleteCountPermanent) SegmentId 
	from Segment with (readpast)	
	where not exists (
		select 1 from ChunkSegmentMapping CSM with (nolock)
		where CSM.SegmentId = Segment.SegmentId
		) ;
		
	delete from Segment with (readpast)
	where Segment.SegmentId in (
		select td.SegmentId from @toDeleteMapping td
		where not exists (
			select 1 from ChunkSegmentMapping CSM
			where CSM.SegmentId = td.SegmentId ));
			
	select @numDeleted = @@rowcount ;
	
	declare @toDeleteTempSegment table (
		SegmentId uniqueidentifier );
	
	insert into @toDeleteTempSegment (SegmentId)		
	select top (@DeleteCountTemp) SegmentId
	from dbo.ReportServerTempDB_Segment with (readpast)	
	where not exists (
		select 1 from dbo.ReportServerTempDB_ChunkSegmentMapping CSM with (nolock)
		where CSM.SegmentId = dbo.ReportServerTempDB_Segment.SegmentId
		) ;
		
	delete from dbo.ReportServerTempDB_Segment with (readpast)
	where dbo.ReportServerTempDB_Segment.SegmentId in (
		select td.SegmentId from @toDeleteTempSegment td 
		where not exists (
			select 1 from dbo.ReportServerTempDB_ChunkSegmentMapping CSM
			where CSM.SegmentId = td.SegmentId
			)) ;
	select @numDeleted = @numDeleted + @@rowcount ;
	
	select @numDeleted;
end

GO
/****** Object:  StoredProcedure [dbo].[RemoveSegmentedMapping]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[RemoveSegmentedMapping]
    @DeleteCountPermanentChunk int,
	@DeleteCountPermanentMapping int, 
	@DeleteCountTempChunk int,
	@DeleteCountTempMapping int,
	@MachineName nvarchar(260)
as
begin
	SET DEADLOCK_PRIORITY LOW
	
	declare @deleted table (
		ChunkID uniqueidentifier, 
		IsPermanent bit );
	
	-- details on lock hints:
	-- we use readpast on ChunkSegmentMapping to skip past
	-- rows which are currently locked.  they are being actively 
	-- used so clearly we do not want to delete them. we use 
	-- nolock on SegmentedChunk table as well, this is because
	-- regardless of whether or not that row is locked, we want to
	-- know if it is referenced by a SegmentedChunk and if 
	-- so we do not want to delete the mapping row.  ChunkIds are 
	-- only modified when creating a shallow chunk copy(see ShallowCopyChunk),
	-- but in this case the ChunkSegmentMapping row is locked (via the insert)
	-- so we are safe.
	
	declare @toDeletePermChunks table (
	    SnapshotDataId uniqueidentifier ) ;
	
	insert into @toDeletePermChunks (SnapshotDataId)		
	select top (@DeleteCountPermanentChunk) SnapshotDataId 
	from SegmentedChunk with (readpast)	
	where not exists (
		select 1 from SnapshotData SD with (nolock)
		where SegmentedChunk.SnapshotDataId = SD.SnapshotDataID
		) ;
		
	delete from SegmentedChunk with (readpast)
	where SegmentedChunk.SnapshotDataId in (
		select td.SnapshotDataId from @toDeletePermChunks td
		where not exists (
			select 1 from SnapshotData SD
			where td.SnapshotDataId = SD.SnapshotDataID
			)) ;
		
	-- clean up segmentedchunks from permanent database
	
	declare @toDeleteChunks table (
		ChunkId uniqueidentifier );	
	
	-- clean up mappings from permanent database
	insert into @toDeleteChunks (ChunkId)
	select top (@DeleteCountPermanentMapping) ChunkId
	from ChunkSegmentMapping with (readpast)	
	where not exists (
		select 1 from SegmentedChunk SC with (nolock)
		where SC.ChunkId = ChunkSegmentMapping.ChunkId
		) ;
		
	delete from ChunkSegmentMapping with (readpast)
	output deleted.ChunkId, convert(bit, 1) into @deleted
	where ChunkSegmentMapping.ChunkId in (
		select td.ChunkId from @toDeleteChunks td
		where not exists (
			select 1 from SegmentedChunk SC 
			where SC.ChunkId = td.ChunkId )
		and not exists (
			select 1 from dbo.ReportServerTempDB_SegmentedChunk TSC
			where TSC.ChunkId = td.ChunkId ) )
	
	declare @toDeleteTempChunks table (		
		SnapshotDataId uniqueidentifier);
			
	-- clean up SegmentedChunks from the Temp database
	-- for locking we play the same idea as in the previous query.
	-- snapshotIds never change, so again this operation is safe.
	insert into @toDeleteTempChunks (SnapshotDataId)		
	select top (@DeleteCountTempChunk) SnapshotDataId 
	from dbo.ReportServerTempDB_SegmentedChunk with (readpast)
	where dbo.ReportServerTempDB_SegmentedChunk.Machine = @MachineName
	and not exists (
		select 1 from dbo.ReportServerTempDB_SnapshotData SD with (nolock)
		where dbo.ReportServerTempDB_SegmentedChunk.SnapshotDataId = SD.SnapshotDataID
		) ;
		
	delete from dbo.ReportServerTempDB_SegmentedChunk with (readpast)
	where dbo.ReportServerTempDB_SegmentedChunk.SnapshotDataId in (
		select td.SnapshotDataId from @toDeleteTempChunks td
		where not exists (
			select 1 from dbo.ReportServerTempDB_SnapshotData SD
			where td.SnapshotDataId = SD.SnapshotDataID
			)) ;
	
	declare @toDeleteTempMappings table (
		ChunkId uniqueidentifier );		
		
	-- clean up mappings from temp database
	insert into @toDeleteTempMappings (ChunkId)	
	select top (@DeleteCountTempMapping) ChunkId
	from dbo.ReportServerTempDB_ChunkSegmentMapping with (readpast)	
	where not exists (
		select 1 from dbo.ReportServerTempDB_SegmentedChunk SC with (nolock)
		where SC.ChunkId = dbo.ReportServerTempDB_ChunkSegmentMapping.ChunkId
		) ;
		
	delete from dbo.ReportServerTempDB_ChunkSegmentMapping with (readpast)
	output deleted.ChunkId, convert(bit, 0) into @deleted
	where dbo.ReportServerTempDB_ChunkSegmentMapping.ChunkId in (
		select td.ChunkId from @toDeleteTempMappings td
		where not exists (
			select 1 from dbo.ReportServerTempDB_SegmentedChunk SC
			where td.ChunkId = SC.ChunkId )) ;
		
	-- need to return these so we can cleanup file system chunks
	select distinct ChunkID, IsPermanent
	from @deleted ;
end

GO
/****** Object:  StoredProcedure [dbo].[RemoveSubscriptionFromBeingDeleted]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[RemoveSubscriptionFromBeingDeleted] 
@SubscriptionID uniqueidentifier
AS
delete from [SubscriptionsBeingDeleted] where SubscriptionID = @SubscriptionID

GO
/****** Object:  StoredProcedure [dbo].[SetAllProperties]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetAllProperties]
@Path nvarchar (425),
@EditSessionID varchar(32) = NULL,
@Property ntext,
@Description ntext = NULL,
@Hidden bit = NULL,
@ModifiedBySid varbinary (85) = NULL,
@ModifiedByName nvarchar(260),
@AuthType int,
@ModifiedDate DateTime
AS

IF(@EditSessionID is null)
BEGIN
DECLARE @ModifiedByID uniqueidentifier
EXEC GetUserID @ModifiedBySid, @ModifiedByName, @AuthType, @ModifiedByID OUTPUT

UPDATE Catalog
SET Property = @Property, Description = @Description, Hidden = @Hidden, ModifiedByID = @ModifiedByID, ModifiedDate = @ModifiedDate
WHERE Path = @Path
END
ELSE
BEGIN
    UPDATE dbo.ReportServerTempDB_TempCatalog
    SET Property = @Property, Description = @Description
    WHERE ContextPath = @Path and EditSessionID = @EditSessionID
END

GO
/****** Object:  StoredProcedure [dbo].[SetCacheLastUsed]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SetCacheLastUsed]
    @SnapshotDataID uniqueidentifier, 
    @Timestamp datetime
AS
BEGIN
    -- Extend the cache lifetime based on the current timestamp
    -- set the last used time, which is utilized to compute which entries
    -- to evict when enforcing cache limits
    -- in the case where the cache entry is using schedule based expiration (RelativeExpiration is null)
    -- then don't update AbsoluteExpiration
    UPDATE dbo.ReportServerTempDB_ExecutionCache
    SET		AbsoluteExpiration = ISNULL(DATEADD(n, RelativeExpiration, @Timestamp), AbsoluteExpiration),
            LastUsedTime = @Timestamp 
    WHERE SnapshotDataID = @SnapshotDataID ;
END

GO
/****** Object:  StoredProcedure [dbo].[SetCacheOptions]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetCacheOptions]
@Path as nvarchar(425),
@CacheReport as bit,
@ExpirationFlags as int,
@CacheExpiration as int = NULL
AS
DECLARE @CachePolicyID as uniqueidentifier
SELECT @CachePolicyID = (SELECT CachePolicyID 
FROM CachePolicy with (XLOCK) INNER JOIN Catalog ON Catalog.ItemID = CachePolicy.ReportID
WHERE  Catalog.Path = @Path)
IF @CachePolicyID IS NULL -- no policy exists
BEGIN
    IF @CacheReport = 1 -- create a new one
    BEGIN
        INSERT INTO CachePolicy
        (CachePolicyID, ReportID, ExpirationFlags, CacheExpiration)
        (SELECT NEWID(), ItemID, @ExpirationFlags, @CacheExpiration
        FROM Catalog WHERE Catalog.Path = @Path)
    END
    -- ELSE if it has no policy and we want to remove its policy do nothing
END
ELSE -- existing policy
BEGIN
    IF @CacheReport = 1
    BEGIN
        UPDATE CachePolicy SET ExpirationFlags = @ExpirationFlags, CacheExpiration = @CacheExpiration
        WHERE CachePolicyID = @CachePolicyID
        EXEC FlushReportFromCache @Path
    END
    ELSE
    BEGIN
        DELETE FROM CachePolicy 
        WHERE CachePolicyID = @CachePolicyID
        EXEC FlushReportFromCache @Path
    END
END

GO
/****** Object:  StoredProcedure [dbo].[SetConfigurationInfo]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetConfigurationInfo]
@Name nvarchar (260),
@Value ntext
AS
DELETE
FROM [ConfigurationInfo]
WHERE [Name] = @Name

IF @Value is not null BEGIN
   INSERT
   INTO ConfigurationInfo
   VALUES ( newid(), @Name, @Value )
END

GO
/****** Object:  StoredProcedure [dbo].[SetDrillthroughReports]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetDrillthroughReports]
@ReportID uniqueidentifier,
@ModelID uniqueidentifier,
@ModelItemID nvarchar(425),
@Type tinyint
AS
 SET NOCOUNT OFF
 INSERT INTO ModelDrill (ModelDrillID, ModelID, ReportID, ModelItemID, [Type])
 VALUES (newid(), @ModelID, @ReportID, @ModelItemID, @Type)

GO
/****** Object:  StoredProcedure [dbo].[SetExecutionOptions]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetExecutionOptions]
@Path as nvarchar(425),
@ExecutionFlag as int,
@ExecutionChanged as bit = 0
AS
IF @ExecutionChanged = 0
BEGIN
    UPDATE Catalog SET ExecutionFlag = @ExecutionFlag WHERE Catalog.Path = @Path
END
ELSE
BEGIN
    IF (@ExecutionFlag & 3) = 2
    BEGIN   -- set it to snapshot, flush cache
        EXEC FlushReportFromCache @Path
        DELETE CachePolicy FROM CachePolicy INNER JOIN Catalog ON CachePolicy.ReportID = Catalog.ItemID
        WHERE Catalog.Path = @Path
    END

    -- now clean existing snapshot and execution time if any
    UPDATE SnapshotData
    SET PermanentRefcount = PermanentRefcount - 1
    FROM
       SnapshotData
       INNER JOIN Catalog ON SnapshotData.SnapshotDataID = Catalog.SnapshotDataID
    WHERE Catalog.Path = @Path
    
    UPDATE Catalog
    SET ExecutionFlag = @ExecutionFlag, SnapshotDataID = NULL, ExecutionTime = NULL
    WHERE Catalog.Path = @Path
END

GO
/****** Object:  StoredProcedure [dbo].[SetHistoryLimit]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetHistoryLimit]
@Path nvarchar (425),
@SnapshotLimit int = NULL
AS
UPDATE Catalog
SET SnapshotLimit=@SnapshotLimit
WHERE Path = @Path

GO
/****** Object:  StoredProcedure [dbo].[SetKeysForInstallation]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetKeysForInstallation]
@InstallationID uniqueidentifier,
@SymmetricKey image = NULL,
@PublicKey image
AS

update [dbo].[Keys]
set [SymmetricKey] = @SymmetricKey, [PublicKey] = @PublicKey
where [InstallationID] = @InstallationID and [Client] = 1

GO
/****** Object:  StoredProcedure [dbo].[SetLastModified]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetLastModified]
@Path nvarchar (425),
@ModifiedBySid varbinary (85) = NULL,
@ModifiedByName nvarchar(260),
@AuthType int,
@ModifiedDate DateTime
AS
DECLARE @ModifiedByID uniqueidentifier
EXEC GetUserID @ModifiedBySid, @ModifiedByName, @AuthType, @ModifiedByID OUTPUT
UPDATE Catalog
SET ModifiedByID = @ModifiedByID, ModifiedDate = @ModifiedDate
WHERE Path = @Path

GO
/****** Object:  StoredProcedure [dbo].[SetMachineName]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetMachineName]
@MachineName nvarchar(256),
@InstallationID uniqueidentifier
AS

UPDATE [dbo].[Keys]
SET MachineName = @MachineName
WHERE [InstallationID] = @InstallationID and [Client] = 1

GO
/****** Object:  StoredProcedure [dbo].[SetModelItemPolicy]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- update the system policy
CREATE PROCEDURE [dbo].[SetModelItemPolicy]
@CatalogItemID as uniqueidentifier,
@ModelItemID as nvarchar(425),
@PrimarySecDesc as image,
@SecondarySecDesc as ntext = NULL,
@XmlPolicy as ntext,
@AuthType as int,
@PolicyID uniqueidentifier OUTPUT
AS 
SELECT @PolicyID = (SELECT PolicyID FROM ModelItemPolicy WHERE CatalogItemID = @CatalogItemID AND ModelItemID = @ModelItemID )
IF (@PolicyID IS NULL)
   BEGIN
     SET @PolicyID = newid()
     INSERT INTO Policies (PolicyID, PolicyFlag)
     VALUES (@PolicyID, 2)
     INSERT INTO SecData (SecDataID, PolicyID, AuthType, XmlDescription, NTSecDescPrimary, NtSecDescSecondary)
     VALUES (newid(), @PolicyID, @AuthType, @XmlPolicy, @PrimarySecDesc, @SecondarySecDesc)
     INSERT INTO ModelItemPolicy (ID, CatalogItemID, ModelItemID, PolicyID)
     VALUES (newid(), @CatalogItemID, @ModelItemID, @PolicyID)
   END
ELSE
   BEGIN
      DECLARE @SecDataID as uniqueidentifier
      SELECT @SecDataID = (SELECT SecDataID FROM SecData WHERE PolicyID = @PolicyID and AuthType = @AuthType)
      IF (@SecDataID IS NULL)
      BEGIN -- insert new sec desc's
        INSERT INTO SecData (SecDataID, PolicyID, AuthType, XmlDescription, NTSecDescPrimary, NtSecDescSecondary)
        VALUES (newid(), @PolicyID, @AuthType, @XmlPolicy, @PrimarySecDesc, @SecondarySecDesc)
      END
      ELSE
      BEGIN -- update existing sec desc's
        UPDATE SecData SET 
        XmlDescription = @XmlPolicy,
        NtSecDescPrimary = @PrimarySecDesc,
        NtSecDescSecondary = @SecondarySecDesc
        WHERE SecData.PolicyID = @PolicyID
        AND AuthType = @AuthType

      END      
   END
DELETE FROM PolicyUserRole WHERE PolicyID = @PolicyID 

GO
/****** Object:  StoredProcedure [dbo].[SetNotificationAttempt]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetNotificationAttempt] 
@Attempt int,
@SecondsToAdd int,
@NotificationID uniqueidentifier
AS

update 
    [Notifications] 
set 
    [ProcessStart] = NULL, 
    [Attempt] = @Attempt, 
    [ProcessAfter] = DateAdd(second, @SecondsToAdd, GetUtcDate())
where
    [NotificationID] = @NotificationID

GO
/****** Object:  StoredProcedure [dbo].[SetObjectContent]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetObjectContent]
@Path nvarchar (425),
@EditSessionID varchar(32) = NULL,
@Type int,
@Content image = NULL,
@Intermediate uniqueidentifier = NULL,
@Parameter ntext = NULL,
@LinkSourceID uniqueidentifier = NULL,
@MimeType nvarchar (260) = NULL,
@DataCacheHash varbinary(64) = NULL,
@SubType nvarchar(128) = NULL,
@ComponentID uniqueidentifier= NULL
AS

DECLARE @OldIntermediate as uniqueidentifier
DECLARE @OldPermanent as bit
IF(@EditSessionID is null)
BEGIN	
SET @OldIntermediate = (SELECT Intermediate FROM Catalog WITH (XLOCK) WHERE Path = @Path)

UPDATE SnapshotData
SET PermanentRefcount = PermanentRefcount - 1,
    -- to fix VSTS 384486 keep shared dataset compiled definition for 14 days
    ExpirationDate = case when @Type = 8 then DATEADD(d, 14, GETDATE()) ELSE ExpirationDate END,
    TransientRefcount = TransientRefcount + case when @Type = 8 then 1 ELSE 0 END
WHERE SnapshotData.SnapshotDataID = @OldIntermediate

UPDATE Catalog
SET Type=@Type, Content = @Content, Intermediate = @Intermediate, [Parameter] = @Parameter, LinkSourceID = @LinkSourceID, MimeType = @MimeType, SubType = @SubType, ComponentID = @ComponentID
WHERE Path = @Path

UPDATE SnapshotData
SET PermanentRefcount = PermanentRefcount + 1, TransientRefcount = TransientRefcount - 1
WHERE SnapshotData.SnapshotDataID = @Intermediate

EXEC FlushReportFromCache @Path

END
ELSE
BEGIN
    DECLARE @OldDataCacheHash binary(64) ;
    DECLARE @ItemID uniqueidentifier ;
    
    SELECT	@OldIntermediate = Intermediate, 
            @OldPermanent = IntermediateIsPermanent,
            @OldDataCacheHash = DataCacheHash, 
            @ItemID = TempCatalogID
    FROM dbo.ReportServerTempDB_TempCatalog WITH (XLOCK)
    WHERE ContextPath = @Path and EditSessionID = @EditSessionID

    UPDATE dbo.ReportServerTempDB_TempCatalog
    SET Content = @Content, 
        Intermediate = @Intermediate, 
        IntermediateIsPermanent = 0, 
        Parameter = @Parameter,
        DataCacheHash = @DataCacheHash
    WHERE ContextPath = @Path and EditSessionID = @EditSessionID
    
    UPDATE dbo.ReportServerTempDB_SnapshotData
    SET  PermanentRefcount = PermanentRefcount - 1
    WHERE SnapshotData.SnapshotDataID = @OldIntermediate

    UPDATE dbo.ReportServerTempDB_SnapshotData
    SET PermanentRefcount = PermanentRefcount + 1, TransientRefcount = TransientRefcount - 1
    WHERE SnapshotData.SnapshotDataID = @Intermediate 
    
    EXEC ExtendEditSessionLifetime @EditSessionID ;
    
    IF ((@OldDataCacheHash <> @DataCacheHash) OR 
		(@OldDataCacheHash IS NULL) OR 
		(@DataCacheHash IS NULL))
    BEGIN
        EXEC FlushCacheById @ItemID
    END
END

GO
/****** Object:  StoredProcedure [dbo].[SetParameters]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetParameters]
@Path nvarchar (425),
@Parameter ntext
AS
UPDATE Catalog
SET [Parameter] = @Parameter
WHERE Path = @Path
EXEC FlushReportFromCache @Path

GO
/****** Object:  StoredProcedure [dbo].[SetPersistedStreamError]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetPersistedStreamError]
@SessionID varchar(32),
@Index int,
@AllRows bit,
@Error nvarchar(512)
AS

if @AllRows = 0
BEGIN
    UPDATE dbo.ReportServerTempDB_PersistedStream SET Error = @Error WHERE SessionID = @SessionID and [Index] = @Index
END
ELSE
BEGIN
    UPDATE dbo.ReportServerTempDB_PersistedStream SET Error = @Error WHERE SessionID = @SessionID
END

GO
/****** Object:  StoredProcedure [dbo].[SetPolicy]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- this assumes the item exists in the catalog
CREATE PROCEDURE [dbo].[SetPolicy]
@ItemName as nvarchar(425),
@ItemNameLike as nvarchar(850),
@PrimarySecDesc as image,
@SecondarySecDesc as ntext = NULL,
@XmlPolicy as ntext,
@AuthType int,
@PolicyID uniqueidentifier OUTPUT
AS 
SELECT @PolicyID = (SELECT PolicyID FROM Catalog WHERE Path = @ItemName AND PolicyRoot = 1)
IF (@PolicyID IS NULL)
   BEGIN -- this is not a policy root
     SET @PolicyID = newid()
     INSERT INTO Policies (PolicyID, PolicyFlag)
     VALUES (@PolicyID, 0)
     INSERT INTO SecData (SecDataID, PolicyID, AuthType, XmlDescription, NTSecDescPrimary, NtSecDescSecondary)
     VALUES (newid(), @PolicyID, @AuthType, @XmlPolicy, @PrimarySecDesc, @SecondarySecDesc)
     DECLARE @OldPolicyID as uniqueidentifier
     SELECT @OldPolicyID = (SELECT PolicyID FROM Catalog WHERE Path = @ItemName)
     -- update item and children that shared the old policy
     UPDATE Catalog SET PolicyID = @PolicyID, PolicyRoot = 1 WHERE Path = @ItemName 
     UPDATE Catalog SET PolicyID = @PolicyID 
    WHERE Path LIKE @ItemNameLike ESCAPE '*' 
    AND Catalog.PolicyID = @OldPolicyID
   END
ELSE
   BEGIN
      UPDATE Policies SET 
      PolicyFlag = 0
      WHERE Policies.PolicyID = @PolicyID
      DECLARE @SecDataID as uniqueidentifier
      SELECT @SecDataID = (SELECT SecDataID FROM SecData WHERE PolicyID = @PolicyID and AuthType = @AuthType)
      IF (@SecDataID IS NULL)
      BEGIN -- insert new sec desc's
        INSERT INTO SecData (SecDataID, PolicyID, AuthType, XmlDescription ,NTSecDescPrimary, NtSecDescSecondary)
        VALUES (newid(), @PolicyID, @AuthType, @XmlPolicy, @PrimarySecDesc, @SecondarySecDesc)
      END
      ELSE
      BEGIN -- update existing sec desc's
        UPDATE SecData SET 
        XmlDescription = @XmlPolicy,
        NtSecDescPrimary = @PrimarySecDesc,
        NtSecDescSecondary = @SecondarySecDesc
        WHERE SecData.PolicyID = @PolicyID
        AND AuthType = @AuthType
      END
   END
DELETE FROM PolicyUserRole WHERE PolicyID = @PolicyID 

GO
/****** Object:  StoredProcedure [dbo].[SetReencryptedDatasourceInfo]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetReencryptedDatasourceInfo]
@DSID uniqueidentifier,
@ConnectionString image = NULL,
@OriginalConnectionString image = NULL,
@UserName image = NULL,
@Password image = NULL,
@CredentialRetrieval int,
@Version int
AS

UPDATE [dbo].[DataSource]
SET
    [ConnectionString] = @ConnectionString,
    [OriginalConnectionString] = @OriginalConnectionString,
    [UserName] = @UserName,
    [Password] = @Password,
    [CredentialRetrieval] = @CredentialRetrieval,
    [Version] = @Version
WHERE [DSID] = @DSID

GO
/****** Object:  StoredProcedure [dbo].[SetReencryptedSubscriptionInfo]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetReencryptedSubscriptionInfo]
@SubscriptionID as uniqueidentifier,
@ExtensionSettings as ntext = NULL,
@Version as int
AS

UPDATE [dbo].[Subscriptions]
SET [ExtensionSettings] = @ExtensionSettings,
    [Version] = @Version
WHERE [SubscriptionID] = @SubscriptionID

GO
/****** Object:  StoredProcedure [dbo].[SetRoleProperties]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetRoleProperties]
@RoleName as nvarchar(260),
@Description as nvarchar(512) = NULL,
@TaskMask as nvarchar(32),
@RoleFlags as tinyint
AS 
SET NOCOUNT OFF
DECLARE @ExistingRoleFlags as tinyint
SET @ExistingRoleFlags = (SELECT RoleFlags FROM Roles WHERE RoleName = @RoleName)
IF @ExistingRoleFlags IS NULL
BEGIN
    RETURN
END
IF @ExistingRoleFlags <> @RoleFlags
BEGIN
    RAISERROR ('Bad role flags', 16, 1)
END
UPDATE Roles SET 
Description = @Description, 
TaskMask = @TaskMask,
RoleFlags = @RoleFlags
WHERE RoleName = @RoleName

GO
/****** Object:  StoredProcedure [dbo].[SetSessionCredentials]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetSessionCredentials]
@SessionID as varchar(32),
@OwnerSid as varbinary(85) = NULL,
@OwnerName as nvarchar(260),
@AuthType as int,
@DataSourceInfo as image = NULL,
@Expiration as datetime,
@EffectiveParams as ntext = NULL
AS

DECLARE @OwnerID uniqueidentifier
EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT

EXEC DereferenceSessionSnapshot @SessionID, @OwnerID

UPDATE SE
SET
   SE.DataSourceInfo = @DataSourceInfo,
   SE.SnapshotDataID = null,
   SE.IsPermanentSnapshot = null,
   SE.SnapshotExpirationDate = null,
   SE.ShowHideInfo = null,
   SE.HasInteractivity = null,
   SE.AutoRefreshSeconds = null,
   SE.Expiration = @Expiration,
   SE.EffectiveParams = @EffectiveParams,
   SE.AwaitingFirstExecution = 1
FROM
   dbo.ReportServerTempDB_SessionData AS SE
WHERE
   SE.SessionID = @SessionID AND
   SE.OwnerID = @OwnerID

GO
/****** Object:  StoredProcedure [dbo].[SetSessionData]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Writes or updates session record
CREATE PROCEDURE [dbo].[SetSessionData]
@SessionID as varchar(32),
@ReportPath as nvarchar(440),
@HistoryDate as datetime = NULL,
@Timeout as int,
@AutoRefreshSeconds as int = NULL,
@EffectiveParams ntext = NULL,
@OwnerSid as varbinary (85) = NULL,
@OwnerName as nvarchar (260),
@AuthType as int,
@ShowHideInfo as image = NULL,
@DataSourceInfo as image = NULL,
@SnapshotDataID as uniqueidentifier = NULL,
@IsPermanentSnapshot as bit = NULL,
@SnapshotTimeoutSeconds as int = NULL,
@HasInteractivity as bit,
@SnapshotExpirationDate as datetime = NULL,
@AwaitingFirstExecution as bit  = NULL, 
@EditSessionID as varchar(32) = NULL,
@DataSetInfo as varbinary(max) = null
AS

DECLARE @OwnerID uniqueidentifier
EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT

DECLARE @now datetime
SET @now = GETDATE()

-- is there a session for the same report ?
DECLARE @OldSnapshotDataID uniqueidentifier
DECLARE @OldIsPermanentSnapshot bit
DECLARE @OldSessionID varchar(32)

SELECT
   @OldSessionID = SessionID,
   @OldSnapshotDataID = SnapshotDataID,
   @OldIsPermanentSnapshot = IsPermanentSnapshot
FROM dbo.ReportServerTempDB_SessionData WITH (XLOCK) 
WHERE SessionID = @SessionID

IF @OldSessionID IS NOT NULL
BEGIN -- Yes, update it
   IF @OldSnapshotDataID != @SnapshotDataID or @SnapshotDataID is NULL BEGIN
      EXEC DereferenceSessionSnapshot @SessionID, @OwnerID
   END

   UPDATE
      dbo.ReportServerTempDB_SessionData
   SET
      SnapshotDataID = @SnapshotDataID,
      IsPermanentSnapshot = @IsPermanentSnapshot,
      Timeout = @Timeout,
      AutoRefreshSeconds = @AutoRefreshSeconds,
      SnapshotExpirationDate = @SnapshotExpirationDate,
      -- we want database session to expire later than in-memory session
      Expiration = DATEADD(s, @Timeout+10, @now),
      ShowHideInfo = @ShowHideInfo,
      DataSourceInfo = @DataSourceInfo,
      AwaitingFirstExecution = @AwaitingFirstExecution,
      DataSetInfo = @DataSetInfo      
      -- EffectiveParams = @EffectiveParams, -- no need to update user params as they are always same
      -- ReportPath = @ReportPath
      -- OwnerID = @OwnerID
   WHERE
      SessionID = @SessionID
 
   
   -- update expiration date on a snapshot that we reference
   IF @IsPermanentSnapshot != 0 BEGIN
      UPDATE
         SnapshotData
      SET
         ExpirationDate = DATEADD(n, @SnapshotTimeoutSeconds, @now)
      WHERE
         SnapshotDataID = @SnapshotDataID
   END ELSE BEGIN
      UPDATE
         dbo.ReportServerTempDB_SnapshotData
      SET
         ExpirationDate = DATEADD(n, @SnapshotTimeoutSeconds, @now)
      WHERE
         SnapshotDataID = @SnapshotDataID
   END

END
ELSE
BEGIN -- no, insert it
   UPDATE PS
    SET PS.RefCount = 1
    FROM
        dbo.ReportServerTempDB_PersistedStream as PS
    WHERE
        PS.SessionID = @SessionID	
        
    INSERT INTO dbo.ReportServerTempDB_SessionData
      (SessionID, SnapshotDataID, IsPermanentSnapshot, ReportPath,
       EffectiveParams, Timeout, AutoRefreshSeconds, Expiration,
       ShowHideInfo, DataSourceInfo, OwnerID, 
       CreationTime, HasInteractivity, SnapshotExpirationDate, HistoryDate, AwaitingFirstExecution, EditSessionID, DataSetInfo)
   VALUES
      (@SessionID, @SnapshotDataID, @IsPermanentSnapshot, @ReportPath,
       @EffectiveParams, @Timeout, @AutoRefreshSeconds, DATEADD(s, @Timeout, @now),
       @ShowHideInfo, @DataSourceInfo, @OwnerID, @now,
       @HasInteractivity, @SnapshotExpirationDate, @HistoryDate, @AwaitingFirstExecution, @EditSessionID, @DataSetInfo)             
END

GO
/****** Object:  StoredProcedure [dbo].[SetSessionParameters]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetSessionParameters]
@SessionID as varchar(32),
@OwnerSid as varbinary(85) = NULL,
@OwnerName as nvarchar(260),
@AuthType as int,
@EffectiveParams as ntext = NULL
AS

DECLARE @OwnerID uniqueidentifier
EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT

UPDATE SE
SET
   SE.EffectiveParams = @EffectiveParams,
   SE.AwaitingFirstExecution = 1
FROM
   dbo.ReportServerTempDB_SessionData AS SE
WHERE
   SE.SessionID = @SessionID AND
   SE.OwnerID = @OwnerID

GO
/****** Object:  StoredProcedure [dbo].[SetSnapshotChunksVersion]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetSnapshotChunksVersion]
@SnapshotDataID as uniqueidentifier,
@IsPermanentSnapshot as bit,
@Version as smallint
AS
declare @affectedRows int
set @affectedRows = 0
if @IsPermanentSnapshot = 1
BEGIN
   if @Version > 0
   BEGIN
      UPDATE ChunkData
      SET Version = @Version
      WHERE SnapshotDataID = @SnapshotDataID
      
      SELECT @affectedRows = @affectedRows + @@rowcount
      
      UPDATE SegmentedChunk
      SET Version = @Version
      WHERE SnapshotDataId = @SnapshotDataID      
      
      SELECT @affectedRows = @affectedRows + @@rowcount            
   END ELSE BEGIN
      UPDATE ChunkData
      SET Version = Version
      WHERE SnapshotDataID = @SnapshotDataID
      
      SELECT @affectedRows = @affectedRows + @@rowcount
      
      UPDATE SegmentedChunk
      SET Version = Version
      WHERE SnapshotDataId = @SnapshotDataID
      
      SELECT @affectedRows = @affectedRows + @@rowcount
   END   
END ELSE BEGIN
   if @Version > 0
   BEGIN
      UPDATE dbo.ReportServerTempDB_ChunkData
      SET Version = @Version
      WHERE SnapshotDataID = @SnapshotDataID
      
      SELECT @affectedRows = @affectedRows + @@rowcount
      
      UPDATE dbo.ReportServerTempDB_SegmentedChunk
      SET Version = @Version
      WHERE SnapshotDataId = @SnapshotDataID    
      
      SELECT @affectedRows = @affectedRows + @@rowcount
   END ELSE BEGIN
      UPDATE dbo.ReportServerTempDB_ChunkData
      SET Version = Version
      WHERE SnapshotDataID = @SnapshotDataID
            
      SELECT @affectedRows = @affectedRows + @@rowcount
      
      UPDATE dbo.ReportServerTempDB_SegmentedChunk
      SET Version = Version
      WHERE SnapshotDataId = @SnapshotDataID   
      
      SELECT @affectedRows = @affectedRows + @@rowcount
   END      
END
SELECT @affectedRows

GO
/****** Object:  StoredProcedure [dbo].[SetSnapshotProcessingFlags]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetSnapshotProcessingFlags]
@SnapshotDataID as uniqueidentifier, 
@IsPermanentSnapshot as bit, 
@ProcessingFlags int
AS

if @IsPermanentSnapshot = 1 
BEGIN
	UPDATE SnapshotData
	SET ProcessingFlags = @ProcessingFlags
	WHERE SnapshotDataID = @SnapshotDataID
END ELSE BEGIN
	UPDATE dbo.ReportServerTempDB_SnapshotData
	SET ProcessingFlags = @ProcessingFlags
	WHERE SnapshotDataID = @SnapshotDataID
END

GO
/****** Object:  StoredProcedure [dbo].[SetSystemPolicy]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- update the system policy
CREATE PROCEDURE [dbo].[SetSystemPolicy]
@PrimarySecDesc as image,
@SecondarySecDesc as ntext = NULL,
@XmlPolicy as ntext,
@AuthType as int,
@PolicyID uniqueidentifier OUTPUT
AS 
SELECT @PolicyID = (SELECT PolicyID FROM Policies WHERE PolicyFlag = 1)
IF (@PolicyID IS NULL)
   BEGIN
     SET @PolicyID = newid()
     INSERT INTO Policies (PolicyID, PolicyFlag)
     VALUES (@PolicyID, 1)
     INSERT INTO SecData (SecDataID, PolicyID, AuthType, XmlDescription, NTSecDescPrimary, NtSecDescSecondary)
     VALUES (newid(), @PolicyID, @AuthType, @XmlPolicy, @PrimarySecDesc, @SecondarySecDesc)
   END
ELSE
   BEGIN
      DECLARE @SecDataID as uniqueidentifier
      SELECT @SecDataID = (SELECT SecDataID FROM SecData WHERE PolicyID = @PolicyID and AuthType = @AuthType)
      IF (@SecDataID IS NULL)
      BEGIN -- insert new sec desc's
        INSERT INTO SecData (SecDataID, PolicyID, AuthType, XmlDescription, NTSecDescPrimary, NtSecDescSecondary)
        VALUES (newid(), @PolicyID, @AuthType, @XmlPolicy, @PrimarySecDesc, @SecondarySecDesc)
      END
      ELSE
      BEGIN -- update existing sec desc's
        UPDATE SecData SET 
        XmlDescription = @XmlPolicy,
        NtSecDescPrimary = @PrimarySecDesc,
        NtSecDescSecondary = @SecondarySecDesc
        WHERE SecData.PolicyID = @PolicyID
        AND AuthType = @AuthType

      END      
   END
DELETE FROM PolicyUserRole WHERE PolicyID = @PolicyID 

GO
/****** Object:  StoredProcedure [dbo].[SetUpgradeItemStatus]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetUpgradeItemStatus]
@ItemName nvarchar(260),
@Status nvarchar(512)
AS
UPDATE 
    [UpgradeInfo]
SET
    [Status] = @Status
WHERE
    [Item] = @ItemName

GO
/****** Object:  StoredProcedure [dbo].[SetUserServiceToken]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- set AAD token on user account
CREATE PROCEDURE [dbo].[SetUserServiceToken]
@ServiceToken ntext,
@UserSid as varbinary(85) = NULL, 
@UserName as nvarchar(260) = NULL,
@AuthType int
AS
BEGIN
DECLARE @UserID uniqueidentifier
EXEC GetUserID @UserSid, @UserName, @AuthType, @UserID OUTPUT

IF (@UserID is not null)
	BEGIN
		UPDATE Users
		SET ServiceToken = @ServiceToken
		WHERE UserID = @UserID
	END
END

GO
/****** Object:  StoredProcedure [dbo].[SetUserSettings]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- set user properties on user account
CREATE PROCEDURE [dbo].[SetUserSettings]
@Setting ntext,
@UserSid as varbinary(85) = NULL, 
@UserName as nvarchar(260) = NULL,
@AuthType int
AS
BEGIN
DECLARE @UserID uniqueidentifier
EXEC GetUserID @UserSid, @UserName, @AuthType, @UserID OUTPUT

IF (@UserID is not null)
	BEGIN
		UPDATE Users
		SET Setting = @Setting
		WHERE UserID = @UserID
	END
END

GO
/****** Object:  StoredProcedure [dbo].[ShallowCopyChunk]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[ShallowCopyChunk]
	@SnapshotId		uniqueidentifier, 
	@ChunkId		uniqueidentifier, 	
	@IsPermanent	bit, 
	@Machine		nvarchar(512),
	@NewChunkId		uniqueidentifier out
as
begin
	-- @SnapshotId & @ChunkId are the old identifiers	
	-- build the chunksegmentmapping first to prevent race 
	-- condition with cleaning it up
	select @NewChunkId = newid() ;
	if (@IsPermanent = 1) begin		
		insert ChunkSegmentMapping (ChunkId, SegmentId, StartByte, LogicalByteCount, ActualByteCount)
		select @NewChunkId, SegmentId, StartByte, LogicalByteCount, ActualByteCount
		from ChunkSegmentMapping where ChunkId = @ChunkId ;		
		
		update SegmentedChunk
		set ChunkId = @NewChunkId
		where ChunkId = @ChunkId and SnapshotDataId = @SnapshotId		
	end
	else begin
		insert dbo.ReportServerTempDB_ChunkSegmentMapping (ChunkId, SegmentId, StartByte, LogicalByteCount, ActualByteCount)
		select @NewChunkId, SegmentId, StartByte, LogicalByteCount, ActualByteCount
		from dbo.ReportServerTempDB_ChunkSegmentMapping where ChunkId = @ChunkId ;		
		
		-- update the machine name also, this is only really useful 
		-- for file system chunks, in which case the snapshot should
		-- have been versioned on the initial update
		update dbo.ReportServerTempDB_SegmentedChunk
		set 
			ChunkId = @NewChunkId, 
			Machine = @Machine
		where ChunkId = @ChunkId and SnapshotDataId = @SnapshotId			
	end
end

GO
/****** Object:  StoredProcedure [dbo].[StoreServerParameters]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[StoreServerParameters]
@ServerParametersID nvarchar(32),
@Path nvarchar(425),
@CurrentDate datetime,
@Timeout int,
@Expiration datetime,
@ParametersValues image,
@ParentParametersID nvarchar(32) = NULL
AS

DECLARE @ExistingServerParametersID as nvarchar(32)
SET @ExistingServerParametersID = (SELECT ServerParametersID from [dbo].[ServerParametersInstance] WHERE ServerParametersID = @ServerParametersID)
IF @ExistingServerParametersID IS NULL -- new row
BEGIN
  INSERT INTO [dbo].[ServerParametersInstance]
    (ServerParametersID, ParentID, Path, CreateDate, ModifiedDate, Timeout, Expiration, ParametersValues)
  VALUES
    (@ServerParametersID, @ParentParametersID, @Path, @CurrentDate, @CurrentDate, @Timeout, @Expiration, @ParametersValues)
END
ELSE
BEGIN
  UPDATE [dbo].[ServerParametersInstance]
  SET Timeout = @Timeout,
  Expiration = @Expiration,
  ParametersValues = @ParametersValues,
  ModifiedDate = @CurrentDate,
  Path = @Path,
  ParentID = @ParentParametersID
  WHERE ServerParametersID = @ServerParametersID
END

GO
/****** Object:  StoredProcedure [dbo].[TempChunkExists]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[TempChunkExists]
	@ChunkId uniqueidentifier
AS
BEGIN
	SELECT COUNT(1) FROM dbo.ReportServerTempDB_SegmentedChunk
	WHERE ChunkId = @ChunkId
END

GO
/****** Object:  StoredProcedure [dbo].[UpdateActiveSubscription]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateActiveSubscription]
@ActiveID uniqueidentifier,
@TotalNotifications int = NULL,
@TotalSuccesses int = NULL,
@TotalFailures int = NULL
AS

if @TotalNotifications is not NULL
begin
    update ActiveSubscriptions set TotalNotifications = @TotalNotifications where ActiveID = @ActiveID
end

if @TotalSuccesses is not NULL
begin
    update ActiveSubscriptions set TotalSuccesses = TotalSuccesses + @TotalSuccesses where ActiveID = @ActiveID
end

if @TotalFailures is not NULL
begin
    update ActiveSubscriptions set TotalFailures = TotalFailures + @TotalFailures where ActiveID = @ActiveID
end

select 
    TotalNotifications, 
    TotalSuccesses, 
    TotalFailures 
from 
    ActiveSubscriptions
where
    ActiveID = @ActiveID

GO
/****** Object:  StoredProcedure [dbo].[UpdateCompiledDefinition]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateCompiledDefinition]
	@Path				NVARCHAR(425),
	@OldSnapshotId		UNIQUEIDENTIFIER,
	@NewSnapshotId		UNIQUEIDENTIFIER,
	@ItemId				UNIQUEIDENTIFIER OUTPUT
AS BEGIN
	-- we have a clustered unique index on [Path] which the QO 
	-- should match for the filter
	UPDATE [dbo].[Catalog]
	SET [Intermediate] = @NewSnapshotId,
		@ItemId = [ItemID]
	WHERE [Path] = @Path AND 
	      ([Intermediate] = @OldSnapshotId OR (@OldSnapshotId IS NULL AND [Intermediate] IS NULL));
	
	DECLARE @UpdatedReferences INT ;
	SELECT @UpdatedReferences = @@ROWCOUNT ;
	
	IF(@UpdatedReferences <> 0)
	BEGIN
		UPDATE [dbo].[SnapshotData]
		SET [PermanentRefcount] = [PermanentRefcount] + @UpdatedReferences,
			[TransientRefcount] = [TransientRefcount] - 1
		WHERE [SnapshotDataID] = @NewSnapshotId ;
		
		UPDATE [dbo].[SnapshotData]
		SET [PermanentRefcount] = [PermanentRefcount] - @UpdatedReferences
		WHERE [SnapshotDataID] = @OldSnapshotId ;
	END
END

GRANT EXECUTE ON [dbo].[UpdateCompiledDefinition] TO RSExecRole

GO
/****** Object:  StoredProcedure [dbo].[UpdatePolicy]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdatePolicy]
@PolicyID as uniqueidentifier,
@PrimarySecDesc as image,
@SecondarySecDesc as ntext = NULL,
@AuthType int
AS
UPDATE SecData SET NtSecDescPrimary = @PrimarySecDesc,
NtSecDescSecondary = @SecondarySecDesc 
WHERE SecData.PolicyID = @PolicyID
AND SecData.AuthType = @AuthType

GO
/****** Object:  StoredProcedure [dbo].[UpdatePolicyPrincipal]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdatePolicyPrincipal]
@PolicyID uniqueidentifier,
@PrincipalSid varbinary(85) = NULL,
@PrincipalName nvarchar(260),
@PrincipalAuthType int,
@RoleName nvarchar(260),
@PrincipalID uniqueidentifier OUTPUT,
@RoleID uniqueidentifier OUTPUT
AS 
EXEC GetPrincipalID @PrincipalSid , @PrincipalName, @PrincipalAuthType, @PrincipalID  OUTPUT
SELECT @RoleID = (SELECT RoleID FROM Roles WHERE RoleName = @RoleName)
INSERT INTO PolicyUserRole 
(ID, RoleID, UserID, PolicyID)
VALUES (newid(), @RoleID, @PrincipalID, @PolicyID)

GO
/****** Object:  StoredProcedure [dbo].[UpdatePolicyRole]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdatePolicyRole]
@PolicyID uniqueidentifier,
@PrincipalID uniqueidentifier,
@RoleName nvarchar(260),
@RoleID uniqueidentifier OUTPUT
AS 
SELECT @RoleID = (SELECT RoleID FROM Roles WHERE RoleName = @RoleName)
INSERT INTO PolicyUserRole 
(ID, RoleID, UserID, PolicyID)
VALUES (newid(), @RoleID, @PrincipalID, @PolicyID)

GO
/****** Object:  StoredProcedure [dbo].[UpdateRunningJob]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateRunningJob]
@JobID as nvarchar(32),
@JobStatus as smallint
AS
SET NOCOUNT OFF
UPDATE RunningJobs SET JobStatus = @JobStatus WHERE JobID = @JobID

GO
/****** Object:  StoredProcedure [dbo].[UpdateScheduleNextRunTime]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateScheduleNextRunTime]
@ScheduleID as uniqueidentifier,
@NextRunTime as datetime
as
update Schedule set [NextRunTime] = @NextRunTime where [ScheduleID] = @ScheduleID

GO
/****** Object:  StoredProcedure [dbo].[UpdateSnapshot]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateSnapshot]
@Path as nvarchar(425),
@SnapshotDataID as uniqueidentifier,
@executionDate as datetime
AS
DECLARE @OldSnapshotDataID uniqueidentifier
DECLARE @ExecutionFlag int

SELECT @OldSnapshotDataID = SnapshotDataID,
	   @ExecutionFlag = ExecutionFlag 
	   FROM Catalog WITH (XLOCK) WHERE Catalog.Path = @Path
	   
	-- If the report is deleted after execution snapshot is fired
	IF (@@rowcount = 0)
	BEGIN		
        RAISERROR('Report does not exist', 16, 1)
        RETURN
    END

-- update reference count in snapshot table
UPDATE SnapshotData
SET PermanentRefcount = PermanentRefcount-1
WHERE SnapshotData.SnapshotDataID = @OldSnapshotDataID

 -- If the report is not set to execution snapshot after the 
 -- update execution snapshot fired, ignore this case.
IF (@ExecutionFlag & 3) <> 2
    BEGIN
        RAISERROR('Invalid snapshot flag', 16, 1)
        RETURN
    END

-- update catalog to point to the new execution snapshot
UPDATE Catalog
SET SnapshotDataID = @SnapshotDataID, ExecutionTime = @executionDate
WHERE Catalog.Path = @Path

UPDATE SnapshotData
SET PermanentRefcount = PermanentRefcount+1, TransientRefcount = TransientRefcount-1
WHERE SnapshotData.SnapshotDataID = @SnapshotDataID

GO
/****** Object:  StoredProcedure [dbo].[UpdateSnapshotPaginationInfo]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateSnapshotPaginationInfo]
@SnapshotDataID as uniqueidentifier, 
@IsPermanentSnapshot as bit, 
@PageCount as int,
@PaginationMode as smallint
AS
IF @IsPermanentSnapshot = 1
BEGIN
   UPDATE SnapshotData SET 
	PageCount = @PageCount, 	
	PaginationMode = @PaginationMode
   WHERE SnapshotDataID = @SnapshotDataID
END ELSE BEGIN
   UPDATE dbo.ReportServerTempDB_SnapshotData SET 
	PageCount = @PageCount, 	
	PaginationMode = @PaginationMode
   WHERE SnapshotDataID = @SnapshotDataID
END      

GO
/****** Object:  StoredProcedure [dbo].[UpdateSnapshotReferences]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateSnapshotReferences]
	@OldSnapshotId UNIQUEIDENTIFIER, 
	@NewSnapshotId UNIQUEIDENTIFIER,
	@IsPermanentSnapshot BIT,
	@TransientRefCountModifier INT,
	@UpdatedReferences INT OUTPUT	
AS 
BEGIN	
	SET @UpdatedReferences = 0
	
	IF(@IsPermanentSnapshot = 1)
	BEGIN
		-- Update Snapshot Executions		
		UPDATE [dbo].[Catalog]
		SET [SnapshotDataID] = @NewSnapshotId
		WHERE [SnapshotDataID] = @OldSnapshotId

		SELECT @UpdatedReferences = @UpdatedReferences + @@ROWCOUNT

		-- Update History
		UPDATE [dbo].[History]
		SET [SnapshotDataID] = @NewSnapshotId
		WHERE [SnapshotDataID] = @OldSnapshotId

		SELECT @UpdatedReferences = @UpdatedReferences + @@ROWCOUNT

		UPDATE [dbo].[SnapshotData]
		SET [PermanentRefcount] = [PermanentRefcount] - @UpdatedReferences,
			[TransientRefcount] = [TransientRefcount] + @TransientRefCountModifier
		WHERE [SnapshotDataID] = @OldSnapshotId

		UPDATE [dbo].[SnapshotData]
		SET [PermanentRefcount] = [PermanentRefcount] + @UpdatedReferences
		WHERE [SnapshotDataID] = @NewSnapshotId
	END
	ELSE
	BEGIN
		-- Update Execution Cache
		UPDATE dbo.ReportServerTempDB_[ExecutionCache]
		SET [SnapshotDataID] = @NewSnapshotId
		WHERE [SnapshotDataID] = @OldSnapshotId
		
		SELECT @UpdatedReferences = @UpdatedReferences + @@ROWCOUNT
		
		UPDATE dbo.ReportServerTempDB_[SnapshotData]
		SET [PermanentRefcount] = [PermanentRefcount] - @UpdatedReferences,
			[TransientRefcount] = [TransientRefcount] + @TransientRefCountModifier
		WHERE [SnapshotDataID] = @OldSnapshotId

		UPDATE dbo.ReportServerTempDB_[SnapshotData]
		SET [PermanentRefcount] = [PermanentRefcount] + @UpdatedReferences
		WHERE [SnapshotDataID] = @NewSnapshotId
	END
END

GO
/****** Object:  StoredProcedure [dbo].[UpdateSubscription]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateSubscription]
@id uniqueidentifier,
@Locale nvarchar(260),
@OwnerSid varbinary(85) = NULL,
@OwnerName nvarchar(260),
@OwnerAuthType int,
@DeliveryExtension nvarchar(260) = NULL,
@InactiveFlags int,
@ExtensionSettings ntext = NULL,
@ModifiedBySid varbinary(85) = NULL, 
@ModifiedByName nvarchar(260),
@ModifiedByAuthType int,
@ModifiedDate datetime,
@Description nvarchar(512) = NULL,
@LastStatus nvarchar(260) = NULL,
@EventType nvarchar(260),
@MatchData ntext = NULL,
@Parameters ntext = NULL,
@DataSettings ntext = NULL,
@Version int
AS
-- Update a subscription's information.
DECLARE @ModifiedByID uniqueidentifier
DECLARE @OwnerID uniqueidentifier

EXEC GetUserID @ModifiedBySid, @ModifiedByName, @ModifiedByAuthType, @ModifiedByID OUTPUT
EXEC GetUserID @OwnerSid, @OwnerName, @OwnerAuthType, @OwnerID OUTPUT

-- Make sure there is a valid provider
update Subscriptions set
        [DeliveryExtension] = @DeliveryExtension,
        [Locale] = @Locale,
        [OwnerID] = @OwnerID,
        [InactiveFlags] = @InactiveFlags,
        [ExtensionSettings] = @ExtensionSettings,
        [ModifiedByID] = @ModifiedByID,
        [ModifiedDate] = @ModifiedDate,
        [Description] = @Description,
        [LastStatus] = @LastStatus,
        [EventType] = @EventType,
        [MatchData] = @MatchData,
        [Parameters] = @Parameters,
        [DataSettings] = @DataSettings,
    [Version] = @Version
where
    [SubscriptionID] = @id

GO
/****** Object:  StoredProcedure [dbo].[UpdateSubscriptionLastRunInfo]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateSubscriptionLastRunInfo]
@SubscriptionID uniqueidentifier,
@Flags int,
@LastRunTime datetime,
@LastStatus nvarchar(260)
AS

update Subscriptions set
        [InactiveFlags] = @Flags,
        [LastRunTime] = @LastRunTime,
        [LastStatus] = @LastStatus
where
    [SubscriptionID] = @SubscriptionID

GO
/****** Object:  StoredProcedure [dbo].[UpdateSubscriptionResult]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateSubscriptionResult]
@SubscriptionID uniqueidentifier,
@ExtensionSettings nvarchar(max),
@SubscriptionResult nvarchar(256)
AS
	declare @ExtensionSettingsHash int
	set @ExtensionSettingsHash = CHECKSUM(@ExtensionSettings)

	IF EXISTS (
		SELECT 1 FROM dbo.[SubscriptionResults] 
		WHERE [SubscriptionID]=@SubscriptionID
			AND [ExtensionSettingsHash]=@ExtensionSettingsHash
			AND [ExtensionSettings] = @ExtensionSettings)
	BEGIN
		UPDATE [SubscriptionResults] SET [SubscriptionResult]=@SubscriptionResult
		WHERE [SubscriptionID]=@SubscriptionID
			AND [ExtensionSettingsHash]=@ExtensionSettingsHash
			AND [ExtensionSettings] = @ExtensionSettings
	END
	ELSE
	BEGIN
		INSERT INTO [SubscriptionResults] (SubscriptionResultID, SubscriptionID, ExtensionSettingsHash, ExtensionSettings, SubscriptionResult)
		VALUES (NewID(), @SubscriptionID, @ExtensionSettingsHash, @ExtensionSettings, @SubscriptionResult)
	END

GO
/****** Object:  StoredProcedure [dbo].[UpdateSubscriptionStatus]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateSubscriptionStatus]
@SubscriptionID uniqueidentifier,
@Status nvarchar(260)
AS

update Subscriptions set
        [LastStatus] = @Status
where
    [SubscriptionID] = @SubscriptionID

GO
/****** Object:  StoredProcedure [dbo].[UpdateTask]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateTask]
@ScheduleID uniqueidentifier,
@Name nvarchar (260),
@StartDate datetime,
@Flags int,
@NextRunTime datetime = NULL,
@LastRunTime datetime = NULL,
@EndDate datetime = NULL,
@RecurrenceType int = NULL,
@MinutesInterval int = NULL,
@DaysInterval int = NULL,
@WeeksInterval int = NULL,
@DaysOfWeek int = NULL,
@DaysOfMonth int = NULL,
@Month int = NULL,
@MonthlyWeek int = NULL,
@State int = NULL,
@LastRunStatus nvarchar (260) = NULL,
@ScheduledRunTimeout int = NULL

AS

-- Update a tasks values. ScheduleID and Report information can not be updated
Update Schedule set
        [StartDate] = @StartDate, 
        [Name] = @Name,
        [Flags] = @Flags,
        [NextRunTime] = @NextRunTime,
        [LastRunTime] = @LastRunTime,
        [EndDate] = @EndDate, 
        [RecurrenceType] = @RecurrenceType, 
        [MinutesInterval] = @MinutesInterval,
        [DaysInterval] = @DaysInterval,
        [WeeksInterval] = @WeeksInterval,
        [DaysOfWeek] = @DaysOfWeek, 
        [DaysOfMonth] = @DaysOfMonth, 
        [Month] = @Month, 
        [MonthlyWeek] = @MonthlyWeek, 
        [State] = @State, 
        [LastRunStatus] = @LastRunStatus,
        [ScheduledRunTimeout] = @ScheduledRunTimeout
where
    [ScheduleID] = @ScheduleID

GO
/****** Object:  StoredProcedure [dbo].[UpgradeSharePointPaths]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[UpgradeSharePointPaths]
    @OldPrefix nvarchar(440),
    @NewPrefix nvarchar(440),
    @PrefixLen int 

AS
BEGIN
UPDATE [Catalog]
  SET [Path] = @NewPrefix + SUBSTRING([Path], @PrefixLen, 5000)
  WHERE [Path] like @OldPrefix escape '*';
END

GO
/****** Object:  StoredProcedure [dbo].[UpgradeSharePointSchedulePaths]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[UpgradeSharePointSchedulePaths]
    @OldPath nvarchar(440),
    @NewPath nvarchar(440)

AS
BEGIN
-- Update Path if the pair (Name, NewPath) is unique.
UPDATE [Schedule]
  SET [Path] = @NewPath
  WHERE [Path] = @OldPath
  AND NOT EXISTS (SELECT [Name] FROM [Schedule] AS S2
                    WHERE S2.[Path] = @NewPath
                    AND S2.[Name] = [Schedule].[Name])

-- If any paths were not updated in the first pass, generate a unique name.
-- Update Name, Path to (Name + "(<ScheduleID>)", NewPath)
UPDATE [Schedule]
  SET [Path] = @NewPath,
       [Name] = [Name] + ' (' + CAST([ScheduleID] AS NCHAR(36)) + ')'
  WHERE [Path] = @OldPath
  AND NOT EXISTS (SELECT [Name] FROM [Schedule] AS S2
                    WHERE S2.[Path] = @NewPath
                    AND S2.[Name] = [Schedule].[Name] + ' (' + CAST([Schedule].[ScheduleID] AS NCHAR(36)) + ')')
END

GO
/****** Object:  StoredProcedure [dbo].[WriteChunkPortion]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[WriteChunkPortion]
@ChunkPointer binary(16),
@IsPermanentSnapshot bit,
@DataIndex int = NULL,
@DeleteLength int = NULL,
@Content image
AS

IF @IsPermanentSnapshot != 0 BEGIN
    UPDATETEXT ChunkData.Content @ChunkPointer @DataIndex @DeleteLength @Content
END ELSE BEGIN
    UPDATETEXT dbo.ReportServerTempDB_ChunkData.Content @ChunkPointer @DataIndex @DeleteLength @Content
END

GO
/****** Object:  StoredProcedure [dbo].[WriteChunkSegment]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[WriteChunkSegment]
	@ChunkId			uniqueidentifier,
	@IsPermanent		bit,
	@SegmentId			uniqueidentifier, 
	@DataIndex			int,
	@Length				int,
	@LogicalByteCount	int, 
	@Content			varbinary(max)
as begin
	declare @output table (actualLength int not null) ;
	if(@IsPermanent = 1) begin	
		update Segment
		set Content.write( substring(@Content, 1, @Length), @DataIndex, @Length )		
		output datalength(inserted.Content) into @output(actualLength)		
		where SegmentId = @SegmentId
		
		update ChunkSegmentMapping
		set LogicalByteCount = @LogicalByteCount, 
		    ActualByteCount = (select top 1 actualLength from @output)
		where ChunkSegmentMapping.ChunkId = @ChunkId and ChunkSegmentMapping.SegmentId = @SegmentId
	end
	else begin
		update dbo.ReportServerTempDB_Segment
		set Content.write( substring(@Content, 1, @Length), @DataIndex, @Length )		
		output datalength(inserted.Content) into @output(actualLength)		
		where SegmentId = @SegmentId
		
		update dbo.ReportServerTempDB_ChunkSegmentMapping
		set LogicalByteCount = @LogicalByteCount, 
		    ActualByteCount = (select top 1 actualLength from @output)
		where ChunkId = @ChunkId and SegmentId = @SegmentId
	end
	
	if(@@rowcount <> 1)
		raiserror('unexpected # of segments update', 16, 1)
end

GO
/****** Object:  StoredProcedure [dbo].[WriteFirstPortionPersistedStream]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[WriteFirstPortionPersistedStream]
@SessionID varchar(32),
@Index int,
@Name nvarchar(260) = NULL,
@MimeType nvarchar(260) = NULL,
@Extension nvarchar(260) = NULL,
@Encoding nvarchar(260) = NULL,
@Content image
AS

UPDATE dbo.ReportServerTempDB_PersistedStream set Content = @Content, [Name] = @Name, MimeType = @MimeType, Extension = @Extension WHERE SessionID = @SessionID AND [Index] = @Index

SELECT TEXTPTR(Content) FROM dbo.ReportServerTempDB_PersistedStream WHERE SessionID = @SessionID AND [Index] = @Index

GO
/****** Object:  StoredProcedure [dbo].[WriteLockSession]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[WriteLockSession]
@SessionID as varchar(32),
@Persisted bit,
@CheckLockVersion bit = 0,
@LockVersion int
AS
SET NOCOUNT OFF ; 
IF @Persisted = 1
BEGIN
	IF @CheckLockVersion = 0
	BEGIN
		UPDATE dbo.ReportServerTempDB_SessionLock WITH (ROWLOCK)
		SET SessionID = SessionID
		WHERE SessionID = @SessionID;
	END
	ELSE
	BEGIN
		DECLARE @ActualLockVersion as int
			
		UPDATE dbo.ReportServerTempDB_SessionLock WITH (ROWLOCK)
		SET SessionID = SessionID,
		LockVersion = LockVersion + 1
		WHERE SessionID = @SessionID	
		AND LockVersion = @LockVersion ;
			
		IF (@@ROWCOUNT = 0)
		BEGIN 
			SELECT @ActualLockVersion = LockVersion 
			FROM dbo.ReportServerTempDB_SessionLock WITH (ROWLOCK)
			WHERE SessionID = @SessionID;
							
			IF (@ActualLockVersion <> @LockVersion)
				RAISERROR ('Invalid version locked', 16,1)
			END 
		END
	END
ELSE
BEGIN
	INSERT INTO dbo.ReportServerTempDB_SessionLock WITH (ROWLOCK) (SessionID) VALUES (@SessionID)
END

GO
/****** Object:  StoredProcedure [dbo].[WriteNextPortionPersistedStream]    Script Date: 12/30/2015 10:40:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[WriteNextPortionPersistedStream]
@DataPointer binary(16),
@DataIndex int,
@DeleteLength int,
@Content image
AS

UPDATETEXT dbo.ReportServerTempDB_PersistedStream.Content @DataPointer @DataIndex @DeleteLength @Content

GO
