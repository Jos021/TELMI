--!strict
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")

local Config  = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local InventoryController = {}

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local currentInventory: {[string]: number} = {}
local inventoryGui: ScreenGui? = nil

-- ----------------------------------------------------------------
-- CRIAR INTERFACE DE INVENTÁRIO
-- ----------------------------------------------------------------
local function createInventoryGui()
	local existing = playerGui:FindFirstChild("InventoryUI")
	if existing then existing:Destroy() end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name         = "InventoryUI"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled      = false
	screenGui.Parent       = playerGui

	local panel = Instance.new("Frame")
	panel.Name             = "Panel"
	panel.Size             = UDim2.new(0, 320, 0, 420)
	panel.Position         = UDim2.new(0.5, -160, 0.5, -210)
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel  = 0
	panel.Parent           = screenGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 12)
	panelCorner.Parent       = panel

	-- Título
	local header = Instance.new("Frame")
	header.Size             = UDim2.new(1, 0, 0, 44)
	header.BackgroundColor3 = Color3.fromRGB(40, 90, 180)
	header.BorderSizePixel  = 0
	header.Parent           = panel

	local hc = Instance.new("UICorner")
	hc.CornerRadius = UDim.new(0, 12)
	hc.Parent       = header

	local title = Instance.new("TextLabel")
	title.Size                 = UDim2.fromScale(1, 1)
	title.BackgroundTransparency = 1
	title.TextColor3           = Color3.fromRGB(255, 255, 255)
	title.Font                 = Enum.Font.GothamBold
	title.TextSize             = 16
	title.Text                 = "🎒 INVENTÁRIO"
	title.Parent               = header

	-- Botão fechar
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size             = UDim2.new(0, 32, 0, 32)
	closeBtn.Position         = UDim2.new(1, -38, 0, 6)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeBtn.BorderSizePixel  = 0
	closeBtn.Text             = "✕"
	closeBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
	closeBtn.Font             = Enum.Font.GothamBold
	closeBtn.TextSize         = 14
	closeBtn.Parent           = header

	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 6)
	cc.Parent       = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		screenGui.Enabled = false
	end)

	-- Lista de recursos
	local listFrame = Instance.new("ScrollingFrame")
	listFrame.Size               = UDim2.new(1, -16, 1, -56)
	listFrame.Position           = UDim2.new(0, 8, 0, 50)
	listFrame.BackgroundTransparency = 1
	listFrame.BorderSizePixel    = 0
	listFrame.ScrollBarThickness = 4
	listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listFrame.CanvasSize         = UDim2.new(0, 0, 0, 0)
	listFrame.Parent             = panel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent  = listFrame

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft   = UDim.new(0, 4)
	pad.PaddingTop    = UDim.new(0, 4)
	pad.PaddingRight  = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 4)
	pad.Parent        = listFrame

	inventoryGui = screenGui

	return screenGui, listFrame
end

-- ----------------------------------------------------------------
-- ATUALIZAR LISTA
-- ----------------------------------------------------------------
local listFrameRef: ScrollingFrame? = nil

local function refreshInventoryUI(inv: {[string]: number})
	if not inventoryGui or not listFrameRef then return end

	-- Limpar filhos (exceto UIListLayout e UIPadding)
	for _, child in ipairs(listFrameRef:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local RESOURCE_ICONS = { Wood = "🪵", Stone = "🪨", Iron = "⚙", Food = "🍎" }
	local RESOURCE_COLORS = {
		Wood  = Color3.fromRGB(160, 120, 60),
		Stone = Color3.fromRGB(130, 130, 130),
		Iron  = Color3.fromRGB(180, 180, 180),
		Food  = Color3.fromRGB(80, 200, 80),
	}

	local hasItems = false
	for item, amount in pairs(inv) do
		if amount <= 0 then continue end
		hasItems = true

		local row = Instance.new("Frame")
		row.Size             = UDim2.new(1, 0, 0, 52)
		row.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
		row.BorderSizePixel  = 0
		row.Parent           = listFrameRef

		local rc = Instance.new("UICorner")
		rc.CornerRadius = UDim.new(0, 8)
		rc.Parent       = row

		-- Ícone colorido
		local iconFr = Instance.new("Frame")
		iconFr.Size             = UDim2.new(0, 40, 0, 40)
		iconFr.Position         = UDim2.new(0, 6, 0.5, -20)
		iconFr.BackgroundColor3 = RESOURCE_COLORS[item] or Color3.fromRGB(100, 100, 100)
		iconFr.BorderSizePixel  = 0
		iconFr.Parent           = row

		local ic = Instance.new("UICorner")
		ic.CornerRadius = UDim.new(0, 6)
		ic.Parent       = iconFr

		local iconLbl = Instance.new("TextLabel")
		iconLbl.Size                 = UDim2.fromScale(1, 1)
		iconLbl.BackgroundTransparency = 1
		iconLbl.Text                 = RESOURCE_ICONS[item] or "?"
		iconLbl.TextSize             = 20
		iconLbl.Parent               = iconFr

		-- Nome e quantidade
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size               = UDim2.new(1, -120, 0, 22)
		nameLbl.Position           = UDim2.new(0, 54, 0, 8)
		nameLbl.BackgroundTransparency = 1
		nameLbl.TextColor3         = Color3.fromRGB(220, 220, 220)
		nameLbl.Font               = Enum.Font.GothamBold
		nameLbl.TextSize           = 14
		nameLbl.TextXAlignment     = Enum.TextXAlignment.Left
		nameLbl.Text               = item
		nameLbl.Parent             = row

		local amtLbl = Instance.new("TextLabel")
		amtLbl.Size               = UDim2.new(1, -54, 0, 18)
		amtLbl.Position           = UDim2.new(0, 54, 0, 28)
		amtLbl.BackgroundTransparency = 1
		amtLbl.TextColor3         = Color3.fromRGB(160, 160, 180)
		amtLbl.Font               = Enum.Font.Gotham
		amtLbl.TextSize           = 12
		amtLbl.TextXAlignment     = Enum.TextXAlignment.Left
		amtLbl.Text               = "Quantidade: " .. amount
		amtLbl.Parent             = row

		-- Botão usar (apenas para comida)
		if item == Config.RESOURCES.FOOD then
			local useBtn = Instance.new("TextButton")
			useBtn.Size             = UDim2.new(0, 52, 0, 32)
			useBtn.Position         = UDim2.new(1, -58, 0.5, -16)
			useBtn.BackgroundColor3 = Color3.fromRGB(30, 160, 60)
			useBtn.BorderSizePixel  = 0
			useBtn.Text             = "Usar"
			useBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
			useBtn.Font             = Enum.Font.GothamBold
			useBtn.TextSize         = 12
			useBtn.Parent           = row

			local uc = Instance.new("UICorner")
			uc.CornerRadius = UDim.new(0, 6)
			uc.Parent       = useBtn

			useBtn.MouseButton1Click:Connect(function()
				Remotes.InventoryAction:FireServer("use", item, 1)
			end)
		end
	end

	if not hasItems then
		local emptyLbl = Instance.new("TextLabel")
		emptyLbl.Size                 = UDim2.new(1, 0, 0, 40)
		emptyLbl.BackgroundTransparency = 1
		emptyLbl.TextColor3           = Color3.fromRGB(130, 130, 150)
		emptyLbl.Font                 = Enum.Font.Gotham
		emptyLbl.TextSize             = 13
		emptyLbl.Text                 = "Inventário vazio. Colete recursos!"
		emptyLbl.Parent               = listFrameRef
	end
end

-- ----------------------------------------------------------------
-- INICIALIZAR
-- ----------------------------------------------------------------
function InventoryController.init()
	local gui, listFrame = createInventoryGui()
	listFrameRef = listFrame

	-- Atualizar ao receber dados do servidor
	Remotes.UpdateInventory.OnClientEvent:Connect(function(inv)
		currentInventory = inv
		if inventoryGui and inventoryGui.Enabled then
			refreshInventoryUI(inv)
		end
	end)

	-- I = abrir/fechar inventário
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.I then
			if inventoryGui then
				inventoryGui.Enabled = not inventoryGui.Enabled
				if inventoryGui.Enabled then
					refreshInventoryUI(currentInventory)
				end
			end
		end
	end)

	print("[InventoryController] Iniciado. Pressione I para abrir o inventário.")
end

return InventoryController
