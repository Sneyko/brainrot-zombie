--!strict

--[[
	ZombieManager (ModuleScript)
	Phase 4 — Gère le spawn et la marche automatique des zombies.
	Appelé par GameLoop à chaque phase correspondante.
	Accessible depuis : ServerScriptService.Server.Systems.ZombieManager
]]

-- Services
local TweenService: TweenService = game:GetService("TweenService")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local sharedFolder: Instance = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(sharedFolder:WaitForChild("Constants"))
local UnitDatabase = require(sharedFolder:WaitForChild("Data"):WaitForChild("UnitDatabase"))

-- BoardManager sera injecté via init() pour éviter la dépendance circulaire
local BoardManager: any = nil

-------------------------------------------------
-- Types
-------------------------------------------------
local ZombieManager = {}

-------------------------------------------------
-- Constantes
-------------------------------------------------
local ROWS: number = Constants.GRID_ROWS
local COLS: number = Constants.GRID_COLS
local SPAWN_COL: number = COLS           -- Colonne 9 = zone de spawn zombie
local MARCH_TWEEN_DURATION: number = 0.4 -- Durée du tween de déplacement
local DEFAULT_ZOMBIE_ID: string = "BasicSkibidi"

-- Vague : nombre de zombies spawnés selon le tour
local BASE_ZOMBIES: number = 1
local WAVE_INTERVAL: number = 3  -- Tous les 3 tours, +1 zombie

-- RNG
local rng: Random = Random.new()

-------------------------------------------------
-- Initialisation (appelé une fois par GameLoop)
-------------------------------------------------

function ZombieManager.Init(boardManager: any): ()
	BoardManager = boardManager
	print("[ZombieManager] ✅ ZombieManager initialisé")
end

-------------------------------------------------
-- Fonctionnalité A : Spawn des Zombies
-------------------------------------------------

--- Calcule le nombre de zombies à spawner selon le numéro de tour
function ZombieManager.GetSpawnCount(turnNumber: number): number
	-- Tour 1-3 : 1 zombie / Tour 4-6 : 2 zombies / etc.
	return BASE_ZOMBIES + math.floor((turnNumber - 1) / WAVE_INTERVAL)
end

--- Spawne les zombies du tour en colonne SPAWN_COL
function ZombieManager.SpawnWave(turnNumber: number): number
	if BoardManager == nil then
		warn("[ZombieManager] ❌ BoardManager non initialisé — appeler Init() d'abord")
		return 0
	end

	local count: number = ZombieManager.GetSpawnCount(turnNumber)
	local spawned: number = 0

	-- Mélanger l'ordre des lignes pour varier les spawns
	local rowOrder: { number } = {}
	for r = 1, ROWS do
		table.insert(rowOrder, r)
	end
	-- Fisher-Yates shuffle
	for i = ROWS, 2, -1 do
		local j: number = rng:NextInteger(1, i)
		rowOrder[i], rowOrder[j] = rowOrder[j], rowOrder[i]
	end

	for _, row: number in rowOrder do
		if spawned >= count then
			break
		end

		-- Vérifier si la case (row, SPAWN_COL) est libre
		if BoardManager:IsEmpty(row, SPAWN_COL) then
			local success: boolean, _msg: string = BoardManager:SpawnZombie(DEFAULT_ZOMBIE_ID, row, SPAWN_COL)
			if success then
				spawned += 1
				print(`[ZombieManager] 🧟 Spawn : {DEFAULT_ZOMBIE_ID} en ({row}, {SPAWN_COL})`)
			end
		end
	end

	print(`[ZombieManager] 🧟 Vague du tour {turnNumber} : {spawned}/{count} zombies spawnés`)
	return spawned
end

-------------------------------------------------
-- Fonctionnalité B : Auto-March
-------------------------------------------------

--- Tween le modèle 3D d'une unité vers sa nouvelle position
local function tweenModelToPosition(model: Part, targetPosition: Vector3): ()
	local tweenInfo: TweenInfo = TweenInfo.new(
		MARCH_TWEEN_DURATION,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.InOut
	)

	local tween: Tween = TweenService:Create(model, tweenInfo, {
		Position = targetPosition,
	})
	tween:Play()
	tween.Completed:Wait()
end

--- Exécute la marche automatique de tous les zombies
--- Parcourt de gauche à droite pour ne pas déplacer un zombie deux fois
function ZombieManager.AutoMarch(): { gameOver: boolean, zombiesPassed: number }
	if BoardManager == nil then
		warn("[ZombieManager] ❌ BoardManager non initialisé")
		return { gameOver = false, zombiesPassed = 0 }
	end

	local zombiesPassed: number = 0
	local gameOver: boolean = false

	-- Parcourir de Col 1 → Col 9 (gauche à droite)
	-- On traite chaque zombie dans l'ordre pour éviter les double-mouvements
	for col = 1, COLS do
		for row = 1, ROWS do
			local cell = BoardManager:GetCell(row, col)
			if cell == nil or cell.Type ~= "Zombie" then
				continue
			end

			local unitId: string = cell.UnitId or DEFAULT_ZOMBIE_ID
			local unitData = UnitDatabase[unitId]
			local moveSpeed: number = if unitData and unitData.MoveSpeed then unitData.MoveSpeed else 1

			-- Calculer la case cible (se déplace vers la gauche)
			local targetCol: number = col - moveSpeed

			-- GAME OVER : le zombie dépasse la grille
			if targetCol < 1 then
				print(`[ZombieManager] 💀 GAME OVER — Zombie {unitId} en ({row}, {col}) a franchi la défense !`)
				-- Retirer le zombie du board
				BoardManager:ClearCell(row, col)
				zombiesPassed += 1
				gameOver = true
				continue
			end

			-- Vérifier la case cible
			local targetCell = BoardManager:GetCell(row, targetCol)
			if targetCell == nil then
				continue
			end

			if targetCell.Type == "Plant" then
				-- COLLISION avec une plante → le zombie s'arrête (combat Phase 5)
				print(`[ZombieManager] ⚔️ Collision : {unitId} ({row},{col}) bloqué par {targetCell.UnitId or "?"} en ({row},{targetCol})`)
				continue
			end

			if targetCell.Type == "Zombie" then
				-- Case occupée par un autre zombie → s'arrête
				print(`[ZombieManager] 🚫 Bloqué : {unitId} ({row},{col}) — zombie devant en ({row},{targetCol})`)
				continue
			end

			-- Case vide → déplacer
			-- Sauvegarder la référence au modèle avant le move
			local modelRef: Part? = cell.ModelRef

			-- Déplacer dans le BoardState
			local success: boolean, _msg: string = BoardManager:MoveUnit(row, col, row, targetCol)
			if not success then
				continue
			end

			-- Tween le modèle 3D vers la nouvelle position
			if modelRef then
				local targetPos: Vector3 = BoardManager:GetTilePosition(row, targetCol)
				local unitSize: number = modelRef.Size.Y
				local finalPos: Vector3 = targetPos + Vector3.new(0, 0.4 / 2 + unitSize / 2, 0)
				tweenModelToPosition(modelRef, finalPos)
			end

			print(`[ZombieManager] 🚶 Marche : {unitId} ({row},{col}) → ({row},{targetCol})`)
		end
	end

	if gameOver then
		warn("[ZombieManager] 💀 GAME OVER — Au moins un zombie est passé !")
	else
		print(`[ZombieManager] ✅ Auto-March terminée — 0 zombie passé`)
	end

	return { gameOver = gameOver, zombiesPassed = zombiesPassed }
end

print("[ZombieManager] 📦 Module chargé")

return ZombieManager
