CREATE TABLE [dbo].[SubscriptionsBeingDeleted] (
    [SubscriptionID] UNIQUEIDENTIFIER NOT NULL,
    [CreationDate]   DATETIME         NOT NULL,
    CONSTRAINT [PK_SubscriptionsBeingDeleted] PRIMARY KEY CLUSTERED ([SubscriptionID] ASC)
);

