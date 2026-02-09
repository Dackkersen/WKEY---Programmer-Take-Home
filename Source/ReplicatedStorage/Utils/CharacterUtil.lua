local CharacterUtil = {}

function CharacterUtil:GetCharacter(player)
	return player.Character or player.CharacterAdded:Wait()
end

function CharacterUtil:GetObject(player, objectName, timeout)
	local character = self:GetCharacter(player)
	if character ~= nil then
		return character:WaitForChild(objectName, timeout)
	end
end

function CharacterUtil:GetHumanoid(player, timeout)
	local character = self:GetCharacter(player)
	if character ~= nil then
		return character:WaitForChild("Humanoid", timeout)
	end
end

function CharacterUtil:GetRootPart(player, timeout)
	local character = self:GetCharacter(player)
	if character ~= nil then
		return character:WaitForChild("HumanoidRootPart", timeout)
	end
end

function CharacterUtil:OnCharacterReady(player, func)
	local character = self:GetCharacterAsync(player)
	if character ~= nil then
		task.wait()
		func(character)
	end
	return player.CharacterAdded:Connect(function(character)
		self:GetHumanoid(player)
		self:GetRootPart(player)
		task.wait()
		func(character)
	end)
end

--> Asynchronous versions
function CharacterUtil:GetCharacterAsync(player)
	return player.Character
end

function CharacterUtil:GetObjectAsync(player, objectName)
	local character = self:GetCharacterAsync(player)
	if character ~= nil then
		return character:FindFirstChild(objectName)
	end
end

function CharacterUtil:GetHumanoidAsync(player)
	local character = self:GetCharacterAsync(player)
	if character ~= nil then
		return character:FindFirstChild("Humanoid")
	end
end

function CharacterUtil:GetRootPartAsync(player)
	local character = self:GetCharacterAsync(player)
	if character ~= nil then
		return character:FindFirstChild("HumanoidRootPart")
	end
end

return CharacterUtil