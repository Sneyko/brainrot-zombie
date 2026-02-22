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
	-- Très facile, introduction douce
	-------------------------------------------------
	{
		Name             = "Les Débuts",
		Theme            = "🌱",
		WaveCount        = 3,
		ZombiePool       = { "BasicZombie" },
		BaseZombieCount  = 2,
		ZombieIncrement  = 1,
		HPMultiplier     = 1.0,
		SpeedMultiplier  = 0.8,
		DamageMultiplier = 1.0,
		StartingBrainCoin = 8,
		WaveSpawnInterval = 3.5,
		WavePause        = 10,
		KillReward       = 2,
		WaveBonus        = 4,
		BossWave         = nil,
		BossType         = nil,
		BossHPMultiplier = nil,
	},

	-------------------------------------------------
	-- Niveau 2 : Double Trouble
	-- Deux types de zombies, encore facile
	-------------------------------------------------
	{
		Name             = "Double Trouble",
		Theme            = "👥",
		WaveCount        = 3,
		ZombiePool       = { "BasicZombie", "BasicSkibidi" },
		BaseZombieCount  = 3,
		ZombieIncrement  = 1,
		HPMultiplier     = 1.0,
		SpeedMultiplier  = 0.9,
		DamageMultiplier = 1.0,
		StartingBrainCoin = 8,
		WaveSpawnInterval = 3.0,
		WavePause        = 10,
		KillReward       = 2,
		WaveBonus        = 4,
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
		BaseZombieCount  = 4,
		ZombieIncrement  = 1,
		HPMultiplier     = 1.0,
		SpeedMultiplier  = 1.0,
		DamageMultiplier = 1.0,
		StartingBrainCoin = 8,
		WaveSpawnInterval = 2.8,
		WavePause        = 9,
		KillReward       = 2,
		WaveBonus        = 5,
		BossWave         = 4,
		BossType         = "NikeShark",
		BossHPMultiplier = 2.0,
	},

	-------------------------------------------------
	-- Niveau 4 : Horde
	-- Plus de zombies par vague
	-------------------------------------------------
	{
		Name             = "Horde",
		Theme            = "🧟",
		WaveCount        = 4,
		ZombiePool       = { "BasicZombie", "BasicSkibidi", "NikeShark" },
		BaseZombieCount  = 5,
		ZombieIncrement  = 2,
		HPMultiplier     = 1.1,
		SpeedMultiplier  = 1.0,
		DamageMultiplier = 1.0,
		StartingBrainCoin = 10,
		WaveSpawnInterval = 2.5,
		WavePause        = 9,
		KillReward       = 2,
		WaveBonus        = 5,
		BossWave         = nil,
		BossType         = nil,
		BossHPMultiplier = nil,
	},

	-------------------------------------------------
	-- Niveau 5 : Accélération
	-- Zombies plus rapides
	-------------------------------------------------
	{
		Name             = "Accélération",
		Theme            = "⚡",
		WaveCount        = 5,
		ZombiePool       = { "BasicSkibidi", "NikeShark" },
		BaseZombieCount  = 5,
		ZombieIncrement  = 2,
		HPMultiplier     = 1.1,
		SpeedMultiplier  = 1.25,
		DamageMultiplier = 1.0,
		StartingBrainCoin = 12,
		WaveSpawnInterval = 2.2,
		WavePause        = 8,
		KillReward       = 2,
		WaveBonus        = 5,
		BossWave         = 5,
		BossType         = "NikeShark",
		BossHPMultiplier = 2.5,
	},

	-------------------------------------------------
	-- Niveau 6 : Résistants
	-- Zombies avec beaucoup de HP
	-------------------------------------------------
	{
		Name             = "Résistants",
		Theme            = "🛡️",
		WaveCount        = 5,
		ZombiePool       = { "BasicZombie", "BasicSkibidi", "NikeShark" },
		BaseZombieCount  = 6,
		ZombieIncrement  = 2,
		HPMultiplier     = 1.5,
		SpeedMultiplier  = 1.0,
		DamageMultiplier = 1.0,
		StartingBrainCoin = 12,
		WaveSpawnInterval = 2.5,
		WavePause        = 8,
		KillReward       = 2,
		WaveBonus        = 6,
		BossWave         = nil,
		BossType         = nil,
		BossHPMultiplier = nil,
	},

	-------------------------------------------------
	-- Niveau 7 : Assaut Nocturne
	-- Tout plus dur, rythme soutenu
	-------------------------------------------------
	{
		Name             = "Assaut Nocturne",
		Theme            = "🌙",
		WaveCount        = 6,
		ZombiePool       = { "BasicZombie", "BasicSkibidi", "NikeShark" },
		BaseZombieCount  = 7,
		ZombieIncrement  = 2,
		HPMultiplier     = 1.4,
		SpeedMultiplier  = 1.15,
		DamageMultiplier = 1.5,
		StartingBrainCoin = 14,
		WaveSpawnInterval = 2.0,
		WavePause        = 7,
		KillReward       = 2,
		WaveBonus        = 6,
		BossWave         = 6,
		BossType         = "NikeShark",
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
		ZombiePool       = { "BasicSkibidi", "NikeShark" },
		BaseZombieCount  = 8,
		ZombieIncrement  = 3,
		HPMultiplier     = 1.6,
		SpeedMultiplier  = 1.2,
		DamageMultiplier = 1.5,
		StartingBrainCoin = 15,
		WaveSpawnInterval = 1.8,
		WavePause        = 7,
		KillReward       = 3,
		WaveBonus        = 7,
		BossWave         = 6,
		BossType         = "NikeShark",
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
		ZombiePool       = { "BasicZombie", "BasicSkibidi", "NikeShark" },
		BaseZombieCount  = 10,
		ZombieIncrement  = 3,
		HPMultiplier     = 1.8,
		SpeedMultiplier  = 1.3,
		DamageMultiplier = 2.0,
		StartingBrainCoin = 16,
		WaveSpawnInterval = 1.5,
		WavePause        = 6,
		KillReward       = 3,
		WaveBonus        = 8,
		BossWave         = 7,
		BossType         = "NikeShark",
		BossHPMultiplier = 4.0,
	},

	-------------------------------------------------
	-- Niveau 10 : Brainrot Final
	-- Ultime défi — boss à chaque vague paire
	-------------------------------------------------
	{
		Name             = "Brainrot Final",
		Theme            = "🧠",
		WaveCount        = 8,
		ZombiePool       = { "BasicZombie", "BasicSkibidi", "NikeShark" },
		BaseZombieCount  = 12,
		ZombieIncrement  = 3,
		HPMultiplier     = 2.0,
		SpeedMultiplier  = 1.35,
		DamageMultiplier = 2.0,
		StartingBrainCoin = 18,
		WaveSpawnInterval = 1.2,
		WavePause        = 6,
		KillReward       = 3,
		WaveBonus        = 8,
		BossWave         = 8,
		BossType         = "NikeShark",
		BossHPMultiplier = 5.0,
	},
}

return LevelDatabase
