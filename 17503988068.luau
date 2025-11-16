local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

local CoreReplication = {
    Event = game.ReplicatedStorage.Events.Core_Replication,
    ToolsEvent = game.ReplicatedStorage.Events.Tools,
    FilterEvent = game.ReplicatedStorage.Events.Filter_Feedback,
    AppearancesEvent = game.ReplicatedStorage.Events.Appearances
}

function CoreReplication:ChangeAttribute(instance, attribute, value)
    self.Event:FireServer("Change_Att", instance, attribute, value)
end

function CoreReplication:AddTool(tool, container)
    self.ToolsEvent:FireServer("Add", tool, container)
end

function CoreReplication:RemoveTool(tool)
    self.ToolsEvent:FireServer("Remove", tool)
end

function CoreReplication:ReWeldTool(action, tool, part)
    self.Event:FireServer("Tools", "Re_Weld", action, tool, part)
end

function CoreReplication:ChangeCharacter(character, cframe)
    self.Event:FireServer("Change_Character", character, cframe)
end

function CoreReplication:Death(player, characterSettings)
    self.Event:FireServer("Death", player, characterSettings)
end

function CoreReplication:SetText(textLabel, text, textType)
    self.Event:FireServer("Text", "Set", textLabel, text, textType)
end

function CoreReplication:FilterText(textLabel, text, textType)
    self.Event:FireServer("Text", "Filter", textLabel, text, textType)
end

function CoreReplication:ChangeTextColor(textLabel, color, textType)
    self.Event:FireServer("Text", "Change_Color", textLabel, color, textType)
end

function CoreReplication:AddTag(tag)
    self.Event:FireServer("Tags", "Add", tag)
end

function CoreReplication:RemoveTag(tag)
    self.Event:FireServer("Tags", "Remove", tag)
end

function CoreReplication:ClearTags(tags)
    self.Event:FireServer("Tags", "Clear", tags)
end

function CoreReplication:TriggerPrompt(prompt, delay)
    self.Event:FireServer("Trigger_Prompt", prompt, delay or 0.1)
end

function CoreReplication:Seat(action, prompt, seat)
    self.Event:FireServer("Seat", action, prompt, seat)
end

function CoreReplication:ToggleLight(trigger, rotation, switch, light, decorLight, window)
    self.Event:FireServer("Toggle_Light", trigger, rotation, switch, light, decorLight, window)
end

function CoreReplication:ToggleFireplace(trigger, fire, duration)
    self.Event:FireServer("Toggle_Fireplace", trigger, fire, duration)
end

function CoreReplication:ChangeTransparency(part, transparency)
    self.Event:FireServer("Change_Transparency", part, transparency)
end

function CoreReplication:TurnHomework(homework, responses, totalQuestions)
    self.Event:FireServer("Turn_Homework", homework, responses, totalQuestions)
end

function CoreReplication:ChangeBookColor(playerSettings, bookTopic, topic, tool, colors)
    self.Event:FireServer("Change_Book_Color", playerSettings, bookTopic, topic, tool, colors)
end

function CoreReplication:RemoveThrowable(item)
    self.Event:FireServer("Remove_Throwable", item)
end

function CoreReplication:AddFavorite(item, container)
    self.Event:FireServer("Favorites", "Add", item, container)
end

function CoreReplication:RemoveFavorite(item, container)
    self.Event:FireServer("Favorites", "Remove", item, container)
end

function CoreReplication:ChangeSettings(settingsFolder, settingsTable, configuration)
    self.Event:FireServer("Change_Settings", settingsFolder, settingsTable, configuration)
end

function CoreReplication:Appear(item, desiredTransparency)
    self.AppearancesEvent:FireServer("Appear", nil, item, desiredTransparency)
end

function CoreReplication:Disappear(item)
    self.AppearancesEvent:FireServer("Dissapear", nil, item)
end

function CoreReplication:ChangeAppearance(characterName, style, shirtTemplate, pantsTemplate)
    self.AppearancesEvent:FireServer(nil, characterName, nil, nil, style, shirtTemplate, pantsTemplate)
end

function CoreReplication:Destroy(instance)
    self.Event:FireServer("Tools", "Remove", instance)
end

function CoreReplication:Clone(instance, parent)
    self.ToolsEvent:FireServer("Add", instance, parent)
    repeat task.wait() until parent:FindFirstChild(instance.Name)
    return parent:FindFirstChild(instance.Name)
end

local function getPlayers(target)
    local results = {}
    
    if target == "me" then
        table.insert(results, Player)
    elseif target == "others" then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= Player then
                table.insert(results, player)
            end
        end
    elseif target == "all" then
        for _, player in ipairs(Players:GetPlayers()) do
            table.insert(results, player)
        end
    elseif target == "random" then
        local allPlayers = Players:GetPlayers()
        if #allPlayers > 0 then
            table.insert(results, allPlayers[math.random(1, #allPlayers)])
        end
    else
        local pattern = target:lower()
        for _, player in ipairs(Players:GetPlayers()) do
            local name = player.Name:lower()
            local displayName = player.DisplayName:lower()
            
            if name == pattern or displayName == pattern then
                table.insert(results, player)
            elseif name:sub(1, #pattern) == pattern or displayName:sub(1, #pattern) == pattern then
                table.insert(results, player)
            elseif name:find(pattern, 1, true) or displayName:find(pattern, 1, true) then
                table.insert(results, player)
            end
        end
    end
    
    return results
end

local Commands = {
    help = {
        desc = "Show all commands",
        args = {},
        func = function() return "help" end
    },
    clear = {
        desc = "Clear console output",
        args = {},
        func = function() return "clear" end
    },
    cmds = {
        desc = "List all commands",
        args = {},
        func = function() return "list" end
    },
    
    ragdoll = {
        desc = "Ragdoll target player(s)",
        args = {"player"},
        func = function(targets)
            for _, player in ipairs(targets) do
                if player.Character then
                    local charSettings = player.Character:FindFirstChild("Character_Settings")
                    if charSettings then
                        CoreReplication:ChangeAttribute(charSettings, "Ragdoll", true)
                    end
                end
            end
            return "Ragdolled " .. #targets .. " player(s)"
        end
    },
    unragdoll = {
        desc = "Unragdoll target player(s)",
        args = {"player"},
        func = function(targets)
            for _, player in ipairs(targets) do
                if player.Character then
                    local charSettings = player.Character:FindFirstChild("Character_Settings")
                    if charSettings then
                        CoreReplication:ChangeAttribute(charSettings, "Ragdoll", false)
                    end
                end
            end
            return "Unragdolled " .. #targets .. " player(s)"
        end
    },
    
    sit = {
        desc = "Make target player(s) sit",
        args = {"player"},
        func = function(targets)
            for _, player in ipairs(targets) do
                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    local humanoid = player.Character.Humanoid
                    CoreReplication:ChangeAttribute(humanoid, "Sit", true)
                end
            end
            return "Made " .. #targets .. " player(s) sit"
        end
    },
    
    tools = {
        desc = "Give yourself all tools",
        args = {},
        func = function()
            local toolsFolder = game.ReplicatedStorage.Tools
            local count = 0
            for _, tool in ipairs(toolsFolder:GetChildren()) do
                if tool:IsA("Tool") then
                    CoreReplication:AddTool(tool, Player.Backpack)
                    count = count + 1
                end
            end
            return "Added " .. count .. " tools"
        end
    },
    tool = {
        desc = "Give yourself specific tool <name>",
        args = {"text"},
        func = function(toolName)
            local tool = game.ReplicatedStorage.Tools:FindFirstChild(toolName)
            if tool then
                CoreReplication:AddTool(tool, Player.Backpack)
                return "Added " .. toolName
            end
            return "Tool not found: " .. toolName
        end
    },
    removetools = {
        desc = "Remove all your tools",
        args = {},
        func = function()
            local count = 0
            for _, tool in ipairs(Player.Backpack:GetChildren()) do
                if tool:IsA("Tool") then
                    CoreReplication:RemoveTool(tool)
                    count = count + 1
                end
            end
            for _, tool in ipairs(Character:GetChildren()) do
                if tool:IsA("Tool") then
                    CoreReplication:RemoveTool(tool)
                    count = count + 1
                end
            end
            return "Removed " .. count .. " tools"
        end
    },
    
    morph = {
        desc = "Morph into character <name>",
        args = {"text"},
        func = function(characterName)
            local character = game.ReplicatedStorage.Characters:FindFirstChild(characterName)
            if character and Character:FindFirstChild("HumanoidRootPart") then
                local cframe = Character.HumanoidRootPart.CFrame
                CoreReplication:ChangeCharacter(character, cframe)
                return "Morphed into " .. characterName
            end
            return "Character not found: " .. characterName
        end
    },
    morphlist = {
        desc = "List available characters",
        args = {},
        func = function()
            local chars = {}
            for _, char in ipairs(game.ReplicatedStorage.Characters:GetChildren()) do
                table.insert(chars, char.Name)
            end
            return "Characters: " .. table.concat(chars, ", ")
        end
    },
    
    rpname = {
        desc = "Set roleplay name <text>",
        args = {"text"},
        func = function(name)
            local nametag = Character:FindFirstChild("Head"):FindFirstChild("Nametag")
            if nametag and nametag:FindFirstChild("Roleplay_Name") then
                CoreReplication:SetText(nametag.Roleplay_Name, name, "Roleplay_Name")
                return "Set roleplay name to: " .. name
            end
            return "Failed to set roleplay name"
        end
    },
    bio = {
        desc = "Set biography <text>",
        args = {"text"},
        func = function(bio)
            local nametag = Character:FindFirstChild("Head"):FindFirstChild("Nametag")
            if nametag and nametag:FindFirstChild("Biography") then
                CoreReplication:SetText(nametag.Biography, bio, "Biography")
                return "Set biography to: " .. bio
            end
            return "Failed to set biography"
        end
    },
    role = {
        desc = "Set role <text>",
        args = {"text"},
        func = function(role)
            local nametag = Character:FindFirstChild("Head"):FindFirstChild("Nametag")
            if nametag and nametag:FindFirstChild("Role") then
                CoreReplication:SetText(nametag.Role, role, "Role")
                return "Set role to: " .. role
            end
            return "Failed to set role"
        end
    },
    namecolor = {
        desc = "Set name color <r> <g> <b>",
        args = {"text"},
        func = function(colorStr)
            local r, g, b = colorStr:match("(%d+)%s+(%d+)%s+(%d+)")
            if r and g and b then
                local color = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
                local nametag = Character:FindFirstChild("Head"):FindFirstChild("Nametag")
                if nametag and nametag:FindFirstChild("Roleplay_Name") then
                    CoreReplication:ChangeTextColor(nametag.Roleplay_Name, color, "Role_Color")
                    return "Changed name color"
                end
            end
            return "Usage: namecolor <r> <g> <b>"
        end
    },
    biocolor = {
        desc = "Set bio color <r> <g> <b>",
        args = {"text"},
        func = function(colorStr)
            local r, g, b = colorStr:match("(%d+)%s+(%d+)%s+(%d+)")
            if r and g and b then
                local color = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
                local nametag = Character:FindFirstChild("Head"):FindFirstChild("Nametag")
                if nametag and nametag:FindFirstChild("Biography") then
                    CoreReplication:ChangeTextColor(nametag.Biography, color, "Bio_Color")
                    return "Changed bio color"
                end
            end
            return "Usage: biocolor <r> <g> <b>"
        end
    },
    
    addtag = {
        desc = "Add location tag <tag>",
        args = {"text"},
        func = function(tag)
            CoreReplication:AddTag(tag)
            return "Added tag: " .. tag
        end
    },
    removetag = {
        desc = "Remove location tag <tag>",
        args = {"text"},
        func = function(tag)
            CoreReplication:RemoveTag(tag)
            return "Removed tag: " .. tag
        end
    },
    cleartags = {
        desc = "Clear all location tags",
        args = {},
        func = function()
            CoreReplication:ClearTags(Player:GetTags())
            return "Cleared all tags"
        end
    },
    
    ws = {
        desc = "Set walkspeed for player(s) <player> <speed>",
        args = {"player", "text"},
        func = function(targets, speed)
            local num = tonumber(speed)
            if num then
                for _, player in ipairs(targets) do
                    if player.Character and player.Character:FindFirstChild("Character_Settings") then
                        local animator = player.Character.Character_Settings.Animator
                        CoreReplication:ChangeAttribute(animator, "Walk_Speed", num)
                    end
                end
                return "Set walkspeed to " .. num .. " for " .. #targets .. " player(s)"
            end
            return "Invalid walkspeed"
        end
    },
    jp = {
        desc = "Set jumppower for player(s) <player> <power>",
        args = {"player", "text"},
        func = function(targets, power)
            local num = tonumber(power)
            if num then
                for _, player in ipairs(targets) do
                    if player.Character and player.Character:FindFirstChild("Humanoid") then
                        CoreReplication:ChangeAttribute(player.Character.Humanoid, "JumpPower", num)
                    end
                end
                return "Set jumppower to " .. num .. " for " .. #targets .. " player(s)"
            end
            return "Invalid jumppower"
        end
    },
    
    invisible = {
        desc = "Make player(s) invisible <player>",
        args = {"player"},
        func = function(targets)
            local count = 0
            for _, player in ipairs(targets) do
                if player.Character then
                    for _, part in ipairs(player.Character:GetDescendants()) do
                        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                            CoreReplication:Disappear(part)
                            count = count + 1
                        end
                    end
                end
            end
            return "Made " .. #targets .. " player(s) invisible (" .. count .. " parts)"
        end
    },
    visible = {
        desc = "Make player(s) visible <player>",
        args = {"player"},
        func = function(targets)
            local count = 0
            for _, player in ipairs(targets) do
                if player.Character then
                    for _, part in ipairs(player.Character:GetDescendants()) do
                        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                            CoreReplication:Appear(part, 0)
                            count = count + 1
                        end
                    end
                end
            end
            return "Made " .. #targets .. " player(s) visible (" .. count .. " parts)"
        end
    },
    
    sitting = {
        desc = "Toggle sitting state",
        args = {},
        func = function()
            local charSettings = Character:FindFirstChild("Character_Settings")
            if charSettings then
                local current = charSettings:GetAttribute("Sitting")
                CoreReplication:ChangeAttribute(charSettings, "Sitting", not current)
                return "Sitting: " .. tostring(not current)
            end
            return "Failed to toggle sitting"
        end
    },
    
    getattributes = {
        desc = "Get all character attributes",
        args = {},
        func = function()
            local charSettings = Character:FindFirstChild("Character_Settings")
            if charSettings then
                local attrs = {}
                for name, value in pairs(charSettings:GetAttributes()) do
                    table.insert(attrs, name .. ": " .. tostring(value))
                end
                return table.concat(attrs, ", ")
            end
            return "No attributes found"
        end
    },
    playerinfo = {
        desc = "Get player info <player>",
        args = {"player"},
        func = function(targets)
            if #targets > 0 then
                local target = targets[1]
                local info = {
                    "Name: " .. target.Name,
                    "DisplayName: " .. target.DisplayName,
                    "UserId: " .. target.UserId,
                    "AccountAge: " .. target.AccountAge .. " days"
                }
                return table.concat(info, " | ")
            end
            return "Player not found"
        end
    },
    
    fireallprompts = {
        desc = "Fire all nearby prompts",
        args = {},
        func = function()
            local count = 0
            for _, prompt in ipairs(workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then
                    local distance = (Character.HumanoidRootPart.Position - prompt.Parent.Position).Magnitude
                    if distance <= prompt.MaxActivationDistance then
                        CoreReplication:TriggerPrompt(prompt, 0.1)
                        count = count + 1
                    end
                end
            end
            return "Fired " .. count .. " prompts"
        end
    },
    
    tpclass = {
        desc = "Teleport to current class",
        args = {},
        func = function()
            local currentClass = game.ReplicatedStorage.Game_Info:GetAttribute("Current_Class")
            if currentClass then
                for _, classObj in ipairs(workspace.Classes:GetChildren()) do
                    if classObj.Name:find(currentClass) then
                        if Character:FindFirstChild("HumanoidRootPart") and classObj:FindFirstChild("Tp") then
                            Character.HumanoidRootPart.CFrame = classObj.Tp.CFrame
                            return "Teleported to " .. currentClass
                        end
                    end
                end
            end
            return "No class found"
        end
    },
    
    reset = {
        desc = "Reset player(s) character <player>",
        args = {"player"},
        func = function(targets)
            for _, player in ipairs(targets) do
                if player.Character then
                    local charSettings = player.Character:FindFirstChild("Character_Settings")
                    if charSettings then
                        CoreReplication:Death(player, charSettings)
                    end
                end
            end
            return "Resetting " .. #targets .. " player(s)..."
        end
    },
    
    kick = {
        desc = "Kick player(s) <player>",
        args = {"player"},
        func = function(targets)
            for _, player in ipairs(targets) do
                if player.Character then
                    CoreReplication:Destroy(player)
                end
            end
            return "Kicked " .. #targets .. " player(s)"
        end
    },
    
    destroy = {
    desc = "Destroy instance <path>",
    args = {"text"},
    func = function(path)
        local success, result = pcall(function()
            local obj = loadstring("return " .. path)()
            if obj then
                CoreReplication:Destroy(obj)
                return true
            end
            return false
        end)
        
        if success and result then
            return "Destroyed: " .. path
        else
            return "Path not found or invalid: " .. path
        end
    end
},
    clone = {
        desc = "Clone instance <path> to <parent>",
        args = {"text"},
        func = function(args)
            local parts = args:split(" to ")
            if #parts ~= 2 then
                return "Usage: clone <path> to <parent>"
            end
            
            local sourcePath = parts[1]:split(".")
            local targetPath = parts[2]:split(".")
            
            local source = game
            for _, part in ipairs(sourcePath) do
                source = source:FindFirstChild(part)
                if not source then
                    return "Source not found: " .. parts[1]
                end
            end
            
            local target = game
            for _, part in ipairs(targetPath) do
                target = target:FindFirstChild(part)
                if not target then
                    return "Target not found: " .. parts[2]
                end
            end
            
            CoreReplication:Clone(source, target)
            return "Cloned " .. parts[1] .. " to " .. parts[2]
        end
    },
    
    spamclone = {
        desc = "Spam clone instance <path> <count>",
        args = {"text"},
        func = function(args)
            local parts = args:split(" ")
            local count = tonumber(parts[#parts])
            if not count then
                return "Usage: spamclone <path> <count>"
            end
            
            table.remove(parts, #parts)
            local path = table.concat(parts, " "):split(".")
            
            local source = game
            for _, part in ipairs(path) do
                source = source:FindFirstChild(part)
                if not source then
                    return "Path not found"
                end
            end
            
            for i = 1, count do
                CoreReplication:Clone(source, source.Parent)
            end
            
            return "Cloned " .. count .. " times"
        end
    },
    
    changealltext = {
        desc = "Change all text in game to <text>",
        args = {"text"},
        func = function(newText)
            local count = 0
            for _, descendant in ipairs(workspace:GetDescendants()) do
                if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
                    CoreReplication:SetText(descendant, newText, tostring(descendant))
                    count = count + 1
                end
            end
            for _, gui in ipairs(Player.PlayerGui:GetDescendants()) do
                if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
                    CoreReplication:SetText(gui, newText, tostring(gui))
                    count = count + 1
                end
            end
            return "Changed " .. count .. " text objects to: " .. newText
        end
    },
    armless = {
    desc = "Remove player(s) arms <player>",
    args = {"player"},
    func = function(targets)
        for _, player in ipairs(targets) do
            if player.Character then
                if player.Character:FindFirstChild("Left Arm") then
                    CoreReplication:Destroy(player.Character["Left Arm"])
                    CoreReplication:Destroy(player.Character["Right Arm"])
                elseif player.Character:FindFirstChild("LeftLowerArm") then
                    CoreReplication:Destroy(player.Character["LeftLowerArm"])
                    CoreReplication:Destroy(player.Character["RightLowerArm"])
                    CoreReplication:Destroy(player.Character["LeftUpperArm"])
                    CoreReplication:Destroy(player.Character["RightUpperArm"])
                    CoreReplication:Destroy(player.Character["LeftHand"])
                    CoreReplication:Destroy(player.Character["RightHand"])
                end
            end
        end
        return "Made " .. #targets .. " player(s) armless"
    end
},
legless = {
    desc = "Remove player(s) legs <player>",
    args = {"player"},
    func = function(targets)
        for _, player in ipairs(targets) do
            if player.Character then
                if player.Character:FindFirstChild("Left Leg") then
                    CoreReplication:Destroy(player.Character["Left Leg"])
                    CoreReplication:Destroy(player.Character["Right Leg"])
                elseif player.Character:FindFirstChild("LeftLowerLeg") then
                    CoreReplication:Destroy(player.Character["LeftLowerLeg"])
                    CoreReplication:Destroy(player.Character["RightLowerLeg"])
                    CoreReplication:Destroy(player.Character["LeftUpperLeg"])
                    CoreReplication:Destroy(player.Character["RightUpperLeg"])
                    CoreReplication:Destroy(player.Character["LeftFoot"])
                    CoreReplication:Destroy(player.Character["RightFoot"])
                end
            end
        end
        return "Made " .. #targets .. " player(s) legless"
    end
},
headless = {
    desc = "Remove player(s) head <player>",
    args = {"player"},
    func = function(targets)
        for _, player in ipairs(targets) do
            if player.Character and player.Character:FindFirstChild("Head") then
                CoreReplication:Destroy(player.Character.Head)
            end
        end
        return "Made " .. #targets .. " player(s) headless"
    end
},
blind = {
    desc = "Make player(s) blind <player>",
    args = {"player"},
    func = function(targets)
        for _, player in ipairs(targets) do
            if player.Character and player.Character:FindFirstChild("Character_Settings") then
                CoreReplication:ChangeAttribute(player.Character.Character_Settings, "Head_Vector_Y_Adapter", 1e15)
            end
        end
        return "Blinded " .. #targets .. " player(s)"
    end
},
unblind = {
    desc = "Restore player(s) vision <player>",
    args = {"player"},
    func = function(targets)
        for _, player in ipairs(targets) do
            if player.Character and player.Character:FindFirstChild("Character_Settings") then
                CoreReplication:ChangeAttribute(player.Character.Character_Settings, "Head_Vector_Y_Adapter", 1.5)
            end
        end
        return "Unblinded " .. #targets .. " player(s)"
    end
},
glow = {
    desc = "Make player(s) glow <player>",
    args = {"player"},
    func = function(targets)
        for _, player in ipairs(targets) do
            if player.Character then
                local glowing = player.Character:FindFirstChild("Class_Highlighter")
                if not glowing then
                    local highlighter = game.ReplicatedStorage.Misc.Class_Highlighter
                    CoreReplication:Clone(highlighter, player.Character)
                end
            end
        end
        return "Made " .. #targets .. " player(s) glow"
    end
},
unglow = {
    desc = "Remove player(s) glow <player>",
    args = {"player"},
    func = function(targets)
        for _, player in ipairs(targets) do
            if player.Character then
                local glowing = player.Character:FindFirstChild("Class_Highlighter")
                if glowing then
                    CoreReplication:Destroy(glowing)
                end
            end
        end
        return "Removed glow from " .. #targets .. " player(s)"
    end
},
punish = {
    desc = "Destroy player(s) character <player>",
    args = {"player"},
    func = function(targets)
        for _, player in ipairs(targets) do
            if player ~= Player and player.Character then
                CoreReplication:Destroy(player.Character)
            end
        end
        return "Punished " .. #targets .. " player(s)"
    end
},
btools = {
    desc = "Get delete tool",
    args = {},
    func = function()
        local tool = Instance.new("Tool", Player.Backpack)
        tool.Name = "Delete Tool"
        tool.RequiresHandle = false
        tool.CanBeDropped = true
        
        tool.Activated:Connect(function()
            local target = Player:GetMouse().Target
            if target then
                local explosion = Instance.new("Explosion", workspace)
                explosion.Position = target.Position
                explosion.BlastRadius = 16
                explosion.BlastPressure = 0
                explosion.DestroyJointRadiusPercent = 0
                explosion.ExplosionType = Enum.ExplosionType.NoCraters
                CoreReplication:Destroy(target)
            end
        end)
        return "Got delete tool"
    end
},
loadmap = {
    desc = "Reset map to original state",
    args = {},
    func = function()
        local originalMap = game.Lighting:FindFirstChild("Map")
        if originalMap then
            for _, v in ipairs(workspace:GetChildren()) do
                local org = originalMap:FindFirstChild(v.Name)
                if org then
                    CoreReplication:Clone(org, workspace)
                    task.wait(0.25)
                    CoreReplication:Destroy(v)
                end
            end
            return "Map reset"
        end
        return "Original map not found"
    end
},
breakserver = {
    desc = "Break the server",
    args = {},
    func = function()
        for _, v in ipairs(game.StarterGui:GetChildren()) do
            CoreReplication:Destroy(v)
        end
        for _, v in ipairs(game.ReplicatedStorage:GetChildren()) do
            CoreReplication:Destroy(v)
        end
        CoreReplication:Destroy(game.StarterPlayer.StarterCharacterScripts.Badges_Loader)
        CoreReplication:Destroy(game.StarterPlayer.StarterCharacterScripts.Client)
        return "Server broken"
    end
},
    morphall = {
        desc = "Morph all players to character <character>",
        args = {"text"},
        func = function(characterName)
            local character = game.ReplicatedStorage.Characters:FindFirstChild(characterName)
            if not character then
                return "Character not found: " .. characterName
            end
            
            local count = 0
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local cframe = player.Character.HumanoidRootPart.CFrame
                    CoreReplication:ChangeCharacter(character, cframe)
                    count = count + 1
                end
            end
            return "Morphed " .. count .. " player(s) into " .. characterName
        end
    },
    
    crashserver = {
        desc = "Crash the server by spam cloning",
        args = {},
        func = function()
            task.spawn(function()
                for i = 1, 1500 do
                    for _, obj in ipairs(workspace["INSIDE MAP"]:GetChildren()) do
                        CoreReplication:Clone(obj, workspace["INSIDE MAP"])
                    end
                end
            end)
            return "Crashing server..."
        end
    }
}


local function notify(message, color)
    color = color or Color3.fromRGB(100, 200, 255)
    
    local NotifGui = Instance.new("ScreenGui")
    NotifGui.Name = "Notification"
    NotifGui.ResetOnSpawn = false
    NotifGui.Parent = CoreGui
    
    local NotifFrame = Instance.new("Frame")
    NotifFrame.Size = UDim2.new(0, 300, 0, 50)
    NotifFrame.Position = UDim2.new(1, -320, 0, 20)
    NotifFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    NotifFrame.BorderSizePixel = 0
    NotifFrame.Parent = NotifGui
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = NotifFrame
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = color
    UIStroke.Thickness = 2
    UIStroke.Parent = NotifFrame
    
    local NotifText = Instance.new("TextLabel")
    NotifText.Size = UDim2.new(1, -20, 1, 0)
    NotifText.Position = UDim2.new(0, 10, 0, 0)
    NotifText.BackgroundTransparency = 1
    NotifText.Font = Enum.Font.GothamBold
    NotifText.TextSize = 14
    NotifText.TextColor3 = Color3.fromRGB(255, 255, 255)
    NotifText.Text = message
    NotifText.TextXAlignment = Enum.TextXAlignment.Left
    NotifText.Parent = NotifFrame
    
    NotifFrame.Position = UDim2.new(1, 0, 0, 20)
    TweenService:Create(NotifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = UDim2.new(1, -320, 0, 20)
    }):Play()
    
    task.wait(3)
    TweenService:Create(NotifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Position = UDim2.new(1, 0, 0, 20)
    }):Play()
    task.wait(0.3)
    NotifGui:Destroy()
end

local ConsoleOutput = {}

local function addConsoleOutput(text, color)
    table.insert(ConsoleOutput, {text = text, color = color or Color3.fromRGB(200, 200, 200)})
    if #ConsoleOutput > 50 then
        table.remove(ConsoleOutput, 1)
    end
end

local function createGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CommandLineInterface"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local ConsoleFrame = Instance.new("Frame")
    ConsoleFrame.Name = "ConsoleFrame"
    ConsoleFrame.Size = UDim2.new(0, 600, 0, 300)
    ConsoleFrame.Position = UDim2.new(0.5, -300, 0, -350)
    ConsoleFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    ConsoleFrame.BorderSizePixel = 0
    ConsoleFrame.Visible = false
    ConsoleFrame.Parent = ScreenGui
    
    local ConsoleCorner = Instance.new("UICorner")
    ConsoleCorner.CornerRadius = UDim.new(0, 8)
    ConsoleCorner.Parent = ConsoleFrame
    
    local ConsoleStroke = Instance.new("UIStroke")
    ConsoleStroke.Color = Color3.fromRGB(60, 60, 70)
    ConsoleStroke.Thickness = 2
    ConsoleStroke.Parent = ConsoleFrame
    
    local ConsoleScroll = Instance.new("ScrollingFrame")
    ConsoleScroll.Name = "ConsoleScroll"
    ConsoleScroll.Size = UDim2.new(1, -20, 1, -20)
    ConsoleScroll.Position = UDim2.new(0, 10, 0, 10)
    ConsoleScroll.BackgroundTransparency = 1
    ConsoleScroll.BorderSizePixel = 0
    ConsoleScroll.ScrollBarThickness = 4
    ConsoleScroll.Parent = ConsoleFrame
    
    local ConsoleList = Instance.new("UIListLayout")
    ConsoleList.Padding = UDim.new(0, 2)
    ConsoleList.Parent = ConsoleScroll
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 600, 0, 40)
    MainFrame.Position = UDim2.new(0.5, -300, 0, -50)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    MainFrame.BorderSizePixel = 0
    MainFrame.Visible = false
    MainFrame.Parent = ScreenGui
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(60, 60, 70)
    UIStroke.Thickness = 2
    UIStroke.Parent = MainFrame
    
    local CommandInput = Instance.new("TextBox")
    CommandInput.Name = "CommandInput"
    CommandInput.Size = UDim2.new(1, -20, 1, -10)
    CommandInput.Position = UDim2.new(0, 10, 0, 5)
    CommandInput.BackgroundTransparency = 1
    CommandInput.Font = Enum.Font.RobotoMono
    CommandInput.TextSize = 16
    CommandInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    CommandInput.PlaceholderText = "❯ Type command..."
    CommandInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
    CommandInput.Text = ""
    CommandInput.TextXAlignment = Enum.TextXAlignment.Left
    CommandInput.ClearTextOnFocus = false
    CommandInput.MultiLine = false
    CommandInput.Parent = MainFrame

    local last = CommandInput.Text

    CommandInput:GetPropertyChangedSignal("Text"):Connect(function()
        local text = CommandInput.Text
        local cleaned = text:gsub("\t", ""):gsub("   ", "")
        if cleaned ~= text then
            local pos = CommandInput.CursorPosition
            CommandInput.Text = cleaned
            CommandInput.CursorPosition = math.max(pos - 1, 1)
        end
        last = cleaned
    end)

    local AutocompleteFrame = Instance.new("Frame")
    AutocompleteFrame.Name = "AutocompleteFrame"
    AutocompleteFrame.Size = UDim2.new(1, 0, 0, 0)
    AutocompleteFrame.Position = UDim2.new(0, 0, 1, 5)
    AutocompleteFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    AutocompleteFrame.BorderSizePixel = 0
    AutocompleteFrame.Visible = false
    AutocompleteFrame.Parent = MainFrame
    
    local ACCorner = Instance.new("UICorner")
    ACCorner.CornerRadius = UDim.new(0, 6)
    ACCorner.Parent = AutocompleteFrame
    
    local ACStroke = Instance.new("UIStroke")
    ACStroke.Color = Color3.fromRGB(60, 60, 70)
    ACStroke.Thickness = 1
    ACStroke.Parent = AutocompleteFrame
    
    local AutocompleteScroll = Instance.new("ScrollingFrame")
    AutocompleteScroll.Name = "AutocompleteScroll"
    AutocompleteScroll.Size = UDim2.new(1, 0, 1, 0)
    AutocompleteScroll.BackgroundTransparency = 1
    AutocompleteScroll.BorderSizePixel = 0
    AutocompleteScroll.ScrollBarThickness = 4
    AutocompleteScroll.Parent = AutocompleteFrame
    
    local AutocompleteList = Instance.new("UIListLayout")
    AutocompleteList.Padding = UDim.new(0, 2)
    AutocompleteList.Parent = AutocompleteScroll
    
    return ScreenGui, MainFrame, CommandInput, AutocompleteFrame, AutocompleteScroll, ConsoleFrame, ConsoleScroll
end

local ScreenGui, MainFrame, CommandInput, AutocompleteFrame, AutocompleteScroll, ConsoleFrame, ConsoleScroll = createGUI()
ScreenGui.Parent = CoreGui

local isOpen = false
local selectedIndex = 0
local autocompleteOptions = {}

local function updateConsole()
    ConsoleScroll:ClearAllChildren()
    
    local ConsoleList = Instance.new("UIListLayout")
    ConsoleList.Padding = UDim.new(0, 2)
    ConsoleList.Parent = ConsoleScroll
    
    for _, entry in ipairs(ConsoleOutput) do
        local TextLabel = Instance.new("TextLabel")
        TextLabel.Size = UDim2.new(1, -10, 0, 20)
        TextLabel.BackgroundTransparency = 1
        TextLabel.Font = Enum.Font.RobotoMono
        TextLabel.TextSize = 14
        TextLabel.TextColor3 = entry.color
        TextLabel.Text = entry.text
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.TextYAlignment = Enum.TextYAlignment.Top
        TextLabel.TextWrapped = true
        TextLabel.Parent = ConsoleScroll
        
        TextLabel.Size = UDim2.new(1, -10, 0, TextLabel.TextBounds.Y)
    end
    
    ConsoleScroll.CanvasSize = UDim2.new(0, 0, 0, ConsoleList.AbsoluteContentSize.Y)
    ConsoleScroll.CanvasPosition = Vector2.new(0, ConsoleScroll.CanvasSize.Y.Offset)
end

local function getAutocompleteSuggestions(text)
    local suggestions = {}
    local words = text:split(" ")
    local currentWord = words[#words] or ""
    
    if #words == 1 then
        for cmdName, cmd in pairs(Commands) do
            if cmdName:lower():sub(1, #currentWord:lower()) == currentWord:lower() then
                table.insert(suggestions, {
                    text = cmdName,
                    desc = cmd.desc,
                    type = "command"
                })
            end
        end
    else
        local cmdName = words[1]
        local cmd = Commands[cmdName]
        
        if cmd and cmd.args and #cmd.args > 0 and cmd.args[1] == "player" then
            local specialTargets = {"me", "others", "all", "random"}
            for _, target in ipairs(specialTargets) do
                if target:sub(1, #currentWord:lower()) == currentWord:lower() then
                    table.insert(suggestions, {
                        text = target,
                        desc = "Special target",
                        type = "target"
                    })
                end
            end
            
            for _, player in ipairs(Players:GetPlayers()) do
                local name = player.Name
                local displayName = player.DisplayName
                
                if name:lower():sub(1, #currentWord:lower()) == currentWord:lower() or
                   displayName:lower():sub(1, #currentWord:lower()) == currentWord:lower() then
                    table.insert(suggestions, {
                        text = name,
                        desc = "@" .. displayName,
                        type = "player"
                    })
                end
            end
        end
    end
    
    return suggestions
end

local function updateAutocomplete(text)
    AutocompleteScroll:ClearAllChildren()
    
    local suggestions = getAutocompleteSuggestions(text)
    autocompleteOptions = suggestions
    
    if #suggestions == 0 then
        AutocompleteFrame.Visible = false
        return
    end
    
    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Padding = UDim.new(0, 2)
    ListLayout.Parent = AutocompleteScroll
    
    for i, suggestion in ipairs(suggestions) do
        local SuggestionButton = Instance.new("TextButton")
        SuggestionButton.Size = UDim2.new(1, -10, 0, 25)
        SuggestionButton.BackgroundColor3 = i == selectedIndex and Color3.fromRGB(40, 40, 50) or Color3.fromRGB(25, 25, 30)
        SuggestionButton.BorderSizePixel = 0
        SuggestionButton.Font = Enum.Font.RobotoMono
        SuggestionButton.TextSize = 14
        SuggestionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        SuggestionButton.TextXAlignment = Enum.TextXAlignment.Left
        SuggestionButton.Text = "  " .. suggestion.text .. " - " .. suggestion.desc
        SuggestionButton.Parent = AutocompleteScroll
        
        local typeColor = suggestion.type == "command" and Color3.fromRGB(100, 200, 255) or 
                          suggestion.type == "player" and Color3.fromRGB(100, 255, 100) or
                          Color3.fromRGB(255, 200, 100)
        
        local TypeIndicator = Instance.new("Frame")
        TypeIndicator.Size = UDim2.new(0, 3, 1, 0)
        TypeIndicator.Position = UDim2.new(0, 0, 0, 0)
        TypeIndicator.BackgroundColor3 = typeColor
        TypeIndicator.BorderSizePixel = 0
        TypeIndicator.Parent = SuggestionButton
        
        SuggestionButton.MouseButton1Click:Connect(function()
            local words = text:split(" ")
            words[#words] = suggestion.text
            CommandInput.Text = table.concat(words, " ")
            CommandInput:CaptureFocus()
            updateAutocomplete(CommandInput.Text)
        end)
    end
    
    ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        AutocompleteScroll.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
    end)
    
    local maxHeight = math.min(150, ListLayout.AbsoluteContentSize.Y + 10)
    AutocompleteFrame.Size = UDim2.new(1, 0, 0, maxHeight)
    AutocompleteFrame.Visible = true
end

local function executeCommand(text)
    addConsoleOutput("❯ " .. text, Color3.fromRGB(100, 200, 255))
    
    local words = text:split(" ")
    local cmdName = words[1]
    local cmd = Commands[cmdName]
    
    if not cmd then
        addConsoleOutput("Unknown command: " .. cmdName, Color3.fromRGB(255, 100, 100))
        notify("Unknown command", Color3.fromRGB(255, 100, 100))
        updateConsole()
        return
    end
    
    if cmdName == "help" then
        for name, command in pairs(Commands) do
            addConsoleOutput(name .. " - " .. command.desc, Color3.fromRGB(200, 200, 200))
        end
        updateConsole()
        return
    elseif cmdName == "clear" then
        ConsoleOutput = {}
        updateConsole()
        return
    elseif cmdName == "cmds" then
        for name, command in pairs(Commands) do
            local argStr = #command.args > 0 and " <" .. table.concat(command.args, "> <") .. ">" or ""
            addConsoleOutput(name .. argStr .. " - " .. command.desc, Color3.fromRGB(200, 200, 200))
        end
        updateConsole()
        return
    end
    
    if cmd.args and #cmd.args > 0 and cmd.args[1] == "player" then
        if #words < 2 then
            addConsoleOutput("Missing player target", Color3.fromRGB(255, 100, 100))
            updateConsole()
            return
        end
        
        local target = words[2]
        local targets = getPlayers(target)
        
        if #targets == 0 then
            addConsoleOutput("No players found matching: " .. target, Color3.fromRGB(255, 100, 100))
            notify("No players found", Color3.fromRGB(255, 100, 100))
            updateConsole()
            return
        end
        
        if #cmd.args == 2 and cmd.args[2] == "text" then
            if #words < 3 then
                addConsoleOutput("Missing argument", Color3.fromRGB(255, 100, 100))
                updateConsole()
                return
            end
            
            table.remove(words, 1)
            table.remove(words, 1)
            local arg = table.concat(words, " ")
            local result = cmd.func(targets, arg)
            addConsoleOutput(result, Color3.fromRGB(100, 255, 100))
            notify(result, Color3.fromRGB(100, 255, 100))
        else
            local result = cmd.func(targets)
            addConsoleOutput(result, Color3.fromRGB(100, 255, 100))
            notify(result, Color3.fromRGB(100, 255, 100))
        end
    elseif cmd.args and #cmd.args > 0 and cmd.args[1] == "text" then
        if #words < 2 then
            addConsoleOutput("Missing argument", Color3.fromRGB(255, 100, 100))
            updateConsole()
            return
        end
        
        table.remove(words, 1)
        local arg = table.concat(words, " ")
        local result = cmd.func(arg)
        addConsoleOutput(result, Color3.fromRGB(100, 255, 100))
        notify(result, Color3.fromRGB(100, 255, 100))
    else
        local result = cmd.func()
        addConsoleOutput(result, Color3.fromRGB(100, 255, 100))
        notify(result, Color3.fromRGB(100, 255, 100))
    end
    
    updateConsole()
end

local function toggleCLI()
    isOpen = not isOpen
    
    if isOpen then
        MainFrame.Visible = true
        MainFrame:TweenPosition(UDim2.new(0.5, -300, 0, 20), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.3, true)
        ConsoleFrame.Visible = true
        ConsoleFrame:TweenPosition(UDim2.new(0.5, -300, 0, 70), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.3, true)
        CommandInput:CaptureFocus()
        task.spawn(function()
    while isOpen do
        if not CommandInput:IsFocused() then
            CommandInput:CaptureFocus()
        end
        task.wait(0.1)
    end
end)
    else
        MainFrame:TweenPosition(UDim2.new(0.5, -300, 0, -50), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.3, true)
        ConsoleFrame:TweenPosition(UDim2.new(0.5, -300, 0, -350), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.3, true)
        task.wait(0.3)
        MainFrame.Visible = false
        ConsoleFrame.Visible = false
        AutocompleteFrame.Visible = false
        CommandInput:ReleaseFocus()
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Insert then
        toggleCLI()
    elseif input.KeyCode == Enum.KeyCode.Escape and isOpen then
        toggleCLI()
    elseif input.KeyCode == Enum.KeyCode.Return and isOpen then
    local cmd = CommandInput.Text:gsub("\n", ""):gsub("\r", "")
    CommandInput.Text = ""
    if cmd ~= "" then
        executeCommand(cmd)
        AutocompleteFrame.Visible = false
    end
    elseif input.KeyCode == Enum.KeyCode.Tab and isOpen then
        if #autocompleteOptions > 0 then
            selectedIndex = (selectedIndex % #autocompleteOptions) + 1
            local words = CommandInput.Text:split(" ")
            words[#words] = autocompleteOptions[selectedIndex].text
            CommandInput.Text = table.concat(words, " ").." "
            updateAutocomplete(CommandInput.Text)
            CommandInput.CursorPosition = #CommandInput.Text + 1
        end
    end
end)
CommandInput.Focused:Connect(function()
    if not isOpen then
        CommandInput:ReleaseFocus()
    end
end)

CommandInput:GetPropertyChangedSignal("Text"):Connect(function()
    if not CommandInput:IsFocused() and isOpen then
        CommandInput:CaptureFocus()
    end
    
    if CommandInput.Text ~= "" then
        updateAutocomplete(CommandInput.Text)
    else
        AutocompleteFrame.Visible = false
    end
    selectedIndex = 0
end)
CommandInput:GetPropertyChangedSignal("Text"):Connect(function()
    if CommandInput.Text ~= "" then
        updateAutocomplete(CommandInput.Text)
    else
        AutocompleteFrame.Visible = false
    end
    selectedIndex = 0
end)


addConsoleOutput("FluentCLI ServerSide (fpe rp gay) loaded!", Color3.fromRGB(100, 255, 100))
addConsoleOutput("Press INSERT to open, ESC to close", Color3.fromRGB(200, 200, 200))
addConsoleOutput("Type 'help' for commands", Color3.fromRGB(200, 200, 200))
updateConsole()

notify("FluentCLI SS loaded.", Color3.fromRGB(100, 255, 100))
task.spawn(function()
while task.wait() do
    if CommandInput.Text:find("[\n\r]") then
        CommandInput.Text = CommandInput.Text:gsub("[\n\r]", "")
    end
end
end)
