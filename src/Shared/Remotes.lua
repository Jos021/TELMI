--!strict
-- Cria ou recupera todos os RemoteEvents/RemoteFunctions usados no jogo.
-- Chamado no servidor (cria) e no cliente (busca).

local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IS_SERVER = RunService:IsServer()

local function getOrCreate(className: string, name: string, parent: Instance): Instance
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing
	end
	if IS_SERVER then
		local inst = Instance.new(className)
		inst.Name   = name
		inst.Parent = parent
		return inst
	end
	-- cliente aguarda até o servidor criar
	return parent:WaitForChild(name, 10)
end

local folder = IS_SERVER
	and (function()
		local f = Instance.new("Folder")
		f.Name   = "Remotes"
		f.Parent = ReplicatedStorage
		return f
	end)()
	or ReplicatedStorage:WaitForChild("Remotes", 10)

local function RE(name: string)
	return getOrCreate("RemoteEvent", name, folder) :: RemoteEvent
end

local function RF(name: string)
	return getOrCreate("RemoteFunction", name, folder) :: RemoteFunction
end

local Remotes = {
	-- Inventário
	UpdateInventory       = RE("UpdateInventory"),       -- Server → Client
	InventoryAction       = RE("InventoryAction"),       -- Client → Server (type, slot, data)

	-- Recursos
	HarvestResource       = RE("HarvestResource"),       -- Client → Server (nodeId)
	NodeDepleted          = RE("NodeDepleted"),          -- Server → Client (nodeId)
	NodeRespawned         = RE("NodeRespawned"),         -- Server → Client (nodeId, pos)

	-- Construção
	PlaceBuilding         = RE("PlaceBuilding"),         -- Client → Server (buildingType, cframe)
	RemoveBuilding        = RE("RemoveBuilding"),        -- Client → Server (buildingId)
	BuildingPlaced        = RE("BuildingPlaced"),        -- Server → Client (data)
	BuildingRemoved       = RE("BuildingRemoved"),       -- Server → Client (buildingId)
	BuildingDamaged       = RE("BuildingDamaged"),       -- Server → Client (buildingId, hp)

	-- Base
	LoadBase              = RF("LoadBase"),              -- Client → Server (RF: retorna data da base)
	UpgradeClanCenter     = RE("UpgradeClanCenter"),     -- Client → Server
	BaseLevelChanged      = RE("BaseLevelChanged"),      -- Server → Client (level)

	-- Clã
	CreateClan            = RE("CreateClan"),            -- Client → Server (name)
	InvitePlayer          = RE("InvitePlayer"),          -- Client → Server (targetUserId)
	AcceptInvite          = RE("AcceptInvite"),          -- Client → Server (clanId)
	DeclineInvite         = RE("DeclineInvite"),         -- Client → Server (clanId)
	LeaveClan             = RE("LeaveClan"),             -- Client → Server
	KickMember            = RE("KickMember"),            -- Client → Server (targetUserId)
	UpdateClanInfo        = RE("UpdateClanInfo"),        -- Server → Client (clanData)
	ClanInviteReceived    = RE("ClanInviteReceived"),    -- Server → Client (clanId, clanName)

	-- Combate
	DealDamage            = RE("DealDamage"),            -- Client → Server (targetId, weaponType)
	PlayerDied            = RE("PlayerDied"),            -- Server → Client (playerId)
	UpdateHealth          = RE("UpdateHealth"),          -- Server → Client (hp, maxHp)

	-- Raid
	DeclareRaid           = RE("DeclareRaid"),           -- Client → Server (targetClanId)
	RaidStarted           = RE("RaidStarted"),           -- Server → All (raidData)
	RaidEnded             = RE("RaidEnded"),             -- Server → All (raidData, winner)
	RaidUpdate            = RE("RaidUpdate"),            -- Server → Client (raidState)

	-- HUD / Notificações
	Notification          = RE("Notification"),          -- Server → Client (msg, type)
	UpdateHUD             = RE("UpdateHUD"),             -- Server → Client (hudData)
	ProtectionStatus      = RE("ProtectionStatus"),      -- Server → Client (isProtected, timeLeft)
}

return Remotes
