--!strict

--[[
	SpawnBuilder (ServerScript)
	Génère le monde du Spawn / Lobby pour Brainrot Defense :
	  • Grande île circulaire d'herbe avec bordure
	  • Fontaine centrale illuminée avec jet d'eau
	  • 4 portails (Jouer, Shop, Sell, Gacha) disposés en cercle
	  • Arbres décoratifs, lampadaires, nuages
	  • Chemins pavés entre la fontaine et les portails
	  • SpawnLocation au centre
	  • Skybox / éclairage nocturne stylisé
]]

-- Services
local Workspace: Workspace = game:GetService("Workspace")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

-- Modules
local sharedFolder: Instance = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(sharedFolder:WaitForChild("Constants"))

-------------------------------------------------
-- Constantes locales
-------------------------------------------------
local CENTER: Vector3 = Constants.SPAWN_CENTER
local RADIUS: number = Constants.SPAWN_RADIUS
local GROUND_Y: number = Constants.SPAWN_GROUND_Y

-------------------------------------------------
-- Dossier conteneur
-------------------------------------------------
local spawnFolder: Folder = Instance.new("Folder")
spawnFolder.Name = "SpawnHub"
spawnFolder.Parent = Workspace

-------------------------------------------------
-- Utilitaires
-------------------------------------------------
local function createPart(props: { [string]: any }): Part
	local part: Part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = props.CanCollide ~= false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	
	for key, value in props do
		if key ~= "CanCollide" then
			(part :: any)[key] = value
		end
	end
	
	part.Parent = props.Parent or spawnFolder
	return part
end

local function radians(degrees: number): number
	return math.rad(degrees)
end

local function posFromAngle(angle: number, dist: number, y: number): Vector3
	local rad = radians(angle)
	return CENTER + Vector3.new(math.cos(rad) * dist, y, math.sin(rad) * dist)
end

-------------------------------------------------
-- 1. Île principale (Cylindre d'herbe)
-------------------------------------------------
local function buildIsland(): ()
	-- Sol principal circulaire (on simule avec un gros cylindre aplati)
	local island: Part = Instance.new("Part")
	island.Name = "SpawnIsland"
	island.Shape = Enum.PartType.Cylinder
	island.Size = Vector3.new(4, RADIUS * 2, RADIUS * 2) -- Cylinder: X=height, Y=diameter, Z=diameter
	island.CFrame = CFrame.new(CENTER) * CFrame.Angles(0, 0, math.rad(90))
	island.Anchored = true
	island.CanCollide = true
	island.Material = Enum.Material.Grass
	island.Color = Color3.fromRGB(80, 170, 60)
	island.TopSurface = Enum.SurfaceType.Smooth
	island.BottomSurface = Enum.SurfaceType.Smooth
	island.Parent = spawnFolder

	-- Bordure lumineuse (anneau Neon autour de l'île)
	local borderRing: Part = Instance.new("Part")
	borderRing.Name = "IslandBorder"
	borderRing.Shape = Enum.PartType.Cylinder
	borderRing.Size = Vector3.new(1, RADIUS * 2 + 6, RADIUS * 2 + 6)
	borderRing.CFrame = CFrame.new(CENTER + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	borderRing.Anchored = true
	borderRing.CanCollide = false
	borderRing.Material = Enum.Material.Neon
	borderRing.Color = Color3.fromRGB(0, 200, 255)
	borderRing.Transparency = 0.4
	borderRing.Parent = spawnFolder

	-- Eau autour de l'île
	local water: Part = Instance.new("Part")
	water.Name = "SurroundingWater"
	water.Shape = Enum.PartType.Cylinder
	water.Size = Vector3.new(2, RADIUS * 4, RADIUS * 4)
	water.CFrame = CFrame.new(CENTER + Vector3.new(0, -2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	water.Anchored = true
	water.CanCollide = false
	water.Material = Enum.Material.Glass
	water.Color = Color3.fromRGB(40, 120, 200)
	water.Transparency = 0.4
	water.Parent = spawnFolder

	print("[SpawnBuilder] ✅ Île principale construite")
end

-------------------------------------------------
-- 2. Fontaine centrale
-------------------------------------------------
local function buildFountain(): ()
	local fRadius: number = Constants.FOUNTAIN_RADIUS
	local fHeight: number = Constants.FOUNTAIN_HEIGHT

	-- Bassin circulaire
	local basin: Part = Instance.new("Part")
	basin.Name = "FountainBasin"
	basin.Shape = Enum.PartType.Cylinder
	basin.Size = Vector3.new(fHeight, fRadius * 2, fRadius * 2)
	basin.CFrame = CFrame.new(CENTER + Vector3.new(0, fHeight / 2 + GROUND_Y, 0)) * CFrame.Angles(0, 0, math.rad(90))
	basin.Anchored = true
	basin.CanCollide = true
	basin.Material = Enum.Material.Marble
	basin.Color = Color3.fromRGB(220, 220, 230)
	basin.TopSurface = Enum.SurfaceType.Smooth
	basin.BottomSurface = Enum.SurfaceType.Smooth
	basin.Parent = spawnFolder

	-- Eau du bassin
	local water: Part = Instance.new("Part")
	water.Name = "FountainWater"
	water.Shape = Enum.PartType.Cylinder
	water.Size = Vector3.new(0.5, fRadius * 2 - 2, fRadius * 2 - 2)
	water.CFrame = CFrame.new(CENTER + Vector3.new(0, fHeight + GROUND_Y + 0.25, 0)) * CFrame.Angles(0, 0, math.rad(90))
	water.Anchored = true
	water.CanCollide = false
	water.Material = Enum.Material.Glass
	water.Color = Color3.fromRGB(80, 180, 255)
	water.Transparency = 0.3
	water.Parent = spawnFolder

	-- Colonne centrale
	local pillar: Part = Instance.new("Part")
	pillar.Name = "FountainPillar"
	pillar.Shape = Enum.PartType.Cylinder
	pillar.Size = Vector3.new(12, 3, 3) -- Grand pilier
	pillar.CFrame = CFrame.new(CENTER + Vector3.new(0, fHeight + GROUND_Y + 6, 0)) * CFrame.Angles(0, 0, math.rad(90))
	pillar.Anchored = true
	pillar.CanCollide = true
	pillar.Material = Enum.Material.Marble
	pillar.Color = Color3.fromRGB(230, 230, 240)
	pillar.Parent = spawnFolder

	-- Sphère au sommet
	local orb: Part = Instance.new("Part")
	orb.Name = "FountainOrb"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(5, 5, 5)
	orb.Position = CENTER + Vector3.new(0, fHeight + GROUND_Y + 13, 0)
	orb.Anchored = true
	orb.CanCollide = false
	orb.Material = Enum.Material.Neon
	orb.Color = Color3.fromRGB(100, 220, 255)
	orb.Transparency = 0.2
	orb.Parent = spawnFolder

	-- Lumière de la sphère
	local orbLight: PointLight = Instance.new("PointLight")
	orbLight.Color = Color3.fromRGB(100, 220, 255)
	orbLight.Brightness = 3
	orbLight.Range = 40
	orbLight.Parent = orb

	-- Particules (jet d'eau simulé)
	local emitter: ParticleEmitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxassetid://241685484" -- Default particle
	emitter.Color = ColorSequence.new(Color3.fromRGB(120, 200, 255), Color3.fromRGB(200, 230, 255))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 2),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(1.5, 2.5)
	emitter.Rate = 60
	emitter.Speed = NumberRange.new(15, 25)
	emitter.SpreadAngle = Vector2.new(15, 15)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Parent = orb

	print("[SpawnBuilder] ✅ Fontaine centrale construite")
end

-------------------------------------------------
-- 3. Portails
-------------------------------------------------
local function buildPortal(portalData: { [string]: any }): ()
	local angle: number = portalData.Angle
	local dist: number = portalData.Distance
	local color: Color3 = portalData.Color
	local portalId: string = portalData.Id
	local portalName: string = portalData.Name
	local subtitle: string = portalData.Subtitle

	local pH: number = Constants.PORTAL_HEIGHT
	local pW: number = Constants.PORTAL_WIDTH
	local pT: number = Constants.PORTAL_THICKNESS
	local iH: number = Constants.PORTAL_INNER_HEIGHT
	local iW: number = Constants.PORTAL_INNER_WIDTH

	-- Position et orientation du portail (face vers le centre)
	local portalPos: Vector3 = posFromAngle(angle, dist, GROUND_Y + pH / 2)
	local lookAtCenter: CFrame = CFrame.lookAt(portalPos, Vector3.new(CENTER.X, portalPos.Y, CENTER.Z))

	-- Conteneur Model
	local portalModel: Model = Instance.new("Model")
	portalModel.Name = `Portal_{portalId}`

	-- NOTE: avec CFrame.lookAt, -Z = vers le centre, X = droite, Y = haut
	-- Les Parts ont Size(X, Y, Z) en coordonnées locales
	-- Largeur du portail = axe X local, profondeur = axe Z local

	-- Pilier gauche
	local pillarL: Part = Instance.new("Part")
	pillarL.Name = "PillarLeft"
	pillarL.Size = Vector3.new((pW - iW) / 2, pH, pT)
	pillarL.CFrame = lookAtCenter * CFrame.new(-(iW / 2 + (pW - iW) / 4), 0, 0)
	pillarL.Anchored = true
	pillarL.Material = Enum.Material.SmoothPlastic
	pillarL.Color = Color3.fromRGB(50, 50, 60)
	pillarL.Parent = portalModel

	-- Détail pilier gauche (bande Neon)
	local pillarLNeon: Part = Instance.new("Part")
	pillarLNeon.Name = "PillarLeftNeon"
	pillarLNeon.Size = Vector3.new(0.4, pH - 2, pT + 0.2)
	pillarLNeon.CFrame = lookAtCenter * CFrame.new(-iW / 2 - 0.3, 0, 0)
	pillarLNeon.Anchored = true
	pillarLNeon.CanCollide = false
	pillarLNeon.Material = Enum.Material.Neon
	pillarLNeon.Color = color
	pillarLNeon.Transparency = 0.3
	pillarLNeon.Parent = portalModel

	-- Pilier droit
	local pillarR: Part = Instance.new("Part")
	pillarR.Name = "PillarRight"
	pillarR.Size = Vector3.new((pW - iW) / 2, pH, pT)
	pillarR.CFrame = lookAtCenter * CFrame.new(iW / 2 + (pW - iW) / 4, 0, 0)
	pillarR.Anchored = true
	pillarR.Material = Enum.Material.SmoothPlastic
	pillarR.Color = Color3.fromRGB(50, 50, 60)
	pillarR.Parent = portalModel

	-- Détail pilier droit (bande Neon)
	local pillarRNeon: Part = Instance.new("Part")
	pillarRNeon.Name = "PillarRightNeon"
	pillarRNeon.Size = Vector3.new(0.4, pH - 2, pT + 0.2)
	pillarRNeon.CFrame = lookAtCenter * CFrame.new(iW / 2 + 0.3, 0, 0)
	pillarRNeon.Anchored = true
	pillarRNeon.CanCollide = false
	pillarRNeon.Material = Enum.Material.Neon
	pillarRNeon.Color = color
	pillarRNeon.Transparency = 0.3
	pillarRNeon.Parent = portalModel

	-- Linteau (haut)
	local lintel: Part = Instance.new("Part")
	lintel.Name = "Lintel"
	lintel.Size = Vector3.new(pW, (pH - iH), pT)
	lintel.CFrame = lookAtCenter * CFrame.new(0, (iH) / 2, 0)
	lintel.Anchored = true
	lintel.Material = Enum.Material.SmoothPlastic
	lintel.Color = Color3.fromRGB(50, 50, 60)
	lintel.Parent = portalModel

	-- Corniche décorative au-dessus du linteau
	local cornice: Part = Instance.new("Part")
	cornice.Name = "Cornice"
	cornice.Size = Vector3.new(pW + 2, 1.5, pT + 1)
	cornice.CFrame = lookAtCenter * CFrame.new(0, pH / 2 + 0.75, 0)
	cornice.Anchored = true
	cornice.Material = Enum.Material.SmoothPlastic
	cornice.Color = Color3.fromRGB(40, 40, 50)
	cornice.Parent = portalModel

	-- Bande Neon sur la corniche
	local corniceNeon: Part = Instance.new("Part")
	corniceNeon.Name = "CorniceNeon"
	corniceNeon.Size = Vector3.new(pW + 2.5, 0.4, pT + 1.5)
	corniceNeon.CFrame = lookAtCenter * CFrame.new(0, pH / 2 + 1.6, 0)
	corniceNeon.Anchored = true
	corniceNeon.CanCollide = false
	corniceNeon.Material = Enum.Material.Neon
	corniceNeon.Color = color
	corniceNeon.Transparency = 0.2
	corniceNeon.Parent = portalModel

	-- Effet intérieur du portail (Neon translucide + particules)
	local portalEffect: Part = Instance.new("Part")
	portalEffect.Name = "PortalEffect"
	portalEffect.Size = Vector3.new(iW, iH, 0.5)
	portalEffect.CFrame = lookAtCenter
	portalEffect.Anchored = true
	portalEffect.CanCollide = false
	portalEffect.Material = Enum.Material.Neon
	portalEffect.Color = color
	portalEffect.Transparency = 0.3
	portalEffect.Parent = portalModel

	-- Lumière sur le portail
	local portalLight: PointLight = Instance.new("PointLight")
	portalLight.Color = color
	portalLight.Brightness = 4
	portalLight.Range = 30
	portalLight.Parent = portalEffect

	-- Particules du portail
	local particles: ParticleEmitter = Instance.new("ParticleEmitter")
	particles.Texture = "rbxassetid://241685484"
	particles.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, 1.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Rate = 30
	particles.Speed = NumberRange.new(2, 5)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Parent = portalEffect

	-- BillboardGui avec le nom du portail
	local billboard: BillboardGui = Instance.new("BillboardGui")
	billboard.Name = "PortalLabel"
	billboard.Size = UDim2.fromOffset(300, 120)
	billboard.StudsOffset = Vector3.new(0, pH / 2 + 4, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 80
	billboard.Parent = portalEffect

	local nameLabel: TextLabel = Instance.new("TextLabel")
	nameLabel.Name = "PortalName"
	nameLabel.Size = UDim2.fromScale(1, 0.6)
	nameLabel.Position = UDim2.fromScale(0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = portalName
	nameLabel.TextColor3 = color
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.Parent = billboard

	local subLabel: TextLabel = Instance.new("TextLabel")
	subLabel.Name = "Subtitle"
	subLabel.Size = UDim2.fromScale(1, 0.35)
	subLabel.Position = UDim2.fromScale(0, 0.6)
	subLabel.BackgroundTransparency = 1
	subLabel.Text = subtitle
	subLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	subLabel.TextStrokeTransparency = 0.3
	subLabel.TextScaled = true
	subLabel.Font = Enum.Font.GothamBold
	subLabel.Parent = billboard

	-- Anneau Neon au sol (cercle de téléportation)
	local teleRing: Part = Instance.new("Part")
	teleRing.Name = "TeleportRing"
	teleRing.Shape = Enum.PartType.Cylinder
	teleRing.Size = Vector3.new(0.5, iW + 4, iW + 4)
	teleRing.CFrame = CFrame.new(posFromAngle(angle, dist, GROUND_Y + 0.5)) * CFrame.Angles(0, 0, math.rad(90))
	teleRing.Anchored = true
	teleRing.CanCollide = false
	teleRing.Material = Enum.Material.Neon
	teleRing.Color = color
	teleRing.Transparency = 0.5
	teleRing.Parent = portalModel

	-- Stocker les métadonnées pour le système de téléportation
	local tag: StringValue = Instance.new("StringValue")
	tag.Name = "PortalId"
	tag.Value = portalId
	tag.Parent = portalEffect

	portalModel.Parent = spawnFolder

	print(`[SpawnBuilder] ✅ Portail "{portalName}" construit (angle={angle}°)`)
end

local function buildAllPortals(): ()
	for _, portalData in Constants.PORTALS do
		buildPortal(portalData)
	end
end

-------------------------------------------------
-- 4. Chemins pavés (du centre vers chaque portail)
-------------------------------------------------
local function buildPaths(): ()
	local PATH_WIDTH: number = 6
	local PATH_SEGMENTS: number = 8 -- Nombre de dalles par chemin

	for _, portalData in Constants.PORTALS do
		local angle: number = portalData.Angle
		local dist: number = portalData.Distance
		local color: Color3 = portalData.Color

		for i = 1, PATH_SEGMENTS do
			local t: number = i / (PATH_SEGMENTS + 1)
			local segDist: number = Constants.FOUNTAIN_RADIUS + 2 + t * (dist - Constants.FOUNTAIN_RADIUS - 8)
			local pos: Vector3 = posFromAngle(angle, segDist, GROUND_Y + 0.3)

			local rad = radians(angle)
			local lookDir = Vector3.new(math.cos(rad), 0, math.sin(rad))
			local segCF: CFrame = CFrame.lookAt(pos, pos + lookDir)

			local slab: Part = Instance.new("Part")
			slab.Name = `Path_{portalData.Id}_{i}`
			slab.Size = Vector3.new(PATH_WIDTH, 0.3, (dist - Constants.FOUNTAIN_RADIUS - 6) / PATH_SEGMENTS - 0.5)
			slab.CFrame = segCF
			slab.Anchored = true
			slab.Material = Enum.Material.Cobblestone
			slab.Color = Color3.fromRGB(140, 130, 120)
			slab.TopSurface = Enum.SurfaceType.Smooth
			slab.BottomSurface = Enum.SurfaceType.Smooth
			slab.Parent = spawnFolder

			-- Lumière latérale faible tous les 3 segments
			if i % 3 == 0 then
				local lampPos: Vector3 = posFromAngle(angle, segDist, GROUND_Y)
				local lamp: Part = Instance.new("Part")
				lamp.Name = `PathLamp_{portalData.Id}_{i}`
				lamp.Shape = Enum.PartType.Cylinder
				lamp.Size = Vector3.new(6, 0.5, 0.5)
				lamp.CFrame = CFrame.new(lampPos + Vector3.new(PATH_WIDTH / 2 + 2, 3, 0))
				lamp.Anchored = true
				lamp.CanCollide = false
				lamp.Material = Enum.Material.Metal
				lamp.Color = Color3.fromRGB(80, 80, 90)
				lamp.Parent = spawnFolder

				local lampOrb: Part = Instance.new("Part")
				lampOrb.Name = "LampOrb"
				lampOrb.Shape = Enum.PartType.Ball
				lampOrb.Size = Vector3.new(2, 2, 2)
				lampOrb.Position = lampPos + Vector3.new(PATH_WIDTH / 2 + 2, 6.5, 0)
				lampOrb.Anchored = true
				lampOrb.CanCollide = false
				lampOrb.Material = Enum.Material.Neon
				lampOrb.Color = Color3.fromRGB(255, 220, 150)
				lampOrb.Transparency = 0.1
				lampOrb.Parent = spawnFolder

				local lampLight: PointLight = Instance.new("PointLight")
				lampLight.Color = Color3.fromRGB(255, 220, 150)
				lampLight.Brightness = 1.5
				lampLight.Range = 15
				lampLight.Parent = lampOrb
			end
		end
	end

	print("[SpawnBuilder] ✅ Chemins pavés construits")
end

-------------------------------------------------
-- 5. Décoration : Arbres stylisés
-------------------------------------------------
local function buildTree(pos: Vector3, scale: number): ()
	-- Tronc
	local trunk: Part = Instance.new("Part")
	trunk.Name = "TreeTrunk"
	trunk.Shape = Enum.PartType.Cylinder
	trunk.Size = Vector3.new(8 * scale, 1.5 * scale, 1.5 * scale) -- Cylinder X=hauteur
	trunk.CFrame = CFrame.new(pos + Vector3.new(0, 4 * scale, 0)) * CFrame.Angles(0, 0, math.rad(90))
	trunk.Anchored = true
	trunk.Material = Enum.Material.Wood
	trunk.Color = Color3.fromRGB(100, 70, 40)
	trunk.Parent = spawnFolder

	-- Feuillage (sphère)
	local foliage: Part = Instance.new("Part")
	foliage.Name = "TreeFoliage"
	foliage.Shape = Enum.PartType.Ball
	foliage.Size = Vector3.new(8 * scale, 8 * scale, 8 * scale)
	foliage.Position = pos + Vector3.new(0, 10 * scale, 0)
	foliage.Anchored = true
	foliage.CanCollide = false
	foliage.Material = Enum.Material.Grass
	foliage.Color = Color3.fromRGB(40 + math.random(0, 40), 130 + math.random(0, 60), 30 + math.random(0, 30))
	foliage.Parent = spawnFolder
end

local function buildTrees(): ()
	-- Placer des arbres aléatoirement autour du spawn (beaucoup plus)
	local treeAngles = { 15, 30, 45, 60, 75, 105, 120, 135, 150, 165, 195, 210, 225, 240, 255, 285, 300, 315, 330, 345 }
	
	for _, tAngle in treeAngles do
		local dist = RADIUS * 0.45 + math.random() * RADIUS * 0.4
		local pos = posFromAngle(tAngle, dist, GROUND_Y)
		local scale = 0.7 + math.random() * 0.8
		buildTree(pos, scale)
	end
	
	-- Couronne d'arbres au bord de l'île
	for i = 1, 30 do
		local tAngle = math.random() * 360
		local dist = RADIUS * 0.7 + math.random() * RADIUS * 0.2
		local pos = posFromAngle(tAngle, dist, GROUND_Y)
		local scale = 0.6 + math.random() * 1.0
		buildTree(pos, scale)
	end

	-- Petits arbustes (arbres très petits) entre les chemins
	for i = 1, 20 do
		local tAngle = math.random() * 360
		local dist = RADIUS * 0.15 + math.random() * RADIUS * 0.3
		local pos = posFromAngle(tAngle, dist, GROUND_Y)
		local scale = 0.3 + math.random() * 0.3
		buildTree(pos, scale)
	end

	print("[SpawnBuilder] ✅ Arbres & arbustes placés")
end

-------------------------------------------------
-- 6. Nuages
-------------------------------------------------
local function buildClouds(): ()
	for i = 1, 18 do
		local cloudX: number = CENTER.X + math.random(-200, 200)
		local cloudY: number = 90 + math.random(0, 50)
		local cloudZ: number = CENTER.Z + math.random(-200, 200)
		
		-- Chaque nuage = groupe de 3-5 sphères
		for j = 1, math.random(3, 5) do
			local offsetX: number = (j - 1) * math.random(4, 8) * (if math.random() > 0.5 then 1 else -1)
			local offsetZ: number = math.random(-3, 3)
			local size: number = math.random(8, 16)

			local cloud: Part = Instance.new("Part")
			cloud.Name = `Cloud_{i}_{j}`
			cloud.Shape = Enum.PartType.Ball
			cloud.Size = Vector3.new(size, size * 0.5, size)
			cloud.Position = Vector3.new(cloudX + offsetX, cloudY, cloudZ + offsetZ)
			cloud.Anchored = true
			cloud.CanCollide = false
			cloud.Material = Enum.Material.SmoothPlastic
			cloud.Color = Color3.fromRGB(240, 240, 245)
			cloud.Transparency = 0.15
			cloud.CastShadow = false
			cloud.Parent = spawnFolder
		end
	end

	print("[SpawnBuilder] ✅ Nuages placés")
end

-------------------------------------------------
-- 7. Lampadaires décoratifs autour de l'île
-------------------------------------------------
local function buildLampposts(): ()
	local numLamps: number = 20
	for i = 1, numLamps do
		local angle: number = (i / numLamps) * 360
		local pos: Vector3 = posFromAngle(angle, RADIUS - 8, GROUND_Y)
		
		-- Poteau
		local pole: Part = Instance.new("Part")
		pole.Name = `Lamppost_{i}`
		pole.Size = Vector3.new(0.6, 10, 0.6)
		pole.Position = pos + Vector3.new(0, 5, 0)
		pole.Anchored = true
		pole.Material = Enum.Material.Metal
		pole.Color = Color3.fromRGB(50, 50, 55)
		pole.Parent = spawnFolder

		-- Lampe
		local lampHead: Part = Instance.new("Part")
		lampHead.Name = "LampHead"
		lampHead.Shape = Enum.PartType.Ball
		lampHead.Size = Vector3.new(3, 3, 3)
		lampHead.Position = pos + Vector3.new(0, 10.5, 0)
		lampHead.Anchored = true
		lampHead.CanCollide = false
		lampHead.Material = Enum.Material.Neon
		lampHead.Color = Color3.fromRGB(255, 200, 100)
		lampHead.Transparency = 0.1
		lampHead.Parent = spawnFolder

		local light: PointLight = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 200, 100)
		light.Brightness = 2
		light.Range = 20
		light.Parent = lampHead
	end

	print("[SpawnBuilder] ✅ Lampadaires placés")
end

-------------------------------------------------
-- 8. Comptoir Gems / Monnaie (panel décoratif)
-------------------------------------------------
local function buildGemsDisplay(): ()
	-- Petit panneau "+500 Gems" sur le côté
	local signPos: Vector3 = posFromAngle(45, RADIUS - 15, GROUND_Y + 5)

	local sign: Part = Instance.new("Part")
	sign.Name = "GemsSign"
	sign.Size = Vector3.new(0.5, 6, 10)
	sign.Position = signPos
	sign.Anchored = true
	sign.Material = Enum.Material.SmoothPlastic
	sign.Color = Color3.fromRGB(40, 40, 50)
	sign.Parent = spawnFolder

	local billboard: BillboardGui = Instance.new("BillboardGui")
	billboard.Name = "GemsLabel"
	billboard.Size = UDim2.fromOffset(200, 80)
	billboard.StudsOffset = Vector3.new(0, 0, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 50
	billboard.Parent = sign

	local lbl: TextLabel = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = "💎 +500 Gems"
	lbl.TextColor3 = Color3.fromRGB(100, 255, 100)
	lbl.TextStrokeTransparency = 0
	lbl.TextScaled = true
	lbl.Font = Enum.Font.FredokaOne
	lbl.Parent = billboard

	local glow: PointLight = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(100, 255, 100)
	glow.Brightness = 2
	glow.Range = 12
	glow.Parent = sign

	print("[SpawnBuilder] ✅ Panneau Gems construit")
end

-------------------------------------------------
-- 9. SpawnLocation (joueur apparaît au centre)
-------------------------------------------------
local function buildSpawnLocation(): ()
	local spawn: SpawnLocation = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = CENTER + Vector3.new(0, GROUND_Y + 0.5, 15) -- Un peu devant la fontaine
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.CanQuery = false
	spawn.Transparency = 1
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Enabled = true
	spawn.Neutral = true
	spawn.Parent = spawnFolder

	print("[SpawnBuilder] ✅ SpawnLocation placée")
end

-------------------------------------------------
-- 10. Éclairage (ambiance nuit stylisée)
-------------------------------------------------
local function setupLighting(): ()
	Lighting.ClockTime = 18.5 -- Crépuscule doré (coucher de soleil)
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(80, 70, 100)
	Lighting.OutdoorAmbient = Color3.fromRGB(130, 120, 150)
	Lighting.FogEnd = 800
	Lighting.FogColor = Color3.fromRGB(60, 50, 80)
	Lighting.GlobalShadows = true

	-- Supprimer ancienne atmosphère
	local existingAtmo: Instance? = Lighting:FindFirstChildOfClass("Atmosphere")
	if existingAtmo then existingAtmo:Destroy() end

	local atmosphere: Atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.25
	atmosphere.Offset = 0.1
	atmosphere.Color = Color3.fromRGB(140, 120, 180)
	atmosphere.Decay = Color3.fromRGB(100, 80, 130)
	atmosphere.Glare = 0.3
	atmosphere.Haze = 1
	atmosphere.Parent = Lighting

	-- Bloom (lueur des Neons)
	local existingBloom: Instance? = Lighting:FindFirstChildOfClass("BloomEffect")
	if existingBloom then existingBloom:Destroy() end

	local bloom: BloomEffect = Instance.new("BloomEffect")
	bloom.Intensity = 0.5
	bloom.Size = 24
	bloom.Threshold = 0.8
	bloom.Parent = Lighting

	-- ColorCorrection (teinte bleutée/violette)
	local existingCC: Instance? = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if existingCC then existingCC:Destroy() end

	local cc: ColorCorrectionEffect = Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.05
	cc.Contrast = 0.1
	cc.Saturation = 0.3
	cc.TintColor = Color3.fromRGB(220, 210, 255)
	cc.Parent = Lighting

	print("[SpawnBuilder] ✅ Éclairage crépuscule configuré")
end

-------------------------------------------------
-- 11. Sol décoratif sous la fontaine (anneau brillant)
-------------------------------------------------
local function buildCenterDecor(): ()
	-- Grand anneau autour de la fontaine
	local ring: Part = Instance.new("Part")
	ring.Name = "CenterRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.3, Constants.FOUNTAIN_RADIUS * 2 + 8, Constants.FOUNTAIN_RADIUS * 2 + 8)
	ring.CFrame = CFrame.new(CENTER + Vector3.new(0, GROUND_Y + 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Anchored = true
	ring.CanCollide = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(0, 200, 255)
	ring.Transparency = 0.4
	ring.Parent = spawnFolder

	-- Étoile decorative au sol (8 branches — barres simples)
	local numBranches: number = 8
	for i = 1, numBranches do
		local angle: number = (i / numBranches) * 360
		local rad = radians(angle)
		local length: number = Constants.FOUNTAIN_RADIUS + 6
		local midDist: number = Constants.FOUNTAIN_RADIUS / 2 + 3
		local pos: Vector3 = CENTER + Vector3.new(
			math.cos(rad) * midDist,
			GROUND_Y + 0.35,
			math.sin(rad) * midDist
		)

		local branch: Part = Instance.new("Part")
		branch.Name = `StarBranch_{i}`
		branch.Size = Vector3.new(length, 0.2, 0.8)
		branch.CFrame = CFrame.lookAt(pos, pos + Vector3.new(math.cos(rad), 0, math.sin(rad)))
		branch.Anchored = true
		branch.CanCollide = false
		branch.Material = Enum.Material.Neon
		branch.Color = Color3.fromRGB(0, 180, 255)
		branch.Transparency = 0.5
		branch.Parent = spawnFolder
	end

	print("[SpawnBuilder] ✅ Décoration centrale construite")
end

-------------------------------------------------
-- 12. Parterres de fleurs colorées
-------------------------------------------------
local FLOWER_COLORS: { Color3 } = {
	Color3.fromRGB(255, 80, 120),   -- Rose
	Color3.fromRGB(255, 200, 50),   -- Jaune
	Color3.fromRGB(180, 80, 255),   -- Violet
	Color3.fromRGB(255, 120, 40),   -- Orange
	Color3.fromRGB(100, 200, 255),  -- Bleu clair
	Color3.fromRGB(255, 50, 50),    -- Rouge
}

local function buildFlowerBed(centerPos: Vector3, bedRadius: number): ()
	-- Base du parterre (anneau de terre)
	local bed: Part = Instance.new("Part")
	bed.Name = "FlowerBed"
	bed.Shape = Enum.PartType.Cylinder
	bed.Size = Vector3.new(0.8, bedRadius * 2, bedRadius * 2)
	bed.CFrame = CFrame.new(centerPos + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90))
	bed.Anchored = true
	bed.CanCollide = false
	bed.Material = Enum.Material.Ground
	bed.Color = Color3.fromRGB(100, 70, 40)
	bed.Parent = spawnFolder

	-- Fleurs individuelles
	for i = 1, math.random(8, 14) do
		local fAngle: number = math.random() * 360
		local fDist: number = math.random() * (bedRadius - 1)
		local fRad = math.rad(fAngle)
		local fPos: Vector3 = centerPos + Vector3.new(math.cos(fRad) * fDist, 0.8, math.sin(fRad) * fDist)
		local fColor: Color3 = FLOWER_COLORS[math.random(1, #FLOWER_COLORS)]

		-- Tige
		local stem: Part = Instance.new("Part")
		stem.Name = "FlowerStem"
		stem.Size = Vector3.new(0.2, 1.2, 0.2)
		stem.Position = fPos + Vector3.new(0, 0.6, 0)
		stem.Anchored = true
		stem.CanCollide = false
		stem.Material = Enum.Material.Grass
		stem.Color = Color3.fromRGB(50, 140, 40)
		stem.Parent = spawnFolder

		-- Pétale (sphère aplatie)
		local petal: Part = Instance.new("Part")
		petal.Name = "FlowerPetal"
		petal.Shape = Enum.PartType.Ball
		petal.Size = Vector3.new(1.2, 0.6, 1.2)
		petal.Position = fPos + Vector3.new(0, 1.5, 0)
		petal.Anchored = true
		petal.CanCollide = false
		petal.Material = Enum.Material.SmoothPlastic
		petal.Color = fColor
		petal.Parent = spawnFolder
	end
end

local function buildAllFlowerBeds(): ()
	-- Parterres entre les portails (8 positions, entre les 4 chemins)
	local flowerAngles = { 45, 135, 225, 315, 22, 68, 112, 158, 202, 248, 292, 338 }
	for _, fAngle in flowerAngles do
		local dist = RADIUS * 0.25 + math.random() * RADIUS * 0.25
		local pos = posFromAngle(fAngle, dist, GROUND_Y)
		buildFlowerBed(pos, 3 + math.random() * 2)
	end

	print("[SpawnBuilder] ✅ Parterres de fleurs placés")
end

-------------------------------------------------
-- 13. Bancs décoratifs
-------------------------------------------------
local function buildBench(pos: Vector3, facingAngle: number): ()
	local rad = math.rad(facingAngle)
	local cf: CFrame = CFrame.new(pos) * CFrame.Angles(0, rad, 0)

	-- Assise
	local seat: Part = Instance.new("Part")
	seat.Name = "BenchSeat"
	seat.Size = Vector3.new(5, 0.4, 1.8)
	seat.CFrame = cf * CFrame.new(0, 1.2, 0)
	seat.Anchored = true
	seat.Material = Enum.Material.Wood
	seat.Color = Color3.fromRGB(120, 80, 45)
	seat.Parent = spawnFolder

	-- Dossier
	local back: Part = Instance.new("Part")
	back.Name = "BenchBack"
	back.Size = Vector3.new(5, 1.5, 0.3)
	back.CFrame = cf * CFrame.new(0, 2, -0.75)
	back.Anchored = true
	back.Material = Enum.Material.Wood
	back.Color = Color3.fromRGB(120, 80, 45)
	back.Parent = spawnFolder

	-- Pieds (4)
	for _, offset in { Vector3.new(-2, 0.6, 0.5), Vector3.new(2, 0.6, 0.5), Vector3.new(-2, 0.6, -0.5), Vector3.new(2, 0.6, -0.5) } do
		local leg: Part = Instance.new("Part")
		leg.Name = "BenchLeg"
		leg.Size = Vector3.new(0.3, 1.2, 0.3)
		leg.CFrame = cf * CFrame.new(offset)
		leg.Anchored = true
		leg.Material = Enum.Material.Metal
		leg.Color = Color3.fromRGB(60, 60, 65)
		leg.Parent = spawnFolder
	end
end

local function buildAllBenches(): ()
	local benchAngles = { 45, 135, 225, 315 }
	for _, bAngle in benchAngles do
		local pos = posFromAngle(bAngle, 30, GROUND_Y)
		buildBench(pos, bAngle + 90) -- Face vers le chemin
	end

	-- Bancs supplémentaires plus loin
	for _, bAngle in { 20, 70, 110, 160, 200, 250, 290, 340 } do
		local pos = posFromAngle(bAngle, RADIUS * 0.55, GROUND_Y)
		buildBench(pos, bAngle)
	end

	print("[SpawnBuilder] ✅ Bancs placés")
end

-------------------------------------------------
-- 14. Formations rocheuses
-------------------------------------------------
local function buildRockCluster(pos: Vector3, scale: number): ()
	local numRocks: number = math.random(3, 6)
	for i = 1, numRocks do
		local offsetX: number = math.random(-3, 3) * scale
		local offsetZ: number = math.random(-3, 3) * scale
		local rockSize: number = (1 + math.random() * 3) * scale

		local rock: Part = Instance.new("Part")
		rock.Name = `Rock_{i}`
		rock.Shape = Enum.PartType.Ball
		rock.Size = Vector3.new(rockSize * 1.2, rockSize * 0.7, rockSize)
		rock.Position = pos + Vector3.new(offsetX, rockSize * 0.3, offsetZ)
		rock.Anchored = true
		rock.Material = Enum.Material.Slate
		rock.Color = Color3.fromRGB(90 + math.random(0, 30), 85 + math.random(0, 25), 80 + math.random(0, 20))
		rock.Parent = spawnFolder
	end
end

local function buildAllRocks(): ()
	local rockAngles = { 55, 125, 190, 260, 335 }
	for _, rAngle in rockAngles do
		local pos = posFromAngle(rAngle, RADIUS * 0.6 + math.random() * RADIUS * 0.2, GROUND_Y)
		buildRockCluster(pos, 0.8 + math.random() * 0.6)
	end

	print("[SpawnBuilder] ✅ Rochers placés")
end

-------------------------------------------------
-- 15. Petites collines (relief)
-------------------------------------------------
local function buildHills(): ()
	local hillData = {
		{ angle = 40,  dist = 0.65, size = 18, height = 5 },
		{ angle = 130, dist = 0.7,  size = 22, height = 7 },
		{ angle = 200, dist = 0.6,  size = 15, height = 4 },
		{ angle = 310, dist = 0.75, size = 20, height = 6 },
		{ angle = 85,  dist = 0.5,  size = 12, height = 3 },
		{ angle = 170, dist = 0.55, size = 16, height = 5 },
		{ angle = 260, dist = 0.65, size = 14, height = 4 },
		{ angle = 350, dist = 0.5,  size = 10, height = 3 },
	}

	for _, h in hillData do
		local pos: Vector3 = posFromAngle(h.angle, RADIUS * h.dist, GROUND_Y)

		local hill: Part = Instance.new("Part")
		hill.Name = "Hill"
		hill.Shape = Enum.PartType.Ball
		hill.Size = Vector3.new(h.size * 2, h.height * 2, h.size * 2)
		hill.Position = pos + Vector3.new(0, -h.height * 0.3, 0)
		hill.Anchored = true
		hill.CanCollide = true
		hill.Material = Enum.Material.Grass
		hill.Color = Color3.fromRGB(70 + math.random(0, 20), 155 + math.random(0, 30), 50 + math.random(0, 20))
		hill.Parent = spawnFolder
	end

	print("[SpawnBuilder] ✅ Collines placées")
end

-------------------------------------------------
-- 16. Petite mare / étang décoratif
-------------------------------------------------
local function buildPonds(): ()
	local pondPositions = {
		{ angle = 65,  dist = 0.4,  radius = 8 },
		{ angle = 245, dist = 0.45, radius = 6 },
	}

	for _, p in pondPositions do
		local pos: Vector3 = posFromAngle(p.angle, RADIUS * p.dist, GROUND_Y)

		-- Eau
		local pond: Part = Instance.new("Part")
		pond.Name = "Pond"
		pond.Shape = Enum.PartType.Cylinder
		pond.Size = Vector3.new(0.5, p.radius * 2, p.radius * 2)
		pond.CFrame = CFrame.new(pos + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
		pond.Anchored = true
		pond.CanCollide = false
		pond.Material = Enum.Material.Glass
		pond.Color = Color3.fromRGB(60, 150, 220)
		pond.Transparency = 0.35
		pond.Parent = spawnFolder

		-- Bordure
		local pondBorder: Part = Instance.new("Part")
		pondBorder.Name = "PondBorder"
		pondBorder.Shape = Enum.PartType.Cylinder
		pondBorder.Size = Vector3.new(0.8, p.radius * 2 + 2, p.radius * 2 + 2)
		pondBorder.CFrame = CFrame.new(pos + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
		pondBorder.Anchored = true
		pondBorder.CanCollide = false
		pondBorder.Material = Enum.Material.Slate
		pondBorder.Color = Color3.fromRGB(110, 100, 90)
		pondBorder.Parent = spawnFolder

		-- Quelques nénuphars (petits disques verts)
		for i = 1, math.random(3, 5) do
			local lAngle = math.random() * 360
			local lDist = math.random() * (p.radius - 2)
			local lRad = math.rad(lAngle)

			local lily: Part = Instance.new("Part")
			lily.Name = "LilyPad"
			lily.Shape = Enum.PartType.Cylinder
			lily.Size = Vector3.new(0.2, 1.5, 1.5)
			lily.CFrame = CFrame.new(pos + Vector3.new(math.cos(lRad) * lDist, 0.55, math.sin(lRad) * lDist)) * CFrame.Angles(0, 0, math.rad(90))
			lily.Anchored = true
			lily.CanCollide = false
			lily.Material = Enum.Material.Grass
			lily.Color = Color3.fromRGB(50, 160, 50)
			lily.Parent = spawnFolder
		end
	end

	print("[SpawnBuilder] ✅ Étangs placés")
end

-------------------------------------------------
-- 17. Guirlandes lumineuses (arcs de lumières entre lampadaires)
-------------------------------------------------
local function buildFairyLights(): ()
	local numArcs: number = 16
	for i = 1, numArcs do
		local angle1: number = (i / numArcs) * 360
		local angle2: number = ((i + 1) / numArcs) * 360
		local pos1: Vector3 = posFromAngle(angle1, RADIUS * 0.45, GROUND_Y + 8)
		local pos2: Vector3 = posFromAngle(angle2, RADIUS * 0.45, GROUND_Y + 8)

		-- 3-4 bulbes le long de l'arc
		for j = 1, 3 do
			local t: number = j / 4
			local mid: Vector3 = pos1:Lerp(pos2, t)
			local sag: number = math.sin(t * math.pi) * 2 -- Courbe vers le bas

			local bulb: Part = Instance.new("Part")
			bulb.Name = `FairyLight_{i}_{j}`
			bulb.Shape = Enum.PartType.Ball
			bulb.Size = Vector3.new(0.8, 0.8, 0.8)
			bulb.Position = mid + Vector3.new(0, -sag, 0)
			bulb.Anchored = true
			bulb.CanCollide = false
			bulb.Material = Enum.Material.Neon
			bulb.Color = Color3.fromRGB(255, 230, 150)
			bulb.Transparency = 0.1
			bulb.Parent = spawnFolder

			local bLight: PointLight = Instance.new("PointLight")
			bLight.Color = Color3.fromRGB(255, 230, 150)
			bLight.Brightness = 0.6
			bLight.Range = 6
			bLight.Parent = bulb
		end
	end

	print("[SpawnBuilder] ✅ Guirlandes lumineuses placées")
end

-------------------------------------------------
-- CONSTRUCTION
-------------------------------------------------
print("[SpawnBuilder] 🏗️ Construction du Spawn Hub...")

buildIsland()
buildFountain()
buildCenterDecor()
buildAllPortals()
buildPaths()
buildHills()
buildTrees()
buildAllFlowerBeds()
buildAllBenches()
buildAllRocks()
buildPonds()
buildClouds()
buildLampposts()
buildFairyLights()
buildGemsDisplay()
buildSpawnLocation()
setupLighting()

print("[SpawnBuilder] ✅ Spawn Hub complet !")
