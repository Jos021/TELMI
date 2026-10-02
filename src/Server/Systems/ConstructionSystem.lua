--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")

local Config          = require(ReplicatedStorage.Shared.Config)
local Remotes         = require(ReplicatedStorage.Shared.Remotes)
local Utils           = require(ReplicatedStorage.Shared.Utils)
local InventorySystem = require(script.Parent.InventorySystem)

local ConstructionSystem = {}

-- buildingId → dados da construção em memória
type BuildingState = {
	id: string,
	buildingType: string,
	ownerId: number,       -- userId do jogador que colocou
	clanId: string?,
	health: number,
	maxHealth: number,
	part: BasePart,
}

local buildings: {[string]: BuildingState} = {}

local BUILD_FOLDER_NAME = "Buildings"
local GRID_SIZE         = 4

local function getOrCreateFolder(): Folder
	local existing = Workspace:FindFirstChild(BUILD_FOLDER_NAME)
	if existing then return existing :: Folder end
	local folder = Instance.new("Folder")
	folder.Name   = BUILD_FOLDER_NAME
	folder.Parent = Workspace
	return folder
end

-- Serializa CFrame → {number}
function ConstructionSystem.serializeCFrame(cf: CFrame): {number}
	return { cf:GetComponents() }
end

-- Desserializa {number} → CFrame
function ConstructionSystem.deserializeCFrame(arr: {number}): CFrame
	return CFrame.new(
		arr[1],  arr[2],  arr[3],
		arr[4],  arr[5],  arr[6],
		arr[7],  arr[8],  arr[9],
		arr[10], arr[11], arr[12]
	)
end

-- ----------------------------------------------------------------
-- COLOCAR CONSTRUÇÃO
-- ----------------------------------------------------------------
local function createBuildingPart(buildingType: string, cf: CFrame, buildingId: string): BasePart
	local data = Config.BUILDING_DATA[buildingType]
	assert(data, "Tipo de construção inválido: " .. buildingType)

	local part = Instance.new("Part")
	part.Size      = data.size
	part.Color     = data.color
	part.Material  = data.material
	part.Anchored  = true
	part.CFrame    = cf
	part.Name      = buildingType

	local idVal = Instance.new("StringValue")
	idVal.Name   = "BuildingId"
	idVal.Value  = buildingId
	idVal.Parent = part

	local typeVal = Instance.new("StringValue")
	typeVal.Name   = "BuildingType"
	typeVal.Value  = buildingType
	typeVal.Parent = part

	-- Porta: adiciona ClickDetector para abrir/fechar
	if data.isDoor then
		local click = Instance.new("ClickDetector")
		click.MaxActivationDistance = 8
		click.Parent = part
		local open = false
		click.MouseClick:Connect(function(player)
			-- Apenas membros do clã dono podem usar
			open = not open
			part.Transparency = open and 0.8 or 0
			part.CanCollide   = not open
		end)
	end

	-- Núcleo: BillboardGui com nome
	if data.isNucleus then
		local billboard = Instance.new("BillboardGui")
		billboard.Size        = UDim2.new(0, 120, 0, 30)
		billboard.StudsOffset = Vector3.new(0, 4, 0)
		billboard.AlwaysOnTop = false
		billboard.Parent      = part

		local label = Instance.new("TextLabel")
		label.Size            = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextColor3      = Color3.fromRGB(80, 200, 255)
		label.Text            = "NÚCLEO"
		label.Font            = Enum.Font.GothamBold
		label.TextScaled      = true
		label.Parent          = billboard
	end

	part.Parent = getOrCreateFolder()
	return part
end

Remotes.PlaceBuilding.OnServerEvent:Connect(function(player, buildingType, cfComponents)
	local data = Config.BUILDING_DATA[buildingType]
	if not data then
		Utils.notify(player, "Tipo de construção inválido.")
		return
	end

	-- Verificar recursos
	if not InventorySystem.hasResources(player, data.cost) then
		local missing = {}
		for res, amt in pairs(data.cost) do
			local has = InventorySystem.getAmount(player, res)
			if has < amt then
				table.insert(missing, res .. " (" .. has .. "/" .. amt .. ")")
			end
		end
		Utils.notify(player, "Recursos insuficientes: " .. table.concat(missing, ", "), "error")
		return
	end

	-- Reconstruir CFrame do cliente (vetor de 12 floats)
	if type(cfComponents) ~= "table" or #cfComponents ~= 12 then
		Utils.notify(player, "Posição de construção inválida.")
		return
	end
	local cf = ConstructionSystem.deserializeCFrame(cfComponents)
	cf = Utils.snapToGrid(cf, GRID_SIZE)

	-- Consumir recursos
	InventorySystem.consumeResources(player, data.cost)

	-- Criar a construção
	local buildingId = Utils.generateId()
	local part       = createBuildingPart(buildingType, cf, buildingId)

	local state: BuildingState = {
		id           = buildingId,
		buildingType = buildingType,
		ownerId      = player.UserId,
		health       = data.health,
		maxHealth    = data.health,
		part         = part,
	}
	buildings[buildingId] = state

	-- Notificar todos os clientes
	Remotes.BuildingPlaced:FireAllClients({
		id           = buildingId,
		buildingType = buildingType,
		ownerId      = player.UserId,
		cfComponents = ConstructionSystem.serializeCFrame(cf),
		health       = data.health,
		maxHealth    = data.health,
	})
end)

-- ----------------------------------------------------------------
-- REMOVER CONSTRUÇÃO
-- ----------------------------------------------------------------
Remotes.RemoveBuilding.OnServerEvent:Connect(function(player, buildingId)
	local state = buildings[buildingId]
	if not state then return end

	-- Apenas o dono pode remover (ou líder do clã)
	if state.ownerId ~= player.UserId then
		Utils.notify(player, "Você não pode remover esta construção.", "error")
		return
	end

	local data = Config.BUILDING_DATA[state.buildingType]
	-- Devolve 50% dos recursos
	local refund: {[string]: number} = {}
	for res, amt in pairs(data.cost) do
		refund[res] = math.floor(amt * 0.5)
	end
	InventorySystem.addLoot(player, refund)

	state.part:Destroy()
	buildings[buildingId] = nil

	Remotes.BuildingRemoved:FireAllClients(buildingId)
	Utils.notify(player, "Construção removida (50% de recursos devolvidos).")
end)

-- ----------------------------------------------------------------
-- DANO EM CONSTRUÇÕES (chamado por CombatSystem)
-- ----------------------------------------------------------------
function ConstructionSystem.damageBuilding(buildingId: string, damage: number): boolean
	local state = buildings[buildingId]
	if not state then return false end

	state.health = math.max(0, state.health - damage)
	Remotes.BuildingDamaged:FireAllClients(buildingId, state.health)

	if state.health <= 0 then
		state.part:Destroy()
		buildings[buildingId] = nil
		Remotes.BuildingRemoved:FireAllClients(buildingId)
		return true -- destruída
	end
	return false
end

function ConstructionSystem.getBuilding(buildingId: string): BuildingState?
	return buildings[buildingId]
end

function ConstructionSystem.getAllBuildings(): {[string]: BuildingState}
	return buildings
end

-- ----------------------------------------------------------------
-- RESTAURAÇÃO DO MAPA AO CARREGAR BASE (BaseSystem chama isto)
-- ----------------------------------------------------------------
function ConstructionSystem.restoreBuilding(buildingData: any, ownerId: number)
	local data = Config.BUILDING_DATA[buildingData.buildingType]
	if not data then return end

	local cf = ConstructionSystem.deserializeCFrame(buildingData.cframe)
	local part = createBuildingPart(buildingData.buildingType, cf, buildingData.id)

	local state: BuildingState = {
		id           = buildingData.id,
		buildingType = buildingData.buildingType,
		ownerId      = ownerId,
		health       = buildingData.health,
		maxHealth    = data.health,
		part         = part,
	}
	buildings[buildingData.id] = state
end

return ConstructionSystem
