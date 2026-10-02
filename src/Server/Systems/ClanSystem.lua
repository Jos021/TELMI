--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local HttpService       = game:GetService("HttpService")

local Config      = require(ReplicatedStorage.Shared.Config)
local Remotes     = require(ReplicatedStorage.Shared.Remotes)
local Utils       = require(ReplicatedStorage.Shared.Utils)
local DataSystem  = require(script.Parent.DataSystem)
local BaseSystem  = require(script.Parent.BaseSystem)

local ClanSystem = {}

type ClanData = {
	id: string,
	name: string,
	leaderId: number,
	members: {number},
	level: number,
	nucleusHealth: number,
}

-- Clãs ativos nessa sessão (clanId → ClanData)
local activeClans: {[string]: ClanData} = {}
-- userId → clanId (cache em memória)
local playerClanMap: {[number]: string} = {}
-- Convites pendentes: userId → {clanId, clanName}[]
local pendingInvites: {[number]: {{clanId: string, clanName: string}}}} = {}

-- ----------------------------------------------------------------
-- UTILITÁRIOS INTERNOS
-- ----------------------------------------------------------------
local function getOrLoadClan(clanId: string): ClanData?
	if activeClans[clanId] then
		return activeClans[clanId]
	end
	local data = DataSystem.loadClan(clanId)
	if data then
		activeClans[clanId] = data :: any
		return activeClans[clanId]
	end
	return nil
end

local function syncToMembers(clan: ClanData)
	for _, userId in ipairs(clan.members) do
		local member = Players:GetPlayerByUserId(userId)
		if member then
			Remotes.UpdateClanInfo:FireClient(member, {
				id      = clan.id,
				name    = clan.name,
				level   = clan.level,
				members = clan.members,
				leaderId= clan.leaderId,
				capacity= Config.CLAN_LEVELS[clan.level].capacity,
			})
		end
	end
end

function ClanSystem.getPlayerClan(player: Player): ClanData?
	local clanId = playerClanMap[player.UserId]
	if clanId then
		return getOrLoadClan(clanId)
	end
	-- Tenta DataStore
	local storedId = DataSystem.getPlayerClanId(player.UserId)
	if storedId then
		playerClanMap[player.UserId] = storedId
		return getOrLoadClan(storedId)
	end
	return nil
end

function ClanSystem.getPlayerClanId(player: Player): string?
	local clan = ClanSystem.getPlayerClan(player)
	return clan and clan.id or nil
end

function ClanSystem.getClanCapacity(clan: ClanData): number
	return Config.CLAN_LEVELS[clan.level].capacity
end

-- ----------------------------------------------------------------
-- CRIAR CLÃ
-- ----------------------------------------------------------------
Remotes.CreateClan.OnServerEvent:Connect(function(player, name)
	if type(name) ~= "string" or #name < 2 or #name > 24 then
		Utils.notify(player, "Nome do clã inválido (2-24 caracteres).", "error")
		return
	end

	if ClanSystem.getPlayerClan(player) then
		Utils.notify(player, "Você já pertence a um clã.", "error")
		return
	end

	local clanId = HttpService:GenerateGUID(false)
	local clan: ClanData = {
		id            = clanId,
		name          = name,
		leaderId      = player.UserId,
		members       = { player.UserId },
		level         = 1,
		nucleusHealth = Config.CLAN_LEVELS[1].nucleusHealth,
	}

	activeClans[clanId]                = clan
	playerClanMap[player.UserId]       = clanId
	DataSystem.saveClan(clan :: any)
	DataSystem.setPlayerClanId(player.UserId, clanId)

	syncToMembers(clan)
	Utils.notify(player, "Clã '" .. name .. "' criado com sucesso!", "success")
end)

-- ----------------------------------------------------------------
-- CONVIDAR JOGADOR
-- ----------------------------------------------------------------
Remotes.InvitePlayer.OnServerEvent:Connect(function(player, targetUserId)
	local clan = ClanSystem.getPlayerClan(player)
	if not clan then
		Utils.notify(player, "Você não pertence a um clã.", "error")
		return
	end
	if clan.leaderId ~= player.UserId then
		Utils.notify(player, "Apenas o líder pode convidar.", "error")
		return
	end

	local capacity = ClanSystem.getClanCapacity(clan)
	if #clan.members >= capacity then
		Utils.notify(player, "Clã cheio (capacidade: " .. capacity .. ").", "error")
		return
	end

	local target = Players:GetPlayerByUserId(targetUserId)
	if not target then
		Utils.notify(player, "Jogador não encontrado.", "error")
		return
	end
	if ClanSystem.getPlayerClan(target) then
		Utils.notify(player, target.Name .. " já está em um clã.", "error")
		return
	end

	-- Registrar convite
	if not pendingInvites[targetUserId] then
		pendingInvites[targetUserId] = {}
	end
	table.insert(pendingInvites[targetUserId], { clanId = clan.id, clanName = clan.name })

	Remotes.ClanInviteReceived:FireClient(target, clan.id, clan.name)
	Utils.notify(player, "Convite enviado para " .. target.Name .. ".")
	Utils.notify(target, player.Name .. " convidou você para o clã '" .. clan.name .. "'.", "info")
end)

-- ----------------------------------------------------------------
-- ACEITAR CONVITE
-- ----------------------------------------------------------------
Remotes.AcceptInvite.OnServerEvent:Connect(function(player, clanId)
	local inviteList = pendingInvites[player.UserId]
	if not inviteList then
		Utils.notify(player, "Nenhum convite pendente.", "error")
		return
	end

	-- Validar que o convite existe
	local foundIdx = nil
	for i, inv in ipairs(inviteList) do
		if inv.clanId == clanId then
			foundIdx = i
			break
		end
	end
	if not foundIdx then
		Utils.notify(player, "Convite não encontrado.", "error")
		return
	end
	table.remove(inviteList, foundIdx)

	if ClanSystem.getPlayerClan(player) then
		Utils.notify(player, "Você já está em um clã.", "error")
		return
	end

	local clan = getOrLoadClan(clanId)
	if not clan then
		Utils.notify(player, "Clã não encontrado.", "error")
		return
	end

	local capacity = ClanSystem.getClanCapacity(clan)
	if #clan.members >= capacity then
		Utils.notify(player, "Clã cheio.", "error")
		return
	end

	table.insert(clan.members, player.UserId)
	playerClanMap[player.UserId] = clanId
	DataSystem.saveClan(clan :: any)
	DataSystem.setPlayerClanId(player.UserId, clanId)

	syncToMembers(clan)
	Utils.notify(player, "Você entrou no clã '" .. clan.name .. "'!", "success")
end)

-- ----------------------------------------------------------------
-- RECUSAR CONVITE
-- ----------------------------------------------------------------
Remotes.DeclineInvite.OnServerEvent:Connect(function(player, clanId)
	local inviteList = pendingInvites[player.UserId]
	if not inviteList then return end
	for i, inv in ipairs(inviteList) do
		if inv.clanId == clanId then
			table.remove(inviteList, i)
			break
		end
	end
	Utils.notify(player, "Convite recusado.")
end)

-- ----------------------------------------------------------------
-- SAIR DO CLÃ
-- ----------------------------------------------------------------
Remotes.LeaveClan.OnServerEvent:Connect(function(player)
	local clan = ClanSystem.getPlayerClan(player)
	if not clan then
		Utils.notify(player, "Você não está em um clã.", "error")
		return
	end

	if clan.leaderId == player.UserId and #clan.members > 1 then
		Utils.notify(player, "Transfira a liderança antes de sair.", "error")
		return
	end

	-- Remove membro
	for i, uid in ipairs(clan.members) do
		if uid == player.UserId then
			table.remove(clan.members, i)
			break
		end
	end
	playerClanMap[player.UserId] = nil
	DataSystem.setPlayerClanId(player.UserId, nil)

	-- Dissolve o clã se vazio
	if #clan.members == 0 then
		activeClans[clan.id] = nil
		DataSystem.deleteClan(clan.id)
		Utils.notify(player, "Clã dissolvido pois ficou sem membros.")
	else
		-- Promove o próximo membro a líder se o líder saiu
		if clan.leaderId == player.UserId then
			clan.leaderId = clan.members[1]
		end
		DataSystem.saveClan(clan :: any)
		syncToMembers(clan)
		Utils.notify(player, "Você saiu do clã.")
	end

	Remotes.UpdateClanInfo:FireClient(player, nil)
end)

-- ----------------------------------------------------------------
-- EXPULSAR MEMBRO
-- ----------------------------------------------------------------
Remotes.KickMember.OnServerEvent:Connect(function(player, targetUserId)
	local clan = ClanSystem.getPlayerClan(player)
	if not clan then return end
	if clan.leaderId ~= player.UserId then
		Utils.notify(player, "Apenas o líder pode expulsar.", "error")
		return
	end
	if targetUserId == player.UserId then
		Utils.notify(player, "Você não pode se expulsar.", "error")
		return
	end

	local found = false
	for i, uid in ipairs(clan.members) do
		if uid == targetUserId then
			table.remove(clan.members, i)
			found = true
			break
		end
	end
	if not found then
		Utils.notify(player, "Membro não encontrado.", "error")
		return
	end

	playerClanMap[targetUserId] = nil
	DataSystem.setPlayerClanId(targetUserId, nil)
	DataSystem.saveClan(clan :: any)
	syncToMembers(clan)

	local target = Players:GetPlayerByUserId(targetUserId)
	if target then
		Remotes.UpdateClanInfo:FireClient(target, nil)
		Utils.notify(target, "Você foi expulso do clã '" .. clan.name .. "'.", "error")
	end
	Utils.notify(player, "Membro expulso do clã.")
end)

-- ----------------------------------------------------------------
-- LIMPEZA AO SAIR
-- ----------------------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
	pendingInvites[player.UserId] = nil
	-- Não remove do mapa; o DataStore persiste a associação
	playerClanMap[player.UserId] = nil
end)

return ClanSystem
