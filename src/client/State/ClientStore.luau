--!strict

--[[
	ClientStore (ModuleScript)
	État partagé côté client — permet à plusieurs LocalScripts de lire/écrire
	la sélection d'unité et le budget sans couplage direct.
	Accessible depuis : StarterPlayerScripts.Client.State.ClientStore
]]

local ClientStore = {}

-------------------------------------------------
-- Sélection d'unité
-------------------------------------------------
ClientStore.SelectedUnitId = nil :: string?

-- Callback optionnel déclenché quand la sélection change
ClientStore._onSelectionChanged = nil :: ((unitId: string?) -> ())?

function ClientStore.SetSelectedUnit(unitId: string?): ()
	ClientStore.SelectedUnitId = unitId
	if ClientStore._onSelectionChanged then
		ClientStore._onSelectionChanged(unitId)
	end
end

function ClientStore.GetSelectedUnit(): string?
	return ClientStore.SelectedUnitId
end

function ClientStore.OnSelectionChanged(callback: (unitId: string?) -> ()): ()
	ClientStore._onSelectionChanged = callback
end

-------------------------------------------------
-- Budget (mis à jour par les events serveur)
-------------------------------------------------
ClientStore.SpawnPoints = 0
ClientStore.ActionPoints = 0

function ClientStore.SetBudget(spawnPoints: number, actionPoints: number): ()
	ClientStore.SpawnPoints = spawnPoints
	ClientStore.ActionPoints = actionPoints
end

return ClientStore
