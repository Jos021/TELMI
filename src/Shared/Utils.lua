--!strict
local Utils = {}

function Utils.deepCopy(original: any): any
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			copy[k] = Utils.deepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

function Utils.notify(player: Player, message: string, notifType: string?)
	local Remotes = require(game:GetService("ReplicatedStorage").Shared.Remotes)
	Remotes.Notification:FireClient(player, message, notifType or "info")
end

function Utils.notifyAll(message: string, notifType: string?)
	local Players = game:GetService("Players")
	local Remotes = require(game:GetService("ReplicatedStorage").Shared.Remotes)
	for _, player in ipairs(Players:GetPlayers()) do
		Remotes.Notification:FireClient(player, message, notifType or "info")
	end
end

-- Arredonda CFrame para grade de tamanho gridSize
function Utils.snapToGrid(cf: CFrame, gridSize: number): CFrame
	local pos = cf.Position
	local snapped = Vector3.new(
		math.round(pos.X / gridSize) * gridSize,
		math.round(pos.Y / gridSize) * gridSize,
		math.round(pos.Z / gridSize) * gridSize
	)
	return CFrame.new(snapped) * (cf - cf.Position)
end

-- Gera um ID único simples
function Utils.generateId(): string
	return tostring(math.random(100000, 999999)) .. tostring(os.time())
end

-- Verifica se a tabela `t` contém todos os itens de `needed`
function Utils.hasResources(inventory: {[string]: number}, needed: {[string]: number}): boolean
	for resource, amount in pairs(needed) do
		if (inventory[resource] or 0) < amount then
			return false
		end
	end
	return true
end

-- Remove recursos da tabela de inventário (mutável)
function Utils.consumeResources(inventory: {[string]: number}, needed: {[string]: number})
	for resource, amount in pairs(needed) do
		inventory[resource] = (inventory[resource] or 0) - amount
		if inventory[resource] <= 0 then
			inventory[resource] = nil
		end
	end
end

-- Adiciona recursos à tabela de inventário (mutável)
function Utils.addResources(inventory: {[string]: number}, items: {[string]: number})
	for resource, amount in pairs(items) do
		inventory[resource] = (inventory[resource] or 0) + amount
	end
end

return Utils
