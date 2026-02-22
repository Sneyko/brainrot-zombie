--!strict

--[[
	LevelSelectHUD (LocalScript)
	Interface de sélection de niveau quand le joueur entre dans le portail "Jouer".
	Affiche une grille de cartes de niveaux (nom, thème, difficulté, nombre de vagues).
	Le joueur clique sur un niveau pour le lancer.
	Accessible depuis : StarterPlayerScripts.Client.Controllers.LevelSelectHUD
]]

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local sharedFolder: Instance = ReplicatedStorage:WaitForChild("Shared")
local LevelDatabase = require(sharedFolder:WaitForChild("Data"):WaitForChild("LevelDatabase"))

-- Player
local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui

-- Events
local eventsFolder: Instance = sharedFolder:WaitForChild("Events")
local portalEnteredEvent: RemoteEvent = eventsFolder:WaitForChild("PortalEntered") :: RemoteEvent
local levelSelectEvent: RemoteEvent = eventsFolder:WaitForChild("LevelSelect") :: RemoteEvent

local TOTAL_LEVELS: number = #LevelDatabase

-- Forward declarations
local hideMenu: () -> ()

-------------------------------------------------
-- Couleurs par difficulté
-------------------------------------------------
local function getDifficultyColor(levelNum: number): Color3
	if levelNum <= 2 then
		return Color3.fromRGB(80, 220, 80)      -- Vert = facile
	elseif levelNum <= 4 then
		return Color3.fromRGB(0, 200, 255)       -- Bleu = moyen
	elseif levelNum <= 6 then
		return Color3.fromRGB(255, 200, 50)      -- Jaune = difficile
	elseif levelNum <= 8 then
		return Color3.fromRGB(255, 120, 30)      -- Orange = très dur
	else
		return Color3.fromRGB(255, 50, 50)       -- Rouge = extrême
	end
end

local function getDifficultyText(levelNum: number): string
	if levelNum <= 2 then return "Facile"
	elseif levelNum <= 4 then return "Moyen"
	elseif levelNum <= 6 then return "Difficile"
	elseif levelNum <= 8 then return "Très Dur"
	else return "Extrême"
	end
end

-------------------------------------------------
-- ScreenGui
-------------------------------------------------
local screenGui: ScreenGui = Instance.new("ScreenGui")
screenGui.Name = "LevelSelectHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 20
screenGui.Parent = playerGui

-------------------------------------------------
-- Container principal (plein écran, fond semi-transparent)
-------------------------------------------------
local overlay: Frame = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.Position = UDim2.fromScale(0, 0)
overlay.BackgroundColor3 = Color3.fromRGB(5, 3, 15)
overlay.BackgroundTransparency = 0.3
overlay.BorderSizePixel = 0
overlay.Visible = false
overlay.Parent = screenGui

-------------------------------------------------
-- Panneau central
-------------------------------------------------
local panel: Frame = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromScale(0.7, 0.8)
panel.Position = UDim2.fromScale(0.15, 0.1)
panel.BackgroundColor3 = Color3.fromRGB(15, 12, 35)
panel.BackgroundTransparency = 0.1
panel.BorderSizePixel = 0
panel.Parent = overlay

local panelCorner: UICorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 24)
panelCorner.Parent = panel

local panelStroke: UIStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(0, 200, 255)
panelStroke.Thickness = 3
panelStroke.Parent = panel

-------------------------------------------------
-- Titre
-------------------------------------------------
local titleLabel: TextLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.fromScale(0.8, 0.08)
titleLabel.Position = UDim2.fromScale(0.1, 0.02)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚔️ SÉLECTION DU NIVEAU"
titleLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
titleLabel.TextStrokeTransparency = 0
titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.Parent = panel

local subtitleLabel: TextLabel = Instance.new("TextLabel")
subtitleLabel.Name = "Subtitle"
subtitleLabel.Size = UDim2.fromScale(0.6, 0.04)
subtitleLabel.Position = UDim2.fromScale(0.2, 0.1)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text = "Choisis un niveau pour commencer la défense !"
subtitleLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
subtitleLabel.TextStrokeTransparency = 0.5
subtitleLabel.TextScaled = true
subtitleLabel.Font = Enum.Font.GothamBold
subtitleLabel.Parent = panel

-------------------------------------------------
-- Bouton Fermer
-------------------------------------------------
local closeBtn: TextButton = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.fromScale(0.05, 0.06)
closeBtn.Position = UDim2.fromScale(0.93, 0.02)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
closeBtn.BackgroundTransparency = 0.3
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✖"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextStrokeTransparency = 0
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.FredokaOne
closeBtn.Parent = panel

local closeBtnCorner: UICorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 8)
closeBtnCorner.Parent = closeBtn

-------------------------------------------------
-- ScrollingFrame pour les cartes de niveaux
-------------------------------------------------
local scrollFrame: ScrollingFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "LevelGrid"
scrollFrame.Size = UDim2.fromScale(0.92, 0.78)
scrollFrame.Position = UDim2.fromScale(0.04, 0.16)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 180, 255)
scrollFrame.CanvasSize = UDim2.fromScale(0, 0) -- Auto computed
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = panel

local gridLayout: UIGridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0.47, 0, 0, 90) -- 2 colonnes, 90px de haut
gridLayout.CellPadding = UDim2.new(0.03, 0, 0, 10)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.FillDirection = Enum.FillDirection.Horizontal
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.Parent = scrollFrame

-- Padding autour de la grille
local gridPadding: UIPadding = Instance.new("UIPadding")
gridPadding.PaddingTop = UDim.new(0, 8)
gridPadding.PaddingBottom = UDim.new(0, 8)
gridPadding.PaddingLeft = UDim.new(0, 4)
gridPadding.PaddingRight = UDim.new(0, 4)
gridPadding.Parent = scrollFrame

-------------------------------------------------
-- Créer les cartes de niveaux
-------------------------------------------------
local function createLevelCard(levelNum: number, levelData: any): TextButton
	local diffColor: Color3 = getDifficultyColor(levelNum)
	local diffText: string = getDifficultyText(levelNum)

	local card: TextButton = Instance.new("TextButton")
	card.Name = `Level_{levelNum}`
	card.LayoutOrder = levelNum
	card.BackgroundColor3 = Color3.fromRGB(25, 20, 50)
	card.BackgroundTransparency = 0.1
	card.BorderSizePixel = 0
	card.Text = ""
	card.AutoButtonColor = true
	card.Parent = scrollFrame

	local cardCorner: UICorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 14)
	cardCorner.Parent = card

	local cardStroke: UIStroke = Instance.new("UIStroke")
	cardStroke.Color = diffColor
	cardStroke.Thickness = 2
	cardStroke.Transparency = 0.3
	cardStroke.Parent = card

	-- Bande colorée à gauche (indicateur de difficulté)
	local colorBand: Frame = Instance.new("Frame")
	colorBand.Name = "ColorBand"
	colorBand.Size = UDim2.fromScale(0.04, 0.85)
	colorBand.Position = UDim2.fromScale(0.02, 0.075)
	colorBand.BackgroundColor3 = diffColor
	colorBand.BorderSizePixel = 0
	colorBand.Parent = card

	local bandCorner: UICorner = Instance.new("UICorner")
	bandCorner.CornerRadius = UDim.new(0, 4)
	bandCorner.Parent = colorBand

	-- Numéro + Thème
	local numLabel: TextLabel = Instance.new("TextLabel")
	numLabel.Name = "LevelNum"
	numLabel.Size = UDim2.fromScale(0.12, 0.85)
	numLabel.Position = UDim2.fromScale(0.08, 0.075)
	numLabel.BackgroundTransparency = 1
	numLabel.Text = `{levelData.Theme}\n{levelNum}`
	numLabel.TextColor3 = diffColor
	numLabel.TextStrokeTransparency = 0
	numLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	numLabel.TextScaled = true
	numLabel.Font = Enum.Font.FredokaOne
	numLabel.Parent = card

	-- Nom du niveau
	local nameLabel: TextLabel = Instance.new("TextLabel")
	nameLabel.Name = "LevelName"
	nameLabel.Size = UDim2.fromScale(0.55, 0.4)
	nameLabel.Position = UDim2.fromScale(0.22, 0.05)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = levelData.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.Parent = card

	-- Infos (vagues, difficulté)
	local infoLabel: TextLabel = Instance.new("TextLabel")
	infoLabel.Name = "Info"
	infoLabel.Size = UDim2.fromScale(0.55, 0.35)
	infoLabel.Position = UDim2.fromScale(0.22, 0.48)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = `🌊 {levelData.WaveCount} vagues  •  ⚡ {diffText}`
	infoLabel.TextColor3 = Color3.fromRGB(170, 170, 190)
	infoLabel.TextStrokeTransparency = 0.5
	infoLabel.TextScaled = true
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.Font = Enum.Font.GothamBold
	infoLabel.Parent = card

	-- Bouton Jouer
	local playBtn: Frame = Instance.new("Frame")
	playBtn.Name = "PlayIcon"
	playBtn.Size = UDim2.fromScale(0.15, 0.65)
	playBtn.Position = UDim2.fromScale(0.82, 0.175)
	playBtn.BackgroundColor3 = diffColor
	playBtn.BackgroundTransparency = 0.2
	playBtn.BorderSizePixel = 0
	playBtn.Parent = card

	local playCorner: UICorner = Instance.new("UICorner")
	playCorner.CornerRadius = UDim.new(0, 10)
	playCorner.Parent = playBtn

	local playLabel: TextLabel = Instance.new("TextLabel")
	playLabel.Size = UDim2.fromScale(1, 1)
	playLabel.BackgroundTransparency = 1
	playLabel.Text = "▶"
	playLabel.TextColor3 = Color3.new(1, 1, 1)
	playLabel.TextStrokeTransparency = 0
	playLabel.TextScaled = true
	playLabel.Font = Enum.Font.FredokaOne
	playLabel.Parent = playBtn

	-- Effet hover
	card.MouseEnter:Connect(function()
		TweenService:Create(cardStroke, TweenInfo.new(0.2), {
			Transparency = 0,
			Thickness = 3,
		}):Play()
		TweenService:Create(card, TweenInfo.new(0.2), {
			BackgroundTransparency = 0,
		}):Play()
	end)

	card.MouseLeave:Connect(function()
		TweenService:Create(cardStroke, TweenInfo.new(0.2), {
			Transparency = 0.3,
			Thickness = 2,
		}):Play()
		TweenService:Create(card, TweenInfo.new(0.2), {
			BackgroundTransparency = 0.1,
		}):Play()
	end)

	return card
end

-- Créer toutes les cartes
for i = 1, TOTAL_LEVELS do
	local levelData = LevelDatabase[i]
	local card: TextButton = createLevelCard(i, levelData)

	card.MouseButton1Click:Connect(function()
		-- Envoyer la sélection au serveur
		levelSelectEvent:FireServer(i)
		print(`[LevelSelectHUD] 🎮 Niveau {i} sélectionné : {levelData.Name}`)

		-- Fermer le menu
		hideMenu()
	end)
end

-------------------------------------------------
-- Afficher / Cacher le menu
-------------------------------------------------
local isOpen: boolean = false

local function showMenu(): ()
	if isOpen then return end
	isOpen = true
	overlay.Visible = true

	-- Animation d'entrée
	panel.Size = UDim2.fromScale(0, 0)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	TweenService:Create(panel, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(0.7, 0.8),
		Position = UDim2.fromScale(0.15, 0.1),
	}):Play()
end

hideMenu = function(): ()
	if not isOpen then return end
	isOpen = false

	local tween = TweenService:Create(panel, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.fromScale(0, 0),
		Position = UDim2.fromScale(0.5, 0.5),
	})
	tween:Play()
	tween.Completed:Connect(function()
		overlay.Visible = false
	end)
end

-- Bouton fermer
closeBtn.MouseButton1Click:Connect(function()
	hideMenu()
end)

-- Cliquer sur le fond ferme aussi
overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		-- Vérifier que le clic est en dehors du panneau
		local absPos = panel.AbsolutePosition
		local absSize = panel.AbsoluteSize
		local mousePos = input.Position

		if mousePos.X < absPos.X or mousePos.X > absPos.X + absSize.X
			or mousePos.Y < absPos.Y or mousePos.Y > absPos.Y + absSize.Y then
			hideMenu()
		end
	end
end)

-------------------------------------------------
-- Écouter l'événement du portail "GameMap"
-------------------------------------------------
portalEnteredEvent.OnClientEvent:Connect(function(portalId: string)
	if portalId == "GameMap" then
		showMenu()
	end
end)

print("[LevelSelectHUD] ✅ Interface de sélection de niveaux initialisée")
