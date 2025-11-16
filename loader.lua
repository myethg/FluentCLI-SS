local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local placeId = game.PlaceId

local baseUrl = "https://raw.githubusercontent.com/myethg/FluentCLI-SS/main/games/"
local url = baseUrl .. placeId .. ".luau"

local success, result = pcall(function()
    return game:HttpGet(url)
end)

if not success then
    warn("[FluentCLI] Failed to fetch script for game:", placeId)
    warn("HTTP Error:", response)
    return
end

-- Reject GitHub 404 file content
if response == "" or response:match("^<!DOCTYPE html>") or response:find("404") then
    warn("[FluentCLI] No loader script found for game:", placeId)
    return
end

local runSuccess, err = pcall(function()
    loadstring(response)()
end)

if not runSuccess then
    warn("[FluentCLI] Script execution failed:", err)
end
