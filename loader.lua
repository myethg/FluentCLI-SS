local placeid = game.PlaceId

local base = "https://raw.githubusercontent.com/myethg/FluentCLI-SS/main/games/"
local url = base .. tostring(placeid) .. ".luau"

local success, result = pcall(function()
    return game:HttpGet(url)
end)

if success and result and not result:find("404") then
    local load_success, error_msg = pcall(function()
        loadstring(result)()
    end)
    
    if not load_success then
        warn("script failed to execute: " .. tostring(error_msg))
    end
end
-- shit loader
