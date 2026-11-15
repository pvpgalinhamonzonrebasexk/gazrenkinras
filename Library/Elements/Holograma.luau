-- // Services
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")
local players = game:GetService("Players")

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
local NOTIFY_TITLE = "System"
local TWEEN_INFO = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local BAR_TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local HEADER_H = 26
local POLL_RATE = 0.1
local MAX_ITEMS = 5
local MAX_FLAGS = 6
local BOX_PAD = 4
local BAR_W = 4
local ITEM_W = 64
local FLAG_W = 64
local BOB_AMPLITUDE = 3
local BOB_SPEED = 2
local SCAN_SPEED = 46
local LIVE_COLOR = Color3.fromRGB(80, 220, 120)

-- // Fonts
local function getFonts()
    return FONT_BOLD or Enum.Font.SourceSansSemibold, FONT or Enum.Font.SourceSans
end

-- // Notify
local function notify(msg, duration)
    pcall(function()
        Notify({
            Title = NOTIFY_TITLE,
            Description = msg,
            Duration = duration
        })
    end)
end

-- // Animation
local function play(instance, props, animate, info)
    if animate then
        tweenService:Create(instance, info or TWEEN_INFO, props):Play()
    else
        for property, value in pairs(props) do
            instance[property] = value
        end
    end
end

-- // Settings
local SETTING_TYPES = {
    Box = "boolean",
    BoxStyle = "string",
    BoxFill = "boolean",
    Name = "boolean",
    Health = "boolean",
    HealthText = "boolean",
    Armor = "boolean",
    Distance = "boolean",
    Tool = "boolean",
    Items = "boolean",
    Flags = "boolean",
    Skeleton = "boolean",
    HeadDot = "boolean",
    Tracer = "boolean",
    TracerOrigin = "string",
    Chams = "boolean",
}

local SETTING_VALUES = {
    BoxStyle = { Full = true, Corner = true },
    TracerOrigin = { Bottom = true, Center = true, Top = true },
}

local DEFAULT_SETTINGS = {
    Box = true,
    BoxStyle = "Full",
    BoxFill = false,
    Name = true,
    Health = true,
    HealthText = true,
    Armor = false,
    Distance = true,
    Tool = true,
    Items = true,
    Flags = true,
    Skeleton = false,
    HeadDot = false,
    Tracer = false,
    TracerOrigin = "Bottom",
    Chams = false,
}

local DEFAULT_COLORS = {
    Hologram = Color3.fromRGB(110, 190, 255),
    Box = Color3.fromRGB(255, 255, 255),
    BoxFill = Color3.fromRGB(255, 255, 255),
    Name = Color3.fromRGB(255, 255, 255),
    Distance = Color3.fromRGB(200, 200, 200),
    Tool = Color3.fromRGB(255, 210, 90),
    Items = Color3.fromRGB(190, 190, 190),
    Flags = Color3.fromRGB(255, 255, 255),
    Skeleton = Color3.fromRGB(255, 255, 255),
    HeadDot = Color3.fromRGB(255, 80, 80),
    Tracer = Color3.fromRGB(255, 255, 255),
    Chams = Color3.fromRGB(170, 90, 255),
    ChamsOutline = Color3.fromRGB(255, 255, 255),
    HealthHigh = Color3.fromRGB(80, 255, 120),
    HealthLow = Color3.fromRGB(255, 70, 70),
    Armor = Color3.fromRGB(80, 160, 255),
}

local NUMBER_KEYS = { "Health", "MaxHealth", "Armor", "MaxArmor", "Distance" }
local STRING_KEYS = { "Name", "Tool" }
local LIST_LIMITS = { Items = MAX_ITEMS, Flags = MAX_FLAGS }

-- // Body
local PARTS = {
    { "Head", 1.5, 0, 1, 1 },
    { "Torso", 1, 1, 2, 2 },
    { "LeftArm", 0, 1, 1, 2 },
    { "RightArm", 3, 1, 1, 2 },
    { "LeftLeg", 1, 3, 1, 2 },
    { "RightLeg", 2, 3, 1, 2 },
}

local SKELETON = {
    { 2, 0.5, 2, 3 },
    { 0.5, 1.2, 3.5, 1.2 },
    { 0.5, 1.2, 0.5, 2.9 },
    { 3.5, 1.2, 3.5, 2.9 },
    { 1.5, 3, 2.5, 3 },
    { 1.5, 3, 1.5, 4.9 },
    { 2.5, 3, 2.5, 4.9 },
}

-- // Helpers
local function create(class, props, parent)
    local instance = Instance.new(class)

    for property, value in pairs(props) do
        instance[property] = value
    end

    instance.Parent = parent

    return instance
end

local function copyTable(source)
    local copy = {}

    for key, value in pairs(source) do
        copy[key] = value
    end

    return copy
end

local function copyList(source)
    local copy = {}

    for index, value in ipairs(source) do
        copy[index] = value
    end

    return copy
end

local function isValidSetting(key, value)
    local expected = SETTING_TYPES[key]

    if not expected or type(value) ~= expected then
        return false
    end

    local allowed = SETTING_VALUES[key]

    if allowed and not allowed[value] then
        return false
    end

    return true
end

local function drawLine(line, x1, y1, x2, y2, thickness)
    local dx = x2 - x1
    local dy = y2 - y1

    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.Position = UDim2.new(0, math.floor((x1 + x2) / 2), 0, math.floor((y1 + y2) / 2))
    line.Size = UDim2.new(0, math.floor(math.sqrt(dx * dx + dy * dy)), 0, thickness)
    line.Rotation = math.deg(math.atan2(dy, dx))
end

local function verticalFade(parent, top, bottom)
    return create("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, top),
            NumberSequenceKeypoint.new(1, bottom),
        }),
    }, parent)
end

local function readPlayer(player)
    local patch = {
        Name = player.DisplayName ~= "" and player.DisplayName or player.Name,
    }

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        patch.Health = humanoid.Health
        patch.MaxHealth = humanoid.MaxHealth
    end

    local equipped = character and character:FindFirstChildOfClass("Tool")
    local items = {}

    patch.Tool = equipped and equipped.Name or ""

    if equipped then
        items[1] = equipped.Name
    end

    local backpack = player:FindFirstChildOfClass("Backpack")

    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                items[#items + 1] = tool.Name
            end
        end
    end

    patch.Items = items

    local flags = {}

    if humanoid then
        if humanoid.Health <= 0 then
            flags[#flags + 1] = "Dead"
        else
            if humanoid.Sit then
                flags[#flags + 1] = "Sitting"
            elseif humanoid.FloorMaterial == Enum.Material.Air then
                flags[#flags + 1] = "Air"
            elseif humanoid.MoveDirection.Magnitude > 0.1 then
                flags[#flags + 1] = "Moving"
            end
        end
    end

    patch.Flags = flags

    local armor = character and character:GetAttribute("Armor")
    local maxArmor = character and character:GetAttribute("MaxArmor")

    if type(armor) == "number" then
        patch.Armor = armor
        patch.MaxArmor = type(maxArmor) == "number" and maxArmor or 100
    else
        patch.Armor = 0
        patch.MaxArmor = 0
    end

    local localPlayer = players.LocalPlayer

    if player ~= localPlayer and character and localPlayer and localPlayer.Character then
        local root = character:FindFirstChild("HumanoidRootPart")
        local localRoot = localPlayer.Character:FindFirstChild("HumanoidRootPart")

        if root and localRoot then
            patch.Distance = (root.Position - localRoot.Position).Magnitude
        end
    end

    return patch
end

-- // Hologram
Elements.Register("Hologram", function(section, options)
    options = type(options) == "table" and options or {}

    local Colors, watchTheme = createColors(section.Panel or Panel)
    local fontBold, fontRegular = getFonts()

    local connections = {}
    local destroyed = false
    local loopConnection
    local unwatchTheme
    local source
    local reader
    local lastPoll = 0
    local pollFailed = false

    local function connect(signal, fn)
        local conn = signal:Connect(fn)
        connections[#connections + 1] = conn
        return conn
    end

    local title = tostring(options.title or options.Name or "Hologram")
    local callback = options.callback or options.Callback

    if type(callback) ~= "function" then
        callback = function() end
    end

    local height = math.clamp(tonumber(options.height) or 290, 230, 420)
    local stageH = height - HEADER_H
    local scale = math.clamp(math.floor(tonumber(options.scale) or ((stageH - 100) / 5)), 10, 40)
    local figW = scale * 4
    local figH = scale * 5
    local figTop = math.max(stageH - 66 - figH, 30)
    local boxW = figW + BOX_PAD * 2
    local boxH = figH + BOX_PAD * 2
    local animated = options.animated ~= false

    local settings = copyTable(DEFAULT_SETTINGS)
    local colors = copyTable(DEFAULT_COLORS)

    if type(options.settings) == "table" then
        for key, value in pairs(options.settings) do
            if isValidSetting(key, value) then
                settings[key] = value
            end
        end
    end

    if type(options.colors) == "table" then
        for key, value in pairs(options.colors) do
            if DEFAULT_COLORS[key] and typeof(value) == "Color3" then
                colors[key] = value
            end
        end
    end

    local state = {
        Name = "Player",
        Health = 100,
        MaxHealth = 100,
        Armor = 50,
        MaxArmor = 100,
        Distance = 25,
        Tool = "Sword",
        Items = { "Sword", "Medkit", "Grenade" },
        Flags = { "Visible" },
    }

    local data = {}

    local container = create("Frame", {
        Name = title .. "_Hologram",
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = Colors.Palette,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, section.frame)

    create("UICorner", { CornerRadius = UDim.new(0, 8) }, container)

    local containerStroke = create("UIStroke", {
        Color = Colors.Border,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, container)

    local function createText(parent, props)
        local label = Instance.new("TextLabel")

        label.BackgroundTransparency = 1
        label.Text = ""
        label.Font = fontBold
        label.TextSize = 11
        label.TextColor3 = Colors.Active
        label.TextStrokeColor3 = Color3.new(0, 0, 0)
        label.TextStrokeTransparency = 0.5
        label.ZIndex = 7

        for property, value in pairs(props) do
            label[property] = value
        end

        label.Parent = parent

        return label
    end

    local header = create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, HEADER_H),
        BackgroundTransparency = 1,
        ZIndex = 10,
    }, container)

    local titleLabel = createText(header, {
        Name = "Title",
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0.5, -10, 1, 0),
        Text = title,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextStrokeTransparency = 1,
        ZIndex = 10,
    })

    local statusFrame = create("Frame", {
        Name = "Status",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 0),
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        ZIndex = 10,
    }, header)

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
    }, statusFrame)

    local statusDot = create("Frame", {
        Name = "Dot",
        Size = UDim2.new(0, 6, 0, 6),
        BackgroundColor3 = Colors.Dim,
        BorderSizePixel = 0,
        LayoutOrder = 0,
        ZIndex = 10,
    }, statusFrame)

    create("UICorner", { CornerRadius = UDim.new(1, 0) }, statusDot)

    local statusLabel = createText(statusFrame, {
        Name = "Text",
        Size = UDim2.new(0, 0, 0, 14),
        AutomaticSize = Enum.AutomaticSize.X,
        Text = "PREVIEW",
        TextSize = 10,
        TextColor3 = Colors.Dim,
        TextStrokeTransparency = 1,
        LayoutOrder = 1,
        ZIndex = 10,
    })

    local divider = create("Frame", {
        Name = "Divider",
        Position = UDim2.new(0, 10, 0, HEADER_H),
        Size = UDim2.new(1, -20, 0, 1),
        BackgroundColor3 = Colors.Border,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        ZIndex = 10,
    }, container)

    local stage = create("Frame", {
        Name = "Stage",
        Position = UDim2.new(0, 0, 0, HEADER_H),
        Size = UDim2.new(1, 0, 0, stageH),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    }, container)

    local beam = create("Frame", {
        Name = "Beam",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -14),
        Size = UDim2.new(0, figW + 36, 1, -14),
        BackgroundColor3 = colors.Hologram,
        BorderSizePixel = 0,
        ZIndex = 1,
    }, stage)

    verticalFade(beam, 1, 0.82)

    local edgeLeft = create("Frame", {
        Name = "EdgeLeft",
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = colors.Hologram,
        BorderSizePixel = 0,
        ZIndex = 1,
    }, beam)

    local edgeRight = create("Frame", {
        Name = "EdgeRight",
        Position = UDim2.new(1, -1, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = colors.Hologram,
        BorderSizePixel = 0,
        ZIndex = 1,
    }, beam)

    verticalFade(edgeLeft, 1, 0.5)
    verticalFade(edgeRight, 1, 0.5)

    local baseOuter = create("Frame", {
        Name = "Base",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 1, -14),
        Size = UDim2.new(0, figW + 36, 0, 16),
        BackgroundColor3 = colors.Hologram,
        BackgroundTransparency = 0.82,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, stage)

    create("UICorner", { CornerRadius = UDim.new(1, 0) }, baseOuter)

    local baseOuterStroke = create("UIStroke", {
        Color = colors.Hologram,
        Thickness = 1,
        Transparency = 0.25,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, baseOuter)

    local baseInner = create("Frame", {
        Name = "BaseInner",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 1, -14),
        Size = UDim2.new(0, math.floor((figW + 36) * 0.6), 0, 9),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, stage)

    create("UICorner", { CornerRadius = UDim.new(1, 0) }, baseInner)

    local baseInnerStroke = create("UIStroke", {
        Color = colors.Hologram,
        Thickness = 1,
        Transparency = 0.5,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, baseInner)

    local scan = create("Frame", {
        Name = "Scan",
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = colors.Hologram,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        Visible = animated,
        ZIndex = 2,
    }, stage)

    create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, scan)

    local tracerLine = create("Frame", {
        Name = "Tracer",
        BackgroundColor3 = colors.Tracer,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 2,
    }, stage)

    local rig = create("Frame", {
        Name = "Rig",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, figTop),
        Size = UDim2.new(0, figW, 0, figH),
        BackgroundTransparency = 1,
        ZIndex = 3,
    }, stage)

    local parts = {}

    for _, spec in ipairs(PARTS) do
        local frame = create("Frame", {
            Name = spec[1],
            Position = UDim2.new(0, math.floor(spec[2] * scale) + 1, 0, math.floor(spec[3] * scale) + 1),
            Size = UDim2.new(0, spec[4] * scale - 2, 0, spec[5] * scale - 2),
            BorderSizePixel = 0,
            ZIndex = 3,
        }, rig)

        create("UICorner", {
            CornerRadius = UDim.new(0, spec[1] == "Head" and math.floor(scale * 0.25) or 2)
        }, frame)

        local stroke = create("UIStroke", {
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        }, frame)

        parts[#parts + 1] = { frame = frame, stroke = stroke }
    end

    local toolFrame = create("Frame", {
        Name = "HeldTool",
        Position = UDim2.new(0, math.floor(scale * 3.5) - math.max(math.floor(scale * 0.125), 1), 0, math.floor(scale * 2.1)),
        Size = UDim2.new(0, math.max(math.floor(scale * 0.25), 3), 0, math.floor(scale * 0.9)),
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        ZIndex = 4,
    }, rig)

    create("UICorner", { CornerRadius = UDim.new(0, 2) }, toolFrame)

    local dotSize = math.max(math.floor(scale * 0.32), 4)

    local headDot = create("Frame", {
        Name = "HeadDot",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, math.floor(scale * 2), 0, math.floor(scale * 0.5)),
        Size = UDim2.new(0, dotSize, 0, dotSize),
        BorderSizePixel = 0,
        ZIndex = 5,
    }, rig)

    create("UICorner", { CornerRadius = UDim.new(1, 0) }, headDot)

    local skeletonLines = {}

    for index, segment in ipairs(SKELETON) do
        local line = create("Frame", {
            Name = "Bone",
            BorderSizePixel = 0,
            ZIndex = 5,
        }, rig)

        drawLine(line, segment[1] * scale, segment[2] * scale, segment[3] * scale, segment[4] * scale, 2)

        skeletonLines[index] = line
    end

    local boxFrame = create("Frame", {
        Name = "Box",
        Position = UDim2.new(0, -BOX_PAD, 0, -BOX_PAD),
        Size = UDim2.new(0, boxW, 0, boxH),
        BorderSizePixel = 0,
        ZIndex = 5,
    }, rig)

    local boxStroke = create("UIStroke", {
        Thickness = 1.5,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, boxFrame)

    local corners = {}
    local cornerLength = math.floor(math.min(boxW, boxH) * 0.22)
    local cornerThickness = 2

    local cornerRects = {
        { 0, 0, cornerLength, cornerThickness },
        { 0, 0, cornerThickness, cornerLength },
        { boxW - cornerLength, 0, cornerLength, cornerThickness },
        { boxW - cornerThickness, 0, cornerThickness, cornerLength },
        { 0, boxH - cornerThickness, cornerLength, cornerThickness },
        { 0, boxH - cornerLength, cornerThickness, cornerLength },
        { boxW - cornerLength, boxH - cornerThickness, cornerLength, cornerThickness },
        { boxW - cornerThickness, boxH - cornerLength, cornerThickness, cornerLength },
    }

    for index, rect in ipairs(cornerRects) do
        corners[index] = create("Frame", {
            Name = "Corner",
            Position = UDim2.new(0, rect[1], 0, rect[2]),
            Size = UDim2.new(0, rect[3], 0, rect[4]),
            BorderSizePixel = 0,
            ZIndex = 6,
        }, boxFrame)
    end

    local function createBar(x)
        local back = create("Frame", {
            Name = "Bar",
            Position = UDim2.new(0, x, 0, -BOX_PAD),
            Size = UDim2.new(0, BAR_W, 0, boxH),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            ZIndex = 5,
        }, rig)

        local fill = create("Frame", {
            Name = "Fill",
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 1, 1, -1),
            Size = UDim2.new(1, -2, 0, boxH - 2),
            BorderSizePixel = 0,
            ZIndex = 6,
        }, back)

        return back, fill
    end

    local healthBack, healthFill = createBar(-(BOX_PAD + BAR_W + 3))
    local armorBack, armorFill = createBar(figW + BOX_PAD + 3)

    local healthText = createText(rig, {
        Name = "HealthText",
        AnchorPoint = Vector2.new(1, 0.5),
        Size = UDim2.new(0, 22, 0, 10),
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Right,
    })

    local nameLabel = createText(rig, {
        Name = "PlayerName",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 0, -BOX_PAD - 2),
        Size = UDim2.new(0, 160, 0, 14),
        TextSize = 12,
    })

    local toolLabel = createText(rig, {
        Name = "ToolName",
        AnchorPoint = Vector2.new(0.5, 0),
        Size = UDim2.new(0, 160, 0, 12),
        TextSize = 10,
    })

    local distanceLabel = createText(rig, {
        Name = "Distance",
        AnchorPoint = Vector2.new(0.5, 0),
        Size = UDim2.new(0, 160, 0, 12),
        TextSize = 10,
    })

    local itemRight = BOX_PAD + BAR_W + 6 + 22 + 4
    local itemLabels = {}
    local flagLabels = {}

    for index = 1, MAX_ITEMS do
        itemLabels[index] = createText(rig, {
            Name = "Item",
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(0, -itemRight, 0, -BOX_PAD + (index - 1) * 12),
            Size = UDim2.new(0, ITEM_W, 0, 12),
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
    end

    for index = 1, MAX_FLAGS do
        flagLabels[index] = createText(rig, {
            Name = "Flag",
            Position = UDim2.new(0, figW + BOX_PAD + 14, 0, -BOX_PAD + (index - 1) * 12),
            Size = UDim2.new(0, FLAG_W, 0, 12),
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
    end

    local function fireCallback(key, value)
        local ok, err = pcall(callback, copyTable(settings), key, value)

        if not ok then
            warn(("Hologram '%s': %s"):format(title, tostring(err)))
            notify(("Hologram '%s': %s"):format(title, tostring(err)), 5)
        end
    end

    local function updateTracer()
        if destroyed then
            return
        end

        local width = stage.AbsoluteSize.X

        if not settings.Tracer or width <= 0 then
            tracerLine.Visible = false
            return
        end

        local startY = stageH

        if settings.TracerOrigin == "Center" then
            startY = stageH / 2
        elseif settings.TracerOrigin == "Top" then
            startY = 0
        end

        local endY = rig.Position.Y.Offset + figH

        drawLine(tracerLine, width / 2, startY, width / 2, endY, 1)
        tracerLine.Visible = true
    end

    local function applyColors()
        beam.BackgroundColor3 = colors.Hologram
        edgeLeft.BackgroundColor3 = colors.Hologram
        edgeRight.BackgroundColor3 = colors.Hologram
        baseOuter.BackgroundColor3 = colors.Hologram
        baseOuterStroke.Color = colors.Hologram
        baseInnerStroke.Color = colors.Hologram
        scan.BackgroundColor3 = colors.Hologram

        boxStroke.Color = colors.Box
        boxFrame.BackgroundColor3 = colors.BoxFill

        for _, corner in ipairs(corners) do
            corner.BackgroundColor3 = colors.Box
        end

        nameLabel.TextColor3 = colors.Name
        toolLabel.TextColor3 = colors.Tool
        distanceLabel.TextColor3 = colors.Distance
        toolFrame.BackgroundColor3 = colors.Tool
        headDot.BackgroundColor3 = colors.HeadDot
        tracerLine.BackgroundColor3 = colors.Tracer
        armorFill.BackgroundColor3 = colors.Armor

        for _, line in ipairs(skeletonLines) do
            line.BackgroundColor3 = colors.Skeleton
        end

        for _, label in ipairs(flagLabels) do
            label.TextColor3 = colors.Flags
        end
    end

    local function applyChams(animate)
        for _, part in ipairs(parts) do
            if settings.Chams then
                play(part.frame, { BackgroundColor3 = colors.Chams, BackgroundTransparency = 0.35 }, animate)
                play(part.stroke, { Color = colors.ChamsOutline, Transparency = 0.1 }, animate)
            else
                play(part.frame, { BackgroundColor3 = colors.Hologram, BackgroundTransparency = 0.85 }, animate)
                play(part.stroke, { Color = colors.Hologram, Transparency = 0.3 }, animate)
            end
        end
    end

    local function applyVisibility()
        local full = settings.BoxStyle == "Full"

        boxFrame.Visible = settings.Box
        boxStroke.Enabled = full
        boxFrame.BackgroundTransparency = settings.BoxFill and 0.88 or 1

        for _, corner in ipairs(corners) do
            corner.Visible = not full
        end

        healthBack.Visible = settings.Health
        healthText.Visible = settings.Health and settings.HealthText
        nameLabel.Visible = settings.Name
        headDot.Visible = settings.HeadDot

        for _, line in ipairs(skeletonLines) do
            line.Visible = settings.Skeleton
        end
    end

    local function renderData(animate)
        if destroyed then
            return
        end

        local ratio = state.MaxHealth > 0 and math.clamp(state.Health / state.MaxHealth, 0, 1) or 0
        local healthColor = colors.HealthLow:Lerp(colors.HealthHigh, ratio)
        local fillH = math.floor((boxH - 2) * ratio)
        local textY = -BOX_PAD + math.clamp(boxH - fillH - 1, 6, boxH - 6)

        play(healthFill, {
            Size = UDim2.new(1, -2, 0, fillH),
            BackgroundColor3 = healthColor,
        }, animate, BAR_TWEEN_INFO)

        play(healthText, {
            Position = UDim2.new(0, -(BOX_PAD + BAR_W + 6), 0, textY),
        }, animate, BAR_TWEEN_INFO)

        healthText.Text = tostring(math.floor(state.Health + 0.5))
        healthText.TextColor3 = healthColor

        local armorRatio = state.MaxArmor > 0 and math.clamp(state.Armor / state.MaxArmor, 0, 1) or 0

        armorBack.Visible = settings.Armor and state.MaxArmor > 0

        play(armorFill, {
            Size = UDim2.new(1, -2, 0, math.floor((boxH - 2) * armorRatio)),
        }, animate, BAR_TWEEN_INFO)

        nameLabel.Text = state.Name
        toolLabel.Text = state.Tool
        distanceLabel.Text = ("%dm"):format(math.floor(state.Distance + 0.5))

        local y = figH + BOX_PAD + 2
        local showTool = settings.Tool and state.Tool ~= ""

        toolLabel.Visible = showTool
        toolFrame.Visible = showTool

        if showTool then
            toolLabel.Position = UDim2.new(0.5, 0, 0, y)
            y = y + 12
        end

        distanceLabel.Visible = settings.Distance
        distanceLabel.Position = UDim2.new(0.5, 0, 0, y)

        for index, label in ipairs(itemLabels) do
            local item = state.Items[index]

            label.Text = item or ""
            label.Visible = settings.Items and item ~= nil
            label.TextColor3 = item ~= nil and item == state.Tool and colors.Tool or colors.Items
        end

        for index, label in ipairs(flagLabels) do
            local flag = state.Flags[index]

            label.Text = flag or ""
            label.Visible = settings.Flags and flag ~= nil
        end
    end

    local function renderAll(animate)
        if destroyed then
            return
        end

        applyColors()
        applyChams(animate)
        applyVisibility()
        renderData(animate)
        updateTracer()
    end

    local function updateStatus()
        local live = reader ~= nil

        statusDot.BackgroundColor3 = live and LIVE_COLOR or Colors.Dim
        statusLabel.TextColor3 = live and LIVE_COLOR or Colors.Dim
        statusLabel.Text = live and "LIVE" or "PREVIEW"
    end

    local function applyTheme()
        if destroyed then
            return
        end

        container.BackgroundColor3 = Colors.Palette
        containerStroke.Color = Colors.Border
        divider.BackgroundColor3 = Colors.Border
        titleLabel.TextColor3 = Colors.Active

        updateStatus()
    end

    local function poll()
        if not reader then
            return
        end

        if typeof(source) == "Instance" and source.Parent == nil then
            data:Bind(nil)
            notify(("Hologram '%s': the bound player left."):format(title), 4)
            return
        end

        local ok, result = pcall(reader)

        if not ok then
            if not pollFailed then
                pollFailed = true
                warn(("Hologram '%s' (bind): %s"):format(title, tostring(result)))
                notify(("Hologram '%s' (bind): %s"):format(title, tostring(result)), 5)
            end

            return
        end

        pollFailed = false
        data:Update(result)
    end

    local function step()
        if destroyed then
            return
        end

        local now = os.clock()

        if animated then
            local bob = math.floor(math.sin(now * BOB_SPEED) * BOB_AMPLITUDE + 0.5)

            rig.Position = UDim2.new(0.5, 0, 0, figTop + bob)
            scan.Position = UDim2.new(0, 0, 0, math.floor((now * SCAN_SPEED) % stageH))

            if settings.Tracer then
                updateTracer()
            end
        end

        if reader and now - lastPoll >= POLL_RATE then
            lastPoll = now
            poll()
        end
    end

    local function refreshLoop()
        local needed = not destroyed and (animated or reader ~= nil)

        if needed and not loopConnection then
            loopConnection = runService.Heartbeat:Connect(step)
        elseif not needed and loopConnection then
            loopConnection:Disconnect()
            loopConnection = nil
        end
    end

    function data:Update(patch)
        if destroyed or type(patch) ~= "table" then
            return
        end

        local changed = false

        for _, key in ipairs(NUMBER_KEYS) do
            local value = patch[key]

            if type(value) == "number" and value == value and state[key] ~= value then
                state[key] = value
                changed = true
            end
        end

        for _, key in ipairs(STRING_KEYS) do
            local value = patch[key]

            if value ~= nil then
                value = tostring(value)

                if state[key] ~= value then
                    state[key] = value
                    changed = true
                end
            end
        end

        for key, limit in pairs(LIST_LIMITS) do
            local value = patch[key]

            if type(value) == "table" then
                local list = {}

                for index = 1, math.min(#value, limit) do
                    list[index] = tostring(value[index])
                end

                if table.concat(list, "\n") ~= table.concat(state[key], "\n") then
                    state[key] = list
                    changed = true
                end
            end
        end

        if changed then
            renderData(true)
        end
    end

    function data:SetName(value)
        data:Update({ Name = value })
    end

    function data:SetHealth(value, max)
        data:Update({ Health = value, MaxHealth = max })
    end

    function data:SetArmor(value, max)
        data:Update({ Armor = value, MaxArmor = max })
    end

    function data:SetDistance(value)
        data:Update({ Distance = value })
    end

    function data:SetTool(value)
        data:Update({ Tool = value })
    end

    function data:SetItems(list)
        data:Update({ Items = list })
    end

    function data:SetFlags(list)
        data:Update({ Flags = list })
    end

    function data:GetData()
        local copy = copyTable(state)

        copy.Items = copyList(state.Items)
        copy.Flags = copyList(state.Flags)

        return copy
    end

    function data:SetSettings(patch)
        if destroyed or type(patch) ~= "table" then
            return
        end

        local applied = {}

        for key, value in pairs(patch) do
            if isValidSetting(key, value) then
                if settings[key] ~= value then
                    settings[key] = value
                    applied[#applied + 1] = key
                end
            else
                notify(("Hologram '%s': invalid setting '%s'."):format(title, tostring(key)), 5)
            end
        end

        if #applied == 0 then
            return
        end

        renderAll(true)

        for _, key in ipairs(applied) do
            fireCallback(key, settings[key])
        end
    end

    function data:Set(key, value)
        if key == nil then
            return
        end

        data:SetSettings({ [key] = value })
    end

    function data:Get(key)
        return settings[key]
    end

    function data:GetSettings()
        return copyTable(settings)
    end

    function data:SetColor(key, color)
        if destroyed then
            return
        end

        if not DEFAULT_COLORS[key] or typeof(color) ~= "Color3" then
            notify(("Hologram '%s': invalid color '%s'."):format(title, tostring(key)), 5)
            return
        end

        colors[key] = color
        renderAll(false)
    end

    function data:SetColors(patch)
        if destroyed or type(patch) ~= "table" then
            return
        end

        for key, color in pairs(patch) do
            if DEFAULT_COLORS[key] and typeof(color) == "Color3" then
                colors[key] = color
            end
        end

        renderAll(false)
    end

    function data:GetColor(key)
        return colors[key]
    end

    function data:Bind(newSource)
        if destroyed then
            return false
        end

        if newSource == nil or newSource == false then
            source = nil
            reader = nil
            pollFailed = false
            updateStatus()
            refreshLoop()

            return true
        end

        if typeof(newSource) == "Instance" and newSource:IsA("Player") then
            source = newSource
            reader = function()
                return readPlayer(newSource)
            end
        elseif type(newSource) == "function" then
            source = newSource
            reader = newSource
        else
            notify(("Hologram '%s': Bind expects a Player or a function."):format(title), 5)

            return false
        end

        pollFailed = false
        lastPoll = os.clock()
        updateStatus()
        poll()
        refreshLoop()

        return true
    end

    function data:Unbind()
        return data:Bind(nil)
    end

    function data:GetBound()
        return source
    end

    function data:SetAnimated(value)
        if destroyed then
            return
        end

        animated = value == true
        scan.Visible = animated

        if not animated then
            rig.Position = UDim2.new(0.5, 0, 0, figTop)
            updateTracer()
        end

        refreshLoop()
    end

    function data:SetTitle(newTitle)
        if destroyed then
            return
        end

        title = tostring(newTitle or "")
        titleLabel.Text = title
    end

    function data:Destroy()
        if destroyed then
            return
        end

        destroyed = true
        reader = nil
        source = nil

        if loopConnection then
            loopConnection:Disconnect()
            loopConnection = nil
        end

        if unwatchTheme then
            unwatchTheme()
            unwatchTheme = nil
        end

        for _, conn in ipairs(connections) do
            conn:Disconnect()
        end

        table.clear(connections)
        container:Destroy()
    end

    connect(stage:GetPropertyChangedSignal("AbsoluteSize"), updateTracer)

    if type(options.data) == "table" then
        data:Update(options.data)
    end

    renderAll(false)
    updateStatus()

    if options.bind == nil or options.bind == true then
        if players.LocalPlayer then
            data:Bind(players.LocalPlayer)
        end
    elseif options.bind ~= false then
        data:Bind(options.bind)
    end

    refreshLoop()

    unwatchTheme = watchTheme(applyTheme)

    return data
end)