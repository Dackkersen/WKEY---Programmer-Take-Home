local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Bag = Assets:WaitForChild("Bag")

local connectedConveyors = {}
local spawnedBags = {}
local defaultConveyorStats = {
	Speed = 10,
	SpawnRate = 1,
}

local ConveyorTestController = {
	Priority = 99,
	Name = "ConveyorTestController",
	Icon = "🧤",
}

function ConveyorTestController:InitConveyor(conveyor: Model)
	local beltPart = conveyor:WaitForChild("BeltPart")
	if not beltPart then
		warn("Conveyor model '" .. conveyor.Name .. "' is missing a 'BeltPart'.")
		return
	end

	local conveyorStats = {
		Speed = beltPart:GetAttribute("Speed") or defaultConveyorStats.Speed,
		SpawnRate = beltPart:GetAttribute("SpawnRate") or defaultConveyorStats.SpawnRate,
		StartCFrame = beltPart.CFrame * CFrame.new(0, 0, (beltPart.Size.Z / 2 - 2)),
		EndCFrame = beltPart.CFrame * CFrame.new(0, 0, (-beltPart.Size.Z / 2 + 2)),
		Interval = 0,
	}

	table.insert(connectedConveyors, {
		Model = conveyor,
		BeltPart = beltPart,
		Stats = conveyorStats,
	})
end

function ConveyorTestController:Init()
	local taggedConveyors: { Model } = CollectionService:GetTagged("Conveyor")

	if #taggedConveyors == 0 then
		warn("No conveyors found with the 'Conveyor' tag.")
		return
	end

	for _, conveyor in taggedConveyors do
		self:InitConveyor(conveyor)
	end

	local startTime = tick()

	RunService.Heartbeat:Connect(function()
		local timeElapsed = tick() - startTime
		startTime = tick()

		for _, data in connectedConveyors do
			data.Stats.Interval += timeElapsed

			if data.Stats.Interval >= data.Stats.SpawnRate then
				data.Stats.Interval = 0
				local bagClone = Bag:Clone()
				bagClone.CFrame = data.Stats.StartCFrame
				bagClone.Parent = workspace.Bags
				spawnedBags[#spawnedBags + 1] = {
					Bag = bagClone,
					ConveyorData = data,
				}
				print("Spawn Bag")
			end
		end

		for _, bag in spawnedBags do
			local direction = bag.ConveyorData.BeltPart.CFrame.LookVector
			local currentVeloctity = bag.ConveyorData.BeltPart.AssemblyLinearVelocity

			local target = direction * bag.ConveyorData.Stats.Speed
			bag.Bag.AssemblyLinearVelocity = Vector3.new(target.X, currentVeloctity.Y, target.Z)
		end
	end)
end

return ConveyorTestController
