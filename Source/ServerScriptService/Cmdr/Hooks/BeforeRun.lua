local RunService = game:GetService("RunService")
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local ProfileService
Knit.OnStart():andThen(function()
	ProfileService = Knit.GetService("ProfileService")
end):catch(warn)

return function (registry)
	registry:RegisterHook("BeforeRun", function(context)
		local profileLoadedResult
		local CmdrGroup

		if RunService:IsServer() then
			profileLoadedResult = ProfileService:IsProfileLoaded(context.Executor)
		elseif RunService:IsClient() then
			profileLoadedResult = ProfileService:IsProfileLoaded():expect()
		end

		if profileLoadedResult ~= true then return "Your data has not been loaded yet." end

		if RunService:IsServer() then
			CmdrGroup = ProfileService:Get(context.Executor, "CmdrGroup")
		elseif RunService:IsClient() then
			CmdrGroup = ProfileService:Get("CmdrGroup"):expect()
		end

		if CmdrGroup < context.Group then
			return ("You don't have permission to run this command (lacking permission %d)"):format(context.Group)
		end
	end)
end
