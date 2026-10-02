--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local Config          = require(ReplicatedStorage.Shared.Config)
local Remotes         = require(ReplicatedStorage.Shared.Remotes)
local Utils           = require(ReplicatedStorage.Shared.Utils)
local InventorySystem = require(script.Parent.InventorySystem)
local ProtectionSystem = require(script.Parent.ProtectionSystem)

local ResourceSystem = {}

-- nodeId → estado do nó
type NodeState = {
	id: string,
	resourceType: string,
	health: number,
	maxHealth: number,
	part: BasePart,
	depleted: boolean,
}

local nodes: {[string]: NodeState} = {}

-- ----------------------------------------------------------------
-- SPAWNAR NÓS NO MAPA
-- ----------------------------------------------------------------
local RESOURCE_FOLDER_NAME = "ResourceNodes"

local function getOrCreateFolder(): Folder
	local existing = Workspace:FindFirstChild(RESOURCE_FOLDER_NAME)
	if existing then return existing :: Folder end
	local folder = Instance.new("Folder")
	folder.Name   = RESOURCE_FOLDER_NAME
	folder.Parent = Workspace
	return folder
end

local function spawnNode(resourceType: string, position: Vector3): NodeState
	local data = Config.RESOURCE_NODE_DATA[resourceType]
	assert(data, "Tipo de recurso desconhecido: " .. resourceType)

	local part = Instance.new("Part")
	part.Size      = data.size
	part.Color     = data.color
	part.Material  = data.material
	part.Anchored  = true
	part.CastShadow = true
	part.Position  = position
	part.Name      = resourceType .. "Node"

	local nodeId = Utils.generateId()
	local label  = Instance.new("StringValue")
	label.Name   = "NodeId"
	label.Value  = nodeId
	label.Parent = part

	local typeVal = Instance.new("StringValue")
	typeVal.Name   = "ResourceType"
	typeVal.Value  = resourceType
	typeVal.Parent = part

	part.Parent = getOrCreateFolder()

	local state: NodeState = {
		id           = nodeId,
		resourceType = resourceType,
		health       = data.health,
		maxHealth    = data.health,
		part         = part,
		depleted     = false,
	}
	nodes[nodeId] = state
	return state
end

local function respawnNode(state: NodeState)
	task.delay(Config.RESOURCE_NODE_DATA[state.resourceType].respawnTime, function()
		if not nodes[state.id] then return end -- foi deletado
		state.health   = state.maxHealth
		state.depleted = false
		state.part.Transparency = 0
		Remotes.NodeRespawned:FireAllClients(state.id, state.part.Position)
	end)
end

-- ----------------------------------------------------------------
-- COLHEITA
-- ----------------------------------------------------------------
Remotes.HarvestResource.OnServerEvent:Connect(function(player, nodeId)
	local state = nodes[nodeId]
	if not state then return end
	if state.depleted then return end

	-- Checar se o jogador está próximo o suficiente
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	local dist = (hrp.Position - state.part.Position).Magnitude
	if dist > 20 then
		Utils.notify(player, "Você está longe demais para coletar.")
		return
	end

	-- Reduz saúde do nó
	state.health -= 1

	local data = Config.RESOURCE_NODE_DATA[state.resourceType]
	local amount = math.random(data.yieldMin, data.yieldMax)
	InventorySystem.addItem(player, state.resourceType, amount)

	Utils.notify(player, "+" .. amount .. " " .. data.label)

	if state.health <= 0 then
		state.depleted        = true
		state.part.Transparency = 0.8
		Remotes.NodeDepleted:FireAllClients(nodeId)
		respawnNode(state)
	end
end)

-- ----------------------------------------------------------------
-- GERAÇÃO INICIAL DO MAPA
-- ----------------------------------------------------------------
function ResourceSystem.generateMap()
	-- Floresta (madeira + comida)
	local forestPositions = {
		Vector3.new(30,  2, 30),  Vector3.new(40,  2, 20),  Vector3.new(20,  2, 40),
		Vector3.new(50,  2, 10),  Vector3.new(15,  2, 55),  Vector3.new(60,  2, 35),
		Vector3.new(-30, 2, 30),  Vector3.new(-40, 2, 20),  Vector3.new(-50, 2, 40),
		Vector3.new(25,  2, -35), Vector3.new(-25, 2, -35), Vector3.new(45,  2, -25),
	}
	for i, pos in ipairs(forestPositions) do
		if i % 3 == 0 then
			spawnNode(Config.RESOURCES.FOOD, pos)
		else
			spawnNode(Config.RESOURCES.WOOD, pos)
		end
	end

	-- Área de mineração (pedra + ferro)
	local minePositions = {
		Vector3.new(80,  2,  0),  Vector3.new(90,  2, 15),  Vector3.new(75,  2, -15),
		Vector3.new(100, 2,  5),  Vector3.new(85,  2, -25), Vector3.new(95,  2, 25),
		Vector3.new(-80, 2,  0),  Vector3.new(-90, 2, 15),  Vector3.new(-75, 2, -15),
	}
	for i, pos in ipairs(minePositions) do
		if i % 3 == 0 then
			spawnNode(Config.RESOURCES.IRON, pos)
		else
			spawnNode(Config.RESOURCES.STONE, pos)
		end
	end
end

return ResourceSystem
