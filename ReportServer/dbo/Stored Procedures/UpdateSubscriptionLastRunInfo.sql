﻿
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
