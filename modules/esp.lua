-- language: Luau, file: modules/esp.lua, target: Roblox (San Diego / Mobile & PC)
return function(ctx)
	local Workspace = ctx.Workspace
	local CFG = ctx.CFG
	local drw = ctx.drw
	local R15 = ctx.R15
	local R6 = ctx.R6
	local alive = ctx.alive
	local wanted_stars = ctx.wanted_stars
	local esp_col = ctx.esp_col
	local ignored = ctx.ignored

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


	ctx.ESP_E = ESP_E
	ctx.NPC_E = NPC_E
	ctx.add_esp = add_esp
	ctx.del_esp = del_esp
	ctx.add_npc_esp = add_npc_esp
	ctx.del_npc_esp = del_npc_esp
	ctx.npc_meta = npc_meta
	ctx.npc_matches_filter = npc_matches_filter
	ctx.npc_info = npc_info
	ctx.npc_alive = npc_alive
	ctx.update_esp = update_esp
end