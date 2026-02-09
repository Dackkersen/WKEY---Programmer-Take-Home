local Profiles = require(script.Profiles)

export type Profile = Profiles.Profile

local PlayerData = {
	Priority = -100,
	Name = "PlayerData",
	Icon = "🧑‍🤝‍🧑",
}

function PlayerData:GetProfile(player: Player): Profiles.Profile
	return Profiles:GetProfile(player)
end

function PlayerData:GetData(player: Player): Profiles.Data
	return Profiles:GetProfile(player).Data
end

function PlayerData:Init()
	Profiles:Init()
end

return PlayerData
