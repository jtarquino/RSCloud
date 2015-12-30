CREATE TABLE [dbo].[Event] (
    [EventID]          UNIQUEIDENTIFIER NOT NULL,
    [EventType]        NVARCHAR (260)   NOT NULL,
    [EventData]        NVARCHAR (260)   NULL,
    [TimeEntered]      DATETIME         NOT NULL,
    [ProcessStart]     DATETIME         NULL,
    [ProcessHeartbeat] DATETIME         NULL,
    [BatchID]          UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_Event] PRIMARY KEY CLUSTERED ([EventID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Event2]
    ON [dbo].[Event]([ProcessStart] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Event_TimeEntered]
    ON [dbo].[Event]([TimeEntered] ASC);

