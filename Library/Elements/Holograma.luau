-- // Services
local runService = game:GetService("RunService")

-- // Themes
local Default = {
    Active = Color3.fromRGB(240, 240, 240),
    Dim = Color3.fromRGB(115, 115, 115),
    Border = Color3.fromRGB(55, 55, 55),
    Palette = Color3.fromRGB(28, 28, 28),
}
local THEME_KEYS = { "Active", "Dim", "Border", "Palette" }
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
        end,
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

-- // Constants
local NOTIFY_TITLE = "System"
local HEIGHT_DEFAULT = 190
local HEIGHT_MIN = 110
local HEIGHT_MAX = 500
local TITLE_H = 16
local DESC_H = 14
local FOOTER_PAD = 8
local SIDE_PAD = 10
local VIEW_FOV = 40
local VIEW_X = 9
local VIEW_Y = 5.6
local VIEW_CENTER = Vector3.new(-0.3, 0, 0)
local LAYING = CFrame.Angles(0, 0, math.rad(-90))
local BOX_PAD = 4
local CORNER_RATIO = 0.25
local LINE_THICKNESS = 1
local HEALTH_RATIO = 0.75
local TRACER_ORIGINS = { Bottom = 1, Center = 0.5, Top = 0 }
local SETTINGS_SCHEMA = {
    Box = "boolean",
    BoxStyle = { Full = true, Corner = true },
    Skeleton = "boolean",
    Tracer = "boolean",
    TracerOrigin = { Bottom = true, Center = true, Top = true },
    Name = "boolean",
    Health = "boolean",
}
local SETTINGS_DEFAULTS = {
    Box = false,
    BoxStyle = "Full",
    Skeleton = false,
    Tracer = false,
    TracerOrigin = "Bottom",
    Name = false,
    Health = false,
}
local COLOR_DEFAULTS = {
    Box = Color3.fromRGB(255, 255, 255),
    Skeleton = Color3.fromRGB(255, 255, 255),
    Tracer = Color3.fromRGB(255, 255, 255),
    Name = Color3.fromRGB(255, 255, 255),
    Health = Color3.fromRGB(80, 220, 120),
    Hologram = Color3.fromRGB(110, 190, 255),
}
local R6_PARTS = {
    { name = "Head", size = Vector3.new(2, 1, 1), offset = Vector3.new(0, 1.5, 0), head = true },
    { name = "Torso", size = Vector3.new(2, 2, 1), offset = Vector3.new(0, 0, 0) },
    { name = "LeftArm", size = Vector3.new(1, 2, 1), offset = Vector3.new(-1.5, 0, 0) },
    { name = "RightArm", size = Vector3.new(1, 2, 1), offset = Vector3.new(1.5, 0, 0) },
    { name = "LeftLeg", size = Vector3.new(1, 2, 1), offset = Vector3.new(-0.5, -2, 0) },
    { name = "RightLeg", size = Vector3.new(1, 2, 1), offset = Vector3.new(0.5, -2, 0) },
}
local JOINTS = {
    Head = Vector3.new(0, 1.5, 0),
    Neck = Vector3.new(0, 1, 0),
    Waist = Vector3.new(0, -1, 0),
    LeftShoulder = Vector3.new(-1.5, 1, 0),
    RightShoulder = Vector3.new(1.5, 1, 0),
    LeftHand = Vector3.new(-1.5, -1, 0),
    RightHand = Vector3.new(1.5, -1, 0),
    LeftHip = Vector3.new(-0.5, -1, 0),
    RightHip = Vector3.new(0.5, -1, 0),
    LeftFoot = Vector3.new(-0.5, -3, 0),
    RightFoot = Vector3.new(0.5, -3, 0),
}
local BONES = {
    { "Head", "Neck" },
    { "Neck", "Waist" },
    { "Neck", "LeftShoulder" },
    { "LeftShoulder", "LeftHand" },
    { "Neck", "RightShoulder" },
    { "RightShoulder", "RightHand" },
    { "Waist", "LeftHip" },
    { "LeftHip", "LeftFoot" },
    { "Waist", "RightHip" },
    { "RightHip", "RightFoot" },
}

-- // Utilities
local function getFonts()
    return FONT_BOLD or Enum.Font.SourceSansSemibold, FONT or Enum.Font.SourceSans
end
local function notify(message, duration)
    pcall(function()
        Notify({
            Title = NOTIFY_TITLE,
            Description = message,
            Duration = duration,
        })
    end)
end
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
local function isValid(spec, value)
    if type(spec) == "table" then
        return type(value) == "string" and spec[value] == true
    end
    return type(value) == spec
end
local function placeRect(frame, x, y, width, height)
    frame.Position = UDim2.fromOffset(math.floor(x), math.floor(y))
    frame.Size = UDim2.fromOffset(math.max(math.floor(width), 1), math.max(math.floor(height), 1))
    frame.Visible = true
end
local function drawLine(line, from, to, thickness)
    local delta = to - from
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.Position = UDim2.fromOffset(math.floor((from.X + to.X) / 2), math.floor((from.Y + to.Y) / 2))
    line.Size = UDim2.fromOffset(math.floor(delta.Magnitude), thickness)
    line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
    line.Visible = true
end

-- // Register
Elements.Register("Hologram", function(section, options)
    options = type(options) == "table" and options or {}
    local Colors, watchTheme = createColors(section.Panel or Panel)

    -- // State
    local api = {}
    local connections = {}
    local reported = {}
    local destroyed = false
    local title = tostring(options.title or "Hologram")
    local description = tostring(options.description or options.desc or "")
    local height = math.clamp(tonumber(options.height) or HEIGHT_DEFAULT, HEIGHT_MIN, HEIGHT_MAX)
    local callback = type(options.callback) == "function" and options.callback or nil
    local settings = copyTable(SETTINGS_DEFAULTS)
    local espColors = copyTable(COLOR_DEFAULTS)
    local parts = {}
    local tanHalf = math.tan(math.rad(VIEW_FOV) / 2)
    local aspect = 1
    local viewSize = Vector2.new(0, 0)
    local footerH = 0
    local layout
    local unwatchTheme

    -- // Reporter
    local function report(message, duration)
        local text = ("Hologram '%s': %s"):format(title, message)
        if reported[text] then
            return
        end
        reported[text] = true
        warn(text)
        notify(text, duration or 5)
    end

    -- // Interface
    local root = create("Frame", {
        Name = title .. "_Hologram",
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = Colors.Palette,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, section.frame)
    create("UICorner", { CornerRadius = UDim.new(0, 8) }, root)
    local rootStroke = create("UIStroke", {
        Color = Colors.Border,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, root)
    local fontBold, fontRegular = getFonts()
    local stage = create("Frame", {
        Name = "Stage",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, root)
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
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, root)
    local function layoutFooter()
        local hasTitle = title ~= ""
        local hasDesc = description ~= ""
        local titleH = hasTitle and TITLE_H or 0
        footerH = titleH + (hasDesc and DESC_H or 0)
        if footerH > 0 then
            footerH = footerH + FOOTER_PAD
        end
        titleLabel.Visible = hasTitle
        titleLabel.Text = title
        descLabel.Visible = hasDesc
        descLabel.Text = description
        titleLabel.Position = UDim2.new(0, SIDE_PAD, 1, -footerH + FOOTER_PAD / 2)
        titleLabel.Size = UDim2.new(1, -SIDE_PAD * 2, 0, TITLE_H)
        descLabel.Position = UDim2.new(0, SIDE_PAD, 1, -footerH + FOOTER_PAD / 2 + titleH)
        descLabel.Size = UDim2.new(1, -SIDE_PAD * 2, 0, DESC_H)
        stage.Size = UDim2.new(1, 0, 1, -footerH)
    end
    layoutFooter()

    -- // Viewport
    local viewer = create("ViewportFrame", {
        Name = "Viewer",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 1,
        Ambient = Color3.fromRGB(150, 150, 150),
        LightColor = Color3.fromRGB(255, 255, 255),
        LightDirection = Vector3.new(0.3, -0.6, 1),
    }, stage)
    local camera = create("Camera", { FieldOfView = VIEW_FOV }, viewer)
    viewer.CurrentCamera = camera
    local worldModel = create("WorldModel", {}, viewer)
    for _, def in ipairs(R6_PARTS) do
        local part = create("Part", {
            Name = def.name,
            Size = def.size,
            Anchored = true,
            CanCollide = false,
            CanQuery = false,
            CanTouch = false,
            CastShadow = false,
            Material = Enum.Material.SmoothPlastic,
            Color = espColors.Hologram,
            TopSurface = Enum.SurfaceType.Smooth,
            BottomSurface = Enum.SurfaceType.Smooth,
            CFrame = LAYING * CFrame.new(def.offset),
        }, worldModel)
        if def.head then
            create("SpecialMesh", {
                MeshType = Enum.MeshType.Head,
                Scale = Vector3.new(1.25, 1.25, 1.25),
            }, part)
        end
        parts[def.name] = part
    end

    -- // Overlay Objects
    local overlay = create("Frame", {
        Name = "Overlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, stage)
    local function newLine(name)
        return create("Frame", {
            Name = name,
            BorderSizePixel = 0,
            Visible = false,
        }, overlay)
    end
    local boxLines = {}
    for index = 1, 8 do
        boxLines[index] = newLine("Box" .. index)
    end
    local boneLines = {}
    for index = 1, #BONES do
        boneLines[index] = newLine("Bone" .. index)
    end
    local tracerLine = newLine("Tracer")
    local nameLabel = create("TextLabel", {
        Name = "PlayerName",
        Size = UDim2.fromOffset(100, 12),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = tostring(options.name or "Player"),
        Font = fontBold,
        TextSize = 11,
        TextStrokeColor3 = Color3.new(0, 0, 0),
        TextStrokeTransparency = 0.5,
        Visible = false,
    }, overlay)
    local healthBack = create("Frame", {
        Name = "HealthBack",
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Visible = false,
    }, overlay)
    local healthFill = create("Frame", {
        Name = "HealthFill",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, HEALTH_RATIO, 0),
        BorderSizePixel = 0,
    }, healthBack)

    -- // Projection
    local function projectPoint(point)
        local rel = camera.CFrame:PointToObjectSpace(point)
        local depth = -rel.Z
        if depth <= 0.05 then
            return nil
        end
        return Vector2.new(
            (rel.X / depth / (tanHalf * aspect) * 0.5 + 0.5) * viewSize.X,
            (0.5 - rel.Y / depth / tanHalf * 0.5) * viewSize.Y
        )
    end
    local function computeLayout()
        local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
        for _, part in pairs(parts) do
            local frame = part.CFrame
            local half = part.Size / 2
            for sx = -1, 1, 2 do
                for sy = -1, 1, 2 do
                    for sz = -1, 1, 2 do
                        local point = projectPoint(frame:PointToWorldSpace(Vector3.new(half.X * sx, half.Y * sy, half.Z * sz)))
                        if point then
                            minX = math.min(minX, point.X)
                            minY = math.min(minY, point.Y)
                            maxX = math.max(maxX, point.X)
                            maxY = math.max(maxY, point.Y)
                        end
                    end
                end
            end
        end
        if minX == math.huge then
            layout = nil
            return
        end
        local points = {}
        for name, joint in pairs(JOINTS) do
            points[name] = projectPoint(LAYING:PointToWorldSpace(joint))
        end
        layout = {
            minX = minX - BOX_PAD,
            minY = minY - BOX_PAD,
            maxX = maxX + BOX_PAD,
            maxY = maxY + BOX_PAD,
            points = points,
            center = projectPoint(Vector3.zero),
        }
    end

    -- // Render
    local function renderParts()
        for _, part in pairs(parts) do
            part.Color = espColors.Hologram
        end
    end
    local function renderOverlay()
        if destroyed then
            return
        end
        for _, line in ipairs(boxLines) do
            line.Visible = false
        end
        for _, line in ipairs(boneLines) do
            line.Visible = false
        end
        tracerLine.Visible = false
        nameLabel.Visible = false
        healthBack.Visible = false
        if not layout then
            return
        end
        local minX, minY, maxX, maxY = layout.minX, layout.minY, layout.maxX, layout.maxY
        local boxW = maxX - minX
        local boxH = maxY - minY
        if settings.Box then
            local segments
            if settings.BoxStyle == "Corner" then
                local lenX = math.max(boxW * CORNER_RATIO, 3)
                local lenY = math.max(boxH * CORNER_RATIO, 3)
                segments = {
                    { minX, minY, lenX, 1 },
                    { minX, minY, 1, lenY },
                    { maxX - lenX, minY, lenX, 1 },
                    { maxX - 1, minY, 1, lenY },
                    { minX, maxY - 1, lenX, 1 },
                    { minX, maxY - lenY, 1, lenY },
                    { maxX - lenX, maxY - 1, lenX, 1 },
                    { maxX - 1, maxY - lenY, 1, lenY },
                }
            else
                segments = {
                    { minX, minY, boxW, 1 },
                    { minX, maxY - 1, boxW, 1 },
                    { minX, minY, 1, boxH },
                    { maxX - 1, minY, 1, boxH },
                }
            end
            for index, segment in ipairs(segments) do
                boxLines[index].BackgroundColor3 = espColors.Box
                placeRect(boxLines[index], segment[1], segment[2], segment[3], segment[4])
            end
        end
        if settings.Name then
            nameLabel.TextColor3 = espColors.Name
            nameLabel.Position = UDim2.fromOffset(math.floor((minX + maxX) / 2 - 50), math.floor(minY - 14))
            nameLabel.Visible = true
        end
        if settings.Health then
            healthFill.BackgroundColor3 = espColors.Health
            placeRect(healthBack, minX - 6, minY, 3, boxH)
        end
        if settings.Skeleton then
            for index, bone in ipairs(BONES) do
                local from = layout.points[bone[1]]
                local to = layout.points[bone[2]]
                if from and to then
                    boneLines[index].BackgroundColor3 = espColors.Skeleton
                    drawLine(boneLines[index], from, to, LINE_THICKNESS)
                end
            end
        end
        if settings.Tracer and layout.center then
            tracerLine.BackgroundColor3 = espColors.Tracer
            drawLine(tracerLine, Vector2.new(viewSize.X / 2, viewSize.Y * TRACER_ORIGINS[settings.TracerOrigin]), layout.center, LINE_THICKNESS)
        end
    end
    local function refresh()
        local size = viewer.AbsoluteSize
        if size.X <= 0 or size.Y <= 0 then
            return
        end
        viewSize = size
        aspect = size.X / size.Y
        local distance = math.max(VIEW_Y / (2 * tanHalf), VIEW_X / (2 * tanHalf * aspect))
        camera.CFrame = CFrame.lookAt(VIEW_CENTER + Vector3.new(0, 0, -distance), VIEW_CENTER)
        computeLayout()
        renderOverlay()
    end

    -- // Settings
    local function setSetting(key, value, silent)
        local spec = SETTINGS_SCHEMA[key]
        if not spec then
            report(("invalid setting '%s'."):format(tostring(key)))
            return false
        end
        if not isValid(spec, value) then
            report(("invalid value for '%s'."):format(tostring(key)))
            return false
        end
        if settings[key] == value then
            return false
        end
        settings[key] = value
        if not silent and callback then
            local ok, err = pcall(callback, copyTable(settings), key, value)
            if not ok then
                report(("callback: %s"):format(tostring(err)))
            end
        end
        return true
    end
    local function setColor(key, value)
        if COLOR_DEFAULTS[key] == nil then
            report(("invalid color '%s'."):format(tostring(key)))
            return false
        end
        if typeof(value) ~= "Color3" then
            report(("invalid value for color '%s'."):format(tostring(key)))
            return false
        end
        espColors[key] = value
        return true
    end

    -- // Settings API
    function api:Set(key, value)
        if destroyed then
            return false
        end
        local changed = setSetting(key, value, false)
        if changed then
            renderOverlay()
        end
        return changed
    end
    function api:SetSettings(map)
        if destroyed or type(map) ~= "table" then
            return false
        end
        local any = false
        for key, value in pairs(map) do
            if setSetting(key, value, false) then
                any = true
            end
        end
        if any then
            renderOverlay()
        end
        return any
    end
    function api:Get(key)
        return settings[key]
    end
    function api:GetSettings()
        return copyTable(settings)
    end
    function api:SetColor(key, value)
        if destroyed or not setColor(key, value) then
            return false
        end
        renderParts()
        renderOverlay()
        return true
    end
    function api:SetColors(map)
        if destroyed or type(map) ~= "table" then
            return false
        end
        local any = false
        for key, value in pairs(map) do
            if setColor(key, value) then
                any = true
            end
        end
        if any then
            renderParts()
            renderOverlay()
        end
        return any
    end
    function api:GetColor(key)
        return espColors[key]
    end

    -- // Control API
    function api:SetTitle(value)
        title = tostring(value or "")
        root.Name = title .. "_Hologram"
        layoutFooter()
    end
    function api:SetDescription(value)
        description = tostring(value or "")
        layoutFooter()
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
    function api:Destroy()
        if destroyed then
            return
        end
        destroyed = true
        if unwatchTheme then
            unwatchTheme()
            unwatchTheme = nil
        end
        for _, conn in ipairs(connections) do
            conn:Disconnect()
        end
        table.clear(connections)
        table.clear(parts)
        root:Destroy()
    end

    -- // Initialization
    connections[#connections + 1] = viewer:GetPropertyChangedSignal("AbsoluteSize"):Connect(refresh)
    if type(options.settings) == "table" then
        for key, value in pairs(options.settings) do
            setSetting(key, value, true)
        end
    end
    if type(options.colors) == "table" then
        for key, value in pairs(options.colors) do
            setColor(key, value)
        end
    end
    renderParts()
    refresh()
    unwatchTheme = watchTheme(function()
        if destroyed then
            return
        end
        root.BackgroundColor3 = Colors.Palette
        rootStroke.Color = Colors.Border
        titleLabel.TextColor3 = Colors.Active
        descLabel.TextColor3 = Colors.Dim
    end)
    return api
end)