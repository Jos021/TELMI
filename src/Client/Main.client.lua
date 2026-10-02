--!strict
-- Cliente principal: inicializa todos os controllers de UI e input.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

-- Aguarda os remotes serem criados pelo servidor
require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local HUDController       = require(script.Parent.Controllers.HUDController)
local InventoryController = require(script.Parent.Controllers.InventoryController)
local BuildingController  = require(script.Parent.Controllers.BuildingController)
local ClanController      = require(script.Parent.Controllers.ClanController)

-- Aguarda o personagem aparecer antes de inicializar a UI
local player = Players.LocalPlayer
player.CharacterAdded:Wait()

HUDController.init()
InventoryController.init()
BuildingController.init()
ClanController.init()

print("[Telmi] Cliente pronto!")
print("  I  = Inventário")
print("  B  = Menu de Construção")
print("  G  = Painel do Clã")
print("  E  = Remover construção (mira com o mouse)")
print("  Clique esquerdo = Colocar construção (no modo build)")
print("  Clique direito / Esc = Sair do modo de construção")
