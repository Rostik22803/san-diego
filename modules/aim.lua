-- language: Luau, file: modules/aim.lua, target: Roblox (San Diego / Mobile & PC)
return function(ctx)
	local Players = ctx.Players
	local UserInputService = ctx.UserInputService
	local Workspace = ctx.Workspace
	local LP = ctx.LP
	local CFG = ctx.CFG
	local S = ctx.S
	local drw = ctx.drw
	local alive = ctx.alive
	local ignored = ctx.ignored
	local TH = ctx.TH
	local UI = ctx.UI

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


	ctx.AimD = AimD
	ctx.bullet_raycast = bullet_raycast
	ctx.can_see = can_see
	ctx.can_see_pos = can_see_pos
	ctx.RND_PARTS = RND_PARTS
	ctx.pick_part = pick_part
	ctx.sync_world_fov = sync_world_fov
	ctx.update_aim_pre = update_aim_pre
	ctx.update_aim_post = update_aim_post
	ctx.update_aim_visuals = update_aim_visuals
	ctx.update_crosshair = update_crosshair
	ctx.cleanup_crosshair = cleanup_crosshair
end