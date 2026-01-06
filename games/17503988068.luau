local players = game:GetService("Players")
local player = players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local ui = loadstring(game:HttpGet("https://raw.githubusercontent.com/myethg/FluentCLI-SS/refs/heads/main/ui.luau"))()

local core_replication = {
    event = game.ReplicatedStorage.Events.Core_Replication,
    tools_event = game.ReplicatedStorage.Events.Tools,
    filter_event = game.ReplicatedStorage.Events.Filter_Feedback,
    appearances_event = game.ReplicatedStorage.Events.Appearances
}

function core_replication:change_attribute(instance, attribute, value)
    self.event:FireServer("Change_Att", instance, attribute, value)
end

function core_replication:add_tool(tool, container)
    self.tools_event:FireServer("Add", tool, container)
end

function core_replication:remove_tool(tool)
    self.tools_event:FireServer("Remove", tool)
end

function core_replication:change_character(char, cframe)
    self.event:FireServer("Change_Character", char, cframe)
end

function core_replication:death(plr, char_settings)
    self.event:FireServer("Death", plr, char_settings)
end

function core_replication:set_text(text_label, text, text_type)
    self.event:FireServer("Text", "Set", text_label, text, text_type)
end

function core_replication:change_text_color(text_label, color, text_type)
    self.event:FireServer("Text", "Change_Color", text_label, color, text_type)
end

function core_replication:add_tag(tag)
    self.event:FireServer("Tags", "Add", tag)
end

function core_replication:remove_tag(tag)
    self.event:FireServer("Tags", "Remove", tag)
end

function core_replication:clear_tags(tags)
    self.event:FireServer("Tags", "Clear", tags)
end

function core_replication:trigger_prompt(prompt, delay)
    self.event:FireServer("Trigger_Prompt", prompt, delay or 0.1)
end

function core_replication:appear(item, desired_transparency)
    self.appearances_event:FireServer("Appear", nil, item, desired_transparency)
end

function core_replication:disappear(item)
    self.appearances_event:FireServer("Dissapear", nil, item)
end

function core_replication:destroy(instance)
    self.event:FireServer("Tools", "Remove", instance)
end

function core_replication:clone(instance, parent)
    self.tools_event:FireServer("Add", instance, parent)
    repeat task.wait() until parent:FindFirstChild(instance.Name)
    return parent:FindFirstChild(instance.Name)
end

-- Update character reference on respawn
player.CharacterAdded:Connect(function(char)
    character = char
end)

ui:init()

-- ============================================
-- PLAYER CONTROL COMMANDS
-- ============================================

ui:add_command("ragdoll", "Ragdoll target player(s)", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character then
            local char_settings = p.Character:FindFirstChild("Character_Settings")
            if char_settings then
                core_replication:change_attribute(char_settings, "Ragdoll", true)
            end
        end
    end
    return "Ragdolled " .. #targets .. " player(s)"
end)

ui:add_command("unragdoll", "Unragdoll target player(s)", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character then
            local char_settings = p.Character:FindFirstChild("Character_Settings")
            if char_settings then
                core_replication:change_attribute(char_settings, "Ragdoll", false)
            end
        end
    end
    return "Unragdolled " .. #targets .. " player(s)"
end)

ui:add_command("loopragdoll", "Loop ragdoll on player(s)", {"player"}, function(targets)
    local id = "loopragdoll_" .. targets[1].Name
    if _G[id] then
        _G[id] = false
        return "Stopped loop ragdolling"
    end
    
    _G[id] = true
    for _, p in ipairs(targets) do
        task.spawn(function()
            while _G[id] and p.Character do
                local char_settings = p.Character:FindFirstChild("Character_Settings")
                if char_settings then
                    core_replication:change_attribute(char_settings, "Ragdoll", true)
                    task.wait(0.5)
                    core_replication:change_attribute(char_settings, "Ragdoll", false)
                    task.wait(0.3)
                end
            end
        end)
    end
    return "Loop ragdolling " .. #targets .. " player(s)"
end)

ui:add_command("sit", "Make target player(s) sit", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("Humanoid") then
            local humanoid = p.Character.Humanoid
            core_replication:change_attribute(humanoid, "Sit", true)
        end
    end
    return "Made " .. #targets .. " player(s) sit"
end)

ui:add_command("unsit", "Make target player(s) stand", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("Humanoid") then
            local humanoid = p.Character.Humanoid
            core_replication:change_attribute(humanoid, "Sit", false)
        end
    end
    return "Made " .. #targets .. " player(s) stand"
end)

ui:add_command("kill", "Kill player(s) character", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character then
            local char_settings = p.Character:FindFirstChild("Character_Settings")
            if char_settings then
                core_replication:death(p, char_settings)
            end
        end
    end
    return "Killed " .. #targets .. " player(s)"
end)

ui:add_command("loopkill", "Loop kill player (run again to stop)", {"player"}, function(targets)
    local id = "loopkill_" .. targets[1].Name
    if _G[id] then
        _G[id] = false
        return "Stopped loop killing"
    end
    
    if #targets > 0 then
        _G[id] = true
        task.spawn(function()
            while _G[id] do
                local p = targets[1]
                if p.Character then
                    local char_settings = p.Character:FindFirstChild("Character_Settings")
                    if char_settings then
                        core_replication:death(p, char_settings)
                    end
                end
                task.wait(1)
            end
        end)
        return "Loop killing " .. targets[1].Name
    end
    return "No target"
end)

ui:add_command("reset", "Reset player(s) character", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character then
            local char_settings = p.Character:FindFirstChild("Character_Settings")
            if char_settings then
                core_replication:death(p, char_settings)
            end
        end
    end
    return "Resetting " .. #targets .. " player(s)..."
end)

-- ============================================
-- MOVEMENT/STATS COMMANDS (Server-side)
-- ============================================

ui:add_command("ws", "Set walkspeed for player(s) <player> <speed>", {"player", "text"}, function(targets, speed)
    local num = tonumber(speed)
    if num then
        for _, p in ipairs(targets) do
            if p.Character and p.Character:FindFirstChild("Character_Settings") then
                local animator = p.Character.Character_Settings.Animator
                if animator then
                    core_replication:change_attribute(animator, "Walk_Speed", num)
                end
            end
        end
        return "Set walkspeed to " .. num .. " for " .. #targets .. " player(s)"
    end
    return "Invalid walkspeed"
end)

ui:add_command("jp", "Set jumppower for player(s) <player> <power>", {"player", "text"}, function(targets, power)
    local num = tonumber(power)
    if num then
        for _, p in ipairs(targets) do
            if p.Character and p.Character:FindFirstChild("Humanoid") then
                core_replication:change_attribute(p.Character.Humanoid, "JumpPower", num)
            end
        end
        return "Set jumppower to " .. num .. " for " .. #targets .. " player(s)"
    end
    return "Invalid jumppower"
end)

ui:add_command("blind", "Make player(s) blind", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("Character_Settings") then
            core_replication:change_attribute(p.Character.Character_Settings, "Head_Vector_Y_Adapter", 1e15)
        end
    end
    return "Blinded " .. #targets .. " player(s)"
end)

ui:add_command("unblind", "Restore player(s) vision", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("Character_Settings") then
            core_replication:change_attribute(p.Character.Character_Settings, "Head_Vector_Y_Adapter", 1.5)
        end
    end
    return "Unblinded " .. #targets .. " player(s)"
end)

-- ============================================
-- TOOL COMMANDS
-- ============================================

ui:add_command("tools", "Give yourself all tools", {}, function()
    local tools_folder = game.ReplicatedStorage.Tools
    local count = 0
    for _, tool in ipairs(tools_folder:GetChildren()) do
        if tool:IsA("Tool") then
            core_replication:add_tool(tool, player.Backpack)
            count = count + 1
        end
    end
    return "Added " .. count .. " tools"
end)

ui:add_command("tool", "Give yourself specific tool <name>", {"text"}, function(tool_name)
    local tool = game.ReplicatedStorage.Tools:FindFirstChild(tool_name)
    if tool then
        core_replication:add_tool(tool, player.Backpack)
        return "Added " .. tool_name
    end
    return "Tool not found: " .. tool_name
end)

ui:add_command("givetool", "Give tool to player <player> <tool>", {"player", "text"}, function(targets, tool_name)
    local tool = game.ReplicatedStorage.Tools:FindFirstChild(tool_name)
    if tool then
        for _, p in ipairs(targets) do
            core_replication:add_tool(tool, p.Backpack)
        end
        return "Gave " .. tool_name .. " to " .. #targets .. " player(s)"
    end
    return "Tool not found: " .. tool_name
end)

ui:add_command("removetools", "Remove all your tools", {}, function()
    local count = 0
    for _, tool in ipairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            core_replication:remove_tool(tool)
            count = count + 1
        end
    end
    if character then
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") then
                core_replication:remove_tool(tool)
                count = count + 1
            end
        end
    end
    return "Removed " .. count .. " tools"
end)

ui:add_command("striptools", "Remove all tools from player(s)", {"player"}, function(targets)
    local count = 0
    for _, p in ipairs(targets) do
        for _, tool in ipairs(p.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                core_replication:remove_tool(tool)
                count = count + 1
            end
        end
        if p.Character then
            for _, tool in ipairs(p.Character:GetChildren()) do
                if tool:IsA("Tool") then
                    core_replication:remove_tool(tool)
                    count = count + 1
                end
            end
        end
    end
    return "Stripped " .. count .. " tools from " .. #targets .. " player(s)"
end)

ui:add_command("toollist", "List available tools", {}, function()
    local tools = {}
    local folder = game.ReplicatedStorage:FindFirstChild("Tools")
    if folder then
        for _, tool in ipairs(folder:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(tools, tool.Name)
            end
        end
    end
    return "Tools: " .. (#tools > 0 and table.concat(tools, ", ") or "None found")
end)

ui:add_command("btools", "Get delete tool (server-side)", {}, function()
    local tool = Instance.new("Tool", player.Backpack)
    tool.Name = "Delete Tool"
    tool.RequiresHandle = false
    tool.CanBeDropped = true
    
    tool.Activated:Connect(function()
        local target = player:GetMouse().Target
        if target then
            core_replication:destroy(target)
        end
    end)
    return "Got delete tool"
end)

-- ============================================
-- MORPH/CHARACTER COMMANDS
-- ============================================

ui:add_command("morph", "Morph into character <name>", {"text"}, function(character_name)
    local char = game.ReplicatedStorage.Characters:FindFirstChild(character_name)
    if char and character:FindFirstChild("HumanoidRootPart") then
        local cframe = character.HumanoidRootPart.CFrame
        core_replication:change_character(char, cframe)
        return "Morphed into " .. character_name
    end
    return "Character not found: " .. character_name
end)

ui:add_command("morphlist", "List available characters", {}, function()
    local chars = {}
    for _, char in ipairs(game.ReplicatedStorage.Characters:GetChildren()) do
        table.insert(chars, char.Name)
    end
    return "Characters: " .. table.concat(chars, ", ")
end)

ui:add_command("morphall", "Morph all players to character <character>", {"text"}, function(character_name)
    local char = game.ReplicatedStorage.Characters:FindFirstChild(character_name)
    if not char then
        return "Character not found: " .. character_name
    end
    
    local count = 0
    for _, p in ipairs(players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local cframe = p.Character.HumanoidRootPart.CFrame
            core_replication:change_character(char, cframe)
            count = count + 1
        end
    end
    return "Morphed " .. count .. " player(s) into " .. character_name
end)

ui:add_command("morphrandom", "Morph into random character", {}, function()
    local chars = game.ReplicatedStorage.Characters:GetChildren()
    if #chars > 0 and character:FindFirstChild("HumanoidRootPart") then
        local randomChar = chars[math.random(1, #chars)]
        local cframe = character.HumanoidRootPart.CFrame
        core_replication:change_character(randomChar, cframe)
        return "Morphed into " .. randomChar.Name
    end
    return "No characters found"
end)

-- ============================================
-- BODY PARTS COMMANDS
-- ============================================

ui:add_command("armless", "Remove player(s) arms", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character then
            if p.Character:FindFirstChild("Left Arm") then
                core_replication:destroy(p.Character["Left Arm"])
                core_replication:destroy(p.Character["Right Arm"])
            elseif p.Character:FindFirstChild("LeftLowerArm") then
                core_replication:destroy(p.Character["LeftLowerArm"])
                core_replication:destroy(p.Character["RightLowerArm"])
                core_replication:destroy(p.Character["LeftUpperArm"])
                core_replication:destroy(p.Character["RightUpperArm"])
                core_replication:destroy(p.Character["LeftHand"])
                core_replication:destroy(p.Character["RightHand"])
            end
        end
    end
    return "Made " .. #targets .. " player(s) armless"
end)

ui:add_command("legless", "Remove player(s) legs", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character then
            if p.Character:FindFirstChild("Left Leg") then
                core_replication:destroy(p.Character["Left Leg"])
                core_replication:destroy(p.Character["Right Leg"])
            elseif p.Character:FindFirstChild("LeftLowerLeg") then
                core_replication:destroy(p.Character["LeftLowerLeg"])
                core_replication:destroy(p.Character["RightLowerLeg"])
                core_replication:destroy(p.Character["LeftUpperLeg"])
                core_replication:destroy(p.Character["RightUpperLeg"])
                core_replication:destroy(p.Character["LeftFoot"])
                core_replication:destroy(p.Character["RightFoot"])
            end
        end
    end
    return "Made " .. #targets .. " player(s) legless"
end)

ui:add_command("headless", "Remove player(s) head", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("Head") then
            core_replication:destroy(p.Character.Head)
        end
    end
    return "Made " .. #targets .. " player(s) headless"
end)

ui:add_command("limbless", "Remove all limbs from player(s)", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character then
            -- R6
            if p.Character:FindFirstChild("Left Arm") then
                core_replication:destroy(p.Character["Left Arm"])
                core_replication:destroy(p.Character["Right Arm"])
                core_replication:destroy(p.Character["Left Leg"])
                core_replication:destroy(p.Character["Right Leg"])
            -- R15
            elseif p.Character:FindFirstChild("LeftLowerArm") then
                for _, part in ipairs({"LeftLowerArm", "RightLowerArm", "LeftUpperArm", "RightUpperArm", "LeftHand", "RightHand", "LeftLowerLeg", "RightLowerLeg", "LeftUpperLeg", "RightUpperLeg", "LeftFoot", "RightFoot"}) do
                    if p.Character:FindFirstChild(part) then
                        core_replication:destroy(p.Character[part])
                    end
                end
            end
        end
    end
    return "Made " .. #targets .. " player(s) limbless"
end)

ui:add_command("torsoless", "Remove player(s) torso", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character then
            if p.Character:FindFirstChild("Torso") then
                core_replication:destroy(p.Character.Torso)
            elseif p.Character:FindFirstChild("UpperTorso") then
                core_replication:destroy(p.Character.UpperTorso)
                core_replication:destroy(p.Character.LowerTorso)
            end
        end
    end
    return "Made " .. #targets .. " player(s) torsoless"
end)

-- ============================================
-- APPEARANCE COMMANDS
-- ============================================

ui:add_command("invisible", "Make player(s) invisible", {"player"}, function(targets)
    local count = 0
    for _, p in ipairs(targets) do
        if p.Character then
            for _, part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    core_replication:disappear(part)
                    count = count + 1
                elseif part:IsA("Decal") or part:IsA("Texture") then
                    core_replication:disappear(part)
                end
            end
        end
    end
    return "Made " .. #targets .. " player(s) invisible (" .. count .. " parts)"
end)

ui:add_command("visible", "Make player(s) visible", {"player"}, function(targets)
    local count = 0
    for _, p in ipairs(targets) do
        if p.Character then
            for _, part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    core_replication:appear(part, 0)
                    count = count + 1
                elseif part:IsA("Decal") or part:IsA("Texture") then
                    core_replication:appear(part, 0)
                end
            end
        end
    end
    return "Made " .. #targets .. " player(s) visible (" .. count .. " parts)"
end)

ui:add_command("ghost", "Make player(s) semi-transparent", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character then
            for _, part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    core_replication:appear(part, 0.7)
                end
            end
        end
    end
    return "Ghosted " .. #targets .. " player(s)"
end)

ui:add_command("glow", "Make player(s) glow", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character then
            local glowing = p.Character:FindFirstChild("Class_Highlighter")
            if not glowing then
                local highlighter = game.ReplicatedStorage.Misc.Class_Highlighter
                core_replication:clone(highlighter, p.Character)
            end
        end
    end
    return "Made " .. #targets .. " player(s) glow"
end)

ui:add_command("unglow", "Remove player(s) glow", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character then
            local glowing = p.Character:FindFirstChild("Class_Highlighter")
            if glowing then
                core_replication:destroy(glowing)
            end
        end
    end
    return "Removed glow from " .. #targets .. " player(s)"
end)

ui:add_command("naked", "Remove player(s) clothes", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character then
            for _, item in ipairs(p.Character:GetDescendants()) do
                if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
                    core_replication:destroy(item)
                end
            end
        end
    end
    return "Stripped " .. #targets .. " player(s)"
end)

ui:add_command("bald", "Remove player(s) hair", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character then
            for _, item in ipairs(p.Character:GetDescendants()) do
                if item:IsA("Accessory") then
                    local handle = item:FindFirstChild("Handle")
                    if handle and handle:FindFirstChild("HairAttachment") then
                        core_replication:destroy(item)
                    end
                end
            end
        end
    end
    return "Made " .. #targets .. " player(s) bald"
end)

ui:add_command("noface", "Remove player(s) face", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("Head") then
            local face = p.Character.Head:FindFirstChild("face") or p.Character.Head:FindFirstChild("Face")
            if face then
                core_replication:destroy(face)
            end
        end
    end
    return "Removed face from " .. #targets .. " player(s)"
end)

ui:add_command("nohat", "Remove player(s) hats/accessories", {"player"}, function(targets)
    local count = 0
    for _, p in ipairs(targets) do
        if p.Character then
            for _, item in ipairs(p.Character:GetChildren()) do
                if item:IsA("Accessory") then
                    core_replication:destroy(item)
                    count = count + 1
                end
            end
        end
    end
    return "Removed " .. count .. " accessories from " .. #targets .. " player(s)"
end)

ui:add_command("glitch", "Glitch player(s) appearance (flickering)", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character then
            for _, part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    task.spawn(function()
                        for i = 1, 20 do
                            core_replication:disappear(part)
                            task.wait(0.1)
                            core_replication:appear(part, 0)
                            task.wait(0.1)
                        end
                    end)
                end
            end
        end
    end
    return "Glitching " .. #targets .. " player(s)"
end)

-- ============================================
-- NAMETAG/TEXT COMMANDS
-- ============================================

ui:add_command("rpname", "Set roleplay name <text>", {"text"}, function(name)
    if character and character:FindFirstChild("Head") then
        local nametag = character.Head:FindFirstChild("Nametag")
        if nametag and nametag:FindFirstChild("Roleplay_Name") then
            core_replication:set_text(nametag.Roleplay_Name, name, "Roleplay_Name")
            return "Set roleplay name to: " .. name
        end
    end
    return "Failed to set roleplay name"
end)

ui:add_command("bio", "Set biography <text>", {"text"}, function(bio)
    if character and character:FindFirstChild("Head") then
        local nametag = character.Head:FindFirstChild("Nametag")
        if nametag and nametag:FindFirstChild("Biography") then
            core_replication:set_text(nametag.Biography, bio, "Biography")
            return "Set biography to: " .. bio
        end
    end
    return "Failed to set biography"
end)

ui:add_command("role", "Set role <text>", {"text"}, function(role)
    if character and character:FindFirstChild("Head") then
        local nametag = character.Head:FindFirstChild("Nametag")
        if nametag and nametag:FindFirstChild("Role") then
            core_replication:set_text(nametag.Role, role, "Role")
            return "Set role to: " .. role
        end
    end
    return "Failed to set role"
end)

ui:add_command("age", "Set age text", {"text"}, function(age)
    if character and character:FindFirstChild("Head") then
        local nametag = character.Head:FindFirstChild("Nametag")
        if nametag and nametag:FindFirstChild("Age") then
            core_replication:set_text(nametag.Age, age, "Age")
            return "Set age to: " .. age
        end
    end
    return "Failed to set age"
end)

ui:add_command("status", "Set status text", {"text"}, function(status)
    if character and character:FindFirstChild("Head") then
        local nametag = character.Head:FindFirstChild("Nametag")
        if nametag and nametag:FindFirstChild("Status") then
            core_replication:set_text(nametag.Status, status, "Status")
            return "Set status to: " .. status
        end
    end
    return "Failed to set status"
end)

ui:add_command("namecolor", "Set name color <r> <g> <b>", {"text"}, function(color_str)
    local r, g, b = color_str:match("(%d+)%s+(%d+)%s+(%d+)")
    if r and g and b then
        local color = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
        if character and character:FindFirstChild("Head") then
            local nametag = character.Head:FindFirstChild("Nametag")
            if nametag and nametag:FindFirstChild("Roleplay_Name") then
                core_replication:change_text_color(nametag.Roleplay_Name, color, "Role_Color")
                return "Changed name color"
            end
        end
    end
    return "Usage: namecolor <r> <g> <b>"
end)

ui:add_command("biocolor", "Set bio color <r> <g> <b>", {"text"}, function(color_str)
    local r, g, b = color_str:match("(%d+)%s+(%d+)%s+(%d+)")
    if r and g and b then
        local color = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
        if character and character:FindFirstChild("Head") then
            local nametag = character.Head:FindFirstChild("Nametag")
            if nametag and nametag:FindFirstChild("Biography") then
                core_replication:change_text_color(nametag.Biography, color, "Bio_Color")
                return "Changed bio color"
            end
        end
    end
    return "Usage: biocolor <r> <g> <b>"
end)

ui:add_command("hidename", "Hide your nametag", {}, function()
    if character and character:FindFirstChild("Head") then
        local nametag = character.Head:FindFirstChild("Nametag")
        if nametag then
            core_replication:disappear(nametag)
            return "Nametag hidden"
        end
    end
    return "No nametag found"
end)

ui:add_command("showname", "Show your nametag", {}, function()
    if character and character:FindFirstChild("Head") then
        local nametag = character.Head:FindFirstChild("Nametag")
        if nametag then
            core_replication:appear(nametag, 0)
            return "Nametag shown"
        end
    end
    return "No nametag found"
end)

ui:add_command("copyname", "Copy player's name/bio/role <player>", {"player"}, function(targets)
    if #targets > 0 and targets[1].Character then
        local targetHead = targets[1].Character:FindFirstChild("Head")
        local myHead = character:FindFirstChild("Head")
        
        if targetHead and myHead then
            local theirTag = targetHead:FindFirstChild("Nametag")
            local myTag = myHead:FindFirstChild("Nametag")
            
            if theirTag and myTag then
                if theirTag:FindFirstChild("Roleplay_Name") and myTag:FindFirstChild("Roleplay_Name") then
                    core_replication:set_text(myTag.Roleplay_Name, theirTag.Roleplay_Name.Text, "Roleplay_Name")
                end
                if theirTag:FindFirstChild("Biography") and myTag:FindFirstChild("Biography") then
                    core_replication:set_text(myTag.Biography, theirTag.Biography.Text, "Biography")
                end
                if theirTag:FindFirstChild("Role") and myTag:FindFirstChild("Role") then
                    core_replication:set_text(myTag.Role, theirTag.Role.Text, "Role")
                end
                return "Copied " .. targets[1].Name .. "'s nametag"
            end
        end
    end
    return "Failed to copy"
end)

ui:add_command("spam", "Spam text in bio <text>", {"text"}, function(text)
    local spammed = string.rep(text .. " ", 10)
    if character and character:FindFirstChild("Head") then
        local nametag = character.Head:FindFirstChild("Nametag")
        if nametag and nametag:FindFirstChild("Biography") then
            core_replication:set_text(nametag.Biography, spammed, "Biography")
            return "Spammed: " .. text
        end
    end
    return "Failed to spam"
end)

-- ============================================
-- TAGS COMMANDS
-- ============================================

ui:add_command("addtag", "Add location tag <tag>", {"text"}, function(tag)
    core_replication:add_tag(tag)
    return "Added tag: " .. tag
end)

ui:add_command("removetag", "Remove location tag <tag>", {"text"}, function(tag)
    core_replication:remove_tag(tag)
    return "Removed tag: " .. tag
end)

ui:add_command("cleartags", "Clear all location tags", {}, function()
    core_replication:clear_tags(player:GetTags())
    return "Cleared all tags"
end)

ui:add_command("spamtags", "Add multiple random tags", {}, function()
    local tags = {"VIP", "ADMIN", "OWNER", "MOD", "DEV", "COOL", "PRO", "LEGEND", "RICH", "FAMOUS"}
    for _, tag in ipairs(tags) do
        core_replication:add_tag(tag)
    end
    return "Added " .. #tags .. " tags"
end)

-- ============================================
-- PROMPT/INTERACTION COMMANDS
-- ============================================

ui:add_command("fireallprompts", "Fire all nearby prompts", {}, function()
    local count = 0
    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            if character and character:FindFirstChild("HumanoidRootPart") then
                local distance = (character.HumanoidRootPart.Position - prompt.Parent.Position).Magnitude
                if distance <= prompt.MaxActivationDistance * 2 then
                    core_replication:trigger_prompt(prompt, 0.1)
                    count = count + 1
                end
            end
        end
    end
    return "Fired " .. count .. " prompts"
end)

ui:add_command("fireprompt", "Fire specific prompt by name <name>", {"text"}, function(name)
    local count = 0
    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Name:lower():find(name:lower()) then
            core_replication:trigger_prompt(prompt, 0.1)
            count = count + 1
        end
    end
    return "Fired " .. count .. " prompts matching '" .. name .. "'"
end)

ui:add_command("loopprompts", "Loop fire all prompts (run again to stop)", {}, function()
    if _G.LoopPrompts then
        _G.LoopPrompts = false
        return "Stopped looping prompts"
    end
    
    _G.LoopPrompts = true
    task.spawn(function()
        while _G.LoopPrompts do
            for _, prompt in ipairs(workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then
                    if character and character:FindFirstChild("HumanoidRootPart") then
                        local distance = (character.HumanoidRootPart.Position - prompt.Parent.Position).Magnitude
                        if distance <= prompt.MaxActivationDistance * 2 then
                            core_replication:trigger_prompt(prompt, 0.05)
                        end
                    end
                end
            end
            task.wait(0.5)
        end
    end)
    return "Looping prompts..."
end)

-- ============================================
-- TROLLING COMMANDS (Server-replicated)
-- ============================================

ui:add_command("fakelag", "Fake lag player(s) with ragdoll flicker", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        task.spawn(function()
            for i = 1, 20 do
                if p.Character and p.Character:FindFirstChild("Character_Settings") then
                    core_replication:change_attribute(p.Character.Character_Settings, "Ragdoll", true)
                    task.wait(0.05)
                    core_replication:change_attribute(p.Character.Character_Settings, "Ragdoll", false)
                    task.wait(0.05)
                end
            end
        end)
    end
    return "Fake lagging " .. #targets .. " player(s)"
end)

ui:add_command("flop", "Make player(s) flop around", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        task.spawn(function()
            for i = 1, 10 do
                if p.Character and p.Character:FindFirstChild("Character_Settings") then
                    core_replication:change_attribute(p.Character.Character_Settings, "Ragdoll", true)
                    task.wait(1)
                    core_replication:change_attribute(p.Character.Character_Settings, "Ragdoll", false)
                    task.wait(0.5)
                end
            end
        end)
    end
    return "Making " .. #targets .. " player(s) flop"
end)

ui:add_command("spazz", "Make player(s) spazz out", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        task.spawn(function()
            for i = 1, 30 do
                if p.Character and p.Character:FindFirstChild("Humanoid") then
                    core_replication:change_attribute(p.Character.Humanoid, "Sit", i % 2 == 0)
                end
                task.wait(0.1)
            end
        end)
    end
    return "Spazzing " .. #targets .. " player(s)"
end)

ui:add_command("cursed", "Apply cursed effects to player(s)", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character then
            -- Remove face
            local head = p.Character:FindFirstChild("Head")
            if head then
                local face = head:FindFirstChild("face") or head:FindFirstChild("Face")
                if face then core_replication:destroy(face) end
            end
            -- Remove clothes
            for _, item in ipairs(p.Character:GetDescendants()) do
                if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("Accessory") then
                    core_replication:destroy(item)
                end
            end
            -- Make semi-transparent
            for _, part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    core_replication:appear(part, 0.5)
                end
            end
        end
    end
    return "Cursed " .. #targets .. " player(s)"
end)

ui:add_command("skeleton", "Turn player(s) into skeletons (remove body parts)", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character then
            -- Remove torso/body visibility
            for _, part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") and (part.Name:find("Torso") or part.Name:find("Arm") or part.Name:find("Leg") or part.Name:find("Hand") or part.Name:find("Foot")) then
                    core_replication:disappear(part)
                end
            end
            -- Remove face, clothes, accessories
            for _, item in ipairs(p.Character:GetDescendants()) do
                if item:IsA("Decal") or item:IsA("Shirt") or item:IsA("Pants") or item:IsA("Accessory") then
                    core_replication:destroy(item)
                end
            end
        end
    end
    return "Skeletonized " .. #targets .. " player(s)"
end)

ui:add_command("strip", "Strip everything from player(s)", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character then
            for _, item in ipairs(p.Character:GetDescendants()) do
                if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("Accessory") or item:IsA("Decal") then
                    core_replication:destroy(item)
                end
            end
        end
    end
    return "Stripped " .. #targets .. " player(s)"
end)

ui:add_command("dissolve", "Slowly dissolve player(s)", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        task.spawn(function()
            if p.Character then
                local parts = {}
                for _, part in ipairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        table.insert(parts, part)
                    end
                end
                for _, part in ipairs(parts) do
                    core_replication:disappear(part)
                    task.wait(0.2)
                end
            end
        end)
    end
    return "Dissolving " .. #targets .. " player(s)"
end)

ui:add_command("flash", "Flash player(s) visibility rapidly", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        task.spawn(function()
            for i = 1, 15 do
                if p.Character then
                    for _, part in ipairs(p.Character:GetDescendants()) do
                        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                            if i % 2 == 0 then
                                core_replication:disappear(part)
                            else
                                core_replication:appear(part, 0)
                            end
                        end
                    end
                end
                task.wait(0.15)
            end
        end)
    end
    return "Flashing " .. #targets .. " player(s)"
end)

-- ============================================
-- INFO COMMANDS
-- ============================================

ui:add_command("players", "List all players", {}, function()
    local list = {}
    for _, p in ipairs(players:GetPlayers()) do
        table.insert(list, p.Name)
    end
    return "Players: " .. table.concat(list, ", ")
end)

ui:add_command("serverinfo", "Show server info", {}, function()
    local info = game.ReplicatedStorage:FindFirstChild("Game_Info")
    if info then
        local class = info:GetAttribute("Current_Class") or "None"
        local period = info:GetAttribute("Period") or "?"
        return "Class: " .. class .. " | Period: " .. tostring(period) .. " | Players: " .. #players:GetPlayers()
    end
    return "Players: " .. #players:GetPlayers()
end)

ui:add_command("rejoin", "Rejoin the server", {}, function()
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
    return "Rejoining..."
end)

ui:add_command("serverhop", "Hop to different server", {}, function()
    local ts = game:GetService("TeleportService")
    local success, servers = pcall(function()
        return game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
    end)
    if success and servers and servers.data then
        for _, server in ipairs(servers.data) do
            if server.id ~= game.JobId and server.playing < server.maxPlayers then
                ts:TeleportToPlaceInstance(game.PlaceId, server.id, player)
                return "Hopping..."
            end
        end
    end
    return "No servers found"
end)

ui:add_command("cmds", "List all commands", {}, function()
    return "Use 'help' or type any letter to see autocomplete suggestions"
end)

-- ============================================
-- CLIENT-SIDE UTILITY (Local only, doesn't affect others)
-- ============================================

ui:add_command("noclip", "Toggle noclip (client-side)", {}, function()
    if _G.NoclipConnection then
        _G.NoclipConnection:Disconnect()
        _G.NoclipConnection = nil
        return "Noclip disabled"
    end
    
    _G.NoclipConnection = game:GetService("RunService").Stepped:Connect(function()
        if player.Character then
            for _, part in ipairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
    return "Noclip enabled (client-side)"
end)

ui:add_command("fly", "Toggle fly (client-side)", {}, function()
    if _G.FlyEnabled then
        _G.FlyEnabled = false
        if _G.FlyBV then _G.FlyBV:Destroy() end
        if _G.FlyBG then _G.FlyBG:Destroy() end
        if character:FindFirstChild("Humanoid") then
            character.Humanoid.PlatformStand = false
        end
        return "Fly disabled"
    end
    
    _G.FlyEnabled = true
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return "Failed" end
    
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp
    _G.FlyBV = bv
    
    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bg.P = 9e4
    bg.Parent = hrp
    _G.FlyBG = bg
    
    character.Humanoid.PlatformStand = true
    
    local uis = game:GetService("UserInputService")
    local cam = workspace.CurrentCamera
    
    task.spawn(function()
        while _G.FlyEnabled do
            local dir = Vector3.zero
            if uis:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if uis:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if uis:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if uis:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            if uis:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if uis:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
            
            bv.Velocity = dir.Magnitude > 0 and dir.Unit * 80 or Vector3.zero
            bg.CFrame = cam.CFrame
            game:GetService("RunService").RenderStepped:Wait()
        end
    end)
    
    return "Fly enabled (WASD + Space/Shift)"
end)

ui:add_command("esp", "Toggle ESP (client-side)", {}, function()
    if _G.ESPEnabled then
        _G.ESPEnabled = false
        for _, highlight in ipairs(workspace:GetDescendants()) do
            if highlight.Name == "ESP_Highlight" then
                highlight:Destroy()
            end
        end
        return "ESP disabled"
    end
    
    _G.ESPEnabled = true
    
    local function addESP(p)
        if p == player then return end
        if p.Character then
            local existing = p.Character:FindFirstChild("ESP_Highlight")
            if existing then existing:Destroy() end
            
            local highlight = Instance.new("Highlight")
            highlight.Name = "ESP_Highlight"
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.5
            highlight.Parent = p.Character
        end
    end
    
    for _, p in ipairs(players:GetPlayers()) do
        addESP(p)
        p.CharacterAdded:Connect(function()
            task.wait(1)
            if _G.ESPEnabled then addESP(p) end
        end)
    end
    
    players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function()
            task.wait(1)
            if _G.ESPEnabled then addESP(p) end
        end)
    end)
    
    return "ESP enabled"
end)

ui:add_command("fullbright", "Toggle fullbright (client-side)", {}, function()
    local lighting = game:GetService("Lighting")
    if _G.FullbrightEnabled then
        _G.FullbrightEnabled = false
        lighting.Ambient = _G.OldAmbient or Color3.fromRGB(0, 0, 0)
        lighting.Brightness = _G.OldBrightness or 1
        lighting.FogEnd = _G.OldFogEnd or 100000
        return "Fullbright disabled"
    end
    
    _G.OldAmbient = lighting.Ambient
    _G.OldBrightness = lighting.Brightness
    _G.OldFogEnd = lighting.FogEnd
    _G.FullbrightEnabled = true
    
    lighting.Ambient = Color3.fromRGB(255, 255, 255)
    lighting.Brightness = 2
    lighting.FogEnd = 100000
    return "Fullbright enabled"
end)

-- ============================================
-- ADDITIONAL CORE_REPLICATION COMMANDS
-- ============================================

ui:add_command("togglelights", "Toggle all lights in area", {}, function()
    local count = 0
    for _, light in ipairs(workspace:GetDescendants()) do
        if light:IsA("PointLight") or light:IsA("SpotLight") or light:IsA("SurfaceLight") then
            local trigger = light.Parent
            local switch = trigger:FindFirstChild("Switch")
            if switch then
                core_replication.event:FireServer("Toggle_Light", trigger, 0.65, switch, light, light, true)
                count = count + 1
            end
        end
    end
    return "Toggled " .. count .. " lights"
end)

ui:add_command("togglefires", "Toggle all fireplaces", {}, function()
    local count = 0
    for _, fire in ipairs(workspace:GetDescendants()) do
        if fire:IsA("Fire") then
            local trigger = fire.Parent
            core_replication.event:FireServer("Toggle_Fireplace", trigger, fire, 0.5)
            count = count + 1
        end
    end
    return "Toggled " .. count .. " fireplaces"
end)

ui:add_command("forcesit", "Force player(s) into nearest seat", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local pos = p.Character.HumanoidRootPart.Position
            local nearestSeat = nil
            local nearestDist = math.huge
            
            for _, seat in ipairs(workspace:GetDescendants()) do
                if seat:IsA("Seat") or seat:IsA("VehicleSeat") then
                    local dist = (seat.Position - pos).Magnitude
                    if dist < nearestDist then
                        nearestDist = dist
                        nearestSeat = seat
                    end
                end
            end
            
            if nearestSeat then
                local prompt = nearestSeat:FindFirstChildWhichIsA("ProximityPrompt") or nearestSeat.Parent:FindFirstChildWhichIsA("ProximityPrompt")
                if prompt then
                    core_replication.event:FireServer("Seat", "Sit", prompt, nearestSeat)
                end
            end
        end
    end
    return "Forced " .. #targets .. " player(s) to sit"
end)

ui:add_command("unseat", "Remove player(s) from seat", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("Humanoid") then
            local seat = p.Character.Humanoid.SeatPart
            if seat then
                core_replication.event:FireServer("Seat", "Remove", p, seat)
            end
        end
    end
    return "Unseated " .. #targets .. " player(s)"
end)

ui:add_command("weldtool", "Weld your current tool to hand", {}, function()
    if character then
        local tool = character:FindFirstChildWhichIsA("Tool")
        if tool then
            local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
            if hand then
                core_replication.event:FireServer("Tools", "Re_Weld", "Add", tool, hand)
                return "Welded " .. tool.Name .. " to hand"
            end
        end
    end
    return "No tool equipped"
end)

ui:add_command("unweldtool", "Unweld your current tool", {}, function()
    if character then
        local tool = character:FindFirstChildWhichIsA("Tool")
        if tool then
            local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
            if hand then
                core_replication.event:FireServer("Tools", "Re_Weld", "Remove", tool, hand)
                return "Unwelded " .. tool.Name
            end
        end
    end
    return "No tool equipped"
end)

ui:add_command("throw", "Throw current prop/item", {}, function()
    if character then
        local tool = character:FindFirstChildWhichIsA("Tool")
        if tool then
            -- Default throw values
            local velocity = 200
            local time = 0.5
            local distance = 4
            core_replication.event:FireServer("Throw_Prop", tool.Name, velocity, time, distance)
            return "Threw " .. tool.Name
        end
    end
    return "No prop to throw"
end)

ui:add_command("throwpower", "Throw with custom power <power>", {"text"}, function(power)
    local vel = tonumber(power) or 200
    if character then
        local tool = character:FindFirstChildWhichIsA("Tool")
        if tool then
            core_replication.event:FireServer("Throw_Prop", tool.Name, vel, 0.5, 4)
            return "Threw " .. tool.Name .. " with power " .. vel
        end
    end
    return "No prop to throw"
end)

ui:add_command("seatall", "Force all players to nearest seats", {}, function()
    local count = 0
    for _, p in ipairs(players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local pos = p.Character.HumanoidRootPart.Position
            for _, seat in ipairs(workspace:GetDescendants()) do
                if (seat:IsA("Seat") or seat:IsA("VehicleSeat")) and not seat.Occupant then
                    local prompt = seat:FindFirstChildWhichIsA("ProximityPrompt") or (seat.Parent and seat.Parent:FindFirstChildWhichIsA("ProximityPrompt"))
                    if prompt then
                        core_replication.event:FireServer("Seat", "Sit", prompt, seat)
                        count = count + 1
                        break
                    end
                end
            end
        end
    end
    return "Seated " .. count .. " player(s)"
end)

ui:add_command("destroyall", "Destroy all of item type <name>", {"text"}, function(item_name)
    local count = 0
    for _, item in ipairs(workspace:GetDescendants()) do
        if item.Name:lower():find(item_name:lower()) then
            pcall(function()
                core_replication:destroy(item)
                count = count + 1
            end)
        end
    end
    return "Destroyed " .. count .. " items matching '" .. item_name .. "'"
end)

ui:add_command("cloneitem", "Clone item to your character <name>", {"text"}, function(item_name)
    local found = nil
    for _, item in ipairs(game.ReplicatedStorage:GetDescendants()) do
        if item.Name:lower():find(item_name:lower()) then
            found = item
            break
        end
    end
    if found and character then
        core_replication:clone(found, character)
        return "Cloned " .. found.Name
    end
    return "Item not found: " .. item_name
end)

ui:add_command("loopws", "Loop set walkspeed for self <speed>", {"text"}, function(speed)
    local num = tonumber(speed)
    if not num then return "Invalid speed" end
    
    if _G.LoopWSEnabled then
        _G.LoopWSEnabled = false
        return "Stopped loop walkspeed"
    end
    
    _G.LoopWSEnabled = true
    task.spawn(function()
        while _G.LoopWSEnabled do
            if player.Character and player.Character:FindFirstChild("Character_Settings") then
                local animator = player.Character.Character_Settings:FindFirstChild("Animator")
                if animator then
                    core_replication:change_attribute(animator, "Walk_Speed", num)
                end
            end
            task.wait(0.5)
        end
    end)
    return "Loop walkspeed " .. num .. " enabled"
end)

ui:add_command("loopjp", "Loop set jumppower for self <power>", {"text"}, function(power)
    local num = tonumber(power)
    if not num then return "Invalid power" end
    
    if _G.LoopJPEnabled then
        _G.LoopJPEnabled = false
        return "Stopped loop jumppower"
    end
    
    _G.LoopJPEnabled = true
    task.spawn(function()
        while _G.LoopJPEnabled do
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                core_replication:change_attribute(player.Character.Humanoid, "JumpPower", num)
            end
            task.wait(0.5)
        end
    end)
    return "Loop jumppower " .. num .. " enabled"
end)

ui:add_command("antikill", "Toggle anti-kill (auto respawn)", {}, function()
    if _G.AntiKillEnabled then
        _G.AntiKillEnabled = false
        return "Anti-kill disabled"
    end
    
    _G.AntiKillEnabled = true
    task.spawn(function()
        while _G.AntiKillEnabled do
            if player.Character then
                local humanoid = player.Character:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health <= 0 then
                    -- Try to respawn quickly
                    local char_settings = player.Character:FindFirstChild("Character_Settings")
                    if char_settings then
                        core_replication:death(player, char_settings)
                    end
                end
            end
            task.wait(0.1)
        end
    end)
    return "Anti-kill enabled"
end)

ui:add_command("massragdoll", "Ragdoll everyone", {}, function()
    local count = 0
    for _, p in ipairs(players:GetPlayers()) do
        if p.Character then
            local char_settings = p.Character:FindFirstChild("Character_Settings")
            if char_settings then
                core_replication:change_attribute(char_settings, "Ragdoll", true)
                count = count + 1
            end
        end
    end
    return "Ragdolled " .. count .. " players"
end)

ui:add_command("masskill", "Kill everyone", {}, function()
    local count = 0
    for _, p in ipairs(players:GetPlayers()) do
        if p.Character then
            local char_settings = p.Character:FindFirstChild("Character_Settings")
            if char_settings then
                core_replication:death(p, char_settings)
                count = count + 1
            end
        end
    end
    return "Killed " .. count .. " players"
end)

ui:add_command("massinvis", "Make everyone invisible", {}, function()
    local count = 0
    for _, p in ipairs(players:GetPlayers()) do
        if p.Character then
            for _, part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    core_replication:disappear(part)
                    count = count + 1
                end
            end
        end
    end
    return "Made all players invisible (" .. count .. " parts)"
end)

ui:add_command("massvisible", "Make everyone visible", {}, function()
    local count = 0
    for _, p in ipairs(players:GetPlayers()) do
        if p.Character then
            for _, part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    core_replication:appear(part, 0)
                    count = count + 1
                end
            end
        end
    end
    return "Made all players visible (" .. count .. " parts)"
end)

ui:add_command("chaos", "Enable chaos mode (random effects on everyone)", {}, function()
    if _G.ChaosMode then
        _G.ChaosMode = false
        return "Chaos mode disabled"
    end
    
    _G.ChaosMode = true
    task.spawn(function()
        local effects = {"ragdoll", "sit", "blind", "invisible", "glow"}
        while _G.ChaosMode do
            local randomPlayer = players:GetPlayers()[math.random(1, #players:GetPlayers())]
            local effect = effects[math.random(1, #effects)]
            
            if randomPlayer and randomPlayer.Character then
                local char = randomPlayer.Character
                local char_settings = char:FindFirstChild("Character_Settings")
                local humanoid = char:FindFirstChild("Humanoid")
                
                if effect == "ragdoll" and char_settings then
                    core_replication:change_attribute(char_settings, "Ragdoll", true)
                    task.delay(2, function()
                        if char_settings then
                            core_replication:change_attribute(char_settings, "Ragdoll", false)
                        end
                    end)
                elseif effect == "sit" and humanoid then
                    core_replication:change_attribute(humanoid, "Sit", true)
                elseif effect == "blind" and char_settings then
                    core_replication:change_attribute(char_settings, "Head_Vector_Y_Adapter", 1e15)
                    task.delay(3, function()
                        if char_settings then
                            core_replication:change_attribute(char_settings, "Head_Vector_Y_Adapter", 1.5)
                        end
                    end)
                elseif effect == "invisible" then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                            core_replication:disappear(part)
                        end
                    end
                    task.delay(3, function()
                        for _, part in ipairs(char:GetDescendants()) do
                            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                                core_replication:appear(part, 0)
                            end
                        end
                    end)
                elseif effect == "glow" then
                    local highlighter = game.ReplicatedStorage.Misc:FindFirstChild("Class_Highlighter")
                    if highlighter then
                        core_replication:clone(highlighter, char)
                    end
                end
            end
            task.wait(math.random(1, 3))
        end
    end)
    return "Chaos mode enabled!"
end)

ui:add_command("spammorph", "Rapidly morph everyone to random characters", {}, function()
    if _G.SpamMorphEnabled then
        _G.SpamMorphEnabled = false
        return "Spam morph disabled"
    end
    
    _G.SpamMorphEnabled = true
    local chars = game.ReplicatedStorage.Characters:GetChildren()
    
    task.spawn(function()
        while _G.SpamMorphEnabled do
            for _, p in ipairs(players:GetPlayers()) do
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local randomChar = chars[math.random(1, #chars)]
                    local cframe = p.Character.HumanoidRootPart.CFrame
                    core_replication:change_character(randomChar, cframe)
                end
            end
            task.wait(0.5)
        end
    end)
    return "Spam morph enabled!"
end)
