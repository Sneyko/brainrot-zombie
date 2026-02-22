--!strict

--[[
	GachaHUD (LocalScript)
	Interface du système de Gacha — s'ouvre quand le joueur entre dans le portail Gacha.
	  • Affichage du pool avec les taux
	  • Boutons de tirage (×1 et ×10)
	  • Animation de révélation avec glow de rareté
	  • Compteur de tokens et indicateurs de Pity
	Accessible depuis : StarterPlayerScripts.Client.Controllers.GachaHUD
]]

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local sharedFolder: Instance = ReplicatedStorage:WaitForChild("Shared")
local GachaCatalog = require(sharedFolder:WaitForChild("Data"):WaitForChild("GachaCatalog"))
local UnitDatabase = require(sharedFolder:WaitForChild("Data"):WaitForChild("UnitDatabase"))

-- Dossier des modèles 3D
local assetsFolder: Folder = ReplicatedStorage:WaitForChild("Assets") :: Folder

-- Liste des ViewportFrame tournants (pour la rotation continue)
local spinningViewports: { { viewport: ViewportFrame, model: Model, angle: number } } = {}

-- Player
local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui

-- Events
local eventsFolder: Instance = sharedFolder:WaitForChild("Events")
local portalEnteredEvent: RemoteEvent = eventsFolder:WaitForChild("PortalEntered") :: RemoteEvent
local gachaPullEvent: RemoteEvent = eventsFolder:WaitForChild("GachaPull") :: RemoteEvent
local gachaResultEvent: RemoteEvent = eventsFolder:WaitForChild("GachaResult") :: RemoteEvent
local gachaInfoEvent: RemoteEvent = eventsFolder:WaitForChild("GachaInfo") :: RemoteEvent

-- État local
local isOpen: boolean = false
local isPulling: boolean = false
local myTokens: number = 0
local myPullsSinceLeg: number = 0
local myPullsSinceMythic: number = 0
local pityLeg: number = GachaCatalog.PityLegendary
local pityMythic: number = GachaCatalog.PityMythic
local ownedUnits: { [string]: boolean } = { Glorbo = true }

-- Forward declarations
local hideMenu: () -> ()
local showResults: (results: { any }) -> ()
local playPullAnimation: (pullCount: number) -> ()
local pendingResults: { any }? = nil

-- Constantes de style
local BG_DARK      = Color3.fromRGB(8, 6, 20)
local BG_PANEL     = Color3.fromRGB(14, 11, 32)
local ACCENT       = Color3.fromRGB(180, 50, 255)
local ACCENT_LIGHT = Color3.fromRGB(200, 100, 255)
local TEXT_WHITE    = Color3.fromRGB(240, 240, 250)
local TEXT_DIM      = Color3.fromRGB(140, 140, 160)
local TOKEN_COLOR   = Color3.fromRGB(255, 220, 50)

local RARITY_COLORS = GachaCatalog.RarityColors

-------------------------------------------------
-- ScreenGui
-------------------------------------------------
local screenGui: ScreenGui = Instance.new("ScreenGui")
screenGui.Name = "GachaHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 25
screenGui.Parent = playerGui

-------------------------------------------------
-- Overlay (fond plein écran)
-------------------------------------------------
local overlay: Frame = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = BG_DARK
overlay.BackgroundTransparency = 0.2
overlay.BorderSizePixel = 0
overlay.Visible = false
overlay.Parent = screenGui

-------------------------------------------------
-- Panneau principal
-------------------------------------------------
local panel: Frame = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromScale(0.8, 0.85)
panel.Position = UDim2.fromScale(0.1, 0.075)
panel.BackgroundColor3 = BG_PANEL
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel = 0
panel.ClipsDescendants = true
panel.Parent = overlay

local panelCorner: UICorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 20)
panelCorner.Parent = panel

local panelStroke: UIStroke = Instance.new("UIStroke")
panelStroke.Color = ACCENT
panelStroke.Thickness = 2
panelStroke.Transparency = 0.4
panelStroke.Parent = panel

-- Accent top bar
local topAccent: Frame = Instance.new("Frame")
topAccent.Size = UDim2.new(1, 0, 0, 3)
topAccent.BackgroundColor3 = ACCENT
topAccent.BorderSizePixel = 0
topAccent.Parent = panel

-------------------------------------------------
-- Header (titre + tokens + close)
-------------------------------------------------
local header: Frame = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 50)
header.Position = UDim2.new(0, 0, 0, 3)
header.BackgroundTransparency = 1
header.Parent = panel

-- Titre
local titleLabel: TextLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.5, 0, 1, 0)
titleLabel.Position = UDim2.new(0.03, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "INVOCATION BRAINROT"
titleLabel.TextColor3 = ACCENT_LIGHT
titleLabel.TextStrokeTransparency = 0.4
titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
titleLabel.TextScaled = true
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.Parent = header

local titleConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
titleConstraint.MaxTextSize = 28
titleConstraint.Parent = titleLabel

-- Token counter
local tokenFrame: Frame = Instance.new("Frame")
tokenFrame.Name = "TokenFrame"
tokenFrame.Size = UDim2.new(0, 140, 0, 34)
tokenFrame.Position = UDim2.new(1, -200, 0.5, -17)
tokenFrame.BackgroundColor3 = Color3.fromRGB(30, 25, 55)
tokenFrame.BorderSizePixel = 0
tokenFrame.Parent = header

local tokenCorner: UICorner = Instance.new("UICorner")
tokenCorner.CornerRadius = UDim.new(0, 8)
tokenCorner.Parent = tokenFrame

local tokenStroke: UIStroke = Instance.new("UIStroke")
tokenStroke.Color = TOKEN_COLOR
tokenStroke.Thickness = 1.5
tokenStroke.Transparency = 0.5
tokenStroke.Parent = tokenFrame

local tokenLabel: TextLabel = Instance.new("TextLabel")
tokenLabel.Name = "TokenLabel"
tokenLabel.Size = UDim2.fromScale(1, 1)
tokenLabel.BackgroundTransparency = 1
tokenLabel.Text = "🎫 0"
tokenLabel.TextColor3 = TOKEN_COLOR
tokenLabel.TextScaled = true
tokenLabel.Font = Enum.Font.GothamBlack
tokenLabel.Parent = tokenFrame

local tokenTextConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
tokenTextConstraint.MaxTextSize = 20
tokenTextConstraint.Parent = tokenLabel

-- Close button
local closeBtn: TextButton = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -48, 0.5, -20)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
closeBtn.BackgroundTransparency = 0.3
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✖"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBlack
closeBtn.Parent = header

local closeBtnCorner: UICorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 8)
closeBtnCorner.Parent = closeBtn

-------------------------------------------------
-- Corps principal — 2 colonnes (pool à gauche, résultat à droite)
-------------------------------------------------
local body: Frame = Instance.new("Frame")
body.Name = "Body"
body.Size = UDim2.new(1, -20, 1, -120)
body.Position = UDim2.new(0, 10, 0, 55)
body.BackgroundTransparency = 1
body.Parent = panel

-------------------------------------------------
-- Colonne gauche : Pool des unités (design moderne)
-------------------------------------------------
local poolColumn: Frame = Instance.new("Frame")
poolColumn.Name = "PoolColumn"
poolColumn.Size = UDim2.fromScale(0.35, 1)
poolColumn.BackgroundColor3 = Color3.fromRGB(10, 8, 25)
poolColumn.BackgroundTransparency = 0.15
poolColumn.BorderSizePixel = 0
poolColumn.Parent = body

local poolCorner: UICorner = Instance.new("UICorner")
poolCorner.CornerRadius = UDim.new(0, 14)
poolCorner.Parent = poolColumn

local poolStroke: UIStroke = Instance.new("UIStroke")
poolStroke.Color = ACCENT
poolStroke.Thickness = 1.5
poolStroke.Transparency = 0.6
poolStroke.Parent = poolColumn

-- Titre pool
local poolTitle: TextLabel = Instance.new("TextLabel")
poolTitle.Size = UDim2.new(1, 0, 0, 36)
poolTitle.BackgroundTransparency = 1
poolTitle.Text = "📊  TAUX DE DROP"
poolTitle.TextColor3 = ACCENT_LIGHT
poolTitle.TextStrokeTransparency = 0.4
poolTitle.TextScaled = true
poolTitle.Font = Enum.Font.GothamBlack
poolTitle.Parent = poolColumn

local poolTitleConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
poolTitleConstraint.MaxTextSize = 16
poolTitleConstraint.Parent = poolTitle

-- Séparateur sous le titre
local poolSep: Frame = Instance.new("Frame")
poolSep.Size = UDim2.new(0.9, 0, 0, 1)
poolSep.Position = UDim2.new(0.05, 0, 0, 36)
poolSep.BackgroundColor3 = ACCENT
poolSep.BackgroundTransparency = 0.5
poolSep.BorderSizePixel = 0
poolSep.Parent = poolColumn

-- Scroll des unités du pool
local poolScroll: ScrollingFrame = Instance.new("ScrollingFrame")
poolScroll.Name = "PoolScroll"
poolScroll.Size = UDim2.new(1, -12, 1, -42)
poolScroll.Position = UDim2.new(0, 6, 0, 40)
poolScroll.BackgroundTransparency = 1
poolScroll.ScrollBarThickness = 4
poolScroll.ScrollBarImageColor3 = ACCENT
poolScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
poolScroll.CanvasSize = UDim2.fromScale(0, 0)
poolScroll.BorderSizePixel = 0
poolScroll.Parent = poolColumn

local poolLayout: UIListLayout = Instance.new("UIListLayout")
poolLayout.SortOrder = Enum.SortOrder.LayoutOrder
poolLayout.Padding = UDim.new(0, 6)
poolLayout.Parent = poolScroll

local poolPadding: UIPadding = Instance.new("UIPadding")
poolPadding.PaddingTop = UDim.new(0, 6)
poolPadding.PaddingLeft = UDim.new(0, 6)
poolPadding.PaddingRight = UDim.new(0, 6)
poolPadding.PaddingBottom = UDim.new(0, 6)
poolPadding.Parent = poolScroll

-- Créer les entrées du pool (cartes modernes avec barre de progression)
for idx, entry in GachaCatalog.Pool do
	local rarityColor: Color3 = RARITY_COLORS[entry.Rarity] or TEXT_DIM
	local unitColor: Color3 = rarityColor
	local unitInfo = (UnitDatabase :: any)[entry.UnitId]
	if unitInfo then unitColor = unitInfo.Color end

	local row: Frame = Instance.new("Frame")
	row.Name = `Pool_{entry.UnitId}`
	row.LayoutOrder = idx
	row.Size = UDim2.new(1, 0, 0, 48)
	row.BackgroundColor3 = Color3.fromRGB(16, 12, 35)
	row.BackgroundTransparency = 0.1
	row.BorderSizePixel = 0
	row.Parent = poolScroll

	local rowCorner: UICorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 10)
	rowCorner.Parent = row

	local rowStroke: UIStroke = Instance.new("UIStroke")
	rowStroke.Color = rarityColor
	rowStroke.Thickness = 1.2
	rowStroke.Transparency = 0.55
	rowStroke.Parent = row

	-- Pastille couleur (mini sphère)
	local dot: Frame = Instance.new("Frame")
	dot.Size = UDim2.new(0, 28, 0, 28)
	dot.Position = UDim2.new(0, 8, 0.5, -14)
	dot.BackgroundColor3 = unitColor
	dot.BorderSizePixel = 0
	dot.Parent = row

	local dotCorner: UICorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(0.5, 0)
	dotCorner.Parent = dot

	-- Mini highlight sur la pastille
	local dotHighlight: Frame = Instance.new("Frame")
	dotHighlight.Size = UDim2.fromScale(0.35, 0.35)
	dotHighlight.Position = UDim2.fromScale(0.12, 0.08)
	dotHighlight.BackgroundColor3 = Color3.new(1, 1, 1)
	dotHighlight.BackgroundTransparency = 0.5
	dotHighlight.BorderSizePixel = 0
	dotHighlight.Parent = dot

	local dhCorner: UICorner = Instance.new("UICorner")
	dhCorner.CornerRadius = UDim.new(0.5, 0)
	dhCorner.Parent = dotHighlight

	-- Nom
	local nameLabel: TextLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.48, 0, 0, 18)
	nameLabel.Position = UDim2.new(0, 42, 0, 4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = entry.Name
	nameLabel.TextColor3 = TEXT_WHITE
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = row

	local nameConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
	nameConstraint.MaxTextSize = 13
	nameConstraint.Parent = nameLabel

	-- Rareté en petit
	local rarSmall: TextLabel = Instance.new("TextLabel")
	rarSmall.Size = UDim2.new(0.48, 0, 0, 14)
	rarSmall.Position = UDim2.new(0, 42, 0, 22)
	rarSmall.BackgroundTransparency = 1
	rarSmall.Text = entry.Rarity
	rarSmall.TextColor3 = rarityColor
	rarSmall.TextScaled = true
	rarSmall.TextXAlignment = Enum.TextXAlignment.Left
	rarSmall.Font = Enum.Font.GothamMedium
	rarSmall.Parent = row

	local rarSmallConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
	rarSmallConstraint.MaxTextSize = 10
	rarSmallConstraint.Parent = rarSmall

	-- Taux (gros, à droite)
	local rateLabel: TextLabel = Instance.new("TextLabel")
	rateLabel.Size = UDim2.new(0, 55, 0, 20)
	rateLabel.Position = UDim2.new(1, -60, 0, 3)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = `{entry.Rate}%`
	rateLabel.TextColor3 = if entry.Rate >= 10 then TEXT_WHITE elseif entry.Rate >= 1 then Color3.fromRGB(255, 220, 100) else Color3.fromRGB(255, 80, 120)
	rateLabel.TextScaled = true
	rateLabel.TextXAlignment = Enum.TextXAlignment.Right
	rateLabel.Font = Enum.Font.GothamBlack
	rateLabel.Parent = row

	local rateConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
	rateConstraint.MaxTextSize = 14
	rateConstraint.Parent = rateLabel

	-- Barre de progression (proportionnelle au taux)
	local barBg: Frame = Instance.new("Frame")
	barBg.Size = UDim2.new(0, 50, 0, 6)
	barBg.Position = UDim2.new(1, -60, 0, 28)
	barBg.BackgroundColor3 = Color3.fromRGB(30, 25, 50)
	barBg.BorderSizePixel = 0
	barBg.Parent = row

	local barBgCorner: UICorner = Instance.new("UICorner")
	barBgCorner.CornerRadius = UDim.new(0.5, 0)
	barBgCorner.Parent = barBg

	local barFill: Frame = Instance.new("Frame")
	barFill.Size = UDim2.new(math.min(entry.Rate / 52, 1), 0, 1, 0) -- 52% max pour scale
	barFill.BackgroundColor3 = rarityColor
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg

	local barFillCorner: UICorner = Instance.new("UICorner")
	barFillCorner.CornerRadius = UDim.new(0.5, 0)
	barFillCorner.Parent = barFill
end

-------------------------------------------------
-- Colonne droite : Zone de résultat + boutons
-------------------------------------------------
local resultColumn: Frame = Instance.new("Frame")
resultColumn.Name = "ResultColumn"
resultColumn.Size = UDim2.new(0.63, 0, 1, 0)
resultColumn.Position = UDim2.new(0.37, 0, 0, 0)
resultColumn.BackgroundTransparency = 1
resultColumn.Parent = body

-- Zone de résultat (centre)
local resultArea: Frame = Instance.new("Frame")
resultArea.Name = "ResultArea"
resultArea.Size = UDim2.new(1, 0, 1, -80)
resultArea.BackgroundTransparency = 1
resultArea.ClipsDescendants = true
resultArea.Parent = resultColumn

-- Message d'attente (visible avant le premier tirage)
local waitLabel: TextLabel = Instance.new("TextLabel")
waitLabel.Name = "WaitLabel"
waitLabel.Size = UDim2.fromScale(0.8, 0.3)
waitLabel.Position = UDim2.fromScale(0.1, 0.35)
waitLabel.BackgroundTransparency = 1
waitLabel.Text = "Appuie sur INVOQUER\npour tirer un brainrot !"
waitLabel.TextColor3 = TEXT_DIM
waitLabel.TextStrokeTransparency = 0.6
waitLabel.TextScaled = true
waitLabel.Font = Enum.Font.GothamMedium
waitLabel.Parent = resultArea

local waitConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
waitConstraint.MaxTextSize = 22
waitConstraint.Parent = waitLabel

-- Container pour les cartes résultat (créé dynamiquement)
local resultContainer: Frame = Instance.new("Frame")
resultContainer.Name = "ResultContainer"
resultContainer.Size = UDim2.fromScale(1, 1)
resultContainer.BackgroundTransparency = 1
resultContainer.Visible = false
resultContainer.Parent = resultArea

-------------------------------------------------
-- Barre de boutons (en bas)
-------------------------------------------------
local buttonBar: Frame = Instance.new("Frame")
buttonBar.Name = "ButtonBar"
buttonBar.Size = UDim2.new(1, 0, 0, 70)
buttonBar.Position = UDim2.new(0, 0, 1, -70)
buttonBar.BackgroundTransparency = 1
buttonBar.Parent = resultColumn

local buttonLayout: UIListLayout = Instance.new("UIListLayout")
buttonLayout.FillDirection = Enum.FillDirection.Horizontal
buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
buttonLayout.Padding = UDim.new(0, 16)
buttonLayout.Parent = buttonBar

-- Helper pour créer un bouton
local function createPullButton(name: string, text: string, cost: number, color: Color3): TextButton
	local btn: TextButton = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 200, 0, 55)
	btn.BackgroundColor3 = color
	btn.BackgroundTransparency = 0.15
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.AutoButtonColor = true
	btn.Parent = buttonBar

	local btnCorner: UICorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 12)
	btnCorner.Parent = btn

	local btnStroke: UIStroke = Instance.new("UIStroke")
	btnStroke.Color = color
	btnStroke.Thickness = 2
	btnStroke.Transparency = 0.2
	btnStroke.Parent = btn

	-- Texte principal
	local btnLabel: TextLabel = Instance.new("TextLabel")
	btnLabel.Size = UDim2.new(1, 0, 0.55, 0)
	btnLabel.Position = UDim2.new(0, 0, 0, 2)
	btnLabel.BackgroundTransparency = 1
	btnLabel.Text = text
	btnLabel.TextColor3 = Color3.new(1, 1, 1)
	btnLabel.TextStrokeTransparency = 0.3
	btnLabel.TextScaled = true
	btnLabel.Font = Enum.Font.GothamBlack
	btnLabel.Parent = btn

	local btnLabelConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
	btnLabelConstraint.MaxTextSize = 18
	btnLabelConstraint.Parent = btnLabel

	-- Coût
	local costLabel: TextLabel = Instance.new("TextLabel")
	costLabel.Size = UDim2.new(1, 0, 0.35, 0)
	costLabel.Position = UDim2.new(0, 0, 0.6, 0)
	costLabel.BackgroundTransparency = 1
	costLabel.Text = `🎫 {cost} token{if cost > 1 then "s" else ""}`
	costLabel.TextColor3 = TOKEN_COLOR
	costLabel.TextStrokeTransparency = 0.5
	costLabel.TextScaled = true
	costLabel.Font = Enum.Font.GothamBold
	costLabel.Parent = btn

	local costConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
	costConstraint.MaxTextSize = 14
	costConstraint.Parent = costLabel

	return btn
end

local singleBtn: TextButton = createPullButton("SinglePull", "INVOQUER ×1", GachaCatalog.PullCostTokens, ACCENT)
local multiBtn: TextButton = createPullButton("MultiPull", "INVOQUER ×10", GachaCatalog.MultiPullCostTokens, Color3.fromRGB(255, 80, 120))

-------------------------------------------------
-- Pity indicators (sous les boutons, dans le panel)
-------------------------------------------------
local pityBar: Frame = Instance.new("Frame")
pityBar.Name = "PityBar"
pityBar.Size = UDim2.new(1, -20, 0, 24)
pityBar.Position = UDim2.new(0, 10, 1, -30)
pityBar.BackgroundTransparency = 1
pityBar.Parent = panel

local pityLabel: TextLabel = Instance.new("TextLabel")
pityLabel.Size = UDim2.fromScale(1, 1)
pityLabel.BackgroundTransparency = 1
pityLabel.Text = "Pity: Legendary 0/100  •  Mythic 0/500"
pityLabel.TextColor3 = TEXT_DIM
pityLabel.TextScaled = true
pityLabel.Font = Enum.Font.GothamMedium
pityLabel.Parent = pityBar

local pityConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
pityConstraint.MaxTextSize = 13
pityConstraint.Parent = pityLabel

-------------------------------------------------
-- Fonctions UI
-------------------------------------------------

local function updateUI(): ()
	tokenLabel.Text = `🎫 {myTokens}`
	pityLabel.Text = `Pity: Legendary {myPullsSinceLeg}/{pityLeg}  •  Mythic {myPullsSinceMythic}/{pityMythic}`
end

local function clearResults(): ()
	-- Arrêter les rotations en cours
	table.clear(spinningViewports)
	for _, child in resultContainer:GetChildren() do
		child:Destroy()
	end
	resultContainer.Visible = false
	waitLabel.Visible = true
end

--- Crée une carte de résultat pour un tirage
local function createResultCard(data: any, index: number, total: number): Frame
	local rarityColor: Color3 = RARITY_COLORS[data.Rarity] or TEXT_DIM
	local unitId: string = data.UnitId or "?"
	local rarity: string = data.Rarity or "Common"
	local isNew: boolean = data.IsNew or false
	local isPity: boolean = data.IsPity or false

	-- Layout : 1 résultat = centre, multi = grille
	local card: Frame = Instance.new("Frame")
	card.Name = `Card_{index}`
	card.BackgroundColor3 = Color3.fromRGB(18, 14, 38)
	card.BackgroundTransparency = 0.1
	card.BorderSizePixel = 0

	if total == 1 then
		card.Size = UDim2.new(0, 220, 0, 260)
		card.Position = UDim2.new(0.5, -110, 0.5, -130)
	else
		-- Grille 5×2
		local col: number = (index - 1) % 5
		local row: number = math.floor((index - 1) / 5)
		local cellW: number = 0.19
		local cellH: number = 0.47
		local padX: number = (1 - cellW * 5) / 6
		local padY: number = (1 - cellH * 2) / 3

		card.Size = UDim2.fromScale(cellW, cellH)
		card.Position = UDim2.fromScale(
			padX + col * (cellW + padX),
			padY + row * (cellH + padY)
		)
	end

	local cardCorner: UICorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 14)
	cardCorner.Parent = card

	-- Glow border (rareté)
	local cardStroke: UIStroke = Instance.new("UIStroke")
	cardStroke.Color = rarityColor
	cardStroke.Thickness = 3
	cardStroke.Transparency = 0
	cardStroke.Parent = card

	-- Accent top
	local cardAccent: Frame = Instance.new("Frame")
	cardAccent.Size = UDim2.new(1, 0, 0, 3)
	cardAccent.BackgroundColor3 = rarityColor
	cardAccent.BorderSizePixel = 0
	cardAccent.Parent = card

	-- Rarity label
	local rarityLabel: TextLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(0.8, 0, 0, 18)
	rarityLabel.Position = UDim2.new(0.1, 0, 0, 10)
	rarityLabel.BackgroundColor3 = rarityColor
	rarityLabel.BackgroundTransparency = 0.3
	rarityLabel.Text = string.upper(rarity)
	rarityLabel.TextColor3 = Color3.new(1, 1, 1)
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.GothamBlack
	rarityLabel.Parent = card

	local rarLabelCorner: UICorner = Instance.new("UICorner")
	rarLabelCorner.CornerRadius = UDim.new(0, 4)
	rarLabelCorner.Parent = rarityLabel

	local rarLabelConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
	rarLabelConstraint.MaxTextSize = 12
	rarLabelConstraint.Parent = rarityLabel

	-- Icône : toujours une sphère colorée, + ViewportFrame 3D si modèle disponible
	local unitInfo = (UnitDatabase :: any)[data.UnitId]
	local sphereColor: Color3 = if unitInfo then unitInfo.Color else rarityColor
	local templateName: string = `Unit_{data.UnitId}`
	local template: Instance? = assetsFolder:FindFirstChild(templateName)

	local iconFrame: Frame = Instance.new("Frame")
	iconFrame.Name = "IconContainer"
	iconFrame.Size = UDim2.new(0.6, 0, 0, 0)
	iconFrame.Position = UDim2.new(0.2, 0, 0.18, 5)
	iconFrame.BackgroundColor3 = Color3.fromRGB(10, 8, 25)
	iconFrame.BackgroundTransparency = 0.15
	iconFrame.BorderSizePixel = 0
	iconFrame.ClipsDescendants = true
	iconFrame.Parent = card

	local iconAspect: UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
	iconAspect.AspectRatio = 1
	iconAspect.Parent = iconFrame

	local iconCorner: UICorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0.12, 0)
	iconCorner.Parent = iconFrame

	-- Glow derrière l'icône (couleur rareté)
	local sphereGlow: Frame = Instance.new("Frame")
	sphereGlow.Size = UDim2.fromScale(1.1, 1.1)
	sphereGlow.Position = UDim2.fromScale(-0.05, -0.05)
	sphereGlow.BackgroundColor3 = rarityColor
	sphereGlow.BackgroundTransparency = 0.55
	sphereGlow.BorderSizePixel = 0
	sphereGlow.ZIndex = 0
	sphereGlow.Parent = iconFrame

	local glowCorner: UICorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(0.12, 0)
	glowCorner.Parent = sphereGlow

	-- Sphère colorée (TOUJOURS affichée comme base visible)
	local innerSphere: Frame = Instance.new("Frame")
	innerSphere.Size = UDim2.fromScale(0.7, 0.7)
	innerSphere.Position = UDim2.fromScale(0.15, 0.15)
	innerSphere.BackgroundColor3 = sphereColor
	innerSphere.BorderSizePixel = 0
	innerSphere.ZIndex = 1
	innerSphere.Parent = iconFrame

	local innerCorner: UICorner = Instance.new("UICorner")
	innerCorner.CornerRadius = UDim.new(0.5, 0)
	innerCorner.Parent = innerSphere

	-- Shine / highlight sur la sphère
	local highlight: Frame = Instance.new("Frame")
	highlight.Size = UDim2.fromScale(0.35, 0.35)
	highlight.Position = UDim2.fromScale(0.12, 0.08)
	highlight.BackgroundColor3 = Color3.new(1, 1, 1)
	highlight.BackgroundTransparency = 0.5
	highlight.BorderSizePixel = 0
	highlight.Parent = innerSphere

	local highlightCorner: UICorner = Instance.new("UICorner")
	highlightCorner.CornerRadius = UDim.new(0.5, 0)
	highlightCorner.Parent = highlight

	-- Initiales de l'unité au centre de la sphère
	local initialLabel: TextLabel = Instance.new("TextLabel")
	initialLabel.Size = UDim2.fromScale(0.7, 0.5)
	initialLabel.Position = UDim2.fromScale(0.15, 0.28)
	initialLabel.BackgroundTransparency = 1
	initialLabel.Text = string.sub(data.Name or unitId, 1, 2)
	initialLabel.TextColor3 = Color3.new(1, 1, 1)
	initialLabel.TextStrokeTransparency = 0.3
	initialLabel.TextScaled = true
	initialLabel.Font = Enum.Font.GothamBlack
	initialLabel.Parent = innerSphere

	-- ViewportFrame 3D (seulement si le modèle a de vrais BaseParts)
	if template ~= nil then
		-- Vérifier que le modèle contient des BaseParts visibles
		local hasParts: boolean = false
		for _, desc in (template :: Instance):GetDescendants() do
			if desc:IsA("BasePart") then
				hasParts = true
				break
			end
		end

		if hasParts then
			local viewport: ViewportFrame = Instance.new("ViewportFrame")
			viewport.Size = UDim2.fromScale(1, 1)
			viewport.BackgroundTransparency = 1
			viewport.BorderSizePixel = 0
			viewport.ZIndex = 2 -- au dessus de la sphère
			viewport.Ambient = Color3.fromRGB(180, 180, 200)
			viewport.LightColor = Color3.fromRGB(255, 255, 255)
			viewport.LightDirection = Vector3.new(-1, -1, -1)
			viewport.Parent = iconFrame

			local vpCorner: UICorner = Instance.new("UICorner")
			vpCorner.CornerRadius = UDim.new(0.12, 0)
			vpCorner.Parent = viewport

			local worldModel: WorldModel = Instance.new("WorldModel")
			worldModel.Parent = viewport

			local vpModel: Model = (template :: Instance):Clone() :: Model
			local origCF: CFrame, origSize: Vector3 = vpModel:GetBoundingBox()
			vpModel:PivotTo(CFrame.new(Vector3.zero) * origCF.Rotation)
			vpModel.Parent = worldModel

			local _, size: Vector3 = vpModel:GetBoundingBox()
			local maxDim: number = math.max(size.X, size.Y, size.Z)
			if maxDim < 0.1 then maxDim = 5 end
			local cameraDistance: number = maxDim * 1.8

			local vpCamera: Camera = Instance.new("Camera")
			vpCamera.CameraType = Enum.CameraType.Scriptable
			vpCamera.FieldOfView = 50
			vpCamera.Parent = viewport
			viewport.CurrentCamera = vpCamera

			vpCamera.CFrame = CFrame.new(
				Vector3.new(0, maxDim * 0.2, cameraDistance),
				Vector3.zero
			)

			-- Cacher la sphère fallback si le VP est fonctionnel
			innerSphere.Visible = false

			table.insert(spinningViewports, {
				viewport = viewport,
				model = vpModel,
				angle = 0,
			})
		end
	end

	-- Nom de l'unité
	local unitName: TextLabel = Instance.new("TextLabel")
	unitName.Size = UDim2.new(0.9, 0, 0, 22)
	unitName.Position = UDim2.new(0.05, 0, 1, -55)
	unitName.BackgroundTransparency = 1
	unitName.Text = data.Name or unitId
	unitName.TextColor3 = TEXT_WHITE
	unitName.TextStrokeTransparency = 0.3
	unitName.TextScaled = true
	unitName.Font = Enum.Font.GothamBlack
	unitName.Parent = card

	local unitNameConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
	unitNameConstraint.MaxTextSize = 16
	unitNameConstraint.Parent = unitName

	-- Badges : NEW / PITY
	if isNew then
		local newBadge: TextLabel = Instance.new("TextLabel")
		newBadge.Size = UDim2.new(0, 50, 0, 18)
		newBadge.Position = UDim2.new(1, -55, 0, 10)
		newBadge.BackgroundColor3 = Color3.fromRGB(0, 220, 100)
		newBadge.Text = "NEW!"
		newBadge.TextColor3 = Color3.new(1, 1, 1)
		newBadge.TextScaled = true
		newBadge.Font = Enum.Font.GothamBlack
		newBadge.Parent = card

		local newCorner: UICorner = Instance.new("UICorner")
		newCorner.CornerRadius = UDim.new(0, 4)
		newCorner.Parent = newBadge

		local newConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
		newConstraint.MaxTextSize = 11
		newConstraint.Parent = newBadge
	end

	if isPity then
		local pityBadge: TextLabel = Instance.new("TextLabel")
		pityBadge.Size = UDim2.new(0, 50, 0, 18)
		pityBadge.Position = UDim2.new(0, 5, 1, -28)
		pityBadge.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
		pityBadge.Text = "PITY!"
		pityBadge.TextColor3 = Color3.new(0, 0, 0)
		pityBadge.TextScaled = true
		pityBadge.Font = Enum.Font.GothamBlack
		pityBadge.Parent = card

		local pityCorner: UICorner = Instance.new("UICorner")
		pityCorner.CornerRadius = UDim.new(0, 4)
		pityCorner.Parent = pityBadge

		local pityBadgeConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
		pityBadgeConstraint.MaxTextSize = 11
		pityBadgeConstraint.Parent = pityBadge
	end

	card.Parent = resultContainer
	return card
end

-------------------------------------------------
-- Animation & affichage des résultats
-------------------------------------------------
-------------------------------------------------
-- Animation de tirage (orbe tournante avant résultat)
-------------------------------------------------
playPullAnimation = function(pullCount: number): ()
	-- Masquer le message d'attente et les résultats précédents
	waitLabel.Visible = false
	clearResults()

	-- Créer le conteneur d'animation
	local animContainer: Frame = Instance.new("Frame")
	animContainer.Name = "PullAnim"
	animContainer.Size = UDim2.fromScale(1, 1)
	animContainer.BackgroundTransparency = 1
	animContainer.Parent = resultArea

	-- Texte "INVOCATION..."
	local invokeLabel: TextLabel = Instance.new("TextLabel")
	invokeLabel.Size = UDim2.new(0.6, 0, 0, 30)
	invokeLabel.Position = UDim2.new(0.2, 0, 0.08, 0)
	invokeLabel.BackgroundTransparency = 1
	invokeLabel.Text = if pullCount > 1 then `INVOCATION ×{pullCount}...` else "INVOCATION..."
	invokeLabel.TextColor3 = ACCENT_LIGHT
	invokeLabel.TextStrokeTransparency = 0.3
	invokeLabel.TextScaled = true
	invokeLabel.Font = Enum.Font.GothamBlack
	invokeLabel.Parent = animContainer

	local invokeLblConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
	invokeLblConstraint.MaxTextSize = 26
	invokeLblConstraint.Parent = invokeLabel

	-- Orbe centrale
	local orbSize: number = 120
	local orb: Frame = Instance.new("Frame")
	orb.Size = UDim2.new(0, orbSize, 0, orbSize)
	orb.Position = UDim2.new(0.5, -orbSize / 2, 0.5, -orbSize / 2)
	orb.BackgroundColor3 = ACCENT
	orb.BackgroundTransparency = 0.2
	orb.BorderSizePixel = 0
	orb.Parent = animContainer

	local orbCorner: UICorner = Instance.new("UICorner")
	orbCorner.CornerRadius = UDim.new(0.5, 0)
	orbCorner.Parent = orb

	local orbStroke: UIStroke = Instance.new("UIStroke")
	orbStroke.Color = Color3.new(1, 1, 1)
	orbStroke.Thickness = 3
	orbStroke.Transparency = 0.3
	orbStroke.Parent = orb

	-- Halo extérieur qui pulse
	local halo: Frame = Instance.new("Frame")
	halo.Size = UDim2.new(0, orbSize * 1.5, 0, orbSize * 1.5)
	halo.Position = UDim2.new(0.5, -orbSize * 0.75, 0.5, -orbSize * 0.75)
	halo.BackgroundColor3 = ACCENT_LIGHT
	halo.BackgroundTransparency = 0.7
	halo.BorderSizePixel = 0
	halo.Parent = animContainer

	local haloCorner: UICorner = Instance.new("UICorner")
	haloCorner.CornerRadius = UDim.new(0.5, 0)
	haloCorner.Parent = halo

	-- Particules tournantes (petits cercles autour de l'orbe)
	local particleFrames: { Frame } = {}
	for i = 1, 6 do
		local p: Frame = Instance.new("Frame")
		p.Size = UDim2.new(0, 12, 0, 12)
		p.BackgroundColor3 = Color3.fromHSV((i - 1) / 6, 0.8, 1)
		p.BackgroundTransparency = 0.3
		p.BorderSizePixel = 0
		p.Parent = animContainer

		local pCorner: UICorner = Instance.new("UICorner")
		pCorner.CornerRadius = UDim.new(0.5, 0)
		pCorner.Parent = p

		table.insert(particleFrames, p)
	end

	-- Animation de rotation des particules + pulse du halo
	local animDuration: number = 1.8
	local startTime: number = tick()
	local animConn: RBXScriptConnection? = nil

	animConn = RunService.Heartbeat:Connect(function()
		local elapsed: number = tick() - startTime
		if elapsed > animDuration then
			if animConn then animConn:Disconnect() end
			return
		end

		local progress: number = elapsed / animDuration
		local speed: number = 2 + progress * 12 -- accélère

		-- Particules tournent
		for i, p in particleFrames do
			local angle: number = (elapsed * speed) + (i - 1) * (math.pi * 2 / #particleFrames)
			local radius: number = 80 * (1 - progress * 0.3)
			local px: number = math.cos(angle) * radius
			local py: number = math.sin(angle) * radius
			p.Position = UDim2.new(0.5, px - 6, 0.5, py - 6)
			p.BackgroundTransparency = progress * 0.5
		end

		-- Halo pulse
		local pulse: number = 1 + math.sin(elapsed * 8) * 0.15
		local haloS: number = orbSize * 1.5 * pulse
		halo.Size = UDim2.new(0, haloS, 0, haloS)
		halo.Position = UDim2.new(0.5, -haloS / 2, 0.5, -haloS / 2)
		halo.BackgroundTransparency = 0.5 + math.sin(elapsed * 6) * 0.2

		-- Orbe change de couleur progressivement
		orb.BackgroundColor3 = Color3.fromHSV((elapsed * 0.5) % 1, 0.7, 1)
	end)

	-- Flash final après l'animation
	task.delay(animDuration, function()
		-- Flash blanc plein écran
		local flash: Frame = Instance.new("Frame")
		flash.Size = UDim2.fromScale(1, 1)
		flash.BackgroundColor3 = Color3.new(1, 1, 1)
		flash.BackgroundTransparency = 0
		flash.BorderSizePixel = 0
		flash.ZIndex = 20
		flash.Parent = resultArea

		TweenService:Create(flash, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
			BackgroundTransparency = 1,
		}):Play()

		-- Supprimer les éléments d'animation
		animContainer:Destroy()

		task.delay(0.15, function()
			-- Afficher les résultats si reçus
			if pendingResults then
				showResults(pendingResults)
				pendingResults = nil
				isPulling = false
			end
			-- Si pas encore reçus, le handler OnClientEvent les affichera quand PullAnim n'existe plus
		end)

		task.delay(0.6, function()
			flash:Destroy()
		end)
	end)
end

-------------------------------------------------
-- Animation & affichage des résultats (rareté-scaled)
-------------------------------------------------

--- Crée un flash coloré sur une carte
local function createCardFlash(card: Frame, color: Color3, transparency: number, duration: number): ()
	local flash: Frame = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = transparency
	flash.BorderSizePixel = 0
	flash.ZIndex = 10
	flash.Parent = card

	local flashCrn: UICorner = Instance.new("UICorner")
	flashCrn.CornerRadius = UDim.new(0, 14)
	flashCrn.Parent = flash

	TweenService:Create(flash, TweenInfo.new(duration), {
		BackgroundTransparency = 1,
	}):Play()

	task.delay(duration + 0.1, function()
		flash:Destroy()
	end)
end

--- Crée un effet de particules radiales autour d'une carte
local function createParticleBurst(card: Frame, color: Color3, count: number, spread: number): ()
	for i = 1, count do
		local dot: Frame = Instance.new("Frame")
		dot.Size = UDim2.new(0, 8, 0, 8)
		dot.Position = UDim2.fromScale(0.5, 0.5)
		dot.BackgroundColor3 = color
		dot.BackgroundTransparency = 0
		dot.BorderSizePixel = 0
		dot.ZIndex = 12
		dot.Parent = card

		local dotCorner: UICorner = Instance.new("UICorner")
		dotCorner.CornerRadius = UDim.new(0.5, 0)
		dotCorner.Parent = dot

		local angle: number = (i / count) * math.pi * 2 + math.random() * 0.5
		local dist: number = spread + math.random(0, 30)
		local targetX: number = 0.5 + math.cos(angle) * (dist / 200)
		local targetY: number = 0.5 + math.sin(angle) * (dist / 200)

		TweenService:Create(dot, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(targetX, targetY),
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 3, 0, 3),
		}):Play()

		task.delay(0.7, function()
			dot:Destroy()
		end)
	end
end

--- Crée un effet de rayons dorés/arc-en-ciel derrière la carte
local function createRaysEffect(card: Frame, color: Color3, rayCount: number, duration: number): ()
	for i = 1, rayCount do
		local ray: Frame = Instance.new("Frame")
		ray.Size = UDim2.new(0, 2, 0.5, 0)
		ray.Position = UDim2.fromScale(0.5, 0.5)
		ray.AnchorPoint = Vector2.new(0.5, 1)
		ray.BackgroundColor3 = color
		ray.BackgroundTransparency = 0.3
		ray.BorderSizePixel = 0
		ray.Rotation = (i / rayCount) * 360
		ray.ZIndex = 0
		ray.Parent = card

		TweenService:Create(ray, TweenInfo.new(duration, Enum.EasingStyle.Quad), {
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 2, 0.8, 0),
		}):Play()

		task.delay(duration + 0.1, function()
			ray:Destroy()
		end)
	end
end

--- Animation spéciale selon la rareté pour les NOUVEAUX brainrots
local function playNewUnlockAnimation(card: Frame, rarity: string, delay_s: number): ()
	local rarityOrder: number = GachaCatalog.RarityOrder[rarity] or 1
	local rarColor: Color3 = RARITY_COLORS[rarity] or ACCENT

	task.delay(delay_s, function()
		if rarityOrder == 1 then
			-- COMMON : simple glow vert
			createCardFlash(card, Color3.fromRGB(0, 220, 100), 0.4, 0.6)

		elseif rarityOrder == 2 then
			-- RARE : glow bleu + petites particules
			createCardFlash(card, rarColor, 0.3, 0.7)
			createParticleBurst(card, rarColor, 6, 60)

		elseif rarityOrder == 3 then
			-- EPIC : double flash violet + particules + pulse de la carte
			createCardFlash(card, rarColor, 0.2, 0.8)
			task.delay(0.2, function()
				createCardFlash(card, Color3.new(1, 1, 1), 0.5, 0.4)
			end)
			createParticleBurst(card, rarColor, 12, 80)

			-- Pulse scale
			local origSize = card.Size
			TweenService:Create(card, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.new(origSize.X.Scale * 1.08, origSize.X.Offset, origSize.Y.Scale * 1.08, origSize.Y.Offset),
			}):Play()
			task.delay(0.15, function()
				TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
					Size = origSize,
				}):Play()
			end)

		elseif rarityOrder == 4 then
			-- LEGENDARY : flash doré intense + rayons + grosses particules + screen shake
			createCardFlash(card, Color3.new(1, 1, 1), 0, 0.3)
			task.delay(0.15, function()
				createCardFlash(card, rarColor, 0.1, 1.0)
			end)
			createRaysEffect(card, rarColor, 12, 1.2)
			createParticleBurst(card, rarColor, 20, 100)
			createParticleBurst(card, Color3.new(1, 1, 1), 8, 70)

			-- Screen shake
			local origPos = panel.Position
			for s = 1, 6 do
				task.delay(0.05 * s, function()
					local offsetX: number = (math.random() - 0.5) * 0.008
					local offsetY: number = (math.random() - 0.5) * 0.008
					panel.Position = UDim2.new(origPos.X.Scale + offsetX, origPos.X.Offset, origPos.Y.Scale + offsetY, origPos.Y.Offset)
				end)
			end
			task.delay(0.4, function()
				TweenService:Create(panel, TweenInfo.new(0.2), {
					Position = origPos,
				}):Play()
			end)

		elseif rarityOrder >= 5 then
			-- MYTHIC : flash arc-en-ciel séquentiel + rayons multicolores + particules massives + shake fort + pulse multiple
			-- Flash séquentiel arc-en-ciel
			local rainbowColors: { Color3 } = {
				Color3.fromRGB(255, 50, 80),
				Color3.fromRGB(255, 180, 0),
				Color3.fromRGB(0, 255, 100),
				Color3.fromRGB(0, 170, 255),
				Color3.fromRGB(180, 50, 255),
				Color3.new(1, 1, 1),
			}
			for ri, c in rainbowColors do
				task.delay(0.08 * (ri - 1), function()
					createCardFlash(card, c, 0.1, 0.4)
				end)
			end

			-- Rayons multicolores
			task.delay(0.2, function()
				for rr = 1, 16 do
					local rc: Color3 = Color3.fromHSV((rr / 16) % 1.0, 0.9, 1)
					local ray: Frame = Instance.new("Frame")
					ray.Size = UDim2.new(0, 3, 0.6, 0)
					ray.Position = UDim2.fromScale(0.5, 0.5)
					ray.AnchorPoint = Vector2.new(0.5, 1)
					ray.BackgroundColor3 = rc
					ray.BackgroundTransparency = 0.2
					ray.BorderSizePixel = 0
					ray.Rotation = (rr / 16) * 360
					ray.ZIndex = 0
					ray.Parent = card

					TweenService:Create(ray, TweenInfo.new(1.5, Enum.EasingStyle.Quad), {
						BackgroundTransparency = 1,
						Size = UDim2.new(0, 3, 1, 0),
					}):Play()
					task.delay(1.6, function()
						ray:Destroy()
					end)
				end
			end)

			-- Particules massives
			createParticleBurst(card, rarColor, 30, 120)
			task.delay(0.3, function()
				createParticleBurst(card, Color3.new(1, 1, 1), 15, 90)
			end)

			-- Screen shake fort
			local origPos = panel.Position
			for s = 1, 10 do
				task.delay(0.04 * s, function()
					local offsetX: number = (math.random() - 0.5) * 0.015
					local offsetY: number = (math.random() - 0.5) * 0.015
					panel.Position = UDim2.new(origPos.X.Scale + offsetX, origPos.X.Offset, origPos.Y.Scale + offsetY, origPos.Y.Offset)
				end)
			end
			task.delay(0.5, function()
				TweenService:Create(panel, TweenInfo.new(0.3), {
					Position = origPos,
				}):Play()
			end)

			-- Triple pulse
			local origSize = card.Size
			for pp = 0, 2 do
				task.delay(0.3 * pp, function()
					TweenService:Create(card, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
						Size = UDim2.new(origSize.X.Scale * 1.12, origSize.X.Offset, origSize.Y.Scale * 1.12, origSize.Y.Offset),
					}):Play()
					task.delay(0.12, function()
						TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
							Size = origSize,
						}):Play()
					end)
				end)
			end
		end
	end)
end

showResults = function(results: { any }): ()
	clearResults()
	waitLabel.Visible = false
	resultContainer.Visible = true

	local total: number = #results

	for i, data in results do
		local card: Frame = createResultCard(data, i, total)
		local rarityOrder: number = GachaCatalog.RarityOrder[data.Rarity] or 1

		-- Animation : fade in + scale up avec délai
		card.BackgroundTransparency = 1
		local children = card:GetDescendants()
		for _, child in children do
			if child:IsA("GuiObject") then
				(child :: GuiObject).Visible = false
			end
		end

		local revealDelay: number = 0.15 * (i - 1)

		-- Pour les rares+, ajouter un délai supplémentaire pour le suspense
		if total == 1 and rarityOrder >= 4 then
			revealDelay = 0.3
		end

		task.delay(revealDelay, function()
			-- Fade le fond
			TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
				BackgroundTransparency = 0.1,
			}):Play()

			-- Rendre les enfants visibles
			for _, child in children do
				if child:IsA("GuiObject") then
					(child :: GuiObject).Visible = true
				end
			end

			-- Flash de rareté de base pour toutes les cartes Legendary+
			if rarityOrder >= 4 then
				local rarColor: Color3 = RARITY_COLORS[data.Rarity] or ACCENT
				createCardFlash(card, rarColor, 0.3, 0.6)
			end

			-- Animation spéciale si c'est un NOUVEAU brainrot
			if data.IsNew then
				playNewUnlockAnimation(card, data.Rarity, 0.2)
			end
		end)
	end
end

-------------------------------------------------
-- Afficher / cacher le menu
-------------------------------------------------
local function showMenu(): ()
	if isOpen then return end
	isOpen = true

	clearResults()
	overlay.Visible = true

	-- Demander les infos au serveur
	gachaInfoEvent:FireServer()

	-- Animation d'entrée
	panel.Position = UDim2.fromScale(0.1, 1)
	TweenService:Create(panel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.1, 0.075),
	}):Play()
end

hideMenu = function(): ()
	if not isOpen then return end
	isOpen = false
	isPulling = false

	local tween = TweenService:Create(panel, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
		Position = UDim2.fromScale(0.1, 1),
	})
	tween:Play()
	tween.Completed:Connect(function()
		overlay.Visible = false
	end)
end

-------------------------------------------------
-- Connexions boutons
-------------------------------------------------
closeBtn.MouseButton1Click:Connect(function()
	hideMenu()
end)

-- Clic en dehors du panel
overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local absPos = panel.AbsolutePosition
		local absSize = panel.AbsoluteSize
		local mousePos = input.Position
		if mousePos.X < absPos.X or mousePos.X > absPos.X + absSize.X
			or mousePos.Y < absPos.Y or mousePos.Y > absPos.Y + absSize.Y then
			hideMenu()
		end
	end
end)

-- Tirage ×1
singleBtn.MouseButton1Click:Connect(function()
	if isPulling then return end
	if myTokens < GachaCatalog.PullCostTokens then
		-- Flash rouge sur le compteur de tokens
		TweenService:Create(tokenFrame, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(255, 40, 40),
		}):Play()
		task.delay(0.3, function()
			TweenService:Create(tokenFrame, TweenInfo.new(0.3), {
				BackgroundColor3 = Color3.fromRGB(30, 25, 55),
			}):Play()
		end)
		return
	end

	isPulling = true
	pendingResults = nil
	playPullAnimation(1)
	gachaPullEvent:FireServer("single")
end)

-- Tirage ×10
multiBtn.MouseButton1Click:Connect(function()
	if isPulling then return end
	if myTokens < GachaCatalog.MultiPullCostTokens then
		TweenService:Create(tokenFrame, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(255, 40, 40),
		}):Play()
		task.delay(0.3, function()
			TweenService:Create(tokenFrame, TweenInfo.new(0.3), {
				BackgroundColor3 = Color3.fromRGB(30, 25, 55),
			}):Play()
		end)
		return
	end

	isPulling = true
	pendingResults = nil
	playPullAnimation(10)
	gachaPullEvent:FireServer("multi")
end)

-------------------------------------------------
-- Réception des résultats du serveur
-------------------------------------------------
gachaResultEvent.OnClientEvent:Connect(function(data: any)
	if data.Error then
		isPulling = false
		pendingResults = nil
		print(`[GachaHUD] Erreur : {data.Error}`)
		return
	end

	-- Mettre à jour les tokens
	if data.TokensLeft ~= nil then
		myTokens = data.TokensLeft
	end

	-- Stocker les résultats — l'animation de tirage les affichera
	if data.Results then
		-- Si l'animation est encore en cours, stocker pour affichage différé
		local pullAnim = resultArea:FindFirstChild("PullAnim")
		if pullAnim then
			pendingResults = data.Results
		else
			-- Animation déjà terminée, afficher directement
			showResults(data.Results)
			isPulling = false
		end
	end

	updateUI()
end)

-------------------------------------------------
-- Réception de l'info inventaire
-------------------------------------------------
gachaInfoEvent.OnClientEvent:Connect(function(data: any)
	if data.Tokens ~= nil then
		myTokens = data.Tokens
	end
	if data.PullsSinceLegendary ~= nil then
		myPullsSinceLeg = data.PullsSinceLegendary
	end
	if data.PullsSinceMythic ~= nil then
		myPullsSinceMythic = data.PullsSinceMythic
	end
	if data.PityLegendary ~= nil then
		pityLeg = data.PityLegendary
	end
	if data.PityMythic ~= nil then
		pityMythic = data.PityMythic
	end
	if data.OwnedUnits then
		ownedUnits = {}
		for _, unitId in data.OwnedUnits do
			ownedUnits[unitId] = true
		end
	end

	updateUI()
end)

-------------------------------------------------
-- Écouter le portail "Gacha"
-------------------------------------------------
portalEnteredEvent.OnClientEvent:Connect(function(portalId: string)
	if portalId == "Gacha" then
		showMenu()
	end
end)

-------------------------------------------------
-- Rotation continue des ViewportFrame (modèles 3D)
-------------------------------------------------
RunService.RenderStepped:Connect(function(dt: number)
	for i = #spinningViewports, 1, -1 do
		local entry = spinningViewports[i]
		if entry.viewport == nil or entry.viewport.Parent == nil then
			table.remove(spinningViewports, i)
			continue
		end

		entry.angle += dt * 40 -- 40 degrés/seconde

		-- Le modèle est centré à l'origine, on tourne la caméra autour
		local ok, _, size = pcall(function()
			return entry.model:GetBoundingBox()
		end)
		if not ok then
			table.remove(spinningViewports, i)
			continue
		end

		local maxDim: number = math.max(size.X, size.Y, size.Z)
		if maxDim < 0.1 then maxDim = 5 end
		local dist: number = maxDim * 1.8
		local rad: number = math.rad(entry.angle)

		local camPos: Vector3 = Vector3.new(
			math.sin(rad) * dist,
			maxDim * 0.2,
			math.cos(rad) * dist
		)

		local cam = entry.viewport.CurrentCamera
		if cam then
			cam.CFrame = CFrame.new(camPos, Vector3.zero)
		end
	end
end)

print("[GachaHUD] ✅ Interface de Gacha initialisée")
