-- language: Luau, file: modules/core.lua, target: Roblox (San Diego / Mobile & PC)
local ctx = {}
-- language: Luau, file: ocel_hub.lua, target: Roblox (San Diego / Mobile & PC)
-- Ocel-Hub: Monochrome Mobile UI, Aimbot, Silent Aim, San Diego ESP (Players & Border Bots), Multi-Style Chams, World Visuals, Crosshair
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer

if getgenv and getgenv().OcelHub then pcall(function() getgenv().OcelHub:Destroy() end) end

local CFG = {
	Menu = { Open = true, ToggleKey = Enum.KeyCode.F3, ShowTogglePill = true, UIScale = 1.0 },
	Aim = {
		Enabled = false, Activation = "Button (Toggle)", ShowAimButton = true, Method = "Camera",
		TargetPart = "Head", Priority = "Crosshair", FOV = 130, ShowFOV = true, FOVFilled = false,
		FOVTransparency = 0.75, FOVThickness = 1.5, FOVColor = Color3.new(1, 1, 1),
		Smoothness = 0.35, Prediction = false, PredictionScale = 0.12, WallCheck = true,
		TeamCheck = false, AliveCheck = true, IgnoreHearseHidden = true, IgnoreModeratorHidden = false,
		MaxDistance = 800, StickyTarget = true, ShowSnapline = true,
	},
	ESP = {
		Enabled = true, MaxDistance = 1500, TeamCheck = false, IgnoreHearseHidden = true, IgnoreModeratorHidden = false,
		ShowBorderBots = true, BotFilter = "Border + Jewelry", ColorBorderBot = Color3.fromRGB(255, 140, 50), ColorJewelryBot = Color3.fromRGB(255, 70, 175),
		ShowBox = true, BoxOutline = true, BoxThickness = 1, ShowSkeleton = true, SkeletonOutline = true,
		SkeletonThickness = 1.5, ShowHeadCircle = true, ShowHealthBar = true, ShowName = true,
		ShowDistance = true, ShowTeamTag = true, ShowWanted = true, ShowTracers = false, TracerOrigin = "Bottom",
		TextSize = 13, ColorUseTeam = true, ColorWantedOverride = true,
		ColorDefault = Color3.new(1, 1, 1), ColorWanted = Color3.fromRGB(255, 70, 70),
		ColorDetained = Color3.fromRGB(255, 195, 60), ColorOutline = Color3.new(0, 0, 0),
	},
	Chams = {
		FlowSpeed = 1.6, StripTextures = true, WireframeThickness = 1.2,
		Players = { Enabled = false, Mode = "Outline + Fill", Style = "Glossy Flow", Color = Color3.fromRGB(0, 220, 255), OutlineColor = Color3.new(1, 1, 1), FillTransparency = 0.25, OutlineTransparency = 0, AlwaysOnTop = true, TeamCheck = false, UseTeamColor = false },
		Self = { Enabled = false, Mode = "Fill", Style = "Water Flow", Color = Color3.fromRGB(170, 85, 255), OutlineColor = Color3.new(1, 1, 1), FillTransparency = 0.25, OutlineTransparency = 0, AlwaysOnTop = false },
		Arms = { Enabled = false, Mode = "Outline + Fill", Style = "Glossy Flow", Color = Color3.fromRGB(0, 220, 255), OutlineColor = Color3.new(1, 1, 1), FillTransparency = 0.2, OutlineTransparency = 0, AlwaysOnTop = false },
		Weapon = { Enabled = false, Mode = "Outline + Fill", Style = "Wireframe", Color = Color3.fromRGB(255, 190, 65), OutlineColor = Color3.new(1, 1, 1), FillTransparency = 0.25, OutlineTransparency = 0, AlwaysOnTop = false },
		Car = { Enabled = false, Mode = "Outline + Fill", Style = "Glossy Flow", Color = Color3.fromRGB(0, 220, 255), OutlineColor = Color3.new(1, 1, 1), FillTransparency = 0.25, OutlineTransparency = 0, AlwaysOnTop = false },
	},
	Crosshair = {
		Enabled = false, Style = "Cross", Position = "Auto",
		Size = 10, Gap = 4, Thickness = 2, Outline = true, CenterDot = true,
		Spin = false, SpinSpeed = 2.0, Rainbow = false, HideGameReticle = false,
		Color = Color3.new(1, 1, 1), OutlineColor = Color3.new(0, 0, 0),
	},
	Silent = {
		Enabled = false, Method = "Hybrid", TargetPart = "Head", Priority = "Crosshair",
		FOV = 140, ShowFOV = true, FOVColor = Color3.fromRGB(255, 85, 85),
		HitChance = 100, MaxDistance = 800, WallCheck = true, MagicBullet = false,
		TeamCheck = false, IgnoreHearseHidden = true, IgnoreModeratorHidden = false,
		TargetNPCs = false, BotFilter = "Border + Jewelry",
		Prediction = true, PredictionScale = 0.12, ShowSnapline = true, ShowTarget = true,
	},
	Tracers = {
		Enabled = false, Duration = 1.0, Thickness = 0.14,
		Fade = true, Rainbow = false, Color = Color3.fromRGB(0, 220, 255),
	},
	Camera = {
		OverrideFOV = false, FOV = 90,
	},
	Visuals = {
		Enabled = false,
		Preset = "Custom",
		FogOverride = false,
		NoFog = false,
		FogColor = Color3.fromRGB(120, 150, 210),
		FogDecayColor = Color3.fromRGB(85, 110, 175),
		FogStart = 0,
		FogEnd = 450,
		AtmosphereDensity = 0.35,
		AtmosphereHaze = 2.0,
		AtmosphereGlare = 0.2,
		WorldColorEnabled = false,
		AmbientColor = Color3.fromRGB(95, 105, 130),
		OutdoorAmbientColor = Color3.fromRGB(130, 145, 175),
		ColorShiftTop = Color3.fromRGB(255, 235, 210),
		ColorShiftBottom = Color3.fromRGB(80, 95, 125),
		ColorTintEnabled = false,
		WorldTintColor = Color3.fromRGB(255, 225, 240),
		Saturation = 0.15,
		Contrast = 0.05,
		CCBrightness = 0.0,
		Fullbright = false,
		TimeOverride = false,
		ClockTime = 14.0,
		BrightnessOverride = false,
		Brightness = 2.5,
		Exposure = 0.0,
		DisableShadows = false,
		SkyMode = "Default",
		HideClouds = false,
		WaterOverride = false,
		WaterColor = Color3.fromRGB(45, 140, 210),
		DisableBlur = false,
		BloomOverride = false,
		BloomIntensity = 0.6,
		BloomSize = 24,
		BloomThreshold = 1.1,
		RainbowWorld = false,
		RainbowSpeed = 0.5,
	},
}

local S = { Destroyed = false, Conns = {}, AimTog = false, AimHold = false, FireHold = false, Locked = nil, AimAct = false, AimPos = nil, AimPart = nil, SilentTgt = nil, SilentHooked = false, SilentHookMsg = "Pending", Tab = "AIM", ChamTab = "Players", Scroll = nil }
local function tc(c) if c then table.insert(S.Conns, c) end return c end
local function drw(k, p)
	if not Drawing or not Drawing.new then local st = { Visible = false }; function st:Remove() end; return st end
	local ok, o = pcall(Drawing.new, k)
	if not ok or not o then local st = { Visible = false }; function st:Remove() end; return st end
	for a, b in pairs(p) do pcall(function() o[a] = b end) end
	return o
end
local function gui_root()
	if typeof(gethui) == "function" then local ok, h = pcall(gethui); if ok and h then return h end end
	if pcall(function() return CoreGui.Name end) then return CoreGui end
	return LP:WaitForChild("PlayerGui")
end

-- San Diego / Rig Helpers
local R15 = { "Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot" }
local R6 = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }
local ARMS = { ["Left Arm"] = true, ["Right Arm"] = true, LeftUpperArm = true, LeftLowerArm = true, LeftHand = true, RightUpperArm = true, RightLowerArm = true, RightHand = true }

local function alive(ch, hum)
	return ch and ch.Parent and hum and hum.Parent and hum.Health > 0 and hum:GetAttribute("Dead") ~= true and hum:GetState() ~= Enum.HumanoidStateType.Dead
end
local function wanted_stars(pl)
	local r = pl:GetAttribute("WantedLevel")
	if typeof(r) ~= "number" or r <= 0 then return 0 end
	return math.clamp(math.ceil(math.clamp(math.round(r), 0, 1000) / 200), 0, 5)
end
local function esp_col(pl, ch)
	if CFG.ESP.ColorWantedOverride and wanted_stars(pl) > 0 then return CFG.ESP.ColorWanted end
	if ch:GetAttribute("IsDetained") == true or ch:GetAttribute("DetainedByUserId") ~= nil then return CFG.ESP.ColorDetained end
	if CFG.ESP.ColorUseTeam and pl.Team then return pl.Team.TeamColor.Color end
	return CFG.ESP.ColorDefault
end
local function ignored(pl, tc_on, hc_on, mc_on)
	if tc_on and LP.Team ~= nil and pl.Team == LP.Team then return true end
	if hc_on and pl:GetAttribute("HearseCoffinHidden") == true then return true end
	if mc_on and (pl:GetAttribute("ModeratorHidden") == true or pl:GetAttribute("ModeratorInvisible") == true) then return true end
	return false
end

-- Monochrome Mobile UI
local TH = {
	Bg = Color3.fromRGB(10, 10, 12), Panel = Color3.fromRGB(16, 16, 19), Card = Color3.fromRGB(22, 22, 26),
	Border = Color3.fromRGB(54, 54, 62), BorderHi = Color3.fromRGB(235, 235, 240),
	Accent = Color3.new(1, 1, 1), AccentTxt = Color3.fromRGB(10, 10, 12),
	Txt = Color3.fromRGB(248, 248, 252), Muted = Color3.fromRGB(145, 145, 155), Off = Color3.fromRGB(36, 36, 42),
}
local PRESETS = {
	Color3.new(1, 1, 1), Color3.fromRGB(0, 220, 255), Color3.fromRGB(55, 125, 255), Color3.fromRGB(170, 85, 255), Color3.fromRGB(255, 75, 185),
	Color3.fromRGB(255, 60, 65), Color3.fromRGB(255, 145, 45), Color3.fromRGB(255, 215, 55), Color3.fromRGB(70, 245, 125), Color3.fromRGB(22, 22, 28),
}
local MODES = { "Outline", "Fill", "Outline + Fill", "Hitboxes", "Boxes" }
local STYLES = { "Flat", "Wireframe", "Glossy Flow", "Water Flow", "ForceField", "Glass", "Neon Pulse", "Rainbow Flow" }
local UI = { Gui = nil, Main = nil, Scale = nil, TPill = nil, APill = nil, AStroke = nil, ALbl = nil, Tabs = {}, Pages = {}, CBox = {}, CBtns = {} }

local function ui(cls, pr, par) local o = Instance.new(cls); for k, v in pairs(pr) do o[k] = v end; if par then o.Parent = par end; return o end
local function rc(p, r) return ui("UICorner", { CornerRadius = UDim.new(0, r) }, p) end
local function st(p, c, t, tr) return ui("UIStroke", { Color = c or TH.Border, Thickness = t or 1, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p) end
local function ptr(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function mov(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end

local function draggable(hdl, tgt, on_tap, on_down, on_up)
	local drag, moved, sp, fp, ai = false, false, nil, nil, nil
	tc(hdl.InputBegan:Connect(function(i)
		if ptr(i) then drag, moved, ai, sp, fp = true, false, i, Vector2.new(i.Position.X, i.Position.Y), tgt.Position; if on_down then on_down() end end
	end))
	tc(UserInputService.InputChanged:Connect(function(i)
		if not drag or not mov(i) or (ai and ai.UserInputType == Enum.UserInputType.Touch and i ~= ai) then return end
		local d = Vector2.new(i.Position.X, i.Position.Y) - sp
		if d.Magnitude > 7 then moved = true end
		if moved then
			local sc = (UI.Scale and UI.Scale.Scale) or 1
			local cam = Workspace.CurrentCamera
			local vp = cam and cam.ViewportSize or Vector2.new(800, 480)
			local abs = tgt.AbsoluteSize
			tgt.Position = UDim2.fromOffset(math.clamp(fp.X.Offset + d.X / sc, 4, math.max(4, (vp.X - abs.X) / sc)), math.clamp(fp.Y.Offset + d.Y / sc, 4, math.max(4, (vp.Y - abs.Y) / sc)))
		end
	end))
	tc(UserInputService.InputEnded:Connect(function(i)
		if drag and ptr(i) and (not ai or i == ai) then drag, ai = false, nil; if on_up then on_up() end; if not moved and on_tap then on_tap() end end
	end))
end

local function hdr_lbl(p, t)
	local h = ui("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 }, p)
	ui("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = string.upper(t), TextSize = 10, TextColor3 = TH.Muted, TextXAlignment = Enum.TextXAlignment.Left }, h)
	ui("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BorderSizePixel = 0, BackgroundColor3 = TH.Border, BackgroundTransparency = 0.35 }, h)
end

local function tog(p, lbl, gv, sv)
	local r = ui("TextButton", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = TH.Card, BorderSizePixel = 0, AutoButtonColor = false, Text = "" }, p)
	rc(r, 6); st(r, TH.Border, 1, 0.45)
	ui("TextLabel", { Size = UDim2.new(1, -64, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, Text = lbl, TextSize = 12, TextColor3 = TH.Txt, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, r)
	local tr = ui("Frame", { Size = UDim2.fromOffset(38, 20), Position = UDim2.new(1, -48, 0.5, -10), BorderSizePixel = 0 }, r); rc(tr, 10)
	local ts = st(tr, TH.Border, 1, 0)
	local kn = ui("Frame", { Size = UDim2.fromOffset(14, 14), BorderSizePixel = 0 }, tr); rc(kn, 7)
	local function ref(inst)
		local s = gv()
		local bg, kbg, pos = s and TH.Accent or TH.Off, s and TH.AccentTxt or TH.Muted, s and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3)
		ts.Color = s and TH.Accent or TH.Border
		if inst then tr.BackgroundColor3, kn.BackgroundColor3, kn.Position = bg, kbg, pos
		else local ti = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out); TweenService:Create(tr, ti, { BackgroundColor3 = bg }):Play(); TweenService:Create(kn, ti, { BackgroundColor3 = kbg, Position = pos }):Play() end
	end
	ref(true)
	r.Activated:Connect(function() sv(not gv()); ref(false) end)
	return function() ref(true) end
end

local function sld(p, lbl, mn, mx, step, suf, gv, sv)
	local c = ui("Frame", { Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = TH.Card, BorderSizePixel = 0 }, p); rc(c, 6); st(c, TH.Border, 1, 0.45)
	ui("TextLabel", { Size = UDim2.new(1, -76, 0, 20), Position = UDim2.fromOffset(10, 4), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, Text = lbl, TextSize = 12, TextColor3 = TH.Txt, TextXAlignment = Enum.TextXAlignment.Left }, c)
	local vl = ui("TextLabel", { Size = UDim2.fromOffset(64, 20), Position = UDim2.new(1, -72, 0, 4), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = TH.Accent, TextXAlignment = Enum.TextXAlignment.Right }, c)
	local hit = ui("TextButton", { Size = UDim2.new(1, -20, 0, 20), Position = UDim2.fromOffset(10, 24), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, c)
	local bar = ui("Frame", { Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, 0.5, -2), BackgroundColor3 = TH.Off, BorderSizePixel = 0 }, hit); rc(bar, 2)
	local fl = ui("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = TH.Accent, BorderSizePixel = 0 }, bar); rc(fl, 2)
	local th = ui("Frame", { Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = TH.Accent, BorderSizePixel = 0 }, bar); rc(th, 6); st(th, TH.Bg, 1.5, 0)
	local function draw(v)
		local n = (v - mn) / math.max(mx - mn, 1e-6)
		fl.Size, th.Position = UDim2.new(n, 0, 1, 0), UDim2.new(n, 0, 0.5, 0)
		vl.Text = step < 1 and string.format("%.2f%s", v, suf or "") or string.format("%d%s", math.round(v), suf or "")
	end
	draw(math.clamp(gv(), mn, mx))
	local drg, ai = false, nil
	local function setx(x)
		local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		local v = math.clamp(math.round((mn + (mx - mn) * a) / step) * step, mn, mx)
		sv(v); draw(v)
	end
	tc(hit.InputBegan:Connect(function(i) if ptr(i) then drg, ai = true, i; if S.Scroll then S.Scroll.ScrollingEnabled = false end; setx(i.Position.X) end end))
	tc(UserInputService.InputChanged:Connect(function(i) if drg and mov(i) and (not ai or ai.UserInputType ~= Enum.UserInputType.Touch or i == ai) then setx(i.Position.X) end end))
	tc(UserInputService.InputEnded:Connect(function(i) if drg and ptr(i) and (not ai or i == ai) then drg, ai = false, nil; if S.Scroll then S.Scroll.ScrollingEnabled = true end end end))
	return function() draw(math.clamp(gv(), mn, mx)) end
end

local function sel(p, lbl, opts, gv, sv)
	local c = ui("Frame", { Size = UDim2.new(1, 0, 0, 34), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = TH.Card, BorderSizePixel = 0, ClipsDescendants = true }, p); rc(c, 6); st(c, TH.Border, 1, 0.45)
	local h = ui("TextButton", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, c)
	ui("TextLabel", { Size = UDim2.new(0.46, 0, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, Text = lbl, TextSize = 12, TextColor3 = TH.Txt, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, h)
	local vl = ui("TextLabel", { Size = UDim2.new(0.5, -24, 1, 0), Position = UDim2.new(0.48, 0, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = TH.Accent, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd }, h)
	local ar = ui("TextLabel", { Size = UDim2.fromOffset(18, 34), Position = UDim2.new(1, -22, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "▾", TextSize = 12, TextColor3 = TH.Muted }, h)
	local ls = ui("Frame", { Size = UDim2.new(1, -12, 0, 0), Position = UDim2.fromOffset(6, 36), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false }, c)
	ui("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, 26), CellPadding = UDim2.fromOffset(6, 5), SortOrder = Enum.SortOrder.LayoutOrder }, ls)
	ui("UIPadding", { PaddingBottom = UDim.new(0, 6) }, ls)
	local btns, exp = {}, false
	local function ref()
		local cur = gv(); vl.Text, ar.Text, ls.Visible = tostring(cur), exp and "▴" or "▾", exp
		for o, b in pairs(btns) do local a = (o == cur); b.BackgroundColor3, b.TextColor3 = a and TH.Accent or TH.Panel, a and TH.AccentTxt or TH.Txt end
	end
	for i, o in ipairs(opts) do
		local b = ui("TextButton", { LayoutOrder = i, BackgroundColor3 = TH.Panel, BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamMedium, Text = o, TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd }, ls)
		rc(b, 4); st(b, TH.Border, 1, 0.5); btns[o] = b
		b.Activated:Connect(function() sv(o); exp = false; ref() end)
	end
	h.Activated:Connect(function() exp = not exp; ref() end)
	ref()
	return ref
end

local function col_eq(a, b)
	return math.abs(a.R - b.R) < 0.015 and math.abs(a.G - b.G) < 0.015 and math.abs(a.B - b.B) < 0.015
end

local function col_row(p, lbl, gc, sc_fn)
	local c = ui("Frame", { Size = UDim2.new(1, 0, 0, 56), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = TH.Card, BorderSizePixel = 0, ClipsDescendants = true }, p); rc(c, 6); st(c, TH.Border, 1, 0.45)
	local top = ui("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1 }, c)
	ui("TextLabel", { Size = UDim2.new(1, -92, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, Text = lbl, TextSize = 12, TextColor3 = TH.Txt, TextXAlignment = Enum.TextXAlignment.Left }, top)
	local hsv_btn = ui("TextButton", { Size = UDim2.fromOffset(36, 16), Position = UDim2.new(1, -74, 0.5, -8), BackgroundColor3 = TH.Panel, BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamBold, Text = "HSV", TextSize = 9, TextColor3 = TH.Muted }, top); rc(hsv_btn, 4); st(hsv_btn, TH.Border, 1, 0.4)
	local pv = ui("TextButton", { Size = UDim2.fromOffset(24, 16), Position = UDim2.new(1, -34, 0.5, -8), BorderSizePixel = 0, Text = "", AutoButtonColor = false }, top); rc(pv, 4); st(pv, TH.Accent, 1, 0.25)

	local row = ui("Frame", { Size = UDim2.new(1, -20, 0, 24), Position = UDim2.fromOffset(10, 27), BackgroundTransparency = 1 }, c)
	ui("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), VerticalAlignment = Enum.VerticalAlignment.Center }, row)

	local hsv_box = ui("Frame", { Size = UDim2.new(1, -20, 0, 74), Position = UDim2.fromOffset(10, 54), BackgroundTransparency = 1, Visible = false }, c)
	local exp = false
	local h0, s0, v0 = gc():ToHSV()
	local hsv = { H = h0, S = s0, V = v0 }
	local sws, bars = {}, {}

	local function mk_bar(idx, name, yoff, grad_cs)
		ui("TextLabel", { Size = UDim2.fromOffset(14, 18), Position = UDim2.fromOffset(0, yoff), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = name, TextSize = 10, TextColor3 = TH.Muted, TextXAlignment = Enum.TextXAlignment.Left }, hsv_box)
		local hit = ui("TextButton", { Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(18, yoff), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, hsv_box)
		local tr = ui("Frame", { Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0.5, -3), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, hit); rc(tr, 3); st(tr, TH.Border, 1, 0.3)
		local gr = ui("UIGradient", { Color = grad_cs }, tr)
		local kn = ui("Frame", { Size = UDim2.fromOffset(10, 12), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = TH.Accent, BorderSizePixel = 0 }, tr); rc(kn, 5); st(kn, TH.Bg, 1.5, 0)
		bars[idx] = { Hit = hit, Tr = tr, Gr = gr, Kn = kn }
	end

	local hue_seq = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
		ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
	})
	mk_bar(1, "H", 2, hue_seq)
	mk_bar(2, "S", 25, ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(hsv.H, 1, 1)))
	mk_bar(3, "V", 48, ColorSequence.new(Color3.new(0, 0, 0), Color3.fromHSV(hsv.H, hsv.S, 1)))

	local function ref(sync_hsv)
		local cur = gc(); pv.BackgroundColor3 = cur
		if sync_hsv then hsv.H, hsv.S, hsv.V = cur:ToHSV() end
		for i, col in ipairs(PRESETS) do
			local eq = col_eq(cur, col)
			sws[i].Color, sws[i].Thickness = eq and TH.Accent or TH.Border, eq and 2 or 1
		end
		bars[1].Kn.Position = UDim2.new(hsv.H, 0, 0.5, 0)
		bars[2].Kn.Position = UDim2.new(hsv.S, 0, 0.5, 0)
		bars[3].Kn.Position = UDim2.new(hsv.V, 0, 0.5, 0)
		bars[2].Gr.Color = ColorSequence.new(Color3.fromHSV(hsv.H, 0, hsv.V), Color3.fromHSV(hsv.H, 1, hsv.V))
		bars[3].Gr.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.fromHSV(hsv.H, hsv.S, 1))
		hsv_box.Visible = exp
		c.Size = UDim2.new(1, 0, 0, exp and 132 or 56)
		hsv_btn.BackgroundColor3 = exp and TH.Accent or TH.Panel
		hsv_btn.TextColor3 = exp and TH.AccentTxt or TH.Muted
	end

	local function bind_bar(idx, key)
		local drg, ai = false, nil
		local function setx(x)
			local tr = bars[idx].Tr
			local a = math.clamp((x - tr.AbsolutePosition.X) / math.max(tr.AbsoluteSize.X, 1), 0, 1)
			hsv[key] = a
			sc_fn(Color3.fromHSV(hsv.H, hsv.S, hsv.V))
			ref(false)
		end
		tc(bars[idx].Hit.InputBegan:Connect(function(i) if ptr(i) then drg, ai = true, i; if S.Scroll then S.Scroll.ScrollingEnabled = false end; setx(i.Position.X) end end))
		tc(UserInputService.InputChanged:Connect(function(i) if drg and mov(i) and (not ai or ai.UserInputType ~= Enum.UserInputType.Touch or i == ai) then setx(i.Position.X) end end))
		tc(UserInputService.InputEnded:Connect(function(i) if drg and ptr(i) and (not ai or i == ai) then drg, ai = false, nil; if S.Scroll then S.Scroll.ScrollingEnabled = true end end end))
	end
	bind_bar(1, "H"); bind_bar(2, "S"); bind_bar(3, "V")

	for i, col in ipairs(PRESETS) do
		local sw = ui("TextButton", { Size = UDim2.fromOffset(20, 17), BackgroundColor3 = col, BorderSizePixel = 0, Text = "", AutoButtonColor = false }, row)
		rc(sw, 4); sws[i] = st(sw, TH.Border, 1, 0)
		sw.Activated:Connect(function() sc_fn(col); ref(true) end)
	end
	local function tog_exp() exp = not exp; ref(true) end
	hsv_btn.Activated:Connect(tog_exp); pv.Activated:Connect(tog_exp)
	ref(true)
	return function() ref(true) end
end

local function act_btn(p, lbl, cb)
	local b = ui("TextButton", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = TH.Card, BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamBold, Text = lbl, TextSize = 12, TextColor3 = TH.Txt }, p)
	rc(b, 6); st(b, TH.BorderHi, 1, 0.55)
	b.Activated:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.08), { BackgroundColor3 = TH.Accent, TextColor3 = TH.AccentTxt }):Play()
		task.delay(0.12, function() if b.Parent then TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = TH.Card, TextColor3 = TH.Txt }):Play() end end)
		cb()
	end)
end


ctx.CollectionService = CollectionService
ctx.Lighting = Lighting
ctx.Players = Players
ctx.RunService = RunService
ctx.UserInputService = UserInputService
ctx.TweenService = TweenService
ctx.Workspace = Workspace
ctx.CoreGui = CoreGui
ctx.LP = LP
ctx.CFG = CFG
ctx.S = S
ctx.tc = tc
ctx.drw = drw
ctx.gui_root = gui_root
ctx.R15 = R15
ctx.R6 = R6
ctx.ARMS = ARMS
ctx.alive = alive
ctx.wanted_stars = wanted_stars
ctx.esp_col = esp_col
ctx.ignored = ignored
ctx.TH = TH
ctx.PRESETS = PRESETS
ctx.MODES = MODES
ctx.STYLES = STYLES
ctx.UI = UI
ctx.ui = ui
ctx.rc = rc
ctx.st = st
ctx.ptr = ptr
ctx.mov = mov
ctx.draggable = draggable
ctx.hdr_lbl = hdr_lbl
ctx.tog = tog
ctx.sld = sld
ctx.sel = sel
ctx.col_eq = col_eq
ctx.col_row = col_row
ctx.act_btn = act_btn
return ctx