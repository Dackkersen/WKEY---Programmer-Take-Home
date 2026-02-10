local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

export type BagInfo = {
	Color: Color3,
	Material: Enum.Material,
	Type: string,
	SpawnTime: number,
	Id: string,
}

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Network = require(Modules:WaitForChild("Network"))
local CatmullSpline = require(Modules:WaitForChild("CatmullSpline"))

local Assets = ReplicatedStorage:WaitForChild("Assets")

local Conveyor = workspace:WaitForChild("Conveyor")
local Bucket = workspace:WaitForChild("Bucket")
local Path = Conveyor:WaitForChild("Path")
local Speed = 10

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer and localPlayer:WaitForChild("PlayerGui")
local conveyorControl = playerGui and playerGui:WaitForChild("ConveyorControl")
local frame = conveyorControl and conveyorControl:WaitForChild("Frame")
local box = frame and frame:WaitForChild("Box")

local spline
local bags = {}
local propBags = {}

local ConveyorController = {
	Priority = 1,
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

local function spawnBag(bag: BagInfo): BasePart
	local bagAsset = Assets:WaitForChild(bag.Type)
	if not bagAsset then
		bagAsset = Assets:WaitForChild("Bag")
	end

	local bagPart = bagAsset:Clone()
	bagPart.Color = bag.Color
	bagPart.Material = bag.Material
	bagPart.Parent = workspace.Bags

	local clickDetector = Instance.new("ClickDetector")
	clickDetector.Parent = bagPart

	clickDetector.MouseClick:Connect(function()
		print("Client ID:", bag.Id)
		Network.GetBagInfo:FireServer(bag.Id)
	end)

	return bagPart
end

local function spawnLaunchingBag(bag: BagInfo, initialCFrame: CFrame)
	local bagPart = spawnBag(bag)
	bagPart.CanCollide = true
	bagPart.CFrame = initialCFrame
	bagPart.AssemblyLinearVelocity = Vector3.new(-20, 175, 0)
	bagPart.AssemblyAngularVelocity = Vector3.new(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10))

	table.insert(propBags, bagPart)
end

function ConveyorController:InitUI()
	conveyorControl.Enabled = false

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
		local bagPart = spawnBag(bag)
		table.insert(bags, {
			Part = bagPart,
			SpawnTime = bag.SpawnTime,
			Type = bag.Type,
			Color = bag.Color,
			Material = bag.Material,
			d = 0,
			SideOffset = (math.random() - 0.75) * 3,
			UpOffset = bagPart.Size.Y / 2.75,
		})
	end)

	Network.Nuke.OnClientEvent:Connect(function()
		local C17 = Assets:WaitForChild("C17")
		local clone = C17:Clone()
		clone.Parent = workspace

		local spawned = false
		local bombClone
		local connection
		connection = RunService.Heartbeat:Connect(function()
			clone:PivotTo(clone:GetPivot() * CFrame.new(0, 0, -1))
			local planeMagnitude = (clone:GetPivot().Position - Bucket.Explosion.Position).Magnitude
			if planeMagnitude < 191 or spawned then
				if not spawned then
					local bomb = Assets:WaitForChild("Bomb")
					bombClone = bomb:Clone()
					bombClone:PivotTo(clone.MainPart.CFrame)
					bombClone.Parent = workspace
					spawned = true
				end

				bombClone:PivotTo(bombClone:GetPivot() * CFrame.new(0, 0, -1))

				local bombMagnitude = (bombClone:GetPivot().Position - Bucket.Explosion.Position).Magnitude

				if bombMagnitude < 25 then
					connection:Disconnect()
					bombClone:Destroy()
					clone:Destroy()

					SoundService:PlayLocalSound(SoundService.Nuke)

					Bucket.Explosion.ParticleEmitter:Emit(100)

					for _, bag in propBags do
						bag:Destroy()
					end

					propBags = {}
				end
			end
		end)
	end)

	local spawnedBags, ownerChosen = Network.GetSpawnedBags:InvokeServer()
	if not ownerChosen then
		conveyorControl.Enabled = true
	end

	if spawnedBags then
		local serverTime = workspace:GetServerTimeNow()
		for _, bag in ipairs(spawnedBags) do
			local bagPart = spawnBag(bag)

			local timeSinceSpawn = serverTime - bag.SpawnTime
			local distanceAlongSpline = (timeSinceSpawn * Speed) % spline:GetLength()

			table.insert(bags, {
				Part = bagPart,
				SpawnTime = bag.SpawnTime,
				d = distanceAlongSpline,
				SideOffset = (math.random() - 0.75) * 3,
				UpOffset = bagPart.Size.Y / 2.5,
				Type = bag.Type,
				Color = bag.Color,
				Material = bag.Material,
			})
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

			if workspace:GetServerTimeNow() >= (spawnTime + lifetime - 0.5) then
				bag.Part:Destroy()
				spawnLaunchingBag(bag, bag.Part.CFrame)
				table.remove(bags, i)
			end
		end
	end)
end

return ConveyorController
