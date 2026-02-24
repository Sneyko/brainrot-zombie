--!strict

--[[
	CameraController (LocalScript)
	Caméra 3ème personne classique Roblox pour Brainrot Defense.
	Le joueur est sur le mur de défense et regarde les zombies arriver.

	NOTE : La transition vers la vue Top-Down (mode édition tactique)
	est gérée par TileSelector.client.luau via le module CameraUtils.
	Ce script ne gère que le mode par défaut.
]]

-- Services
local Players: Players = game:GetService("Players")

-------------------------------------------------
-- Vue classique Roblox (3ème personne)
-------------------------------------------------
local player: Player = Players.LocalPlayer
player.CameraMode = Enum.CameraMode.Classic

print("[CameraController] ✅ Caméra 3ème personne classique (E ou bouton UI → mode tactique)")
