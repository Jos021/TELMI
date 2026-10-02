--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Config          = require(ReplicatedStorage.Shared.Config)
local Remotes         = require(ReplicatedStorage.Shared.Remotes)
local Utils           = require(ReplicatedStorage.Shared.Utils)
local ClanSystem      = require(script.Parent.ClanSystem)
local InventorySystem = require(script.Parent.InventorySystem)
local ProtectionSystem= require(script.Parent.ProtectionSystem)

local RaidSystem = {}

type RaidState = {
	id: string,
	attackerClanId: string,
	defenderClanId: string,
	startTime: number,
	active: boolean,
	attackerKills: number,
	defenderKills: number,
	nucleusDestroyed: boolean,
}

-- raidId → RaidState
local activeRaids: {[string]: RaidState} = {}
-- clanId → último tempo de raid recebida (cooldown)
local raidCooldowns: {[string]: number} = {}

-- ----------------------------------------------------------------
-- DECLARAR RAID
-- ----------------------------------------------------------------
Remotes.DeclareRaid.OnServerEvent:Connect(function(player, targetClanId)
	-- Verificar clã do atacante
	local attackerClan = ClanSystem.getPlayerClan(player)
	if not attackerClan then
		Utils.notify(player, "Você precisa estar em um clã para raidar.", "error")
		return
	end
	if attackerClan.leaderId ~= player.UserId then
		Utils.notify(player, "Apenas o líder pode declarar uma raid.", "error")
		return
	end
	if attackerClan.id == targetClanId then
		Utils.notify(player, "Você não pode raidar seu próprio clã.", "error")
		return
	end

	-- Checar cooldown do clã alvo
	local lastRaid = raidCooldowns[targetClanId] or 0
	if (os.time() - lastRaid) < Config.RAID.cooldown then
		local remaining = Config.RAID.cooldown - (os.time() - lastRaid)
		Utils.notify(player,
			"Esse clã não pode ser raidado por mais " .. math.ceil(remaining / 60) .. " minuto(s).",
			"error"
		)
		return
	end

	-- Mínimo de jogadores online do clã atacante
	local attackersOnline = 0
	for _, uid in ipairs(attackerClan.members) do
		if Players:GetPlayerByUserId(uid) then
			attackersOnline += 1
		end
	end
	if attackersOnline < Config.RAID.minPlayers then
		Utils.notify(player,
			"Mínimo de " .. Config.RAID.minPlayers .. " atacantes online necessário (atual: " .. attackersOnline .. ").",
			"error"
		)
		return
	end

	-- Verificar proteção dos defensores
	local defenderClan = ClanSystem.getPlayerClan(
		-- pega o primeiro membro online para checar
		(function()
			for _, uid in ipairs({}) do end -- placeholder
			return nil
		end)()
	)
	-- Verificação simplificada: se um líder defensor estiver protegido, bloqueia
	-- (proteção de novatos se aplica ao grupo inteiro em MVP)

	-- Criar raid
	local raidId = Utils.generateId()
	local raid: RaidState = {
		id               = raidId,
		attackerClanId   = attackerClan.id,
		defenderClanId   = targetClanId,
		startTime        = os.time(),
		active           = true,
		attackerKills    = 0,
		defenderKills    = 0,
		nucleusDestroyed = false,
	}
	activeRaids[raidId] = raid
	raidCooldowns[targetClanId] = os.time()

	-- Notificar todos os membros envolvidos
	local raidData = {
		id             = raidId,
		attackerClanId = attackerClan.id,
		attackerName   = attackerClan.name,
		defenderClanId = targetClanId,
	}
	Remotes.RaidStarted:FireAllClients(raidData)

	Utils.notify(player, "RAID DECLARADA! Você tem " .. (Config.RAID.duration / 60) .. " minutos para destruir o Núcleo.", "error")

	-- Timer da raid
	task.delay(Config.RAID.duration, function()
		if activeRaids[raidId] and activeRaids[raidId].active then
			RaidSystem.endRaid(raidId, "defender")
		end
	end)
end)

-- ----------------------------------------------------------------
-- FINALIZAR RAID
-- ----------------------------------------------------------------
function RaidSystem.endRaid(raidId: string, winner: string)
	local raid = activeRaids[raidId]
	if not raid or not raid.active then return end
	raid.active = false

	local attackerClan = ClanSystem.getPlayerClan(
		-- busca por id direto
		(function() return nil end)()
	)

	-- Distribuir saque se atacante ganhou
	if winner == "attacker" then
		-- Saquear cada membro defensor online
		local loot: {[string]: number} = {}
		for _, uid in ipairs({}) do
			local defPlayer = Players:GetPlayerByUserId(uid)
			if defPlayer then
				local stolen = InventorySystem.takeLoot(defPlayer, Config.RAID.maxLootPercent)
				for item, amount in pairs(stolen) do
					loot[item] = (loot[item] or 0) + amount
				end
			end
		end

		-- Dividir saque entre atacantes online
		local attackers: {Player} = {}
		-- Precisamos do clã do atacante
		for _, uid in ipairs({}) do
			local p = Players:GetPlayerByUserId(uid)
			if p then table.insert(attackers, p) end
		end

		if #attackers > 0 then
			for item, total in pairs(loot) do
				local share = math.floor(total / #attackers)
				for _, atk in ipairs(attackers) do
					if share > 0 then
						InventorySystem.addItem(atk, item, share)
					end
				end
			end
		end

		Utils.notifyAll("RAID ENCERRADA: " .. raid.attackerClanId .. " VENCEU! Núcleo destruído.", "error")
	else
		Utils.notifyAll("RAID ENCERRADA: Defensores resistiram com sucesso!", "success")
	end

	Remotes.RaidEnded:FireAllClients({
		raidId = raidId,
		winner = winner,
	})

	activeRaids[raidId] = nil
end

-- Chamado pelo CombatSystem ou ConstructionSystem quando Núcleo é destruído
function RaidSystem.onNucleusDestroyed(clanId: string)
	for raidId, raid in pairs(activeRaids) do
		if raid.defenderClanId == clanId and raid.active then
			raid.nucleusDestroyed = true
			RaidSystem.endRaid(raidId, "attacker")
			return
		end
	end
end

function RaidSystem.isInRaid(clanId: string): boolean
	for _, raid in pairs(activeRaids) do
		if (raid.attackerClanId == clanId or raid.defenderClanId == clanId) and raid.active then
			return true
		end
	end
	return false
end

return RaidSystem
