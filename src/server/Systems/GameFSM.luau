--!strict

--[[
	GameFSM (ModuleScript)
	Phase 2 — Task 2.0.1 & 2.0.2
	Machine à états pour le déroulement des tours de Brainrot Defense.
	Accessible depuis : ServerScriptService.Server.Systems.GameFSM
]]

-- Services
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

-- RemoteEvent pour notifier les clients du changement d'état
local eventsFolder: Folder = ReplicatedStorage.Shared:WaitForChild("Events") :: Folder
local stateChangedEvent: RemoteEvent = eventsFolder:WaitForChild("StateChanged") :: RemoteEvent

-------------------------------------------------
-- Types
-------------------------------------------------
export type GameFSMType = {
	CurrentState: string,
	TurnNumber: number,
	TransitionTo: (self: GameFSMType, newState: string) -> boolean,
	GetState: (self: GameFSMType) -> string,
	GetTurnNumber: (self: GameFSMType) -> number,
}

-------------------------------------------------
-- FSM
-------------------------------------------------
local GameFSM: GameFSMType = {
	CurrentState = Constants.GAME_STATES.WAITING,
	TurnNumber = 0,
} :: GameFSMType

--- Transition vers un nouvel état avec validation
function GameFSM:TransitionTo(newState: string): boolean
	local currentState: string = self.CurrentState

	-- Vérifier que le nouvel état existe
	local stateExists: boolean = false
	for _, state: string in Constants.GAME_STATES do
		if state == newState then
			stateExists = true
			break
		end
	end

	if not stateExists then
		warn(`[GameFSM] ❌ État inconnu : "{newState}"`)
		return false
	end

	-- Vérifier que la transition est autorisée
	local expectedNext: string? = Constants.STATE_ORDER[currentState]
	if expectedNext ~= newState then
		warn(`[GameFSM] ❌ Transition invalide : "{currentState}" → "{newState}" (attendu : "{tostring(expectedNext)}")`)
		return false
	end

	-- Incrémenter le tour quand on entre en DICE_PHASE
	if newState == Constants.GAME_STATES.DICE_PHASE then
		self.TurnNumber += 1
	end

	-- Appliquer la transition
	self.CurrentState = newState
	print(`[GameFSM] ⚡ STATE: {newState} (Tour {self.TurnNumber})`)

	-- Notifier tous les clients
	stateChangedEvent:FireAllClients(newState, self.TurnNumber)

	return true
end

--- Retourne l'état actuel
function GameFSM:GetState(): string
	return self.CurrentState
end

--- Retourne le numéro de tour actuel
function GameFSM:GetTurnNumber(): number
	return self.TurnNumber
end

print(`[GameFSM] ✅ FSM initialisée — État initial : {GameFSM.CurrentState}`)

return GameFSM
