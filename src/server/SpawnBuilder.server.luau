--!strict

--[[
	SpawnBuilder (ServerScript) — v2.0 "Brainrot Shrine"
	=====================================================
	Génère le Spawn Hub AAA pour Brainrot Defense :
	  • Architecture Torii / Pagode cyberpunk (inspirée de l'image de ref)
	  • Statue dorée centrale "Glorbo" sur piédestal néon
	  • 4 Portails épiques (arches Torii géantes avec FX)
	  • Zone AFK "Salle du Temps" avec sièges gamer
	  • Vitrine "Hall of Fame" avec podiums unités légendaires
	  • Leaderboard physique
	  • Chemins pavés lumineux, lanternes, arbres cerisier
	  • Anneaux animés (TweenService), particules, néons
	  • Lighting crépuscule fantastique (Bloom, Atmosphere, CC)
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
local RADIUS: number  = Constants.SPAWN_RADIUS
local GROUND_Y: number = Constants.SPAWN_GROUND_Y

-- Palettes couleurs (thème Pagode cyberpunk brainrot)
local COLOR_TORII_RED     = Color3.fromRGB(180, 30, 30)
local COLOR_TORII_DARK    = Color3.fromRGB(100, 15, 15)
local COLOR_GOLD          = Color3.fromRGB(255, 200, 50)
local COLOR_DARK_WOOD     = Color3.fromRGB(60, 35, 20)
local COLOR_STONE         = Color3.fromRGB(160, 155, 145)
local COLOR_STONE_DARK    = Color3.fromRGB(90, 85, 80)
local COLOR_NEON_CYAN     = Color3.fromRGB(0, 200, 255)
local COLOR_NEON_PINK     = Color3.fromRGB(255, 50, 180)
local COLOR_LANTERN_WARM  = Color3.fromRGB(255, 180, 80)
local COLOR_GRASS         = Color3.fromRGB(60, 150, 45)
local COLOR_CHERRY_PINK   = Color3.fromRGB(255, 150, 180)
local COLOR_CHERRY_WHITE  = Color3.fromRGB(255, 220, 230)
local COLOR_WATER         = Color3.fromRGB(40, 130, 210)
local COLOR_HUB_FLOOR     = Color3.fromRGB(130, 125, 115)
local COLOR_PAGODA_ROOF   = Color3.fromRGB(35, 100, 55)

-------------------------------------------------
-- Dossier conteneur
-------------------------------------------------
local existingHub = Workspace:FindFirstChild("SpawnHub")
if existingHub then existingHub:Destroy() end

local spawnFolder: Folder = Instance.new("Folder")
spawnFolder.Name = "SpawnHub"
spawnFolder.Parent = Workspace

-------------------------------------------------
-- Utilitaires
-------------------------------------------------
local function rad(degrees: number): number
	return math.rad(degrees)
end

local function posFromAngle(angle: number, dist: number, y: number): Vector3
	local r = rad(angle)
	return CENTER + Vector3.new(math.cos(r) * dist, y, math.sin(r) * dist)
end

local function createPart(props: { [string]: any }): Part
	local part: Part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = if props.CanCollide ~= nil then props.CanCollide else true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		if key ~= "CanCollide" and key ~= "Parent" then
			(part :: any)[key] = value
		end
	end
	part.Parent = props.Parent or spawnFolder
	return part
end

--- Tween ping-pong (aller-retour infini)
local function pingPongTween(instance: Instance, duration: number, goals: { [string]: any }): ()
	local info = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	TweenService:Create(instance, info, goals):Play()
end

--- Tween rotation continue
local function spinForever(part: BasePart, axis: string, rps: number): ()
	task.spawn(function()
		while part and part.Parent do
			local startCF = part.CFrame
			local endCF: CFrame
			if axis == "Y" then
				endCF = startCF * CFrame.Angles(0, math.pi * 2, 0)
			elseif axis == "X" then
				endCF = startCF * CFrame.Angles(math.pi * 2, 0, 0)
			else
				endCF = startCF * CFrame.Angles(0, 0, math.pi * 2)
			end
			local tween = TweenService:Create(part, TweenInfo.new(1 / rps, Enum.EasingStyle.Linear), { CFrame = endCF })
			tween:Play()
			tween.Completed:Wait()
		end
	end)
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 1. ÎLE PRINCIPALE — Sol circulaire + Bordure
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildIsland(): ()
	-- Sol principal : cylindre d'herbe
	createPart({
		Name = "SpawnIsland",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(6, RADIUS * 2, RADIUS * 2),
		CFrame = CFrame.new(CENTER + Vector3.new(0, -1, 0)) * CFrame.Angles(0, 0, rad(90)),
		Material = Enum.Material.Grass,
		Color = COLOR_GRASS,
	})

	-- Sous-sol (épaisseur terre)
	createPart({
		Name = "IslandBase",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(20, RADIUS * 2 + 10, RADIUS * 2 + 10),
		CFrame = CFrame.new(CENTER + Vector3.new(0, -12, 0)) * CFrame.Angles(0, 0, rad(90)),
		Material = Enum.Material.Ground,
		Color = Color3.fromRGB(90, 65, 35),
	})

	-- Zone centrale pavée (cercle de pierre sous la fontaine + autour)
	local innerRadius = 35
	createPart({
		Name = "CenterPlaza",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1, innerRadius * 2, innerRadius * 2),
		CFrame = CFrame.new(CENTER + Vector3.new(0, GROUND_Y, 0)) * CFrame.Angles(0, 0, rad(90)),
		Material = Enum.Material.Cobblestone,
		Color = COLOR_HUB_FLOOR,
	})

	-- Anneau de pierre sculptée autour de la plaza
	createPart({
		Name = "PlazaBorder",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.5, innerRadius * 2 + 4, innerRadius * 2 + 4),
		CFrame = CFrame.new(CENTER + Vector3.new(0, GROUND_Y - 0.1, 0)) * CFrame.Angles(0, 0, rad(90)),
		Material = Enum.Material.Slate,
		Color = COLOR_STONE_DARK,
		CanCollide = false,
	})

	-- Bordure néon extérieure de l'île
	local borderNeon = createPart({
		Name = "IslandNeonBorder",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.5, RADIUS * 2 + 4, RADIUS * 2 + 4),
		CFrame = CFrame.new(CENTER + Vector3.new(0, GROUND_Y + 0.3, 0)) * CFrame.Angles(0, 0, rad(90)),
		Material = Enum.Material.Neon,
		Color = COLOR_NEON_CYAN,
		Transparency = 0.5,
		CanCollide = false,
	})

	-- Eau décorative autour
	createPart({
		Name = "SurroundingWater",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(3, RADIUS * 4, RADIUS * 4),
		CFrame = CFrame.new(CENTER + Vector3.new(0, -3, 0)) * CFrame.Angles(0, 0, rad(90)),
		Material = Enum.Material.Glass,
		Color = COLOR_WATER,
		Transparency = 0.4,
		CanCollide = false,
	})

	-- Pulser la bordure néon
	pingPongTween(borderNeon, 3, { Transparency = 0.8 })

	print("[SpawnBuilder] ✅ Île principale construite")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 2. STATUE CENTRALE — "Glorbo Doré" sur piédestal
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildCentralStatue(): ()
	local fRadius: number = Constants.FOUNTAIN_RADIUS
	local fHeight: number = Constants.FOUNTAIN_HEIGHT
	local statueH: number = Constants.STATUE_HEIGHT
	local pedestalH: number = Constants.STATUE_PEDESTAL_H

	-- ─── Bassin octogonal (simulé cylindre + steps) ───
	-- Marches extérieures (3 niveaux)
	for step = 1, 3 do
		local stepR = fRadius + (4 - step) * 3
		local stepH = step * 0.8
		createPart({
			Name = `BasinStep_{step}`,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(stepH, stepR * 2, stepR * 2),
			CFrame = CFrame.new(CENTER + Vector3.new(0, GROUND_Y + stepH / 2, 0)) * CFrame.Angles(0, 0, rad(90)),
			Material = Enum.Material.Marble,
			Color = COLOR_STONE,
		})
	end

	-- Bassin principal
	createPart({
		Name = "FountainBasin",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(fHeight, fRadius * 2, fRadius * 2),
		CFrame = CFrame.new(CENTER + Vector3.new(0, GROUND_Y + 2.4 + fHeight / 2, 0)) * CFrame.Angles(0, 0, rad(90)),
		Material = Enum.Material.Marble,
		Color = Color3.fromRGB(200, 195, 185),
	})

	-- Eau du bassin
	createPart({
		Name = "FountainWater",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.5, fRadius * 2 - 3, fRadius * 2 - 3),
		CFrame = CFrame.new(CENTER + Vector3.new(0, GROUND_Y + 2.4 + fHeight + 0.25, 0)) * CFrame.Angles(0, 0, rad(90)),
		Material = Enum.Material.Glass,
		Color = Color3.fromRGB(80, 190, 255),
		Transparency = 0.25,
		CanCollide = false,
	})

	-- ─── Piédestal doré (base de la statue) ───
	local baseY = GROUND_Y + 2.4 + fHeight + 0.5

	createPart({
		Name = "Pedestal",
		Size = Vector3.new(5, pedestalH, 5),
		CFrame = CFrame.new(CENTER + Vector3.new(0, baseY + pedestalH / 2, 0)),
		Material = Enum.Material.Marble,
		Color = Color3.fromRGB(220, 210, 190),
	})

	-- Bande néon dorée autour du piédestal
	createPart({
		Name = "PedestalNeon",
		Size = Vector3.new(5.4, 0.6, 5.4),
		CFrame = CFrame.new(CENTER + Vector3.new(0, baseY + pedestalH - 0.3, 0)),
		Material = Enum.Material.Neon,
		Color = COLOR_GOLD,
		Transparency = 0.2,
		CanCollide = false,
	})

	-- ─── Statue "Glorbo Doré" ───
	local statueBaseY = baseY + pedestalH

	-- Corps principal
	local body = createPart({
		Name = "GlorboBody",
		Size = Vector3.new(4, statueH * 0.55, 3),
		CFrame = CFrame.new(CENTER + Vector3.new(0, statueBaseY + statueH * 0.275, 0)),
		Material = Enum.Material.Metal,
		Color = COLOR_GOLD,
	})

	-- Tête (sphère dorée)
	local head = createPart({
		Name = "GlorboHead",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(5, 5, 5),
		Position = CENTER + Vector3.new(0, statueBaseY + statueH * 0.55 + 3, 0),
		Material = Enum.Material.Metal,
		Color = COLOR_GOLD,
		CanCollide = false,
	})

	-- "Caméra" / Oeil (style CameraMan)
	createPart({
		Name = "GlorboCameraLens",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(3.5, 2.5, 2.5),
		CFrame = CFrame.new(CENTER + Vector3.new(0, statueBaseY + statueH * 0.55 + 3, -2.5)) * CFrame.Angles(rad(90), 0, 0),
		Material = Enum.Material.Glass,
		Color = Color3.fromRGB(30, 30, 30),
		CanCollide = false,
	})

	-- Lentille néon rouge
	local lens = createPart({
		Name = "GlorboLensGlow",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 2, 2),
		CFrame = CFrame.new(CENTER + Vector3.new(0, statueBaseY + statueH * 0.55 + 3, -3.8)) * CFrame.Angles(rad(90), 0, 0),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 50, 50),
		CanCollide = false,
	})

	pingPongTween(lens, 1.5, { Transparency = 0.6 })

	-- Lumière sur la statue
	local statueLight = Instance.new("PointLight")
	statueLight.Color = COLOR_GOLD
	statueLight.Brightness = 4
	statueLight.Range = 50
	statueLight.Parent = head

	-- Bras étendus
	for _, side in { -1, 1 } do
		createPart({
			Name = if side == -1 then "GlorboArmLeft" else "GlorboArmRight",
			Size = Vector3.new(6, 1.5, 1.5),
			CFrame = CFrame.new(CENTER + Vector3.new(side * 5, statueBaseY + statueH * 0.4, 0))
				* CFrame.Angles(0, 0, rad(side * -30)),
			Material = Enum.Material.Metal,
			Color = COLOR_GOLD,
			CanCollide = false,
		})
	end

	-- ─── Anneaux rotatifs autour de la statue ───
	for i, ringData in {
		{ radius = 8, y = 8, color = COLOR_NEON_CYAN, speed = 0.08 },
		{ radius = 10, y = 14, color = COLOR_NEON_PINK, speed = 0.05 },
		{ radius = 6, y = 20, color = COLOR_GOLD, speed = 0.12 },
	} do
		local ring = createPart({
			Name = `StatueRing_{i}`,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.4, ringData.radius * 2, ringData.radius * 2),
			CFrame = CFrame.new(CENTER + Vector3.new(0, statueBaseY + ringData.y, 0))
				* CFrame.Angles(0, 0, rad(90)),
			Material = Enum.Material.Neon,
			Color = ringData.color,
			Transparency = 0.3,
			CanCollide = false,
		})

		spinForever(ring, "Y", math.abs(ringData.speed))
	end

	-- ─── Particules "énergie brainrot" ───
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "BrainrotEnergy"
	emitter.Texture = "rbxassetid://241685484"
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, COLOR_GOLD),
		ColorSequenceKeypoint.new(0.5, COLOR_NEON_CYAN),
		ColorSequenceKeypoint.new(1, COLOR_NEON_PINK),
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, 1.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(2, 4)
	emitter.Rate = 40
	emitter.Speed = NumberRange.new(8, 18)
	emitter.SpreadAngle = Vector2.new(25, 25)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Parent = head

	-- Étincelles dorées
	local sparkEmitter = Instance.new("ParticleEmitter")
	sparkEmitter.Name = "GoldenSparks"
	sparkEmitter.Texture = "rbxassetid://241685484"
	sparkEmitter.Color = ColorSequence.new(COLOR_GOLD, Color3.fromRGB(255, 255, 200))
	sparkEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.5, 0.8),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparkEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparkEmitter.Lifetime = NumberRange.new(0.5, 1.2)
	sparkEmitter.Rate = 25
	sparkEmitter.Speed = NumberRange.new(3, 8)
	sparkEmitter.SpreadAngle = Vector2.new(180, 180)
	sparkEmitter.Parent = body

	print("[SpawnBuilder] ✅ Statue Glorbo Doré construite")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 3. PORTAILS ÉPIQUES — Arches Torii géantes
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildPortal(portalData: { [string]: any }): ()
	local angle: number   = portalData.Angle
	local dist: number    = portalData.Distance
	local color: Color3   = portalData.Color
	local portalId: string = portalData.Id
	local portalName: string = portalData.Name
	local subtitle: string = portalData.Subtitle

	local pH: number = Constants.PORTAL_HEIGHT
	local pW: number = Constants.PORTAL_WIDTH
	local pT: number = Constants.PORTAL_THICKNESS
	local iH: number = Constants.PORTAL_INNER_HEIGHT
	local iW: number = Constants.PORTAL_INNER_WIDTH

	-- Position et orientation (face vers le centre)
	local portalPos: Vector3 = posFromAngle(angle, dist, GROUND_Y + pH / 2)
	local lookAtCenter: CFrame = CFrame.lookAt(portalPos, Vector3.new(CENTER.X, portalPos.Y, CENTER.Z))

	local portalModel: Model = Instance.new("Model")
	portalModel.Name = `Portal_{portalId}`

	-- ─── Plateforme surélevée ───
	local platformPos = posFromAngle(angle, dist, GROUND_Y)
	createPart({
		Name = "PortalPlatform",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.5, pW + 10, pW + 10),
		CFrame = CFrame.new(platformPos + Vector3.new(0, 0.75, 0)) * CFrame.Angles(0, 0, rad(90)),
		Material = Enum.Material.Cobblestone,
		Color = COLOR_STONE,
		Parent = portalModel,
	})

	-- Marche néon
	createPart({
		Name = "PlatformNeonRing",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, pW + 12, pW + 12),
		CFrame = CFrame.new(platformPos + Vector3.new(0, 1.6, 0)) * CFrame.Angles(0, 0, rad(90)),
		Material = Enum.Material.Neon,
		Color = color,
		Transparency = 0.5,
		CanCollide = false,
		Parent = portalModel,
	})

	-- ─── Piliers Torii (rouge foncé style bois laqué) ───
	local pillarWidth = (pW - iW) / 2

	for _, side in { -1, 1 } do
		local sideName = if side == -1 then "Left" else "Right"
		local xOff = side * (iW / 2 + pillarWidth / 2)

		-- Pilier principal
		createPart({
			Name = `Pillar{sideName}`,
			Size = Vector3.new(pillarWidth, pH + 2, pT),
			CFrame = lookAtCenter * CFrame.new(xOff, -1, 0),
			Material = Enum.Material.Wood,
			Color = COLOR_TORII_RED,
			Parent = portalModel,
		})

		-- Base du pilier
		createPart({
			Name = `PillarBase{sideName}`,
			Size = Vector3.new(pillarWidth + 1.5, 2, pT + 1.5),
			CFrame = lookAtCenter * CFrame.new(xOff, -pH / 2 + 0.5, 0),
			Material = Enum.Material.Slate,
			Color = COLOR_STONE_DARK,
			Parent = portalModel,
		})

		-- Bande néon latérale
		local neonStrip = createPart({
			Name = `NeonStrip{sideName}`,
			Size = Vector3.new(0.4, pH - 2, 0.4),
			CFrame = lookAtCenter * CFrame.new(side * (iW / 2 + 0.3), 0, pT / 2 + 0.3),
			Material = Enum.Material.Neon,
			Color = color,
			Transparency = 0.2,
			CanCollide = false,
			Parent = portalModel,
		})

		pingPongTween(neonStrip, 2 + side * 0.3, { Transparency = 0.6 })

		-- Lanterne suspendue
		local lanternY = pH / 2 - 2
		local lanternPart = createPart({
			Name = `Lantern{sideName}`,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(3, 1.8, 1.8),
			CFrame = lookAtCenter * CFrame.new(xOff, lanternY, pT / 2 + 1.5) * CFrame.Angles(0, 0, rad(90)),
			Material = Enum.Material.Neon,
			Color = color,
			Transparency = 0.3,
			CanCollide = false,
			Parent = portalModel,
		})

		local lanternLight = Instance.new("PointLight")
		lanternLight.Color = color
		lanternLight.Brightness = 2
		lanternLight.Range = 15
		lanternLight.Parent = lanternPart
	end

	-- ─── Linteau supérieur (toit Torii double) ───
	createPart({
		Name = "Lintel",
		Size = Vector3.new(pW + 4, 2, pT + 0.5),
		CFrame = lookAtCenter * CFrame.new(0, iH / 2 + 1, 0),
		Material = Enum.Material.Wood,
		Color = COLOR_TORII_RED,
		Parent = portalModel,
	})

	-- Kasagi (second linteau plus large)
	createPart({
		Name = "Kasagi",
		Size = Vector3.new(pW + 8, 1.5, pT + 2),
		CFrame = lookAtCenter * CFrame.new(0, pH / 2 + 1, 0),
		Material = Enum.Material.Wood,
		Color = COLOR_TORII_DARK,
		Parent = portalModel,
	})

	-- Plaque dorée ornementale
	createPart({
		Name = "GoldTablet",
		Size = Vector3.new(5, 3, 0.5),
		CFrame = lookAtCenter * CFrame.new(0, iH / 2 + 1, -pT / 2 - 0.5),
		Material = Enum.Material.Metal,
		Color = COLOR_GOLD,
		CanCollide = false,
		Parent = portalModel,
	})

	-- ─── Effet intérieur du portail (vortex néon) ───
	local portalEffect = createPart({
		Name = "PortalEffect",
		Size = Vector3.new(iW, iH, 0.5),
		CFrame = lookAtCenter,
		Material = Enum.Material.Neon,
		Color = color,
		Transparency = 0.35,
		CanCollide = false,
		Parent = portalModel,
	})

	local portalLight = Instance.new("PointLight")
	portalLight.Color = color
	portalLight.Brightness = 5
	portalLight.Range = 35
	portalLight.Parent = portalEffect

	-- Particules vortex
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "PortalParticles"
	particles.Texture = "rbxassetid://241685484"
	particles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color),
		ColorSequenceKeypoint.new(0.7, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, color),
	})
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.4, 2),
		NumberSequenceKeypoint.new(1, 0),
	})
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	particles.Lifetime = NumberRange.new(1, 2.5)
	particles.Rate = 50
	particles.Speed = NumberRange.new(3, 8)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.RotSpeed = NumberRange.new(-90, 90)
	particles.Rotation = NumberRange.new(0, 360)
	particles.Parent = portalEffect

	-- Particules montantes
	local riseParticles = Instance.new("ParticleEmitter")
	riseParticles.Name = "RisingGlow"
	riseParticles.Texture = "rbxassetid://241685484"
	riseParticles.Color = ColorSequence.new(color)
	riseParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	riseParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	riseParticles.Lifetime = NumberRange.new(1.5, 3)
	riseParticles.Rate = 15
	riseParticles.Speed = NumberRange.new(5, 12)
	riseParticles.EmissionDirection = Enum.NormalId.Top
	riseParticles.SpreadAngle = Vector2.new(10, 10)
	riseParticles.Parent = portalEffect

	-- ─── Anneau néon au sol ───
	local teleRing = createPart({
		Name = "TeleportRing",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, iW + 6, iW + 6),
		CFrame = CFrame.new(posFromAngle(angle, dist, GROUND_Y + 1.8)) * CFrame.Angles(0, 0, rad(90)),
		Material = Enum.Material.Neon,
		Color = color,
		Transparency = 0.4,
		CanCollide = false,
		Parent = portalModel,
	})

	pingPongTween(teleRing, 2, { Transparency = 0.8 })

	-- ─── BillboardGui ───
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PortalLabel"
	billboard.Size = UDim2.fromOffset(400, 160)
	billboard.StudsOffset = Vector3.new(0, pH / 2 + 5, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 120
	billboard.Parent = portalEffect

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "PortalName"
	nameLabel.Size = UDim2.fromScale(1, 0.45)
	nameLabel.Position = UDim2.fromScale(0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = string.upper(string.gsub(portalName, "[^%w%s]", ""))
	nameLabel.TextColor3 = color
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.Parent = billboard

	local chevronLabel = Instance.new("TextLabel")
	chevronLabel.Name = "Chevrons"
	chevronLabel.Size = UDim2.fromScale(1, 0.22)
	chevronLabel.Position = UDim2.fromScale(0, 0.45)
	chevronLabel.BackgroundTransparency = 1
	chevronLabel.Text = `>>  {portalName}  <<`
	chevronLabel.TextColor3 = color
	chevronLabel.TextStrokeTransparency = 0
	chevronLabel.TextScaled = true
	chevronLabel.Font = Enum.Font.FredokaOne
	chevronLabel.Parent = billboard

	local subLabel = Instance.new("TextLabel")
	subLabel.Name = "Subtitle"
	subLabel.Size = UDim2.fromScale(1, 0.28)
	subLabel.Position = UDim2.fromScale(0, 0.7)
	subLabel.BackgroundTransparency = 1
	subLabel.Text = subtitle
	subLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	subLabel.TextStrokeTransparency = 0.3
	subLabel.TextScaled = true
	subLabel.Font = Enum.Font.GothamBold
	subLabel.Parent = billboard

	-- ─── Tag pour téléportation ───
	local tag = Instance.new("StringValue")
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
-- ═══════════════════════════════════════════════
-- 4. CHEMINS PAVÉS LUMINEUX
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildPaths(): ()
	local PATH_WIDTH: number = 7
	local PATH_SEGMENTS: number = 10

	for _, portalData in Constants.PORTALS do
		local angle: number = portalData.Angle
		local dist: number  = portalData.Distance
		local color: Color3 = portalData.Color

		for i = 1, PATH_SEGMENTS do
			local t: number = i / (PATH_SEGMENTS + 1)
			local segDist: number = Constants.FOUNTAIN_RADIUS + 6 + t * (dist - Constants.FOUNTAIN_RADIUS - 14)
			local pos: Vector3 = posFromAngle(angle, segDist, GROUND_Y + 0.3)

			local r = rad(angle)
			local lookDir = Vector3.new(math.cos(r), 0, math.sin(r))
			local segCF: CFrame = CFrame.lookAt(pos, pos + lookDir)

			createPart({
				Name = `Path_{portalData.Id}_{i}`,
				Size = Vector3.new(PATH_WIDTH, 0.4, (dist - Constants.FOUNTAIN_RADIUS - 12) / PATH_SEGMENTS - 0.3),
				CFrame = segCF,
				Material = Enum.Material.Cobblestone,
				Color = Color3.fromRGB(145, 135, 120),
			})

			-- Trait néon central tous les 2 segments
			if i % 2 == 0 then
				createPart({
					Name = `PathNeon_{portalData.Id}_{i}`,
					Size = Vector3.new(0.5, 0.15, (dist - Constants.FOUNTAIN_RADIUS - 12) / PATH_SEGMENTS - 0.5),
					CFrame = segCF * CFrame.new(0, 0.15, 0),
					Material = Enum.Material.Neon,
					Color = color,
					Transparency = 0.4,
					CanCollide = false,
				})
			end

			-- Lanternes rouges tous les 3 segments
			if i % 3 == 1 then
				for _, side in { -1, 1 } do
					local lanternPos = posFromAngle(angle, segDist, GROUND_Y)
					local perpX = -math.sin(r) * (PATH_WIDTH / 2 + 2) * side
					local perpZ = math.cos(r) * (PATH_WIDTH / 2 + 2) * side

					createPart({
						Name = `LanternPole_{portalData.Id}_{i}_{side}`,
						Size = Vector3.new(0.4, 6, 0.4),
						Position = lanternPos + Vector3.new(perpX, 3, perpZ),
						Material = Enum.Material.Metal,
						Color = COLOR_TORII_DARK,
					})

					local lantern = createPart({
						Name = `Lantern_{portalData.Id}_{i}_{side}`,
						Size = Vector3.new(1.8, 2.5, 1.8),
						Position = lanternPos + Vector3.new(perpX, 7, perpZ),
						Material = Enum.Material.Neon,
						Color = COLOR_TORII_RED,
						Transparency = 0.15,
						CanCollide = false,
					})

					local light = Instance.new("PointLight")
					light.Color = COLOR_LANTERN_WARM
					light.Brightness = 1.5
					light.Range = 14
					light.Parent = lantern
				end
			end
		end
	end

	print("[SpawnBuilder] ✅ Chemins pavés lumineux construits")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 5. ARBRES — Cerisiers en fleurs + Bambous
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildCherryTree(pos: Vector3, scale: number): ()
	createPart({
		Name = "CherryTrunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(10 * scale, 1.8 * scale, 1.8 * scale),
		CFrame = CFrame.new(pos + Vector3.new(0, 5 * scale, 0))
			* CFrame.Angles(0, 0, rad(90))
			* CFrame.Angles(0, rad(math.random(-15, 15)), 0),
		Material = Enum.Material.Wood,
		Color = COLOR_DARK_WOOD,
	})

	local canopyY = 10 * scale
	for j = 1, 4 do
		local offX = (math.random() - 0.5) * 6 * scale
		local offZ = (math.random() - 0.5) * 6 * scale
		local offY = (math.random() - 0.5) * 3 * scale
		local blobSize = (4 + math.random() * 4) * scale

		local blob = createPart({
			Name = `CherryBloom_{j}`,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(blobSize, blobSize * 0.7, blobSize),
			Position = pos + Vector3.new(offX, canopyY + offY, offZ),
			Material = Enum.Material.SmoothPlastic,
			Color = if math.random() > 0.4 then COLOR_CHERRY_PINK else COLOR_CHERRY_WHITE,
			CanCollide = false,
		})

		-- Pétales tombantes (1er blob uniquement)
		if j == 1 then
			local petals = Instance.new("ParticleEmitter")
			petals.Name = "FallingPetals"
			petals.Texture = "rbxassetid://241685484"
			petals.Color = ColorSequence.new(COLOR_CHERRY_PINK, COLOR_CHERRY_WHITE)
			petals.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.3),
				NumberSequenceKeypoint.new(1, 0.1),
			})
			petals.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.2),
				NumberSequenceKeypoint.new(1, 1),
			})
			petals.Lifetime = NumberRange.new(3, 6)
			petals.Rate = 8
			petals.Speed = NumberRange.new(1, 3)
			petals.SpreadAngle = Vector2.new(180, 180)
			petals.EmissionDirection = Enum.NormalId.Bottom
			petals.RotSpeed = NumberRange.new(-60, 60)
			petals.Parent = blob
		end
	end
end

local function buildBamboo(pos: Vector3, height: number): ()
	for j = 1, math.random(3, 5) do
		local offX = (math.random() - 0.5) * 3
		local offZ = (math.random() - 0.5) * 3
		local h = height * (0.7 + math.random() * 0.3)

		createPart({
			Name = `Bamboo_{j}`,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(h, 0.6, 0.6),
			CFrame = CFrame.new(pos + Vector3.new(offX, h / 2, offZ)) * CFrame.Angles(0, 0, rad(90)),
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(80, 170, 50),
		})

		createPart({
			Name = `BambooLeaf_{j}`,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(2, 3, 2),
			Position = pos + Vector3.new(offX, h + 1, offZ),
			Material = Enum.Material.Grass,
			Color = Color3.fromRGB(60, 150, 40),
			CanCollide = false,
		})
	end
end

local function buildAllTrees(): ()
	local cherryAngles = { 20, 50, 70, 110, 140, 160, 200, 230, 250, 290, 320, 340 }
	for _, a in cherryAngles do
		local dist = RADIUS * 0.35 + math.random() * RADIUS * 0.35
		buildCherryTree(posFromAngle(a, dist, GROUND_Y), 0.8 + math.random() * 0.6)
	end

	for i = 1, 16 do
		local a = math.random() * 360
		local dist = RADIUS * 0.65 + math.random() * RADIUS * 0.2
		buildCherryTree(posFromAngle(a, dist, GROUND_Y), 1.0 + math.random() * 0.8)
	end

	local bambooAngles = { 30, 60, 120, 150, 210, 240, 300, 330 }
	for _, a in bambooAngles do
		local dist = RADIUS * 0.25 + math.random() * RADIUS * 0.3
		buildBamboo(posFromAngle(a, dist, GROUND_Y), 12 + math.random() * 8)
	end

	print("[SpawnBuilder] ✅ Cerisiers & bambous placés")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 6. ZONE AFK — "Salle du Temps"
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildAFKZone(): ()
	local afkAngle = Constants.AFK_ZONE_ANGLE
	local afkDist  = Constants.AFK_ZONE_DISTANCE
	local afkR     = Constants.AFK_ZONE_RADIUS
	local afkCenter = posFromAngle(afkAngle, afkDist, GROUND_Y)

	-- Plateforme surélevée
	createPart({
		Name = "AFKPlatform",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2, afkR * 2, afkR * 2),
		CFrame = CFrame.new(afkCenter + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, rad(90)),
		Material = Enum.Material.Cobblestone,
		Color = COLOR_STONE,
	})

	-- Tapis néon
	local carpet = createPart({
		Name = "AFKCarpet",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, afkR * 2 - 4, afkR * 2 - 4),
		CFrame = CFrame.new(afkCenter + Vector3.new(0, 2.1, 0)) * CFrame.Angles(0, 0, rad(90)),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(60, 20, 120),
		Transparency = 0.6,
		CanCollide = false,
	})

	pingPongTween(carpet, 4, { Color = Color3.fromRGB(20, 60, 120) })

	-- Toit pagode miniature
	createPart({
		Name = "AFKRoof",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.5, afkR * 2 + 6, afkR * 2 + 6),
		CFrame = CFrame.new(afkCenter + Vector3.new(0, 14, 0)) * CFrame.Angles(0, 0, rad(90)),
		Material = Enum.Material.Wood,
		Color = COLOR_PAGODA_ROOF,
	})

	-- Piliers de soutien (4)
	for i = 1, 4 do
		local pRad = rad((i - 1) * 90)
		local px = afkCenter.X + math.cos(pRad) * (afkR - 2)
		local pz = afkCenter.Z + math.sin(pRad) * (afkR - 2)

		createPart({
			Name = `AFKPillar_{i}`,
			Size = Vector3.new(1.5, 12, 1.5),
			Position = Vector3.new(px, GROUND_Y + 8, pz),
			Material = Enum.Material.Wood,
			Color = COLOR_TORII_RED,
		})
	end

	-- Sièges gamer disposés en cercle
	local numSeats = Constants.AFK_SEATS
	for i = 1, numSeats do
		local seatAngle = (i / numSeats) * math.pi * 2
		local sx = afkCenter.X + math.cos(seatAngle) * (afkR - 6)
		local sz = afkCenter.Z + math.sin(seatAngle) * (afkR - 6)
		local seatPos = Vector3.new(sx, GROUND_Y + 2, sz)
		local seatCF = CFrame.lookAt(seatPos + Vector3.new(0, 0.5, 0), afkCenter + Vector3.new(0, 2.5, 0))

		-- Assise
		createPart({
			Name = `GamerSeat_{i}`,
			Size = Vector3.new(3, 0.5, 3),
			CFrame = seatCF,
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(30, 30, 35),
		})

		-- Dossier
		createPart({
			Name = `GamerBack_{i}`,
			Size = Vector3.new(3, 3, 0.5),
			CFrame = seatCF * CFrame.new(0, 1.5, -1.5),
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(30, 30, 35),
		})

		-- Bande RGB néon
		local rgbStrip = createPart({
			Name = `GamerRGB_{i}`,
			Size = Vector3.new(2.5, 0.3, 0.6),
			CFrame = seatCF * CFrame.new(0, 2.5, -1.5),
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 0, 100),
			Transparency = 0.2,
			CanCollide = false,
		})

		-- Animation couleur RGB
		task.spawn(function()
			local hue = (i / numSeats)
			while rgbStrip and rgbStrip.Parent do
				hue = (hue + 0.005) % 1
				rgbStrip.Color = Color3.fromHSV(hue, 0.8, 1)
				task.wait(0.05)
			end
		end)
	end

	-- ─── Panneau "SALLE DU TEMPS" ───
	local signPart = createPart({
		Name = "AFKSign",
		Size = Vector3.new(10, 4, 0.5),
		Position = afkCenter + Vector3.new(0, 16.5, 0),
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(20, 15, 30),
		CanCollide = false,
	})

	local signBB = Instance.new("BillboardGui")
	signBB.Name = "AFKLabel"
	signBB.Size = UDim2.fromOffset(350, 140)
	signBB.StudsOffset = Vector3.new(0, 1, 0)
	signBB.AlwaysOnTop = false
	signBB.MaxDistance = 80
	signBB.Parent = signPart

	local afkTitle = Instance.new("TextLabel")
	afkTitle.Size = UDim2.fromScale(1, 0.55)
	afkTitle.BackgroundTransparency = 1
	afkTitle.Text = "⏳ SALLE DU TEMPS"
	afkTitle.TextColor3 = Color3.fromRGB(180, 120, 255)
	afkTitle.TextStrokeTransparency = 0
	afkTitle.TextScaled = true
	afkTitle.Font = Enum.Font.FredokaOne
	afkTitle.Parent = signBB

	local afkSub = Instance.new("TextLabel")
	afkSub.Size = UDim2.fromScale(1, 0.4)
	afkSub.Position = UDim2.fromScale(0, 0.58)
	afkSub.BackgroundTransparency = 1
	afkSub.Text = `Reste ici pour gagner {Constants.AFK_REWARD_AMOUNT} 🧠/min`
	afkSub.TextColor3 = Color3.fromRGB(200, 200, 220)
	afkSub.TextStrokeTransparency = 0.3
	afkSub.TextScaled = true
	afkSub.Font = Enum.Font.GothamBold
	afkSub.Parent = signBB

	-- Zone de détection AFK (trigger invisible)
	local afkTrigger = createPart({
		Name = "AFKTrigger",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(12, afkR * 2, afkR * 2),
		CFrame = CFrame.new(afkCenter + Vector3.new(0, 8, 0)) * CFrame.Angles(0, 0, rad(90)),
		Transparency = 1,
		CanCollide = false,
	})

	local afkTag = Instance.new("StringValue")
	afkTag.Name = "ZoneType"
	afkTag.Value = "AFK"
	afkTag.Parent = afkTrigger

	print("[SpawnBuilder] ✅ Zone AFK 'Salle du Temps' construite")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 7. VITRINE — Hall of Fame
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildShowcase(): ()
	local scAngle = Constants.SHOWCASE_ANGLE
	local scDist  = Constants.SHOWCASE_DISTANCE
	local scLen   = Constants.SHOWCASE_LENGTH
	local scCenter = posFromAngle(scAngle, scDist, GROUND_Y)

	-- Plateforme
	createPart({
		Name = "ShowcasePlatform",
		Size = Vector3.new(scLen + 8, 1.5, 14),
		Position = scCenter + Vector3.new(0, 0.75, 0),
		Material = Enum.Material.Marble,
		Color = Color3.fromRGB(30, 25, 40),
	})

	-- Bordure néon
	createPart({
		Name = "ShowcasePlatformNeon",
		Size = Vector3.new(scLen + 9, 0.3, 15),
		Position = scCenter + Vector3.new(0, 1.65, 0),
		Material = Enum.Material.Neon,
		Color = COLOR_GOLD,
		Transparency = 0.5,
		CanCollide = false,
	})

	-- Mur de fond vitré
	createPart({
		Name = "ShowcaseBackWall",
		Size = Vector3.new(scLen + 6, 12, 0.5),
		Position = scCenter + Vector3.new(0, 7.5, -6),
		Material = Enum.Material.Glass,
		Color = Color3.fromRGB(15, 10, 25),
		Transparency = 0.3,
	})

	-- ─── Podiums pour chaque unité ───
	local units = Constants.SHOWCASE_UNITS
	local spacing = scLen / (#units + 1)

	for i, unitName in units do
		local podiumX = scCenter.X + (i - (#units + 1) / 2) * spacing
		local podiumPos = Vector3.new(podiumX, GROUND_Y + 1.5, scCenter.Z)

		createPart({
			Name = `Podium_{unitName}`,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(3, 5, 5),
			CFrame = CFrame.new(podiumPos + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, rad(90)),
			Material = Enum.Material.Marble,
			Color = Color3.fromRGB(50, 45, 60),
		})

		local podiumRing = createPart({
			Name = `PodiumRing_{unitName}`,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.3, 5.5, 5.5),
			CFrame = CFrame.new(podiumPos + Vector3.new(0, 3.1, 0)) * CFrame.Angles(0, 0, rad(90)),
			Material = Enum.Material.Neon,
			Color = COLOR_GOLD,
			Transparency = 0.4,
			CanCollide = false,
		})

		spinForever(podiumRing, "Y", 0.1)

		-- Placeholder (sphère en attendant le vrai modèle)
		local unitPlaceholder = createPart({
			Name = `UnitDisplay_{unitName}`,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(4, 4, 4),
			Position = podiumPos + Vector3.new(0, 5.5, 0),
			Material = Enum.Material.Neon,
			Color = if i == 1 then Color3.fromRGB(255, 80, 80)
				elseif i == 2 then Color3.fromRGB(100, 200, 255)
				else COLOR_GOLD,
			Transparency = 0.2,
			CanCollide = false,
		})

		pingPongTween(unitPlaceholder, 2, { Position = podiumPos + Vector3.new(0, 6.5, 0) })

		local unitBB = Instance.new("BillboardGui")
		unitBB.Size = UDim2.fromOffset(200, 60)
		unitBB.StudsOffset = Vector3.new(0, 4, 0)
		unitBB.AlwaysOnTop = false
		unitBB.MaxDistance = 60
		unitBB.Parent = unitPlaceholder

		local unitLbl = Instance.new("TextLabel")
		unitLbl.Size = UDim2.fromScale(1, 1)
		unitLbl.BackgroundTransparency = 1
		unitLbl.Text = unitName
		unitLbl.TextColor3 = COLOR_GOLD
		unitLbl.TextStrokeTransparency = 0
		unitLbl.TextScaled = true
		unitLbl.Font = Enum.Font.FredokaOne
		unitLbl.Parent = unitBB

		local shimmer = Instance.new("ParticleEmitter")
		shimmer.Texture = "rbxassetid://241685484"
		shimmer.Color = ColorSequence.new(COLOR_GOLD)
		shimmer.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.5), NumberSequenceKeypoint.new(1, 0) })
		shimmer.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
		shimmer.Lifetime = NumberRange.new(1, 2)
		shimmer.Rate = 10
		shimmer.Speed = NumberRange.new(2, 5)
		shimmer.EmissionDirection = Enum.NormalId.Top
		shimmer.Parent = unitPlaceholder
	end

	-- ─── Titre "HALL OF FAME" ───
	local famePart = createPart({
		Name = "HallOfFameSign",
		Size = Vector3.new(scLen, 4, 0.5),
		Position = scCenter + Vector3.new(0, 15, -6),
		Material = Enum.Material.Neon,
		Color = COLOR_GOLD,
		Transparency = 0.5,
		CanCollide = false,
	})

	local fameBB = Instance.new("BillboardGui")
	fameBB.Size = UDim2.fromOffset(500, 100)
	fameBB.AlwaysOnTop = false
	fameBB.MaxDistance = 100
	fameBB.Parent = famePart

	local fameLabel = Instance.new("TextLabel")
	fameLabel.Size = UDim2.fromScale(1, 1)
	fameLabel.BackgroundTransparency = 1
	fameLabel.Text = "🏆 HALL OF FAME 🏆"
	fameLabel.TextColor3 = COLOR_GOLD
	fameLabel.TextStrokeTransparency = 0
	fameLabel.TextScaled = true
	fameLabel.Font = Enum.Font.FredokaOne
	fameLabel.Parent = fameBB

	print("[SpawnBuilder] ✅ Vitrine Hall of Fame construite")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 8. LEADERBOARD PHYSIQUE
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildLeaderboard(): ()
	local lbAngle = Constants.LEADERBOARD_ANGLE
	local lbDist  = Constants.LEADERBOARD_DISTANCE
	local lbCenter = posFromAngle(lbAngle, lbDist, GROUND_Y)

	-- Écran géant
	local screen = createPart({
		Name = "LeaderboardScreen",
		Size = Vector3.new(16, 12, 1),
		Position = lbCenter + Vector3.new(0, 9, 0),
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(10, 8, 18),
	})

	-- Cadre néon
	for _, edge in {
		{ size = Vector3.new(16.5, 0.5, 1.2), offset = Vector3.new(0, 6.3, 0) },
		{ size = Vector3.new(16.5, 0.5, 1.2), offset = Vector3.new(0, -6.3, 0) },
		{ size = Vector3.new(0.5, 12.5, 1.2), offset = Vector3.new(8.3, 0, 0) },
		{ size = Vector3.new(0.5, 12.5, 1.2), offset = Vector3.new(-8.3, 0, 0) },
	} do
		createPart({
			Name = "LBFrameNeon",
			Size = edge.size,
			Position = lbCenter + Vector3.new(0, 9, 0) + edge.offset,
			Material = Enum.Material.Neon,
			Color = COLOR_NEON_CYAN,
			Transparency = 0.3,
			CanCollide = false,
		})
	end

	-- Supports
	for _, sx in { -5, 5 } do
		createPart({
			Name = "LBSupport",
			Size = Vector3.new(1, 10, 1),
			CFrame = CFrame.new(lbCenter + Vector3.new(sx, 4, 1.5)) * CFrame.Angles(rad(10), 0, 0),
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(50, 50, 55),
		})
	end

	-- SurfaceGui pour le leaderboard
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "LeaderboardGUI"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 30
	surfaceGui.Parent = screen

	local titleLB = Instance.new("TextLabel")
	titleLB.Size = UDim2.fromScale(1, 0.15)
	titleLB.BackgroundTransparency = 1
	titleLB.Text = "🏆 TOP DEFENDERS 🏆"
	titleLB.TextColor3 = COLOR_GOLD
	titleLB.TextScaled = true
	titleLB.Font = Enum.Font.FredokaOne
	titleLB.Parent = surfaceGui

	for rank = 1, 8 do
		local row = Instance.new("TextLabel")
		row.Size = UDim2.new(0.9, 0, 0.08, 0)
		row.Position = UDim2.new(0.05, 0, 0.15 + (rank - 1) * 0.1, 0)
		row.BackgroundTransparency = if rank <= 3 then 0.7 else 0.85
		row.BackgroundColor3 = if rank == 1 then COLOR_GOLD
			elseif rank == 2 then Color3.fromRGB(180, 180, 200)
			elseif rank == 3 then Color3.fromRGB(180, 120, 60)
			else Color3.fromRGB(40, 40, 50)
		row.Text = `  #{rank}  ···  Joueur{rank}  ···  {math.floor(1000 / rank)} pts`
		row.TextColor3 = Color3.new(1, 1, 1)
		row.TextScaled = true
		row.Font = Enum.Font.GothamBold
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Parent = surfaceGui

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 6)
		rowCorner.Parent = row
	end

	print("[SpawnBuilder] ✅ Leaderboard physique construit")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 9. DÉCORATION CENTRALE (Sol étoilé + anneaux)
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildCenterDecor(): ()
	local ring1 = createPart({
		Name = "CenterRing1",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, Constants.FOUNTAIN_RADIUS * 2 + 12, Constants.FOUNTAIN_RADIUS * 2 + 12),
		CFrame = CFrame.new(CENTER + Vector3.new(0, GROUND_Y + 0.5, 0)) * CFrame.Angles(0, 0, rad(90)),
		Material = Enum.Material.Neon,
		Color = COLOR_NEON_CYAN,
		Transparency = 0.4,
		CanCollide = false,
	})

	local ring2 = createPart({
		Name = "CenterRing2",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, Constants.FOUNTAIN_RADIUS * 2 + 18, Constants.FOUNTAIN_RADIUS * 2 + 18),
		CFrame = CFrame.new(CENTER + Vector3.new(0, GROUND_Y + 0.45, 0)) * CFrame.Angles(0, 0, rad(90)),
		Material = Enum.Material.Neon,
		Color = COLOR_NEON_PINK,
		Transparency = 0.6,
		CanCollide = false,
	})

	pingPongTween(ring1, 3, { Transparency = 0.7 })
	pingPongTween(ring2, 4, { Transparency = 0.85 })

	for i = 1, 8 do
		local angle = (i / 8) * 360
		local r = rad(angle)
		local length = Constants.FOUNTAIN_RADIUS + 10
		local midDist = Constants.FOUNTAIN_RADIUS / 2 + 5
		local pos = CENTER + Vector3.new(
			math.cos(r) * midDist,
			GROUND_Y + 0.4,
			math.sin(r) * midDist
		)

		createPart({
			Name = `StarBranch_{i}`,
			Size = Vector3.new(length, 0.15, 0.6),
			CFrame = CFrame.lookAt(pos, pos + Vector3.new(math.cos(r), 0, math.sin(r))),
			Material = Enum.Material.Neon,
			Color = COLOR_NEON_CYAN,
			Transparency = 0.5,
			CanCollide = false,
		})
	end

	print("[SpawnBuilder] ✅ Décoration centrale construite")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 10. LAMPADAIRES TORII (bordure de l'île)
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildLampposts(): ()
	local numLamps: number = 24
	for i = 1, numLamps do
		local angle: number = (i / numLamps) * 360
		local pos: Vector3 = posFromAngle(angle, RADIUS - 10, GROUND_Y)

		createPart({
			Name = `Lamppost_{i}`,
			Size = Vector3.new(0.8, 8, 0.8),
			Position = pos + Vector3.new(0, 4, 0),
			Material = Enum.Material.Wood,
			Color = COLOR_TORII_RED,
		})

		createPart({
			Name = `LampCross_{i}`,
			Size = Vector3.new(3, 0.5, 0.5),
			Position = pos + Vector3.new(0, 8.5, 0),
			Material = Enum.Material.Wood,
			Color = COLOR_TORII_DARK,
		})

		local lantern = createPart({
			Name = `LampLantern_{i}`,
			Size = Vector3.new(1.5, 2, 1.5),
			Position = pos + Vector3.new(0, 9.5, 0),
			Material = Enum.Material.Neon,
			Color = COLOR_LANTERN_WARM,
			Transparency = 0.15,
			CanCollide = false,
		})

		local light = Instance.new("PointLight")
		light.Color = COLOR_LANTERN_WARM
		light.Brightness = 2
		light.Range = 18
		light.Parent = lantern
	end

	print("[SpawnBuilder] ✅ Lanternes Torii placées")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 11. NUAGES + ROCHERS FLOTTANTS
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildClouds(): ()
	for i = 1, 14 do
		local cloudX = CENTER.X + math.random(-220, 220)
		local cloudY = 80 + math.random(0, 60)
		local cloudZ = CENTER.Z + math.random(-220, 220)

		for j = 1, math.random(3, 6) do
			local ox = (j - 1) * math.random(4, 8) * (if math.random() > 0.5 then 1 else -1)
			local oz = math.random(-4, 4)
			local sz = math.random(10, 20)

			createPart({
				Name = `Cloud_{i}_{j}`,
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(sz, sz * 0.4, sz),
				Position = Vector3.new(cloudX + ox, cloudY, cloudZ + oz),
				Material = Enum.Material.SmoothPlastic,
				Color = Color3.fromRGB(240, 235, 245),
				Transparency = 0.15,
				CanCollide = false,
				CastShadow = false,
			})
		end
	end

	-- Rochers flottants mystiques
	for i = 1, 5 do
		local fAngle = math.random() * 360
		local fDist  = RADIUS * 0.8 + math.random() * 50
		local fY     = 40 + math.random() * 30
		local fPos   = posFromAngle(fAngle, fDist, fY)
		local fSize  = 6 + math.random() * 10

		local floatingRock = createPart({
			Name = `FloatingRock_{i}`,
			Size = Vector3.new(fSize * 1.3, fSize * 0.8, fSize),
			Position = fPos,
			Material = Enum.Material.Slate,
			Color = Color3.fromRGB(80 + math.random(0,30), 75 + math.random(0,25), 70 + math.random(0,20)),
			CanCollide = false,
		})

		pingPongTween(floatingRock, 4 + math.random() * 3, {
			Position = fPos + Vector3.new(0, 3 + math.random() * 2, 0),
		})

		createPart({
			Name = `FloatingGrass_{i}`,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1, fSize * 0.8, fSize * 0.8),
			CFrame = CFrame.new(fPos + Vector3.new(0, fSize * 0.4 + 0.3, 0)) * CFrame.Angles(0, 0, rad(90)),
			Material = Enum.Material.Grass,
			Color = COLOR_GRASS,
			CanCollide = false,
		})
	end

	print("[SpawnBuilder] ✅ Nuages & rochers flottants placés")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 12. PAGODES DÉCORATIVES
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildMiniPagoda(pos: Vector3, roofColor: Color3, scale: number): ()
	local s = scale

	createPart({
		Name = "PagodaBase",
		Size = Vector3.new(8 * s, 1, 8 * s),
		Position = pos + Vector3.new(0, 0.5, 0),
		Material = Enum.Material.Cobblestone,
		Color = COLOR_STONE,
	})

	for floor = 1, 3 do
		local floorW = (8 - floor * 1.5) * s
		local floorH = 4 * s
		local floorY = 1 + (floor - 1) * (floorH + 1)

		createPart({
			Name = `PagodaFloor_{floor}`,
			Size = Vector3.new(floorW, floorH, floorW),
			Position = pos + Vector3.new(0, floorY + floorH / 2, 0),
			Material = Enum.Material.Wood,
			Color = COLOR_DARK_WOOD,
		})

		createPart({
			Name = `PagodaRoof_{floor}`,
			Size = Vector3.new(floorW + 3 * s, 0.8, floorW + 3 * s),
			Position = pos + Vector3.new(0, floorY + floorH + 0.4, 0),
			Material = Enum.Material.SmoothPlastic,
			Color = roofColor,
		})

		createPart({
			Name = `PagodaRoofNeon_{floor}`,
			Size = Vector3.new(floorW + 3.5 * s, 0.2, floorW + 3.5 * s),
			Position = pos + Vector3.new(0, floorY + floorH + 0.9, 0),
			Material = Enum.Material.Neon,
			Color = COLOR_GOLD,
			Transparency = 0.5,
			CanCollide = false,
		})
	end

	local topOrb = createPart({
		Name = "PagodaTopOrb",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2 * s, 2 * s, 2 * s),
		Position = pos + Vector3.new(0, 18 * s, 0),
		Material = Enum.Material.Neon,
		Color = COLOR_GOLD,
		Transparency = 0.2,
		CanCollide = false,
	})

	local topLight = Instance.new("PointLight")
	topLight.Color = COLOR_LANTERN_WARM
	topLight.Brightness = 3
	topLight.Range = 25
	topLight.Parent = topOrb
end

local function buildAllPagodas(): ()
	local pagodaData = {
		{ angle = 135, dist = RADIUS - 20, color = COLOR_TORII_RED, scale = 1.0 },
		{ angle = 315, dist = RADIUS - 25, color = COLOR_PAGODA_ROOF, scale = 0.8 },
		{ angle = 60,  dist = RADIUS - 15, color = COLOR_TORII_DARK, scale = 0.7 },
		{ angle = 240, dist = RADIUS - 18, color = Color3.fromRGB(40, 50, 120), scale = 0.9 },
	}

	for _, pd in pagodaData do
		buildMiniPagoda(posFromAngle(pd.angle, pd.dist, GROUND_Y), pd.color, pd.scale)
	end

	print("[SpawnBuilder] ✅ Pagodes décoratives construites")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 13. PONT COURBÉ
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildBridge(): ()
	local bridgeStart = posFromAngle(145, 45, GROUND_Y)
	local bridgeEnd   = posFromAngle(215, 45, GROUND_Y)
	local segments = 12

	for i = 0, segments do
		local t = i / segments
		local pos = bridgeStart:Lerp(bridgeEnd, t)
		local archY = math.sin(t * math.pi) * 5

		createPart({
			Name = `BridgeSeg_{i}`,
			Size = Vector3.new(5, 0.6, (bridgeEnd - bridgeStart).Magnitude / segments + 0.2),
			CFrame = CFrame.lookAt(
				pos + Vector3.new(0, archY + 1, 0),
				bridgeEnd + Vector3.new(0, archY, 0)
			),
			Material = Enum.Material.Wood,
			Color = COLOR_TORII_RED,
		})
	end

	for _, side in { -2.5, 2.5 } do
		for i = 0, segments, 3 do
			local t = i / segments
			local pos = bridgeStart:Lerp(bridgeEnd, t)
			local archY = math.sin(t * math.pi) * 5

			createPart({
				Name = `BridgeRail_{i}_{side}`,
				Size = Vector3.new(0.3, 2, 0.3),
				Position = pos + Vector3.new(side, archY + 2.5, 0),
				Material = Enum.Material.Wood,
				Color = COLOR_TORII_DARK,
			})
		end
	end

	print("[SpawnBuilder] ✅ Pont courbé construit")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 14. ÉTANGS
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildPonds(): ()
	local pondData = {
		{ angle = 160, dist = 0.35, radius = 10 },
		{ angle = 280, dist = 0.4,  radius = 7  },
	}

	for _, p in pondData do
		local pos = posFromAngle(p.angle, RADIUS * p.dist, GROUND_Y)

		createPart({
			Name = "Pond",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.5, p.radius * 2, p.radius * 2),
			CFrame = CFrame.new(pos + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, rad(90)),
			Material = Enum.Material.Glass,
			Color = COLOR_WATER,
			Transparency = 0.3,
			CanCollide = false,
		})

		createPart({
			Name = "PondBorder",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.8, p.radius * 2 + 2, p.radius * 2 + 2),
			CFrame = CFrame.new(pos + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, rad(90)),
			Material = Enum.Material.Slate,
			Color = COLOR_STONE_DARK,
			CanCollide = false,
		})

		for i = 1, math.random(3, 6) do
			local la = math.random() * 360
			local ld = math.random() * (p.radius - 2)
			local lr = rad(la)

			createPart({
				Name = `LilyPad_{i}`,
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.15, 1.5, 1.5),
				CFrame = CFrame.new(pos + Vector3.new(math.cos(lr) * ld, 0.5, math.sin(lr) * ld)) * CFrame.Angles(0, 0, rad(90)),
				Material = Enum.Material.Grass,
				Color = Color3.fromRGB(50, 160, 50),
				CanCollide = false,
			})
		end
	end

	print("[SpawnBuilder] ✅ Étangs construits")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 15. ROCHERS
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildRocks(): ()
	for i = 1, 8 do
		local rAngle = math.random() * 360
		local rDist = RADIUS * 0.55 + math.random() * RADIUS * 0.3
		local pos = posFromAngle(rAngle, rDist, GROUND_Y)

		for j = 1, math.random(2, 5) do
			local ox = (math.random() - 0.5) * 4
			local oz = (math.random() - 0.5) * 4
			local rs = 1 + math.random() * 3

			createPart({
				Name = `Rock_{i}_{j}`,
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(rs * 1.3, rs * 0.7, rs),
				Position = pos + Vector3.new(ox, rs * 0.3, oz),
				Material = Enum.Material.Slate,
				Color = Color3.fromRGB(85 + math.random(0,30), 80 + math.random(0,25), 75 + math.random(0,20)),
			})
		end
	end

	print("[SpawnBuilder] ✅ Rochers placés")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 16. GUIRLANDES FESTIVAL
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildFairyLights(): ()
	local numArcs = 20
	for i = 1, numArcs do
		local angle1 = (i / numArcs) * 360
		local angle2 = ((i + 1) / numArcs) * 360
		local pos1 = posFromAngle(angle1, RADIUS * 0.5, GROUND_Y + 9)
		local pos2 = posFromAngle(angle2, RADIUS * 0.5, GROUND_Y + 9)

		for j = 1, 4 do
			local t = j / 5
			local mid = pos1:Lerp(pos2, t)
			local sag = math.sin(t * math.pi) * 2.5

			local bulb = createPart({
				Name = `FairyLight_{i}_{j}`,
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(0.7, 0.7, 0.7),
				Position = mid + Vector3.new(0, -sag, 0),
				Material = Enum.Material.Neon,
				Color = if j % 2 == 0 then COLOR_LANTERN_WARM else COLOR_TORII_RED,
				Transparency = 0.1,
				CanCollide = false,
			})

			if j == 2 then
				local bl = Instance.new("PointLight")
				bl.Color = COLOR_LANTERN_WARM
				bl.Brightness = 0.5
				bl.Range = 6
				bl.Parent = bulb
			end
		end
	end

	print("[SpawnBuilder] ✅ Guirlandes festival placées")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 17. SPAWN LOCATION
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildSpawnLocation(): ()
	local spawn: SpawnLocation = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = CENTER + Vector3.new(0, GROUND_Y + 0.5, 15)
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
-- ═══════════════════════════════════════════════
-- 18. ÉCLAIRAGE — Crépuscule fantastique + Skybox
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function setupLighting(): ()
	-- Crépuscule doré/violet (comme l'image de ref)
	Lighting.ClockTime = 17.8
	Lighting.Brightness = 2.5
	Lighting.Ambient = Color3.fromRGB(90, 70, 110)
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 120, 160)
	Lighting.FogEnd = 1000
	Lighting.FogColor = Color3.fromRGB(70, 50, 90)
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.4
	Lighting.GeographicLatitude = 20

	-- Nettoyer les effets existants
	for _, child in Lighting:GetChildren() do
		if child:IsA("Atmosphere") or child:IsA("BloomEffect") or child:IsA("ColorCorrectionEffect")
			or child:IsA("SunRaysEffect") or child:IsA("DepthOfFieldEffect") then
			child:Destroy()
		end
	end

	-- ─── Atmosphere (brume fantastique violette) ───
	local atmo = Instance.new("Atmosphere")
	atmo.Density = 0.3
	atmo.Offset = 0.15
	atmo.Color = Color3.fromRGB(160, 130, 200)
	atmo.Decay = Color3.fromRGB(120, 90, 150)
	atmo.Glare = 0.4
	atmo.Haze = 1.5
	atmo.Parent = Lighting

	-- ─── Bloom (néons bien visibles) ───
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.6
	bloom.Size = 30
	bloom.Threshold = 0.75
	bloom.Parent = Lighting

	-- ─── ColorCorrection (teinte chaude/violette) ───
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.06
	cc.Contrast = 0.12
	cc.Saturation = 0.35
	cc.TintColor = Color3.fromRGB(235, 220, 255)
	cc.Parent = Lighting

	-- ─── SunRays ───
	local sunRays = Instance.new("SunRaysEffect")
	sunRays.Intensity = 0.06
	sunRays.Spread = 0.8
	sunRays.Parent = Lighting

	-- ─── Skybox ───
	local existingSky = Lighting:FindFirstChildOfClass("Sky")
	if existingSky then existingSky:Destroy() end

	local sky = Instance.new("Sky")
	sky.CelestialBodiesShown = true
	sky.StarCount = 1500
	sky.MoonAngularSize = 14
	sky.SunAngularSize = 18
	-- IDs publics — remplacer par tes propres assets si nécessaire
	sky.SkyboxBk = "rbxassetid://1012890"
	sky.SkyboxDn = "rbxassetid://1012891"
	sky.SkyboxFt = "rbxassetid://1012887"
	sky.SkyboxLf = "rbxassetid://1012889"
	sky.SkyboxRt = "rbxassetid://1012888"
	sky.SkyboxUp = "rbxassetid://1012890"
	sky.Parent = Lighting

	print("[SpawnBuilder] ✅ Éclairage crépuscule fantastique configuré")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- CONSTRUCTION SÉQUENTIELLE
-- ═══════════════════════════════════════════════
-------------------------------------------------
print("══════════════════════════════════════")
print("[SpawnBuilder] 🏯 Construction du Brainrot Shrine Hub...")
print("══════════════════════════════════════")

buildIsland()
buildCentralStatue()
buildCenterDecor()
buildAllPortals()
buildPaths()
buildAFKZone()
buildShowcase()
buildLeaderboard()
buildAllTrees()
buildAllPagodas()
buildBridge()
buildPonds()
buildRocks()
buildClouds()
buildLampposts()
buildFairyLights()
buildSpawnLocation()
setupLighting()

print("══════════════════════════════════════")
print("[SpawnBuilder] 🏯 BRAINROT SHRINE HUB — COMPLETE !")
print("══════════════════════════════════════")
