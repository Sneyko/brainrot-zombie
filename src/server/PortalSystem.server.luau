--!strict

--[[
	PortalSystem (ServerScript)
	Gère la détection des joueurs entrant dans les portails du spawn hub.
	  • Détecte la proximité joueur ↔ portail via Touched
	  • Portail "GameMap" → téléporte le joueur vers la zone de jeu (sur le mur)
	  • Portail "Shop" / "Sell" / "Gacha" → ouvre l'UI côté client
]]

-- Services
local Players = game:GetService("Players")
local Workspace: Workspace = game:GetService("Workspace")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local sharedFolder: Instance = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(sharedFolder:WaitForChild("Constants"))

-- Attendre que le SpawnHub soit construit
local spawnHub: Folder = Workspace:WaitForChild("SpawnHub", 30) :: Folder
if spawnHub == nil then
	warn("[PortalSystem] ⚠️ SpawnHub non trouvé, abandon.")
	return
end

-------------------------------------------------
-- RemoteEvent pour notifier le client
-------------------------------------------------
local eventsFolder: Instance = sharedFolder:WaitForChild("Events")
local portalEnteredEvent: RemoteEvent = eventsFolder:WaitForChild("PortalEntered") :: RemoteEvent

-------------------------------------------------
-- Destinations des portails
-------------------------------------------------
-- Position de jeu = sur le mur de défense (ancienne SpawnLocation)
local GAME_SPAWN_POS: Vector3 = Vector3.new(
	Constants.WALL_POSITION.X,
	Constants.WALL_TOP_Y + 3,
	Constants.WALL_FRONT_Z - 3
)

-- Position retour au spawn
local HUB_SPAWN_POS: Vector3 = Constants.SPAWN_CENTER + Vector3.new(0, 3, 15)

-------------------------------------------------
-- Cooldowns pour éviter les téléportations en boucle
-------------------------------------------------
local cooldowns: { [Player]: number } = {}
local COOLDOWN_TIME: number = 3 -- secondes

local function isOnCooldown(player: Player): boolean
	local lastTime = cooldowns[player]
	if lastTime and (tick() - lastTime) < COOLDOWN_TIME then
		return true
	end
	return false
end

local function setCooldown(player: Player): ()
	cooldowns[player] = tick()
end

-------------------------------------------------
-- Téléportation du joueur
-------------------------------------------------
local function teleportPlayer(player: Player, destination: Vector3): ()
	local character = player.Character
	if character == nil then return end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if humanoidRootPart == nil then return end
	
	humanoidRootPart.CFrame = CFrame.new(destination)
	setCooldown(player)
end

-------------------------------------------------
-- Gestion des portails
-------------------------------------------------
local function handlePortalTouch(portalId: string, player: Player): ()
	if isOnCooldown(player) then return end

	if portalId == "GameMap" then
		-- Téléporter vers la zone de jeu
		teleportPlayer(player, GAME_SPAWN_POS)
		-- Notifier le client pour afficher le bouton retour
		portalEnteredEvent:FireClient(player, "GameMap")
		print(`[PortalSystem] {player.Name} → Zone de jeu`)
	else
		-- Envoyer un événement au client pour ouvrir l'UI correspondante
		portalEnteredEvent:FireClient(player, portalId)
		setCooldown(player)
		print(`[PortalSystem] {player.Name} → UI "{portalId}"`)
	end
end

-------------------------------------------------
-- Connecter les zones de détection de chaque portail
-------------------------------------------------
local function setupPortalTriggers(): ()
	for _, portalData in Constants.PORTALS do
		local portalModel: Instance? = spawnHub:FindFirstChild(`Portal_{portalData.Id}`)
		if portalModel == nil then
			warn(`[PortalSystem] ⚠️ Portal_{portalData.Id} non trouvé`)
			continue
		end

		local portalEffect: Instance? = portalModel:FindFirstChild("PortalEffect")
		if portalEffect == nil or not portalEffect:IsA("BasePart") then
			warn(`[PortalSystem] ⚠️ PortalEffect manquant pour {portalData.Id}`)
			continue
		end

		-- Agrandir la hitbox pour la détection Touched
		local trigger: Part = Instance.new("Part")
		trigger.Name = "PortalTrigger"
		trigger.Size = Vector3.new(6, Constants.PORTAL_INNER_HEIGHT, Constants.PORTAL_INNER_WIDTH)
		trigger.CFrame = (portalEffect :: BasePart).CFrame
		trigger.Anchored = true
		trigger.CanCollide = false
		trigger.Transparency = 1
		trigger.Parent = portalModel

		trigger.Touched:Connect(function(hit: BasePart)
			local character: Model? = hit.Parent :: Model?
			if character == nil then return end

			local player: Player? = Players:GetPlayerFromCharacter(character)
			if player == nil then return end

			handlePortalTouch(portalData.Id, player)
		end)
	end

	print("[PortalSystem] ✅ Triggers des portails configurés")
end

-------------------------------------------------
-- Bouton retour au Hub (quand le joueur est en jeu)
-- Le client peut fire PortalEntered avec "ReturnToHub"
-------------------------------------------------
portalEnteredEvent.OnServerEvent:Connect(function(player: Player, action: string)
	if action == "ReturnToHub" then
		if isOnCooldown(player) then return end
		teleportPlayer(player, HUB_SPAWN_POS)
		print(`[PortalSystem] {player.Name} → Retour au Hub`)
	end
end)

-- Nettoyage cooldowns
Players.PlayerRemoving:Connect(function(player: Player)
	cooldowns[player] = nil
end)

-------------------------------------------------
-- Initialisation
-------------------------------------------------
setupPortalTriggers()
print("[PortalSystem] ✅ Système de portails initialisé")
