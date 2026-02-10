local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bolt = require(ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("Bolt"))

local Network = {
	BagSpawned = Bolt.ReliableEvent("BagSpawned") :: Bolt.ReliableEvent<
		({ Color: Color3, Material: Enum.Material, Type: string, SpawnTime: number, Id: string })
	>,
	Nuke = Bolt.ReliableEvent("Nuke") :: Bolt.ReliableEvent<()>,
	GetBagInfo = Bolt.ReliableEvent("GetBagInfo") :: Bolt.ReliableEvent<(string)>,
	ChangeSpawnInterval = Bolt.ReliableEvent("ChangeSpawnInterval") :: Bolt.ReliableEvent<(number)>,
	GetSpawnedBags = Bolt.RemoteFunction("GetSpawnedBags") :: Bolt.RemoteFunction<
		(),
		({ Color: Color3, Material: Enum.Material, Type: string, SpawnTime: number, Id: string })
	>,
}

return Network
