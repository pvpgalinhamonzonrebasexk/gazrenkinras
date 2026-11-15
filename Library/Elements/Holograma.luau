local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local contentProvider = game:GetService("ContentProvider")
local players = game:GetService("Players")
local guiService = game:GetService("GuiService")

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

local THEME_SET = {}

for _, key in ipairs(THEME_KEYS) do
    THEME_SET[key] = true
end

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

local NOTIFY_TITLE = "System"
local TWEEN_INFO = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local BAR_TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local HEIGHT_DEFAULT = 300
local HEIGHT_MIN = 60
local HEIGHT_MAX = 600
local RATE_DEFAULT = 0.1
local RATE_MIN = 0.016
local RATE_MAX = 5
local TITLE_H = 20
local DESC_H = 26
local HEADER_PAD = 10
local DRAG_THRESHOLD = 6
local DRAG_SENSITIVITY = 0.01
local PICK_RANGE = 200
local VIEW_HEIGHT = 7.6
local VIEW_WIDTH = 5.8
local VIEW_CENTER_Y = -0.3
local VIEW_FOV = 40
local ASSET_PREFIX = "rbxassetid://"

local VIEW_COLORS = {
    Base = Color3.fromRGB(110, 190, 255),
    Hover = Color3.fromRGB(165, 218, 255),
    Selected = Color3.fromRGB(255, 255, 255),
    Disabled = Color3.fromRGB(90, 90, 90),
}

local BODY_COLORS = {
    Head = "HeadColor3",
    Torso = "TorsoColor3",
    LeftArm = "LeftArmColor3",
    RightArm = "RightArmColor3",
    LeftLeg = "LeftLegColor3",
    RightLeg = "RightLegColor3",
}

local ALIGN_X = {
    Left = Enum.TextXAlignment.Left,
    Center = Enum.TextXAlignment.Center,
    Right = Enum.TextXAlignment.Right,
}

local ALIGN_Y = {
    Top = Enum.TextYAlignment.Top,
    Center = Enum.TextYAlignment.Center,
    Bottom = Enum.TextYAlignment.Bottom,
}

local function getFonts()
    return FONT_BOLD or Enum.Font.SourceSansSemibold, FONT or Enum.Font.SourceSans
end

local function notify(msg, duration)
    pcall(function()
        Notify({
            Title = NOTIFY_TITLE,
            Description = msg,
            Duration = duration
        })
    end)
end

local function play(instance, props, animate, info)
    if animate then
        tweenService:Create(instance, info or TWEEN_INFO, props):Play()
    else
        for property, value in pairs(props) do
            instance[property] = value
        end
    end
end

local function merge(...)
    local result = {}

    for _, source in ipairs({ ... }) do
        for key, value in pairs(source) do
            result[key] = value
        end
    end

    return result
end

local COMMON_SCHEMA = {
    Visible = "boolean",
    Layer = "number",
    Animate = "boolean",
}

local COMMON_DEFAULTS = {
    Visible = true,
    Layer = 1,
    Animate = true,
}

local OUTLINE_SCHEMA = {
    Outline = "boolean",
    OutlineColor = "color",
    OutlineThickness = "number",
    OutlineTransparency = "number",
}

local OUTLINE_DEFAULTS = {
    Outline = false,
    OutlineColor = "Border",
    OutlineThickness = 1,
    OutlineTransparency = 0,
}

local BOX_SCHEMA = {
    X = "number",
    Y = "number",
    Width = "number",
    Height = "number",
    Rotation = "number",
    Transparency = "number",
    Color = "color",
    Corner = "number",
}

local SPECS = {
    Part = {
        schema = merge(COMMON_SCHEMA, OUTLINE_SCHEMA, BOX_SCHEMA),
        defaults = merge(COMMON_DEFAULTS, OUTLINE_DEFAULTS, {
            X = 0,
            Y = 0,
            Width = 20,
            Height = 20,
            Rotation = 0,
            Transparency = 0,
            Color = "Active",
            Corner = 0,
        }),
    },
    Circle = {
        schema = merge(COMMON_SCHEMA, OUTLINE_SCHEMA, BOX_SCHEMA),
        defaults = merge(COMMON_DEFAULTS, OUTLINE_DEFAULTS, {
            X = 0,
            Y = 0,
            Width = 20,
            Height = 20,
            Rotation = 0,
            Transparency = 0,
            Color = "Active",
            Corner = 0,
        }),
    },
    Text = {
        schema = merge(COMMON_SCHEMA, {
            X = "number",
            Y = "number",
            Width = "number",
            Height = "number",
            Rotation = "number",
            Transparency = "number",
            Color = "color",
            Text = "string",
            Size = "number",
            Bold = "boolean",
            Align = ALIGN_X,
            VAlign = ALIGN_Y,
            Shadow = "boolean",
            Truncate = "boolean",
            Wrap = "boolean",
        }),
        defaults = merge(COMMON_DEFAULTS, {
            X = 0,
            Y = 0,
            Width = 100,
            Height = 14,
            Rotation = 0,
            Transparency = 0,
            Color = "Active",
            Text = "",
            Size = 11,
            Bold = true,
            Align = "Left",
            VAlign = "Center",
            Shadow = false,
            Truncate = false,
            Wrap = false,
        }),
    },
    Line = {
        schema = merge(COMMON_SCHEMA, {
            X1 = "number",
            Y1 = "number",
            X2 = "number",
            Y2 = "number",
            Thickness = "number",
            Transparency = "number",
            Color = "color",
        }),
        defaults = merge(COMMON_DEFAULTS, {
            X1 = 0,
            Y1 = 0,
            X2 = 20,
            Y2 = 20,
            Thickness = 1,
            Transparency = 0,
            Color = "Active",
        }),
    },
    Bar = {
        schema = merge(COMMON_SCHEMA, OUTLINE_SCHEMA, {
            X = "number",
            Y = "number",
            Width = "number",
            Height = "number",
            Value = "number",
            Max = "number",
            Vertical = "boolean",
            Reverse = "boolean",
            Padding = "number",
            Corner = "number",
            Transparency = "number",
            Color = "color",
            BackColor = "color",
            BackTransparency = "number",
        }),
        defaults = merge(COMMON_DEFAULTS, OUTLINE_DEFAULTS, {
            X = 0,
            Y = 0,
            Width = 4,
            Height = 60,
            Value = 0,
            Max = 100,
            Vertical = true,
            Reverse = false,
            Padding = 1,
            Corner = 0,
            Transparency = 0,
            Color = "Active",
            BackColor = "Background",
            BackTransparency = 0,
        }),
    },
    Image = {
        schema = merge(COMMON_SCHEMA, {
            X = "number",
            Y = "number",
            Width = "number",
            Height = "number",
            Rotation = "number",
            Transparency = "number",
            Color = "color",
            Corner = "number",
            Image = "string",
        }),
        defaults = merge(COMMON_DEFAULTS, {
            X = 0,
            Y = 0,
            Width = 32,
            Height = 32,
            Rotation = 0,
            Transparency = 0,
            Color = "Active",
            Corner = 0,
            Image = "",
        }),
    },
}

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

local function clampRate(value)
    return math.clamp(tonumber(value) or RATE_DEFAULT, RATE_MIN, RATE_MAX)
end

local function isValid(spec, value)
    if spec == "color" then
        return typeof(value) == "Color3" or (type(value) == "string" and THEME_SET[value] == true)
    end

    if type(spec) == "table" then
        return type(value) == "string" and spec[value] ~= nil
    end

    if spec == "number" then
        return type(value) == "number" and value == value
    end

    return type(value) == spec
end

local function drawLine(line, x1, y1, x2, y2, thickness)
    local dx = x2 - x1
    local dy = y2 - y1

    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.Position = UDim2.new(0, math.floor((x1 + x2) / 2), 0, math.floor((y1 + y2) / 2))
    line.Size = UDim2.new(0, math.floor(math.sqrt(dx * dx + dy * dy)), 0, thickness)
    line.Rotation = math.deg(math.atan2(dy, dx))
end

local ALL_FACES = {
    Enum.NormalId.Front,
    Enum.NormalId.Back,
    Enum.NormalId.Left,
    Enum.NormalId.Right,
    Enum.NormalId.Top,
    Enum.NormalId.Bottom,
}

local R6_PARTS = {
    { name = "Head", label = "Head", size = Vector3.new(2, 1, 1), offset = Vector3.new(0, 1.5, 0), mesh = "Head" },
    { name = "Torso", label = "Torso", size = Vector3.new(2, 2, 1), offset = Vector3.new(0, 0, 0) },
    { name = "LeftArm", label = "Left Arm", size = Vector3.new(1, 2, 1), offset = Vector3.new(-1.5, 0, 0) },
    { name = "RightArm", label = "Right Arm", size = Vector3.new(1, 2, 1), offset = Vector3.new(1.5, 0, 0) },
    { name = "LeftLeg", label = "Left Leg", size = Vector3.new(1, 2, 1), offset = Vector3.new(-0.5, -2, 0) },
    { name = "RightLeg", label = "Right Leg", size = Vector3.new(1, 2, 1), offset = Vector3.new(0.5, -2, 0) },
    { name = "Hair", label = "Hair", size = Vector3.new(1.4, 0.35, 1.4), offset = Vector3.new(0, 2.2, 0), extra = true },
    { name = "Face", label = "Face", size = Vector3.new(1, 0.7, 0.05), offset = Vector3.new(0, 1.5, -0.55), extra = true, faces = { Enum.NormalId.Front } },
}

local ATTACH_OFFSETS = {
    HairAttachment = { "Head", CFrame.new(0, 0.6, 0) },
    HatAttachment = { "Head", CFrame.new(0, 0.6, 0) },
    FaceFrontAttachment = { "Head", CFrame.new(0, 0, -0.6) },
    FaceCenterAttachment = { "Head", CFrame.new(0, 0, 0) },
    NeckAttachment = { "Torso", CFrame.new(0, 1, 0) },
    BodyFrontAttachment = { "Torso", CFrame.new(0, 0, -0.5) },
    BodyBackAttachment = { "Torso", CFrame.new(0, 0, 0.5) },
    WaistFrontAttachment = { "Torso", CFrame.new(0, -1, -0.5) },
    WaistBackAttachment = { "Torso", CFrame.new(0, -1, 0.5) },
    WaistCenterAttachment = { "Torso", CFrame.new(0, -1, 0) },
    LeftCollarAttachment = { "Torso", CFrame.new(-1, 1, 0) },
    RightCollarAttachment = { "Torso", CFrame.new(1, 1, 0) },
    LeftShoulderAttachment = { "LeftArm", CFrame.new(0, 1, 0) },
    RightShoulderAttachment = { "RightArm", CFrame.new(0, 1, 0) },
}

local ACCESSORY_SLOTS = {
    HairAttachment = "Hair",
    HatAttachment = "Hair",
    FaceFrontAttachment = "Face",
    FaceCenterAttachment = "Face",
}

local PART_FIELDS = {
    Label = "label",
    Color = "color",
    Transparency = "transparency",
    Material = "material",
    Visible = "visible",
    Enabled = "enabled",
    Tint = "tint",
    MeshId = "meshId",
    TextureId = "textureId",
    MeshScale = "meshScale",
    Model = "modelId",
    Data = "data",
}

local PART_RESETTABLE = {
    Color = true,
    Transparency = true,
    Material = true,
    MeshId = true,
    TextureId = true,
    MeshScale = true,
    Model = true,
}

local modelCache = {}
local modelWaiting = {}
local assetReady = {}

local function normalizeAsset(value)
    if type(value) == "number" then
        return ASSET_PREFIX .. tostring(math.floor(value))
    end

    if type(value) == "string" and value ~= "" then
        if value:match("^%d+$") then
            return ASSET_PREFIX .. value
        end

        return value
    end

    return nil
end

local function resolveMaterial(value)
    if typeof(value) == "EnumItem" then
        if value.EnumType == Enum.Material then
            return value
        end

        return nil
    end

    if type(value) == "string" then
        local ok, result = pcall(function()
            return Enum.Material[value]
        end)

        if ok then
            return result
        end
    end

    return nil
end

local PART_VALID = {
    Label = function(value)
        return type(value) == "string"
    end,
    Color = function(value)
        return value == false or typeof(value) == "Color3"
    end,
    Transparency = function(value)
        return value == false or (type(value) == "number" and value == value)
    end,
    Material = function(value)
        return value == false or resolveMaterial(value) ~= nil
    end,
    Visible = function(value)
        return type(value) == "boolean"
    end,
    Enabled = function(value)
        return type(value) == "boolean"
    end,
    Tint = function(value)
        return type(value) == "boolean"
    end,
    MeshId = function(value)
        return value == false or normalizeAsset(value) ~= nil
    end,
    TextureId = function(value)
        return value == false or normalizeAsset(value) ~= nil
    end,
    Model = function(value)
        return value == false or normalizeAsset(value) ~= nil
    end,
    MeshScale = function(value)
        return value == false or typeof(value) == "Vector3"
    end,
    Data = function()
        return true
    end,
}

local function preloadAssets(list, done)
    local pending = {}

    for _, value in ipairs(list) do
        local id = normalizeAsset(value)

        if id and not assetReady[id] then
            pending[#pending + 1] = id
        end
    end

    if #pending == 0 then
        if done then
            task.defer(done)
        end

        return
    end

    task.spawn(function()
        pcall(function()
            contentProvider:PreloadAsync(pending)
        end)

        for _, id in ipairs(pending) do
            assetReady[id] = true
        end

        if done then
            pcall(done)
        end
    end)
end

local function sanitizeInstance(instance)
    for _, descendant in ipairs(instance:GetDescendants()) do
        if descendant:IsA("LuaSourceContainer") or descendant:IsA("Sound") or descendant:IsA("Humanoid") then
            descendant:Destroy()
        end
    end
end

local function fetchTemplate(url)
    local result
    local ok, err = pcall(function()
        result = game:GetObjects(url)
    end)

    if not ok or type(result) ~= "table" or result[1] == nil then
        local number = tonumber(url:match("(%d+)$"))

        if not number then
            return nil, tostring(err or "asset not found")
        end

        ok, err = pcall(function()
            result = { game:GetService("InsertService"):LoadAsset(number) }
        end)
    end

    if not ok or type(result) ~= "table" or result[1] == nil then
        return nil, tostring(err or "asset not found")
    end

    local template = result[1]

    if #result > 1 then
        template = Instance.new("Model")

        for _, object in ipairs(result) do
            object.Parent = template
        end
    end

    sanitizeInstance(template)

    return template
end

local function loadTemplate(id, callback)
    local url = normalizeAsset(id)

    if not url then
        callback(nil, "invalid asset id")
        return
    end

    local cached = modelCache[url]

    if cached then
        callback(cached)
        return
    end

    local waiting = modelWaiting[url]

    if waiting then
        waiting[#waiting + 1] = callback
        return
    end

    modelWaiting[url] = { callback }

    task.spawn(function()
        local template, err = fetchTemplate(url)
        local list = modelWaiting[url]

        modelWaiting[url] = nil

        if template then
            modelCache[url] = template
            assetReady[url] = true
        end

        for _, fn in ipairs(list) do
            pcall(fn, template, err)
        end

        if template then
            pcall(function()
                contentProvider:PreloadAsync({ template })
            end)
        end
    end)
end

Elements.Register("Hologram", function(section, options)
    options = type(options) == "table" and options or {}

    local Colors, watchTheme = createColors(section.Panel or Panel)

    local api = {}
    local items = {}
    local connections = {}
    local resizeCallbacks = {}
    local reported = {}
    local destroyed = false
    local paused = false
    local loopConnection
    local unwatchTheme
    local reader
    local readerFailed = false
    local elapsed = 0
    local rate = clampRate(options.rate)
    local title = tostring(options.title or options.Name or "Hologram")
    local height = math.clamp(tonumber(options.height) or HEIGHT_DEFAULT, HEIGHT_MIN, HEIGHT_MAX)
    local showFrame = options.frame ~= false
    local refreshLoop
    local slots = {}
    local slotOrder = {}
    local hasViewer = options.viewer ~= false
    local description = tostring(options.description or options.desc or "")
    local viewColors = copyTable(VIEW_COLORS)
    local partMaterial = resolveMaterial(options.material) or Enum.Material.SmoothPlastic
    local multi = options.multi == true
    local toggle = options.toggle ~= false
    local deselectOnEmpty = options.deselectOnEmpty ~= false
    local rotatable = options.rotatable ~= false
    local showLabel = options.label ~= false
    local yaw = math.rad(tonumber(options.yaw) or 0)
    local zoom = math.clamp(tonumber(options.zoom) or 1, 0.3, 3)
    local spin = math.rad(tonumber(options.spin) or 0)
    local headerH = 0
    local hoverName
    local drag
    local clickCallbacks = {}
    local hoverCallbacks = {}
    local selectCallbacks = {}
    local viewer
    local worldModel
    local camera
    local rig
    local origin
    local partLabel

    if type(options.colors) == "table" then
        for key, value in pairs(options.colors) do
            if VIEW_COLORS[key] and typeof(value) == "Color3" then
                viewColors[key] = value
            end
        end
    end

    local function connect(signal, fn)
        local conn = signal:Connect(fn)
        connections[#connections + 1] = conn
        return conn
    end

    local function report(message, duration)
        local text = ("Hologram '%s': %s"):format(title, message)

        if reported[text] then
            return
        end

        reported[text] = true
        warn(text)
        notify(text, duration or 5)
    end

    local function resolve(value)
        if typeof(value) == "Color3" then
            return value
        end

        return Colors[value]
    end

    local root = create("Frame", {
        Name = title .. "_Hologram",
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = Colors.Palette,
        BackgroundTransparency = showFrame and 0 or 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, section.frame)

    create("UICorner", { CornerRadius = UDim.new(0, 8) }, root)

    local containerStroke = create("UIStroke", {
        Color = Colors.Border,
        Thickness = 1,
        Enabled = showFrame,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, root)

    local fontBold, fontRegular = getFonts()

    local titleLabel = create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        Font = fontBold,
        TextSize = 13,
        TextColor3 = Colors.Active,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 30,
    }, root)

    local descLabel = create("TextLabel", {
        Name = "Description",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        Font = fontRegular,
        TextSize = 11,
        TextColor3 = Colors.Dim,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 30,
    }, root)

    local container = create("Frame", {
        Name = "Stage",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, root)

    local function layoutHeader()
        local hasTitle = title ~= ""
        local hasDesc = description ~= ""
        local y = 6

        titleLabel.Visible = hasTitle
        titleLabel.Text = title
        descLabel.Visible = hasDesc
        descLabel.Text = description

        if hasTitle then
            titleLabel.Position = UDim2.new(0, HEADER_PAD, 0, y)
            titleLabel.Size = UDim2.new(1, -HEADER_PAD * 2, 0, TITLE_H)
            y = y + TITLE_H
        end

        if hasDesc then
            descLabel.Position = UDim2.new(0, HEADER_PAD, 0, y)
            descLabel.Size = UDim2.new(1, -HEADER_PAD * 2, 0, DESC_H)
            y = y + DESC_H
        end

        headerH = (hasTitle or hasDesc) and y + 4 or 0
        container.Position = UDim2.new(0, 0, 0, headerH)
        container.Size = UDim2.new(1, 0, 1, -headerH)
    end

    layoutHeader()

    local function buildPart(id, circle)
        local frame = create("Frame", { Name = id, BorderSizePixel = 0 }, container)
        local corner = create("UICorner", {}, frame)
        local stroke = create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, frame)
        local item = { root = frame }

        function item.render(animate)
            local p = item.props

            corner.CornerRadius = circle and UDim.new(1, 0) or UDim.new(0, p.Corner)
            stroke.Enabled = p.Outline
            stroke.Color = resolve(p.OutlineColor)
            stroke.Thickness = p.OutlineThickness
            stroke.Transparency = p.OutlineTransparency
            frame.Rotation = p.Rotation
            frame.Visible = p.Visible
            frame.ZIndex = p.Layer

            play(frame, {
                Position = UDim2.fromOffset(p.X, p.Y),
                Size = UDim2.fromOffset(p.Width, p.Height),
                BackgroundColor3 = resolve(p.Color),
                BackgroundTransparency = p.Transparency,
            }, animate)
        end

        return item
    end

    local function buildText(id)
        local label = create("TextLabel", {
            Name = id,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            TextStrokeColor3 = Color3.new(0, 0, 0),
        }, container)

        local item = { root = label }

        function item.render(animate)
            local p = item.props
            local bold, regular = getFonts()

            label.Font = p.Bold and bold or regular
            label.TextSize = p.Size
            label.Text = p.Text
            label.TextXAlignment = ALIGN_X[p.Align]
            label.TextYAlignment = ALIGN_Y[p.VAlign]
            label.TextTruncate = p.Truncate and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None
            label.TextWrapped = p.Wrap
            label.TextStrokeTransparency = p.Shadow and 0.5 or 1
            label.Rotation = p.Rotation
            label.Visible = p.Visible
            label.ZIndex = p.Layer

            play(label, {
                Position = UDim2.fromOffset(p.X, p.Y),
                Size = UDim2.fromOffset(p.Width, p.Height),
                TextColor3 = resolve(p.Color),
                TextTransparency = p.Transparency,
            }, animate)
        end

        return item
    end

    local function buildLine(id)
        local frame = create("Frame", { Name = id, BorderSizePixel = 0 }, container)
        local item = { root = frame }

        function item.render(animate)
            local p = item.props

            drawLine(frame, p.X1, p.Y1, p.X2, p.Y2, p.Thickness)
            frame.Visible = p.Visible
            frame.ZIndex = p.Layer

            play(frame, {
                BackgroundColor3 = resolve(p.Color),
                BackgroundTransparency = p.Transparency,
            }, animate)
        end

        return item
    end

    local function buildBar(id)
        local back = create("Frame", { Name = id, BorderSizePixel = 0 }, container)
        local backCorner = create("UICorner", {}, back)
        local backStroke = create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, back)
        local fill = create("Frame", { Name = "Fill", BorderSizePixel = 0 }, back)
        local fillCorner = create("UICorner", {}, fill)
        local item = { root = back }

        function item.render(animate)
            local p = item.props
            local ratio = p.Max > 0 and math.clamp(p.Value / p.Max, 0, 1) or 0
            local pad = math.max(p.Padding, 0)
            local innerW = math.max(p.Width - pad * 2, 0)
            local innerH = math.max(p.Height - pad * 2, 0)
            local anchor
            local position
            local size

            if p.Vertical then
                local top = p.Reverse

                anchor = Vector2.new(0, top and 0 or 1)
                position = UDim2.new(0, pad, top and 0 or 1, top and pad or -pad)
                size = UDim2.fromOffset(innerW, math.floor(innerH * ratio))
            else
                local right = p.Reverse

                anchor = Vector2.new(right and 1 or 0, 0)
                position = UDim2.new(right and 1 or 0, right and -pad or pad, 0, pad)
                size = UDim2.fromOffset(math.floor(innerW * ratio), innerH)
            end

            backCorner.CornerRadius = UDim.new(0, p.Corner)
            fillCorner.CornerRadius = UDim.new(0, math.max(p.Corner - pad, 0))
            backStroke.Enabled = p.Outline
            backStroke.Color = resolve(p.OutlineColor)
            backStroke.Thickness = p.OutlineThickness
            backStroke.Transparency = p.OutlineTransparency
            back.Visible = p.Visible
            back.ZIndex = p.Layer
            fill.ZIndex = p.Layer + 1
            fill.AnchorPoint = anchor
            fill.Position = position

            play(back, {
                Position = UDim2.fromOffset(p.X, p.Y),
                Size = UDim2.fromOffset(p.Width, p.Height),
                BackgroundColor3 = resolve(p.BackColor),
                BackgroundTransparency = p.BackTransparency,
            }, animate)

            play(fill, {
                Size = size,
                BackgroundColor3 = resolve(p.Color),
                BackgroundTransparency = p.Transparency,
            }, animate, BAR_TWEEN_INFO)
        end

        return item
    end

    local function buildImage(id)
        local image = create("ImageLabel", {
            Name = id,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = "",
        }, container)

        local corner = create("UICorner", {}, image)
        local item = { root = image }

        function item.render(animate)
            local p = item.props

            corner.CornerRadius = UDim.new(0, p.Corner)
            image.Image = p.Image
            image.Rotation = p.Rotation
            image.Visible = p.Visible
            image.ZIndex = p.Layer

            play(image, {
                Position = UDim2.fromOffset(p.X, p.Y),
                Size = UDim2.fromOffset(p.Width, p.Height),
                ImageColor3 = resolve(p.Color),
                ImageTransparency = p.Transparency,
            }, animate)
        end

        return item
    end

    local builders = {
        Part = function(id)
            return buildPart(id, false)
        end,
        Circle = function(id)
            return buildPart(id, true)
        end,
        Text = buildText,
        Line = buildLine,
        Bar = buildBar,
        Image = buildImage,
    }

    local rayParams = RaycastParams.new()

    if hasViewer then
        viewer = create("ViewportFrame", {
            Name = "Viewer",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 0,
            Ambient = Color3.fromRGB(150, 150, 150),
            LightColor = Color3.fromRGB(255, 255, 255),
            LightDirection = Vector3.new(0.3, -0.6, 1),
        }, container)

        camera = create("Camera", { FieldOfView = VIEW_FOV }, viewer)
        viewer.CurrentCamera = camera
        worldModel = create("WorldModel", {}, viewer)
        rig = create("Model", { Name = "R6" }, worldModel)

        origin = create("Part", {
            Name = "Origin",
            Size = Vector3.new(0.2, 0.2, 0.2),
            Transparency = 1,
            Anchored = true,
            CanCollide = false,
            CanQuery = false,
            CanTouch = false,
            CFrame = CFrame.new(),
        }, rig)

        rig.PrimaryPart = origin

        partLabel = create("TextLabel", {
            Name = "PartLabel",
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, -4),
            Size = UDim2.new(1, -20, 0, 16),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            Font = fontBold,
            TextSize = 11,
            TextColor3 = Colors.Active,
            TextStrokeColor3 = Color3.new(0, 0, 0),
            TextStrokeTransparency = 0.5,
            Visible = false,
            ZIndex = 30,
        }, container)
    end

    local function applyYaw()
        if rig then
            rig:PivotTo(CFrame.Angles(0, yaw, 0))
        end
    end

    local function updateCamera()
        if not viewer then
            return
        end

        local size = viewer.AbsoluteSize

        if size.X <= 0 or size.Y <= 0 then
            return
        end

        local tanHalf = math.tan(math.rad(camera.FieldOfView) / 2)
        local aspect = size.X / size.Y
        local byHeight = VIEW_HEIGHT / (2 * tanHalf)
        local byWidth = VIEW_WIDTH / (2 * tanHalf * aspect)
        local distance = math.max(byHeight, byWidth) / zoom

        camera.CFrame = CFrame.lookAt(
            Vector3.new(0, VIEW_CENTER_Y, -distance),
            Vector3.new(0, VIEW_CENTER_Y, 0)
        )
    end

    local function renderPart(slot)
        local color = slot.color or viewColors.Base
        local transparency = slot.transparency or 0.45

        if not slot.enabled then
            color = viewColors.Disabled
            transparency = math.max(transparency, 0.7)
        elseif slot.selected then
            color = viewColors.Selected
            transparency = math.min(transparency, 0.1)
        elseif slot.hovered then
            color = viewColors.Hover
            transparency = math.min(transparency, 0.25)
        end

        local showBase = slot.visible

        if slot.replaced then
            showBase = slot.visible and (slot.selected or slot.hovered)
            transparency = math.max(transparency, 0.7)
        end

        slot.part.Color = color
        slot.part.Material = slot.material or partMaterial
        slot.part.Transparency = showBase and transparency or 1
        slot.part.CanQuery = slot.visible and slot.enabled and not slot.replaced

        for _, decal in ipairs(slot.decals) do
            decal.Transparency = showBase and 0 or 1
        end

        local wantParent = slot.visible and rig or nil

        if slot.holder.Parent ~= wantParent then
            slot.holder.Parent = wantParent
        end

        for _, modelPart in ipairs(slot.modelParts) do
            if slot.tint then
                modelPart.Color = color
                modelPart.Transparency = transparency
            end

            modelPart.CanQuery = slot.visible and slot.enabled
        end
    end

    local function updateLabel()
        if not partLabel then
            return
        end

        local text = ""

        if hoverName and slots[hoverName] then
            text = slots[hoverName].label
        else
            local labels = {}

            for _, name in ipairs(slotOrder) do
                local slot = slots[name]

                if slot and slot.selected then
                    labels[#labels + 1] = slot.label
                end
            end

            text = table.concat(labels, ", ")
        end

        partLabel.Text = text
        partLabel.Visible = showLabel and text ~= ""
    end

    local function partInfo(slot)
        return {
            Name = slot.name,
            Label = slot.label,
            Selected = slot.selected,
            Hovered = slot.hovered,
            Enabled = slot.enabled,
            Visible = slot.visible,
            Color = slot.color,
            Transparency = slot.transparency,
            Material = slot.material,
            MeshId = slot.meshId,
            TextureId = slot.textureId,
            ModelId = slot.modelId,
            Data = slot.data,
            Part = slot.part,
        }
    end

    local function applyAssets(slot)
        local part = slot.part

        for _, decal in ipairs(slot.decals) do
            decal:Destroy()
        end

        slot.decals = {}

        if slot.meshId then
            local mesh = slot.mesh

            if not mesh then
                mesh = create("SpecialMesh", {}, part)
                slot.mesh = mesh
            end

            mesh.MeshType = Enum.MeshType.FileMesh
            mesh.MeshId = slot.meshId
            mesh.TextureId = slot.textureId or ""
            mesh.Scale = slot.meshScale or Vector3.new(1, 1, 1)

            return
        end

        if slot.mesh then
            if slot.def.mesh == "Head" then
                slot.mesh.MeshType = Enum.MeshType.Head
                slot.mesh.MeshId = ""
                slot.mesh.TextureId = ""
                slot.mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
            else
                slot.mesh:Destroy()
                slot.mesh = nil
            end
        end

        if slot.textureId then
            for _, face in ipairs(slot.def.faces or ALL_FACES) do
                slot.decals[#slot.decals + 1] = create("Decal", {
                    Texture = slot.textureId,
                    Face = face,
                }, part)
            end
        end
    end

    local function clearModel(slot)
        for _, child in ipairs(slot.holder:GetChildren()) do
            child:Destroy()
        end

        slot.modelParts = {}
        slot.replaced = false
    end

    local function collectParts(slot)
        local list = {}

        for _, descendant in ipairs(slot.holder:GetDescendants()) do
            if descendant:IsA("BasePart") then
                list[#list + 1] = descendant
            end
        end

        slot.modelParts = list
    end

    local function attachModel(slot, template, opts)
        local clone = template:Clone()
        local handle

        if clone:IsA("BasePart") then
            handle = clone
        elseif clone:IsA("Accoutrement") then
            handle = clone:FindFirstChild("Handle")
        else
            handle = clone:IsA("Model") and clone.PrimaryPart or nil
        end

        if not handle then
            handle = clone:FindFirstChildWhichIsA("BasePart", true)
        end

        if not handle then
            clone:Destroy()
            return false
        end

        local target = slot.part.CFrame
        local attachment = handle:FindFirstChildOfClass("Attachment")
        local mapped = attachment and ATTACH_OFFSETS[attachment.Name]

        if mapped then
            local base = slots[mapped[1]]
            local baseCFrame = base and base.part.CFrame or slot.part.CFrame

            target = baseCFrame * mapped[2] * attachment.CFrame:Inverse()
        end

        if typeof(opts.offset) == "Vector3" then
            target = target * CFrame.new(opts.offset)
        end

        local delta = target * handle.CFrame:Inverse()
        local parts = {}

        if clone:IsA("BasePart") then
            parts[1] = clone
        end

        for _, descendant in ipairs(clone:GetDescendants()) do
            if descendant:IsA("BasePart") then
                parts[#parts + 1] = descendant
            end
        end

        for _, part in ipairs(parts) do
            part.Anchored = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = true
            part.CastShadow = false
            part:SetAttribute("HoloSlot", slot.name)
            part.CFrame = delta * part.CFrame
        end

        if not opts.append then
            clearModel(slot)
        end

        clone.Parent = slot.holder
        collectParts(slot)

        local tint = opts.tint

        if tint == nil then
            tint = slot.tint
        end

        slot.tint = tint == true

        if opts.replace == nil then
            slot.replaced = slot.def.extra == true
        else
            slot.replaced = opts.replace == true
        end

        renderPart(slot)

        return true
    end

    local function startModel(slot, opts, callback)
        opts = type(opts) == "table" and opts or {}
        slot.loadToken = slot.loadToken + 1

        local token = slot.loadToken

        if not slot.modelId then
            clearModel(slot)
            renderPart(slot)

            if callback then
                pcall(callback, true, nil)
            end

            return
        end

        loadTemplate(slot.modelId, function(template, err)
            if destroyed or slots[slot.name] ~= slot or slot.loadToken ~= token then
                return
            end

            if not template then
                report(("could not load model '%s': %s"):format(tostring(slot.modelId), tostring(err)))

                if callback then
                    pcall(callback, false, err)
                end

                return
            end

            local ok = attachModel(slot, template, opts)

            if callback then
                pcall(callback, ok, slot.holder)
            end
        end)
    end

    local function addSlot(name, def)
        if not hasViewer then
            return nil
        end

        if type(name) ~= "string" or name == "" then
            report("body part name must be a non-empty string.")
            return nil
        end

        if slots[name] then
            report(("body part '%s' already exists."):format(name))
            return nil
        end

        local shape = Enum.PartType.Block

        if type(def.shape) == "string" then
            local ok, result = pcall(function()
                return Enum.PartType[def.shape]
            end)

            if ok and result then
                shape = result
            end
        end

        local part = create("Part", {
            Name = name,
            Shape = shape,
            Size = def.size,
            Anchored = true,
            CanCollide = false,
            CanTouch = false,
            CastShadow = false,
            TopSurface = Enum.SurfaceType.Smooth,
            BottomSurface = Enum.SurfaceType.Smooth,
        }, nil)

        part.CFrame = origin.CFrame * def.cframe
        part:SetAttribute("HoloSlot", name)

        local slot = {
            name = name,
            label = def.label or name,
            part = part,
            def = def,
            baseCFrame = def.cframe,
            holder = create("Model", { Name = name .. "_Attach" }, nil),
            decals = {},
            modelParts = {},
            live = {},
            liveFailed = {},
            enabled = true,
            visible = true,
            selected = false,
            hovered = false,
            replaced = false,
            tint = false,
            loadToken = 0,
        }

        if def.mesh == "Head" then
            slot.mesh = create("SpecialMesh", {
                MeshType = Enum.MeshType.Head,
                Scale = Vector3.new(1.25, 1.25, 1.25),
            }, part)
        end

        part.Parent = rig
        slots[name] = slot
        slotOrder[#slotOrder + 1] = name
        renderPart(slot)

        return slot
    end

    local function removeSlot(name)
        local slot = slots[name]

        if not slot then
            return false
        end

        slots[name] = nil

        for index, value in ipairs(slotOrder) do
            if value == name then
                table.remove(slotOrder, index)
                break
            end
        end

        if hoverName == name then
            hoverName = nil
        end

        slot.loadToken = slot.loadToken + 1
        slot.part:Destroy()
        slot.holder:Destroy()
        updateLabel()
        refreshLoop()

        return true
    end

    local function setHover(name)
        if hoverName == name then
            return
        end

        local previous = hoverName and slots[hoverName]

        hoverName = name

        if previous then
            previous.hovered = false
            renderPart(previous)
        end

        local current = name and slots[name]

        if current then
            current.hovered = true
            renderPart(current)
        end

        updateLabel()

        for fn in pairs(hoverCallbacks) do
            pcall(fn, name, current and partInfo(current) or nil, api)
        end
    end

    local function fireSelect()
        local list = api:GetSelected()

        for fn in pairs(selectCallbacks) do
            pcall(fn, list, api)
        end
    end

    local function setSlotField(slot, key, value)
        if PART_RESETTABLE[key] and value == false then
            value = nil
        end

        if key == "Material" and value ~= nil then
            value = resolveMaterial(value)
        end

        if (key == "MeshId" or key == "TextureId" or key == "Model") and value ~= nil then
            value = normalizeAsset(value)
        end

        local field = PART_FIELDS[key]

        if slot[field] == value then
            return false
        end

        slot[field] = value

        return true
    end

    local function applyPartPatch(slot, patch, fromLive)
        local visual = false
        local assets = false
        local model = false
        local liveChanged = false

        for key, value in pairs(patch) do
            local valid = PART_VALID[key]

            if not valid then
                report(("invalid part property '%s' on '%s'."):format(tostring(key), slot.name))
            elseif type(value) == "function" and not fromLive then
                slot.live[key] = value
                slot.liveFailed[key] = nil
                liveChanged = true
            elseif valid(value) then
                if setSlotField(slot, key, value) then
                    if key == "MeshId" or key == "TextureId" or key == "MeshScale" then
                        assets = true
                    elseif key == "Model" then
                        model = true
                    else
                        visual = true
                    end
                end

                if fromLive then
                    slot.liveFailed[key] = nil
                elseif slot.live[key] then
                    slot.live[key] = nil
                    liveChanged = true
                end
            elseif fromLive then
                if not slot.liveFailed[key] then
                    slot.liveFailed[key] = true
                    report(("live '%s' on '%s' returned an invalid value."):format(key, slot.name))
                end
            else
                report(("invalid value for '%s' on '%s'."):format(key, slot.name))
            end
        end

        if liveChanged then
            refreshLoop()
        end

        if assets then
            applyAssets(slot)
            preloadAssets({ slot.meshId, slot.textureId })
            visual = true
        end

        if model then
            startModel(slot, nil, nil)
        end

        if visual then
            renderPart(slot)
            updateLabel()
        end

        return visual or assets or model
    end

    local function pollSlot(name, slot)
        local keys = {}

        for key in pairs(slot.live) do
            keys[#keys + 1] = key
        end

        if #keys == 0 then
            return
        end

        local patch = {}
        local any = false

        for _, key in ipairs(keys) do
            local fn = slot.live[key]

            if fn then
                local ok, result = pcall(fn, api, name)

                if not ok then
                    if not slot.liveFailed[key] then
                        slot.liveFailed[key] = true
                        report(("live '%s' on '%s': %s"):format(key, name, tostring(result)))
                    end
                elseif result ~= nil then
                    patch[key] = result
                    any = true
                end
            end
        end

        if any then
            applyPartPatch(slot, patch, true)
        end
    end

    local function resetSlot(slot)
        slot.loadToken = slot.loadToken + 1
        clearModel(slot)
        slot.color = nil
        slot.transparency = nil
        slot.material = nil
        slot.meshId = nil
        slot.textureId = nil
        slot.meshScale = nil
        slot.modelId = nil
        slot.tint = false
        slot.enabled = true
        slot.visible = true
        applyAssets(slot)
        renderPart(slot)
    end

    local function isShown()
        local object = root

        while object do
            if object:IsA("GuiObject") and not object.Visible then
                return false
            end

            if object:IsA("LayerCollector") then
                return object.Enabled
            end

            object = object.Parent
        end

        return false
    end

    local function visibleAt(point)
        local object = viewer

        while object do
            if object:IsA("GuiObject") and (object == viewer or object.ClipsDescendants) then
                local position = object.AbsolutePosition
                local size = object.AbsoluteSize

                if point.X < position.X or point.Y < position.Y or point.X > position.X + size.X or point.Y > position.Y + size.Y then
                    return false
                end
            end

            object = object.Parent
        end

        return true
    end

    local function inputPoint(input)
        local point = Vector2.new(input.Position.X, input.Position.Y)
        local gui = root:FindFirstAncestorWhichIsA("ScreenGui")

        if gui and gui.IgnoreGuiInset then
            point = point + guiService:GetGuiInset()
        end

        return point
    end

    local function pick(point)
        local position = viewer.AbsolutePosition
        local size = viewer.AbsoluteSize

        if size.X <= 0 or size.Y <= 0 then
            return nil
        end

        local nx = ((point.X - position.X) / size.X) * 2 - 1
        local ny = 1 - ((point.Y - position.Y) / size.Y) * 2
        local tanHalf = math.tan(math.rad(camera.FieldOfView) / 2)
        local aspect = size.X / size.Y
        local direction = camera.CFrame:VectorToWorldSpace(Vector3.new(nx * tanHalf * aspect, ny * tanHalf, -1)).Unit
        local result = worldModel:Raycast(camera.CFrame.Position, direction * PICK_RANGE, rayParams)

        if not result then
            return nil
        end

        local name = result.Instance:GetAttribute("HoloSlot")

        if name and slots[name] then
            return name
        end

        return nil
    end

    local function handleClick(name)
        if name then
            local slot = slots[name]
            local state = not (slot.selected and toggle)

            api:SelectPart(name, state)

            for fn in pairs(clickCallbacks) do
                pcall(fn, name, partInfo(slot), api)
            end
        elseif deselectOnEmpty then
            api:ClearSelection()
        end
    end

    if hasViewer then
        connect(viewer:GetPropertyChangedSignal("AbsoluteSize"), updateCamera)

        connect(userInputService.InputBegan, function(input)
            if destroyed then
                return
            end

            local kind = input.UserInputType

            if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then
                return
            end

            if not isShown() then
                return
            end

            local point = inputPoint(input)

            if not visibleAt(point) then
                return
            end

            drag = {
                input = input,
                start = point,
                last = point,
                moved = false,
            }
        end)

        connect(userInputService.InputChanged, function(input)
            if destroyed then
                return
            end

            local kind = input.UserInputType

            if drag then
                local same = input == drag.input
                    or (kind == Enum.UserInputType.MouseMovement and drag.input.UserInputType == Enum.UserInputType.MouseButton1)

                if same then
                    local point = inputPoint(input)
                    local delta = point - drag.last

                    drag.last = point

                    if not drag.moved and (point - drag.start).Magnitude > DRAG_THRESHOLD then
                        drag.moved = true
                    end

                    if drag.moved and rotatable then
                        yaw = yaw + delta.X * DRAG_SENSITIVITY
                        applyYaw()
                    end
                end

                return
            end

            if kind == Enum.UserInputType.MouseMovement then
                if not isShown() then
                    setHover(nil)
                    return
                end

                local point = inputPoint(input)

                if visibleAt(point) then
                    setHover(pick(point))
                else
                    setHover(nil)
                end
            end
        end)

        connect(userInputService.InputEnded, function(input)
            if destroyed or not drag then
                return
            end

            local same = input == drag.input
                or (input.UserInputType == Enum.UserInputType.MouseButton1 and drag.input.UserInputType == Enum.UserInputType.MouseButton1)

            if not same then
                return
            end

            local finished = drag

            drag = nil

            if not finished.moved then
                handleClick(pick(finished.start))
            end
        end)
    end

    function api:SetPart(name, patch)
        if destroyed then
            return false
        end

        local slot = slots[name]

        if not slot or type(patch) ~= "table" then
            return false
        end

        return applyPartPatch(slot, patch, false)
    end

    function api:SetParts(map)
        if destroyed or type(map) ~= "table" then
            return false
        end

        local any = false

        for name, patch in pairs(map) do
            if api:SetPart(name, patch) then
                any = true
            end
        end

        return any
    end

    function api:GetPart(name)
        local slot = slots[name]

        if not slot then
            return nil
        end

        return partInfo(slot)
    end

    function api:HasPart(name)
        return slots[name] ~= nil
    end

    function api:ListParts()
        return copyTable(slotOrder)
    end

    function api:AddBodyPart(name, props)
        if destroyed then
            return false
        end

        props = type(props) == "table" and props or {}

        local cframe = CFrame.new()

        if typeof(props.Offset) == "CFrame" then
            cframe = props.Offset
        elseif typeof(props.Offset) == "Vector3" then
            cframe = CFrame.new(props.Offset)
        end

        local parent = type(props.Parent) == "string" and slots[props.Parent] or nil

        if parent then
            cframe = parent.baseCFrame * cframe
        end

        local slot = addSlot(name, {
            size = typeof(props.Size) == "Vector3" and props.Size or Vector3.new(1, 1, 1),
            cframe = cframe,
            shape = props.Shape,
            label = type(props.Label) == "string" and props.Label or nil,
            extra = props.Extra == true,
        })

        if not slot then
            return false
        end

        local patch = {}

        for key, value in pairs(props) do
            if PART_VALID[key] then
                patch[key] = value
            end
        end

        applyPartPatch(slot, patch, false)

        return true
    end

    function api:RemoveBodyPart(name)
        local slot = slots[name]

        if not slot then
            return false
        end

        local wasSelected = slot.selected

        removeSlot(name)

        if wasSelected then
            fireSelect()
        end

        return true
    end

    function api:SelectPart(name, state)
        local slot = slots[name]

        if not slot then
            return false
        end

        if state == nil then
            state = true
        end

        if state and not slot.enabled then
            return false
        end

        if state and not multi then
            for _, other in pairs(slots) do
                if other ~= slot and other.selected then
                    other.selected = false
                    renderPart(other)
                end
            end
        end

        if slot.selected == state then
            return true
        end

        slot.selected = state
        renderPart(slot)
        updateLabel()
        fireSelect()

        return true
    end

    function api:DeselectPart(name)
        return api:SelectPart(name, false)
    end

    function api:ClearSelection()
        local any = false

        for _, slot in pairs(slots) do
            if slot.selected then
                slot.selected = false
                renderPart(slot)
                any = true
            end
        end

        if any then
            updateLabel()
            fireSelect()
        end

        return any
    end

    function api:GetSelected()
        local list = {}

        for _, name in ipairs(slotOrder) do
            local slot = slots[name]

            if slot and slot.selected then
                list[#list + 1] = name
            end
        end

        return list
    end

    function api:IsSelected(name)
        local slot = slots[name]

        return slot ~= nil and slot.selected
    end

    function api:OnPartClick(fn)
        if type(fn) ~= "function" then
            return function() end
        end

        clickCallbacks[fn] = true

        return function()
            clickCallbacks[fn] = nil
        end
    end

    function api:OnPartHover(fn)
        if type(fn) ~= "function" then
            return function() end
        end

        hoverCallbacks[fn] = true

        return function()
            hoverCallbacks[fn] = nil
        end
    end

    function api:OnSelect(fn)
        if type(fn) ~= "function" then
            return function() end
        end

        selectCallbacks[fn] = true

        return function()
            selectCallbacks[fn] = nil
        end
    end

    function api:SetPartLive(name, key, fn)
        local slot = slots[name]

        if not slot or type(fn) ~= "function" then
            return false
        end

        if not PART_VALID[key] then
            report(("invalid part property '%s' on '%s'."):format(tostring(key), name))
            return false
        end

        slot.live[key] = fn
        slot.liveFailed[key] = nil
        refreshLoop()
        pollSlot(name, slot)

        return true
    end

    function api:ClearPartLive(name, key)
        local slot = slots[name]

        if not slot then
            return false
        end

        if key == nil then
            table.clear(slot.live)
            table.clear(slot.liveFailed)
        else
            slot.live[key] = nil
            slot.liveFailed[key] = nil
        end

        refreshLoop()

        return true
    end

    function api:LoadModel(name, id, opts, callback)
        if destroyed then
            return false
        end

        local slot = slots[name]

        if not slot then
            report(("body part '%s' not found."):format(tostring(name)))
            return false
        end

        slot.modelId = id and normalizeAsset(id) or nil
        startModel(slot, opts, callback)

        return true
    end

    function api:ClearModel(name)
        return api:LoadModel(name, nil)
    end

    function api:LoadAppearance(user, opts, callback)
        if destroyed then
            return false
        end

        opts = type(opts) == "table" and opts or {}

        task.spawn(function()
            local userId = tonumber(user)

            if not userId and type(user) == "string" then
                local ok, result = pcall(function()
                    return players:GetUserIdFromNameAsync(user)
                end)

                if ok then
                    userId = result
                end
            end

            if not userId then
                report(("user '%s' not found."):format(tostring(user)))

                if callback then
                    pcall(callback, false, "user not found")
                end

                return
            end

            local ok, appearance = pcall(function()
                return players:GetCharacterAppearanceAsync(userId)
            end)

            if not ok or typeof(appearance) ~= "Instance" then
                report(("could not load appearance of '%s'."):format(tostring(user)))

                if callback then
                    pcall(callback, false, tostring(appearance))
                end

                return
            end

            if destroyed then
                appearance:Destroy()
                return
            end

            sanitizeInstance(appearance)

            local info = {}

            local processed, err = pcall(function()
                local bodyColors = appearance:FindFirstChildOfClass("BodyColors")

                if bodyColors and opts.skin ~= false then
                    for name, property in pairs(BODY_COLORS) do
                        local slot = slots[name]

                        if slot then
                            slot.color = bodyColors[property]
                            renderPart(slot)
                        end
                    end
                end

                local shirt = appearance:FindFirstChildOfClass("Shirt")
                local pants = appearance:FindFirstChildOfClass("Pants")

                info.Shirt = shirt and shirt.ShirtTemplate or nil
                info.Pants = pants and pants.PantsTemplate or nil

                local headPart = appearance:FindFirstChild("Head")
                local faceDecal = headPart and headPart:FindFirstChildWhichIsA("Decal") or nil

                if faceDecal and slots.Face then
                    info.Face = faceDecal.Texture
                    api:SetPart("Face", { TextureId = faceDecal.Texture })
                end

                local cleared = {}

                for _, accessory in ipairs(appearance:GetChildren()) do
                    if accessory:IsA("Accoutrement") then
                        local handle = accessory:FindFirstChild("Handle")
                        local attachment = handle and handle:FindFirstChildOfClass("Attachment") or nil
                        local target = attachment and ACCESSORY_SLOTS[attachment.Name] or nil
                        local replace = true

                        if not target then
                            target = "Torso"
                            replace = false
                        end

                        local slot = slots[target]

                        if slot then
                            local first = not cleared[target]

                            if first then
                                cleared[target] = true
                                clearModel(slot)
                            end

                            attachModel(slot, accessory, {
                                append = true,
                                replace = replace,
                                tint = opts.tint,
                            })
                        end
                    end
                end
            end)

            appearance:Destroy()

            if callback then
                pcall(callback, processed, processed and info or tostring(err))
            end
        end)

        return true
    end

    function api:ResetPart(name)
        local slot = slots[name]

        if not slot then
            return false
        end

        resetSlot(slot)
        updateLabel()

        return true
    end

    function api:ResetParts()
        for _, name in ipairs(slotOrder) do
            resetSlot(slots[name])
        end

        updateLabel()

        return true
    end

    function api:Preload(list, callback)
        if type(list) ~= "table" then
            return false
        end

        preloadAssets(list, callback)

        return true
    end

    function api:IsLoaded(id)
        local url = normalizeAsset(id)

        return url ~= nil and assetReady[url] == true
    end

    function api:SetYaw(degrees)
        yaw = math.rad(tonumber(degrees) or 0)
        applyYaw()
    end

    function api:GetYaw()
        return math.deg(yaw)
    end

    function api:SetSpin(degreesPerSecond)
        spin = math.rad(tonumber(degreesPerSecond) or 0)
        refreshLoop()
    end

    function api:SetZoom(value)
        zoom = math.clamp(tonumber(value) or zoom, 0.3, 3)
        updateCamera()
    end

    function api:SetRotatable(value)
        rotatable = value == true
    end

    function api:SetLabelVisible(value)
        showLabel = value == true
        updateLabel()
    end

    function api:SetViewColors(patch)
        if type(patch) ~= "table" then
            return false
        end

        for key, value in pairs(patch) do
            if VIEW_COLORS[key] and typeof(value) == "Color3" then
                viewColors[key] = value
            end
        end

        for _, slot in pairs(slots) do
            renderPart(slot)
        end

        return true
    end

    function api:SetMaterial(value)
        local material = resolveMaterial(value)

        if not material then
            report("invalid material.")
            return false
        end

        partMaterial = material

        for _, slot in pairs(slots) do
            renderPart(slot)
        end

        return true
    end

    function api:SetDescription(value)
        value = tostring(value or "")

        if value == description then
            return
        end

        description = value
        layoutHeader()
    end

    function api:GetDescription()
        return description
    end

    function api:GetTitle()
        return title
    end

    if hasViewer then
        local include

        if type(options.parts) == "table" then
            include = {}

            for _, name in ipairs(options.parts) do
                include[name] = true
            end
        end

        if options.r6 ~= false then
            for _, def in ipairs(R6_PARTS) do
                if not include or include[def.name] then
                    addSlot(def.name, {
                        size = def.size,
                        cframe = CFrame.new(def.offset),
                        mesh = def.mesh,
                        label = def.label,
                        extra = def.extra,
                        faces = def.faces,
                    })
                end
            end
        end

        applyYaw()
        updateCamera()
    end

    local function applyPatch(id, item, patch, fromLive)
        local schema = SPECS[item.kind].schema
        local changed = false
        local liveChanged = false

        for key, value in pairs(patch) do
            local spec = schema[key]

            if not spec then
                report(("invalid property '%s' on '%s'."):format(tostring(key), id))
            elseif type(value) == "function" and not fromLive then
                item.live[key] = value
                item.liveFailed[key] = nil
                liveChanged = true
            else
                if key == "Text" and type(value) ~= "string" then
                    value = tostring(value)
                end

                if isValid(spec, value) then
                    if item.props[key] ~= value then
                        item.props[key] = value
                        changed = true
                    end

                    if fromLive then
                        item.liveFailed[key] = nil
                    elseif item.live[key] then
                        item.live[key] = nil
                        liveChanged = true
                    end
                elseif fromLive then
                    if not item.liveFailed[key] then
                        item.liveFailed[key] = true
                        report(("live '%s' on '%s' returned an invalid value."):format(key, id))
                    end
                else
                    report(("invalid value for '%s' on '%s'."):format(key, id))
                end
            end
        end

        if liveChanged then
            refreshLoop()
        end

        return changed
    end

    local function pollItem(id, item)
        local keys = {}

        for key in pairs(item.live) do
            keys[#keys + 1] = key
        end

        if #keys == 0 then
            return
        end

        local patch = {}
        local any = false

        for _, key in ipairs(keys) do
            local fn = item.live[key]

            if fn then
                local ok, result = pcall(fn, api, id)

                if not ok then
                    if not item.liveFailed[key] then
                        item.liveFailed[key] = true
                        report(("live '%s' on '%s': %s"):format(key, id, tostring(result)))
                    end
                elseif result ~= nil then
                    patch[key] = result
                    any = true
                end
            end
        end

        if any and applyPatch(id, item, patch, true) then
            item.render(item.props.Animate)
        end
    end

    local function poll(delta)
        if reader then
            local ok, result = pcall(reader, api, delta)

            if ok then
                readerFailed = false

                if type(result) == "table" then
                    if type(result.Header) == "table" then
                        if result.Header.Title ~= nil then
                            api:SetTitle(result.Header.Title)
                        end

                        if result.Header.Description ~= nil then
                            api:SetDescription(result.Header.Description)
                        end
                    end

                    if type(result.Parts) == "table" then
                        api:SetParts(result.Parts)
                    end

                    api:Update(result)
                end
            elseif not readerFailed then
                readerFailed = true
                report(("bind: %s"):format(tostring(result)))
            end
        end

        if destroyed then
            return
        end

        local ids = {}

        for id, item in pairs(items) do
            if next(item.live) ~= nil then
                ids[#ids + 1] = id
            end
        end

        for _, id in ipairs(ids) do
            local item = items[id]

            if item then
                pollItem(id, item)
            end
        end

        local names = {}

        for name, slot in pairs(slots) do
            if next(slot.live) ~= nil then
                names[#names + 1] = name
            end
        end

        for _, name in ipairs(names) do
            local slot = slots[name]

            if slot then
                pollSlot(name, slot)
            end
        end
    end

    local function step(dt)
        if destroyed or paused then
            return
        end

        if spin ~= 0 and not (drag and drag.moved) then
            yaw = yaw + spin * dt
            applyYaw()
        end

        elapsed = elapsed + dt

        if elapsed < rate then
            return
        end

        local delta = elapsed

        elapsed = 0
        poll(delta)
    end

    local function hasLive()
        for _, item in pairs(items) do
            if next(item.live) ~= nil then
                return true
            end
        end

        for _, slot in pairs(slots) do
            if next(slot.live) ~= nil then
                return true
            end
        end

        return false
    end

    refreshLoop = function()
        local needed = not destroyed and not paused and (reader ~= nil or hasLive() or spin ~= 0)

        if needed and not loopConnection then
            loopConnection = runService.Heartbeat:Connect(step)
        elseif not needed and loopConnection then
            loopConnection:Disconnect()
            loopConnection = nil
        end
    end

    local function addItem(kind, id, props)
        if destroyed then
            return false
        end

        local spec = SPECS[kind]

        if not spec then
            report(("unknown element kind '%s'."):format(tostring(kind)))
            return false
        end

        if type(id) ~= "string" or id == "" then
            report("element id must be a non-empty string.")
            return false
        end

        if items[id] then
            report(("element '%s' already exists."):format(id))
            return false
        end

        local item = builders[kind](id)

        item.kind = kind
        item.props = copyTable(spec.defaults)
        item.live = {}
        item.liveFailed = {}
        items[id] = item

        applyPatch(id, item, type(props) == "table" and props or {}, false)
        item.render(false)
        refreshLoop()

        return true
    end

    local function applyTheme()
        if destroyed then
            return
        end

        if showFrame then
            root.BackgroundColor3 = Colors.Palette
            containerStroke.Color = Colors.Border
        end

        titleLabel.TextColor3 = Colors.Active
        descLabel.TextColor3 = Colors.Dim

        if partLabel then
            partLabel.TextColor3 = Colors.Active
        end

        for _, item in pairs(items) do
            item.render(false)
        end
    end

    function api:Add(kind, id, props)
        return addItem(kind, id, props)
    end

    function api:AddPart(id, props)
        return addItem("Part", id, props)
    end

    function api:AddCircle(id, props)
        return addItem("Circle", id, props)
    end

    function api:AddText(id, props)
        return addItem("Text", id, props)
    end

    function api:AddLine(id, props)
        return addItem("Line", id, props)
    end

    function api:AddBar(id, props)
        return addItem("Bar", id, props)
    end

    function api:AddImage(id, props)
        return addItem("Image", id, props)
    end

    function api:Update(first, second, third)
        if destroyed then
            return false
        end

        if type(first) == "table" then
            local any = false

            for id, patch in pairs(first) do
                if api:Update(id, patch, second) then
                    any = true
                end
            end

            return any
        end

        local item = items[first]

        if not item or type(second) ~= "table" then
            return false
        end

        local changed = applyPatch(first, item, second, false)

        if changed then
            local animate = third

            if animate == nil then
                animate = item.props.Animate
            end

            item.render(animate == true)
        end

        return changed
    end

    function api:Set(id, key, value, animate)
        if key == nil then
            return false
        end

        return api:Update(id, { [key] = value }, animate)
    end

    function api:Get(id, key)
        local item = items[id]

        if not item then
            return nil
        end

        return item.props[key]
    end

    function api:GetAll(id)
        local item = items[id]

        if not item then
            return nil
        end

        local copy = copyTable(item.props)

        copy.Kind = item.kind

        return copy
    end

    function api:Has(id)
        return items[id] ~= nil
    end

    function api:List()
        local ids = {}

        for id in pairs(items) do
            ids[#ids + 1] = id
        end

        table.sort(ids)

        return ids
    end

    function api:Count()
        local count = 0

        for _ in pairs(items) do
            count = count + 1
        end

        return count
    end

    function api:Remove(id)
        local item = items[id]

        if not item then
            return false
        end

        items[id] = nil
        item.root:Destroy()
        refreshLoop()

        return true
    end

    function api:Clear()
        for _, id in ipairs(api:List()) do
            api:Remove(id)
        end
    end

    function api:SetLive(id, key, fn)
        local item = items[id]

        if not item or type(fn) ~= "function" then
            return false
        end

        if not SPECS[item.kind].schema[key] then
            report(("invalid property '%s' on '%s'."):format(tostring(key), id))
            return false
        end

        item.live[key] = fn
        item.liveFailed[key] = nil
        refreshLoop()
        pollItem(id, item)

        return true
    end

    function api:ClearLive(id, key)
        local item = items[id]

        if not item then
            return false
        end

        if key == nil then
            table.clear(item.live)
            table.clear(item.liveFailed)
        else
            item.live[key] = nil
            item.liveFailed[key] = nil
        end

        refreshLoop()

        return true
    end

    function api:Bind(fn)
        if destroyed then
            return false
        end

        if fn == nil or fn == false then
            reader = nil
            readerFailed = false
            refreshLoop()

            return true
        end

        if type(fn) ~= "function" then
            report("Bind expects a function.")
            return false
        end

        reader = fn
        readerFailed = false
        elapsed = 0
        refreshLoop()
        poll(0)

        return true
    end

    function api:Unbind()
        return api:Bind(nil)
    end

    function api:GetBound()
        return reader
    end

    function api:Pause()
        if destroyed then
            return
        end

        paused = true
        refreshLoop()
    end

    function api:Resume()
        if destroyed then
            return
        end

        paused = false
        elapsed = rate
        refreshLoop()
    end

    function api:IsPaused()
        return paused
    end

    function api:SetRate(value)
        rate = clampRate(value)
    end

    function api:GetRate()
        return rate
    end

    function api:SetTitle(value)
        value = tostring(value or "")

        if value == title then
            return
        end

        title = value
        root.Name = title .. "_Hologram"
        layoutHeader()
    end

    function api:SetVisible(value)
        if destroyed then
            return
        end

        root.Visible = value == true
    end

    function api:SetHeight(value)
        if destroyed then
            return
        end

        height = math.clamp(tonumber(value) or height, HEIGHT_MIN, HEIGHT_MAX)
        root.Size = UDim2.new(1, 0, 0, height)
    end

    function api:GetSize()
        return container.AbsoluteSize
    end

    function api:OnResize(fn)
        if type(fn) ~= "function" then
            return function() end
        end

        resizeCallbacks[fn] = true

        return function()
            resizeCallbacks[fn] = nil
        end
    end

    function api:Destroy()
        if destroyed then
            return
        end

        destroyed = true
        reader = nil

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
        table.clear(resizeCallbacks)
        table.clear(items)
        table.clear(slots)
        table.clear(slotOrder)
        table.clear(clickCallbacks)
        table.clear(hoverCallbacks)
        table.clear(selectCallbacks)
        drag = nil
        root:Destroy()
    end

    connect(container:GetPropertyChangedSignal("AbsoluteSize"), function()
        local size = container.AbsoluteSize

        for fn in pairs(resizeCallbacks) do
            local ok, err = pcall(fn, size, api)

            if not ok then
                report(("resize: %s"):format(tostring(err)))
            end
        end
    end)

    if type(options.preload) == "table" then
        preloadAssets(options.preload)
    end

    if hasViewer then
        if type(options.partData) == "table" then
            api:SetParts(options.partData)
        end

        if type(options.onClick) == "function" then
            api:OnPartClick(options.onClick)
        end

        if type(options.onHover) == "function" then
            api:OnPartHover(options.onHover)
        end

        if type(options.onSelect) == "function" then
            api:OnSelect(options.onSelect)
        end

        if options.appearance ~= nil then
            api:LoadAppearance(options.appearance, options.appearanceOptions)
        end
    end

    if type(options.items) == "table" then
        for _, entry in ipairs(options.items) do
            if type(entry) == "table" then
                addItem(entry.kind or entry.Kind, entry.id or entry.Id, entry.props or entry.Props)
            end
        end
    end

    if type(options.init) == "function" then
        local ok, err = pcall(options.init, api)

        if not ok then
            report(("init: %s"):format(tostring(err)))
        end
    end

    if type(options.bind) == "function" then
        api:Bind(options.bind)
    end

    refreshLoop()

    unwatchTheme = watchTheme(applyTheme)

    return api
end)