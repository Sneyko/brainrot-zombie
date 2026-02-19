--!strict

--[[
	ProjectileFX (LocalScript)
	VFX Expert — Projectiles visuels + impact pour chaque tir de tour.
	Écoute le RemoteEvent UnitFired(UnitPosition, TargetPosition, UnitType).
	Accessible depuis : StarterPlayerScripts.Client.Systems.ProjectileFX
]]

-- Services
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService: TweenService = game:GetService("TweenService")
local Workspace: Workspace = game:GetService("Workspace")
local Debris: Debris = game:GetService("Debris")

-- Events
local sharedFolder: Instance = ReplicatedStorage:WaitForChild("Shared")
local eventsFolder: Instance = sharedFolder:WaitForChild("Events")
local unitFiredEvent: RemoteEvent = eventsFolder:WaitForChild("UnitFired") :: RemoteEvent

-------------------------------------------------
-- Constantes VFX
-------------------------------------------------
local PROJECTILE_SPEED: number = 0.15          -- Durée du tween (secondes)
local PROJECTILE_SIZE: Vector3 = Vector3.new(0.6, 0.6, 1.2)
local IMPACT_FLASH_DURATION: number = 0.12     -- Durée du flash d'impact
local IMPACT_PARTICLE_LIFETIME: number = 0.3   -- Durée des particules
local IMPACT_PARTICLE_COUNT: number = 6        -- Nombre de particules émises
local IMPACT_LIGHT_RANGE: number = 12          -- Portée du PointLight d'impact
local TRAIL_LIFETIME: number = 0.08            -- Durée de traînée

-------------------------------------------------
-- Couleurs par type d'unité
-------------------------------------------------
type ProjectileStyle = {
	Color: Color3,
	TrailColor: Color3,
	ImpactColor: Color3,
	Size: Vector3,
	Shape: Enum.PartType,
}

local UNIT_STYLES: { [string]: ProjectileStyle } = {
	Glorbo = {
		Color = Color3.fromRGB(80, 255, 120),
		TrailColor = Color3.fromRGB(120, 255, 160),
		ImpactColor = Color3.fromRGB(150, 255, 180),
		Size = Vector3.new(0.5, 0.5, 1.0),
		Shape = Enum.PartType.Ball,
	},
	Bombardino = {
		Color = Color3.fromRGB(255, 100, 20),
		TrailColor = Color3.fromRGB(255, 160, 40),
		ImpactColor = Color3.fromRGB(255, 200, 80),
		Size = Vector3.new(0.9, 0.9, 0.9),
		Shape = Enum.PartType.Ball,
	},
	TungTungSahur = {
		Color = Color3.fromRGB(180, 80, 255),
		TrailColor = Color3.fromRGB(200, 120, 255),
		ImpactColor = Color3.fromRGB(220, 160, 255),
		Size = Vector3.new(0.4, 0.4, 1.6),
		Shape = Enum.PartType.Block,
	},
	Tralalero = {
		Color = Color3.fromRGB(255, 40, 40),
		TrailColor = Color3.fromRGB(255, 100, 60),
		ImpactColor = Color3.fromRGB(255, 180, 80),
		Size = Vector3.new(0.8, 0.8, 1.8),
		Shape = Enum.PartType.Block,
	},
}

local DEFAULT_STYLE: ProjectileStyle = {
	Color = Color3.fromRGB(255, 220, 50),
	TrailColor = Color3.fromRGB(255, 240, 120),
	ImpactColor = Color3.fromRGB(255, 255, 200),
	Size = PROJECTILE_SIZE,
	Shape = Enum.PartType.Ball,
}

-------------------------------------------------
-- Helpers
-------------------------------------------------

--- Récupère le style visuel pour un type d'unité
local function getStyle(unitType: string): ProjectileStyle
	return UNIT_STYLES[unitType] or DEFAULT_STYLE
end

--- Dossier parent pour les FX
local function getFXParent(): Instance
	local gameBoard: Instance? = Workspace:FindFirstChild("GameBoard")
	return if gameBoard then gameBoard else Workspace
end

-------------------------------------------------
-- Effet d'impact : flash + particules
-------------------------------------------------
local function playImpactFX(position: Vector3, style: ProjectileStyle): ()
	local parent: Instance = getFXParent()

	-- 1) Flash lumineux (Part Neon surdimensionnée qui shrink)
	local flash: Part = Instance.new("Part")
	flash.Name = "ImpactFlash"
	flash.Size = Vector3.new(2.5, 2.5, 2.5)
	flash.Position = position
	flash.Anchored = true
	flash.CanCollide = false
	flash.Material = Enum.Material.Neon
	flash.Color = style.ImpactColor
	flash.Transparency = 0.3
	flash.Shape = Enum.PartType.Ball
	flash.Parent = parent

	-- PointLight pour l'éclairage ambiant
	local light: PointLight = Instance.new("PointLight")
	light.Color = style.ImpactColor
	light.Brightness = 3
	light.Range = IMPACT_LIGHT_RANGE
	light.Parent = flash

	-- Tween : grossit légèrement puis shrink + fade
	local expandTween: Tween = TweenService:Create(flash, TweenInfo.new(IMPACT_FLASH_DURATION * 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(3.5, 3.5, 3.5),
		Transparency = 0.1,
	})
	local shrinkTween: Tween = TweenService:Create(flash, TweenInfo.new(IMPACT_FLASH_DURATION * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1,
	})
	local lightFade: Tween = TweenService:Create(light, TweenInfo.new(IMPACT_FLASH_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Brightness = 0,
	})

	expandTween:Play()
	lightFade:Play()
	expandTween.Completed:Once(function(): ()
		shrinkTween:Play()
	end)

	Debris:AddItem(flash, IMPACT_FLASH_DURATION + 0.1)

	-- 2) Particules d'éclats (petites Parts Neon projetées aléatoirement)
	local rng: Random = Random.new()
	for _ = 1, IMPACT_PARTICLE_COUNT do
		local particle: Part = Instance.new("Part")
		particle.Name = "ImpactParticle"
		particle.Size = Vector3.new(0.25, 0.25, 0.25)
		particle.Position = position
		particle.Anchored = true
		particle.CanCollide = false
		particle.Material = Enum.Material.Neon
		particle.Color = style.ImpactColor
		particle.Shape = Enum.PartType.Ball
		particle.Transparency = 0
		particle.Parent = parent

		-- Direction aléatoire
		local direction: Vector3 = Vector3.new(
			rng:NextNumber(-1, 1),
			rng:NextNumber(0.2, 1),
			rng:NextNumber(-1, 1)
		).Unit

		local targetPos: Vector3 = position + direction * rng:NextNumber(1.5, 3.5)

		local particleTween: Tween = TweenService:Create(particle, TweenInfo.new(IMPACT_PARTICLE_LIFETIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = targetPos,
			Size = Vector3.new(0.05, 0.05, 0.05),
			Transparency = 1,
		})
		particleTween:Play()

		Debris:AddItem(particle, IMPACT_PARTICLE_LIFETIME + 0.05)
	end
end

-------------------------------------------------
-- Création et animation du projectile
-------------------------------------------------
local function fireProjectile(unitPos: Vector3, targetPos: Vector3, unitType: string): ()
	local style: ProjectileStyle = getStyle(unitType)
	local parent: Instance = getFXParent()

	-- Calculer la direction et l'orientation
	local direction: Vector3 = (targetPos - unitPos)
	local distance: number = direction.Magnitude
	if distance < 0.1 then
		return
	end

	-- Durée proportionnelle à la distance (minimum 0.08s, max 0.25s)
	local duration: number = math.clamp(distance / 120, 0.08, 0.25)

	-- Créer le projectile
	local projectile: Part = Instance.new("Part")
	projectile.Name = `Projectile_{unitType}`
	projectile.Size = style.Size
	projectile.CFrame = CFrame.lookAt(unitPos, targetPos)
	projectile.Anchored = true
	projectile.CanCollide = false
	projectile.Material = Enum.Material.Neon
	projectile.Color = style.Color
	projectile.Shape = style.Shape
	projectile.Transparency = 0
	projectile.Parent = parent

	-- PointLight embarqué sur le projectile
	local glow: PointLight = Instance.new("PointLight")
	glow.Color = style.Color
	glow.Brightness = 2
	glow.Range = 6
	glow.Parent = projectile

	-- Trail (traînée lumineuse)
	-- Attachments nécessaires pour le Trail
	local att0: Attachment = Instance.new("Attachment")
	att0.Position = Vector3.new(0, 0, style.Size.Z / 2)
	att0.Parent = projectile

	local att1: Attachment = Instance.new("Attachment")
	att1.Position = Vector3.new(0, 0, -style.Size.Z / 2)
	att1.Parent = projectile

	local trail: Trail = Instance.new("Trail")
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Color = ColorSequence.new(style.TrailColor, style.Color)
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Lifetime = TRAIL_LIFETIME
	trail.MinLength = 0
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	trail.LightEmission = 0.8
	trail.FaceCamera = true
	trail.Parent = projectile

	-- Tween de déplacement vers la cible
	local targetCFrame: CFrame = CFrame.lookAt(targetPos, targetPos + direction.Unit)

	local moveTween: Tween = TweenService:Create(projectile, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
		CFrame = targetCFrame,
	})

	moveTween.Completed:Once(function(): ()
		-- Impact !
		playImpactFX(targetPos, style)

		-- Détruire le projectile
		projectile:Destroy()
	end)

	moveTween:Play()

	-- Sécurité : cleanup si jamais le tween bug
	Debris:AddItem(projectile, duration + 0.5)
end

-------------------------------------------------
-- Écoute de l'event serveur
-------------------------------------------------
unitFiredEvent.OnClientEvent:Connect(function(unitPos: unknown, targetPos: unknown, unitType: unknown): ()
	-- Validation des arguments
	if typeof(unitPos) ~= "Vector3" then
		return
	end
	if typeof(targetPos) ~= "Vector3" then
		return
	end

	local unitTypeStr: string = if typeof(unitType) == "string" then unitType :: string else "Unknown"

	-- Lancer le projectile
	fireProjectile(unitPos :: Vector3, targetPos :: Vector3, unitTypeStr)
end)

print("[ProjectileFX] ✅ VFX initialisé — En attente de UnitFired")
