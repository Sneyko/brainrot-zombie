--!strict

--[[
	LevelDatabase (ModuleScript)
	Définition de tous les niveaux pour Brainrot Defense.
	Chaque niveau a un nombre de vagues limité, des multiplicateurs de difficulté,
	et des types de zombies disponibles.
	Accessible depuis : ReplicatedStorage.Shared.Data.LevelDatabase
]]

export type LevelData = {
	Name: string,              -- Nom affiché du niveau
	Theme: string,             -- Emoji / courte description
	WaveCount: number,         -- Nombre de vagues dans ce niveau
	ZombiePool: { string },    -- Types de zombies disponibles
	BaseZombieCount: number,   -- Nombre de zombies à la 1ère vague du niveau
	ZombieIncrement: number,   -- Zombies ajoutés par vague
	HPMultiplier: number,      -- Multiplicateur HP des zombies (1.0 = normal)
	SpeedMultiplier: number,   -- Multiplicateur vitesse des zombies
	DamageMultiplier: number,  -- Multiplicateur dégâts des zombies
	StartingBrainCoin: number, -- BrainCoin de départ pour ce niveau
	WaveSpawnInterval: number, -- Secondes entre chaque spawn de zombie
	WavePause: number,         -- Secondes de pause entre les vagues
	KillReward: number,        -- BrainCoin par zombie tué
	WaveBonus: number,         -- BrainCoin bonus par vague terminée
	BossWave: number?,         -- Vague avec un boss (nil = pas de boss)
	BossType: string?,         -- Type de zombie boss
	BossHPMultiplier: number?, -- Multiplicateur HP spécial pour le boss
}

local LevelDatabase: { LevelData } = {
	-------------------------------------------------
	-- Niveau 1 : Les Débuts
	-- Introduction douce
	-------------------------------------------------
	{
		Name             = "Les Débuts",
		Theme            = "🌱",
		WaveCount        = 3,
		ZombiePool       = { "BasicZombie" },
		BaseZombieCount  = 3,
		ZombieIncrement  = 1,
		HPMultiplier     = 1.0,
		SpeedMultiplier  = 0.8,
		DamageMultiplier = 1.0,
		StartingBrainCoin = 8,
		WaveSpawnInterval = 3.0,
		WavePause        = 9,
		KillReward       = 2,
		WaveBonus        = 3,
		BossWave         = nil,
		BossType         = nil,
		BossHPMultiplier = nil,
	},

	-------------------------------------------------
	-- Niveau 2 : Double Trouble
	-- Deux types de zombies, rythme modéré
	-------------------------------------------------
	{
		Name             = "Double Trouble",
		Theme            = "👥",
		WaveCount        = 3,
		ZombiePool       = { "BasicZombie", "BasicSkibidi" },
		BaseZombieCount  = 4,
		ZombieIncrement  = 2,
		HPMultiplier     = 1.0,
		SpeedMultiplier  = 0.85,
		DamageMultiplier = 1.0,
		StartingBrainCoin = 8,
		WaveSpawnInterval = 2.8,
		WavePause        = 9,
		KillReward       = 2,
		WaveBonus        = 3,
		BossWave         = nil,
		BossType         = nil,
		BossHPMultiplier = nil,
	},

	-------------------------------------------------
	-- Niveau 3 : Le Sprint
	-- Introduction du NikeShark en boss
	-------------------------------------------------
	{
		Name             = "Le Sprint",
		Theme            = "👟",
		WaveCount        = 4,
		ZombiePool       = { "BasicZombie", "BasicSkibidi" },
		BaseZombieCount  = 5,
		ZombieIncrement  = 2,
		HPMultiplier     = 1.1,
		SpeedMultiplier  = 0.95,
		DamageMultiplier = 1.0,
		StartingBrainCoin = 9,
		WaveSpawnInterval = 2.5,
		WavePause        = 8,
		KillReward       = 2,
		WaveBonus        = 3,
		BossWave         = 4,
		BossType         = "NikeShark",
		BossHPMultiplier = 2.0,
	},

	-------------------------------------------------
	-- Niveau 4 : Horde
	-- Plus de zombies, NikeShark rejoint la pool
	-------------------------------------------------
	{
		Name             = "Horde",
		Theme            = "🧟",
		WaveCount        = 4,
		ZombiePool       = { "BasicZombie", "BasicSkibidi", "NikeShark" },
		BaseZombieCount  = 6,
		ZombieIncrement  = 2,
		HPMultiplier     = 1.2,
		SpeedMultiplier  = 1.0,
		DamageMultiplier = 1.1,
		StartingBrainCoin = 10,
		WaveSpawnInterval = 2.2,
		WavePause        = 8,
		KillReward       = 2,
		WaveBonus        = 4,
		BossWave         = nil,
		BossType         = nil,
		BossHPMultiplier = nil,
	},

	-------------------------------------------------
	-- Niveau 5 : Accélération
	-- SpeedDemon entre en jeu
	-------------------------------------------------
	{
		Name             = "Accélération",
		Theme            = "⚡",
		WaveCount        = 5,
		ZombiePool       = { "BasicSkibidi", "NikeShark", "SpeedDemon" },
		BaseZombieCount  = 7,
		ZombieIncrement  = 2,
		HPMultiplier     = 1.3,
		SpeedMultiplier  = 1.1,
		DamageMultiplier = 1.1,
		StartingBrainCoin = 11,
		WaveSpawnInterval = 2.0,
		WavePause        = 7,
		KillReward       = 2,
		WaveBonus        = 4,
		BossWave         = 5,
		BossType         = "NikeShark",
		BossHPMultiplier = 2.5,
	},

	-------------------------------------------------
	-- Niveau 6 : Résistants
	-- ArmoredSkibidi introduit — tanks
	-------------------------------------------------
	{
		Name             = "Résistants",
		Theme            = "🛡️",
		WaveCount        = 5,
		ZombiePool       = { "BasicZombie", "BasicSkibidi", "ArmoredSkibidi" },
		BaseZombieCount  = 7,
		ZombieIncrement  = 3,
		HPMultiplier     = 1.4,
		SpeedMultiplier  = 1.0,
		DamageMultiplier = 1.2,
		StartingBrainCoin = 12,
		WaveSpawnInterval = 2.0,
		WavePause        = 7,
		KillReward       = 2,
		WaveBonus        = 4,
		BossWave         = 5,
		BossType         = "ArmoredSkibidi",
		BossHPMultiplier = 2.5,
	},

	-------------------------------------------------
	-- Niveau 7 : Assaut Nocturne
	-- Pool complet, rythme soutenu
	-------------------------------------------------
	{
		Name             = "Assaut Nocturne",
		Theme            = "🌙",
		WaveCount        = 6,
		ZombiePool       = { "BasicSkibidi", "NikeShark", "SpeedDemon", "ArmoredSkibidi" },
		BaseZombieCount  = 8,
		ZombieIncrement  = 3,
		HPMultiplier     = 1.6,
		SpeedMultiplier  = 1.15,
		DamageMultiplier = 1.4,
		StartingBrainCoin = 13,
		WaveSpawnInterval = 1.8,
		WavePause        = 6,
		KillReward       = 2,
		WaveBonus        = 5,
		BossWave         = 6,
		BossType         = "ArmoredSkibidi",
		BossHPMultiplier = 3.0,
	},

	-------------------------------------------------
	-- Niveau 8 : Le Mur
	-- Beaucoup d'élites, dégâts accrus
	-------------------------------------------------
	{
		Name             = "Le Mur",
		Theme            = "🧱",
		WaveCount        = 6,
		ZombiePool       = { "NikeShark", "SpeedDemon", "ArmoredSkibidi" },
		BaseZombieCount  = 9,
		ZombieIncrement  = 3,
		HPMultiplier     = 2.0,
		SpeedMultiplier  = 1.2,
		DamageMultiplier = 1.6,
		StartingBrainCoin = 14,
		WaveSpawnInterval = 1.5,
		WavePause        = 6,
		KillReward       = 3,
		WaveBonus        = 5,
		BossWave         = 6,
		BossType         = "ArmoredSkibidi",
		BossHPMultiplier = 3.5,
	},

	-------------------------------------------------
	-- Niveau 9 : Chaos Total
	-- Très difficile, tout poussé à fond
	-------------------------------------------------
	{
		Name             = "Chaos Total",
		Theme            = "💀",
		WaveCount        = 7,
		ZombiePool       = { "BasicSkibidi", "NikeShark", "SpeedDemon", "ArmoredSkibidi" },
		BaseZombieCount  = 11,
		ZombieIncrement  = 4,
		HPMultiplier     = 2.5,
		SpeedMultiplier  = 1.3,
		DamageMultiplier = 1.8,
		StartingBrainCoin = 16,
		WaveSpawnInterval = 1.3,
		WavePause        = 5,
		KillReward       = 3,
		WaveBonus        = 5,
		BossWave         = 7,
		BossType         = "ArmoredSkibidi",
		BossHPMultiplier = 4.5,
	},

	-------------------------------------------------
	-- Niveau 10 : Brainrot Final
	-- Ultime défi — zombies monstrueux
	-------------------------------------------------
	{
		Name             = "Brainrot Final",
		Theme            = "🧠",
		WaveCount        = 8,
		ZombiePool       = { "NikeShark", "SpeedDemon", "ArmoredSkibidi" },
		BaseZombieCount  = 13,
		ZombieIncrement  = 4,
		HPMultiplier     = 3.0,
		SpeedMultiplier  = 1.35,
		DamageMultiplier = 2.2,
		StartingBrainCoin = 18,
		WaveSpawnInterval = 1.0,
		WavePause        = 5,
		KillReward       = 3,
		WaveBonus        = 6,
		BossWave         = 8,
		BossType         = "ArmoredSkibidi",
		BossHPMultiplier = 5.0,
	},
}

return LevelDatabase
