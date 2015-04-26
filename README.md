# knotifier

Depends on something to push data to redis' pub/sub on the convention of of the following channels: ``notifications.GENERATED_KEY-OWNER_ID`` and ``user.USER_ID``

Keys can be static, but you should only store them for at most two weeks before marking them as invalid, this is easily done using a SQL database.

You have two methods of generating new keys, one is resource efficient, the other is processing efficient.

You can either:

1. Generate a new key every time the current key is over a certain age. (processing efficient)
2. Delete keys that are over a certain age. (resource efficient)
