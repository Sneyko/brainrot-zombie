--!strict

--[[
	GameStore (ModuleScript)
	État partagé côté client — sélection d'unité, BrainCoin, HP base.
	Tower Defense temps réel.
	Accessible depuis : StarterPlayerScripts.Client.State.GameStore
]]

local GameStore = {}

-------------------------------------------------
-- Signal : SelectionChanged (BindableEvent)
-------------------------------------------------
local selectionChangedEvent: BindableEvent = Instance.new("BindableEvent")

--- Signal public — se connecter avec GameStore.SelectionChanged:Connect(function(unitId) end)
GameStore.SelectionChanged = selectionChangedEvent.Event

-------------------------------------------------
-- Sélection d'unité
-------------------------------------------------
local selectedUnitId: string? = nil

function GameStore.SetSelection(unitId: string?): ()
	if unitId == selectedUnitId then
		return
	end
	selectedUnitId = unitId
	selectionChangedEvent:Fire(unitId)
end

function GameStore.GetSelection(): string?
	return selectedUnitId
end

-------------------------------------------------
-- BrainCoin + Base HP (Tower Defense temps réel)
-------------------------------------------------
GameStore.BrainCoin = 0
GameStore.BaseHP = 0

local brainCoinChangedEvent: BindableEvent = Instance.new("BindableEvent")
GameStore.BrainCoinChanged = brainCoinChangedEvent.Event

function GameStore.SetBrainCoin(brainCoin: number, baseHP: number): ()
	GameStore.BrainCoin = brainCoin
	GameStore.BaseHP = baseHP
	brainCoinChangedEvent:Fire(brainCoin, baseHP)
end

return GameStore
