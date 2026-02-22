--!strict

--[[
	GachaSystem (ServerScript)
	Logique serveur du système de Gacha :
	  • Tirage pondéré (weighted RNG)
	  • Pity system (Legendary garanti @100, Mythic @500)
	  • Gestion des doublons (tokens bonus)
	  • Communication avec le client via RemoteEvents
	Accessible depuis : ServerScriptService.Server.GachaSystem
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local sharedFolder: Instance = ReplicatedStorage:WaitForChild("Shared")
local GachaCatalog = require(sharedFolder:WaitForChild("Data"):WaitForChild("GachaCatalog"))
local PlayerInventory = require(script.Parent:WaitForChild("Systems"):WaitForChild("PlayerInventory"))

-- RemoteEvents
local eventsFolder: Instance = sharedFolder:WaitForChild("Events")
local gachaPullEvent: RemoteEvent = eventsFolder:WaitForChild("GachaPull") :: RemoteEvent
local gachaResultEvent: RemoteEvent = eventsFolder:WaitForChild("GachaResult") :: RemoteEvent
local gachaInfoEvent: RemoteEvent = eventsFolder:WaitForChild("GachaInfo") :: RemoteEvent

-- RNG
local rng: Random = Random.new()

-------------------------------------------------
-- Helpers
-------------------------------------------------

local function isLegendaryPlus(rarity: string): boolean
	return rarity == "Legendary" or rarity == "Mythic"
end

local function isMythic(rarity: string): boolean
	return rarity == "Mythic"
end

--- Tirage pondéré classique dans le pool
local function rollFromPool(): (string, string) -- unitId, rarity
	local roll: number = rng:NextNumber() * 100
	local cumulative: number = 0

	for _, entry in GachaCatalog.Pool do
		cumulative += entry.Rate
		if roll <= cumulative then
			return entry.UnitId, entry.Rarity
		end
	end

	-- Fallback (ne devrait jamais arriver)
	local fallback = GachaCatalog.Pool[1]
	return fallback.UnitId, fallback.Rarity
end

--- Tirage garanti parmi les unités d'une rareté minimum
local function rollGuaranteed(minRarity: string): (string, string)
	local filtered: { { UnitId: string, Rarity: string, Rate: number } } = {}
	local totalRate: number = 0

	for _, entry in GachaCatalog.Pool do
		local include: boolean = false
		if minRarity == "Mythic" and entry.Rarity == "Mythic" then
			include = true
		elseif minRarity == "Legendary" and (entry.Rarity == "Legendary" or entry.Rarity == "Mythic") then
			include = true
		end

		if include then
			table.insert(filtered, entry)
			totalRate += entry.Rate
		end
	end

	if #filtered == 0 then
		return rollFromPool()
	end

	-- Tirage pondéré dans le sous-pool
	local roll: number = rng:NextNumber() * totalRate
	local cumulative: number = 0

	for _, entry in filtered do
		cumulative += entry.Rate
		if roll <= cumulative then
			return entry.UnitId, entry.Rarity
		end
	end

	return filtered[1].UnitId, filtered[1].Rarity
end

-------------------------------------------------
-- Tirage unique
-------------------------------------------------
local function performSinglePull(player: Player): { UnitId: string, Rarity: string, IsPity: boolean, IsNew: boolean }
	local inv = PlayerInventory.Get(player)
	if inv == nil then
		return { UnitId = "Glorbo", Rarity = "Common", IsPity = false, IsNew = false }
	end

	-- Incrémenter les compteurs
	inv.TotalPulls += 1
	inv.PullsSinceLegendary += 1
	inv.PullsSinceMythic += 1

	local unitId: string
	local rarity: string
	local isPity: boolean = false

	-- Vérifier le Pity (Mythic d'abord, priorité haute)
	if inv.PullsSinceMythic >= GachaCatalog.PityMythic then
		unitId, rarity = rollGuaranteed("Mythic")
		isPity = true
		print(`[GachaSystem] PITY MYTHIC pour {player.Name} à {inv.TotalPulls} pulls !`)
	elseif inv.PullsSinceLegendary >= GachaCatalog.PityLegendary then
		unitId, rarity = rollGuaranteed("Legendary")
		isPity = true
		print(`[GachaSystem] PITY LEGENDARY pour {player.Name} à {inv.TotalPulls} pulls !`)
	else
		unitId, rarity = rollFromPool()
	end

	-- Reset des compteurs de pity
	if isMythic(rarity) then
		inv.PullsSinceMythic = 0
		inv.PullsSinceLegendary = 0
	elseif isLegendaryPlus(rarity) then
		inv.PullsSinceLegendary = 0
	end

	-- Débloquer l'unité (gère les doublons)
	local isNew: boolean = PlayerInventory.UnlockUnit(player, unitId, rarity)

	print(`[GachaSystem] {player.Name} → {unitId} ({rarity}){if isPity then " [PITY]" else ""}{if isNew then " [NEW]" else " [DUPE]"}`)

	return {
		UnitId = unitId,
		Rarity = rarity,
		IsPity = isPity,
		IsNew = isNew,
	}
end

-------------------------------------------------
-- Envoyer l'état de l'inventaire au client
-------------------------------------------------
local function sendGachaInfo(player: Player): ()
	local inv = PlayerInventory.Get(player)
	if inv == nil then return end

	gachaInfoEvent:FireClient(player, {
		Tokens = inv.Tokens,
		TotalPulls = inv.TotalPulls,
		PullsSinceLegendary = inv.PullsSinceLegendary,
		PullsSinceMythic = inv.PullsSinceMythic,
		PityLegendary = GachaCatalog.PityLegendary,
		PityMythic = GachaCatalog.PityMythic,
		OwnedUnits = PlayerInventory.GetOwnedList(player),
	})
end

-------------------------------------------------
-- Écouter les demandes de tirage
-------------------------------------------------
gachaPullEvent.OnServerEvent:Connect(function(player: Player, pullType: unknown)
	local pType: string = if typeof(pullType) == "string" then pullType else "single"

	local pullCount: number
	local cost: number

	if pType == "multi" then
		pullCount = GachaCatalog.MultiPullCount
		cost = GachaCatalog.MultiPullCostTokens
	else
		pullCount = 1
		cost = GachaCatalog.PullCostTokens
	end

	-- Vérifier les tokens
	if not PlayerInventory.SpendTokens(player, cost) then
		gachaResultEvent:FireClient(player, {
			Error = "NotEnoughTokens",
			TokensLeft = PlayerInventory.GetTokens(player),
		})
		return
	end

	-- Effectuer les tirages
	local results: { any } = {}
	for _ = 1, pullCount do
		local result = performSinglePull(player)
		table.insert(results, result)
	end

	-- Envoyer les résultats
	gachaResultEvent:FireClient(player, {
		Results = results,
		TokensLeft = PlayerInventory.GetTokens(player),
	})

	print(`[GachaSystem] {player.Name} a tiré {pullCount}x`)
end)

-------------------------------------------------
-- Écouter les demandes d'info (quand le UI s'ouvre)
-------------------------------------------------
gachaInfoEvent.OnServerEvent:Connect(function(player: Player)
	sendGachaInfo(player)
end)

-------------------------------------------------
-- Envoyer l'info au joueur quand il se connecte
-------------------------------------------------
Players.PlayerAdded:Connect(function(player: Player)
	task.wait(2) -- Laisser le temps à l'inventaire de s'init
	sendGachaInfo(player)
end)

-- Init pour les joueurs déjà connectés
task.defer(function()
	for _, player: Player in Players:GetPlayers() do
		sendGachaInfo(player)
	end
end)

print("[GachaSystem] ✅ Système de Gacha initialisé")
print(`[GachaSystem]    Pity Legendary : {GachaCatalog.PityLegendary} pulls`)
print(`[GachaSystem]    Pity Mythic : {GachaCatalog.PityMythic} pulls`)
print(`[GachaSystem]    Pool : {#GachaCatalog.Pool} unités`)
