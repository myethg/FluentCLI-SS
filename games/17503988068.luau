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

ui:init()

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

ui:add_command("sit", "Make target player(s) sit", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("Humanoid") then
            local humanoid = p.Character.Humanoid
            core_replication:change_attribute(humanoid, "Sit", true)
        end
    end
    return "Made " .. #targets .. " player(s) sit"
end)

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

ui:add_command("removetools", "Remove all your tools", {}, function()
    local count = 0
    for _, tool in ipairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            core_replication:remove_tool(tool)
            count = count + 1
        end
    end
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            core_replication:remove_tool(tool)
            count = count + 1
        end
    end
    return "Removed " .. count .. " tools"
end)

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

ui:add_command("rpname", "Set roleplay name <text>", {"text"}, function(name)
    local nametag = character:FindFirstChild("Head"):FindFirstChild("Nametag")
    if nametag and nametag:FindFirstChild("Roleplay_Name") then
        core_replication:set_text(nametag.Roleplay_Name, name, "Roleplay_Name")
        return "Set roleplay name to: " .. name
    end
    return "Failed to set roleplay name"
end)

ui:add_command("bio", "Set biography <text>", {"text"}, function(bio)
    local nametag = character:FindFirstChild("Head"):FindFirstChild("Nametag")
    if nametag and nametag:FindFirstChild("Biography") then
        core_replication:set_text(nametag.Biography, bio, "Biography")
        return "Set biography to: " .. bio
    end
    return "Failed to set biography"
end)

ui:add_command("role", "Set role <text>", {"text"}, function(role)
    local nametag = character:FindFirstChild("Head"):FindFirstChild("Nametag")
    if nametag and nametag:FindFirstChild("Role") then
        core_replication:set_text(nametag.Role, role, "Role")
        return "Set role to: " .. role
    end
    return "Failed to set role"
end)

ui:add_command("namecolor", "Set name color <r> <g> <b>", {"text"}, function(color_str)
    local r, g, b = color_str:match("(%d+)%s+(%d+)%s+(%d+)")
    if r and g and b then
        local color = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
        local nametag = character:FindFirstChild("Head"):FindFirstChild("Nametag")
        if nametag and nametag:FindFirstChild("Roleplay_Name") then
            core_replication:change_text_color(nametag.Roleplay_Name, color, "Role_Color")
            return "Changed name color"
        end
    end
    return "Usage: namecolor <r> <g> <b>"
end)

ui:add_command("biocolor", "Set bio color <r> <g> <b>", {"text"}, function(color_str)
    local r, g, b = color_str:match("(%d+)%s+(%d+)%s+(%d+)")
    if r and g and b then
        local color = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
        local nametag = character:FindFirstChild("Head"):FindFirstChild("Nametag")
        if nametag and nametag:FindFirstChild("Biography") then
            core_replication:change_text_color(nametag.Biography, color, "Bio_Color")
            return "Changed bio color"
        end
    end
    return "Usage: biocolor <r> <g> <b>"
end)

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

ui:add_command("ws", "Set walkspeed for player(s) <player> <speed>", {"player", "text"}, function(targets, speed)
    local num = tonumber(speed)
    if num then
        for _, p in ipairs(targets) do
            if p.Character and p.Character:FindFirstChild("Character_Settings") then
                local animator = p.Character.Character_Settings.Animator
                core_replication:change_attribute(animator, "Walk_Speed", num)
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

ui:add_command("invisible", "Make player(s) invisible <player>", {"player"}, function(targets)
    local count = 0
    for _, p in ipairs(targets) do
        if p.Character then
            for _, part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    core_replication:disappear(part)
                    count = count + 1
                end
            end
        end
    end
    return "Made " .. #targets .. " player(s) invisible (" .. count .. " parts)"
end)

ui:add_command("visible", "Make player(s) visible <player>", {"player"}, function(targets)
    local count = 0
    for _, p in ipairs(targets) do
        if p.Character then
            for _, part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    core_replication:appear(part, 0)
                    count = count + 1
                end
            end
        end
    end
    return "Made " .. #targets .. " player(s) visible (" .. count .. " parts)"
end)

ui:add_command("reset", "Reset player(s) character <player>", {"player"}, function(targets)
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

ui:add_command("armless", "Remove player(s) arms <player>", {"player"}, function(targets)
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

ui:add_command("legless", "Remove player(s) legs <player>", {"player"}, function(targets)
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

ui:add_command("headless", "Remove player(s) head <player>", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("Head") then
            core_replication:destroy(p.Character.Head)
        end
    end
    return "Made " .. #targets .. " player(s) headless"
end)

ui:add_command("blind", "Make player(s) blind <player>", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("Character_Settings") then
            core_replication:change_attribute(p.Character.Character_Settings, "Head_Vector_Y_Adapter", 1e15)
        end
    end
    return "Blinded " .. #targets .. " player(s)"
end)

ui:add_command("unblind", "Restore player(s) vision <player>", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("Character_Settings") then
            core_replication:change_attribute(p.Character.Character_Settings, "Head_Vector_Y_Adapter", 1.5)
        end
    end
    return "Unblinded " .. #targets .. " player(s)"
end)

ui:add_command("glow", "Make player(s) glow <player>", {"player"}, function(targets)
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

ui:add_command("unglow", "Remove player(s) glow <player>", {"player"}, function(targets)
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

ui:add_command("fireallprompts", "Fire all nearby prompts", {}, function()
    local count = 0
    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            local distance = (character.HumanoidRootPart.Position - prompt.Parent.Position).Magnitude
            if distance <= prompt.MaxActivationDistance then
                core_replication:trigger_prompt(prompt, 0.1)
                count = count + 1
            end
        end
    end
    return "Fired " .. count .. " prompts"
end)

ui:add_command("tpclass", "Teleport to current class", {}, function()
    local current_class = game.ReplicatedStorage.Game_Info:GetAttribute("Current_Class")
    if current_class then
        for _, class_obj in ipairs(workspace.Classes:GetChildren()) do
            if class_obj.Name:find(current_class) then
                if character:FindFirstChild("HumanoidRootPart") and class_obj:FindFirstChild("Tp") then
                    character.HumanoidRootPart.CFrame = class_obj.Tp.CFrame
                    return "Teleported to " .. current_class
                end
            end
        end
    end
    return "No class found"
end)

ui:add_command("btools", "Get delete tool", {}, function()
    local tool = Instance.new("Tool", player.Backpack)
    tool.Name = "Delete Tool"
    tool.RequiresHandle = false
    tool.CanBeDropped = true
    
    tool.Activated:Connect(function()
        local target = player:GetMouse().Target
        if target then
            local explosion = Instance.new("Explosion", workspace)
            explosion.Position = target.Position
            explosion.BlastRadius = 16
            explosion.BlastPressure = 0
            explosion.DestroyJointRadiusPercent = 0
            explosion.ExplosionType = Enum.ExplosionType.NoCraters
            core_replication:destroy(target)
        end
    end)
    return "Got delete tool"
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
