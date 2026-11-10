-- language: Luau, file: modules/world.lua, target: Roblox (San Diego / Mobile & PC)
return function(ctx)
	local Lighting = ctx.Lighting
	local Workspace = ctx.Workspace
	local CFG = ctx.CFG

-- World & Atmosphere Visuals
local VIS = {
	Orig = nil,
	OrigAtm = nil,
	AtmRef = nil,
	OrigBloom = nil,
	BloomRef = nil,
	OrigBlurs = {},
	OrigClouds = nil,
	CloudsRef = nil,
	OrigWaterColor = nil,
	OrigSky = nil,
	CCObj = nil,
	BloomObj = nil,
	SkyObj = nil,
	LastSkyMode = "Default",
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
			Ambient = Lighting.Ambient,
			OutdoorAmbient = Lighting.OutdoorAmbient,
			ColorShift_Top = Lighting.ColorShift_Top,
			ColorShift_Bottom = Lighting.ColorShift_Bottom,
			FogColor = Lighting.FogColor,
			FogStart = Lighting.FogStart,
			FogEnd = Lighting.FogEnd,
			ClockTime = Lighting.ClockTime,
			Brightness = Lighting.Brightness,
			ExposureCompensation = Lighting.ExposureCompensation,
			GlobalShadows = Lighting.GlobalShadows,
		}
	end
	if not VIS.OrigAtm then
		local atm = Lighting:FindFirstChildOfClass("Atmosphere")
		if atm then
			VIS.AtmRef = atm
			VIS.OrigAtm = { Color = atm.Color, Decay = atm.Decay, Density = atm.Density, Haze = atm.Haze, Glare = atm.Glare, Offset = atm.Offset }
		end
	end
	if not VIS.OrigBloom then
		local bl = Lighting:FindFirstChildOfClass("BloomEffect")
		if bl and bl.Name ~= "OcelWorldBloom" then
			VIS.BloomRef = bl
			VIS.OrigBloom = { Enabled = bl.Enabled, Intensity = bl.Intensity, Size = bl.Size, Threshold = bl.Threshold }
		end
	end
	if VIS.OrigWaterColor == nil then
		pcall(function() VIS.OrigWaterColor = Workspace.Terrain.WaterColor end)
	end
	if not VIS.OrigClouds then
		local cl = Workspace.Terrain:FindFirstChildOfClass("Clouds")
		if cl then
			VIS.CloudsRef = cl
			VIS.OrigClouds = { Enabled = cl.Enabled }
		end
	end
end

local function restore_fog()
	if not VIS.Dirty.Fog or not VIS.Orig then return end
	VIS.Dirty.Fog = false
	Lighting.FogColor = VIS.Orig.FogColor
	Lighting.FogStart = VIS.Orig.FogStart
	Lighting.FogEnd = VIS.Orig.FogEnd
	if VIS.AtmRef and VIS.AtmRef.Parent and VIS.OrigAtm then
		VIS.AtmRef.Color = VIS.OrigAtm.Color
		VIS.AtmRef.Decay = VIS.OrigAtm.Decay
		VIS.AtmRef.Density = VIS.OrigAtm.Density
		VIS.AtmRef.Haze = VIS.OrigAtm.Haze
		VIS.AtmRef.Glare = VIS.OrigAtm.Glare
		VIS.AtmRef.Offset = VIS.OrigAtm.Offset
	end
end

local function restore_world_colors()
	if not VIS.Dirty.World or not VIS.Orig then return end
	VIS.Dirty.World = false
	Lighting.Ambient = VIS.Orig.Ambient
	Lighting.OutdoorAmbient = VIS.Orig.OutdoorAmbient
	Lighting.ColorShift_Top = VIS.Orig.ColorShift_Top
	Lighting.ColorShift_Bottom = VIS.Orig.ColorShift_Bottom
end

local function restore_time()
	if not VIS.Dirty.Time or not VIS.Orig then return end
	VIS.Dirty.Time = false
	Lighting.ClockTime = VIS.Orig.ClockTime
end

local function restore_bright()
	if not VIS.Dirty.Bright or not VIS.Orig then return end
	VIS.Dirty.Bright = false
	Lighting.Brightness = VIS.Orig.Brightness
	Lighting.ExposureCompensation = VIS.Orig.ExposureCompensation
end

local function restore_shadows()
	if not VIS.Dirty.Shadows or not VIS.Orig then return end
	VIS.Dirty.Shadows = false
	Lighting.GlobalShadows = VIS.Orig.GlobalShadows
end

local function restore_tint()
	if VIS.CCObj then
		pcall(function() VIS.CCObj:Destroy() end)
		VIS.CCObj = nil
	end
	VIS.Dirty.Tint = false
end

local function restore_bloom()
	if VIS.BloomObj then
		pcall(function() VIS.BloomObj:Destroy() end)
		VIS.BloomObj = nil
	end
	if VIS.Dirty.Bloom and VIS.BloomRef and VIS.BloomRef.Parent and VIS.OrigBloom then
		VIS.BloomRef.Enabled = VIS.OrigBloom.Enabled
		VIS.BloomRef.Intensity = VIS.OrigBloom.Intensity
		VIS.BloomRef.Size = VIS.OrigBloom.Size
		VIS.BloomRef.Threshold = VIS.OrigBloom.Threshold
	end
	VIS.Dirty.Bloom = false
end

local function restore_blur()
	if not VIS.Dirty.Blur then return end
	VIS.Dirty.Blur = false
	for inst, was_on in pairs(VIS.OrigBlurs) do
		if inst and inst.Parent then pcall(function() inst.Enabled = was_on end) end
	end
	table.clear(VIS.OrigBlurs)
end

local function restore_clouds()
	if not VIS.Dirty.Clouds then return end
	VIS.Dirty.Clouds = false
	if VIS.CloudsRef and VIS.CloudsRef.Parent and VIS.OrigClouds then
		VIS.CloudsRef.Enabled = VIS.OrigClouds.Enabled
	end
end

local function restore_water()
	if not VIS.Dirty.Water or not VIS.OrigWaterColor then return end
	VIS.Dirty.Water = false
	pcall(function() Workspace.Terrain.WaterColor = VIS.OrigWaterColor end)
end

local function restore_sky()
	if VIS.SkyObj then
		pcall(function() VIS.SkyObj:Destroy() end)
		VIS.SkyObj = nil
	end
	if VIS.OrigSky and VIS.OrigSky.Parent == nil then
		pcall(function() VIS.OrigSky.Parent = Lighting end)
	end
	VIS.OrigSky = nil
	VIS.LastSkyMode = "Default"
	VIS.Dirty.Sky = false
end

local function restore_all_world()
	restore_fog()
	restore_world_colors()
	restore_time()
	restore_bright()
	restore_shadows()
	restore_tint()
	restore_bloom()
	restore_blur()
	restore_clouds()
	restore_water()
	restore_sky()
end

local function apply_world_preset(name, refs)
	local pr = VIS_PRESETS[name]
	if not pr then return end
	local v = CFG.Visuals
	v.Preset = name
	v.Enabled = true
	v.RainbowWorld = false
	for k, val in pairs(pr) do v[k] = val end
	if refs then
		for _, fn in ipairs(refs) do pcall(fn) end
	end
end

local function update_world(clk)
	local v = CFG.Visuals
	if not v.Enabled then
		if VIS.Orig then restore_all_world() end
		return
	end
	capture_world_orig()

	local rcol = v.RainbowWorld and Color3.fromHSV((clk * v.RainbowSpeed * 0.15) % 1, 0.78, 1) or nil

	-- Fog & Atmosphere
	if v.NoFog then
		VIS.Dirty.Fog = true
		Lighting.FogStart = 1e6
		Lighting.FogEnd = 1e6
		local atm = (VIS.AtmRef and VIS.AtmRef.Parent == Lighting) and VIS.AtmRef or Lighting:FindFirstChildOfClass("Atmosphere")
		if atm then
			VIS.AtmRef = atm
			if not VIS.OrigAtm then VIS.OrigAtm = { Color = atm.Color, Decay = atm.Decay, Density = atm.Density, Haze = atm.Haze, Glare = atm.Glare, Offset = atm.Offset } end
			atm.Density = 0
			atm.Haze = 0
		end
	elseif v.FogOverride then
		VIS.Dirty.Fog = true
		local fc = rcol or v.FogColor
		local dc = rcol and Color3.fromHSV(((clk * v.RainbowSpeed * 0.15) + 0.18) % 1, 0.72, 0.85) or v.FogDecayColor
		Lighting.FogColor = fc
		Lighting.FogStart = v.FogStart
		Lighting.FogEnd = math.max(v.FogStart + 10, v.FogEnd)
		local atm = (VIS.AtmRef and VIS.AtmRef.Parent == Lighting) and VIS.AtmRef or Lighting:FindFirstChildOfClass("Atmosphere")
		if atm then
			VIS.AtmRef = atm
			if not VIS.OrigAtm then VIS.OrigAtm = { Color = atm.Color, Decay = atm.Decay, Density = atm.Density, Haze = atm.Haze, Glare = atm.Glare, Offset = atm.Offset } end
			atm.Color = fc
			atm.Decay = dc
			atm.Density = v.AtmosphereDensity
			atm.Haze = v.AtmosphereHaze
			atm.Glare = v.AtmosphereGlare
		end
	else
		restore_fog()
	end

	-- World / Ambient Colors
	if v.WorldColorEnabled then
		VIS.Dirty.World = true
		if rcol then
			local amb = Color3.new(rcol.R * 0.55, rcol.G * 0.55, rcol.B * 0.55)
			Lighting.Ambient = amb
			Lighting.OutdoorAmbient = rcol
			Lighting.ColorShift_Top = rcol
			Lighting.ColorShift_Bottom = amb
		else
			Lighting.Ambient = v.AmbientColor
			Lighting.OutdoorAmbient = v.OutdoorAmbientColor
			Lighting.ColorShift_Top = v.ColorShiftTop
			Lighting.ColorShift_Bottom = v.ColorShiftBottom
		end
	elseif v.Fullbright then
		VIS.Dirty.World = true
		Lighting.Ambient = Color3.fromRGB(220, 220, 220)
		Lighting.OutdoorAmbient = Color3.fromRGB(235, 235, 235)
		Lighting.ColorShift_Top = VIS.Orig.ColorShift_Top
		Lighting.ColorShift_Bottom = VIS.Orig.ColorShift_Bottom
	else
		restore_world_colors()
	end

	-- Time of Day
	if v.TimeOverride then
		VIS.Dirty.Time = true
		Lighting.ClockTime = v.ClockTime
	elseif v.Fullbright then
		VIS.Dirty.Time = true
		Lighting.ClockTime = 14
	else
		restore_time()
	end

	-- Brightness & Exposure
	if v.BrightnessOverride or v.Fullbright then
		VIS.Dirty.Bright = true
		Lighting.Brightness = v.BrightnessOverride and v.Brightness or math.max(VIS.Orig.Brightness, 2.5)
		Lighting.ExposureCompensation = v.BrightnessOverride and v.Exposure or math.max(VIS.Orig.ExposureCompensation, 0.35)
	else
		restore_bright()
	end

	-- Shadows
	if v.DisableShadows or v.Fullbright then
		VIS.Dirty.Shadows = true
		Lighting.GlobalShadows = false
	else
		restore_shadows()
	end

	-- Screen ColorCorrection / World Tint
	if v.ColorTintEnabled then
		VIS.Dirty.Tint = true
		if not VIS.CCObj or VIS.CCObj.Parent ~= Lighting then
			if VIS.CCObj then pcall(function() VIS.CCObj:Destroy() end) end
			local cc = Instance.new("ColorCorrectionEffect")
			cc.Name = "OcelWorldCC"
			cc.Parent = Lighting
			VIS.CCObj = cc
		end
		VIS.CCObj.Enabled = true
		VIS.CCObj.TintColor = rcol or v.WorldTintColor
		VIS.CCObj.Saturation = v.Saturation
		VIS.CCObj.Contrast = v.Contrast
		VIS.CCObj.Brightness = v.CCBrightness
	else
		restore_tint()
	end

	-- Bloom
	if v.BloomOverride then
		VIS.Dirty.Bloom = true
		local bl = (VIS.BloomRef and VIS.BloomRef.Parent == Lighting) and VIS.BloomRef or Lighting:FindFirstChildOfClass("BloomEffect")
		if bl and bl ~= VIS.BloomObj then
			VIS.BloomRef = bl
			if not VIS.OrigBloom then VIS.OrigBloom = { Enabled = bl.Enabled, Intensity = bl.Intensity, Size = bl.Size, Threshold = bl.Threshold } end
		elseif not bl then
			bl = Instance.new("BloomEffect")
			bl.Name = "OcelWorldBloom"
			bl.Parent = Lighting
			VIS.BloomObj = bl
		end
		bl.Enabled = true
		bl.Intensity = v.BloomIntensity
		bl.Size = v.BloomSize
		bl.Threshold = v.BloomThreshold
	else
		restore_bloom()
	end

	-- Disable Blur / DepthOfField
	if v.DisableBlur then
		VIS.Dirty.Blur = true
		for _, ch in ipairs(Lighting:GetChildren()) do
			if ch:IsA("BlurEffect") or ch:IsA("DepthOfFieldEffect") then
				if VIS.OrigBlurs[ch] == nil then VIS.OrigBlurs[ch] = ch.Enabled end
				if ch.Enabled then ch.Enabled = false end
			end
		end
	else
		restore_blur()
	end

	-- Clouds
	if v.HideClouds then
		VIS.Dirty.Clouds = true
		local cl = (VIS.CloudsRef and VIS.CloudsRef.Parent) and VIS.CloudsRef or Workspace.Terrain:FindFirstChildOfClass("Clouds")
		if cl then
			VIS.CloudsRef = cl
			if not VIS.OrigClouds then VIS.OrigClouds = { Enabled = cl.Enabled } end
			cl.Enabled = false
		end
	else
		restore_clouds()
	end

	-- Water
	if v.WaterOverride then
		VIS.Dirty.Water = true
		pcall(function() Workspace.Terrain.WaterColor = rcol or v.WaterColor end)
	else
		restore_water()
	end

	-- Sky Mode
	if v.SkyMode ~= "Default" then
		VIS.Dirty.Sky = true
		if not VIS.OrigSky then
			local cur_sky = Lighting:FindFirstChildOfClass("Sky")
			if cur_sky and cur_sky ~= VIS.SkyObj then
				VIS.OrigSky = cur_sky
				cur_sky.Parent = nil
			end
		end
		if not VIS.SkyObj or VIS.SkyObj.Parent ~= Lighting or VIS.LastSkyMode ~= v.SkyMode then
			if VIS.SkyObj then pcall(function() VIS.SkyObj:Destroy() end) end
			local sk = Instance.new("Sky")
			sk.Name = "OcelWorldSky"
			if v.SkyMode == "Pure Black" then
				local blank = "rbxassetid://0"
				sk.SkyboxBk, sk.SkyboxDn, sk.SkyboxFt, sk.SkyboxLf, sk.SkyboxRt, sk.SkyboxUp = blank, blank, blank, blank, blank, blank
				sk.CelestialBodiesShown = false
				sk.StarCount = 0
			elseif v.SkyMode == "Starfield" then
				local blank = "rbxassetid://0"
				sk.SkyboxBk, sk.SkyboxDn, sk.SkyboxFt, sk.SkyboxLf, sk.SkyboxRt, sk.SkyboxUp = blank, blank, blank, blank, blank, blank
				sk.CelestialBodiesShown = true
				sk.StarCount = 5000
			elseif v.SkyMode == "Procedural" then
				sk.CelestialBodiesShown = true
				sk.StarCount = 3000
			end
			sk.Parent = Lighting
			VIS.SkyObj = sk
			VIS.LastSkyMode = v.SkyMode
		end
	else
		restore_sky()
	end
end

local function cleanup_world()
	restore_all_world()
	VIS.Orig = nil
	VIS.OrigAtm = nil
	VIS.AtmRef = nil
	VIS.OrigBloom = nil
	VIS.BloomRef = nil
	VIS.OrigClouds = nil
	VIS.CloudsRef = nil
	VIS.OrigWaterColor = nil
end


	ctx.VIS = VIS
	ctx.VIS_PRESETS = VIS_PRESETS
	ctx.restore_all_world = restore_all_world
	ctx.apply_world_preset = apply_world_preset
	ctx.update_world = update_world
	ctx.cleanup_world = cleanup_world
end