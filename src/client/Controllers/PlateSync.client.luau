--!strict

--[[
	PlateSync (LocalScript)
	Synchronise l'apparence des plaques d'achat avec l'inventaire du joueur.
	  • Plaque colorée (couleur de l'unité) → unité déverrouillée
	  • Plaque grise + cadenas → unité verrouillée
	  • Glow et bordures ajustés en conséquence
	Accessible depuis : StarterPlayerScripts.Client.Controllers.PlateSync
]]

-- Services
local Workspace: Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local sharedFolder: Instance = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(sharedFolder:WaitForChild("Constants"))
local UnitDatabase = require(sharedFolder:WaitForChild("Data"):WaitForChild("UnitDatabase"))
local GameStore = require(script.Parent.Parent:WaitForChild("State"):WaitForChild("GameStore"))

-- Events
local eventsFolder: Instance = sharedFolder:WaitForChild("Events")
local gachaInfoEvent: RemoteEvent = eventsFolder:WaitForChild("GachaInfo") :: RemoteEvent

-- Constantes
local GREY_COLOR: Color3 = Color3.fromRGB(60, 60, 65)
local GREY_BORDER: Color3 = Color3.fromRGB(40, 40, 45)
local LOCKED_TRANSPARENCY: number = 0.5
local PLANT_UNITS: { string } = Constants.PLANT_UNITS

-- État
local ownedUnits: { [string]: boolean } = { Glorbo = true }
local gameBoardRef: Folder? = nil

-------------------------------------------------
-- Attendre que GameBoard soit prêt
-------------------------------------------------
local function getGameBoard(): Folder
	if gameBoardRef then return gameBoardRef end
	gameBoardRef = Workspace:WaitForChild("GameBoard", 30) :: Folder
	return gameBoardRef
end

-------------------------------------------------
-- Mettre à jour l'apparence d'une plaque
-------------------------------------------------
local function updatePlate(unitId: string): ()
	local gameBoard: Folder = getGameBoard()
	if gameBoard == nil then return end

	local plateName: string = `Plate_{unitId}`
	local plate: Part? = gameBoard:FindFirstChild(plateName) :: Part?
	if plate == nil then return end

	local unitData = UnitDatabase[unitId]
	if unitData == nil then return end

	local isOwned: boolean = ownedUnits[unitId] == true

	-- Couleur et transparence de la plaque
	local targetColor: Color3 = if isOwned then unitData.Color else GREY_COLOR
	local targetTransparency: number = if isOwned then 0.1 else LOCKED_TRANSPARENCY

	TweenService:Create(plate, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {
		Color = targetColor,
		Transparency = targetTransparency,
	}):Play()

	-- Glow (PointLight)
	local glow: PointLight? = plate:FindFirstChildOfClass("PointLight") :: PointLight?
	if glow then
		TweenService:Create(glow, TweenInfo.new(0.4), {
			Color = targetColor,
			Brightness = if isOwned then 1 else 0.2,
			Range = if isOwned then 8 else 3,
		}):Play()
	end

	-- Bordures néon (dans GameBoard, pas dans la plaque)
	for j = 1, 4 do
		local borderName: string = `PlateBorder_{j}`
		-- Les bordures sont des enfants de gameBoard au même niveau que les plaques
		-- On doit les trouver par position relative
	end

	-- BillboardGui — ajuster l'opacité du texte si verrouillé
	local billboard: BillboardGui? = plate:FindFirstChild("PlateLabel") :: BillboardGui?
	if billboard then
		local nameLabel: TextLabel? = billboard:FindFirstChild("NameLabel") :: TextLabel?
		local costLabel: TextLabel? = billboard:FindFirstChild("CostLabel") :: TextLabel?
		local statsLabel: TextLabel? = billboard:FindFirstChild("StatsLabel") :: TextLabel?

		if nameLabel then
			nameLabel.TextColor3 = if isOwned then Color3.new(1, 1, 1) else Color3.fromRGB(100, 100, 110)
			-- Ajouter un indicateur de cadenas pour les unités verrouillées
			if isOwned then
				nameLabel.Text = unitData.Name
			else
				nameLabel.Text = `🔒 {unitData.Name}`
			end
		end
		if costLabel then
			costLabel.TextColor3 = if isOwned then Color3.fromRGB(255, 220, 50) else Color3.fromRGB(80, 80, 90)
		end
		if statsLabel then
			statsLabel.TextColor3 = if isOwned then Color3.fromRGB(200, 210, 220) else Color3.fromRGB(70, 70, 80)
		end
	end
end

-------------------------------------------------
-- Rafraîchir toutes les plaques
-------------------------------------------------
local function refreshAllPlates(): ()
	for _, unitId: string in PLANT_UNITS do
		updatePlate(unitId)
	end
end

-------------------------------------------------
-- Écouter les infos Gacha (inventaire)
-------------------------------------------------
gachaInfoEvent.OnClientEvent:Connect(function(data: any)
	if data.OwnedUnits then
		ownedUnits = {}
		for _, unitId in data.OwnedUnits do
			ownedUnits[unitId] = true
		end
		refreshAllPlates()
	end
end)

-------------------------------------------------
-- Écouter les changements de niveau (LevelSelected → rafraîchir plaques)
-------------------------------------------------
GameStore.LevelChanged:Connect(function(eventType: string, data: { [string]: any })
	if eventType == "LevelSelected" or eventType == "LevelStart" then
		-- Demander l'inventaire au serveur
		gachaInfoEvent:FireServer()
		-- Rafraîchir après un court délai pour laisser le temps au serveur
		task.delay(0.5, refreshAllPlates)
	end
end)

-- Init — rafraîchir quand le GameBoard est prêt
task.spawn(function()
	getGameBoard()
	task.wait(1)
	gachaInfoEvent:FireServer()
	task.wait(0.5)
	refreshAllPlates()
end)

print("[PlateSync] ✅ Synchronisation des plaques initialisée")
