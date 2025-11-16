local placeId = game.PlaceId
local url = "https://raw.githubusercontent.com/myethg/FluentCLI-SS/main/games/" .. placeId .. ".luau"

local success, result = pcall(function()
    return game:HttpGet(url)
end)

if not success then
    warn("[FluentCLI] Failed to fetch script:", result)
    return
end

if result == "" or result:match("^<!DOCTYPE html>") or result:find("404") then
    warn("[FluentCLI] No loader script found for game:", placeId)
    return
end

local runSuccess, err = pcall(function()
    loadstring(result)()
end)

if not runSuccess then
    warn("[FluentCLI] Script execution failed:", err)
end
