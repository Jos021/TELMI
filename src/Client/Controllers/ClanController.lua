--!strict
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local ClanController = {}

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local currentClan: any = nil
local clanGui: ScreenGui? = nil

-- ----------------------------------------------------------------
-- CRIAR GUI DO CLÃ
-- ----------------------------------------------------------------
local function createClanGui()
	local existing = playerGui:FindFirstChild("ClanUI")
	if existing then existing:Destroy() end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name         = "ClanUI"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled      = false
	screenGui.Parent       = playerGui

	local panel = Instance.new("Frame")
	panel.Name             = "Panel"
	panel.Size             = UDim2.new(0, 360, 0, 500)
	panel.Position         = UDim2.new(0.5, -180, 0.5, -250)
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel  = 0
	panel.Parent           = screenGui

	local pc = Instance.new("UICorner")
	pc.CornerRadius = UDim.new(0, 12)
	pc.Parent       = panel

	-- Header
	local header = Instance.new("Frame")
	header.Size             = UDim2.new(1, 0, 0, 44)
	header.BackgroundColor3 = Color3.fromRGB(60, 40, 120)
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
	title.Text                 = "🏰 CLÃ"
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

	-- Corpo dinâmico (substituído ao atualizar)
	local body = Instance.new("Frame")
	body.Name             = "Body"
	body.Size             = UDim2.new(1, -16, 1, -52)
	body.Position         = UDim2.new(0, 8, 0, 48)
	body.BackgroundTransparency = 1
	body.Parent           = panel

	clanGui = screenGui
	return screenGui, body
end

-- ----------------------------------------------------------------
-- RENDERIZAR ESTADO
-- ----------------------------------------------------------------
local bodyRef: Frame? = nil

local function clearBody()
	if not bodyRef then return end
	for _, child in ipairs(bodyRef:GetChildren()) do
		child:Destroy()
	end
end

local function renderNoClan()
	clearBody()
	if not bodyRef then return end

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = bodyRef

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.PaddingTop = UDim.new(0, 12)
	pad.Parent = bodyRef

	local infoLbl = Instance.new("TextLabel")
	infoLbl.Size                 = UDim2.new(1, 0, 0, 40)
	infoLbl.BackgroundTransparency = 1
	infoLbl.TextColor3           = Color3.fromRGB(180, 180, 200)
	infoLbl.Font                 = Enum.Font.Gotham
	infoLbl.TextSize             = 13
	infoLbl.TextWrapped          = true
	infoLbl.Text                 = "Você não pertence a nenhum clã.\nCrie um ou aguarde um convite!"
	infoLbl.Parent               = bodyRef

	-- Campo de texto + botão criar clã
	local nameInput = Instance.new("TextBox")
	nameInput.Size                 = UDim2.new(1, 0, 0, 36)
	nameInput.BackgroundColor3     = Color3.fromRGB(35, 35, 55)
	nameInput.BorderSizePixel      = 0
	nameInput.PlaceholderText      = "Nome do clã (2–24 caracteres)"
	nameInput.PlaceholderColor3    = Color3.fromRGB(120, 120, 140)
	nameInput.Text                 = ""
	nameInput.TextColor3           = Color3.fromRGB(220, 220, 220)
	nameInput.Font                 = Enum.Font.Gotham
	nameInput.TextSize             = 13
	nameInput.ClearTextOnFocus     = false
	nameInput.Parent               = bodyRef

	local nic = Instance.new("UICorner")
	nic.CornerRadius = UDim.new(0, 6)
	nic.Parent       = nameInput

	local createBtn = Instance.new("TextButton")
	createBtn.Size             = UDim2.new(1, 0, 0, 40)
	createBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
	createBtn.BorderSizePixel  = 0
	createBtn.Text             = "Criar Clã"
	createBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
	createBtn.Font             = Enum.Font.GothamBold
	createBtn.TextSize         = 14
	createBtn.Parent           = bodyRef

	local cbc = Instance.new("UICorner")
	cbc.CornerRadius = UDim.new(0, 8)
	cbc.Parent       = createBtn

	createBtn.MouseButton1Click:Connect(function()
		local name = nameInput.Text
		if #name >= 2 then
			Remotes.CreateClan:FireServer(name)
			nameInput.Text = ""
		end
	end)
end

local function renderClanInfo(clan: any)
	clearBody()
	if not bodyRef then return end

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.Parent = bodyRef

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.PaddingTop = UDim.new(0, 8)
	pad.Parent = bodyRef

	-- Info geral
	local infoFr = Instance.new("Frame")
	infoFr.Size             = UDim2.new(1, 0, 0, 70)
	infoFr.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
	infoFr.BorderSizePixel  = 0
	infoFr.Parent           = bodyRef

	local ic = Instance.new("UICorner")
	ic.CornerRadius = UDim.new(0, 8)
	ic.Parent       = infoFr

	local pad2 = Instance.new("UIPadding")
	pad2.PaddingLeft  = UDim.new(0, 10)
	pad2.PaddingTop   = UDim.new(0, 8)
	pad2.Parent       = infoFr

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size                 = UDim2.new(1, -20, 0, 24)
	nameLbl.BackgroundTransparency = 1
	nameLbl.TextColor3           = Color3.fromRGB(80, 200, 255)
	nameLbl.Font                 = Enum.Font.GothamBold
	nameLbl.TextSize             = 16
	nameLbl.TextXAlignment       = Enum.TextXAlignment.Left
	nameLbl.Text                 = "🏰 " .. tostring(clan.name)
	nameLbl.Parent               = infoFr

	local levelLbl = Instance.new("TextLabel")
	levelLbl.Size                 = UDim2.new(1, -20, 0, 18)
	levelLbl.Position             = UDim2.new(0, 0, 0, 26)
	levelLbl.BackgroundTransparency = 1
	levelLbl.TextColor3           = Color3.fromRGB(180, 180, 200)
	levelLbl.Font                 = Enum.Font.Gotham
	levelLbl.TextSize             = 13
	levelLbl.TextXAlignment       = Enum.TextXAlignment.Left
	levelLbl.Text                 = "Nível " .. tostring(clan.level) ..
		"  |  Membros: " .. #clan.members .. "/" .. tostring(clan.capacity)
	levelLbl.Parent               = infoFr

	-- Lista de membros
	local membersTitle = Instance.new("TextLabel")
	membersTitle.Size                 = UDim2.new(1, 0, 0, 22)
	membersTitle.BackgroundTransparency = 1
	membersTitle.TextColor3           = Color3.fromRGB(220, 220, 220)
	membersTitle.Font                 = Enum.Font.GothamBold
	membersTitle.TextSize             = 13
	membersTitle.TextXAlignment       = Enum.TextXAlignment.Left
	membersTitle.Text                 = "Membros:"
	membersTitle.Parent               = bodyRef

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size               = UDim2.new(1, 0, 0, 180)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel    = 0
	scroll.ScrollBarThickness = 4
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize         = UDim2.new(0, 0, 0, 0)
	scroll.Parent             = bodyRef

	local mLayout = Instance.new("UIListLayout")
	mLayout.Padding = UDim.new(0, 4)
	mLayout.Parent  = scroll

	for _, uid in ipairs(clan.members) do
		local memberRow = Instance.new("Frame")
		memberRow.Size             = UDim2.new(1, 0, 0, 36)
		memberRow.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
		memberRow.BorderSizePixel  = 0
		memberRow.Parent           = scroll

		local mrc = Instance.new("UICorner")
		mrc.CornerRadius = UDim.new(0, 6)
		mrc.Parent       = memberRow

		local isLeader = uid == clan.leaderId
		local isOnline = Players:GetPlayerByUserId(uid) ~= nil

		local mLbl = Instance.new("TextLabel")
		mLbl.Size                 = UDim2.new(1, -50, 1, 0)
		mLbl.Position             = UDim2.new(0, 10, 0, 0)
		mLbl.BackgroundTransparency = 1
		mLbl.TextColor3           = isLeader and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(200, 200, 200)
		mLbl.Font                 = isLeader and Enum.Font.GothamBold or Enum.Font.Gotham
		mLbl.TextSize             = 13
		mLbl.TextXAlignment       = Enum.TextXAlignment.Left
		mLbl.Text                 = (isLeader and "👑 " or "• ") ..
			"ID:" .. uid .. (isOnline and " 🟢" or " ⚫")
		mLbl.Parent               = memberRow

		-- Líder pode expulsar membros (exceto si mesmo)
		if clan.leaderId == player.UserId and uid ~= player.UserId then
			local kickBtn = Instance.new("TextButton")
			kickBtn.Size             = UDim2.new(0, 42, 0, 26)
			kickBtn.Position         = UDim2.new(1, -48, 0.5, -13)
			kickBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
			kickBtn.BorderSizePixel  = 0
			kickBtn.Text             = "Kick"
			kickBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
			kickBtn.Font             = Enum.Font.GothamBold
			kickBtn.TextSize         = 11
			kickBtn.Parent           = memberRow

			local kc = Instance.new("UICorner")
			kc.CornerRadius = UDim.new(0, 4)
			kc.Parent       = kickBtn

			kickBtn.MouseButton1Click:Connect(function()
				Remotes.KickMember:FireServer(uid)
			end)
		end
	end

	-- Botões de ação
	local actionsTitle = Instance.new("TextLabel")
	actionsTitle.Size                 = UDim2.new(1, 0, 0, 20)
	actionsTitle.BackgroundTransparency = 1
	actionsTitle.TextColor3           = Color3.fromRGB(180, 180, 200)
	actionsTitle.Font                 = Enum.Font.GothamBold
	actionsTitle.TextSize             = 12
	actionsTitle.TextXAlignment       = Enum.TextXAlignment.Left
	actionsTitle.Text                 = "Ações:"
	actionsTitle.Parent               = bodyRef

	local leaveBtn = Instance.new("TextButton")
	leaveBtn.Size             = UDim2.new(1, 0, 0, 36)
	leaveBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
	leaveBtn.BorderSizePixel  = 0
	leaveBtn.Text             = "Sair do Clã"
	leaveBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
	leaveBtn.Font             = Enum.Font.GothamBold
	leaveBtn.TextSize         = 13
	leaveBtn.Parent           = bodyRef

	local lbc = Instance.new("UICorner")
	lbc.CornerRadius = UDim.new(0, 8)
	lbc.Parent       = leaveBtn

	leaveBtn.MouseButton1Click:Connect(function()
		Remotes.LeaveClan:FireServer()
	end)
end

-- ----------------------------------------------------------------
-- CONVITE RECEBIDO
-- ----------------------------------------------------------------
local function showInviteNotification(clanId: string, clanName: string)
	local playerGui2 = player:WaitForChild("PlayerGui")
	local screenGui  = Instance.new("ScreenGui")
	screenGui.Name         = "InviteNotif"
	screenGui.ResetOnSpawn = false
	screenGui.Parent       = playerGui2

	local frame = Instance.new("Frame")
	frame.Size             = UDim2.new(0, 320, 0, 100)
	frame.Position         = UDim2.new(0.5, -160, 0, 80)
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	frame.BorderSizePixel  = 0
	frame.Parent           = screenGui

	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(0, 10)
	fc.Parent       = frame

	local lbl = Instance.new("TextLabel")
	lbl.Size                 = UDim2.new(1, -16, 0.5, 0)
	lbl.Position             = UDim2.new(0, 8, 0, 8)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3           = Color3.fromRGB(220, 220, 220)
	lbl.Font                 = Enum.Font.Gotham
	lbl.TextSize             = 13
	lbl.TextWrapped          = true
	lbl.Text                 = "🏰 Convite para o clã:\n'" .. clanName .. "'"
	lbl.Parent               = frame

	local acceptBtn = Instance.new("TextButton")
	acceptBtn.Size             = UDim2.new(0.45, -6, 0, 32)
	acceptBtn.Position         = UDim2.new(0, 8, 1, -40)
	acceptBtn.BackgroundColor3 = Color3.fromRGB(30, 160, 60)
	acceptBtn.BorderSizePixel  = 0
	acceptBtn.Text             = "Aceitar"
	acceptBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
	acceptBtn.Font             = Enum.Font.GothamBold
	acceptBtn.TextSize         = 13
	acceptBtn.Parent           = frame

	local ac = Instance.new("UICorner")
	ac.CornerRadius = UDim.new(0, 6)
	ac.Parent       = acceptBtn

	local declineBtn = Instance.new("TextButton")
	declineBtn.Size             = UDim2.new(0.45, -6, 0, 32)
	declineBtn.Position         = UDim2.new(0.55, -2, 1, -40)
	declineBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	declineBtn.BorderSizePixel  = 0
	declineBtn.Text             = "Recusar"
	declineBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
	declineBtn.Font             = Enum.Font.GothamBold
	declineBtn.TextSize         = 13
	declineBtn.Parent           = frame

	local dc = Instance.new("UICorner")
	dc.CornerRadius = UDim.new(0, 6)
	dc.Parent       = declineBtn

	acceptBtn.MouseButton1Click:Connect(function()
		Remotes.AcceptInvite:FireServer(clanId)
		screenGui:Destroy()
	end)
	declineBtn.MouseButton1Click:Connect(function()
		Remotes.DeclineInvite:FireServer(clanId)
		screenGui:Destroy()
	end)

	task.delay(20, function()
		if screenGui.Parent then
			screenGui:Destroy()
		end
	end)
end

-- ----------------------------------------------------------------
-- INICIALIZAR
-- ----------------------------------------------------------------
function ClanController.init()
	local gui, body = createClanGui()
	bodyRef = body

	-- Atualizar info do clã
	Remotes.UpdateClanInfo.OnClientEvent:Connect(function(clanData)
		currentClan = clanData
		if clanGui and clanGui.Enabled then
			if clanData then
				renderClanInfo(clanData)
			else
				renderNoClan()
			end
		end
	end)

	-- Convite recebido
	Remotes.ClanInviteReceived.OnClientEvent:Connect(function(clanId, clanName)
		showInviteNotification(clanId, clanName)
	end)

	-- G = abrir/fechar painel de clã
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.G then
			if clanGui then
				clanGui.Enabled = not clanGui.Enabled
				if clanGui.Enabled then
					if currentClan then
						renderClanInfo(currentClan)
					else
						renderNoClan()
					end
				end
			end
		end
	end)

	print("[ClanController] Iniciado. Pressione G para o painel de clã.")
end

return ClanController
