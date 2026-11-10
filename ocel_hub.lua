-- language: Luau, file: ocel_hub.lua, target: Roblox (San Diego / Mobile & PC)
-- Ocel-Hub Loader: fetches modular Ocel-Hub from Rostik22803/san-diego
local BASE = "https://raw.githubusercontent.com/Rostik22803/san-diego/main/modules/"
local ORDER = { "aim.lua", "esp.lua", "silent.lua", "chams.lua", "world.lua", "ui.lua" }

local function fetch(path)
	local url = BASE .. path .. "?t=" .. tostring(os.time())
	local ok, src = pcall(game.HttpGet, game, url, true)
	if not ok or type(src) ~= "string" or #src == 0 then
		error("[Ocel-Hub] Failed to fetch " .. path .. ": " .. tostring(src))
	end
	local fn, err = loadstring(src, "@ocel/" .. path)
	if not fn then
		error("[Ocel-Hub] Syntax error in " .. path .. ": " .. tostring(err))
	end
	return fn()
end

local ctx = fetch("core.lua")
for _, name in ipairs(ORDER) do
	local init = fetch(name)
	if type(init) == "function" then
		init(ctx)
	end
end

return getgenv and getgenv().OcelHub or ctx
