--!strict

--[[
	MapBuilder (ServerScript)
	Génère le terrain pour Brainrot Defense :
	  • Sol plat — zone de marche des zombies
	  • Mur de défense — le joueur est dessus en 3ème personne
	  • 4 plaques d'achat sur le mur (1 par brainrot, avec nom + prix)
	  • SpawnLocation sur le mur
	  • Éclairage ambiant
]]

-- Services
local Workspace: Workspace = game:GetService("Workspace")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local sharedFolder: Instance = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(sharedFolder:WaitForChild("Constants"))
local UnitDatabase = require(sharedFolder:WaitForChild("Data"):WaitForChild("UnitDatabase"))

-------------------------------------------------
-- Constantes terrain
-------------------------------------------------
local WALL_CENTER_X: number = Constants.WALL_POSITION.X
local WALL_TOP_Y: number = Constants.WALL_TOP_Y
local WALL_FRONT_Z: number = Constants.WALL_FRONT_Z

local PLATE_SIZE: number = Constants.PLATE_SIZE
local PLATE_THICKNESS: number = Constants.TILE_THICKNESS
local PLANT_UNITS: { string } = Constants.PLANT_UNITS

local GROUND_COLOR: Color3 = Color3.fromRGB(90, 130, 70)
local WALL_COLOR: Color3 = Color3.fromRGB(140, 140, 150)

-- Couleurs par rareté
local RARITY_COLORS: { [string]: Color3 } = {
	Common    = Color3.fromRGB(120, 200, 120),
	Rare      = Color3.fromRGB(80, 150, 255),
	Legendary = Color3.fromRGB(255, 180, 40),
}

-------------------------------------------------
-- Dossier de jeu
-------------------------------------------------
local gameBoard: Folder = Instance.new("Folder")
gameBoard.Name = "GameBoard"
gameBoard.Parent = Workspace

-------------------------------------------------
-- 1. Sol (zone zombie)
-------------------------------------------------
local function buildGround(): ()
	local ground: Part = Instance.new("Part")
	ground.Name = "Ground"
	ground.Size = Constants.GROUND_SIZE
	ground.Position = Constants.GROUND_POSITION
	ground.Anchored = true
	ground.CanCollide = true
	ground.Material = Enum.Material.Grass
	ground.Color = GROUND_COLOR
	ground.TopSurface = Enum.SurfaceType.Smooth
	ground.BottomSurface = Enum.SurfaceType.Smooth
	ground.Parent = gameBoard

	print("[MapBuilder] ✅ Sol construit")
end

-------------------------------------------------
-- 2. Mur de défense
-------------------------------------------------
local function buildWall(): ()
	local wall: Part = Instance.new("Part")
	wall.Name = "DefenseWall"
	wall.Size = Constants.WALL_SIZE
	wall.Position = Constants.WALL_POSITION
	wall.Anchored = true
	wall.CanCollide = true
	wall.Material = Enum.Material.Concrete
	wall.Color = WALL_COLOR
	wall.TopSurface = Enum.SurfaceType.Smooth
	wall.BottomSurface = Enum.SurfaceType.Smooth
	wall.Parent = gameBoard

	-- Bande Neon sur la corniche avant
	local ledge: Part = Instance.new("Part")
	ledge.Name = "WallLedge"
	ledge.Size = Vector3.new(Constants.WALL_SIZE.X, 0.5, 1)
	ledge.Position = Vector3.new(
		Constants.WALL_POSITION.X,
		WALL_TOP_Y + 0.25,
		WALL_FRONT_Z + 0.5
	)
	ledge.Anchored = true
	ledge.CanCollide = true
	ledge.Material = Enum.Material.Neon
	ledge.Color = Color3.fromRGB(100, 200, 255)
	ledge.Transparency = 0.3
	ledge.Parent = gameBoard

	print("[MapBuilder] ✅ Mur de défense construit")
end

-------------------------------------------------
-- 3. Plaques d'achat (4, sur le dessus du mur)
-------------------------------------------------
local function buildPlates(): ()
	local count: number = #PLANT_UNITS
	local wallWidth: number = Constants.WALL_SIZE.X
	local spacing: number = wallWidth / count
	local plateZ: number = WALL_FRONT_Z - 10    -- 10 studs en arrière du bord

	for i, unitId: string in PLANT_UNITS do
		local unitData = UnitDatabase[unitId]
		if unitData == nil then
			warn(`[MapBuilder] ⚠️ Unité inconnue : {unitId}`)
			continue
		end

		local plateX: number = WALL_CENTER_X - wallWidth / 2 + spacing * (i - 0.5)
		local plateY: number = WALL_TOP_Y + PLATE_THICKNESS / 2

		-- Plaque rectangulaire
		local plate: Part = Instance.new("Part")
		plate.Name = `Plate_{unitId}`
		plate.Size = Vector3.new(PLATE_SIZE, PLATE_THICKNESS, PLATE_SIZE)
		plate.Position = Vector3.new(plateX, plateY, plateZ)
		plate.Anchored = true
		plate.CanCollide = true
		plate.Material = Enum.Material.SmoothPlastic
		plate.Color = unitData.Color
		plate.Transparency = 0.1
		plate.TopSurface = Enum.SurfaceType.Smooth
		plate.BottomSurface = Enum.SurfaceType.Smooth

		-- Bordure Neon colorée
		local rarityColor: Color3 = RARITY_COLORS[unitData.Rarity] or Color3.fromRGB(200, 200, 200)

		local borderThickness: number = 0.3
		local borders: { { size: Vector3, pos: Vector3 } } = {
			{ size = Vector3.new(PLATE_SIZE + 0.4, 0.2, borderThickness), pos = Vector3.new(0, 0, PLATE_SIZE / 2) },
			{ size = Vector3.new(PLATE_SIZE + 0.4, 0.2, borderThickness), pos = Vector3.new(0, 0, -PLATE_SIZE / 2) },
			{ size = Vector3.new(borderThickness, 0.2, PLATE_SIZE + 0.4), pos = Vector3.new(PLATE_SIZE / 2, 0, 0) },
			{ size = Vector3.new(borderThickness, 0.2, PLATE_SIZE + 0.4), pos = Vector3.new(-PLATE_SIZE / 2, 0, 0) },
		}

		for j, bData in borders do
			local border: Part = Instance.new("Part")
			border.Name = `PlateBorder_{j}`
			border.Size = bData.size
			border.Position = plate.Position + bData.pos
			border.Anchored = true
			border.CanCollide = false
			border.Material = Enum.Material.Neon
			border.Color = rarityColor
			border.Transparency = 0.2
			border.Parent = gameBoard
		end

		-- PointLight
		local glow: PointLight = Instance.new("PointLight")
		glow.Color = unitData.Color
		glow.Brightness = 1
		glow.Range = 8
		glow.Parent = plate

		-- BillboardGui (nom + prix + stats)
		local billboard: BillboardGui = Instance.new("BillboardGui")
		billboard.Name = "PlateLabel"
		billboard.Size = UDim2.fromOffset(220, 160)
		billboard.StudsOffset = Vector3.new(0, 5, 0)
		billboard.AlwaysOnTop = false
		billboard.MaxDistance = 60
		billboard.Parent = plate

		local nameLabel: TextLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.fromScale(1, 0.22)
		nameLabel.Position = UDim2.fromScale(0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = unitData.Name
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.TextStrokeTransparency = 0
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.FredokaOne
		nameLabel.Parent = billboard

		local costLabel: TextLabel = Instance.new("TextLabel")
		costLabel.Name = "CostLabel"
		costLabel.Size = UDim2.fromScale(1, 0.18)
		costLabel.Position = UDim2.fromScale(0, 0.22)
		costLabel.BackgroundTransparency = 1
		costLabel.Text = `🧠 {unitData.Cost}`
		costLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
		costLabel.TextStrokeTransparency = 0
		costLabel.TextScaled = true
		costLabel.Font = Enum.Font.GothamBold
		costLabel.Parent = billboard

		-- Stats détaillées
		local statsText: string = `❤️ {unitData.HP}  ⚔️ {unitData.Damage}\n🔫 {unitData.FireRate or 0}/s  📏 {unitData.Range or 0}`

		local statsLabel: TextLabel = Instance.new("TextLabel")
		statsLabel.Name = "StatsLabel"
		statsLabel.Size = UDim2.fromScale(1, 0.55)
		statsLabel.Position = UDim2.fromScale(0, 0.42)
		statsLabel.BackgroundTransparency = 1
		statsLabel.Text = statsText
		statsLabel.TextColor3 = Color3.fromRGB(200, 210, 220)
		statsLabel.TextStrokeTransparency = 0.3
		statsLabel.TextScaled = true
		statsLabel.Font = Enum.Font.GothamBold
		statsLabel.TextWrapped = true
		statsLabel.Parent = billboard

		plate.Parent = gameBoard
	end

	print(`[MapBuilder] ✅ {count} plaques d'achat créées`)
end

-------------------------------------------------
-- 4. SpawnLocation (joueur sur le mur)
-------------------------------------------------
local function buildSpawnLocation(): ()
	local spawn: SpawnLocation = Instance.new("SpawnLocation")
	spawn.Name = "WallSpawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(WALL_CENTER_X, WALL_TOP_Y + 0.5, WALL_FRONT_Z - 3)
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.CanQuery = false
	spawn.Transparency = 1
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Enabled = true
	spawn.Neutral = true
	spawn.Parent = gameBoard

	print("[MapBuilder] ✅ SpawnLocation sur le mur")
end

-------------------------------------------------
-- 5. Éclairage ambiant
-------------------------------------------------
local function setupLighting(): ()
	local lighting = game:GetService("Lighting")
	lighting.ClockTime = 14
	lighting.Brightness = 1.5
	lighting.Ambient = Color3.fromRGB(60, 60, 80)
	lighting.OutdoorAmbient = Color3.fromRGB(120, 130, 140)
	lighting.FogEnd = 800
	lighting.GlobalShadows = true

	local existingAtmo: Instance? = lighting:FindFirstChildOfClass("Atmosphere")
	if existingAtmo then existingAtmo:Destroy() end

	local atmosphere: Atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.1
	atmosphere.Color = Color3.fromRGB(180, 190, 220)
	atmosphere.Decay = Color3.fromRGB(120, 130, 160)
	atmosphere.Glare = 0.2
	atmosphere.Haze = 1
	atmosphere.Parent = lighting

	print("[MapBuilder] ✅ Éclairage configuré")
end

-------------------------------------------------
-- Construction
-------------------------------------------------
buildGround()
buildWall()
buildPlates()
buildSpawnLocation()
setupLighting()

print("[MapBuilder] 🏗️ Carte construite — Sol + Mur + 4 plaques d'achat")
