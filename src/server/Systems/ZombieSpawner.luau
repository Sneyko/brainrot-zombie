--!strict

--[[
	ZombieSpawner (ModuleScript)
	Tower Defense temps réel — Spawn + mouvement fluide des zombies.
	Les zombies apparaissent en col 9 et avancent fluidement vers col 1.
	Accessible depuis : ServerScriptService.Server.Systems.ZombieSpawner
]]

-- Services
local Workspace: Workspace = game:GetService("Workspace")
local TweenService: TweenService = game:GetService("TweenService")
local RunService: RunService = game:GetService("RunService")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local sharedFolder: Instance = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(sharedFolder:WaitForChild("Constants"))
local UnitDatabase = require(sharedFolder:WaitForChild("Data"):WaitForChild("UnitDatabase"))

-- Dossier Assets (modèle zombie)
local assetsFolder: Folder = ReplicatedStorage:WaitForChild("Assets") :: Folder

-------------------------------------------------
-- Types
-------------------------------------------------
export type ZombieInstance = {
	Id: number,
	UnitId: string,
	HP: number,
	MaxHP: number,
	Damage: number,
	MoveSpeed: number,
	Model: Part,
	Visual: Model?,         -- Modèle 3D visuel (cloné depuis Assets)
	VisualOffset: CFrame?,  -- Offset du modèle par rapport à l'ancre
	Row: number,
	Tween: Tween?,
	Dead: boolean,
}

-------------------------------------------------
-- Module
-------------------------------------------------
local ZombieSpawner = {}

-- Registre de tous les zombies actifs (clé = id unique)
ZombieSpawner.ActiveZombies = {} :: { [number]: ZombieInstance }
local nextZombieId: number = 0

-- Callbacks (injectés par le GameLoop)
ZombieSpawner.OnZombieReachedEnd = nil :: ((zombie: ZombieInstance) -> ())?
ZombieSpawner.OnZombieDied = nil :: ((zombie: ZombieInstance) -> ())?

-------------------------------------------------
-- Constantes de grille
-------------------------------------------------
local ROWS: number = Constants.GRID_ROWS
local COLS: number = Constants.GRID_COLS
local TILE_SIZE: number = Constants.TILE_SIZE
local CELL_STEP: number = TILE_SIZE + Constants.TILE_SPACING
local LANE_WIDTH: number = ROWS * CELL_STEP
local SPAWN_COL: number = COLS

-- Positions (zombies marchent sur le sol)
local WALL_CENTER_X: number = Constants.WALL_POSITION.X
local GROUND_TOP_Y: number = Constants.GROUND_TOP_Y
local ZOMBIE_SPAWN_Z: number = Constants.ZOMBIE_SPAWN_Z
local ZOMBIE_BASE_Z: number = Constants.ZOMBIE_BASE_Z

-- RNG
local rng: Random = Random.new()

-------------------------------------------------
-- Helpers
-------------------------------------------------

--- Calcule la position world d'un zombie sur le sol (row → X, col → Z interpolé)
local function getTilePosition(row: number, col: number): Vector3
	local x: number = WALL_CENTER_X + (row - 1) * CELL_STEP - LANE_WIDTH / 2 + TILE_SIZE / 2
	local t: number = col / COLS
	local z: number = ZOMBIE_BASE_Z + t * (ZOMBIE_SPAWN_Z - ZOMBIE_BASE_Z)
	return Vector3.new(x, GROUND_TOP_Y, z)
end

--- Taille cible des zombies (studs de haut)
local ZOMBIE_MODEL_HEIGHT: number = 5

--- Crée le modèle 3D d'un zombie (clone depuis Assets/Unit_Zombie)
local function createZombieModel(unitId: string, row: number, spawnPosition: Vector3): Part
	local unitData = UnitDatabase[unitId]
	local unitSize: number = TILE_SIZE * 0.55

	-- Part ancre invisible (sert de root pour le tween)
	local anchor: Part = Instance.new("Part")
	anchor.Name = `Zombie_{unitId}_{nextZombieId}`
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Position = spawnPosition + Vector3.new(0, unitSize / 2, 0)

	-- Cloner le modèle visuel depuis Assets
	local template: Instance? = assetsFolder:FindFirstChild("Unit_Zombie")
	if template and template:IsA("Model") then
		local visual: Model = template:Clone() :: Model

		-- Uniformiser la taille
		local _, origSize: Vector3 = visual:GetBoundingBox()
		if origSize.Y > 0 then
			local currentScale: number = visual:GetScale()
			local scaleFactor: number = (ZOMBIE_MODEL_HEIGHT / origSize.Y) * currentScale
			visual:ScaleTo(scaleFactor)
		end

		-- Positionner et orienter (face au mur, -Z)
		local _, scaledSize: Vector3 = visual:GetBoundingBox()
		local visualY: number = spawnPosition.Y + scaledSize.Y / 2
		local visualPos: Vector3 = Vector3.new(spawnPosition.X, visualY, spawnPosition.Z)
		local lookTarget: Vector3 = visualPos + Vector3.new(0, 0, -1)
		visual:PivotTo(CFrame.lookAt(visualPos, lookTarget))

		-- Ancrer toutes les parts (pas de WeldConstraint — sync via Heartbeat)
		for _, desc: Instance in visual:GetDescendants() do
			if desc:IsA("BasePart") then
				local bp: BasePart = desc :: BasePart
				bp.Anchored = true
				bp.CanCollide = false
			end
		end

		-- Mettre à jour la position de l'ancre pour correspondre au centre du modèle
		anchor.Position = visualPos
		visual.Parent = anchor

		-- Stocker le modèle visuel dans l'ancre pour le retrouver plus tard
		visual:SetAttribute("IsZombieVisual", true)
	else
		-- Fallback : bloc coloré si pas d'asset
		anchor.Transparency = 0
		anchor.Size = Vector3.new(unitSize, unitSize, unitSize)
		anchor.Material = Enum.Material.SmoothPlastic
		anchor.Shape = Enum.PartType.Block
		anchor.Color = if unitData then unitData.Color else Color3.fromRGB(140, 90, 50)
		anchor.Position = spawnPosition + Vector3.new(0, unitSize / 2, 0)
	end

	-- Label au-dessus
	local billboard: BillboardGui = Instance.new("BillboardGui")
	billboard.Name = "ZombieLabel"
	billboard.Size = UDim2.fromOffset(120, 40)
	billboard.StudsOffset = Vector3.new(0, ZOMBIE_MODEL_HEIGHT / 2 + 1.5, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 60

	local nameLabel: TextLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.fromScale(1, 0.5)
	nameLabel.Position = UDim2.fromScale(0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = if unitData then unitData.Name else unitId
	nameLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.Parent = billboard

	-- Barre de vie
	local hpBg: Frame = Instance.new("Frame")
	hpBg.Name = "HPBackground"
	hpBg.Size = UDim2.fromScale(0.8, 0.3)
	hpBg.Position = UDim2.fromScale(0.1, 0.6)
	hpBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	hpBg.BorderSizePixel = 0
	hpBg.Parent = billboard

	local hpCorner: UICorner = Instance.new("UICorner")
	hpCorner.CornerRadius = UDim.new(0.3, 0)
	hpCorner.Parent = hpBg

	local hpFill: Frame = Instance.new("Frame")
	hpFill.Name = "HPFill"
	hpFill.Size = UDim2.fromScale(1, 1)
	hpFill.BackgroundColor3 = Color3.fromRGB(80, 220, 80)
	hpFill.BorderSizePixel = 0
	hpFill.Parent = hpBg

	local hpFillCorner: UICorner = Instance.new("UICorner")
	hpFillCorner.CornerRadius = UDim.new(0.3, 0)
	hpFillCorner.Parent = hpFill

	billboard.Parent = anchor

	-- Placer dans le dossier GameBoard
	local gameBoard: Instance? = Workspace:FindFirstChild("GameBoard")
	if gameBoard then
		anchor.Parent = gameBoard
	else
		anchor.Parent = Workspace
	end

	return anchor
end

--- Met à jour la barre de vie visuelle
local function updateHPBar(zombie: ZombieInstance): ()
	local billboard: BillboardGui? = zombie.Model:FindFirstChild("ZombieLabel") :: BillboardGui?
	if billboard == nil then return end

	local hpBg: Frame? = billboard:FindFirstChild("HPBackground") :: Frame?
	if hpBg == nil then return end

	local hpFill: Frame? = hpBg:FindFirstChild("HPFill") :: Frame?
	if hpFill == nil then return end

	local ratio: number = math.clamp(zombie.HP / zombie.MaxHP, 0, 1)
	TweenService:Create(hpFill, TweenInfo.new(0.2), {
		Size = UDim2.fromScale(ratio, 1),
		BackgroundColor3 = if ratio > 0.5
			then Color3.fromRGB(80, 220, 80)
			elseif ratio > 0.25
			then Color3.fromRGB(255, 200, 40)
			else Color3.fromRGB(255, 50, 50),
	}):Play()
end

-------------------------------------------------
-- Spawn
-------------------------------------------------

--- Spawn un zombie sur une ligne donnée, en col 9
function ZombieSpawner.SpawnZombie(unitId: string, row: number?): ZombieInstance?
	local spawnRow: number = row or rng:NextInteger(1, ROWS)
	local unitData = UnitDatabase[unitId]
	if unitData == nil or unitData.Type ~= "Zombie" then
		warn(`[ZombieSpawner] ❌ Unité invalide : {unitId}`)
		return nil
	end

	nextZombieId += 1
	local id: number = nextZombieId

	local spawnPos: Vector3 = getTilePosition(spawnRow, SPAWN_COL)
	local model: Part = createZombieModel(unitId, spawnRow, spawnPos)

	-- Retrouver le modèle visuel (enfant Model avec attribut)
	local visualModel: Model? = nil
	for _, child: Instance in model:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("IsZombieVisual") then
			visualModel = child :: Model
			break
		end
	end

	-- Calculer l'offset entre l'ancre et le pivot du modèle visuel
	local visualOffset: CFrame? = nil
	if visualModel then
		visualOffset = model.CFrame:Inverse() * visualModel:GetPivot()
	end

	local zombie: ZombieInstance = {
		Id = id,
		UnitId = unitId,
		HP = unitData.HP,
		MaxHP = unitData.HP,
		Damage = unitData.Damage,
		MoveSpeed = unitData.MoveSpeed or Constants.ZOMBIE_SPEED,
		Model = model,
		Visual = visualModel,
		VisualOffset = visualOffset,
		Row = spawnRow,
		Tween = nil,
		Dead = false,
	}

	ZombieSpawner.ActiveZombies[id] = zombie

	-- Démarrer le mouvement fluide
	ZombieSpawner._startMovement(zombie)

	print(`[ZombieSpawner] 🧟 Spawn : {unitData.Name} (ID:{id}) en row {spawnRow}`)
	return zombie
end

-------------------------------------------------
-- Mouvement fluide (TweenService)
-------------------------------------------------

--- Lance le tween de mouvement continu d'un zombie vers le bord gauche
function ZombieSpawner._startMovement(zombie: ZombieInstance): ()
	if zombie.Dead then return end

	-- Position cible : col 0 (pied du mur)
	local targetPos: Vector3 = getTilePosition(zombie.Row, 0)
	local unitSize: number = zombie.Model.Size.Y
	local finalY: number = GROUND_TOP_Y + unitSize / 2
	local destination: Vector3 = Vector3.new(targetPos.X, finalY, targetPos.Z)

	-- Calculer la distance restante
	local currentPos: Vector3 = zombie.Model.Position
	local distance: number = (destination - currentPos).Magnitude
	local duration: number = distance / zombie.MoveSpeed

	local tweenInfo: TweenInfo = TweenInfo.new(
		duration,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.InOut
	)

	local tween: Tween = TweenService:Create(zombie.Model, tweenInfo, {
		Position = destination,
	})

	zombie.Tween = tween

	tween.Completed:Connect(function(playbackState: Enum.PlaybackState): ()
		if playbackState ~= Enum.PlaybackState.Completed then
			return
		end
		if zombie.Dead then
			return
		end

		-- Le zombie a atteint le bord gauche !
		print(`[ZombieSpawner] 💀 Zombie {zombie.UnitId} (ID:{zombie.Id}) a franchi la défense !`)

		if ZombieSpawner.OnZombieReachedEnd then
			ZombieSpawner.OnZombieReachedEnd(zombie)
		end

		ZombieSpawner.DestroyZombie(zombie.Id)
	end)

	tween:Play()
end

-------------------------------------------------
-- Dégâts / Mort
-------------------------------------------------

--- Inflige des dégâts à un zombie
function ZombieSpawner.DamageZombie(zombieId: number, damage: number): ()
	local zombie: ZombieInstance? = ZombieSpawner.ActiveZombies[zombieId]
	if zombie == nil or zombie.Dead then return end

	zombie.HP -= damage
	updateHPBar(zombie)

	if zombie.HP <= 0 then
		zombie.Dead = true

		-- Callback de mort (cash reward)
		if ZombieSpawner.OnZombieDied then
			ZombieSpawner.OnZombieDied(zombie)
		end

		ZombieSpawner.DestroyZombie(zombieId)
	end
end

--- Détruit un zombie (nettoyage complet)
function ZombieSpawner.DestroyZombie(zombieId: number): ()
	local zombie: ZombieInstance? = ZombieSpawner.ActiveZombies[zombieId]
	if zombie == nil then return end

	zombie.Dead = true

	-- Arrêter le tween
	if zombie.Tween then
		zombie.Tween:Cancel()
		zombie.Tween = nil
	end

	-- Détruire le modèle 3D
	if zombie.Model then
		zombie.Model:Destroy()
	end

	ZombieSpawner.ActiveZombies[zombieId] = nil
end

--- Retourne le nombre de zombies actifs
function ZombieSpawner.GetActiveCount(): number
	local count: number = 0
	for _ in ZombieSpawner.ActiveZombies do
		count += 1
	end
	return count
end

print("[ZombieSpawner] 📦 Module chargé")

-------------------------------------------------
-- Boucle Heartbeat : synchroniser le modèle visuel
-- avec la position de l'ancre invisible twinnée.
-------------------------------------------------
RunService.Heartbeat:Connect(function(): ()
	for _, zombie: ZombieInstance in ZombieSpawner.ActiveZombies do
		if zombie.Dead then continue end
		if zombie.Visual == nil or zombie.VisualOffset == nil then continue end

		-- Déplacer le modèle visuel pour suivre l'ancre
		local targetCFrame: CFrame = zombie.Model.CFrame * zombie.VisualOffset
		zombie.Visual:PivotTo(targetCFrame)
	end
end)

return ZombieSpawner
