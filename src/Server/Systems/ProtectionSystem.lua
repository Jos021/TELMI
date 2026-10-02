--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Config  = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local ProtectionSystem = {}

-- userId → timestamp de entrada (primeira vez que entrou)
local firstJoinTime: {[number]: number} = {}

function ProtectionSystem.onPlayerAdded(player: Player)
	firstJoinTime[player.UserId] = os.time()
	ProtectionSystem.sendStatus(player)

	-- Atualiza o cliente a cada minuto enquanto tiver proteção
	task.spawn(function()
		while firstJoinTime[player.UserId] do
			task.wait(60)
			if player.Parent then
				ProtectionSystem.sendStatus(player)
			end
		end
	end)
end

function ProtectionSystem.onPlayerRemoving(player: Player)
	firstJoinTime[player.UserId] = nil
end

function ProtectionSystem.isProtected(player: Player): boolean
	local joined = firstJoinTime[player.UserId]
	if not joined then return false end
	return (os.time() - joined) < Config.PLAYER.protectionDuration
end

function ProtectionSystem.timeLeft(player: Player): number
	local joined = firstJoinTime[player.UserId]
	if not joined then return 0 end
	local elapsed = os.time() - joined
	return math.max(0, Config.PLAYER.protectionDuration - elapsed)
end

function ProtectionSystem.sendStatus(player: Player)
	local protected = ProtectionSystem.isProtected(player)
	local left      = ProtectionSystem.timeLeft(player)
	Remotes.ProtectionStatus:FireClient(player, protected, left)
end

Players.PlayerAdded:Connect(ProtectionSystem.onPlayerAdded)
Players.PlayerRemoving:Connect(ProtectionSystem.onPlayerRemoving)

return ProtectionSystem
