--!strict

--[[
	CombatSystem (ModuleScript)
	Tower Defense temps réel — Boucle de combat Heartbeat.
	Chaque unité placée (PlacedUnit) cherche le zombie le plus proche,
	puis tire automatiquement (cooldown FireRate) avec laser + VFX.
	Accessible depuis : ServerScriptService.Server.Systems.CombatSystem
]]

-- Services
local Workspace: Workspace = game:GetService("Workspace")
local RunService: RunService = game:GetService("RunService")
local TweenService: TweenService = game:GetService("TweenService")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris: Debris = game:GetService("Debris")

-- Modules
local sharedFolder: Instance = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(sharedFolder:WaitForChild("Constants"))
local UnitDatabase = require(sharedFolder:WaitForChild("Data"):WaitForChild("UnitDatabase"))

-- RemoteEvents
local eventsFolder: Folder = sharedFolder:WaitForChild("Events") :: Folder
local unitFiredEvent: RemoteEvent = eventsFolder:WaitForChild("UnitFired") :: RemoteEvent

-- Références injectées par GameLoop
local BoardManager: any = nil  -- BoardManager module
local ZombieSpawner: any = nil -- ZombieSpawner module

-------------------------------------------------
-- Types
-------------------------------------------------
type PlantCooldown = {
	LastFired: number,
	FireInterval: number,
}

-------------------------------------------------
-- Module
-------------------------------------------------
local CombatSystem = {}

-- Cooldowns par ID d'unité placée
local cooldowns: { [number]: PlantCooldown } = {}

-- Connexion Heartbeat
local heartbeatConnection: RBXScriptConnection? = nil

-------------------------------------------------
-- Init
-------------------------------------------------
function CombatSystem.Init(boardMgr: any, zombieSpawner: any): ()
	BoardManager = boardMgr
	ZombieSpawner = zombieSpawner
	print("[CombatSystem] ✅ Dépendances injectées")
end

-------------------------------------------------
-- Helpers
-------------------------------------------------

--- Trouve le zombie le plus proche dans la portée
local function findNearestZombie(plantPos: Vector3, range: number): (number?, number?)
	local bestId: number? = nil
	local bestDist: number = range + 1

	for id: number, zombie in ZombieSpawner.ActiveZombies do
		if zombie.Dead then
			continue
		end

		local zombiePos: Vector3 = zombie.Model.Position
		local dist: number = (plantPos - zombiePos).Magnitude

		if dist <= range and dist < bestDist then
			bestDist = dist
			bestId = id
		end
	end

	if bestId then
		return bestId, bestDist
	end
	return nil, nil
end

--- Crée un rayon laser visuel
local function createBeam(from: Vector3, to: Vector3, color: Color3): ()
	local distance: number = (to - from).Magnitude
	local midPoint: Vector3 = (from + to) / 2

	local beam: Part = Instance.new("Part")
	beam.Name = "AttackBeam"
	beam.Size = Vector3.new(0.3, 0.3, distance)
	beam.CFrame = CFrame.lookAt(midPoint, to)
	beam.Anchored = true
	beam.CanCollide = false
	beam.Material = Enum.Material.Neon
	beam.Color = color
	beam.Transparency = 0.2

	local gameBoard: Instance? = Workspace:FindFirstChild("GameBoard")
	beam.Parent = if gameBoard then gameBoard else Workspace

	local fadeTween: Tween = TweenService:Create(beam, TweenInfo.new(Constants.BEAM_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Transparency = 1,
		Size = Vector3.new(0.05, 0.05, distance),
	})
	fadeTween:Play()

	Debris:AddItem(beam, Constants.BEAM_DURATION + 0.05)
end

-------------------------------------------------
-- Boucle de combat (Heartbeat)
-------------------------------------------------

function CombatSystem.Start(): ()
	if heartbeatConnection then
		return
	end

	print("[CombatSystem] 🔥 Boucle de combat démarrée (Heartbeat)")

	heartbeatConnection = RunService.Heartbeat:Connect(function(_dt: number): ()
		local now: number = tick()

		-- Parcourir chaque unité placée
		for id: number, unit in BoardManager.PlacedUnits do
			local unitData = UnitDatabase[unit.UnitId]
			if unitData == nil then
				continue
			end

			-- Portée et cadence
			local range: number = unitData.Range or Constants.DEFAULT_RANGE
			local fireRate: number = unitData.FireRate or Constants.DEFAULT_FIRE_RATE
			local fireInterval: number = 1 / fireRate

			-- Cooldown
			local cd: PlantCooldown? = cooldowns[id]
			if cd == nil then
				cd = {
					LastFired = 0,
					FireInterval = fireInterval,
				}
				cooldowns[id] = cd
			end

			if (now - cd.LastFired) < cd.FireInterval then
				continue
			end

			-- Position de l'unité
			local plantPos: Vector3 = unit.Position

			-- Chercher le zombie le plus proche
			local targetId: number?, _dist: number? = findNearestZombie(plantPos, range)
			if targetId == nil then
				continue
			end

			local targetZombie = ZombieSpawner.ActiveZombies[targetId :: number]
			if targetZombie == nil or targetZombie.Dead then
				continue
			end

			-- TIR !
			cd.LastFired = now

			local damage: number = unitData.Damage
			ZombieSpawner.DamageZombie(targetId :: number, damage)

			-- Laser visuel
			local zombiePos: Vector3 = targetZombie.Model.Position
			createBeam(plantPos, zombiePos, unitData.Color)

			-- VFX projectile côté client
			unitFiredEvent:FireAllClients(plantPos, zombiePos, unit.UnitId)
		end
	end)
end

function CombatSystem.Stop(): ()
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
		print("[CombatSystem] ⏹️ Boucle de combat arrêtée")
	end
end

--- Nettoie le cooldown d'une unité supprimée
function CombatSystem.ClearCooldown(unitId: number): ()
	cooldowns[unitId] = nil
end

function CombatSystem.ResetCooldowns(): ()
	table.clear(cooldowns)
end

print("[CombatSystem] 📦 Module chargé")

return CombatSystem
