-- language: Luau, file: modules/chams.lua, target: Roblox (San Diego / Mobile & PC)
return function(ctx)
	local CollectionService = ctx.CollectionService
	local Players = ctx.Players
	local Workspace = ctx.Workspace
	local LP = ctx.LP
	local CFG = ctx.CFG
	local drw = ctx.drw
	local gui_root = ctx.gui_root
	local ARMS = ctx.ARMS
	local alive = ctx.alive
	local esp_col = ctx.esp_col
	local ignored = ctx.ignored
	local ui = ctx.ui
	local can_see = ctx.can_see

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


	ctx.update_chams = update_chams
	ctx.cleanup_chams = cleanup_chams
end