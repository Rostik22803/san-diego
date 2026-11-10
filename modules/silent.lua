-- language: Luau, file: modules/silent.lua, target: Roblox (San Diego / Mobile & PC)
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
	local bullet_raycast = ctx.bullet_raycast
	local can_see = ctx.can_see
	local can_see_pos = ctx.can_see_pos
	local RND_PARTS = ctx.RND_PARTS
	local pick_part = ctx.pick_part
	local NPC_E = ctx.NPC_E
	local npc_meta = ctx.npc_meta
	local npc_matches_filter = ctx.npc_matches_filter
	local npc_info = ctx.npc_info
	local npc_alive = ctx.npc_alive

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


	ctx.install_silent_hooks = install_silent_hooks
	ctx.sync_silent_slot = sync_silent_slot
	ctx.update_silent = update_silent
	ctx.cleanup_silent = cleanup_silent
	ctx.update_tracers = update_tracers
	ctx.cleanup_tracers = cleanup_tracers
end