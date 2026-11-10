-- language: Luau, file: modules/ui.lua, target: Roblox (San Diego / Mobile & PC)
return function(ctx)
	local Players = ctx.Players
	local RunService = ctx.RunService
	local UserInputService = ctx.UserInputService
	local Workspace = ctx.Workspace
	local LP = ctx.LP
	local CFG = ctx.CFG
	local S = ctx.S
	local tc = ctx.tc
	local gui_root = ctx.gui_root
	local TH = ctx.TH
	local MODES = ctx.MODES
	local STYLES = ctx.STYLES
	local UI = ctx.UI
	local ui = ctx.ui
	local rc = ctx.rc
	local st = ctx.st
	local draggable = ctx.draggable
	local hdr_lbl = ctx.hdr_lbl
	local tog = ctx.tog
	local sld = ctx.sld
	local sel = ctx.sel
	local col_row = ctx.col_row
	local act_btn = ctx.act_btn
	local AimD = ctx.AimD
	local sync_world_fov = ctx.sync_world_fov
	local update_aim_pre = ctx.update_aim_pre
	local update_aim_post = ctx.update_aim_post
	local update_aim_visuals = ctx.update_aim_visuals
	local update_crosshair = ctx.update_crosshair
	local cleanup_crosshair = ctx.cleanup_crosshair
	local ESP_E = ctx.ESP_E
	local NPC_E = ctx.NPC_E
	local add_esp = ctx.add_esp
	local del_esp = ctx.del_esp
	local add_npc_esp = ctx.add_npc_esp
	local del_npc_esp = ctx.del_npc_esp
	local update_esp = ctx.update_esp
	local install_silent_hooks = ctx.install_silent_hooks
	local sync_silent_slot = ctx.sync_silent_slot
	local update_silent = ctx.update_silent
	local cleanup_silent = ctx.cleanup_silent
	local update_tracers = ctx.update_tracers
	local cleanup_tracers = ctx.cleanup_tracers
	local update_chams = ctx.update_chams
	local cleanup_chams = ctx.cleanup_chams
	local VIS = ctx.VIS
	local restore_all_world = ctx.restore_all_world
	local apply_world_preset = ctx.apply_world_preset
	local update_world = ctx.update_world
	local cleanup_world = ctx.cleanup_world

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
	for _, tn in ipairs({ "AIM", "ESP", "CHAMS", "WORLD", "MISC" }) do
		local tb = ui("TextButton", { Size = UDim2.new(0.2, -5, 1, 0), BackgroundColor3 = TH.Card, BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamBold, Text = tn, TextSize = 11 }, tbar)
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

	local wpg = mk_pg("WORLD")
	local wrefs, preset_ref = {}, nil
	local function wr(fn) table.insert(wrefs, fn); return fn end
	local function sync_wrefs() for _, fn in ipairs(wrefs) do pcall(fn) end end
	local function mark_custom()
		if CFG.Visuals.Preset ~= "Custom" then
			CFG.Visuals.Preset = "Custom"
			if preset_ref then preset_ref() end
		end
	end

	hdr_lbl(wpg, "World Visuals & Presets")
	wr(tog(wpg, "Enable World Visuals", function() return CFG.Visuals.Enabled end, function(v)
		CFG.Visuals.Enabled = v
		if not v and VIS.Orig then restore_all_world() end
	end))
	preset_ref = wr(sel(wpg, "Visual Preset", { "Custom", "Neon Night", "Blood Moon", "Arctic", "Synthwave", "Clear Day", "Fullbright" }, function() return CFG.Visuals.Preset end, function(v)
		if v == "Custom" then CFG.Visuals.Preset = "Custom"
		else apply_world_preset(v, wrefs) end
	end))
	wr(tog(wpg, "Rainbow World Cycle", function() return CFG.Visuals.RainbowWorld end, function(v) CFG.Visuals.RainbowWorld = v; mark_custom() end))
	wr(sld(wpg, "Rainbow Speed", 0.1, 3.0, 0.1, "x", function() return CFG.Visuals.RainbowSpeed end, function(v) CFG.Visuals.RainbowSpeed = v end))

	hdr_lbl(wpg, "Fog & Atmosphere")
	wr(tog(wpg, "No Fog (Clear View)", function() return CFG.Visuals.NoFog end, function(v) CFG.Visuals.NoFog = v; mark_custom() end))
	wr(tog(wpg, "Override Fog Color", function() return CFG.Visuals.FogOverride end, function(v) CFG.Visuals.FogOverride = v; mark_custom() end))
	wr(col_row(wpg, "Fog Color", function() return CFG.Visuals.FogColor end, function(c) CFG.Visuals.FogColor = c; mark_custom() end))
	wr(col_row(wpg, "Fog Decay / Horizon", function() return CFG.Visuals.FogDecayColor end, function(c) CFG.Visuals.FogDecayColor = c; mark_custom() end))
	wr(sld(wpg, "Atmosphere Density", 0, 0.90, 0.02, "", function() return CFG.Visuals.AtmosphereDensity end, function(v) CFG.Visuals.AtmosphereDensity = v; mark_custom() end))
	wr(sld(wpg, "Atmosphere Haze", 0, 10, 0.25, "", function() return CFG.Visuals.AtmosphereHaze end, function(v) CFG.Visuals.AtmosphereHaze = v; mark_custom() end))
	wr(sld(wpg, "Atmosphere Glare", 0, 5, 0.1, "", function() return CFG.Visuals.AtmosphereGlare end, function(v) CFG.Visuals.AtmosphereGlare = v; mark_custom() end))
	wr(sld(wpg, "Fog Start", 0, 500, 10, "m", function() return CFG.Visuals.FogStart end, function(v) CFG.Visuals.FogStart = v; mark_custom() end))
	wr(sld(wpg, "Fog End", 50, 3000, 25, "m", function() return CFG.Visuals.FogEnd end, function(v) CFG.Visuals.FogEnd = v; mark_custom() end))

	hdr_lbl(wpg, "World & Ambient Colors")
	wr(tog(wpg, "Override World Colors", function() return CFG.Visuals.WorldColorEnabled end, function(v) CFG.Visuals.WorldColorEnabled = v; mark_custom() end))
	wr(col_row(wpg, "Ambient Color (Shadows)", function() return CFG.Visuals.AmbientColor end, function(c) CFG.Visuals.AmbientColor = c; mark_custom() end))
	wr(col_row(wpg, "Outdoor Ambient (World)", function() return CFG.Visuals.OutdoorAmbientColor end, function(c) CFG.Visuals.OutdoorAmbientColor = c; mark_custom() end))
	wr(col_row(wpg, "ColorShift Top (Sun)", function() return CFG.Visuals.ColorShiftTop end, function(c) CFG.Visuals.ColorShiftTop = c; mark_custom() end))
	wr(col_row(wpg, "ColorShift Bottom (Ground)", function() return CFG.Visuals.ColorShiftBottom end, function(c) CFG.Visuals.ColorShiftBottom = c; mark_custom() end))

	hdr_lbl(wpg, "Screen World Tint & Grading")
	wr(tog(wpg, "Enable World Tint / CC", function() return CFG.Visuals.ColorTintEnabled end, function(v) CFG.Visuals.ColorTintEnabled = v; mark_custom() end))
	wr(col_row(wpg, "World Tint Color", function() return CFG.Visuals.WorldTintColor end, function(c) CFG.Visuals.WorldTintColor = c; mark_custom() end))
	wr(sld(wpg, "Saturation", -1.0, 2.0, 0.05, "", function() return CFG.Visuals.Saturation end, function(v) CFG.Visuals.Saturation = v; mark_custom() end))
	wr(sld(wpg, "Contrast", -0.8, 1.5, 0.05, "", function() return CFG.Visuals.Contrast end, function(v) CFG.Visuals.Contrast = v; mark_custom() end))
	wr(sld(wpg, "Tint Brightness", -0.5, 0.5, 0.02, "", function() return CFG.Visuals.CCBrightness end, function(v) CFG.Visuals.CCBrightness = v; mark_custom() end))

	hdr_lbl(wpg, "Lighting, Time & Sky")
	wr(tog(wpg, "Fullbright", function() return CFG.Visuals.Fullbright end, function(v) CFG.Visuals.Fullbright = v; mark_custom() end))
	wr(tog(wpg, "Disable Global Shadows", function() return CFG.Visuals.DisableShadows end, function(v) CFG.Visuals.DisableShadows = v; mark_custom() end))
	wr(tog(wpg, "Override Time of Day", function() return CFG.Visuals.TimeOverride end, function(v) CFG.Visuals.TimeOverride = v; mark_custom() end))
	wr(sld(wpg, "Clock Time", 0, 24, 0.25, "h", function() return CFG.Visuals.ClockTime end, function(v) CFG.Visuals.ClockTime = v; mark_custom() end))
	wr(tog(wpg, "Override Brightness", function() return CFG.Visuals.BrightnessOverride end, function(v) CFG.Visuals.BrightnessOverride = v; mark_custom() end))
	wr(sld(wpg, "Brightness", 0, 10, 0.2, "", function() return CFG.Visuals.Brightness end, function(v) CFG.Visuals.Brightness = v; mark_custom() end))
	wr(sld(wpg, "Exposure", -3.0, 3.0, 0.1, "", function() return CFG.Visuals.Exposure end, function(v) CFG.Visuals.Exposure = v; mark_custom() end))
	wr(sel(wpg, "Sky Mode", { "Default", "Pure Black", "Starfield", "Procedural" }, function() return CFG.Visuals.SkyMode end, function(v) CFG.Visuals.SkyMode = v; mark_custom() end))
	wr(tog(wpg, "Hide Clouds", function() return CFG.Visuals.HideClouds end, function(v) CFG.Visuals.HideClouds = v; mark_custom() end))

	hdr_lbl(wpg, "Water & Post Effects")
	wr(tog(wpg, "Override Water Color", function() return CFG.Visuals.WaterOverride end, function(v) CFG.Visuals.WaterOverride = v; mark_custom() end))
	wr(col_row(wpg, "Water Color", function() return CFG.Visuals.WaterColor end, function(c) CFG.Visuals.WaterColor = c; mark_custom() end))
	wr(tog(wpg, "Disable Blur & DoF", function() return CFG.Visuals.DisableBlur end, function(v) CFG.Visuals.DisableBlur = v; mark_custom() end))
	wr(tog(wpg, "Override Bloom", function() return CFG.Visuals.BloomOverride end, function(v) CFG.Visuals.BloomOverride = v; mark_custom() end))
	wr(sld(wpg, "Bloom Intensity", 0, 3.0, 0.05, "", function() return CFG.Visuals.BloomIntensity end, function(v) CFG.Visuals.BloomIntensity = v; mark_custom() end))
	wr(sld(wpg, "Bloom Size", 0, 56, 2, "px", function() return CFG.Visuals.BloomSize end, function(v) CFG.Visuals.BloomSize = v; mark_custom() end))
	wr(sld(wpg, "Bloom Threshold", 0.5, 2.5, 0.05, "", function() return CFG.Visuals.BloomThreshold end, function(v) CFG.Visuals.BloomThreshold = v; mark_custom() end))
	act_btn(wpg, "Restore Game Visuals", function()
		local v = CFG.Visuals
		v.Enabled = false; v.Preset = "Custom"; v.FogOverride = false; v.NoFog = false
		v.WorldColorEnabled = false; v.ColorTintEnabled = false; v.Fullbright = false
		v.TimeOverride = false; v.BrightnessOverride = false; v.DisableShadows = false
		v.SkyMode = "Default"; v.HideClouds = false; v.WaterOverride = false
		v.DisableBlur = false; v.BloomOverride = false; v.RainbowWorld = false
		restore_all_world()
		sync_wrefs()
	end)

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
	cleanup_world()
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
tc(RunService.RenderStepped:Connect(function() if not S.Destroyed then sync_world_fov(false); update_aim_visuals(); local clk = os.clock(); update_esp(); update_chams(clk); update_crosshair(clk); update_silent(); update_tracers(clk); update_world(clk) end end))


end