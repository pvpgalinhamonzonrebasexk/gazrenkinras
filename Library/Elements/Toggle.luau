-- // Services
local userInputService = UserInputService or game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")
local players = game:GetService("Players")
local env = getgenv and getgenv() or _G

-- // Themes
local Default = {
    Active = Color3.fromRGB(240, 240, 240),
    Inactive = Color3.fromRGB(165, 165, 165),
    Dim = Color3.fromRGB(115, 115, 115),
    Accent = Color3.fromRGB(42, 42, 42),
    Border = Color3.fromRGB(55, 55, 55),
    BorderHover = Color3.fromRGB(88, 88, 88),
    Palette = Color3.fromRGB(28, 28, 28),
    Background = Color3.fromRGB(24, 24, 24),
    GradientTop = Color3.fromRGB(38, 38, 38),
}

local THEME_KEYS = {
    "Active",
    "Inactive",
    "Dim",
    "Accent",
    "Border",
    "BorderHover",
    "Palette",
    "Background",
    "GradientTop",
}

-- // ThemeWatcher
local themeWatchers = {}
local themeConnection

local function startThemeWatcher()
    if themeConnection then
        return
    end

    local elapsed = 0

    themeConnection = runService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt

        if elapsed < 0.25 then
            return
        end

        elapsed = 0

        for check in pairs(themeWatchers) do
            check()
        end
    end)
end

local function stopThemeWatcher()
    if themeConnection and next(themeWatchers) == nil then
        themeConnection:Disconnect()
        themeConnection = nil
    end
end

local function createColors(panel)
    local colors = setmetatable({}, {
        __index = function(_, key)
            local theme = panel and panel.Theme
            local live = type(theme) == "table" and theme[key] or nil

            if typeof(live) == "Color3" then
                return live
            end

            return Default[key]
        end
    })

    local function signature()
        local parts = {}

        for index, key in ipairs(THEME_KEYS) do
            parts[index] = tostring(colors[key])
        end

        return table.concat(parts, "|")
    end

    local lastSignature = signature()

    local function watch(apply)
        local function check()
            local current = signature()

            if current == lastSignature then
                return
            end

            lastSignature = current
            pcall(apply)
        end

        themeWatchers[check] = true
        startThemeWatcher()

        return function()
            themeWatchers[check] = nil
            stopThemeWatcher()
        end
    end

    return colors, watch
end

-- // Config
local NOTIFY_TITLE = "Sistema"
local WORD_MAX = 20
local TWEEN_INFO = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- // Fonts
local function getFonts()
    return FONT_BOLD or Enum.Font.SourceSansSemibold, FONT or Enum.Font.SourceSans
end

-- // Emoji
local EMOJI_LIST = {
    fire = "\u{1F525}",
    star = "\u{2B50}",
    heart = "\u{2764}\u{FE0F}",
    check = "\u{2705}",
    cross = "\u{274C}",
    warning = "\u{26A0}\u{FE0F}",
    lock = "\u{1F512}",
    unlock = "\u{1F513}",
    gear = "\u{2699}\u{FE0F}",
    bolt = "\u{26A1}",
    eye = "\u{1F441}\u{FE0F}",
    target = "\u{1F3AF}",
    sword = "\u{2694}\u{FE0F}",
    shield = "\u{1F6E1}\u{FE0F}",
    gun = "\u{1F52B}",
    skull = "\u{1F480}",
    crown = "\u{1F451}",
    rocket = "\u{1F680}",
    gem = "\u{1F48E}",
    fish = "\u{1F41F}",
    sparkles = "\u{2728}",
    bell = "\u{1F514}",
    key = "\u{1F511}",
    globe = "\u{1F310}",
    music = "\u{1F3B5}",
    moon = "\u{1F319}",
    sun = "\u{2600}\u{FE0F}",
    pumpkin = "\u{1F383}",
    ghost = "\u{1F47B}",
    candy = "\u{1F36C}",
    car = "\u{1F697}",
    run = "\u{1F3C3}",
    wrench = "\u{1F527}",
    trophy = "\u{1F3C6}",
    flag = "\u{1F3C1}",
    wave = "\u{1F30A}",
    home = "\u{1F3E0}",
    clock = "\u{1F552}",
    diamond = "\u{1F537}",
}

local Emoji = {}

local function emojiKey(name)
    return (tostring(name or ""):lower():gsub("^:", ""):gsub(":$", ""))
end

local function isJoiner(codepoint)
    return codepoint == 0xFE0F
        or codepoint == 0xFE0E
        or codepoint == 0x200D
        or (codepoint >= 0x1F3FB and codepoint <= 0x1F3FF)
        or (codepoint >= 0x0300 and codepoint <= 0x036F)
        or (codepoint >= 0xE0020 and codepoint <= 0xE007F)
end

function Emoji.Get(name)
    return EMOJI_LIST[emojiKey(name)]
end

function Emoji.Add(name, value)
    local key = emojiKey(name)

    if key == "" or type(value) ~= "string" or value == "" then
        return false
    end

    EMOJI_LIST[key] = value

    return true
end

function Emoji.Remove(name)
    EMOJI_LIST[emojiKey(name)] = nil
end

function Emoji.List()
    local copy = {}

    for key, value in pairs(EMOJI_LIST) do
        copy[key] = value
    end

    return copy
end

function Emoji.Sanitize(text)
    text = tostring(text or "")

    if utf8.len(text) then
        return text
    end

    local result = {}

    for char in text:gmatch(utf8.charpattern) do
        if utf8.len(char) then
            result[#result + 1] = char
        end
    end

    return table.concat(result)
end

function Emoji.Parse(text)
    text = Emoji.Sanitize(text)

    return (text:gsub(":([%w_]+):", function(name)
        return EMOJI_LIST[name:lower()]
    end))
end

function Emoji.Units(text)
    text = Emoji.Sanitize(text)

    local units = {}
    local joinNext = false
    local flagOpen = false

    for _, codepoint in utf8.codes(text) do
        local char = utf8.char(codepoint)
        local isFlag = codepoint >= 0x1F1E6 and codepoint <= 0x1F1FF

        if #units > 0 and (joinNext or isJoiner(codepoint) or (isFlag and flagOpen)) then
            units[#units] = units[#units] .. char
            flagOpen = false
        else
            units[#units + 1] = char
            flagOpen = isFlag
        end

        joinNext = codepoint == 0x200D
    end

    return units
end

function Emoji.Length(text)
    return #Emoji.Units(text)
end

env.EcoHubEmoji = Emoji

-- // Notify
local function notify(msg, duration)
    pcall(function()
        Notify({
            Title = Emoji.Parse(NOTIFY_TITLE),
            Description = Emoji.Parse(msg),
            Duration = duration
        })
    end)
end

-- // Animation
local function play(instance, props, animate)
    if animate then
        tweenService:Create(instance, TWEEN_INFO, props):Play()
    else
        for property, value in pairs(props) do
            instance[property] = value
        end
    end
end

-- // Text
local function breakLongWords(text, maxLen)
    text = Emoji.Parse(text)
    local lines = {}

    for line in (text .. "\n"):gmatch("(.-)\n") do
        local result = {}

        for word in line:gmatch("%S+") do
            if #word <= maxLen then
                result[#result + 1] = word
            else
                local units = Emoji.Units(word)

                if #units > maxLen then
                    for index = 1, #units, maxLen do
                        result[#result + 1] = table.concat(units, "", index, math.min(index + maxLen - 1, #units))
                    end
                else
                    result[#result + 1] = word
                end
            end
        end

        lines[#lines + 1] = table.concat(result, " ")
    end

    return table.concat(lines, "\n")
end

-- // Keybinds
local KEY_NAMES = {
    [Enum.KeyCode.LeftShift] = "LShift",
    [Enum.KeyCode.RightShift] = "RShift",
    [Enum.KeyCode.LeftControl] = "LCtrl",
    [Enum.KeyCode.RightControl] = "RCtrl",
    [Enum.KeyCode.LeftAlt] = "LAlt",
    [Enum.KeyCode.RightAlt] = "RAlt",
    [Enum.KeyCode.CapsLock] = "Caps",
    [Enum.KeyCode.Return] = "Enter",
    [Enum.KeyCode.Backspace] = "Back",
    [Enum.KeyCode.Delete] = "Del",
    [Enum.KeyCode.Insert] = "Ins",
    [Enum.KeyCode.PageUp] = "PgUp",
    [Enum.KeyCode.PageDown] = "PgDn",
    [Enum.KeyCode.Escape] = "Esc",
    [Enum.KeyCode.Zero] = "0",
    [Enum.KeyCode.One] = "1",
    [Enum.KeyCode.Two] = "2",
    [Enum.KeyCode.Three] = "3",
    [Enum.KeyCode.Four] = "4",
    [Enum.KeyCode.Five] = "5",
    [Enum.KeyCode.Six] = "6",
    [Enum.KeyCode.Seven] = "7",
    [Enum.KeyCode.Eight] = "8",
    [Enum.KeyCode.Nine] = "9",
    [Enum.KeyCode.KeypadZero] = "Num0",
    [Enum.KeyCode.KeypadOne] = "Num1",
    [Enum.KeyCode.KeypadTwo] = "Num2",
    [Enum.KeyCode.KeypadThree] = "Num3",
    [Enum.KeyCode.KeypadFour] = "Num4",
    [Enum.KeyCode.KeypadFive] = "Num5",
    [Enum.KeyCode.KeypadSix] = "Num6",
    [Enum.KeyCode.KeypadSeven] = "Num7",
    [Enum.KeyCode.KeypadEight] = "Num8",
    [Enum.KeyCode.KeypadNine] = "Num9",
    [Enum.UserInputType.MouseButton1] = "M1",
    [Enum.UserInputType.MouseButton2] = "M2",
    [Enum.UserInputType.MouseButton3] = "M3",
}

local function getKeyName(binding)
    if not binding then
        return "None"
    end

    local name = KEY_NAMES[binding]

    if name then
        return name
    end

    local ok, result = pcall(function()
        return binding.Name
    end)

    if ok and type(result) == "string" and result ~= "" then
        return result
    end

    return "?"
end

local function isValidBinding(binding)
    if typeof(binding) ~= "EnumItem" then
        return false
    end

    return binding.EnumType == Enum.KeyCode or binding.EnumType == Enum.UserInputType
end

local function normalizeBinding(binding)
    if typeof(binding) == "EnumItem" then
        return binding
    end

    if type(binding) == "string" and binding ~= "" then
        local candidates = {
            binding,
            binding:upper(),
            binding:sub(1, 1):upper() .. binding:sub(2)
        }

        for _, name in ipairs(candidates) do
            local ok, res = pcall(function()
                return Enum.KeyCode[name]
            end)

            if ok and res then
                return res
            end

            ok, res = pcall(function()
                return Enum.UserInputType[name]
            end)

            if ok and res then
                return res
            end
        end
    end

    return nil
end

local function matchInput(binding, input)
    if typeof(binding) ~= "EnumItem" then
        return false
    end

    if binding.EnumType == Enum.KeyCode then
        return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == binding
    elseif binding.EnumType == Enum.UserInputType then
        return input.UserInputType == binding
    end

    return false
end

-- // KeybindHud
local HUD_WIDTH = 232
local HUD_HEADER_H = 38
local HUD_ROW_H = 30
local HUD_PILL_W = 58
local HUD_MARGIN = 12

local HUD_BG_TOP = Color3.fromRGB(68, 68, 80)
local HUD_BG_BOTTOM = Color3.fromRGB(46, 46, 56)
local HUD_BORDER = Color3.fromRGB(104, 104, 122)
local HUD_ROW = Color3.fromRGB(80, 80, 96)
local HUD_TEXT = Color3.fromRGB(255, 255, 255)
local HUD_SUB = Color3.fromRGB(200, 200, 212)
local HUD_DIM = Color3.fromRGB(150, 150, 166)
local HUD_ON = Color3.fromRGB(74, 222, 128)
local HUD_OFF = Color3.fromRGB(122, 122, 138)
local HUD_CLOSE = Color3.fromRGB(255, 110, 110)

local HUD_ACCENTS = {
    Color3.fromRGB(139, 92, 246),
    Color3.fromRGB(59, 130, 246),
    Color3.fromRGB(34, 197, 94),
    Color3.fromRGB(236, 72, 153),
    Color3.fromRGB(249, 115, 22),
}

local keybindHud

local function getPlayerGui()
    local player = players.LocalPlayer

    if not player then
        return nil
    end

    return player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 5)
end

local function createKeybindHud()
    local parent = getPlayerGui()

    if not parent then
        return nil
    end

    local fontBold = getFonts()

    local hud = {
        closed = false,
        entries = {},
        order = 0,
        accent = HUD_ACCENTS[1],
        onlyActive = false,
        draggable = true,
    }

    local connections = {}
    local userMoved = false

    local function bindHover(button, onEnter, onLeave)
        connections[#connections + 1] = button.MouseEnter:Connect(onEnter)
        connections[#connections + 1] = button.MouseLeave:Connect(onLeave)
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "EcoHubKeybindHud"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 50
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = parent

    hud.gui = gui

    local frame = Instance.new("Frame")
    frame.Name = "Hud"
    frame.AnchorPoint = Vector2.new(0, 0)
    frame.Position = UDim2.new(0, HUD_MARGIN, 0.5, -60)
    frame.Size = UDim2.new(0, HUD_WIDTH, 0, 0)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.BackgroundColor3 = Color3.new(1, 1, 1)
    frame.BackgroundTransparency = 0.02
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = gui

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 12)
    frameCorner.Parent = frame

    local frameGradient = Instance.new("UIGradient")
    frameGradient.Rotation = 90
    frameGradient.Parent = frame

    local frameStroke = Instance.new("UIStroke")
    frameStroke.Color = Color3.new(1, 1, 1)
    frameStroke.Thickness = 1.5
    frameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    frameStroke.Parent = frame

    local strokeGradient = Instance.new("UIGradient")
    strokeGradient.Rotation = 90
    strokeGradient.Parent = frameStroke

    local frameLayout = Instance.new("UIListLayout")
    frameLayout.FillDirection = Enum.FillDirection.Vertical
    frameLayout.SortOrder = Enum.SortOrder.LayoutOrder
    frameLayout.Padding = UDim.new(0, 0)
    frameLayout.Parent = frame

    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, HUD_HEADER_H)
    header.BackgroundTransparency = 1
    header.LayoutOrder = 0
    header.Active = true
    header.Parent = frame

    local headerPadding = Instance.new("UIPadding")
    headerPadding.PaddingLeft = UDim.new(0, 12)
    headerPadding.PaddingRight = UDim.new(0, 8)
    headerPadding.Parent = header

    local badge = Instance.new("Frame")
    badge.Name = "Badge"
    badge.Size = UDim2.new(0, 22, 0, 22)
    badge.AnchorPoint = Vector2.new(0, 0.5)
    badge.Position = UDim2.new(0, 0, 0.5, 0)
    badge.BackgroundColor3 = Color3.new(1, 1, 1)
    badge.BorderSizePixel = 0
    badge.Parent = header

    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0, 7)
    badgeCorner.Parent = badge

    local badgeGradient = Instance.new("UIGradient")
    badgeGradient.Rotation = 45
    badgeGradient.Parent = badge

    local badgeIcon = Instance.new("TextLabel")
    badgeIcon.Name = "Icon"
    badgeIcon.Size = UDim2.new(1, 0, 1, 0)
    badgeIcon.BackgroundTransparency = 1
    badgeIcon.Text = Emoji.Parse(":key:")
    badgeIcon.TextColor3 = HUD_TEXT
    badgeIcon.TextSize = 12
    badgeIcon.Font = fontBold
    badgeIcon.TextXAlignment = Enum.TextXAlignment.Center
    badgeIcon.TextYAlignment = Enum.TextYAlignment.Center
    badgeIcon.Parent = badge

    local headerLabel = Instance.new("TextLabel")
    headerLabel.Name = "Title"
    headerLabel.Position = UDim2.new(0, 30, 0, 0)
    headerLabel.Size = UDim2.new(1, -(30 + 92), 1, 0)
    headerLabel.BackgroundTransparency = 1
    headerLabel.Text = "Key Bind"
    headerLabel.TextColor3 = HUD_TEXT
    headerLabel.TextSize = 14
    headerLabel.Font = fontBold
    headerLabel.TextXAlignment = Enum.TextXAlignment.Left
    headerLabel.TextYAlignment = Enum.TextYAlignment.Center
    headerLabel.TextTruncate = Enum.TextTruncate.AtEnd
    headerLabel.Parent = header

    local headerRight = Instance.new("Frame")
    headerRight.Name = "Right"
    headerRight.AnchorPoint = Vector2.new(1, 0.5)
    headerRight.Position = UDim2.new(1, 0, 0.5, 0)
    headerRight.Size = UDim2.new(0, 0, 1, 0)
    headerRight.AutomaticSize = Enum.AutomaticSize.X
    headerRight.BackgroundTransparency = 1
    headerRight.Parent = header

    local rightLayout = Instance.new("UIListLayout")
    rightLayout.FillDirection = Enum.FillDirection.Horizontal
    rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    rightLayout.Padding = UDim.new(0, 4)
    rightLayout.Parent = headerRight

    local countLabel = Instance.new("TextLabel")
    countLabel.Name = "Count"
    countLabel.Size = UDim2.new(0, 0, 0, 20)
    countLabel.AutomaticSize = Enum.AutomaticSize.X
    countLabel.BackgroundColor3 = HUD_ROW
    countLabel.BackgroundTransparency = 0.3
    countLabel.BorderSizePixel = 0
    countLabel.Text = "0/0"
    countLabel.TextColor3 = HUD_TEXT
    countLabel.TextSize = 11
    countLabel.Font = fontBold
    countLabel.LayoutOrder = 0
    countLabel.Parent = headerRight

    local countCorner = Instance.new("UICorner")
    countCorner.CornerRadius = UDim.new(1, 0)
    countCorner.Parent = countLabel

    local countPadding = Instance.new("UIPadding")
    countPadding.PaddingLeft = UDim.new(0, 8)
    countPadding.PaddingRight = UDim.new(0, 8)
    countPadding.Parent = countLabel

    local optionsBtn = Instance.new("TextButton")
    optionsBtn.Name = "OptionsButton"
    optionsBtn.Size = UDim2.new(0, 22, 0, 22)
    optionsBtn.BackgroundTransparency = 1
    optionsBtn.Text = ""
    optionsBtn.AutoButtonColor = false
    optionsBtn.Selectable = false
    optionsBtn.LayoutOrder = 1
    optionsBtn.ZIndex = 2
    optionsBtn.Parent = headerRight

    local optionsDotsLayout = Instance.new("UIListLayout")
    optionsDotsLayout.FillDirection = Enum.FillDirection.Horizontal
    optionsDotsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    optionsDotsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    optionsDotsLayout.Padding = UDim.new(0, 3)
    optionsDotsLayout.Parent = optionsBtn

    local optionsDots = {}

    for index = 1, 3 do
        local dotPart = Instance.new("Frame")
        dotPart.Name = "Dot"
        dotPart.Size = UDim2.new(0, 4, 0, 4)
        dotPart.BackgroundColor3 = HUD_SUB
        dotPart.BorderSizePixel = 0
        dotPart.LayoutOrder = index
        dotPart.ZIndex = 3
        dotPart.Parent = optionsBtn

        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = dotPart

        optionsDots[#optionsDots + 1] = dotPart
    end

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 22, 0, 22)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = ""
    closeBtn.AutoButtonColor = false
    closeBtn.Selectable = false
    closeBtn.LayoutOrder = 2
    closeBtn.ZIndex = 2
    closeBtn.Parent = headerRight

    local closeLines = {}

    for _, rotation in ipairs({ 45, -45 }) do
        local line = Instance.new("Frame")
        line.Name = "Line"
        line.Size = UDim2.new(0, 12, 0, 2)
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.Position = UDim2.new(0.5, 0, 0.5, 0)
        line.Rotation = rotation
        line.BackgroundColor3 = HUD_SUB
        line.BorderSizePixel = 0
        line.ZIndex = 3
        line.Parent = closeBtn

        local lineCorner = Instance.new("UICorner")
        lineCorner.CornerRadius = UDim.new(1, 0)
        lineCorner.Parent = line

        closeLines[#closeLines + 1] = line
    end

    -- Divider
    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.BackgroundColor3 = Color3.new(1, 1, 1)
    divider.BorderSizePixel = 0
    divider.LayoutOrder = 1
    divider.Parent = frame

    local dividerGradient = Instance.new("UIGradient")
    dividerGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.1),
        NumberSequenceKeypoint.new(1, 1),
    })
    dividerGradient.Parent = divider

    -- Body
    local body = Instance.new("Frame")
    body.Name = "Body"
    body.Size = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.BackgroundTransparency = 1
    body.LayoutOrder = 2
    body.Parent = frame

    local bodyPadding = Instance.new("UIPadding")
    bodyPadding.PaddingTop = UDim.new(0, 8)
    bodyPadding.PaddingBottom = UDim.new(0, 8)
    bodyPadding.PaddingLeft = UDim.new(0, 10)
    bodyPadding.PaddingRight = UDim.new(0, 10)
    bodyPadding.Parent = body

    local bodyLayout = Instance.new("UIListLayout")
    bodyLayout.FillDirection = Enum.FillDirection.Vertical
    bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bodyLayout.Padding = UDim.new(0, 4)
    bodyLayout.Parent = body

    local emptyLabel = Instance.new("TextLabel")
    emptyLabel.Name = "Empty"
    emptyLabel.Size = UDim2.new(1, 0, 0, 24)
    emptyLabel.BackgroundTransparency = 1
    emptyLabel.Text = "Nenhum ativo"
    emptyLabel.TextColor3 = HUD_DIM
    emptyLabel.TextSize = 12
    emptyLabel.Font = fontBold
    emptyLabel.LayoutOrder = 0
    emptyLabel.Visible = false
    emptyLabel.Parent = body

    -- Options
    local optionsFrame = Instance.new("Frame")
    optionsFrame.Name = "Options"
    optionsFrame.Size = UDim2.new(1, 0, 0, 0)
    optionsFrame.AutomaticSize = Enum.AutomaticSize.Y
    optionsFrame.BackgroundTransparency = 1
    optionsFrame.LayoutOrder = 3
    optionsFrame.Visible = false
    optionsFrame.Parent = frame

    local optionsLayout = Instance.new("UIListLayout")
    optionsLayout.FillDirection = Enum.FillDirection.Vertical
    optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    optionsLayout.Parent = optionsFrame

    local optionsDivider = Instance.new("Frame")
    optionsDivider.Name = "Divider"
    optionsDivider.Size = UDim2.new(1, 0, 0, 1)
    optionsDivider.BackgroundColor3 = HUD_BORDER
    optionsDivider.BackgroundTransparency = 0.4
    optionsDivider.BorderSizePixel = 0
    optionsDivider.LayoutOrder = 0
    optionsDivider.Parent = optionsFrame

    local optionsBody = Instance.new("Frame")
    optionsBody.Name = "Body"
    optionsBody.Size = UDim2.new(1, 0, 0, 0)
    optionsBody.AutomaticSize = Enum.AutomaticSize.Y
    optionsBody.BackgroundTransparency = 1
    optionsBody.LayoutOrder = 1
    optionsBody.Parent = optionsFrame

    local optionsBodyPadding = Instance.new("UIPadding")
    optionsBodyPadding.PaddingTop = UDim.new(0, 10)
    optionsBodyPadding.PaddingBottom = UDim.new(0, 12)
    optionsBodyPadding.PaddingLeft = UDim.new(0, 12)
    optionsBodyPadding.PaddingRight = UDim.new(0, 12)
    optionsBodyPadding.Parent = optionsBody

    local optionsBodyLayout = Instance.new("UIListLayout")
    optionsBodyLayout.FillDirection = Enum.FillDirection.Vertical
    optionsBodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    optionsBodyLayout.Padding = UDim.new(0, 8)
    optionsBodyLayout.Parent = optionsBody

    local function makeOptionRow(text, order)
        local optionRow = Instance.new("Frame")
        optionRow.Size = UDim2.new(1, 0, 0, 22)
        optionRow.BackgroundTransparency = 1
        optionRow.LayoutOrder = order
        optionRow.Parent = optionsBody

        local optionLabel = Instance.new("TextLabel")
        optionLabel.Size = UDim2.new(0.5, 0, 1, 0)
        optionLabel.BackgroundTransparency = 1
        optionLabel.Text = text
        optionLabel.TextColor3 = HUD_SUB
        optionLabel.TextSize = 12
        optionLabel.Font = fontBold
        optionLabel.TextXAlignment = Enum.TextXAlignment.Left
        optionLabel.TextYAlignment = Enum.TextYAlignment.Center
        optionLabel.ZIndex = 2
        optionLabel.Parent = optionRow

        return optionRow
    end

    local colorRow = makeOptionRow("Cor", 0)

    local swatchHolder = Instance.new("Frame")
    swatchHolder.Name = "Swatches"
    swatchHolder.AnchorPoint = Vector2.new(1, 0.5)
    swatchHolder.Position = UDim2.new(1, 0, 0.5, 0)
    swatchHolder.Size = UDim2.new(0, 0, 1, 0)
    swatchHolder.AutomaticSize = Enum.AutomaticSize.X
    swatchHolder.BackgroundTransparency = 1
    swatchHolder.Parent = colorRow

    local swatchLayout = Instance.new("UIListLayout")
    swatchLayout.FillDirection = Enum.FillDirection.Horizontal
    swatchLayout.SortOrder = Enum.SortOrder.LayoutOrder
    swatchLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    swatchLayout.Padding = UDim.new(0, 7)
    swatchLayout.Parent = swatchHolder

    local swatches = {}

    for index, color in ipairs(HUD_ACCENTS) do
        local swatch = Instance.new("TextButton")
        swatch.Name = "Swatch"
        swatch.Size = UDim2.new(0, 16, 0, 16)
        swatch.BackgroundColor3 = color
        swatch.BorderSizePixel = 0
        swatch.Text = ""
        swatch.AutoButtonColor = false
        swatch.Selectable = false
        swatch.LayoutOrder = index
        swatch.ZIndex = 2
        swatch.Parent = swatchHolder

        local swatchCorner = Instance.new("UICorner")
        swatchCorner.CornerRadius = UDim.new(1, 0)
        swatchCorner.Parent = swatch

        local swatchStroke = Instance.new("UIStroke")
        swatchStroke.Color = HUD_TEXT
        swatchStroke.Thickness = 2
        swatchStroke.Transparency = 1
        swatchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        swatchStroke.Parent = swatch

        swatches[#swatches + 1] = { color = color, stroke = swatchStroke }

        connections[#connections + 1] = swatch.Activated:Connect(function()
            hud:SetAccent(color)
        end)
    end

    local onlyRow = makeOptionRow("Só ativos", 1)

    local onlyButton = Instance.new("TextButton")
    onlyButton.Name = "OnlyActive"
    onlyButton.Size = UDim2.new(1, 0, 1, 0)
    onlyButton.BackgroundTransparency = 1
    onlyButton.Text = ""
    onlyButton.AutoButtonColor = false
    onlyButton.Selectable = false
    onlyButton.ZIndex = 1
    onlyButton.Parent = onlyRow

    local onlyTrack = Instance.new("Frame")
    onlyTrack.Name = "Track"
    onlyTrack.AnchorPoint = Vector2.new(1, 0.5)
    onlyTrack.Position = UDim2.new(1, 0, 0.5, 0)
    onlyTrack.Size = UDim2.new(0, 32, 0, 18)
    onlyTrack.BackgroundColor3 = HUD_OFF
    onlyTrack.BorderSizePixel = 0
    onlyTrack.ZIndex = 2
    onlyTrack.Parent = onlyRow

    local onlyTrackCorner = Instance.new("UICorner")
    onlyTrackCorner.CornerRadius = UDim.new(1, 0)
    onlyTrackCorner.Parent = onlyTrack

    local onlyKnob = Instance.new("Frame")
    onlyKnob.Name = "Knob"
    onlyKnob.AnchorPoint = Vector2.new(0, 0.5)
    onlyKnob.Position = UDim2.new(0, 3, 0.5, 0)
    onlyKnob.Size = UDim2.new(0, 12, 0, 12)
    onlyKnob.BackgroundColor3 = HUD_TEXT
    onlyKnob.BorderSizePixel = 0
    onlyKnob.ZIndex = 3
    onlyKnob.Parent = onlyTrack

    local onlyKnobCorner = Instance.new("UICorner")
    onlyKnobCorner.CornerRadius = UDim.new(1, 0)
    onlyKnobCorner.Parent = onlyKnob

    local resetButton = Instance.new("TextButton")
    resetButton.Name = "ResetPosition"
    resetButton.Size = UDim2.new(1, 0, 0, 26)
    resetButton.BackgroundColor3 = HUD_ROW
    resetButton.BackgroundTransparency = 0.3
    resetButton.BorderSizePixel = 0
    resetButton.Text = "Resetar posição"
    resetButton.TextColor3 = HUD_TEXT
    resetButton.TextSize = 12
    resetButton.Font = fontBold
    resetButton.AutoButtonColor = false
    resetButton.Selectable = false
    resetButton.LayoutOrder = 2
    resetButton.Parent = optionsBody

    local resetCorner = Instance.new("UICorner")
    resetCorner.CornerRadius = UDim.new(0, 7)
    resetCorner.Parent = resetButton

    local resetStroke = Instance.new("UIStroke")
    resetStroke.Color = HUD_BORDER
    resetStroke.Thickness = 1
    resetStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    resetStroke.Parent = resetButton

    -- Layout / Refresh
    local function refreshOptions()
        for _, swatch in ipairs(swatches) do
            swatch.stroke.Transparency = swatch.color == hud.accent and 0 or 1
        end

        play(onlyTrack, { BackgroundColor3 = hud.onlyActive and hud.accent or HUD_OFF }, true)
        play(onlyKnob, {
            Position = hud.onlyActive and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        }, true)

        for _, dotPart in ipairs(optionsDots) do
            dotPart.BackgroundColor3 = optionsFrame.Visible and hud.accent or HUD_SUB
        end
    end

    local function refresh()
        local total = 0
        local on = 0
        local shown = 0

        for entry in pairs(hud.entries) do
            local visible = false

            if entry.active then
                total = total + 1

                if entry.state then
                    on = on + 1
                end

                visible = not hud.onlyActive or entry.state == true

                if visible then
                    shown = shown + 1
                end
            end

            if entry.row then
                entry.row.Visible = visible
            end
        end

        countLabel.Text = on .. "/" .. total
        emptyLabel.Visible = total > 0 and shown == 0
        frame.Visible = total > 0 and not hud.closed
    end

    local function applyAccent()
        local accent = hud.accent

        frameGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, accent:Lerp(HUD_BG_TOP, 0.72)),
            ColorSequenceKeypoint.new(0.4, HUD_BG_TOP),
            ColorSequenceKeypoint.new(1, HUD_BG_BOTTOM),
        })
        strokeGradient.Color = ColorSequence.new(accent, HUD_BORDER)
        badgeGradient.Color = ColorSequence.new(accent, accent:Lerp(Color3.new(0, 0, 0), 0.35))
        dividerGradient.Color = ColorSequence.new(accent)
        countLabel.TextColor3 = accent:Lerp(Color3.new(1, 1, 1), 0.45)

        for entry in pairs(hud.entries) do
            entry:Restyle(false)
        end

        refreshOptions()
    end

    local function clampPosition(x, y)
        local camera = workspace.CurrentCamera

        if not camera then
            return x, y
        end

        local viewport = camera.ViewportSize
        local size = frame.AbsoluteSize

        x = math.clamp(x, 0, math.max(viewport.X - size.X, 0))
        y = math.clamp(y, 0, math.max(viewport.Y - size.Y, 0))

        return x, y
    end

    local function place()
        if userMoved then
            return
        end

        local camera = workspace.CurrentCamera

        if not camera then
            return
        end

        local viewport = camera.ViewportSize
        local size = frame.AbsoluteSize

        frame.Position = UDim2.new(0, HUD_MARGIN, 0, math.floor((viewport.Y - size.Y) / 2))
    end

    connections[#connections + 1] = frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)

    if workspace.CurrentCamera then
        connections[#connections + 1] = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(place)
    end

    -- Drag
    local dragging = false
    local dragStart
    local startX, startY = 0, 0

    connections[#connections + 1] = header.InputBegan:Connect(function(input)
        if not hud.draggable then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        dragging = true
        dragStart = input.Position
        startX = frame.AbsolutePosition.X
        startY = frame.AbsolutePosition.Y

        local changed
        changed = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false

                if changed then
                    changed:Disconnect()
                end
            end
        end)
    end)

    connections[#connections + 1] = userInputService.InputChanged:Connect(function(input)
        if not dragging or not dragStart then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - dragStart
        local x, y = clampPosition(startX + delta.X, startY + delta.Y)

        userMoved = true
        frame.Position = UDim2.new(0, x, 0, y)
    end)

    -- Buttons
    bindHover(closeBtn, function()
        for _, line in ipairs(closeLines) do
            line.BackgroundColor3 = HUD_CLOSE
        end
    end, function()
        for _, line in ipairs(closeLines) do
            line.BackgroundColor3 = HUD_SUB
        end
    end)

    bindHover(optionsBtn, function()
        for _, dotPart in ipairs(optionsDots) do
            dotPart.BackgroundColor3 = HUD_TEXT
        end
    end, function()
        refreshOptions()
    end)

    bindHover(resetButton, function()
        resetButton.BackgroundTransparency = 0.05
        resetStroke.Color = hud.accent
    end, function()
        resetButton.BackgroundTransparency = 0.3
        resetStroke.Color = HUD_BORDER
    end)

    connections[#connections + 1] = closeBtn.Activated:Connect(function()
        dragging = false
        hud.closed = true
        refresh()
    end)

    connections[#connections + 1] = optionsBtn.Activated:Connect(function()
        optionsFrame.Visible = not optionsFrame.Visible
        refreshOptions()
    end)

    connections[#connections + 1] = onlyButton.Activated:Connect(function()
        hud:SetOnlyActive(not hud.onlyActive)
    end)

    connections[#connections + 1] = resetButton.Activated:Connect(function()
        hud:ResetPosition()
    end)

    function hud:Add()
        hud.order = hud.order + 1

        local entry = {
            active = false,
            state = false,
        }

        local row = Instance.new("Frame")
        row.Name = "Row"
        row.Size = UDim2.new(1, 0, 0, HUD_ROW_H)
        row.BackgroundColor3 = HUD_ROW
        row.BackgroundTransparency = 0.5
        row.BorderSizePixel = 0
        row.LayoutOrder = hud.order
        row.Visible = false
        row.Parent = body

        entry.row = row

        local rowCorner = Instance.new("UICorner")
        rowCorner.CornerRadius = UDim.new(0, 8)
        rowCorner.Parent = row

        local rowStroke = Instance.new("UIStroke")
        rowStroke.Color = hud.accent
        rowStroke.Thickness = 1
        rowStroke.Transparency = 1
        rowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        rowStroke.Parent = row

        local dot = Instance.new("Frame")
        dot.Name = "Status"
        dot.Size = UDim2.new(0, 8, 0, 8)
        dot.AnchorPoint = Vector2.new(0, 0.5)
        dot.Position = UDim2.new(0, 11, 0.5, 0)
        dot.BackgroundColor3 = HUD_OFF
        dot.BorderSizePixel = 0
        dot.Parent = row

        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = dot

        local dotGlow = Instance.new("UIStroke")
        dotGlow.Color = HUD_ON
        dotGlow.Thickness = 3
        dotGlow.Transparency = 1
        dotGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        dotGlow.Parent = dot

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "Name"
        nameLabel.Position = UDim2.new(0, 28, 0, 0)
        nameLabel.Size = UDim2.new(1, -(28 + HUD_PILL_W + 14), 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = ""
        nameLabel.TextColor3 = HUD_DIM
        nameLabel.TextSize = 13
        nameLabel.Font = fontBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextYAlignment = Enum.TextYAlignment.Center
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Parent = row

        local keyLabel = Instance.new("TextLabel")
        keyLabel.Name = "Key"
        keyLabel.Size = UDim2.new(0, 0, 0, 22)
        keyLabel.AutomaticSize = Enum.AutomaticSize.X
        keyLabel.AnchorPoint = Vector2.new(1, 0.5)
        keyLabel.Position = UDim2.new(1, -8, 0.5, 0)
        keyLabel.BackgroundColor3 = Color3.new(1, 1, 1)
        keyLabel.BorderSizePixel = 0
        keyLabel.Text = ""
        keyLabel.TextColor3 = HUD_SUB
        keyLabel.TextSize = 11
        keyLabel.Font = fontBold
        keyLabel.TextXAlignment = Enum.TextXAlignment.Center
        keyLabel.TextYAlignment = Enum.TextYAlignment.Center
        keyLabel.TextTruncate = Enum.TextTruncate.AtEnd
        keyLabel.Parent = row

        local keyCorner = Instance.new("UICorner")
        keyCorner.CornerRadius = UDim.new(0, 6)
        keyCorner.Parent = keyLabel

        local keyGradient = Instance.new("UIGradient")
        keyGradient.Color = ColorSequence.new(Color3.fromRGB(108, 108, 124), Color3.fromRGB(80, 80, 96))
        keyGradient.Rotation = 90
        keyGradient.Parent = keyLabel

        local keyStroke = Instance.new("UIStroke")
        keyStroke.Color = Color3.fromRGB(132, 132, 150)
        keyStroke.Thickness = 1
        keyStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        keyStroke.Parent = keyLabel

        local keyPadding = Instance.new("UIPadding")
        keyPadding.PaddingLeft = UDim.new(0, 7)
        keyPadding.PaddingRight = UDim.new(0, 7)
        keyPadding.Parent = keyLabel

        local keySize = Instance.new("UISizeConstraint")
        keySize.MinSize = Vector2.new(24, 22)
        keySize.MaxSize = Vector2.new(HUD_PILL_W, 22)
        keySize.Parent = keyLabel

        local function style(animate)
            local on = entry.state
            local accent = hud.accent

            play(row, {
                BackgroundColor3 = on and accent:Lerp(HUD_BG_BOTTOM, 0.7) or HUD_ROW,
                BackgroundTransparency = on and 0.1 or 0.5
            }, animate)
            play(rowStroke, { Color = accent, Transparency = on and 0.45 or 1 }, animate)
            play(dot, { BackgroundColor3 = on and HUD_ON or HUD_OFF }, animate)
            play(dotGlow, { Transparency = on and 0.55 or 1 }, animate)
            play(nameLabel, { TextColor3 = on and HUD_TEXT or HUD_DIM }, animate)
            play(keyLabel, { TextColor3 = on and HUD_TEXT or HUD_SUB }, animate)
        end

        function entry:Restyle(animate)
            style(animate)
        end

        function entry:Update(title, keyText, state)
            local animate = row.Visible

            nameLabel.Text = tostring(title or "")

            if keyText then
                keyLabel.Text = tostring(keyText)
                entry.active = true
            else
                entry.active = false
            end

            entry.state = state == true
            style(animate)
            refresh()
        end

        function entry:Remove()
            hud.entries[entry] = nil
            row:Destroy()
            refresh()
        end

        hud.entries[entry] = true

        return entry
    end

    function hud:SetAccent(color)
        if typeof(color) ~= "Color3" then
            return
        end

        hud.accent = color
        applyAccent()
    end

    function hud:SetOnlyActive(value)
        hud.onlyActive = value == true
        refresh()
        refreshOptions()
    end

    function hud:SetTransparency(value)
        frame.BackgroundTransparency = math.clamp(tonumber(value) or 0.02, 0, 0.9)
    end

    function hud:SetDraggable(value)
        hud.draggable = value ~= false
    end

    function hud:ResetPosition()
        userMoved = false
        place()
    end

    function hud:Configure(settings)
        if type(settings) ~= "table" then
            return
        end

        if settings.Accent ~= nil then
            hud:SetAccent(settings.Accent)
        end

        if settings.OnlyActive ~= nil then
            hud:SetOnlyActive(settings.OnlyActive)
        end

        if settings.Transparency ~= nil then
            hud:SetTransparency(settings.Transparency)
        end

        if settings.Draggable ~= nil then
            hud:SetDraggable(settings.Draggable)
        end
    end

    function hud:Show()
        hud.closed = false
        refresh()
    end

    function hud:Hide()
        hud.closed = true
        refresh()
    end

    function hud:Toggle()
        hud.closed = not hud.closed
        refresh()
    end

    function hud:Destroy()
        if env.EcoHubKeybindHud == hud then
            env.EcoHubKeybindHud = nil
        end

        for _, conn in ipairs(connections) do
            conn:Disconnect()
        end

        table.clear(connections)
        gui:Destroy()
    end

    applyAccent()

    return hud
end

local function getKeybindHud()
    if keybindHud and keybindHud.gui and keybindHud.gui.Parent then
        return keybindHud
    end

    if env.EcoHubKeybindHud then
        pcall(function()
            env.EcoHubKeybindHud:Destroy()
        end)

        env.EcoHubKeybindHud = nil
    end

    keybindHud = createKeybindHud()
    env.EcoHubKeybindHud = keybindHud

    return keybindHud
end

local function showKeybindHud()
    local hud = getKeybindHud()

    if hud then
        hud:Show()
    end
end

-- // Checkbox
Elements.Register("Checkbox", function(section, options)
    options = type(options) == "table" and options or {}

    local TITLE_SIZE = 13
    local DESC_SIZE = 11
    local KEY_SIZE = 11
    local SWITCH_W = 36
    local SWITCH_H = 20
    local KNOB = 14
    local KNOB_PAD = 3
    local SIDE_PAD = 0
    local PILL_W = 40
    local PILL_H = 20
    local BASE_H = 30

    local Colors, watchTheme = createColors(section.Panel or Panel)
    local fontBold, fontRegular = getFonts()
    local isDesktop = userInputService.KeyboardEnabled

    local connections = {}
    local destroyed = false
    local listeningConnection
    local listenStartedAt = 0
    local unwatchTheme

    local function connect(signal, fn)
        local conn = signal:Connect(fn)
        connections[#connections + 1] = conn
        return conn
    end

    local title = tostring(options.title or options.Name or "Checkbox")
    local emojiIcon = tostring(options.emoji or options.Emoji or "")
    local description = tostring(options.description or "")
    local default = (options.default or options.Default) == true
    local disabled = options.disabled == true
    local callback = options.callback or options.Callback
    local keybind = normalizeBinding(options.keybind)
    local keybindCb = options.keybindCallback

    if type(callback) ~= "function" then
        callback = function() end
    end

    if type(keybindCb) ~= "function" then
        keybindCb = nil
    end

    if keybind ~= nil and not isValidBinding(keybind) then
        keybind = nil
    end

    local hasKeybind = options.keybind ~= nil and options.keybind ~= false and isDesktop

    local data = {
        state = default,
        disabled = disabled,
        keybind = keybind,
        listening = false,
    }

    local function buildTitle()
        local text = Emoji.Parse(title)
        local icon = Emoji.Parse(emojiIcon)

        if icon ~= "" then
            return icon .. " " .. text
        end

        return text
    end

    local hudEntry

    if hasKeybind then
        local hud = getKeybindHud()

        if hud then
            hudEntry = hud:Add()
        end
    end

    local function syncHud()
        if not hudEntry then
            return
        end

        hudEntry:Update(buildTitle(), data.keybind and getKeyName(data.keybind) or nil, data.state)
    end

    local rightReserve = SWITCH_W + SIDE_PAD + 10

    if hasKeybind then
        rightReserve = rightReserve + PILL_W + 8
    end

    local container = Instance.new("Frame")
    container.Name = title .. "_Checkbox"
    container.Size = UDim2.new(1, 0, 0, BASE_H)
    container.BackgroundTransparency = 1
    container.Parent = section.frame

    local rowButton = Instance.new("TextButton")
    rowButton.Name = "RowButton"
    rowButton.Size = UDim2.new(1, 0, 1, 0)
    rowButton.BackgroundTransparency = 1
    rowButton.Text = ""
    rowButton.AutoButtonColor = false
    rowButton.Selectable = false
    rowButton.ZIndex = 1
    rowButton.Parent = container

    local textFrame = Instance.new("Frame")
    textFrame.Name = "TextFrame"
    textFrame.Size = UDim2.new(1, -rightReserve, 1, 0)
    textFrame.BackgroundTransparency = 1
    textFrame.ZIndex = 2
    textFrame.Parent = container

    local textLayout = Instance.new("UIListLayout")
    textLayout.FillDirection = Enum.FillDirection.Vertical
    textLayout.SortOrder = Enum.SortOrder.LayoutOrder
    textLayout.Padding = UDim.new(0, 1)
    textLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    textLayout.Parent = textFrame

    local label = Instance.new("TextLabel")
    label.Name = "Title"
    label.Size = UDim2.new(1, 0, 0, TITLE_SIZE + 3)
    label.BackgroundTransparency = 1
    label.Text = buildTitle()
    label.TextColor3 = Colors.Active
    label.TextSize = TITLE_SIZE
    label.Font = fontBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.LayoutOrder = 0
    label.ZIndex = 2
    label.Parent = textFrame

    local descLabel

    local function createDescription(text)
        descLabel = Instance.new("TextLabel")
        descLabel.Name = "Description"
        descLabel.Size = UDim2.new(1, 0, 0, 0)
        descLabel.AutomaticSize = Enum.AutomaticSize.Y
        descLabel.BackgroundTransparency = 1
        descLabel.Text = breakLongWords(text, WORD_MAX)
        descLabel.TextColor3 = Colors.Dim
        descLabel.TextSize = DESC_SIZE
        descLabel.Font = fontRegular
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextYAlignment = Enum.TextYAlignment.Top
        descLabel.TextWrapped = true
        descLabel.LineHeight = 1.1
        descLabel.LayoutOrder = 1
        descLabel.ZIndex = 2
        descLabel.Parent = textFrame
    end

    local function knobPosition(state)
        if state then
            return UDim2.new(1, -(KNOB + KNOB_PAD), 0.5, 0)
        end

        return UDim2.new(0, KNOB_PAD, 0.5, 0)
    end

    local track = Instance.new("Frame")
    track.Name = "Switch"
    track.Size = UDim2.new(0, SWITCH_W, 0, SWITCH_H)
    track.Position = UDim2.new(1, -SIDE_PAD, 0.5, 0)
    track.AnchorPoint = Vector2.new(1, 0.5)
    track.BackgroundColor3 = default and Colors.Active or Colors.Border
    track.BorderSizePixel = 0
    track.ZIndex = 3
    track.Parent = container

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.new(0, KNOB, 0, KNOB)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Position = knobPosition(default)
    knob.BackgroundColor3 = default and Colors.Background or Colors.Active
    knob.BorderSizePixel = 0
    knob.ZIndex = 4
    knob.Parent = track

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local keyBtn
    local keyLabel
    local keyStroke

    if hasKeybind then
        keyBtn = Instance.new("TextButton")
        keyBtn.Name = "KeyBind"
        keyBtn.Size = UDim2.new(0, PILL_W, 0, PILL_H)
        keyBtn.AnchorPoint = Vector2.new(1, 0.5)
        keyBtn.Position = UDim2.new(1, -(SWITCH_W + SIDE_PAD + 8), 0.5, 0)
        keyBtn.BackgroundColor3 = Colors.Palette
        keyBtn.BorderSizePixel = 0
        keyBtn.Text = ""
        keyBtn.AutoButtonColor = false
        keyBtn.Selectable = false
        keyBtn.ClipsDescendants = true
        keyBtn.ZIndex = 3
        keyBtn.Parent = container

        local keyCorner = Instance.new("UICorner")
        keyCorner.CornerRadius = UDim.new(0, 5)
        keyCorner.Parent = keyBtn

        keyStroke = Instance.new("UIStroke")
        keyStroke.Color = Colors.Border
        keyStroke.Thickness = 1
        keyStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        keyStroke.Parent = keyBtn

        keyLabel = Instance.new("TextLabel")
        keyLabel.Name = "KeyLabel"
        keyLabel.Size = UDim2.new(1, 0, 1, 0)
        keyLabel.BackgroundTransparency = 1
        keyLabel.Text = getKeyName(data.keybind)
        keyLabel.TextColor3 = Colors.Inactive
        keyLabel.TextSize = KEY_SIZE
        keyLabel.Font = fontBold
        keyLabel.TextXAlignment = Enum.TextXAlignment.Center
        keyLabel.TextYAlignment = Enum.TextYAlignment.Center
        keyLabel.TextWrapped = false
        keyLabel.TextTruncate = Enum.TextTruncate.AtEnd
        keyLabel.ZIndex = 4
        keyLabel.Parent = keyBtn
    end

    local function resizeContainer()
        if destroyed then
            return
        end

        if not descLabel then
            container.Size = UDim2.new(1, 0, 0, BASE_H)
            return
        end

        container.Size = UDim2.new(1, 0, 0, math.max(textLayout.AbsoluteContentSize.Y + 10, BASE_H))
    end

    local function updateVisuals(animate)
        if destroyed then
            return
        end

        local trackColor = data.state and Colors.Active or Colors.Border
        local knobColor = data.state and Colors.Background or Colors.Active

        if data.disabled then
            trackColor = Colors.GradientTop
            knobColor = Colors.BorderHover
        end

        play(track, { BackgroundColor3 = trackColor }, animate)
        play(knob, {
            BackgroundColor3 = knobColor,
            Position = knobPosition(data.state)
        }, animate)

        rowButton.Active = not data.disabled

        syncHud()
    end

    local function fireCallback(value)
        local ok, err = pcall(callback, value)

        if not ok then
            notify(("Checkbox '%s': %s"):format(title, tostring(err)), 5)
        end
    end

    local function fireKeybindCallback(value)
        if not keybindCb then
            return
        end

        local ok, err = pcall(keybindCb, value)

        if not ok then
            notify(("Checkbox '%s' (keybind): %s"):format(title, tostring(err)), 5)
        end
    end

    local function toggle()
        if destroyed or data.disabled then
            return
        end

        data.state = not data.state
        updateVisuals(true)
        fireCallback(data.state)
    end

    local function resetKeyVisual()
        if not keyBtn then
            return
        end

        keyBtn.BackgroundColor3 = Colors.Palette
        keyStroke.Color = Colors.Border
        keyLabel.Text = getKeyName(data.keybind)
        keyLabel.TextColor3 = Colors.Inactive
    end

    local function stopListening()
        if listeningConnection then
            listeningConnection:Disconnect()
            listeningConnection = nil
        end

        if data.listening then
            env.EcoHubBinding = nil
        end

        data.listening = false
        resetKeyVisual()
        syncHud()
    end

    local function enterListenMode()
        if destroyed or not hasKeybind or data.disabled or data.listening then
            return
        end

        if env.EcoHubBinding then
            return
        end

        data.listening = true
        env.EcoHubBinding = true
        listenStartedAt = os.clock()

        keyBtn.BackgroundColor3 = Colors.Accent
        keyStroke.Color = Colors.Active
        keyLabel.Text = "..."
        keyLabel.TextColor3 = Colors.Active

        listeningConnection = userInputService.InputBegan:Connect(function(input)
            if destroyed or not data.listening then
                return
            end

            if os.clock() - listenStartedAt < 0.15 then
                return
            end

            local newBind

            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.MouseButton2
            or input.UserInputType == Enum.UserInputType.MouseButton3 then
                newBind = input.UserInputType
            elseif input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.Escape then
                    data.keybind = nil
                    stopListening()
                    notify(("Keybind de '%s' removida."):format(title), 3)
                    return
                end

                newBind = input.KeyCode
            end

            if newBind then
                data.keybind = newBind
                stopListening()
                showKeybindHud()
                notify(("'%s' -> %s"):format(title, getKeyName(newBind)), 3)
            end
        end)
    end

    local function applyTheme()
        if destroyed then
            return
        end

        label.TextColor3 = Colors.Active

        if descLabel then
            descLabel.TextColor3 = Colors.Dim
        end

        updateVisuals(false)

        if keyBtn then
            if data.listening then
                keyBtn.BackgroundColor3 = Colors.Accent
                keyStroke.Color = Colors.Active
                keyLabel.TextColor3 = Colors.Active
            else
                resetKeyVisual()
            end
        end
    end

    if hasKeybind then
        connect(userInputService.InputBegan, function(input, gp)
            if destroyed or gp or data.disabled or data.listening then
                return
            end

            if env.EcoHubBinding then
                return
            end

            if not data.keybind then
                return
            end

            if matchInput(data.keybind, input) then
                toggle()
                fireKeybindCallback(data.state)
            end
        end)

        connect(keyBtn.Activated, enterListenMode)
    end

    connect(rowButton.Activated, toggle)
    connect(textLayout:GetPropertyChangedSignal("AbsoluteContentSize"), resizeContainer)

    if description ~= "" then
        createDescription(description)
    end

    resizeContainer()
    updateVisuals(false)
    syncHud()

    if default then
        fireCallback(default)
    end

    function data:Set(value)
        if destroyed then
            return
        end

        value = value == true

        if data.state == value then
            return
        end

        data.state = value
        updateVisuals(true)
        fireCallback(value)
    end

    function data:Get()
        return data.state
    end

    function data:Toggle()
        toggle()
    end

    function data:SetDisabled(value)
        if destroyed then
            return
        end

        data.disabled = value == true

        if data.disabled and data.listening then
            stopListening()
        end

        updateVisuals(true)
    end

    function data:SetTitle(newTitle)
        if destroyed then
            return
        end

        title = tostring(newTitle or "")
        label.Text = buildTitle()
        syncHud()
    end

    function data:SetEmoji(value)
        if destroyed then
            return
        end

        emojiIcon = tostring(value or "")
        label.Text = buildTitle()
        syncHud()
    end

    function data:GetEmoji()
        return emojiIcon
    end

    function data:SetDescription(newDesc)
        if destroyed then
            return
        end

        newDesc = tostring(newDesc or "")

        if newDesc == "" then
            if descLabel then
                descLabel:Destroy()
                descLabel = nil
            end

            resizeContainer()
            return
        end

        if not descLabel then
            createDescription(newDesc)
        else
            descLabel.Text = breakLongWords(newDesc, WORD_MAX)
        end

        resizeContainer()
    end

    function data:SetKeybind(newBind)
        if destroyed then
            return
        end

        newBind = normalizeBinding(newBind)

        if newBind ~= nil and not isValidBinding(newBind) then
            notify(("Checkbox '%s': keybind inválida."):format(title), 5)
            return
        end

        data.keybind = newBind

        if data.listening then
            stopListening()
        elseif keyLabel then
            keyLabel.Text = getKeyName(newBind)
        end

        syncHud()
    end

    function data:GetKeybind()
        return data.keybind
    end

    function data:ClearKeybind()
        if destroyed then
            return
        end

        data.keybind = nil

        if data.listening then
            stopListening()
        elseif keyLabel then
            keyLabel.Text = "None"
        end

        syncHud()
    end

    function data:Destroy()
        if destroyed then
            return
        end

        destroyed = true

        if data.listening then
            env.EcoHubBinding = nil
            data.listening = false
        end

        if listeningConnection then
            listeningConnection:Disconnect()
            listeningConnection = nil
        end

        if unwatchTheme then
            unwatchTheme()
            unwatchTheme = nil
        end

        if hudEntry then
            hudEntry:Remove()
            hudEntry = nil
        end

        for _, conn in ipairs(connections) do
            conn:Disconnect()
        end

        table.clear(connections)
        container:Destroy()
    end

    unwatchTheme = watchTheme(applyTheme)

    return data
end)