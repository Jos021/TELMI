--!strict
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")

local Config  = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local BuildingController = {}

local player    = Players.LocalPlayer
local camera    = workspace.CurrentCamera
local GRID_SIZE = 4

-- Estado de construção
local buildMode       = false
local selectedType    = "WoodBlock"
local previewPart: BasePart? = nil
local canPlace        = false

-- ----------------------------------------------------------------
-- PREVIEW
-- ----------------------------------------------------------------
local function destroyPreview()
	if previewPart then
		previewPart:Destroy()
		previewPart = nil
	end
end

local function createPreview(buildingType: string): BasePart
	destroyPreview()
	local data = Config.BUILDING_DATA[buildingType]
	if not data then
		return Instance.new("Part") -- fallback
	end

	local part = Instance.new("Part")
	part.Name        = "BuildPreview"
	part.Size        = data.size
	part.Color       = data.color
	part.Material    = data.material
	part.Anchored    = true
	part.CanCollide  = false
	part.Transparency = 0.5
	part.CastShadow  = false
	part.Parent      = workspace
	previewPart = part
	return part
end

local function snapPosition(pos: Vector3): Vector3
	return Vector3.new(
		math.round(pos.X / GRID_SIZE) * GRID_SIZE,
		math.round(pos.Y / GRID_SIZE) * GRID_SIZE,
		math.round(pos.Z / GRID_SIZE) * GRID_SIZE
	)
end

local function getRaycastTarget(): (Vector3?, BasePart?)
	local mouse = player:GetMouse()
	local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
	local params  = RaycastParams.new()
	params.FilterDescendantsInstances = { previewPart }
	params.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 80, params)
	if result then
		return result.Position, result.Instance :: BasePart
	end
	return nil, nil
end

-- ----------------------------------------------------------------
-- LOOP DE PREVIEW (RenderStepped)
-- ----------------------------------------------------------------
local renderConnection: RBXScriptConnection? = nil

local function startPreviewLoop()
	if renderConnection then renderConnection:Disconnect() end
	renderConnection = RunService.RenderStepped:Connect(function()
		if not buildMode or not previewPart then return end

		local pos, _ = getRaycastTarget()
		if pos then
			local snapped = snapPosition(pos + Vector3.new(0, previewPart.Size.Y / 2, 0))
			previewPart.CFrame = CFrame.new(snapped)
			previewPart.Color  = Color3.fromRGB(0, 200, 100) -- verde = pode colocar
			canPlace = true
		else
			previewPart.Color = Color3.fromRGB(200, 50, 50) -- vermelho = não pode
			canPlace = false
		end
	end)
end

local function stopPreviewLoop()
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
end

-- ----------------------------------------------------------------
-- MENU DE CONSTRUÇÃO
-- ----------------------------------------------------------------
local buildMenuGui: ScreenGui? = nil

local function createBuildMenu()
	local playerGui = player:WaitForChild("PlayerGui")
	local existing  = playerGui:FindFirstChild("BuildMenu")
	if existing then existing:Destroy() end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name           = "BuildMenu"
	screenGui.ResetOnSpawn   = false
	screenGui.Enabled        = false
	screenGui.Parent         = playerGui

	local panel = Instance.new("Frame")
	panel.Name             = "Panel"
	panel.Size             = UDim2.new(0, 280, 0, 380)
	panel.Position         = UDim2.new(1, -296, 0.5, -190)
	panel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	panel.BackgroundTransparency = 0.1
	panel.BorderSizePixel  = 0
	panel.Parent           = screenGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 10)
	panelCorner.Parent       = panel

	local title = Instance.new("TextLabel")
	title.Size             = UDim2.new(1, 0, 0, 36)
	title.BackgroundColor3 = Color3.fromRGB(40, 100, 200)
	title.BackgroundTransparency = 0
	title.BorderSizePixel  = 0
	title.Text             = "🔨 CONSTRUÇÃO"
	title.TextColor3       = Color3.fromRGB(255, 255, 255)
	title.Font             = Enum.Font.GothamBold
	title.TextSize         = 15
	title.Parent           = panel

	local tc = Instance.new("UICorner")
	tc.CornerRadius = UDim.new(0, 10)
	tc.Parent       = title

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size                = UDim2.new(1, -12, 1, -44)
	scroll.Position            = UDim2.new(0, 6, 0, 38)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel     = 0
	scroll.ScrollBarThickness  = 4
	scroll.CanvasSize          = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent              = panel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent  = scroll

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft   = UDim.new(0, 4)
	pad.PaddingTop    = UDim.new(0, 4)
	pad.PaddingRight  = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 4)
	pad.Parent        = scroll

	-- Botões por tipo de construção (MVP)
	local MVP_BUILDINGS = {
		"WoodBlock", "StoneBlock", "Wall", "Floor", "Door", "Chest", "Nucleus", "Tower"
	}

	for _, bType in ipairs(MVP_BUILDINGS) do
		local data = Config.BUILDING_DATA[bType]
		if not data then continue end

		local btn = Instance.new("TextButton")
		btn.Name             = bType
		btn.Size             = UDim2.new(1, 0, 0, 50)
		btn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
		btn.BorderSizePixel  = 0
		btn.Text             = ""
		btn.Parent           = scroll

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent       = btn

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size               = UDim2.new(1, -8, 0.5, 0)
		nameLabel.Position           = UDim2.new(0, 8, 0, 4)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3         = Color3.fromRGB(220, 220, 220)
		nameLabel.Font               = Enum.Font.GothamBold
		nameLabel.TextSize           = 13
		nameLabel.TextXAlignment     = Enum.TextXAlignment.Left
		nameLabel.Text               = data.label
		nameLabel.Parent             = btn

		local costParts = {}
		for res, amt in pairs(data.cost) do
			table.insert(costParts, res .. ": " .. amt)
		end
		local costLabel = Instance.new("TextLabel")
		costLabel.Size               = UDim2.new(1, -8, 0.5, -4)
		costLabel.Position           = UDim2.new(0, 8, 0.5, 0)
		costLabel.BackgroundTransparency = 1
		costLabel.TextColor3         = Color3.fromRGB(160, 160, 180)
		costLabel.Font               = Enum.Font.Gotham
		costLabel.TextSize           = 11
		costLabel.TextXAlignment     = Enum.TextXAlignment.Left
		costLabel.Text               = table.concat(costParts, "  |  ")
		costLabel.Parent             = btn

		btn.MouseButton1Click:Connect(function()
			selectedType = bType
			BuildingController.enterBuildMode(bType)
			screenGui.Enabled = false
		end)
	end

	buildMenuGui = screenGui
	return screenGui
end

-- ----------------------------------------------------------------
-- MODO DE CONSTRUÇÃO
-- ----------------------------------------------------------------
function BuildingController.enterBuildMode(buildingType: string)
	buildMode    = true
	selectedType = buildingType
	createPreview(buildingType)
	startPreviewLoop()
end

function BuildingController.exitBuildMode()
	buildMode = false
	destroyPreview()
	stopPreviewLoop()
end

function BuildingController.toggleMenu()
	if not buildMenuGui then
		createBuildMenu()
	end
	buildMenuGui = player:WaitForChild("PlayerGui"):FindFirstChild("BuildMenu") :: ScreenGui?
	if buildMenuGui then
		buildMenuGui.Enabled = not buildMenuGui.Enabled
		if buildMenuGui.Enabled then
			BuildingController.exitBuildMode()
		end
	end
end

-- ----------------------------------------------------------------
-- INPUT
-- ----------------------------------------------------------------
function BuildingController.init()
	createBuildMenu()

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		-- B = abrir menu de construção
		if input.KeyCode == Enum.KeyCode.B then
			BuildingController.toggleMenu()
		end

		-- Clique esquerdo = colocar construção
		if input.UserInputType == Enum.UserInputType.MouseButton1 and buildMode then
			if not canPlace or not previewPart then return end
			local cf = previewPart.CFrame
			local components = { cf:GetComponents() }
			Remotes.PlaceBuilding:FireServer(selectedType, components)
		end

		-- Clique direito = cancelar modo de construção
		if input.UserInputType == Enum.UserInputType.MouseButton2 and buildMode then
			BuildingController.exitBuildMode()
		end

		-- Escape = fechar menu / sair do modo
		if input.KeyCode == Enum.KeyCode.Escape then
			BuildingController.exitBuildMode()
			if buildMenuGui then
				buildMenuGui.Enabled = false
			end
		end
	end)

	-- Receber confirmação do servidor e replicar para todos os clientes
	Remotes.BuildingPlaced.OnClientEvent:Connect(function(data)
		-- A construção física já foi criada no servidor; não recriar no cliente
		-- (FilteringEnabled cuida disso — o servidor replica a Part)
	end)

	Remotes.BuildingRemoved.OnClientEvent:Connect(function(_buildingId)
		-- Idem: o servidor destrói a Part e a replicação cuida do restante
	end)

	print("[BuildingController] Iniciado. Pressione B para abrir o menu de construção.")
end

-- Acesso ao modo de remoção: jogador clica em uma peça com E
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.E then
		local mouse  = player:GetMouse()
		local target = mouse.Target
		if target then
			local idVal = target:FindFirstChild("BuildingId")
			if idVal then
				Remotes.RemoveBuilding:FireServer(idVal.Value)
			end
		end
	end
end)

return BuildingController
