--!strict

--[[
	BrainrotCatalog (ModuleScript)
	Catalogue de TOUS les brainrots disponibles dans le jeu.
	Affiché dans la vitrine du Spawn Hub.

	═══════════════════════════════════════════════════════
	  POUR MODIFIER : change les valeurs ci-dessous.
	  Le jeu se met à jour en temps réel via Rojo.
	═══════════════════════════════════════════════════════

	Champs :
	  • Name        : Nom affiché
	  • Rarity      : "Common" | "Rare" | "Epic" | "Legendary" | "Mythic"
	  • Color       : Couleur du modèle placeholder
	  • RobuxPrice  : Prix en Robux (nil = non achetable directement)
	  • LootChance  : % de chance de drop dans un coffre (0-100, nil = pas dans les coffres)
	  • Description : Texte court affiché sous le nom
	  • Stats       : Résumé des stats pour la vitrine
	  • Available   : true/false — masque de la vitrine si false
]]

export type CatalogEntry = {
	Name: string,
	Rarity: string,
	Color: Color3,
	RobuxPrice: number?,
	LootChance: number?,
	Description: string,
	Stats: string,
	Available: boolean,
}

-- ╔══════════════════════════════════════════════════════╗
-- ║         MODIFIER LES VALEURS ICI ▼ ▼ ▼             ║
-- ╚══════════════════════════════════════════════════════╝

local BrainrotCatalog: { [string]: CatalogEntry } = {

	-- ════════════ COMMON ════════════
	Glorbo = {
		Name        = "Glorbo",
		Rarity      = "Common",
		Color       = Color3.fromRGB(80, 200, 120),
		RobuxPrice  = nil,           -- Gratuit (obtenu de base)
		LootChance  = 40,            -- 40% dans un coffre
		Description = "Petit soldat vert. Tir rapide, dégâts faibles.",
		Stats       = "❤️ 4  ⚔️ 1  🔫 1.2/s  📏 70",
		Available   = true,
	},

	-- ════════════ RARE ════════════
	Bombardino = {
		Name        = "Bombardino",
		Rarity      = "Rare",
		Color       = Color3.fromRGB(255, 120, 30),
		RobuxPrice  = 99,            -- 99 Robux
		LootChance  = 20,            -- 20% dans un coffre
		Description = "Crocodile explosif. Lent mais dévastateur!",
		Stats       = "❤️ 10  ⚔️ 4  🔫 0.4/s  📏 50",
		Available   = true,
	},

	Kapuchino = {
		Name        = "Kapuchino",
		Rarity      = "Rare",
		Color       = Color3.fromRGB(160, 80, 255),
		RobuxPrice  = 149,           -- 149 Robux
		LootChance  = 18,            -- 18% dans un coffre
		Description = "Sniper caféiné. Longue portée, tirs précis!",
		Stats       = "❤️ 5  ⚔️ 2  🔫 0.9/s  📏 120",
		Available   = true,
	},

	-- ════════════ EPIC ════════════
	TungTungSahur = {
		Name        = "Tung Tung Sahur",
		Rarity      = "Epic",
		Color       = Color3.fromRGB(255, 80, 200),
		RobuxPrice  = 299,           -- 299 Robux
		LootChance  = 8,             -- 8% dans un coffre
		Description = "Batteur frénétique. AoE sonore dévastateur!",
		Stats       = "❤️ 12  ⚔️ 5  🔫 0.7/s  📏 60",
		Available   = true,
	},

	BrrBrrPatapim = {
		Name        = "Brr Brr Patapim",
		Rarity      = "Epic",
		Color       = Color3.fromRGB(50, 200, 220),
		RobuxPrice  = 349,           -- 349 Robux
		LootChance  = 6,             -- 6% dans un coffre
		Description = "Skibidi glacial. Ralentit les zombies!",
		Stats       = "❤️ 8  ⚔️ 3  🔫 1.0/s  📏 90  ❄️ Slow",
		Available   = true,
	},

	-- ════════════ LEGENDARY ════════════
	Tralalero = {
		Name        = "Tralalero Tralala",
		Rarity      = "Legendary",
		Color       = Color3.fromRGB(255, 50, 50),
		RobuxPrice  = 699,           -- 699 Robux
		LootChance  = 2,             -- 2% dans un coffre
		Description = "Requin légendaire. Stats massives!",
		Stats       = "❤️ 15  ⚔️ 6  🔫 0.6/s  📏 130",
		Available   = true,
	},

	LiriliLarala = {
		Name        = "Lirili Larala",
		Rarity      = "Legendary",
		Color       = Color3.fromRGB(255, 215, 0),
		RobuxPrice  = 799,           -- 799 Robux
		LootChance  = 1.5,           -- 1.5% dans un coffre
		Description = "Barde doré. Buff toutes les unités proches!",
		Stats       = "❤️ 10  ⚔️ 2  🔫 0.5/s  📏 40  🎵 +30% ATK",
		Available   = true,
	},

	-- ════════════ MYTHIC ════════════
	SigmaSkibidi = {
		Name        = "Sigma Skibidi",
		Rarity      = "Mythic",
		Color       = Color3.fromRGB(255, 0, 255),
		RobuxPrice  = 1999,          -- 1999 Robux
		LootChance  = 0.5,           -- 0.5% dans un coffre (ultra rare)
		Description = "Le Sigma ultime. Pouvoir absolu.",
		Stats       = "❤️ 30  ⚔️ 10  🔫 1.5/s  📏 150  💀 Instakill 5%",
		Available   = true,
	},

	CameraMan = {
		Name        = "Titan CameraMan",
		Rarity      = "Mythic",
		Color       = Color3.fromRGB(220, 220, 240),
		RobuxPrice  = nil,           -- Non achetable, coffre uniquement
		LootChance  = 0.1,           -- 0.1% (!!!)
		Description = "Titan légendaire. Exclusif aux coffres!",
		Stats       = "❤️ 50  ⚔️ 15  🔫 0.3/s  📏 200  📸 Stun",
		Available   = true,
	},

	-- ════════════ BIENTÔT (coming soon) ════════════
	BoboBobobo = {
		Name        = "Bobo Bobobo",
		Rarity      = "Epic",
		Color       = Color3.fromRGB(150, 150, 150),
		RobuxPrice  = 399,
		LootChance  = 5,
		Description = "??? — Bientôt disponible",
		Stats       = "???",
		Available   = false,          -- Masqué pour l'instant
	},
}

-- ╔══════════════════════════════════════════════════════╗
-- ║    COULEURS PAR RARETÉ (pour la vitrine)            ║
-- ╚══════════════════════════════════════════════════════╝

BrainrotCatalog._RARITY_COLORS = {
	Common    = Color3.fromRGB(180, 180, 180),
	Rare      = Color3.fromRGB(80, 150, 255),
	Epic      = Color3.fromRGB(200, 80, 255),
	Legendary = Color3.fromRGB(255, 180, 40),
	Mythic    = Color3.fromRGB(255, 50, 200),
} :: any

-- ╔══════════════════════════════════════════════════════╗
-- ║    ORDRE D'AFFICHAGE DANS LA VITRINE                ║
-- ╚══════════════════════════════════════════════════════╝

BrainrotCatalog._DISPLAY_ORDER = {
	"Glorbo",
	"Bombardino",
	"Kapuchino",
	"TungTungSahur",
	"BrrBrrPatapim",
	"Tralalero",
	"LiriliLarala",
	"SigmaSkibidi",
	"CameraMan",
	"BoboBobobo",
} :: any

return BrainrotCatalog :: any
