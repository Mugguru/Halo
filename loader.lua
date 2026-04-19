-- Halo Loader — single entry point for the universal cheat suite.
--
-- USAGE (paste this one line into Potassium / any executor):
--   loadstring(game:HttpGet("https://raw.githubusercontent.com/Mugguru/Halo/main/loader.lua"))()
--
-- The loader fetches halo.lua (UI library) and suite.lua (features) from the
-- repo's `main` branch and runs them. Cache-busting query strings are added
-- so executors don't serve stale copies after a push.

local BRANCH = "main"
local USER   = "Mugguru"
local REPO   = "Halo"
local BASE   = "https://raw.githubusercontent.com/" .. USER .. "/" .. REPO .. "/" .. BRANCH .. "/"

local function fetch(path)
    -- ?t=<tick> defeats CDN/executor caches so updates appear instantly
    local url = BASE .. path .. "?t=" .. tostring(tick())
    local ok, body = pcall(game.HttpGet, game, url, true)
    if not ok or not body then
        error("[Halo Loader] Failed to fetch " .. path .. ": " .. tostring(body))
    end
    return body
end

local function run(name, body)
    local fn, err = loadstring(body, "=" .. name)
    if not fn then error("[Halo Loader] Compile error in " .. name .. ": " .. tostring(err)) end
    local ok, runErr = pcall(fn)
    if not ok then error("[Halo Loader] Runtime error in " .. name .. ": " .. tostring(runErr)) end
end

print("[Halo Loader] Fetching halo.lua...")
run("halo.lua",  fetch("halo.lua"))

print("[Halo Loader] Fetching suite.lua...")
run("suite.lua", fetch("suite.lua"))

print("[Halo Loader] Ready. Press \\ to toggle the window.")
