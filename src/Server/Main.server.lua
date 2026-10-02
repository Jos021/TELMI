--!strict
-- Servidor principal: inicializa todos os sistemas e gerencia entrada/saída de jogadores.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Carrega módulos compartilhados primeiro para criar os RemoteEvents
require(ReplicatedStorage.Shared.Remotes)

-- Sistemas do servidor
local DataSystem       = require(script.Parent.Systems.DataSystem)
local InventorySystem  = require(script.Parent.Systems.InventorySystem)
local BaseSystem       = require(script.Parent.Systems.BaseSystem)
local ClanSystem       = require(script.Parent.Systems.ClanSystem)
local ResourceSystem   = require(script.Parent.Systems.ResourceSystem)
local ConstructionSystem = require(script.Parent.Systems.ConstructionSystem)
local CombatSystem     = require(script.Parent.Systems.CombatSystem)
local ProtectionSystem = require(script.Parent.Systems.ProtectionSystem)
local RaidSystem       = require(script.Parent.Systems.RaidSystem)

print("[Telmi] Servidor iniciando...")

-- ----------------------------------------------------------------
-- GERAR MAPA
-- ----------------------------------------------------------------
ResourceSystem.generateMap()
print("[Telmi] Mapa gerado.")

-- ----------------------------------------------------------------
-- CONFIGURAR SPAWN
-- ----------------------------------------------------------------
local function setupSpawnArea()
	local workspace = game:GetService("Workspace")

	-- Plataforma de spawn central
	local ground = Instance.new("Part")
	ground.Name       = "SpawnGround"
	ground.Size       = Vector3.new(200, 2, 200)
	ground.Position   = Vector3.new(0, -1, 0)
	ground.Anchored   = true
	ground.Material   = Enum.Material.Grass
	ground.Color      = Color3.fromRGB(106, 127, 63)
	ground.Parent     = workspace

	-- Área de spawn protegida (marcador visual)
	local spawnMarker = Instance.new("Part")
	spawnMarker.Name        = "SpawnZone"
	spawnMarker.Size        = Vector3.new(20, 0.5, 20)
	spawnMarker.Position    = Vector3.new(0, 0.5, 0)
	spawnMarker.Anchored    = true
	spawnMarker.Material    = Enum.Material.Neon
	spawnMarker.Color       = Color3.fromRGB(0, 200, 100)
	spawnMarker.Transparency = 0.7
	spawnMarker.CanCollide  = false
	spawnMarker.Parent      = workspace

	local label = Instance.new("BillboardGui")
	label.Size        = UDim2.new(0, 200, 0, 50)
	label.StudsOffset = Vector3.new(0, 5, 0)
	label.Parent      = spawnMarker
	local lbl = Instance.new("TextLabel")
	lbl.Size                 = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3           = Color3.fromRGB(0, 255, 100)
	lbl.Text                 = "ZONA DE SPAWN (SEGURA)"
	lbl.Font                 = Enum.Font.GothamBold
	lbl.TextScaled           = true
	lbl.Parent               = label
end

setupSpawnArea()

-- ----------------------------------------------------------------
-- ENTRADA DE JOGADORES
-- ----------------------------------------------------------------
local function onPlayerAdded(player: Player)
	print("[Telmi] Jogador entrou: " .. player.Name)

	-- Carregar dados
	InventorySystem.loadForPlayer(player)
	BaseSystem.loadForPlayer(player)

	-- Proteção de novato
	ProtectionSystem.onPlayerAdded(player)

	player.CharacterAdded:Connect(function(character)
		-- Configurar velocidade e saúde
		local hum = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if hum then
			hum.MaxHealth  = 100
			hum.Health     = 100
			hum.WalkSpeed  = 16
			hum.JumpHeight = 7.2
		end
	end)
end

local function onPlayerRemoving(player: Player)
	print("[Telmi] Jogador saiu: " .. player.Name)
	BaseSystem.saveForPlayer(player)
	InventorySystem.saveForPlayer(player)
	ProtectionSystem.onPlayerRemoving(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Jogadores que já estavam no servidor quando o script carregou
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- ----------------------------------------------------------------
-- AUTO-SAVE A CADA 5 MINUTOS
-- ----------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(5 * 60)
		for _, player in ipairs(Players:GetPlayers()) do
			InventorySystem.saveForPlayer(player)
			BaseSystem.saveForPlayer(player)
			-- Recarregar para manter em memória após save
			InventorySystem.loadForPlayer(player)
			BaseSystem.loadForPlayer(player)
		end
		print("[Telmi] Auto-save executado.")
	end
end)

print("[Telmi] Servidor pronto! Sistemas ativos:")
print("  ✓ ResourceSystem")
print("  ✓ InventorySystem")
print("  ✓ ConstructionSystem")
print("  ✓ BaseSystem")
print("  ✓ ClanSystem")
print("  ✓ CombatSystem")
print("  ✓ RaidSystem")
print("  ✓ ProtectionSystem")
