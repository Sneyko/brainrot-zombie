--!strict

--[[
	GameHUD (LocalScript)
	Tower Defense temps réel — Affiche Cash, HP Base et N° de vague.
	Remplace l'ancien DiceHUD devenu obsolète.
]]

-- Services
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local sharedFolder: Instance = ReplicatedStorage:WaitForChild("Shared")
local GameStore = require(script.Parent.Parent:WaitForChild("State"):WaitForChild("GameStore"))

-- Player
local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui

-------------------------------------------------
-- Construction UI
-------------------------------------------------

local screenGui: ScreenGui = Instance.new("ScreenGui")
screenGui.Name = "GameHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 10
screenGui.Parent = playerGui

-- Container en haut de l'écran
local topBar: Frame = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.fromScale(0.4, 0.06)
topBar.Position = UDim2.fromScale(0.5, 0.02)
topBar.AnchorPoint = Vector2.new(0.5, 0)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
topBar.BackgroundTransparency = 0.3
topBar.Parent = screenGui

local topCorner: UICorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0.3, 0)
topCorner.Parent = topBar

local topStroke: UIStroke = Instance.new("UIStroke")
topStroke.Color = Color3.fromRGB(80, 80, 90)
topStroke.Thickness = 2
topStroke.Parent = topBar

-- Layout horizontal
local topLayout: UIListLayout = Instance.new("UIListLayout")
topLayout.FillDirection = Enum.FillDirection.Horizontal
topLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
topLayout.VerticalAlignment = Enum.VerticalAlignment.Center
topLayout.Padding = UDim.new(0.05, 0)
topLayout.Parent = topBar

local topPadding: UIPadding = Instance.new("UIPadding")
topPadding.PaddingLeft = UDim.new(0.02, 0)
topPadding.PaddingRight = UDim.new(0.02, 0)
topPadding.Parent = topBar

-- Cash container (image + texte)
local cashFrame: Frame = Instance.new("Frame")
cashFrame.Name = "CashFrame"
cashFrame.Size = UDim2.fromScale(0.45, 0.8)
cashFrame.BackgroundTransparency = 1
cashFrame.Parent = topBar

local cashLayout: UIListLayout = Instance.new("UIListLayout")
cashLayout.FillDirection = Enum.FillDirection.Horizontal
cashLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
cashLayout.VerticalAlignment = Enum.VerticalAlignment.Center
cashLayout.Padding = UDim.new(0.03, 0)
cashLayout.Parent = cashFrame

local coinIcon: ImageLabel = Instance.new("ImageLabel")
coinIcon.Name = "CoinIcon"
coinIcon.Size = UDim2.fromScale(0.3, 1)
coinIcon.BackgroundTransparency = 1
coinIcon.Image = "rbxassetid://121334825729026"
coinIcon.ScaleType = Enum.ScaleType.Fit
coinIcon.Parent = cashFrame

local coinAspect: UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
coinAspect.AspectRatio = 1
coinAspect.Parent = coinIcon

local cashLabel: TextLabel = Instance.new("TextLabel")
cashLabel.Name = "CashLabel"
cashLabel.Size = UDim2.fromScale(0.65, 1)
cashLabel.BackgroundTransparency = 1
cashLabel.Text = "0"
cashLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
cashLabel.TextScaled = true
cashLabel.Font = Enum.Font.FredokaOne
cashLabel.TextStrokeTransparency = 0.4
cashLabel.Parent = cashFrame

-- HP label
local hpLabel: TextLabel = Instance.new("TextLabel")
hpLabel.Name = "HPLabel"
hpLabel.Size = UDim2.fromScale(0.4, 0.8)
hpLabel.BackgroundTransparency = 1
hpLabel.Text = "❤️ 20"
hpLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
hpLabel.TextScaled = true
hpLabel.Font = Enum.Font.FredokaOne
hpLabel.TextStrokeTransparency = 0.4
hpLabel.Parent = topBar

-------------------------------------------------
-- Mise à jour via GameStore
-------------------------------------------------
GameStore.BrainCoinChanged:Connect(function(brainCoin: number, baseHP: number): ()
	cashLabel.Text = tostring(brainCoin)
	hpLabel.Text = `❤️ {baseHP}`

	-- Couleur rouge si HP bas
	if baseHP <= 5 then
		hpLabel.TextColor3 = Color3.fromRGB(255, 30, 30)
	elseif baseHP <= 10 then
		hpLabel.TextColor3 = Color3.fromRGB(255, 120, 30)
	else
		hpLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	end
end)

print("[GameHUD] ✅ HUD initialisé — Cash + HP")
