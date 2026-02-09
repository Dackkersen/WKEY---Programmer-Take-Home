local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Syscore = require(ReplicatedStorage.Libraries.Syscore)

Syscore.AddFolderOfModules(ServerScriptService.Services)
Syscore.Start()
