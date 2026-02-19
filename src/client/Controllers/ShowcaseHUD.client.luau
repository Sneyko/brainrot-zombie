--!strict

--[[
	ShowcaseHUD (LocalScript)
	Affiche la fiche info d'un brainrot UNIQUEMENT quand le joueur
	vise une vitrine avec le VISEUR (centre de l'écran).
	Raycast chaque frame → détecte le modèle → affiche la carte.
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local BrainrotCatalog = require(sharedFolder:WaitForChild("Data"):WaitForChild("BrainrotCatalog"))

local RARITY_COLORS: { [string]: Color3 } = BrainrotCatalog._RARITY_COLORS

-- Joueur / caméra
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Paramètres
local MAX_DISTANCE: number = 50 -- distance max de détection (studs)
local RAYCAST_PARAMS = RaycastParams.new()
RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Exclude

-- ════════════════════════════════════════════
-- UI : ScreenGui + carte info
-- ════════════════════════════════════════════
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShowcaseHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 5
screenGui.Parent = playerGui

-- Viseur (petit point au centre)
local crosshair = Instance.new("Frame")
crosshair.Name = "Crosshair"
crosshair.Size = UDim2.fromOffset(6, 6)
crosshair.Position = UDim2.fromScale(0.5, 0.5)
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.BackgroundColor3 = Color3.new(1, 1, 1)
crosshair.BackgroundTransparency = 0.3
crosshair.BorderSizePixel = 0
crosshair.Parent = screenGui

local crossCorner = Instance.new("UICorner")
crossCorner.CornerRadius = UDim.new(1, 0)
crossCorner.Parent = crosshair

-- Carte info (côté droit de l'écran)
local cardFrame = Instance.new("Frame")
cardFrame.Name = "BrainrotCard"
cardFrame.Size = UDim2.new(0, 320, 0, 420)
cardFrame.Position = UDim2.new(1, -340, 0.5, -210)
cardFrame.AnchorPoint = Vector2.new(0, 0)
cardFrame.BackgroundColor3 = Color3.fromRGB(15, 12, 30)
cardFrame.BackgroundTransparency = 0.1
cardFrame.BorderSizePixel = 0
cardFrame.Visible = false
cardFrame.Parent = screenGui

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 16)
cardCorner.Parent = cardFrame

local cardStroke = Instance.new("UIStroke")
cardStroke.Name = "CardStroke"
cardStroke.Color = Color3.new(1, 1, 1)
cardStroke.Thickness = 2.5
cardStroke.Transparency = 0.2
cardStroke.Parent = cardFrame

-- Padding interne
local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 16)
padding.PaddingRight = UDim.new(0, 16)
padding.PaddingTop = UDim.new(0, 14)
padding.PaddingBottom = UDim.new(0, 14)
padding.Parent = cardFrame

-- Layout vertical
local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.FillDirection = Enum.FillDirection.Vertical
layout.Padding = UDim.new(0, 6)
layout.Parent = cardFrame

-- ── Helpers pour créer les labels ──

local function makeLabel(name: string, order: number, height: number, fontSize: number?, font: Enum.Font?): TextLabel
	local lbl = Instance.new("TextLabel")
	lbl.Name = name
	lbl.LayoutOrder = order
	lbl.Size = UDim2.new(1, 0, 0, height)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.TextStrokeTransparency = 0.3
	lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextWrapped = true
	lbl.TextScaled = false
	lbl.TextSize = fontSize or 18
	lbl.Font = font or Enum.Font.GothamBold
	lbl.Text = ""
	lbl.Parent = cardFrame
	return lbl
end

local function makeSep(order: number, color: Color3?): Frame
	local sep = Instance.new("Frame")
	sep.Name = `Sep_{order}`
	sep.LayoutOrder = order
	sep.Size = UDim2.new(1, 0, 0, 1)
	sep.BackgroundColor3 = color or Color3.fromRGB(100, 100, 100)
	sep.BackgroundTransparency = 0.5
	sep.BorderSizePixel = 0
	sep.Parent = cardFrame
	return sep
end

-- Labels
local lblName   = makeLabel("Name",   1, 36, 28, Enum.Font.FredokaOne)
local lblRarity = makeLabel("Rarity", 2, 22, 18, Enum.Font.GothamBold)
local sep1      = makeSep(3)
local lblDesc   = makeLabel("Desc",   4, 40, 15, Enum.Font.Gotham)
local lblStats  = makeLabel("Stats",  5, 28, 16, Enum.Font.GothamBold)
local sep2      = makeSep(6)
local lblPrice  = makeLabel("Price",  7, 30, 22, Enum.Font.FredokaOne)
local lblLoot   = makeLabel("Loot",   8, 24, 17, Enum.Font.GothamBold)
local sep3      = makeSep(9)
local lblBadge  = makeLabel("Badge", 10, 28, 20, Enum.Font.FredokaOne)

-- Indice "Viser une vitrine"
local hintLabel = Instance.new("TextLabel")
hintLabel.Name = "Hint"
hintLabel.Size = UDim2.new(0, 300, 0, 30)
hintLabel.Position = UDim2.new(0.5, 0, 0.85, 0)
hintLabel.AnchorPoint = Vector2.new(0.5, 0)
hintLabel.BackgroundTransparency = 1
hintLabel.Text = ""
hintLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
hintLabel.TextStrokeTransparency = 0.3
hintLabel.TextScaled = true
hintLabel.Font = Enum.Font.GothamBold
hintLabel.Visible = false
hintLabel.Parent = screenGui

-- ════════════════════════════════════════════
-- Logique : raycast au centre de l'écran
-- ════════════════════════════════════════════

-- Showcase folder
local showcaseFolder: Folder? = nil
local function getShowcase(): Folder?
	if showcaseFolder then return showcaseFolder end
	local hub = Workspace:FindFirstChild("SpawnHub")
	if hub then
		showcaseFolder = hub:FindFirstChild("BrainrotShowcase") :: Folder?
	end
	return showcaseFolder
end

-- Trouver le BrainrotId en remontant l'arborescence
local function findBrainrotId(part: BasePart): string?
	-- 1. La Part elle-même a un BrainrotId ?
	local tag = part:FindFirstChild("BrainrotId")
	if tag and tag:IsA("StringValue") then
		return tag.Value
	end

	-- 2. Remonter les parents (le raycast peut toucher un descendant d'un Model cloné)
	local current: Instance? = part.Parent
	while current and current ~= Workspace do
		local parentTag = current:FindFirstChild("BrainrotId")
		if parentTag and parentTag:IsA("StringValue") then
			return parentTag.Value
		end
		current = current.Parent
	end

	-- 3. Le nom de la Part contient le nom d'un brainrot ? (Glass_Front_Glorbo, Pedestal_Glorbo...)
	local showcase = getShowcase()
	if not showcase then return nil end

	local partName: string = part.Name
	for _, child in showcase:GetChildren() do
		local childTag = child:FindFirstChild("BrainrotId")
		if childTag and childTag:IsA("StringValue") then
			local unitData = (BrainrotCatalog[childTag.Value] :: any)
			if unitData then
				local name = unitData.Name
				if string.find(partName, name, 1, true) then
					return childTag.Value
				end
			end
		end
	end

	-- 4. Dernier recours : trouver l'ancre/modèle le plus proche (max 15 studs)
	local bestDist = 15
	local bestId: string? = nil
	for _, child in showcase:GetChildren() do
		local childTag = child:FindFirstChild("BrainrotId")
		if childTag and childTag:IsA("StringValue") then
			local childPos: Vector3
			if child:IsA("BasePart") then
				childPos = (child :: BasePart).Position
			elseif child:IsA("Model") then
				local _, _ = (child :: Model):GetBoundingBox()
				childPos = (child :: Model):GetPivot().Position
			else
				continue
			end
			local dist = (childPos - part.Position).Magnitude
			if dist < bestDist then
				bestDist = dist
				bestId = childTag.Value
			end
		end
	end
	return bestId
end

-- État précédent
local currentId: string? = nil

local function updateCard(brainrotId: string?): ()
	if brainrotId == currentId then return end
	currentId = brainrotId

	if brainrotId == nil or brainrotId == "" then
		cardFrame.Visible = false
		hintLabel.Visible = false
		crosshair.BackgroundColor3 = Color3.new(1, 1, 1)
		crosshair.BackgroundTransparency = 0.3
		return
	end

	local entry = BrainrotCatalog[brainrotId]
	if not entry then
		cardFrame.Visible = false
		return
	end

	local rarityColor: Color3 = RARITY_COLORS[entry.Rarity] or Color3.fromRGB(200, 200, 200)

	-- Mise à jour des labels
	lblName.Text = entry.Name
	lblName.TextColor3 = Color3.new(1, 1, 1)

	lblRarity.Text = `⭐ {entry.Rarity}`
	lblRarity.TextColor3 = rarityColor

	sep1.BackgroundColor3 = rarityColor
	sep2.BackgroundColor3 = rarityColor
	sep3.BackgroundColor3 = rarityColor

	lblDesc.Text = entry.Description
	lblDesc.TextColor3 = Color3.fromRGB(180, 180, 200)

	lblStats.Text = entry.Stats
	lblStats.TextColor3 = Color3.fromRGB(150, 220, 255)

	-- Prix
	if entry.RobuxPrice ~= nil then
		lblPrice.Text = `💎 {entry.RobuxPrice} Robux`
		lblPrice.TextColor3 = Color3.fromRGB(100, 255, 100)
	else
		lblPrice.Text = "🎁 Gratuit / Coffre uniquement"
		lblPrice.TextColor3 = Color3.fromRGB(255, 200, 100)
	end

	-- Loot
	if entry.LootChance ~= nil then
		if entry.LootChance >= 1 then
			lblLoot.Text = `🎰 {entry.LootChance}% drop coffre`
		else
			lblLoot.Text = `🎰 {entry.LootChance}% drop (ultra rare!)`
		end
		lblLoot.TextColor3 = Color3.fromRGB(255, 220, 100)
	else
		lblLoot.Text = "🚫 Pas dans les coffres"
		lblLoot.TextColor3 = Color3.fromRGB(150, 150, 150)
	end

	-- Badge
	if not entry.Available then
		lblBadge.Text = "🔒 BIENTÔT DISPONIBLE"
		lblBadge.TextColor3 = Color3.fromRGB(255, 80, 80)
		lblBadge.Visible = true
	else
		lblBadge.Text = ""
		lblBadge.Visible = false
	end

	-- Bordure de la carte
	cardStroke.Color = rarityColor

	-- Crosshair
	crosshair.BackgroundColor3 = rarityColor
	crosshair.BackgroundTransparency = 0

	cardFrame.Visible = true
end

-- ════════════════════════════════════════════
-- Boucle principale
-- ════════════════════════════════════════════

-- Exclure le personnage du joueur du raycast
local function updateFilter(): ()
	local char = player.Character
	if char then
		RAYCAST_PARAMS.FilterDescendantsInstances = { char }
	end
end

player.CharacterAdded:Connect(updateFilter)
if player.Character then updateFilter() end

-- Vérifier si on est près de la vitrine
local isNearShowcase: boolean = false

RunService.RenderStepped:Connect(function()
	-- Vérifier proximité avec le showcase (optimisation)
	local showcase = getShowcase()
	if not showcase then
		updateCard(nil)
		return
	end

	local cam = camera :: Camera
	if not cam then
		updateCard(nil)
		return
	end

	-- Raycast depuis le centre de l'écran
	local viewportSize = cam.ViewportSize
	local centerRay = cam:ViewportPointToRay(viewportSize.X / 2, viewportSize.Y / 2)
	local direction = centerRay.Direction * MAX_DISTANCE

	local result = Workspace:Raycast(centerRay.Origin, direction, RAYCAST_PARAMS)

	if result and result.Instance then
		-- Vérifier que la part est dans le showcase
		local hitPart = result.Instance
		local inShowcase = false
		local current: Instance? = hitPart
		while current do
			if current == showcase then
				inShowcase = true
				break
			end
			current = current.Parent
		end

		if inShowcase then
			local brainrotId = findBrainrotId(hitPart :: BasePart)
			updateCard(brainrotId)
		else
			updateCard(nil)
		end
	else
		updateCard(nil)
	end
end)

print("[ShowcaseHUD] ✅ HUD vitrine initialisé (raycast viseur)")
