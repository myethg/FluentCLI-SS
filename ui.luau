local players = game:GetService("Players")
local userinputservice = game:GetService("UserInputService")
local tweenservice = game:GetService("TweenService")
local coregui = game:GetService("CoreGui")
local player = players.LocalPlayer

local library = {}
library.commands = {}
library.console_output = {}
library.command_history = {}
library.history_index = 0
library.is_open = false
library.selected_index = 0
library.autocomplete_options = {}

local screengui, mainframe, commandinput, autocompleteframe, autocompletescroll, consoleframe, consolescroll, titlebar, statusbar

local function notify(message, color)
    color = color or Color3.fromRGB(100, 200, 255)
    
    local notifgui = Instance.new("ScreenGui")
    notifgui.Name = "Notification"
    notifgui.ResetOnSpawn = false
    notifgui.Parent = coregui
    
    local notifframe = Instance.new("Frame")
    notifframe.Size = UDim2.new(0, 350, 0, 60)
    notifframe.Position = UDim2.new(1, 20, 0, 20)
    notifframe.BackgroundColor3 = Color3.fromRGB(18, 18, 23)
    notifframe.BorderSizePixel = 0
    notifframe.Parent = notifgui
    notifframe.ClipsDescendants = true
    
    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0, 12)
    uicorner.Parent = notifframe
    
    local uistroke = Instance.new("UIStroke")
    uistroke.Color = Color3.fromRGB(80, 80, 90)
    uistroke.Thickness = 2
    uistroke.Transparency = 0.3
    uistroke.Parent = notifframe
    
    local glow = Instance.new("ImageLabel")
    glow.Size = UDim2.new(1, 40, 1, 40)
    glow.Position = UDim2.new(0.5, 0, 0.5, 0)
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    glow.ImageColor3 = color
    glow.ImageTransparency = 0.95
    glow.ScaleType = Enum.ScaleType.Slice
    glow.SliceCenter = Rect.new(10, 10, 10, 10)
    glow.Parent = notifframe
    
    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 4, 1, 0)
    accent.Position = UDim2.new(0, 0, 0, 0)
    accent.BackgroundColor3 = color
    accent.BorderSizePixel = 0
    accent.Parent = notifframe
    
    local accentcorner = Instance.new("UICorner")
    accentcorner.CornerRadius = UDim.new(0, 12)
    accentcorner.Parent = accent
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 40, 0, 40)
    icon.Position = UDim2.new(0, 10, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.BackgroundTransparency = 1
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 24
    icon.TextColor3 = color
    icon.Text = "✓"
    icon.Parent = notifframe
    
    local notiftext = Instance.new("TextLabel")
    notiftext.Size = UDim2.new(1, -70, 1, 0)
    notiftext.Position = UDim2.new(0, 60, 0, 0)
    notiftext.BackgroundTransparency = 1
    notiftext.Font = Enum.Font.GothamMedium
    notiftext.TextSize = 15
    notiftext.TextColor3 = Color3.fromRGB(255, 255, 255)
    notiftext.Text = message
    notiftext.TextXAlignment = Enum.TextXAlignment.Left
    notiftext.TextWrapped = true
    notiftext.Parent = notifframe
    
    notifframe.Position = UDim2.new(1, 20, 0, 20)
    
    local slide_in = tweenservice:Create(notifframe, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -370, 0, 20)
    })
    
    local glow_pulse = tweenservice:Create(glow, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        ImageTransparency = 0.95
    })
    
    slide_in:Play()
    
    task.wait(3.5)
    
    local slide_out = tweenservice:Create(notifframe, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(1, 20, 0, 20)
    })
    
    local fade_out = tweenservice:Create(notifframe, TweenInfo.new(0.4), {
        BackgroundTransparency = 1
    })
    
    slide_out:Play()
    fade_out:Play()
    task.wait(0.4)
    notifgui:Destroy()
end

local function add_console_output(text, color)
    table.insert(library.console_output, {text = text, color = color or Color3.fromRGB(200, 200, 200), time = os.date("%H:%M:%S")})
    if #library.console_output > 100 then
        table.remove(library.console_output, 1)
    end
end

local function update_console()
    consolescroll:ClearAllChildren()
    
    local consolelist = Instance.new("UIListLayout")
    consolelist.Padding = UDim.new(0, 4)
    consolelist.Parent = consolescroll
    
    for i, entry in ipairs(library.console_output) do
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -10, 0, 25)
        container.BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(20, 20, 25) or Color3.fromRGB(18, 18, 23)
        container.BorderSizePixel = 0
        container.Parent = consolescroll
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = container
        
        local timestamp = Instance.new("TextLabel")
        timestamp.Size = UDim2.new(0, 60, 1, 0)
        timestamp.Position = UDim2.new(0, 8, 0, 0)
        timestamp.BackgroundTransparency = 1
        timestamp.Font = Enum.Font.RobotoMono
        timestamp.TextSize = 11
        timestamp.TextColor3 = Color3.fromRGB(120, 120, 130)
        timestamp.Text = entry.time
        timestamp.TextXAlignment = Enum.TextXAlignment.Left
        timestamp.Parent = container
        
        local textlabel = Instance.new("TextLabel")
        textlabel.Size = UDim2.new(1, -75, 1, 0)
        textlabel.Position = UDim2.new(0, 70, 0, 0)
        textlabel.BackgroundTransparency = 1
        textlabel.Font = Enum.Font.RobotoMono
        textlabel.TextSize = 14
        textlabel.TextColor3 = entry.color
        textlabel.Text = entry.text
        textlabel.TextXAlignment = Enum.TextXAlignment.Left
        textlabel.TextYAlignment = Enum.TextYAlignment.Center
        textlabel.TextWrapped = true
        textlabel.Parent = container
        
        if textlabel.TextBounds.Y > 25 then
            container.Size = UDim2.new(1, -10, 0, textlabel.TextBounds.Y + 10)
        end
    end
    
    consolescroll.CanvasSize = UDim2.new(0, 0, 0, consolelist.AbsoluteContentSize.Y + 10)
    consolescroll.CanvasPosition = Vector2.new(0, consolescroll.CanvasSize.Y.Offset)
end

local function get_players(target)
    local results = {}
    
    if target == "me" then
        table.insert(results, player)
    elseif target == "others" then
        for _, p in ipairs(players:GetPlayers()) do
            if p ~= player then
                table.insert(results, p)
            end
        end
    elseif target == "all" then
        for _, p in ipairs(players:GetPlayers()) do
            table.insert(results, p)
        end
    elseif target == "random" then
        local all_players = players:GetPlayers()
        if #all_players > 0 then
            table.insert(results, all_players[math.random(1, #all_players)])
        end
    else
        local pattern = target:lower()
        for _, p in ipairs(players:GetPlayers()) do
            local name = p.Name:lower()
            local displayname = p.DisplayName:lower()
            if name == pattern or displayname == pattern then
                table.insert(results, p)
            elseif name:sub(1, #pattern) == pattern or displayname:sub(1, #pattern) == pattern then
                table.insert(results, p)
            elseif name:find(pattern, 1, true) or displayname:find(pattern, 1, true) then
                table.insert(results, p)
            end
        end
    end
    
    return results
end

local function get_autocomplete_suggestions(text)
    local suggestions = {}
    local words = text:split(" ")
    local current_word = words[#words] or ""
    
    if #words == 1 then
        for cmdname, cmd in pairs(library.commands) do
            if cmdname:lower():sub(1, #current_word:lower()) == current_word:lower() then
                table.insert(suggestions, {
                    text = cmdname,
                    desc = cmd.desc,
                    type = "command"
                })
            end
        end
    else
        local cmdname = words[1]
        local cmd = library.commands[cmdname]
        
        if cmd and cmd.args and #cmd.args > 0 and cmd.args[1] == "player" then
            local special_targets = {"me", "others", "all", "random"}
            for _, target in ipairs(special_targets) do
                if target:sub(1, #current_word:lower()) == current_word:lower() then
                    table.insert(suggestions, {
                        text = target,
                        desc = "Special target",
                        type = "target"
                    })
                end
            end
            
            for _, p in ipairs(players:GetPlayers()) do
                local name = p.Name
                local displayname = p.DisplayName
                if name:lower():sub(1, #current_word:lower()) == current_word:lower() or 
                   displayname:lower():sub(1, #current_word:lower()) == current_word:lower() then
                    table.insert(suggestions, {
                        text = name,
                        desc = "@" .. displayname,
                        type = "player"
                    })
                end
            end
        end
    end
    
    return suggestions
end

local function update_autocomplete(text)
    autocompletescroll:ClearAllChildren()
    
    local suggestions = get_autocomplete_suggestions(text)
    library.autocomplete_options = suggestions
    
    if #suggestions == 0 then
        tweenservice:Create(autocompleteframe, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Size = UDim2.new(1, 0, 0, 0)
        }):Play()
        task.wait(0.2)
        autocompleteframe.Visible = false
        return
    end
    
    local listlayout = Instance.new("UIListLayout")
    listlayout.Padding = UDim.new(0, 3)
    listlayout.Parent = autocompletescroll
    
    for i, suggestion in ipairs(suggestions) do
        local suggestionbutton = Instance.new("TextButton")
        suggestionbutton.Size = UDim2.new(1, -10, 0, 30)
        suggestionbutton.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        suggestionbutton.BorderSizePixel = 0
        suggestionbutton.Font = Enum.Font.GothamMedium
        suggestionbutton.TextSize = 14
        suggestionbutton.TextColor3 = Color3.fromRGB(255, 255, 255)
        suggestionbutton.TextXAlignment = Enum.TextXAlignment.Left
        suggestionbutton.Text = "  " .. suggestion.text
        suggestionbutton.AutoButtonColor = false
        suggestionbutton.Parent = autocompletescroll
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = suggestionbutton
        
        local typecolor = suggestion.type == "command" and Color3.fromRGB(100, 200, 255) or
                          suggestion.type == "player" and Color3.fromRGB(100, 255, 100) or
                          Color3.fromRGB(255, 200, 100)
        
        local typeindicator = Instance.new("Frame")
        typeindicator.Size = UDim2.new(0, 4, 0.7, 0)
        typeindicator.Position = UDim2.new(0, 0, 0.15, 0)
        typeindicator.BackgroundColor3 = typecolor
        typeindicator.BorderSizePixel = 0
        typeindicator.Parent = suggestionbutton
        
        local indicatorcorner = Instance.new("UICorner")
        indicatorcorner.CornerRadius = UDim.new(1, 0)
        indicatorcorner.Parent = typeindicator
        
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 12)
        padding.Parent = suggestionbutton
        
        local desctext = Instance.new("TextLabel")
        desctext.Size = UDim2.new(1, -40, 1, 0)
        desctext.Position = UDim2.new(1, -10, 0, 0)
        desctext.AnchorPoint = Vector2.new(1, 0)
        desctext.BackgroundTransparency = 1
        desctext.Font = Enum.Font.Gotham
        desctext.TextSize = 12
        desctext.TextColor3 = Color3.fromRGB(150, 150, 160)
        desctext.Text = suggestion.desc
        desctext.TextXAlignment = Enum.TextXAlignment.Right
        desctext.Parent = suggestionbutton
        
        if i == library.selected_index then
            suggestionbutton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            local stroke = Instance.new("UIStroke")
            stroke.Color = typecolor
            stroke.Thickness = 2
            stroke.Transparency = 0.5
            stroke.Parent = suggestionbutton
        end
        
        suggestionbutton.MouseEnter:Connect(function()
            tweenservice:Create(suggestionbutton, TweenInfo.new(0.15), {
                BackgroundColor3 = Color3.fromRGB(35, 35, 42)
            }):Play()
            tweenservice:Create(typeindicator, TweenInfo.new(0.15), {
                Size = UDim2.new(0, 6, 0.7, 0)
            }):Play()
        end)
        
        suggestionbutton.MouseLeave:Connect(function()
            if i ~= library.selected_index then
                tweenservice:Create(suggestionbutton, TweenInfo.new(0.15), {
                    BackgroundColor3 = Color3.fromRGB(25, 25, 30)
                }):Play()
            end
            tweenservice:Create(typeindicator, TweenInfo.new(0.15), {
                Size = UDim2.new(0, 4, 0.7, 0)
            }):Play()
        end)
        
        suggestionbutton.MouseButton1Click:Connect(function()
            local words = text:split(" ")
            words[#words] = suggestion.text
            commandinput.Text = table.concat(words, " ")
            commandinput:CaptureFocus()
            update_autocomplete(commandinput.Text)
        end)
    end
    
    listlayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        autocompletescroll.CanvasSize = UDim2.new(0, 0, 0, listlayout.AbsoluteContentSize.Y)
    end)
    
    local max_height = math.min(180, listlayout.AbsoluteContentSize.Y + 15)
    autocompleteframe.Visible = true
    tweenservice:Create(autocompleteframe, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Size = UDim2.new(1, 0, 0, max_height)
    }):Play()
end

local function execute_command(text)
    add_console_output("❯ " .. text, Color3.fromRGB(100, 200, 255))
    
    table.insert(library.command_history, text)
    library.history_index = 0
    
    autocompleteframe.Visible = false
    
    local words = text:split(" ")
    local cmdname = words[1]
    local cmd = library.commands[cmdname]
    
    if not cmd then
        add_console_output("✗ Unknown command: " .. cmdname, Color3.fromRGB(255, 100, 100))
        notify("Unknown command", Color3.fromRGB(255, 100, 100))
        update_console()
        return
    end
    
    if cmdname == "help" then
        for name, command in pairs(library.commands) do
            add_console_output(name .. " - " .. command.desc, Color3.fromRGB(200, 200, 200))
        end
        update_console()
        return
    elseif cmdname == "clear" then
        library.console_output = {}
        update_console()
        return
    elseif cmdname == "cmds" then
        for name, command in pairs(library.commands) do
            local arg_str = #command.args > 0 and " <" .. table.concat(command.args, "> <") .. ">" or ""
            add_console_output(name .. arg_str .. " - " .. command.desc, Color3.fromRGB(200, 200, 200))
        end
        update_console()
        return
    end
    
    if cmd.args and #cmd.args > 0 and cmd.args[1] == "player" then
        if #words < 2 then
            add_console_output("✗ Missing player target", Color3.fromRGB(255, 100, 100))
            update_console()
            return
        end
        
        local target = words[2]
        local targets = get_players(target)
        
        if #targets == 0 then
            add_console_output("✗ No players found matching: " .. target, Color3.fromRGB(255, 100, 100))
            notify("No players found", Color3.fromRGB(255, 100, 100))
            update_console()
            return
        end
        
        if #cmd.args == 2 and cmd.args[2] == "text" then
            if #words < 3 then
                add_console_output("✗ Missing argument", Color3.fromRGB(255, 100, 100))
                update_console()
                return
            end
            
            table.remove(words, 1)
            table.remove(words, 1)
            local arg = table.concat(words, " ")
            local result = cmd.func(targets, arg)
            add_console_output("✓ " .. result, Color3.fromRGB(100, 255, 100))
            notify(result, Color3.fromRGB(100, 255, 100))
        else
            local result = cmd.func(targets)
            add_console_output("✓ " .. result, Color3.fromRGB(100, 255, 100))
            notify(result, Color3.fromRGB(100, 255, 100))
        end
    elseif cmd.args and #cmd.args > 0 and cmd.args[1] == "text" then
        if #words < 2 then
            add_console_output("✗ Missing argument", Color3.fromRGB(255, 100, 100))
            update_console()
            return
        end
        
        table.remove(words, 1)
        local arg = table.concat(words, " ")
        local result = cmd.func(arg)
        add_console_output("✓ " .. result, Color3.fromRGB(100, 255, 100))
        notify(result, Color3.fromRGB(100, 255, 100))
    else
        local result = cmd.func()
        add_console_output("✓ " .. result, Color3.fromRGB(100, 255, 100))
        notify(result, Color3.fromRGB(100, 255, 100))
    end
    
    update_console()
end

local function update_status()
    local cmd_count = 0
    for _ in pairs(library.commands) do
        cmd_count = cmd_count + 1
    end
    
    statusbar.Text = string.format("  Commands: %d | History: %d | Players: %d", 
        cmd_count, #library.command_history, #players:GetPlayers())
end
local function toggle_cli()
    library.is_open = not library.is_open
    
    if library.is_open then
        mainframe.Visible = true
        consoleframe.Visible = true
        mainframe.BackgroundTransparency = 0
        consoleframe.BackgroundTransparency = 0
        
        tweenservice:Create(mainframe, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, -350, 0, 30)
        }):Play()
        
        tweenservice:Create(consoleframe, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, -350, 0, 120)
        }):Play()
        
        task.wait(0.2)
        commandinput:CaptureFocus()
        update_status()
        
        task.spawn(function()
            while library.is_open do
                if not commandinput:IsFocused() then
                    commandinput:CaptureFocus()
                end
                task.wait(0.1)
            end
        end)
    else
        tweenservice:Create(mainframe, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -350, 0, -100)
        }):Play()
        
        tweenservice:Create(consoleframe, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -350, 0, -450)
        }):Play()
        
        task.wait(0.3)
        mainframe.Visible = false
        consoleframe.Visible = false
        autocompleteframe.Visible = false
        commandinput:ReleaseFocus()
    end
end

local function create_gui()
    local sg = Instance.new("ScreenGui")
    sg.Name = "CommandLineInterface"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local cf = Instance.new("Frame")
    cf.Name = "ConsoleFrame"
    cf.Size = UDim2.new(0, 700, 0, 350)
    cf.Position = UDim2.new(0.5, -350, 0, -450)
    cf.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    cf.BorderSizePixel = 0
    cf.Visible = false
    cf.BackgroundTransparency = 1
    cf.Parent = sg
    
    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 12)
    cc.Parent = cf
    
    local cs = Instance.new("UIStroke")
    cs.Color = Color3.fromRGB(100, 200, 255)
    cs.Thickness = 2
    cs.Transparency = 0.3
    cs.Parent = cf
    
    local cscroll = Instance.new("ScrollingFrame")
    cscroll.Name = "ConsoleScroll"
    cscroll.Size = UDim2.new(1, -30, 1, -30)
    cscroll.Position = UDim2.new(0, 15, 0, 15)
    cscroll.BackgroundTransparency = 1
    cscroll.BorderSizePixel = 0
    cscroll.ScrollBarThickness = 6
    cscroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    cscroll.Parent = cf
    
    local mf = Instance.new("Frame")
    mf.Name = "MainFrame"
    mf.Size = UDim2.new(0, 700, 0, 75)
    mf.Position = UDim2.new(0.5, -350, 0, -100)
    mf.BackgroundColor3 = Color3.fromRGB(18, 18, 23)
    mf.BorderSizePixel = 0
    mf.Visible = false
    mf.BackgroundTransparency = 1
    mf.Parent = sg
    
    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0, 12)
    uicorner.Parent = mf
    
    local uistroke = Instance.new("UIStroke")
    uistroke.Color = Color3.fromRGB(100, 200, 255)
    uistroke.Thickness = 2
    uistroke.Transparency = 0.3
    uistroke.Parent = mf
    
    local tb = Instance.new("Frame")
    tb.Name = "TitleBar"
    tb.Size = UDim2.new(1, 0, 0, 30)
    tb.Position = UDim2.new(0, 0, 0, 0)
    tb.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    tb.BorderSizePixel = 0
    tb.Parent = mf
    
    local tbcorner = Instance.new("UICorner")
    tbcorner.CornerRadius = UDim.new(0, 12)
    tbcorner.Parent = tb
    
    local tbbottom = Instance.new("Frame")
    tbbottom.Size = UDim2.new(1, 0, 0, 15)
    tbbottom.Position = UDim2.new(0, 0, 1, -15)
    tbbottom.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    tbbottom.BorderSizePixel = 0
    tbbottom.Parent = tb
    
    local titlelabel = Instance.new("TextLabel")
    titlelabel.Size = UDim2.new(0, 200, 1, 0)
    titlelabel.Position = UDim2.new(0, 15, 0, 0)
    titlelabel.BackgroundTransparency = 1
    titlelabel.Font = Enum.Font.GothamBold
    titlelabel.TextSize = 14
    titlelabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    titlelabel.Text = "⌘ FluentCLI"
    titlelabel.TextXAlignment = Enum.TextXAlignment.Left
    titlelabel.Parent = tb
    
    local sb = Instance.new("TextLabel")
    sb.Name = "StatusBar"
    sb.Size = UDim2.new(1, -30, 0, 20)
    sb.Position = UDim2.new(0, 15, 0, 8)
    sb.BackgroundTransparency = 1
    sb.Font = Enum.Font.Gotham
    sb.TextSize = 11
    sb.TextColor3 = Color3.fromRGB(120, 120, 140)
    sb.Text = "  Commands: 0 | History: 0"
    sb.TextXAlignment = Enum.TextXAlignment.Right
    sb.Parent = tb
    
    local ci = Instance.new("TextBox")
    ci.Name = "CommandInput"
    ci.Size = UDim2.new(1, -30, 0, 30)
    ci.Position = UDim2.new(0, 15, 0, 40)
    ci.BackgroundTransparency = 1
    ci.Font = Enum.Font.RobotoMono
    ci.TextSize = 16
    ci.TextColor3 = Color3.fromRGB(255, 255, 255)
    ci.PlaceholderText = "❯ Type command..."
    ci.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
    ci.Text = ""
    ci.TextXAlignment = Enum.TextXAlignment.Left
    ci.ClearTextOnFocus = false
    ci.MultiLine = false
    ci.Parent = mf
    
    local inputglow = Instance.new("Frame")
    inputglow.Size = UDim2.new(1, -30, 0, 2)
    inputglow.Position = UDim2.new(0, 15, 1, -5)
    inputglow.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
    inputglow.BorderSizePixel = 0
    inputglow.BackgroundTransparency = 1
    inputglow.Parent = mf
    
    local glowcorner = Instance.new("UICorner")
    glowcorner.CornerRadius = UDim.new(1, 0)
    glowcorner.Parent = inputglow
    
    ci.Focused:Connect(function()
        tweenservice:Create(inputglow, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            BackgroundTransparency = 0.3
        }):Play()
        tweenservice:Create(uistroke, TweenInfo.new(0.3), {
            Color = Color3.fromRGB(100, 200, 255)
        }):Play()
    end)
    
    ci.FocusLost:Connect(function()
        tweenservice:Create(inputglow, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            BackgroundTransparency = 1
        }):Play()
        tweenservice:Create(uistroke, TweenInfo.new(0.3), {
            Color = Color3.fromRGB(80, 80, 90)
        }):Play()
    end)
    
    ci:GetPropertyChangedSignal("Text"):Connect(function()
        local text = ci.Text
        local cleaned = text:gsub("\t", ""):gsub(" ", ""):gsub("\n", ""):gsub("\r", "")
        if cleaned ~= text then
            local pos = ci.CursorPosition
            ci.Text = cleaned
            ci.CursorPosition = math.max(pos - 1, 1)
        end
    end)
    
    local acf = Instance.new("Frame")
    acf.Name = "AutocompleteFrame"
    acf.Size = UDim2.new(1, 0, 0, 0)
    acf.Position = UDim2.new(0, 0, 1, 8)
    acf.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    acf.BorderSizePixel = 0
    acf.Visible = false
    acf.Parent = mf
    
    local acc = Instance.new("UICorner")
    acc.CornerRadius = UDim.new(0, 10)
    acc.Parent = acf
    
    local acs = Instance.new("UIStroke")
    acs.Color = Color3.fromRGB(80, 80, 90)
    acs.Thickness = 2
    acs.Transparency = 0.5
    acs.Parent = acf
    
    local acscroll = Instance.new("ScrollingFrame")
    acscroll.Name = "AutocompleteScroll"
    acscroll.Size = UDim2.new(1, -10, 1, -10)
    acscroll.Position = UDim2.new(0, 5, 0, 5)
    acscroll.BackgroundTransparency = 1
    acscroll.BorderSizePixel = 0
    acscroll.ScrollBarThickness = 5
    acscroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    acscroll.Parent = acf
    
    return sg, mf, ci, acf, acscroll, cf, cscroll, tb, sb
end

function library:init()
    screengui, mainframe, commandinput, autocompleteframe, autocompletescroll, consoleframe, consolescroll, titlebar, statusbar = create_gui()
    screengui.Parent = coregui
    
    self.commands.help = {
        desc = "Show all commands",
        args = {},
        func = function()
            return "help"
        end
    }
    
    self.commands.clear = {
        desc = "Clear console output",
        args = {},
        func = function()
            return "clear"
        end
    }
    
    self.commands.cmds = {
        desc = "List all commands",
        args = {},
        func = function()
            return "list"
        end
    }
    
    userinputservice.InputBegan:Connect(function(input, gameprocessed)
        if not self.is_open then return end
        
        if input.KeyCode == Enum.KeyCode.Insert then
            toggle_cli()
        elseif input.KeyCode == Enum.KeyCode.Escape then
            toggle_cli()
        elseif input.KeyCode == Enum.KeyCode.Return then
            local cmd = commandinput.Text:gsub("\n", ""):gsub("\r", "")
            commandinput.Text = ""
            if cmd ~= "" then
                execute_command(cmd)
            end
        elseif input.KeyCode == Enum.KeyCode.Up then
            if #self.command_history > 0 then
                self.history_index = math.min(self.history_index + 1, #self.command_history)
                commandinput.Text = self.command_history[#self.command_history - self.history_index + 1]
                commandinput.CursorPosition = #commandinput.Text + 1
            end
        elseif input.KeyCode == Enum.KeyCode.Down then
            if self.history_index > 0 then
                self.history_index = math.max(self.history_index - 1, 0)
                if self.history_index == 0 then
                    commandinput.Text = ""
                else
                    commandinput.Text = self.command_history[#self.command_history - self.history_index + 1]
                    commandinput.CursorPosition = #commandinput.Text + 1
                end
            end
        elseif input.KeyCode == Enum.KeyCode.Tab then
            if #self.autocomplete_options > 0 and autocompleteframe.Visible then
                self.selected_index = (self.selected_index % #self.autocomplete_options) + 1
                local words = commandinput.Text:split(" ")
                words[#words] = self.autocomplete_options[self.selected_index].text
                commandinput.Text = table.concat(words, " ") .. " "
                commandinput.CursorPosition = #commandinput.Text + 1
                task.wait()
                update_autocomplete(commandinput.Text)
            end
        end
    end)
    
    userinputservice.InputBegan:Connect(function(input, gameprocessed)
        if input.KeyCode == Enum.KeyCode.Insert and not self.is_open then
            toggle_cli()
        end
    end)
    
    commandinput.Focused:Connect(function()
        if not self.is_open then
            commandinput:ReleaseFocus()
        end
    end)
    
    commandinput:GetPropertyChangedSignal("Text"):Connect(function()
        if not commandinput:IsFocused() and self.is_open then
            commandinput:CaptureFocus()
        end
        
        if commandinput.Text ~= "" then
            update_autocomplete(commandinput.Text)
        else
            autocompleteframe.Visible = false
        end
        
        self.selected_index = 0
    end)
    
    task.spawn(function()
        while task.wait(5) do
            if self.is_open then
                update_status()
            end
        end
    end)
    
    add_console_output("✓ FluentCLI initialized successfully!", Color3.fromRGB(100, 255, 100))
    add_console_output("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", Color3.fromRGB(80, 80, 90))
    add_console_output("Press INSERT to open | ESC to close", Color3.fromRGB(200, 200, 200))
    add_console_output("Use UP/DOWN arrows for command history", Color3.fromRGB(200, 200, 200))
    add_console_output("Type 'help' for available commands", Color3.fromRGB(200, 200, 200))
    add_console_output("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", Color3.fromRGB(80, 80, 90))
    update_console()
    
    notify("FluentCLI loaded successfully", Color3.fromRGB(100, 255, 100))
end

function library:add_command(name, desc, args, func)
    self.commands[name] = {
        desc = desc,
        args = args,
        func = func
    }
end

return library
