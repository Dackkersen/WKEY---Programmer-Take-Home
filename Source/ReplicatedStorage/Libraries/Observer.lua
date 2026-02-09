--!strict
local RunService = game:GetService("RunService")
local HTTPService = game:GetService("HttpService")

local VERSION = "1.0.0"

if RunService:IsServer() then
	warn(`👀 v{VERSION}`)
end

--[=[
	@within Observer
	@interface Connection
	.Disconnect (self: Connection) -> () -- Disconnects the connection, removing the callback from the event.
]=]
export type Connection = {
	Disconnect: (self: Connection) -> (),
}

--[=[
	@within Observer
	@interface Event<T...>

	.Connect (self: Event<T...>, callback: (...any) -> ()) -> Connection -- Connects a callback to the event. The callback will be called with the event's parameters when the event is fired.
	.Fire (self: Event<T...>, ...: T...) -> () -- Fires the event with the given parameters. All connected callbacks will be called with these parameters.
]=]
export type Event<T...> = {
	Connect: (self: Event<T...>, callback: (...any) -> ()) -> Connection,
	Fire: (self: Event<T...>, T...) -> (),
}

local events: { [string]: any } = {}

local observers: { [string]: {
	callbacks: { [string]: (...any) -> () },
} } = {}

--[=[
	@class Observer

	- Wally Package: [Observer](https://wally.run/package/naxious/observer)

	A typed observer that notifies subscribers when its value changes.
	Observers can be created and subscribed to from any module.
	They are useful for decoupling modules and creating a more modular codebase.
	The Observer class is a singleton and should not be instantiated.
	The Observer class provides two methods for creating and getting observers.
	You can create an observer with a specific type and subscribe to it with a callback.
	When the observer's value changes, all subscribed callbacks are called with the new value.

	One of my favorite explanations of the observer pattern is from [Refactoring Guru](https://refactoring.guru/design-patterns/observer).

	Here's an example of how to use the Observer class:
	`Firstly, Setup Event Module`
	```lua
	local Observer = require(path.to.Observer)

	local events = {
		["PlayerDamaged"] = Observer.Create("PlayerDamaged") :: Observer.Event<Player, number>,
		["MorningTime"] = Observer.Create("MorningTime") :: Observer.Event<string>,
	}

	return events
	```
	`Secondly, Connect to an Event in any Module`
	```lua
	local events = require(path.to.Events)

	events.MorningTime:Connect(function(morningString: string)
		if morningString == "Good Morning" then
			print(`{morningString}! It's a awesome day!`)
		elseif morningString == "Bad Morning" then
			print(`{morningString}! It's what we get when it rains!`)
		end
	end)

	events.PlayerDamaged:Connect(function(player: Player, damage: number)
		print(`{player.Name} took {damage} damage!`)
		playerEffects:ShakeScreen() -- example function
		particleSystem:BloodSplatter(player.Position) -- example function
	end)
	```
	`Lastly, Fire the Event Value in any Module`
	```lua
	local events = require(path.to.Events)

	events.MorningTime:Fire("Good Morning")

	while player:IsStandingInFire() do
		events.PlayerDamaged:Fire(10)
	end
	```

	:::note
		Observers are client/server specific and cannot be shared between them.
		You would need to create a separate observer for each side.
		OR create some sort of networked event system to communicate between them.
	:::
]=]

local Observer = {}

local function createEvent<T...>(name: string): Event<T...>
	local event = {}

	function event:Connect(callback: (T...) -> ()): Connection
		if not observers[name] then
			Observer.Create(name)
		end
		local id = HTTPService:GenerateGUID(false)
		observers[name].callbacks[id] = callback

		return {
			Disconnect = function()
				observers[name].callbacks[id] = nil
			end,
		}
	end

	function event:Fire(...: T...)
		if not observers[name] then
			return
		end

		for _, callback in observers[name].callbacks do
			callback(...)
		end
	end

	return event :: Event<T...>
end

--[=[
	Creates a new typed observer with the specified name.

	```lua
	local Observer = require(path.to.Observer)

	local events = {
		["PlayerDamaged"] = Observer.Create("PlayerDamaged") :: Observer.Event<Player, number>,
		["MorningTime"] = Observer.Create("MorningTime") :: Observer.Event<string>,
	}

	return events
	```
]=]

function Observer.Create<T...>(name: string): Event<T...>
	assert(not observers[name], `Observer '${name}' already exists`)

	observers[name] = {
		callbacks = {},
	}

	local event = createEvent(name)
	events[name] = event

	return event :: Event<T...>
end

return Observer