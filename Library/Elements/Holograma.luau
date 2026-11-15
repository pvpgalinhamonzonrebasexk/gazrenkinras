-- // Services
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local players = game:GetService("Players")

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
local TYPE_W = 150
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
local CLONE_BUDGET = 0.006
local PENDING_BUDGET = 60
local PLAYER_WAIT = 10
local APPEARANCE_WAIT = 5
local IMAGE_TIMEOUT = 8
local THUMB_SIZE_DEFAULT = 420
local THUMB_SIZE_SMALL = 150
local THUMB_DEFAULT = "Asset"
local HOLO_COLOR = Color3.fromRGB(110, 190, 255)
local MATERIAL_COLOR = Color3.fromRGB(200, 200, 200)
local MATERIAL_RADIUS = 2
local PLACEHOLDER_DEFAULT = "No item loaded"
local LOADING_TEXT = "Loading..."
local EMPTY_TEXT = "Nothing to display"
local LIVE_RATES = { Player = 30, Model = 20, Map = 4 }
local LIVE_RATE_FALLBACK = 10
local CHANNEL_DEFAULT = "ColorMap"
local CHANNELS = { ColorMap = true, NormalMap = true, MetalnessMap = true, RoughnessMap = true }
local TARGET_KEYS = {
    "target",
    "Target",
    "item",
    "Item",
    "map",
    "Map",
    "source",
    "Source",
    "thumbnail",
    "Thumbnail",
    "image",
    "Image",
    "icon",
    "Icon",
    "id",
    "Id",
}
local TYPE_ALIASES = {
    auto = "Auto",
    player = "Player",
    players = "Player",
    character = "Player",
    me = "Player",
    map = "Map",
    world = "Map",
    workspace = "Map",
    model = "Model",
    item = "Model",
    tool = "Model",
    object = "Model",
    accessory = "Model",
    hologram = "Model",
    texture = "Texture",
    image = "Texture",
    decal = "Texture",
    material = "Texture",
    thumbnail = "Thumbnail",
    thumbnaild = "Thumbnail",
    thumb = "Thumbnail",
    icon = "Thumbnail",
    avatar = "Thumbnail",
    headshot = "Thumbnail",
}
local THUMB_LOOKUP = {}
for _, name in ipairs({
    "Asset",
    "Avatar",
    "AvatarHeadShot",
    "AvatarBust",
    "GamePass",
    "BadgeIcon",
    "GameIcon",
    "BundleThumbnail",
    "Outfit",
    "GroupIcon",
}) do
    THUMB_LOOKUP[name:lower()] = name
end
THUMB_LOOKUP.item = "Asset"
THUMB_LOOKUP.headshot = "AvatarHeadShot"
THUMB_LOOKUP.bust = "AvatarBust"
THUMB_LOOKUP.bundle = "BundleThumbnail"
THUMB_LOOKUP.badge = "BadgeIcon"
THUMB_LOOKUP.game = "GameIcon"
THUMB_LOOKUP.group = "GroupIcon"
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
local function pick(source, lower, upper)
    local value = source[lower]
    if value == nil then
        value = source[upper]
    end
    return value
end
local function pickFunction(source, lower, upper)
    local value = pick(source, lower, upper)
    if type(value) == "function" then
        return value
    end
    return nil
end
local function findTarget(data)
    for _, key in ipairs(TARGET_KEYS) do
        local value = data[key]
        if value ~= nil then
            return value
        end
    end
    return nil
end
local function unpackEntry(value)
    if type(value) ~= "table" then
        return value
    end
    local inner = pick(value, "target", "Target")
    if inner == nil then
        return value
    end
    return inner, pick(value, "title", "Title"), pick(value, "description", "Description"), pick(value, "type", "Type")
end
local function normalizeType(value)
    if value == nil then
        return "Auto"
    end
    return TYPE_ALIASES[tostring(value):lower()]
end
local function normalizeThumbSize(value)
    local number = tonumber(value) or THUMB_SIZE_DEFAULT
    if number <= 200 then
        return THUMB_SIZE_SMALL
    end
    return THUMB_SIZE_DEFAULT
end
local function isDisplayPart(instance)
    return instance:IsA("BasePart") and not instance:IsA("Terrain")
end
local function inCharacter(part, stop)
    local ancestor = part.Parent
    while ancestor and ancestor ~= stop do
        if ancestor:IsA("Model") and players:GetPlayerFromCharacter(ancestor) then
            return true
        end
        ancestor = ancestor.Parent
    end
    return false
end
local function collectParts(root, excludeCharacters)
    local list = {}
    if isDisplayPart(root) then
        list[1] = root
    end
    for _, descendant in ipairs(root:GetDescendants()) do
        if isDisplayPart(descendant) and not (excludeCharacters and inCharacter(descendant, root)) then
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
local function addLink(part, linkMap, reverseMap, originalMap)
    local clone = clonePart(part)
    if not clone then
        return nil
    end
    linkMap[clone] = part
    reverseMap[part] = clone
    originalMap[clone] = { Color = clone.Color, Material = clone.Material }
    return clone
end
local function yawFrame(part, fallback)
    local cf = part.CFrame
    local look = cf.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    if flat.Magnitude < 0.001 then
        return fallback
    end
    return CFrame.lookAt(cf.Position, cf.Position + flat)
end
local function isAssetString(value)
    return value:match("^rbxassetid://") ~= nil
        or value:match("^rbxasset://") ~= nil
        or value:match("^https?://") ~= nil
        or value:match("^%d+$") ~= nil
end
local function normalizeAsset(value)
    if type(value) == "number" then
        return "rbxassetid://" .. tostring(math.floor(value))
    end
    if value:match("^%d+$") then
        return "rbxassetid://" .. value
    end
    return value
end
local function extractId(value)
    if type(value) == "number" then
        return math.floor(value)
    end
    if type(value) == "string" then
        local digits = value:match("^%d+$") or value:match("rbxassetid://(%d+)") or value:match("[?&][iI]d=(%d+)")
        return digits and tonumber(digits) or nil
    end
    return nil
end
local function thumbUrl(kind, id, size)
    return ("rbxthumb://type=%s&id=%d&w=%d&h=%d"):format(kind, math.floor(id), size, size)
end
local function textureProperty(instance, channel)
    if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
        return "Image"
    end
    if instance:IsA("Decal") or instance:IsA("Texture") then
        return "Texture"
    end
    if instance:IsA("SurfaceAppearance") then
        return channel
    end
    if instance:IsA("MeshPart") then
        return "TextureID"
    end
    if instance:IsA("SpecialMesh") then
        return "TextureId"
    end
    if instance:IsA("ShirtGraphic") then
        return "Graphic"
    end
    if instance:IsA("Shirt") then
        return "ShirtTemplate"
    end
    if instance:IsA("Pants") then
        return "PantsTemplate"
    end
    return nil
end
local function isTextureInstance(instance)
    if instance:IsA("MeshPart") or instance:IsA("SpecialMesh") then
        return false
    end
    return textureProperty(instance, CHANNEL_DEFAULT) ~= nil
end
local function resolveTarget(target)
    if typeof(target) == "Instance" then
        if target:IsA("Player") then
            return target.Character
        end
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
local function detectType(target)
    if type(target) == "table" then
        return "Thumbnail"
    end
    if typeof(target) == "EnumItem" then
        return target.EnumType == Enum.Material and "Texture" or "Auto"
    end
    if type(target) == "number" then
        return "Thumbnail"
    end
    if type(target) == "string" then
        if isAssetString(target) then
            if extractId(target) then
                return "Thumbnail"
            end
            return "Texture"
        end
        local named = players:FindFirstChild(target)
        if named and named:IsA("Player") then
            return "Player"
        end
    end
    if type(target) == "function" then
        local ok, result = pcall(target)
        target = ok and result or nil
    end
    local instance = typeof(target) == "Instance" and target or resolveTarget(target)
    if not instance then
        return "Model"
    end
    if instance:IsA("Player") then
        return "Player"
    end
    if isTextureInstance(instance) then
        return "Texture"
    end
    if instance:IsA("Model") and players:GetPlayerFromCharacter(instance) then
        return "Player"
    end
    if instance:IsA("Terrain") or instance:IsA("Folder") or instance:IsA("WorldRoot") then
        return "Map"
    end
    return "Model"
end
local function resolveThumbnail(target, kind, size, channel)
    if type(target) == "function" then
        local ok, result = pcall(target)
        if not ok then
            return nil, "target function failed."
        end
        target = result
    end
    if type(target) == "table" then
        local rawId = pick(target, "id", "Id")
        local userId = pick(target, "userId", "UserId")
        local id = extractId(rawId ~= nil and rawId or userId)
        if not id then
            return nil, "invalid thumbnail data."
        end
        local custom = THUMB_LOOKUP[tostring(pick(target, "kind", "Kind") or pick(target, "thumbType", "ThumbType") or ""):lower()]
        local fallback = (userId ~= nil and rawId == nil) and "AvatarHeadShot" or THUMB_DEFAULT
        local customSize = pick(target, "size", "Size")
        return {
            Image = thumbUrl(custom or kind or fallback, id, customSize and normalizeThumbSize(customSize) or size),
            Name = tostring(id),
        }
    end
    if type(target) == "string" and not isAssetString(target) then
        local named = players:FindFirstChild(target)
        if named and named:IsA("Player") then
            target = named
        end
    end
    if type(target) == "number" or (type(target) == "string" and isAssetString(target)) then
        local id = extractId(target)
        if id then
            return { Image = thumbUrl(kind or THUMB_DEFAULT, id, size), Name = tostring(id) }
        end
        return { Image = normalizeAsset(target), Name = tostring(target) }
    end
    local instance = typeof(target) == "Instance" and target or resolveTarget(target)
    if not instance then
        return nil, "target not found."
    end
    local owner = instance
    if instance:IsA("Model") then
        owner = players:GetPlayerFromCharacter(instance) or instance
    end
    if owner:IsA("Player") then
        return {
            Image = thumbUrl(kind or "AvatarHeadShot", owner.UserId, size),
            Name = owner.Name,
            Instance = owner,
        }
    end
    if instance:IsA("IntValue") or instance:IsA("NumberValue") or instance:IsA("StringValue") then
        local valueId = extractId(instance.Value)
        if valueId then
            return {
                Image = thumbUrl(kind or THUMB_DEFAULT, valueId, size),
                Name = instance.Name,
                Instance = instance,
            }
        end
    end
    if instance:IsA("Tool") and instance.TextureId ~= "" then
        return {
            Image = instance.TextureId,
            Name = instance.Name,
            Instance = instance,
            Property = "TextureId",
        }
    end
    if isTextureInstance(instance) then
        local property = textureProperty(instance, channel)
        return {
            Image = instance[property],
            Name = instance.Name,
            Instance = instance,
            Property = property,
        }
    end
    return { Fallback = instance }
end

-- // Hologram
local function buildHologram(section, options)
    options = type(options) == "table" and options or {}
    local Colors, watchTheme = createColors(section.Panel or Panel)

    local api = {}
    local connections = {}
    local structureConnections = {}
    local reported = {}
    local links = {}
    local reverse = {}
    local originals = {}
    local pending = {}
    local destroyed = false
    local title = tostring(pick(options, "title", "Title") or "Hologram")
    local description = tostring(options.description or options.desc or options.Description or "")
    local placeholder = tostring(pick(options, "placeholder", "Placeholder") or PLACEHOLDER_DEFAULT)
    local showType = options.showType ~= false
    local height = math.clamp(tonumber(options.height or options.Height) or HEIGHT_DEFAULT, HEIGHT_MIN, HEIGHT_MAX)
    local callback = pickFunction(options, "callback", "Callback") or pickFunction(options, "onLoaded", "OnLoaded")
    local onFail = pickFunction(options, "onFail", "OnFail") or pickFunction(options, "onError", "OnError")
    local onClear = pickFunction(options, "onClear", "OnClear")
    local onTypeChange = pickFunction(options, "onTypeChange", "OnTypeChange")
    local maxParts = math.max(math.floor(tonumber(options.maxParts) or MAX_PARTS_DEFAULT), 1)
    local skipInvisible = options.skipInvisible ~= false
    local excludePlayers = options.excludePlayers ~= false
    local followOption = options.follow ~= false
    local live = options.live ~= false
    local liveRate = tonumber(options.liveRate)
    local spin = options.spin ~= false
    local spinSpeed = tonumber(options.spinSpeed) or SPIN_SPEED_DEFAULT
    local draggable = options.draggable ~= false
    local zoom = math.clamp(tonumber(options.zoom) or 1, ZOOM_MIN, ZOOM_MAX)
    local yaw = tonumber(options.yaw) or YAW_DEFAULT
    local pitch = math.clamp(tonumber(options.pitch) or PITCH_DEFAULT, -PITCH_LIMIT, PITCH_LIMIT)
    local tint = options.tint == true
    local holoColor = typeof(options.color) == "Color3" and options.color or HOLO_COLOR
    local channel = CHANNELS[options.channel or options.textureChannel] and (options.channel or options.textureChannel) or CHANNEL_DEFAULT
    local thumbKind
    local thumbSize = normalizeThumbSize(pick(options, "thumbSize", "ThumbSize"))
    local currentType = "Auto"
    local activeType
    local viewMode = "Model"
    local tanHalf = math.tan(math.rad(VIEW_FOV) / 2)
    local aspect = 1
    local radius = 5
    local footerH = 0
    local loadId = 0
    local loading = false
    local dragging = false
    local partCount = 0
    local holder
    local getOrigin
    local loadedInstance
    local loadedName = ""
    local lastTarget
    local lastKind
    local textureConnection
    local imageConnection
    local list = {}
    local index = 0
    local followedPlayer
    local followConnection
    local playerToken = 0
    local unwatchTheme

    -- // Callback
    local function report(message, duration)
        local text = ("Hologram '%s': %s"):format(title, message)
        if reported[text] then
            return
        end
        reported[text] = true
        warn(text)
        notify(text, duration or 5)
    end
    local function fire(handler, ...)
        if type(handler) ~= "function" then
            return
        end
        local ok, err = pcall(handler, ...)
        if not ok then
            report(("callback: %s"):format(tostring(err)))
        end
    end

    local requestedType = pick(options, "type", "Type")
    if requestedType ~= nil then
        local normalized = normalizeType(requestedType)
        if normalized then
            currentType = normalized
        else
            report(("invalid type '%s'."):format(tostring(requestedType)))
        end
    end
    local requestedThumb = pick(options, "thumbType", "ThumbType")
    if requestedThumb ~= nil then
        thumbKind = THUMB_LOOKUP[tostring(requestedThumb):lower()]
        if not thumbKind then
            report(("invalid thumbnail type '%s'."):format(tostring(requestedThumb)))
        end
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
    local typeLabel = create("TextLabel", {
        Name = "Type",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        Font = fontRegular,
        TextSize = 11,
        TextColor3 = Colors.Dim,
        TextXAlignment = Enum.TextXAlignment.Right,
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
        local headerH = (hasTitle or showType) and TITLE_H or 0
        local typeW = showType and TYPE_W or 0
        footerH = headerH + (hasDesc and DESC_H or 0)
        if footerH > 0 then
            footerH = footerH + FOOTER_PAD
        end
        local top = -footerH + FOOTER_PAD / 2
        titleLabel.Visible = hasTitle
        titleLabel.Text = title
        titleLabel.Position = UDim2.new(0, SIDE_PAD, 1, top)
        titleLabel.Size = UDim2.new(1, -(SIDE_PAD * 2 + typeW), 0, TITLE_H)
        typeLabel.Visible = showType
        typeLabel.Position = UDim2.new(1, -(SIDE_PAD + typeW), 1, top)
        typeLabel.Size = UDim2.new(0, typeW, 0, TITLE_H)
        descLabel.Visible = hasDesc
        descLabel.Text = description
        descLabel.Position = UDim2.new(0, SIDE_PAD, 1, top + headerH)
        descLabel.Size = UDim2.new(1, -SIDE_PAD * 2, 0, DESC_H)
        stage.Size = UDim2.new(1, 0, 1, -footerH)
    end
    local function updateTypeLabel()
        local text = activeType or currentType
        if loadedName ~= "" then
            text = text .. " · " .. loadedName
        end
        typeLabel.Text = text
    end
    local function setInfo(newTitle, newDescription)
        local changed = false
        if newTitle ~= nil then
            newTitle = tostring(newTitle)
            if newTitle ~= title then
                title = newTitle
                root.Name = title .. "_Hologram"
                changed = true
            end
        end
        if newDescription ~= nil then
            newDescription = tostring(newDescription)
            if newDescription ~= description then
                description = newDescription
                changed = true
            end
        end
        if changed then
            layoutFooter()
        end
    end
    layoutFooter()
    updateTypeLabel()

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
    local textureView = create("ImageLabel", {
        Name = "Texture",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(0.9, 0.9),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = "",
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 1,
        Visible = false,
    }, stage)
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
    local function showMode(mode)
        viewMode = mode
        viewer.Visible = mode == "Model"
        textureView.Visible = mode == "Texture"
    end

    -- // Camera
    local function updateCamera()
        if destroyed then
            return
        end
        if viewMode == "Texture" then
            textureView.Size = UDim2.fromScale(0.9 * zoom, 0.9 * zoom)
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

    -- // Live
    local function syncLinks()
        if not holder or not getOrigin then
            return
        end
        local ok, origin = pcall(getOrigin)
        if not ok or not origin then
            return
        end
        local inverse = origin:Inverse()
        for clone, source in pairs(links) do
            if source.Parent then
                local cf = inverse * source.CFrame
                if clone.CFrame ~= cf then
                    clone.CFrame = cf
                end
                local size = source.Size
                if clone.Size ~= size then
                    clone.Size = size
                end
                local transparency = source.Transparency
                if clone.Transparency ~= transparency then
                    clone.Transparency = transparency
                end
                local original = originals[clone]
                local color = source.Color
                local material = source.Material
                if original and (original.Color ~= color or original.Material ~= material) then
                    original.Color = color
                    original.Material = material
                    if not tint then
                        clone.Color = color
                        clone.Material = material
                    end
                end
            end
        end
    end
    local function processPending()
        if not holder then
            return
        end
        local budget = PENDING_BUDGET
        for part in pairs(pending) do
            pending[part] = nil
            budget = budget - 1
            if part.Parent and partCount < maxParts and not reverse[part] and not (skipInvisible and part.Transparency >= 1) then
                local clone = addLink(part, links, reverse, originals)
                if clone then
                    partCount = partCount + 1
                    clone.Parent = holder
                    if tint then
                        clone.Color = holoColor
                        clone.Material = Enum.Material.ForceField
                    end
                end
            end
            if budget <= 0 then
                break
            end
        end
    end
    local function disconnectStructure()
        for _, connection in ipairs(structureConnections) do
            connection:Disconnect()
        end
        table.clear(structureConnections)
    end
    local function watchStructure(instance, kind)
        disconnectStructure()
        structureConnections[1] = instance.DescendantAdded:Connect(function(descendant)
            if not isDisplayPart(descendant) then
                return
            end
            if kind == "Map" and excludePlayers and inCharacter(descendant, instance) then
                return
            end
            pending[descendant] = true
        end)
        structureConnections[2] = instance.DescendantRemoving:Connect(function(descendant)
            pending[descendant] = nil
            local clone = reverse[descendant]
            if clone then
                links[clone] = nil
                reverse[descendant] = nil
                originals[clone] = nil
                partCount = math.max(partCount - 1, 0)
                clone:Destroy()
            end
        end)
    end

    -- // Loader
    local function clearLoaded()
        if holder then
            holder:Destroy()
            holder = nil
        end
        disconnectStructure()
        if textureConnection then
            textureConnection:Disconnect()
            textureConnection = nil
        end
        if imageConnection then
            imageConnection:Disconnect()
            imageConnection = nil
        end
        textureView.Image = ""
        links = {}
        reverse = {}
        originals = {}
        pending = {}
        getOrigin = nil
        partCount = 0
        loadedInstance = nil
        loadedName = ""
        activeType = nil
        updateTypeLabel()
    end
    local function fail(message)
        loadId = loadId + 1
        loading = false
        clearLoaded()
        showMode("Model")
        setStatus(EMPTY_TEXT)
        if message then
            report(message)
            fire(onFail, message)
        end
        return false
    end
    local function loadInstance(instance, kind)
        loadId = loadId + 1
        local id = loadId
        clearLoaded()
        showMode("Model")
        loading = true
        setStatus(LOADING_TEXT)
        task.spawn(function()
            local parts = collectParts(instance, kind == "Map" and excludePlayers)
            local model = create("Model", { Name = "Hologram" })
            local newLinks = {}
            local newReverse = {}
            local newOriginals = {}
            local count = 0
            local truncated = false
            local sliceStart = os.clock()
            for _, part in ipairs(parts) do
                if destroyed or id ~= loadId then
                    model:Destroy()
                    return
                end
                if count >= maxParts then
                    truncated = true
                    break
                end
                if not (skipInvisible and part.Transparency >= 1) then
                    local clone = addLink(part, newLinks, newReverse, newOriginals)
                    if clone then
                        count = count + 1
                        clone.Parent = model
                    end
                end
                if os.clock() - sliceStart >= CLONE_BUDGET then
                    task.wait()
                    sliceStart = os.clock()
                end
            end
            if destroyed or id ~= loadId then
                model:Destroy()
                return
            end
            loading = false
            if count == 0 then
                model:Destroy()
                setStatus(EMPTY_TEXT)
                fire(onFail, "nothing to display.")
                return
            end
            local boxCFrame, boxSize = model:GetBoundingBox()
            local center = boxCFrame.Position
            local origin = CFrame.new(center)
            local resolver = function()
                return origin
            end
            if kind == "Player" then
                local rootPart = instance:FindFirstChild("HumanoidRootPart")
                if rootPart and rootPart:IsA("BasePart") then
                    local frame0 = yawFrame(rootPart, CFrame.new(rootPart.Position))
                    origin = CFrame.new(center) * frame0.Rotation
                    local offset = frame0:ToObjectSpace(origin)
                    local last = frame0
                    resolver = function()
                        last = yawFrame(rootPart, last)
                        return last * offset
                    end
                end
            elseif kind == "Model" then
                local pivotSource = instance
                if not instance:IsA("PVInstance") then
                    local handle = instance:FindFirstChild("Handle")
                    pivotSource = handle and handle:IsA("BasePart") and handle or nil
                end
                if pivotSource then
                    local pivot0 = pivotSource:GetPivot()
                    origin = CFrame.new(center) * pivot0.Rotation
                    local offset = pivot0:ToObjectSpace(origin)
                    resolver = function()
                        return pivotSource:GetPivot() * offset
                    end
                end
            end
            radius = math.max(boxSize.Magnitude / 2, 0.5)
            links = newLinks
            reverse = newReverse
            originals = newOriginals
            partCount = count
            holder = model
            getOrigin = resolver
            loadedInstance = instance
            loadedName = instance.Name
            activeType = kind
            syncLinks()
            model.Parent = worldModel
            applyTint()
            setStatus(nil)
            updateTypeLabel()
            updateCamera()
            watchStructure(instance, kind)
            if truncated then
                report(("'%s' has too many parts, showing %d."):format(instance.Name, count))
            end
            fire(callback, instance, model, api, kind)
        end)
        return true
    end
    local function loadMaterial(material)
        loadId = loadId + 1
        clearLoaded()
        showMode("Model")
        loading = false
        local model = create("Model", { Name = "Hologram" })
        local sphere = create("Part", {
            Name = "Sphere",
            Shape = Enum.PartType.Ball,
            Size = Vector3.new(MATERIAL_RADIUS * 2, MATERIAL_RADIUS * 2, MATERIAL_RADIUS * 2),
            Anchored = true,
            CanCollide = false,
            CanQuery = false,
            CanTouch = false,
            CastShadow = false,
            Material = material,
            Color = MATERIAL_COLOR,
            CFrame = CFrame.new(),
        }, model)
        originals[sphere] = { Color = sphere.Color, Material = sphere.Material }
        radius = MATERIAL_RADIUS
        holder = model
        loadedName = material.Name
        activeType = "Texture"
        model.Parent = worldModel
        applyTint()
        setStatus(nil)
        updateTypeLabel()
        updateCamera()
        fire(callback, material, model, api, "Texture")
        return true
    end

    -- // Thumbnail
    local function trackImage(token)
        if imageConnection then
            imageConnection:Disconnect()
            imageConnection = nil
        end
        if textureView.Image == "" then
            setStatus(EMPTY_TEXT)
            return
        end
        if textureView.IsLoaded then
            setStatus(nil)
            return
        end
        setStatus(LOADING_TEXT)
        imageConnection = textureView:GetPropertyChangedSignal("IsLoaded"):Connect(function()
            if destroyed or token ~= loadId then
                return
            end
            if textureView.IsLoaded then
                setStatus(nil)
                if imageConnection then
                    imageConnection:Disconnect()
                    imageConnection = nil
                end
            end
        end)
        task.delay(IMAGE_TIMEOUT, function()
            if destroyed or token ~= loadId or textureView.IsLoaded then
                return
            end
            setStatus(EMPTY_TEXT)
        end)
    end
    local function showImage(image, name, instance, property, kind, source)
        loadId = loadId + 1
        local id = loadId
        clearLoaded()
        showMode("Texture")
        loading = false
        textureView.Image = image
        loadedInstance = instance
        loadedName = name
        activeType = kind
        if instance and property then
            textureConnection = instance:GetPropertyChangedSignal(property):Connect(function()
                if destroyed or id ~= loadId then
                    return
                end
                textureView.Image = instance[property]
                trackImage(id)
            end)
        end
        trackImage(id)
        updateTypeLabel()
        updateCamera()
        fire(callback, source, textureView, api, kind)
        return true
    end
    local function loadTexture(target)
        if typeof(target) == "EnumItem" and target.EnumType == Enum.Material then
            return loadMaterial(target)
        end
        local instance
        local image
        if typeof(target) == "Instance" then
            instance = target
        elseif type(target) == "number" then
            image = normalizeAsset(target)
        elseif type(target) == "string" and isAssetString(target) then
            image = normalizeAsset(target)
        else
            instance = resolveTarget(target)
        end
        local property
        if instance then
            property = textureProperty(instance, channel)
            if not property then
                return fail(("'%s' is not a texture source."):format(instance.Name))
            end
            image = instance[property]
        end
        if not image then
            return fail("texture not found.")
        end
        return showImage(image, instance and instance.Name or image, instance, property, "Texture", instance or image)
    end
    local function loadThumbnail(target)
        if typeof(target) == "EnumItem" and target.EnumType == Enum.Material then
            return loadMaterial(target)
        end
        local result, message = resolveThumbnail(target, thumbKind, thumbSize, channel)
        if not result then
            return fail(message or "thumbnail not found.")
        end
        if result.Fallback then
            return loadInstance(result.Fallback, "Model")
        end
        return showImage(result.Image, result.Name, result.Instance, result.Property, "Thumbnail", result.Instance or result.Image)
    end

    -- // Player
    local function unbindPlayer()
        playerToken = playerToken + 1
        followedPlayer = nil
        if followConnection then
            followConnection:Disconnect()
            followConnection = nil
        end
    end
    local function waitCharacter(player, token)
        local character = player.Character
        local waited = 0
        while not character and waited < PLAYER_WAIT do
            task.wait(0.1)
            waited = waited + 0.1
            if destroyed or token ~= playerToken then
                return nil
            end
            character = player.Character
        end
        if not character then
            return nil
        end
        character:WaitForChild("HumanoidRootPart", PLAYER_WAIT)
        waited = 0
        while waited < APPEARANCE_WAIT do
            local ok, loaded = pcall(player.HasAppearanceLoaded, player)
            if not ok or loaded then
                break
            end
            task.wait(0.1)
            waited = waited + 0.1
        end
        if destroyed or token ~= playerToken or player.Character ~= character then
            return nil
        end
        return character
    end
    local function loadPlayer(player, follow)
        if player == nil or player == true then
            player = players.LocalPlayer
        elseif type(player) == "string" then
            player = players:FindFirstChild(player)
        elseif typeof(player) == "Instance" and player:IsA("Model") then
            local owner = players:GetPlayerFromCharacter(player)
            if not owner then
                unbindPlayer()
                return loadInstance(player, "Model")
            end
            player = owner
        end
        if typeof(player) ~= "Instance" or not player:IsA("Player") then
            return fail("player not found.")
        end
        unbindPlayer()
        local token = playerToken
        followedPlayer = player
        lastTarget = player
        lastKind = "Player"
        index = 0
        list = {}
        loadId = loadId + 1
        clearLoaded()
        showMode("Model")
        loading = true
        setStatus(LOADING_TEXT)
        local function refreshPlayer()
            task.spawn(function()
                local character = waitCharacter(player, token)
                if destroyed or token ~= playerToken then
                    return
                end
                if character then
                    loadInstance(character, "Player")
                elseif not holder then
                    fail("character not found.")
                end
            end)
        end
        if follow ~= false then
            followConnection = player.CharacterAdded:Connect(refreshPlayer)
        end
        refreshPlayer()
        return true
    end
    local function loadAuto(target, typeName)
        local inner, entryTitle, entryDescription, entryType = unpackEntry(target)
        target = inner
        setInfo(entryTitle, entryDescription)
        local requested = typeName
        if requested == nil then
            requested = entryType
        end
        local kind = currentType
        if requested ~= nil then
            kind = normalizeType(requested) or currentType
        end
        if kind == "Auto" then
            kind = detectType(target)
        end
        lastTarget = target
        lastKind = requested
        if kind == "Player" then
            return loadPlayer(target, followOption)
        end
        unbindPlayer()
        if kind == "Texture" then
            return loadTexture(target)
        end
        if kind == "Thumbnail" then
            return loadThumbnail(target)
        end
        local instance = resolveTarget(target)
        if not instance then
            return fail("target not found.")
        end
        return loadInstance(instance, kind == "Map" and "Map" or "Model")
    end
    local function selectIndex(position)
        if #list == 0 then
            return false
        end
        index = ((position - 1) % #list) + 1
        return loadAuto(list[index])
    end
    local function reloadCurrent()
        if index > 0 and list[index] ~= nil then
            return loadAuto(list[index])
        end
        if lastTarget ~= nil then
            return loadAuto(lastTarget, lastKind)
        end
        if currentType == "Player" then
            return loadPlayer(nil, followOption)
        end
        return true
    end
    local function setTypeValue(value)
        local normalized = normalizeType(value)
        if not normalized then
            report(("invalid type '%s'."):format(tostring(value)))
            return false, false
        end
        local previous = currentType
        currentType = normalized
        updateTypeLabel()
        if previous ~= normalized then
            fire(onTypeChange, normalized, previous)
        end
        return true, previous ~= normalized
    end
    local function loadFromData(data)
        local items = data.list or data.List or data.items or data.Items
        if type(items) == "table" then
            return api:LoadList(items, pick(data, "start", "Start"))
        end
        local playerValue = pick(data, "player", "Player")
        if playerValue ~= nil and playerValue ~= false then
            return api:LoadPlayer(playerValue, followOption)
        end
        local target = findTarget(data)
        if target ~= nil then
            return api:Load(target)
        end
        return nil
    end

    -- // Load API
    function api:Load(target, typeName, info, extra)
        if destroyed then
            return false
        end
        if type(info) == "table" then
            setInfo(pick(info, "title", "Title"), pick(info, "description", "Description"))
        elseif info ~= nil or extra ~= nil then
            setInfo(info, extra)
        end
        index = 0
        list = {}
        return loadAuto(target, typeName)
    end
    function api:Update(data)
        if destroyed or type(data) ~= "table" then
            return false
        end
        setInfo(pick(data, "title", "Title"), pick(data, "description", "Description"))
        local value = pick(data, "placeholder", "Placeholder")
        if value ~= nil then
            api:SetPlaceholder(value)
        end
        value = pick(data, "thumbSize", "ThumbSize")
        if value ~= nil then
            thumbSize = normalizeThumbSize(value)
        end
        value = pick(data, "thumbType", "ThumbType")
        if value ~= nil then
            thumbKind = THUMB_LOOKUP[tostring(value):lower()] or thumbKind
        end
        value = pick(data, "channel", "Channel")
        if value ~= nil and CHANNELS[value] then
            channel = value
        end
        value = pick(data, "color", "Color")
        if value ~= nil then
            api:SetColor(value)
        end
        value = pick(data, "tint", "Tint")
        if value ~= nil then
            api:SetTint(value)
        end
        value = pick(data, "spin", "Spin")
        if value ~= nil then
            api:SetSpin(value)
        end
        value = pick(data, "spinSpeed", "SpinSpeed")
        if value ~= nil then
            api:SetSpinSpeed(value)
        end
        value = pick(data, "zoom", "Zoom")
        if value ~= nil then
            api:SetZoom(value)
        end
        value = pick(data, "height", "Height")
        if value ~= nil then
            api:SetHeight(value)
        end
        value = pick(data, "visible", "Visible")
        if value ~= nil then
            api:SetVisible(value)
        end
        local changed = false
        value = pick(data, "type", "Type")
        if value ~= nil then
            local _, typeChanged = setTypeValue(value)
            changed = typeChanged
        end
        local result = loadFromData(data)
        if result ~= nil then
            return result
        end
        if changed then
            lastKind = nil
            return reloadCurrent()
        end
        return true
    end
    function api:LoadPlayer(player, follow)
        if destroyed then
            return false
        end
        followOption = follow ~= false
        return loadPlayer(player, followOption)
    end
    function api:LoadList(items, start)
        if destroyed or type(items) ~= "table" then
            return false
        end
        unbindPlayer()
        list = {}
        for _, item in ipairs(items) do
            list[#list + 1] = item
        end
        return selectIndex(math.floor(tonumber(start) or 1))
    end
    function api:Select(position)
        if destroyed then
            return false
        end
        return selectIndex(math.floor(tonumber(position) or 1))
    end
    function api:Next()
        if destroyed then
            return false
        end
        return selectIndex(index + 1)
    end
    function api:Prev()
        if destroyed then
            return false
        end
        return selectIndex(index - 1)
    end
    function api:Reload()
        if destroyed then
            return false
        end
        if followedPlayer then
            return loadPlayer(followedPlayer, followConnection ~= nil)
        end
        return reloadCurrent()
    end
    function api:Clear()
        if destroyed then
            return
        end
        loadId = loadId + 1
        loading = false
        index = 0
        list = {}
        lastTarget = nil
        lastKind = nil
        unbindPlayer()
        clearLoaded()
        showMode("Model")
        setStatus(placeholder)
        fire(onClear)
    end
    function api:Sync()
        if destroyed then
            return
        end
        processPending()
        syncLinks()
    end
    function api:StopFollow()
        if followConnection then
            followConnection:Disconnect()
            followConnection = nil
        end
    end
    function api:GetLoaded()
        return loadedInstance
    end
    function api:GetName()
        return loadedName
    end
    function api:GetPlayer()
        return followedPlayer
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

    -- // Type API
    function api:SetType(value)
        local valid = setTypeValue(value)
        if not valid or destroyed then
            return false
        end
        lastKind = nil
        return reloadCurrent()
    end
    function api:GetType()
        return currentType
    end
    function api:GetActiveType()
        return activeType
    end
    function api:SetChannel(value)
        if not CHANNELS[value] then
            report(("invalid channel '%s'."):format(tostring(value)))
            return false
        end
        channel = value
        if activeType == "Texture" or activeType == "Thumbnail" then
            return reloadCurrent()
        end
        return true
    end
    function api:SetThumbType(value)
        if value == nil then
            thumbKind = nil
        else
            local resolved = THUMB_LOOKUP[tostring(value):lower()]
            if not resolved then
                report(("invalid thumbnail type '%s'."):format(tostring(value)))
                return false
            end
            thumbKind = resolved
        end
        if activeType == "Thumbnail" then
            return reloadCurrent()
        end
        return true
    end
    function api:GetThumbType()
        return thumbKind
    end
    function api:SetThumbSize(value)
        thumbSize = normalizeThumbSize(value)
        if activeType == "Thumbnail" then
            return reloadCurrent()
        end
        return true
    end
    function api:GetThumbSize()
        return thumbSize
    end

    -- // Live API
    function api:SetLive(value)
        live = value == true
    end
    function api:GetLive()
        return live
    end
    function api:SetLiveRate(value)
        liveRate = tonumber(value)
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
        if not holder and not loading and viewMode == "Model" and activeType == nil then
            setStatus(placeholder)
        end
    end

    -- // Control API
    function api:SetTitle(value)
        if destroyed then
            return
        end
        setInfo(tostring(value or ""), nil)
    end
    function api:SetDescription(value)
        if destroyed then
            return
        end
        setInfo(nil, tostring(value or ""))
    end
    function api:SetInfo(newTitle, newDescription)
        if destroyed then
            return
        end
        setInfo(newTitle, newDescription)
    end
    function api:GetTitle()
        return title
    end
    function api:GetDescription()
        return description
    end
    function api:SetShowType(value)
        showType = value == true
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
    function api:IsDestroyed()
        return destroyed
    end
    function api:Destroy()
        if destroyed then
            return
        end
        destroyed = true
        loadId = loadId + 1
        unbindPlayer()
        disconnectStructure()
        if textureConnection then
            textureConnection:Disconnect()
            textureConnection = nil
        end
        if imageConnection then
            imageConnection:Disconnect()
            imageConnection = nil
        end
        if unwatchTheme then
            unwatchTheme()
            unwatchTheme = nil
        end
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        table.clear(connections)
        table.clear(list)
        links = {}
        reverse = {}
        originals = {}
        pending = {}
        root:Destroy()
    end

    -- // Callback API
    function api:SetCallback(handler)
        callback = type(handler) == "function" and handler or nil
    end
    function api:SetOnFail(handler)
        onFail = type(handler) == "function" and handler or nil
    end
    function api:SetOnClear(handler)
        onClear = type(handler) == "function" and handler or nil
    end
    function api:SetOnTypeChange(handler)
        onTypeChange = type(handler) == "function" and handler or nil
    end
    api.Frame = root
    api.Instance = root

    -- // Properties
    local getters = {
        Title = function()
            return title
        end,
        Description = function()
            return description
        end,
        Type = function()
            return currentType
        end,
        Visible = function()
            return root.Visible
        end,
        Height = function()
            return height
        end,
        Spin = function()
            return spin
        end,
        Zoom = function()
            return zoom
        end,
        Tint = function()
            return tint
        end,
    }
    local setters = {
        Title = function(value)
            api:SetTitle(value)
        end,
        Description = function(value)
            api:SetDescription(value)
        end,
        Type = function(value)
            api:SetType(value)
        end,
        Visible = function(value)
            api:SetVisible(value)
        end,
        Height = function(value)
            api:SetHeight(value)
        end,
        Spin = function(value)
            api:SetSpin(value)
        end,
        Zoom = function(value)
            api:SetZoom(value)
        end,
        Tint = function(value)
            api:SetTint(value)
        end,
    }
    setmetatable(api, {
        __index = function(_, key)
            local getter = getters[key]
            if getter then
                return getter()
            end
            return nil
        end,
        __newindex = function(self, key, value)
            local setter = setters[key]
            if setter then
                setter(value)
                return
            end
            rawset(self, key, value)
        end,
    })

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
        if not dragging or viewMode ~= "Model" then
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

    -- // Update
    local liveElapsed = 0
    connections[#connections + 1] = runService.Heartbeat:Connect(function(dt)
        if not root.Visible or not holder or viewMode ~= "Model" then
            return
        end
        if live and not loading then
            liveElapsed = liveElapsed + dt
            local rate = liveRate or LIVE_RATES[activeType] or LIVE_RATE_FALLBACK
            if liveElapsed >= 1 / math.max(rate, 1) then
                liveElapsed = 0
                processPending()
                syncLinks()
            end
        end
        if spin and not dragging then
            yaw = (yaw + spinSpeed * dt) % 360
            updateCamera()
        end
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
        typeLabel.TextColor3 = Colors.Dim
        descLabel.TextColor3 = Colors.Dim
        statusLabel.TextColor3 = Colors.Dim
    end)
    local initialResult = loadFromData(options)
    if initialResult == nil and currentType == "Player" then
        loadPlayer(nil, followOption)
    end
    return api
end

-- // Register
Elements.Register("Hologram", buildHologram)