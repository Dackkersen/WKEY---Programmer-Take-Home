--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ProfileStore = require(script.Parent.ProfileStore)
local ProfileSchema = require(script.Parent.ProfileSchema)

local playerStore = ProfileStore.New("PlayerStore", ProfileSchema)

export type Data = typeof(ProfileSchema)
export type Profile = ProfileStore.Profile<Data>

local profiles = {} :: { [Player]: Profile }
local Profiles = {}

function Profiles:GetProfile(player: Player): Profile
    local profile = profiles[player]
    if not profile then
        local attempt = 0
        repeat
            attempt += 1
            if attempt > 10 then
                warn("Failed to get profile for player: ", player.Name)
                player:Kick("Failed to load profile, please rejoin.")
                error(`Failed to get profile for player: {player.Name}, attempts: {attempt}`)
            end

            task.wait(0.5)
            profile = profiles[player]
        until profile
    end
    return profiles[player]
end

function Profiles:Init()
    Players.PlayerAdded:Connect(function(player)
        local profileKey = RunService:IsStudio() and `{player.UserId}_"Studio"` or `{player.UserId}`
        local profile = playerStore:StartSessionAsync(profileKey, {
            Cancel = function()
                return player.Parent ~= Players
            end,
        })
        if not profile then
            warn(`Failed to load profile for {player.Name}`)
            player:Kick("Failed to load profile.")
            return
        end

        profile:AddUserId(player.UserId) -- Add the user ID to the profile for GDPR
        profile:Reconcile() -- Fill in missing variables from PROFILE_SCHEMA

        profile.OnSessionEnd:Connect(function()
            profiles[player] = nil
            warn(`ProfileStore session ended for {player.Name}`)
            player:Kick("ProfileStore session ended - Please rejoin!")
        end)

        if player.Parent ~= Players then
            profile:EndSession() -- The player left before the session started
            return
        end

        profiles[player] = profile :: any
    end)

    Players.PlayerRemoving:Connect(function(player)
        local profile = profiles[player]
        if profile then
            profile:EndSession()
        end
    end)
end

return Profiles