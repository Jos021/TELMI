--!strict
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Config  = require(ReplicatedStorage.Shared.Config)

local HUDController = {}

local player     = Players.LocalPlayer
local playerGui  = player:WaitForChild("PlayerGui")

-- ----------------------------------------------------------------
-- CRIAR HUD
-- ----------------------------------------------------------------
local function createHUD()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name             = "HUD"
	screenGui.ResetOnSpawn     = false
	screenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
	screenGui.Parent           = playerGui

	-- ---- BARRA DE VIDA ----
	local healthBg = Instance.new("Frame")
	healthBg.Name            = "HealthBar"
	healthBg.Size            = UDim2.new(0, 220, 0, 22)
	healthBg.Position        = UDim2.new(0, 16, 1, -60)
	healthBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	healthBg.BorderSizePixel = 0
	healthBg.Parent           = screenGui

	local corner1 = Instance.new("UICorner")
	corner1.CornerRadius = UDim.new(0, 6)
	corner1.Parent       = healthBg

	local healthFill = Instance.new("Frame")
	healthFill.Name             = "Fill"
	healthFill.Size             = UDim2.fromScale(1, 1)
	healthFill.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
	healthFill.BorderSizePixel  = 0
	healthFill.Parent            = healthBg

	local corner2 = Instance.new("UICorner")
	corner2.CornerRadius = UDim.new(0, 6)
	corner2.Parent       = healthFill

	local healthLabel = Instance.new("TextLabel")
	healthLabel.Name                 = "Label"
	healthLabel.Size                 = UDim2.fromScale(1, 1)
	healthLabel.BackgroundTransparency = 1
	healthLabel.TextColor3           = Color3.fromRGB(255, 255, 255)
	healthLabel.Font                 = Enum.Font.GothamBold
	healthLabel.TextSize             = 13
	healthLabel.Text                 = "❤ 100 / 100"
	healthLabel.Parent               = healthFill

	-- ---- RECURSOS ----
	local resFr = Instance.new("Frame")
	resFr.Name            = "Resources"
	resFr.Size            = UDim2.new(0, 160, 0, 110)
	resFr.Position        = UDim2.new(0, 16, 0, 16)
	resFr.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	resFr.BackgroundTransparency = 0.4
	resFr.BorderSizePixel = 0
	resFr.Parent           = screenGui

	local resCorner = Instance.new("UICorner")
	resCorner.CornerRadius = UDim.new(0, 8)
	resCorner.Parent       = resFr

	local resLayout = Instance.new("UIListLayout")
	resLayout.Padding = UDim.new(0, 4)
	resLayout.Parent  = resFr

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft   = UDim.new(0, 8)
	padding.PaddingTop    = UDim.new(0, 6)
	padding.PaddingRight  = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.Parent        = resFr

	local RESOURCE_ICONS = {
		Wood  = "🪵",
		Stone = "🪨",
		Iron  = "⚙",
		Food  = "🍎",
	}
	local resLabels: {[string]: TextLabel} = {}

	for _, res in ipairs({ "Wood", "Stone", "Iron", "Food" }) do
		local lbl = Instance.new("TextLabel")
		lbl.Name                 = res
		lbl.Size                 = UDim2.new(1, 0, 0, 18)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3           = Color3.fromRGB(220, 220, 220)
		lbl.Font                 = Enum.Font.Gotham
		lbl.TextSize             = 13
		lbl.TextXAlignment       = Enum.TextXAlignment.Left
		lbl.Text                 = (RESOURCE_ICONS[res] or "") .. " " .. res .. ": 0"
		lbl.Parent               = resFr
		resLabels[res]           = lbl
	end

	-- ---- PROTEÇÃO ----
	local protLabel = Instance.new("TextLabel")
	protLabel.Name                 = "ProtectionLabel"
	protLabel.Size                 = UDim2.new(0, 220, 0, 22)
	protLabel.Position             = UDim2.new(0, 16, 1, -90)
	protLabel.BackgroundColor3     = Color3.fromRGB(0, 200, 100)
	protLabel.BackgroundTransparency = 0.3
	protLabel.BorderSizePixel      = 0
	protLabel.TextColor3           = Color3.fromRGB(255, 255, 255)
	protLabel.Font                 = Enum.Font.GothamBold
	protLabel.TextSize             = 12
	protLabel.Text                 = "🛡 Protegido"
	protLabel.Visible              = false
	protLabel.Parent               = screenGui

	local protCorner = Instance.new("UICorner")
	protCorner.CornerRadius = UDim.new(0, 6)
	protCorner.Parent       = protLabel

	-- ---- NOTIFICAÇÕES ----
	local notifFrame = Instance.new("Frame")
	notifFrame.Name                 = "Notifications"
	notifFrame.Size                 = UDim2.new(0, 300, 0, 200)
	notifFrame.Position             = UDim2.new(1, -316, 0.5, -100)
	notifFrame.BackgroundTransparency = 1
	notifFrame.Parent                = screenGui

	local notifLayout = Instance.new("UIListLayout")
	notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	notifLayout.Padding           = UDim.new(0, 4)
	notifLayout.Parent            = notifFrame

	-- ---- CLAN INFO ----
	local clanFr = Instance.new("Frame")
	clanFr.Name             = "ClanInfo"
	clanFr.Size             = UDim2.new(0, 180, 0, 50)
	clanFr.Position         = UDim2.new(0.5, -90, 0, 16)
	clanFr.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	clanFr.BackgroundTransparency = 0.4
	clanFr.BorderSizePixel  = 0
	clanFr.Visible          = false
	clanFr.Parent           = screenGui

	local clanCorner = Instance.new("UICorner")
	clanCorner.CornerRadius = UDim.new(0, 8)
	clanCorner.Parent       = clanFr

	local clanLabel = Instance.new("TextLabel")
	clanLabel.Name                 = "ClanLabel"
	clanLabel.Size                 = UDim2.fromScale(1, 1)
	clanLabel.BackgroundTransparency = 1
	clanLabel.TextColor3           = Color3.fromRGB(80, 200, 255)
	clanLabel.Font                 = Enum.Font.GothamBold
	clanLabel.TextSize             = 14
	clanLabel.Text                 = ""
	clanLabel.Parent               = clanFr

	return {
		screenGui    = screenGui,
		healthFill   = healthFill,
		healthLabel  = healthLabel,
		resLabels    = resLabels,
		protLabel    = protLabel,
		notifFrame   = notifFrame,
		clanFr       = clanFr,
		clanLabel    = clanLabel,
	}
end

-- ----------------------------------------------------------------
-- NOTIFICAÇÃO FLUTUANTE
-- ----------------------------------------------------------------
local NOTIF_COLORS = {
	info    = Color3.fromRGB(50, 120, 220),
	success = Color3.fromRGB(30, 180, 80),
	error   = Color3.fromRGB(200, 50, 50),
	warning = Color3.fromRGB(220, 160, 20),
}

local function showNotification(notifFrame: Frame, message: string, notifType: string?)
	local color = NOTIF_COLORS[notifType or "info"] or NOTIF_COLORS.info

	local notif = Instance.new("Frame")
	notif.Size                 = UDim2.new(1, 0, 0, 32)
	notif.BackgroundColor3     = color
	notif.BackgroundTransparency = 0.2
	notif.BorderSizePixel      = 0
	notif.Parent               = notifFrame

	local nc = Instance.new("UICorner")
	nc.CornerRadius = UDim.new(0, 6)
	nc.Parent       = notif

	local lbl = Instance.new("TextLabel")
	lbl.Size                 = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3           = Color3.fromRGB(255, 255, 255)
	lbl.Font                 = Enum.Font.Gotham
	lbl.TextSize             = 12
	lbl.Text                 = message
	lbl.TextWrapped          = true
	lbl.Parent               = notif

	task.delay(4, function()
		local TweenService = game:GetService("TweenService")
		local tween = TweenService:Create(notif,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 }
		)
		TweenService:Create(lbl, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		tween:Play()
		tween.Completed:Connect(function()
			notif:Destroy()
		end)
	end)
end

-- ----------------------------------------------------------------
-- INICIALIZAR
-- ----------------------------------------------------------------
function HUDController.init()
	local hud = createHUD()

	-- Saúde via Humanoid local
	local function hookHealth()
		local char = player.Character or player.CharacterAdded:Wait()
		local hum  = char:WaitForChild("Humanoid") :: Humanoid
		local function updateHealth()
			local pct = hum.Health / hum.MaxHealth
			hud.healthFill.Size  = UDim2.fromScale(math.clamp(pct, 0, 1), 1)
			hud.healthLabel.Text = "❤ " .. math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
		end
		hum.HealthChanged:Connect(updateHealth)
		updateHealth()
	end
	task.spawn(hookHealth)
	player.CharacterAdded:Connect(function()
		task.spawn(hookHealth)
	end)

	-- Inventário
	Remotes.UpdateInventory.OnClientEvent:Connect(function(inv)
		for res, lbl in pairs(hud.resLabels) do
			local ICONS = { Wood = "🪵", Stone = "🪨", Iron = "⚙", Food = "🍎" }
			lbl.Text = (ICONS[res] or "") .. " " .. res .. ": " .. tostring(inv[res] or 0)
		end
	end)

	-- Proteção
	Remotes.ProtectionStatus.OnClientEvent:Connect(function(isProtected, timeLeft)
		hud.protLabel.Visible = isProtected
		if isProtected then
			local mins = math.ceil(timeLeft / 60)
			hud.protLabel.Text = "🛡 Protegido: " .. mins .. " min"
		end
	end)

	-- Notificações
	Remotes.Notification.OnClientEvent:Connect(function(message, notifType)
		showNotification(hud.notifFrame, message, notifType)
	end)

	-- Info do clã
	Remotes.UpdateClanInfo.OnClientEvent:Connect(function(clanData)
		if clanData then
			hud.clanFr.Visible  = true
			hud.clanLabel.Text  = "🏰 " .. clanData.name .. " (Nv." .. clanData.level .. ")"
		else
			hud.clanFr.Visible  = false
			hud.clanLabel.Text  = ""
		end
	end)

	-- Raid
	Remotes.RaidStarted.OnClientEvent:Connect(function(raidData)
		showNotification(hud.notifFrame,
			"⚔ RAID: " .. (raidData.attackerName or "?") .. " está atacando!",
			"error"
		)
	end)

	Remotes.RaidEnded.OnClientEvent:Connect(function(data)
		local msg = data.winner == "attacker"
			and "⚔ Raid encerrada: atacantes venceram!"
			or  "🛡 Raid encerrada: defensores resistiram!"
		showNotification(hud.notifFrame, msg, data.winner == "attacker" and "error" or "success")
	end)
end

return HUDController
