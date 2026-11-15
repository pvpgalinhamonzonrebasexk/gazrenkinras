-- // Hologram
-- // Services
local runService = game:GetService("RunService")
local players = game:GetService("Players")

-- // Theme System
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
local SPIN_SPEED = 45
local SWAY_RANGE = 0.9
local SWAY_SPEED = 0.8
local BOX_PAD = 4
local CORNER_RATIO = 0.25
local LINE_THICKNESS = 1
local HEALTH_RATIO = 0.75
local HOLOGRAM_TRANSPARENCY = 0.5
local ASSET_PREFIX = "rbxassetid://"
local SELF_ALIASES = { self = true, me = true, eu = true, localplayer = true }
local TRACER_ORIGINS = { Bottom = 1, Center = 0.5, Top = 0 }
local TEXTURE_TARGETS = {
    Head = true,
    Torso = true,
    LeftArm = true,
    RightArm = true,
    LeftLeg = true,
    RightLeg = true,
    Face = true,
}
local EXTENTS = {
    Standing = { X = 6.4, Y = 8, Center = Vector3.new(0, -0.3, 0) },
    Lying = { X = 9, Y = 5.6, Center = Vector3.new(-0.3, 0, 0) },
}
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
local BODY_COLORS = {
    Head = "HeadColor3",
    Torso = "TorsoColor3",
    LeftArm = "LeftArmColor3",
    RightArm = "RightArmColor3",
    LeftLeg = "LeftLegColor3",
    RightLeg = "RightLegColor3",
}
local ALL_FACES = {
    Enum.NormalId.Front,
    Enum.NormalId.Back,
    Enum.NormalId.Left,
    Enum.NormalId.Right,
    Enum.NormalId.Top,
    Enum.NormalId.Bottom,
}
local FACE_ONLY = { Enum.NormalId.Front }
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

-- // Player Resolver
local function resolveUserId(user)
    if typeof(user) == "Instance" and user:IsA("Player") then
        return user.UserId
    end
    if type(user) == "string" and SELF_ALIASES[user:lower()] then
        local me = players.LocalPlayer
        return me and me.UserId or nil
    end
    local id = tonumber(user)
    if id then
        return id
    end
    if type(user) == "string" then
        local ok, result = pcall(function()
            return players:GetUserIdFromNameAsync(user)
        end)
        if ok then
            return result
        end
    end
    return nil
end

-- // Hologram Element
Elements.Register("Hologram", function(section, options)
    options = type(options) == "table" and options or {}
    local Colors, watchTheme = createColors(section.Panel or Panel)

    -- // Internal State
    local api = {}
    local connections = {}
    local reported = {}
    local destroyed = false
    local animated = options.animated == true
    local lying = options.lying ~= false
    local title = tostring(options.title or "Hologram")
    local description = tostring(options.description or options.desc or "")
    local height = math.clamp(tonumber(options.height) or HEIGHT_DEFAULT, HEIGHT_MIN, HEIGHT_MAX)
    local callback = type(options.callback) == "function" and options.callback or nil
    local settings = copyTable(SETTINGS_DEFAULTS)
    local espColors = copyTable(COLOR_DEFAULTS)
    local textures = {}
    local parts = {}
    local tanHalf = math.tan(math.rad(VIEW_FOV) / 2)
    local aspect = 1
    local viewSize = Vector2.new(0, 0)
    local footerH = 0
    local yaw = 0
    local clock = 0
    local loopConnection
    local unwatchTheme
    local root

    -- // Local Helpers
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

    -- // Base Interface
    root = create("Frame", {
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

    -- // 3D Viewport
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
    local rig = create("Model", { Name = "R6" }, worldModel)
    local origin = create("Part", {
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
            Transparency = HOLOGRAM_TRANSPARENCY,
            TopSurface = Enum.SurfaceType.Smooth,
            BottomSurface = Enum.SurfaceType.Smooth,
            CFrame = CFrame.new(def.offset),
        }, rig)
        if def.head then
            create("SpecialMesh", {
                MeshType = Enum.MeshType.Head,
                Scale = Vector3.new(1.25, 1.25, 1.25),
            }, part)
        end
        parts[def.name] = { part = part, decals = {} }
    end
    local function updateCamera()
        local size = viewer.AbsoluteSize
        if size.X <= 0 or size.Y <= 0 then
            return
        end
        local extents = lying and EXTENTS.Lying or EXTENTS.Standing
        aspect = size.X / size.Y
        local distance = math.max(extents.Y / (2 * tanHalf), extents.X / (2 * tanHalf * aspect))
        camera.CFrame = CFrame.lookAt(extents.Center + Vector3.new(0, 0, -distance), extents.Center)
    end
    local function applyPose()
        local base = lying and CFrame.Angles(0, 0, math.rad(-90)) or CFrame.new()
        local sway = animated and math.sin(clock * SWAY_SPEED) * SWAY_RANGE or 0
        rig:PivotTo(CFrame.new(sway, 0, 0) * base * CFrame.Angles(0, math.rad(yaw), 0))
    end

    -- // Part Render
    local function renderParts()
        for _, entry in pairs(parts) do
            entry.part.Color = entry.skin or espColors.Hologram
        end
    end
    local function renderTexture(name)
        local entry = name == "Face" and parts.Head or parts[name]
        local old = entry.decals[name]
        if old then
            for _, decal in ipairs(old) do
                decal:Destroy()
            end
            entry.decals[name] = nil
        end
        local id = textures[name]
        if not id then
            return
        end
        local list = {}
        for _, face in ipairs(name == "Face" and FACE_ONLY or ALL_FACES) do
            list[#list + 1] = create("Decal", {
                Texture = id,
                Face = face,
                Transparency = HOLOGRAM_TRANSPARENCY,
            }, entry.part)
        end
        entry.decals[name] = list
    end

    -- // ESP Overlay Objects
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

    -- // ESP Render
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
    local function getBounds()
        local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
        for _, entry in pairs(parts) do
            local frame = entry.part.CFrame
            local half = entry.part.Size / 2
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
            return nil
        end
        return minX, minY, maxX, maxY
    end
    local function renderOverlay()
        if destroyed then
            return
        end
        viewSize = viewer.AbsoluteSize
        for _, line in ipairs(boxLines) do
            line.Visible = false
        end
        for _, line in ipairs(boneLines) do
            line.Visible = false
        end
        tracerLine.Visible = false
        nameLabel.Visible = false
        healthBack.Visible = false
        if viewSize.X <= 0 or viewSize.Y <= 0 then
            return
        end
        if settings.Box or settings.Name or settings.Health then
            local minX, minY, maxX, maxY = getBounds()
            if minX then
                minX = minX - BOX_PAD
                minY = minY - BOX_PAD
                maxX = maxX + BOX_PAD
                maxY = maxY + BOX_PAD
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
            end
        end
        if settings.Skeleton then
            local frame = origin.CFrame
            local points = {}
            for name, joint in pairs(JOINTS) do
                points[name] = projectPoint(frame:PointToWorldSpace(joint))
            end
            for index, bone in ipairs(BONES) do
                local from = points[bone[1]]
                local to = points[bone[2]]
                if from and to then
                    boneLines[index].BackgroundColor3 = espColors.Skeleton
                    drawLine(boneLines[index], from, to, LINE_THICKNESS)
                end
            end
        end
        if settings.Tracer then
            local target = projectPoint(origin.CFrame.Position)
            if target then
                tracerLine.BackgroundColor3 = espColors.Tracer
                drawLine(tracerLine, Vector2.new(viewSize.X / 2, viewSize.Y * TRACER_ORIGINS[settings.TracerOrigin]), target, LINE_THICKNESS)
            end
        end
    end

    -- // Animation System
    local function refreshLoop()
        local needed = animated and not destroyed
        if needed and not loopConnection then
            loopConnection = runService.Heartbeat:Connect(function(dt)
                if destroyed or not isShown() then
                    return
                end
                clock = clock + dt
                yaw = (yaw + SPIN_SPEED * dt) % 360
                applyPose()
                renderOverlay()
            end)
        elseif not needed and loopConnection then
            loopConnection:Disconnect()
            loopConnection = nil
        end
    end

    -- // Settings System
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

    -- // Character System
    local function applyAppearance(appearance)
        local bodyColors = appearance:FindFirstChildOfClass("BodyColors")
        if bodyColors then
            for name, property in pairs(BODY_COLORS) do
                parts[name].skin = bodyColors[property]
            end
        end
        local head = appearance:FindFirstChild("Head")
        local face = head and head:FindFirstChildWhichIsA("Decal") or nil
        if face then
            textures.Face = face.Texture
            renderTexture("Face")
        end
        appearance:Destroy()
        renderParts()
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
        if key == "Hologram" then
            renderParts()
        end
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

    -- // Texture API
    function api:SetTexture(name, id)
        if destroyed then
            return false
        end
        if not TEXTURE_TARGETS[name] then
            report(("invalid texture target '%s'."):format(tostring(name)))
            return false
        end
        textures[name] = id and normalizeAsset(id) or nil
        renderTexture(name)
        return true
    end
    function api:SetTextures(map)
        if destroyed or type(map) ~= "table" then
            return false
        end
        for name, id in pairs(map) do
            api:SetTexture(name, id)
        end
        return true
    end
    function api:GetTexture(name)
        return textures[name]
    end

    -- // Character API
    function api:LoadCharacter(who, onDone)
        if destroyed then
            return false
        end
        if typeof(who) == "Instance" and not who:IsA("Player") then
            local ok, clone = pcall(function()
                return who:Clone()
            end)
            if not ok or typeof(clone) ~= "Instance" then
                report("could not clone the character model.")
                return false
            end
            local applied, err = pcall(applyAppearance, clone)
            if onDone then
                pcall(onDone, applied, err)
            end
            return applied
        end
        task.spawn(function()
            local userId = resolveUserId(who)
            if not userId then
                report(("user '%s' not found."):format(tostring(who)))
                if onDone then
                    pcall(onDone, false, "user not found")
                end
                return
            end
            local ok, appearance = pcall(function()
                return players:GetCharacterAppearanceAsync(userId)
            end)
            if not ok or typeof(appearance) ~= "Instance" then
                report(("could not load appearance of '%s'."):format(tostring(who)))
                if onDone then
                    pcall(onDone, false, tostring(appearance))
                end
                return
            end
            if destroyed then
                appearance:Destroy()
                return
            end
            local applied, err = pcall(applyAppearance, appearance)
            if onDone then
                pcall(onDone, applied, err)
            end
        end)
        return true
    end
    function api:LoadOwnCharacter(onDone)
        return api:LoadCharacter("Self", onDone)
    end
    function api:ClearCharacter()
        if destroyed then
            return false
        end
        for _, entry in pairs(parts) do
            entry.skin = nil
        end
        textures.Face = nil
        renderTexture("Face")
        renderParts()
        return true
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
    function api:SetHeader(newTitle, newDescription)
        if newTitle ~= nil then
            title = tostring(newTitle)
            root.Name = title .. "_Hologram"
        end
        if newDescription ~= nil then
            description = tostring(newDescription)
        end
        layoutFooter()
    end
    function api:SetAnimated(value)
        animated = value == true
        if not animated then
            yaw = 0
            clock = 0
            applyPose()
            renderOverlay()
        end
        refreshLoop()
    end
    function api:SetLying(value)
        lying = value ~= false
        updateCamera()
        applyPose()
        renderOverlay()
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
        table.clear(parts)
        table.clear(textures)
        root:Destroy()
    end

    -- // Initialization
    connect(viewer:GetPropertyChangedSignal("AbsoluteSize"), function()
        updateCamera()
        renderOverlay()
    end)
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
    if type(options.textures) == "table" then
        for name, id in pairs(options.textures) do
            api:SetTexture(name, id)
        end
    end
    if options.character ~= nil then
        api:LoadCharacter(options.character)
    end
    renderParts()
    updateCamera()
    applyPose()
    renderOverlay()
    refreshLoop()
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