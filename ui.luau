--[[
    FluentCLI - Clean Command Line Interface
    Press INSERT to toggle
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Library = {
    Commands = {},
    ConsoleLog = {},
    CommandHistory = {},
    HistoryIndex = 0,
    IsOpen = false,
    SelectedSuggestion = 0,
    Suggestions = {},
}

-- GUI References
local ScreenGui, MainFrame, InputBox, AutocompleteFrame, ConsoleFrame, StatusLabel

--// Utility Functions
local function Tween(object, time, properties, style, direction)
    local tween = TweenService:Create(
        object, 
        TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
        properties
    )
    tween:Play()
    return tween
end

local function Notify(message, color)
    color = color or Color3.fromRGB(100, 200, 255)
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "FluentNotification"
    gui.ResetOnSpawn = false
    gui.Parent = CoreGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 320, 0, 50)
    frame.Position = UDim2.new(1, 20, 0, 20)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
    frame.BorderSizePixel = 0
    frame.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 1.5
    stroke.Transparency = 0.5
    stroke.Parent = frame
    
    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 0.6, 0)
    accent.Position = UDim2.new(0, 8, 0.2, 0)
    accent.BackgroundColor3 = color
    accent.BorderSizePixel = 0
    accent.Parent = frame
    
    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(1, 0)
    accentCorner.Parent = accent
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -30, 1, 0)
    text.Position = UDim2.new(0, 20, 0, 0)
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.GothamMedium
    text.TextSize = 14
    text.TextColor3 = Color3.fromRGB(240, 240, 240)
    text.Text = message
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextWrapped = true
    text.Parent = frame
    
    -- Animate in
    Tween(frame, 0.4, {Position = UDim2.new(1, -340, 0, 20)}, Enum.EasingStyle.Back)
    
    task.delay(3, function()
        Tween(frame, 0.3, {Position = UDim2.new(1, 20, 0, 20)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        task.wait(0.3)
        gui:Destroy()
    end)
end

local function AddLog(text, color)
    table.insert(Library.ConsoleLog, {
        Text = text,
        Color = color or Color3.fromRGB(200, 200, 210),
        Time = os.date("%H:%M:%S")
    })
    
    if #Library.ConsoleLog > 100 then
        table.remove(Library.ConsoleLog, 1)
    end
end

local function GetPlayers(target)
    local results = {}
    target = target:lower()
    
    if target == "me" then
        return {LocalPlayer}
    elseif target == "all" then
        return Players:GetPlayers()
    elseif target == "others" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                table.insert(results, p)
            end
        end
        return results
    elseif target == "random" then
        local all = Players:GetPlayers()
        if #all > 0 then
            return {all[math.random(1, #all)]}
        end
        return {}
    end
    
    -- Search by name
    for _, p in ipairs(Players:GetPlayers()) do
        local name = p.Name:lower()
        local display = p.DisplayName:lower()
        if name == target or display == target or 
           name:sub(1, #target) == target or display:sub(1, #target) == target then
            table.insert(results, p)
        end
    end
    
    return results
end

--// Console Rendering
local function RenderConsole()
    local scroll = ConsoleFrame:FindFirstChild("Scroll")
    if not scroll then return end
    
    -- Clear existing
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local layout = scroll:FindFirstChild("Layout") or Instance.new("UIListLayout")
    layout.Name = "Layout"
    layout.Padding = UDim.new(0, 2)
    layout.Parent = scroll
    
    for i, entry in ipairs(Library.ConsoleLog) do
        local line = Instance.new("Frame")
        line.Size = UDim2.new(1, -8, 0, 22)
        line.BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(22, 22, 28) or Color3.fromRGB(18, 18, 24)
        line.BackgroundTransparency = 0.3
        line.BorderSizePixel = 0
        line.Parent = scroll
        
        local lineCorner = Instance.new("UICorner")
        lineCorner.CornerRadius = UDim.new(0, 4)
        lineCorner.Parent = line
        
        local time = Instance.new("TextLabel")
        time.Size = UDim2.new(0, 55, 1, 0)
        time.Position = UDim2.new(0, 6, 0, 0)
        time.BackgroundTransparency = 1
        time.Font = Enum.Font.RobotoMono
        time.TextSize = 11
        time.TextColor3 = Color3.fromRGB(100, 100, 110)
        time.Text = entry.Time
        time.TextXAlignment = Enum.TextXAlignment.Left
        time.Parent = line
        
        local msg = Instance.new("TextLabel")
        msg.Size = UDim2.new(1, -70, 1, 0)
        msg.Position = UDim2.new(0, 65, 0, 0)
        msg.BackgroundTransparency = 1
        msg.Font = Enum.Font.RobotoMono
        msg.TextSize = 13
        msg.TextColor3 = entry.Color
        msg.Text = entry.Text
        msg.TextXAlignment = Enum.TextXAlignment.Left
        msg.TextTruncate = Enum.TextTruncate.AtEnd
        msg.Parent = line
    end
    
    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    scroll.CanvasPosition = Vector2.new(0, scroll.CanvasSize.Y.Offset)
end

--// Autocomplete
local function GetSuggestions(text)
    local suggestions = {}
    local words = text:split(" ")
    local current = words[#words] or ""
    
    if #words == 1 then
        -- Command suggestions
        for name, cmd in pairs(Library.Commands) do
            if name:lower():sub(1, #current:lower()) == current:lower() then
                table.insert(suggestions, {
                    Text = name,
                    Desc = cmd.Desc,
                    Type = "command"
                })
            end
        end
    else
        -- Player/target suggestions
        local cmd = Library.Commands[words[1]]
        if cmd and cmd.Args and cmd.Args[1] == "player" then
            for _, target in ipairs({"me", "all", "others", "random"}) do
                if target:sub(1, #current:lower()) == current:lower() then
                    table.insert(suggestions, {Text = target, Desc = "Target", Type = "target"})
                end
            end
            
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Name:lower():sub(1, #current:lower()) == current:lower() then
                    table.insert(suggestions, {
                        Text = p.Name,
                        Desc = "@" .. p.DisplayName,
                        Type = "player"
                    })
                end
            end
        end
    end
    
    return suggestions
end

local function RenderAutocomplete()
    local scroll = AutocompleteFrame:FindFirstChild("Scroll")
    if not scroll then return end
    
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local suggestions = Library.Suggestions
    
    if #suggestions == 0 then
        Tween(AutocompleteFrame, 0.15, {Size = UDim2.new(1, 0, 0, 0)})
        task.delay(0.15, function()
            AutocompleteFrame.Visible = false
        end)
        return
    end
    
    local layout = scroll:FindFirstChild("Layout") or Instance.new("UIListLayout")
    layout.Name = "Layout"
    layout.Padding = UDim.new(0, 2)
    layout.Parent = scroll
    
    for i, sug in ipairs(suggestions) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -6, 0, 28)
        btn.BackgroundColor3 = i == Library.SelectedSuggestion and Color3.fromRGB(40, 40, 50) or Color3.fromRGB(28, 28, 35)
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 13
        btn.TextColor3 = Color3.fromRGB(240, 240, 240)
        btn.Text = "  " .. sug.Text
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.AutoButtonColor = false
        btn.Parent = scroll
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn
        
        local typeColor = sug.Type == "command" and Color3.fromRGB(100, 200, 255) or
                          sug.Type == "player" and Color3.fromRGB(100, 255, 150) or
                          Color3.fromRGB(255, 200, 100)
        
        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 3, 0.5, 0)
        indicator.Position = UDim2.new(0, 4, 0.25, 0)
        indicator.BackgroundColor3 = typeColor
        indicator.BorderSizePixel = 0
        indicator.Parent = btn
        
        local indCorner = Instance.new("UICorner")
        indCorner.CornerRadius = UDim.new(1, 0)
        indCorner.Parent = indicator
        
        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(0.5, 0, 1, 0)
        desc.Position = UDim2.new(0.5, -10, 0, 0)
        desc.BackgroundTransparency = 1
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 11
        desc.TextColor3 = Color3.fromRGB(130, 130, 140)
        desc.Text = sug.Desc
        desc.TextXAlignment = Enum.TextXAlignment.Right
        desc.TextTruncate = Enum.TextTruncate.AtEnd
        desc.Parent = btn
        
        if i == Library.SelectedSuggestion then
            local stroke = Instance.new("UIStroke")
            stroke.Color = typeColor
            stroke.Thickness = 1
            stroke.Transparency = 0.6
            stroke.Parent = btn
        end
        
        btn.MouseEnter:Connect(function()
            Tween(btn, 0.1, {BackgroundColor3 = Color3.fromRGB(38, 38, 48)})
        end)
        
        btn.MouseLeave:Connect(function()
            if i ~= Library.SelectedSuggestion then
                Tween(btn, 0.1, {BackgroundColor3 = Color3.fromRGB(28, 28, 35)})
            end
        end)
        
        btn.MouseButton1Click:Connect(function()
            local words = InputBox.Text:split(" ")
            words[#words] = sug.Text
            InputBox.Text = table.concat(words, " ") .. " "
            InputBox.CursorPosition = #InputBox.Text + 1
            InputBox:CaptureFocus()
        end)
    end
    
    local height = math.min(150, layout.AbsoluteContentSize.Y + 10)
    AutocompleteFrame.Visible = true
    Tween(AutocompleteFrame, 0.15, {Size = UDim2.new(1, 0, 0, height)})
    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
end

local function UpdateAutocomplete(text)
    Library.Suggestions = GetSuggestions(text)
    Library.SelectedSuggestion = 0
    RenderAutocomplete()
end

--// Command Execution
local function ExecuteCommand(text)
    text = text:gsub("^%s+", ""):gsub("%s+$", "") -- Trim
    if text == "" then return end
    
    AddLog("❯ " .. text, Color3.fromRGB(100, 200, 255))
    
    table.insert(Library.CommandHistory, text)
    Library.HistoryIndex = 0
    
    local words = text:split(" ")
    local cmdName = words[1]:lower()
    local cmd = Library.Commands[cmdName]
    
    if not cmd then
        AddLog("✗ Unknown command: " .. cmdName, Color3.fromRGB(255, 100, 100))
        Notify("Unknown command", Color3.fromRGB(255, 100, 100))
        RenderConsole()
        return
    end
    
    -- Built-in commands
    if cmdName == "help" or cmdName == "cmds" then
        AddLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━", Color3.fromRGB(80, 80, 90))
        for name, c in pairs(Library.Commands) do
            local argStr = c.Args and #c.Args > 0 and " <" .. table.concat(c.Args, "> <") .. ">" or ""
            AddLog(name .. argStr .. " - " .. c.Desc, Color3.fromRGB(200, 200, 210))
        end
        AddLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━", Color3.fromRGB(80, 80, 90))
        RenderConsole()
        return
    elseif cmdName == "clear" then
        Library.ConsoleLog = {}
        RenderConsole()
        return
    end
    
    -- Execute command
    local success, result = pcall(function()
        if cmd.Args and cmd.Args[1] == "player" then
            if #words < 2 then
                return false, "Missing player target"
            end
            
            local targets = GetPlayers(words[2])
            if #targets == 0 then
                return false, "No players found: " .. words[2]
            end
            
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
            if not num then
                return false, "Invalid number"
            end
            return true, cmd.Func(num)
        else
            return true, cmd.Func()
        end
    end)
    
    if success and result then
        if type(result) == "table" then
            if result[1] then
                AddLog("✓ " .. (result[2] or "Success"), Color3.fromRGB(100, 255, 150))
                Notify(result[2] or "Success", Color3.fromRGB(100, 255, 150))
            else
                AddLog("✗ " .. (result[2] or "Failed"), Color3.fromRGB(255, 100, 100))
                Notify(result[2] or "Failed", Color3.fromRGB(255, 100, 100))
            end
        elseif type(result) == "string" then
            AddLog("✓ " .. result, Color3.fromRGB(100, 255, 150))
            Notify(result, Color3.fromRGB(100, 255, 150))
        end
    elseif not success then
        AddLog("✗ Error: " .. tostring(result), Color3.fromRGB(255, 100, 100))
    end
    
    RenderConsole()
end

--// Toggle UI
local function Toggle()
    Library.IsOpen = not Library.IsOpen
    
    if Library.IsOpen then
        MainFrame.Visible = true
        ConsoleFrame.Visible = true
        
        Tween(MainFrame, 0.35, {Position = UDim2.new(0.5, 0, 0, 25)}, Enum.EasingStyle.Back)
        Tween(ConsoleFrame, 0.35, {Position = UDim2.new(0.5, 0, 0, 105)}, Enum.EasingStyle.Back)
        
        task.delay(0.1, function()
            InputBox:CaptureFocus()
        end)
        
        -- Update status
        local cmdCount = 0
        for _ in pairs(Library.Commands) do cmdCount = cmdCount + 1 end
        StatusLabel.Text = string.format("Commands: %d | Players: %d", cmdCount, #Players:GetPlayers())
    else
        AutocompleteFrame.Visible = false
        InputBox:ReleaseFocus()
        
        Tween(MainFrame, 0.25, {Position = UDim2.new(0.5, 0, 0, -120)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        Tween(ConsoleFrame, 0.25, {Position = UDim2.new(0.5, 0, 0, -400)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        
        task.delay(0.25, function()
            if not Library.IsOpen then
                MainFrame.Visible = false
                ConsoleFrame.Visible = false
            end
        end)
    end
end

--// Create GUI
local function CreateGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "FluentCLI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Console Frame (output)
    local console = Instance.new("Frame")
    console.Name = "Console"
    console.Size = UDim2.new(0, 650, 0, 280)
    console.Position = UDim2.new(0.5, 0, 0, -400)
    console.AnchorPoint = Vector2.new(0.5, 0)
    console.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
    console.BorderSizePixel = 0
    console.Visible = false
    console.Parent = gui
    
    local consoleCorner = Instance.new("UICorner")
    consoleCorner.CornerRadius = UDim.new(0, 10)
    consoleCorner.Parent = console
    
    local consoleStroke = Instance.new("UIStroke")
    consoleStroke.Color = Color3.fromRGB(60, 60, 70)
    consoleStroke.Thickness = 1
    consoleStroke.Parent = console
    
    local consoleScroll = Instance.new("ScrollingFrame")
    consoleScroll.Name = "Scroll"
    consoleScroll.Size = UDim2.new(1, -20, 1, -20)
    consoleScroll.Position = UDim2.new(0, 10, 0, 10)
    consoleScroll.BackgroundTransparency = 1
    consoleScroll.BorderSizePixel = 0
    consoleScroll.ScrollBarThickness = 4
    consoleScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
    consoleScroll.Parent = console
    
    -- Main Frame (input)
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 650, 0, 70)
    main.Position = UDim2.new(0.5, 0, 0, -120)
    main.AnchorPoint = Vector2.new(0.5, 0)
    main.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
    main.BorderSizePixel = 0
    main.Visible = false
    main.Parent = gui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = main
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(100, 180, 255)
    mainStroke.Thickness = 1.5
    mainStroke.Parent = main
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 28)
    titleBar.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar
    
    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 12)
    titleFix.Position = UDim2.new(0, 0, 1, -12)
    titleFix.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 150, 1, 0)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextColor3 = Color3.fromRGB(100, 180, 255)
    title.Text = "⌘ FluentCLI"
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar
    
    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(0.6, 0, 1, 0)
    status.Position = UDim2.new(0.4, -10, 0, 0)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.Gotham
    status.TextSize = 11
    status.TextColor3 = Color3.fromRGB(100, 100, 120)
    status.Text = "Commands: 0 | Players: 0"
    status.TextXAlignment = Enum.TextXAlignment.Right
    status.Parent = titleBar
    
    -- Input box
    local input = Instance.new("TextBox")
    input.Name = "Input"
    input.Size = UDim2.new(1, -24, 0, 28)
    input.Position = UDim2.new(0, 12, 0, 34)
    input.BackgroundTransparency = 1
    input.Font = Enum.Font.RobotoMono
    input.TextSize = 15
    input.TextColor3 = Color3.fromRGB(240, 240, 240)
    input.PlaceholderText = "❯ Type a command..."
    input.PlaceholderColor3 = Color3.fromRGB(90, 90, 110)
    input.Text = ""
    input.TextXAlignment = Enum.TextXAlignment.Left
    input.ClearTextOnFocus = false
    input.Parent = main
    
    local inputLine = Instance.new("Frame")
    inputLine.Size = UDim2.new(1, -24, 0, 2)
    inputLine.Position = UDim2.new(0, 12, 1, -6)
    inputLine.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
    inputLine.BackgroundTransparency = 0.7
    inputLine.BorderSizePixel = 0
    inputLine.Parent = main
    
    local lineCorner = Instance.new("UICorner")
    lineCorner.CornerRadius = UDim.new(1, 0)
    lineCorner.Parent = inputLine
    
    -- Autocomplete frame
    local autocomplete = Instance.new("Frame")
    autocomplete.Name = "Autocomplete"
    autocomplete.Size = UDim2.new(1, 0, 0, 0)
    autocomplete.Position = UDim2.new(0, 0, 1, 6)
    autocomplete.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    autocomplete.BorderSizePixel = 0
    autocomplete.Visible = false
    autocomplete.ClipsDescendants = true
    autocomplete.Parent = main
    
    local acCorner = Instance.new("UICorner")
    acCorner.CornerRadius = UDim.new(0, 8)
    acCorner.Parent = autocomplete
    
    local acStroke = Instance.new("UIStroke")
    acStroke.Color = Color3.fromRGB(50, 50, 60)
    acStroke.Thickness = 1
    acStroke.Parent = autocomplete
    
    local acScroll = Instance.new("ScrollingFrame")
    acScroll.Name = "Scroll"
    acScroll.Size = UDim2.new(1, -6, 1, -6)
    acScroll.Position = UDim2.new(0, 3, 0, 3)
    acScroll.BackgroundTransparency = 1
    acScroll.BorderSizePixel = 0
    acScroll.ScrollBarThickness = 3
    acScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
    acScroll.Parent = autocomplete
    
    -- Input effects
    input.Focused:Connect(function()
        Tween(inputLine, 0.2, {BackgroundTransparency = 0.3})
        Tween(mainStroke, 0.2, {Color = Color3.fromRGB(100, 200, 255)})
    end)
    
    input.FocusLost:Connect(function()
        Tween(inputLine, 0.2, {BackgroundTransparency = 0.7})
        Tween(mainStroke, 0.2, {Color = Color3.fromRGB(60, 60, 70)})
    end)
    
    return gui, main, input, autocomplete, console, status
end

--// Initialize
function Library:Init()
    ScreenGui, MainFrame, InputBox, AutocompleteFrame, ConsoleFrame, StatusLabel = CreateGUI()
    ScreenGui.Parent = CoreGui
    
    -- Built-in commands
    self.Commands.help = {Desc = "Show all commands", Args = {}, Func = function() end}
    self.Commands.cmds = {Desc = "List all commands", Args = {}, Func = function() end}
    self.Commands.clear = {Desc = "Clear console", Args = {}, Func = function() end}
    
    -- Input handling - SINGLE handler for toggle
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.Insert then
            Toggle()
            return
        end
        
        if not self.IsOpen then return end
        
        if input.KeyCode == Enum.KeyCode.Escape then
            Toggle()
        elseif input.KeyCode == Enum.KeyCode.Return then
            local cmd = InputBox.Text:gsub("\n", ""):gsub("\r", "")
            InputBox.Text = ""
            ExecuteCommand(cmd)
        elseif input.KeyCode == Enum.KeyCode.Up then
            if #self.CommandHistory > 0 then
                self.HistoryIndex = math.min(self.HistoryIndex + 1, #self.CommandHistory)
                InputBox.Text = self.CommandHistory[#self.CommandHistory - self.HistoryIndex + 1]
                InputBox.CursorPosition = #InputBox.Text + 1
            end
        elseif input.KeyCode == Enum.KeyCode.Down then
            if self.HistoryIndex > 0 then
                self.HistoryIndex = self.HistoryIndex - 1
                if self.HistoryIndex == 0 then
                    InputBox.Text = ""
                else
                    InputBox.Text = self.CommandHistory[#self.CommandHistory - self.HistoryIndex + 1]
                end
            end
        elseif input.KeyCode == Enum.KeyCode.Tab then
            if #self.Suggestions > 0 then
                self.SelectedSuggestion = (self.SelectedSuggestion % #self.Suggestions) + 1
                local words = InputBox.Text:split(" ")
                words[#words] = self.Suggestions[self.SelectedSuggestion].Text
                InputBox.Text = table.concat(words, " ") .. " "
                InputBox.CursorPosition = #InputBox.Text + 1
                task.wait()
                RenderAutocomplete()
            end
        end
    end)
    
    -- Text change
    InputBox:GetPropertyChangedSignal("Text"):Connect(function()
        -- Clean tabs/newlines
        local text = InputBox.Text
        local cleaned = text:gsub("\t", ""):gsub("\n", ""):gsub("\r", "")
        if cleaned ~= text then
            InputBox.Text = cleaned
        end
        
        if InputBox.Text ~= "" then
            UpdateAutocomplete(InputBox.Text)
        else
            AutocompleteFrame.Visible = false
        end
    end)
    
    -- Keep focus while open
    task.spawn(function()
        while true do
            task.wait(0.2)
            if self.IsOpen and not InputBox:IsFocused() then
                InputBox:CaptureFocus()
            end
        end
    end)
    
    -- Welcome messages
    AddLog("✓ FluentCLI initialized!", Color3.fromRGB(100, 255, 150))
    AddLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━", Color3.fromRGB(60, 60, 70))
    AddLog("Press INSERT to toggle", Color3.fromRGB(180, 180, 190))
    AddLog("Type 'help' for commands", Color3.fromRGB(180, 180, 190))
    AddLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━", Color3.fromRGB(60, 60, 70))
    RenderConsole()
    
    Notify("FluentCLI loaded!", Color3.fromRGB(100, 255, 150))
end

function Library:AddCommand(name, desc, args, func)
    self.Commands[name:lower()] = {
        Desc = desc,
        Args = args or {},
        Func = func
    }
end

return Library
