--!strict

--[[
	Constants (ModuleScript)
	Constantes partagées pour Brainrot Defense (Tower Defense temps réel).
	Layout : sol + mur de défense. Joueur en 1ère personne sur le mur.
	Accessible depuis : ReplicatedStorage.Shared.Constants
]]

local Constants = {}

-------------------------------------------------
-- Terrain — Sol
-------------------------------------------------
Constants.GROUND_SIZE     = Vector3.new(200, 0.5, 400)
Constants.GROUND_POSITION = Vector3.new(-1, 0, -1)
Constants.GROUND_TOP_Y    = 0.25   -- Y du dessus du sol

-------------------------------------------------
-- Terrain — Mur de défense
-------------------------------------------------
Constants.WALL_SIZE     = Vector3.new(200, 70, 50)
Constants.WALL_POSITION = Vector3.new(-1, 35, -226)
Constants.WALL_TOP_Y    = 70       -- Y du dessus du mur (bas à Y=0, haut à Y=70)
Constants.WALL_FRONT_Z  = -201     -- Face avant du mur (WALL_POSITION.Z + WALL_SIZE.Z / 2)

-------------------------------------------------
-- Grille (logique interne)
-------------------------------------------------
Constants.GRID_ROWS    = 5
Constants.GRID_COLS    = 9   -- Col 1-8 = placement, Col 9 = spawn zombie
Constants.TILE_SIZE    = 6
Constants.TILE_SPACING = 0

-------------------------------------------------
-- Plaques de placement (sur le mur)
-------------------------------------------------
Constants.TILE_THICKNESS = 0.5    -- Épaisseur des plaques d'achat
Constants.PLATE_SIZE     = 12     -- Taille d'une plaque (studs)
Constants.PLANT_UNITS    = { "Glorbo", "Kapuchino", "Bombardino", "Tralalero", "TungTungSahur", "BrrBrrPatapim", "LiriliLarala", "SigmaSkibidi", "TitanCameraMan" }

-------------------------------------------------
-- Spawn unités (sur le sol)
-------------------------------------------------
Constants.UNIT_SPAWN_Z_MIN   = -160  -- Zone de spawn des unités (près du mur)
Constants.UNIT_SPAWN_Z_MAX   = -80   -- Zone de spawn des unités (plus loin)
Constants.UNIT_SPAWN_X_SPREAD = 60   -- Spread X max par rapport au centre
Constants.UNIT_MODEL_HEIGHT   = 10   -- Hauteur cible (studs) — tous les brainrot sont mis à cette taille

-------------------------------------------------
-- Chemin zombie (sur le sol)
-------------------------------------------------
Constants.ZOMBIE_SPAWN_Z = 190    -- Z d'apparition (fond du sol)
Constants.ZOMBIE_BASE_Z  = -195   -- Z cible (pied du mur)

-------------------------------------------------
-- Économie (BrainCoin)
-------------------------------------------------
Constants.STARTING_BRAINCOIN = 8
Constants.KILL_REWARD        = 2
Constants.WAVE_BONUS         = 4

-------------------------------------------------
-- Vagues (Waves)
-------------------------------------------------
Constants.WAVE_SPAWN_INTERVAL  = 3
Constants.WAVE_PAUSE           = 8
Constants.BASE_ZOMBIES_PER_WAVE = 3
Constants.ZOMBIES_INCREMENT    = 2

-------------------------------------------------
-- Zombies (mouvement)
-------------------------------------------------
Constants.ZOMBIE_SPEED = 4   -- Studs/seconde

-------------------------------------------------
-- Combat
-------------------------------------------------
Constants.DEFAULT_RANGE     = 80    -- Portée par défaut (studs) — haute car tirs du mur vers le sol
Constants.DEFAULT_FIRE_RATE = 1
Constants.BEAM_DURATION     = 0.1

-------------------------------------------------
-- Santé de la base
-------------------------------------------------
Constants.BASE_HP = 20

-------------------------------------------------
-- Spawn Hub (Lobby)
-------------------------------------------------
Constants.SPAWN_CENTER       = Vector3.new(0, 0, 500)   -- Centre du spawn hub (éloigné de la map de jeu)
Constants.SPAWN_RADIUS       = 150                        -- Rayon de la zone circulaire (grand)
Constants.SPAWN_GROUND_Y     = 0.25                       -- Hauteur du sol du spawn

-- Portails
Constants.PORTAL_HEIGHT       = 20
Constants.PORTAL_WIDTH        = 14
Constants.PORTAL_THICKNESS    = 2.5
Constants.PORTAL_INNER_HEIGHT = 15
Constants.PORTAL_INNER_WIDTH  = 9

-- Définition des portails (angle en degrés autour du centre, distance depuis le centre)
Constants.PORTALS = {
	{
		Id       = "GameMap",
		Name     = "⚔️ JOUER",
		Subtitle = "Brainrot Defense",
		Color    = Color3.fromRGB(0, 200, 255),
		Angle    = 0,
		Distance = 120,
	},
	{
		Id       = "Shop",
		Name     = "🛒 SHOP",
		Subtitle = "Acheter des unités",
		Color    = Color3.fromRGB(0, 255, 120),
		Angle    = 90,
		Distance = 120,
	},
	{
		Id       = "Sell",
		Name     = "💰 SELL",
		Subtitle = "Vendre des items",
		Color    = Color3.fromRGB(255, 200, 50),
		Angle    = 180,
		Distance = 120,
	},
	{
		Id       = "Gacha",
		Name     = "🎰 GACHA",
		Subtitle = "Invoquer des brainrots",
		Color    = Color3.fromRGB(200, 50, 255),
		Angle    = 270,
		Distance = 120,
	},
}

-- Fontaine centrale
Constants.FOUNTAIN_RADIUS     = 14
Constants.FOUNTAIN_HEIGHT     = 5
Constants.FOUNTAIN_JET_HEIGHT = 25

return Constants
