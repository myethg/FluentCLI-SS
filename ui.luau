--[[
    FluentCLI - VSCode-Inspired Command Palette
    Press INSERT to toggle
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Theme (VSCode Dark+)
local Theme = {
    Background = Color3.fromRGB(30, 30, 30),
    BackgroundLight = Color3.fromRGB(37, 37, 38),
    BackgroundLighter = Color3.fromRGB(45, 45, 46),
    BackgroundHover = Color3.fromRGB(55, 55, 56),
    Border = Color3.fromRGB(60, 60, 60),
    BorderFocus = Color3.fromRGB(0, 122, 204),
    Text = Color3.fromRGB(212, 212, 212),
    TextDim = Color3.fromRGB(128, 128, 128),
    TextMuted = Color3.fromRGB(90, 90, 90),
    Accent = Color3.fromRGB(0, 122, 204),
    AccentLight = Color3.fromRGB(47, 150, 218),
    Success = Color3.fromRGB(78, 201, 176),
    Error = Color3.fromRGB(244, 71, 71),
    Warning = Color3.fromRGB(220, 185, 80),
    Command = Color3.fromRGB(86, 156, 214),
    Player = Color3.fromRGB(156, 220, 254),
    Target = Color3.fromRGB(206, 145, 120),
    String = Color3.fromRGB(206, 145, 120),
}

local Library = {
    Commands = {},
    ConsoleLog = {},
    CommandHistory = {},
    HistoryIndex = 0,
    IsOpen = false,
    SelectedSuggestion = 1,
    Suggestions = {},
}

local ScreenGui, MainFrame, InputBox, SuggestionsFrame, ConsoleFrame, StatusBar

-- Utility
local function Tween(obj, time, props, style, dir)
    local tween = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    tween:Play()
    return tween
end

local function CreateShadow(parent, size, transparency)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6014261993"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = transparency or 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.Size = UDim2.new(1, size or 50, 1, size or 50)
    shadow.Position = UDim2.new(0, -(size or 50)/2, 0, -(size or 50)/2)
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Parent = parent
    return shadow
end

-- Notifications
local function Notify(message, color, duration)
    color = color or Theme.Accent
    duration = duration or 3
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "FluentNotify"
    gui.ResetOnSpawn = false
    gui.Parent = CoreGui
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 360, 0, 0)
    container.Position = UDim2.new(1, -380, 1, -20)
    container.AnchorPoint = Vector2.new(0, 1)
    container.BackgroundColor3 = Theme.BackgroundLight
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    container.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container
    
    CreateShadow(container, 40, 0.6)
    
    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 1, 0)
    accent.BackgroundColor3 = color
    accent.BorderSizePixel = 0
    accent.Parent = container
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 40, 1, 0)
    icon.Position = UDim2.new(0, 3, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 18
    icon.TextColor3 = color
    icon.Text = color == Theme.Error and "✕" or color == Theme.Warning and "⚠" or "✓"
    icon.Parent = container
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -55, 1, 0)
    text.Position = UDim2.new(0, 45, 0, 0)
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.GothamMedium
    text.TextSize = 13
    text.TextColor3 = Theme.Text
    text.Text = message
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextWrapped = true
    text.Parent = container
    
    -- Animate in
    Tween(container, 0.4, {Size = UDim2.new(0, 360, 0, 50)}, Enum.EasingStyle.Back)
    
    task.delay(duration, function()
        Tween(container, 0.25, {Size = UDim2.new(0, 360, 0, 0)})
        task.wait(0.25)
        gui:Destroy()
    end)
end

-- Console Logging
local function AddLog(text, color)
    table.insert(Library.ConsoleLog, {
        Text = text,
        Color = color or Theme.Text,
        Time = os.date("%H:%M:%S")
    })
    if #Library.ConsoleLog > 150 then
        table.remove(Library.ConsoleLog, 1)
    end
end

-- Player Parsing
local function GetPlayers(target)
    local results = {}
    target = target:lower()
    
    if target == "me" or target == "." then
        return {LocalPlayer}
    elseif target == "all" or target == "*" then
        return Players:GetPlayers()
    elseif target == "others" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then table.insert(results, p) end
        end
        return results
    elseif target == "random" or target == "?" then
        local all = Players:GetPlayers()
        return #all > 0 and {all[math.random(1, #all)]} or {}
    end
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #target) == target or p.DisplayName:lower():sub(1, #target) == target then
            table.insert(results, p)
        end
    end
    return results
end

-- Console Render
local function RenderConsole()
    if not ConsoleFrame then return end
    local scroll = ConsoleFrame:FindFirstChild("Scroll")
    if not scroll then return end
    
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    for i, entry in ipairs(Library.ConsoleLog) do
        local line = Instance.new("Frame")
        line.Size = UDim2.new(1, 0, 0, 20)
        line.BackgroundColor3 = i % 2 == 0 and Theme.BackgroundLighter or Theme.BackgroundLight
        line.BackgroundTransparency = 0.5
        line.BorderSizePixel = 0
        line.LayoutOrder = i
        line.Parent = scroll
        
        local time = Instance.new("TextLabel")
        time.Size = UDim2.new(0, 65, 1, 0)
        time.Position = UDim2.new(0, 10, 0, 0)
        time.BackgroundTransparency = 1
        time.Font = Enum.Font.RobotoMono
        time.TextSize = 11
        time.TextColor3 = Theme.TextMuted
        time.Text = entry.Time
        time.TextXAlignment = Enum.TextXAlignment.Left
        time.Parent = line
        
        local msg = Instance.new("TextLabel")
        msg.Size = UDim2.new(1, -85, 1, 0)
        msg.Position = UDim2.new(0, 75, 0, 0)
        msg.BackgroundTransparency = 1
        msg.Font = Enum.Font.RobotoMono
        msg.TextSize = 12
        msg.TextColor3 = entry.Color
        msg.Text = entry.Text
        msg.TextXAlignment = Enum.TextXAlignment.Left
        msg.TextTruncate = Enum.TextTruncate.AtEnd
        msg.Parent = line
    end
    
    local layout = scroll:FindFirstChild("Layout")
    if layout then
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
        scroll.CanvasPosition = Vector2.new(0, math.max(0, scroll.CanvasSize.Y.Offset - scroll.AbsoluteSize.Y))
    end
end

-- Suggestions
local function GetSuggestions(text)
    local suggestions = {}
    local words = text:split(" ")
    local current = (words[#words] or ""):lower()
    local cmdName = words[1] and words[1]:lower() or ""
    
    if #words <= 1 then
        -- Command suggestions
        for name, cmd in pairs(Library.Commands) do
            if current == "" or name:sub(1, #current) == current then
                table.insert(suggestions, {
                    Text = name,
                    Desc = cmd.Desc,
                    Type = "command",
                    Icon = "⌘"
                })
            end
        end
        table.sort(suggestions, function(a, b) return a.Text < b.Text end)
    else
        -- Argument suggestions
        local cmd = Library.Commands[cmdName]
        if cmd and cmd.Args then
            local argIndex = #words - 1
            local argType = cmd.Args[argIndex]
            
            if argType == "player" then
                local targets = {"me", "all", "others", "random"}
                for _, t in ipairs(targets) do
                    if current == "" or t:sub(1, #current) == current then
                        table.insert(suggestions, {Text = t, Desc = "Target selector", Type = "target", Icon = "◎"})
                    end
                end
                for _, p in ipairs(Players:GetPlayers()) do
                    if current == "" or p.Name:lower():sub(1, #current) == current then
                        table.insert(suggestions, {
                            Text = p.Name,
                            Desc = p.DisplayName,
                            Type = "player",
                            Icon = "👤"
                        })
                    end
                end
            end
        end
    end
    
    return suggestions
end

local function RenderSuggestions()
    if not SuggestionsFrame then return end
    local container = SuggestionsFrame:FindFirstChild("Container")
    if not container then return end
    
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    local suggestions = Library.Suggestions
    
    if #suggestions == 0 then
        Tween(SuggestionsFrame, 0.15, {Size = UDim2.new(1, 0, 0, 0)})
        return
    end
    
    -- Clamp selected
    Library.SelectedSuggestion = math.clamp(Library.SelectedSuggestion, 1, #suggestions)
    
    for i, sug in ipairs(suggestions) do
        if i > 8 then break end -- Limit visible suggestions
        
        local isSelected = i == Library.SelectedSuggestion
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -8, 0, 32)
        btn.Position = UDim2.new(0, 4, 0, 0)
        btn.BackgroundColor3 = isSelected and Theme.BackgroundHover or Theme.BackgroundLight
        btn.BackgroundTransparency = isSelected and 0 or 1
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.LayoutOrder = i
        btn.Parent = container
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = btn
        
        -- Icon
        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 30, 1, 0)
        icon.Position = UDim2.new(0, 8, 0, 0)
        icon.BackgroundTransparency = 1
        icon.Font = Enum.Font.GothamBold
        icon.TextSize = 14
        icon.TextColor3 = sug.Type == "command" and Theme.Command or sug.Type == "player" and Theme.Player or Theme.Target
        icon.Text = sug.Icon or "•"
        icon.Parent = btn
        
        -- Name
        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(0.5, -40, 1, 0)
        name.Position = UDim2.new(0, 38, 0, 0)
        name.BackgroundTransparency = 1
        name.Font = Enum.Font.GothamMedium
        name.TextSize = 13
        name.TextColor3 = Theme.Text
        name.Text = sug.Text
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Parent = btn
        
        -- Description
        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(0.45, -10, 1, 0)
        desc.Position = UDim2.new(0.55, 0, 0, 0)
        desc.BackgroundTransparency = 1
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 11
        desc.TextColor3 = Theme.TextDim
        desc.Text = sug.Desc
        desc.TextXAlignment = Enum.TextXAlignment.Right
        desc.TextTruncate = Enum.TextTruncate.AtEnd
        desc.Parent = btn
        
        -- Selection indicator
        if isSelected then
            local indicator = Instance.new("Frame")
            indicator.Size = UDim2.new(0, 2, 0.6, 0)
            indicator.Position = UDim2.new(0, 2, 0.2, 0)
            indicator.BackgroundColor3 = Theme.Accent
            indicator.BorderSizePixel = 0
            indicator.Parent = btn
            
            local indCorner = Instance.new("UICorner")
            indCorner.CornerRadius = UDim.new(1, 0)
            indCorner.Parent = indicator
        end
        
        -- Hover effects
        btn.MouseEnter:Connect(function()
            if not (i == Library.SelectedSuggestion) then
                Tween(btn, 0.1, {BackgroundTransparency = 0.5})
            end
        end)
        
        btn.MouseLeave:Connect(function()
            if not (i == Library.SelectedSuggestion) then
                Tween(btn, 0.1, {BackgroundTransparency = 1})
            end
        end)
        
        btn.MouseButton1Click:Connect(function()
            local words = InputBox.Text:split(" ")
            words[#words] = sug.Text
            InputBox.Text = table.concat(words, " ") .. " "
            InputBox.CursorPosition = #InputBox.Text + 1
            InputBox:CaptureFocus()
            Library.Suggestions = GetSuggestions(InputBox.Text)
            Library.SelectedSuggestion = 1
            RenderSuggestions()
        end)
    end
    
    local layout = container:FindFirstChild("Layout")
    local height = math.min(280, (layout and layout.AbsoluteContentSize.Y or 0) + 8)
    Tween(SuggestionsFrame, 0.15, {Size = UDim2.new(1, 0, 0, height)})
end

local function UpdateSuggestions(text)
    Library.Suggestions = GetSuggestions(text)
    Library.SelectedSuggestion = 1
    RenderSuggestions()
end

-- Command Execution
local function Execute(text)
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return end
    
    AddLog("› " .. text, Theme.AccentLight)
    table.insert(Library.CommandHistory, text)
    Library.HistoryIndex = 0
    
    local words = text:split(" ")
    local cmdName = words[1]:lower()
    local cmd = Library.Commands[cmdName]
    
    if not cmd then
        AddLog("  Unknown command: " .. cmdName, Theme.Error)
        Notify("Unknown command", Theme.Error)
        RenderConsole()
        return
    end
    
    -- Built-ins
    if cmdName == "help" or cmdName == "cmds" or cmdName == "commands" then
        AddLog("─────────────────────────────", Theme.Border)
        local sorted = {}
        for name, c in pairs(Library.Commands) do
            if name ~= "help" and name ~= "cmds" and name ~= "clear" and name ~= "commands" then
                table.insert(sorted, {name = name, cmd = c})
            end
        end
        table.sort(sorted, function(a, b) return a.name < b.name end)
        for _, item in ipairs(sorted) do
            local args = item.cmd.Args and #item.cmd.Args > 0 and " <" .. table.concat(item.cmd.Args, "> <") .. ">" or ""
            AddLog("  " .. item.name .. args, Theme.Command)
            AddLog("    " .. item.cmd.Desc, Theme.TextDim)
        end
        AddLog("─────────────────────────────", Theme.Border)
        RenderConsole()
        return
    elseif cmdName == "clear" or cmdName == "cls" then
        Library.ConsoleLog = {}
        RenderConsole()
        return
    end
    
    -- Execute
    local success, result = pcall(function()
        if cmd.Args and cmd.Args[1] == "player" then
            if #words < 2 then return false, "Missing player target" end
            local targets = GetPlayers(words[2])
            if #targets == 0 then return false, "No players found: " .. words[2] end
            
            if cmd.Args[2] == "text" then
                table.remove(words, 1)
                table.remove(words, 1)
                return true, cmd.Func(targets, table.concat(words, " "))
            else
                return true, cmd.Func(targets)
            end
        elseif cmd.Args and cmd.Args[1] == "text" then
            table.remove(words, 1)
            return true, cmd.Func(table.concat(words, " "))
        elseif cmd.Args and cmd.Args[1] == "number" then
            local num = tonumber(words[2])
            if not num then return false, "Invalid number" end
            return true, cmd.Func(num)
        else
            return true, cmd.Func()
        end
    end)
    
    if success and result then
        if type(result) == "table" then
            local msg = result[2] or (result[1] and "Success" or "Failed")
            local col = result[1] and Theme.Success or Theme.Error
            AddLog("  " .. msg, col)
            Notify(msg, col)
        elseif type(result) == "string" then
            AddLog("  " .. result, Theme.Success)
            Notify(result, Theme.Success)
        end
    elseif not success then
        AddLog("  Error: " .. tostring(result), Theme.Error)
        Notify("Error occurred", Theme.Error)
    end
    
    RenderConsole()
end

-- Toggle
local function Toggle()
    Library.IsOpen = not Library.IsOpen
    
    if Library.IsOpen then
        MainFrame.Visible = true
        ConsoleFrame.Visible = true
        
        Tween(MainFrame, 0.35, {
            Position = UDim2.new(0.5, 0, 0.15, 0),
            GroupTransparency = 0
        }, Enum.EasingStyle.Back)
        
        Tween(ConsoleFrame, 0.35, {
            Position = UDim2.new(0.5, 0, 0.15, 68),
            GroupTransparency = 0
        }, Enum.EasingStyle.Back)
        
        task.delay(0.15, function()
            if Library.IsOpen then
                InputBox:CaptureFocus()
            end
        end)
        
        -- Update status
        local count = 0
        for _ in pairs(Library.Commands) do count = count + 1 end
        StatusBar.Text = string.format("%d commands • %d players • INSERT to close", count, #Players:GetPlayers())
    else
        SuggestionsFrame.Visible = false
        InputBox:ReleaseFocus()
        
        Tween(MainFrame, 0.2, {
            Position = UDim2.new(0.5, 0, 0, -100),
            GroupTransparency = 1
        })
        
        Tween(ConsoleFrame, 0.2, {
            Position = UDim2.new(0.5, 0, 0, -400),
            GroupTransparency = 1
        })
        
        task.delay(0.2, function()
            if not Library.IsOpen then
                MainFrame.Visible = false
                ConsoleFrame.Visible = false
            end
        end)
    end
end

-- Create GUI
local function CreateGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "FluentCLI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999
    
    -- Console Frame
    local console = Instance.new("CanvasGroup")
    console.Name = "Console"
    console.Size = UDim2.new(0, 600, 0, 280)
    console.Position = UDim2.new(0.5, 0, 0, -400)
    console.AnchorPoint = Vector2.new(0.5, 0)
    console.BackgroundColor3 = Theme.Background
    console.BorderSizePixel = 0
    console.GroupTransparency = 1
    console.Visible = false
    console.Parent = gui
    
    local consoleCorner = Instance.new("UICorner")
    consoleCorner.CornerRadius = UDim.new(0, 8)
    consoleCorner.Parent = console
    
    local consoleStroke = Instance.new("UIStroke")
    consoleStroke.Color = Theme.Border
    consoleStroke.Thickness = 1
    consoleStroke.Parent = console
    
    CreateShadow(console, 60, 0.7)
    
    -- Console header
    local consoleHeader = Instance.new("Frame")
    consoleHeader.Size = UDim2.new(1, 0, 0, 32)
    consoleHeader.BackgroundColor3 = Theme.BackgroundLight
    consoleHeader.BorderSizePixel = 0
    consoleHeader.Parent = console
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 8)
    headerCorner.Parent = consoleHeader
    
    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0, 10)
    headerFix.Position = UDim2.new(0, 0, 1, -10)
    headerFix.BackgroundColor3 = Theme.BackgroundLight
    headerFix.BorderSizePixel = 0
    headerFix.Parent = consoleHeader
    
    local consoleTitle = Instance.new("TextLabel")
    consoleTitle.Size = UDim2.new(1, -20, 1, 0)
    consoleTitle.Position = UDim2.new(0, 15, 0, 0)
    consoleTitle.BackgroundTransparency = 1
    consoleTitle.Font = Enum.Font.GothamMedium
    consoleTitle.TextSize = 12
    consoleTitle.TextColor3 = Theme.TextDim
    consoleTitle.Text = "OUTPUT"
    consoleTitle.TextXAlignment = Enum.TextXAlignment.Left
    consoleTitle.Parent = consoleHeader
    
    local consoleScroll = Instance.new("ScrollingFrame")
    consoleScroll.Name = "Scroll"
    consoleScroll.Size = UDim2.new(1, -12, 1, -44)
    consoleScroll.Position = UDim2.new(0, 6, 0, 38)
    consoleScroll.BackgroundTransparency = 1
    consoleScroll.BorderSizePixel = 0
    consoleScroll.ScrollBarThickness = 6
    consoleScroll.ScrollBarImageColor3 = Theme.Border
    consoleScroll.ScrollBarImageTransparency = 0.3
    consoleScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    consoleScroll.Parent = console
    
    local scrollLayout = Instance.new("UIListLayout")
    scrollLayout.Name = "Layout"
    scrollLayout.Padding = UDim.new(0, 1)
    scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
    scrollLayout.Parent = consoleScroll
    
    -- Main Frame (Command Palette)
    local main = Instance.new("CanvasGroup")
    main.Name = "Main"
    main.Size = UDim2.new(0, 600, 0, 60)
    main.Position = UDim2.new(0.5, 0, 0, -100)
    main.AnchorPoint = Vector2.new(0.5, 0)
    main.BackgroundColor3 = Theme.Background
    main.BorderSizePixel = 0
    main.GroupTransparency = 1
    main.Visible = false
    main.Parent = gui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = main
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Name = "Stroke"
    mainStroke.Color = Theme.Border
    mainStroke.Thickness = 1
    mainStroke.Parent = main
    
    CreateShadow(main, 60, 0.7)
    
    -- Search icon
    local searchIcon = Instance.new("TextLabel")
    searchIcon.Size = UDim2.new(0, 40, 0, 60)
    searchIcon.Position = UDim2.new(0, 8, 0, 0)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Font = Enum.Font.GothamBold
    searchIcon.TextSize = 18
    searchIcon.TextColor3 = Theme.Accent
    searchIcon.Text = "❯"
    searchIcon.Parent = main
    
    -- Input
    local input = Instance.new("TextBox")
    input.Name = "Input"
    input.Size = UDim2.new(1, -60, 0, 60)
    input.Position = UDim2.new(0, 48, 0, 0)
    input.BackgroundTransparency = 1
    input.Font = Enum.Font.GothamMedium
    input.TextSize = 15
    input.TextColor3 = Theme.Text
    input.PlaceholderText = "Type a command or search..."
    input.PlaceholderColor3 = Theme.TextDim
    input.Text = ""
    input.TextXAlignment = Enum.TextXAlignment.Left
    input.ClearTextOnFocus = false
    input.Parent = main
    
    -- Suggestions dropdown
    local suggestions = Instance.new("Frame")
    suggestions.Name = "Suggestions"
    suggestions.Size = UDim2.new(1, 0, 0, 0)
    suggestions.Position = UDim2.new(0, 0, 1, 4)
    suggestions.BackgroundColor3 = Theme.Background
    suggestions.BorderSizePixel = 0
    suggestions.ClipsDescendants = true
    suggestions.Visible = false
    suggestions.Parent = main
    
    local sugCorner = Instance.new("UICorner")
    sugCorner.CornerRadius = UDim.new(0, 8)
    sugCorner.Parent = suggestions
    
    local sugStroke = Instance.new("UIStroke")
    sugStroke.Color = Theme.Border
    sugStroke.Thickness = 1
    sugStroke.Parent = suggestions
    
    CreateShadow(suggestions, 40, 0.6)
    
    local sugContainer = Instance.new("Frame")
    sugContainer.Name = "Container"
    sugContainer.Size = UDim2.new(1, 0, 1, -4)
    sugContainer.Position = UDim2.new(0, 0, 0, 4)
    sugContainer.BackgroundTransparency = 1
    sugContainer.Parent = suggestions
    
    local sugLayout = Instance.new("UIListLayout")
    sugLayout.Name = "Layout"
    sugLayout.Padding = UDim.new(0, 2)
    sugLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sugLayout.Parent = sugContainer
    
    -- Status bar
    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, -20, 0, 20)
    status.Position = UDim2.new(0, 10, 1, -22)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.Gotham
    status.TextSize = 10
    status.TextColor3 = Theme.TextMuted
    status.Text = "0 commands • 0 players • INSERT to close"
    status.TextXAlignment = Enum.TextXAlignment.Right
    status.Parent = console
    
    -- Input effects
    input.Focused:Connect(function()
        Tween(mainStroke, 0.2, {Color = Theme.BorderFocus})
        Tween(searchIcon, 0.2, {TextColor3 = Theme.AccentLight})
    end)
    
    input.FocusLost:Connect(function()
        Tween(mainStroke, 0.2, {Color = Theme.Border})
        Tween(searchIcon, 0.2, {TextColor3 = Theme.Accent})
    end)
    
    return gui, main, input, suggestions, console, status
end

-- Initialize
function Library:Init()
    ScreenGui, MainFrame, InputBox, SuggestionsFrame, ConsoleFrame, StatusBar = CreateGUI()
    ScreenGui.Parent = CoreGui
    
    -- Built-in commands
    self.Commands.help = {Desc = "Show all commands", Args = {}, Func = function() end}
    self.Commands.commands = {Desc = "Show all commands", Args = {}, Func = function() end}
    self.Commands.cmds = {Desc = "List commands", Args = {}, Func = function() end}
    self.Commands.clear = {Desc = "Clear console", Args = {}, Func = function() end}
    self.Commands.cls = {Desc = "Clear console", Args = {}, Func = function() end}
    
    -- Input handling
    UserInputService.InputBegan:Connect(function(input, processed)
        if input.KeyCode == Enum.KeyCode.Insert then
            Toggle()
            return
        end
        
        if not self.IsOpen then return end
        
        if input.KeyCode == Enum.KeyCode.Escape then
            Toggle()
        elseif input.KeyCode == Enum.KeyCode.Return and not processed then
            local cmd = InputBox.Text:gsub("[\n\r\t]", "")
            InputBox.Text = ""
            SuggestionsFrame.Visible = false
            Execute(cmd)
            task.wait()
            InputBox:CaptureFocus()
        elseif input.KeyCode == Enum.KeyCode.Up then
            if #self.Suggestions > 0 then
                self.SelectedSuggestion = self.SelectedSuggestion > 1 and self.SelectedSuggestion - 1 or #self.Suggestions
                RenderSuggestions()
            elseif #self.CommandHistory > 0 then
                self.HistoryIndex = math.min(self.HistoryIndex + 1, #self.CommandHistory)
                InputBox.Text = self.CommandHistory[#self.CommandHistory - self.HistoryIndex + 1]
                InputBox.CursorPosition = #InputBox.Text + 1
            end
        elseif input.KeyCode == Enum.KeyCode.Down then
            if #self.Suggestions > 0 then
                self.SelectedSuggestion = self.SelectedSuggestion < #self.Suggestions and self.SelectedSuggestion + 1 or 1
                RenderSuggestions()
            elseif self.HistoryIndex > 0 then
                self.HistoryIndex = self.HistoryIndex - 1
                InputBox.Text = self.HistoryIndex == 0 and "" or self.CommandHistory[#self.CommandHistory - self.HistoryIndex + 1]
            end
        elseif input.KeyCode == Enum.KeyCode.Tab then
            if #self.Suggestions > 0 and self.SelectedSuggestion > 0 then
                local words = InputBox.Text:split(" ")
                words[#words] = self.Suggestions[self.SelectedSuggestion].Text
                InputBox.Text = table.concat(words, " ") .. " "
                InputBox.CursorPosition = #InputBox.Text + 1
                self.Suggestions = GetSuggestions(InputBox.Text)
                self.SelectedSuggestion = 1
                task.wait()
                RenderSuggestions()
            end
        end
    end)
    
    -- Text change handler
    InputBox:GetPropertyChangedSignal("Text"):Connect(function()
        local text = InputBox.Text
        local cleaned = text:gsub("[\t\n\r]", "")
        if cleaned ~= text then
            InputBox.Text = cleaned
            return
        end
        
        if text ~= "" then
            SuggestionsFrame.Visible = true
            UpdateSuggestions(text)
        else
            SuggestionsFrame.Visible = false
            Tween(SuggestionsFrame, 0.15, {Size = UDim2.new(1, 0, 0, 0)})
        end
    end)
    
    -- Auto-focus
    task.spawn(function()
        while true do
            task.wait(0.3)
            if self.IsOpen and not InputBox:IsFocused() then
                InputBox:CaptureFocus()
            end
        end
    end)
    
    -- Welcome
    AddLog("FluentCLI v2.0 loaded!", Theme.Success)
    AddLog("─────────────────────────────", Theme.Border)
    AddLog("Press INSERT to toggle", Theme.TextDim)
    AddLog("Type 'help' for commands", Theme.TextDim)
    AddLog("Use ↑↓ to navigate, TAB to complete", Theme.TextDim)
    AddLog("─────────────────────────────", Theme.Border)
    RenderConsole()
    
    Notify("FluentCLI loaded!", Theme.Success)
end

function Library:AddCommand(name, desc, args, func)
    self.Commands[name:lower()] = {
        Desc = desc,
        Args = args or {},
        Func = func
    }
end

-- Aliases
Library.add_command = Library.AddCommand
Library.init = Library.Init

return Library
