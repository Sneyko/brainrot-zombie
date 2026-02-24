--!strict

--[[
	UnitDatabase (ModuleScript)
	Données de toutes les unités — Tower Defense temps réel.
	Accessible depuis : ReplicatedStorage.Shared.Data.UnitDatabase
]]

export type UnitData = {
	Name: string,
	Type: string,          -- "Plant" (tour/défenseur) ou "Zombie" (ennemi)
	Rarity: string,        -- "Common", "Rare", "Legendary"
	Cost: number,          -- Coût en Cash pour placer la tour
	HP: number,            -- Points de vie
	Damage: number,        -- Dégâts par tir (Plant) ou par contact (Zombie)
	Range: number?,        -- Portée en studs (Plant uniquement)
	FireRate: number?,     -- Tirs par seconde (Plant uniquement)
	MoveSpeed: number?,    -- Studs/seconde (Zombie uniquement)
	Color: Color3,         -- Couleur placeholder du modèle 3D
	Description: string,
}

local UnitDatabase: { [string]: UnitData } = {
	-- ============ PLANTS / TOURS (Défenseurs) ============
	Glorbo = {
		Name = "Glorbo",
		Type = "Plant",
		Rarity = "Common",
		Cost = 5,
		HP = 4,
		Damage = 1,
		Range = 55,
		FireRate = 0.8,
		MoveSpeed = nil,
		Color = Color3.fromRGB(80, 200, 120),
		Description = "Petit soldat vert. Tir modéré, bon marché.",
	},

	Bombardino = {
		Name = "Bombardino",
		Type = "Plant",
		Rarity = "Rare",
		Cost = 8,
		HP = 10,
		Damage = 3,
		Range = 55,
		FireRate = 0.4,
		MoveSpeed = nil,
		Color = Color3.fromRGB(255, 120, 30),
		Description = "Crocodile explosif. Lent mais dévastateur!",
	},

	Kapuchino = {
		Name = "Kapuchino",
		Type = "Plant",
		Rarity = "Rare",
		Cost = 8,
		HP = 5,
		Damage = 2,
		Range = 80,
		FireRate = 0.7,
		MoveSpeed = nil,
		Color = Color3.fromRGB(160, 80, 255),
		Description = "Sniper caféiné. Longue portée, tirs précis!",
	},

	Tralalero = {
		Name = "Tralalero",
		Type = "Plant",
		Rarity = "Legendary",
		Cost = 14,
		HP = 12,
		Damage = 4,
		Range = 90,
		FireRate = 0.55,
		MoveSpeed = nil,
		Color = Color3.fromRGB(255, 50, 50),
		Description = "Requin légendaire. Stats massives!",
	},

	-- ============ EPIC (débloqués via Gacha) ============
	TungTungSahur = {
		Name = "Tung Tung Sahur",
		Type = "Plant",
		Rarity = "Epic",
		Cost = 10,
		HP = 7,
		Damage = 2,
		Range = 70,
		FireRate = 0.8,
		MoveSpeed = nil,
		Color = Color3.fromRGB(180, 50, 220),
		Description = "Batteur frénétique. Cadence rapide, dégâts épiques!",
	},

	BrrBrrPatapim = {
		Name = "Brr Brr Patapim",
		Type = "Plant",
		Rarity = "Epic",
		Cost = 10,
		HP = 10,
		Damage = 3,
		Range = 60,
		FireRate = 0.6,
		MoveSpeed = nil,
		Color = Color3.fromRGB(30, 200, 230),
		Description = "Pingouin glacé. Tank robuste avec de la puissance!",
	},

	-- ============ LEGENDARY (débloqués via Gacha) ============
	LiriliLarala = {
		Name = "Lirili Larala",
		Type = "Plant",
		Rarity = "Legendary",
		Cost = 16,
		HP = 14,
		Damage = 4,
		Range = 80,
		FireRate = 0.8,
		MoveSpeed = nil,
		Color = Color3.fromRGB(255, 80, 180),
		Description = "Diva légendaire. Cadence de folie, portée impressionnante!",
	},

	-- ============ MYTHIC (débloqués via Gacha) ============
	SigmaSkibidi = {
		Name = "Sigma Skibidi",
		Type = "Plant",
		Rarity = "Mythic",
		Cost = 22,
		HP = 20,
		Damage = 5,
		Range = 100,
		FireRate = 0.65,
		MoveSpeed = nil,
		Color = Color3.fromRGB(50, 0, 50),
		Description = "Le Sigma. Puissance absolue. Respecte le grindset.",
	},

	TitanCameraMan = {
		Name = "Titan CameraMan",
		Type = "Plant",
		Rarity = "Mythic",
		Cost = 28,
		HP = 28,
		Damage = 7,
		Range = 110,
		FireRate = 0.65,
		MoveSpeed = nil,
		Color = Color3.fromRGB(255, 200, 50),
		Description = "TITAN. La machine de guerre ultime. Inarrêtable.",
	},

	-- ============ ZOMBIES (Ennemis) ============
	BasicSkibidi = {
		Name = "Basic Skibidi",
		Type = "Zombie",
		Rarity = "Common",
		Cost = 0,
		HP = 14,
		Damage = 2,
		Range = nil,
		FireRate = nil,
		MoveSpeed = 4.5,
		Color = Color3.fromRGB(140, 90, 50),
		Description = "Skibidi de base. Avance lentement mais sûrement.",
	},

	BasicZombie = {
		Name = "Basic Zombie",
		Type = "Zombie",
		Rarity = "Common",
		Cost = 0,
		HP = 12,
		Damage = 2,
		Range = nil,
		FireRate = nil,
		MoveSpeed = 5.5,
		Color = Color3.fromRGB(100, 160, 60),
		Description = "Avance tout droit. Basic but persistent.",
	},

	NikeShark = {
		Name = "Nike Shark",
		Type = "Zombie",
		Rarity = "Rare",
		Cost = 0,
		HP = 25,
		Damage = 4,
		Range = nil,
		FireRate = nil,
		MoveSpeed = 8.5,
		Color = Color3.fromRGB(60, 60, 60),
		Description = "Vitesse extrême. Drip or drown.",
	},

	ArmoredSkibidi = {
		Name = "Armored Skibidi",
		Type = "Zombie",
		Rarity = "Rare",
		Cost = 0,
		HP = 50,
		Damage = 5,
		Range = nil,
		FireRate = nil,
		MoveSpeed = 3,
		Color = Color3.fromRGB(80, 80, 80),
		Description = "Blindé et implacable. Absorbe des tonnes de dégâts.",
	},

	SpeedDemon = {
		Name = "Speed Demon",
		Type = "Zombie",
		Rarity = "Rare",
		Cost = 0,
		HP = 8,
		Damage = 2,
		Range = nil,
		FireRate = nil,
		MoveSpeed = 14,
		Color = Color3.fromRGB(255, 0, 80),
		Description = "Ultra rapide ! Blink et il est passé.",
	},
}

return UnitDatabase
