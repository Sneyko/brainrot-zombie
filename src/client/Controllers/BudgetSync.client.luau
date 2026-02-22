--!strict

--[[
	BrainCoinSync (LocalScript)
	Tower Defense temps réel — Synchronise les BrainCoin, niveaux et vagues
	du serveur avec le GameStore client.
	Écoute BudgetUpdate pour BrainCoin/BaseHP/Level/Wave.
	Écoute StateChanged pour les événements de niveau (LevelStart, WaveStart, etc.).
]]

-- Services
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local sharedFolder: Instance = ReplicatedStorage:WaitForChild("Shared")
local GameStore = require(script.Parent.Parent:WaitForChild("State"):WaitForChild("GameStore"))

-- RemoteEvents
local eventsFolder: Instance = sharedFolder:WaitForChild("Events")
local budgetUpdateEvent: RemoteEvent = eventsFolder:WaitForChild("BudgetUpdate") :: RemoteEvent
local stateChangedEvent: RemoteEvent = eventsFolder:WaitForChild("StateChanged") :: RemoteEvent

-------------------------------------------------
-- Écouter les mises à jour de BrainCoin + Niveau du serveur
-------------------------------------------------
budgetUpdateEvent.OnClientEvent:Connect(function(brainCoin: unknown, baseHP: unknown, level: unknown, wave: unknown, totalWaves: unknown): ()
	local bc: number = if typeof(brainCoin) == "number" then brainCoin else 0
	local hp: number = if typeof(baseHP) == "number" then baseHP else 0
	local lv: number = if typeof(level) == "number" then level else 0
	local wv: number = if typeof(wave) == "number" then wave else 0
	local tw: number = if typeof(totalWaves) == "number" then totalWaves else 0

	GameStore.SetBrainCoin(bc, hp, lv, wv, tw)
end)

-------------------------------------------------
-- Écouter les événements de niveau (LevelStart, WaveStart, etc.)
-------------------------------------------------
stateChangedEvent.OnClientEvent:Connect(function(eventType: unknown, data: unknown): ()
	local eType: string = if typeof(eventType) == "string" then eventType else ""
	local eData: { [string]: any } = if typeof(data) == "table" then data :: any else {}

	GameStore.FireLevelEvent(eType, eData)
	print(`[BrainCoinSync] 📡 Événement : {eType}`)
end)

print("[BrainCoinSync] ✅ Initialisé — Écoute BudgetUpdate + StateChanged")
