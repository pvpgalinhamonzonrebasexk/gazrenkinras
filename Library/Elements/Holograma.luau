-- // Services
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")

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
local HEIGHT_DEFAULT = 220
local HEIGHT_MIN = 110
local HEIGHT_MAX = 500
local TITLE_H = 16
local DESC_H = 14
local FOOTER_PAD = 8
local SIDE_PAD = 10
local VIEW_FOV = 40
local FIT_MARGIN = 1.15
local ZOOM_MIN = 0.25
local ZOOM_MAX = 3
local ZOOM_STEP = 0.1
local PITCH_LIMIT = 85
local PITCH_DEFAULT = 20
local YAW_DEFAULT = 0
local SPIN_SPEED_DEFAULT = 30
local DRAG_YAW = 0.6
local DRAG_PITCH = 0.4
local MAX_PARTS_DEFAULT = 2500
local CLONE_CHUNK = 120
local HOLO_COLOR = Color3.fromRGB(110, 190, 255)
local PLACEHOLDER_DEFAULT = "No item loaded"
local LOADING_TEXT = "Loading..."
local EMPTY_TEXT = "Nothing to display"
local STRIP_CLASSES = {
    "LuaSourceContainer",
    "Sound",
    "SurfaceGui",
    "BillboardGui",
    "JointInstance",
    "WeldConstraint",
    "Constraint",
    "Humanoid",
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
local function isDisplayPart(instance)
    return instance:IsA("BasePart") and not instance:IsA("Terrain")
end
local function collectParts(root)
    local list = {}
    if isDisplayPart(root) then
        list[1] = root
    end
    for _, descendant in ipairs(root:GetDescendants()) do
        if isDisplayPart(descendant) then
            list[#list + 1] = descendant
        end
    end
    return list
end
local function clonePart(part)
    local ok, clone = pcall(function()
        local archivable = part.Archivable
        if not archivable then
            part.Archivable = true
        end
        local copy = part:Clone()
        if not archivable then
            part.Archivable = false
        end
        return copy
    end)
    if not ok or not clone then
        return nil
    end
    for _, descendant in ipairs(clone:GetDescendants()) do
        local remove = descendant:IsA("BasePart")
        if not remove then
            for _, class in ipairs(STRIP_CLASSES) do
                if descendant:IsA(class) then
                    remove = true
                    break
                end
            end
        end
        if remove then
            descendant:Destroy()
        end
    end
    clone.Anchored = true
    clone.CanCollide = false
    clone.CanQuery = false
    clone.CanTouch = false
    clone.CastShadow = false
    return clone
end
local function resolveTarget(target)
    if typeof(target) == "Instance" then
        return target
    end
    if type(target) == "function" then
        local ok, result = pcall(target)
        if ok and typeof(result) == "Instance" then
            return result
        end
        return nil
    end
    if type(target) == "string" and target ~= "" then
        local current = game
        for segment in target:gmatch("[^%.]+") do
            local nextInstance = current:FindFirstChild(segment)
            if not nextInstance and current == game then
                local ok, service = pcall(game.GetService, game, segment)
                nextInstance = ok and service or nil
            end
            if not nextInstance then
                return nil
            end
            current = nextInstance
        end
        return current ~= game and current or nil
    end
    return nil
end

-- // Hologram
local function buildHologram(section, options)
    options = type(options) == "table" and options or {}
    local Colors, watchTheme = createColors(section.Panel or Panel)

    local api = {}
    local connections = {}
    local reported = {}
    local originals = {}
    local destroyed = false
    local title = tostring(options.title or options.Title or "Hologram")
    local description = tostring(options.description or options.desc or options.Description or "")
    local placeholder = tostring(options.placeholder or PLACEHOLDER_DEFAULT)
    local height = math.clamp(tonumber(options.height or options.Height) or HEIGHT_DEFAULT, HEIGHT_MIN, HEIGHT_MAX)
    local callback = type(options.callback) == "function" and options.callback or (type(options.Callback) == "function" and options.Callback or nil)
    local maxParts = math.max(math.floor(tonumber(options.maxParts) or MAX_PARTS_DEFAULT), 1)
    local skipInvisible = options.skipInvisible ~= false
    local spin = options.spin ~= false
    local spinSpeed = tonumber(options.spinSpeed) or SPIN_SPEED_DEFAULT
    local draggable = options.draggable ~= false
    local zoom = math.clamp(tonumber(options.zoom) or 1, ZOOM_MIN, ZOOM_MAX)
    local yaw = tonumber(options.yaw) or YAW_DEFAULT
    local pitch = math.clamp(tonumber(options.pitch) or PITCH_DEFAULT, -PITCH_LIMIT, PITCH_LIMIT)
    local tint = options.tint == true
    local holoColor = typeof(options.color) == "Color3" and options.color or HOLO_COLOR
    local tanHalf = math.tan(math.rad(VIEW_FOV) / 2)
    local aspect = 1
    local radius = 5
    local footerH = 0
    local loadId = 0
    local loading = false
    local dragging = false
    local holder
    local loadedInstance
    local loadedName = ""
    local list = {}
    local index = 0
    local unwatchTheme

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
        Visible = options.visible ~= false and options.Visible ~= false,
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
        Active = draggable,
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
    local statusLabel = create("TextLabel", {
        Name = "Status",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = placeholder,
        Font = fontRegular,
        TextSize = 12,
        TextColor3 = Colors.Dim,
        ZIndex = 2,
    }, stage)
    local function setStatus(text)
        statusLabel.Text = text or ""
        statusLabel.Visible = text ~= nil
    end

    -- // Camera
    local function updateCamera()
        if destroyed then
            return
        end
        local size = viewer.AbsoluteSize
        if size.X <= 0 or size.Y <= 0 then
            return
        end
        aspect = size.X / size.Y
        local halfVertical = math.rad(VIEW_FOV) / 2
        local halfHorizontal = math.atan(tanHalf * aspect)
        local distance = radius / math.sin(math.min(halfVertical, halfHorizontal)) * FIT_MARGIN * zoom
        local orbit = CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(math.rad(pitch), 0, 0)
        camera.CFrame = CFrame.lookAt(orbit * Vector3.new(0, 0, -distance), Vector3.zero)
    end

    -- // Style
    local function applyTint()
        for part, original in pairs(originals) do
            if part.Parent then
                if tint then
                    part.Color = holoColor
                    part.Material = Enum.Material.ForceField
                else
                    part.Color = original.Color
                    part.Material = original.Material
                end
            end
        end
    end

    -- // Loader
    local function clearLoaded()
        if holder then
            holder:Destroy()
            holder = nil
        end
        table.clear(originals)
        loadedInstance = nil
        loadedName = ""
    end
    local function load(target)
        if destroyed then
            return false
        end
        local instance = resolveTarget(target)
        loadId = loadId + 1
        local id = loadId
        clearLoaded()
        if not instance then
            loading = false
            setStatus(EMPTY_TEXT)
            report("target not found.")
            return false
        end
        loading = true
        setStatus(LOADING_TEXT)
        task.spawn(function()
            local parts = collectParts(instance)
            local model = create("Model", { Name = "Hologram" })
            local count = 0
            local truncated = false
            for position, part in ipairs(parts) do
                if destroyed or id ~= loadId then
                    model:Destroy()
                    return
                end
                if count >= maxParts then
                    truncated = true
                    break
                end
                if not (skipInvisible and part.Transparency >= 1) then
                    local clone = clonePart(part)
                    if clone then
                        count = count + 1
                        originals[clone] = { Color = clone.Color, Material = clone.Material }
                        clone.Parent = model
                    end
                end
                if position % CLONE_CHUNK == 0 then
                    task.wait()
                end
            end
            if destroyed or id ~= loadId then
                model:Destroy()
                return
            end
            loading = false
            if count == 0 then
                model:Destroy()
                table.clear(originals)
                setStatus(EMPTY_TEXT)
                return
            end
            local boxCFrame, boxSize = model:GetBoundingBox()
            model.WorldPivot = boxCFrame
            model:PivotTo(CFrame.new())
            radius = math.max(boxSize.Magnitude / 2, 0.5)
            model.Parent = worldModel
            holder = model
            loadedInstance = instance
            loadedName = instance.Name
            applyTint()
            setStatus(nil)
            updateCamera()
            if truncated then
                report(("'%s' has too many parts, showing %d."):format(instance.Name, count))
            end
            if callback then
                local ok, err = pcall(callback, instance, model)
                if not ok then
                    report(("callback: %s"):format(tostring(err)))
                end
            end
        end)
        return true
    end
    local function select(position)
        if #list == 0 then
            return false
        end
        index = ((position - 1) % #list) + 1
        return load(list[index])
    end

    -- // Load API
    function api:Load(target)
        index = 0
        list = {}
        return load(target)
    end
    function api:LoadList(items, start)
        if type(items) ~= "table" then
            return false
        end
        list = {}
        for _, item in ipairs(items) do
            list[#list + 1] = item
        end
        return select(math.floor(tonumber(start) or 1))
    end
    function api:Select(position)
        if destroyed then
            return false
        end
        return select(math.floor(tonumber(position) or 1))
    end
    function api:Next()
        if destroyed then
            return false
        end
        return select(index + 1)
    end
    function api:Prev()
        if destroyed then
            return false
        end
        return select(index - 1)
    end
    function api:Reload()
        if destroyed or not loadedInstance then
            return false
        end
        return load(loadedInstance)
    end
    function api:Clear()
        if destroyed then
            return
        end
        loadId = loadId + 1
        loading = false
        index = 0
        list = {}
        clearLoaded()
        setStatus(placeholder)
    end
    function api:GetLoaded()
        return loadedInstance
    end
    function api:GetName()
        return loadedName
    end
    function api:GetIndex()
        return index
    end
    function api:GetCount()
        return #list
    end
    function api:IsLoading()
        return loading
    end

    -- // View API
    function api:SetSpin(value)
        spin = value == true
    end
    function api:GetSpin()
        return spin
    end
    function api:SetSpinSpeed(value)
        spinSpeed = tonumber(value) or spinSpeed
    end
    function api:SetZoom(value)
        zoom = math.clamp(tonumber(value) or zoom, ZOOM_MIN, ZOOM_MAX)
        updateCamera()
    end
    function api:GetZoom()
        return zoom
    end
    function api:SetRotation(newYaw, newPitch)
        yaw = tonumber(newYaw) or yaw
        pitch = math.clamp(tonumber(newPitch) or pitch, -PITCH_LIMIT, PITCH_LIMIT)
        updateCamera()
    end
    function api:SetTint(value)
        tint = value == true
        applyTint()
    end
    function api:GetTint()
        return tint
    end
    function api:SetColor(value)
        if typeof(value) ~= "Color3" then
            report("invalid color.")
            return false
        end
        holoColor = value
        applyTint()
        return true
    end
    function api:GetColor()
        return holoColor
    end
    function api:SetMaxParts(value)
        maxParts = math.max(math.floor(tonumber(value) or maxParts), 1)
    end
    function api:SetPlaceholder(value)
        placeholder = tostring(value or PLACEHOLDER_DEFAULT)
        if not holder and not loading then
            setStatus(placeholder)
        end
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
        if value == true then
            task.defer(updateCamera)
        end
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
        loadId = loadId + 1
        if unwatchTheme then
            unwatchTheme()
            unwatchTheme = nil
        end
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        table.clear(connections)
        table.clear(originals)
        table.clear(list)
        root:Destroy()
    end
    api.Frame = root
    api.Instance = root

    -- // Input
    connections[#connections + 1] = stage.InputBegan:Connect(function(input)
        if not draggable then
            return
        end
        local kind = input.UserInputType
        if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    connections[#connections + 1] = stage.InputChanged:Connect(function(input)
        if draggable and input.UserInputType == Enum.UserInputType.MouseWheel then
            zoom = math.clamp(zoom - input.Position.Z * ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
            updateCamera()
        end
    end)
    connections[#connections + 1] = userInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end
        local kind = input.UserInputType
        if kind == Enum.UserInputType.MouseMovement or kind == Enum.UserInputType.Touch then
            yaw = (yaw - input.Delta.X * DRAG_YAW) % 360
            pitch = math.clamp(pitch + input.Delta.Y * DRAG_PITCH, -PITCH_LIMIT, PITCH_LIMIT)
            updateCamera()
        end
    end)
    connections[#connections + 1] = userInputService.InputEnded:Connect(function(input)
        local kind = input.UserInputType
        if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    connections[#connections + 1] = runService.Heartbeat:Connect(function(dt)
        if not spin or dragging or not holder or not root.Visible then
            return
        end
        yaw = (yaw + spinSpeed * dt) % 360
        updateCamera()
    end)
    connections[#connections + 1] = viewer:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCamera)

    -- // Initialization
    setStatus(placeholder)
    updateCamera()
    task.defer(updateCamera)
    unwatchTheme = watchTheme(function()
        if destroyed then
            return
        end
        root.BackgroundColor3 = Colors.Palette
        rootStroke.Color = Colors.Border
        titleLabel.TextColor3 = Colors.Active
        descLabel.TextColor3 = Colors.Dim
        statusLabel.TextColor3 = Colors.Dim
    end)
    local source = options.list or options.items
    if type(source) == "table" then
        api:LoadList(source, options.start)
    else
        local initial = options.target or options.item or options.map or options.source
        if initial ~= nil then
            api:Load(initial)
        end
    end
    return api
end

-- // Register
Elements.Register("Hologram", buildHologram)