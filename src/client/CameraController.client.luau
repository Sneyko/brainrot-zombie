--!strict

--[[
	CameraController (LocalScript)
	Caméra 3ème personne classique Roblox pour Brainrot Defense.
	Le joueur est sur le mur de défense et regarde les zombies arriver.
]]

-- Services
local Players: Players = game:GetService("Players")

-------------------------------------------------
-- Vue classique Roblox (3ème personne)
-------------------------------------------------
local player: Player = Players.LocalPlayer
player.CameraMode = Enum.CameraMode.Classic

print("[CameraController] ✅ Caméra 3ème personne classique")
