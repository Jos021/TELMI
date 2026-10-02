--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")

local Config           = require(ReplicatedStorage.Shared.Config)
local Remotes          = require(ReplicatedStorage.Shared.Remotes)
local Utils            = require(ReplicatedStorage.Shared.Utils)
local ProtectionSystem = require(script.Parent.ProtectionSystem)
local ClanSystem       = require(script.Parent.ClanSystem)

local CombatSystem = {}

-- Cooldown de ataque por player
local attackCooldowns: {[number]: number} = {}
-- Armor equipada por player
local playerArmor: {[number]: boolean} = {}

local function isOnCooldown(userId: number, weaponType: string): boolean
	local cd   = Config.COMBAT[weaponType] and Config.COMBAT[weaponType].cooldown or 1
	local last = attackCooldowns[userId] or 0
	return (os.clock() - last) < cd
end

local function setCooldown(userId: number)
	attackCooldowns[userId] = os.clock()
end

local function getDamageReduction(targetPlayer: Player): number
	if playerArmor[targetPlayer.UserId] then
		return Config.COMBAT.ARMOR.damageReduction
	end
	return 0
end

-- Verifica se dois jogadores são do mesmo clã
local function isSameClan(p1: Player, p2: Player): boolean
	local c1 = ClanSystem.getPlayerClanId(p1)
	local c2 = ClanSystem.getPlayerClanId(p2)
	return c1 ~= nil and c1 == c2
end

-- ----------------------------------------------------------------
-- DANO EM JOGADORES
-- ----------------------------------------------------------------
Remotes.DealDamage.OnServerEvent:Connect(function(attacker, targetId, weaponType)
	-- Validações básicas
	if type(targetId) ~= "number" then return end
	weaponType = tostring(weaponType)
	if weaponType ~= "SWORD" and weaponType ~= "BOW" then return end

	local weaponData = Config.COMBAT[weaponType]
	if not weaponData then return end

	if isOnCooldown(attacker.UserId, weaponType) then return end
	setCooldown(attacker.UserId)

	-- Proteção de novato: atacante protegido não pode atacar
	if ProtectionSystem.isProtected(attacker) then
		Utils.notify(attacker, "Você está protegido e não pode atacar.", "info")
		return
	end

	local target = Players:GetPlayerByUserId(targetId)
	if not target then return end

	-- Alvo protegido: não pode ser atacado
	if ProtectionSystem.isProtected(target) then
		Utils.notify(attacker, target.Name .. " está protegido.", "info")
		return
	end

	-- Membros do mesmo clã não podem se atacar
	if isSameClan(attacker, target) then
		Utils.notify(attacker, "Você não pode atacar aliados.", "info")
		return
	end

	-- Verificar distância (segurança server-side)
	local attackerChar = attacker.Character
	local targetChar   = target.Character
	if not attackerChar or not targetChar then return end

	local aHRP = attackerChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	local tHRP = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not aHRP or not tHRP then return end

	local maxRange = weaponData.range
	local dist     = (aHRP.Position - tHRP.Position).Magnitude
	if dist > maxRange + 5 then -- +5 de tolerância de rede
		Utils.notify(attacker, "Alvo muito distante.", "info")
		return
	end

	-- Aplicar dano
	local damage     = weaponData.damage
	local reduction  = getDamageReduction(target)
	local finalDamage = damage * (1 - reduction)

	local hum = targetChar:FindFirstChild("Humanoid") :: Humanoid?
	if not hum then return end
	hum:TakeDamage(finalDamage)

	Remotes.UpdateHealth:FireClient(target, hum.Health, hum.MaxHealth)
	Remotes.UpdateHealth:FireClient(attacker, hum.Health, hum.MaxHealth)
end)

-- ----------------------------------------------------------------
-- MORTE E RESPAWN
-- ----------------------------------------------------------------
local function onCharacterAdded(player: Player, character: Model)
	local hum = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not hum then return end

	hum.Died:Connect(function()
		Remotes.PlayerDied:FireAllClients(player.UserId)
		Utils.notify(player, "Você morreu. Respawn em " .. Config.PLAYER.respawnTime .. "s.", "error")
		task.delay(Config.PLAYER.respawnTime, function()
			if player.Parent then
				player:LoadCharacter()
			end
		end)
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		onCharacterAdded(player, char)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end)

-- ----------------------------------------------------------------
-- FERRAMENTAS DO JOGADOR (criadas no spawn)
-- ----------------------------------------------------------------
local function giveCombatTools(player: Player)
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return end

	-- Remove ferramentas anteriores
	for _, child in ipairs(backpack:GetChildren()) do
		if child:IsA("Tool") then child:Destroy() end
	end

	-- Espada
	local sword = Instance.new("Tool")
	sword.Name         = "Espada"
	sword.RequiresHandle = true
	sword.CanBeDropped = false

	local swordHandle = Instance.new("Part")
	swordHandle.Name   = "Handle"
	swordHandle.Size   = Vector3.new(0.3, 2, 0.3)
	swordHandle.Color  = Color3.fromRGB(170, 170, 170)
	swordHandle.Material = Enum.Material.Metal
	swordHandle.Parent = sword

	local swordMesh = Instance.new("SpecialMesh")
	swordMesh.MeshType = Enum.MeshType.FileMesh
	swordMesh.Parent = swordHandle

	sword.Activated:Connect(function()
		local char = player.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then return end

		for _, target in ipairs(Players:GetPlayers()) do
			if target == player then continue end
			local tChar = target.Character
			if not tChar then continue end
			local tHRP = tChar:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not tHRP then continue end
			if (hrp.Position - tHRP.Position).Magnitude <= Config.COMBAT.SWORD.range then
				Remotes.DealDamage:FireServer(target.UserId, "SWORD")
			end
		end
	end)
	sword.Parent = backpack

	-- Arco (ferramenta simples, lógica de projétil no cliente)
	local bow = Instance.new("Tool")
	bow.Name         = "Arco"
	bow.RequiresHandle = true
	bow.CanBeDropped = false

	local bowHandle = Instance.new("Part")
	bowHandle.Name     = "Handle"
	bowHandle.Size     = Vector3.new(0.3, 1.5, 0.3)
	bowHandle.Color    = Color3.fromRGB(101, 67, 33)
	bowHandle.Material = Enum.Material.Wood
	bowHandle.Parent   = bow

	bow.Parent = backpack
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.delay(1, function()
			giveCombatTools(player)
		end)
	end)
end)

function CombatSystem.equipArmor(player: Player)
	playerArmor[player.UserId] = true
	Utils.notify(player, "Armadura equipada! Redução de dano de " .. (Config.COMBAT.ARMOR.damageReduction * 100) .. "%.", "success")
end

Players.PlayerRemoving:Connect(function(player)
	attackCooldowns[player.UserId] = nil
	playerArmor[player.UserId]     = nil
end)

return CombatSystem
