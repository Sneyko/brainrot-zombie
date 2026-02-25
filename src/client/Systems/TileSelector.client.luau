--!strict

--[[
	TileSelector (LocalScript)
	Mode Édition Tactique — Vue Top-Down + Grille Interactive.

	Fonctionnalités :
	  • Bouton UI (ou touche E) pour activer/désactiver le mode édition
	  • Caméra Top-Down fixe au-dessus de la grille de défense
	  • Curseur visuel (Part semi-transparente) qui snap sur la grille 5×8
	  • Raycast depuis la souris → intersection plan Y = sol → coordonnées grille
	  • Clic sur unité déjà posée → sélection (Highlight bleu)
	  • Clic sur case vide → déplacement via RemoteEvent sécurisé "MoveUnit"
	  • Clic droit → désélection

	Rojo : StarterPlayerScripts.Client.Systems.TileSelector
]]

-- Services
local Players: Players = game:GetService("Players")
local UserInputService: UserInputService = game:GetService("UserInputService")
local RunService: RunService = game:GetService("RunService")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Modules
local sharedFolder: Instance = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(sharedFolder:WaitForChild("Constants"))
local CameraUtils = require(script.Parent:WaitForChild("CameraUtils"))
local GameStore = require(script.Parent.Parent:WaitForChild("State"):WaitForChild("GameStore"))

-- Player
local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui

-- RemoteEvents
local eventsFolder: Instance = sharedFolder:WaitForChild("Events")
local moveUnitEvent: RemoteEvent = eventsFolder:WaitForChild("MoveUnit") :: RemoteEvent

-------------------------------------------------
-- Constantes locales (dérivées de Constants)
-------------------------------------------------
local GRID_ROWS: number = Constants.GRID_ROWS
local GRID_COLS: number = Constants.GRID_PLACEABLE_COLS
local TILE_SIZE: number = Constants.TILE_SIZE
local GROUND_Y: number = Constants.GROUND_TOP_Y

-------------------------------------------------
-- État du mode édition
-------------------------------------------------
local editMode: boolean = false
local selectedUnitId: number? = nil

-- Références visuelles (créées à la demande)
local gridFolder: Folder? = nil           -- Dossier contenant les tiles de la grille
local cursorPart: Part? = nil             -- Part curseur qui suit la souris
local selectionHighlight: Highlight? = nil -- Highlight sur l'unité sélectionnée

-- Connexion RenderStepped (boucle curseur)
local renderConnection: RBXScriptConnection? = nil

-- Debounce pour le toggle
local lastToggle: number = 0
local TOGGLE_COOLDOWN: number = 0.5

-- Pan clavier : touches enfoncées
local heldKeys: { [Enum.KeyCode]: boolean } = {}

-------------------------------------------------
-- 1. CALCUL DE GRILLE (Raycasting mathématique)
--    Intersection Rayon → Plan Y = GROUND_Y
--    Puis conversion en coordonnées (row, col)
-------------------------------------------------

--- Calcule la cellule de grille sous le curseur souris.
--- Utilise camera:ScreenPointToRay + intersection plan Y = GROUND_Y.
--- Retourne (row, col) ou (nil, nil) si hors grille.
local function getGridCellFromMouse(): (number?, number?)
	local camera: Camera = Workspace.CurrentCamera
	if camera == nil then return nil, nil end

	-- Ray depuis la position de la souris à l'écran
	local mouseLocation: Vector2 = UserInputService:GetMouseLocation()
	local unitRay: Ray = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

	-- Intersection rayon / plan horizontal Y = GROUND_Y
	-- Équation : Origin.Y + t × Direction.Y = GROUND_Y
	local dirY: number = unitRay.Direction.Y
	if math.abs(dirY) < 0.001 then return nil, nil end -- rayon quasi-horizontal

	local t: number = (GROUND_Y - unitRay.Origin.Y) / dirY
	if t <= 0 then return nil, nil end -- plan derrière la caméra

	-- Point d'impact sur le plan sol
	local hitPoint: Vector3 = unitRay.Origin + unitRay.Direction * t

	-- Conversion world → grille
	return Constants.WorldToGrid(hitPoint)
end

-------------------------------------------------
-- 2. DÉTECTION D'UNITÉ SOUS LA SOURIS (Raycast physique)
--    Raycast complet dans le monde pour trouver un
--    modèle PlacedUnit touché par le clic.
-------------------------------------------------

--- Retourne l'ID numérique unique du PlacedUnit sous la souris, ou nil.
local function getUnitIdAtMouse(): number?
	local camera: Camera = Workspace.CurrentCamera
	if camera == nil then return nil end

	local mouseLocation: Vector2 = UserInputService:GetMouseLocation()
	local unitRay: Ray = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

	-- Params : exclure le personnage, la grille visuelle, et le curseur
	local params: RaycastParams = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local filterList: { Instance } = {}
	if player.Character then table.insert(filterList, player.Character) end
	if gridFolder then table.insert(filterList, gridFolder) end
	if cursorPart then table.insert(filterList, cursorPart) end
	params.FilterDescendantsInstances = filterList

	local result: RaycastResult? = Workspace:Raycast(
		unitRay.Origin,
		unitRay.Direction * 500,
		params
	)
	if result == nil then return nil end

	-- Remonter l'arborescence pour trouver un Model "PlacedUnit_{UnitId}_{NumericId}"
	local current: Instance? = result.Instance
	while current and current ~= Workspace do
		if current:IsA("Model") then
			local name: string = current.Name
			local idStr: string? = string.match(name, "^PlacedUnit_%w+_(%d+)$")
			if idStr then
				return tonumber(idStr)
			end
		end
		current = current.Parent
	end
	return nil
end

-------------------------------------------------
-- 3. SÉLECTION VISUELLE
--    Highlight bleu sur l'unité sélectionnée.
-------------------------------------------------

local function clearSelection(): ()
	selectedUnitId = nil
	if selectionHighlight then
		selectionHighlight:Destroy()
		selectionHighlight = nil
	end
end

local function selectUnit(unitId: number): ()
	clearSelection()
	selectedUnitId = unitId

	-- Trouver le modèle correspondant dans GameBoard
	local gameBoard: Instance? = Workspace:FindFirstChild("GameBoard")
	if gameBoard == nil then return end

	for _, child: Instance in gameBoard:GetChildren() do
		if child:IsA("Model") then
			local idStr: string? = string.match(child.Name, "^PlacedUnit_%w+_(%d+)$")
			if idStr and tonumber(idStr) == unitId then
				-- Créer le Highlight visuel
				local hl: Highlight = Instance.new("Highlight")
				hl.Name = "EditSelection"
				hl.FillColor = Color3.fromRGB(0, 150, 255)
				hl.FillTransparency = 0.5
				hl.OutlineColor = Color3.fromRGB(50, 200, 255)
				hl.OutlineTransparency = 0
				hl.Adornee = child
				hl.Parent = playerGui -- Highlight local uniquement
				selectionHighlight = hl
				print(`[TileSelector] 🔵 Unité {unitId} sélectionnée`)
				break
			end
		end
	end
end

-------------------------------------------------
-- 4. GRILLE VISUELLE (40 tiles Neon semi-transparentes)
--    Créée une fois, montrée/cachée avec le mode édition.
-------------------------------------------------

local function createGridVisualization(): Folder
	local folder: Folder = Instance.new("Folder")
	folder.Name = "TacticalGrid"

	for row = 1, GRID_ROWS do
		for col = 1, GRID_COLS do
			local cellPos: Vector3 = Constants.GridToWorld(row, col)

			local cell: Part = Instance.new("Part")
			cell.Name = `Cell_{row}_{col}`
			cell.Size = Vector3.new(TILE_SIZE - 0.3, 0.05, TILE_SIZE - 0.3)
			cell.Position = Vector3.new(cellPos.X, GROUND_Y + 0.15, cellPos.Z)
			cell.Anchored = true
			cell.CanCollide = false
			cell.CanQuery = false -- Invisible au Raycast
			cell.Material = Enum.Material.Neon
			cell.Color = Color3.fromRGB(100, 200, 255)
			cell.Transparency = 0.88
			cell.Parent = folder

			-- Contour fin autour de chaque cellule
			local border: SelectionBox = Instance.new("SelectionBox")
			border.Adornee = cell
			border.Color3 = Color3.fromRGB(80, 160, 220)
			border.LineThickness = 0.02
			border.Transparency = 0.6
			border.Parent = cell
		end
	end

	return folder
end

-------------------------------------------------
-- 5. CURSEUR SOURIS (Part qui snap sur la grille)
-------------------------------------------------

local function createCursor(): Part
	local cursor: Part = Instance.new("Part")
	cursor.Name = "GridCursor"
	cursor.Size = Vector3.new(TILE_SIZE - 0.1, 0.25, TILE_SIZE - 0.1)
	cursor.Anchored = true
	cursor.CanCollide = false
	cursor.CanQuery = false -- Invisible au Raycast
	cursor.Material = Enum.Material.Neon
	cursor.Color = Color3.fromRGB(0, 255, 120)
	cursor.Transparency = 1 -- Invisible au départ
	return cursor
end

-------------------------------------------------
-- 6. UI : Bouton "📐 MODE TACTIQUE"
-------------------------------------------------

local function createEditButton(): TextButton
	local screenGui: ScreenGui = Instance.new("ScreenGui")
	screenGui.Name = "EditModeUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	local button: TextButton = Instance.new("TextButton")
	button.Name = "EditModeButton"
	button.Size = UDim2.fromOffset(200, 50)
	button.Position = UDim2.new(0.5, -100, 0, 12)
	button.AnchorPoint = Vector2.new(0, 0)
	button.BackgroundColor3 = Color3.fromRGB(30, 30, 55)
	button.TextColor3 = Color3.fromRGB(200, 220, 255)
	button.Text = "📐 MODE TACTIQUE"
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = true
	button.Parent = screenGui

	local corner: UICorner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button

	local stroke: UIStroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 160, 255)
	stroke.Thickness = 2
	stroke.Parent = button

	local padding: UIPadding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = button

	return button
end

-------------------------------------------------
-- 7. TOGGLE — Entrée / Sortie du mode édition
-------------------------------------------------

local function enterEditMode(): ()
	editMode = true

	-- Afficher la grille visuelle
	if gridFolder == nil then
		gridFolder = createGridVisualization()
	end
	gridFolder.Parent = Workspace

	-- Créer le curseur s'il n'existe pas
	if cursorPart == nil then
		cursorPart = createCursor()
	end
	cursorPart.Transparency = 1 -- Invisible jusqu'au premier hover valide
	cursorPart.Parent = Workspace

	-- Transition caméra → Top-Down
	CameraUtils.TransitionToTopDown()

	-- Boucle RenderStepped : curseur + pan clavier
	if renderConnection then renderConnection:Disconnect() end
	renderConnection = RunService.RenderStepped:Connect(function(dt: number): ()
		if not editMode then return end

		-------------------------------------------------
		-- Pan horizontal (ZQSD / Flèches / WASD)
		-- En vue top-down : écran haut = +X monde, écran droite = +Z monde
		-------------------------------------------------
		local panX: number = 0
		local panZ: number = 0
		-- Haut (écran haut = +X en monde)
		if heldKeys[Enum.KeyCode.Z] or heldKeys[Enum.KeyCode.W] or heldKeys[Enum.KeyCode.Up] then
			panX += 1
		end
		-- Bas (écran bas = -X en monde)
		if heldKeys[Enum.KeyCode.S] or heldKeys[Enum.KeyCode.Down] then
			panX -= 1
		end
		-- Gauche (écran gauche = -Z en monde)
		if heldKeys[Enum.KeyCode.Q] or heldKeys[Enum.KeyCode.A] or heldKeys[Enum.KeyCode.Left] then
			panZ -= 1
		end
		-- Droite (écran droite = +Z en monde)
		if heldKeys[Enum.KeyCode.D] or heldKeys[Enum.KeyCode.Right] then
			panZ += 1
		end

		if panX ~= 0 or panZ ~= 0 then
			local speed: number = Constants.TOPDOWN_PAN_SPEED
			CameraUtils.UpdatePan(panX * speed * dt, panZ * speed * dt)
		end

		-------------------------------------------------
		-- Curseur grille
		-------------------------------------------------
		if cursorPart == nil then return end

		local row: number?, col: number? = getGridCellFromMouse()
		if row and col then
			local worldPos: Vector3 = Constants.GridToWorld(row :: number, col :: number)
			cursorPart.Position = Vector3.new(worldPos.X, GROUND_Y + 0.35, worldPos.Z)
			cursorPart.Transparency = 0.35

			-- Couleur contextuelle :
			--   • Vert  = case vide (déplacement possible)
			--   • Jaune = unité dessus (sélectionnable)
			local unitAtMouse: number? = getUnitIdAtMouse()
			if unitAtMouse then
				cursorPart.Color = Color3.fromRGB(255, 220, 50) -- Jaune : sélectionnable
			elseif selectedUnitId then
				cursorPart.Color = Color3.fromRGB(0, 255, 120) -- Vert : déplacer ici
			else
				cursorPart.Color = Color3.fromRGB(100, 200, 255) -- Bleu clair : neutre
			end
		else
			cursorPart.Transparency = 1 -- Hors de la grille
		end
	end)

	print("[TileSelector] 📐 Mode édition ACTIVÉ — Vue Top-Down")
end

local function exitEditMode(): ()
	editMode = false
	clearSelection()

	-- Cacher la grille
	if gridFolder then
		gridFolder.Parent = nil
	end

	-- Cacher le curseur
	if cursorPart then
		cursorPart.Transparency = 1
	end

	-- Déconnecter la boucle de rendu
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end

	-- Reset pan keys
	table.clear(heldKeys)

	-- Retour caméra → 3ème personne
	CameraUtils.TransitionToNormal()

	print("[TileSelector] 📐 Mode édition DÉSACTIVÉ — Vue 3ème personne")
end

local function toggleEditMode(): ()
	local now: number = tick()
	if (now - lastToggle) < TOGGLE_COOLDOWN then return end
	lastToggle = now

	if editMode then
		exitEditMode()
	else
		enterEditMode()
	end
end

-------------------------------------------------
-- 8. ENTRÉES — Clic souris + raccourci clavier
-------------------------------------------------

-- Clic gauche : sélectionner une unité OU déplacer l'unité sélectionnée
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean): ()
	if gameProcessed then return end
	if not editMode then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		-- 1) Vérifier si on clique directement sur un PlacedUnit
		local clickedUnitId: number? = getUnitIdAtMouse()
		if clickedUnitId then
			if selectedUnitId == clickedUnitId then
				-- Re-clic sur la même unité → désélectionner
				clearSelection()
			else
				selectUnit(clickedUnitId)
			end
			return
		end

		-- 2) Si une unité est sélectionnée → tenter le déplacement
		if selectedUnitId then
			local row: number?, col: number? = getGridCellFromMouse()
			if row and col then
				print(`[TileSelector] 📤 MoveUnit({selectedUnitId}) → ({row}, {col})`)
				moveUnitEvent:FireServer(selectedUnitId, row, col)
				clearSelection()
			end
		end
	end

	-- Clic droit : désélectionner
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		clearSelection()
	end
end)

-- Raccourci clavier : E pour basculer le mode édition + suivi pan keys
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean): ()
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.E then
		if not GameStore.InLevel then return end -- bloquer hors niveau
		toggleEditMode()
		return
	end
	-- Enregistrer les touches de pan
	if editMode and input.KeyCode ~= Enum.KeyCode.Unknown then
		heldKeys[input.KeyCode] = true
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject): ()
	if input.KeyCode ~= Enum.KeyCode.Unknown then
		heldKeys[input.KeyCode] = nil
	end
end)

-------------------------------------------------
-- 9. SÉCURITÉ — Quitter le mode si le joueur meurt
-------------------------------------------------
player.CharacterAdded:Connect(function(): ()
	if editMode then
		exitEditMode()
	end
end)

-------------------------------------------------
-- 10. INITIALISATION
-------------------------------------------------

-- Créer le bouton UI
local editButton: TextButton = createEditButton()
editButton.Activated:Connect(toggleEditMode)

-- Cacher le bouton par défaut (visible uniquement en niveau)
local editButtonGui: ScreenGui = editButton.Parent :: ScreenGui
editButtonGui.Enabled = GameStore.InLevel

-- Mettre à jour le texte du bouton quand l'état change
local function updateButtonVisual(): ()
	if editMode then
		editButton.Text = "🔙 RETOUR (E)"
		editButton.BackgroundColor3 = Color3.fromRGB(55, 30, 30)
	else
		editButton.Text = "📐 TACTIQUE (E)"
		editButton.BackgroundColor3 = Color3.fromRGB(30, 30, 55)
	end
end

-- Écouter le changement d'état InLevel pour afficher/cacher le bouton tactique
GameStore.InLevelChanged:Connect(function(inLevel: boolean): ()
	editButtonGui.Enabled = inLevel
	-- Si on quitte le niveau et qu'on est en mode édition, on en sort
	if not inLevel and editMode then
		exitEditMode()
	end
end)

-- Polling léger pour sync le bouton (pas de RenderStepped, juste Heartbeat throttled)
local buttonSyncAccum: number = 0
RunService.Heartbeat:Connect(function(dt: number): ()
	buttonSyncAccum += dt
	if buttonSyncAccum >= 0.25 then
		buttonSyncAccum = 0
		updateButtonVisual()
	end
end)

print("[TileSelector] ✅ Système tactique initialisé — Touche E ou bouton UI pour basculer")