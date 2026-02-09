local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Network = require(ReplicatedStorage.Modules.Network)

local SpawnInterval = 1

local spawnedBags = {}

local ConveyorService = {
	Priority = 99,
	Name = "ConveyorService",
	Icon = "🧤",
}

local function getRandomColor(): Color3
	local randomR = math.random(0, 255)
	local randomG = math.random(0, 255)
	local randomB = math.random(0, 255)
	return Color3.fromRGB(randomR, randomG, randomB)
end

local function getRandomMaterial(): Enum.Material
	local material = Enum.Material:GetEnumItems()[math.random(1, #Enum.Material:GetEnumItems())]
	if material == Enum.Material.Air then
		return getRandomMaterial()
	end
	return material
end

local function getBagById(id: string)
	for _, bag in spawnedBags do
		if bag.Id ~= id then
			continue
		end

		return bag
	end
	return nil
end

function ConveyorService:ChangeSpawnInterval(newInterval: number)
	SpawnInterval = newInterval
end

function ConveyorService:SpawnBag()
	local randomColor: Color3 = getRandomColor()
	local randomMaterial: Enum.Material = getRandomMaterial()
	local spawnTime: number = workspace:GetServerTimeNow()

	local bag = {
		Id = HttpService:GenerateGUID(false),
		Color = randomColor,
		Material = randomMaterial,
		SpawnTime = spawnTime,
	}

	table.insert(spawnedBags, bag)
	Network.BagSpawned:FireAllClients(bag)

	local lifetime = 100 / 10
	task.delay(lifetime, function()
		for i = #spawnedBags, 1, -1 do
			if spawnedBags[i] == bag then
				table.remove(spawnedBags, i)
				break
			end
		end
	end)
end

function ConveyorService:Init()
	local startTime = tick()

	Network.GetSpawnedBags.OnServerInvoke = function()
		return spawnedBags
	end

	Network.GetBagInfo.OnServerEvent:Connect(function(_: Player, bagId: string)
		if not bagId then
			return
		end

		local bag = getBagById(bagId)
		if bag then
			print("Server ID: ", bag.Id, bag)
		else
			print("Bag not found for ID:", bagId)
		end
	end)

	Network.ChangeSpawnInterval.OnServerEvent:Connect(function(_: Player, newInterval: number)
		if type(newInterval) ~= "number" or newInterval <= 0 then
			return
		end

		self:ChangeSpawnInterval(newInterval)
	end)

	RunService.Heartbeat:Connect(function()
		local timeElapsed = tick() - startTime
		if timeElapsed < SpawnInterval then
			return
		end

		self:SpawnBag()
		startTime = tick()
	end)
end

return ConveyorService
