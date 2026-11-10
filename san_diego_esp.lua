-- language: Luau, file: san_diego_esp.lua, target: Roblox (San Diego dump), Executor Drawing API
-- Full 2D Bounding Box + Anatomical R15/R6 Skeleton ESP tailored to San Diego's character/attribute schema.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local local_player = Players.LocalPlayer

if getgenv and getgenv().SanDiegoESP then
	pcall(function()
		getgenv().SanDiegoESP:Destroy()
	end)
end

local CONFIG = {
	Enabled = true,
	ToggleKey = Enum.KeyCode.F3,
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
	ColorDefault = Color3.fromRGB(255, 255, 255),
	ColorWanted = Color3.fromRGB(255, 65, 65),
	ColorDetained = Color3.fromRGB(255, 195, 60),
	ColorOutline = Color3.fromRGB(0, 0, 0),
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

local function get_target_color(player, character)
	if CONFIG.ColorWantedOverride and get_wanted_stars(player) > 0 then
		return CONFIG.ColorWanted
	end
	if character:GetAttribute("IsDetained") == true or character:GetAttribute("DetainedByUserId") ~= nil then
		return CONFIG.ColorDetained
	end
	if CONFIG.ColorUseTeam and player.Team then
		return player.Team.TeamColor.Color
	end
	return CONFIG.ColorDefault
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
		PartCount = #part_names,
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

local entries = {}

local function create_entry(player)
	local skeleton_outlines = {}
	local skeleton_lines = {}
	for i = 1, #SKELETON_BONES do
		skeleton_outlines[i] = new_drawing("Line", {
			Visible = false,
			Color = CONFIG.ColorOutline,
			Thickness = CONFIG.SkeletonThickness + 2,
			Transparency = 1,
			ZIndex = 1,
		})
		skeleton_lines[i] = new_drawing("Line", {
			Visible = false,
			Color = CONFIG.ColorDefault,
			Thickness = CONFIG.SkeletonThickness,
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
		BoxOutline = new_drawing("Square", {
			Visible = false,
			Filled = false,
			Color = CONFIG.ColorOutline,
			Thickness = CONFIG.BoxThickness + 2,
			Transparency = 1,
			ZIndex = 1,
		}),
		Box = new_drawing("Square", {
			Visible = false,
			Filled = false,
			Color = CONFIG.ColorDefault,
			Thickness = CONFIG.BoxThickness,
			Transparency = 1,
			ZIndex = 2,
		}),
		HealthBg = new_drawing("Line", {
			Visible = false,
			Color = CONFIG.ColorOutline,
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
			Color = CONFIG.ColorOutline,
			Thickness = CONFIG.SkeletonThickness + 2,
			Transparency = 1,
			ZIndex = 1,
		}),
		HeadCircle = new_drawing("Circle", {
			Visible = false,
			Filled = false,
			NumSides = 20,
			Color = CONFIG.ColorDefault,
			Thickness = CONFIG.SkeletonThickness,
			Transparency = 1,
			ZIndex = 2,
		}),
		NameText = new_drawing("Text", {
			Visible = false,
			Center = true,
			Outline = true,
			OutlineColor = CONFIG.ColorOutline,
			Size = CONFIG.TextSize,
			Font = 2,
			Color = CONFIG.ColorDefault,
			Transparency = 1,
			ZIndex = 3,
		}),
		SubText = new_drawing("Text", {
			Visible = false,
			Center = true,
			Outline = true,
			OutlineColor = CONFIG.ColorOutline,
			Size = math.max(11, CONFIG.TextSize - 1),
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

local function hide_entry(entry)
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

local function remove_entry(player)
	local entry = entries[player]
	if not entry then
		return
	end
	entries[player] = nil
	for _, conn in ipairs(entry.Connections) do
		conn:Disconnect()
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

local input_conn = UserInputService.InputBegan:Connect(function(input, game_processed)
	if not game_processed and input.KeyCode == CONFIG.ToggleKey then
		CONFIG.Enabled = not CONFIG.Enabled
	end
end)

local render_conn = RunService.RenderStepped:Connect(function()
	local camera = Workspace.CurrentCamera
	if not camera or not CONFIG.Enabled then
		for _, entry in pairs(entries) do
			hide_entry(entry)
		end
		return
	end

	local cam_pos = camera.CFrame.Position

	for player, entry in pairs(entries) do
		local char = player.Character
		if not char or not char.Parent then
			hide_entry(entry)
			continue
		end

		if CONFIG.TeamCheck and local_player.Team ~= nil and player.Team == local_player.Team then
			hide_entry(entry)
			continue
		end
		if CONFIG.IgnoreHearseHidden and player:GetAttribute("HearseCoffinHidden") == true then
			hide_entry(entry)
			continue
		end
		if CONFIG.IgnoreModeratorHidden and (player:GetAttribute("ModeratorHidden") == true or player:GetAttribute("ModeratorInvisible") == true) then
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
		if distance > CONFIG.MaxDistance then
			hide_entry(entry)
			continue
		end

		if entry.RigChar ~= char or not entry.Rig then
			entry.Rig = build_rig_cache(char)
			entry.RigChar = char
		end
		local rig = entry.Rig
		if not rig.Parts.Head or (rig.IsR15 and (not rig.Parts.UpperTorso or not rig.Parts.LowerTorso)) then
			entry.Rig = build_rig_cache(char)
			rig = entry.Rig
		end

		local bx, by, bw, bh = compute_screen_box(camera, rig)
		if not bx then
			hide_entry(entry)
			continue
		end

		local color = get_target_color(player, char)

		-- 2D Box
		if CONFIG.ShowBox then
			local box_pos = Vector2.new(bx, by)
			local box_size = Vector2.new(bw, bh)
			if CONFIG.BoxOutline then
				entry.BoxOutline.Position = box_pos
				entry.BoxOutline.Size = box_size
				entry.BoxOutline.Thickness = CONFIG.BoxThickness + 2
				entry.BoxOutline.Visible = true
			else
				entry.BoxOutline.Visible = false
			end
			entry.Box.Position = box_pos
			entry.Box.Size = box_size
			entry.Box.Color = color
			entry.Box.Thickness = CONFIG.BoxThickness
			entry.Box.Visible = true
		else
			entry.BoxOutline.Visible = false
			entry.Box.Visible = false
		end

		-- Health Bar
		if CONFIG.ShowHealthBar then
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

		-- Name + Wanted / Detained Tags
		local center_x = bx + bw * 0.5
		if CONFIG.ShowName then
			local label = player.DisplayName ~= "" and player.DisplayName or player.Name
			if CONFIG.ShowWanted then
				local stars = get_wanted_stars(player)
				if stars > 0 then
					label = string.format("%s [W%d]", label, stars)
				end
			end
			if char:GetAttribute("IsDetained") == true then
				label = label .. " [CUFF]"
			end
			entry.NameText.Text = label
			entry.NameText.Position = Vector2.new(center_x, by - CONFIG.TextSize - 3)
			entry.NameText.Color = color
			entry.NameText.Visible = true
		else
			entry.NameText.Visible = false
		end

		-- Distance / Team Tag
		if CONFIG.ShowDistance or CONFIG.ShowTeamTag then
			local parts_txt = {}
			if CONFIG.ShowTeamTag and player.Team then
				table.insert(parts_txt, player.Team.Name)
			end
			if CONFIG.ShowDistance then
				table.insert(parts_txt, string.format("%dm", math.floor(distance + 0.5)))
			end
			entry.SubText.Text = table.concat(parts_txt, " | ")
			entry.SubText.Position = Vector2.new(center_x, by + bh + 2)
			entry.SubText.Visible = true
		else
			entry.SubText.Visible = false
		end

		-- Anatomical Skeleton
		if CONFIG.ShowSkeleton then
			local wjoints = entry.WorldJoints
			local sjoints = entry.ScreenJoints
			table.clear(wjoints)
			table.clear(sjoints)

			if resolve_joints_world(rig, wjoints) then
				for jname, wpos in pairs(wjoints) do
					local sp, _ = camera:WorldToViewportPoint(wpos)
					if sp.Z > 0 then
						sjoints[jname] = Vector2.new(sp.X, sp.Y)
					end
				end

				for i, bone in ipairs(SKELETON_BONES) do
					local p1 = sjoints[bone[1]]
					local p2 = sjoints[bone[2]]
					if p1 and p2 then
						if CONFIG.SkeletonOutline then
							entry.SkeletonOutlines[i].From = p1
							entry.SkeletonOutlines[i].To = p2
							entry.SkeletonOutlines[i].Thickness = CONFIG.SkeletonThickness + 2
							entry.SkeletonOutlines[i].Visible = true
						else
							entry.SkeletonOutlines[i].Visible = false
						end
						entry.SkeletonLines[i].From = p1
						entry.SkeletonLines[i].To = p2
						entry.SkeletonLines[i].Color = color
						entry.SkeletonLines[i].Thickness = CONFIG.SkeletonThickness
						entry.SkeletonLines[i].Visible = true
					else
						entry.SkeletonOutlines[i].Visible = false
						entry.SkeletonLines[i].Visible = false
					end
				end

				-- Head Circle scaled by projected Head size
				local head_part = rig.Parts.Head
				local head_screen = sjoints.HeadCenter
				if CONFIG.ShowHeadCircle and head_part and head_screen then
					local head_top_sp = camera:WorldToViewportPoint(head_part.Position + camera.CFrame.UpVector * (head_part.Size.Y * 0.52))
					local radius = head_top_sp.Z > 0 and math.clamp((Vector2.new(head_top_sp.X, head_top_sp.Y) - head_screen).Magnitude, 2, 42) or 4
					if CONFIG.SkeletonOutline then
						entry.HeadOutline.Position = head_screen
						entry.HeadOutline.Radius = radius
						entry.HeadOutline.Thickness = CONFIG.SkeletonThickness + 2
						entry.HeadOutline.Visible = true
					else
						entry.HeadOutline.Visible = false
					end
					entry.HeadCircle.Position = head_screen
					entry.HeadCircle.Radius = radius
					entry.HeadCircle.Color = color
					entry.HeadCircle.Thickness = CONFIG.SkeletonThickness
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

local controller = {
	Config = CONFIG,
	Destroy = function()
		if render_conn then render_conn:Disconnect() end
		if player_added_conn then player_added_conn:Disconnect() end
		if player_removing_conn then player_removing_conn:Disconnect() end
		if input_conn then input_conn:Disconnect() end
		for player in pairs(entries) do
			remove_entry(player)
		end
		if getgenv and getgenv().SanDiegoESP then
			getgenv().SanDiegoESP = nil
		end
	end,
}

if getgenv then
	getgenv().SanDiegoESP = controller
end
