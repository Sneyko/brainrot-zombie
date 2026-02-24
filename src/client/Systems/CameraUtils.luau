--!strict

--[[
	CameraUtils (ModuleScript)
	Transitions fluides entre la vue 3ème personne classique
	et la vue Top-Down tactique (au-dessus de la grille de défense).
	Supporte le pan horizontal (ZQSD / flèches / bord d'écran) en mode Top-Down.

	Rojo : StarterPlayerScripts.Client.Systems.CameraUtils
]]

-- Services
local TweenService: TweenService = game:GetService("TweenService")
local Players: Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local sharedFolder: Instance = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(sharedFolder:WaitForChild("Constants"))

-------------------------------------------------
-- Module
-------------------------------------------------
local CameraUtils = {}

local player: Player = Players.LocalPlayer

-- Tween actif (pour pouvoir l'annuler lors d'un double toggle)
local activeTween: Tween? = nil

-- Pan offset actuel (X = horizontal, Z = profondeur)
local panOffsetX: number = 0
local panOffsetZ: number = 0

-- Flag : vrai si la caméra est en mode Top-Down
CameraUtils.IsTopDown = false

-------------------------------------------------
-- Helpers internes
-------------------------------------------------

--- Calcule la CFrame Top-Down avec le pan offset actuel
local function getTopDownCFrame(): CFrame
	local gridCenter: Vector3 = Constants.GetGridCenter()
	local camPos: Vector3 = Vector3.new(
		gridCenter.X + panOffsetX,
		Constants.TOPDOWN_CAM_HEIGHT,
		gridCenter.Z + panOffsetZ
	)
	local lookAt: Vector3 = Vector3.new(
		gridCenter.X + panOffsetX,
		Constants.GROUND_TOP_Y,
		gridCenter.Z + panOffsetZ
	)
	return CFrame.lookAt(camPos, lookAt)
end

-------------------------------------------------
-- TransitionToTopDown
-- Passe la caméra en mode Scriptable et tween vers
-- la vue Top-Down centrée sur la grille.
-------------------------------------------------
function CameraUtils.TransitionToTopDown(): ()
	-- Annuler tout tween en cours
	if activeTween then
		activeTween:Cancel()
		activeTween = nil
	end

	-- Reset le pan au centre
	panOffsetX = 0
	panOffsetZ = 0

	local camera: Camera = Workspace.CurrentCamera
	local targetCFrame: CFrame = getTopDownCFrame()

	-- Passer en mode Scriptable
	camera.CameraType = Enum.CameraType.Scriptable

	-- Tween fluide
	local tweenInfo: TweenInfo = TweenInfo.new(
		Constants.TOPDOWN_TWEEN_TIME,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.InOut
	)
	activeTween = TweenService:Create(camera, tweenInfo, {
		CFrame = targetCFrame,
	})
	activeTween:Play()

	CameraUtils.IsTopDown = true
	print("[CameraUtils] 📷 Transition → Top-Down (ZQSD / flèches pour bouger)")
end

-------------------------------------------------
-- TransitionToNormal
-- Tween retour vers le personnage, puis restaure Custom.
-------------------------------------------------
function CameraUtils.TransitionToNormal(): ()
	-- Annuler tout tween en cours
	if activeTween then
		activeTween:Cancel()
		activeTween = nil
	end

	CameraUtils.IsTopDown = false

	local camera: Camera = Workspace.CurrentCamera

	-- Trouver le personnage
	local character: Model? = player.Character
	if character == nil then
		camera.CameraType = Enum.CameraType.Custom
		return
	end

	local hrp: BasePart? = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp == nil then
		camera.CameraType = Enum.CameraType.Custom
		return
	end

	-- CFrame de transition douce vers le personnage
	local returnPos: Vector3 = hrp.Position + Vector3.new(0, 10, 10)
	local returnCFrame: CFrame = CFrame.lookAt(returnPos, hrp.Position)

	-- Tween fluide
	local tweenInfo: TweenInfo = TweenInfo.new(
		Constants.TOPDOWN_TWEEN_TIME,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.InOut
	)
	activeTween = TweenService:Create(camera, tweenInfo, {
		CFrame = returnCFrame,
	})
	activeTween:Play()

	activeTween.Completed:Connect(function(playbackState: Enum.PlaybackState): ()
		if playbackState == Enum.PlaybackState.Completed then
			camera.CameraType = Enum.CameraType.Custom
			print("[CameraUtils] 📷 Caméra restaurée → 3ème personne")
		end
	end)

	-- Reset pan
	panOffsetX = 0
	panOffsetZ = 0

	print("[CameraUtils] 📷 Transition → 3ème personne")
end

-------------------------------------------------
-- UpdatePan
-- Appelé chaque frame par TileSelector quand le mode
-- Top-Down est actif. Applique le delta de déplacement
-- (dt × vitesse), clamp dans les limites, et met à jour
-- la CFrame de la caméra directement (pas de Tween).
-------------------------------------------------
function CameraUtils.UpdatePan(dx: number, dz: number): ()
	if not CameraUtils.IsTopDown then return end

	panOffsetX += dx
	panOffsetZ += dz

	-- Clamp dans les limites
	panOffsetX = math.clamp(panOffsetX, -Constants.TOPDOWN_PAN_LIMIT_X, Constants.TOPDOWN_PAN_LIMIT_X)
	panOffsetZ = math.clamp(panOffsetZ, -Constants.TOPDOWN_PAN_LIMIT_Z, Constants.TOPDOWN_PAN_LIMIT_Z)

	-- Appliquer immédiatement (pas de Tween pour le pan = réactif)
	local camera: Camera = Workspace.CurrentCamera
	camera.CFrame = getTopDownCFrame()
end

-------------------------------------------------
-- GetPanOffset (pour debug ou UI)
-------------------------------------------------
function CameraUtils.GetPanOffset(): (number, number)
	return panOffsetX, panOffsetZ
end

print("[CameraUtils] ✅ Module chargé (pan horizontal supporté)")

return CameraUtils
