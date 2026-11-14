-- // Services
local userInputService = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")
local guiService = game:GetService("GuiService")
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
local KEY_ALIASES = {
    { "KeyCode", "LeftShift", "LShift" },
    { "KeyCode", "RightShift", "RShift" },
    { "KeyCode", "LeftControl", "LCtrl" },
    { "KeyCode", "RightControl", "RCtrl" },
    { "KeyCode", "LeftAlt", "LAlt" },
    { "KeyCode", "RightAlt", "RAlt" },
    { "KeyCode", "LeftMeta", "LMeta" },
    { "KeyCode", "RightMeta", "RMeta" },
    { "KeyCode", "LeftSuper", "LWin" },
    { "KeyCode", "RightSuper", "RWin" },
    { "KeyCode", "CapsLock", "Caps" },
    { "KeyCode", "Return", "Enter" },
    { "KeyCode", "Backspace", "Back" },
    { "KeyCode", "Delete", "Del" },
    { "KeyCode", "Insert", "Ins" },
    { "KeyCode", "PageUp", "PgUp" },
    { "KeyCode", "PageDown", "PgDn" },
    { "KeyCode", "Escape", "Esc" },
    { "KeyCode", "Space", "Space" },
    { "KeyCode", "Tab", "Tab" },
    { "KeyCode", "Home", "Home" },
    { "KeyCode", "End", "End" },
    { "KeyCode", "Up", "Up" },
    { "KeyCode", "Down", "Down" },
    { "KeyCode", "Left", "Left" },
    { "KeyCode", "Right", "Right" },
    { "KeyCode", "NumLock", "NumLk" },
    { "KeyCode", "ScrollLock", "ScrLk" },
    { "KeyCode", "Print", "Print" },
    { "KeyCode", "Pause", "Pause" },
    { "KeyCode", "Backquote", "`" },
    { "KeyCode", "Tilde", "~" },
    { "KeyCode", "Minus", "-" },
    { "KeyCode", "Equals", "=" },
    { "KeyCode", "LeftBracket", "[" },
    { "KeyCode", "RightBracket", "]" },
    { "KeyCode", "BackSlash", "\\" },
    { "KeyCode", "Semicolon", ";" },
    { "KeyCode", "Quote", "'" },
    { "KeyCode", "Comma", "," },
    { "KeyCode", "Period", "." },
    { "KeyCode", "Slash", "/" },
    { "KeyCode", "Zero", "0" },
    { "KeyCode", "One", "1" },
    { "KeyCode", "Two", "2" },
    { "KeyCode", "Three", "3" },
    { "KeyCode", "Four", "4" },
    { "KeyCode", "Five", "5" },
    { "KeyCode", "Six", "6" },
    { "KeyCode", "Seven", "7" },
    { "KeyCode", "Eight", "8" },
    { "KeyCode", "Nine", "9" },
    { "KeyCode", "KeypadZero", "Num0" },
    { "KeyCode", "KeypadOne", "Num1" },
    { "KeyCode", "KeypadTwo", "Num2" },
    { "KeyCode", "KeypadThree", "Num3" },
    { "KeyCode", "KeypadFour", "Num4" },
    { "KeyCode", "KeypadFive", "Num5" },
    { "KeyCode", "KeypadSix", "Num6" },
    { "KeyCode", "KeypadSeven", "Num7" },
    { "KeyCode", "KeypadEight", "Num8" },
    { "KeyCode", "KeypadNine", "Num9" },
    { "KeyCode", "KeypadPeriod", "Num." },
    { "KeyCode", "KeypadPlus", "Num+" },
    { "KeyCode", "KeypadMinus", "Num-" },
    { "KeyCode", "KeypadMultiply", "Num*" },
    { "KeyCode", "KeypadDivide", "Num/" },
    { "KeyCode", "KeypadEquals", "Num=" },
    { "KeyCode", "KeypadEnter", "NumEnt" },
    { "KeyCode", "ButtonA", "PadA" },
    { "KeyCode", "ButtonB", "PadB" },
    { "KeyCode", "ButtonX", "PadX" },
    { "KeyCode", "ButtonY", "PadY" },
    { "KeyCode", "ButtonL1", "L1" },
    { "KeyCode", "ButtonR1", "R1" },
    { "KeyCode", "ButtonL2", "L2" },
    { "KeyCode", "ButtonR2", "R2" },
    { "KeyCode", "ButtonL3", "L3" },
    { "KeyCode", "ButtonR3", "R3" },
    { "KeyCode", "ButtonStart", "Start" },
    { "KeyCode", "ButtonSelect", "Select" },
    { "KeyCode", "DPadUp", "DUp" },
    { "KeyCode", "DPadDown", "DDown" },
    { "KeyCode", "DPadLeft", "DLeft" },
    { "KeyCode", "DPadRight", "DRight" },
    { "UserInputType", "MouseButton1", "M1" },
    { "UserInputType", "MouseButton2", "M2" },
    { "UserInputType", "MouseButton3", "M3" },
}

local WHEEL_UP = { Kind = "Wheel", Name = "WheelUp", Direction = 1 }
local WHEEL_DOWN = { Kind = "Wheel", Name = "WheelDown", Direction = -1 }

local KEY_NAMES = {
    [WHEEL_UP] = "WhUp",
    [WHEEL_DOWN] = "WhDn",
}

local KEY_LOOKUP = {
    whup = WHEEL_UP,
    wheelup = WHEEL_UP,
    whdn = WHEEL_DOWN,
    wheeldown = WHEEL_DOWN,
}

for _, alias in ipairs(KEY_ALIASES) do
    local ok, item = pcall(function()
        return Enum[alias[1]][alias[2]]
    end)

    if ok and item then
        KEY_NAMES[item] = alias[3]
        KEY_LOOKUP[alias[3]:lower()] = item
    end
end

local function isWheel(binding)
    return binding == WHEEL_UP or binding == WHEEL_DOWN
end

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
    if isWheel(binding) then
        return true
    end

    if typeof(binding) ~= "EnumItem" then
        return false
    end

    return binding.EnumType == Enum.KeyCode or binding.EnumType == Enum.UserInputType
end

local function normalizeBinding(binding)
    if isWheel(binding) then
        return binding
    end

    if typeof(binding) == "EnumItem" then
        return binding
    end

    if type(binding) == "string" and binding ~= "" then
        local alias = KEY_LOOKUP[binding:lower()]

        if alias then
            return alias
        end

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
    if isWheel(binding) then
        if input.UserInputType ~= Enum.UserInputType.MouseWheel then
            return false
        end

        local z = input.Position.Z

        return z ~= 0 and (z > 0) == (binding.Direction > 0)
    end

    if typeof(binding) ~= "EnumItem" then
        return false
    end

    if binding.EnumType == Enum.KeyCode then
        return binding ~= Enum.KeyCode.Unknown and input.KeyCode == binding
    elseif binding.EnumType == Enum.UserInputType then
        return input.UserInputType == binding
    end

    return false
end

-- // KeybindHud
local HUD_WIDTH = 190
local HUD_TOP_H = 40
local HUD_ROW_H = 28
local HUD_PILL_W = 52
local HUD_MARGIN = 12
local HUD_PAD = 6
local HUD_GAP = 4
local HUD_CARD_H = 40
local HUD_BUTTON_H = 30
local HUD_CARD_GAP = 6
local HUD_SETTINGS_H = HUD_TOP_H + 1 + HUD_PAD + (HUD_CARD_H * 2) + HUD_BUTTON_H + (HUD_CARD_GAP * 2) + HUD_PAD

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

    local fontBold, fontRegular = getFonts()

    local settings = env.EcoHubHudSettings

    if type(settings) ~= "table" then
        settings = {
            neverShow = false,
            draggable = true,
        }

        env.EcoHubHudSettings = settings
    end

    local hud = {
        closed = false,
        entries = {},
        order = 0,
        draggable = settings.draggable ~= false,
    }

    local connections = {}
    local userMoved = false
    local settingsOpen = false
    local curX, curY = HUD_MARGIN, HUD_MARGIN
    local frameH = 0
    local dragging = false
    local dragInput
    local dragConnection
    local setDragToggle
    local setNeverToggle

    local function stopDrag()
        dragging = false
        dragInput = nil

        if dragConnection then
            dragConnection:Disconnect()
            dragConnection = nil
        end
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
    frame.Position = UDim2.new(0, HUD_MARGIN, 0, HUD_MARGIN)
    frame.Size = UDim2.new(0, HUD_WIDTH, 0, 0)
    frame.BackgroundColor3 = Default.Background
    frame.BackgroundTransparency = 0.08
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = gui

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 8)
    frameCorner.Parent = frame

    local frameStroke = Instance.new("UIStroke")
    frameStroke.Color = Default.Border
    frameStroke.Thickness = 1
    frameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    frameStroke.Parent = frame

    local listView = Instance.new("Frame")
    listView.Name = "List"
    listView.Size = UDim2.new(1, 0, 1, 0)
    listView.BackgroundTransparency = 1
    listView.Parent = frame

    local settingsView = Instance.new("Frame")
    settingsView.Name = "Settings"
    settingsView.Size = UDim2.new(1, 0, 1, 0)
    settingsView.BackgroundTransparency = 1
    settingsView.Visible = false
    settingsView.Parent = frame

    local dragHandle = Instance.new("TextButton")
    dragHandle.Name = "DragHandle"
    dragHandle.Size = UDim2.new(1, -56, 0, HUD_TOP_H)
    dragHandle.BackgroundTransparency = 1
    dragHandle.Text = ""
    dragHandle.AutoButtonColor = false
    dragHandle.Selectable = false
    dragHandle.Parent = frame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Position = UDim2.new(0, HUD_PAD, 0, 5)
    titleLabel.Size = UDim2.new(1, -(HUD_PAD + 56), 0, 18)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Key Bind"
    titleLabel.TextColor3 = Default.Active
    titleLabel.TextSize = 14
    titleLabel.Font = fontBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    titleLabel.TextStrokeTransparency = 0.55
    titleLabel.ZIndex = 2
    titleLabel.Parent = frame

    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Name = "Subtitle"
    subtitleLabel.Position = UDim2.new(0, HUD_PAD, 0, 22)
    subtitleLabel.Size = UDim2.new(1, -(HUD_PAD + 56), 0, 14)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = "by rip_sheldoohz"
    subtitleLabel.TextColor3 = Default.Inactive
    subtitleLabel.TextSize = 11
    subtitleLabel.Font = fontRegular
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    subtitleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    subtitleLabel.TextStrokeTransparency = 0.55
    subtitleLabel.ZIndex = 2
    subtitleLabel.Parent = frame

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 22, 0, 22)
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.Position = UDim2.new(1, -4, 0, math.floor((HUD_TOP_H - 22) / 2))
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = ""
    closeBtn.AutoButtonColor = false
    closeBtn.Selectable = false
    closeBtn.ZIndex = 2
    closeBtn.Parent = frame

    local closeLines = {}

    for _, rotation in ipairs({ 45, -45 }) do
        local line = Instance.new("Frame")
        line.Name = "Line"
        line.Size = UDim2.new(0, 11, 0, 2)
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.Position = UDim2.new(0.5, 0, 0.5, 0)
        line.Rotation = rotation
        line.BackgroundColor3 = Default.Inactive
        line.BorderSizePixel = 0
        line.ZIndex = 3
        line.Parent = closeBtn

        local lineCorner = Instance.new("UICorner")
        lineCorner.CornerRadius = UDim.new(1, 0)
        lineCorner.Parent = line

        closeLines[#closeLines + 1] = line
    end

    local settingsBtn = Instance.new("TextButton")
    settingsBtn.Name = "SettingsButton"
    settingsBtn.Size = UDim2.new(0, 22, 0, 22)
    settingsBtn.AnchorPoint = Vector2.new(1, 0)
    settingsBtn.Position = UDim2.new(1, -30, 0, math.floor((HUD_TOP_H - 22) / 2))
    settingsBtn.BackgroundTransparency = 1
    settingsBtn.Text = ""
    settingsBtn.AutoButtonColor = false
    settingsBtn.Selectable = false
    settingsBtn.ZIndex = 2
    settingsBtn.Parent = frame

    local gearParts = {}

    for _, rotation in ipairs({ 0, 45, 90, 135 }) do
        local tooth = Instance.new("Frame")
        tooth.Name = "Tooth"
        tooth.Size = UDim2.new(0, 3, 0, 15)
        tooth.AnchorPoint = Vector2.new(0.5, 0.5)
        tooth.Position = UDim2.new(0.5, 0, 0.5, 0)
        tooth.Rotation = rotation
        tooth.BackgroundColor3 = Default.Inactive
        tooth.BorderSizePixel = 0
        tooth.ZIndex = 3
        tooth.Parent = settingsBtn

        local toothCorner = Instance.new("UICorner")
        toothCorner.CornerRadius = UDim.new(0, 1)
        toothCorner.Parent = tooth

        gearParts[#gearParts + 1] = tooth
    end

    local gearDisc = Instance.new("Frame")
    gearDisc.Name = "Disc"
    gearDisc.Size = UDim2.new(0, 11, 0, 11)
    gearDisc.AnchorPoint = Vector2.new(0.5, 0.5)
    gearDisc.Position = UDim2.new(0.5, 0, 0.5, 0)
    gearDisc.BackgroundColor3 = Default.Inactive
    gearDisc.BorderSizePixel = 0
    gearDisc.ZIndex = 4
    gearDisc.Parent = settingsBtn

    local gearDiscCorner = Instance.new("UICorner")
    gearDiscCorner.CornerRadius = UDim.new(1, 0)
    gearDiscCorner.Parent = gearDisc

    gearParts[#gearParts + 1] = gearDisc

    local gearHole = Instance.new("Frame")
    gearHole.Name = "Hole"
    gearHole.Size = UDim2.new(0, 5, 0, 5)
    gearHole.AnchorPoint = Vector2.new(0.5, 0.5)
    gearHole.Position = UDim2.new(0.5, 0, 0.5, 0)
    gearHole.BackgroundColor3 = Default.Background
    gearHole.BorderSizePixel = 0
    gearHole.ZIndex = 5
    gearHole.Parent = settingsBtn

    local gearHoleCorner = Instance.new("UICorner")
    gearHoleCorner.CornerRadius = UDim.new(1, 0)
    gearHoleCorner.Parent = gearHole

    local backBtn = Instance.new("TextButton")
    backBtn.Name = "Back"
    backBtn.Size = UDim2.new(0, 22, 0, 22)
    backBtn.AnchorPoint = Vector2.new(1, 0)
    backBtn.Position = UDim2.new(1, -30, 0, math.floor((HUD_TOP_H - 22) / 2))
    backBtn.BackgroundTransparency = 1
    backBtn.Text = ""
    backBtn.AutoButtonColor = false
    backBtn.Selectable = false
    backBtn.Visible = false
    backBtn.ZIndex = 2
    backBtn.Parent = frame

    local backParts = {}

    for _, rotation in ipairs({ -45, 45 }) do
        local arm = Instance.new("Frame")
        arm.Name = "Arm"
        arm.Size = UDim2.new(0, 9, 0, 2)
        arm.AnchorPoint = Vector2.new(0.5, 0.5)
        arm.Position = UDim2.new(0.5, -1, 0.5, rotation < 0 and -3 or 3)
        arm.Rotation = rotation
        arm.BackgroundColor3 = Default.Inactive
        arm.BorderSizePixel = 0
        arm.ZIndex = 3
        arm.Parent = backBtn

        local armCorner = Instance.new("UICorner")
        armCorner.CornerRadius = UDim.new(1, 0)
        armCorner.Parent = arm

        backParts[#backParts + 1] = arm
    end

    local function styleIconButton(button, parts, holes)
        holes = holes or {}

        button.BackgroundColor3 = Default.Accent

        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 5)
        buttonCorner.Parent = button

        local function setHover(on, animate)
            play(button, { BackgroundTransparency = on and 0 or 1 }, animate)

            for _, part in ipairs(parts) do
                part.BackgroundColor3 = on and Default.Active or Default.Inactive
            end

            for _, hole in ipairs(holes) do
                hole.BackgroundColor3 = on and Default.Accent or Default.Background
            end
        end

        connections[#connections + 1] = button.MouseEnter:Connect(function()
            setHover(true, true)
        end)

        connections[#connections + 1] = button.MouseLeave:Connect(function()
            setHover(false, true)
        end)

        return function()
            setHover(false, false)
        end
    end

    styleIconButton(closeBtn, closeLines)

    local resetSettingsHover = styleIconButton(settingsBtn, gearParts, { gearHole })
    local resetBackHover = styleIconButton(backBtn, backParts)

    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.Position = UDim2.new(0, HUD_PAD, 0, HUD_TOP_H)
    divider.Size = UDim2.new(1, -(HUD_PAD * 2), 0, 1)
    divider.BackgroundColor3 = Default.Border
    divider.BackgroundTransparency = 0.3
    divider.BorderSizePixel = 0
    divider.Parent = frame

    local function getScreen()
        local size = gui.AbsoluteSize

        if size.X <= 0 or size.Y <= 0 then
            local camera = workspace.CurrentCamera

            if camera then
                return camera.ViewportSize
            end
        end

        return size
    end

    local function clampPosition(x, y)
        local screen = getScreen()

        x = math.clamp(x, 0, math.max(screen.X - HUD_WIDTH, 0))
        y = math.clamp(y, 0, math.max(screen.Y - frameH, 0))

        return x, y
    end

    local function applyPosition(x, y)
        curX, curY = x, y
        frame.Position = UDim2.new(0, x, 0, y)
    end

    local function settle()
        if userMoved then
            applyPosition(clampPosition(curX, curY))
        else
            local screen = getScreen()

            applyPosition(HUD_MARGIN, math.floor((screen.Y - frameH) / 2))
        end
    end

    local function layout()
        local list = {}

        for entry in pairs(hud.entries) do
            entry.row.Visible = false

            if entry.active == true and entry.state == true then
                list[#list + 1] = entry
            end
        end

        table.sort(list, function(a, b)
            return a.order < b.order
        end)

        local y = HUD_TOP_H + 1 + HUD_PAD

        for _, entry in ipairs(list) do
            entry.row.Position = UDim2.new(0, 0, 0, y)
            entry.row.Visible = true
            y = y + HUD_ROW_H + HUD_GAP
        end

        local listH = 0

        if #list > 0 then
            listH = y - HUD_GAP + HUD_PAD
        end

        frameH = settingsOpen and HUD_SETTINGS_H or listH

        frame.Size = UDim2.new(0, HUD_WIDTH, 0, frameH)
        settle()

        local show = not hud.closed and not settings.neverShow and (settingsOpen or #list > 0)

        frame.Visible = show

        if not show then
            stopDrag()
        end
    end

    local function setView(open)
        settingsOpen = open == true

        titleLabel.Text = settingsOpen and "Configurações" or "Key Bind"
        subtitleLabel.Text = settingsOpen and "Painel de Key Bind" or "by rip_sheldoohz"
        backBtn.Visible = settingsOpen
        settingsBtn.Visible = not settingsOpen
        resetSettingsHover()
        resetBackHover()
        listView.Visible = not settingsOpen
        settingsView.Visible = settingsOpen

        layout()
    end

    connections[#connections + 1] = gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(settle)

    local settingsY = HUD_TOP_H + 1 + HUD_PAD

    local function createCard(height)
        local card = Instance.new("TextButton")
        card.Position = UDim2.new(0, HUD_PAD, 0, settingsY)
        card.Size = UDim2.new(1, -(HUD_PAD * 2), 0, height)
        card.BackgroundColor3 = Default.Palette
        card.BackgroundTransparency = 0.2
        card.BorderSizePixel = 0
        card.Text = ""
        card.AutoButtonColor = false
        card.Selectable = false
        card.Parent = settingsView

        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 6)
        cardCorner.Parent = card

        local cardStroke = Instance.new("UIStroke")
        cardStroke.Color = Default.Border
        cardStroke.Thickness = 1
        cardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        cardStroke.Parent = card

        connections[#connections + 1] = card.MouseEnter:Connect(function()
            play(cardStroke, { Color = Default.BorderHover }, true)
        end)

        connections[#connections + 1] = card.MouseLeave:Connect(function()
            play(cardStroke, { Color = Default.Border }, true)
        end)

        settingsY = settingsY + height + HUD_CARD_GAP

        return card
    end

    local function createToggle(text, description, initial, onChange)
        local card = createCard(HUD_CARD_H)

        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Position = UDim2.new(0, 8, 0, 6)
        label.Size = UDim2.new(1, -52, 0, 16)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Default.Active
        label.TextSize = 12
        label.Font = fontBold
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.Parent = card

        local hint = Instance.new("TextLabel")
        hint.Name = "Description"
        hint.Position = UDim2.new(0, 8, 0, 22)
        hint.Size = UDim2.new(1, -52, 0, 12)
        hint.BackgroundTransparency = 1
        hint.Text = description
        hint.TextColor3 = Default.Dim
        hint.TextSize = 10
        hint.Font = fontRegular
        hint.TextXAlignment = Enum.TextXAlignment.Left
        hint.TextTruncate = Enum.TextTruncate.AtEnd
        hint.Parent = card

        local track = Instance.new("Frame")
        track.Name = "Track"
        track.Size = UDim2.new(0, 32, 0, 18)
        track.AnchorPoint = Vector2.new(1, 0.5)
        track.Position = UDim2.new(1, -8, 0.5, 0)
        track.BorderSizePixel = 0
        track.Parent = card

        local trackCorner = Instance.new("UICorner")
        trackCorner.CornerRadius = UDim.new(1, 0)
        trackCorner.Parent = track

        local knob = Instance.new("Frame")
        knob.Name = "Knob"
        knob.Size = UDim2.new(0, 12, 0, 12)
        knob.AnchorPoint = Vector2.new(0, 0.5)
        knob.BorderSizePixel = 0
        knob.Parent = track

        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = knob

        local state = initial == true

        local function render(animate)
            play(track, {
                BackgroundColor3 = state and Default.Active or Default.Border,
            }, animate)

            play(knob, {
                BackgroundColor3 = state and Default.Background or Default.Active,
                Position = state and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
            }, animate)
        end

        render(false)

        connections[#connections + 1] = card.Activated:Connect(function()
            state = not state
            render(true)
            onChange(state)
        end)

        return function(value)
            value = value == true

            if state == value then
                return
            end

            state = value
            render(false)
        end
    end

    setNeverToggle = createToggle("Não mostrar mais", "Oculta este painel", settings.neverShow, function(value)
        settings.neverShow = value
        layout()

        if value then
            notify("Painel de Key Bind oculto.", 3)
        end
    end)

    setDragToggle = createToggle("Permitir arrastar", "Move pela barra superior", hud.draggable, function(value)
        hud:SetDraggable(value)
    end)

    local resetBtn = createCard(HUD_BUTTON_H)
    resetBtn.Text = "Resetar posição"
    resetBtn.TextColor3 = Default.Inactive
    resetBtn.TextSize = 12
    resetBtn.Font = fontBold

    connections[#connections + 1] = resetBtn.MouseEnter:Connect(function()
        play(resetBtn, { TextColor3 = Default.Active }, true)
    end)

    connections[#connections + 1] = resetBtn.MouseLeave:Connect(function()
        play(resetBtn, { TextColor3 = Default.Inactive }, true)
    end)

    connections[#connections + 1] = resetBtn.Activated:Connect(function()
        hud:ResetPosition()
    end)

    local function pointerPosition(input)
        if input and input.UserInputType == Enum.UserInputType.Touch then
            return Vector2.new(input.Position.X, input.Position.Y) + guiService:GetGuiInset()
        end

        return userInputService:GetMouseLocation()
    end

    local function startDrag(input)
        stopDrag()

        local origin = pointerPosition(input)
        local grabX = origin.X - curX
        local grabY = origin.Y - curY

        dragging = true
        dragInput = input

        dragConnection = runService.RenderStepped:Connect(function()
            if not dragging or not dragInput then
                return
            end

            local isTouch = dragInput.UserInputType == Enum.UserInputType.Touch

            if not isTouch and not userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                stopDrag()
                return
            end

            local pointer = pointerPosition(dragInput)

            if not userMoved and (pointer - origin).Magnitude < 3 then
                return
            end

            userMoved = true
            applyPosition(clampPosition(pointer.X - grabX, pointer.Y - grabY))
        end)
    end

    connections[#connections + 1] = dragHandle.InputBegan:Connect(function(input)
        if not hud.draggable then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            startDrag(input)
        end
    end)

    connections[#connections + 1] = userInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            stopDrag()
        elseif input.UserInputType == Enum.UserInputType.Touch and input == dragInput then
            stopDrag()
        end
    end)

    connections[#connections + 1] = closeBtn.Activated:Connect(function()
        stopDrag()
        hud.closed = true
        setView(false)
    end)

    connections[#connections + 1] = settingsBtn.Activated:Connect(function()
        stopDrag()
        setView(true)
    end)

    connections[#connections + 1] = backBtn.Activated:Connect(function()
        setView(false)
    end)

    function hud:Add()
        hud.order = hud.order + 1

        local entry = {
            active = false,
            state = false,
            order = hud.order,
        }

        local row = Instance.new("Frame")
        row.Name = "Row"
        row.Size = UDim2.new(1, 0, 0, HUD_ROW_H)
        row.BackgroundTransparency = 1
        row.Visible = false
        row.Parent = listView

        entry.row = row

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "Name"
        nameLabel.Position = UDim2.new(0, HUD_PAD, 0, 0)
        nameLabel.Size = UDim2.new(1, -(HUD_PAD + HUD_PILL_W + 14), 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = ""
        nameLabel.TextColor3 = Default.Active
        nameLabel.TextSize = 13
        nameLabel.Font = fontBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        nameLabel.TextStrokeTransparency = 0.55
        nameLabel.Parent = row

        local keyLabel = Instance.new("TextLabel")
        keyLabel.Name = "Key"
        keyLabel.Size = UDim2.new(0, 0, 0, 20)
        keyLabel.AutomaticSize = Enum.AutomaticSize.X
        keyLabel.AnchorPoint = Vector2.new(1, 0.5)
        keyLabel.Position = UDim2.new(1, -HUD_PAD, 0.5, 0)
        keyLabel.BackgroundColor3 = Default.Palette
        keyLabel.BackgroundTransparency = 0.25
        keyLabel.BorderSizePixel = 0
        keyLabel.Text = ""
        keyLabel.TextColor3 = Default.Active
        keyLabel.TextSize = 11
        keyLabel.Font = fontBold
        keyLabel.TextTruncate = Enum.TextTruncate.AtEnd
        keyLabel.Parent = row

        local keyCorner = Instance.new("UICorner")
        keyCorner.CornerRadius = UDim.new(0, 5)
        keyCorner.Parent = keyLabel

        local keyStroke = Instance.new("UIStroke")
        keyStroke.Color = Default.BorderHover
        keyStroke.Thickness = 1
        keyStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        keyStroke.Parent = keyLabel

        local keyPadding = Instance.new("UIPadding")
        keyPadding.PaddingLeft = UDim.new(0, 6)
        keyPadding.PaddingRight = UDim.new(0, 6)
        keyPadding.Parent = keyLabel

        local keySize = Instance.new("UISizeConstraint")
        keySize.MinSize = Vector2.new(22, 20)
        keySize.MaxSize = Vector2.new(HUD_PILL_W, 20)
        keySize.Parent = keyLabel

        function entry:Update(title, keyText, state)
            local wasOn = entry.state

            nameLabel.Text = tostring(title or "")

            if keyText then
                keyLabel.Text = tostring(keyText)
                entry.active = true
            else
                entry.active = false
            end

            entry.state = state == true

            if entry.active and entry.state and not wasOn then
                hud.closed = false
            end

            layout()
        end

        function entry:Remove()
            hud.entries[entry] = nil
            row:Destroy()
            layout()
        end

        hud.entries[entry] = true

        return entry
    end

    function hud:SetDraggable(value)
        hud.draggable = value ~= false
        settings.draggable = hud.draggable

        if setDragToggle then
            setDragToggle(hud.draggable)
        end

        if not hud.draggable then
            stopDrag()
        end
    end

    function hud:SetNeverShow(value)
        settings.neverShow = value == true

        if setNeverToggle then
            setNeverToggle(settings.neverShow)
        end

        layout()
    end

    function hud:ResetPosition()
        userMoved = false
        settle()
    end

    function hud:Show()
        hud.closed = false
        layout()
    end

    function hud:Destroy()
        if env.EcoHubKeybindHud == hud then
            env.EcoHubKeybindHud = nil
        end

        stopDrag()

        for _, conn in ipairs(connections) do
            conn:Disconnect()
        end

        table.clear(connections)
        gui:Destroy()
    end

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
    local PILL_W = 40
    local PILL_H = 20
    local BASE_H = 30

    local Colors, watchTheme = createColors(section.Panel or Panel)
    local fontBold, fontRegular = getFonts()
    local isDesktop = userInputService.KeyboardEnabled

    local connections = {}
    local destroyed = false
    local listeningConnection
    local listeningWheelConnection
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

    local rightReserve = SWITCH_W + 10

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
    rowButton.Parent = container

    local textFrame = Instance.new("Frame")
    textFrame.Name = "TextFrame"
    textFrame.Size = UDim2.new(1, -rightReserve, 1, 0)
    textFrame.BackgroundTransparency = 1
    textFrame.ZIndex = 2
    textFrame.Parent = container

    local textLayout = Instance.new("UIListLayout")
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
    track.Position = UDim2.new(1, 0, 0.5, 0)
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
        keyBtn.Position = UDim2.new(1, -(SWITCH_W + 8), 0.5, 0)
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

    local function disconnectListening()
        if listeningConnection then
            listeningConnection:Disconnect()
            listeningConnection = nil
        end

        if listeningWheelConnection then
            listeningWheelConnection:Disconnect()
            listeningWheelConnection = nil
        end
    end

    local function stopListening()
        disconnectListening()

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

        local function accept(newBind)
            data.keybind = newBind
            stopListening()
            showKeybindHud()
            notify(("'%s' -> %s"):format(title, getKeyName(newBind)), 3)
        end

        listeningConnection = userInputService.InputBegan:Connect(function(input)
            if destroyed or not data.listening then
                return
            end

            if os.clock() - listenStartedAt < 0.15 then
                return
            end

            local inputType = input.UserInputType

            if inputType == Enum.UserInputType.MouseButton1
            or inputType == Enum.UserInputType.MouseButton2
            or inputType == Enum.UserInputType.MouseButton3 then
                accept(inputType)
            elseif inputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.Escape then
                    data.keybind = nil
                    stopListening()
                    notify(("Keybind de '%s' removida."):format(title), 3)
                    return
                end

                if input.KeyCode ~= Enum.KeyCode.Unknown then
                    accept(input.KeyCode)
                end
            elseif inputType.Name:find("^Gamepad") and input.KeyCode ~= Enum.KeyCode.Unknown then
                accept(input.KeyCode)
            end
        end)

        listeningWheelConnection = userInputService.InputChanged:Connect(function(input)
            if destroyed or not data.listening then
                return
            end

            if input.UserInputType ~= Enum.UserInputType.MouseWheel then
                return
            end

            if os.clock() - listenStartedAt < 0.15 then
                return
            end

            local z = input.Position.Z

            if z ~= 0 then
                accept(z > 0 and WHEEL_UP or WHEEL_DOWN)
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
        local function handleBindInput(input, gp)
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
        end

        connect(userInputService.InputBegan, handleBindInput)

        connect(userInputService.InputChanged, function(input, gp)
            if input.UserInputType == Enum.UserInputType.MouseWheel then
                handleBindInput(input, gp)
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

        disconnectListening()

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