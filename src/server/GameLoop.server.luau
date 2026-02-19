--!strict

--[[
	GameLoop (ServerScript)
	Tower Defense temps réel — WaveManager + économie BrainCoin.
	Placement via plaques Touched sur le mur.
	Accessible depuis : ServerScriptService.Server.GameLoop
]]

-- Services
local Players: Players = game:GetService("Players")
local Workspace: Workspace = game:GetService("Workspace")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local sharedFolder: Instance = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(sharedFolder:WaitForChild("Constants"))
local BoardManager = require(script.Parent:WaitForChild("Systems"):WaitForChild("BoardManager"))
local UnitDatabase = require(sharedFolder:WaitForChild("Data"):WaitForChild("UnitDatabase"))
local ZombieSpawner = require(script.Parent:WaitForChild("Systems"):WaitForChild("ZombieSpawner"))
local CombatSystem = require(script.Parent:WaitForChild("Systems"):WaitForChild("CombatSystem"))

-- Initialiser le CombatSystem
CombatSystem.Init(BoardManager, ZombieSpawner)

-- RemoteEvents
local eventsFolder: Folder = sharedFolder:WaitForChild("Events") :: Folder
local budgetUpdateEvent: RemoteEvent = eventsFolder:WaitForChild("BudgetUpdate") :: RemoteEvent

-- Constantes
local MIN_PLAYERS: number = 1
local PLATE_DEBOUNCE: number = 2  -- Secondes entre deux achats par joueur

-- RNG
local rng: Random = Random.new()

-- Types de zombies
local ZOMBIE_TYPES: { string } = { "BasicSkibidi", "BasicZombie" }
local ELITE_ZOMBIE: string = "NikeShark"
local ELITE_WAVE_INTERVAL: number = 3

-------------------------------------------------
-- État du jeu
-------------------------------------------------
local playerBrainCoin: number = Constants.STARTING_BRAINCOIN
local baseHP: number = Constants.BASE_HP
local currentWave: number = 0
local gameOver: boolean = false

-- Debounce par joueur+plaque ("UserId_UnitId" → temps du dernier achat)
local plateDebounce: { [string]: number } = {}

-------------------------------------------------
-- Helpers
-------------------------------------------------

local function waitForPlayers(): ()
	print("[GameLoop] ⏳ En attente de joueurs...")
	while #Players:GetPlayers() < MIN_PLAYERS do
		task.wait(1)
	end
	print(`[GameLoop] ✅ {#Players:GetPlayers()} joueur(s) connecté(s) — Démarrage !`)
end

local function broadcastBrainCoin(): ()
	budgetUpdateEvent:FireAllClients(playerBrainCoin, baseHP)
end

local function addBrainCoin(amount: number): ()
	playerBrainCoin += amount
	broadcastBrainCoin()
end

-------------------------------------------------
-- Callbacks ZombieSpawner
-------------------------------------------------

ZombieSpawner.OnZombieDied = function(zombie)
	print(`[GameLoop] 💀 Zombie {zombie.UnitId} (ID:{zombie.Id}) tué ! +{Constants.KILL_REWARD} BrainCoin`)
	addBrainCoin(Constants.KILL_REWARD)
end

ZombieSpawner.OnZombieReachedEnd = function(zombie)
	baseHP -= zombie.Damage
	print(`[GameLoop] 🏠 Base touchée ! -{zombie.Damage} HP → {baseHP}/{Constants.BASE_HP}`)
	broadcastBrainCoin()

	if baseHP <= 0 and not gameOver then
		gameOver = true
		warn(`[GameLoop] 💀 GAME OVER — La base est détruite ! (Vague {currentWave})`)
	end
end

-------------------------------------------------
-- Placement via Touched (plaques sur le mur)
-------------------------------------------------

--- Remonte l'arborescence pour trouver le Character (gère Accessories)
local function getCharacterFromPart(part: BasePart): Model?
	local current: Instance? = part.Parent
	while current do
		if current:IsA("Model") and current:FindFirstChildOfClass("Humanoid") then
			return current :: Model
		end
		current = current.Parent
	end
	return nil
end

--- Connecte les événements Touched sur les 4 plaques d'achat
local function setupPlates(): ()
	local gameBoard: Folder = Workspace:WaitForChild("GameBoard") :: Folder

	for _, unitId: string in Constants.PLANT_UNITS do
		local plateName: string = `Plate_{unitId}`
		local plate: Part? = gameBoard:FindFirstChild(plateName) :: Part?
		if plate == nil then
			warn(`[GameLoop] ⚠️ Plaque introuvable : {plateName}`)
			continue
		end

		plate.Touched:Connect(function(otherPart: BasePart): ()
			if gameOver then return end

			-- Trouver le Character (gère accessoires + body parts)
			local character: Model? = getCharacterFromPart(otherPart)
			if character == nil then return end

			local player: Player? = Players:GetPlayerFromCharacter(character)
			if player == nil then return end

			-- Debounce par joueur + plaque
			local debounceKey: string = `{player.UserId}_{unitId}`
			local now: number = tick()
			local lastBuy: number = plateDebounce[debounceKey] or 0
			if (now - lastBuy) < PLATE_DEBOUNCE then return end

			-- Vérifier données de l'unité
			local unitData = UnitDatabase[unitId]
			if unitData == nil then
				warn(`[GameLoop] ⚠️ UnitDatabase["{unitId}"] introuvable`)
				return
			end

			-- Vérifier BrainCoin
			local cost: number = unitData.Cost
			if playerBrainCoin < cost then
				print(`[GameLoop] ❌ BrainCoin insuffisant pour {unitData.Name} : {playerBrainCoin}/{cost}`)
				return
			end

			-- Debounce activé
			plateDebounce[debounceKey] = now

			-- Déduire le coût
			playerBrainCoin -= cost
			broadcastBrainCoin()

			-- Position de spawn sur le sol (aléatoire dans la zone)
			local spawnX: number = Constants.WALL_POSITION.X + rng:NextNumber(
				-Constants.UNIT_SPAWN_X_SPREAD,
				Constants.UNIT_SPAWN_X_SPREAD
			)
			local spawnZ: number = rng:NextNumber(
				Constants.UNIT_SPAWN_Z_MIN,
				Constants.UNIT_SPAWN_Z_MAX
			)
			local spawnPos: Vector3 = Vector3.new(spawnX, Constants.GROUND_TOP_Y, spawnZ)

			print(`[GameLoop] 🔧 Spawn {unitData.Name} à ({math.floor(spawnX)}, {Constants.GROUND_TOP_Y}, {math.floor(spawnZ)})`)

			-- Placer l'unité sur le sol (clone depuis Assets)
			local unitIdResult: number = BoardManager.PlaceUnit(unitId, spawnPos, player)

			if unitIdResult < 0 then
				-- Rembourser si échec
				playerBrainCoin += cost
				broadcastBrainCoin()
				warn(`[GameLoop] ❌ Échec placement {unitData.Name}`)
				return
			end

			print(`[GameLoop] 🧠 {unitData.Name} acheté ! BrainCoin restant : {playerBrainCoin} (-{cost})`)
		end)

		print(`[GameLoop] 🔗 Plaque connectée : {plateName}`)
	end
end

-------------------------------------------------
-- Système de vagues
-------------------------------------------------

local function spawnWave(waveNumber: number): ()
	local zombieCount: number = Constants.BASE_ZOMBIES_PER_WAVE + (waveNumber - 1) * Constants.ZOMBIES_INCREMENT

	print(`[GameLoop] 🌊 VAGUE {waveNumber} — {zombieCount} zombie(s)`)

	for i = 1, zombieCount do
		if gameOver then break end

		local zombieType: string
		if waveNumber >= ELITE_WAVE_INTERVAL and i == zombieCount and waveNumber % ELITE_WAVE_INTERVAL == 0 then
			zombieType = ELITE_ZOMBIE
		else
			zombieType = ZOMBIE_TYPES[rng:NextInteger(1, #ZOMBIE_TYPES)]
		end

		ZombieSpawner.SpawnZombie(zombieType)

		if i < zombieCount then
			task.wait(Constants.WAVE_SPAWN_INTERVAL)
		end
	end
end

local function waitForWaveEnd(): ()
	while ZombieSpawner.GetActiveCount() > 0 and not gameOver do
		task.wait(0.5)
	end
end

-------------------------------------------------
-- Boucle principale
-------------------------------------------------
print("[GameLoop] 🎮 GameLoop démarrée (Tower Defense — plaques d'achat)")

task.spawn(function(): ()
	waitForPlayers()

	-- Connecter les plaques d'achat
	setupPlates()

	-- Broadcast BrainCoin initiaux
	broadcastBrainCoin()

	-- Démarrer le CombatSystem
	CombatSystem.Start()

	-- Pause initiale
	print("[GameLoop] ⏳ Première vague dans 5 secondes...")
	task.wait(5)

	-- Boucle de vagues
	while not gameOver do
		currentWave += 1
		spawnWave(currentWave)
		waitForWaveEnd()

		if gameOver then break end

		print(`[GameLoop] 🏆 Vague {currentWave} terminée ! +{Constants.WAVE_BONUS} BrainCoin bonus`)
		addBrainCoin(Constants.WAVE_BONUS)

		print(`[GameLoop] ⏸️ Prochaine vague dans {Constants.WAVE_PAUSE}s...`)
		task.wait(Constants.WAVE_PAUSE)
	end

	CombatSystem.Stop()
	print(`[GameLoop] 🏁 Partie terminée à la vague {currentWave}`)
end)
