--!strict

--[[
	SpawnBuilder (ServerScript) — v3.0 "L'Arche du Néant"
	=====================================================
	Génère le Spawn Hub « Void Sanctum » pour Brainrot Defense.

	DA : Fragment de réalité arraché au tissu de l'espace-temps, suspendu
	dans un vide cosmique infini. Sol d'obsidienne fracturée, veines néon,
	monument armillaire central, portails = fractures dimensionnelles.

	Squelette technique respecté :
	  • Centre : Constants.SPAWN_CENTER  (0, 0, 500)
	  • Rayon : Constants.SPAWN_RADIUS   (150 studs)
	  • Portails à 120 studs, angles 0/90/180/270
	  • Monument central rayon 14, effets visuels hauteur 25
	  • Zone AFK, Vitrine, Leaderboard aux positions Constants
	  • PortalSystem attend : Model "Portal_{Id}" > Part "PortalEffect"
]]

-- Services
local Workspace: Workspace = game:GetService("Workspace")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Modules
local sharedFolder: Instance = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(sharedFolder:WaitForChild("Constants"))

-------------------------------------------------
-- Constantes locales
-------------------------------------------------
local CENTER: Vector3 = Constants.SPAWN_CENTER
local RADIUS: number  = Constants.SPAWN_RADIUS
local GROUND_Y: number = Constants.SPAWN_GROUND_Y

-- ═════ PALETTE "VOID SANCTUM" ═════
local VOID_BLACK       = Color3.fromRGB(6, 4, 12)
local OBSIDIAN         = Color3.fromRGB(18, 14, 28)
local OBSIDIAN_LIGHT   = Color3.fromRGB(30, 24, 45)
local BASALT_DARK      = Color3.fromRGB(25, 22, 35)
local CRYSTAL_DARK     = Color3.fromRGB(20, 15, 40)
local CRYSTAL_PURPLE   = Color3.fromRGB(90, 40, 180)
local NEON_VIOLET      = Color3.fromRGB(160, 60, 255)
local NEON_CYAN        = Color3.fromRGB(0, 220, 255)
local NEON_MAGENTA     = Color3.fromRGB(255, 30, 180)
local NEON_WHITE       = Color3.fromRGB(220, 210, 255)
local ENERGY_CORE      = Color3.fromRGB(180, 120, 255)
local ENERGY_HOT       = Color3.fromRGB(255, 180, 255)
local GOLD_ACCENT      = Color3.fromRGB(255, 200, 50)
local NEBULA_BLUE      = Color3.fromRGB(20, 40, 120)
local NEBULA_PURPLE    = Color3.fromRGB(60, 15, 100)
local NEBULA_PINK      = Color3.fromRGB(100, 20, 60)

-------------------------------------------------
-- Dossier conteneur
-------------------------------------------------
local existingHub = Workspace:FindFirstChild("SpawnHub")
if existingHub then existingHub:Destroy() end

local hub: Folder = Instance.new("Folder")
hub.Name = "SpawnHub"
hub.Parent = Workspace

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
	part.CastShadow = if props.CastShadow ~= nil then props.CastShadow else true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		if key ~= "CanCollide" and key ~= "Parent" and key ~= "CastShadow" then
			(part :: any)[key] = value
		end
	end
	part.Parent = props.Parent or hub
	return part
end

--- Tween ping-pong infini (respiration)
local function breathe(inst: Instance, dur: number, goals: { [string]: any }): ()
	local info = TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	TweenService:Create(inst, info, goals):Play()
end

--- Rotation continue sur un axe via RunService (ultra-fluide)
local function spinForever(part: BasePart, axisVec: Vector3, rps: number): ()
	task.spawn(function()
		local conn: RBXScriptConnection?
		conn = RunService.Heartbeat:Connect(function(dt: number)
			if not part or not part.Parent then
				if conn then conn:Disconnect() end
				return
			end
			part.CFrame = part.CFrame * CFrame.fromAxisAngle(axisVec, math.pi * 2 * rps * dt)
		end)
	end)
end

--- Création rapide d'un PointLight
local function addLight(parent: Instance, color: Color3, brightness: number, range: number): PointLight
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness
	light.Range = range
	light.Shadows = false
	light.Parent = parent
	return light
end

--- Création d'un ParticleEmitter
local function addParticles(parent: Instance, props: { [string]: any }): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = props.Texture or "rbxassetid://241685484"
	emitter.Color = props.Color or ColorSequence.new(NEON_VIOLET)
	emitter.Size = props.Size or NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = props.Transparency or NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = props.Lifetime or NumberRange.new(1, 3)
	emitter.Rate = props.Rate or 20
	emitter.Speed = props.Speed or NumberRange.new(3, 8)
	emitter.SpreadAngle = props.SpreadAngle or Vector2.new(20, 20)
	emitter.EmissionDirection = props.EmissionDirection or Enum.NormalId.Top
	emitter.RotSpeed = props.RotSpeed or NumberRange.new(-45, 45)
	emitter.LightInfluence = 0.2
	emitter.LightEmission = 0.8
	if props.Name then emitter.Name = props.Name end
	emitter.Parent = parent
	return emitter
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 1. L'ÎLE FRACTURÉE — Plateforme d'obsidienne
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildVoidIsland(): ()
	-- Sol principal : disque d'obsidienne/basalt
	createPart({
		Name = "VoidPlatform",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(4, RADIUS * 2, RADIUS * 2),
		CFrame = CFrame.new(CENTER + Vector3.new(0, GROUND_Y - 1.5, 0)) * CFrame.Angles(0, 0, rad(90)),
		Material = Enum.Material.Basalt,
		Color = BASALT_DARK,
	})

	-- Couche supérieure (surface de marche)
	createPart({
		Name = "VoidSurface",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1, RADIUS * 2 - 2, RADIUS * 2 - 2),
		CFrame = CFrame.new(CENTER + Vector3.new(0, GROUND_Y, 0)) * CFrame.Angles(0, 0, rad(90)),
		Material = Enum.Material.Slate,
		Color = OBSIDIAN,
	})

	-- Sous-sol arraché (profondeur abyssale)
	createPart({
		Name = "VoidUnderbelly",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(30, RADIUS * 2 - 20, RADIUS * 2 - 20),
		CFrame = CFrame.new(CENTER + Vector3.new(0, -17, 0)) * CFrame.Angles(0, 0, rad(90)),
		Material = Enum.Material.Basalt,
		Color = Color3.fromRGB(12, 10, 20),
		CanCollide = false,
	})

	-- Stalactites inversées sous l'île
	for i = 1, 5 do
		local a = (i / 5) * 360 + math.random(-15, 15)
		local d = math.random(20, 80)
		local pos = posFromAngle(a, d, -5)
		local height = 15 + math.random() * 25

		createPart({
			Name = `Stalactite_{i}`,
			Size = Vector3.new(3 + math.random() * 4, height, 3 + math.random() * 4),
			CFrame = CFrame.new(pos + Vector3.new(0, -height / 2, 0))
				* CFrame.Angles(rad(math.random(-8, 8)), rad(math.random(0, 360)), rad(math.random(-8, 8))),
			Material = Enum.Material.Basalt,
			Color = BASALT_DARK,
			CanCollide = false,
		})
	end

	-- Veines de fracture concentriques (anneaux lumineux au sol)
	local crackRadii = { 20, 40, 65, 95, 130 }
	local crackColors = { NEON_VIOLET, NEON_CYAN, NEON_VIOLET, NEON_MAGENTA, NEON_VIOLET }
	for idx, cr in crackRadii do
		local vein = createPart({
			Name = `FractureRing_{idx}`,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.15, cr * 2, cr * 2),
			CFrame = CFrame.new(CENTER + Vector3.new(0, GROUND_Y + 0.15, 0)) * CFrame.Angles(0, 0, rad(90)),
			Material = Enum.Material.Neon,
			Color = crackColors[idx],
			Transparency = 0.4,
			CanCollide = false,
			CastShadow = false,
		})
		breathe(vein, 3 + idx * 0.7, { Transparency = 0.75 })
	end

	-- Veines radiales (8 branches étoilées)
	for i = 1, 8 do
		local angle = (i / 8) * 360
		local r = rad(angle)
		local length = RADIUS - 20
		local midDist = length / 2
		local pos = CENTER + Vector3.new(math.cos(r) * midDist, GROUND_Y + 0.13, math.sin(r) * midDist)

		local vein = createPart({
			Name = `RadialVein_{i}`,
			Size = Vector3.new(length, 0.08, 0.4),
			CFrame = CFrame.lookAt(pos, pos + Vector3.new(math.cos(r), 0, math.sin(r))),
			Material = Enum.Material.Neon,
			Color = if i % 2 == 0 then NEON_CYAN else NEON_VIOLET,
			Transparency = 0.5,
			CanCollide = false,
			CastShadow = false,
		})
		breathe(vein, 2.5 + (i % 3) * 0.5, { Transparency = 0.8 })
	end

	-- Fragments brisés flottants autour du bord
	for i = 1, 28 do
		local angle = (i / 28) * 360 + math.random(-5, 5)
		local dist = RADIUS - 5 + math.random() * 15
		local yOff = -2 + math.random() * 5
		local fragSize = 3 + math.random() * 8

		local frag = createPart({
			Name = `EdgeFragment_{i}`,
			Size = Vector3.new(fragSize * 0.8, fragSize * 0.4, fragSize),
			CFrame = CFrame.new(posFromAngle(angle, dist, GROUND_Y + yOff))
				* CFrame.Angles(rad(math.random(-25, 25)), rad(math.random(0, 360)), rad(math.random(-25, 25))),
			Material = Enum.Material.Basalt,
			Color = if math.random() > 0.6 then OBSIDIAN_LIGHT else BASALT_DARK,
			CanCollide = false,
			CastShadow = false,
		})

		breathe(frag, 4 + math.random() * 4, {
			CFrame = frag.CFrame + Vector3.new(0, 1.5 + math.random() * 2, 0),
		})
	end

	-- Aura néon sous l'île
	local underglow = createPart({
		Name = "UnderlightGlow",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2, RADIUS * 1.5, RADIUS * 1.5),
		CFrame = CFrame.new(CENTER + Vector3.new(0, -4, 0)) * CFrame.Angles(0, 0, rad(90)),
		Material = Enum.Material.Neon,
		Color = NEON_VIOLET,
		Transparency = 0.85,
		CanCollide = false,
		CastShadow = false,
	})
	breathe(underglow, 5, { Transparency = 0.93 })
	addLight(underglow, NEON_VIOLET, 2, 80)

	-- Plaza centrale (zone autour du monument)
	local plazaRadius = Constants.FOUNTAIN_RADIUS + 10
	createPart({
		Name = "CenterPlaza",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, plazaRadius * 2, plazaRadius * 2),
		CFrame = CFrame.new(CENTER + Vector3.new(0, GROUND_Y + 0.05, 0)) * CFrame.Angles(0, 0, rad(90)),
		Material = Enum.Material.DiamondPlate,
		Color = OBSIDIAN_LIGHT,
	})

	print("[SpawnBuilder] ✅ Île fracturée du Void construite")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 2. LE CŒUR DU BRAINROT — Monument central
--    Sphère armillaire cosmique (rayon 14, FX h=25)
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildBrainrotCore(): ()
	local fRadius: number = Constants.FOUNTAIN_RADIUS
	local fxHeight: number = Constants.FOUNTAIN_JET_HEIGHT
	local pedestalH: number = Constants.STATUE_PEDESTAL_H
	local baseY = GROUND_Y

	-- Marches hexagonales (3 niveaux)
	for step = 1, 3 do
		local stepR = fRadius - (step - 1) * 2
		local stepH = step * 0.5
		createPart({
			Name = `CoreStep_{step}`,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(stepH, stepR * 2, stepR * 2),
			CFrame = CFrame.new(CENTER + Vector3.new(0, baseY + stepH / 2, 0)) * CFrame.Angles(0, 0, rad(90)),
			Material = Enum.Material.DiamondPlate,
			Color = OBSIDIAN,
		})
	end

	-- Obélisque principal (pilier d'obsidienne fissuré)
	local obeliskH = 12
	local obeliskBase = baseY + 1.5

	createPart({
		Name = "CoreObelisk",
		Size = Vector3.new(4, obeliskH, 4),
		CFrame = CFrame.new(CENTER + Vector3.new(0, obeliskBase + obeliskH / 2, 0)),
		Material = Enum.Material.DiamondPlate,
		Color = OBSIDIAN,
	})

	-- Fissures lumineuses sur l'obélisque (4 faces)
	for i = 1, 4 do
		local faceAngle = (i - 1) * 90
		local r = rad(faceAngle)
		local crackPos = CENTER + Vector3.new(
			math.cos(r) * 2.1,
			obeliskBase + obeliskH * 0.3 + (i % 2) * 3,
			math.sin(r) * 2.1
		)

		local crack = createPart({
			Name = `ObeliskCrack_{i}`,
			Size = Vector3.new(0.15, obeliskH * 0.6, 1.5),
			CFrame = CFrame.lookAt(crackPos, crackPos + Vector3.new(math.cos(r), 0, math.sin(r))),
			Material = Enum.Material.Neon,
			Color = ENERGY_CORE,
			Transparency = 0.15,
			CanCollide = false,
			CastShadow = false,
		})
		breathe(crack, 1.5 + i * 0.3, { Transparency = 0.5 })
	end

	-- ═══ LE NOYAU — Sphère d'énergie pure ═══
	local coreY = obeliskBase + obeliskH + 4
	local coreSize = 6

	local coreSphere = createPart({
		Name = "BrainrotCore",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(coreSize, coreSize, coreSize),
		Position = CENTER + Vector3.new(0, coreY, 0),
		Material = Enum.Material.Neon,
		Color = ENERGY_CORE,
		Transparency = 0.1,
		CanCollide = false,
		CastShadow = false,
	})

	-- Pulsation du noyau (respiration)
	breathe(coreSphere, 2, {
		Size = Vector3.new(coreSize * 1.2, coreSize * 1.2, coreSize * 1.2),
		Transparency = 0.25,
	})

	addLight(coreSphere, ENERGY_CORE, 8, 80)

	-- Halo ForceField autour du noyau
	local halo = createPart({
		Name = "CoreHalo",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(coreSize + 3, coreSize + 3, coreSize + 3),
		Position = CENTER + Vector3.new(0, coreY, 0),
		Material = Enum.Material.ForceField,
		Color = ENERGY_HOT,
		Transparency = 0.7,
		CanCollide = false,
		CastShadow = false,
	})
	breathe(halo, 2.5, {
		Size = Vector3.new(coreSize + 5, coreSize + 5, coreSize + 5),
		Transparency = 0.85,
	})

	-- ═══ ANNEAUX ARMILLAIRES (3 orbites à axes différents) ═══
	local ringData = {
		{ radius = 8,  thickness = 0.5,  color = NEON_CYAN,    axis = Vector3.new(0, 1, 0), rps = 0.08,  tiltX = 0,  tiltZ = 0  },
		{ radius = 10, thickness = 0.4,  color = NEON_VIOLET,  axis = Vector3.new(1, 0, 0), rps = -0.05, tiltX = 70, tiltZ = 0  },
		{ radius = 12, thickness = 0.35, color = NEON_MAGENTA, axis = Vector3.new(0, 0, 1), rps = 0.03,  tiltX = 0,  tiltZ = 55 },
	}

	for idx, rd in ringData do
		local ring = createPart({
			Name = `ArmillaryRing_{idx}`,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(rd.thickness, rd.radius * 2, rd.radius * 2),
			CFrame = CFrame.new(CENTER + Vector3.new(0, coreY, 0))
				* CFrame.Angles(rad(rd.tiltX), 0, rad(rd.tiltZ))
				* CFrame.Angles(0, 0, rad(90)),
			Material = Enum.Material.Neon,
			Color = rd.color,
			Transparency = 0.25,
			CanCollide = false,
			CastShadow = false,
		})

		spinForever(ring, rd.axis, rd.rps)
	end

	-- Pilier de lumière vertical (faisceau montant du noyau)
	local beam = createPart({
		Name = "CoreBeam",
		Size = Vector3.new(1.5, fxHeight, 1.5),
		CFrame = CFrame.new(CENTER + Vector3.new(0, coreY + fxHeight / 2, 0)),
		Material = Enum.Material.Neon,
		Color = ENERGY_CORE,
		Transparency = 0.6,
		CanCollide = false,
		CastShadow = false,
	})
	breathe(beam, 3, { Transparency = 0.8, Size = Vector3.new(2, fxHeight, 2) })

	-- Faisceau bas (sous le noyau → obélisque)
	createPart({
		Name = "CoreBeamDown",
		Size = Vector3.new(1, 4, 1),
		CFrame = CFrame.new(CENTER + Vector3.new(0, coreY - coreSize / 2 - 2, 0)),
		Material = Enum.Material.Neon,
		Color = ENERGY_CORE,
		Transparency = 0.4,
		CanCollide = false,
		CastShadow = false,
	})

	-- Fragments cristallins en orbite autour du noyau
	for i = 1, 8 do
		local fragAngle = (i / 8) * 360
		local fragDist = 5 + (i % 3) * 2
		local fragY = coreY + (math.random() - 0.5) * 6
		local fragSize = 0.8 + math.random() * 1.5

		local crystal = createPart({
			Name = `CoreCrystal_{i}`,
			Size = Vector3.new(fragSize, fragSize * 2, fragSize),
			CFrame = CFrame.new(posFromAngle(fragAngle, fragDist, fragY))
				* CFrame.Angles(rad(math.random(0, 360)), rad(math.random(0, 360)), rad(math.random(0, 360))),
			Material = Enum.Material.Glass,
			Color = if i % 2 == 0 then CRYSTAL_PURPLE else NEON_VIOLET,
			Transparency = 0.3,
			CanCollide = false,
			CastShadow = false,
		})
		breathe(crystal, 3 + math.random() * 2, {
			CFrame = crystal.CFrame + Vector3.new(0, 1 + math.random(), 0),
		})
	end

	-- ═══ PARTICULES D'ÉNERGIE BRAINROT ═══
	addParticles(coreSphere, {
		Name = "CoreEnergy",
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, ENERGY_CORE),
			ColorSequenceKeypoint.new(0.4, NEON_CYAN),
			ColorSequenceKeypoint.new(0.7, NEON_MAGENTA),
			ColorSequenceKeypoint.new(1, ENERGY_HOT),
		}),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.3, 2),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Rate = 50,
		Speed = NumberRange.new(8, 20),
		SpreadAngle = Vector2.new(30, 30),
		Lifetime = NumberRange.new(2, 5),
	})

	-- Étincelles de glitch
	addParticles(coreSphere, {
		Name = "GlitchSparks",
		Color = ColorSequence.new(NEON_WHITE, NEON_CYAN),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.2, 0.5),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Rate = 30,
		Speed = NumberRange.new(15, 30),
		SpreadAngle = Vector2.new(180, 180),
		Lifetime = NumberRange.new(0.3, 0.8),
	})

	-- BillboardGui "LE CŒUR DU BRAINROT"
	local labelPart = createPart({
		Name = "CoreLabel",
		Size = Vector3.new(1, 1, 1),
		Position = CENTER + Vector3.new(0, coreY + fxHeight + 3, 0),
		Transparency = 1,
		CanCollide = false,
		CastShadow = false,
	})

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(500, 120)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 150
	bb.Parent = labelPart

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.fromScale(1, 0.6)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "LE CŒUR DU BRAINROT"
	titleLabel.TextColor3 = ENERGY_CORE
	titleLabel.TextStrokeTransparency = 0
	titleLabel.TextStrokeColor3 = VOID_BLACK
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.FredokaOne
	titleLabel.Parent = bb

	local subLabel = Instance.new("TextLabel")
	subLabel.Size = UDim2.fromScale(1, 0.35)
	subLabel.Position = UDim2.fromScale(0, 0.62)
	subLabel.BackgroundTransparency = 1
	subLabel.Text = "⟐ Nexus de la Réalité Corrompue ⟐"
	subLabel.TextColor3 = NEON_CYAN
	subLabel.TextStrokeTransparency = 0.3
	subLabel.TextScaled = true
	subLabel.Font = Enum.Font.GothamBold
	subLabel.Parent = bb

	print("[SpawnBuilder] ✅ Cœur du Brainrot construit")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 3. FRACTURES DIMENSIONNELLES — Portails
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildPortal(portalData: { [string]: any }): ()
	local angle: number    = portalData.Angle
	local dist: number     = portalData.Distance
	local color: Color3    = portalData.Color
	local portalId: string = portalData.Id
	local portalName: string = portalData.Name
	local subtitle: string = portalData.Subtitle

	local pH: number = Constants.PORTAL_HEIGHT
	local pW: number = Constants.PORTAL_WIDTH
	local pT: number = Constants.PORTAL_THICKNESS
	local iH: number = Constants.PORTAL_INNER_HEIGHT
	local iW: number = Constants.PORTAL_INNER_WIDTH

	local portalPos: Vector3 = posFromAngle(angle, dist, GROUND_Y + pH / 2)
	local lookAtCenter: CFrame = CFrame.lookAt(portalPos, Vector3.new(CENTER.X, portalPos.Y, CENTER.Z))

	local portalModel: Model = Instance.new("Model")
	portalModel.Name = `Portal_{portalId}`

	-- ── Cratère sous le portail ──
	local craterPos = posFromAngle(angle, dist, GROUND_Y)

	createPart({
		Name = "FractureCrater",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.8, pW + 8, pW + 8),
		CFrame = CFrame.new(craterPos + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, rad(90)),
		Material = Enum.Material.DiamondPlate,
		Color = OBSIDIAN,
		Parent = portalModel,
	})

	-- Anneau d'énergie au sol
	local groundRing = createPart({
		Name = "FractureGroundRing",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, pW + 12, pW + 12),
		CFrame = CFrame.new(craterPos + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, rad(90)),
		Material = Enum.Material.Neon,
		Color = color,
		Transparency = 0.4,
		CanCollide = false,
		CastShadow = false,
		Parent = portalModel,
	})
	breathe(groundRing, 2.5, { Transparency = 0.75 })

	-- ── Formations cristallines (cadre de la fracture) ──
	local halfInner = iW / 2
	for _, side in { -1, 1 } do
		local sideName = if side == -1 then "Left" else "Right"
		local xOff = side * (halfInner + 1.5)

		-- Cristal principal (pilier angulaire)
		local crystalH = pH + math.random(-2, 3)
		createPart({
			Name = `CrystalPillar{sideName}`,
			Size = Vector3.new(2.5 + math.random() * 0.5, crystalH, 2.5 + math.random() * 0.5),
			CFrame = lookAtCenter * CFrame.new(xOff, (crystalH - pH) / 2, 0)
				* CFrame.Angles(rad(math.random(-3, 3)), 0, rad(side * math.random(2, 5))),
			Material = Enum.Material.Glass,
			Color = CRYSTAL_DARK,
			Transparency = 0.15,
			Parent = portalModel,
		})

		-- Cristal secondaire (plus petit, incliné)
		local secH = pH * 0.6 + math.random() * 3
		createPart({
			Name = `CrystalSec{sideName}`,
			Size = Vector3.new(1.5, secH, 1.5),
			CFrame = lookAtCenter * CFrame.new(xOff + side * 2, (secH - pH) / 2 - 2, math.random(-1, 1))
				* CFrame.Angles(rad(math.random(-10, 10)), 0, rad(side * math.random(8, 15))),
			Material = Enum.Material.Glass,
			Color = CRYSTAL_DARK,
			Transparency = 0.2,
			Parent = portalModel,
		})

		-- Nervure néon sur le cristal
		local neonStrip = createPart({
			Name = `CrystalNeon{sideName}`,
			Size = Vector3.new(0.2, crystalH - 2, 0.2),
			CFrame = lookAtCenter * CFrame.new(xOff - side * 0.3, 0, 0),
			Material = Enum.Material.Neon,
			Color = color,
			Transparency = 0.15,
			CanCollide = false,
			CastShadow = false,
			Parent = portalModel,
		})
		breathe(neonStrip, 1.8 + side * 0.2, { Transparency = 0.5 })

		-- Fragments de cristal flottants
		for j = 1, 3 do
			local fragH = 1 + math.random() * 2
			local fragY = pH * 0.2 * j + math.random(-2, 2)
			local fragDistLocal = 2 + math.random() * 1.5

			local frag = createPart({
				Name = `CrystalFrag{sideName}_{j}`,
				Size = Vector3.new(fragH * 0.5, fragH, fragH * 0.5),
				CFrame = lookAtCenter * CFrame.new(xOff + side * fragDistLocal, fragY - pH / 2, math.random(-2, 2))
					* CFrame.Angles(rad(math.random(0, 360)), rad(math.random(0, 360)), rad(math.random(0, 360))),
				Material = Enum.Material.Glass,
				Color = color,
				Transparency = 0.4,
				CanCollide = false,
				CastShadow = false,
				Parent = portalModel,
			})
			breathe(frag, 3 + math.random() * 2, {
				CFrame = frag.CFrame + Vector3.new(0, 0.8 + math.random() * 0.5, 0),
			})
		end
	end

	-- Linteau supérieur (pont de cristal brisé)
	createPart({
		Name = "CrystalLintel",
		Size = Vector3.new(pW + 2, 2.5, pT),
		CFrame = lookAtCenter * CFrame.new(0, iH / 2 + 1.5, 0),
		Material = Enum.Material.Glass,
		Color = CRYSTAL_DARK,
		Transparency = 0.1,
		Parent = portalModel,
	})

	-- Crête lumineuse au sommet
	local crestGlow = createPart({
		Name = "CrystalCrest",
		Size = Vector3.new(pW + 4, 0.6, 0.6),
		CFrame = lookAtCenter * CFrame.new(0, pH / 2 + 2, 0),
		Material = Enum.Material.Neon,
		Color = color,
		Transparency = 0.2,
		CanCollide = false,
		CastShadow = false,
		Parent = portalModel,
	})
	breathe(crestGlow, 2, { Transparency = 0.55 })

	-- ══ EFFET INTÉRIEUR — LE RIFT (plan néon = la faille) ══
	local portalEffect = createPart({
		Name = "PortalEffect",
		Size = Vector3.new(iW, iH, 0.5),
		CFrame = lookAtCenter,
		Material = Enum.Material.Neon,
		Color = color,
		Transparency = 0.3,
		CanCollide = false,
		CastShadow = false,
		Parent = portalModel,
	})
	addLight(portalEffect, color, 6, 45)

	-- Couche de distorsion ForceField derrière la faille
	createPart({
		Name = "FractureDistortion",
		Size = Vector3.new(iW - 1, iH - 1, 0.3),
		CFrame = lookAtCenter * CFrame.new(0, 0, 0.4),
		Material = Enum.Material.ForceField,
		Color = color,
		Transparency = 0.5,
		CanCollide = false,
		CastShadow = false,
		Parent = portalModel,
	})

	-- Faisceau de lumière vertical (monte vers l'infini)
	local beamH = 60
	local vertBeam = createPart({
		Name = "PortalBeam",
		Size = Vector3.new(1, beamH, 1),
		CFrame = CFrame.new(craterPos + Vector3.new(0, GROUND_Y + pH / 2 + beamH / 2, 0)),
		Material = Enum.Material.Neon,
		Color = color,
		Transparency = 0.7,
		CanCollide = false,
		CastShadow = false,
		Parent = portalModel,
	})
	breathe(vertBeam, 3, { Transparency = 0.88, Size = Vector3.new(1.8, beamH, 1.8) })

	-- Particules vortex
	addParticles(portalEffect, {
		Name = "FractureVortex",
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, color),
			ColorSequenceKeypoint.new(0.5, NEON_WHITE),
			ColorSequenceKeypoint.new(1, color),
		}),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.3, 2.5),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Rate = 40,
		Speed = NumberRange.new(2, 6),
		SpreadAngle = Vector2.new(180, 180),
		RotSpeed = NumberRange.new(-120, 120),
		Lifetime = NumberRange.new(1.5, 3),
	})

	-- Particules montantes depuis la base
	local baseEmitter = createPart({
		Name = "PortalBaseEmitter",
		Size = Vector3.new(iW, 0.5, pT),
		CFrame = lookAtCenter * CFrame.new(0, -iH / 2, 0),
		Transparency = 1,
		CanCollide = false,
		CastShadow = false,
		Parent = portalModel,
	})
	addParticles(baseEmitter, {
		Name = "RisingEnergy",
		Color = ColorSequence.new(color),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.5, 1.5),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Rate = 20,
		Speed = NumberRange.new(6, 14),
		SpreadAngle = Vector2.new(15, 15),
		Lifetime = NumberRange.new(1, 2.5),
	})

	-- ── BillboardGui ──
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PortalLabel"
	billboard.Size = UDim2.fromOffset(420, 180)
	billboard.StudsOffset = Vector3.new(0, pH / 2 + 6, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 120
	billboard.Parent = portalEffect

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "PortalName"
	nameLabel.Size = UDim2.fromScale(1, 0.4)
	nameLabel.Position = UDim2.fromScale(0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = string.upper(string.gsub(portalName, "[^%w%s]", ""))
	nameLabel.TextColor3 = color
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextStrokeColor3 = VOID_BLACK
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.Parent = billboard

	local glyphLabel = Instance.new("TextLabel")
	glyphLabel.Name = "Glyphs"
	glyphLabel.Size = UDim2.fromScale(1, 0.2)
	glyphLabel.Position = UDim2.fromScale(0, 0.4)
	glyphLabel.BackgroundTransparency = 1
	glyphLabel.Text = "⟐ ◈ ⟐ ◈ ⟐"
	glyphLabel.TextColor3 = color
	glyphLabel.TextStrokeTransparency = 0.3
	glyphLabel.TextScaled = true
	glyphLabel.Font = Enum.Font.FredokaOne
	glyphLabel.Parent = billboard

	local subLabelBB = Instance.new("TextLabel")
	subLabelBB.Name = "Subtitle"
	subLabelBB.Size = UDim2.fromScale(1, 0.3)
	subLabelBB.Position = UDim2.fromScale(0, 0.65)
	subLabelBB.BackgroundTransparency = 1
	subLabelBB.Text = subtitle
	subLabelBB.TextColor3 = NEON_WHITE
	subLabelBB.TextStrokeTransparency = 0.3
	subLabelBB.TextScaled = true
	subLabelBB.Font = Enum.Font.GothamBold
	subLabelBB.Parent = billboard

	-- Tag pour le PortalSystem
	local tag = Instance.new("StringValue")
	tag.Name = "PortalId"
	tag.Value = portalId
	tag.Parent = portalEffect

	portalModel.Parent = hub
	print(`[SpawnBuilder] ✅ Fracture "{portalName}" construite (angle={angle}°)`)
end

local function buildAllPortals(): ()
	for _, portalData in Constants.PORTALS do
		buildPortal(portalData)
	end
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 4. VEINES NEURALES — Chemins lumineux pulsants
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildNeuralPaths(): ()
	local SEGMENTS: number = 12

	for _, portalData in Constants.PORTALS do
		local angle: number = portalData.Angle
		local dist: number  = portalData.Distance
		local color: Color3 = portalData.Color

		local r = rad(angle)
		local lookDir = Vector3.new(math.cos(r), 0, math.sin(r))

		for i = 1, SEGMENTS do
			local t: number = i / (SEGMENTS + 1)
			local segDist: number = Constants.FOUNTAIN_RADIUS + 6 + t * (dist - Constants.FOUNTAIN_RADIUS - 14)
			local pos: Vector3 = posFromAngle(angle, segDist, GROUND_Y + 0.12)
			local segCF: CFrame = CFrame.lookAt(pos, pos + lookDir)
			local segLen = (dist - Constants.FOUNTAIN_RADIUS - 12) / SEGMENTS - 0.5

			-- Veine principale (trait néon fin)
			local vein = createPart({
				Name = `Vein_{portalData.Id}_{i}`,
				Size = Vector3.new(0.6, 0.08, segLen),
				CFrame = segCF,
				Material = Enum.Material.Neon,
				Color = color,
				Transparency = 0.25,
				CanCollide = false,
				CastShadow = false,
			})

			-- Pulsation en vagues (décalage par segment)
			local delayTime = i * 0.15
			task.delay(delayTime, function()
				breathe(vein, 1.5, { Transparency = 0.7 })
			end)

			-- Ramifications (veines latérales)
			if i % 2 == 0 then
				for _, side in { -1, 1 } do
					local branchLen = 2 + math.random() * 3
					local branchAngle = angle + side * (20 + math.random() * 25)
					local branchR = rad(branchAngle)
					local branchPos = posFromAngle(angle, segDist, GROUND_Y + 0.11)
						+ Vector3.new(math.cos(branchR) * branchLen / 2, 0, math.sin(branchR) * branchLen / 2)

					createPart({
						Name = `VeinBranch_{portalData.Id}_{i}_{side}`,
						Size = Vector3.new(0.25, 0.06, branchLen),
						CFrame = CFrame.lookAt(branchPos, branchPos + Vector3.new(math.cos(branchR), 0, math.sin(branchR))),
						Material = Enum.Material.Neon,
						Color = color,
						Transparency = 0.45,
						CanCollide = false,
						CastShadow = false,
					})
				end
			end

			-- Nœuds lumineux (jonctions)
			if i % 3 == 0 then
				local node = createPart({
					Name = `VeinNode_{portalData.Id}_{i}`,
					Shape = Enum.PartType.Ball,
					Size = Vector3.new(1.2, 0.4, 1.2),
					Position = posFromAngle(angle, segDist, GROUND_Y + 0.2),
					Material = Enum.Material.Neon,
					Color = color,
					Transparency = 0.3,
					CanCollide = false,
					CastShadow = false,
				})
				breathe(node, 1.5, { Transparency = 0.65, Size = Vector3.new(1.6, 0.6, 1.6) })
				addLight(node, color, 1.5, 12)
			end
		end
	end

	print("[SpawnBuilder] ✅ Veines neurales construites")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 5. ZONE AFK — "La Chambre de Stase"
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildStasisChamber(): ()
	local afkAngle = Constants.AFK_ZONE_ANGLE
	local afkDist  = Constants.AFK_ZONE_DISTANCE
	local afkR     = Constants.AFK_ZONE_RADIUS
	local afkCenter = posFromAngle(afkAngle, afkDist, GROUND_Y)

	-- Plateforme flottante d'obsidienne
	createPart({
		Name = "StasisPlatform",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.5, afkR * 2, afkR * 2),
		CFrame = CFrame.new(afkCenter + Vector3.new(0, 0.75, 0)) * CFrame.Angles(0, 0, rad(90)),
		Material = Enum.Material.DiamondPlate,
		Color = OBSIDIAN,
	})

	-- Anneau de confinement
	local containRing = createPart({
		Name = "StasisContainRing",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, afkR * 2 + 4, afkR * 2 + 4),
		CFrame = CFrame.new(afkCenter + Vector3.new(0, 1.7, 0)) * CFrame.Angles(0, 0, rad(90)),
		Material = Enum.Material.Neon,
		Color = NEON_VIOLET,
		Transparency = 0.5,
		CanCollide = false,
		CastShadow = false,
	})
	breathe(containRing, 4, { Transparency = 0.8, Color = NEON_CYAN })

	-- 6 piliers de confinement (cristal noir)
	for i = 1, 6 do
		local pRad = rad((i - 1) * 60)
		local px = afkCenter.X + math.cos(pRad) * (afkR - 2)
		local pz = afkCenter.Z + math.sin(pRad) * (afkR - 2)
		local pillarH = 10 + math.random() * 3

		createPart({
			Name = `StasisPillar_{i}`,
			Size = Vector3.new(1, pillarH, 1),
			Position = Vector3.new(px, GROUND_Y + pillarH / 2, pz),
			Material = Enum.Material.Glass,
			Color = CRYSTAL_DARK,
			Transparency = 0.1,
		})

		local tip = createPart({
			Name = `StasisTip_{i}`,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.2, 1.2, 1.2),
			Position = Vector3.new(px, GROUND_Y + pillarH + 0.6, pz),
			Material = Enum.Material.Neon,
			Color = NEON_VIOLET,
			Transparency = 0.2,
			CanCollide = false,
			CastShadow = false,
		})
		breathe(tip, 2 + i * 0.3, { Transparency = 0.6 })
		addLight(tip, NEON_VIOLET, 1, 10)
	end

	-- Sièges (piliers de méditation cristallins)
	local numSeats = Constants.AFK_SEATS
	for i = 1, numSeats do
		local seatAngle = (i / numSeats) * math.pi * 2
		local sx = afkCenter.X + math.cos(seatAngle) * (afkR - 6)
		local sz = afkCenter.Z + math.sin(seatAngle) * (afkR - 6)

		createPart({
			Name = `StasisSeat_{i}`,
			Size = Vector3.new(2.5, 0.8, 2.5),
			Position = Vector3.new(sx, GROUND_Y + 1.9, sz),
			Material = Enum.Material.Glass,
			Color = OBSIDIAN_LIGHT,
			Transparency = 0.15,
		})

		local rune = createPart({
			Name = `StasisRune_{i}`,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.1, 3, 3),
			CFrame = CFrame.new(Vector3.new(sx, GROUND_Y + 1.55, sz)) * CFrame.Angles(0, 0, rad(90)),
			Material = Enum.Material.Neon,
			Color = NEON_VIOLET,
			Transparency = 0.5,
			CanCollide = false,
			CastShadow = false,
		})
		breathe(rune, 3, { Transparency = 0.8 })
	end

	-- Panneau
	local signPart = createPart({
		Name = "StasisSign",
		Size = Vector3.new(1, 1, 1),
		Position = afkCenter + Vector3.new(0, 16, 0),
		Transparency = 1,
		CanCollide = false,
		CastShadow = false,
	})

	local signBB = Instance.new("BillboardGui")
	signBB.Size = UDim2.fromOffset(380, 150)
	signBB.AlwaysOnTop = false
	signBB.MaxDistance = 80
	signBB.Parent = signPart

	local afkTitle = Instance.new("TextLabel")
	afkTitle.Size = UDim2.fromScale(1, 0.5)
	afkTitle.BackgroundTransparency = 1
	afkTitle.Text = "◈ CHAMBRE DE STASE ◈"
	afkTitle.TextColor3 = NEON_VIOLET
	afkTitle.TextStrokeTransparency = 0
	afkTitle.TextStrokeColor3 = VOID_BLACK
	afkTitle.TextScaled = true
	afkTitle.Font = Enum.Font.FredokaOne
	afkTitle.Parent = signBB

	local afkSub = Instance.new("TextLabel")
	afkSub.Size = UDim2.fromScale(1, 0.4)
	afkSub.Position = UDim2.fromScale(0, 0.55)
	afkSub.BackgroundTransparency = 1
	afkSub.Text = `Reste ici → {Constants.AFK_REWARD_AMOUNT} 🧠/min`
	afkSub.TextColor3 = NEON_WHITE
	afkSub.TextStrokeTransparency = 0.3
	afkSub.TextScaled = true
	afkSub.Font = Enum.Font.GothamBold
	afkSub.Parent = signBB

	-- Trigger AFK
	local afkTrigger = createPart({
		Name = "AFKTrigger",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(12, afkR * 2, afkR * 2),
		CFrame = CFrame.new(afkCenter + Vector3.new(0, 8, 0)) * CFrame.Angles(0, 0, rad(90)),
		Transparency = 1,
		CanCollide = false,
		CastShadow = false,
	})

	local afkTag = Instance.new("StringValue")
	afkTag.Name = "ZoneType"
	afkTag.Value = "AFK"
	afkTag.Parent = afkTrigger

	print("[SpawnBuilder] ✅ Chambre de Stase construite")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 6. VITRINE — "L'Archive du Void"
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildArchive(): ()
	local scAngle = Constants.SHOWCASE_ANGLE
	local scDist  = Constants.SHOWCASE_DISTANCE
	local scLen   = Constants.SHOWCASE_LENGTH
	local scCenter = posFromAngle(scAngle, scDist, GROUND_Y)

	-- Plateforme monolithique
	createPart({
		Name = "ArchivePlatform",
		Size = Vector3.new(scLen + 8, 1, 14),
		Position = scCenter + Vector3.new(0, 0.5, 0),
		Material = Enum.Material.DiamondPlate,
		Color = OBSIDIAN,
	})

	-- Mur de fond (verre noir translucide)
	createPart({
		Name = "ArchiveBackwall",
		Size = Vector3.new(scLen + 6, 14, 0.5),
		Position = scCenter + Vector3.new(0, 8, -6),
		Material = Enum.Material.Glass,
		Color = VOID_BLACK,
		Transparency = 0.2,
	})

	-- Podiums
	local units = Constants.SHOWCASE_UNITS
	local spacing = scLen / (#units + 1)
	local unitColors = { NEON_MAGENTA, NEON_CYAN, GOLD_ACCENT }

	for i, unitName in units do
		local podiumX = scCenter.X + (i - (#units + 1) / 2) * spacing
		local podiumPos = Vector3.new(podiumX, GROUND_Y + 1, scCenter.Z)

		-- Colonne cristalline
		createPart({
			Name = `ArchivePodium_{unitName}`,
			Size = Vector3.new(3, 4, 3),
			CFrame = CFrame.new(podiumPos + Vector3.new(0, 2, 0)),
			Material = Enum.Material.Glass,
			Color = CRYSTAL_DARK,
			Transparency = 0.15,
		})

		-- Anneau néon
		local podRing = createPart({
			Name = `ArchiveRing_{unitName}`,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.2, 4, 4),
			CFrame = CFrame.new(podiumPos + Vector3.new(0, 4.2, 0)) * CFrame.Angles(0, 0, rad(90)),
			Material = Enum.Material.Neon,
			Color = unitColors[i] or NEON_VIOLET,
			Transparency = 0.3,
			CanCollide = false,
			CastShadow = false,
		})
		spinForever(podRing, Vector3.new(0, 1, 0), 0.1)

		-- Placeholder unité (sphère flottante ForceField)
		local unitOrb = createPart({
			Name = `UnitDisplay_{unitName}`,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(3.5, 3.5, 3.5),
			Position = podiumPos + Vector3.new(0, 6, 0),
			Material = Enum.Material.ForceField,
			Color = unitColors[i] or NEON_VIOLET,
			Transparency = 0.15,
			CanCollide = false,
			CastShadow = false,
		})
		breathe(unitOrb, 2.5, { Position = podiumPos + Vector3.new(0, 7, 0) })

		-- Label
		local unitBB = Instance.new("BillboardGui")
		unitBB.Size = UDim2.fromOffset(220, 60)
		unitBB.StudsOffset = Vector3.new(0, 4.5, 0)
		unitBB.AlwaysOnTop = false
		unitBB.MaxDistance = 60
		unitBB.Parent = unitOrb

		local unitLbl = Instance.new("TextLabel")
		unitLbl.Size = UDim2.fromScale(1, 1)
		unitLbl.BackgroundTransparency = 1
		unitLbl.Text = unitName
		unitLbl.TextColor3 = unitColors[i] or NEON_VIOLET
		unitLbl.TextStrokeTransparency = 0
		unitLbl.TextStrokeColor3 = VOID_BLACK
		unitLbl.TextScaled = true
		unitLbl.Font = Enum.Font.FredokaOne
		unitLbl.Parent = unitBB

		addParticles(unitOrb, {
			Name = "DisplayShimmer",
			Color = ColorSequence.new(unitColors[i] or NEON_VIOLET),
			Rate = 8,
			Speed = NumberRange.new(1, 4),
			SpreadAngle = Vector2.new(180, 180),
			Lifetime = NumberRange.new(1, 2),
		})
	end

	-- Titre
	local archiveSign = createPart({
		Name = "ArchiveSign",
		Size = Vector3.new(1, 1, 1),
		Position = scCenter + Vector3.new(0, 16, -6),
		Transparency = 1,
		CanCollide = false,
		CastShadow = false,
	})

	local archiveBB = Instance.new("BillboardGui")
	archiveBB.Size = UDim2.fromOffset(500, 100)
	archiveBB.AlwaysOnTop = false
	archiveBB.MaxDistance = 100
	archiveBB.Parent = archiveSign

	local archiveLabel = Instance.new("TextLabel")
	archiveLabel.Size = UDim2.fromScale(1, 1)
	archiveLabel.BackgroundTransparency = 1
	archiveLabel.Text = "◈ ARCHIVE DU VOID ◈"
	archiveLabel.TextColor3 = GOLD_ACCENT
	archiveLabel.TextStrokeTransparency = 0
	archiveLabel.TextStrokeColor3 = VOID_BLACK
	archiveLabel.TextScaled = true
	archiveLabel.Font = Enum.Font.FredokaOne
	archiveLabel.Parent = archiveBB

	print("[SpawnBuilder] ✅ Archive du Void construite")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 7. LEADERBOARD — Projection holographique
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildLeaderboard(): ()
	local lbAngle = Constants.LEADERBOARD_ANGLE
	local lbDist  = Constants.LEADERBOARD_DISTANCE
	local lbCenter = posFromAngle(lbAngle, lbDist, GROUND_Y)

	-- Écran cristallin
	local screen = createPart({
		Name = "LeaderboardScreen",
		Size = Vector3.new(16, 12, 0.5),
		Position = lbCenter + Vector3.new(0, 9, 0),
		Material = Enum.Material.Glass,
		Color = VOID_BLACK,
		Transparency = 0.1,
	})

	-- Cadre néon animé
	local frameEdges = {
		{ size = Vector3.new(17, 0.4, 0.8), offset = Vector3.new(0, 6.3, 0) },
		{ size = Vector3.new(17, 0.4, 0.8), offset = Vector3.new(0, -6.3, 0) },
		{ size = Vector3.new(0.4, 13, 0.8), offset = Vector3.new(8.5, 0, 0) },
		{ size = Vector3.new(0.4, 13, 0.8), offset = Vector3.new(-8.5, 0, 0) },
	}
	for _, edge in frameEdges do
		local edgePart = createPart({
			Name = "LBFrame",
			Size = edge.size,
			Position = lbCenter + Vector3.new(0, 9, 0) + edge.offset,
			Material = Enum.Material.Neon,
			Color = NEON_CYAN,
			Transparency = 0.2,
			CanCollide = false,
			CastShadow = false,
		})
		breathe(edgePart, 3, { Transparency = 0.5 })
	end

	-- Supports cristallins
	for _, sx in { -6, 6 } do
		createPart({
			Name = "LBSupport",
			Size = Vector3.new(0.8, 8, 0.8),
			CFrame = CFrame.new(lbCenter + Vector3.new(sx, 4, 0.8))
				* CFrame.Angles(rad(8), 0, 0),
			Material = Enum.Material.Glass,
			Color = CRYSTAL_DARK,
			Transparency = 0.1,
		})
	end

	-- SurfaceGui
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "LeaderboardGUI"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 30
	surfaceGui.Parent = screen

	local titleLB = Instance.new("TextLabel")
	titleLB.Size = UDim2.fromScale(1, 0.14)
	titleLB.BackgroundTransparency = 1
	titleLB.Text = "◈ TOP DEFENDERS ◈"
	titleLB.TextColor3 = GOLD_ACCENT
	titleLB.TextScaled = true
	titleLB.Font = Enum.Font.FredokaOne
	titleLB.Parent = surfaceGui

	for rank = 1, 8 do
		local row = Instance.new("TextLabel")
		row.Size = UDim2.new(0.9, 0, 0.08, 0)
		row.Position = UDim2.new(0.05, 0, 0.15 + (rank - 1) * 0.1, 0)
		row.BackgroundTransparency = if rank <= 3 then 0.7 else 0.85
		row.BackgroundColor3 = if rank == 1 then GOLD_ACCENT
			elseif rank == 2 then Color3.fromRGB(180, 180, 200)
			elseif rank == 3 then Color3.fromRGB(180, 120, 60)
			else Color3.fromRGB(20, 18, 35)
		row.Text = `  #{rank}  ···  Joueur{rank}  ···  {math.floor(1000 / rank)} pts`
		row.TextColor3 = NEON_WHITE
		row.TextScaled = true
		row.Font = Enum.Font.GothamBold
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Parent = surfaceGui

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 6)
		rowCorner.Parent = row
	end

	print("[SpawnBuilder] ✅ Leaderboard holographique construit")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 8. DÉBRIS DU VOID — Géométries flottantes
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildVoidDebris(): ()
	-- Grands fragments géométriques distants
	for i = 1, 20 do
		local dAngle = math.random() * 360
		local dDist = RADIUS + 30 + math.random() * 120
		local dY = -20 + math.random() * 100
		local dPos = posFromAngle(dAngle, dDist, dY)
		local dSize = 4 + math.random() * 15

		local shapes = { Enum.PartType.Block, Enum.PartType.Ball, Enum.PartType.Cylinder }
		local chosenShape = shapes[math.random(1, #shapes)]

		local debris = createPart({
			Name = `VoidDebris_{i}`,
			Shape = chosenShape,
			Size = if chosenShape == Enum.PartType.Cylinder
				then Vector3.new(dSize * 0.3, dSize, dSize)
				else Vector3.new(dSize * 0.8, dSize * 0.5, dSize),
			CFrame = CFrame.new(dPos) * CFrame.Angles(
				rad(math.random(0, 360)),
				rad(math.random(0, 360)),
				rad(math.random(0, 360))
			),
			Material = if math.random() > 0.6 then Enum.Material.Basalt else Enum.Material.Slate,
			Color = Color3.fromRGB(
				15 + math.random(0, 20),
				12 + math.random(0, 15),
				25 + math.random(0, 20)
			),
			Transparency = 0.1,
			CanCollide = false,
			CastShadow = false,
		})

		local axis = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5).Unit
		spinForever(debris, axis, 0.01 + math.random() * 0.03)

		breathe(debris, 6 + math.random() * 6, {
			CFrame = debris.CFrame + Vector3.new(0, 2 + math.random() * 3, 0),
		})
	end

	-- Petits cristaux lumineux flottants (plus proches)
	for i = 1, 12 do
		local cAngle = math.random() * 360
		local cDist = RADIUS * 0.4 + math.random() * RADIUS * 0.4
		local cY = 15 + math.random() * 40
		local cPos = posFromAngle(cAngle, cDist, cY)
		local cSize = 0.8 + math.random() * 2.5

		local crystal = createPart({
			Name = `FloatingCrystal_{i}`,
			Size = Vector3.new(cSize * 0.5, cSize * 2, cSize * 0.5),
			CFrame = CFrame.new(cPos) * CFrame.Angles(
				rad(math.random(0, 360)),
				rad(math.random(0, 360)),
				rad(math.random(-20, 20))
			),
			Material = Enum.Material.Neon,
			Color = if i % 3 == 0 then NEON_CYAN
				elseif i % 3 == 1 then NEON_VIOLET
				else NEON_MAGENTA,
			Transparency = 0.3,
			CanCollide = false,
			CastShadow = false,
		})
		breathe(crystal, 3 + math.random() * 3, {
			CFrame = crystal.CFrame + Vector3.new(0, 1.5 + math.random() * 2, 0),
		})
	end

	-- Nuages de nébuleuse (grandes sphères semi-transparentes au loin)
	local nebulaColors = { NEBULA_BLUE, NEBULA_PURPLE, NEBULA_PINK }
	for i = 1, 8 do
		local nAngle = math.random() * 360
		local nDist = RADIUS + 80 + math.random() * 150
		local nY = -30 + math.random() * 120
		local nSize = 40 + math.random() * 60

		local nebula = createPart({
			Name = `Nebula_{i}`,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(nSize, nSize * 0.5, nSize),
			Position = posFromAngle(nAngle, nDist, nY),
			Material = Enum.Material.Neon,
			Color = nebulaColors[((i - 1) % #nebulaColors) + 1],
			Transparency = 0.92,
			CanCollide = false,
			CastShadow = false,
		})
		breathe(nebula, 8 + math.random() * 6, { Transparency = 0.96 })
	end

	print("[SpawnBuilder] ✅ Débris du Void placés")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 9. RUNES & GLYPHES AU SOL
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildRunicCircles(): ()
	local runeRadius = Constants.FOUNTAIN_RADIUS + 5

	-- 12 glyphes en cercle autour du monument
	for i = 1, 12 do
		local angle = (i / 12) * 360
		local pos = posFromAngle(angle, runeRadius, GROUND_Y + 0.1)

		local glyph = createPart({
			Name = `Glyph_{i}`,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.08, 2.5, 2.5),
			CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, rad(90)),
			Material = Enum.Material.Neon,
			Color = if i % 2 == 0 then NEON_VIOLET else NEON_CYAN,
			Transparency = 0.35,
			CanCollide = false,
			CastShadow = false,
		})

		task.delay(i * 0.25, function()
			breathe(glyph, 2, { Transparency = 0.7 })
		end)
	end

	-- Symboles entre les veines radiales
	for i = 1, 8 do
		local angle1 = (i / 8) * 360 + 22.5
		for j = 1, 3 do
			local d = 30 + j * 15
			local pos = posFromAngle(angle1, d, GROUND_Y + 0.1)
			local r = rad(angle1 + 45 * j)

			createPart({
				Name = `RuneLine_{i}_{j}`,
				Size = Vector3.new(3.5, 0.06, 0.15),
				CFrame = CFrame.new(pos) * CFrame.Angles(0, r, 0),
				Material = Enum.Material.Neon,
				Color = ENERGY_CORE,
				Transparency = 0.55,
				CanCollide = false,
				CastShadow = false,
			})
		end
	end

	print("[SpawnBuilder] ✅ Cercles runiques tracés")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 10. PYLÔNES DE BORDURE
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildBorderPylons(): ()
	local numPylons: number = 16
	for i = 1, numPylons do
		local angle: number = (i / numPylons) * 360
		local pos: Vector3 = posFromAngle(angle, RADIUS - 12, GROUND_Y)

		local pylonH = 8 + math.random() * 6
		createPart({
			Name = `Pylon_{i}`,
			Size = Vector3.new(1.2, pylonH, 1.2),
			CFrame = CFrame.new(pos + Vector3.new(0, pylonH / 2, 0))
				* CFrame.Angles(0, 0, rad((math.random() - 0.5) * 6)),
			Material = Enum.Material.Glass,
			Color = CRYSTAL_DARK,
			Transparency = 0.1,
		})

		local orb = createPart({
			Name = `PylonOrb_{i}`,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.5, 1.5, 1.5),
			Position = pos + Vector3.new(0, pylonH + 1, 0),
			Material = Enum.Material.Neon,
			Color = if i % 3 == 0 then NEON_CYAN elseif i % 3 == 1 then NEON_VIOLET else NEON_MAGENTA,
			Transparency = 0.2,
			CanCollide = false,
			CastShadow = false,
		})

		breathe(orb, 2 + (i % 4) * 0.5, { Transparency = 0.6 })
		addLight(orb, orb.Color, 1.5, 15)
	end

	print("[SpawnBuilder] ✅ Pylônes de bordure érigés")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 11. PARTICULES AMBIANTES ("code rain" du Void)
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function buildAmbientFX(): ()
	-- Émetteur aérien central (code rain)
	local ambientBox = createPart({
		Name = "AmbientFXEmitter",
		Size = Vector3.new(RADIUS * 2, 1, RADIUS * 2),
		Position = CENTER + Vector3.new(0, 60, 0),
		Transparency = 1,
		CanCollide = false,
		CastShadow = false,
	})

	addParticles(ambientBox, {
		Name = "CodeRain",
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, NEON_VIOLET),
			ColorSequenceKeypoint.new(0.5, NEON_CYAN),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 20, 80)),
		}),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.3, 0.3),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.5, 0.3),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Rate = 60,
		Speed = NumberRange.new(5, 15),
		SpreadAngle = Vector2.new(180, 180),
		EmissionDirection = Enum.NormalId.Bottom,
		Lifetime = NumberRange.new(4, 8),
		RotSpeed = NumberRange.new(-30, 30),
	})

	-- Particules ascendantes sous l'île
	local underEmitter = createPart({
		Name = "UnderworldFX",
		Size = Vector3.new(RADIUS * 1.5, 1, RADIUS * 1.5),
		Position = CENTER + Vector3.new(0, -10, 0),
		Transparency = 1,
		CanCollide = false,
		CastShadow = false,
	})

	addParticles(underEmitter, {
		Name = "VoidWisps",
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, NEON_VIOLET),
			ColorSequenceKeypoint.new(1, ENERGY_CORE),
		}),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.5, 1.5),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Rate = 15,
		Speed = NumberRange.new(3, 8),
		SpreadAngle = Vector2.new(60, 60),
		Lifetime = NumberRange.new(4, 8),
	})

	print("[SpawnBuilder] ✅ Effets ambiants du Void activés")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 12. SPAWN LOCATION (invisible)
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
	spawn.Parent = hub

	print("[SpawnBuilder] ✅ SpawnLocation placée")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- 13. ÉCLAIRAGE — Void cosmique (Technology: Future)
-- ═══════════════════════════════════════════════
-------------------------------------------------
local function setupLighting(): ()
	-- Minuit absolu — pas de lumière directionnelle
	-- NOTE: Lighting.Technology est non-scriptable (Studio only), on ne peut pas le changer ici.
	pcall(function() Lighting.Technology = Enum.Technology.Future end) -- Tentative silencieuse
	Lighting.ClockTime = 0
	Lighting.Brightness = 0
	Lighting.Ambient = Color3.fromRGB(8, 5, 18)
	Lighting.OutdoorAmbient = Color3.fromRGB(12, 8, 25)
	Lighting.FogEnd = 800
	Lighting.FogStart = 200
	Lighting.FogColor = Color3.fromRGB(5, 3, 12)
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 0.3
	Lighting.EnvironmentSpecularScale = 0.6
	Lighting.GeographicLatitude = 0

	-- Nettoyer les effets existants
	for _, child in Lighting:GetChildren() do
		if child:IsA("PostEffect") or child:IsA("Atmosphere") or child:IsA("Sky") then
			child:Destroy()
		end
	end

	-- Atmosphere (brume abyssale)
	local atmo = Instance.new("Atmosphere")
	atmo.Density = 0.35
	atmo.Offset = 0.1
	atmo.Color = Color3.fromRGB(30, 15, 60)
	atmo.Decay = Color3.fromRGB(15, 8, 40)
	atmo.Glare = 0
	atmo.Haze = 2.5
	atmo.Parent = Lighting

	-- Bloom (néons intenses, halo cosmique)
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.8
	bloom.Size = 40
	bloom.Threshold = 0.6
	bloom.Parent = Lighting

	-- ColorCorrection (teinte froide violette)
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.03
	cc.Contrast = 0.18
	cc.Saturation = 0.15
	cc.TintColor = Color3.fromRGB(200, 180, 255)
	cc.Parent = Lighting

	-- Skybox noir absolu + étoiles
	local sky = Instance.new("Sky")
	sky.CelestialBodiesShown = false
	sky.StarCount = 3000
	sky.MoonAngularSize = 0
	sky.SunAngularSize = 0
	local blackSky = "rbxassetid://1040631063"
	sky.SkyboxBk = blackSky
	sky.SkyboxDn = blackSky
	sky.SkyboxFt = blackSky
	sky.SkyboxLf = blackSky
	sky.SkyboxRt = blackSky
	sky.SkyboxUp = blackSky
	sky.Parent = Lighting

	print("[SpawnBuilder] ✅ Éclairage Void cosmique configuré")
end

-------------------------------------------------
-- ═══════════════════════════════════════════════
-- CONSTRUCTION SÉQUENTIELLE
-- ═══════════════════════════════════════════════
-------------------------------------------------
print("══════════════════════════════════════")
print("[SpawnBuilder] ⟐ Construction de L'ARCHE DU NÉANT...")
print("══════════════════════════════════════")

-- ⚠️ SpawnLocation EN PREMIER — le joueur doit pouvoir spawn même si le reste erreur
buildSpawnLocation()

-- Construire chaque section avec pcall pour qu'un bug n'arrête pas tout
local buildSteps: { { string | () -> () } } = {
	{ "Île Fracturée",     buildVoidIsland },
	{ "Cœur du Brainrot",  buildBrainrotCore },
	{ "Cercles Runiques",  buildRunicCircles },
	{ "Portails",          buildAllPortals },
	{ "Veines Neurales",   buildNeuralPaths },
	{ "Chambre de Stase",  buildStasisChamber },
	-- buildArchive SUPPRIMÉ : ShowcaseBuilder.server.luau gère déjà la vitrine à angle 315°
	{ "Leaderboard",       buildLeaderboard },
	{ "Débris du Void",    buildVoidDebris },
	{ "Pylônes",           buildBorderPylons },
	{ "Effets Ambiants",   buildAmbientFX },
}

for _, step in buildSteps do
	local name = step[1] :: string
	local fn = step[2] :: () -> ()
	local ok, err = pcall(fn)
	if not ok then
		warn(`[SpawnBuilder] ❌ Erreur dans "{name}": {err}`)
	end
end

-- ⚠️ Lighting EN DERNIER + task.defer pour gagner la race condition avec GridManager
task.defer(function()
	task.wait(0.5) -- Laisser GridManager finir d'abord
	local lightOk, lightErr = pcall(setupLighting)
	if not lightOk then
		warn(`[SpawnBuilder] ❌ Erreur lighting: {lightErr}`)
	end
end)

print("══════════════════════════════════════")
print("[SpawnBuilder] ⟐ L'ARCHE DU NÉANT — COMPLETE !")
print(`[SpawnBuilder]   Centre: {CENTER}`)
print(`[SpawnBuilder]   Rayon: {RADIUS} studs`)
print(`[SpawnBuilder]   Portails: 4 Fractures à 120 studs`)
print("══════════════════════════════════════")
