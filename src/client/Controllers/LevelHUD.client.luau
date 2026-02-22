--!strict

--[[
	LevelHUD (LocalScript)
	Barre unifiée en haut de l'écran pendant le gameplay :
	  ┌───────────────────────────────────────────────┐
	  │ [NIV.X]  🧠 19   ███████░░░   ❤️ 20  [V X/X] │
	  │          ═══════ barre progression ═══════     │
	  └───────────────────────────────────────────────┘
	+ Bannières de transition (début vague, victoire, défaite…)
	Remplace l'ancien DiceHUD (BrainCoin / HP) + l'ancien LevelHUD séparé.
	Accessible depuis : StarterPlayerScripts.Client.Controllers.LevelHUD
]]

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local GameStore = require(script.Parent.Parent:WaitForChild("State"):WaitForChild("GameStore"))

-- Player
local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui

-- Palette
local BG_DARK       = Color3.fromRGB(8, 6, 18)
local BG_MEDIUM     = Color3.fromRGB(16, 13, 32)
local ACCENT        = Color3.fromRGB(0, 180, 255)
local ACCENT_GLOW   = Color3.fromRGB(60, 220, 255)
local COIN_COLOR    = Color3.fromRGB(255, 210, 40)
local HP_COLOR      = Color3.fromRGB(255, 65, 65)
local HP_WARN       = Color3.fromRGB(255, 120, 30)
local HP_CRIT       = Color3.fromRGB(255, 30, 30)
local WAVE_COLOR    = Color3.fromRGB(255, 200, 60)
local SUCCESS_COLOR = Color3.fromRGB(60, 230, 120)
local DANGER_COLOR  = Color3.fromRGB(255, 55, 55)
local GOLD_COLOR    = Color3.fromRGB(255, 215, 0)
local TEXT_WHITE    = Color3.fromRGB(240, 240, 250)
local TEXT_DIM      = Color3.fromRGB(150, 150, 170)

-------------------------------------------------
-- ScreenGui
-------------------------------------------------
local screenGui: ScreenGui = Instance.new("ScreenGui")
screenGui.Name = "LevelHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 10
screenGui.Parent = playerGui

-------------------------------------------------
-- Barre principale (collée au bord haut)
-------------------------------------------------
local mainBar: Frame = Instance.new("Frame")
mainBar.Name = "MainBar"
mainBar.Size = UDim2.new(0, 540, 0, 46)
mainBar.Position = UDim2.fromScale(0.5, 0)
mainBar.AnchorPoint = Vector2.new(0.5, 0)
mainBar.BackgroundColor3 = BG_DARK
mainBar.BackgroundTransparency = 0.06
mainBar.BorderSizePixel = 0
mainBar.Visible = false
mainBar.ClipsDescendants = false
mainBar.Parent = screenGui

-- Coins arrondis seulement en bas (technique : coin plein + masques carrés en haut)
local mainBarCorner: UICorner = Instance.new("UICorner")
mainBarCorner.CornerRadius = UDim.new(0, 14)
mainBarCorner.Parent = mainBar

-- Bandeau fin tout en haut (masque les coins arrondis du haut visuellement)
local topMask: Frame = Instance.new("Frame")
topMask.Name = "TopMask"
topMask.Size = UDim2.new(1, 0, 0, 14)
topMask.Position = UDim2.new(0, 0, 0, 0)
topMask.BackgroundColor3 = BG_DARK
topMask.BackgroundTransparency = 0.06
topMask.BorderSizePixel = 0
topMask.ZIndex = 0
topMask.Parent = mainBar

-- Ligne accent en bas de la barre
local bottomLine: Frame = Instance.new("Frame")
bottomLine.Name = "BottomLine"
bottomLine.Size = UDim2.new(0.5, 0, 0, 2)
bottomLine.Position = UDim2.new(0.25, 0, 1, -1)
bottomLine.BackgroundColor3 = ACCENT
bottomLine.BackgroundTransparency = 0.4
bottomLine.BorderSizePixel = 0
bottomLine.Parent = mainBar

local bottomLineCorner: UICorner = Instance.new("UICorner")
bottomLineCorner.CornerRadius = UDim.new(0.5, 0)
bottomLineCorner.Parent = bottomLine

-------------------------------------------------
-- Helper : badge compact
-------------------------------------------------
local function createBadge(name: string, parent: Frame, text: string, accentColor: Color3, posX: UDim2): { Frame: Frame, Label: TextLabel, Accent: Frame, Stroke: UIStroke }
	local badge: Frame = Instance.new("Frame")
	badge.Name = name
	badge.Size = UDim2.new(0, 105, 0, 30)
	badge.Position = posX
	badge.BackgroundColor3 = BG_MEDIUM
	badge.BackgroundTransparency = 0.1
	badge.BorderSizePixel = 0
	badge.Parent = parent

	local corner: UICorner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = badge

	local stroke: UIStroke = Instance.new("UIStroke")
	stroke.Name = "Stroke"
	stroke.Color = accentColor
	stroke.Thickness = 1.5
	stroke.Transparency = 0.45
	stroke.Parent = badge

	-- Accent bar à gauche
	local accent: Frame = Instance.new("Frame")
	accent.Name = "Accent"
	accent.Size = UDim2.new(0, 3, 0.55, 0)
	accent.Position = UDim2.new(0, 5, 0.225, 0)
	accent.BackgroundColor3 = accentColor
	accent.BorderSizePixel = 0
	accent.Parent = badge

	local accentCorner: UICorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0.5, 0)
	accentCorner.Parent = accent

	local label: TextLabel = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -16, 1, 0)
	label.Position = UDim2.new(0, 14, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = accentColor
	label.TextStrokeTransparency = 0.5
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = badge

	local textConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
	textConstraint.MaxTextSize = 15
	textConstraint.Parent = label

	return { Frame = badge, Label = label, Accent = accent, Stroke = stroke }
end

-- Badge NIV (gauche)
local levelBadge = createBadge("LevelBadge", mainBar, "NIV. 1", ACCENT, UDim2.new(0, 8, 0.5, -15))

-- Badge VAGUE (droite)
local waveBadge = createBadge("WaveBadge", mainBar, "VAGUE 0/0", WAVE_COLOR, UDim2.new(1, -113, 0.5, -15))

-------------------------------------------------
-- Zone centrale : BrainCoin + HP
-------------------------------------------------
local centerArea: Frame = Instance.new("Frame")
centerArea.Name = "CenterArea"
centerArea.Size = UDim2.new(1, -240, 0, 30)
centerArea.Position = UDim2.new(0, 120, 0.5, -15)
centerArea.BackgroundTransparency = 1
centerArea.Parent = mainBar

local centerLayout: UIListLayout = Instance.new("UIListLayout")
centerLayout.FillDirection = Enum.FillDirection.Horizontal
centerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
centerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
centerLayout.Padding = UDim.new(0, 16)
centerLayout.Parent = centerArea

-- ═══ BrainCoin ═══
local coinFrame: Frame = Instance.new("Frame")
coinFrame.Name = "CoinFrame"
coinFrame.Size = UDim2.new(0, 100, 0, 28)
coinFrame.BackgroundColor3 = Color3.fromRGB(35, 28, 12)
coinFrame.BackgroundTransparency = 0.3
coinFrame.BorderSizePixel = 0
coinFrame.Parent = centerArea

local coinCorner: UICorner = Instance.new("UICorner")
coinCorner.CornerRadius = UDim.new(0, 7)
coinCorner.Parent = coinFrame

local coinIcon: ImageLabel = Instance.new("ImageLabel")
coinIcon.Name = "Icon"
coinIcon.Size = UDim2.new(0, 22, 0, 22)
coinIcon.Position = UDim2.new(0, 5, 0.5, -11)
coinIcon.BackgroundTransparency = 1
coinIcon.Image = "rbxassetid://121334825729026"
coinIcon.ScaleType = Enum.ScaleType.Fit
coinIcon.Parent = coinFrame

local coinLabel: TextLabel = Instance.new("TextLabel")
coinLabel.Name = "CoinLabel"
coinLabel.Size = UDim2.new(1, -32, 1, 0)
coinLabel.Position = UDim2.new(0, 30, 0, 0)
coinLabel.BackgroundTransparency = 1
coinLabel.Text = "0"
coinLabel.TextColor3 = COIN_COLOR
coinLabel.TextStrokeTransparency = 0.3
coinLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
coinLabel.TextScaled = true
coinLabel.Font = Enum.Font.GothamBlack
coinLabel.TextXAlignment = Enum.TextXAlignment.Left
coinLabel.Parent = coinFrame

local coinTextConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
coinTextConstraint.MaxTextSize = 18
coinTextConstraint.Parent = coinLabel

-- ═══ HP ═══
local hpFrame: Frame = Instance.new("Frame")
hpFrame.Name = "HPFrame"
hpFrame.Size = UDim2.new(0, 100, 0, 28)
hpFrame.BackgroundColor3 = Color3.fromRGB(35, 12, 12)
hpFrame.BackgroundTransparency = 0.3
hpFrame.BorderSizePixel = 0
hpFrame.Parent = centerArea

local hpCorner: UICorner = Instance.new("UICorner")
hpCorner.CornerRadius = UDim.new(0, 7)
hpCorner.Parent = hpFrame

local hpEmoji: TextLabel = Instance.new("TextLabel")
hpEmoji.Name = "Emoji"
hpEmoji.Size = UDim2.new(0, 22, 1, 0)
hpEmoji.Position = UDim2.new(0, 4, 0, 0)
hpEmoji.BackgroundTransparency = 1
hpEmoji.Text = "❤️"
hpEmoji.TextScaled = true
hpEmoji.Font = Enum.Font.GothamBlack
hpEmoji.Parent = hpFrame

local hpEmojiConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
hpEmojiConstraint.MaxTextSize = 16
hpEmojiConstraint.Parent = hpEmoji

local hpLabel: TextLabel = Instance.new("TextLabel")
hpLabel.Name = "HPLabel"
hpLabel.Size = UDim2.new(1, -32, 1, 0)
hpLabel.Position = UDim2.new(0, 30, 0, 0)
hpLabel.BackgroundTransparency = 1
hpLabel.Text = "20"
hpLabel.TextColor3 = HP_COLOR
hpLabel.TextStrokeTransparency = 0.3
hpLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
hpLabel.TextScaled = true
hpLabel.Font = Enum.Font.GothamBlack
hpLabel.TextXAlignment = Enum.TextXAlignment.Left
hpLabel.Parent = hpFrame

local hpTextConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
hpTextConstraint.MaxTextSize = 18
hpTextConstraint.Parent = hpLabel

-------------------------------------------------
-- Barre de progression fine (sous la barre)
-------------------------------------------------
local progressBg: Frame = Instance.new("Frame")
progressBg.Name = "ProgressBg"
progressBg.Size = UDim2.new(0.8, 0, 0, 4)
progressBg.Position = UDim2.new(0.1, 0, 1, -3)
progressBg.BackgroundColor3 = Color3.fromRGB(25, 20, 45)
progressBg.BackgroundTransparency = 0.15
progressBg.BorderSizePixel = 0
progressBg.Parent = mainBar

local progressBgCorner: UICorner = Instance.new("UICorner")
progressBgCorner.CornerRadius = UDim.new(0.5, 0)
progressBgCorner.Parent = progressBg

local progressFill: Frame = Instance.new("Frame")
progressFill.Name = "Fill"
progressFill.Size = UDim2.fromScale(0, 1)
progressFill.BackgroundColor3 = ACCENT
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBg

local progressFillCorner: UICorner = Instance.new("UICorner")
progressFillCorner.CornerRadius = UDim.new(0.5, 0)
progressFillCorner.Parent = progressFill

-- Lueur
local progressGlow: Frame = Instance.new("Frame")
progressGlow.Name = "Glow"
progressGlow.Size = UDim2.fromScale(1, 1)
progressGlow.BackgroundColor3 = Color3.new(1, 1, 1)
progressGlow.BackgroundTransparency = 0.7
progressGlow.BorderSizePixel = 0
progressGlow.Parent = progressFill

local progressGlowCorner: UICorner = Instance.new("UICorner")
progressGlowCorner.CornerRadius = UDim.new(0.5, 0)
progressGlowCorner.Parent = progressGlow

local glowGradient: UIGradient = Instance.new("UIGradient")
glowGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.4, 0.5),
	NumberSequenceKeypoint.new(0.6, 0.5),
	NumberSequenceKeypoint.new(1, 1),
})
glowGradient.Parent = progressGlow

-------------------------------------------------
-- Bannière de transition (centre écran)
-------------------------------------------------
local bannerFrame: Frame = Instance.new("Frame")
bannerFrame.Name = "BannerFrame"
bannerFrame.Size = UDim2.new(0, 500, 0, 110)
bannerFrame.Position = UDim2.fromScale(0.5, 0.4)
bannerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
bannerFrame.BackgroundColor3 = BG_DARK
bannerFrame.BackgroundTransparency = 0.08
bannerFrame.BorderSizePixel = 0
bannerFrame.Visible = false
bannerFrame.ClipsDescendants = true
bannerFrame.Parent = screenGui

local bannerCorner: UICorner = Instance.new("UICorner")
bannerCorner.CornerRadius = UDim.new(0, 16)
bannerCorner.Parent = bannerFrame

local bannerStroke: UIStroke = Instance.new("UIStroke")
bannerStroke.Color = ACCENT
bannerStroke.Thickness = 2
bannerStroke.Transparency = 0.3
bannerStroke.Parent = bannerFrame

local bannerTopAccent: Frame = Instance.new("Frame")
bannerTopAccent.Name = "TopAccent"
bannerTopAccent.Size = UDim2.new(1, 0, 0, 3)
bannerTopAccent.BackgroundColor3 = ACCENT
bannerTopAccent.BorderSizePixel = 0
bannerTopAccent.Parent = bannerFrame

local bannerGradient: UIGradient = Instance.new("UIGradient")
bannerGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 15, 50)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 8, 25)),
})
bannerGradient.Rotation = 90
bannerGradient.Parent = bannerFrame

local bannerTitle: TextLabel = Instance.new("TextLabel")
bannerTitle.Name = "Title"
bannerTitle.Size = UDim2.new(0.9, 0, 0, 40)
bannerTitle.Position = UDim2.new(0.05, 0, 0, 15)
bannerTitle.BackgroundTransparency = 1
bannerTitle.Text = ""
bannerTitle.TextColor3 = ACCENT_GLOW
bannerTitle.TextStrokeTransparency = 0.3
bannerTitle.TextStrokeColor3 = Color3.new(0, 0, 0)
bannerTitle.TextScaled = true
bannerTitle.Font = Enum.Font.GothamBlack
bannerTitle.Parent = bannerFrame

local bannerTitleConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
bannerTitleConstraint.MaxTextSize = 32
bannerTitleConstraint.Parent = bannerTitle

local bannerSub: TextLabel = Instance.new("TextLabel")
bannerSub.Name = "Subtitle"
bannerSub.Size = UDim2.new(0.85, 0, 0, 26)
bannerSub.Position = UDim2.new(0.075, 0, 0, 62)
bannerSub.BackgroundTransparency = 1
bannerSub.Text = ""
bannerSub.TextColor3 = TEXT_DIM
bannerSub.TextStrokeTransparency = 0.5
bannerSub.TextScaled = true
bannerSub.Font = Enum.Font.GothamMedium
bannerSub.Parent = bannerFrame

local bannerSubConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
bannerSubConstraint.MaxTextSize = 18
bannerSubConstraint.Parent = bannerSub

local bannerDivider: Frame = Instance.new("Frame")
bannerDivider.Name = "Divider"
bannerDivider.Size = UDim2.new(0.3, 0, 0, 1)
bannerDivider.Position = UDim2.new(0.35, 0, 0, 58)
bannerDivider.BackgroundColor3 = ACCENT
bannerDivider.BackgroundTransparency = 0.5
bannerDivider.BorderSizePixel = 0
bannerDivider.Parent = bannerFrame

-------------------------------------------------
-- Fonctions utilitaires
-------------------------------------------------

local function showBanner(title: string, subtitle: string, color: Color3, duration: number): ()
	bannerTitle.Text = title
	bannerTitle.TextColor3 = color
	bannerSub.Text = subtitle
	bannerStroke.Color = color
	bannerTopAccent.BackgroundColor3 = color
	bannerDivider.BackgroundColor3 = color

	bannerFrame.Position = UDim2.fromScale(0.5, 0.3)
	bannerFrame.BackgroundTransparency = 0.5
	bannerFrame.Visible = true

	TweenService:Create(bannerFrame, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.4),
		BackgroundTransparency = 0.08,
	}):Play()

	task.delay(duration, function()
		local tweenOut = TweenService:Create(bannerFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
			Position = UDim2.fromScale(0.5, 0.3),
			BackgroundTransparency = 1,
		})
		tweenOut:Play()
		tweenOut.Completed:Connect(function()
			bannerFrame.Visible = false
		end)
	end)
end

local function setProgressColor(color: Color3): ()
	TweenService:Create(progressFill, TweenInfo.new(0.4), { BackgroundColor3 = color }):Play()
end

local function setBadgeTheme(lvColor: Color3, wvColor: Color3): ()
	TweenService:Create(levelBadge.Stroke, TweenInfo.new(0.4), { Color = lvColor }):Play()
	TweenService:Create(waveBadge.Stroke, TweenInfo.new(0.4), { Color = wvColor }):Play()
	levelBadge.Accent.BackgroundColor3 = lvColor
	waveBadge.Accent.BackgroundColor3 = wvColor
	levelBadge.Label.TextColor3 = lvColor
	waveBadge.Label.TextColor3 = wvColor
end

local function resetTheme(): ()
	setBadgeTheme(ACCENT, WAVE_COLOR)
	setProgressColor(ACCENT)
	bottomLine.BackgroundColor3 = ACCENT
end

-------------------------------------------------
-- Mise à jour des données affichées
-------------------------------------------------

local function updateTopBar(): ()
	local lv: number = GameStore.CurrentLevel
	local wv: number = GameStore.CurrentWave
	local tw: number = GameStore.TotalWaves

	levelBadge.Label.Text = `NIV. {lv}`
	waveBadge.Label.Text = `VAGUE {wv}/{tw}`

	local ratio: number = if tw > 0 then math.clamp(wv / tw, 0, 1) else 0
	TweenService:Create(progressFill, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
		Size = UDim2.fromScale(ratio, 1),
	}):Play()
end

local function updateCoinHP(): ()
	local bc: number = GameStore.BrainCoin
	local hp: number = GameStore.BaseHP

	coinLabel.Text = tostring(bc)
	hpLabel.Text = tostring(hp)

	-- Couleur HP dynamique
	if hp <= 5 then
		hpLabel.TextColor3 = HP_CRIT
		hpFrame.BackgroundColor3 = Color3.fromRGB(55, 10, 10)
	elseif hp <= 10 then
		hpLabel.TextColor3 = HP_WARN
		hpFrame.BackgroundColor3 = Color3.fromRGB(45, 20, 10)
	else
		hpLabel.TextColor3 = HP_COLOR
		hpFrame.BackgroundColor3 = Color3.fromRGB(35, 12, 12)
	end

	-- Flash subtil sur la frame coin
	TweenService:Create(coinFrame, TweenInfo.new(0.1), {
		BackgroundColor3 = Color3.fromRGB(55, 45, 18),
	}):Play()
	task.delay(0.15, function()
		TweenService:Create(coinFrame, TweenInfo.new(0.3), {
			BackgroundColor3 = Color3.fromRGB(35, 28, 12),
		}):Play()
	end)
end

-------------------------------------------------
-- Connexions GameStore
-------------------------------------------------

GameStore.BrainCoinChanged:Connect(function()
	updateCoinHP()
	updateTopBar()
end)

GameStore.LevelChanged:Connect(function(eventType: string, data: { [string]: any })
	if eventType == "LevelStart" then
		local levelNum: number = data.Level or 0
		local name: string = data.Name or ""
		local theme: string = data.Theme or ""
		local totalWaves: number = data.TotalWaves or 0
		local totalLevels: number = data.TotalLevels or 10

		showBanner(
			`{theme}  NIVEAU {levelNum} — {name}`,
			`{totalWaves} vagues  ·  Niveau {levelNum}/{totalLevels}`,
			ACCENT_GLOW,
			4
		)

	elseif eventType == "WaveStart" then
		local wave: number = data.Wave or 0
		local totalWaves: number = data.TotalWaves or 0
		local isBoss: boolean = data.IsBossWave or false
		local zombieCount: number = data.ZombieCount or 0

		if isBoss then
			showBanner(
				`VAGUE BOSS  {wave}/{totalWaves}`,
				`{zombieCount} zombie(s) + BOSS incoming !`,
				DANGER_COLOR,
				3
			)
			setBadgeTheme(DANGER_COLOR, DANGER_COLOR)
			setProgressColor(DANGER_COLOR)
			bottomLine.BackgroundColor3 = DANGER_COLOR
			task.delay(3, resetTheme)
		elseif wave > 1 then
			showBanner(
				`VAGUE {wave}/{totalWaves}`,
				`{zombieCount} zombie(s) en approche`,
				WAVE_COLOR,
				2.5
			)
		end

	elseif eventType == "WaveComplete" then
		local wave: number = data.Wave or 0
		local totalWaves: number = data.TotalWaves or 0

		if wave < totalWaves then
			showBanner(
				`VAGUE {wave} TERMINÉE`,
				"Préparez la défense...",
				SUCCESS_COLOR,
				2
			)
		end

	elseif eventType == "LevelComplete" then
		local level: number = data.Level or 0
		local totalLevels: number = data.TotalLevels or 10

		showBanner(
			`NIVEAU {level} TERMINÉ !`,
			"Retour au menu...",
			SUCCESS_COLOR,
			5
		)
		setProgressColor(SUCCESS_COLOR)
		bottomLine.BackgroundColor3 = SUCCESS_COLOR
		task.delay(2, resetTheme)

	elseif eventType == "GameOver" then
		local level: number = data.Level or 0
		local wave: number = data.Wave or 0

		showBanner(
			"DÉFAITE",
			`Niveau {level}, vague {wave}`,
			DANGER_COLOR,
			6
		)
		setBadgeTheme(DANGER_COLOR, DANGER_COLOR)
		bottomLine.BackgroundColor3 = DANGER_COLOR

	elseif eventType == "ReturnToMenu" then
		mainBar.Visible = false
		resetTheme()

	elseif eventType == "LevelSelected" then
		mainBar.Visible = true
		progressFill.Size = UDim2.fromScale(0, 1)
		resetTheme()
		updateCoinHP()

	elseif eventType == "GameWon" then
		local totalLevels: number = data.TotalLevels or 10
		showBanner(
			"VICTOIRE TOTALE !",
			`{totalLevels} niveaux terminés — Bravo !`,
			GOLD_COLOR,
			10
		)
		setBadgeTheme(GOLD_COLOR, GOLD_COLOR)
		setProgressColor(GOLD_COLOR)
		bottomLine.BackgroundColor3 = GOLD_COLOR
	end
end)

-- Init — caché au démarrage (lobby)
mainBar.Visible = false
updateTopBar()

print("[LevelHUD] ✅ Barre unifiée initialisée")
