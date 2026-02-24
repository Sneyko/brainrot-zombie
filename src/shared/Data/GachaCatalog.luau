--!strict

--[[
	GachaCatalog (ModuleScript)
	Définition du pool de Gacha, taux de drop (optimisés), pity system, et coûts.
	Taux basés sur l'audit économique :
	  • Common réduit de 70% → ~52% (moins de frustration au premier tirage)
	  • Rare/Epic redistribués vers le haut
	  • Pity system : Legendary garanti à 100 pulls, Mythic à 500 pulls
	Accessible depuis : ReplicatedStorage.Shared.Data.GachaCatalog
]]

export type GachaEntry = {
	UnitId: string,
	Name: string,
	Rarity: string,
	Rate: number,          -- Taux en % (0-100), total = 100
	RobuxPrice: number?,   -- Prix achat direct (nil = gacha exclusif)
}

local GachaCatalog = {}

-------------------------------------------------
-- Configuration globale
-------------------------------------------------
GachaCatalog.PullCostTokens      = 1     -- Coût d'un tirage (en GachaTokens)
GachaCatalog.MultiPullCount      = 10    -- Nombre de tirages dans un multi
GachaCatalog.MultiPullCostTokens = 9     -- Coût multi (10% de réduction)
GachaCatalog.PityLegendary       = 100   -- Pull garanti Legendary tous les 100 pulls
GachaCatalog.PityMythic          = 500   -- Pull garanti Mythic tous les 500 pulls
GachaCatalog.StartingTokens      = 3     -- Tokens offerts au premier lancement

-- Tokens gagnés par niveau complété (augmentés car les niveaux sont plus durs)
GachaCatalog.TokenRewards = {
	[1] = 1, [2] = 1, [3] = 2,          -- Niveaux faciles : 1-2 tokens
	[4] = 2, [5] = 3, [6] = 3,          -- Niveaux moyens : 2-3 tokens
	[7] = 4, [8] = 4, [9] = 5,          -- Niveaux durs : 4-5 tokens
	[10] = 8,                             -- Niveau final : 8 tokens
}

-------------------------------------------------
-- Pool de Gacha — Taux optimisés (total = 100%)
--
--   51.75 + 18 + 14 + 7 + 5 + 2.5 + 1.5 + 0.15 + 0.10 = 100.00
-------------------------------------------------
GachaCatalog.Pool = {
	{
		UnitId     = "Glorbo",
		Name       = "Glorbo",
		Rarity     = "Common",
		Rate       = 51.75,
		RobuxPrice = nil,              -- Gratuit (obtenu de base)
	},
	{
		UnitId     = "Bombardino",
		Name       = "Bombardino",
		Rarity     = "Rare",
		Rate       = 18,
		RobuxPrice = 99,
	},
	{
		UnitId     = "Kapuchino",
		Name       = "Kapuchino",
		Rarity     = "Rare",
		Rate       = 14,
		RobuxPrice = 149,
	},
	{
		UnitId     = "TungTungSahur",
		Name       = "Tung Tung Sahur",
		Rarity     = "Epic",
		Rate       = 7,
		RobuxPrice = 299,
	},
	{
		UnitId     = "BrrBrrPatapim",
		Name       = "Brr Brr Patapim",
		Rarity     = "Epic",
		Rate       = 5,
		RobuxPrice = 349,
	},
	{
		UnitId     = "Tralalero",
		Name       = "Tralalero",
		Rarity     = "Legendary",
		Rate       = 2.5,
		RobuxPrice = 699,
	},
	{
		UnitId     = "LiriliLarala",
		Name       = "Lirili Larala",
		Rarity     = "Legendary",
		Rate       = 1.5,
		RobuxPrice = 799,
	},
	{
		UnitId     = "SigmaSkibidi",
		Name       = "Sigma Skibidi",
		Rarity     = "Mythic",
		Rate       = 0.15,
		RobuxPrice = 1999,
	},
	{
		UnitId     = "TitanCameraMan",
		Name       = "Titan CameraMan",
		Rarity     = "Mythic",
		Rate       = 0.10,
		RobuxPrice = nil,              -- Exclusif au Gacha
	},
} :: { GachaEntry }

-------------------------------------------------
-- Couleurs par rareté (pour les UI)
-------------------------------------------------
GachaCatalog.RarityColors = {
	Common    = Color3.fromRGB(180, 180, 180),
	Rare      = Color3.fromRGB(0, 170, 255),
	Epic      = Color3.fromRGB(180, 50, 255),
	Legendary = Color3.fromRGB(255, 180, 0),
	Mythic    = Color3.fromRGB(255, 50, 80),
}

GachaCatalog.RarityOrder = {
	Common    = 1,
	Rare      = 2,
	Epic      = 3,
	Legendary = 4,
	Mythic    = 5,
}

return GachaCatalog
