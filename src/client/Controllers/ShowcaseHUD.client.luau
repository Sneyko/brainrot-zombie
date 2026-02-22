--!strict

--[[
	ShowcaseHUD (LocalScript)
	Vitrine complète de tous les Brainrots — design moderne, aéré, avec ViewportFrame 3D.
	S'ouvre quand le joueur entre dans le portail "Showcase".
	
	Architecture UI :
	  ScreenGui > Overlay > Panel
	    ├── Header (titre + close)
	    ├── ScrollingFrame (grille)
	    │     └── UIGridLayout + UIPadding
	    │         └── Card × N
	    │               ├── ViewportFrame (3D) ou sphère colorée
	    │               ├── Nom
	    │               ├── Rareté badge
	    │               ├── Stats
	    │               └── UIStroke (glow rareté)
	    └── Footer (légende raretés)
]]

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local sharedFolder: Instance = ReplicatedStorage:WaitForChild("Shared")
local BrainrotCatalog = require(sharedFolder:WaitForChild("Data"):WaitForChild("BrainrotCatalog"))
local GachaCatalog = require(sharedFolder:WaitForChild("Data"):WaitForChild("GachaCatalog"))

local RARITY_COLORS: { [string]: Color3 } = (BrainrotCatalog :: any)._RARITY_COLORS
local DISPLAY_ORDER: { string } = (BrainrotCatalog :: any)._DISPLAY_ORDER

-- Assets
local assetsFolder: Folder = ReplicatedStorage:WaitForChild("Assets") :: Folder

-- Player
local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui

-- Events
local eventsFolder: Instance = sharedFolder:WaitForChild("Events")
local portalEnteredEvent: RemoteEvent = eventsFolder:WaitForChild("PortalEntered") :: RemoteEvent
local gachaInfoEvent: RemoteEvent = eventsFolder:WaitForChild("GachaInfo") :: RemoteEvent

-- État
local isOpen: boolean = false
local ownedUnits: { [string]: boolean } = { Glorbo = true }

-- Spinning viewports
local spinningViewports: { { viewport: ViewportFrame, model: Model, angle: number } } = {}

-- Forward
local hideMenu: () -> ()

-- ═══════════════════════════════════════════════════
-- STYLE CONSTANTS
-- ═══════════════════════════════════════════════════
local BG_DARK      = Color3.fromRGB(6, 4, 16)
local BG_PANEL     = Color3.fromRGB(12, 9, 28)
local BG_CARD      = Color3.fromRGB(18, 14, 38)
local ACCENT       = Color3.fromRGB(140, 60, 255)
local TEXT_WHITE    = Color3.fromRGB(240, 240, 250)
local TEXT_DIM      = Color3.fromRGB(130, 130, 150)
local TEXT_LOCKED   = Color3.fromRGB(80, 80, 90)

-- ═══════════════════════════════════════════════════
-- ScreenGui
-- ═══════════════════════════════════════════════════
local screenGui: ScreenGui = Instance.new("ScreenGui")
screenGui.Name = "ShowcaseHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 20
screenGui.Parent = playerGui

-- ═══════════════════════════════════════════════════
-- Overlay
-- ═══════════════════════════════════════════════════
local overlay: Frame = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = BG_DARK
overlay.BackgroundTransparency = 0.15
overlay.BorderSizePixel = 0
overlay.Visible = false
overlay.Parent = screenGui

-- ═══════════════════════════════════════════════════
-- Panel principal
-- ═══════════════════════════════════════════════════
local panel: Frame = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromScale(0.85, 0.88)
panel.Position = UDim2.fromScale(0.075, 0.06)
panel.BackgroundColor3 = BG_PANEL
panel.BackgroundTransparency = 0.03
panel.BorderSizePixel = 0
panel.ClipsDescendants = true
panel.Parent = overlay

local panelCorner: UICorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 22)
panelCorner.Parent = panel

local panelStroke: UIStroke = Instance.new("UIStroke")
panelStroke.Color = ACCENT
panelStroke.Thickness = 2
panelStroke.Transparency = 0.4
panelStroke.Parent = panel

-- Top accent bar
local topBar: Frame = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 3)
topBar.BackgroundColor3 = ACCENT
topBar.BorderSizePixel = 0
topBar.Parent = panel

-- ═══════════════════════════════════════════════════
-- Header
-- ═══════════════════════════════════════════════════
local header: Frame = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 56)
header.Position = UDim2.new(0, 0, 0, 3)
header.BackgroundTransparency = 1
header.Parent = panel

-- Titre
local titleLabel: TextLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.7, 0, 0.6, 0)
titleLabel.Position = UDim2.new(0.03, 0, 0, 2)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "COLLECTION BRAINROT"
titleLabel.TextColor3 = TEXT_WHITE
titleLabel.TextStrokeTransparency = 0.3
titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
titleLabel.TextScaled = true
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.Parent = header

local titleConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
titleConstraint.MaxTextSize = 32
titleConstraint.Parent = titleLabel

-- Sous-titre dynamique (X/Y débloqués)
local subtitleLabel: TextLabel = Instance.new("TextLabel")
subtitleLabel.Name = "Subtitle"
subtitleLabel.Size = UDim2.new(0.3, 0, 0, 20)
subtitleLabel.Position = UDim2.new(0.03, 0, 0.6, 2)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text = "1/10 débloqués"
subtitleLabel.TextColor3 = TEXT_DIM
subtitleLabel.TextScaled = true
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
subtitleLabel.Font = Enum.Font.GothamMedium
subtitleLabel.Parent = header

local subConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
subConstraint.MaxTextSize = 14
subConstraint.Parent = subtitleLabel

-- Close button
local closeBtn: TextButton = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 44, 0, 44)
closeBtn.Position = UDim2.new(1, -52, 0.5, -22)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
closeBtn.BackgroundTransparency = 0.3
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✖"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBlack
closeBtn.Parent = header

local closeBtnCorner: UICorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 10)
closeBtnCorner.Parent = closeBtn

-- ═══════════════════════════════════════════════════
-- Séparateur header
-- ═══════════════════════════════════════════════════
local headerSep: Frame = Instance.new("Frame")
headerSep.Size = UDim2.new(0.96, 0, 0, 1)
headerSep.Position = UDim2.new(0.02, 0, 0, 60)
headerSep.BackgroundColor3 = ACCENT
headerSep.BackgroundTransparency = 0.6
headerSep.BorderSizePixel = 0
headerSep.Parent = panel

-- ═══════════════════════════════════════════════════
-- ScrollingFrame (grille de cartes)
-- ═══════════════════════════════════════════════════
local scrollFrame: ScrollingFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "CardGrid"
scrollFrame.Size = UDim2.new(1, -24, 1, -110)
scrollFrame.Position = UDim2.new(0, 12, 0, 66)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollBarImageColor3 = ACCENT
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.CanvasSize = UDim2.fromScale(0, 0)
scrollFrame.BorderSizePixel = 0
scrollFrame.ElasticBehavior = Enum.ElasticBehavior.Always
scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
scrollFrame.Parent = panel

-- GridLayout
local gridLayout: UIGridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 200, 0, 280)
gridLayout.CellPadding = UDim2.new(0, 16, 0, 16)
gridLayout.FillDirection = Enum.FillDirection.Horizontal
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = scrollFrame

-- Padding interne
local gridPadding: UIPadding = Instance.new("UIPadding")
gridPadding.PaddingTop = UDim.new(0, 12)
gridPadding.PaddingBottom = UDim.new(0, 12)
gridPadding.PaddingLeft = UDim.new(0, 12)
gridPadding.PaddingRight = UDim.new(0, 12)
gridPadding.Parent = scrollFrame

-- ═══════════════════════════════════════════════════
-- Footer (légende des raretés)
-- ═══════════════════════════════════════════════════
local footer: Frame = Instance.new("Frame")
footer.Name = "Footer"
footer.Size = UDim2.new(1, 0, 0, 36)
footer.Position = UDim2.new(0, 0, 1, -38)
footer.BackgroundColor3 = Color3.fromRGB(8, 6, 18)
footer.BackgroundTransparency = 0.3
footer.BorderSizePixel = 0
footer.Parent = panel

local footerLayout: UIListLayout = Instance.new("UIListLayout")
footerLayout.FillDirection = Enum.FillDirection.Horizontal
footerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
footerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
footerLayout.Padding = UDim.new(0, 20)
footerLayout.Parent = footer

local rarityNames = { "Common", "Rare", "Epic", "Legendary", "Mythic" }
for _, rarName in rarityNames do
	local rarColor: Color3 = RARITY_COLORS[rarName] or TEXT_DIM
	local dot: Frame = Instance.new("Frame")
	dot.Size = UDim2.new(0, 10, 0, 10)
	dot.BackgroundColor3 = rarColor
	dot.BorderSizePixel = 0
	dot.Parent = footer

	local dotCorner: UICorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(0.5, 0)
	dotCorner.Parent = dot

	local lbl: TextLabel = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0, 70, 0, 20)
	lbl.BackgroundTransparency = 1
	lbl.Text = rarName
	lbl.TextColor3 = rarColor
	lbl.TextScaled = true
	lbl.Font = Enum.Font.GothamBold
	lbl.Parent = footer

	local lblC: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
	lblC.MaxTextSize = 12
	lblC.Parent = lbl
end

-- ═══════════════════════════════════════════════════
-- Création des cartes
-- ═══════════════════════════════════════════════════

local cardFrames: { [string]: Frame } = {}
local viewportLabels: { [string]: TextLabel } = {}

local function createCard(brainrotId: string, entry: any, order: number): Frame
	local rarityColor: Color3 = RARITY_COLORS[entry.Rarity] or TEXT_DIM
	local isOwned: boolean = ownedUnits[brainrotId] == true
	local isAvailable: boolean = entry.Available ~= false

	-- Carte
	local card: Frame = Instance.new("Frame")
	card.Name = `Card_{brainrotId}`
	card.LayoutOrder = order
	card.BackgroundColor3 = if isOwned then BG_CARD else Color3.fromRGB(12, 10, 22)
	card.BackgroundTransparency = if isOwned then 0.05 else 0.2
	card.BorderSizePixel = 0
	card.ClipsDescendants = true

	local cardCorner: UICorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 16)
	cardCorner.Parent = card

	-- Glow border (rareté)
	local stroke: UIStroke = Instance.new("UIStroke")
	stroke.Name = "RarityStroke"
	stroke.Color = rarityColor
	stroke.Thickness = if isOwned then 2.5 else 1.5
	stroke.Transparency = if isOwned then 0.1 else 0.6
	stroke.Parent = card

	-- Padding interne
	local cardPadding: UIPadding = Instance.new("UIPadding")
	cardPadding.PaddingTop = UDim.new(0, 10)
	cardPadding.PaddingBottom = UDim.new(0, 10)
	cardPadding.PaddingLeft = UDim.new(0, 10)
	cardPadding.PaddingRight = UDim.new(0, 10)
	cardPadding.Parent = card

	-- Accent top bar
	local accentBar: Frame = Instance.new("Frame")
	accentBar.Size = UDim2.new(1, 20, 0, 3)
	accentBar.Position = UDim2.new(0, -10, 0, -10)
	accentBar.BackgroundColor3 = rarityColor
	accentBar.BackgroundTransparency = if isOwned then 0 else 0.5
	accentBar.BorderSizePixel = 0
	accentBar.Parent = card

	-- Rareté badge (en haut)
	local rarBadge: TextLabel = Instance.new("TextLabel")
	rarBadge.Size = UDim2.new(0.7, 0, 0, 18)
	rarBadge.Position = UDim2.new(0.15, 0, 0, 2)
	rarBadge.BackgroundColor3 = rarityColor
	rarBadge.BackgroundTransparency = 0.25
	rarBadge.Text = string.upper(entry.Rarity)
	rarBadge.TextColor3 = Color3.new(1, 1, 1)
	rarBadge.TextScaled = true
	rarBadge.Font = Enum.Font.GothamBlack
	rarBadge.Parent = card

	local rarBadgeCorner: UICorner = Instance.new("UICorner")
	rarBadgeCorner.CornerRadius = UDim.new(0, 6)
	rarBadgeCorner.Parent = rarBadge

	local rarBadgeConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
	rarBadgeConstraint.MaxTextSize = 11
	rarBadgeConstraint.Parent = rarBadge

	-- ViewportFrame / Icône (zone centrale)
	local iconContainer: Frame = Instance.new("Frame")
	iconContainer.Name = "IconContainer"
	iconContainer.Size = UDim2.new(0.75, 0, 0, 0)
	iconContainer.Position = UDim2.new(0.125, 0, 0, 26)
	iconContainer.BackgroundColor3 = Color3.fromRGB(8, 6, 20)
	iconContainer.BackgroundTransparency = 0.3
	iconContainer.BorderSizePixel = 0
	iconContainer.ClipsDescendants = true
	iconContainer.Parent = card

	local iconAspect: UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
	iconAspect.AspectRatio = 1
	iconAspect.Parent = iconContainer

	local iconCorner: UICorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0.12, 0)
	iconCorner.Parent = iconContainer

	-- Glow derrière l'icône
	local iconGlow: Frame = Instance.new("Frame")
	iconGlow.Size = UDim2.fromScale(1.08, 1.08)
	iconGlow.Position = UDim2.fromScale(-0.04, -0.04)
	iconGlow.BackgroundColor3 = rarityColor
	iconGlow.BackgroundTransparency = if isOwned then 0.55 else 0.85
	iconGlow.BorderSizePixel = 0
	iconGlow.ZIndex = 0
	iconGlow.Parent = iconContainer

	local glowCorner: UICorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(0.12, 0)
	glowCorner.Parent = iconGlow

	local templateName: string = `Unit_{brainrotId}`
	local template: Instance? = assetsFolder:FindFirstChild(templateName)

	if isOwned then
		-- Sphère colorée (TOUJOURS affichée comme base)
		local sphere: Frame = Instance.new("Frame")
		sphere.Size = UDim2.fromScale(0.65, 0.65)
		sphere.Position = UDim2.fromScale(0.175, 0.175)
		sphere.BackgroundColor3 = entry.Color
		sphere.BorderSizePixel = 0
		sphere.ZIndex = 1
		sphere.Parent = iconContainer

		local sCorner: UICorner = Instance.new("UICorner")
		sCorner.CornerRadius = UDim.new(0.5, 0)
		sCorner.Parent = sphere

		local sHighlight: Frame = Instance.new("Frame")
		sHighlight.Size = UDim2.fromScale(0.35, 0.35)
		sHighlight.Position = UDim2.fromScale(0.12, 0.08)
		sHighlight.BackgroundColor3 = Color3.new(1, 1, 1)
		sHighlight.BackgroundTransparency = 0.5
		sHighlight.BorderSizePixel = 0
		sHighlight.Parent = sphere

		local shCorner: UICorner = Instance.new("UICorner")
		shCorner.CornerRadius = UDim.new(0.5, 0)
		shCorner.Parent = sHighlight

		-- Initiales
		local initLabel: TextLabel = Instance.new("TextLabel")
		initLabel.Size = UDim2.fromScale(0.7, 0.5)
		initLabel.Position = UDim2.fromScale(0.15, 0.28)
		initLabel.BackgroundTransparency = 1
		initLabel.Text = string.sub(entry.Name, 1, 2)
		initLabel.TextColor3 = Color3.new(1, 1, 1)
		initLabel.TextStrokeTransparency = 0.3
		initLabel.TextScaled = true
		initLabel.Font = Enum.Font.GothamBlack
		initLabel.Parent = sphere

		-- VP 3D seulement si modèle a des BaseParts
		if template ~= nil then
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
				viewport.ZIndex = 2
				viewport.Ambient = Color3.fromRGB(180, 180, 200)
				viewport.LightColor = Color3.fromRGB(255, 255, 255)
				viewport.LightDirection = Vector3.new(-1, -1, -1)
				viewport.Parent = iconContainer

				local vpCorner: UICorner = Instance.new("UICorner")
				vpCorner.CornerRadius = UDim.new(0.12, 0)
				vpCorner.Parent = viewport

				local worldModel: WorldModel = Instance.new("WorldModel")
				worldModel.Parent = viewport

				local vpModel: Model = (template :: Instance):Clone() :: Model
				local origCF: CFrame = vpModel:GetBoundingBox()
				vpModel:PivotTo(CFrame.new(Vector3.zero) * origCF.Rotation)
				vpModel.Parent = worldModel

				local _, size: Vector3 = vpModel:GetBoundingBox()
				local maxDim: number = math.max(size.X, size.Y, size.Z)
				if maxDim < 0.1 then maxDim = 5 end
				local camDist: number = maxDim * 1.8

				local vpCamera: Camera = Instance.new("Camera")
				vpCamera.CameraType = Enum.CameraType.Scriptable
				vpCamera.FieldOfView = 50
				vpCamera.Parent = viewport
				viewport.CurrentCamera = vpCamera

				vpCamera.CFrame = CFrame.new(
					Vector3.new(0, maxDim * 0.2, camDist),
					Vector3.zero
				)

				sphere.Visible = false

				table.insert(spinningViewports, {
					viewport = viewport,
					model = vpModel,
					angle = order * 30,
				})
			end
		end
	else
		-- Locked → silhouette sombre avec 🔒
		local lockedFrame: Frame = Instance.new("Frame")
		lockedFrame.Size = UDim2.fromScale(0.65, 0.65)
		lockedFrame.Position = UDim2.fromScale(0.175, 0.175)
		lockedFrame.BackgroundColor3 = Color3.fromRGB(30, 28, 40)
		lockedFrame.BorderSizePixel = 0
		lockedFrame.Parent = iconContainer

		local lCorner: UICorner = Instance.new("UICorner")
		lCorner.CornerRadius = UDim.new(0.5, 0)
		lCorner.Parent = lockedFrame

		local qMark: TextLabel = Instance.new("TextLabel")
		qMark.Name = "QuestionMark"
		qMark.Size = UDim2.fromScale(0.6, 0.6)
		qMark.Position = UDim2.fromScale(0.2, 0.2)
		qMark.BackgroundTransparency = 1
		qMark.Text = "🔒"
		qMark.TextColor3 = TEXT_LOCKED
		qMark.TextScaled = true
		qMark.Font = Enum.Font.GothamBlack
		qMark.Parent = lockedFrame

		viewportLabels[brainrotId] = qMark
	end

	-- Nom
	local nameLabel: TextLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0, 24)
	nameLabel.Position = UDim2.new(0, 0, 1, -70)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = if isOwned or isAvailable then entry.Name else "???"
	nameLabel.TextColor3 = if isOwned then TEXT_WHITE else TEXT_LOCKED
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.Parent = card

	local nameConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
	nameConstraint.MaxTextSize = 16
	nameConstraint.Parent = nameLabel

	-- Stats
	local statsLabel: TextLabel = Instance.new("TextLabel")
	statsLabel.Name = "StatsLabel"
	statsLabel.Size = UDim2.new(1, 0, 0, 16)
	statsLabel.Position = UDim2.new(0, 0, 1, -46)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Text = if isOwned then entry.Stats else "— — —"
	statsLabel.TextColor3 = if isOwned then Color3.fromRGB(150, 210, 255) else TEXT_LOCKED
	statsLabel.TextScaled = true
	statsLabel.Font = Enum.Font.GothamMedium
	statsLabel.Parent = card

	local statsConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
	statsConstraint.MaxTextSize = 11
	statsConstraint.Parent = statsLabel

	-- Description courte
	local descLabel: TextLabel = Instance.new("TextLabel")
	descLabel.Name = "DescLabel"
	descLabel.Size = UDim2.new(1, 0, 0, 14)
	descLabel.Position = UDim2.new(0, 0, 1, -30)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = if isOwned then entry.Description else ""
	descLabel.TextColor3 = TEXT_DIM
	descLabel.TextScaled = true
	descLabel.TextWrapped = true
	descLabel.Font = Enum.Font.Gotham
	descLabel.Parent = card

	local descConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
	descConstraint.MaxTextSize = 10
	descConstraint.Parent = descLabel

	-- Badge "BIENTÔT" si pas disponible
	if not isAvailable then
		local soonBadge: TextLabel = Instance.new("TextLabel")
		soonBadge.Size = UDim2.new(1, 20, 0, 22)
		soonBadge.Position = UDim2.new(0, -10, 0.5, -11)
		soonBadge.BackgroundColor3 = Color3.fromRGB(40, 35, 55)
		soonBadge.BackgroundTransparency = 0.2
		soonBadge.Text = "BIENTÔT"
		soonBadge.TextColor3 = Color3.fromRGB(255, 80, 80)
		soonBadge.TextScaled = true
		soonBadge.Font = Enum.Font.GothamBlack
		soonBadge.Rotation = -8
		soonBadge.ZIndex = 5
		soonBadge.Parent = card

		local soonConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
		soonConstraint.MaxTextSize = 14
		soonConstraint.Parent = soonBadge
	end

	card.Parent = scrollFrame
	cardFrames[brainrotId] = card
	return card
end

-- ═══════════════════════════════════════════════════
-- Construire toutes les cartes
-- ═══════════════════════════════════════════════════
local function buildCards(): ()
	-- Nettoyer
	table.clear(spinningViewports)
	table.clear(cardFrames)
	table.clear(viewportLabels)
	for _, child in scrollFrame:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Compter les débloqués
	local ownedCount: number = 0
	local totalCount: number = 0

	for idx, key in DISPLAY_ORDER do
		local entry = (BrainrotCatalog :: any)[key]
		if entry and type(entry) == "table" and entry.Name then
			totalCount += 1
			if ownedUnits[key] then
				ownedCount += 1
			end
			createCard(key, entry, idx)
		end
	end

	subtitleLabel.Text = `{ownedCount}/{totalCount} débloqués`
end

-- ═══════════════════════════════════════════════════
-- Show / Hide
-- ═══════════════════════════════════════════════════
local function showMenu(): ()
	if isOpen then return end
	isOpen = true

	-- Demander l'inventaire au serveur
	gachaInfoEvent:FireServer()

	buildCards()
	overlay.Visible = true

	-- Animation d'entrée
	panel.Position = UDim2.fromScale(0.075, 1)
	TweenService:Create(panel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.075, 0.06),
	}):Play()
end

hideMenu = function(): ()
	if not isOpen then return end
	isOpen = false

	local tween = TweenService:Create(panel, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
		Position = UDim2.fromScale(0.075, 1),
	})
	tween:Play()
	tween.Completed:Connect(function()
		overlay.Visible = false
		table.clear(spinningViewports)
	end)
end

-- ═══════════════════════════════════════════════════
-- Connexions
-- ═══════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════
-- Réception des infos inventaire (via GachaInfo)
-- ═══════════════════════════════════════════════════
gachaInfoEvent.OnClientEvent:Connect(function(data: any)
	if data.OwnedUnits then
		ownedUnits = {}
		for _, unitId in data.OwnedUnits do
			ownedUnits[unitId] = true
		end
		-- Rebuilder les cartes si la vitrine est ouverte
		if isOpen then
			buildCards()
		end
	end
end)

-- ═══════════════════════════════════════════════════
-- Portail "Showcase"
-- ═══════════════════════════════════════════════════
portalEnteredEvent.OnClientEvent:Connect(function(portalId: string)
	if portalId == "Showcase" then
		showMenu()
	end
end)

-- ═══════════════════════════════════════════════════
-- Rotation des ViewportFrame
-- ═══════════════════════════════════════════════════
RunService.RenderStepped:Connect(function(dt: number)
	for i = #spinningViewports, 1, -1 do
		local entry = spinningViewports[i]
		if entry.viewport == nil or entry.viewport.Parent == nil then
			table.remove(spinningViewports, i)
			continue
		end

		entry.angle += dt * 35
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

print("[ShowcaseHUD] ✅ Vitrine Brainrot initialisée (design moderne)")
