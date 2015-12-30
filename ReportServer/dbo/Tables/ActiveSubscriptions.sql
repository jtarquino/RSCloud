CREATE TABLE [dbo].[ActiveSubscriptions] (
    [ActiveID]           UNIQUEIDENTIFIER NOT NULL,
    [SubscriptionID]     UNIQUEIDENTIFIER NOT NULL,
    [TotalNotifications] INT              NULL,
    [TotalSuccesses]     INT              NOT NULL,
    [TotalFailures]      INT              NOT NULL,
    CONSTRAINT [PK_ActiveSubscriptions] PRIMARY KEY CLUSTERED ([ActiveID] ASC),
    CONSTRAINT [FK_ActiveSubscriptions_Subscriptions] FOREIGN KEY ([SubscriptionID]) REFERENCES [dbo].[Subscriptions] ([SubscriptionID]) ON DELETE CASCADE
);

