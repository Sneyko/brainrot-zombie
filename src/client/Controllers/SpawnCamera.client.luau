--!strict

--[[
	SpawnCamera (ClientScript)
	Gère une caméra de lobby agréable dans le Spawn Hub :
	  • Rotation lente autour du centre du spawn au démarrage
	  • Puis libère la caméra pour le contrôle joueur normal
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local sharedFolder: Instance = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(sharedFolder:WaitForChild("Constants"))

-- Joueur
local player: Player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local CENTER: Vector3 = Constants.SPAWN_CENTER
local CAMERA_HEIGHT: number = 60
local CAMERA_DIST: number = 100
local ROTATION_SPEED: number = 0.1 -- radians/seconde

-------------------------------------------------
-- Caméra cinématique (intro)
-------------------------------------------------
local function runIntroCamera(): ()
	camera.CameraType = Enum.CameraType.Scriptable
	
	local startAngle: number = 0
	local elapsed: number = 0
	local INTRO_DURATION: number = 5 -- secondes
	
	local connection: RBXScriptConnection?
	connection = RunService.RenderStepped:Connect(function(dt: number)
		elapsed += dt
		
		if elapsed >= INTRO_DURATION then
			if connection then
				connection:Disconnect()
			end
			-- Rendre la caméra au joueur
			camera.CameraType = Enum.CameraType.Custom
			return
		end
		
		local angle: number = startAngle + elapsed * ROTATION_SPEED
		local camPos: Vector3 = CENTER + Vector3.new(
			math.cos(angle) * CAMERA_DIST,
			CAMERA_HEIGHT,
			math.sin(angle) * CAMERA_DIST
		)
		
		camera.CFrame = CFrame.lookAt(camPos, CENTER + Vector3.new(0, 5, 0))
	end)
end

-- Attendre que le personnage spawn avant de lancer la caméra
local character = player.Character or player.CharacterAdded:Wait()
task.wait(0.5) -- Petit délai pour laisser le spawn se construire

runIntroCamera()

print("[SpawnCamera] ✅ Caméra d'intro lancée")
