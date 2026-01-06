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

-- ============================================
-- TROLLING COMMANDS
-- ============================================

ui:add_command("ragdolloop", "Loop ragdoll on player(s)", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        task.spawn(function()
            while p.Character and p.Character:FindFirstChild("Character_Settings") do
                core_replication:change_attribute(p.Character.Character_Settings, "Ragdoll", true)
                task.wait(0.5)
                core_replication:change_attribute(p.Character.Character_Settings, "Ragdoll", false)
                task.wait(0.3)
            end
        end)
    end
    return "Loop ragdolling " .. #targets .. " player(s)"
end)

ui:add_command("spin", "Make player(s) spin forever", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local bv = Instance.new("BodyAngularVelocity")
            bv.Name = "SpinForce"
            bv.MaxTorque = Vector3.new(0, math.huge, 0)
            bv.AngularVelocity = Vector3.new(0, 50, 0)
            bv.Parent = p.Character.HumanoidRootPart
        end
    end
    return "Spinning " .. #targets .. " player(s)"
end)

ui:add_command("unspin", "Stop player(s) from spinning", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local spin = p.Character.HumanoidRootPart:FindFirstChild("SpinForce")
            if spin then spin:Destroy() end
        end
    end
    return "Stopped spinning " .. #targets .. " player(s)"
end)

ui:add_command("tiny", "Make player(s) tiny", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("Humanoid") then
            local humanoid = p.Character.Humanoid
            local desc = humanoid:GetAppliedDescription()
            desc.HeadScale = 0.3
            desc.BodyTypeScale = 0.3
            desc.DepthScale = 0.3
            desc.HeightScale = 0.3
            desc.WidthScale = 0.3
            humanoid:ApplyDescription(desc)
        end
    end
    return "Made " .. #targets .. " player(s) tiny"
end)

ui:add_command("giant", "Make player(s) giant", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("Humanoid") then
            local humanoid = p.Character.Humanoid
            local desc = humanoid:GetAppliedDescription()
            desc.HeadScale = 3
            desc.BodyTypeScale = 1
            desc.DepthScale = 3
            desc.HeightScale = 3
            desc.WidthScale = 3
            humanoid:ApplyDescription(desc)
        end
    end
    return "Made " .. #targets .. " player(s) giant"
end)

ui:add_command("bighead", "Give player(s) big head", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("Humanoid") then
            local humanoid = p.Character.Humanoid
            local desc = humanoid:GetAppliedDescription()
            desc.HeadScale = 5
            humanoid:ApplyDescription(desc)
        end
    end
    return "Big headed " .. #targets .. " player(s)"
end)

ui:add_command("normalsize", "Reset player(s) size", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("Humanoid") then
            local humanoid = p.Character.Humanoid
            local desc = humanoid:GetAppliedDescription()
            desc.HeadScale = 1
            desc.BodyTypeScale = 0
            desc.DepthScale = 1
            desc.HeightScale = 1
            desc.WidthScale = 1
            humanoid:ApplyDescription(desc)
        end
    end
    return "Reset size for " .. #targets .. " player(s)"
end)

ui:add_command("freeze", "Freeze player(s) in place", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            p.Character.HumanoidRootPart.Anchored = true
        end
    end
    return "Froze " .. #targets .. " player(s)"
end)

ui:add_command("thaw", "Unfreeze player(s)", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            p.Character.HumanoidRootPart.Anchored = false
        end
    end
    return "Thawed " .. #targets .. " player(s)"
end)

ui:add_command("fling", "Fling player(s) into the sky", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = p.Character.HumanoidRootPart
            hrp.Velocity = Vector3.new(math.random(-500, 500), 1000, math.random(-500, 500))
        end
    end
    return "Flung " .. #targets .. " player(s)"
end)

ui:add_command("explode", "Explode on player(s)", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local explosion = Instance.new("Explosion")
            explosion.Position = p.Character.HumanoidRootPart.Position
            explosion.BlastRadius = 10
            explosion.BlastPressure = 500000
            explosion.Parent = workspace
        end
    end
    return "Exploded on " .. #targets .. " player(s)"
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

ui:add_command("trip", "Trip player(s)", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("Humanoid") then
            p.Character.Humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
        end
    end
    return "Tripped " .. #targets .. " player(s)"
end)

ui:add_command("platform", "Create platform at player(s)", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local platform = Instance.new("Part")
            platform.Size = Vector3.new(10, 1, 10)
            platform.Position = p.Character.HumanoidRootPart.Position + Vector3.new(0, 50, 0)
            platform.Anchored = true
            platform.BrickColor = BrickColor.new("Bright blue")
            platform.Material = Enum.Material.Neon
            platform.Parent = workspace
            
            p.Character.HumanoidRootPart.CFrame = platform.CFrame + Vector3.new(0, 3, 0)
        end
    end
    return "Platformed " .. #targets .. " player(s)"
end)

ui:add_command("jail", "Put player(s) in jail", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local pos = p.Character.HumanoidRootPart.Position
            
            for i = 1, 4 do
                local wall = Instance.new("Part")
                wall.Size = Vector3.new(1, 10, 8)
                wall.Anchored = true
                wall.Transparency = 0.5
                wall.BrickColor = BrickColor.new("Really black")
                wall.Material = Enum.Material.ForceField
                wall.Parent = workspace
                
                if i == 1 then wall.CFrame = CFrame.new(pos + Vector3.new(4, 5, 0))
                elseif i == 2 then wall.CFrame = CFrame.new(pos + Vector3.new(-4, 5, 0))
                elseif i == 3 then wall.CFrame = CFrame.new(pos + Vector3.new(0, 5, 4)) * CFrame.Angles(0, math.rad(90), 0)
                else wall.CFrame = CFrame.new(pos + Vector3.new(0, 5, -4)) * CFrame.Angles(0, math.rad(90), 0) end
            end
            
            local roof = Instance.new("Part")
            roof.Size = Vector3.new(8, 1, 8)
            roof.Position = pos + Vector3.new(0, 10, 0)
            roof.Anchored = true
            roof.Transparency = 0.5
            roof.BrickColor = BrickColor.new("Really black")
            roof.Material = Enum.Material.ForceField
            roof.Parent = workspace
        end
    end
    return "Jailed " .. #targets .. " player(s)"
end)

ui:add_command("fire", "Set player(s) on fire", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local fire = Instance.new("Fire")
            fire.Size = 10
            fire.Heat = 10
            fire.Parent = p.Character.HumanoidRootPart
        end
    end
    return "Set " .. #targets .. " player(s) on fire"
end)

ui:add_command("unfire", "Remove fire from player(s)", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character then
            for _, item in ipairs(p.Character:GetDescendants()) do
                if item:IsA("Fire") then
                    item:Destroy()
                end
            end
        end
    end
    return "Extinguished " .. #targets .. " player(s)"
end)

ui:add_command("sparkles", "Give player(s) sparkles", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local sparkles = Instance.new("Sparkles")
            sparkles.SparkleColor = Color3.fromRGB(255, 255, 0)
            sparkles.Parent = p.Character.HumanoidRootPart
        end
    end
    return "Sparkled " .. #targets .. " player(s)"
end)

ui:add_command("smoke", "Give player(s) smoke", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local smoke = Instance.new("Smoke")
            smoke.Size = 5
            smoke.Opacity = 0.5
            smoke.Parent = p.Character.HumanoidRootPart
        end
    end
    return "Smoked " .. #targets .. " player(s)"
end)

ui:add_command("trail", "Give player(s) a trail", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = p.Character.HumanoidRootPart
            local head = p.Character:FindFirstChild("Head")
            if head then
                local att0 = Instance.new("Attachment", hrp)
                att0.Position = Vector3.new(0, -2, 0)
                local att1 = Instance.new("Attachment", head)
                att1.Position = Vector3.new(0, 0.5, 0)
                
                local trail = Instance.new("Trail")
                trail.Attachment0 = att0
                trail.Attachment1 = att1
                trail.Lifetime = 1
                trail.MinLength = 0.1
                trail.Color = ColorSequence.new(Color3.fromRGB(255, 0, 255), Color3.fromRGB(0, 255, 255))
                trail.Parent = p.Character
            end
        end
    end
    return "Trailed " .. #targets .. " player(s)"
end)

-- ============================================
-- TELEPORT COMMANDS
-- ============================================

ui:add_command("tp", "Teleport to player <player>", {"player"}, function(targets)
    if #targets > 0 and targets[1].Character and targets[1].Character:FindFirstChild("HumanoidRootPart") then
        if character:FindFirstChild("HumanoidRootPart") then
            character.HumanoidRootPart.CFrame = targets[1].Character.HumanoidRootPart.CFrame + Vector3.new(3, 0, 0)
            return "Teleported to " .. targets[1].Name
        end
    end
    return "Failed to teleport"
end)

ui:add_command("bring", "Bring player(s) to you", {"player"}, function(targets)
    if character:FindFirstChild("HumanoidRootPart") then
        local pos = character.HumanoidRootPart.CFrame
        for i, p in ipairs(targets) do
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.CFrame = pos + Vector3.new(i * 3, 0, 0)
            end
        end
        return "Brought " .. #targets .. " player(s)"
    end
    return "Failed to bring"
end)

ui:add_command("tpall", "Teleport all to you", {}, function()
    if character:FindFirstChild("HumanoidRootPart") then
        local pos = character.HumanoidRootPart.CFrame
        local count = 0
        for i, p in ipairs(players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.CFrame = pos + Vector3.new(i * 3, 0, 0)
                count = count + 1
            end
        end
        return "Brought " .. count .. " player(s)"
    end
    return "Failed"
end)

ui:add_command("sky", "Teleport player(s) to sky", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            p.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame + Vector3.new(0, 500, 0)
        end
    end
    return "Sent " .. #targets .. " player(s) to sky"
end)

ui:add_command("void", "Send player(s) to void", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            p.Character.HumanoidRootPart.CFrame = CFrame.new(0, -500, 0)
        end
    end
    return "Voided " .. #targets .. " player(s)"
end)

-- ============================================
-- UTILITY COMMANDS
-- ============================================

ui:add_command("noclip", "Toggle noclip", {}, function()
    local noclipEnabled = false
    local noclipConn = nil
    
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
    return "Noclip enabled"
end)

ui:add_command("fly", "Toggle fly", {}, function()
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
    
    game:GetService("RunService").RenderStepped:Connect(function()
        if not _G.FlyEnabled then return end
        local dir = Vector3.zero
        if uis:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if uis:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
        
        bv.Velocity = dir.Magnitude > 0 and dir.Unit * 80 or Vector3.zero
        bg.CFrame = cam.CFrame
    end)
    
    return "Fly enabled (WASD + Space/Shift)"
end)

ui:add_command("esp", "Toggle ESP", {}, function()
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

ui:add_command("fullbright", "Toggle fullbright", {}, function()
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

ui:add_command("hidename", "Hide your nametag", {}, function()
    if character:FindFirstChild("Head") then
        local nametag = character.Head:FindFirstChild("Nametag")
        if nametag then
            core_replication:disappear(nametag)
            return "Nametag hidden"
        end
    end
    return "No nametag found"
end)

ui:add_command("showname", "Show your nametag", {}, function()
    if character:FindFirstChild("Head") then
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

ui:add_command("age", "Set age text", {"text"}, function(age)
    if character:FindFirstChild("Head") then
        local nametag = character.Head:FindFirstChild("Nametag")
        if nametag and nametag:FindFirstChild("Age") then
            core_replication:set_text(nametag.Age, age, "Age")
            return "Set age to: " .. age
        end
    end
    return "Failed to set age"
end)

ui:add_command("status", "Set status text", {"text"}, function(status)
    if character:FindFirstChild("Head") then
        local nametag = character.Head:FindFirstChild("Nametag")
        if nametag and nametag:FindFirstChild("Status") then
            core_replication:set_text(nametag.Status, status, "Status")
            return "Set status to: " .. status
        end
    end
    return "Failed to set status"
end)

-- ============================================
-- SERVER/GAME INFO COMMANDS
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
    local servers = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
    for _, server in ipairs(servers.data) do
        if server.id ~= game.JobId and server.playing < server.maxPlayers then
            ts:TeleportToPlaceInstance(game.PlaceId, server.id, player)
            return "Hopping..."
        end
    end
    return "No servers found"
end)

-- ============================================
-- FUN/CHAOS COMMANDS
-- ============================================

ui:add_command("disco", "Disco lights!", {}, function()
    if _G.DiscoEnabled then
        _G.DiscoEnabled = false
        game:GetService("Lighting").Ambient = Color3.fromRGB(127, 127, 127)
        return "Disco disabled"
    end
    
    _G.DiscoEnabled = true
    task.spawn(function()
        local lighting = game:GetService("Lighting")
        while _G.DiscoEnabled do
            lighting.Ambient = Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255))
            task.wait(0.1)
        end
    end)
    return "Disco enabled!"
end)

ui:add_command("earthquake", "Shake everyone's screen", {}, function()
    task.spawn(function()
        local cam = workspace.CurrentCamera
        for i = 1, 50 do
            local shake = CFrame.new(
                math.random(-2, 2) / 10,
                math.random(-2, 2) / 10,
                math.random(-2, 2) / 10
            )
            cam.CFrame = cam.CFrame * shake
            task.wait(0.02)
        end
    end)
    return "EARTHQUAKE!"
end)

ui:add_command("confetti", "Spawn confetti on player(s)", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            for i = 1, 50 do
                local part = Instance.new("Part")
                part.Size = Vector3.new(0.2, 0.2, 0.2)
                part.Position = p.Character.HumanoidRootPart.Position + Vector3.new(math.random(-5, 5), 10, math.random(-5, 5))
                part.BrickColor = BrickColor.Random()
                part.Material = Enum.Material.Neon
                part.Parent = workspace
                game:GetService("Debris"):AddItem(part, 5)
            end
        end
    end
    return "Confetti for " .. #targets .. " player(s)!"
end)

ui:add_command("orbit", "Orbit around player <player>", {"player"}, function(targets)
    if #targets > 0 then
        local target = targets[1]
        if _G.OrbitConnection then
            _G.OrbitConnection:Disconnect()
            _G.OrbitConnection = nil
            return "Stopped orbiting"
        end
        
        local angle = 0
        _G.OrbitConnection = game:GetService("RunService").Heartbeat:Connect(function()
            if target.Character and target.Character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("HumanoidRootPart") then
                angle = angle + 0.05
                local x = math.cos(angle) * 8
                local z = math.sin(angle) * 8
                character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(x, 0, z)
            end
        end)
        return "Orbiting " .. target.Name
    end
    return "No target"
end)

ui:add_command("annoy", "Annoy player by following them <player>", {"player"}, function(targets)
    if #targets > 0 then
        local target = targets[1]
        if _G.AnnoyConnection then
            _G.AnnoyConnection:Disconnect()
            _G.AnnoyConnection = nil
            return "Stopped annoying"
        end
        
        _G.AnnoyConnection = game:GetService("RunService").Heartbeat:Connect(function()
            if target.Character and target.Character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("HumanoidRootPart") then
                character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -2)
            end
        end)
        return "Annoying " .. target.Name
    end
    return "No target"
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

ui:add_command("loopkill", "Loop kill player", {"player"}, function(targets)
    if _G.LoopKillTarget then
        _G.LoopKillTarget = nil
        return "Stopped loop killing"
    end
    
    if #targets > 0 then
        _G.LoopKillTarget = targets[1]
        task.spawn(function()
            while _G.LoopKillTarget do
                local p = _G.LoopKillTarget
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

ui:add_command("loopragdoll", "Loop ragdoll player", {"player"}, function(targets)
    if _G.LoopRagdollTarget then
        _G.LoopRagdollTarget = nil
        return "Stopped loop ragdolling"
    end
    
    if #targets > 0 then
        _G.LoopRagdollTarget = targets[1]
        task.spawn(function()
            while _G.LoopRagdollTarget do
                local p = _G.LoopRagdollTarget
                if p.Character then
                    local char_settings = p.Character:FindFirstChild("Character_Settings")
                    if char_settings then
                        core_replication:change_attribute(char_settings, "Ragdoll", true)
                    end
                end
                task.wait(0.1)
            end
        end)
        return "Loop ragdolling " .. targets[1].Name
    end
    return "No target"
end)

ui:add_command("fakelag", "Fake lag player(s)", {"player"}, function(targets)
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

ui:add_command("seizure", "Give player(s) a seizure", {"player"}, function(targets)
    for _, p in ipairs(targets) do
        task.spawn(function()
            for i = 1, 30 do
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    p.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.Angles(math.random(), math.random(), math.random())
                end
                task.wait(0.05)
            end
        end)
    end
    return "Seizure for " .. #targets .. " player(s)"
end)

ui:add_command("glitch", "Glitch player(s) character", {"player"}, function(targets)
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
