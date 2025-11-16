local players = game:GetService("Players")
local userinputservice = game:GetService("UserInputService")
local tweenservice = game:GetService("TweenService")
local coregui = game:GetService("CoreGui")

local player = players.LocalPlayer

local library = {}
library.commands = {}
library.console_output = {}
library.is_open = false
library.selected_index = 0
library.autocomplete_options = {}

local screengui, mainframe, commandinput, autocompleteframe, autocompletescroll, consoleframe, consolescroll

local function notify(message, color)
    color = color or Color3.fromRGB(100, 200, 255)
    
    local notifgui = Instance.new("ScreenGui")
    notifgui.Name = "Notification"
    notifgui.ResetOnSpawn = false
    notifgui.Parent = coregui
    
    local notifframe = Instance.new("Frame")
    notifframe.Size = UDim2.new(0, 300, 0, 50)
    notifframe.Position = UDim2.new(1, -320, 0, 20)
    notifframe.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    notifframe.BorderSizePixel = 0
    notifframe.Parent = notifgui
    
    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0, 8)
    uicorner.Parent = notifframe
    
    local uistroke = Instance.new("UIStroke")
    uistroke.Color = color
    uistroke.Thickness = 2
    uistroke.Parent = notifframe
    
    local notiftext = Instance.new("TextLabel")
    notiftext.Size = UDim2.new(1, -20, 1, 0)
    notiftext.Position = UDim2.new(0, 10, 0, 0)
    notiftext.BackgroundTransparency = 1
    notiftext.Font = Enum.Font.GothamBold
    notiftext.TextSize = 14
    notiftext.TextColor3 = Color3.fromRGB(255, 255, 255)
    notiftext.Text = message
    notiftext.TextXAlignment = Enum.TextXAlignment.Left
    notiftext.Parent = notifframe
    
    notifframe.Position = UDim2.new(1, 0, 0, 20)
    tweenservice:Create(notifframe, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = UDim2.new(1, -320, 0, 20)
    }):Play()
    
    task.wait(3)
    tweenservice:Create(notifframe, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Position = UDim2.new(1, 0, 0, 20)
    }):Play()
    task.wait(0.3)
    notifgui:Destroy()
end

local function add_console_output(text, color)
    table.insert(library.console_output, {text = text, color = color or Color3.fromRGB(200, 200, 200)})
    if #library.console_output > 50 then
        table.remove(library.console_output, 1)
    end
end

local function update_console()
    consolescroll:ClearAllChildren()
    
    local consolelist = Instance.new("UIListLayout")
    consolelist.Padding = UDim.new(0, 2)
    consolelist.Parent = consolescroll
    
    for _, entry in ipairs(library.console_output) do
        local textlabel = Instance.new("TextLabel")
        textlabel.Size = UDim2.new(1, -10, 0, 20)
        textlabel.BackgroundTransparency = 1
        textlabel.Font = Enum.Font.RobotoMono
        textlabel.TextSize = 14
        textlabel.TextColor3 = entry.color
        textlabel.Text = entry.text
        textlabel.TextXAlignment = Enum.TextXAlignment.Left
        textlabel.TextYAlignment = Enum.TextYAlignment.Top
        textlabel.TextWrapped = true
        textlabel.Parent = consolescroll
        
        textlabel.Size = UDim2.new(1, -10, 0, textlabel.TextBounds.Y)
    end
    
    consolescroll.CanvasSize = UDim2.new(0, 0, 0, consolelist.AbsoluteContentSize.Y)
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
        autocompleteframe.Visible = false
        return
    end
    
    local listlayout = Instance.new("UIListLayout")
    listlayout.Padding = UDim.new(0, 2)
    listlayout.Parent = autocompletescroll
    
    for i, suggestion in ipairs(suggestions) do
        local suggestionbutton = Instance.new("TextButton")
        suggestionbutton.Size = UDim2.new(1, -10, 0, 25)
        suggestionbutton.BackgroundColor3 = i == library.selected_index and Color3.fromRGB(40, 40, 50) or Color3.fromRGB(25, 25, 30)
        suggestionbutton.BorderSizePixel = 0
        suggestionbutton.Font = Enum.Font.RobotoMono
        suggestionbutton.TextSize = 14
        suggestionbutton.TextColor3 = Color3.fromRGB(255, 255, 255)
        suggestionbutton.TextXAlignment = Enum.TextXAlignment.Left
        suggestionbutton.Text = "  " .. suggestion.text .. " - " .. suggestion.desc
        suggestionbutton.Parent = autocompletescroll
        
        local typecolor = suggestion.type == "command" and Color3.fromRGB(100, 200, 255) or 
                          suggestion.type == "player" and Color3.fromRGB(100, 255, 100) or
                          Color3.fromRGB(255, 200, 100)
        
        local typeindicator = Instance.new("Frame")
        typeindicator.Size = UDim2.new(0, 3, 1, 0)
        typeindicator.Position = UDim2.new(0, 0, 0, 0)
        typeindicator.BackgroundColor3 = typecolor
        typeindicator.BorderSizePixel = 0
        typeindicator.Parent = suggestionbutton
        
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
    
    local max_height = math.min(150, listlayout.AbsoluteContentSize.Y + 10)
    autocompleteframe.Size = UDim2.new(1, 0, 0, max_height)
    autocompleteframe.Visible = true
end

local function execute_command(text)
    add_console_output("❯ " .. text, Color3.fromRGB(100, 200, 255))
    
    local words = text:split(" ")
    local cmdname = words[1]
    local cmd = library.commands[cmdname]
    
    if not cmd then
        add_console_output("Unknown command: " .. cmdname, Color3.fromRGB(255, 100, 100))
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
            add_console_output("Missing player target", Color3.fromRGB(255, 100, 100))
            update_console()
            return
        end
        
        local target = words[2]
        local targets = get_players(target)
        
        if #targets == 0 then
            add_console_output("No players found matching: " .. target, Color3.fromRGB(255, 100, 100))
            notify("No players found", Color3.fromRGB(255, 100, 100))
            update_console()
            return
        end
        
        if #cmd.args == 2 and cmd.args[2] == "text" then
            if #words < 3 then
                add_console_output("Missing argument", Color3.fromRGB(255, 100, 100))
                update_console()
                return
            end
            
            table.remove(words, 1)
            table.remove(words, 1)
            local arg = table.concat(words, " ")
            local result = cmd.func(targets, arg)
            add_console_output(result, Color3.fromRGB(100, 255, 100))
            notify(result, Color3.fromRGB(100, 255, 100))
        else
            local result = cmd.func(targets)
            add_console_output(result, Color3.fromRGB(100, 255, 100))
            notify(result, Color3.fromRGB(100, 255, 100))
        end
    elseif cmd.args and #cmd.args > 0 and cmd.args[1] == "text" then
        if #words < 2 then
            add_console_output("Missing argument", Color3.fromRGB(255, 100, 100))
            update_console()
            return
        end
        
        table.remove(words, 1)
        local arg = table.concat(words, " ")
        local result = cmd.func(arg)
        add_console_output(result, Color3.fromRGB(100, 255, 100))
        notify(result, Color3.fromRGB(100, 255, 100))
    else
        local result = cmd.func()
        add_console_output(result, Color3.fromRGB(100, 255, 100))
        notify(result, Color3.fromRGB(100, 255, 100))
    end
    
    update_console()
end

local function toggle_cli()
    library.is_open = not library.is_open
    
    if library.is_open then
        mainframe.Visible = true
        mainframe:TweenPosition(UDim2.new(0.5, -300, 0, 20), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.3, true)
        consoleframe.Visible = true
        consoleframe:TweenPosition(UDim2.new(0.5, -300, 0, 70), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.3, true)
        commandinput:CaptureFocus()
        task.spawn(function()
            while library.is_open do
                if not commandinput:IsFocused() then
                    commandinput:CaptureFocus()
                end
                task.wait(0.1)
            end
        end)
    else
        mainframe:TweenPosition(UDim2.new(0.5, -300, 0, -50), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.3, true)
        consoleframe:TweenPosition(UDim2.new(0.5, -300, 0, -350), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.3, true)
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
    cf.Size = UDim2.new(0, 600, 0, 300)
    cf.Position = UDim2.new(0.5, -300, 0, -350)
    cf.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    cf.BorderSizePixel = 0
    cf.Visible = false
    cf.Parent = sg
    
    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 8)
    cc.Parent = cf
    
    local cs = Instance.new("UIStroke")
    cs.Color = Color3.fromRGB(60, 60, 70)
    cs.Thickness = 2
    cs.Parent = cf
    
    local cscroll = Instance.new("ScrollingFrame")
    cscroll.Name = "ConsoleScroll"
    cscroll.Size = UDim2.new(1, -20, 1, -20)
    cscroll.Position = UDim2.new(0, 10, 0, 10)
    cscroll.BackgroundTransparency = 1
    cscroll.BorderSizePixel = 0
    cscroll.ScrollBarThickness = 4
    cscroll.Parent = cf
    
    local mf = Instance.new("Frame")
    mf.Name = "MainFrame"
    mf.Size = UDim2.new(0, 600, 0, 40)
    mf.Position = UDim2.new(0.5, -300, 0, -50)
    mf.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    mf.BorderSizePixel = 0
    mf.Visible = false
    mf.Parent = sg
    
    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0, 8)
    uicorner.Parent = mf
    
    local uistroke = Instance.new("UIStroke")
    uistroke.Color = Color3.fromRGB(60, 60, 70)
    uistroke.Thickness = 2
    uistroke.Parent = mf
    
    local ci = Instance.new("TextBox")
    ci.Name = "CommandInput"
    ci.Size = UDim2.new(1, -20, 1, -10)
    ci.Position = UDim2.new(0, 10, 0, 5)
    ci.BackgroundTransparency = 1
    ci.Font = Enum.Font.RobotoMono
    ci.TextSize = 16
    ci.TextColor3 = Color3.fromRGB(255, 255, 255)
    ci.PlaceholderText = "❯ Type command..."
    ci.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
    ci.Text = ""
    ci.TextXAlignment = Enum.TextXAlignment.Left
    ci.ClearTextOnFocus = false
    ci.MultiLine = false
    ci.Parent = mf

    ci:GetPropertyChangedSignal("Text"):Connect(function()
        local text = ci.Text
        local cleaned = text:gsub("\t", ""):gsub("   ", ""):gsub("\n", ""):gsub("\r", "")
        if cleaned ~= text then
            local pos = ci.CursorPosition
            ci.Text = cleaned
            ci.CursorPosition = math.max(pos - 1, 1)
        end
    end)

    local acf = Instance.new("Frame")
    acf.Name = "AutocompleteFrame"
    acf.Size = UDim2.new(1, 0, 0, 0)
    acf.Position = UDim2.new(0, 0, 1, 5)
    acf.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    acf.BorderSizePixel = 0
    acf.Visible = false
    acf.Parent = mf
    
    local acc = Instance.new("UICorner")
    acc.CornerRadius = UDim.new(0, 6)
    acc.Parent = acf
    
    local acs = Instance.new("UIStroke")
    acs.Color = Color3.fromRGB(60, 60, 70)
    acs.Thickness = 1
    acs.Parent = acf
    
    local acscroll = Instance.new("ScrollingFrame")
    acscroll.Name = "AutocompleteScroll"
    acscroll.Size = UDim2.new(1, 0, 1, 0)
    acscroll.BackgroundTransparency = 1
    acscroll.BorderSizePixel = 0
    acscroll.ScrollBarThickness = 4
    acscroll.Parent = acf
    
    return sg, mf, ci, acf, acscroll, cf, cscroll
end

function library:init()
    screengui, mainframe, commandinput, autocompleteframe, autocompletescroll, consoleframe, consolescroll = create_gui()
    screengui.Parent = coregui
    
    self.commands.help = {
        desc = "Show all commands",
        args = {},
        func = function() return "help" end
    }
    
    self.commands.clear = {
        desc = "Clear console output",
        args = {},
        func = function() return "clear" end
    }
    
    self.commands.cmds = {
        desc = "List all commands",
        args = {},
        func = function() return "list" end
    }
    
    userinputservice.InputBegan:Connect(function(input, gameprocessed)
        if input.KeyCode == Enum.KeyCode.Insert then
            toggle_cli()
        elseif input.KeyCode == Enum.KeyCode.Escape and self.is_open then
            toggle_cli()
        elseif input.KeyCode == Enum.KeyCode.Return and self.is_open then
            local cmd = commandinput.Text:gsub("\n", ""):gsub("\r", "")
            commandinput.Text = ""
            if cmd ~= "" then
                execute_command(cmd)
                autocompleteframe.Visible = false
            end
        elseif input.KeyCode == Enum.KeyCode.Tab and self.is_open then
            if #self.autocomplete_options > 0 then
                self.selected_index = (self.selected_index % #self.autocomplete_options) + 1
                local words = commandinput.Text:split(" ")
                words[#words] = self.autocomplete_options[self.selected_index].text
                commandinput.Text = table.concat(words, " ").." "
                update_autocomplete(commandinput.Text)
                commandinput.CursorPosition = #commandinput.Text + 1
            end
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
    
    add_console_output("FluentCLI loaded!", Color3.fromRGB(100, 255, 100))
    add_console_output("Press INSERT to open, ESC to close", Color3.fromRGB(200, 200, 200))
    add_console_output("Type 'help' for commands", Color3.fromRGB(200, 200, 200))
    update_console()
    
    notify("FluentCLI loaded.", Color3.fromRGB(100, 255, 100))
end

function library:add_command(name, desc, args, func)
    self.commands[name] = {
        desc = desc,
        args = args,
        func = func
    }
end

return library
