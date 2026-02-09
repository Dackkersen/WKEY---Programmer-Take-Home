local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

export type BagInfo = {
	Color: Color3,
	Material: Enum.Material,
	SpawnTime: number,
	Id: string,
}

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Network = require(Modules:WaitForChild("Network"))
local CatmullSpline = require(Modules:WaitForChild("CatmullSpline"))

local Conveyor = workspace:WaitForChild("Conveyor")
local Path = Conveyor:WaitForChild("Path")
local Speed = 10

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer and localPlayer:WaitForChild("PlayerGui")
local conveyorControl = playerGui and playerGui:WaitForChild("ConveyorControl")
local frame = conveyorControl and conveyorControl:WaitForChild("Frame")
local box = frame and frame:WaitForChild("Box")

local spline
local bags = {}

local ConveyorController = {
	Priority = 99,
	Name = "ConveyorController",
	Icon = "🧤",
}

local function createSpline()
	repeat
		task.wait()
	until Path and #Path:GetChildren() > 2

	spline = CatmullSpline.new(Path, {
		Closed = false,
		SamplesPerSegment = 100,
	})
end

local function spawnPart(bag: BagInfo): BasePart
	local bagPart = Instance.new("Part")
	bagPart.Size = Vector3.new(2, 1, 1)
	bagPart.Color = bag.Color
	bagPart.Material = bag.Material
	bagPart.Anchored = true
	bagPart.CanCollide = false
	bagPart:SetAttribute("Id", bag.Id)
	bagPart.Parent = workspace.Bags

	local clickDetector = Instance.new("ClickDetector")
	clickDetector.Parent = bagPart

	clickDetector.MouseClick:Connect(function()
		print("Client ID:", bag.Id)
		Network.GetBagInfo:FireServer(bag.Id)
	end)

	return bagPart
end

function ConveyorController:InitUI()
	box.Changed:Connect(function()
		local newInterval = tonumber(box.Text)
		if newInterval and newInterval > 0 then
			Network.ChangeSpawnInterval:FireServer(newInterval)
		end
	end)
end

function ConveyorController:Init()
	self:InitUI()
	createSpline()
	Network.BagSpawned.OnClientEvent:Connect(function(bag: BagInfo)
		local bagPart = spawnPart(bag)
		table.insert(
			bags,
			{ Part = bagPart, SpawnTime = bag.SpawnTime, d = 0, SideOffset = (math.random() - 0.75) * 3, UpOffset = 0 }
		)
	end)

	local spawnedBags = Network.GetSpawnedBags:InvokeServer()
	if spawnedBags then
		local serverTime = workspace:GetServerTimeNow()
		for _, bag in ipairs(spawnedBags) do
			local bagPart = spawnPart(bag)

			local timeSinceSpawn = serverTime - bag.SpawnTime
			local distanceAlongSpline = (timeSinceSpawn * Speed) % spline:GetLength()

			table.insert(bags, { Part = bagPart, SpawnTime = bag.SpawnTime, d = distanceAlongSpline })
		end
	end

	RunService.Heartbeat:Connect(function(deltaTime)
		local length = spline:GetLength()
		local lifetime = length / Speed
		for i = #bags, 1, -1 do
            local bag = bags[i]
            local spawnTime = bag.SpawnTime

            bag.d = (bag.d + Speed * deltaTime) % length

            local p = spline:GetPositionAtDistance(bag.d)
            local aheadD = (bag.d + 0.2) % length
            local p2 = spline:GetPositionAtDistance(aheadD)
            local tangent = (p2 - p)

            if tangent.Magnitude < math.huge then
                tangent = Vector3.zAxis
            else
                tangent = tangent.Unit
            end

            local right = tangent:Cross(Vector3.yAxis)
            if right.Magnitude < math.huge then
                right = Vector3.xAxis
            else
                right = right.Unit
            end

            local side = bag.SideOffset or 0
            local upOff = bag.UpOffset or 0

            bag.Part.Position = p + right * side + Vector3.yAxis * upOff

			if workspace:GetServerTimeNow() >= spawnTime + lifetime then
				bag.Part:Destroy()
				table.remove(bags, i)
			end
		end
	end)
end

return ConveyorController
