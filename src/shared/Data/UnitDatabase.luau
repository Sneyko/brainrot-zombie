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
		Cost = 3,
		HP = 4,
		Damage = 1,
		Range = 70,
		FireRate = 1.2,
		MoveSpeed = nil,
		Color = Color3.fromRGB(80, 200, 120),
		Description = "Petit soldat vert. Tir rapide, d\195\169g\195\162ts faibles.",
	},

	Bombardino = {
		Name = "Bombardino",
		Type = "Plant",
		Rarity = "Rare",
		Cost = 6,
		HP = 10,
		Damage = 4,
		Range = 50,
		FireRate = 0.4,
		MoveSpeed = nil,
		Color = Color3.fromRGB(255, 120, 30),
		Description = "Crocodile explosif. Lent mais d\195\169vastateur!",
	},

	Kapuchino = {
		Name = "Kapuchino",
		Type = "Plant",
		Rarity = "Rare",
		Cost = 5,
		HP = 5,
		Damage = 2,
		Range = 120,
		FireRate = 0.9,
		MoveSpeed = nil,
		Color = Color3.fromRGB(160, 80, 255),
		Description = "Sniper caf\195\169in\195\169. Longue port\195\169e, tirs pr\195\169cis!",
	},

	Tralalero = {
		Name = "Tralalero",
		Type = "Plant",
		Rarity = "Legendary",
		Cost = 10,
		HP = 15,
		Damage = 6,
		Range = 130,
		FireRate = 0.6,
		MoveSpeed = nil,
		Color = Color3.fromRGB(255, 50, 50),
		Description = "Requin l\195\169gendaire. Stats massives!",
	},

	-- ============ ZOMBIES (Ennemis) ============
	BasicSkibidi = {
		Name = "Basic Skibidi",
		Type = "Zombie",
		Rarity = "Common",
		Cost = 0,
		HP = 5,
		Damage = 1,
		Range = nil,
		FireRate = nil,
		MoveSpeed = 4,
		Color = Color3.fromRGB(140, 90, 50),
		Description = "Skibidi de base. Avance lentement mais sûrement.",
	},

	BasicZombie = {
		Name = "Basic Zombie",
		Type = "Zombie",
		Rarity = "Common",
		Cost = 0,
		HP = 4,
		Damage = 1,
		Range = nil,
		FireRate = nil,
		MoveSpeed = 5,
		Color = Color3.fromRGB(100, 160, 60),
		Description = "Avance tout droit. Basic but persistent.",
	},

	NikeShark = {
		Name = "Nike Shark",
		Type = "Zombie",
		Rarity = "Rare",
		Cost = 0,
		HP = 8,
		Damage = 2,
		Range = nil,
		FireRate = nil,
		MoveSpeed = 7,
		Color = Color3.fromRGB(60, 60, 60),
		Description = "Vitesse double. Drip or drown.",
	},
}

return UnitDatabase
