local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bolt = require(ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("Bolt"))

local Network = {
    Money = Bolt.RemoteProperty("Money", 0) :: Bolt.RemoteProperty<number>,
}

return Network