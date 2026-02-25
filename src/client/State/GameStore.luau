--!strict

--[[
	GameStore (ModuleScript)
	État partagé côté client — sélection d'unité, BrainCoin, HP base, niveau/vague.
	Tower Defense temps réel avec système de niveaux.
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
-- BrainCoin + Base HP + Niveau + Vague
-------------------------------------------------
GameStore.BrainCoin = 0
GameStore.BaseHP = 0
GameStore.CurrentLevel = 0
GameStore.CurrentWave = 0
GameStore.TotalWaves = 0

local brainCoinChangedEvent: BindableEvent = Instance.new("BindableEvent")
GameStore.BrainCoinChanged = brainCoinChangedEvent.Event

function GameStore.SetBrainCoin(brainCoin: number, baseHP: number, level: number?, wave: number?, totalWaves: number?): ()
	GameStore.BrainCoin = brainCoin
	GameStore.BaseHP = baseHP
	GameStore.CurrentLevel = level or GameStore.CurrentLevel
	GameStore.CurrentWave = wave or GameStore.CurrentWave
	GameStore.TotalWaves = totalWaves or GameStore.TotalWaves
	brainCoinChangedEvent:Fire(brainCoin, baseHP)
end

-------------------------------------------------
-- État "en niveau" (InLevel)
-------------------------------------------------
GameStore.InLevel = false

local inLevelChangedEvent: BindableEvent = Instance.new("BindableEvent")
GameStore.InLevelChanged = inLevelChangedEvent.Event

function GameStore.SetInLevel(value: boolean): ()
	if value == GameStore.InLevel then return end
	GameStore.InLevel = value
	inLevelChangedEvent:Fire(value)
end

-------------------------------------------------
-- Événements de niveau (LevelStart, WaveStart, etc.)
-------------------------------------------------
local levelChangedEvent: BindableEvent = Instance.new("BindableEvent")
GameStore.LevelChanged = levelChangedEvent.Event

function GameStore.FireLevelEvent(eventType: string, data: { [string]: any }): ()
	-- Mettre à jour InLevel automatiquement
	if eventType == "LevelStart" or eventType == "LevelSelected" then
		GameStore.SetInLevel(true)
	elseif eventType == "ReturnToMenu" or eventType == "GameOver" or eventType == "LevelComplete" then
		GameStore.SetInLevel(false)
	end

	levelChangedEvent:Fire(eventType, data)
end

return GameStore
