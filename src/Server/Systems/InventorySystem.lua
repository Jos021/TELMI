--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Config     = require(ReplicatedStorage.Shared.Config)
local Remotes    = require(ReplicatedStorage.Shared.Remotes)
local Utils      = require(ReplicatedStorage.Shared.Utils)
local DataSystem = require(script.Parent.DataSystem)

local InventorySystem = {}

-- Cache de inventário em memória durante a sessão
-- inventory[userId] = { Wood = 10, Stone = 5, ... }
local inventories: {[number]: {[string]: number}} = {}

-- ----------------------------------------------------------------
-- INICIALIZAÇÃO
-- ----------------------------------------------------------------
function InventorySystem.loadForPlayer(player: Player)
	local data = DataSystem.loadInventory(player)
	inventories[player.UserId] = data
	InventorySystem.syncToClient(player)
end

function InventorySystem.saveForPlayer(player: Player)
	local inv = inventories[player.UserId]
	if inv then
		DataSystem.saveInventory(player, inv)
	end
	inventories[player.UserId] = nil
end

-- ----------------------------------------------------------------
-- ACESSO
-- ----------------------------------------------------------------
function InventorySystem.get(player: Player): {[string]: number}
	return inventories[player.UserId] or {}
end

function InventorySystem.getAmount(player: Player, item: string): number
	local inv = inventories[player.UserId]
	return inv and (inv[item] or 0) or 0
end

function InventorySystem.addItem(player: Player, item: string, amount: number)
	local inv = inventories[player.UserId]
	if not inv then return end
	inv[item] = (inv[item] or 0) + math.max(0, amount)
	InventorySystem.syncToClient(player)
end

-- Retorna true se conseguiu remover, false se não tinha suficiente
function InventorySystem.removeItem(player: Player, item: string, amount: number): boolean
	local inv = inventories[player.UserId]
	if not inv then return false end
	if (inv[item] or 0) < amount then
		return false
	end
	inv[item] -= amount
	if inv[item] <= 0 then
		inv[item] = nil
	end
	InventorySystem.syncToClient(player)
	return true
end

function InventorySystem.hasResources(player: Player, needed: {[string]: number}): boolean
	local inv = inventories[player.UserId] or {}
	return Utils.hasResources(inv, needed)
end

function InventorySystem.consumeResources(player: Player, needed: {[string]: number}): boolean
	if not InventorySystem.hasResources(player, needed) then
		return false
	end
	local inv = inventories[player.UserId]
	Utils.consumeResources(inv, needed)
	InventorySystem.syncToClient(player)
	return true
end

-- Retira percentual dos recursos como saque parcial de raid
function InventorySystem.takeLoot(player: Player, percent: number): {[string]: number}
	local inv = inventories[player.UserId] or {}
	local loot: {[string]: number} = {}
	for item, amount in pairs(inv) do
		local stolen = math.floor(amount * percent)
		if stolen > 0 then
			loot[item] = stolen
			inv[item] = amount - stolen
		end
	end
	InventorySystem.syncToClient(player)
	return loot
end

-- Adiciona vários itens de uma vez (ex: distribuir saque)
function InventorySystem.addLoot(player: Player, loot: {[string]: number})
	local inv = inventories[player.UserId]
	if not inv then return end
	Utils.addResources(inv, loot)
	InventorySystem.syncToClient(player)
end

-- ----------------------------------------------------------------
-- SINCRONIZAÇÃO
-- ----------------------------------------------------------------
function InventorySystem.syncToClient(player: Player)
	local inv = inventories[player.UserId] or {}
	Remotes.UpdateInventory:FireClient(player, inv)
end

-- ----------------------------------------------------------------
-- EVENTOS REMOTOS
-- ----------------------------------------------------------------
Remotes.InventoryAction.OnServerEvent:Connect(function(player, actionType, item, amount)
	-- Por enquanto aceita apenas "use" para consumir comida (restore HP)
	if actionType == "use" and item == Config.RESOURCES.FOOD then
		if InventorySystem.removeItem(player, item, 1) then
			local char = player.Character
			if char then
				local hum = char:FindFirstChild("Humanoid") :: Humanoid?
				if hum then
					hum.Health = math.min(hum.MaxHealth, hum.Health + 20)
				end
			end
			Utils.notify(player, "Você comeu e recuperou 20 HP.")
		end
	end
end)

return InventorySystem
