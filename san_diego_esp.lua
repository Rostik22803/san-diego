-- language: Luau, file: san_diego_esp.lua, target: Roblox (San Diego dump), Ocel-hub (Aimbot + ESP + Chams)
-- Self-contained Ocel-hub UI + San Diego Camera Aimbot + 2D Box & R15/R6 Skeleton ESP + 7-mode Chams.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local local_player = Players.LocalPlayer

if getgenv then
	if getgenv().OcelHub then
		pcall(function()
			getgenv().OcelHub:Destroy()
		end)
	end
	if getgenv().SanDiegoESP then
		pcall(function()
			getgenv().SanDiegoESP:Destroy()
		end)
	end
end

local function get_ui_parent()
	if gethui then
		local ok, res = pcall(gethui)
		if ok and res then
			return res
		end
	end
	local ok, cg = pcall(function()
		return CoreGui
	end)
	if ok and cg then
		return cg
	end
	return local_player:WaitForChild("PlayerGui")
end

local CONFIG = {
	MenuOpen = true,
	MenuKey = Enum.KeyCode.RightShift,
	EspToggleKey = Enum.KeyCode.F3,

	Aim = {
		Enabled = false,
		Mode = "Hold", -- "Hold" | "Toggle" | "Always"
		Key = "RMB",   -- "RMB" | "E" | "Q" | "X" | "LeftAlt" | "LeftShift"
		TargetPart = "Head", -- "Head" | "UpperTorso" | "HumanoidRootPart" | "Closest"
		FOV = 140,
		ShowFOV = true,
		Smoothness = 4, -- 1 = instant, higher = smoother
		WallCheck = true,
		TeamCheck = false,
		IgnoreHearseHidden = true,
		StickyTarget = true,
		Prediction = false,
		PredictionAmount = 0.08,
		MaxDistance = 1200,
		FOVColor = Color3.fromRGB(45, 212, 191),
	},

	ESP = {
		Enabled = true,
		MaxDistance = 1500,
		TeamCheck = false,
		IgnoreHearseHidden = true,
		IgnoreModeratorHidden = false,

		ShowBox = true,
		BoxOutline = true,
		BoxThickness = 1,

		ShowSkeleton = true,
		SkeletonOutline = true,
		SkeletonThickness = 1.5,
		ShowHeadCircle = true,

		ShowHealthBar = true,
		ShowName = true,
		ShowDistance = true,
		ShowTeamTag = true,
		ShowWanted = true,
		TextSize = 13,

		ColorUseTeam = true,
		ColorWantedOverride = true,
		ColorDefault = Color3.fromRGB(240, 244, 248),
		ColorWanted = Color3.fromRGB(255, 68, 68),
		ColorDetained = Color3.fromRGB(255, 196, 61),
		ColorOutline = Color3.fromRGB(0, 0, 0),
	},

	Chams = {
		Enabled = false,
		Mode = "Water Flow", -- "Solid" | "Wireframe" | "Glossy Flow" | "Water Flow" | "Pulse Glow" | "Thermal" | "Ghost"
		DepthMode = "AlwaysOnTop", -- "AlwaysOnTop" | "Occluded"
		ColorMode = "Custom", -- "Custom" | "Team" | "Rainbow"
		CustomColor = Color3.fromRGB(45, 212, 191),
		OutlineColor = Color3.fromRGB(255, 255, 255),
		WantedOverride = true,
		TeamCheck = false,
		IgnoreHearseHidden = true,
		FillTransparency = 0.45,
		OutlineTransparency = 0.1,
		FlowSpeed = 2.4,
		WireframeThickness = 1.2,
		MaxDistance = 1200,
	},
}

local R15_BODY_PARTS = {
	"Head",
	"UpperTorso",
	"LowerTorso",
	"LeftUpperArm",
	"LeftLowerArm",
	"LeftHand",
	"RightUpperArm",
	"RightLowerArm",
	"RightHand",
	"LeftUpperLeg",
	"LeftLowerLeg",
	"LeftFoot",
	"RightUpperLeg",
	"RightLowerLeg",
	"RightFoot",
}

local R6_BODY_PARTS = {
	"Head",
	"Torso",
	"Left Arm",
	"Right Arm",
	"Left Leg",
	"Right Leg",
}

-- Ordered top-to-bottom for flowing gradient chams
local R15_FLOW_PARTS = {
	{ Name = "Head", Phase = 0.0 },
	{ Name = "UpperTorso", Phase = 0.7 },
	{ Name = "LeftUpperArm", Phase = 0.8 },
	{ Name = "RightUpperArm", Phase = 0.8 },
	{ Name = "LowerTorso", Phase = 1.4 },
	{ Name = "LeftLowerArm", Phase = 1.5 },
	{ Name = "RightLowerArm", Phase = 1.5 },
	{ Name = "LeftHand", Phase = 2.1 },
	{ Name = "RightHand", Phase = 2.1 },
	{ Name = "LeftUpperLeg", Phase = 2.2 },
	{ Name = "RightUpperLeg", Phase = 2.2 },
	{ Name = "LeftLowerLeg", Phase = 2.9 },
	{ Name = "RightLowerLeg", Phase = 2.9 },
	{ Name = "LeftFoot", Phase = 3.5 },
	{ Name = "RightFoot", Phase = 3.5 },
}

local R6_FLOW_PARTS = {
	{ Name = "Head", Phase = 0.0 },
	{ Name = "Torso", Phase = 1.0 },
	{ Name = "Left Arm", Phase = 1.3 },
	{ Name = "Right Arm", Phase = 1.3 },
	{ Name = "Left Leg", Phase = 2.5 },
	{ Name = "Right Leg", Phase = 2.5 },
}

local WIREFRAME_R15_PARTS = {
	"Head",
	"UpperTorso",
	"LowerTorso",
	"LeftUpperArm",
	"LeftLowerArm",
	"RightUpperArm",
	"RightLowerArm",
	"LeftUpperLeg",
	"LeftLowerLeg",
	"RightUpperLeg",
	"RightLowerLeg",
}

local WIREFRAME_EDGES = {
	{ 1, 2 }, { 2, 4 }, { 4, 3 }, { 3, 1 },
	{ 5, 6 }, { 6, 8 }, { 8, 7 }, { 7, 5 },
	{ 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 },
}

-- 20 anatomical segments: head/neck, spine, clavicles, left/right arms, pelvis, left/right legs
local SKELETON_BONES = {
	{ "HeadCenter", "Neck" },
	{ "Neck", "UpperChest" },
	{ "UpperChest", "Waist" },
	{ "Waist", "Pelvis" },

	{ "UpperChest", "LeftShoulder" },
	{ "LeftShoulder", "LeftElbow" },
	{ "LeftElbow", "LeftWrist" },
	{ "LeftWrist", "LeftHandTip" },

	{ "UpperChest", "RightShoulder" },
	{ "RightShoulder", "RightElbow" },
	{ "RightElbow", "RightWrist" },
	{ "RightWrist", "RightHandTip" },

	{ "Pelvis", "LeftHip" },
	{ "LeftHip", "LeftKnee" },
	{ "LeftKnee", "LeftAnkle" },
	{ "LeftAnkle", "LeftFootTip" },

	{ "Pelvis", "RightHip" },
	{ "RightHip", "RightKnee" },
	{ "RightKnee", "RightAnkle" },
	{ "RightAnkle", "RightFootTip" },
}

local CORNER_SIGNS = {
	Vector3.new(-0.5, -0.5, -0.5),
	Vector3.new( 0.5, -0.5, -0.5),
	Vector3.new(-0.5,  0.5, -0.5),
	Vector3.new( 0.5,  0.5, -0.5),
	Vector3.new(-0.5, -0.5,  0.5),
	Vector3.new( 0.5, -0.5,  0.5),
	Vector3.new(-0.5,  0.5,  0.5),
	Vector3.new( 0.5,  0.5,  0.5),
}

local function new_drawing(kind, props)
	local obj = Drawing.new(kind)
	for k, v in pairs(props) do
		obj[k] = v
	end
	return obj
end

local function is_alive(character, humanoid)
	if not character or not character.Parent then
		return false
	end
	if not humanoid or not humanoid.Parent then
		return false
	end
	if humanoid.Health <= 0 or humanoid:GetAttribute("Dead") == true then
		return false
	end
	if humanoid:GetState() == Enum.HumanoidStateType.Dead then
		return false
	end
	return true
end

local function get_wanted_stars(player)
	local raw = player:GetAttribute("WantedLevel")
	if typeof(raw) ~= "number" or raw <= 0 then
		return 0
	end
	return math.clamp(math.ceil(math.clamp(math.round(raw), 0, 1000) / 200), 0, 5)
end

local function get_esp_color(player, character)
	if CONFIG.ESP.ColorWantedOverride and get_wanted_stars(player) > 0 then
		return CONFIG.ESP.ColorWanted
	end
	if character:GetAttribute("IsDetained") == true or character:GetAttribute("DetainedByUserId") ~= nil then
		return CONFIG.ESP.ColorDetained
	end
	if CONFIG.ESP.ColorUseTeam and player.Team then
		return player.Team.TeamColor.Color
	end
	return CONFIG.ESP.ColorDefault
end

local function build_rig_cache(character)
	local is_r15 = character:FindFirstChild("UpperTorso") ~= nil
	local part_names = is_r15 and R15_BODY_PARTS or R6_BODY_PARTS
	local parts = {}
	for _, name in ipairs(part_names) do
		local p = character:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			parts[name] = p
		end
	end

	local attachments = {}
	if is_r15 then
		local function find_att(part_name, att_name)
			local p = parts[part_name]
			if not p then
				return nil
			end
			local a = p:FindFirstChild(att_name)
			return (a and a:IsA("Attachment")) and a or nil
		end

		attachments.Neck = find_att("UpperTorso", "NeckRigAttachment") or find_att("Head", "NeckRigAttachment")
		attachments.Waist = find_att("LowerTorso", "WaistRigAttachment") or find_att("UpperTorso", "WaistRigAttachment")
		attachments.LeftShoulder = find_att("LeftUpperArm", "LeftShoulderRigAttachment") or find_att("UpperTorso", "LeftShoulderRigAttachment")
		attachments.LeftElbow = find_att("LeftLowerArm", "LeftElbowRigAttachment") or find_att("LeftUpperArm", "LeftElbowRigAttachment")
		attachments.LeftWrist = find_att("LeftHand", "LeftWristRigAttachment") or find_att("LeftLowerArm", "LeftWristRigAttachment")
		attachments.RightShoulder = find_att("RightUpperArm", "RightShoulderRigAttachment") or find_att("UpperTorso", "RightShoulderRigAttachment")
		attachments.RightElbow = find_att("RightLowerArm", "RightElbowRigAttachment") or find_att("RightUpperArm", "RightElbowRigAttachment")
		attachments.RightWrist = find_att("RightHand", "RightWristRigAttachment") or find_att("RightLowerArm", "RightWristRigAttachment")
		attachments.LeftHip = find_att("LeftUpperLeg", "LeftHipRigAttachment") or find_att("LowerTorso", "LeftHipRigAttachment")
		attachments.LeftKnee = find_att("LeftLowerLeg", "LeftKneeRigAttachment") or find_att("LeftUpperLeg", "LeftKneeRigAttachment")
		attachments.LeftAnkle = find_att("LeftFoot", "LeftAnkleRigAttachment") or find_att("LeftLowerLeg", "LeftAnkleRigAttachment")
		attachments.RightHip = find_att("RightUpperLeg", "RightHipRigAttachment") or find_att("LowerTorso", "RightHipRigAttachment")
		attachments.RightKnee = find_att("RightLowerLeg", "RightKneeRigAttachment") or find_att("RightUpperLeg", "RightKneeRigAttachment")
		attachments.RightAnkle = find_att("RightFoot", "RightAnkleRigAttachment") or find_att("RightLowerLeg", "RightAnkleRigAttachment")
	end

	return {
		Character = character,
		IsR15 = is_r15,
		Parts = parts,
		Attachments = attachments,
	}
end

local function part_offset(part, rx, ry, rz)
	return part.CFrame:PointToWorldSpace(Vector3.new(part.Size.X * rx, part.Size.Y * ry, part.Size.Z * rz))
end

local function resolve_joints_world(rig, out_world)
	local p = rig.Parts
	local a = rig.Attachments
	local head = p.Head
	if not head then
		return false
	end

	out_world.HeadCenter = head.Position

	if rig.IsR15 then
		local ut = p.UpperTorso
		local lt = p.LowerTorso
		if not ut or not lt then
			return false
		end

		out_world.Neck = (a.Neck and a.Neck.Parent) and a.Neck.WorldPosition or part_offset(ut, 0, 0.5, 0)
		out_world.UpperChest = part_offset(ut, 0, 0.28, 0)
		out_world.Waist = (a.Waist and a.Waist.Parent) and a.Waist.WorldPosition or part_offset(lt, 0, 0.45, 0)
		out_world.Pelvis = part_offset(lt, 0, -0.3, 0)

		local lua, lla, lh = p.LeftUpperArm, p.LeftLowerArm, p.LeftHand
		out_world.LeftShoulder = (a.LeftShoulder and a.LeftShoulder.Parent) and a.LeftShoulder.WorldPosition
			or (lua and part_offset(lua, 0, 0.35, 0))
		out_world.LeftElbow = (a.LeftElbow and a.LeftElbow.Parent) and a.LeftElbow.WorldPosition
			or (lla and part_offset(lla, 0, 0.45, 0))
		out_world.LeftWrist = (a.LeftWrist and a.LeftWrist.Parent) and a.LeftWrist.WorldPosition
			or (lh and part_offset(lh, 0, 0.4, 0))
		out_world.LeftHandTip = lh and part_offset(lh, 0, -0.4, 0) or out_world.LeftWrist

		local rua, rla, rh = p.RightUpperArm, p.RightLowerArm, p.RightHand
		out_world.RightShoulder = (a.RightShoulder and a.RightShoulder.Parent) and a.RightShoulder.WorldPosition
			or (rua and part_offset(rua, 0, 0.35, 0))
		out_world.RightElbow = (a.RightElbow and a.RightElbow.Parent) and a.RightElbow.WorldPosition
			or (rla and part_offset(rla, 0, 0.45, 0))
		out_world.RightWrist = (a.RightWrist and a.RightWrist.Parent) and a.RightWrist.WorldPosition
			or (rh and part_offset(rh, 0, 0.4, 0))
		out_world.RightHandTip = rh and part_offset(rh, 0, -0.4, 0) or out_world.RightWrist

		local lul, lll, lf = p.LeftUpperLeg, p.LeftLowerLeg, p.LeftFoot
		out_world.LeftHip = (a.LeftHip and a.LeftHip.Parent) and a.LeftHip.WorldPosition
			or (lul and part_offset(lul, 0, 0.4, 0))
		out_world.LeftKnee = (a.LeftKnee and a.LeftKnee.Parent) and a.LeftKnee.WorldPosition
			or (lll and part_offset(lll, 0, 0.45, 0))
		out_world.LeftAnkle = (a.LeftAnkle and a.LeftAnkle.Parent) and a.LeftAnkle.WorldPosition
			or (lf and part_offset(lf, 0, 0.4, 0))
		out_world.LeftFootTip = lf and part_offset(lf, 0, -0.35, -0.25) or out_world.LeftAnkle

		local rul, rll, rf = p.RightUpperLeg, p.RightLowerLeg, p.RightFoot
		out_world.RightHip = (a.RightHip and a.RightHip.Parent) and a.RightHip.WorldPosition
			or (rul and part_offset(rul, 0, 0.4, 0))
		out_world.RightKnee = (a.RightKnee and a.RightKnee.Parent) and a.RightKnee.WorldPosition
			or (rll and part_offset(rll, 0, 0.45, 0))
		out_world.RightAnkle = (a.RightAnkle and a.RightAnkle.Parent) and a.RightAnkle.WorldPosition
			or (rf and part_offset(rf, 0, 0.4, 0))
		out_world.RightFootTip = rf and part_offset(rf, 0, -0.35, -0.25) or out_world.RightAnkle
	else
		local torso = p.Torso
		if not torso then
			return false
		end

		out_world.Neck = part_offset(torso, 0, 0.5, 0)
		out_world.UpperChest = part_offset(torso, 0, 0.32, 0)
		out_world.Waist = torso.Position
		out_world.Pelvis = part_offset(torso, 0, -0.45, 0)

		local la, ra = p["Left Arm"], p["Right Arm"]
		if la then
			out_world.LeftShoulder = part_offset(la, 0, 0.35, 0)
			out_world.LeftElbow = la.Position
			out_world.LeftWrist = part_offset(la, 0, -0.35, 0)
			out_world.LeftHandTip = part_offset(la, 0, -0.48, 0)
		end
		if ra then
			out_world.RightShoulder = part_offset(ra, 0, 0.35, 0)
			out_world.RightElbow = ra.Position
			out_world.RightWrist = part_offset(ra, 0, -0.35, 0)
			out_world.RightHandTip = part_offset(ra, 0, -0.48, 0)
		end

		local ll, rl = p["Left Leg"], p["Right Leg"]
		if ll then
			out_world.LeftHip = part_offset(ll, 0, 0.42, 0)
			out_world.LeftKnee = ll.Position
			out_world.LeftAnkle = part_offset(ll, 0, -0.35, 0)
			out_world.LeftFootTip = part_offset(ll, 0, -0.48, -0.15)
		end
		if rl then
			out_world.RightHip = part_offset(rl, 0, 0.42, 0)
			out_world.RightKnee = rl.Position
			out_world.RightAnkle = part_offset(rl, 0, -0.35, 0)
			out_world.RightFootTip = part_offset(rl, 0, -0.48, -0.15)
		end
	end

	return true
end

local function compute_screen_box(camera, rig)
	local min_x, min_y = math.huge, math.huge
	local max_x, max_y = -math.huge, -math.huge
	local any_visible = false

	for _, part in pairs(rig.Parts) do
		if part.Parent then
			local cf = part.CFrame
			local size = part.Size
			for _, sign in ipairs(CORNER_SIGNS) do
				local world_corner = cf:PointToWorldSpace(Vector3.new(size.X * sign.X, size.Y * sign.Y, size.Z * sign.Z))
				local screen_pos, on_screen = camera:WorldToViewportPoint(world_corner)
				if screen_pos.Z > 0.2 then
					if on_screen then
						any_visible = true
					end
					if screen_pos.X < min_x then min_x = screen_pos.X end
					if screen_pos.Y < min_y then min_y = screen_pos.Y end
					if screen_pos.X > max_x then max_x = screen_pos.X end
					if screen_pos.Y > max_y then max_y = screen_pos.Y end
				end
			end
		end
	end

	if not any_visible or min_x >= max_x or min_y >= max_y then
		return nil
	end
	return min_x, min_y, max_x - min_x, max_y - min_y
end

-- Chams container isolated from target characters
local chams_root = Instance.new("Folder")
chams_root.Name = "OcelHub_Chams"
chams_root.Parent = get_ui_parent()

local entries = {}

local function hide_wireframe(entry)
	if entry.WireLines then
		for i = 1, #entry.WireLines do
			entry.WireLines[i].Visible = false
		end
	end
end

local function ensure_wireframe_pool(entry)
	if entry.WireLines then
		return entry.WireLines
	end
	local lines = {}
	local count = #WIREFRAME_R15_PARTS * #WIREFRAME_EDGES
	for i = 1, count do
		lines[i] = new_drawing("Line", {
			Visible = false,
			Color = CONFIG.Chams.CustomColor,
			Thickness = CONFIG.Chams.WireframeThickness,
			Transparency = 1,
			ZIndex = 1,
		})
	end
	entry.WireLines = lines
	return lines
end

local function clear_adornments(entry)
	for part, adorn in pairs(entry.Adornments) do
		if adorn then
			adorn:Destroy()
		end
		entry.Adornments[part] = nil
	end
end

local function hide_chams(entry)
	if entry.Highlight then
		entry.Highlight.Enabled = false
	end
	for _, adorn in pairs(entry.Adornments) do
		if adorn then
			adorn.Visible = false
		end
	end
	hide_wireframe(entry)
end

local function ensure_highlight(entry, char)
	local hl = entry.Highlight
	if not hl or not hl.Parent then
		hl = Instance.new("Highlight")
		hl.Name = "OcelCham_" .. entry.Player.UserId
		hl.Parent = chams_root
		entry.Highlight = hl
	end
	if hl.Adornee ~= char then
		hl.Adornee = char
	end
	return hl
end

local function ensure_adornments(entry, rig)
	local flow_list = rig.IsR15 and R15_FLOW_PARTS or R6_FLOW_PARTS
	for part, adorn in pairs(entry.Adornments) do
		if not part.Parent or part.Parent ~= rig.Character then
			adorn:Destroy()
			entry.Adornments[part] = nil
		end
	end
	for _, item in ipairs(flow_list) do
		local part = rig.Parts[item.Name]
		if part and part.Parent then
			local adorn = entry.Adornments[part]
			if not adorn or not adorn.Parent then
				adorn = Instance.new("BoxHandleAdornment")
				adorn.Name = "OcelFlow_" .. item.Name
				adorn.Adornee = part
				adorn.Size = part.Size + Vector3.new(0.035, 0.035, 0.035)
				adorn.ZIndex = 5
				adorn.Parent = chams_root
				entry.Adornments[part] = adorn
			else
				adorn.Size = part.Size + Vector3.new(0.035, 0.035, 0.035)
			end
		end
	end
	return flow_list
end

local function resolve_chams_base_color(player)
	if CONFIG.Chams.WantedOverride and get_wanted_stars(player) > 0 then
		return CONFIG.ESP.ColorWanted
	end
	if CONFIG.Chams.ColorMode == "Team" and player.Team then
		return player.Team.TeamColor.Color
	elseif CONFIG.Chams.ColorMode == "Rainbow" then
		local h = (os.clock() * 0.25) % 1
		return Color3.fromHSV(h, 0.85, 1)
	end
	return CONFIG.Chams.CustomColor
end

local function update_chams(entry, player, char, rig, camera, distance, now)
	if not CONFIG.Chams.Enabled or distance > CONFIG.Chams.MaxDistance then
		hide_chams(entry)
		return
	end
	if CONFIG.Chams.TeamCheck and local_player.Team ~= nil and player.Team == local_player.Team then
		hide_chams(entry)
		return
	end
	if CONFIG.Chams.IgnoreHearseHidden and player:GetAttribute("HearseCoffinHidden") == true then
		hide_chams(entry)
		return
	end

	local mode = CONFIG.Chams.Mode
	local depth_mode = CONFIG.Chams.DepthMode == "Occluded"
		and Enum.HighlightDepthMode.Occluded
		or Enum.HighlightDepthMode.AlwaysOnTop
	local always_on_top = (CONFIG.Chams.DepthMode == "AlwaysOnTop")
	local base_color = resolve_chams_base_color(player)
	local outline_color = CONFIG.Chams.OutlineColor
	local speed = CONFIG.Chams.FlowSpeed

	if mode == "Wireframe" then
		for _, adorn in pairs(entry.Adornments) do
			adorn.Visible = false
		end
		local hl = ensure_highlight(entry, char)
		hl.DepthMode = depth_mode
		hl.FillColor = base_color
		hl.OutlineColor = base_color
		hl.FillTransparency = 0.94
		hl.OutlineTransparency = 0.35
		hl.Enabled = true

		local lines = ensure_wireframe_pool(entry)
		local wf_parts = rig.IsR15 and WIREFRAME_R15_PARTS or R6_BODY_PARTS
		local idx = 0
		local corners_2d = {}

		for _, pname in ipairs(wf_parts) do
			local part = rig.Parts[pname]
			if part and part.Parent then
				local cf = part.CFrame
				local size = part.Size
				local all_in_front = true
				for c = 1, 8 do
					local s = CORNER_SIGNS[c]
					local wp = cf:PointToWorldSpace(Vector3.new(size.X * s.X, size.Y * s.Y, size.Z * s.Z))
					local sp = camera:WorldToViewportPoint(wp)
					if sp.Z <= 0.2 then
						all_in_front = false
						break
					end
					corners_2d[c] = Vector2.new(sp.X, sp.Y)
				end
				if all_in_front then
					for _, edge in ipairs(WIREFRAME_EDGES) do
						idx += 1
						local ln = lines[idx]
						ln.From = corners_2d[edge[1]]
						ln.To = corners_2d[edge[2]]
						ln.Color = base_color
						ln.Thickness = CONFIG.Chams.WireframeThickness
						ln.Visible = true
					end
				end
			end
		end
		for i = idx + 1, #lines do
			lines[i].Visible = false
		end
		return
	end

	hide_wireframe(entry)

	if mode == "Water Flow" then
		local flow_list = ensure_adornments(entry, rig)
		local hl = ensure_highlight(entry, char)
		local wave_hl = 0.5 + 0.5 * math.sin(now * speed)
		hl.DepthMode = depth_mode
		hl.FillColor = Color3.fromRGB(0, 150, 255):Lerp(Color3.fromRGB(0, 245, 212), wave_hl)
		hl.OutlineColor = Color3.fromRGB(165, 243, 252)
		hl.FillTransparency = math.clamp(CONFIG.Chams.FillTransparency + 0.2, 0.2, 0.92)
		hl.OutlineTransparency = CONFIG.Chams.OutlineTransparency
		hl.Enabled = true

		local c_deep = Color3.fromRGB(14, 116, 244)
		local c_mid = Color3.fromRGB(0, 196, 255)
		local c_crest = Color3.fromRGB(110, 255, 238)

		for _, item in ipairs(flow_list) do
			local part = rig.Parts[item.Name]
			local adorn = part and entry.Adornments[part]
			if adorn then
				local w = 0.5 + 0.5 * math.sin(now * speed * 1.35 - item.Phase)
				local col = w < 0.5 and c_deep:Lerp(c_mid, w * 2) or c_mid:Lerp(c_crest, (w - 0.5) * 2)
				adorn.Color3 = col
				adorn.AlwaysOnTop = always_on_top
				adorn.Transparency = math.clamp(0.78 - w * 0.34, 0.25, 0.9)
				adorn.Visible = true
			end
		end
		return
	end

	if mode == "Glossy Flow" then
		local flow_list = ensure_adornments(entry, rig)
		local hl = ensure_highlight(entry, char)
		local sweep = 0.5 + 0.5 * math.sin(now * speed)
		hl.DepthMode = depth_mode
		hl.FillColor = base_color:Lerp(Color3.fromRGB(235, 245, 255), sweep * 0.45)
		hl.OutlineColor = Color3.fromRGB(255, 255, 255)
		hl.FillTransparency = CONFIG.Chams.FillTransparency
		hl.OutlineTransparency = math.clamp(CONFIG.Chams.OutlineTransparency * 0.5, 0, 0.8)
		hl.Enabled = true

		local c_base = base_color
		local c_iris = Color3.fromRGB(168, 85, 247)
		local c_spec = Color3.fromRGB(248, 250, 252)

		for _, item in ipairs(flow_list) do
			local part = rig.Parts[item.Name]
			local adorn = part and entry.Adornments[part]
			if adorn then
				local w = 0.5 + 0.5 * math.sin(now * speed * 1.6 - item.Phase * 0.85)
				local col = w < 0.65 and c_base:Lerp(c_iris, w / 0.65) or c_iris:Lerp(c_spec, (w - 0.65) / 0.35)
				adorn.Color3 = col
				adorn.AlwaysOnTop = always_on_top
				adorn.Transparency = math.clamp(0.84 - (w ^ 2) * 0.48, 0.2, 0.92)
				adorn.Visible = true
			end
		end
		return
	end

	-- Highlight-only modes: Solid, Pulse Glow, Thermal, Ghost
	for _, adorn in pairs(entry.Adornments) do
		adorn.Visible = false
	end

	local hl = ensure_highlight(entry, char)
	hl.DepthMode = depth_mode
	hl.Enabled = true

	if mode == "Pulse Glow" then
		local p = 0.5 + 0.5 * math.sin(now * speed * 1.5)
		hl.FillColor = base_color:Lerp(Color3.fromRGB(255, 255, 255), p * 0.35)
		hl.OutlineColor = outline_color
		hl.FillTransparency = math.clamp(0.2 + (1 - p) * 0.65, 0.1, 0.9)
		hl.OutlineTransparency = math.clamp(p * 0.35, 0, 0.8)
	elseif mode == "Thermal" then
		local t = 0.5 + 0.5 * math.sin(now * speed * 1.2)
		hl.FillColor = Color3.fromRGB(255, 45, 32):Lerp(Color3.fromRGB(255, 130, 0), t)
		hl.OutlineColor = Color3.fromRGB(255, 235, 110)
		hl.FillTransparency = 0.28
		hl.OutlineTransparency = 0.05
	elseif mode == "Ghost" then
		local g = 0.5 + 0.5 * math.sin(now * speed)
		hl.FillColor = Color3.fromRGB(125, 211, 252):Lerp(Color3.fromRGB(192, 132, 252), g)
		hl.OutlineColor = Color3.fromRGB(224, 242, 254)
		hl.FillTransparency = 0.72 + g * 0.14
		hl.OutlineTransparency = 0.25
	else -- "Solid"
		hl.FillColor = base_color
		hl.OutlineColor = outline_color
		hl.FillTransparency = CONFIG.Chams.FillTransparency
		hl.OutlineTransparency = CONFIG.Chams.OutlineTransparency
	end
end

local function create_entry(player)
	local skeleton_outlines = {}
	local skeleton_lines = {}
	for i = 1, #SKELETON_BONES do
		skeleton_outlines[i] = new_drawing("Line", {
			Visible = false,
			Color = CONFIG.ESP.ColorOutline,
			Thickness = CONFIG.ESP.SkeletonThickness + 2,
			Transparency = 1,
			ZIndex = 1,
		})
		skeleton_lines[i] = new_drawing("Line", {
			Visible = false,
			Color = CONFIG.ESP.ColorDefault,
			Thickness = CONFIG.ESP.SkeletonThickness,
			Transparency = 1,
			ZIndex = 2,
		})
	end

	local entry = {
		Player = player,
		Rig = nil,
		RigChar = nil,
		WorldJoints = {},
		ScreenJoints = {},
		Highlight = nil,
		Adornments = {},
		WireLines = nil,
		BoxOutline = new_drawing("Square", {
			Visible = false,
			Filled = false,
			Color = CONFIG.ESP.ColorOutline,
			Thickness = CONFIG.ESP.BoxThickness + 2,
			Transparency = 1,
			ZIndex = 1,
		}),
		Box = new_drawing("Square", {
			Visible = false,
			Filled = false,
			Color = CONFIG.ESP.ColorDefault,
			Thickness = CONFIG.ESP.BoxThickness,
			Transparency = 1,
			ZIndex = 2,
		}),
		HealthBg = new_drawing("Line", {
			Visible = false,
			Color = CONFIG.ESP.ColorOutline,
			Thickness = 4,
			Transparency = 1,
			ZIndex = 1,
		}),
		HealthFill = new_drawing("Line", {
			Visible = false,
			Color = Color3.fromRGB(80, 255, 95),
			Thickness = 2,
			Transparency = 1,
			ZIndex = 2,
		}),
		HeadOutline = new_drawing("Circle", {
			Visible = false,
			Filled = false,
			NumSides = 20,
			Color = CONFIG.ESP.ColorOutline,
			Thickness = CONFIG.ESP.SkeletonThickness + 2,
			Transparency = 1,
			ZIndex = 1,
		}),
		HeadCircle = new_drawing("Circle", {
			Visible = false,
			Filled = false,
			NumSides = 20,
			Color = CONFIG.ESP.ColorDefault,
			Thickness = CONFIG.ESP.SkeletonThickness,
			Transparency = 1,
			ZIndex = 2,
		}),
		NameText = new_drawing("Text", {
			Visible = false,
			Center = true,
			Outline = true,
			OutlineColor = CONFIG.ESP.ColorOutline,
			Size = CONFIG.ESP.TextSize,
			Font = 2,
			Color = CONFIG.ESP.ColorDefault,
			Transparency = 1,
			ZIndex = 3,
		}),
		SubText = new_drawing("Text", {
			Visible = false,
			Center = true,
			Outline = true,
			OutlineColor = CONFIG.ESP.ColorOutline,
			Size = math.max(11, CONFIG.ESP.TextSize - 1),
			Font = 2,
			Color = Color3.fromRGB(220, 220, 220),
			Transparency = 1,
			ZIndex = 3,
		}),
		SkeletonOutlines = skeleton_outlines,
		SkeletonLines = skeleton_lines,
		Connections = {},
	}

	local char_child_conn = nil
	local function refresh_rig(char)
		if char_child_conn then
			char_child_conn:Disconnect()
			char_child_conn = nil
		end
		clear_adornments(entry)
		if char then
			local function rebuild()
				if player.Character == char and char.Parent then
					entry.Rig = build_rig_cache(char)
					entry.RigChar = char
				end
			end
			task.defer(rebuild)
			char_child_conn = char.ChildAdded:Connect(function(child)
				if child:IsA("BasePart") then
					rebuild()
				end
			end)
		else
			entry.Rig = nil
			entry.RigChar = nil
		end
	end

	table.insert(entry.Connections, player.CharacterAdded:Connect(refresh_rig))
	table.insert(entry.Connections, player.CharacterRemoving:Connect(function()
		if char_child_conn then
			char_child_conn:Disconnect()
			char_child_conn = nil
		end
		clear_adornments(entry)
		entry.Rig = nil
		entry.RigChar = nil
	end))
	table.insert(entry.Connections, {
		Disconnect = function()
			if char_child_conn then
				char_child_conn:Disconnect()
				char_child_conn = nil
			end
		end,
	})
	if player.Character then
		refresh_rig(player.Character)
	end

	entries[player] = entry
end

local function hide_esp(entry)
	entry.BoxOutline.Visible = false
	entry.Box.Visible = false
	entry.HealthBg.Visible = false
	entry.HealthFill.Visible = false
	entry.HeadOutline.Visible = false
	entry.HeadCircle.Visible = false
	entry.NameText.Visible = false
	entry.SubText.Visible = false
	for i = 1, #SKELETON_BONES do
		entry.SkeletonOutlines[i].Visible = false
		entry.SkeletonLines[i].Visible = false
	end
end

local function hide_entry(entry)
	hide_esp(entry)
	hide_chams(entry)
end

local function remove_entry(player)
	local entry = entries[player]
	if not entry then
		return
	end
	entries[player] = nil
	for _, conn in ipairs(entry.Connections) do
		conn:Disconnect()
	end
	if entry.Highlight then
		entry.Highlight:Destroy()
	end
	clear_adornments(entry)
	if entry.WireLines then
		for i = 1, #entry.WireLines do
			entry.WireLines[i]:Remove()
		end
	end
	entry.BoxOutline:Remove()
	entry.Box:Remove()
	entry.HealthBg:Remove()
	entry.HealthFill:Remove()
	entry.HeadOutline:Remove()
	entry.HeadCircle:Remove()
	entry.NameText:Remove()
	entry.SubText:Remove()
	for i = 1, #SKELETON_BONES do
		entry.SkeletonOutlines[i]:Remove()
		entry.SkeletonLines[i]:Remove()
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	if player ~= local_player then
		create_entry(player)
	end
end

local player_added_conn = Players.PlayerAdded:Connect(function(player)
	if player ~= local_player then
		create_entry(player)
	end
end)

local player_removing_conn = Players.PlayerRemoving:Connect(remove_entry)

-- Aimbot state & FOV drawings
local fov_outline = new_drawing("Circle", {
	Visible = false,
	Filled = false,
	NumSides = 64,
	Color = Color3.fromRGB(0, 0, 0),
	Thickness = 3,
	Transparency = 0.65,
	ZIndex = 1,
})
local fov_circle = new_drawing("Circle", {
	Visible = false,
	Filled = false,
	NumSides = 64,
	Color = CONFIG.Aim.FOVColor,
	Thickness = 1.2,
	Transparency = 0.9,
	ZIndex = 2,
})

local aim_toggled = false
local locked_player = nil
local wall_ray_params = RaycastParams.new()
wall_ray_params.FilterType = Enum.RaycastFilterType.Exclude
wall_ray_params.IgnoreWater = true

local AIM_KEY_MAP = {
	RMB = { Kind = "Mouse", Code = Enum.UserInputType.MouseButton2 },
	E = { Kind = "Key", Code = Enum.KeyCode.E },
	Q = { Kind = "Key", Code = Enum.KeyCode.Q },
	X = { Kind = "Key", Code = Enum.KeyCode.X },
	LeftAlt = { Kind = "Key", Code = Enum.KeyCode.LeftAlt },
	LeftShift = { Kind = "Key", Code = Enum.KeyCode.LeftShift },
}

local function is_aim_key_down()
	if CONFIG.Aim.Mode == "Always" then
		return true
	end
	if CONFIG.Aim.Mode == "Toggle" then
		return aim_toggled
	end
	local spec = AIM_KEY_MAP[CONFIG.Aim.Key] or AIM_KEY_MAP.RMB
	if spec.Kind == "Mouse" then
		return UserInputService:IsMouseButtonPressed(spec.Code)
	end
	return UserInputService:IsKeyDown(spec.Code)
end

local function is_part_visible(camera, origin, target_part, target_char)
	local filter = {}
	if local_player.Character then
		table.insert(filter, local_player.Character)
	end
	wall_ray_params.FilterDescendantsInstances = filter
	local dir = target_part.Position - origin
	local result = Workspace:Raycast(origin, dir, wall_ray_params)
	if not result then
		return true
	end
	return result.Instance:IsDescendantOf(target_char)
end

local function pick_aim_part(camera, char, rig, screen_center)
	local mode = CONFIG.Aim.TargetPart
	if mode == "Closest" then
		local best_part = nil
		local best_dist = math.huge
		local candidates = { "Head", "UpperTorso", "Torso", "LowerTorso", "HumanoidRootPart" }
		for _, name in ipairs(candidates) do
			local p = rig.Parts[name] or char:FindFirstChild(name)
			if p and p:IsA("BasePart") then
				local sp, on_screen = camera:WorldToViewportPoint(p.Position)
				if sp.Z > 0.2 and on_screen then
					local d = (Vector2.new(sp.X, sp.Y) - screen_center).Magnitude
					if d < best_dist then
						best_dist = d
						best_part = p
					end
				end
			end
		end
		return best_part
	end

	local p = rig.Parts[mode] or char:FindFirstChild(mode)
	if p and p:IsA("BasePart") then
		return p
	end
	return rig.Parts.UpperTorso or rig.Parts.Torso or rig.Parts.Head or char:FindFirstChild("HumanoidRootPart")
end

local function get_aim_target(camera, screen_center)
	local origin = camera.CFrame.Position

	local function validate(player, fov_limit)
		local entry = entries[player]
		if not entry then
			return nil
		end
		local char = player.Character
		if not char or not char.Parent then
			return nil
		end
		if CONFIG.Aim.TeamCheck and local_player.Team ~= nil and player.Team == local_player.Team then
			return nil
		end
		if CONFIG.Aim.IgnoreHearseHidden and player:GetAttribute("HearseCoffinHidden") == true then
			return nil
		end
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		local root = (humanoid and humanoid.RootPart) or char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
		if not root or not is_alive(char, humanoid) then
			return nil
		end
		if (root.Position - origin).Magnitude > CONFIG.Aim.MaxDistance then
			return nil
		end
		local rig = entry.Rig or build_rig_cache(char)
		local target_part = pick_aim_part(camera, char, rig, screen_center)
		if not target_part then
			return nil
		end
		local sp, on_screen = camera:WorldToViewportPoint(target_part.Position)
		if sp.Z <= 0.2 or not on_screen then
			return nil
		end
		local dist_2d = (Vector2.new(sp.X, sp.Y) - screen_center).Magnitude
		if dist_2d > fov_limit then
			return nil
		end
		if CONFIG.Aim.WallCheck and not is_part_visible(camera, origin, target_part, char) then
			return nil
		end
		return target_part, dist_2d
	end

	if CONFIG.Aim.StickyTarget and locked_player then
		local sticky_part = validate(locked_player, CONFIG.Aim.FOV * 1.25)
		if sticky_part then
			return locked_player, sticky_part
		end
		locked_player = nil
	end

	local best_player, best_part, best_fov = nil, nil, CONFIG.Aim.FOV
	for player in pairs(entries) do
		local part, dist_2d = validate(player, best_fov)
		if part and dist_2d < best_fov then
			best_fov = dist_2d
			best_player = player
			best_part = part
		end
	end
	locked_player = best_player
	return best_player, best_part
end

-- Main ESP + Chams render loop
local render_conn = RunService.RenderStepped:Connect(function()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	local now = os.clock()
	local cam_pos = camera.CFrame.Position
	local vp = camera.ViewportSize
	local screen_center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)

	if CONFIG.Aim.Enabled and CONFIG.Aim.ShowFOV then
		fov_outline.Position = screen_center
		fov_outline.Radius = CONFIG.Aim.FOV
		fov_outline.Visible = true
		fov_circle.Position = screen_center
		fov_circle.Radius = CONFIG.Aim.FOV
		fov_circle.Color = CONFIG.Aim.FOVColor
		fov_circle.Visible = true
	else
		fov_outline.Visible = false
		fov_circle.Visible = false
	end

	for player, entry in pairs(entries) do
		local char = player.Character
		if not char or not char.Parent then
			hide_entry(entry)
			continue
		end

		local humanoid = char:FindFirstChildOfClass("Humanoid")
		local root = (humanoid and humanoid.RootPart) or char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
		if not root or not is_alive(char, humanoid) then
			hide_entry(entry)
			continue
		end

		local distance = (root.Position - cam_pos).Magnitude
		if entry.RigChar ~= char or not entry.Rig then
			entry.Rig = build_rig_cache(char)
			entry.RigChar = char
		end
		local rig = entry.Rig
		if not rig.Parts.Head or (rig.IsR15 and (not rig.Parts.UpperTorso or not rig.Parts.LowerTorso)) then
			entry.Rig = build_rig_cache(char)
			rig = entry.Rig
		end

		update_chams(entry, player, char, rig, camera, distance, now)

		if not CONFIG.ESP.Enabled or distance > CONFIG.ESP.MaxDistance then
			hide_esp(entry)
			continue
		end
		if CONFIG.ESP.TeamCheck and local_player.Team ~= nil and player.Team == local_player.Team then
			hide_esp(entry)
			continue
		end
		if CONFIG.ESP.IgnoreHearseHidden and player:GetAttribute("HearseCoffinHidden") == true then
			hide_esp(entry)
			continue
		end
		if CONFIG.ESP.IgnoreModeratorHidden and (player:GetAttribute("ModeratorHidden") == true or player:GetAttribute("ModeratorInvisible") == true) then
			hide_esp(entry)
			continue
		end

		local bx, by, bw, bh = compute_screen_box(camera, rig)
		if not bx then
			hide_esp(entry)
			continue
		end

		local color = get_esp_color(player, char)

		if CONFIG.ESP.ShowBox then
			local box_pos = Vector2.new(bx, by)
			local box_size = Vector2.new(bw, bh)
			if CONFIG.ESP.BoxOutline then
				entry.BoxOutline.Position = box_pos
				entry.BoxOutline.Size = box_size
				entry.BoxOutline.Thickness = CONFIG.ESP.BoxThickness + 2
				entry.BoxOutline.Visible = true
			else
				entry.BoxOutline.Visible = false
			end
			entry.Box.Position = box_pos
			entry.Box.Size = box_size
			entry.Box.Color = color
			entry.Box.Thickness = CONFIG.ESP.BoxThickness
			entry.Box.Visible = true
		else
			entry.BoxOutline.Visible = false
			entry.Box.Visible = false
		end

		if CONFIG.ESP.ShowHealthBar then
			local max_hp = math.max(humanoid.MaxHealth, 1)
			local frac = math.clamp(humanoid.Health / max_hp, 0, 1)
			local bar_x = bx - 5
			local top_y = by
			local bot_y = by + bh
			local fill_top_y = bot_y - (bh * frac)

			entry.HealthBg.From = Vector2.new(bar_x, top_y - 1)
			entry.HealthBg.To = Vector2.new(bar_x, bot_y + 1)
			entry.HealthBg.Visible = true

			entry.HealthFill.From = Vector2.new(bar_x, bot_y)
			entry.HealthFill.To = Vector2.new(bar_x, fill_top_y)
			entry.HealthFill.Color = Color3.fromRGB(math.floor(255 * (1 - frac)), math.floor(255 * frac), 55)
			entry.HealthFill.Visible = true
		else
			entry.HealthBg.Visible = false
			entry.HealthFill.Visible = false
		end

		local center_x = bx + bw * 0.5
		if CONFIG.ESP.ShowName then
			local label = player.DisplayName ~= "" and player.DisplayName or player.Name
			if CONFIG.ESP.ShowWanted then
				local stars = get_wanted_stars(player)
				if stars > 0 then
					label = string.format("%s [W%d]", label, stars)
				end
			end
			if char:GetAttribute("IsDetained") == true then
				label = label .. " [CUFF]"
			end
			entry.NameText.Text = label
			entry.NameText.Position = Vector2.new(center_x, by - CONFIG.ESP.TextSize - 3)
			entry.NameText.Color = color
			entry.NameText.Visible = true
		else
			entry.NameText.Visible = false
		end

		if CONFIG.ESP.ShowDistance or CONFIG.ESP.ShowTeamTag then
			local parts_txt = {}
			if CONFIG.ESP.ShowTeamTag and player.Team then
				table.insert(parts_txt, player.Team.Name)
			end
			if CONFIG.ESP.ShowDistance then
				table.insert(parts_txt, string.format("%dm", math.floor(distance + 0.5)))
			end
			entry.SubText.Text = table.concat(parts_txt, " | ")
			entry.SubText.Position = Vector2.new(center_x, by + bh + 2)
			entry.SubText.Visible = true
		else
			entry.SubText.Visible = false
		end

		if CONFIG.ESP.ShowSkeleton then
			local wjoints = entry.WorldJoints
			local sjoints = entry.ScreenJoints
			table.clear(wjoints)
			table.clear(sjoints)

			if resolve_joints_world(rig, wjoints) then
				for jname, wpos in pairs(wjoints) do
					local sp = camera:WorldToViewportPoint(wpos)
					if sp.Z > 0.2 then
						sjoints[jname] = Vector2.new(sp.X, sp.Y)
					end
				end

				for i, bone in ipairs(SKELETON_BONES) do
					local p1 = sjoints[bone[1]]
					local p2 = sjoints[bone[2]]
					if p1 and p2 then
						if CONFIG.ESP.SkeletonOutline then
							entry.SkeletonOutlines[i].From = p1
							entry.SkeletonOutlines[i].To = p2
							entry.SkeletonOutlines[i].Thickness = CONFIG.ESP.SkeletonThickness + 2
							entry.SkeletonOutlines[i].Visible = true
						else
							entry.SkeletonOutlines[i].Visible = false
						end
						entry.SkeletonLines[i].From = p1
						entry.SkeletonLines[i].To = p2
						entry.SkeletonLines[i].Color = color
						entry.SkeletonLines[i].Thickness = CONFIG.ESP.SkeletonThickness
						entry.SkeletonLines[i].Visible = true
					else
						entry.SkeletonOutlines[i].Visible = false
						entry.SkeletonLines[i].Visible = false
					end
				end

				local head_part = rig.Parts.Head
				local head_screen = sjoints.HeadCenter
				if CONFIG.ESP.ShowHeadCircle and head_part and head_screen then
					local head_top_sp = camera:WorldToViewportPoint(head_part.Position + camera.CFrame.UpVector * (head_part.Size.Y * 0.52))
					local radius = head_top_sp.Z > 0.2 and math.clamp((Vector2.new(head_top_sp.X, head_top_sp.Y) - head_screen).Magnitude, 2, 42) or 4
					if CONFIG.ESP.SkeletonOutline then
						entry.HeadOutline.Position = head_screen
						entry.HeadOutline.Radius = radius
						entry.HeadOutline.Thickness = CONFIG.ESP.SkeletonThickness + 2
						entry.HeadOutline.Visible = true
					else
						entry.HeadOutline.Visible = false
					end
					entry.HeadCircle.Position = head_screen
					entry.HeadCircle.Radius = radius
					entry.HeadCircle.Color = color
					entry.HeadCircle.Thickness = CONFIG.ESP.SkeletonThickness
					entry.HeadCircle.Visible = true
				else
					entry.HeadOutline.Visible = false
					entry.HeadCircle.Visible = false
				end
			else
				entry.HeadOutline.Visible = false
				entry.HeadCircle.Visible = false
				for i = 1, #SKELETON_BONES do
					entry.SkeletonOutlines[i].Visible = false
					entry.SkeletonLines[i].Visible = false
				end
			end
		else
			entry.HeadOutline.Visible = false
			entry.HeadCircle.Visible = false
			for i = 1, #SKELETON_BONES do
				entry.SkeletonOutlines[i].Visible = false
				entry.SkeletonLines[i].Visible = false
			end
		end
	end
end)

-- Aimbot bound after San Diego CameraController (+5) & CameraShaker (+6)
local AIM_BIND_NAME = "OcelHub_AimbotStep"
RunService:BindToRenderStep(AIM_BIND_NAME, Enum.RenderPriority.Camera.Value + 10, function(dt)
	if not CONFIG.Aim.Enabled then
		locked_player = nil
		return
	end
	if CONFIG.MenuOpen and UserInputService:GetFocusedTextBox() then
		return
	end
	if not is_aim_key_down() then
		locked_player = nil
		return
	end

	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	local vp = camera.ViewportSize
	local screen_center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
	local _, target_part = get_aim_target(camera, screen_center)
	if not target_part then
		return
	end

	local aim_pos = target_part.Position
	if CONFIG.Aim.Prediction then
		aim_pos = aim_pos + target_part.AssemblyLinearVelocity * CONFIG.Aim.PredictionAmount
	end

	local cam_pos = camera.CFrame.Position
	local desired = CFrame.lookAt(cam_pos, aim_pos)
	if CONFIG.Aim.Smoothness <= 1 then
		camera.CFrame = desired
	else
		local alpha = 1 - math.exp(-dt * (32 / CONFIG.Aim.Smoothness))
		camera.CFrame = camera.CFrame:Lerp(desired, math.clamp(alpha, 0.02, 1))
	end
end)

-- ============================================================================
-- Ocel-hub UI
-- ============================================================================
local gui = Instance.new("ScreenGui")
gui.Name = "OcelHub_UI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
gui.Parent = get_ui_parent()

local THEME = {
	Bg = Color3.fromRGB(11, 15, 23),
	Sidebar = Color3.fromRGB(15, 20, 31),
	Card = Color3.fromRGB(18, 25, 38),
	Control = Color3.fromRGB(25, 34, 52),
	Stroke = Color3.fromRGB(38, 50, 74),
	Accent = Color3.fromRGB(45, 212, 191),
	AccentDim = Color3.fromRGB(20, 83, 78),
	Text = Color3.fromRGB(241, 245, 249),
	Muted = Color3.fromRGB(148, 163, 184),
	Danger = Color3.fromRGB(239, 68, 68),
}

local function add_corner(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = inst
	return c
end

local function add_stroke(inst, col, thick)
	local s = Instance.new("UIStroke")
	s.Color = col or THEME.Stroke
	s.Thickness = thick or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return s
end

local main = Instance.new("Frame")
main.Name = "MainFrame"
main.Size = UDim2.new(0, 520, 0, 390)
main.Position = UDim2.new(0.5, -260, 0.5, -195)
main.BackgroundColor3 = THEME.Bg
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui
add_corner(main, 12)
add_stroke(main, THEME.Stroke, 1.2)

-- Top Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundColor3 = THEME.Sidebar
header.BorderSizePixel = 0
header.Parent = main

local header_line = Instance.new("Frame")
header_line.Size = UDim2.new(1, 0, 0, 1)
header_line.Position = UDim2.new(0, 0, 1, -1)
header_line.BackgroundColor3 = THEME.Stroke
header_line.BorderSizePixel = 0
header_line.Parent = header

local dot = Instance.new("Frame")
dot.Size = UDim2.new(0, 8, 0, 8)
dot.Position = UDim2.new(0, 14, 0.5, -4)
dot.BackgroundColor3 = THEME.Accent
dot.BorderSizePixel = 0
dot.Parent = header
add_corner(dot, 99)

local title_lbl = Instance.new("TextLabel")
title_lbl.Size = UDim2.new(0, 120, 1, 0)
title_lbl.Position = UDim2.new(0, 30, 0, 0)
title_lbl.BackgroundTransparency = 1
title_lbl.Font = Enum.Font.GothamBold
title_lbl.Text = "Ocel-hub"
title_lbl.TextColor3 = THEME.Text
title_lbl.TextSize = 15
title_lbl.TextXAlignment = Enum.TextXAlignment.Left
title_lbl.Parent = header

local badge = Instance.new("TextLabel")
badge.Size = UDim2.new(0, 78, 0, 18)
badge.Position = UDim2.new(0, 108, 0.5, -9)
badge.BackgroundColor3 = THEME.AccentDim
badge.Font = Enum.Font.GothamSemibold
badge.Text = "SAN DIEGO"
badge.TextColor3 = THEME.Accent
badge.TextSize = 10
badge.Parent = header
add_corner(badge, 5)

local min_btn = Instance.new("TextButton")
min_btn.Size = UDim2.new(0, 26, 0, 24)
min_btn.Position = UDim2.new(1, -64, 0.5, -12)
min_btn.BackgroundColor3 = THEME.Control
min_btn.Font = Enum.Font.GothamBold
min_btn.Text = "-"
min_btn.TextColor3 = THEME.Muted
min_btn.TextSize = 15
min_btn.AutoButtonColor = false
min_btn.Parent = header
add_corner(min_btn, 6)

local close_btn = Instance.new("TextButton")
close_btn.Size = UDim2.new(0, 26, 0, 24)
close_btn.Position = UDim2.new(1, -34, 0.5, -12)
close_btn.BackgroundColor3 = THEME.Control
close_btn.Font = Enum.Font.GothamBold
close_btn.Text = "x"
close_btn.TextColor3 = THEME.Muted
close_btn.TextSize = 13
close_btn.AutoButtonColor = false
close_btn.Parent = header
add_corner(close_btn, 6)

-- Dragging
local ui_conns = {}
local dragging, drag_start, start_pos = false, nil, nil
table.insert(ui_conns, header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		drag_start = input.Position
		start_pos = main.Position
	end
end))
table.insert(ui_conns, UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - drag_start
		main.Position = UDim2.new(start_pos.X.Scale, start_pos.X.Offset + delta.X, start_pos.Y.Scale, start_pos.Y.Offset + delta.Y)
	end
end))
table.insert(ui_conns, UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end))

-- Sidebar
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 128, 1, -42)
sidebar.Position = UDim2.new(0, 0, 0, 42)
sidebar.BackgroundColor3 = THEME.Sidebar
sidebar.BorderSizePixel = 0
sidebar.Parent = main

local side_border = Instance.new("Frame")
side_border.Size = UDim2.new(0, 1, 1, 0)
side_border.Position = UDim2.new(1, -1, 0, 0)
side_border.BackgroundColor3 = THEME.Stroke
side_border.BorderSizePixel = 0
side_border.Parent = sidebar

local tab_list = Instance.new("Frame")
tab_list.Size = UDim2.new(1, -16, 1, -44)
tab_list.Position = UDim2.new(0, 8, 0, 10)
tab_list.BackgroundTransparency = 1
tab_list.Parent = sidebar

local tab_layout = Instance.new("UIListLayout")
tab_layout.Padding = UDim.new(0, 6)
tab_layout.Parent = tab_list

local hint_lbl = Instance.new("TextLabel")
hint_lbl.Size = UDim2.new(1, -16, 0, 26)
hint_lbl.Position = UDim2.new(0, 8, 1, -32)
hint_lbl.BackgroundTransparency = 1
hint_lbl.Font = Enum.Font.Gotham
hint_lbl.Text = "RShift: Menu | F3: ESP"
hint_lbl.TextColor3 = THEME.Muted
hint_lbl.TextSize = 10
hint_lbl.Parent = sidebar

local content_holder = Instance.new("Frame")
content_holder.Size = UDim2.new(1, -128, 1, -42)
content_holder.Position = UDim2.new(0, 128, 0, 42)
content_holder.BackgroundTransparency = 1
content_holder.Parent = main

local pages = {}
local tab_buttons = {}
local active_tab = nil

local function select_tab(name)
	active_tab = name
	for tname, page in pairs(pages) do
		page.Visible = (tname == name)
	end
	for tname, info in pairs(tab_buttons) do
		local is_on = (tname == name)
		TweenService:Create(info.Btn, TweenInfo.new(0.15), {
			BackgroundColor3 = is_on and THEME.Control or THEME.Sidebar,
			TextColor3 = is_on and THEME.Text or THEME.Muted,
		}):Play()
		info.Bar.Visible = is_on
	end
end

local function create_tab(name)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 32)
	btn.BackgroundColor3 = THEME.Sidebar
	btn.Font = Enum.Font.GothamSemibold
	btn.Text = "   " .. name
	btn.TextColor3 = THEME.Muted
	btn.TextSize = 13
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.AutoButtonColor = false
	btn.Parent = tab_list
	add_corner(btn, 7)

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 3, 0, 18)
	bar.Position = UDim2.new(0, 0, 0.5, -9)
	bar.BackgroundColor3 = THEME.Accent
	bar.BorderSizePixel = 0
	bar.Visible = false
	bar.Parent = btn
	add_corner(bar, 2)

	local page = Instance.new("ScrollingFrame")
	page.Size = UDim2.new(1, -16, 1, -16)
	page.Position = UDim2.new(0, 8, 0, 8)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = THEME.Stroke
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.Visible = false
	page.Parent = content_holder

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 7)
	layout.Parent = page

	local pad = Instance.new("UIPadding")
	pad.PaddingRight = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.Parent = page

	pages[name] = page
	tab_buttons[name] = { Btn = btn, Bar = bar }

	table.insert(ui_conns, btn.MouseButton1Click:Connect(function()
		select_tab(name)
	end))

	return page
end

local function add_section(page, text)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 18)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.Text = string.upper(text)
	lbl.TextColor3 = THEME.Accent
	lbl.TextSize = 10
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = page
end

local function add_toggle(page, label_text, tbl, key)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 34)
	card.BackgroundColor3 = THEME.Card
	card.BorderSizePixel = 0
	card.Parent = page
	add_corner(card, 7)
	add_stroke(card, THEME.Stroke, 1)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -60, 1, 0)
	lbl.Position = UDim2.new(0, 12, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamMedium
	lbl.Text = label_text
	lbl.TextColor3 = THEME.Text
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = card

	local track = Instance.new("TextButton")
	track.Size = UDim2.new(0, 38, 0, 20)
	track.Position = UDim2.new(1, -48, 0.5, -10)
	track.BackgroundColor3 = tbl[key] and THEME.Accent or THEME.Control
	track.Text = ""
	track.AutoButtonColor = false
	track.Parent = card
	add_corner(track, 99)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 14, 0, 14)
	knob.Position = tbl[key] and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.Parent = track
	add_corner(knob, 99)

	local function refresh(state)
		TweenService:Create(track, TweenInfo.new(0.14), {
			BackgroundColor3 = state and THEME.Accent or THEME.Control,
		}):Play()
		TweenService:Create(knob, TweenInfo.new(0.14), {
			Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
		}):Play()
	end

	table.insert(ui_conns, track.MouseButton1Click:Connect(function()
		tbl[key] = not tbl[key]
		refresh(tbl[key])
	end))

	return refresh
end

local function format_cycle_opt(opt)
	if type(opt) == "table" and opt.Name ~= nil then
		return opt.Name, opt.Value
	end
	if typeof(opt) == "EnumItem" then
		return opt.Name, opt
	end
	return tostring(opt), opt
end

local function add_cycle(page, label_text, options, tbl, key)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 34)
	card.BackgroundColor3 = THEME.Card
	card.BorderSizePixel = 0
	card.Parent = page
	add_corner(card, 7)
	add_stroke(card, THEME.Stroke, 1)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.52, -12, 1, 0)
	lbl.Position = UDim2.new(0, 12, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamMedium
	lbl.Text = label_text
	lbl.TextColor3 = THEME.Text
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = card

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.48, -14, 0, 22)
	btn.Position = UDim2.new(0.52, 4, 0.5, -11)
	btn.BackgroundColor3 = THEME.Control
	btn.Font = Enum.Font.GothamSemibold
	btn.TextColor3 = THEME.Accent
	btn.TextSize = 11
	btn.AutoButtonColor = false
	btn.Parent = card
	add_corner(btn, 5)
	add_stroke(btn, THEME.Stroke, 1)

	local cur_idx = 1
	for i, opt in ipairs(options) do
		local _, val = format_cycle_opt(opt)
		if val == tbl[key] then
			cur_idx = i
			break
		end
	end
	local init_name, init_val = format_cycle_opt(options[cur_idx])
	btn.Text = init_name
	if typeof(init_val) == "Color3" then
		btn.TextColor3 = init_val
	end

	table.insert(ui_conns, btn.MouseButton1Click:Connect(function()
		cur_idx = (cur_idx % #options) + 1
		local name, val = format_cycle_opt(options[cur_idx])
		tbl[key] = val
		btn.Text = name
		if typeof(val) == "Color3" then
			btn.TextColor3 = val
		end
	end))
end

local function add_slider(page, label_text, min_val, max_val, step, tbl, key)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 44)
	card.BackgroundColor3 = THEME.Card
	card.BorderSizePixel = 0
	card.Parent = page
	add_corner(card, 7)
	add_stroke(card, THEME.Stroke, 1)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.7, -12, 0, 20)
	lbl.Position = UDim2.new(0, 12, 0, 4)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamMedium
	lbl.Text = label_text
	lbl.TextColor3 = THEME.Text
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = card

	local val_lbl = Instance.new("TextLabel")
	val_lbl.Size = UDim2.new(0.3, -12, 0, 20)
	val_lbl.Position = UDim2.new(0.7, 0, 0, 4)
	val_lbl.BackgroundTransparency = 1
	val_lbl.Font = Enum.Font.GothamBold
	val_lbl.Text = tostring(tbl[key])
	val_lbl.TextColor3 = THEME.Accent
	val_lbl.TextSize = 11
	val_lbl.TextXAlignment = Enum.TextXAlignment.Right
	val_lbl.Parent = card

	local bar_bg = Instance.new("TextButton")
	bar_bg.Size = UDim2.new(1, -24, 0, 6)
	bar_bg.Position = UDim2.new(0, 12, 0, 29)
	bar_bg.BackgroundColor3 = THEME.Control
	bar_bg.Text = ""
	bar_bg.AutoButtonColor = false
	bar_bg.Parent = card
	add_corner(bar_bg, 99)

	local fill = Instance.new("Frame")
	local init_pct = math.clamp((tbl[key] - min_val) / (max_val - min_val), 0, 1)
	fill.Size = UDim2.new(init_pct, 0, 1, 0)
	fill.BackgroundColor3 = THEME.Accent
	fill.BorderSizePixel = 0
	fill.Parent = bar_bg
	add_corner(fill, 99)

	local sliding = false
	local function set_from_x(x)
		local abs_pos = bar_bg.AbsolutePosition.X
		local abs_size = math.max(bar_bg.AbsoluteSize.X, 1)
		local pct = math.clamp((x - abs_pos) / abs_size, 0, 1)
		local raw = min_val + (max_val - min_val) * pct
		local snapped = math.floor(raw / step + 0.5) * step
		snapped = math.clamp(tonumber(string.format("%.2f", snapped)), min_val, max_val)
		tbl[key] = snapped
		val_lbl.Text = tostring(snapped)
		fill.Size = UDim2.new((snapped - min_val) / (max_val - min_val), 0, 1, 0)
	end

	table.insert(ui_conns, bar_bg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			sliding = true
			set_from_x(input.Position.X)
		end
	end))
	table.insert(ui_conns, UserInputService.InputChanged:Connect(function(input)
		if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
			set_from_x(input.Position.X)
		end
	end))
	table.insert(ui_conns, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			sliding = false
		end
	end))
end

local function add_button(page, text, col, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 32)
	btn.BackgroundColor3 = col or THEME.Control
	btn.Font = Enum.Font.GothamSemibold
	btn.Text = text
	btn.TextColor3 = THEME.Text
	btn.TextSize = 12
	btn.AutoButtonColor = false
	btn.Parent = page
	add_corner(btn, 7)
	add_stroke(btn, THEME.Stroke, 1)

	table.insert(ui_conns, btn.MouseButton1Click:Connect(callback))
	return btn
end

-- Build Pages
local aim_page = create_tab("Aimbot")
add_section(aim_page, "Aim Lock")
add_toggle(aim_page, "Enable Aimbot", CONFIG.Aim, "Enabled")
add_cycle(aim_page, "Aim Mode", { "Hold", "Toggle", "Always" }, CONFIG.Aim, "Mode")
add_cycle(aim_page, "Aim Key", { "RMB", "E", "Q", "X", "LeftAlt", "LeftShift" }, CONFIG.Aim, "Key")
add_cycle(aim_page, "Target Bone", { "Head", "UpperTorso", "HumanoidRootPart", "Closest" }, CONFIG.Aim, "TargetPart")
add_slider(aim_page, "FOV Radius", 25, 500, 5, CONFIG.Aim, "FOV")
add_slider(aim_page, "Smoothness (1 = Snap)", 1, 20, 1, CONFIG.Aim, "Smoothness")
add_section(aim_page, "Checks & Assist")
add_toggle(aim_page, "Show FOV Circle", CONFIG.Aim, "ShowFOV")
add_toggle(aim_page, "Wall Check", CONFIG.Aim, "WallCheck")
add_toggle(aim_page, "Sticky Target", CONFIG.Aim, "StickyTarget")
add_toggle(aim_page, "Team Check", CONFIG.Aim, "TeamCheck")
add_toggle(aim_page, "Velocity Prediction", CONFIG.Aim, "Prediction")
add_slider(aim_page, "Prediction Factor", 0.02, 0.25, 0.01, CONFIG.Aim, "PredictionAmount")

local esp_page = create_tab("ESP")
add_section(esp_page, "Visuals")
local refresh_esp_toggle = add_toggle(esp_page, "Enable ESP (F3)", CONFIG.ESP, "Enabled")
add_toggle(esp_page, "2D Bounding Boxes", CONFIG.ESP, "ShowBox")
add_toggle(esp_page, "Box Outline", CONFIG.ESP, "BoxOutline")
add_toggle(esp_page, "Anatomical Skeleton", CONFIG.ESP, "ShowSkeleton")
add_toggle(esp_page, "Head Circle", CONFIG.ESP, "ShowHeadCircle")
add_toggle(esp_page, "Health Bar", CONFIG.ESP, "ShowHealthBar")
add_toggle(esp_page, "Name & Wanted/Cuff", CONFIG.ESP, "ShowName")
add_toggle(esp_page, "Team & Distance", CONFIG.ESP, "ShowDistance")
add_section(esp_page, "Filters")
add_slider(esp_page, "Max Distance", 200, 3000, 50, CONFIG.ESP, "MaxDistance")
add_toggle(esp_page, "Team Check", CONFIG.ESP, "TeamCheck")
add_toggle(esp_page, "Ignore Hearse Coffin", CONFIG.ESP, "IgnoreHearseHidden")
add_toggle(esp_page, "Ignore Hidden Mods", CONFIG.ESP, "IgnoreModeratorHidden")

local chams_page = create_tab("Chams")
add_section(chams_page, "Chams Variety")
add_toggle(chams_page, "Enable Chams", CONFIG.Chams, "Enabled")
add_cycle(chams_page, "Style", {
	"Water Flow",
	"Glossy Flow",
	"Wireframe",
	"Solid",
	"Pulse Glow",
	"Thermal",
	"Ghost",
}, CONFIG.Chams, "Mode")
add_cycle(chams_page, "Depth Mode", { "AlwaysOnTop", "Occluded" }, CONFIG.Chams, "DepthMode")
add_cycle(chams_page, "Color Source", { "Custom", "Team", "Rainbow" }, CONFIG.Chams, "ColorMode")
add_cycle(chams_page, "Custom Color", {
	{ Name = "Teal", Value = Color3.fromRGB(45, 212, 191) },
	{ Name = "Sky Blue", Value = Color3.fromRGB(56, 189, 248) },
	{ Name = "Violet", Value = Color3.fromRGB(168, 85, 247) },
	{ Name = "Crimson", Value = Color3.fromRGB(244, 63, 94) },
	{ Name = "Emerald", Value = Color3.fromRGB(34, 197, 94) },
	{ Name = "Amber", Value = Color3.fromRGB(245, 158, 11) },
}, CONFIG.Chams, "CustomColor")
add_section(chams_page, "Tuning & Filters")
add_slider(chams_page, "Flow / Pulse Speed", 0.5, 6.0, 0.1, CONFIG.Chams, "FlowSpeed")
add_slider(chams_page, "Fill Transparency", 0, 0.95, 0.05, CONFIG.Chams, "FillTransparency")
add_slider(chams_page, "Outline Transparency", 0, 1, 0.05, CONFIG.Chams, "OutlineTransparency")
add_slider(chams_page, "Max Distance", 200, 2500, 50, CONFIG.Chams, "MaxDistance")
add_toggle(chams_page, "Wanted Red Override", CONFIG.Chams, "WantedOverride")
add_toggle(chams_page, "Team Check", CONFIG.Chams, "TeamCheck")

local cfg_page = create_tab("Config")
add_section(cfg_page, "Ocel-hub Controls")
add_cycle(cfg_page, "Menu Toggle Key", { Enum.KeyCode.RightShift, Enum.KeyCode.Insert, Enum.KeyCode.F4 }, CONFIG, "MenuKey")
add_cycle(cfg_page, "ESP Toggle Key", { Enum.KeyCode.F3, Enum.KeyCode.F2, Enum.KeyCode.F5 }, CONFIG, "EspToggleKey")

local controller

add_button(cfg_page, "Unload Ocel-hub", Color3.fromRGB(127, 29, 29), function()
	if controller then
		controller.Destroy()
	end
end)

select_tab("Aimbot")

-- Minimize & Close behavior
local minimized = false
table.insert(ui_conns, min_btn.MouseButton1Click:Connect(function()
	minimized = not minimized
	sidebar.Visible = not minimized
	content_holder.Visible = not minimized
	TweenService:Create(main, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = minimized and UDim2.new(0, 250, 0, 42) or UDim2.new(0, 520, 0, 390),
	}):Play()
end))

table.insert(ui_conns, close_btn.MouseButton1Click:Connect(function()
	CONFIG.MenuOpen = false
	gui.Enabled = false
end))

-- Keybind handling (Menu, ESP toggle, Aimbot toggle mode)
local input_conn = UserInputService.InputBegan:Connect(function(input, game_processed)
	if game_processed then
		return
	end
	if input.KeyCode == CONFIG.MenuKey then
		CONFIG.MenuOpen = not CONFIG.MenuOpen
		gui.Enabled = CONFIG.MenuOpen
	elseif input.KeyCode == CONFIG.EspToggleKey then
		CONFIG.ESP.Enabled = not CONFIG.ESP.Enabled
		refresh_esp_toggle(CONFIG.ESP.Enabled)
	elseif CONFIG.Aim.Enabled and CONFIG.Aim.Mode == "Toggle" then
		local spec = AIM_KEY_MAP[CONFIG.Aim.Key] or AIM_KEY_MAP.RMB
		if (spec.Kind == "Mouse" and input.UserInputType == spec.Code)
			or (spec.Kind == "Key" and input.KeyCode == spec.Code) then
			aim_toggled = not aim_toggled
		end
	end
end)

controller = {
	Config = CONFIG,
	Destroy = function()
		pcall(function()
			RunService:UnbindFromRenderStep(AIM_BIND_NAME)
		end)
		if render_conn then render_conn:Disconnect() end
		if player_added_conn then player_added_conn:Disconnect() end
		if player_removing_conn then player_removing_conn:Disconnect() end
		if input_conn then input_conn:Disconnect() end
		for _, conn in ipairs(ui_conns) do
			conn:Disconnect()
		end
		for player in pairs(entries) do
			remove_entry(player)
		end
		fov_outline:Remove()
		fov_circle:Remove()
		if chams_root then chams_root:Destroy() end
		if gui then gui:Destroy() end
		if getgenv and getgenv().OcelHub == controller then
			getgenv().OcelHub = nil
		end
	end,
}

if getgenv then
	getgenv().OcelHub = controller
end
