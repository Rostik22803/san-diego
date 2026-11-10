-- language: Luau, file: san_diego_visuals.lua, target: Roblox (San Diego / Mobile & PC)
-- Standalone World & Atmosphere Visuals: Fog Color, Atmosphere, World/Ambient Colors, ColorCorrection Tint, Fullbright, Sky, Water, Bloom, Blur Removal
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer

if getgenv and getgenv().SanDiegoVisuals then
	pcall(function() getgenv().SanDiegoVisuals:Destroy() end)
end

local CFG = {
	Menu = { Open = true, ToggleKey = Enum.KeyCode.F4, ShowTogglePill = true, UIScale = 1.0 },
	Visuals = {
		Enabled = true,
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

local S = { Destroyed = false, Conns = {}, Scroll = nil }
local function tc(c) if c then table.insert(S.Conns, c) end return c end
local function gui_root()
	if typeof(gethui) == "function" then local ok, h = pcall(gethui); if ok and h then return h end end
	if pcall(function() return CoreGui.Name end) then return CoreGui end
	return LP:WaitForChild("PlayerGui")
end

-- World & Atmosphere Engine
local VIS = {
	Orig = nil, OrigAtm = nil, AtmRef = nil, OrigBloom = nil, BloomRef = nil,
	OrigBlurs = {}, OrigClouds = nil, CloudsRef = nil, OrigWaterColor = nil, OrigSky = nil,
	CCObj = nil, BloomObj = nil, SkyObj = nil, LastSkyMode = "Default",
	Dirty = { Fog = false, World = false, Time = false, Bright = false, Shadows = false, Water = false, Clouds = false, Bloom = false, Blur = false, Sky = false, Tint = false },
}

local VIS_PRESETS = {
	["Neon Night"] = {
		FogOverride = true, NoFog = false, FogColor = Color3.fromRGB(95, 45, 195), FogDecayColor = Color3.fromRGB(30, 145, 225),
		FogStart = 0, FogEnd = 520, AtmosphereDensity = 0.42, AtmosphereHaze = 2.6, AtmosphereGlare = 0.35,
		WorldColorEnabled = true, AmbientColor = Color3.fromRGB(55, 45, 115), OutdoorAmbientColor = Color3.fromRGB(85, 110, 185),
		ColorShiftTop = Color3.fromRGB(145, 95, 255), ColorShiftBottom = Color3.fromRGB(35, 190, 255),
		ColorTintEnabled = true, WorldTintColor = Color3.fromRGB(235, 225, 255), Saturation = 0.35, Contrast = 0.14, CCBrightness = 0.02,
		TimeOverride = true, ClockTime = 23.0, BrightnessOverride = true, Brightness = 2.2, Exposure = 0.15,
		Fullbright = false, DisableShadows = false, SkyMode = "Starfield", HideClouds = false,
		BloomOverride = true, BloomIntensity = 1.15, BloomSize = 28, BloomThreshold = 0.95, DisableBlur = true,
		WaterOverride = true, WaterColor = Color3.fromRGB(35, 95, 195),
	},
	["Blood Moon"] = {
		FogOverride = true, NoFog = false, FogColor = Color3.fromRGB(165, 28, 42), FogDecayColor = Color3.fromRGB(90, 12, 24),
		FogStart = 0, FogEnd = 420, AtmosphereDensity = 0.48, AtmosphereHaze = 3.2, AtmosphereGlare = 0.45,
		WorldColorEnabled = true, AmbientColor = Color3.fromRGB(105, 28, 35), OutdoorAmbientColor = Color3.fromRGB(135, 42, 52),
		ColorShiftTop = Color3.fromRGB(255, 70, 75), ColorShiftBottom = Color3.fromRGB(70, 15, 22),
		ColorTintEnabled = true, WorldTintColor = Color3.fromRGB(255, 200, 205), Saturation = 0.2, Contrast = 0.18, CCBrightness = 0.0,
		TimeOverride = true, ClockTime = 0.5, BrightnessOverride = true, Brightness = 2.0, Exposure = 0.1,
		Fullbright = false, DisableShadows = false, SkyMode = "Starfield", HideClouds = true,
		BloomOverride = true, BloomIntensity = 0.9, BloomSize = 24, BloomThreshold = 1.0, DisableBlur = true,
		WaterOverride = true, WaterColor = Color3.fromRGB(130, 20, 32),
	},
	["Arctic"] = {
		FogOverride = true, NoFog = false, FogColor = Color3.fromRGB(190, 228, 255), FogDecayColor = Color3.fromRGB(140, 195, 245),
		FogStart = 20, FogEnd = 750, AtmosphereDensity = 0.28, AtmosphereHaze = 1.8, AtmosphereGlare = 0.25,
		WorldColorEnabled = true, AmbientColor = Color3.fromRGB(150, 185, 215), OutdoorAmbientColor = Color3.fromRGB(185, 220, 250),
		ColorShiftTop = Color3.fromRGB(220, 245, 255), ColorShiftBottom = Color3.fromRGB(130, 170, 210),
		ColorTintEnabled = true, WorldTintColor = Color3.fromRGB(235, 248, 255), Saturation = -0.1, Contrast = 0.08, CCBrightness = 0.04,
		TimeOverride = true, ClockTime = 12.5, BrightnessOverride = true, Brightness = 2.8, Exposure = 0.1,
		Fullbright = false, DisableShadows = false, SkyMode = "Default", HideClouds = false,
		BloomOverride = false, DisableBlur = true, WaterOverride = true, WaterColor = Color3.fromRGB(85, 185, 240),
	},
	["Synthwave"] = {
		FogOverride = true, NoFog = false, FogColor = Color3.fromRGB(255, 80, 175), FogDecayColor = Color3.fromRGB(70, 210, 255),
		FogStart = 0, FogEnd = 620, AtmosphereDensity = 0.36, AtmosphereHaze = 2.5, AtmosphereGlare = 0.5,
		WorldColorEnabled = true, AmbientColor = Color3.fromRGB(115, 55, 145), OutdoorAmbientColor = Color3.fromRGB(195, 95, 175),
		ColorShiftTop = Color3.fromRGB(255, 125, 200), ColorShiftBottom = Color3.fromRGB(45, 215, 255),
		ColorTintEnabled = true, WorldTintColor = Color3.fromRGB(255, 220, 245), Saturation = 0.45, Contrast = 0.15, CCBrightness = 0.02,
		TimeOverride = true, ClockTime = 19.25, BrightnessOverride = true, Brightness = 2.4, Exposure = 0.15,
		Fullbright = false, DisableShadows = false, SkyMode = "Procedural", HideClouds = false,
		BloomOverride = true, BloomIntensity = 1.25, BloomSize = 32, BloomThreshold = 0.9, DisableBlur = true,
		WaterOverride = true, WaterColor = Color3.fromRGB(165, 55, 220),
	},
	["Clear Day"] = {
		FogOverride = false, NoFog = true, WorldColorEnabled = false, ColorTintEnabled = false,
		TimeOverride = true, ClockTime = 14.0, BrightnessOverride = true, Brightness = 2.4, Exposure = 0.05,
		Fullbright = false, DisableShadows = true, SkyMode = "Default", HideClouds = true,
		BloomOverride = false, DisableBlur = true, WaterOverride = false,
	},
	["Fullbright"] = {
		FogOverride = false, NoFog = true, WorldColorEnabled = false, ColorTintEnabled = false,
		TimeOverride = false, BrightnessOverride = false, Fullbright = true, DisableShadows = true,
		SkyMode = "Default", HideClouds = false, BloomOverride = false, DisableBlur = true, WaterOverride = false,
	},
}

local function capture_world_orig()
	if not VIS.Orig then
		VIS.Orig = {
			Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
			ColorShift_Top = Lighting.ColorShift_Top, ColorShift_Bottom = Lighting.ColorShift_Bottom,
			FogColor = Lighting.FogColor, FogStart = Lighting.FogStart, FogEnd = Lighting.FogEnd,
			ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness,
			ExposureCompensation = Lighting.ExposureCompensation, GlobalShadows = Lighting.GlobalShadows,
		}
	end
	if not VIS.OrigAtm then
		local atm = Lighting:FindFirstChildOfClass("Atmosphere")
		if atm then VIS.AtmRef = atm; VIS.OrigAtm = { Color = atm.Color, Decay = atm.Decay, Density = atm.Density, Haze = atm.Haze, Glare = atm.Glare, Offset = atm.Offset } end
	end
	if not VIS.OrigBloom then
		local bl = Lighting:FindFirstChildOfClass("BloomEffect")
		if bl and bl.Name ~= "OcelWorldBloom" then VIS.BloomRef = bl; VIS.OrigBloom = { Enabled = bl.Enabled, Intensity = bl.Intensity, Size = bl.Size, Threshold = bl.Threshold } end
	end
	if VIS.OrigWaterColor == nil then pcall(function() VIS.OrigWaterColor = Workspace.Terrain.WaterColor end) end
	if not VIS.OrigClouds then
		local cl = Workspace.Terrain:FindFirstChildOfClass("Clouds")
		if cl then VIS.CloudsRef = cl; VIS.OrigClouds = { Enabled = cl.Enabled } end
	end
end

local function restore_fog()
	if not VIS.Dirty.Fog or not VIS.Orig then return end; VIS.Dirty.Fog = false
	Lighting.FogColor, Lighting.FogStart, Lighting.FogEnd = VIS.Orig.FogColor, VIS.Orig.FogStart, VIS.Orig.FogEnd
	if VIS.AtmRef and VIS.AtmRef.Parent and VIS.OrigAtm then
		VIS.AtmRef.Color, VIS.AtmRef.Decay, VIS.AtmRef.Density = VIS.OrigAtm.Color, VIS.OrigAtm.Decay, VIS.OrigAtm.Density
		VIS.AtmRef.Haze, VIS.AtmRef.Glare, VIS.AtmRef.Offset = VIS.OrigAtm.Haze, VIS.OrigAtm.Glare, VIS.OrigAtm.Offset
	end
end
local function restore_world_colors()
	if not VIS.Dirty.World or not VIS.Orig then return end; VIS.Dirty.World = false
	Lighting.Ambient, Lighting.OutdoorAmbient = VIS.Orig.Ambient, VIS.Orig.OutdoorAmbient
	Lighting.ColorShift_Top, Lighting.ColorShift_Bottom = VIS.Orig.ColorShift_Top, VIS.Orig.ColorShift_Bottom
end
local function restore_time() if VIS.Dirty.Time and VIS.Orig then VIS.Dirty.Time = false; Lighting.ClockTime = VIS.Orig.ClockTime end end
local function restore_bright() if VIS.Dirty.Bright and VIS.Orig then VIS.Dirty.Bright = false; Lighting.Brightness, Lighting.ExposureCompensation = VIS.Orig.Brightness, VIS.Orig.ExposureCompensation end end
local function restore_shadows() if VIS.Dirty.Shadows and VIS.Orig then VIS.Dirty.Shadows = false; Lighting.GlobalShadows = VIS.Orig.GlobalShadows end end
local function restore_tint() if VIS.CCObj then pcall(function() VIS.CCObj:Destroy() end); VIS.CCObj = nil end; VIS.Dirty.Tint = false end
local function restore_bloom()
	if VIS.BloomObj then pcall(function() VIS.BloomObj:Destroy() end); VIS.BloomObj = nil end
	if VIS.Dirty.Bloom and VIS.BloomRef and VIS.BloomRef.Parent and VIS.OrigBloom then
		VIS.BloomRef.Enabled, VIS.BloomRef.Intensity, VIS.BloomRef.Size, VIS.BloomRef.Threshold = VIS.OrigBloom.Enabled, VIS.OrigBloom.Intensity, VIS.OrigBloom.Size, VIS.OrigBloom.Threshold
	end
	VIS.Dirty.Bloom = false
end
local function restore_blur()
	if not VIS.Dirty.Blur then return end; VIS.Dirty.Blur = false
	for inst, was_on in pairs(VIS.OrigBlurs) do if inst and inst.Parent then pcall(function() inst.Enabled = was_on end) end end
	table.clear(VIS.OrigBlurs)
end
local function restore_clouds()
	if not VIS.Dirty.Clouds then return end; VIS.Dirty.Clouds = false
	if VIS.CloudsRef and VIS.CloudsRef.Parent and VIS.OrigClouds then VIS.CloudsRef.Enabled = VIS.OrigClouds.Enabled end
end
local function restore_water()
	if not VIS.Dirty.Water or not VIS.OrigWaterColor then return end; VIS.Dirty.Water = false
	pcall(function() Workspace.Terrain.WaterColor = VIS.OrigWaterColor end)
end
local function restore_sky()
	if VIS.SkyObj then pcall(function() VIS.SkyObj:Destroy() end); VIS.SkyObj = nil end
	if VIS.OrigSky and VIS.OrigSky.Parent == nil then pcall(function() VIS.OrigSky.Parent = Lighting end) end
	VIS.OrigSky, VIS.LastSkyMode, VIS.Dirty.Sky = nil, "Default", false
end
local function restore_all_world()
	restore_fog(); restore_world_colors(); restore_time(); restore_bright(); restore_shadows()
	restore_tint(); restore_bloom(); restore_blur(); restore_clouds(); restore_water(); restore_sky()
end

local function update_world(clk)
	local v = CFG.Visuals
	if not v.Enabled then if VIS.Orig then restore_all_world() end; return end
	capture_world_orig()
	local rcol = v.RainbowWorld and Color3.fromHSV((clk * v.RainbowSpeed * 0.15) % 1, 0.78, 1) or nil

	if v.NoFog then
		VIS.Dirty.Fog = true; Lighting.FogStart, Lighting.FogEnd = 1e6, 1e6
		local atm = (VIS.AtmRef and VIS.AtmRef.Parent == Lighting) and VIS.AtmRef or Lighting:FindFirstChildOfClass("Atmosphere")
		if atm then VIS.AtmRef = atm; if not VIS.OrigAtm then VIS.OrigAtm = { Color = atm.Color, Decay = atm.Decay, Density = atm.Density, Haze = atm.Haze, Glare = atm.Glare, Offset = atm.Offset } end; atm.Density, atm.Haze = 0, 0 end
	elseif v.FogOverride then
		VIS.Dirty.Fog = true
		local fc = rcol or v.FogColor
		local dc = rcol and Color3.fromHSV(((clk * v.RainbowSpeed * 0.15) + 0.18) % 1, 0.72, 0.85) or v.FogDecayColor
		Lighting.FogColor, Lighting.FogStart, Lighting.FogEnd = fc, v.FogStart, math.max(v.FogStart + 10, v.FogEnd)
		local atm = (VIS.AtmRef and VIS.AtmRef.Parent == Lighting) and VIS.AtmRef or Lighting:FindFirstChildOfClass("Atmosphere")
		if atm then
			VIS.AtmRef = atm
			if not VIS.OrigAtm then VIS.OrigAtm = { Color = atm.Color, Decay = atm.Decay, Density = atm.Density, Haze = atm.Haze, Glare = atm.Glare, Offset = atm.Offset } end
			atm.Color, atm.Decay, atm.Density, atm.Haze, atm.Glare = fc, dc, v.AtmosphereDensity, v.AtmosphereHaze, v.AtmosphereGlare
		end
	else restore_fog() end

	if v.WorldColorEnabled then
		VIS.Dirty.World = true
		if rcol then
			local amb = Color3.new(rcol.R * 0.55, rcol.G * 0.55, rcol.B * 0.55)
			Lighting.Ambient, Lighting.OutdoorAmbient, Lighting.ColorShift_Top, Lighting.ColorShift_Bottom = amb, rcol, rcol, amb
		else
			Lighting.Ambient, Lighting.OutdoorAmbient, Lighting.ColorShift_Top, Lighting.ColorShift_Bottom = v.AmbientColor, v.OutdoorAmbientColor, v.ColorShiftTop, v.ColorShiftBottom
		end
	elseif v.Fullbright then
		VIS.Dirty.World = true
		Lighting.Ambient, Lighting.OutdoorAmbient = Color3.fromRGB(220, 220, 220), Color3.fromRGB(235, 235, 235)
		Lighting.ColorShift_Top, Lighting.ColorShift_Bottom = VIS.Orig.ColorShift_Top, VIS.Orig.ColorShift_Bottom
	else restore_world_colors() end

	if v.TimeOverride then VIS.Dirty.Time = true; Lighting.ClockTime = v.ClockTime
	elseif v.Fullbright then VIS.Dirty.Time = true; Lighting.ClockTime = 14
	else restore_time() end

	if v.BrightnessOverride or v.Fullbright then
		VIS.Dirty.Bright = true
		Lighting.Brightness = v.BrightnessOverride and v.Brightness or math.max(VIS.Orig.Brightness, 2.5)
		Lighting.ExposureCompensation = v.BrightnessOverride and v.Exposure or math.max(VIS.Orig.ExposureCompensation, 0.35)
	else restore_bright() end

	if v.DisableShadows or v.Fullbright then VIS.Dirty.Shadows = true; Lighting.GlobalShadows = false
	else restore_shadows() end

	if v.ColorTintEnabled then
		VIS.Dirty.Tint = true
		if not VIS.CCObj or VIS.CCObj.Parent ~= Lighting then
			if VIS.CCObj then pcall(function() VIS.CCObj:Destroy() end) end
			local cc = Instance.new("ColorCorrectionEffect"); cc.Name = "OcelWorldCC"; cc.Parent = Lighting; VIS.CCObj = cc
		end
		VIS.CCObj.Enabled, VIS.CCObj.TintColor, VIS.CCObj.Saturation, VIS.CCObj.Contrast, VIS.CCObj.Brightness = true, (rcol or v.WorldTintColor), v.Saturation, v.Contrast, v.CCBrightness
	else restore_tint() end

	if v.BloomOverride then
		VIS.Dirty.Bloom = true
		local bl = (VIS.BloomRef and VIS.BloomRef.Parent == Lighting) and VIS.BloomRef or Lighting:FindFirstChildOfClass("BloomEffect")
		if bl and bl ~= VIS.BloomObj then
			VIS.BloomRef = bl; if not VIS.OrigBloom then VIS.OrigBloom = { Enabled = bl.Enabled, Intensity = bl.Intensity, Size = bl.Size, Threshold = bl.Threshold } end
		elseif not bl then bl = Instance.new("BloomEffect"); bl.Name = "OcelWorldBloom"; bl.Parent = Lighting; VIS.BloomObj = bl end
		bl.Enabled, bl.Intensity, bl.Size, bl.Threshold = true, v.BloomIntensity, v.BloomSize, v.BloomThreshold
	else restore_bloom() end

	if v.DisableBlur then
		VIS.Dirty.Blur = true
		for _, ch in ipairs(Lighting:GetChildren()) do
			if ch:IsA("BlurEffect") or ch:IsA("DepthOfFieldEffect") then
				if VIS.OrigBlurs[ch] == nil then VIS.OrigBlurs[ch] = ch.Enabled end
				if ch.Enabled then ch.Enabled = false end
			end
		end
	else restore_blur() end

	if v.HideClouds then
		VIS.Dirty.Clouds = true
		local cl = (VIS.CloudsRef and VIS.CloudsRef.Parent) and VIS.CloudsRef or Workspace.Terrain:FindFirstChildOfClass("Clouds")
		if cl then VIS.CloudsRef = cl; if not VIS.OrigClouds then VIS.OrigClouds = { Enabled = cl.Enabled } end; cl.Enabled = false end
	else restore_clouds() end

	if v.WaterOverride then VIS.Dirty.Water = true; pcall(function() Workspace.Terrain.WaterColor = rcol or v.WaterColor end)
	else restore_water() end

	if v.SkyMode ~= "Default" then
		VIS.Dirty.Sky = true
		if not VIS.OrigSky then
			local cur = Lighting:FindFirstChildOfClass("Sky")
			if cur and cur ~= VIS.SkyObj then VIS.OrigSky = cur; cur.Parent = nil end
		end
		if not VIS.SkyObj or VIS.SkyObj.Parent ~= Lighting or VIS.LastSkyMode ~= v.SkyMode then
			if VIS.SkyObj then pcall(function() VIS.SkyObj:Destroy() end) end
			local sk = Instance.new("Sky"); sk.Name = "OcelWorldSky"
			if v.SkyMode == "Pure Black" or v.SkyMode == "Starfield" then
				local b = "rbxassetid://0"
				sk.SkyboxBk, sk.SkyboxDn, sk.SkyboxFt, sk.SkyboxLf, sk.SkyboxRt, sk.SkyboxUp = b, b, b, b, b, b
				sk.CelestialBodiesShown = (v.SkyMode == "Starfield")
				sk.StarCount = (v.SkyMode == "Starfield") and 5000 or 0
			elseif v.SkyMode == "Procedural" then
				sk.CelestialBodiesShown = true; sk.StarCount = 3000
			end
			sk.Parent = Lighting; VIS.SkyObj = sk; VIS.LastSkyMode = v.SkyMode
		end
	else restore_sky() end
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
local UI = { Gui = nil, Main = nil, Scale = nil, TPill = nil }

local function ui(cls, pr, par) local o = Instance.new(cls); for k, v in pairs(pr) do o[k] = v end; if par then o.Parent = par end; return o end
local function rc(p, r) return ui("UICorner", { CornerRadius = UDim.new(0, r) }, p) end
local function st(p, c, t, tr) return ui("UIStroke", { Color = c or TH.Border, Thickness = t or 1, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p) end
local function ptr(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function mov(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end

local function draggable(hdl, tgt, on_tap)
	local drag, moved, sp, fp, ai = false, false, nil, nil, nil
	tc(hdl.InputBegan:Connect(function(i) if ptr(i) then drag, moved, ai, sp, fp = true, false, i, Vector2.new(i.Position.X, i.Position.Y), tgt.Position end end))
	tc(UserInputService.InputChanged:Connect(function(i)
		if not drag or not mov(i) or (ai and ai.UserInputType == Enum.UserInputType.Touch and i ~= ai) then return end
		local d = Vector2.new(i.Position.X, i.Position.Y) - sp
		if d.Magnitude > 7 then moved = true end
		if moved then
			local sc = (UI.Scale and UI.Scale.Scale) or 1
			local cam = Workspace.CurrentCamera; local vp = cam and cam.ViewportSize or Vector2.new(800, 480); local abs = tgt.AbsoluteSize
			tgt.Position = UDim2.fromOffset(math.clamp(fp.X.Offset + d.X / sc, 4, math.max(4, (vp.X - abs.X) / sc)), math.clamp(fp.Y.Offset + d.Y / sc, 4, math.max(4, (vp.Y - abs.Y) / sc)))
		end
	end))
	tc(UserInputService.InputEnded:Connect(function(i) if drag and ptr(i) and (not ai or i == ai) then drag, ai = false, nil; if not moved and on_tap then on_tap() end end end))
end

local function hdr_lbl(p, t)
	local h = ui("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 }, p)
	ui("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = string.upper(t), TextSize = 10, TextColor3 = TH.Muted, TextXAlignment = Enum.TextXAlignment.Left }, h)
	ui("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BorderSizePixel = 0, BackgroundColor3 = TH.Border, BackgroundTransparency = 0.35 }, h)
end

local function tog(p, lbl, gv, sv)
	local r = ui("TextButton", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = TH.Card, BorderSizePixel = 0, AutoButtonColor = false, Text = "" }, p); rc(r, 6); st(r, TH.Border, 1, 0.45)
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
	ref(true); r.Activated:Connect(function() sv(not gv()); ref(false) end)
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
		rc(b, 4); st(b, TH.Border, 1, 0.5); btns[o] = b; b.Activated:Connect(function() sv(o); exp = false; ref() end)
	end
	h.Activated:Connect(function() exp = not exp; ref() end); ref()
	return ref
end

local function col_eq(a, b) return math.abs(a.R - b.R) < 0.015 and math.abs(a.G - b.G) < 0.015 and math.abs(a.B - b.B) < 0.015 end

local function col_row(p, lbl, gc, sc_fn)
	local c = ui("Frame", { Size = UDim2.new(1, 0, 0, 56), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = TH.Card, BorderSizePixel = 0, ClipsDescendants = true }, p); rc(c, 6); st(c, TH.Border, 1, 0.45)
	local top = ui("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1 }, c)
	ui("TextLabel", { Size = UDim2.new(1, -92, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, Text = lbl, TextSize = 12, TextColor3 = TH.Txt, TextXAlignment = Enum.TextXAlignment.Left }, top)
	local hsv_btn = ui("TextButton", { Size = UDim2.fromOffset(36, 16), Position = UDim2.new(1, -74, 0.5, -8), BackgroundColor3 = TH.Panel, BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamBold, Text = "HSV", TextSize = 9, TextColor3 = TH.Muted }, top); rc(hsv_btn, 4); st(hsv_btn, TH.Border, 1, 0.4)
	local pv = ui("TextButton", { Size = UDim2.fromOffset(24, 16), Position = UDim2.new(1, -34, 0.5, -8), BorderSizePixel = 0, Text = "", AutoButtonColor = false }, top); rc(pv, 4); st(pv, TH.Accent, 1, 0.25)
	local row = ui("Frame", { Size = UDim2.new(1, -20, 0, 24), Position = UDim2.fromOffset(10, 27), BackgroundTransparency = 1 }, c)
	ui("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), VerticalAlignment = Enum.VerticalAlignment.Center }, row)
	local hsv_box = ui("Frame", { Size = UDim2.new(1, -20, 0, 74), Position = UDim2.fromOffset(10, 54), BackgroundTransparency = 1, Visible = false }, c)
	local exp, h0, s0, v0 = false, gc():ToHSV()
	local hsv, sws, bars = { H = h0, S = s0, V = v0 }, {}, {}
	local function mk_bar(idx, name, yoff, grad_cs)
		ui("TextLabel", { Size = UDim2.fromOffset(14, 18), Position = UDim2.fromOffset(0, yoff), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = name, TextSize = 10, TextColor3 = TH.Muted, TextXAlignment = Enum.TextXAlignment.Left }, hsv_box)
		local hit = ui("TextButton", { Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(18, yoff), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, hsv_box)
		local tr = ui("Frame", { Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0.5, -3), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, hit); rc(tr, 3); st(tr, TH.Border, 1, 0.3)
		local gr = ui("UIGradient", { Color = grad_cs }, tr)
		local kn = ui("Frame", { Size = UDim2.fromOffset(10, 12), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = TH.Accent, BorderSizePixel = 0 }, tr); rc(kn, 5); st(kn, TH.Bg, 1.5, 0)
		bars[idx] = { Hit = hit, Tr = tr, Gr = gr, Kn = kn }
	end
	mk_bar(1, "H", 2, ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
	}))
	mk_bar(2, "S", 25, ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(hsv.H, 1, 1)))
	mk_bar(3, "V", 48, ColorSequence.new(Color3.new(0, 0, 0), Color3.fromHSV(hsv.H, hsv.S, 1)))
	local function ref(sync_hsv)
		local cur = gc(); pv.BackgroundColor3 = cur
		if sync_hsv then hsv.H, hsv.S, hsv.V = cur:ToHSV() end
		for i, col in ipairs(PRESETS) do local eq = col_eq(cur, col); sws[i].Color, sws[i].Thickness = eq and TH.Accent or TH.Border, eq and 2 or 1 end
		bars[1].Kn.Position, bars[2].Kn.Position, bars[3].Kn.Position = UDim2.new(hsv.H, 0, 0.5, 0), UDim2.new(hsv.S, 0, 0.5, 0), UDim2.new(hsv.V, 0, 0.5, 0)
		bars[2].Gr.Color = ColorSequence.new(Color3.fromHSV(hsv.H, 0, hsv.V), Color3.fromHSV(hsv.H, 1, hsv.V))
		bars[3].Gr.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.fromHSV(hsv.H, hsv.S, 1))
		hsv_box.Visible = exp; c.Size = UDim2.new(1, 0, 0, exp and 132 or 56)
		hsv_btn.BackgroundColor3, hsv_btn.TextColor3 = exp and TH.Accent or TH.Panel, exp and TH.AccentTxt or TH.Muted
	end
	local function bind_bar(idx, key)
		local drg, ai = false, nil
		local function setx(x)
			local tr = bars[idx].Tr; hsv[key] = math.clamp((x - tr.AbsolutePosition.X) / math.max(tr.AbsoluteSize.X, 1), 0, 1)
			sc_fn(Color3.fromHSV(hsv.H, hsv.S, hsv.V)); ref(false)
		end
		tc(bars[idx].Hit.InputBegan:Connect(function(i) if ptr(i) then drg, ai = true, i; if S.Scroll then S.Scroll.ScrollingEnabled = false end; setx(i.Position.X) end end))
		tc(UserInputService.InputChanged:Connect(function(i) if drg and mov(i) and (not ai or ai.UserInputType ~= Enum.UserInputType.Touch or i == ai) then setx(i.Position.X) end end))
		tc(UserInputService.InputEnded:Connect(function(i) if drg and ptr(i) and (not ai or i == ai) then drg, ai = false, nil; if S.Scroll then S.Scroll.ScrollingEnabled = true end end end))
	end
	bind_bar(1, "H"); bind_bar(2, "S"); bind_bar(3, "V")
	for i, col in ipairs(PRESETS) do
		local sw = ui("TextButton", { Size = UDim2.fromOffset(20, 17), BackgroundColor3 = col, BorderSizePixel = 0, Text = "", AutoButtonColor = false }, row)
		rc(sw, 4); sws[i] = st(sw, TH.Border, 1, 0); sw.Activated:Connect(function() sc_fn(col); ref(true) end)
	end
	local function tog_exp() exp = not exp; ref(true) end
	hsv_btn.Activated:Connect(tog_exp); pv.Activated:Connect(tog_exp); ref(true)
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

local function set_open(o) CFG.Menu.Open = o; if UI.Main then UI.Main.Visible = o end end
local function upd_scale()
	if not UI.Scale then return end
	local cam = Workspace.CurrentCamera; local vp = cam and cam.ViewportSize or Vector2.new(800, 480)
	UI.Scale.Scale = math.clamp(math.min((vp.X - 24) / 410, (vp.Y - 24) / 310, 1), 0.68, 1) * CFG.Menu.UIScale
end

local ctrl
local function destroy_all()
	if S.Destroyed then return end; S.Destroyed = true
	for _, c in ipairs(S.Conns) do pcall(function() c:Disconnect() end) end
	table.clear(S.Conns)
	restore_all_world()
	if UI.Gui then pcall(function() UI.Gui:Destroy() end) end
	if getgenv and getgenv().SanDiegoVisuals == ctrl then getgenv().SanDiegoVisuals = nil end
end
ctrl = { Config = CFG, Destroy = destroy_all, SetOpen = set_open }
if getgenv then getgenv().SanDiegoVisuals = ctrl end

local function build_ui()
	local sg = ui("ScreenGui", { Name = "SanDiegoVisualsGui", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999998 }, gui_root())
	UI.Gui = sg; UI.Scale = ui("UIScale", { Scale = 1 }, sg)

	local tp = ui("TextButton", { Name = "VisTogglePill", Size = UDim2.fromOffset(74, 30), Position = UDim2.fromOffset(14, 156), BackgroundColor3 = TH.Bg, BorderSizePixel = 0, AutoButtonColor = false, Text = "", Visible = CFG.Menu.ShowTogglePill }, sg)
	rc(tp, 15); st(tp, TH.Accent, 1.4, 0.15)
	rc(ui("Frame", { Size = UDim2.fromOffset(6, 6), Position = UDim2.fromOffset(11, 12), BackgroundColor3 = TH.Accent, BorderSizePixel = 0 }, tp), 3)
	ui("TextLabel", { Size = UDim2.new(1, -22, 1, 0), Position = UDim2.fromOffset(19, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "VIS", TextSize = 11, TextColor3 = TH.Txt, TextXAlignment = Enum.TextXAlignment.Left }, tp)
	UI.TPill = tp; draggable(tp, tp, function() set_open(not CFG.Menu.Open) end)

	local mn = ui("Frame", { Name = "MainWindow", Size = UDim2.fromOffset(400, 300), Position = UDim2.fromOffset(105, 50), BackgroundColor3 = TH.Bg, BackgroundTransparency = 0.04, BorderSizePixel = 0, Visible = CFG.Menu.Open }, sg)
	rc(mn, 10); st(mn, TH.BorderHi, 1.2, 0.35); UI.Main = mn

	local hdr = ui("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = TH.Panel, BorderSizePixel = 0 }, mn); rc(hdr, 10)
	ui("Frame", { Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -10), BackgroundColor3 = TH.Panel, BorderSizePixel = 0 }, hdr)
	ui("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = TH.Border, BorderSizePixel = 0 }, hdr)
	rc(ui("Frame", { Size = UDim2.fromOffset(7, 7), Position = UDim2.fromOffset(13, 16), BackgroundColor3 = TH.Accent, BorderSizePixel = 0 }, hdr), 4)
	ui("TextLabel", { Size = UDim2.fromOffset(150, 20), Position = UDim2.fromOffset(26, 9), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "WORLD VISUALS", TextSize = 13, TextColor3 = TH.Txt, TextXAlignment = Enum.TextXAlignment.Left }, hdr)
	local bdg = ui("TextLabel", { Size = UDim2.fromOffset(78, 16), Position = UDim2.fromOffset(145, 11), BackgroundColor3 = TH.Card, BorderSizePixel = 0, Font = Enum.Font.GothamBold, Text = "SAN DIEGO", TextSize = 9, TextColor3 = TH.Muted }, hdr); rc(bdg, 4); st(bdg, TH.Border, 1, 0.4)
	local mb = ui("TextButton", { Size = UDim2.fromOffset(26, 24), Position = UDim2.new(1, -60, 0.5, -12), BackgroundColor3 = TH.Card, BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamBold, Text = "—", TextSize = 12, TextColor3 = TH.Txt }, hdr); rc(mb, 5); mb.Activated:Connect(function() set_open(false) end)
	local cb = ui("TextButton", { Size = UDim2.fromOffset(26, 24), Position = UDim2.new(1, -30, 0.5, -12), BackgroundColor3 = TH.Card, BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamBold, Text = "×", TextSize = 15, TextColor3 = TH.Txt }, hdr); rc(cb, 5); cb.Activated:Connect(destroy_all)
	draggable(hdr, mn)

	local scr = ui("ScrollingFrame", { Size = UDim2.new(1, -16, 1, -48), Position = UDim2.fromOffset(8, 44), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = TH.Accent, ScrollBarImageTransparency = 0.35, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y }, mn)
	S.Scroll = scr
	local wpg = ui("Frame", { Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, scr)
	ui("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, wpg); ui("UIPadding", { PaddingBottom = UDim.new(0, 8) }, wpg)

	local wrefs, preset_ref = {}, nil
	local function wr(fn) table.insert(wrefs, fn); return fn end
	local function sync_wrefs() for _, fn in ipairs(wrefs) do pcall(fn) end end
	local function mark_custom()
		if CFG.Visuals.Preset ~= "Custom" then CFG.Visuals.Preset = "Custom"; if preset_ref then preset_ref() end end
	end

	hdr_lbl(wpg, "Master & Presets")
	wr(tog(wpg, "Enable World Visuals", function() return CFG.Visuals.Enabled end, function(v) CFG.Visuals.Enabled = v; if not v and VIS.Orig then restore_all_world() end end))
	preset_ref = wr(sel(wpg, "Visual Preset", { "Custom", "Neon Night", "Blood Moon", "Arctic", "Synthwave", "Clear Day", "Fullbright" }, function() return CFG.Visuals.Preset end, function(v)
		if v == "Custom" then CFG.Visuals.Preset = "Custom"; return end
		local pr = VIS_PRESETS[v]; if not pr then return end
		CFG.Visuals.Preset = v; CFG.Visuals.Enabled = true; CFG.Visuals.RainbowWorld = false
		for k, val in pairs(pr) do CFG.Visuals[k] = val end
		sync_wrefs()
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
		v.Enabled = false; v.Preset = "Custom"; v.FogOverride = false; v.NoFog = false; v.WorldColorEnabled = false
		v.ColorTintEnabled = false; v.Fullbright = false; v.TimeOverride = false; v.BrightnessOverride = false
		v.DisableShadows = false; v.SkyMode = "Default"; v.HideClouds = false; v.WaterOverride = false
		v.DisableBlur = false; v.BloomOverride = false; v.RainbowWorld = false
		restore_all_world(); sync_wrefs()
	end)
	act_btn(wpg, "Unload Visuals", destroy_all)
	upd_scale()
end

tc(UserInputService.InputBegan:Connect(function(i, gp) if not gp and i.KeyCode == CFG.Menu.ToggleKey then set_open(not CFG.Menu.Open) end end))
tc(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(upd_scale))
build_ui()
tc(RunService.RenderStepped:Connect(function() if not S.Destroyed then update_world(os.clock()) end end))
