--!strict

--[[
	LevelHUD (LocalScript)
	Affiche les informations du niveau en cours :
	  • 🧠 BrainCoin (monnaie)
	  • ❤️ HP de la base
	  • 🌊 Vague actuelle / totale
	  • 🏰 Niveau en cours
	Visible uniquement quand le joueur est dans un niveau.
	Rojo : StarterPlayerScripts.Client.Controllers.LevelHUD
]]

-- Services
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local GameStore = require(script.Parent.Parent:WaitForChild("State"):WaitForChild("GameStore"))
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

-- Player
local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui

-------------------------------------------------
-- Construction de l'interface
-------------------------------------------------

local screenGui: ScreenGui = Instance.new("ScreenGui")
screenGui.Name = "LevelHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = false -- caché par défaut
screenGui.Parent = playerGui

-- Frame principale (barre en haut à gauche)
local mainFrame: Frame = Instance.new("Frame")
mainFrame.Name = "InfoBar"
mainFrame.Size = UDim2.new(0, 340, 0, 140)
mainFrame.Position = UDim2.new(0, 16, 0, 80)
mainFrame.AnchorPoint = Vector2.new(0, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
mainFrame.BackgroundTransparency = 0.25
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainCorner: UICorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = mainFrame

local mainStroke: UIStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(80, 160, 255)
mainStroke.Thickness = 2
mainStroke.Transparency = 0.3
mainStroke.Parent = mainFrame

local mainPadding: UIPadding = Instance.new("UIPadding")
mainPadding.PaddingTop = UDim.new(0, 10)
mainPadding.PaddingBottom = UDim.new(0, 10)
mainPadding.PaddingLeft = UDim.new(0, 14)
mainPadding.PaddingRight = UDim.new(0, 14)
mainPadding.Parent = mainFrame

local listLayout: UIListLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.Padding = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = mainFrame

-------------------------------------------------
-- Helper : créer une ligne d'info
-------------------------------------------------
local function createInfoRow(name: string, icon: string, order: number): TextLabel
	local label: TextLabel = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, 0, 0, 26)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 20
	label.TextColor3 = Color3.fromRGB(220, 230, 255)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = `{icon} ---`
	label.LayoutOrder = order
	label.Parent = mainFrame
	return label
end

-------------------------------------------------
-- Lignes d'info
-------------------------------------------------
local levelLabel:  TextLabel = createInfoRow("LevelLabel",  "🏰", 1)
local waveLabel:   TextLabel = createInfoRow("WaveLabel",   "🌊", 2)
local coinLabel:   TextLabel = createInfoRow("CoinLabel",   "🧠", 3)
local hpLabel:     TextLabel = createInfoRow("HPLabel",     "❤️", 4)

-------------------------------------------------
-- Mise à jour des valeurs affichées
-------------------------------------------------
local function updateDisplay(): ()
	local level: number = GameStore.CurrentLevel
	local wave: number = GameStore.CurrentWave
	local totalWaves: number = GameStore.TotalWaves
	local brainCoin: number = GameStore.BrainCoin
	local baseHP: number = GameStore.BaseHP

	levelLabel.Text = `🏰 Niveau {level}`
	waveLabel.Text = if totalWaves > 0 then `🌊 Vague {wave} / {totalWaves}` else "🌊 Vague ---"
	coinLabel.Text = `🧠 BrainCoin : {brainCoin}`

	-- Couleur HP en fonction du pourcentage
	local hpRatio: number = if Constants.BASE_HP > 0 then baseHP / Constants.BASE_HP else 0
	if hpRatio > 0.6 then
		hpLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- vert
	elseif hpRatio > 0.3 then
		hpLabel.TextColor3 = Color3.fromRGB(255, 220, 50) -- jaune
	else
		hpLabel.TextColor3 = Color3.fromRGB(255, 80, 80) -- rouge
	end
	hpLabel.Text = `❤️ Base : {baseHP} / {Constants.BASE_HP}`
end

-------------------------------------------------
-- Écouter les mises à jour du GameStore
-------------------------------------------------
GameStore.BrainCoinChanged:Connect(function(): ()
	updateDisplay()
end)

-------------------------------------------------
-- Écouter InLevel pour afficher/cacher le HUD
-------------------------------------------------
GameStore.InLevelChanged:Connect(function(inLevel: boolean): ()
	screenGui.Enabled = inLevel
	if inLevel then
		updateDisplay()
	end
end)

-------------------------------------------------
-- Écouter les événements de niveau pour mettre à jour
-------------------------------------------------
GameStore.LevelChanged:Connect(function(eventType: string, data: { [string]: any }): ()
	if eventType == "LevelStart" then
		updateDisplay()
	elseif eventType == "WaveStart" then
		updateDisplay()
	elseif eventType == "WaveComplete" then
		updateDisplay()
	elseif eventType == "GameOver" then
		hpLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
		hpLabel.Text = "💀 BASE DÉTRUITE"
	elseif eventType == "LevelComplete" then
		waveLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		waveLabel.Text = "🏆 NIVEAU TERMINÉ !"
	end
end)

-- Sync initial si on rejoint en cours de partie
if GameStore.InLevel then
	screenGui.Enabled = true
	updateDisplay()
end

print("[LevelHUD] ✅ HUD de niveau initialisé")
