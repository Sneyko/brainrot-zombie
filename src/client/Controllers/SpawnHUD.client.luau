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

-------------------------------------------------
-- 4b. Popup de confirmation Retour au Hub
-------------------------------------------------
local confirmOverlay: Frame = Instance.new("Frame")
confirmOverlay.Name = "ConfirmOverlay"
confirmOverlay.Size = UDim2.fromScale(1, 1)
confirmOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
confirmOverlay.BackgroundTransparency = 0.5
confirmOverlay.BorderSizePixel = 0
confirmOverlay.Visible = false
confirmOverlay.ZIndex = 50
confirmOverlay.Parent = screenGui

local confirmBox: Frame = Instance.new("Frame")
confirmBox.Name = "ConfirmBox"
confirmBox.Size = UDim2.new(0, 380, 0, 200)
confirmBox.Position = UDim2.fromScale(0.5, 0.5)
confirmBox.AnchorPoint = Vector2.new(0.5, 0.5)
confirmBox.BackgroundColor3 = Color3.fromRGB(14, 11, 28)
confirmBox.BackgroundTransparency = 0.05
confirmBox.BorderSizePixel = 0
confirmBox.ZIndex = 51
confirmBox.Parent = confirmOverlay

local confirmCorner: UICorner = Instance.new("UICorner")
confirmCorner.CornerRadius = UDim.new(0, 16)
confirmCorner.Parent = confirmBox

local confirmStroke: UIStroke = Instance.new("UIStroke")
confirmStroke.Color = Color3.fromRGB(255, 80, 60)
confirmStroke.Thickness = 2
confirmStroke.Transparency = 0.3
confirmStroke.Parent = confirmBox

-- Accent rouge en haut
local confirmAccent: Frame = Instance.new("Frame")
confirmAccent.Size = UDim2.new(1, 0, 0, 3)
confirmAccent.BackgroundColor3 = Color3.fromRGB(255, 80, 60)
confirmAccent.BorderSizePixel = 0
confirmAccent.ZIndex = 52
confirmAccent.Parent = confirmBox

-- Icône warning
local warnIcon: TextLabel = Instance.new("TextLabel")
warnIcon.Size = UDim2.new(0, 40, 0, 40)
warnIcon.Position = UDim2.new(0.5, -20, 0, 12)
warnIcon.BackgroundTransparency = 1
warnIcon.Text = "⚠️"
warnIcon.TextScaled = true
warnIcon.Font = Enum.Font.GothamBlack
warnIcon.ZIndex = 52
warnIcon.Parent = confirmBox

-- Titre
local confirmTitle: TextLabel = Instance.new("TextLabel")
confirmTitle.Size = UDim2.new(0.9, 0, 0, 26)
confirmTitle.Position = UDim2.new(0.05, 0, 0, 55)
confirmTitle.BackgroundTransparency = 1
confirmTitle.Text = "QUITTER LE NIVEAU ?"
confirmTitle.TextColor3 = Color3.fromRGB(255, 90, 70)
confirmTitle.TextStrokeTransparency = 0.3
confirmTitle.TextStrokeColor3 = Color3.new(0, 0, 0)
confirmTitle.TextScaled = true
confirmTitle.Font = Enum.Font.GothamBlack
confirmTitle.ZIndex = 52
confirmTitle.Parent = confirmBox

local confirmTitleConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
confirmTitleConstraint.MaxTextSize = 22
confirmTitleConstraint.Parent = confirmTitle

-- Message d'avertissement
local confirmMsg: TextLabel = Instance.new("TextLabel")
confirmMsg.Size = UDim2.new(0.85, 0, 0, 40)
confirmMsg.Position = UDim2.new(0.075, 0, 0, 85)
confirmMsg.BackgroundTransparency = 1
confirmMsg.Text = "Toute la progression du niveau en cours\nsera perdue si tu quittes maintenant !"
confirmMsg.TextColor3 = Color3.fromRGB(200, 200, 220)
confirmMsg.TextStrokeTransparency = 0.5
confirmMsg.TextScaled = true
confirmMsg.TextWrapped = true
confirmMsg.Font = Enum.Font.GothamMedium
confirmMsg.ZIndex = 52
confirmMsg.Parent = confirmBox

local confirmMsgConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
confirmMsgConstraint.MaxTextSize = 15
confirmMsgConstraint.Parent = confirmMsg

-- Boutons : Annuler / Confirmer
local btnRow: Frame = Instance.new("Frame")
btnRow.Size = UDim2.new(0.9, 0, 0, 40)
btnRow.Position = UDim2.new(0.05, 0, 1, -50)
btnRow.BackgroundTransparency = 1
btnRow.ZIndex = 52
btnRow.Parent = confirmBox

local btnLayout: UIListLayout = Instance.new("UIListLayout")
btnLayout.FillDirection = Enum.FillDirection.Horizontal
btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
btnLayout.Padding = UDim.new(0, 16)
btnLayout.Parent = btnRow

-- Bouton Annuler
local cancelBtn: TextButton = Instance.new("TextButton")
cancelBtn.Name = "Cancel"
cancelBtn.Size = UDim2.new(0, 145, 0, 38)
cancelBtn.BackgroundColor3 = Color3.fromRGB(50, 45, 70)
cancelBtn.BackgroundTransparency = 0.15
cancelBtn.BorderSizePixel = 0
cancelBtn.Text = "✖ Annuler"
cancelBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
cancelBtn.TextStrokeTransparency = 0.3
cancelBtn.TextScaled = true
cancelBtn.Font = Enum.Font.GothamBold
cancelBtn.AutoButtonColor = true
cancelBtn.ZIndex = 53
cancelBtn.Parent = btnRow

local cancelCorner: UICorner = Instance.new("UICorner")
cancelCorner.CornerRadius = UDim.new(0, 10)
cancelCorner.Parent = cancelBtn

local cancelConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
cancelConstraint.MaxTextSize = 16
cancelConstraint.Parent = cancelBtn

-- Bouton Confirmer (rouge)
local confirmBtn: TextButton = Instance.new("TextButton")
confirmBtn.Name = "Confirm"
confirmBtn.Size = UDim2.new(0, 145, 0, 38)
confirmBtn.BackgroundColor3 = Color3.fromRGB(200, 45, 35)
confirmBtn.BackgroundTransparency = 0.15
confirmBtn.BorderSizePixel = 0
confirmBtn.Text = "🏠 Quitter"
confirmBtn.TextColor3 = Color3.new(1, 1, 1)
confirmBtn.TextStrokeTransparency = 0.2
confirmBtn.TextScaled = true
confirmBtn.Font = Enum.Font.GothamBlack
confirmBtn.AutoButtonColor = true
confirmBtn.ZIndex = 53
confirmBtn.Parent = btnRow

local confirmBtnCorner: UICorner = Instance.new("UICorner")
confirmBtnCorner.CornerRadius = UDim.new(0, 10)
confirmBtnCorner.Parent = confirmBtn

local confirmBtnConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
confirmBtnConstraint.MaxTextSize = 16
confirmBtnConstraint.Parent = confirmBtn

-- Logique de la popup
local function showConfirm(): ()
	confirmOverlay.Visible = true
	confirmBox.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(confirmBox, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 380, 0, 200),
	}):Play()
end

local function hideConfirm(): ()
	local tw = TweenService:Create(confirmBox, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0),
	})
	tw:Play()
	tw.Completed:Connect(function()
		confirmOverlay.Visible = false
	end)
end

cancelBtn.MouseButton1Click:Connect(function()
	hideConfirm()
end)

-- Clic en dehors de la box → annuler
confirmOverlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local pos = confirmBox.AbsolutePosition
		local sz = confirmBox.AbsoluteSize
		local m = input.Position
		if m.X < pos.X or m.X > pos.X + sz.X or m.Y < pos.Y or m.Y > pos.Y + sz.Y then
			hideConfirm()
		end
	end
end)

confirmBtn.MouseButton1Click:Connect(function()
	hideConfirm()
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

returnBtn.MouseButton1Click:Connect(function()
	showConfirm()
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
		-- Le LevelSelectHUD gère l'affichage de la sélection de niveau
		-- Ne rien faire ici (pas de TP immédiate, pas de bouton retour)
	else
		-- Ouvrir la popup correspondante
		local popup = popups[portalId]
		if popup then
			tweenIn(popup)
		end
	end
end)

-------------------------------------------------
-- 7. Écouter les événements de niveau pour le bouton retour
-------------------------------------------------
local stateChangedEvent: RemoteEvent = eventsFolder:WaitForChild("StateChanged") :: RemoteEvent

stateChangedEvent.OnClientEvent:Connect(function(eventType: unknown, data: unknown): ()
	local eType: string = if typeof(eventType) == "string" then eventType else ""

	if eType == "LevelStart" or eType == "LevelSelected" then
		-- Le niveau démarre → afficher le bouton retour, cacher le welcome
		returnBtn.Visible = true
		welcomeFrame.Visible = false
	elseif eType == "ReturnToMenu" or eType == "GameOver" or eType == "LevelComplete" then
		-- Retour au hub → cacher le bouton retour, ré-afficher welcome
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
	end
end)

print("[SpawnHUD] ✅ HUD du Spawn Hub initialisé")
