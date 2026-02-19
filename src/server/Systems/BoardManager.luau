--!strict

--[[
	BoardManager (ModuleScript)
	Gestion des unités défensives placées sur le sol.
	Plus de grille — les unités sont clonées depuis Assets et placées librement.
	Accessible depuis : ServerScriptService.Server.Systems.BoardManager
]]

-- Services
local Workspace: Workspace = game:GetService("Workspace")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local sharedFolder: Instance = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(sharedFolder:WaitForChild("Constants"))
local UnitDatabase = require(sharedFolder:WaitForChild("Data"):WaitForChild("UnitDatabase"))

-- Dossier Assets (modèles 3D des brainrot)
local assetsFolder: Folder = ReplicatedStorage:WaitForChild("Assets") :: Folder

-------------------------------------------------
-- Types
-------------------------------------------------
export type PlacedUnit = {
	Id: number,
	UnitId: string,       -- Clé dans UnitDatabase (ex: "Glorbo")
	Owner: Player?,
	Model: Model,         -- Modèle 3D cloné depuis Assets
	Position: Vector3,    -- Position world (centre au sol)
}

-------------------------------------------------
-- Module
-------------------------------------------------
local BoardManager = {}

BoardManager.PlacedUnits = {} :: { [number]: PlacedUnit }
local nextUnitId: number = 0

-------------------------------------------------
-- Placement d'unité (clone depuis Assets)
-------------------------------------------------

--- Place une unité sur le sol en clonant le modèle depuis Assets
function BoardManager.PlaceUnit(unitId: string, position: Vector3, owner: Player?): number
	local unitData = UnitDatabase[unitId]
	if unitData == nil then
		warn(`[BoardManager] ❌ Unité inconnue : "{unitId}"`)
		return -1
	end

	if unitData.Type ~= "Plant" then
		warn(`[BoardManager] ❌ "{unitId}" n'est pas une unité défensive`)
		return -1
	end

	-- Chercher le modèle dans Assets
	local templateName: string = `Unit_{unitId}`
	local template: Instance? = assetsFolder:FindFirstChild(templateName)
	if template == nil then
		warn(`[BoardManager] ❌ Asset introuvable : {templateName}`)
		return -1
	end

	-- Cloner le modèle
	local model: Model = template:Clone() :: Model

	nextUnitId += 1
	local id: number = nextUnitId
	model.Name = `PlacedUnit_{unitId}_{id}`

	-- Uniformiser la taille (tous à UNIT_MODEL_HEIGHT studs de haut)
	local scaleOk: boolean, scaleErr: string? = pcall(function(): ()
		local _, origSize: Vector3 = model:GetBoundingBox()
		local currentHeight: number = origSize.Y
		if currentHeight > 0 then
			local currentScale: number = model:GetScale()
			local scaleFactor: number = (Constants.UNIT_MODEL_HEIGHT / currentHeight) * currentScale
			model:ScaleTo(scaleFactor)
			print(`[BoardManager] 📐 {unitId} — hauteur orig: {math.floor(currentHeight)} → cible: {Constants.UNIT_MODEL_HEIGHT} (scale: {string.format("%.3f", scaleFactor)})`)
		else
			warn(`[BoardManager] ⚠️ {unitId} — bounding box vide (pas de BasePart ?)`)
		end
	end)
	if not scaleOk then
		warn(`[BoardManager] ⚠️ Erreur scale {unitId}: {scaleErr or "inconnue"}`)
	end

	-- Recalculer après mise à l'échelle
	local _, size: Vector3 = model:GetBoundingBox()
	local groundY: number = Constants.GROUND_TOP_Y + size.Y / 2
	local spawnPos: Vector3 = Vector3.new(position.X, groundY, position.Z)

	-- Positionner face aux zombies (+Z = direction d'où viennent les zombies)
	local lookTarget: Vector3 = spawnPos + Vector3.new(0, 0, 1)
	model:PivotTo(CFrame.lookAt(spawnPos, lookTarget))
	
	-- Ancrer toutes les parts 
	for _, descendant: Instance in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			(descendant :: BasePart).Anchored = true
			(descendant :: BasePart).CanCollide = false
		end
	end

	-- Placer dans le dossier GameBoard
	local gameBoard: Instance? = Workspace:FindFirstChild("GameBoard")
	model.Parent = if gameBoard then gameBoard else Workspace

	local unit: PlacedUnit = {
		Id = id,
		UnitId = unitId,
		Owner = owner,
		Model = model,
		Position = spawnPos,
	}

	BoardManager.PlacedUnits[id] = unit

	print(`[BoardManager] ✅ {unitData.Name} placé (ID:{id}) à ({math.floor(spawnPos.X)}, {math.floor(spawnPos.Z)})`)
	return id
end

-------------------------------------------------
-- Suppression d'unité
-------------------------------------------------

--- Supprime une unité placée
function BoardManager.RemoveUnit(id: number): ()
	local unit: PlacedUnit? = BoardManager.PlacedUnits[id]
	if unit == nil then return end

	if unit.Model then
		unit.Model:Destroy()
	end

	BoardManager.PlacedUnits[id] = nil
	print(`[BoardManager] 🗑️ Unité {id} supprimée`)
end

--- Retourne le nombre d'unités placées
function BoardManager.GetPlacedCount(): number
	local count: number = 0
	for _ in BoardManager.PlacedUnits do
		count += 1
	end
	return count
end

print("[BoardManager] ✅ BoardManager initialisé (mode liste)")

return BoardManager
