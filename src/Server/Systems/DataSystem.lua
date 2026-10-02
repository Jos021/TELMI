--!strict
local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local DataSystem = {}

local inventoryStore = DataStoreService:GetDataStore(Config.DS_INVENTORY)
local baseStore      = DataStoreService:GetDataStore(Config.DS_BASE)
local clanStore      = DataStoreService:GetDataStore(Config.DS_CLAN)

-- Cache local para evitar leituras duplicadas
local cache: {[string]: any} = {}

local function key(player: Player, prefix: string): string
	return prefix .. "_" .. tostring(player.UserId)
end

-- ----------------------------------------------------------------
-- INVENTÁRIO
-- ----------------------------------------------------------------
function DataSystem.loadInventory(player: Player): {[string]: number}
	local k = key(player, "inv")
	if cache[k] then
		return cache[k]
	end
	local ok, data = pcall(function()
		return inventoryStore:GetAsync(tostring(player.UserId))
	end)
	local inventory: {[string]: number} = (ok and data) and data or {}
	cache[k] = inventory
	return inventory
end

function DataSystem.saveInventory(player: Player, inventory: {[string]: number})
	cache[key(player, "inv")] = inventory
	task.spawn(function()
		local ok, err = pcall(function()
			inventoryStore:SetAsync(tostring(player.UserId), inventory)
		end)
		if not ok then
			warn("[DataSystem] Erro ao salvar inventário de " .. player.Name .. ": " .. tostring(err))
		end
	end)
end

-- ----------------------------------------------------------------
-- BASE
-- ----------------------------------------------------------------
type BaseData = {
	level: number,
	buildings: {{
		id: string,
		buildingType: string,
		cframe: {number},  -- CFrame serializado como array de 12 números
		health: number,
	}},
	nucleusId: string?,
}

function DataSystem.loadBase(player: Player): BaseData
	local k = key(player, "base")
	if cache[k] then
		return cache[k]
	end
	local ok, data = pcall(function()
		return baseStore:GetAsync(tostring(player.UserId))
	end)
	local base: BaseData = (ok and data) and data or { level = 1, buildings = {}, nucleusId = nil }
	cache[k] = base
	return base
end

function DataSystem.saveBase(player: Player, baseData: BaseData)
	cache[key(player, "base")] = baseData
	task.spawn(function()
		local ok, err = pcall(function()
			baseStore:SetAsync(tostring(player.UserId), baseData)
		end)
		if not ok then
			warn("[DataSystem] Erro ao salvar base de " .. player.Name .. ": " .. tostring(err))
		end
	end)
end

-- ----------------------------------------------------------------
-- CLÃ (armazenado por clanId)
-- ----------------------------------------------------------------
type ClanData = {
	id: string,
	name: string,
	leaderId: number,
	members: {number},
	level: number,
	nucleusHealth: number,
}

function DataSystem.loadClan(clanId: string): ClanData?
	local k = "clan_" .. clanId
	if cache[k] then
		return cache[k]
	end
	local ok, data = pcall(function()
		return clanStore:GetAsync(clanId)
	end)
	if ok and data then
		cache[k] = data
		return data
	end
	return nil
end

function DataSystem.saveClan(clan: ClanData)
	cache["clan_" .. clan.id] = clan
	task.spawn(function()
		local ok, err = pcall(function()
			clanStore:SetAsync(clan.id, clan)
		end)
		if not ok then
			warn("[DataSystem] Erro ao salvar clã " .. clan.name .. ": " .. tostring(err))
		end
	end)
end

function DataSystem.deleteClan(clanId: string)
	cache["clan_" .. clanId] = nil
	task.spawn(function()
		pcall(function()
			clanStore:RemoveAsync(clanId)
		end)
	end)
end

-- Mapeia userId → clanId para pesquisa rápida
local playerClanStore = DataStoreService:GetDataStore("PlayerClan_v1")

function DataSystem.getPlayerClanId(userId: number): string?
	local k = "pclan_" .. tostring(userId)
	if cache[k] ~= nil then
		return cache[k] or nil
	end
	local ok, data = pcall(function()
		return playerClanStore:GetAsync(tostring(userId))
	end)
	local result = (ok and data) and data or nil
	cache[k] = result or false
	return result
end

function DataSystem.setPlayerClanId(userId: number, clanId: string?)
	local k = "pclan_" .. tostring(userId)
	cache[k] = clanId or false
	task.spawn(function()
		pcall(function()
			if clanId then
				playerClanStore:SetAsync(tostring(userId), clanId)
			else
				playerClanStore:RemoveAsync(tostring(userId))
			end
		end)
	end)
end

-- ----------------------------------------------------------------
-- LIMPEZA DE CACHE AO SAIR
-- ----------------------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
	cache[key(player, "inv")]  = nil
	cache[key(player, "base")] = nil
	cache["pclan_" .. tostring(player.UserId)] = nil
end)

return DataSystem
