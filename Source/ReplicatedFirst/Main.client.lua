local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local Syscore = require(ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("Syscore"))

if not game:IsLoaded() then
    game.Loaded:Wait()
end

Syscore.AddFolderOfModules(ReplicatedFirst.Controllers)
Syscore.Start()