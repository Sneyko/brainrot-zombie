--!strict

--[[
	ShowcaseBuilder (ServerScript)
	Construit le bâtiment "Vitrine Brainrot" dans le Spawn Hub.
	  • Bâtiment avec murs, toit, enseigne lumineuse
	  • Vitrines en verre pour chaque brainrot du catalogue
	  • Affiche : nom, rareté, prix Robux, % loot coffre, stats
	  • Lit BrainrotCatalog → toute modif du fichier = mise à jour
]]

-- Services
local Workspace: Workspace = game:GetService("Workspace")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local sharedFolder: Instance = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(sharedFolder:WaitForChild("Constants"))
local BrainrotCatalog = require(sharedFolder:WaitForChild("Data"):WaitForChild("BrainrotCatalog"))

-- Dossier Assets (modèles 3D des brainrot)
local assetsFolder: Folder = ReplicatedStorage:WaitForChild("Assets") :: Folder

-------------------------------------------------
-- Constantes
-------------------------------------------------
local CENTER: Vector3 = Constants.SPAWN_CENTER
local GROUND_Y: number = Constants.SPAWN_GROUND_Y
local RADIUS: number = Constants.SPAWN_RADIUS

-- Position du bâtiment (entre les portails Shop et Gacha, angle ~315°)
local BUILDING_ANGLE: number = 315
local BUILDING_DIST: number = 65
local BUILDING_RAD: number = math.rad(BUILDING_ANGLE)
local BUILDING_CENTER: Vector3 = CENTER + Vector3.new(
	math.cos(BUILDING_RAD) * BUILDING_DIST,
	0,
	math.sin(BUILDING_RAD) * BUILDING_DIST
)

-- Dimensions du bâtiment
local BUILDING_WIDTH: number = 100   -- X local (façade) — assez large pour 10 vitrines
local BUILDING_DEPTH: number = 22    -- Z local (profondeur)
local BUILDING_HEIGHT: number = 18   -- Y (hauteur murs)
local WALL_THICKNESS: number = 1

-- Vitrine
local CASE_WIDTH: number = 8
local CASE_HEIGHT: number = 10
local CASE_DEPTH: number = 3.5
local CASE_SPACING: number = 2
local PEDESTAL_HEIGHT: number = 2
local MODEL_SIZE: number = 4

-- Couleurs
local WALL_COLOR: Color3 = Color3.fromRGB(45, 40, 60)
local FLOOR_COLOR: Color3 = Color3.fromRGB(60, 55, 75)
local ROOF_COLOR: Color3 = Color3.fromRGB(35, 30, 50)
local GLASS_COLOR: Color3 = Color3.fromRGB(180, 220, 255)

-- Rareté
local RARITY_COLORS: { [string]: Color3 } = BrainrotCatalog._RARITY_COLORS
local DISPLAY_ORDER: { string } = BrainrotCatalog._DISPLAY_ORDER

-- Orientation : le bâtiment fait face vers le centre du spawn
local FACING_CF: CFrame = CFrame.lookAt(BUILDING_CENTER, Vector3.new(CENTER.X, BUILDING_CENTER.Y, CENTER.Z))

-------------------------------------------------
-- Dossier
-------------------------------------------------
local spawnHub: Folder = Workspace:WaitForChild("SpawnHub", 30) :: Folder
if spawnHub == nil then
	spawnHub = Instance.new("Folder")
	spawnHub.Name = "SpawnHub"
	spawnHub.Parent = Workspace
end

local showcaseFolder: Folder = Instance.new("Folder")
showcaseFolder.Name = "BrainrotShowcase"
showcaseFolder.Parent = spawnHub

-------------------------------------------------
-- Utilitaire : créer une Part ancrée
-------------------------------------------------
local function makePart(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, transparency: number?): Part
	local p: Part = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = true
	p.Material = material
	p.Color = color
	p.Transparency = transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = showcaseFolder
	return p
end

-------------------------------------------------
-- 1. Structure du bâtiment
-------------------------------------------------
local function buildStructure(): ()
	local baseY: number = GROUND_Y
	local halfW: number = BUILDING_WIDTH / 2
	local halfD: number = BUILDING_DEPTH / 2
	local halfH: number = BUILDING_HEIGHT / 2

	-- Sol
	makePart("Floor", Vector3.new(BUILDING_WIDTH + 4, 0.5, BUILDING_DEPTH + 4),
		FACING_CF * CFrame.new(0, baseY + 0.25, 0),
		FLOOR_COLOR, Enum.Material.Marble)

	-- Mur arrière (fond)
	makePart("BackWall", Vector3.new(BUILDING_WIDTH, BUILDING_HEIGHT, WALL_THICKNESS),
		FACING_CF * CFrame.new(0, baseY + halfH, halfD),
		WALL_COLOR, Enum.Material.SmoothPlastic)

	-- Mur gauche
	makePart("LeftWall", Vector3.new(WALL_THICKNESS, BUILDING_HEIGHT, BUILDING_DEPTH),
		FACING_CF * CFrame.new(-halfW, baseY + halfH, 0),
		WALL_COLOR, Enum.Material.SmoothPlastic)

	-- Mur droit
	makePart("RightWall", Vector3.new(WALL_THICKNESS, BUILDING_HEIGHT, BUILDING_DEPTH),
		FACING_CF * CFrame.new(halfW, baseY + halfH, 0),
		WALL_COLOR, Enum.Material.SmoothPlastic)

	-- Toit
	makePart("Roof", Vector3.new(BUILDING_WIDTH + 6, 1, BUILDING_DEPTH + 6),
		FACING_CF * CFrame.new(0, baseY + BUILDING_HEIGHT + 0.5, 0),
		ROOF_COLOR, Enum.Material.SmoothPlastic)

	-- Bandeau Neon sous le toit (façade)
	local neonBand: Part = makePart("RoofNeon", Vector3.new(BUILDING_WIDTH + 6, 0.6, 1),
		FACING_CF * CFrame.new(0, baseY + BUILDING_HEIGHT + 0.3, -halfD - 3),
		Color3.fromRGB(0, 200, 255), Enum.Material.Neon, 0.2)

	local neonLight: PointLight = Instance.new("PointLight")
	neonLight.Color = Color3.fromRGB(0, 200, 255)
	neonLight.Brightness = 3
	neonLight.Range = 25
	neonLight.Parent = neonBand

	-- Colonne décorative gauche (façade)
	makePart("ColumnLeft", Vector3.new(2, BUILDING_HEIGHT + 2, 2),
		FACING_CF * CFrame.new(-halfW - 1, baseY + halfH, -halfD - 1),
		Color3.fromRGB(60, 55, 80), Enum.Material.SmoothPlastic)

	-- Colonne décorative droite (façade)
	makePart("ColumnRight", Vector3.new(2, BUILDING_HEIGHT + 2, 2),
		FACING_CF * CFrame.new(halfW + 1, baseY + halfH, -halfD - 1),
		Color3.fromRGB(60, 55, 80), Enum.Material.SmoothPlastic)

	-- Éclairage intérieur (spots au plafond)
	for i = 1, 4 do
		local spotX: number = -halfW + (BUILDING_WIDTH / 5) * i
		local spotPart: Part = makePart(`CeilingLight_{i}`,
			Vector3.new(1, 0.3, 1),
			FACING_CF * CFrame.new(spotX, baseY + BUILDING_HEIGHT - 0.5, 0),
			Color3.fromRGB(255, 240, 200), Enum.Material.Neon, 0.1)

		local spotLight: SpotLight = Instance.new("SpotLight")
		spotLight.Face = Enum.NormalId.Bottom
		spotLight.Angle = 60
		spotLight.Brightness = 3
		spotLight.Range = 20
		spotLight.Color = Color3.fromRGB(255, 240, 200)
		spotLight.Parent = spotPart
	end

	print("[ShowcaseBuilder] ✅ Structure du bâtiment construite")
end

-------------------------------------------------
-- 2. Enseigne lumineuse
-------------------------------------------------
local function buildSign(): ()
	local signY: number = GROUND_Y + BUILDING_HEIGHT + 2
	local halfD: number = BUILDING_DEPTH / 2

	-- Panneau principal
	local sign: Part = makePart("SignBoard", Vector3.new(30, 6, 1),
		FACING_CF * CFrame.new(0, signY + 3, -halfD - 3.5),
		Color3.fromRGB(30, 25, 45), Enum.Material.SmoothPlastic)

	-- Bordure Neon
	local signNeon: Part = makePart("SignNeon", Vector3.new(31, 6.5, 0.5),
		FACING_CF * CFrame.new(0, signY + 3, -halfD - 4.1),
		Color3.fromRGB(255, 180, 40), Enum.Material.Neon, 0.3)

	local signLight: PointLight = Instance.new("PointLight")
	signLight.Color = Color3.fromRGB(255, 180, 40)
	signLight.Brightness = 4
	signLight.Range = 35
	signLight.Parent = signNeon

	-- Ancre invisible devant le panneau (en espace local du bâtiment)
	local signAnchor: Part = Instance.new("Part")
	signAnchor.Name = "SignAnchor"
	signAnchor.Size = Vector3.new(0.1, 0.1, 0.1)
	signAnchor.CFrame = FACING_CF * CFrame.new(0, signY + 3, -halfD - 6)
	signAnchor.Anchored = true
	signAnchor.CanCollide = false
	signAnchor.Transparency = 1
	signAnchor.Parent = showcaseFolder

	-- Texte de l'enseigne
	local billboard: BillboardGui = Instance.new("BillboardGui")
	billboard.Name = "SignLabel"
	billboard.Size = UDim2.fromOffset(500, 120)
	billboard.StudsOffset = Vector3.new(0, 0, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 120
	billboard.Parent = signAnchor

	local title: TextLabel = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.fromScale(1, 0.6)
	title.Position = UDim2.fromScale(0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🧠 BRAINROT COLLECTION"
	title.TextColor3 = Color3.fromRGB(255, 200, 50)
	title.TextStrokeTransparency = 0
	title.TextStrokeColor3 = Color3.new(0, 0, 0)
	title.TextScaled = true
	title.Font = Enum.Font.FredokaOne
	title.Parent = billboard

	local subtitle: TextLabel = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.fromScale(1, 0.35)
	subtitle.Position = UDim2.fromScale(0, 0.6)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Tous les brainrots • Prix & Chances de loot"
	subtitle.TextColor3 = Color3.fromRGB(200, 200, 220)
	subtitle.TextStrokeTransparency = 0.3
	subtitle.TextScaled = true
	subtitle.Font = Enum.Font.GothamBold
	subtitle.Parent = billboard

	print("[ShowcaseBuilder] ✅ Enseigne construite")
end

-------------------------------------------------
-- 3. Vitrine individuelle pour un brainrot
-------------------------------------------------
local function buildDisplayCase(entry: any, catalogKey: string, index: number, totalVisible: number): ()
	local halfW: number = BUILDING_WIDTH / 2
	local halfD: number = BUILDING_DEPTH / 2
	local totalWidth: number = totalVisible * (CASE_WIDTH + CASE_SPACING) - CASE_SPACING

	-- Position X de cette vitrine (centrée dans le bâtiment)
	local startX: number = -totalWidth / 2 + CASE_WIDTH / 2
	local caseX: number = startX + (index - 1) * (CASE_WIDTH + CASE_SPACING)
	local caseZ: number = halfD - CASE_DEPTH / 2 - 2 -- Contre le mur du fond

	local baseY: number = GROUND_Y
	local rarityColor: Color3 = RARITY_COLORS[entry.Rarity] or Color3.fromRGB(200, 200, 200)

	-- Piédestal
	local pedestal: Part = makePart(`Pedestal_{entry.Name}`,
		Vector3.new(CASE_WIDTH - 1, PEDESTAL_HEIGHT, CASE_DEPTH - 0.5),
		FACING_CF * CFrame.new(caseX, baseY + PEDESTAL_HEIGHT / 2 + 0.5, caseZ),
		Color3.fromRGB(50, 45, 65), Enum.Material.Marble)

	-- Bande Neon de rareté sur le piédestal
	local pedNeon: Part = makePart(`PedNeon_{entry.Name}`,
		Vector3.new(CASE_WIDTH - 0.5, 0.3, CASE_DEPTH),
		FACING_CF * CFrame.new(caseX, baseY + PEDESTAL_HEIGHT + 0.65, caseZ),
		rarityColor, Enum.Material.Neon, 0.3)

	-- Vitre en verre (5 faces : avant, gauche, droite, dessus, + fond transparent)
	-- Avant (face joueur)
	makePart(`Glass_Front_{entry.Name}`,
		Vector3.new(CASE_WIDTH, CASE_HEIGHT, 0.3),
		FACING_CF * CFrame.new(caseX, baseY + PEDESTAL_HEIGHT + CASE_HEIGHT / 2 + 0.5, caseZ - CASE_DEPTH / 2),
		GLASS_COLOR, Enum.Material.Glass, 0.7)

	-- Gauche
	makePart(`Glass_Left_{entry.Name}`,
		Vector3.new(0.3, CASE_HEIGHT, CASE_DEPTH),
		FACING_CF * CFrame.new(caseX - CASE_WIDTH / 2, baseY + PEDESTAL_HEIGHT + CASE_HEIGHT / 2 + 0.5, caseZ),
		GLASS_COLOR, Enum.Material.Glass, 0.75)

	-- Droite
	makePart(`Glass_Right_{entry.Name}`,
		Vector3.new(0.3, CASE_HEIGHT, CASE_DEPTH),
		FACING_CF * CFrame.new(caseX + CASE_WIDTH / 2, baseY + PEDESTAL_HEIGHT + CASE_HEIGHT / 2 + 0.5, caseZ),
		GLASS_COLOR, Enum.Material.Glass, 0.75)

	-- Dessus
	makePart(`Glass_Top_{entry.Name}`,
		Vector3.new(CASE_WIDTH, 0.3, CASE_DEPTH),
		FACING_CF * CFrame.new(caseX, baseY + PEDESTAL_HEIGHT + CASE_HEIGHT + 0.5, caseZ),
		GLASS_COLOR, Enum.Material.Glass, 0.7)

	-- ════════ Modèle 3D du brainrot ════════
	-- Position cible du modèle dans la vitrine
	local modelY: number = baseY + PEDESTAL_HEIGHT + 1 + MODEL_SIZE / 2 + 1
	local modelCF: CFrame = FACING_CF * CFrame.new(caseX, modelY, caseZ)

	-- Ancre invisible (sert de parent pour le tag, la lumière, le nom)
	local anchor: Part = Instance.new("Part")
	anchor.Name = `Anchor_{entry.Name}`
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.CFrame = modelCF
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Parent = showcaseFolder

	-- Tag StringValue pour que le client retrouve l'ID catalogue
	local idTag: StringValue = Instance.new("StringValue")
	idTag.Name = "BrainrotId"
	idTag.Value = catalogKey
	idTag.Parent = anchor

	-- Tenter de cloner le vrai modèle depuis Assets
	local templateName: string = `Unit_{catalogKey}`
	local template: Instance? = assetsFolder:FindFirstChild(templateName)
	local usedRealModel: boolean = false

	if template and template:IsA("Model") then
		local visual: Model = template:Clone() :: Model
		visual.Name = `Model_{entry.Name}`

		-- Uniformiser la taille pour rentrer dans la vitrine
		local SHOWCASE_HEIGHT: number = CASE_HEIGHT - 3 -- laisser de la marge
		local ok, _ = pcall(function()
			local _, origSize: Vector3 = visual:GetBoundingBox()
			if origSize.Y > 0 then
				local currentScale: number = visual:GetScale()
				local scaleFactor: number = (SHOWCASE_HEIGHT / origSize.Y) * currentScale
				visual:ScaleTo(scaleFactor)
			end
		end)

		-- Positionner : centré sur le piédestal, face au joueur
		local _, scaledSize: Vector3 = visual:GetBoundingBox()
		local visualY: number = baseY + PEDESTAL_HEIGHT + 0.5 + scaledSize.Y / 2
		local visualCF: CFrame = FACING_CF * CFrame.new(caseX, visualY, caseZ)
		visual:PivotTo(visualCF)

		-- Ancrer toutes les parts, désactiver collision
		for _, desc: Instance in visual:GetDescendants() do
			if desc:IsA("BasePart") then
				local bp: BasePart = desc :: BasePart
				bp.Anchored = true
				bp.CanCollide = false
			end
		end

		-- Grisé si pas encore disponible
		if not entry.Available then
			for _, desc: Instance in visual:GetDescendants() do
				if desc:IsA("BasePart") then
					local bp: BasePart = desc :: BasePart
					bp.Color = Color3.fromRGB(100, 100, 100)
					bp.Transparency = math.max(bp.Transparency, 0.4)
				end
			end
		end

		visual.Parent = showcaseFolder
		usedRealModel = true

		-- Dupliquer le tag dans le PrimaryPart aussi (pour le raycast client)
		if visual.PrimaryPart then
			local idTag2: StringValue = Instance.new("StringValue")
			idTag2.Name = "BrainrotId"
			idTag2.Value = catalogKey
			idTag2.Parent = visual.PrimaryPart
		end
	else
		-- Fallback : sphère colorée si pas d'asset
		local ball: Part = Instance.new("Part")
		ball.Name = `Model_{entry.Name}`
		ball.Shape = Enum.PartType.Ball
		ball.Size = Vector3.new(MODEL_SIZE, MODEL_SIZE, MODEL_SIZE)
		ball.CFrame = modelCF
		ball.Anchored = true
		ball.CanCollide = false
		ball.Material = Enum.Material.SmoothPlastic
		ball.Color = if entry.Available then entry.Color else Color3.fromRGB(100, 100, 100)
		ball.Transparency = if entry.Available then 0 else 0.4
		ball.Parent = showcaseFolder

		local idTag3: StringValue = Instance.new("StringValue")
		idTag3.Name = "BrainrotId"
		idTag3.Value = catalogKey
		idTag3.Parent = ball
	end

	-- Lumière sous le modèle
	local modelLight: PointLight = Instance.new("PointLight")
	modelLight.Color = rarityColor
	modelLight.Brightness = 2
	modelLight.Range = 8
	modelLight.Parent = anchor

	-- Particules subtiles pour les raretés élevées
	if entry.Rarity == "Legendary" or entry.Rarity == "Mythic" then
		local sparkle: ParticleEmitter = Instance.new("ParticleEmitter")
		sparkle.Texture = "rbxassetid://241685484"
		sparkle.Color = ColorSequence.new(rarityColor, Color3.new(1, 1, 1))
		sparkle.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 0.6),
			NumberSequenceKeypoint.new(1, 0),
		})
		sparkle.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(1, 1),
		})
		sparkle.Lifetime = NumberRange.new(0.8, 1.5)
		sparkle.Rate = if entry.Rarity == "Mythic" then 25 else 12
		sparkle.Speed = NumberRange.new(1, 3)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Parent = anchor
	end

	-- Petit nom flottant au-dessus de la vitrine (visible de loin)
	local nameTag: BillboardGui = Instance.new("BillboardGui")
	nameTag.Name = `NameTag_{entry.Name}`
	nameTag.Size = UDim2.fromOffset(180, 30)
	nameTag.StudsOffset = Vector3.new(0, CASE_HEIGHT / 2 + 3, 0)
	nameTag.AlwaysOnTop = false
	nameTag.MaxDistance = 60
	nameTag.Parent = anchor

	local nameLabel: TextLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.fromScale(1, 1)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = entry.Name
	nameLabel.TextColor3 = rarityColor
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.Parent = nameTag
end

-------------------------------------------------
-- 4. Construire toutes les vitrines
-------------------------------------------------
local function buildAllCases(): ()
	-- Filtrer les entrées visibles (garder la clé catalogue)
	local visibleEntries: { { key: string, entry: any } } = {}
	for _, unitId in DISPLAY_ORDER do
		local entry = BrainrotCatalog[unitId]
		if entry then
			table.insert(visibleEntries, { key = unitId, entry = entry })
		end
	end

	local total: number = #visibleEntries

	for i, item in visibleEntries do
		buildDisplayCase(item.entry, item.key, i, total)
	end

	print(`[ShowcaseBuilder] ✅ {total} vitrines construites`)
end

-------------------------------------------------
-- 5. Plateformes d'entrée (marches devant le bâtiment)
-------------------------------------------------
local function buildEntrance(): ()
	local halfD: number = BUILDING_DEPTH / 2

	-- 3 marches d'entrée
	for step = 1, 3 do
		local stepDepth: number = 3
		local stepHeight: number = 0.6 * step
		makePart(`Step_{step}`,
			Vector3.new(BUILDING_WIDTH * 0.6, stepHeight, stepDepth),
			FACING_CF * CFrame.new(0, GROUND_Y + stepHeight / 2, -halfD - step * stepDepth),
			Color3.fromRGB(55, 50, 70), Enum.Material.Marble)
	end

	-- Tapis rouge (bande au sol)
	makePart("RedCarpet",
		Vector3.new(6, 0.1, 12),
		FACING_CF * CFrame.new(0, GROUND_Y + 0.3, -halfD - 6),
		Color3.fromRGB(180, 30, 30), Enum.Material.Fabric, 0)

	-- Torches de chaque côté de l'entrée
	for _, side in { -1, 1 } do
		local torchX: number = BUILDING_WIDTH * 0.3 * side
		local torchPos: CFrame = FACING_CF * CFrame.new(torchX, GROUND_Y, -halfD - 2)

		-- Poteau
		local pole: Part = makePart(`TorchPole_{side}`,
			Vector3.new(0.6, 8, 0.6),
			torchPos * CFrame.new(0, 4, 0),
			Color3.fromRGB(60, 50, 40), Enum.Material.Metal)

		-- Flamme (orbe Neon)
		local flame: Part = Instance.new("Part")
		flame.Name = `TorchFlame_{side}`
		flame.Shape = Enum.PartType.Ball
		flame.Size = Vector3.new(2, 2, 2)
		flame.CFrame = torchPos * CFrame.new(0, 9, 0)
		flame.Anchored = true
		flame.CanCollide = false
		flame.Material = Enum.Material.Neon
		flame.Color = Color3.fromRGB(255, 150, 30)
		flame.Transparency = 0.15
		flame.Parent = showcaseFolder

		local fireLight: PointLight = Instance.new("PointLight")
		fireLight.Color = Color3.fromRGB(255, 150, 30)
		fireLight.Brightness = 3
		fireLight.Range = 18
		fireLight.Parent = flame

		-- Particules de feu
		local fireParticles: ParticleEmitter = Instance.new("ParticleEmitter")
		fireParticles.Texture = "rbxassetid://241685484"
		fireParticles.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 50)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 20)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 50, 10)),
		})
		fireParticles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 1.5),
			NumberSequenceKeypoint.new(1, 0),
		})
		fireParticles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		})
		fireParticles.Lifetime = NumberRange.new(0.5, 1)
		fireParticles.Rate = 40
		fireParticles.Speed = NumberRange.new(3, 6)
		fireParticles.SpreadAngle = Vector2.new(20, 20)
		fireParticles.EmissionDirection = Enum.NormalId.Top
		fireParticles.Parent = flame
	end

	print("[ShowcaseBuilder] ✅ Entrée construite")
end

-------------------------------------------------
-- CONSTRUCTION
-------------------------------------------------
print("[ShowcaseBuilder] 🏗️ Construction de la Vitrine Brainrot...")

buildStructure()
buildSign()
buildAllCases()
buildEntrance()

print("[ShowcaseBuilder] ✅ Vitrine Brainrot complète !")
