--|=| Services
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

--|=| Core
local ProductService = {
	Priority = 99,
	Name = "ProductService",
	Icon = "🛒",
}

--|=| Constants
local ProductStore = DataStoreService:GetDataStore("ProductStore")

local Handlers = {}

-- Handlers[products.GameEgg3] = function(data, player)
-- 	task.spawn(function()
-- 	end)
-- 	return true
-- end

function ProductService:Init()
	--|=| SERVICE REFERENCES
	MarketplaceService.ProcessReceipt = function(ReceiptInfo)
		local Key = ReceiptInfo.PlayerId .. "_" .. ReceiptInfo.PurchaseId

		local Success, IsPurchaseRecorded = pcall(
			ProductStore.UpdateAsync,
			ProductStore,
			Key,
			function(AlreadyPurchased)
				if AlreadyPurchased then
					return true
				end

				local Player = Players:GetPlayerByUserId(ReceiptInfo.PlayerId)
				local Handler = Handlers[ReceiptInfo.ProductId]

				if not Player or not Handler then
					return nil
				end

				local _Success, Result = pcall(Handler, ReceiptInfo, Player)

				if not _Success or not Result then
					warn("Failed to process receipt!", _Success, Result)
					return nil
				end

				return true
			end
		)

		if not Success or IsPurchaseRecorded == nil then
			if not Success then
				warn("Failed to process receipt!", IsPurchaseRecorded)
			end

			warn("Failed to Process receipt!")
			return Enum.ProductPurchaseDecision.NotProcessedYet
		else
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end
end

return ProductService
