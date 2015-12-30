CREATE TABLE [dbo].[RunningJobs] (
    [JobID]        NVARCHAR (32)    NOT NULL,
    [StartDate]    DATETIME         NOT NULL,
    [ComputerName] NVARCHAR (32)    NOT NULL,
    [RequestName]  NVARCHAR (425)   NOT NULL,
    [RequestPath]  NVARCHAR (425)   NOT NULL,
    [UserId]       UNIQUEIDENTIFIER NOT NULL,
    [Description]  NTEXT            NULL,
    [Timeout]      INT              NOT NULL,
    [JobAction]    SMALLINT         NOT NULL,
    [JobType]      SMALLINT         NOT NULL,
    [JobStatus]    SMALLINT         NOT NULL,
    CONSTRAINT [PK_RunningJobs] PRIMARY KEY CLUSTERED ([JobID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_RunningJobsStatus]
    ON [dbo].[RunningJobs]([ComputerName] ASC, [JobType] ASC);

