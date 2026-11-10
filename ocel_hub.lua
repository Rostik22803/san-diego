-- language: Luau, file: ocel_hub.lua, target: Roblox (San Diego / Mobile & PC)
-- Ocel-Hub: Monochrome Mobile UI, Aimbot, Silent Aim, San Diego ESP (Players & Border Bots), Multi-Style Chams, Crosshair
local CollectionService = game:GetService("CollectionService")
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

-- Aimbot System
local AimD = {
	FOVOut = drw("Circle", { Visible = false, Filled = false, NumSides = 64, Color = Color3.new(0, 0, 0), Thickness = 3, Transparency = 0.75, ZIndex = 4 }),
	FOV = drw("Circle", { Visible = false, Filled = false, NumSides = 64, Color = CFG.Aim.FOVColor, Thickness = 1.5, Transparency = 0.75, ZIndex = 5 }),
	SnapOut = drw("Line", { Visible = false, Color = Color3.new(0, 0, 0), Thickness = 3.2, Transparency = 0.65, ZIndex = 4 }),
	Snap = drw("Line", { Visible = false, Color = Color3.new(1, 1, 1), Thickness = 1.4, Transparency = 0.9, ZIndex = 5 }),
	DotOut = drw("Circle", { Visible = false, Filled = true, NumSides = 16, Radius = 4.8, Color = Color3.new(0, 0, 0), Transparency = 0.75, ZIndex = 5 }),
	Dot = drw("Circle", { Visible = false, Filled = true, NumSides = 16, Radius = 3.0, Color = Color3.new(1, 1, 1), Transparency = 1, ZIndex = 6 }),
}
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.IgnoreWater = true
pcall(function() rp.CollisionGroup = "Bullet" end)

local function is_pierceable_part(inst)
	if not inst or not inst:IsA("BasePart") then return false end
	local tool = inst:FindFirstAncestorWhichIsA("Tool")
	if tool and tool.Name == "Riot Shield" then return false end
	if inst.CollisionGroup == "DoorPathfinding" then return true end
	if inst:GetAttribute("BulletsCanPierce") == true then return true end
	if inst.Transparency >= 0.4 and (inst.CollisionGroup == "Default" or inst.CollisionGroup == "BoatHull") then
		return true
	end
	if inst.Transparency >= 1 and not inst.CanCollide then
		local gp = Workspace:FindFirstChild("Gameplay")
		local bp = gp and gp:FindFirstChild("BeachHousePlots")
		if bp and inst:IsDescendantOf(bp) then return true end
	end
	return false
end

local function bullet_raycast(orig, dir, base_filter, stop_mdl)
	if dir.Magnitude < 0.05 then return nil end
	local f = table.clone(base_filter)
	for _ = 1, 5 do
		rp.FilterDescendantsInstances = f
		local res = Workspace:Raycast(orig, dir, rp)
		if not res or not res.Instance then return nil end
		local hit = res.Instance
		if stop_mdl and hit:IsDescendantOf(stop_mdl) then return res end
		if is_pierceable_part(hit) then
			table.insert(f, hit)
		else
			return res
		end
	end
	return nil
end

local function can_see(cam, orig, part, ch)
	local dir = part.Position - orig
	if dir.Magnitude < 0.05 then return true end
	local f = {}; if LP.Character then table.insert(f, LP.Character) end; if cam then table.insert(f, cam) end
	local res = bullet_raycast(orig, dir, f, ch)
	return not res or (res.Instance and res.Instance:IsDescendantOf(ch))
end

local function can_see_pos(cam, orig, pos, ch)
	local dir = pos - orig
	if dir.Magnitude < 0.05 then return true end
	local f = {}; if LP.Character then table.insert(f, LP.Character) end; if cam then table.insert(f, cam) end
	local res = bullet_raycast(orig, dir, f, ch)
	return not res or (ch and res.Instance and res.Instance:IsDescendantOf(ch))
end

local RND_PARTS = { "Head", "UpperTorso", "Torso", "HumanoidRootPart", "LowerTorso" }
local function pick_part(cam, ch, ctr, mode, fov_px)
	local m = mode or CFG.Aim.TargetPart
	local fov = fov_px or CFG.Aim.FOV
	if m == "Head" then return ch:FindFirstChild("Head") or ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso")
	elseif m == "UpperTorso" then return ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso") or ch:FindFirstChild("HumanoidRootPart")
	elseif m == "HumanoidRootPart" then return ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart
	elseif m == "Random" then
		local pool = {}
		for _, n in ipairs(RND_PARTS) do local p = ch:FindFirstChild(n); if p and p:IsA("BasePart") then table.insert(pool, p) end end
		return (#pool > 0) and pool[math.random(1, #pool)] or ch:FindFirstChild("Head") or ch.PrimaryPart
	elseif m == "Dynamic" then
		local h, t = ch:FindFirstChild("Head"), ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso")
		if h then local sp, on = cam:WorldToViewportPoint(h.Position); if on and sp.Z > 0 and (Vector2.new(sp.X, sp.Y) - ctr).Magnitude <= fov * 0.45 then return h end end
		return t or h
	elseif m == "Closest" then
		local best, bd = nil, math.huge
		for _, n in ipairs({ "Head", "UpperTorso", "Torso", "LowerTorso", "HumanoidRootPart" }) do
			local p = ch:FindFirstChild(n)
			if p and p:IsA("BasePart") then local sp, on = cam:WorldToViewportPoint(p.Position); if on and sp.Z > 0 then local d = (Vector2.new(sp.X, sp.Y) - ctr).Magnitude; if d < bd then bd, best = d, p end end end
		end
		return best
	end
	return ch:FindFirstChild("Head")
end

local function aim_on()
	if not CFG.Aim.Enabled then return false end
	local a = CFG.Aim.Activation
	return a == "Always" or (a == "Button (Toggle)" and S.AimTog) or (a == "Button (Hold)" and S.AimHold)
		or (a == "Shooting" and (S.FireHold or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)))
end

local function check_tgt(pl, cam, ctr, fov)
	if pl == LP or ignored(pl, CFG.Aim.TeamCheck, CFG.Aim.IgnoreHearseHidden, CFG.Aim.IgnoreModeratorHidden) then return nil end
	local ch = pl.Character; local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not ch or not ch.Parent or (CFG.Aim.AliveCheck and not alive(ch, hum)) then return nil end
	local part = pick_part(cam, ch, ctr)
	if not part or not part:IsA("BasePart") then return nil end
	local wd = (part.Position - cam.CFrame.Position).Magnitude
	if wd > CFG.Aim.MaxDistance then return nil end
	local sp, on = cam:WorldToViewportPoint(part.Position)
	if not on or sp.Z <= 0.2 then return nil end
	local fd = (Vector2.new(sp.X, sp.Y) - ctr).Magnitude
	if fd > fov or (CFG.Aim.WallCheck and not can_see(cam, cam.CFrame.Position, part, ch)) then return nil end
	return { Player = pl, Hum = hum, Part = part, Fov = fd, Dist = wd }
end

local function aim_origin(cam)
	if CFG.Aim.Method == "Mouse" and UserInputService.MouseBehavior == Enum.MouseBehavior.Default then
		return UserInputService:GetMouseLocation()
	end
	return cam.ViewportSize * 0.5
end

local function hide_aim_visuals()
	AimD.SnapOut.Visible, AimD.Snap.Visible, AimD.DotOut.Visible, AimD.Dot.Visible = false, false, false, false
end

local function find_aim_tgt(cam, ctr)
	local tgt = (CFG.Aim.StickyTarget and S.Locked and S.Locked.Parent) and check_tgt(S.Locked, cam, ctr, CFG.Aim.FOV) or nil
	if not tgt then
		local best = math.huge
		for _, pl in ipairs(Players:GetPlayers()) do
			local inf = check_tgt(pl, cam, ctr, CFG.Aim.FOV)
			if inf then
				local sc = (CFG.Aim.Priority == "Distance" and inf.Dist) or (CFG.Aim.Priority == "Lowest HP" and ((inf.Hum and inf.Hum.Health or 100) + inf.Fov * 0.05)) or (CFG.Aim.Priority == "Hybrid" and (inf.Fov + inf.Dist * 0.22)) or inf.Fov
				if sc < best then best, tgt = sc, inf end
			end
		end
	end
	return tgt
end

local function update_aim_pre(dt)
	local cam = Workspace.CurrentCamera
	if not cam then S.AimAct, S.AimPos, S.AimPart = false, nil, nil; return end
	local ctr = aim_origin(cam)
	local act = aim_on()
	if UI.APill then
		local sp = CFG.Aim.Enabled and CFG.Aim.ShowAimButton and (CFG.Aim.Activation == "Button (Toggle)" or CFG.Aim.Activation == "Button (Hold)")
		UI.APill.Visible = sp
		if sp then
			UI.APill.BackgroundColor3, UI.ALbl.TextColor3 = act and TH.Accent or TH.Bg, act and TH.AccentTxt or TH.Txt
			UI.AStroke.Color, UI.ALbl.Text = act and TH.Accent or TH.BorderHi, act and "AIM: ON" or "AIM"
		end
	end
	if not CFG.Aim.Enabled then
		S.Locked, S.AimAct, S.AimPos, S.AimPart = nil, false, nil, nil
		return
	end

	local tgt = find_aim_tgt(cam, ctr)
	if not tgt then
		S.Locked, S.AimAct, S.AimPos, S.AimPart = nil, false, nil, nil
		return
	end

	local apos = tgt.Part.Position + (CFG.Aim.Prediction and (tgt.Part.AssemblyLinearVelocity * CFG.Aim.PredictionScale) or Vector3.zero)
	local asp, aon = cam:WorldToViewportPoint(apos)
	if not aon or asp.Z <= 0.2 or (Vector2.new(asp.X, asp.Y) - ctr).Magnitude > CFG.Aim.FOV then
		apos = tgt.Part.Position
	end
	S.AimPart, S.AimPos, S.AimAct = tgt.Part, apos, act
	if not act then S.Locked = nil; return end
	S.Locked = tgt.Player

	if CFG.Aim.Method == "Mouse" and typeof(mousemoverel) == "function" then
		local sp = cam:WorldToViewportPoint(apos)
		if sp.Z > 0.2 then
			local d = Vector2.new(sp.X, sp.Y) - ctr
			local f = (CFG.Aim.Smoothness <= 0.01) and 1 or math.clamp((1 - CFG.Aim.Smoothness) * math.clamp(dt * 60, 0.4, 2.0) * 0.45, 0.06, 0.9)
			mousemoverel(d.X * f, d.Y * f)
		end
	else
		local g = CFrame.lookAt(cam.CFrame.Position, apos)
		if CFG.Aim.Smoothness <= 0.01 then
			cam.CFrame = g
		else
			local alpha = 1 - math.exp(-math.max((1 - math.clamp(CFG.Aim.Smoothness, 0, 0.96)) * 28, 2.5) * math.clamp(dt, 0.001, 0.05))
			cam.CFrame = cam.CFrame:Lerp(g, alpha)
		end
	end
end

local CAMGC = { Ctrl = nil, LastScan = 0, Applied = false, Sig = nil, SigCam = nil, Lock = false }
local function find_cam_ctrl()
	local now = os.clock()
	if CAMGC.Ctrl or (now - CAMGC.LastScan) < 2.0 then return CAMGC.Ctrl end
	if typeof(getgc) ~= "function" then return nil end
	CAMGC.LastScan = now
	pcall(function()
		for _, obj in ipairs(getgc(true)) do
			if typeof(obj) == "table" and typeof(rawget(obj, "SetFOVOverride")) == "function" and typeof(rawget(obj, "SetFOVMultiplier")) == "function" and typeof(rawget(obj, "GetBaseFOV")) == "function" then
				CAMGC.Ctrl = obj
				break
			end
		end
	end)
	return CAMGC.Ctrl
end

local function sync_world_fov(force_off)
	local cam = Workspace.CurrentCamera
	local on = (not force_off) and CFG.Camera.OverrideFOV
	local ctrl_c = find_cam_ctrl()
	if on then
		CAMGC.Applied = true
		if ctrl_c then pcall(function() ctrl_c:SetFOVOverride(CFG.Camera.FOV) end) end
		if cam and not CAMGC.Lock then
			CAMGC.Lock = true
			if math.abs(cam.FieldOfView - CFG.Camera.FOV) > 0.05 then cam.FieldOfView = CFG.Camera.FOV end
			if CAMGC.SigCam ~= cam then
				if CAMGC.Sig then pcall(function() CAMGC.Sig:Disconnect() end); CAMGC.Sig = nil end
				CAMGC.SigCam = cam
				CAMGC.Sig = cam:GetPropertyChangedSignal("FieldOfView"):Connect(function()
					if not S.Destroyed and CFG.Camera.OverrideFOV and not CAMGC.Lock and Workspace.CurrentCamera == cam then
						if math.abs(cam.FieldOfView - CFG.Camera.FOV) > 0.05 then
							CAMGC.Lock = true
							cam.FieldOfView = CFG.Camera.FOV
							CAMGC.Lock = false
						end
					end
				end)
			end
			CAMGC.Lock = false
		end
	elseif CAMGC.Applied or force_off then
		CAMGC.Applied = false
		if ctrl_c then pcall(function() ctrl_c:SetFOVOverride(nil) end) end
		if CAMGC.Sig then pcall(function() CAMGC.Sig:Disconnect() end); CAMGC.Sig = nil end
		CAMGC.SigCam = nil
		if cam and not CAMGC.Lock then
			CAMGC.Lock = true
			cam.FieldOfView = 70
			CAMGC.Lock = false
		end
	end
end

local function update_aim_post()
	local cam = Workspace.CurrentCamera
	if not cam then return end
	sync_world_fov(false)
	if S.AimAct and S.AimPos and CFG.Aim.Method == "Camera" and CFG.Aim.Smoothness <= 0.01 then
		cam.CFrame = CFrame.lookAt(cam.CFrame.Position, S.AimPos)
	end
end

local function update_aim_visuals()
	local cam = Workspace.CurrentCamera
	if not cam then AimD.FOV.Visible, AimD.FOVOut.Visible = false, false; hide_aim_visuals(); return end
	local ctr = aim_origin(cam)
	local sf = CFG.Aim.Enabled and CFG.Aim.ShowFOV
	AimD.FOVOut.Visible, AimD.FOV.Visible = sf and not CFG.Aim.FOVFilled, sf
	if sf then
		AimD.FOVOut.Position, AimD.FOVOut.Radius, AimD.FOVOut.Thickness = ctr, CFG.Aim.FOV, CFG.Aim.FOVThickness + 1.5
		AimD.FOV.Position, AimD.FOV.Radius, AimD.FOV.Color, AimD.FOV.Filled, AimD.FOV.Thickness = ctr, CFG.Aim.FOV, CFG.Aim.FOVColor, CFG.Aim.FOVFilled, CFG.Aim.FOVThickness
		AimD.FOV.Transparency = CFG.Aim.FOVFilled and math.min(CFG.Aim.FOVTransparency, 0.25) or CFG.Aim.FOVTransparency
	end

	local aim_pos = S.AimPos
	if CFG.Aim.Enabled and CFG.Aim.ShowSnapline and S.AimPart and S.AimPart.Parent then
		local rsp, ron = cam:WorldToViewportPoint(S.AimPart.Position)
		local rfd = (Vector2.new(rsp.X, rsp.Y) - ctr).Magnitude
		if ron and rsp.Z > 0.2 and rfd <= (CFG.Aim.FOV - 1) then
			local pos = aim_pos or S.AimPart.Position
			local sp, on = cam:WorldToViewportPoint(pos)
			local pt = Vector2.new(sp.X, sp.Y)
			local fd = (pt - ctr).Magnitude
			if not (on and sp.Z > 0.2 and fd <= (CFG.Aim.FOV - 1)) then
				sp, on, pt, fd = rsp, ron, Vector2.new(rsp.X, rsp.Y), rfd
			end
			local lcol = S.AimAct and CFG.Aim.FOVColor or Color3.fromRGB(220, 220, 230)
			local show_line = fd >= 4
			AimD.SnapOut.Visible, AimD.Snap.Visible = show_line, show_line
			if show_line then
				AimD.SnapOut.From, AimD.SnapOut.To = ctr, pt
				AimD.Snap.From, AimD.Snap.To, AimD.Snap.Color = ctr, pt, lcol
			end
			AimD.DotOut.Position, AimD.DotOut.Visible = pt, true
			AimD.Dot.Position, AimD.Dot.Color, AimD.Dot.Visible = pt, lcol, true
		else
			hide_aim_visuals()
		end
	else
		hide_aim_visuals()
	end
end

-- Custom Crosshair
local CrossD = {
	LO = { drw("Line", { Visible = false, ZIndex = 7 }), drw("Line", { Visible = false, ZIndex = 7 }), drw("Line", { Visible = false, ZIndex = 7 }), drw("Line", { Visible = false, ZIndex = 7 }) },
	L = { drw("Line", { Visible = false, ZIndex = 8 }), drw("Line", { Visible = false, ZIndex = 8 }), drw("Line", { Visible = false, ZIndex = 8 }), drw("Line", { Visible = false, ZIndex = 8 }) },
	CO = drw("Circle", { Visible = false, Filled = false, NumSides = 40, ZIndex = 7 }),
	C = drw("Circle", { Visible = false, Filled = false, NumSides = 40, ZIndex = 8 }),
	DO = drw("Circle", { Visible = false, Filled = true, NumSides = 16, ZIndex = 7 }),
	D = drw("Circle", { Visible = false, Filled = true, NumSides = 16, ZIndex = 8 }),
}
local reticle_hidden = false

local function set_game_reticle_hidden(hide)
	local pg = LP:FindFirstChild("PlayerGui")
	local rg = pg and pg:FindFirstChild("ReticleGui")
	local ret = rg and rg:FindFirstChild("Reticle")
	if not ret then return end
	if hide then
		local ch = ret:FindFirstChild("Crosshairs")
		local cr = ret:FindFirstChild("Circle")
		if ch and ch:IsA("GuiObject") and ch.Visible then ch.Visible = false end
		if cr and cr:IsA("GuiObject") and cr.Visible then cr.Visible = false end
		reticle_hidden = true
	elseif reticle_hidden then
		reticle_hidden = false
		local ch = ret:FindFirstChild("Crosshairs")
		if ch and ch:IsA("GuiObject") then ch.Visible = true end
	end
end

local function hide_crosshair()
	for i = 1, 4 do CrossD.LO[i].Visible, CrossD.L[i].Visible = false, false end
	CrossD.CO.Visible, CrossD.C.Visible, CrossD.DO.Visible, CrossD.D.Visible = false, false, false, false
	set_game_reticle_hidden(false)
end

local function update_crosshair(clk)
	local cc = CFG.Crosshair
	local cam = Workspace.CurrentCamera
	if not cc.Enabled or not cam then hide_crosshair(); return end
	set_game_reticle_hidden(cc.HideGameReticle)

	local ctr
	if cc.Position == "Mouse" then
		ctr = UserInputService:GetMouseLocation()
	elseif cc.Position == "Center" then
		ctr = cam.ViewportSize * 0.5
	else
		ctr = (UserInputService.MouseBehavior == Enum.MouseBehavior.Default) and UserInputService:GetMouseLocation() or (cam.ViewportSize * 0.5)
	end

	local col = cc.Rainbow and Color3.fromHSV((clk * 0.35) % 1, 0.85, 1) or cc.Color
	local ocol = cc.OutlineColor
	local thk, sz, gap = cc.Thickness, cc.Size, cc.Gap
	local stn = cc.Style

	if stn == "Circle" then
		for i = 1, 4 do CrossD.LO[i].Visible, CrossD.L[i].Visible = false, false end
		CrossD.CO.Visible = cc.Outline
		if cc.Outline then CrossD.CO.Position, CrossD.CO.Radius, CrossD.CO.Thickness, CrossD.CO.Color = ctr, sz, thk + 2, ocol end
		CrossD.C.Position, CrossD.C.Radius, CrossD.C.Thickness, CrossD.C.Color, CrossD.C.Visible = ctr, sz, thk, col, true
	elseif stn == "Dot" then
		for i = 1, 4 do CrossD.LO[i].Visible, CrossD.L[i].Visible = false, false end
		CrossD.CO.Visible, CrossD.C.Visible = false, false
	else
		CrossD.CO.Visible, CrossD.C.Visible = false, false
		local base_ang = (cc.Spin and (clk * cc.SpinSpeed) or 0) + (stn == "X-Cross" and (math.pi * 0.25) or 0)
		for i = 1, 4 do
			if stn == "T-Shape" and i == 4 then
				CrossD.LO[i].Visible, CrossD.L[i].Visible = false, false
			else
				local a = base_ang + (i - 1) * (math.pi * 0.5)
				local dir = Vector2.new(math.cos(a), math.sin(a))
				local p1, p2 = ctr + dir * gap, ctr + dir * (gap + sz)
				CrossD.LO[i].Visible = cc.Outline
				if cc.Outline then CrossD.LO[i].From, CrossD.LO[i].To, CrossD.LO[i].Thickness, CrossD.LO[i].Color = p1, p2, thk + 2, ocol end
				CrossD.L[i].From, CrossD.L[i].To, CrossD.L[i].Thickness, CrossD.L[i].Color, CrossD.L[i].Visible = p1, p2, thk, col, true
			end
		end
	end

	local show_dot = cc.CenterDot or stn == "Dot"
	if show_dot then
		local dr = math.max(1.5, thk * 0.8)
		CrossD.DO.Visible = cc.Outline
		if cc.Outline then CrossD.DO.Position, CrossD.DO.Radius, CrossD.DO.Color = ctr, dr + 1.2, ocol end
		CrossD.D.Position, CrossD.D.Radius, CrossD.D.Color, CrossD.D.Visible = ctr, dr, col, true
	else
		CrossD.DO.Visible, CrossD.D.Visible = false, false
	end
end

local function cleanup_crosshair()
	hide_crosshair()
	for i = 1, 4 do pcall(function() CrossD.LO[i]:Remove() end); pcall(function() CrossD.L[i]:Remove() end) end
	pcall(function() CrossD.CO:Remove() end); pcall(function() CrossD.C:Remove() end)
	pcall(function() CrossD.DO:Remove() end); pcall(function() CrossD.D:Remove() end)
end

-- San Diego ESP
local BONES = {
	{ "HeadCenter", "Neck" }, { "Neck", "UpperChest" }, { "UpperChest", "Waist" }, { "Waist", "Pelvis" },
	{ "UpperChest", "LeftShoulder" }, { "LeftShoulder", "LeftElbow" }, { "LeftElbow", "LeftWrist" }, { "LeftWrist", "LeftHandTip" },
	{ "UpperChest", "RightShoulder" }, { "RightShoulder", "RightElbow" }, { "RightElbow", "RightWrist" }, { "RightWrist", "RightHandTip" },
	{ "Pelvis", "LeftHip" }, { "LeftHip", "LeftKnee" }, { "LeftKnee", "LeftAnkle" }, { "LeftAnkle", "LeftFootTip" },
	{ "Pelvis", "RightHip" }, { "RightHip", "RightKnee" }, { "RightKnee", "RightAnkle" }, { "RightAnkle", "RightFootTip" },
}
local CORNERS = {
	Vector3.new(-0.5, -0.5, -0.5), Vector3.new(0.5, -0.5, -0.5), Vector3.new(-0.5, 0.5, -0.5), Vector3.new(0.5, 0.5, -0.5),
	Vector3.new(-0.5, -0.5, 0.5), Vector3.new(0.5, -0.5, 0.5), Vector3.new(-0.5, 0.5, 0.5), Vector3.new(0.5, 0.5, 0.5),
}
local ESP_E = {}
local NPC_E = {}

local function build_rig(ch)
	local r15 = ch:FindFirstChild("UpperTorso") ~= nil
	local pts, atts = {}, {}
	for _, n in ipairs(r15 and R15 or R6) do local p = ch:FindFirstChild(n); if p and p:IsA("BasePart") then pts[n] = p end end
	if r15 then
		local function att(pn, an) local p = pts[pn]; local a = p and p:FindFirstChild(an); return (a and a:IsA("Attachment")) and a or nil end
		atts.Neck = att("UpperTorso", "NeckRigAttachment") or att("Head", "NeckRigAttachment")
		atts.Waist = att("LowerTorso", "WaistRigAttachment") or att("UpperTorso", "WaistRigAttachment")
		atts.LS = att("LeftUpperArm", "LeftShoulderRigAttachment") or att("UpperTorso", "LeftShoulderRigAttachment")
		atts.LE = att("LeftLowerArm", "LeftElbowRigAttachment") or att("LeftUpperArm", "LeftElbowRigAttachment")
		atts.LW = att("LeftHand", "LeftWristRigAttachment") or att("LeftLowerArm", "LeftWristRigAttachment")
		atts.RS = att("RightUpperArm", "RightShoulderRigAttachment") or att("UpperTorso", "RightShoulderRigAttachment")
		atts.RE = att("RightLowerArm", "RightElbowRigAttachment") or att("RightUpperArm", "RightElbowRigAttachment")
		atts.RW = att("RightHand", "RightWristRigAttachment") or att("RightLowerArm", "RightWristRigAttachment")
		atts.LH = att("LeftUpperLeg", "LeftHipRigAttachment") or att("LowerTorso", "LeftHipRigAttachment")
		atts.LK = att("LeftLowerLeg", "LeftKneeRigAttachment") or att("LeftUpperLeg", "LeftKneeRigAttachment")
		atts.LA = att("LeftFoot", "LeftAnkleRigAttachment") or att("LeftLowerLeg", "LeftAnkleRigAttachment")
		atts.RH = att("RightUpperLeg", "RightHipRigAttachment") or att("LowerTorso", "RightHipRigAttachment")
		atts.RK = att("RightLowerLeg", "RightKneeRigAttachment") or att("RightUpperLeg", "RightKneeRigAttachment")
		atts.RA = att("RightFoot", "RightAnkleRigAttachment") or att("RightLowerLeg", "RightAnkleRigAttachment")
	end
	return { R15 = r15, Parts = pts, Atts = atts }
end
local function poff(p, x, y, z) return p.CFrame:PointToWorldSpace(Vector3.new(p.Size.X * x, p.Size.Y * y, p.Size.Z * z)) end
local function joints_world(rig, out)
	local p, a = rig.Parts, rig.Atts
	if not p.Head then return false end
	out.HeadCenter = p.Head.Position
	if rig.R15 then
		local ut, lt = p.UpperTorso, p.LowerTorso
		if not ut or not lt then return false end
		out.Neck = (a.Neck and a.Neck.Parent) and a.Neck.WorldPosition or poff(ut, 0, 0.5, 0)
		out.UpperChest = poff(ut, 0, 0.28, 0)
		out.Waist = (a.Waist and a.Waist.Parent) and a.Waist.WorldPosition or poff(lt, 0, 0.45, 0)
		out.Pelvis = poff(lt, 0, -0.3, 0)
		local function lb(u, l, e, au, al, ae, k1, k2, k3, k4, fy, fz)
			out[k1] = (au and au.Parent) and au.WorldPosition or (u and poff(u, 0, 0.38, 0))
			out[k2] = (al and al.Parent) and al.WorldPosition or (l and poff(l, 0, 0.45, 0))
			out[k3] = (ae and ae.Parent) and ae.WorldPosition or (e and poff(e, 0, 0.4, 0))
			out[k4] = e and poff(e, 0, fy, fz) or out[k3]
		end
		lb(p.LeftUpperArm, p.LeftLowerArm, p.LeftHand, a.LS, a.LE, a.LW, "LeftShoulder", "LeftElbow", "LeftWrist", "LeftHandTip", -0.4, 0)
		lb(p.RightUpperArm, p.RightLowerArm, p.RightHand, a.RS, a.RE, a.RW, "RightShoulder", "RightElbow", "RightWrist", "RightHandTip", -0.4, 0)
		lb(p.LeftUpperLeg, p.LeftLowerLeg, p.LeftFoot, a.LH, a.LK, a.LA, "LeftHip", "LeftKnee", "LeftAnkle", "LeftFootTip", -0.35, -0.25)
		lb(p.RightUpperLeg, p.RightLowerLeg, p.RightFoot, a.RH, a.RK, a.RA, "RightHip", "RightKnee", "RightAnkle", "RightFootTip", -0.35, -0.25)
	else
		local t = p.Torso; if not t then return false end
		out.Neck, out.UpperChest, out.Waist, out.Pelvis = poff(t, 0, 0.5, 0), poff(t, 0, 0.32, 0), t.Position, poff(t, 0, -0.45, 0)
		local function r6l(pt, k1, k2, k3, k4, fz)
			if pt then out[k1], out[k2], out[k3], out[k4] = poff(pt, 0, 0.38, 0), pt.Position, poff(pt, 0, -0.35, 0), poff(pt, 0, -0.48, fz) end
		end
		r6l(p["Left Arm"], "LeftShoulder", "LeftElbow", "LeftWrist", "LeftHandTip", 0)
		r6l(p["Right Arm"], "RightShoulder", "RightElbow", "RightWrist", "RightHandTip", 0)
		r6l(p["Left Leg"], "LeftHip", "LeftKnee", "LeftAnkle", "LeftFootTip", -0.15)
		r6l(p["Right Leg"], "RightHip", "RightKnee", "RightAnkle", "RightFootTip", -0.15)
	end
	return true
end

local function screen_box(cam, rig)
	local x1, y1, x2, y2, vis = math.huge, math.huge, -math.huge, -math.huge, false
	for _, p in pairs(rig.Parts) do
		if p.Parent then
			local cf, sz = p.CFrame, p.Size
			for _, s in ipairs(CORNERS) do
				local sp, on = cam:WorldToViewportPoint(cf:PointToWorldSpace(Vector3.new(sz.X * s.X, sz.Y * s.Y, sz.Z * s.Z)))
				if sp.Z > 0.2 then
					if on then vis = true end
					if sp.X < x1 then x1 = sp.X end; if sp.Y < y1 then y1 = sp.Y end
					if sp.X > x2 then x2 = sp.X end; if sp.Y > y2 then y2 = sp.Y end
				end
			end
		end
	end
	if not vis or x1 >= x2 or y1 >= y2 then return nil end
	return x1, y1, x2 - x1, y2 - y1
end

local function new_esp_entry()
	local so, sl = {}, {}
	for i = 1, #BONES do
		so[i] = drw("Line", { Visible = false, Color = CFG.ESP.ColorOutline, Thickness = 3.5, Transparency = 1, ZIndex = 1 })
		sl[i] = drw("Line", { Visible = false, Color = CFG.ESP.ColorDefault, Thickness = 1.5, Transparency = 1, ZIndex = 2 })
	end
	return {
		Rig = nil, RigChar = nil, WJ = {}, SJ = {}, Conns = {}, SO = so, SL = sl,
		BO = drw("Square", { Visible = false, Filled = false, Color = CFG.ESP.ColorOutline, Thickness = 3, Transparency = 1, ZIndex = 1 }),
		B = drw("Square", { Visible = false, Filled = false, Color = CFG.ESP.ColorDefault, Thickness = 1, Transparency = 1, ZIndex = 2 }),
		HB = drw("Line", { Visible = false, Color = CFG.ESP.ColorOutline, Thickness = 4, Transparency = 1, ZIndex = 1 }),
		HF = drw("Line", { Visible = false, Color = Color3.fromRGB(80, 255, 95), Thickness = 2, Transparency = 1, ZIndex = 2 }),
		HO = drw("Circle", { Visible = false, Filled = false, NumSides = 20, Color = CFG.ESP.ColorOutline, Thickness = 3.5, Transparency = 1, ZIndex = 1 }),
		HC = drw("Circle", { Visible = false, Filled = false, NumSides = 20, Color = CFG.ESP.ColorDefault, Thickness = 1.5, Transparency = 1, ZIndex = 2 }),
		NT = drw("Text", { Visible = false, Center = true, Outline = true, OutlineColor = CFG.ESP.ColorOutline, Size = 13, Font = 2, Color = CFG.ESP.ColorDefault, Transparency = 1, ZIndex = 3 }),
		ST = drw("Text", { Visible = false, Center = true, Outline = true, OutlineColor = CFG.ESP.ColorOutline, Size = 12, Font = 2, Color = Color3.fromRGB(220, 220, 220), Transparency = 1, ZIndex = 3 }),
		TR = drw("Line", { Visible = false, Color = CFG.ESP.ColorDefault, Thickness = 1, Transparency = 0.8, ZIndex = 1 }),
	}
end

local function hide_esp(e)
	e.BO.Visible, e.B.Visible, e.HB.Visible, e.HF.Visible, e.HO.Visible, e.HC.Visible, e.NT.Visible, e.ST.Visible, e.TR.Visible = false, false, false, false, false, false, false, false, false
	for i = 1, #BONES do e.SO[i].Visible, e.SL[i].Visible = false, false end
end

local function free_esp_entry(e)
	for _, c in ipairs(e.Conns) do c:Disconnect() end
	e.BO:Remove(); e.B:Remove(); e.HB:Remove(); e.HF:Remove(); e.HO:Remove(); e.HC:Remove(); e.NT:Remove(); e.ST:Remove(); e.TR:Remove()
	for i = 1, #BONES do e.SO[i]:Remove(); e.SL[i]:Remove() end
end

local function add_esp(pl)
	local e = new_esp_entry()
	e.Player = pl
	local cc = nil
	local function oc(ch)
		if cc then cc:Disconnect(); cc = nil end
		if ch then
			local function rb() if pl.Character == ch and ch.Parent then e.Rig, e.RigChar = build_rig(ch), ch end end
			task.defer(rb); cc = ch.ChildAdded:Connect(function(c) if c:IsA("BasePart") then rb() end end)
		else e.Rig, e.RigChar = nil, nil end
	end
	table.insert(e.Conns, pl.CharacterAdded:Connect(oc))
	table.insert(e.Conns, pl.CharacterRemoving:Connect(function() if cc then cc:Disconnect(); cc = nil end; e.Rig, e.RigChar = nil, nil end))
	table.insert(e.Conns, { Disconnect = function() if cc then cc:Disconnect(); cc = nil end end })
	if pl.Character then oc(pl.Character) end
	ESP_E[pl] = e
end

local function del_esp(pl)
	local e = ESP_E[pl]; if not e then return end; ESP_E[pl] = nil
	free_esp_entry(e)
end

local function add_npc_esp(mdl)
	if not mdl or not mdl:IsA("Model") or NPC_E[mdl] then return end
	if not mdl:FindFirstChildOfClass("Humanoid") and not mdl:FindFirstChild("HumanoidRootPart") then
		-- Wait briefly for humanoid replication if rig was just parented
		local has_hum = false
		for _, c in ipairs(mdl:GetChildren()) do
			if c:IsA("Humanoid") then has_hum = true; break end
		end
		if not has_hum then return end
	end
	local e = new_esp_entry()
	e.Model = mdl
	e.Rig, e.RigChar = build_rig(mdl), mdl
	table.insert(e.Conns, mdl.ChildAdded:Connect(function(c)
		if c:IsA("BasePart") then e.Rig, e.RigChar = build_rig(mdl), mdl end
	end))
	NPC_E[mdl] = e
end

local function del_npc_esp(mdl)
	local e = NPC_E[mdl]; if not e then return end; NPC_E[mdl] = nil
	free_esp_entry(e)
end

local NPCGC = { Map = nil, Entities = nil, Ctrl = nil, LastScan = 0 }
local function scan_npc_gc()
	local now = os.clock()
	if (NPCGC.Map and NPCGC.Entities and NPCGC.Ctrl) or (now - NPCGC.LastScan) < 2.0 then return end
	if typeof(getgc) ~= "function" then return end
	NPCGC.LastScan = now
	pcall(function()
		for _, obj in ipairs(getgc(true)) do
			if typeof(obj) == "table" then
				if not NPCGC.Map then
					local eop = rawget(obj, "EntityOfPart")
					if typeof(eop) == "table" and (rawget(obj, "HumanoidPools") ~= nil or next(eop) ~= nil) then
						NPCGC.Map = eop
					end
				end
				if not NPCGC.Entities then
					local ents = rawget(obj, "Entities")
					if typeof(ents) == "table" then
						local _, first = next(ents)
						if typeof(first) == "table" and rawget(first, "Archetype") ~= nil then
							NPCGC.Entities = ents
						end
					end
				end
				if not NPCGC.Ctrl then
					if typeof(rawget(obj, "GetEntityFromPart")) == "function" and typeof(rawget(obj, "GetEntity")) == "function" then
						NPCGC.Ctrl = obj
					end
				end
				if NPCGC.Map and NPCGC.Entities and NPCGC.Ctrl then break end
			end
		end
	end)
end

local function npc_meta(part, mdl)
	local aid = part and (part:GetAttribute("NPCId") or (part.Parent and part.Parent:GetAttribute("NPCId")))
	if typeof(aid) ~= "number" or aid == 0 then
		scan_npc_gc()
		if NPCGC.Map then
			if part then
				local id = NPCGC.Map[part]
				if typeof(id) == "number" and id ~= 0 then aid = id end
			end
			if (not aid or aid == 0) and mdl then
				for _, ch in ipairs(mdl:GetChildren()) do
					if ch:IsA("BasePart") then
						local id = NPCGC.Map[ch]
						if typeof(id) == "number" and id ~= 0 then aid = id; break end
					end
				end
			end
		end
		if (not aid or aid == 0) and NPCGC.Ctrl then
			if part then
				local ok, id = pcall(function() return NPCGC.Ctrl:GetEntityFromPart(part) end)
				if ok and typeof(id) == "number" and id ~= 0 then aid = id end
			end
			if (not aid or aid == 0) and mdl then
				for _, ch in ipairs(mdl:GetChildren()) do
					if ch:IsA("BasePart") then
						local ok, id = pcall(function() return NPCGC.Ctrl:GetEntityFromPart(ch) end)
						if ok and typeof(id) == "number" and id ~= 0 then aid = id; break end
					end
				end
			end
		end
	end
	local ent, arch
	if typeof(aid) == "number" and aid ~= 0 then
		scan_npc_gc()
		ent = NPCGC.Entities and NPCGC.Entities[aid]
		if not ent and NPCGC.Ctrl then
			local ok, r = pcall(function() return NPCGC.Ctrl:GetEntity(aid) end)
			if ok then ent = r end
		end
		arch = typeof(ent) == "table" and ent.Archetype or nil
	end
	return (typeof(aid) == "number" and aid ~= 0) and aid or nil, arch, ent
end

local function npc_matches_filter(filter, is_border, is_jewelry)
	if filter == "All NPCs" then return true end
	if filter == "Border Only" then return is_border end
	if filter == "Jewelry Only" then return is_jewelry end
	return is_border or is_jewelry
end

local function npc_info(mdl, rt)
	local nt = rt:FindFirstChild("Nametag")
	local nar = nt and nt:FindFirstChild("NameAndRank")
	local plbl = nar and nar:FindFirstChild("PlayerName")
	local rlbl = nar and nar:FindFirstChild("RankName")
	local aid, arch, ent = npc_meta(rt, mdl)
	local aname = typeof(arch) == "table" and arch.Name or ""
	local adisp = typeof(arch) == "table" and arch.DisplayName or ""
	local nm = (plbl and plbl:IsA("TextLabel") and plbl.Text ~= "") and plbl.Text or (adisp ~= "" and adisp or mdl.Name)
	local rk = (rlbl and rlbl:IsA("TextLabel")) and rlbl.Text or ""
	local tc_col = (rlbl and rlbl:IsA("TextLabel")) and rlbl.TextColor3 or nil
	local is_border = (aname == "CheckpointOfficer") or (rk:find("Checkpoint", 1, true) ~= nil) or (nm:find("Checkpoint", 1, true) ~= nil)
	-- JewelleryGuard has Nametag = false in NPCArchetypes; fall back to missing Nametag before Replica populates
	local is_jewelry = (aname == "JewelleryGuard") or (adisp == "Security Guard") or (not is_border and aname == "" and nt == nil)
	return nm, rk, tc_col, is_border, is_jewelry, aname, aid, ent
end

local function npc_alive(mdl, hum, rt)
	if not mdl or not mdl.Parent or not hum or not hum.Parent or not rt then return false end
	if rt.Position.Y > 10000 then return false end -- NPCController pools inactive rigs at Y=20000
	if hum.Health <= 0 or hum:GetAttribute("Dead") == true or hum:GetState() == Enum.HumanoidStateType.Dead then return false end
	local hd = mdl:FindFirstChild("Head")
	if hd and hd:IsA("BasePart") and not rt.Anchored and not hd.CanQuery then return false end
	local aid, _, ent = npc_meta(hd or rt, mdl)
	-- Renderer.Kill removes parts from EntityOfPart while Humanoid.Health stays 100 on ragdoll corpses
	if (NPCGC.Map or NPCGC.Ctrl) and not aid then return false end
	if typeof(ent) == "table" and typeof(ent.Flags) == "number" and bit32 and bit32.btest(ent.Flags, 32) then return false end
	return true
end

local function render_esp_entry(e, cam, vp, ch, hum, dist, col, lbl, team_tag)
	if e.RigChar ~= ch or not e.Rig then e.Rig, e.RigChar = build_rig(ch), ch end
	if not e.Rig.Parts.Head or (e.Rig.R15 and (not e.Rig.Parts.UpperTorso or not e.Rig.Parts.LowerTorso)) then e.Rig = build_rig(ch) end
	local bx, by, bw, bh = screen_box(cam, e.Rig)
	if not bx then hide_esp(e); return end
	local cx = bx + bw * 0.5

	if CFG.ESP.ShowBox then
		local bp, bs = Vector2.new(bx, by), Vector2.new(bw, bh)
		e.BO.Visible = CFG.ESP.BoxOutline; if CFG.ESP.BoxOutline then e.BO.Position, e.BO.Size, e.BO.Thickness = bp, bs, CFG.ESP.BoxThickness + 2 end
		e.B.Position, e.B.Size, e.B.Color, e.B.Thickness, e.B.Visible = bp, bs, col, CFG.ESP.BoxThickness, true
	else e.BO.Visible, e.B.Visible = false, false end

	if CFG.ESP.ShowHealthBar then
		local fr, barx = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1), bx - 5
		e.HB.From, e.HB.To, e.HB.Visible = Vector2.new(barx, by - 1), Vector2.new(barx, by + bh + 1), true
		e.HF.From, e.HF.To, e.HF.Color, e.HF.Visible = Vector2.new(barx, by + bh), Vector2.new(barx, by + bh - bh * fr), Color3.fromRGB(math.floor(255 * (1 - fr)), math.floor(255 * fr), 55), true
	else e.HB.Visible, e.HF.Visible = false, false end

	if CFG.ESP.ShowName then
		e.NT.Text, e.NT.Size, e.NT.Position, e.NT.Color, e.NT.Visible = lbl, CFG.ESP.TextSize, Vector2.new(cx, by - CFG.ESP.TextSize - 3), col, true
	else e.NT.Visible = false end

	if CFG.ESP.ShowDistance or CFG.ESP.ShowTeamTag then
		local pt = {}
		if CFG.ESP.ShowTeamTag and team_tag and team_tag ~= "" then table.insert(pt, team_tag) end
		if CFG.ESP.ShowDistance then table.insert(pt, string.format("%dm", math.floor(dist + 0.5))) end
		e.ST.Text, e.ST.Size, e.ST.Position, e.ST.Visible = table.concat(pt, " | "), math.max(11, CFG.ESP.TextSize - 1), Vector2.new(cx, by + bh + 2), true
	else e.ST.Visible = false end

	if CFG.ESP.ShowTracers then
		local oy = (CFG.ESP.TracerOrigin == "Center" and vp.Y * 0.5) or (CFG.ESP.TracerOrigin == "Top" and 0) or vp.Y
		e.TR.From, e.TR.To, e.TR.Color, e.TR.Visible = Vector2.new(vp.X * 0.5, oy), Vector2.new(cx, by + bh), col, true
	else e.TR.Visible = false end

	local sok = false
	if CFG.ESP.ShowSkeleton then
		table.clear(e.WJ); table.clear(e.SJ)
		if joints_world(e.Rig, e.WJ) then
			sok = true
			for j, wp in pairs(e.WJ) do local sp = cam:WorldToViewportPoint(wp); if sp.Z > 0 then e.SJ[j] = Vector2.new(sp.X, sp.Y) end end
			for i, b in ipairs(BONES) do
				local p1, p2 = e.SJ[b[1]], e.SJ[b[2]]
				if p1 and p2 then
					e.SO[i].Visible = CFG.ESP.SkeletonOutline
					if CFG.ESP.SkeletonOutline then e.SO[i].From, e.SO[i].To, e.SO[i].Thickness = p1, p2, CFG.ESP.SkeletonThickness + 2 end
					e.SL[i].From, e.SL[i].To, e.SL[i].Color, e.SL[i].Thickness, e.SL[i].Visible = p1, p2, col, CFG.ESP.SkeletonThickness, true
				else e.SO[i].Visible, e.SL[i].Visible = false, false end
			end
			local hp, hs = e.Rig.Parts.Head, e.SJ.HeadCenter
			if CFG.ESP.ShowHeadCircle and hp and hs then
				local ht = cam:WorldToViewportPoint(hp.Position + cam.CFrame.UpVector * (hp.Size.Y * 0.52))
				local r = ht.Z > 0 and math.clamp((Vector2.new(ht.X, ht.Y) - hs).Magnitude, 2, 42) or 4
				e.HO.Visible = CFG.ESP.SkeletonOutline; if CFG.ESP.SkeletonOutline then e.HO.Position, e.HO.Radius, e.HO.Thickness = hs, r, CFG.ESP.SkeletonThickness + 2 end
				e.HC.Position, e.HC.Radius, e.HC.Color, e.HC.Thickness, e.HC.Visible = hs, r, col, CFG.ESP.SkeletonThickness, true
			else e.HO.Visible, e.HC.Visible = false, false end
		end
	end
	if not sok then e.HO.Visible, e.HC.Visible = false, false; for i = 1, #BONES do e.SO[i].Visible, e.SL[i].Visible = false, false end end
end

local function update_esp()
	local cam = Workspace.CurrentCamera
	if not cam or not CFG.ESP.Enabled then
		for _, e in pairs(ESP_E) do hide_esp(e) end
		for _, e in pairs(NPC_E) do hide_esp(e) end
		return
	end
	local cp, vp = cam.CFrame.Position, cam.ViewportSize
	for pl, e in pairs(ESP_E) do
		local ch = pl.Character
		if not ch or not ch.Parent or ignored(pl, CFG.ESP.TeamCheck, CFG.ESP.IgnoreHearseHidden, CFG.ESP.IgnoreModeratorHidden) then hide_esp(e); continue end
		local hum = ch:FindFirstChildOfClass("Humanoid")
		local rt = (hum and hum.RootPart) or ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart
		if not rt or not alive(ch, hum) then hide_esp(e); continue end
		local dist = (rt.Position - cp).Magnitude
		if dist > CFG.ESP.MaxDistance then hide_esp(e); continue end
		local lbl = pl.DisplayName ~= "" and pl.DisplayName or pl.Name
		if CFG.ESP.ShowWanted then local st_n = wanted_stars(pl); if st_n > 0 then lbl = string.format("%s [W%d]", lbl, st_n) end end
		if ch:GetAttribute("IsDetained") == true then lbl = lbl .. " [CUFF]" end
		render_esp_entry(e, cam, vp, ch, hum, dist, esp_col(pl, ch), lbl, pl.Team and pl.Team.Name or nil)
	end

	for mdl, e in pairs(NPC_E) do
		if not CFG.ESP.ShowBorderBots then hide_esp(e); continue end
		local hum = mdl:FindFirstChildOfClass("Humanoid")
		local rt = (hum and hum.RootPart) or mdl:FindFirstChild("HumanoidRootPart") or mdl.PrimaryPart
		if not npc_alive(mdl, hum, rt) then hide_esp(e); continue end
		local dist = (rt.Position - cp).Magnitude
		if dist > CFG.ESP.MaxDistance then hide_esp(e); continue end
		local nm, rk, _, is_border, is_jewelry = npc_info(mdl, rt)
		if not npc_matches_filter(CFG.ESP.BotFilter, is_border, is_jewelry) then hide_esp(e); continue end
		local col = is_jewelry and CFG.ESP.ColorJewelryBot or CFG.ESP.ColorBorderBot
		local tag = (rk ~= "" and rk) or (is_jewelry and "Security Guard" or (is_border and "Checkpoint Authority" or "NPC"))
		render_esp_entry(e, cam, vp, mdl, hum, dist, col, nm .. " [BOT]", tag)
	end
end

-- Silent Aim (San Diego DynamicCast + GunService.TryShoot)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SilentD = {
	FOVOut = drw("Circle", { Visible = false, Filled = false, NumSides = 64, Color = Color3.new(0, 0, 0), Thickness = 2.8, Transparency = 0.7, ZIndex = 4 }),
	FOV = drw("Circle", { Visible = false, Filled = false, NumSides = 64, Color = CFG.Silent.FOVColor, Thickness = 1.3, Transparency = 0.75, ZIndex = 5 }),
	SnapOut = drw("Line", { Visible = false, Color = Color3.new(0, 0, 0), Thickness = 3.0, Transparency = 0.65, ZIndex = 4 }),
	Snap = drw("Line", { Visible = false, Color = CFG.Silent.FOVColor, Thickness = 1.3, Transparency = 0.9, ZIndex = 5 }),
	DotOut = drw("Circle", { Visible = false, Filled = true, NumSides = 16, Radius = 4.5, Color = Color3.new(0, 0, 0), Transparency = 0.75, ZIndex = 5 }),
	Dot = drw("Circle", { Visible = false, Filled = true, NumSides = 16, Radius = 2.6, Color = CFG.Silent.FOVColor, Transparency = 1, ZIndex = 6 }),
}
local tracer_queue, active_tracers = {}, {}
local function queue_tryshoot_tracers(shots)
	if not CFG.Tracers.Enabled or typeof(shots) ~= "table" then return end
	for i = 1, #shots do
		local s = shots[i]
		if typeof(s) == "table" and typeof(s.MuzzlePosition) == "Vector3" then
			local end_p = s.BulletImpactPosition
			if typeof(end_p) ~= "Vector3" then
				local d = s.Direction or s.MuzzleDirectionUnit
				if typeof(d) == "Vector3" and d.Magnitude > 0.01 then
					end_p = s.MuzzlePosition + d.Unit * 320
				end
			end
			if typeof(end_p) == "Vector3" and (end_p - s.MuzzlePosition).Magnitude > 0.25 then
				tracer_queue[#tracer_queue + 1] = { From = s.MuzzlePosition, To = end_p }
			end
		end
	end
end
local function silent_npc_id(part, mdl)
	if not part or not part:IsA("BasePart") then return nil end
	local id = npc_meta(part, mdl)
	return id
end

local function silent_origin(cam)
	if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter and UserInputService.PreferredInput ~= Enum.PreferredInput.Touch then
		return UserInputService:GetMouseLocation()
	end
	return cam.ViewportSize * 0.5
end

local function resolve_silent_pos(origin, part, hum)
	local pos = part.Position
	if CFG.Silent.Prediction then
		local vel = part.AssemblyLinearVelocity
		if vel.Magnitude < 0.05 and hum and hum.RootPart then vel = hum.RootPart.AssemblyLinearVelocity end
		pos = pos + vel * CFG.Silent.PredictionScale
	end
	return pos
end

local function obb_hit_on_part(origin, aim_pos, part)
	local dv = aim_pos - origin
	if dv.Magnitude < 0.05 then return aim_pos, Vector3.new(0, 1, 0) end
	local ud = dv.Unit
	local cf, sz = part.CFrame, part.Size * 0.5
	local rv, uv, fv = cf.RightVector, cf.UpVector, -cf.LookVector
	local rel = origin - cf.Position
	local lo = { rel:Dot(rv), rel:Dot(uv), rel:Dot(fv) }
	local ld = { ud:Dot(rv), ud:Dot(uv), ud:Dot(fv) }
	local hs = { sz.X, sz.Y, sz.Z }
	local ax_v = { rv, uv, fv }
	local tmin, tmax, hit_ax, hit_s = -1e9, 1e9, 2, 1
	for i = 1, 3 do
		local o, d, h = lo[i], ld[i], hs[i]
		if math.abs(d) < 1e-6 then
			if o < -h or o > h then tmin = 1e9; break end
		else
			local t1, t2 = (-h - o) / d, (h - o) / d
			local s = -1
			if t1 > t2 then t1, t2, s = t2, t1, 1 end
			if t1 > tmin then tmin, hit_ax, hit_s = t1, i, s end
			if t2 < tmax then tmax = t2 end
			if tmin > tmax then tmin = 1e9; break end
		end
	end
	if tmin > 0 and tmin < 1e8 then
		return origin + ud * tmin, ax_v[hit_ax] * hit_s, true
	end
	local r = math.min(sz.X, sz.Y, sz.Z) * 0.85
	return aim_pos - ud * math.min(r, dv.Magnitude * 0.5), -ud, false
end

local function safe_silent_aim_pos(cam, orig, part, hum, model)
	local ap = resolve_silent_pos(orig, part, hum)
	if (ap - part.Position).Magnitude > 0.05 then
		local _, _, hit_obb = obb_hit_on_part(orig, ap, part)
		if not hit_obb or (CFG.Silent.MagicBullet and not can_see_pos(cam, orig, ap, model)) then
			return part.Position
		end
	end
	return ap
end

local function collect_tgt_parts(ch)
	local pool = {}
	for _, n in ipairs(RND_PARTS) do
		local p = ch:FindFirstChild(n)
		if p and p:IsA("BasePart") then table.insert(pool, p) end
	end
	return pool
end

local function find_silent_tgt(for_shot)
	local cam = Workspace.CurrentCamera
	if not cam then return nil end
	local sc = CFG.Silent
	local ctr = silent_origin(cam)
	local pmode = (for_shot and sc.TargetPart == "Random") and "Random" or ((sc.TargetPart == "Random") and "UpperTorso" or sc.TargetPart)
	local best_sc, best_tgt = math.huge, nil

	local function eval_model(mdl, hum, pl, is_npc)
		local part = pick_part(cam, mdl, ctr, pmode, sc.FOV)
		if not part or not part:IsA("BasePart") then return end
		local wd = (part.Position - cam.CFrame.Position).Magnitude
		if wd > sc.MaxDistance then return end
		local sp, on = cam:WorldToViewportPoint(part.Position)
		if not on or sp.Z <= 0.2 then return end
		local fd = (Vector2.new(sp.X, sp.Y) - ctr).Magnitude
		if fd > sc.FOV then return end
		if sc.WallCheck and not sc.MagicBullet and not can_see(cam, cam.CFrame.Position, part, mdl) then return end
		local score = (sc.Priority == "Distance" and wd)
			or (sc.Priority == "Lowest HP" and ((hum and hum.Health or 100) + fd * 0.05))
			or (sc.Priority == "Hybrid" and (fd + wd * 0.22))
			or fd
		if score < best_sc then
			best_sc = score
			best_tgt = {
				Model = mdl, Player = pl, Hum = hum, Part = part,
				Parts = (not for_shot and sc.TargetPart == "Random") and collect_tgt_parts(mdl) or nil,
				NPCId = is_npc and silent_npc_id(part, mdl) or nil,
				Fov = fd, Dist = wd, IsNPC = is_npc,
			}
		end
	end

	for _, pl in ipairs(Players:GetPlayers()) do
		if pl ~= LP and not ignored(pl, sc.TeamCheck, sc.IgnoreHearseHidden, sc.IgnoreModeratorHidden) then
			local ch = pl.Character; local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			if ch and ch.Parent and alive(ch, hum) then eval_model(ch, hum, pl, false) end
		end
	end

	if sc.TargetNPCs then
		for mdl, _ in pairs(NPC_E) do
			local hum = mdl:FindFirstChildOfClass("Humanoid")
			local rt = (hum and hum.RootPart) or mdl:FindFirstChild("HumanoidRootPart") or mdl.PrimaryPart
			if npc_alive(mdl, hum, rt) then
				local _, _, _, is_border, is_jewelry = npc_info(mdl, rt)
				if npc_matches_filter(sc.BotFilter, is_border, is_jewelry) then eval_model(mdl, hum, nil, true) end
			end
		end
	end
	return best_tgt
end

local last_cast_roll = { T = 0, Pass = false, Tgt = nil }
local function sample_silent_shot(use_cached)
	local now = os.clock()
	if now - last_cast_roll.T < 0.008 then
		if use_cached and S.SilentTgt then return last_cast_roll.Pass, S.SilentTgt end
		return last_cast_roll.Pass, last_cast_roll.Tgt
	end
	local pass = (CFG.Silent.HitChance >= 100) or (math.random(1, 100) <= CFG.Silent.HitChance)
	local tgt = pass and (use_cached and S.SilentTgt or (S.SilentTgt or find_silent_tgt(true))) or nil
	last_cast_roll.T, last_cast_roll.Pass, last_cast_roll.Tgt = now, pass, tgt
	return pass, tgt
end

local function list_has_inst(list, item)
	if typeof(list) ~= "table" then return false end
	for i = 1, #list do
		if list[i] == item then return true end
	end
	return false
end

local function has_local_char_filter(params)
	local my_ch = LP and LP.Character
	if not my_ch then return false end
	local ok1, f1 = pcall(function() return params.FilterDescendantsInstances end)
	if ok1 and list_has_inst(f1, my_ch) then return true end
	local ok2, f2 = pcall(function() return params.ExcludeInstances end)
	if ok2 and list_has_inst(f2, my_ch) then return true end
	return false
end

local function is_gun_cast(method, orig, dir, params)
	if typeof(params) ~= "RaycastParams" then return false end
	if params.CollisionGroup ~= "Bullet" or params.FilterType ~= Enum.RaycastFilterType.Exclude then return false end
	if typeof(orig) ~= "Vector3" or typeof(dir) ~= "Vector3" or dir.Magnitude < 15 then return false end
	if not has_local_char_filter(params) then return false end
	if method == "Spherecast" then return true end
	if typeof(debug) == "table" and typeof(debug.info) == "function" then
		for lvl = 2, 6 do
			local src = debug.info(lvl, "s")
			if not src then break end
			if src:find("DynamicCast", 1, true) then return true end
			if lvl <= 3 and (src:find("Aim", 1, true) or src:find("UpdateScope", 1, true)) then return false end
		end
	end
	local cam = Workspace.CurrentCamera
	return cam ~= nil and (orig - cam.CFrame.Position).Magnitude > 0.75
end

local in_dyncast_redirect = false
-- Must stay 100% free of :Method() calls (called from inside __namecall on TryShoot)
local function patch_tryshoot_table(shots)
	local sc = CFG.Silent
	if typeof(shots) ~= "table" or #shots == 0 then return end
	local pass_c, ptgt_c = sample_silent_shot(true)
	local tgt = S.SilentTgt or (pass_c and ptgt_c or nil)
	if not tgt or not tgt.Part or not tgt.Part.Parent then return end
	for i = 1, #shots do
		local s = shots[i]
		if typeof(s) == "table" and typeof(s.MuzzlePosition) == "Vector3" then
			if s.Direction ~= nil and s.BulletImpactPosition == nil then
				if sc.Method == "Hybrid" or sc.Method == "Remote" then
					local pass, ptgt = sample_silent_shot(true)
					if pass and ptgt and ptgt.Part then
						if sc.MagicBullet and ptgt.WallbangMuzzle then s.MuzzlePosition = ptgt.WallbangMuzzle end
						local ap = resolve_silent_pos(s.MuzzlePosition, ptgt.Part, ptgt.Hum)
						local _, _, hit_obb = obb_hit_on_part(s.MuzzlePosition, ap, ptgt.Part)
						if not hit_obb then ap = ptgt.Part.Position end
						local dv = ap - s.MuzzlePosition
						if dv.Magnitude > 0.05 then s.Direction = dv.Unit end
					end
				end
			elseif s.MuzzleDirectionUnit ~= nil then
				local already_hit = (typeof(s.TargetInstance) == "Instance") and (s.TargetCharacter ~= nil or s.NPCId ~= nil)
				if (sc.Method == "Hybrid" or sc.Method == "Raycast") and already_hit and typeof(s.BulletImpactPosition) == "Vector3" then
					if sc.MagicBullet and tgt.WallbangMuzzle then s.MuzzlePosition = tgt.WallbangMuzzle end
					local dv = s.BulletImpactPosition - s.MuzzlePosition
					if dv.Magnitude > 0.05 then s.MuzzleDirectionUnit = dv.Unit end
				elseif sc.Method == "Remote" or (sc.MagicBullet and not already_hit) then
					local pass, rtgt = sample_silent_shot(true)
					if pass and rtgt and rtgt.Model then
						local part = rtgt.Part
						if sc.TargetPart == "Random" and rtgt.Parts and #rtgt.Parts > 0 then
							part = rtgt.Parts[math.random(1, #rtgt.Parts)]
						end
						if part and part.Parent then
							if sc.MagicBullet and rtgt.WallbangMuzzle then s.MuzzlePosition = rtgt.WallbangMuzzle end
							local ap = resolve_silent_pos(s.MuzzlePosition, part, rtgt.Hum)
							local imp, nrm, hit_obb = obb_hit_on_part(s.MuzzlePosition, ap, part)
							if not hit_obb then
								ap = part.Position
								imp, nrm = obb_hit_on_part(s.MuzzlePosition, ap, part)
							end
							local dv = ap - s.MuzzlePosition
							if dv.Magnitude > 0.05 then
								local ud = dv.Unit
								s.MuzzleDirectionUnit = ud
								s.BulletImpactPosition = imp
								s.Normal = nrm
								s.TargetInstance = part
								s.CraftPart, s.CraftImpact, s.CraftPartPosition = nil, nil, nil
								if rtgt.IsNPC then
									s.TargetCharacter = nil
									s.NPCId = rtgt.NPCId
									s.TargetSize = nil
									s.TargetCFrame = nil
								else
									s.TargetCharacter = rtgt.Model
									s.NPCId = nil
									s.TargetSize = part.Size
									s.TargetCFrame = part.CFrame
								end
							end
						end
					end
				end
			end
		end
	end
end

local function sync_silent_slot()
	local g = getgenv and getgenv() or _G
	if g._OcelSilentSlot then
		g._OcelSilentSlot.Active = (not S.Destroyed and (CFG.Silent.Enabled or CFG.Tracers.Enabled))
	end
end

local has_open_los, find_wallbang_muzzle, resolve_tgt_wallbang

local function install_silent_hooks()
	local g = getgenv and getgenv() or _G
	g._OcelSilentSlot = g._OcelSilentSlot or { Installed = false, DynInstalled = false, Version = 0, Active = false, Handler = nil, DynHandler = nil }
	local slot = g._OcelSilentSlot
	slot.Active = (not S.Destroyed and (CFG.Silent.Enabled or CFG.Tracers.Enabled))

	slot.Handler = function(kind, self, method, old_nc, ...)
		local sc = CFG.Silent
		if S.Destroyed then
			if kind == "Cast" then return old_nc(self, ...) end
			return
		end

		if kind == "Cast" then
			if in_dyncast_redirect or not sc.Enabled or (sc.Method ~= "Hybrid" and sc.Method ~= "Raycast") then return old_nc(self, ...) end
			if method == "Spherecast" then
				local orig, rad, dir, params = ...
				if is_gun_cast(method, orig, dir, params) then
					local pass, tgt = sample_silent_shot(false)
					if pass and tgt and tgt.Part then
						local aim_p = resolve_silent_pos(orig, tgt.Part, tgt.Hum)
						local nv = aim_p - orig
						if nv.Magnitude > 0.05 then return old_nc(self, orig, rad, nv.Unit * dir.Magnitude, params) end
					end
				end
			else
				local orig, dir, params = ...
				if is_gun_cast(method, orig, dir, params) then
					local pass, tgt = sample_silent_shot(false)
					if pass and tgt and tgt.Part then
						local aim_p = resolve_silent_pos(orig, tgt.Part, tgt.Hum)
						local nv = aim_p - orig
						if nv.Magnitude > 0.05 then return old_nc(self, orig, nv.Unit * dir.Magnitude, params) end
					end
				end
			end
			return old_nc(self, ...)
		elseif kind == "Remote" then
			local shots = ...
			if sc.Enabled then patch_tryshoot_table(shots) end
			if CFG.Tracers.Enabled then queue_tryshoot_tracers(shots) end
		end
	end

	slot.DynHandler = function(orig_run, orig, vec, params, pierce_fn, rad, viz)
		local sc = CFG.Silent
		local cast_orig, out_vec = orig, vec
		local redirected = false
		if not S.Destroyed and sc.Enabled and (sc.Method == "Hybrid" or sc.Method == "Raycast") then
			if typeof(orig) == "Vector3" and typeof(vec) == "Vector3" and vec.Magnitude >= 15 and typeof(params) == "RaycastParams" and params.CollisionGroup == "Bullet" and has_local_char_filter(params) then
				local pass, tgt = sample_silent_shot(false)
				if pass and tgt and tgt.Part then
					local cam = Workspace.CurrentCamera
					if sc.MagicBullet and cam then
						if not tgt.WallbangChecked then resolve_tgt_wallbang(cam, tgt) end
						if tgt.WallbangMuzzle then
							cast_orig = tgt.WallbangMuzzle
						elseif not has_open_los(cam, orig, tgt.Part, tgt.Model) then
							local my_ch = LP and LP.Character
							local my_hd = my_ch and (my_ch:FindFirstChild("Head") or my_ch:FindFirstChild("HumanoidRootPart"))
							local hd_pos = (my_hd and my_hd:IsA("BasePart")) and my_hd.Position or cam.CFrame.Position
							if has_open_los(cam, hd_pos, tgt.Part, tgt.Model) then
								tgt.WallbangMuzzle = hd_pos
								cast_orig = hd_pos
							end
						end
					end
					local aim_p = cam and safe_silent_aim_pos(cam, cast_orig, tgt.Part, tgt.Hum, tgt.Model) or resolve_silent_pos(cast_orig, tgt.Part, tgt.Hum)
					local nv = aim_p - cast_orig
					if nv.Magnitude > 0.05 then
						out_vec = nv.Unit * vec.Magnitude
						redirected = true
					end
				end
			end
		end
		if redirected then in_dyncast_redirect = true end
		local r1, r2, r3, r4 = orig_run(cast_orig, out_vec, params, pierce_fn, rad, viz)
		if redirected then in_dyncast_redirect = false end
		if not S.Destroyed and not slot.Installed and CFG.Tracers.Enabled and typeof(cast_orig) == "Vector3" and typeof(out_vec) == "Vector3" and out_vec.Magnitude >= 15 and typeof(params) == "RaycastParams" and params.CollisionGroup == "Bullet" and has_local_char_filter(params) then
			local ep = (r1 and r1.Position) or (cast_orig + out_vec)
			tracer_queue[#tracer_queue + 1] = { From = cast_orig, To = ep }
		end
		return r1, r2, r3, r4
	end

	-- 1) Direct DynamicCast.Run table hook via getgc (zero __namecall overhead, works without hookmetamethod)
	if not slot.DynInstalled and typeof(getgc) == "function" then
		pcall(function()
			for _, obj in ipairs(getgc(true)) do
				if typeof(obj) == "table" and rawget(obj, "MAX_PIERCE_DEPTH") == 5 and typeof(rawget(obj, "IsShapecast")) == "function" and typeof(rawget(obj, "Run")) == "function" then
					local orig_run = rawget(obj, "Run")
					obj.Run = function(orig, vec, params, pierce_fn, rad, viz)
						local dh = slot.DynHandler
						if dh then return dh(orig_run, orig, vec, params, pierce_fn, rad, viz) end
						return orig_run(orig, vec, params, pierce_fn, rad, viz)
					end
					slot.DynInstalled = true
					break
				end
			end
		end)
	end

	-- 2) Safe __namecall hook: zero ':' method calls inside hook, fast-path exit when disabled
	if not slot.Installed or slot.Version ~= 2 then
		local wrap = typeof(newcclosure) == "function" and newcclosure or function(f) return f end
		local setnc = typeof(setnamecallmethod) == "function" and setnamecallmethod or nil
		local nc_hook = wrap(function(self, ...)
			local raw = slot.RawNC or slot.OldNC
			if not slot.Active or S.Destroyed or (checkcaller and checkcaller()) then
				return raw(self, ...)
			end
			local m = getnamecallmethod()
			if m == "FireServer" or m == "InvokeServer" then
				if typeof(self) == "Instance" and self.Name == "TryShoot" then
					local par = self.Parent
					if par and par.Name == "GunService" then
						local h = slot.Handler
						if h then h("Remote", self, m, raw, ...) end
						if setnc then setnc(m) end
					end
				end
				return raw(self, ...)
			elseif not slot.DynInstalled and (m == "Raycast" or m == "Spherecast") then
				if self == Workspace then
					local h = slot.Handler
					if h then
						local r1, r2, r3, r4 = h("Cast", self, m, raw, ...)
						if setnc then setnc(m) end
						return r1, r2, r3, r4
					end
				end
				return raw(self, ...)
			end
			return raw(self, ...)
		end)

		if typeof(hookmetamethod) == "function" and typeof(getnamecallmethod) == "function" then
			local prev = nil
			local ok = pcall(function()
				prev = hookmetamethod(game, "__namecall", nc_hook)
			end)
			if ok and typeof(prev) == "function" then
				if not slot.RawNC then slot.RawNC = prev end
				slot.OldNC = slot.RawNC
				slot.Installed = true
				slot.Version = 2
			end
		elseif typeof(getrawmetatable) == "function" and typeof(setreadonly) == "function" and typeof(getnamecallmethod) == "function" then
			local prev = nil
			local ok = pcall(function()
				local mt = getrawmetatable(game)
				prev = mt.__namecall
				setreadonly(mt, false)
				mt.__namecall = nc_hook
				setreadonly(mt, true)
			end)
			if ok and typeof(prev) == "function" then
				if not slot.RawNC then slot.RawNC = prev end
				slot.OldNC = slot.RawNC
				slot.Installed = true
				slot.Version = 2
			end
		end
	end

	-- 3) hookfunction fallback when neither hookmetamethod nor getrawmetatable worked
	if not slot.Installed and typeof(hookfunction) == "function" then
		pcall(function()
			local wrap = typeof(newcclosure) == "function" and newcclosure or function(f) return f end
			local r_ev = Instance.new("RemoteEvent")
			local old_fs
			old_fs = hookfunction(r_ev.FireServer, wrap(function(self, ...)
				if slot.Active and not S.Destroyed and typeof(self) == "Instance" and self.Name == "TryShoot" and (not checkcaller or not checkcaller()) then
					local par = self.Parent
					if par and par.Name == "GunService" then
						local h = slot.Handler
						if h then h("Remote", self, "FireServer", old_fs, ...) end
					end
				end
				return old_fs(self, ...)
			end))
			r_ev:Destroy()
			slot.Installed = true
			slot.HookFnMode = true
			slot.Version = 2
		end)
	end

	S.SilentHooked = slot.Installed or slot.DynInstalled
	if slot.Installed and slot.DynInstalled then
		S.SilentHookMsg = slot.HookFnMode and "HF + DynCast" or "NC + DynCast"
	elseif slot.Installed then
		S.SilentHookMsg = slot.HookFnMode and "Hooked HF" or "Hooked NC"
	elseif slot.DynInstalled then
		S.SilentHookMsg = "DynCast Only"
	else
		S.SilentHookMsg = "Unsupported"
	end
end

local function hide_silent_visuals()
	SilentD.FOVOut.Visible, SilentD.FOV.Visible, SilentD.SnapOut.Visible, SilentD.Snap.Visible, SilentD.DotOut.Visible, SilentD.Dot.Visible = false, false, false, false, false, false
end

has_open_los = function(cam, orig, part, mdl)
	if not can_see(cam, orig, part, mdl) then return false end
	local back = orig - part.Position
	if back.Magnitude < 0.05 then return true end
	local f = {}; if LP.Character then table.insert(f, LP.Character) end
	if cam then table.insert(f, cam) end
	if mdl then table.insert(f, mdl) end
	-- Reverse bullet ray rejects origins placed inside solid walls while skipping pierceable glass/doors
	return bullet_raycast(part.Position, back, f, nil) == nil
end

local wb_cache = { Part = nil, Base = nil, TgtPos = nil, Pos = nil, T = 0 }
find_wallbang_muzzle = function(cam, part, mdl)
	local my_ch = LP and LP.Character
	local my_hd = my_ch and (my_ch:FindFirstChild("Head") or my_ch:FindFirstChild("HumanoidRootPart"))
	local base = (my_hd and my_hd:IsA("BasePart")) and my_hd.Position or cam.CFrame.Position
	if has_open_los(cam, base, part, mdl) then
		local chest = base - Vector3.new(0, 1.35, 0)
		wb_cache.Part = nil
		if has_open_los(cam, chest, part, mdl) then return nil end
		return base
	end
	local now = os.clock()
	if wb_cache.Part == part and wb_cache.Pos and (now - wb_cache.T) < 0.05
		and (base - wb_cache.Base).Magnitude < 0.5 and (part.Position - wb_cache.TgtPos).Magnitude < 0.5
		and has_open_los(cam, wb_cache.Pos, part, mdl) then
		return wb_cache.Pos
	end
	local to_tgt = part.Position - base
	local dist = to_tgt.Magnitude
	if dist < 0.5 then return nil end
	local fwd = to_tgt / dist
	local up = Vector3.new(0, 1, 0)
	local flat = Vector3.new(fwd.X, 0, fwd.Z)
	local right = (flat.Magnitude > 0.05) and flat.Unit:Cross(up).Unit or cam.CFrame.RightVector
	local dirs = {
		up,
		right, -right,
		fwd,
		(up + right).Unit, (up - right).Unit,
		(up + fwd).Unit,
		(fwd + right).Unit, (fwd - right).Unit,
	}
	if part.Position.Y < base.Y + 1 then table.insert(dirs, -up) end

	-- Pass 1: closest open origin around shooter (stays near player when peeking single/narrow cover)
	local found = nil
	for _, r in ipairs({ 2.0, 4.5, 8.0, 13.0, 19.0, 26.0 }) do
		if r < dist - 0.5 then
			for _, d in ipairs(dirs) do
				local probe = base + d * r
				if has_open_los(cam, probe, part, mdl) then found = probe; break end
			end
			if found then break end
		end
	end

	-- Pass 2a: reverse raycast from target toward shooter measures exact air gap past the last wall (solves 2+ walls)
	local tgt_filter = {}; if my_ch then table.insert(tgt_filter, my_ch) end
	if cam then table.insert(tgt_filter, cam) end
	if mdl then table.insert(tgt_filter, mdl) end
	if not found then
		local rev = bullet_raycast(part.Position, -fwd * dist, tgt_filter, nil)
		local gap = rev and rev.Distance or dist
		if gap >= 0.48 then
			for _, off_d in ipairs({ math.min(2.4, gap * 0.55), gap * 0.30, math.max(0.35, gap - 0.35) }) do
				if off_d < dist - 0.4 then
					local probe = part.Position - fwd * off_d
					if has_open_los(cam, probe, part, mdl) then found = probe; break end
				end
			end
		end
	end

	-- Pass 2b: outward clearance cage around target (handles target hugging wall #2 or low ceilings)
	if not found then
		local tgt_dirs = {
			up, right, -right, fwd,
			(-fwd + up).Unit, (up + right).Unit, (up - right).Unit,
			(fwd + right).Unit, (fwd - right).Unit,
			(-fwd + right).Unit, (-fwd - right).Unit,
			-up,
		}
		for _, td in ipairs(tgt_dirs) do
			local h = bullet_raycast(part.Position, td * 4.5, tgt_filter, nil)
			local probe = nil
			if not h then
				probe = part.Position + td * 2.4
			elseif h.Distance >= 0.52 then
				probe = part.Position + td * math.min(2.2, h.Distance * 0.65)
			end
			if probe and has_open_los(cam, probe, part, mdl) then found = probe; break end
		end
	end

	-- Pass 3: fine corridor march fallback
	if not found then
		for _, frac in ipairs({ 0.20, 0.35, 0.50, 0.65, 0.78, 0.88, 0.94 }) do
			if dist * frac > 1.2 and dist * (1 - frac) > 0.4 then
				local probe = base + fwd * (dist * frac)
				if has_open_los(cam, probe, part, mdl) then found = probe; break end
			end
		end
	end

	wb_cache.Part, wb_cache.Base, wb_cache.TgtPos, wb_cache.Pos, wb_cache.T = part, base, part.Position, found, now
	return found
end

resolve_tgt_wallbang = function(cam, tgt)
	tgt.WallbangChecked = true
	tgt.WallbangMuzzle = find_wallbang_muzzle(cam, tgt.Part, tgt.Model)
	if not tgt.WallbangMuzzle and tgt.Model and tgt.Part.Name ~= "HumanoidRootPart" then
		local my_ch = LP and LP.Character
		local my_hd = my_ch and (my_ch:FindFirstChild("Head") or my_ch:FindFirstChild("HumanoidRootPart"))
		local base = (my_hd and my_hd:IsA("BasePart")) and my_hd.Position or cam.CFrame.Position
		if not has_open_los(cam, base, tgt.Part, tgt.Model) then
			for _, alt_name in ipairs({ "UpperTorso", "Torso", "HumanoidRootPart" }) do
				local ap = tgt.Model:FindFirstChild(alt_name)
				if ap and ap:IsA("BasePart") and ap ~= tgt.Part then
					local wb = find_wallbang_muzzle(cam, ap, tgt.Model)
					if wb or has_open_los(cam, base, ap, tgt.Model) then
						tgt.Part = ap
						tgt.WallbangMuzzle = wb
						if tgt.IsNPC then tgt.NPCId = silent_npc_id(ap, tgt.Model) end
						break
					end
				end
			end
		end
	end
end

local function update_silent()
	sync_silent_slot()
	local cam = Workspace.CurrentCamera
	local sc = CFG.Silent
	if not sc.Enabled or not cam then
		S.SilentTgt = nil; hide_silent_visuals(); return
	end
	local ctr = silent_origin(cam)
	local sf = sc.ShowFOV
	SilentD.FOVOut.Visible, SilentD.FOV.Visible = sf, sf
	if sf then
		SilentD.FOVOut.Position, SilentD.FOVOut.Radius = ctr, sc.FOV
		SilentD.FOV.Position, SilentD.FOV.Radius, SilentD.FOV.Color = ctr, sc.FOV, sc.FOVColor
	end

	local tgt = find_silent_tgt(false)
	if tgt and tgt.Part and sc.MagicBullet then
		resolve_tgt_wallbang(cam, tgt)
	end
	S.SilentTgt = tgt
	if tgt and tgt.Part then
		local rsp, ron = cam:WorldToViewportPoint(tgt.Part.Position)
		local rfd = (Vector2.new(rsp.X, rsp.Y) - ctr).Magnitude
		if ron and rsp.Z > 0.2 and rfd <= (sc.FOV - 1) then
			local pos = resolve_silent_pos(cam.CFrame.Position, tgt.Part, tgt.Hum)
			local sp, on = cam:WorldToViewportPoint(pos)
			local pt = Vector2.new(sp.X, sp.Y)
			local fd = (pt - ctr).Magnitude
			if not (on and sp.Z > 0.2 and fd <= (sc.FOV - 1)) then
				sp, on, pt, fd = rsp, ron, Vector2.new(rsp.X, rsp.Y), rfd
			end
			local sl = sc.ShowSnapline and (fd >= 4)
			SilentD.SnapOut.Visible, SilentD.Snap.Visible = sl, sl
			if sl then
				SilentD.SnapOut.From, SilentD.SnapOut.To = ctr, pt
				SilentD.Snap.From, SilentD.Snap.To, SilentD.Snap.Color = ctr, pt, sc.FOVColor
			end
			local sd = sc.ShowTarget
			SilentD.DotOut.Visible, SilentD.Dot.Visible = sd, sd
			if sd then
				SilentD.DotOut.Position = pt
				SilentD.Dot.Position, SilentD.Dot.Color = pt, sc.FOVColor
			end
		else
			SilentD.SnapOut.Visible, SilentD.Snap.Visible, SilentD.DotOut.Visible, SilentD.Dot.Visible = false, false, false, false
		end
	else
		SilentD.SnapOut.Visible, SilentD.Snap.Visible, SilentD.DotOut.Visible, SilentD.Dot.Visible = false, false, false, false
	end
end

local function cleanup_silent()
	local g = getgenv and getgenv() or _G
	if g._OcelSilentSlot then
		g._OcelSilentSlot.Active = CFG.Tracers.Enabled and not S.Destroyed or false
		g._OcelSilentSlot.Handler = nil
		g._OcelSilentSlot.DynHandler = nil
	end
	for _, d in pairs(SilentD) do pcall(function() d:Remove() end) end
end

local function spawn_beam_tracer(from_p, to_p, clk)
	local ter = Workspace.Terrain
	if not ter then return end
	local col = CFG.Tracers.Rainbow and Color3.fromHSV((clk * 0.65) % 1, 0.9, 1) or CFG.Tracers.Color
	local w = CFG.Tracers.Thickness
	local a0 = Instance.new("Attachment"); a0.Name = "OcelTrA0"; a0.WorldPosition = from_p; a0.Parent = ter
	local a1 = Instance.new("Attachment"); a1.Name = "OcelTrA1"; a1.WorldPosition = to_p; a1.Parent = ter
	local bm = Instance.new("Beam")
	bm.Name = "OcelTracer"
	bm.Attachment0, bm.Attachment1 = a0, a1
	bm.FaceCamera = true
	bm.LightEmission = 1
	bm.LightInfluence = 0
	bm.Width0, bm.Width1 = w, w * 0.45
	bm.Segments = 1
	bm.Color = ColorSequence.new(col)
	bm.Transparency = NumberSequence.new(0.05)
	bm.Parent = ter
	table.insert(active_tracers, { A0 = a0, A1 = a1, Beam = bm, T0 = clk, Dur = math.max(CFG.Tracers.Duration, 0.1) })
end

local function update_tracers(clk)
	if #tracer_queue > 0 then
		if CFG.Tracers.Enabled then
			for i = 1, #tracer_queue do
				local item = tracer_queue[i]
				pcall(spawn_beam_tracer, item.From, item.To, clk)
			end
		end
		table.clear(tracer_queue)
	end
	for i = #active_tracers, 1, -1 do
		local tr = active_tracers[i]
		local elapsed = clk - tr.T0
		if elapsed >= tr.Dur or not tr.Beam.Parent then
			pcall(function() tr.Beam:Destroy() end)
			pcall(function() tr.A0:Destroy() end)
			pcall(function() tr.A1:Destroy() end)
			table.remove(active_tracers, i)
		elseif CFG.Tracers.Fade then
			local a = math.clamp(elapsed / tr.Dur, 0, 1)
			local t_val = a * a
			tr.Beam.Transparency = NumberSequence.new(math.min(0.05 + t_val * 0.95, 1))
			if CFG.Tracers.Rainbow then
				tr.Beam.Color = ColorSequence.new(Color3.fromHSV(((tr.T0 + elapsed) * 0.65) % 1, 0.9, 1))
			end
		end
	end
end

local function cleanup_tracers()
	table.clear(tracer_queue)
	for _, tr in ipairs(active_tracers) do
		pcall(function() tr.Beam:Destroy() end)
		pcall(function() tr.A0:Destroy() end)
		pcall(function() tr.A1:Destroy() end)
	end
	table.clear(active_tracers)
end

-- Multi-Style Chams (Players, Self, Arms, Weapon)
local CH = {
	OrigP = {}, OrigC = {}, OrigSA = {}, OrigSM = {}, OrigDT = {}, OrigBC = {},
	HLs = {}, Bxs = {}, Wrs = {}, Ads = {}, WLines = {},
	AP = {}, AH = {}, AB = {}, AW = {}, AAD = {}, AC = {}, ASA = {}, ASM = {}, ADT = {}, ABC = {}, AWL = {},
	AF = nil, HF = nil, HC = nil,
}

local PART_PHASE = {
	Head = 0.0, UpperTorso = 0.7, Torso = 1.1, LowerTorso = 1.4,
	LeftUpperArm = 0.8, RightUpperArm = 0.8, LeftLowerArm = 1.5, RightLowerArm = 1.5,
	LeftHand = 2.1, RightHand = 2.1, ["Left Arm"] = 1.3, ["Right Arm"] = 1.3,
	LeftUpperLeg = 2.2, RightUpperLeg = 2.2, LeftLowerLeg = 2.9, RightLowerLeg = 2.9,
	LeftFoot = 3.5, RightFoot = 3.5, ["Left Leg"] = 2.5, ["Right Leg"] = 2.5,
}

local WIRE_SHAPES = (function()
	local function ring(n, y, rx, rz, ang_off)
		local out = {}
		for i = 0, n - 1 do
			local a = ang_off + (i / n) * math.pi * 2
			out[i + 1] = Vector3.new(math.cos(a) * rx, y, math.sin(a) * rz)
		end
		return out
	end
	-- Geodesic triangulated sphere for Head
	local sv = { Vector3.new(0, 0.5, 0), Vector3.new(0, -0.5, 0) }
	local se = {}
	for _, p in ipairs(ring(6, 0.25, 0.44, 0.44, 0)) do table.insert(sv, p) end
	for _, p in ipairs(ring(6, -0.25, 0.44, 0.44, math.pi / 6)) do table.insert(sv, p) end
	for i = 1, 6 do
		local nxt = (i % 6) + 1
		local u, l, u2, l2 = 2 + i, 8 + i, 2 + nxt, 8 + nxt
		table.insert(se, { 1, u }); table.insert(se, { u, u2 })
		table.insert(se, { u, l }); table.insert(se, { u2, l })
		table.insert(se, { l, l2 }); table.insert(se, { l, 2 })
	end
	-- Hexagonal triangulated torso cage
	local tv, te = {}, {}
	for _, p in ipairs(ring(6, 0.46, 0.48, 0.45, 0)) do table.insert(tv, p) end
	for _, p in ipairs(ring(6, -0.46, 0.42, 0.40, 0)) do table.insert(tv, p) end
	for i = 1, 6 do
		local nxt = (i % 6) + 1
		table.insert(te, { i, nxt }); table.insert(te, { 6 + i, 6 + nxt })
		table.insert(te, { i, 6 + i }); table.insert(te, { i, 6 + nxt })
	end
	-- Pentagonal tapered triangulated limb/weapon mesh
	local lv, le = {}, {}
	for _, p in ipairs(ring(5, 0.46, 0.46, 0.46, 0)) do table.insert(lv, p) end
	for _, p in ipairs(ring(5, -0.46, 0.36, 0.36, 0)) do table.insert(lv, p) end
	for i = 1, 5 do
		local nxt = (i % 5) + 1
		table.insert(le, { i, nxt }); table.insert(le, { 5 + i, 5 + nxt })
		table.insert(le, { i, 5 + i }); table.insert(le, { i, 5 + nxt })
	end
	-- Rectangular box wireframe for vehicle parts
	local bv = {
		Vector3.new(-0.49, -0.49, -0.49), Vector3.new(0.49, -0.49, -0.49), Vector3.new(0.49, -0.49, 0.49), Vector3.new(-0.49, -0.49, 0.49),
		Vector3.new(-0.49,  0.49, -0.49), Vector3.new(0.49,  0.49, -0.49), Vector3.new(0.49,  0.49, 0.49), Vector3.new(-0.49,  0.49, 0.49),
	}
	local be = {
		{ 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 1 },
		{ 5, 6 }, { 6, 7 }, { 7, 8 }, { 8, 5 },
		{ 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 },
	}
	return { Sphere = { V = sv, E = se }, Torso = { V = tv, E = te }, Limb = { V = lv, E = le }, Box = { V = bv, E = be } }
end)()

local function part_wire_shape(p, k)
	if k == "Car" then return WIRE_SHAPES.Box end
	if p.Name == "Head" or (p:IsA("Part") and p.Shape == Enum.PartType.Ball) then return WIRE_SHAPES.Sphere end
	if p.Name == "UpperTorso" or p.Name == "LowerTorso" or p.Name == "Torso" then return WIRE_SHAPES.Torso end
	return WIRE_SHAPES.Limb
end

local function ensure_cf()
	if not CH.AF or not CH.AF.Parent then CH.AF = ui("Folder", { Name = "OcelChamsAdornees" }, gui_root()) end
	local cam = Workspace.CurrentCamera
	if cam and (not CH.HF or CH.HC ~= cam or not CH.HF.Parent) then
		if CH.HF then pcall(function() CH.HF:Destroy() end) end
		CH.HF, CH.HC = ui("Folder", { Name = "OcelChamsHighlights" }, cam), cam
	end
end

local function restore_p(p)
	local s = CH.OrigP[p]; if not s then return end; CH.OrigP[p] = nil
	if p and p.Parent then pcall(function() p.Material, p.Color, p.Transparency, p.Reflectance, p.CastShadow = s.M, s.C, s.T, s.R, s.CS; if s.TID ~= nil and p:IsA("MeshPart") then p.TextureID = s.TID end end) end
end

local function restore_sm(sm)
	local s = CH.OrigSM[sm]; if not s then return end; CH.OrigSM[sm] = nil
	if sm and sm.Parent then pcall(function() sm.TextureId, sm.VertexColor = s.TID, s.VC end) end
end

local function restore_sa(sa)
	local par = CH.OrigSA[sa]; if not par then return end; CH.OrigSA[sa] = nil
	if sa and par.Parent then pcall(function() sa.Parent = par end) end
end

local function restore_bc(bc)
	local par = CH.OrigBC[bc]; if not par then return end; CH.OrigBC[bc] = nil
	if bc and par.Parent then pcall(function() bc.Parent = par end) end
end

local function restore_dt(d)
	local t = CH.OrigDT[d]; if t == nil then return end; CH.OrigDT[d] = nil
	if d and d.Parent then pcall(function() d.Transparency = t end) end
end

local function style_vis(cfg, clk, ov, phase)
	local b, t, stn = ov or cfg.Color, clk * CFG.Chams.FlowSpeed, cfg.Style
	local ph = phase or 1.4
	local c, oc, m, r, ft, ot = b, cfg.OutlineColor, Enum.Material.SmoothPlastic, 0, cfg.FillTransparency, cfg.OutlineTransparency
	local wr, flow, hl_ft, hl_oc = false, false, ft, oc

	if stn == "Wireframe" then
		m, ft, wr, hl_ft = Enum.Material.ForceField, math.clamp(math.max(ft, 0.85), 0.78, 0.95), true, 0.88
	elseif stn == "Glossy Flow" then
		local w = 0.5 + 0.5 * math.sin(t * 1.15 - ph * 1.05)
		local sh = w ^ 2
		r, flow = 0.22 + 0.14 * w, true
		c = b:Lerp(Color3.new(1, 1, 1), sh * 0.42)
		oc = oc:Lerp(b, w * 0.30)
		hl_ft = 1
	elseif stn == "Water Flow" then
		local w = 0.5 + 0.5 * math.sin(t * 1.35 - ph * 1.15)
		local deep = b:Lerp(Color3.fromRGB(6, 22, 44), 0.38)
		local crest = b:Lerp(Color3.fromRGB(160, 245, 255), 0.52)
		m, r, flow = Enum.Material.SmoothPlastic, 0.22, true
		c = w < 0.5 and deep:Lerp(b, w * 2) or b:Lerp(crest, (w - 0.5) * 2)
		oc = oc:Lerp(crest, w * 0.35)
		hl_ft = 1
	elseif stn == "ForceField" then
		m, r = Enum.Material.ForceField, 0
		c = b
		ft = math.clamp(math.max(ft, 0.76), 0.70, 0.90)
		hl_ft = math.clamp(math.max(ft, 0.84), 0.78, 0.92)
		hl_oc, ot = b:Lerp(Color3.new(1, 1, 1), 0.22), math.min(ot, 0.08)
	elseif stn == "Glass" then
		m, r = Enum.Material.SmoothPlastic, 0.28
		c = b:Lerp(Color3.fromRGB(220, 240, 255), 0.22)
		ft = math.clamp(math.max(ft, 0.50), 0.45, 0.85)
		hl_ft = math.clamp(math.max(ft, 0.62), 0.52, 0.88)
		hl_oc = oc:Lerp(Color3.new(1, 1, 1), 0.35)
	elseif stn == "Neon Pulse" then
		local p = 0.5 + 0.5 * math.sin(t * 1.45)
		m = Enum.Material.Neon
		c = b:Lerp(Color3.new(1, 1, 1), p * 0.24)
		ft = math.clamp(ft + (0.5 - p) * 0.14, 0.05, 0.88)
		hl_ft = ft
	elseif stn == "Rainbow Flow" then
		local h = (t * 0.12 - ph * 0.10) % 1
		m, flow = Enum.Material.Neon, true
		c, oc = Color3.fromHSV(h, 0.88, 1), Color3.fromHSV((h + 0.5) % 1, 0.88, 1)
		hl_ft, hl_oc = 1, oc
	end
	return { C = c, OC = oc, M = m, R = r, FT = ft, OT = ot, WR = wr, FLW = flow, HL_FT = hl_ft, HL_OC = hl_oc }
end

local function wire_box(p, c, lt, sc, str, tr)
	CH.AW[p] = true
	local sb = CH.Wrs[p]
	if not sb or not sb.Parent then sb = ui("SelectionBox", { Name = "OcelWire" }, CH.AF); CH.Wrs[p] = sb end
	sb.Adornee, sb.Color3, sb.LineThickness, sb.SurfaceColor3, sb.SurfaceTransparency, sb.Transparency = p, c, lt, sc, str, tr
end

local function adorn_part(p, c, tr, top)
	CH.AAD[p] = true
	local ad = CH.Ads[p]
	local need_sph = (p.Name == "Head" or (p:IsA("Part") and p.Shape == Enum.PartType.Ball))
	local cls = need_sph and "SphereHandleAdornment" or "BoxHandleAdornment"
	if not ad or not ad.Parent or ad.ClassName ~= cls then
		if ad then pcall(function() ad:Destroy() end) end
		ad = ui(cls, { Name = "OcelChamAdorn", ZIndex = 5 }, CH.AF)
		pcall(function() ad.Shading = Enum.AdornShading.Shaded end)
		CH.Ads[p] = ad
	end
	local t_tr = math.clamp(tr, 0.06, 0.94)
	if ad.Adornee ~= p then ad.Adornee = p end
	if ad.AlwaysOnTop ~= top then ad.AlwaysOnTop = top end
	if ad.Color3 ~= c then ad.Color3 = c end
	if math.abs(ad.Transparency - t_tr) > 0.005 then ad.Transparency = t_tr end
	if not ad.Visible then ad.Visible = true end
	if need_sph then
		local r = math.max(p.Size.X, p.Size.Y, p.Size.Z) * 0.54
		if math.abs(ad.Radius - r) > 0.005 then ad.Radius = r end
	else
		local sz = p.Size + Vector3.new(0.04, 0.04, 0.04)
		if (ad.Size - sz).Magnitude > 0.005 then ad.Size = sz end
	end
end

local function fill_part(p, v, keep_opaque)
	CH.AP[p] = true
	if not CH.OrigP[p] then
		local s = { M = p.Material, C = p.Color, T = p.Transparency, R = p.Reflectance, CS = p.CastShadow }
		if p:IsA("MeshPart") then s.TID = p.TextureID end
		CH.OrigP[p] = s
	end
	pcall(function()
		if p.Material ~= v.M then p.Material = v.M end
		if p.Color ~= v.C then p.Color = v.C end
		if math.abs(p.Reflectance - v.R) > 0.01 then p.Reflectance = v.R end
		if p.CastShadow ~= false then p.CastShadow = false end
		local t_tr = (not keep_opaque and v.FT > 0.02) and math.max(CH.OrigP[p].T, v.FT) or CH.OrigP[p].T
		if math.abs(p.Transparency - t_tr) > 0.005 then p.Transparency = t_tr end
		if CFG.Chams.StripTextures and p:IsA("MeshPart") and p.TextureID ~= "" then p.TextureID = "" end
	end)
	for _, ch_i in ipairs(p:GetChildren()) do
		if ch_i:IsA("SurfaceAppearance") then
			CH.ASA[ch_i] = true
			if not CH.OrigSA[ch_i] then CH.OrigSA[ch_i] = p end
			pcall(function() ch_i.Parent = nil end)
		elseif ch_i:IsA("SpecialMesh") then
			CH.ASM[ch_i] = true
			if not CH.OrigSM[ch_i] then CH.OrigSM[ch_i] = { TID = ch_i.TextureId, VC = ch_i.VertexColor } end
			pcall(function()
				if CFG.Chams.StripTextures and ch_i.TextureId ~= "" then ch_i.TextureId = "" end
				local vc = Vector3.new(v.C.R, v.C.G, v.C.B)
				if (ch_i.VertexColor - vc).Magnitude > 0.01 then ch_i.VertexColor = vc end
			end)
		elseif CFG.Chams.StripTextures and (ch_i:IsA("Decal") or ch_i:IsA("Texture")) then
			CH.ADT[ch_i] = true
			if CH.OrigDT[ch_i] == nil then CH.OrigDT[ch_i] = ch_i.Transparency end
			if ch_i.Transparency < 1 then pcall(function() ch_i.Transparency = 1 end) end
		end
	end
end

local function box_part(p, v, top, hitbox_only)
	CH.AB[p] = true
	local pk = CH.Bxs[p]
	if not pk or not pk.B.Parent then
		pk = { B = ui("BoxHandleAdornment", { Name = "OcelBox", ZIndex = 5 }, CH.AF), W = ui("SelectionBox", { Name = "OcelBoxEdge" }, CH.AF) }
		CH.Bxs[p] = pk
	end
	if hitbox_only then
		pk.B.Adornee, pk.B.Size, pk.B.AlwaysOnTop, pk.B.Color3 = p, p.Size + Vector3.new(0.03, 0.03, 0.03), top, v.C
		pk.B.Transparency, pk.B.Visible = math.clamp(math.max(v.FT, 0.72), 0.55, 0.94), true
		pk.W.Adornee, pk.W.Color3, pk.W.LineThickness = p, v.C, 0.024
		pk.W.SurfaceColor3, pk.W.SurfaceTransparency, pk.W.Transparency = v.C, math.clamp(math.max(v.FT, 0.84), 0.72, 0.98), math.clamp(v.OT, 0, 0.75)
	else
		pk.B.Adornee, pk.B.Size, pk.B.AlwaysOnTop, pk.B.Color3 = p, p.Size + Vector3.new(0.04, 0.04, 0.04), top, v.C
		pk.B.Transparency, pk.B.Visible = math.clamp(v.FT, 0.08, 0.92), true
		if v.OT < 0.99 then
			pk.W.Adornee, pk.W.Color3, pk.W.LineThickness = p, v.OC, 0.015
			pk.W.SurfaceColor3, pk.W.SurfaceTransparency, pk.W.Transparency = v.C, 1, v.OT
		else pk.W.Adornee = nil end
	end
end

local function hl_apply(k, ad, ft, fc, ot, oc, top)
	if not CH.HF then return end
	CH.AH[k] = true
	local h = CH.HLs[k]; if not h or not h.Parent then h = ui("Highlight", { Name = "OcelHL" }, CH.HF); CH.HLs[k] = h end
	local dm = top and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
	if h.Adornee ~= ad then h.Adornee = ad end
	if h.DepthMode ~= dm then h.DepthMode = dm end
	if math.abs(h.FillTransparency - ft) > 0.005 then h.FillTransparency = ft end
	if h.FillColor ~= fc then h.FillColor = fc end
	if math.abs(h.OutlineTransparency - ot) > 0.005 then h.OutlineTransparency = ot end
	if h.OutlineColor ~= oc then h.OutlineColor = oc end
	if not h.Enabled then h.Enabled = true end
end

local function strip_cl(ch)
	if not CFG.Chams.StripTextures then return end
	for _, c in ipairs(ch:GetChildren()) do
		if c:IsA("Shirt") or c:IsA("Pants") or c:IsA("ShirtGraphic") then
			CH.AC[c] = true
			if not CH.OrigC[c] then
				CH.OrigC[c] = { Sh = c:IsA("Shirt") and c.ShirtTemplate or nil, Pa = c:IsA("Pants") and c.PantsTemplate or nil, Gr = c:IsA("ShirtGraphic") and c.Graphic or nil }
				pcall(function() if c:IsA("Shirt") then c.ShirtTemplate = "" end; if c:IsA("Pants") then c.PantsTemplate = "" end; if c:IsA("ShirtGraphic") then c.Graphic = "" end end)
			end
		elseif c:IsA("BodyColors") then
			CH.ABC[c] = true
			if not CH.OrigBC[c] then CH.OrigBC[c] = ch end
			pcall(function() c.Parent = nil end)
		elseif c:IsA("SurfaceAppearance") then
			CH.ASA[c] = true
			if not CH.OrigSA[c] then CH.OrigSA[c] = ch end
			pcall(function() c.Parent = nil end)
		end
	end
end

local function vpart(i)
	return i:IsA("BasePart") and i.Name ~= "HumanoidRootPart" and i.Name ~= "FakeCamera" and i:GetAttribute("OcelIgnore") ~= true
end

local function part_vis(p)
	return p and p.Parent and p.Transparency < 0.98 and p.LocalTransparencyModifier < 0.98
end

local function vpart_car(p)
	if not p:IsA("BasePart") or p:GetAttribute("OcelIgnore") == true then return false end
	if p.Name == "Root" or p.Name == "Collider" or p.Name == "Hitbox" or p.Name == "HumanoidRootPart" or p.Name == "FakeCamera" then return false end
	if p:IsA("Seat") or p:IsA("VehicleSeat") then return false end
	local par = p.Parent
	if par and (par.Name == "Colliders" or par.Name == "Hitboxes") then return false end
	if p:FindFirstChild("LightAttachment") then return false end
	local orig = CH.OrigP[p]
	return (orig and orig.T < 0.98) or (p.Parent ~= nil and p.Transparency < 0.98)
end

local function is_vehicle_model(m)
	if not m or not m:IsA("Model") then return false end
	if CollectionService:HasTag(m, "Vehicle") then return true end
	local vid = m:GetAttribute("VehicleId")
	if typeof(vid) == "string" and vid ~= "" then return true end
	local par = m.Parent
	if par and par.Name == "Vehicles" and par.Parent == Workspace and m:FindFirstChild("Body") ~= nil then return true end
	return false
end

local function find_own_car(ch)
	local uid = LP.UserId
	for _, m in ipairs(CollectionService:GetTagged("Vehicle")) do
		if m:IsA("Model") and m:IsDescendantOf(Workspace) then
			if m:GetAttribute("OwnerUserId") == uid or m:GetAttribute("SpawnerOwnerUserId") == uid then return m end
		end
	end
	local vf = Workspace:FindFirstChild("Vehicles")
	if vf then
		for _, m in ipairs(vf:GetChildren()) do
			if m:IsA("Model") and (m:GetAttribute("OwnerUserId") == uid or m:GetAttribute("SpawnerOwnerUserId") == uid) then return m end
		end
	end
	if ch then
		local hum = ch:FindFirstChildOfClass("Humanoid")
		local seat = hum and hum.SeatPart
		if seat then
			local cur = seat.Parent
			while cur and cur ~= Workspace do
				if is_vehicle_model(cur) then return cur end
				cur = cur.Parent
			end
		end
	end
	return nil
end

local function draw_wire_mesh(k, pts, mdl, cfg, clk, ov)
	local cam = Workspace.CurrentCamera
	if not cam then return end
	CH.AWL[k] = true
	local pool = CH.WLines[k]
	if not pool then pool = {}; CH.WLines[k] = pool end
	local idx, cpos = 0, cam.CFrame.Position
	local thk = CFG.Chams.WireframeThickness or 1.2
	local v = style_vis(cfg, clk, ov, 1.4)
	local lcol, ltr = v.C, math.clamp(1 - v.OT * 0.45, 0.55, 1)

	for _, p in ipairs(pts) do
		local sz = p.Size
		if part_vis(p) and math.max(sz.X, sz.Y, sz.Z) >= 0.28 then
			if cfg.AlwaysOnTop or can_see(cam, cpos, p, mdl or p) then
				local shp, cf = part_wire_shape(p, k), p.CFrame
				local proj, verts, edges = {}, shp.V, shp.E
				for vi = 1, #verts do
					local lv = verts[vi]
					local sp = cam:WorldToViewportPoint(cf:PointToWorldSpace(Vector3.new(lv.X * sz.X, lv.Y * sz.Y, lv.Z * sz.Z)))
					if sp.Z > 0.05 then proj[vi] = Vector2.new(sp.X, sp.Y) end
				end
				for ei = 1, #edges do
					local e = edges[ei]
					local p1, p2 = proj[e[1]], proj[e[2]]
					if p1 and p2 then
						idx = idx + 1
						local ln = pool[idx]
						if not ln then
							ln = drw("Line", { Visible = false, ZIndex = 2 })
							pool[idx] = ln
						end
						ln.From, ln.To, ln.Color, ln.Thickness, ln.Transparency, ln.Visible = p1, p2, lcol, thk, ltr, true
					end
				end
			end
		end
	end
	for i = idx + 1, #pool do pool[i].Visible = false end
end

local function proc_grp(k, pts, mdl, cfg, clk, ov, bdg, dist)
	local m, is_wpn, is_car = cfg.Mode, (k == "Weapon"), (k == "Car")
	if m == "Hitboxes" or m == "Boxes" then
		local v = style_vis(cfg, clk, ov, 1.4)
		for _, p in ipairs(pts) do
			if is_car or part_vis(p) then
				local pv = v.FLW and style_vis(cfg, clk, ov, PART_PHASE[p.Name] or 1.6) or v
				box_part(p, pv, cfg.AlwaysOnTop, m == "Hitboxes")
			end
		end
		return bdg
	end

	local fl = (m == "Fill" or m == "Outline + Fill")
	local out = (m == "Outline" or m == "Outline + Fill")
	local v = style_vis(cfg, clk, ov, 1.4)

	-- Car chams: never mutate BaseParts alongside Highlight (prevents Highlight cache rebuild flicker)
	if is_car then
		if fl and v.WR then
			if not dist or dist <= 650 then draw_wire_mesh(k, pts, mdl, cfg, clk, ov) end
			return bdg
		end
		local use_hl = out or (fl and (cfg.AlwaysOnTop or cfg.Style == "ForceField"))
		if use_hl and mdl and bdg > 0 then
			local hl_ft = fl and math.clamp(v.FT, 0.08, 0.92) or 1
			local hl_ot = (out or cfg.Style == "ForceField") and v.OT or 1
			hl_apply(k, mdl, hl_ft, v.C, hl_ot, cfg.OutlineColor, cfg.AlwaysOnTop)
			return bdg - 1
		end
		if fl then
			for _, p in ipairs(pts) do
				local ph = (p.Position.X + p.Position.Z) * 0.25
				local pv = v.FLW and style_vis(cfg, clk, ov, ph) or v
				fill_part(p, pv, true)
			end
		end
		return bdg
	end

	if fl then
		if v.WR then
			if not dist or dist <= 650 then draw_wire_mesh(k, pts, mdl, cfg, clk, ov) end
			if is_wpn then
				for _, p in ipairs(pts) do
					if part_vis(p) then fill_part(p, v, true) end
				end
			end
		elseif cfg.AlwaysOnTop and not is_wpn then
			if v.FLW or not mdl or bdg <= 0 then
				for _, p in ipairs(pts) do
					if part_vis(p) then
						local pv = v.FLW and style_vis(cfg, clk, ov, PART_PHASE[p.Name] or 1.6) or v
						adorn_part(p, pv.C, pv.FT, true)
					end
				end
			end
		else
			if mdl then strip_cl(mdl) end
			for i, p in ipairs(pts) do
				if part_vis(p) then
					local ph = PART_PHASE[p.Name] or (is_wpn and ((i % 6) * 0.55) or 1.6)
					local pv = v.FLW and style_vis(cfg, clk, ov, ph) or v
					fill_part(p, pv, is_wpn)
				end
			end
		end
	end

	local want_hl = out or (not is_wpn and fl and (cfg.AlwaysOnTop or cfg.Style == "ForceField"))
	if want_hl then
		if mdl and bdg > 0 then
			local use_hl_fill = not is_wpn and fl and (v.WR or (cfg.AlwaysOnTop and not v.FLW) or cfg.Style == "ForceField")
			local hl_ft = use_hl_fill and v.HL_FT or 1
			local hl_ot = (out or (not is_wpn and cfg.Style == "ForceField")) and v.OT or 1
			hl_apply(k, mdl, hl_ft, v.C, hl_ot, v.HL_OC, cfg.AlwaysOnTop)
			return bdg - 1
		elseif out then
			for _, p in ipairs(pts) do
				if part_vis(p) then wire_box(p, v.OC, 0.015, v.C, 1, v.OT) end
			end
		end
	end
	return bdg
end

local function update_chams(clk)
	ensure_cf()
	table.clear(CH.AP); table.clear(CH.AH); table.clear(CH.AB); table.clear(CH.AW); table.clear(CH.AAD)
	table.clear(CH.AC); table.clear(CH.ASA); table.clear(CH.ASM); table.clear(CH.ADT); table.clear(CH.ABC); table.clear(CH.AWL)
	local bdg, ch = 28, LP.Character
	local sp, ap, wp_world, wp_vm, vms = {}, {}, {}, {}, {}
	local tool = ch and ch:FindFirstChildOfClass("Tool") or nil
	local vm_gun, arms_mdl = nil, nil

	if ch and ch.Parent then
		for _, c in ipairs(ch:GetChildren()) do
			if c:IsA("Tool") then
				for _, d in ipairs(c:GetDescendants()) do if vpart(d) and part_vis(d) then table.insert(wp_world, d) end end
			elseif c:IsA("Accessory") then
				for _, d in ipairs(c:GetDescendants()) do if vpart(d) and part_vis(d) then table.insert(sp, d) end end
			elseif vpart(c) and part_vis(c) then
				table.insert(ARMS[c.Name] and ap or sp, c)
			end
		end
	end
	local cam = Workspace.CurrentCamera
	if cam then
		for _, c in ipairs(cam:GetChildren()) do
			if c:IsA("Model") then
				local ha = false
				local ga = c:FindFirstChild("GeneratedArmVisuals")
				if ga then arms_mdl = ga end
				if tool and not vm_gun then
					local gm = c:FindFirstChild(tool.Name)
					if gm and gm:IsA("Model") then vm_gun = gm end
				end
				for _, d in ipairs(c:GetDescendants()) do
					if vpart(d) and part_vis(d) then
						if ARMS[d.Name] then
							ha = true; table.insert(ap, d)
						elseif d.Name ~= "Root" and d.Name ~= "Torso" and d.Name ~= "Head" then
							table.insert(wp_vm, d)
							if not vm_gun then
								local p_mdl = d:FindFirstAncestorOfClass("Model")
								if p_mdl and p_mdl ~= c and p_mdl ~= ga then vm_gun = p_mdl end
							end
						end
					end
				end
				if ha then table.insert(vms, c) end
			end
		end
	end
	if not CFG.Chams.Arms.Enabled and CFG.Chams.Self.Enabled and ch then
		for _, c in ipairs(ch:GetChildren()) do if vpart(c) and part_vis(c) and ARMS[c.Name] then table.insert(sp, c) end end
	end

	if CFG.Chams.Self.Enabled and ch and #sp > 0 then
		bdg = proc_grp("Self", sp, ch, CFG.Chams.Self, clk, nil, bdg, 0)
	end
	if CFG.Chams.Arms.Enabled and #ap > 0 then
		local amdl = arms_mdl or (not vm_gun and vms[1] or nil)
		bdg = proc_grp("Arms", ap, amdl, CFG.Chams.Arms, clk, nil, bdg, 0)
	end
	local wp = (#wp_vm > 0) and wp_vm or wp_world
	local w_mdl = (#wp_vm > 0) and (vm_gun or vms[1]) or tool
	if CFG.Chams.Weapon.Enabled and #wp > 0 then
		bdg = proc_grp("Weapon", wp, w_mdl, CFG.Chams.Weapon, clk, nil, bdg, 0)
	end
	if CFG.Chams.Car.Enabled then
		local car = find_own_car(ch)
		if car then
			local cp = {}
			for _, d in ipairs(car:GetDescendants()) do if vpart_car(d) then table.insert(cp, d) end end
			if #cp > 0 then
				local cdist = (car:GetPivot().Position - (cam and cam.CFrame.Position or Vector3.zero)).Magnitude
				bdg = proc_grp("Car", cp, car, CFG.Chams.Car, clk, nil, bdg, cdist)
			end
		end
	end
	if CFG.Chams.Players.Enabled then
		local pc, cp, list = CFG.Chams.Players, cam and cam.CFrame.Position or Vector3.zero, {}
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl ~= LP and not ignored(pl, pc.TeamCheck, CFG.ESP.IgnoreHearseHidden, CFG.ESP.IgnoreModeratorHidden) then
				local pch = pl.Character; local hum = pch and pch:FindFirstChildOfClass("Humanoid"); local rt = (hum and hum.RootPart) or (pch and pch:FindFirstChild("HumanoidRootPart"))
				if pch and pch.Parent and rt and alive(pch, hum) then
					local d = (rt.Position - cp).Magnitude; if d <= CFG.ESP.MaxDistance then table.insert(list, { Pl = pl, Ch = pch, D = d }) end
				end
			end
		end
		table.sort(list, function(a, b) return a.D < b.D end)
		for _, it in ipairs(list) do
			local pp = {}; for _, d in ipairs(it.Ch:GetDescendants()) do if vpart(d) then table.insert(pp, d) end end
			if #pp > 0 then
				bdg = proc_grp("P_" .. it.Pl.UserId, pp, it.Ch, pc, clk, pc.UseTeamColor and esp_col(it.Pl, it.Ch) or nil, bdg, it.D)
			end
		end
	end

	for p in pairs(CH.OrigP) do if not CH.AP[p] then restore_p(p) end end
	for sm in pairs(CH.OrigSM) do if not CH.ASM[sm] then restore_sm(sm) end end
	for sa in pairs(CH.OrigSA) do if not CH.ASA[sa] then restore_sa(sa) end end
	for bc in pairs(CH.OrigBC) do if not CH.ABC[bc] then restore_bc(bc) end end
	for d in pairs(CH.OrigDT) do if not CH.ADT[d] then restore_dt(d) end end
	for c, sv in pairs(CH.OrigC) do
		if not CH.AC[c] then CH.OrigC[c] = nil; if c and c.Parent then pcall(function() if sv.Sh ~= nil then c.ShirtTemplate = sv.Sh end; if sv.Pa ~= nil then c.PantsTemplate = sv.Pa end; if sv.Gr ~= nil then c.Graphic = sv.Gr end end) end end
	end
	for k, h in pairs(CH.HLs) do if not CH.AH[k] then CH.HLs[k] = nil; pcall(function() h:Destroy() end) end end
	for p, pk in pairs(CH.Bxs) do if not CH.AB[p] or not p.Parent then CH.Bxs[p] = nil; pcall(function() pk.B:Destroy(); pk.W:Destroy() end) end end
	for p, sb in pairs(CH.Wrs) do if not CH.AW[p] or not p.Parent then CH.Wrs[p] = nil; pcall(function() sb:Destroy() end) end end
	for p, ad in pairs(CH.Ads) do if not CH.AAD[p] or not p.Parent then CH.Ads[p] = nil; pcall(function() ad:Destroy() end) end end
	for k, pool in pairs(CH.WLines) do
		if not CH.AWL[k] then
			CH.WLines[k] = nil
			for i = 1, #pool do pcall(function() pool[i]:Remove() end) end
		end
	end
end

local function cleanup_chams()
	for p in pairs(CH.OrigP) do restore_p(p) end
	for sm in pairs(CH.OrigSM) do restore_sm(sm) end
	for sa in pairs(CH.OrigSA) do restore_sa(sa) end
	for bc in pairs(CH.OrigBC) do restore_bc(bc) end
	for d in pairs(CH.OrigDT) do restore_dt(d) end
	for c, sv in pairs(CH.OrigC) do if c and c.Parent then pcall(function() if sv.Sh ~= nil then c.ShirtTemplate = sv.Sh end; if sv.Pa ~= nil then c.PantsTemplate = sv.Pa end; if sv.Gr ~= nil then c.Graphic = sv.Gr end end) end end
	table.clear(CH.OrigC)
	for _, h in pairs(CH.HLs) do pcall(function() h:Destroy() end) end
	for _, pk in pairs(CH.Bxs) do pcall(function() pk.B:Destroy(); pk.W:Destroy() end) end
	for _, sb in pairs(CH.Wrs) do pcall(function() sb:Destroy() end) end
	for _, ad in pairs(CH.Ads) do pcall(function() ad:Destroy() end) end
	for _, pool in pairs(CH.WLines) do for i = 1, #pool do pcall(function() pool[i]:Remove() end) end end
	table.clear(CH.HLs); table.clear(CH.Bxs); table.clear(CH.Wrs); table.clear(CH.Ads); table.clear(CH.WLines)
	if CH.AF then pcall(function() CH.AF:Destroy() end) end; if CH.HF then pcall(function() CH.HF:Destroy() end) end
end

-- Build Ocel-Hub UI
local function set_open(o) CFG.Menu.Open = o; if UI.Main then UI.Main.Visible = o end end
local function upd_scale()
	if not UI.Scale then return end
	local cam = Workspace.CurrentCamera; local vp = cam and cam.ViewportSize or Vector2.new(800, 480)
	UI.Scale.Scale = math.clamp(math.min((vp.X - 24) / 430, (vp.Y - 24) / 310, 1), 0.68, 1) * CFG.Menu.UIScale
end
local function sw_tab(n)
	S.Tab = n
	for k, p in pairs(UI.Pages) do p.Visible = (k == n) end
	for k, b in pairs(UI.Tabs) do local a = (k == n); b.BackgroundColor3, b.TextColor3 = a and TH.Accent or TH.Card, a and TH.AccentTxt or TH.Muted end
	if S.Scroll then S.Scroll.CanvasPosition = Vector2.zero end
end
local function sw_cham(n)
	S.ChamTab = n
	for k, c in pairs(UI.CBox) do c.Visible = (k == n) end
	for k, b in pairs(UI.CBtns) do local a = (k == n); b.BackgroundColor3, b.TextColor3 = a and TH.Accent or TH.Panel, a and TH.AccentTxt or TH.Muted end
end

local function build_ui(destroy_fn)
	local sg = ui("ScreenGui", { Name = "OcelHubGui", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999999 }, gui_root())
	UI.Gui = sg; UI.Scale = ui("UIScale", { Scale = 1 }, sg)

	local tp = ui("TextButton", { Name = "OcelTogglePill", Size = UDim2.fromOffset(76, 30), Position = UDim2.fromOffset(14, 70), BackgroundColor3 = TH.Bg, BorderSizePixel = 0, AutoButtonColor = false, Text = "", Visible = CFG.Menu.ShowTogglePill }, sg)
	rc(tp, 15); st(tp, TH.Accent, 1.4, 0.15)
	rc(ui("Frame", { Size = UDim2.fromOffset(6, 6), Position = UDim2.fromOffset(11, 12), BackgroundColor3 = TH.Accent, BorderSizePixel = 0 }, tp), 3)
	ui("TextLabel", { Size = UDim2.new(1, -22, 1, 0), Position = UDim2.fromOffset(19, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "OCEL", TextSize = 11, TextColor3 = TH.Txt, TextXAlignment = Enum.TextXAlignment.Left }, tp)
	UI.TPill = tp; draggable(tp, tp, function() set_open(not CFG.Menu.Open) end)

	local ap = ui("TextButton", { Name = "OcelAimPill", Size = UDim2.fromOffset(82, 36), Position = UDim2.fromOffset(14, 112), BackgroundColor3 = TH.Bg, BorderSizePixel = 0, AutoButtonColor = false, Text = "", Visible = false }, sg)
	rc(ap, 18); UI.AStroke = st(ap, TH.BorderHi, 1.5, 0)
	UI.ALbl = ui("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "AIM", TextSize = 12, TextColor3 = TH.Txt }, ap)
	UI.APill = ap
	draggable(ap, ap, function() if CFG.Aim.Activation == "Button (Toggle)" then S.AimTog = not S.AimTog end end, function() if CFG.Aim.Activation == "Button (Hold)" then S.AimHold = true end end, function() S.AimHold = false end)

	local mn = ui("Frame", { Name = "MainWindow", Size = UDim2.fromOffset(420, 300), Position = UDim2.fromOffset(105, 30), BackgroundColor3 = TH.Bg, BackgroundTransparency = 0.04, BorderSizePixel = 0, Visible = CFG.Menu.Open }, sg)
	rc(mn, 10); st(mn, TH.BorderHi, 1.2, 0.35); UI.Main = mn

	local hdr = ui("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = TH.Panel, BorderSizePixel = 0 }, mn); rc(hdr, 10)
	ui("Frame", { Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -10), BackgroundColor3 = TH.Panel, BorderSizePixel = 0 }, hdr)
	ui("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = TH.Border, BorderSizePixel = 0 }, hdr)
	rc(ui("Frame", { Size = UDim2.fromOffset(7, 7), Position = UDim2.fromOffset(13, 16), BackgroundColor3 = TH.Accent, BorderSizePixel = 0 }, hdr), 4)
	ui("TextLabel", { Size = UDim2.fromOffset(160, 20), Position = UDim2.fromOffset(26, 9), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "OCEL-HUB", TextSize = 14, TextColor3 = TH.Txt, TextXAlignment = Enum.TextXAlignment.Left }, hdr)
	local bdg = ui("TextLabel", { Size = UDim2.fromOffset(82, 16), Position = UDim2.fromOffset(112, 11), BackgroundColor3 = TH.Card, BorderSizePixel = 0, Font = Enum.Font.GothamBold, Text = "SAN DIEGO", TextSize = 9, TextColor3 = TH.Muted }, hdr); rc(bdg, 4); st(bdg, TH.Border, 1, 0.4)
	local mb = ui("TextButton", { Size = UDim2.fromOffset(26, 24), Position = UDim2.new(1, -60, 0.5, -12), BackgroundColor3 = TH.Card, BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamBold, Text = "—", TextSize = 12, TextColor3 = TH.Txt }, hdr); rc(mb, 5); mb.Activated:Connect(function() set_open(false) end)
	local cb = ui("TextButton", { Size = UDim2.fromOffset(26, 24), Position = UDim2.new(1, -30, 0.5, -12), BackgroundColor3 = TH.Card, BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamBold, Text = "×", TextSize = 15, TextColor3 = TH.Txt }, hdr); rc(cb, 5); cb.Activated:Connect(destroy_fn)
	draggable(hdr, mn)

	local tbar = ui("Frame", { Size = UDim2.new(1, -16, 0, 30), Position = UDim2.fromOffset(8, 44), BackgroundTransparency = 1 }, mn)
	ui("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }, tbar)
	for _, tn in ipairs({ "AIM", "ESP", "CHAMS", "MISC" }) do
		local tb = ui("TextButton", { Size = UDim2.new(0.25, -5, 1, 0), BackgroundColor3 = TH.Card, BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamBold, Text = tn, TextSize = 11 }, tbar)
		rc(tb, 6); st(tb, TH.Border, 1, 0.45); UI.Tabs[tn] = tb; tb.Activated:Connect(function() sw_tab(tn) end)
	end

	local scr = ui("ScrollingFrame", { Size = UDim2.new(1, -16, 1, -86), Position = UDim2.fromOffset(8, 80), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = TH.Accent, ScrollBarImageTransparency = 0.35, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y }, mn)
	S.Scroll = scr
	local function mk_pg(n)
		local p = ui("Frame", { Name = n .. "Page", Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false }, scr)
		ui("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, p); ui("UIPadding", { PaddingBottom = UDim.new(0, 8) }, p); UI.Pages[n] = p; return p
	end

	local apg = mk_pg("AIM")
	hdr_lbl(apg, "Core Aimbot")
	tog(apg, "Enable Aimbot", function() return CFG.Aim.Enabled end, function(v) CFG.Aim.Enabled = v end)
	sel(apg, "Activation", { "Button (Toggle)", "Button (Hold)", "Always", "Shooting" }, function() return CFG.Aim.Activation end, function(v) CFG.Aim.Activation = v; S.AimTog, S.AimHold = false, false end)
	tog(apg, "Show Mobile [AIM] Pill", function() return CFG.Aim.ShowAimButton end, function(v) CFG.Aim.ShowAimButton = v end)
	sel(apg, "Aim Method", { "Camera", "Mouse" }, function() return CFG.Aim.Method end, function(v) CFG.Aim.Method = v end)
	sel(apg, "Target Bone", { "Head", "UpperTorso", "HumanoidRootPart", "Closest", "Dynamic" }, function() return CFG.Aim.TargetPart end, function(v) CFG.Aim.TargetPart = v end)
	sel(apg, "Priority", { "Crosshair", "Distance", "Lowest HP", "Hybrid" }, function() return CFG.Aim.Priority end, function(v) CFG.Aim.Priority = v end)
	hdr_lbl(apg, "Tuning & Prediction")
	sld(apg, "Smoothness", 0, 0.95, 0.05, "", function() return CFG.Aim.Smoothness end, function(v) CFG.Aim.Smoothness = v end)
	sld(apg, "Max Distance", 50, 2000, 25, "m", function() return CFG.Aim.MaxDistance end, function(v) CFG.Aim.MaxDistance = v end)
	tog(apg, "Velocity Prediction", function() return CFG.Aim.Prediction end, function(v) CFG.Aim.Prediction = v end)
	sld(apg, "Prediction Lead", 0.02, 0.30, 0.02, "s", function() return CFG.Aim.PredictionScale end, function(v) CFG.Aim.PredictionScale = v end)
	tog(apg, "Sticky Target Lock", function() return CFG.Aim.StickyTarget end, function(v) CFG.Aim.StickyTarget = v end)
	hdr_lbl(apg, "Checks & FOV Circle")
	tog(apg, "Wall Check (Visible Only)", function() return CFG.Aim.WallCheck end, function(v) CFG.Aim.WallCheck = v end)
	tog(apg, "Team Check", function() return CFG.Aim.TeamCheck end, function(v) CFG.Aim.TeamCheck = v end)
	tog(apg, "Ignore Hearse Hidden", function() return CFG.Aim.IgnoreHearseHidden end, function(v) CFG.Aim.IgnoreHearseHidden = v end)
	tog(apg, "Show FOV Circle", function() return CFG.Aim.ShowFOV end, function(v) CFG.Aim.ShowFOV = v end)
	sld(apg, "FOV Radius", 25, 420, 5, "px", function() return CFG.Aim.FOV end, function(v) CFG.Aim.FOV = v end)
	tog(apg, "FOV Filled", function() return CFG.Aim.FOVFilled end, function(v) CFG.Aim.FOVFilled = v end)
	tog(apg, "Target Snapline", function() return CFG.Aim.ShowSnapline end, function(v) CFG.Aim.ShowSnapline = v end)
	col_row(apg, "FOV Color", function() return CFG.Aim.FOVColor end, function(c) CFG.Aim.FOVColor = c end)

	hdr_lbl(apg, "Silent Aim (" .. S.SilentHookMsg .. ")")
	tog(apg, "Enable Silent Aim", function() return CFG.Silent.Enabled end, function(v) CFG.Silent.Enabled = v; sync_silent_slot() end)
	sel(apg, "Silent Method", { "Hybrid", "Raycast", "Remote" }, function() return CFG.Silent.Method end, function(v) CFG.Silent.Method = v end)
	sel(apg, "Silent Bone", { "Head", "UpperTorso", "HumanoidRootPart", "Closest", "Dynamic", "Random" }, function() return CFG.Silent.TargetPart end, function(v) CFG.Silent.TargetPart = v end)
	sel(apg, "Silent Priority", { "Crosshair", "Distance", "Lowest HP", "Hybrid" }, function() return CFG.Silent.Priority end, function(v) CFG.Silent.Priority = v end)
	sld(apg, "Hit Chance", 5, 100, 5, "%", function() return CFG.Silent.HitChance end, function(v) CFG.Silent.HitChance = v end)
	sld(apg, "Silent FOV", 25, 450, 5, "px", function() return CFG.Silent.FOV end, function(v) CFG.Silent.FOV = v end)
	sld(apg, "Silent Max Dist", 50, 2000, 25, "m", function() return CFG.Silent.MaxDistance end, function(v) CFG.Silent.MaxDistance = v end)
	tog(apg, "Silent Wall Check", function() return CFG.Silent.WallCheck end, function(v) CFG.Silent.WallCheck = v end)
	tog(apg, "Magic Bullet (Wallbang)", function() return CFG.Silent.MagicBullet end, function(v) CFG.Silent.MagicBullet = v end)
	tog(apg, "Silent Team Check", function() return CFG.Silent.TeamCheck end, function(v) CFG.Silent.TeamCheck = v end)
	tog(apg, "Ignore Hearse Hidden", function() return CFG.Silent.IgnoreHearseHidden end, function(v) CFG.Silent.IgnoreHearseHidden = v end)
	tog(apg, "Target NPC Bots", function() return CFG.Silent.TargetNPCs end, function(v) CFG.Silent.TargetNPCs = v end)
	sel(apg, "NPC Bot Filter", { "Border + Jewelry", "All NPCs", "Border Only", "Jewelry Only" }, function() return CFG.Silent.BotFilter end, function(v) CFG.Silent.BotFilter = v end)
	tog(apg, "Silent Prediction", function() return CFG.Silent.Prediction end, function(v) CFG.Silent.Prediction = v end)
	sld(apg, "Silent Pred Lead", 0.02, 0.30, 0.02, "s", function() return CFG.Silent.PredictionScale end, function(v) CFG.Silent.PredictionScale = v end)
	tog(apg, "Show Silent FOV", function() return CFG.Silent.ShowFOV end, function(v) CFG.Silent.ShowFOV = v end)
	tog(apg, "Show Silent Line (To Target)", function() return CFG.Silent.ShowSnapline end, function(v) CFG.Silent.ShowSnapline = v end)
	tog(apg, "Show Silent Target Dot", function() return CFG.Silent.ShowTarget end, function(v) CFG.Silent.ShowTarget = v end)
	col_row(apg, "Silent FOV Color", function() return CFG.Silent.FOVColor end, function(c) CFG.Silent.FOVColor = c end)

	hdr_lbl(apg, "Bullet Tracers")
	tog(apg, "Enable Bullet Tracers", function() return CFG.Tracers.Enabled end, function(v) CFG.Tracers.Enabled = v; sync_silent_slot() end)
	sld(apg, "Tracer Duration", 0.2, 3.0, 0.1, "s", function() return CFG.Tracers.Duration end, function(v) CFG.Tracers.Duration = v end)
	sld(apg, "Tracer Width", 0.05, 0.60, 0.05, "", function() return CFG.Tracers.Thickness end, function(v) CFG.Tracers.Thickness = v end)
	tog(apg, "Smooth Fade Out", function() return CFG.Tracers.Fade end, function(v) CFG.Tracers.Fade = v end)
	tog(apg, "Rainbow Tracers", function() return CFG.Tracers.Rainbow end, function(v) CFG.Tracers.Rainbow = v end)
	col_row(apg, "Tracer Color", function() return CFG.Tracers.Color end, function(c) CFG.Tracers.Color = c end)

	local epg = mk_pg("ESP")
	hdr_lbl(epg, "Master & Filters")
	tog(epg, "Enable ESP", function() return CFG.ESP.Enabled end, function(v) CFG.ESP.Enabled = v end)
	sld(epg, "Max Distance", 100, 2500, 50, "m", function() return CFG.ESP.MaxDistance end, function(v) CFG.ESP.MaxDistance = v end)
	tog(epg, "Team Check", function() return CFG.ESP.TeamCheck end, function(v) CFG.ESP.TeamCheck = v end)
	tog(epg, "Ignore Hearse Hidden", function() return CFG.ESP.IgnoreHearseHidden end, function(v) CFG.ESP.IgnoreHearseHidden = v end)
	tog(epg, "Ignore Moderator Hidden", function() return CFG.ESP.IgnoreModeratorHidden end, function(v) CFG.ESP.IgnoreModeratorHidden = v end)
	hdr_lbl(epg, "NPC Bots (Border / Jewelry)")
	tog(epg, "Bots ESP", function() return CFG.ESP.ShowBorderBots end, function(v) CFG.ESP.ShowBorderBots = v end)
	sel(epg, "Bot Filter", { "Border + Jewelry", "All NPCs", "Border Only", "Jewelry Only" }, function() return CFG.ESP.BotFilter end, function(v) CFG.ESP.BotFilter = v end)
	col_row(epg, "Border Bot Color", function() return CFG.ESP.ColorBorderBot end, function(c) CFG.ESP.ColorBorderBot = c end)
	col_row(epg, "Jewelry Bot Color", function() return CFG.ESP.ColorJewelryBot end, function(c) CFG.ESP.ColorJewelryBot = c end)
	hdr_lbl(epg, "Elements")
	tog(epg, "2D Box", function() return CFG.ESP.ShowBox end, function(v) CFG.ESP.ShowBox = v end)
	tog(epg, "Skeleton (R15 / R6)", function() return CFG.ESP.ShowSkeleton end, function(v) CFG.ESP.ShowSkeleton = v end)
	tog(epg, "Head Circle", function() return CFG.ESP.ShowHeadCircle end, function(v) CFG.ESP.ShowHeadCircle = v end)
	tog(epg, "Health Bar", function() return CFG.ESP.ShowHealthBar end, function(v) CFG.ESP.ShowHealthBar = v end)
	tog(epg, "Name & Status", function() return CFG.ESP.ShowName end, function(v) CFG.ESP.ShowName = v end)
	tog(epg, "Wanted Stars [W1-5]", function() return CFG.ESP.ShowWanted end, function(v) CFG.ESP.ShowWanted = v end)
	tog(epg, "Distance & Team Tag", function() return CFG.ESP.ShowDistance end, function(v) CFG.ESP.ShowDistance, CFG.ESP.ShowTeamTag = v, v end)
	tog(epg, "Tracers", function() return CFG.ESP.ShowTracers end, function(v) CFG.ESP.ShowTracers = v end)
	sel(epg, "Tracer Origin", { "Bottom", "Center", "Top" }, function() return CFG.ESP.TracerOrigin end, function(v) CFG.ESP.TracerOrigin = v end)
	tog(epg, "Use Team Colors", function() return CFG.ESP.ColorUseTeam end, function(v) CFG.ESP.ColorUseTeam = v end)
	tog(epg, "Wanted Red Override", function() return CFG.ESP.ColorWantedOverride end, function(v) CFG.ESP.ColorWantedOverride = v end)

	local cpg = mk_pg("CHAMS")
	hdr_lbl(cpg, "Global Chams Engine")
	sld(cpg, "Flow Animation Speed", 0.2, 5.0, 0.2, "x", function() return CFG.Chams.FlowSpeed end, function(v) CFG.Chams.FlowSpeed = v end)
	sld(cpg, "Wireframe Line Thickness", 0.5, 3.0, 0.1, "px", function() return CFG.Chams.WireframeThickness end, function(v) CFG.Chams.WireframeThickness = v end)
	tog(cpg, "Strip Clothes/Textures on Fill", function() return CFG.Chams.StripTextures end, function(v) CFG.Chams.StripTextures = v end)
	local sbar = ui("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 }, cpg)
	ui("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5) }, sbar)
	for _, cn in ipairs({ "Players", "Self", "Arms", "Weapon", "Car" }) do
		local cbtn = ui("TextButton", { Size = UDim2.new(0.2, -4, 1, 0), BackgroundColor3 = TH.Panel, BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamBold, Text = cn, TextSize = 11 }, sbar)
		rc(cbtn, 5); st(cbtn, TH.Border, 1, 0.45); UI.CBtns[cn] = cbtn; cbtn.Activated:Connect(function() sw_cham(cn) end)
		local hld = ui("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false }, cpg)
		ui("UIListLayout", { Padding = UDim.new(0, 6) }, hld)
		local cf = CFG.Chams[cn]
		hdr_lbl(hld, cn .. " Chams Settings")
		tog(hld, "Enable " .. cn .. " Chams", function() return cf.Enabled end, function(v) cf.Enabled = v end)
		sel(hld, "Render Mode", MODES, function() return cf.Mode end, function(v) cf.Mode = v end)
		sel(hld, "Material Style", STYLES, function() return cf.Style end, function(v) cf.Style = v end)
		sld(hld, "Fill Transparency", 0, 0.95, 0.05, "", function() return cf.FillTransparency end, function(v) cf.FillTransparency = v end)
		sld(hld, "Outline Transparency", 0, 1.0, 0.05, "", function() return cf.OutlineTransparency end, function(v) cf.OutlineTransparency = v end)
		tog(hld, "Through Walls (AlwaysOnTop)", function() return cf.AlwaysOnTop end, function(v) cf.AlwaysOnTop = v end)
		if cn == "Players" then
			tog(hld, "Team Check", function() return cf.TeamCheck end, function(v) cf.TeamCheck = v end)
			tog(hld, "Use Team/Wanted Color", function() return cf.UseTeamColor end, function(v) cf.UseTeamColor = v end)
		end
		col_row(hld, "Fill / Box Color", function() return cf.Color end, function(c) cf.Color = c end)
		col_row(hld, "Outline Color", function() return cf.OutlineColor end, function(c) cf.OutlineColor = c end)
		UI.CBox[cn] = hld
	end

	local mpg = mk_pg("MISC")
	hdr_lbl(mpg, "Custom Crosshair")
	tog(mpg, "Enable Crosshair", function() return CFG.Crosshair.Enabled end, function(v) CFG.Crosshair.Enabled = v end)
	sel(mpg, "Style", { "Cross", "T-Shape", "X-Cross", "Circle", "Dot" }, function() return CFG.Crosshair.Style end, function(v) CFG.Crosshair.Style = v end)
	sel(mpg, "Position", { "Auto", "Center", "Mouse" }, function() return CFG.Crosshair.Position end, function(v) CFG.Crosshair.Position = v end)
	sld(mpg, "Size", 2, 32, 1, "px", function() return CFG.Crosshair.Size end, function(v) CFG.Crosshair.Size = v end)
	sld(mpg, "Gap", 0, 20, 1, "px", function() return CFG.Crosshair.Gap end, function(v) CFG.Crosshair.Gap = v end)
	sld(mpg, "Thickness", 1, 6, 1, "px", function() return CFG.Crosshair.Thickness end, function(v) CFG.Crosshair.Thickness = v end)
	tog(mpg, "Center Dot", function() return CFG.Crosshair.CenterDot end, function(v) CFG.Crosshair.CenterDot = v end)
	tog(mpg, "Outline", function() return CFG.Crosshair.Outline end, function(v) CFG.Crosshair.Outline = v end)
	tog(mpg, "Spin", function() return CFG.Crosshair.Spin end, function(v) CFG.Crosshair.Spin = v end)
	sld(mpg, "Spin Speed", 0.5, 8.0, 0.5, "x", function() return CFG.Crosshair.SpinSpeed end, function(v) CFG.Crosshair.SpinSpeed = v end)
	tog(mpg, "Rainbow Color", function() return CFG.Crosshair.Rainbow end, function(v) CFG.Crosshair.Rainbow = v end)
	tog(mpg, "Hide Game Reticle", function() return CFG.Crosshair.HideGameReticle end, function(v) CFG.Crosshair.HideGameReticle = v end)
	col_row(mpg, "Crosshair Color", function() return CFG.Crosshair.Color end, function(c) CFG.Crosshair.Color = c end)
	col_row(mpg, "Outline Color", function() return CFG.Crosshair.OutlineColor end, function(c) CFG.Crosshair.OutlineColor = c end)
	hdr_lbl(mpg, "World Camera FOV")
	tog(mpg, "Override World FOV", function() return CFG.Camera.OverrideFOV end, function(v)
		CFG.Camera.OverrideFOV = v
		sync_world_fov(not v)
	end)
	sld(mpg, "World FOV", 30, 120, 1, "deg", function() return CFG.Camera.FOV end, function(v)
		CFG.Camera.FOV = v
		if CFG.Camera.OverrideFOV then sync_world_fov(false) end
	end)
	hdr_lbl(mpg, "Mobile & Interface")
	sld(mpg, "Menu Scale", 0.75, 1.30, 0.05, "x", function() return CFG.Menu.UIScale end, function(v) CFG.Menu.UIScale = v; upd_scale() end)
	tog(mpg, "Show [OCEL] Toggle Pill", function() return CFG.Menu.ShowTogglePill end, function(v) CFG.Menu.ShowTogglePill = v; if UI.TPill then UI.TPill.Visible = v end end)
	act_btn(mpg, "Reset Window Position", function()
		if UI.Main then UI.Main.Position = UDim2.fromOffset(105, 30) end
		if UI.TPill then UI.TPill.Position = UDim2.fromOffset(14, 70) end
		if UI.APill then UI.APill.Position = UDim2.fromOffset(14, 112) end
	end)
	act_btn(mpg, "Unload Ocel-Hub", destroy_fn)

	sw_tab(S.Tab); sw_cham(S.ChamTab); upd_scale()
end

-- Lifecycle & Runtime
local ctrl
local function destroy_all()
	if S.Destroyed then return end; S.Destroyed = true
	pcall(function() RunService:UnbindFromRenderStep("OcelHubAimPre") end)
	pcall(function() RunService:UnbindFromRenderStep("OcelHubAim") end)
	for _, c in ipairs(S.Conns) do pcall(function() c:Disconnect() end) end
	table.clear(S.Conns)
	for pl in pairs(ESP_E) do del_esp(pl) end
	for mdl in pairs(NPC_E) do del_npc_esp(mdl) end
	for _, d in pairs(AimD) do pcall(function() d:Remove() end) end
	cleanup_silent()
	cleanup_tracers()
	cleanup_crosshair()
	cleanup_chams()
	sync_world_fov(true)
	if UI.Gui then pcall(function() UI.Gui:Destroy() end) end
	if getgenv and getgenv().OcelHub == ctrl then getgenv().OcelHub = nil end
end
ctrl = { Config = CFG, Destroy = destroy_all, SetOpen = set_open }
if getgenv then getgenv().OcelHub = ctrl end

local function bind_npc_folder(nf)
	if not nf or not nf:IsA("Folder") then return end
	for _, c in ipairs(nf:GetChildren()) do add_npc_esp(c) end
	tc(nf.ChildAdded:Connect(add_npc_esp))
	tc(nf.ChildRemoved:Connect(del_npc_esp))
end

for _, pl in ipairs(Players:GetPlayers()) do if pl ~= LP then add_esp(pl) end end
tc(Players.PlayerAdded:Connect(function(pl) if pl ~= LP then add_esp(pl) end end))
tc(Players.PlayerRemoving:Connect(del_esp))
local npc_folder = Workspace:FindFirstChild("NPCs")
if npc_folder then bind_npc_folder(npc_folder) end
tc(Workspace.ChildAdded:Connect(function(c) if c.Name == "NPCs" then bind_npc_folder(c) end end))
tc(UserInputService.InputBegan:Connect(function(i, gp)
	if not gp and i.KeyCode == CFG.Menu.ToggleKey then set_open(not CFG.Menu.Open) end
	if i.UserInputType == Enum.UserInputType.MouseButton1 then S.FireHold = true end
end))
tc(UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then S.FireHold = false end end))
tc(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(upd_scale))

install_silent_hooks()
build_ui(destroy_all)
RunService:BindToRenderStep("OcelHubAimPre", Enum.RenderPriority.First.Value + 1, function(dt) if not S.Destroyed then update_aim_pre(dt) end end)
RunService:BindToRenderStep("OcelHubAim", Enum.RenderPriority.Camera.Value + 10, function() if not S.Destroyed then update_aim_post() end end)
tc(RunService.RenderStepped:Connect(function() if not S.Destroyed then sync_world_fov(false); update_aim_visuals(); local clk = os.clock(); update_esp(); update_chams(clk); update_crosshair(clk); update_silent(); update_tracers(clk) end end))