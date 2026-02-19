--!strict

--[[
	DiceRoller (ModuleScript)
	Phase 2.1 — Task 2.1.1
	Système de lancer de dés avec Random.new() pour une meilleure entropie.
	Accessible depuis : ReplicatedStorage.Shared.Systems.DiceRoller
]]

local DiceRoller = {}

-- Instance RNG persistante (meilleure entropie que math.random)
local rng: Random = Random.new()

-- Constantes
local MIN_FACE: number = 1
local MAX_FACE: number = 6

--- Lance `amount` dés à 6 faces et retourne les résultats
--- @param amount number — Nombre de dés à lancer
--- @return {number} — Tableau des résultats (ex: {5, 2})
function DiceRoller.Roll(amount: number): { number }
	assert(amount > 0, "[DiceRoller] Le nombre de dés doit être > 0")

	local results: { number } = {}
	for i = 1, amount do
		results[i] = rng:NextInteger(MIN_FACE, MAX_FACE)
	end

	return results
end

return DiceRoller
