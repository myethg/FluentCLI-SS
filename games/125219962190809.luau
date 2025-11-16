local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local ui = loadstring(game:HttpGet("https://raw.githubusercontent.com/myethg/FluentCLI-SS/refs/heads/main/ui.luau"))()
assert(ui, "[FluentCLI] Failed to load UI")

local slapEvent = game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Slap")

ui:init()

-- To keep track of loops so we can stop them
local loopFlingRunning = false
local loopSlapRunning = false

local function flingOnce(targets, power)
    local count = 0
    for _, target in ipairs(targets) do
        if target.Character then
            local direction = Vector3.new(-0.07, 0, -1).Unit * power
            local args = {
                "Default",
                target.Character,
                direction
            }
            slapEvent:FireServer(unpack(args))
            count = count + 1
        end
    end
    return count
end

local function slapOnce(targets)
    -- Default slap power ~10 (same vector * 10)
    return flingOnce(targets, 10)
end

ui:add_command("fling", "Fling player(s) once with optional power (default 10)", {"player", "text"}, function(targets, powerStr)
    local power = tonumber(powerStr)
    if not power or power <= 0 then
        power = 10
    end

    local count = flingOnce(targets, power)
    return "Flinged " .. count .. " player(s) with power " .. power
end)

ui:add_command("loopfling", "Continuously fling player(s) with optional power (default 10)", {"player", "text"}, function(targets, powerStr)
    if loopFlingRunning then
        return "Loop fling already running! Use stopfling to stop it first."
    end

    local power = tonumber(powerStr)
    if not power or power <= 0 then
        power = 10
    end

    loopFlingRunning = true
    task.spawn(function()
        while loopFlingRunning do
            flingOnce(targets, power)
            task.wait(0.5) -- half-second delay between flings
        end
    end)

    return "Started loop fling with power " .. power
end)

ui:add_command("stopfling", "Stop any running loop fling", {}, function()
    if loopFlingRunning then
        loopFlingRunning = false
        return "Loop fling stopped"
    else
        return "No loop fling running"
    end
end)

ui:add_command("slap", "Slap player(s) once with default power", {"player"}, function(targets)
    local count = slapOnce(targets)
    return "Slapped " .. count .. " player(s)"
end)

ui:add_command("loopslap", "Continuously slap player(s) with default power", {"player"}, function(targets)
    if loopSlapRunning then
        return "Loop slap already running! Use stopslap to stop it first."
    end

    loopSlapRunning = true
    task.spawn(function()
        while loopSlapRunning do
            slapOnce(targets)
            task.wait(0.5)
        end
    end)

    return "Started loop slap"
end)

ui:add_command("stopslap", "Stop any running loop slap", {}, function()
    if loopSlapRunning then
        loopSlapRunning = false
        return "Loop slap stopped"
    else
        return "No loop slap running"
    end
end)
