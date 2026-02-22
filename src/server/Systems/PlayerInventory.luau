--!strict

--[[
	PlayerInventory (ModuleScript — Serveur)
	Gère l'inventaire de chaque joueur :
	  • Unités débloquées (OwnedUnits)
	  • GachaTokens (monnaie de tirage)
	  • Compteurs de Pity (pulls depuis dernier Legendary / Mythic)
	  • Doublons = convertis en tokens bonus

	En mémoire uniquement (pas de DataStore pour l'instant).
	Accessible depuis : ServerScriptService.Server.Systems.PlayerInventory
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder: Instance = ReplicatedStorage:WaitForChild("Shared")
local GachaCatalog = require(sharedFolder:WaitForChild("Data"):WaitForChild("GachaCatalog"))

local PlayerInventory = {}

-------------------------------------------------
-- Types
-------------------------------------------------
export type InventoryData = {
	OwnedUnits: { [string]: number },  -- UnitId → nombre d'exemplaires
	Tokens: number,
	TotalPulls: number,
	PullsSinceLegendary: number,
	PullsSinceMythic: number,
}

-------------------------------------------------
-- Stockage en mémoire
-------------------------------------------------
local inventories: { [Player]: InventoryData } = {}

-- Tokens bonus pour les doublons (par rareté)
local DUPE_TOKEN_REWARD: { [string]: number } = {
	Common    = 0,
	Rare      = 1,
	Epic      = 2,
	Legendary = 5,
	Mythic    = 15,
}

-------------------------------------------------
-- API publique
-------------------------------------------------

function PlayerInventory.Init(player: Player): ()
	if inventories[player] then return end
	inventories[player] = {
		OwnedUnits = { Glorbo = 1 },    -- Tout le monde commence avec Glorbo
		Tokens = GachaCatalog.StartingTokens,
		TotalPulls = 0,
		PullsSinceLegendary = 0,
		PullsSinceMythic = 0,
	}
	print(`[PlayerInventory] Inventaire créé pour {player.Name} ({GachaCatalog.StartingTokens} tokens)`)
end

function PlayerInventory.Get(player: Player): InventoryData?
	return inventories[player]
end

function PlayerInventory.OwnsUnit(player: Player, unitId: string): boolean
	local inv = inventories[player]
	if inv == nil then return false end
	return (inv.OwnedUnits[unitId] or 0) > 0
end

--- Débloque une unité. Retourne true si c'est un nouveau drop, false si doublon.
function PlayerInventory.UnlockUnit(player: Player, unitId: string, rarity: string): boolean
	local inv = inventories[player]
	if inv == nil then return false end

	local count: number = inv.OwnedUnits[unitId] or 0
	inv.OwnedUnits[unitId] = count + 1

	if count > 0 then
		-- Doublon → bonus tokens
		local bonus: number = DUPE_TOKEN_REWARD[rarity] or 0
		if bonus > 0 then
			inv.Tokens += bonus
			print(`[PlayerInventory] Doublon de {unitId} pour {player.Name} → +{bonus} tokens`)
		end
		return false -- Pas nouveau
	end

	return true -- Nouvelle unité
end

function PlayerInventory.GetTokens(player: Player): number
	local inv = inventories[player]
	if inv == nil then return 0 end
	return inv.Tokens
end

function PlayerInventory.AddTokens(player: Player, amount: number): ()
	local inv = inventories[player]
	if inv == nil then return end
	inv.Tokens += amount
	print(`[PlayerInventory] {player.Name} +{amount} tokens → {inv.Tokens} total`)
end

function PlayerInventory.SpendTokens(player: Player, amount: number): boolean
	local inv = inventories[player]
	if inv == nil then return false end
	if inv.Tokens < amount then return false end
	inv.Tokens -= amount
	return true
end

function PlayerInventory.GetOwnedList(player: Player): { string }
	local inv = inventories[player]
	if inv == nil then return {} end
	local list: { string } = {}
	for unitId, count in inv.OwnedUnits do
		if count > 0 then
			table.insert(list, unitId)
		end
	end
	return list
end

function PlayerInventory.Cleanup(player: Player): ()
	inventories[player] = nil
end

-------------------------------------------------
-- Auto-init / cleanup
-------------------------------------------------
Players.PlayerAdded:Connect(function(player: Player)
	PlayerInventory.Init(player)
end)

for _, player: Player in Players:GetPlayers() do
	PlayerInventory.Init(player)
end

Players.PlayerRemoving:Connect(function(player: Player)
	PlayerInventory.Cleanup(player)
end)

return PlayerInventory
