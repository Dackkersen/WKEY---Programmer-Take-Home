The way I approached the task was simply I didn't want the server to handle any visual spawning / moving the objects since the client can handle all of that which allows the server to "chill" and not waste resources on that, all I had the server do was store the data of the bag such as (SpawnTime, Color, etc) then let the clients render everything, Using the StartTime applied from the server I knew when the bags hit the end of the track by doing some math using the spawnTime and doing PathLength/Speed and then checking the Current Servertime based on that.

With startTime it also allowed me to make sure that if new players joined the game while bags were already spawned it would know where exactly those bags would be and could replicated it on their client

Originally for the movement of the Bags I wanted to just apply Velocity but then realized it would only really work for straight paths but we'd also run into physics issues, collisions and messes, so I went with Catmull Splines which ended up making the conveyor feel really nice.

I added some little spice and "event" for when the Bags get deleted so let some get deleted and you'll see the surprise..
For the actual spawning of the bags I went a little basic but other ideas I had was: Falling down, popup from a hatch or something with a crane.
