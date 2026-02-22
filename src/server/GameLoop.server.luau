--!strict

--[[
	GameLoop (ServerScript)
	Tower Defense temps réel — Système de niveaux + vagues + économie BrainCoin.
	Placement via plaques Touched sur le mur.
	Chaque niveau a un nombre limité de vagues et des paramètres de difficulté.
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
local LevelDatabase = require(sharedFolder:WaitForChild("Data"):WaitForChild("LevelDatabase"))
local PlayerInventory = require(script.Parent:WaitForChild("Systems"):WaitForChild("PlayerInventory"))
local GachaCatalog = require(sharedFolder:WaitForChild("Data"):WaitForChild("GachaCatalog"))

-- Initialiser le CombatSystem
CombatSystem.Init(BoardManager, ZombieSpawner)

-- RemoteEvents
local eventsFolder: Folder = sharedFolder:WaitForChild("Events") :: Folder
local budgetUpdateEvent: RemoteEvent = eventsFolder:WaitForChild("BudgetUpdate") :: RemoteEvent
local stateChangedEvent: RemoteEvent = eventsFolder:WaitForChild("StateChanged") :: RemoteEvent
local levelSelectEvent: RemoteEvent = eventsFolder:WaitForChild("LevelSelect") :: RemoteEvent
local gachaInfoEvent: RemoteEvent = eventsFolder:WaitForChild("GachaInfo") :: RemoteEvent

-- Constantes
local MIN_PLAYERS: number = 1
local PLATE_DEBOUNCE: number = 2  -- Secondes entre deux achats par joueur
local TOTAL_LEVELS: number = #LevelDatabase

-- RNG
local rng: Random = Random.new()

-------------------------------------------------
-- État du jeu
-------------------------------------------------
local playerBrainCoin: number = 0
local baseHP: number = Constants.BASE_HP
local currentLevel: number = 0
local currentWave: number = 0
local totalWavesInLevel: number = 0
local gameOver: boolean = false
local gameWon: boolean = false

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

local function broadcastGameState(): ()
	budgetUpdateEvent:FireAllClients(playerBrainCoin, baseHP, currentLevel, currentWave, totalWavesInLevel)
end

local function broadcastLevelEvent(eventType: string, data: { [string]: any }?): ()
	stateChangedEvent:FireAllClients(eventType, data or {})
end

local function addBrainCoin(amount: number): ()
	playerBrainCoin += amount
	broadcastGameState()
end

-------------------------------------------------
-- Callbacks ZombieSpawner
-------------------------------------------------

local function getLevelData(): any
	if currentLevel >= 1 and currentLevel <= TOTAL_LEVELS then
		return LevelDatabase[currentLevel]
	end
	return nil
end

ZombieSpawner.OnZombieDied = function(zombie)
	local levelData = getLevelData()
	local reward: number = if levelData then levelData.KillReward else Constants.KILL_REWARD
	print(`[GameLoop] 💀 Zombie {zombie.UnitId} (ID:{zombie.Id}) tué ! +{reward} BrainCoin`)
	addBrainCoin(reward)
end

ZombieSpawner.OnZombieReachedEnd = function(zombie)
	baseHP -= zombie.Damage
	print(`[GameLoop] 🏠 Base touchée ! -{zombie.Damage} HP → {baseHP}/{Constants.BASE_HP}`)
	broadcastGameState()

	if baseHP <= 0 and not gameOver then
		gameOver = true
		warn(`[GameLoop] 💀 GAME OVER — La base est détruite ! (Niveau {currentLevel}, Vague {currentWave}/{totalWavesInLevel})`)
		broadcastLevelEvent("GameOver", {
			Level = currentLevel,
			Wave = currentWave,
		})
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
			if gameOver or gameWon then return end

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

			-- Vérifier que le joueur possède l'unité (inventaire Gacha)
			if not PlayerInventory.OwnsUnit(player, unitId) then
				print(`[GameLoop] 🔒 {player.Name} ne possède pas {unitData.Name}`)
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
			broadcastGameState()

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
				broadcastGameState()
				warn(`[GameLoop] ❌ Échec placement {unitData.Name}`)
				return
			end

			print(`[GameLoop] 🧠 {unitData.Name} acheté ! BrainCoin restant : {playerBrainCoin} (-{cost})`)
		end)

		print(`[GameLoop] 🔗 Plaque connectée : {plateName}`)
	end
end

-------------------------------------------------
-- Système de vagues par niveau
-------------------------------------------------

local function spawnWave(levelData: any, waveNumber: number): ()
	local zombieCount: number = levelData.BaseZombieCount + (waveNumber - 1) * levelData.ZombieIncrement
	local isBossWave: boolean = (levelData.BossWave ~= nil and waveNumber == levelData.BossWave)

	print(`[GameLoop] 🌊 NIVEAU {currentLevel} — VAGUE {waveNumber}/{totalWavesInLevel} — {zombieCount} zombie(s){if isBossWave then " + BOSS!" else ""}`)

	-- Notifier les clients
	broadcastLevelEvent("WaveStart", {
		Level = currentLevel,
		Wave = waveNumber,
		TotalWaves = totalWavesInLevel,
		ZombieCount = zombieCount,
		IsBossWave = isBossWave,
	})

	local pool: { string } = levelData.ZombiePool

	for i = 1, zombieCount do
		if gameOver then break end

		-- Choisir un type de zombie aléatoire dans le pool du niveau
		local zombieType: string = pool[rng:NextInteger(1, #pool)]
		ZombieSpawner.SpawnZombie(zombieType)

		if i < zombieCount then
			task.wait(levelData.WaveSpawnInterval)
		end
	end

	-- Spawner le boss en dernier si c'est la vague boss
	if isBossWave and levelData.BossType and not gameOver then
		task.wait(levelData.WaveSpawnInterval)
		local bossHP: number = math.ceil(
			(UnitDatabase[levelData.BossType] and UnitDatabase[levelData.BossType].HP or 10)
			* levelData.HPMultiplier
			* (levelData.BossHPMultiplier or 2.0)
		)
		ZombieSpawner.SpawnZombie(levelData.BossType, nil, bossHP)
		print(`[GameLoop] 👹 BOSS {levelData.BossType} spawné avec {bossHP} HP !`)
	end
end

local function waitForWaveEnd(): ()
	while ZombieSpawner.GetActiveCount() > 0 and not gameOver do
		task.wait(0.5)
	end
end

local function runLevel(levelNumber: number): boolean
	local levelData = LevelDatabase[levelNumber]
	if levelData == nil then
		warn(`[GameLoop] ❌ Niveau {levelNumber} introuvable dans LevelDatabase`)
		return false
	end

	currentLevel = levelNumber
	totalWavesInLevel = levelData.WaveCount
	currentWave = 0

	-- Configurer les multiplicateurs du niveau sur le ZombieSpawner
	ZombieSpawner.SetMultipliers(
		levelData.HPMultiplier,
		levelData.SpeedMultiplier,
		levelData.DamageMultiplier
	)

	-- Donner le BrainCoin de départ du niveau
	playerBrainCoin = levelData.StartingBrainCoin
	baseHP = Constants.BASE_HP

	print(`\n[GameLoop] ═══════════════════════════════════════`)
	print(`[GameLoop] 🏰 NIVEAU {levelNumber} : {levelData.Theme} {levelData.Name}`)
	print(`[GameLoop]    Vagues : {levelData.WaveCount} | Zombies : {levelData.BaseZombieCount}+{levelData.ZombieIncrement}/vague`)
	print(`[GameLoop]    HP×{levelData.HPMultiplier}  Speed×{levelData.SpeedMultiplier}  Dmg×{levelData.DamageMultiplier}`)
	print(`[GameLoop]    BrainCoin de départ : {levelData.StartingBrainCoin}`)
	print(`[GameLoop] ═══════════════════════════════════════\n`)

	-- Notifier les clients du début du niveau
	broadcastLevelEvent("LevelStart", {
		Level = levelNumber,
		Name = levelData.Name,
		Theme = levelData.Theme,
		TotalWaves = levelData.WaveCount,
		TotalLevels = TOTAL_LEVELS,
	})
	broadcastGameState()

	-- Pause avant la première vague
	print(`[GameLoop] ⏳ Première vague dans 5 secondes...`)
	task.wait(5)

	-- Boucle des vagues du niveau
	for wave = 1, levelData.WaveCount do
		if gameOver then return false end

		currentWave = wave
		broadcastGameState()

		spawnWave(levelData, wave)
		waitForWaveEnd()

		if gameOver then return false end

		-- Vague terminée !
		print(`[GameLoop] 🏆 Vague {wave}/{levelData.WaveCount} terminée ! +{levelData.WaveBonus} BrainCoin bonus`)
		addBrainCoin(levelData.WaveBonus)

		broadcastLevelEvent("WaveComplete", {
			Level = levelNumber,
			Wave = wave,
			TotalWaves = levelData.WaveCount,
		})

		-- Pause entre les vagues (sauf après la dernière)
		if wave < levelData.WaveCount then
			print(`[GameLoop] ⏸️ Prochaine vague dans {levelData.WavePause}s...`)
			task.wait(levelData.WavePause)
		end
	end

	-- Niveau terminé !
	return true
end

-------------------------------------------------
-- Boucle principale — Attend la sélection de niveau
-------------------------------------------------
print("[GameLoop] 🎮 GameLoop démarrée (Sélection de niveaux)")

-- État de la file d'attente de sélection
local selectedLevel: number? = nil
local waitingForSelection: boolean = false

-- Connexion plaques faite une seule fois
local platesSetup: boolean = false

-- Écouter la sélection de niveau par un joueur
levelSelectEvent.OnServerEvent:Connect(function(player: Player, levelNumber: unknown)
	local lv: number = if typeof(levelNumber) == "number" then math.floor(levelNumber) else 0
	if lv < 1 or lv > TOTAL_LEVELS then return end
	if not waitingForSelection then return end

	selectedLevel = lv
	print(`[GameLoop] 📩 {player.Name} a choisi le niveau {lv}`)
end)

task.spawn(function(): ()
	-- Attendre qu'au moins un joueur soit connecté
	waitForPlayers()

	-- Connecter les plaques d'achat (une seule fois)
	if not platesSetup then
		setupPlates()
		platesSetup = true
	end

	-- Démarrer le CombatSystem
	CombatSystem.Start()

	-- Boucle : attendre sélection → jouer niveau → retour
	while true do
		-- Reset état
		gameOver = false
		gameWon = false
		selectedLevel = nil
		waitingForSelection = true
		currentLevel = 0
		currentWave = 0
		totalWavesInLevel = 0

		print("[GameLoop] ⏳ En attente de sélection de niveau...")

		-- Attendre qu'un joueur sélectionne un niveau
		while selectedLevel == nil do
			task.wait(0.5)
		end
		waitingForSelection = false

		local chosenLevel: number = selectedLevel :: number
		print(`[GameLoop] 🎯 Niveau {chosenLevel} sélectionné — Lancement !`)

		-- Notification
		broadcastLevelEvent("LevelSelected", {
			Level = chosenLevel,
			Name = LevelDatabase[chosenLevel].Name,
			Theme = LevelDatabase[chosenLevel].Theme,
		})

		-- Petite pause pour laisser le joueur arriver sur le mur
		task.wait(2)

		-- Lancer le niveau
		local success: boolean = runLevel(chosenLevel)

		if success and not gameOver then
			print(`[GameLoop] ✅ NIVEAU {chosenLevel} TERMINÉ !`)

			-- Récompense GachaTokens
			local tokenReward: number = GachaCatalog.TokenRewards[chosenLevel] or 1
			for _, p in Players:GetPlayers() do
				PlayerInventory.AddTokens(p, tokenReward)
				local newBalance: number = PlayerInventory.GetTokens(p)
				gachaInfoEvent:FireClient(p, { Tokens = newBalance })
				print(`[GameLoop] 🎫 {p.Name} reçoit {tokenReward} GachaToken(s) → {newBalance}`)
			end

			broadcastLevelEvent("LevelComplete", {
				Level = chosenLevel,
				TotalLevels = TOTAL_LEVELS,
			})

			-- Pause avant retour au menu
			task.wait(8)
		elseif gameOver then
			-- Pause après game over avant retour au menu
			task.wait(8)
		end

		-- Nettoyer les zombies restants
		for id, _ in ZombieSpawner.ActiveZombies do
			ZombieSpawner.DestroyZombie(id)
		end

		-- Téléporter tous les joueurs au hub
		local HUB_RETURN_POS: Vector3 = Constants.SPAWN_CENTER + Vector3.new(0, 3, 15)
		for _, p in Players:GetPlayers() do
			local character = p.Character
			if character then
				local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if hrp then
					hrp.CFrame = CFrame.new(HUB_RETURN_POS)
				end
			end
		end

		-- Notifier le retour au menu
		broadcastLevelEvent("ReturnToMenu", {})
		print("[GameLoop] 🔄 Retour au menu de sélection de niveau")
	end
end)
