--!strict

--[[
	SpawnHUD (ClientScript)
	Gère l'interface du Spawn Hub côté client :
	  • Affiche un message de bienvenue
	  • Écoute le RemoteEvent PortalEntered pour ouvrir des UI contextuelles
	  • Bouton "Retour au Hub" quand le joueur est en zone de jeu
	  • Popup Shop / Sell / Gacha (placeholder)
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Modules
local sharedFolder: Instance = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(sharedFolder:WaitForChild("Constants"))

-- Player
local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui

-- Events
local eventsFolder: Instance = sharedFolder:WaitForChild("Events")
local portalEnteredEvent: RemoteEvent = eventsFolder:WaitForChild("PortalEntered") :: RemoteEvent

-------------------------------------------------
-- Utilitaires UI
-------------------------------------------------
local function tweenIn(guiObject: GuiObject): ()
	guiObject.Size = UDim2.fromScale(0, 0)
	guiObject.Visible = true
	local tween = TweenService:Create(guiObject, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = guiObject:GetAttribute("TargetSize") or UDim2.fromScale(0.4, 0.5),
	})
	tween:Play()
end

local function tweenOut(guiObject: GuiObject): ()
	local tween = TweenService:Create(guiObject, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.fromScale(0, 0),
	})
	tween:Play()
	tween.Completed:Connect(function()
		guiObject.Visible = false
	end)
end

-------------------------------------------------
-- 1. ScreenGui principal du Hub
-------------------------------------------------
local screenGui: ScreenGui = Instance.new("ScreenGui")
screenGui.Name = "SpawnHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-------------------------------------------------
-- 2. Message de bienvenue
-------------------------------------------------
local welcomeFrame: Frame = Instance.new("Frame")
welcomeFrame.Name = "WelcomeFrame"
welcomeFrame.Size = UDim2.fromScale(0.4, 0.12)
welcomeFrame.Position = UDim2.fromScale(0.3, 0.05)
welcomeFrame.BackgroundColor3 = Color3.fromRGB(20, 15, 40)
welcomeFrame.BackgroundTransparency = 0.3
welcomeFrame.BorderSizePixel = 0
welcomeFrame.Parent = screenGui

local welcomeCorner: UICorner = Instance.new("UICorner")
welcomeCorner.CornerRadius = UDim.new(0, 16)
welcomeCorner.Parent = welcomeFrame

local welcomeStroke: UIStroke = Instance.new("UIStroke")
welcomeStroke.Color = Color3.fromRGB(0, 200, 255)
welcomeStroke.Thickness = 2
welcomeStroke.Transparency = 0.3
welcomeStroke.Parent = welcomeFrame

local welcomeLabel: TextLabel = Instance.new("TextLabel")
welcomeLabel.Name = "WelcomeText"
welcomeLabel.Size = UDim2.fromScale(1, 0.55)
welcomeLabel.Position = UDim2.fromScale(0, 0.05)
welcomeLabel.BackgroundTransparency = 1
welcomeLabel.Text = "🧠 BRAINROT DEFENSE"
welcomeLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
welcomeLabel.TextStrokeTransparency = 0
welcomeLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
welcomeLabel.TextScaled = true
welcomeLabel.Font = Enum.Font.FredokaOne
welcomeLabel.Parent = welcomeFrame

local subWelcome: TextLabel = Instance.new("TextLabel")
subWelcome.Name = "SubText"
subWelcome.Size = UDim2.fromScale(1, 0.35)
subWelcome.Position = UDim2.fromScale(0, 0.55)
subWelcome.BackgroundTransparency = 1
subWelcome.Text = "Marche vers un portail pour commencer !"
subWelcome.TextColor3 = Color3.fromRGB(200, 200, 220)
subWelcome.TextStrokeTransparency = 0.3
subWelcome.TextScaled = true
subWelcome.Font = Enum.Font.GothamBold
subWelcome.Parent = welcomeFrame

-- Fade out après 5s
task.delay(6, function()
	local tween = TweenService:Create(welcomeFrame, TweenInfo.new(1.5), {
		BackgroundTransparency = 1,
	})
	tween:Play()
	for _, child in welcomeFrame:GetChildren() do
		if child:IsA("TextLabel") then
			TweenService:Create(child, TweenInfo.new(1.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		elseif child:IsA("UIStroke") then
			TweenService:Create(child, TweenInfo.new(1.5), { Transparency = 1 }):Play()
		end
	end
end)

-------------------------------------------------
-- 3. Monnaie affichée (HUD en haut à droite)
-------------------------------------------------
local currencyFrame: Frame = Instance.new("Frame")
currencyFrame.Name = "CurrencyFrame"
currencyFrame.Size = UDim2.fromScale(0.15, 0.05)
currencyFrame.Position = UDim2.fromScale(0.83, 0.02)
currencyFrame.BackgroundColor3 = Color3.fromRGB(20, 15, 40)
currencyFrame.BackgroundTransparency = 0.4
currencyFrame.BorderSizePixel = 0
currencyFrame.Parent = screenGui

local currCorner: UICorner = Instance.new("UICorner")
currCorner.CornerRadius = UDim.new(0, 12)
currCorner.Parent = currencyFrame

local currStroke: UIStroke = Instance.new("UIStroke")
currStroke.Color = Color3.fromRGB(255, 200, 50)
currStroke.Thickness = 2
currStroke.Transparency = 0.3
currStroke.Parent = currencyFrame

local currLabel: TextLabel = Instance.new("TextLabel")
currLabel.Name = "GemsLabel"
currLabel.Size = UDim2.fromScale(1, 1)
currLabel.BackgroundTransparency = 1
currLabel.Text = "💎 0 Gems"
currLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
currLabel.TextStrokeTransparency = 0
currLabel.TextScaled = true
currLabel.Font = Enum.Font.FredokaOne
currLabel.Parent = currencyFrame

-------------------------------------------------
-- 4. Bouton Retour au Hub (visible en zone de jeu)
-------------------------------------------------
local returnBtn: TextButton = Instance.new("TextButton")
returnBtn.Name = "ReturnToHub"
returnBtn.Size = UDim2.fromScale(0.12, 0.05)
returnBtn.Position = UDim2.fromScale(0.02, 0.93)
returnBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
returnBtn.BackgroundTransparency = 0.2
returnBtn.BorderSizePixel = 0
returnBtn.Text = "🏠 Retour au Hub"
returnBtn.TextColor3 = Color3.new(1, 1, 1)
returnBtn.TextStrokeTransparency = 0
returnBtn.TextScaled = true
returnBtn.Font = Enum.Font.FredokaOne
returnBtn.Visible = false
returnBtn.Parent = screenGui

local returnCorner: UICorner = Instance.new("UICorner")
returnCorner.CornerRadius = UDim.new(0, 10)
returnCorner.Parent = returnBtn

returnBtn.MouseButton1Click:Connect(function()
	portalEnteredEvent:FireServer("ReturnToHub")
	returnBtn.Visible = false
	welcomeFrame.Visible = true
	welcomeFrame.BackgroundTransparency = 0.3
	for _, child in welcomeFrame:GetChildren() do
		if child:IsA("TextLabel") then
			(child :: TextLabel).TextTransparency = 0
			(child :: TextLabel).TextStrokeTransparency = 0
		elseif child:IsA("UIStroke") then
			(child :: UIStroke).Transparency = 0.3
		end
	end
end)

-------------------------------------------------
-- 5. Popup générique (Shop / Sell / Gacha)
-------------------------------------------------
local function createPopup(portalId: string): Frame
	local popup: Frame = Instance.new("Frame")
	popup.Name = `Popup_{portalId}`
	popup.Size = UDim2.fromScale(0.45, 0.55)
	popup.Position = UDim2.fromScale(0.275, 0.225)
	popup.BackgroundColor3 = Color3.fromRGB(25, 20, 50)
	popup.BackgroundTransparency = 0.1
	popup.BorderSizePixel = 0
	popup.Visible = false
	popup.Parent = screenGui
	popup:SetAttribute("TargetSize", UDim2.fromScale(0.45, 0.55))

	local popCorner: UICorner = Instance.new("UICorner")
	popCorner.CornerRadius = UDim.new(0, 20)
	popCorner.Parent = popup

	-- Trouver la couleur du portail
	local portalColor: Color3 = Color3.fromRGB(255, 255, 255)
	local portalTitle: string = portalId
	for _, pData in Constants.PORTALS do
		if pData.Id == portalId then
			portalColor = pData.Color
			portalTitle = pData.Name
			break
		end
	end

	local popStroke: UIStroke = Instance.new("UIStroke")
	popStroke.Color = portalColor
	popStroke.Thickness = 3
	popStroke.Parent = popup

	-- Titre
	local title: TextLabel = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.fromScale(1, 0.12)
	title.Position = UDim2.fromScale(0, 0.02)
	title.BackgroundTransparency = 1
	title.Text = portalTitle
	title.TextColor3 = portalColor
	title.TextStrokeTransparency = 0
	title.TextScaled = true
	title.Font = Enum.Font.FredokaOne
	title.Parent = popup

	-- Placeholder contenu
	local content: TextLabel = Instance.new("TextLabel")
	content.Name = "Content"
	content.Size = UDim2.fromScale(0.8, 0.5)
	content.Position = UDim2.fromScale(0.1, 0.2)
	content.BackgroundTransparency = 1
	content.Text = `Bientôt disponible !\n\nCette fonctionnalité arrive prochainement.`
	content.TextColor3 = Color3.fromRGB(180, 180, 200)
	content.TextStrokeTransparency = 0.5
	content.TextScaled = true
	content.TextWrapped = true
	content.Font = Enum.Font.GothamBold
	content.Parent = popup

	-- Bouton fermer
	local closeBtn: TextButton = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.fromScale(0.3, 0.1)
	closeBtn.Position = UDim2.fromScale(0.35, 0.85)
	closeBtn.BackgroundColor3 = portalColor
	closeBtn.BackgroundTransparency = 0.2
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✖ Fermer"
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.TextStrokeTransparency = 0
	closeBtn.TextScaled = true
	closeBtn.Font = Enum.Font.FredokaOne
	closeBtn.Parent = popup

	local closeBtnCorner: UICorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 10)
	closeBtnCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		tweenOut(popup)
	end)

	return popup
end

-- Pré-créer les popups pour chaque portail non-GameMap
local popups: { [string]: Frame } = {}
for _, pData in Constants.PORTALS do
	if pData.Id ~= "GameMap" then
		popups[pData.Id] = createPopup(pData.Id)
	end
end

-------------------------------------------------
-- 6. Écouter les événements du serveur
-------------------------------------------------
portalEnteredEvent.OnClientEvent:Connect(function(portalId: string)
	if portalId == "GameMap" then
		-- Le serveur gère la TP, on affiche le bouton retour
		returnBtn.Visible = true
		welcomeFrame.Visible = false
	else
		-- Ouvrir la popup correspondante
		local popup = popups[portalId]
		if popup then
			tweenIn(popup)
		end
	end
end)

print("[SpawnHUD] ✅ HUD du Spawn Hub initialisé")
