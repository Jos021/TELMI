--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Config             = require(ReplicatedStorage.Shared.Config)
local Remotes            = require(ReplicatedStorage.Shared.Remotes)
local Utils              = require(ReplicatedStorage.Shared.Utils)
local DataSystem         = require(script.Parent.DataSystem)
local InventorySystem    = require(script.Parent.InventorySystem)
local ConstructionSystem = require(script.Parent.ConstructionSystem)

local BaseSystem = {}

-- userId → base data em memória
local basesInMemory: {[number]: any} = {}

-- ----------------------------------------------------------------
-- CARREGAR BASE
-- ----------------------------------------------------------------
function BaseSystem.loadForPlayer(player: Player)
	local baseData = DataSystem.loadBase(player)
	basesInMemory[player.UserId] = baseData

	-- Restaurar construções salvas
	for _, building in ipairs(baseData.buildings) do
		ConstructionSystem.restoreBuilding(building, player.UserId)
	end

	Remotes.BaseLevelChanged:FireClient(player, baseData.level)
end

function BaseSystem.saveForPlayer(player: Player)
	local baseData = basesInMemory[player.UserId]
	if not baseData then return end

	-- Atualiza lista de construções a partir do estado atual em memória
	local allBuildings = ConstructionSystem.getAllBuildings()
	local playerBuildings = {}
	for id, state in pairs(allBuildings) do
		if state.ownerId == player.UserId then
			table.insert(playerBuildings, {
				id           = id,
				buildingType = state.buildingType,
				cframe       = ConstructionSystem.serializeCFrame(state.part.CFrame),
				health       = state.health,
			})
		end
	end

	baseData.buildings = playerBuildings
	DataSystem.saveBase(player, baseData)
	basesInMemory[player.UserId] = nil
end

function BaseSystem.getLevel(player: Player): number
	local data = basesInMemory[player.UserId]
	return data and data.level or 1
end

-- ----------------------------------------------------------------
-- UPGRADE DO NÚCLEO
-- ----------------------------------------------------------------
Remotes.UpgradeClanCenter.OnServerEvent:Connect(function(player)
	local baseData = basesInMemory[player.UserId]
	if not baseData then
		Utils.notify(player, "Base não carregada.", "error")
		return
	end

	local currentLevel = baseData.level
	local nextLevel    = currentLevel + 1

	if nextLevel > Config.MAX_CLAN_LEVEL then
		Utils.notify(player, "Nível máximo atingido!", "info")
		return
	end

	local cost = Config.CLAN_UPGRADE_COST[nextLevel]
	if not cost then
		Utils.notify(player, "Custo de upgrade não definido.", "error")
		return
	end

	if not InventorySystem.hasResources(player, cost) then
		local missing = {}
		for res, amt in pairs(cost) do
			local has = InventorySystem.getAmount(player, res)
			if has < amt then
				table.insert(missing, res .. " (" .. has .. "/" .. amt .. ")")
			end
		end
		Utils.notify(player, "Recursos insuficientes: " .. table.concat(missing, ", "), "error")
		return
	end

	InventorySystem.consumeResources(player, cost)
	baseData.level = nextLevel

	local levelData = Config.CLAN_LEVELS[nextLevel]
	Remotes.BaseLevelChanged:FireClient(player, nextLevel)
	Utils.notify(player,
		"Centro do Clã evoluído para Nível " .. nextLevel ..
		" (" .. levelData.label .. ") — Capacidade: " .. levelData.capacity .. " membros",
		"success"
	)

	-- Salva automaticamente após upgrade
	DataSystem.saveBase(player, baseData)
end)

-- Resposta ao cliente pedindo dados da base (RF)
Remotes.LoadBase.OnServerInvoke = function(player)
	local baseData = basesInMemory[player.UserId]
	if not baseData then return nil end
	return { level = baseData.level }
end

return BaseSystem
