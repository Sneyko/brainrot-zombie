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
Constants.GRID_ROWS    = 16
Constants.GRID_COLS    = 11   -- Col 1-10 = placement, Col 11 = spawn zombie
Constants.TILE_SIZE    = 10
Constants.TILE_SPACING = 2    -- Espacement entre les cases (studs)

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
Constants.STARTING_BRAINCOIN = 5
Constants.KILL_REWARD        = 1
Constants.WAVE_BONUS         = 2

-------------------------------------------------
-- Vagues (Waves)
-------------------------------------------------
Constants.WAVE_SPAWN_INTERVAL  = 2.5
Constants.WAVE_PAUSE           = 7
Constants.BASE_ZOMBIES_PER_WAVE = 4
Constants.ZOMBIES_INCREMENT    = 2

-------------------------------------------------
-- Zombies (mouvement)
-------------------------------------------------
Constants.ZOMBIE_SPEED = 5   -- Studs/seconde

-------------------------------------------------
-- Combat
-------------------------------------------------
Constants.DEFAULT_RANGE     = 60    -- Portée par défaut (studs) — haute car tirs du mur vers le sol
Constants.DEFAULT_FIRE_RATE = 0.8
Constants.BEAM_DURATION     = 0.1

-------------------------------------------------
-- Santé de la base
-------------------------------------------------
Constants.BASE_HP = 18

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

-------------------------------------------------
-- Grille tactique (Placement Top-Down)
-- La grille 5×8 couvre la zone défensive sur le sol.
-- Rows = lanes horizontales (axe X), Cols = profondeur (axe Z).
-- Col 1 est la plus proche du mur, Col 8 la plus avancée.
-------------------------------------------------
Constants.GRID_ORIGIN_Z       = -180    -- Z du bord avant de la colonne 1 (près du mur)
Constants.GRID_PLACEABLE_COLS = 10      -- Colonnes 1-10 pour le placement (11 = spawn zombie)

-- Caméra Top-Down
Constants.TOPDOWN_CAM_HEIGHT  = 140     -- Hauteur caméra en vue tactique (studs) — grille 16×10
Constants.TOPDOWN_TWEEN_TIME  = 0.8     -- Durée transition caméra (secondes)
Constants.TOPDOWN_PAN_SPEED   = 80      -- Vitesse de déplacement horizontal (studs/sec)
Constants.TOPDOWN_PAN_LIMIT_X = 80      -- Limite horizontale du pan depuis le centre (studs)
Constants.TOPDOWN_PAN_LIMIT_Z = 50      -- Limite en profondeur du pan depuis le centre (studs)

-------------------------------------------------
-- Fonctions utilitaires Grille (partagées client/serveur)
-------------------------------------------------

--- Convertit une coordonnée de grille (row, col) en position worldspace.
--- Retourne le centre de la tile au niveau du sol (Y = GROUND_TOP_Y).
function Constants.GridToWorld(row: number, col: number): Vector3
	local cellStep: number = Constants.TILE_SIZE + Constants.TILE_SPACING
	local totalWidth: number = Constants.GRID_ROWS * cellStep
	local x: number = Constants.WALL_POSITION.X - totalWidth / 2 + (row - 0.5) * cellStep
	local z: number = Constants.GRID_ORIGIN_Z + (col - 0.5) * cellStep
	return Vector3.new(x, Constants.GROUND_TOP_Y, z)
end

--- Convertit une position worldspace en coordonnées de grille (row, col).
--- Retourne (nil, nil) si la position est hors des limites de la grille.
function Constants.WorldToGrid(worldPos: Vector3): (number?, number?)
	local cellStep: number = Constants.TILE_SIZE + Constants.TILE_SPACING
	local totalWidth: number = Constants.GRID_ROWS * cellStep
	local localX: number = worldPos.X - (Constants.WALL_POSITION.X - totalWidth / 2)
	local localZ: number = worldPos.Z - Constants.GRID_ORIGIN_Z
	local row: number = math.floor(localX / cellStep) + 1
	local col: number = math.floor(localZ / cellStep) + 1
	if row >= 1 and row <= Constants.GRID_ROWS and col >= 1 and col <= Constants.GRID_PLACEABLE_COLS then
		return row, col
	end
	return nil, nil
end

--- Retourne la position worldspace du centre de la grille
function Constants.GetGridCenter(): Vector3
	return Constants.GridToWorld(
		math.ceil(Constants.GRID_ROWS / 2),
		math.ceil(Constants.GRID_PLACEABLE_COLS / 2)
	)
end

return Constants
