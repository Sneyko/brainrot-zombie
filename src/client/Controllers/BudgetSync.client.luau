--!strict

--[[
	BrainCoinSync (LocalScript)
	Tower Defense temps réel — Synchronise les BrainCoin serveur avec le GameStore client.
	Écoute le RemoteEvent BudgetUpdate pour mettre à jour BrainCoin et BaseHP.
]]

-- Services
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local sharedFolder: Instance = ReplicatedStorage:WaitForChild("Shared")
local GameStore = require(script.Parent.Parent:WaitForChild("State"):WaitForChild("GameStore"))

-- RemoteEvents
local eventsFolder: Instance = sharedFolder:WaitForChild("Events")
local budgetUpdateEvent: RemoteEvent = eventsFolder:WaitForChild("BudgetUpdate") :: RemoteEvent

-------------------------------------------------
-- Écouter les mises à jour de BrainCoin du serveur
-------------------------------------------------
budgetUpdateEvent.OnClientEvent:Connect(function(brainCoin: unknown, baseHP: unknown): ()
	local bc: number = if typeof(brainCoin) == "number" then brainCoin else 0
	local hp: number = if typeof(baseHP) == "number" then baseHP else 0

	GameStore.SetBrainCoin(bc, hp)
	print(`[BrainCoinSync] 🧠 BrainCoin: {bc} | 🏠 Base HP: {hp}`)
end)

print("[BrainCoinSync] ✅ Initialisé — Écoute BudgetUpdate")
