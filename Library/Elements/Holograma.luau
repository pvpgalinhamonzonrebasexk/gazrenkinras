local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local players = game:GetService("Players")
local marketplaceService = game:GetService("MarketplaceService")

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

local NOTIFY_TITLE = "System"
local HEIGHT_DEFAULT = 190
local HEIGHT_MIN = 90
local HEIGHT_MAX = 500
local TITLE_H = 16
local DESC_H = 14
local FOOTER_TOP = 2
local FOOTER_BOTTOM = 8
local FOOTER_GAP = 2
local SIDE_PAD = 10
local IMAGE_FILL = 1
local VIEW_FOV = 40
local FIT_MARGIN = 1.02
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
local IMAGE_TIMEOUT = 4
local FALLBACK_TIMEOUT = 8
local THUMB_SMALL = 150
local THUMB_LARGE = 420
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
local KIND_DEFAULT = "Asset"
local KIND_PLAYER = "AvatarHeadShot"
local SMALL_ONLY = { BadgeIcon = true, GamePass = true, GameIcon = true }
local AVATAR_KINDS = { Avatar = true, AvatarHeadShot = true, AvatarBust = true }
local INFO_TYPES = {
    Asset = Enum.InfoType.Asset,
    GamePass = Enum.InfoType.GamePass,
    BundleThumbnail = Enum.InfoType.Bundle,
}
local TARGET_KEYS = {
    "target",
    "Target",
    "item",
    "Item",
    "map",
    "Map",
    "player",
    "Player",
    "source",
    "Source",
    "icon",
    "Icon",
    "image",
    "Image",
    "id",
    "Id",
}
local ATTRIBUTE_KEYS = { "AssetId", "ImageId", "Image", "Icon", "Thumbnail", "TextureId", "Id" }
local VIEW_ALIASES = {
    auto = "Auto",
    hologram = "Hologram",
    holo = "Hologram",
    model = "Hologram",
    image = "Image",
    icon = "Image",
    thumbnail = "Image",
    thumb = "Image",
    texture = "Image",
}
local STYLE_LOOKUP = {
    asset = "Asset",
    item = "Asset",
    avatar = "Avatar",
    full = "Avatar",
    user = "AvatarHeadShot",
    headshot = "AvatarHeadShot",
    avatarheadshot = "AvatarHeadShot",
    bust = "AvatarBust",
    avatarbust = "AvatarBust",
    pass = "GamePass",
    gamepass = "GamePass",
    badge = "BadgeIcon",
    badgeicon = "BadgeIcon",
    bundle = "BundleThumbnail",
    bundlethumbnail = "BundleThumbnail",
    group = "GroupIcon",
    groupicon = "GroupIcon",
    outfit = "Outfit",
}
local LINK_PATTERNS = {
    { "/catalog/(%d+)", "Asset" },
    { "/library/(%d+)", "Asset" },
    { "/bundles/(%d+)", "BundleThumbnail" },
    { "/game%-pass/(%d+)", "GamePass" },
    { "/users/(%d+)", "AvatarHeadShot" },
    { "/badges/(%d+)", "BadgeIcon" },
    { "/groups/(%d+)", "GroupIcon" },
    { "/communities/(%d+)", "GroupIcon" },
    { "[?&][iI][dD]=(%d+)", "Asset" },
}
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
local infoCache = {}

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
local function lookupStyle(value)
    if value == nil then
        return nil
    end
    return STYLE_LOOKUP[tostring(value):lower()]
end
local function normalizeView(value)
    if value == nil then
        return nil
    end
    return VIEW_ALIASES[tostring(value):lower()]
end
local function unpackEntry(value)
    if type(value) ~= "table" then
        return value
    end
    local inner = pick(value, "target", "Target")
    if inner == nil then
        return value
    end
    return inner,
        pick(value, "title", "Title"),
        pick(value, "description", "Description"),
        pick(value, "view", "View"),
        pick(value, "style", "Style")
end
local function extractId(value)
    if type(value) == "number" then
        local id = math.floor(value)
        return id > 0 and id or nil
    end
    if type(value) == "string" then
        local digits = value:match("^%d+$") or value:match("rbxassetid://(%d+)") or value:match("[?&][iI][dD]=(%d+)")
        return digits and tonumber(digits) or nil
    end
    return nil
end
local function thumbUrl(kind, id, pixels)
    if SMALL_ONLY[kind] then
        pixels = THUMB_SMALL
    end
    return ("rbxthumb://type=%s&id=%d&w=%d&h=%d"):format(kind, math.floor(id), pixels, pixels)
end
local function isImageString(text)
    if text:match("^rbxthumb://") or text:match("^rbxasset://") or text:match("^rbxassetid://") or text:match("^https?://") or text:match("^%d+$") then
        return true
    end
    local prefix = text:match("^(%a+):%d+$")
    return prefix ~= nil and STYLE_LOOKUP[prefix:lower()] ~= nil
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
    if instance:IsA("Tool") then
        return "TextureId"
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
local function isPureImage(instance)
    return not (instance:IsA("Tool") or instance:IsA("MeshPart") or instance:IsA("SpecialMesh"))
end
local function findTexture(root, channel)
    for _, descendant in ipairs(root:GetDescendants()) do
        local property = textureProperty(descendant, channel)
        if property then
            local value = descendant[property]
            if type(value) == "string" and value ~= "" then
                return descendant, property, value
            end
        end
    end
    return nil
end
local function resolvePath(target)
    if typeof(target) == "Instance" then
        return target
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
local function findPlayer(name)
    local lowered = name:gsub("^@", ""):lower()
    if lowered == "" then
        return nil
    end
    local partial
    for _, player in ipairs(players:GetPlayers()) do
        local playerName = player.Name:lower()
        local displayName = player.DisplayName:lower()
        if playerName == lowered or displayName == lowered then
            return player
        end
        if not partial and #lowered >= 3 and (playerName:sub(1, #lowered) == lowered or displayName:sub(1, #lowered) == lowered) then
            partial = player
        end
    end
    return partial
end
local function ownerOf(instance)
    if instance:IsA("Player") then
        return instance
    end
    local model = instance:IsA("Humanoid") and instance.Parent or instance
    if model and model:IsA("Model") then
        return players:GetPlayerFromCharacter(model)
    end
    return nil
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
local function thumbSpec(kind, id, pixels, name, description)
    local spec = {
        Image = thumbUrl(kind, id, pixels),
        Name = name or tostring(id),
        Description = description,
        Kind = kind,
        Id = id,
    }
    if kind == "Asset" then
        spec.Fallback = "rbxassetid://" .. tostring(id)
    end
    return spec
end
local function playerSpec(player, style, pixels)
    local kind = AVATAR_KINDS[style] and style or KIND_PLAYER
    return thumbSpec(kind, player.UserId, pixels, player.DisplayName, "@" .. player.Name)
end
local function resolveLink(text, pixels)
    for _, entry in ipairs(LINK_PATTERNS) do
        local digits = text:match(entry[1])
        if digits then
            return thumbSpec(entry[2], tonumber(digits), pixels)
        end
    end
    return nil, "unsupported link."
end
local function resolveSource(target, style, pixels, channel, depth)
    depth = depth or 0
    if depth > 4 then
        return nil, "target is nested too deep."
    end
    if target == nil then
        return nil, "target not found.", true
    end
    if type(target) == "function" then
        local ok, result = pcall(target)
        if not ok then
            return nil, "target function failed."
        end
        return resolveSource(result, style, pixels, channel, depth + 1)
    end
    if type(target) == "table" then
        local rawId = pick(target, "id", "Id")
        local userId = pick(target, "userId", "UserId")
        local id = extractId(rawId ~= nil and rawId or userId)
        if not id then
            return nil, "invalid target data."
        end
        local kind = lookupStyle(pick(target, "style", "Style")) or style
        if not kind then
            kind = (userId ~= nil and rawId == nil) and KIND_PLAYER or KIND_DEFAULT
        end
        return thumbSpec(kind, id, pixels)
    end
    if type(target) == "number" then
        local id = extractId(target)
        if not id then
            return nil, "invalid id."
        end
        return thumbSpec(style or KIND_DEFAULT, id, pixels)
    end
    if type(target) == "string" then
        local text = target:match("^%s*(.-)%s*$")
        if text == "" then
            return nil, "target not found.", true
        end
        if text:match("^rbxthumb://") then
            return { Image = text, Name = "Thumbnail" }
        end
        if text:match("^rbxasset://") then
            return { Image = text, Name = text:match("[^/]+$") or text }
        end
        local assetId = text:match("^rbxassetid://(%d+)")
        if assetId then
            return thumbSpec(style or KIND_DEFAULT, tonumber(assetId), pixels)
        end
        if text:match("^https?://") then
            return resolveLink(text, pixels)
        end
        if text:match("^%d+$") then
            return thumbSpec(style or KIND_DEFAULT, tonumber(text), pixels)
        end
        local prefix, rest = text:match("^(%a+):(%d+)$")
        local prefixKind = prefix and STYLE_LOOKUP[prefix:lower()]
        if prefixKind then
            return thumbSpec(prefixKind, tonumber(rest), pixels)
        end
        local named = findPlayer(text)
        if named then
            return playerSpec(named, style, pixels)
        end
        target = resolvePath(text)
        if not target then
            return nil, "target not found.", true
        end
    end
    if typeof(target) ~= "Instance" then
        return nil, "target not found.", true
    end
    local instance = target
    local owner = ownerOf(instance)
    if owner then
        return playerSpec(owner, style, pixels)
    end
    if instance:IsA("ObjectValue") then
        if instance.Value then
            return resolveSource(instance.Value, style, pixels, channel, depth + 1)
        end
        return nil, ("'%s' is empty."):format(instance.Name)
    end
    if instance:IsA("IntValue") or instance:IsA("NumberValue") or instance:IsA("StringValue") then
        local value = instance.Value
        if value == "" or value == 0 then
            return nil, ("'%s' is empty."):format(instance.Name)
        end
        return resolveSource(value, style, pixels, channel, depth + 1)
    end
    for _, key in ipairs(ATTRIBUTE_KEYS) do
        local value = instance:GetAttribute(key)
        if value ~= nil and value ~= "" then
            local spec = resolveSource(value, style, pixels, channel, depth + 1)
            if spec then
                spec.Name = instance.Name
                spec.Description = nil
                return spec
            end
        end
    end
    local property = textureProperty(instance, channel)
    if property then
        local value = instance[property]
        if type(value) == "string" and (value ~= "" or isPureImage(instance)) then
            return {
                Image = value,
                Name = instance.Name,
                Kind = "Texture",
                Instance = instance,
                Property = property,
            }
        end
    end
    local source, sourceProperty, value = findTexture(instance, channel)
    if source then
        return {
            Image = value,
            Name = instance.Name,
            Kind = "Texture",
            Instance = source,
            Property = sourceProperty,
        }
    end
    return nil, ("'%s' has no image."):format(instance.Name)
end
local function classify(target, view, depth)
    depth = depth or 0
    if depth > 4 then
        return nil, "target is nested too deep."
    end
    if target == nil then
        return nil, "target not found."
    end
    if type(target) == "function" then
        local ok, result = pcall(target)
        if not ok then
            return nil, "target function failed."
        end
        return classify(result, view, depth + 1)
    end
    if typeof(target) == "EnumItem" then
        if target.EnumType == Enum.Material then
            return "Material", target
        end
        return nil, "unsupported target."
    end
    if type(target) == "table" or type(target) == "number" then
        return "Image", target
    end
    if type(target) == "string" then
        local text = target:match("^%s*(.-)%s*$")
        if text == "" then
            return nil, "target not found."
        end
        if isImageString(text) then
            return "Image", text
        end
        local named = findPlayer(text)
        if named then
            return view == "Image" and "Image" or "Player", named
        end
        local found = resolvePath(text)
        if not found then
            return "Image", text
        end
        target = found
    end
    if typeof(target) ~= "Instance" then
        return nil, "target not found."
    end
    local instance = target
    if instance:IsA("ObjectValue") then
        if instance.Value then
            return classify(instance.Value, view, depth + 1)
        end
        return nil, ("'%s' is empty."):format(instance.Name)
    end
    if instance:IsA("IntValue") or instance:IsA("NumberValue") or instance:IsA("StringValue") then
        local value = instance.Value
        if value == "" or value == 0 then
            return nil, ("'%s' is empty."):format(instance.Name)
        end
        return classify(value, view, depth + 1)
    end
    local owner = ownerOf(instance)
    if owner then
        return view == "Image" and "Image" or "Player", owner
    end
    if view == "Image" then
        return "Image", instance
    end
    local property = textureProperty(instance, CHANNEL_DEFAULT)
    if property and isPureImage(instance) then
        return "Image", instance
    end
    if instance:IsA("Terrain") or instance:IsA("Folder") or instance:IsA("WorldRoot") then
        return "Map", instance
    end
    return "Model", instance
end
local function requestInfo(kind, id)
    local key = kind .. ":" .. tostring(id)
    local cached = infoCache[key]
    if cached ~= nil then
        return cached or nil
    end
    local ok, result = pcall(function()
        return marketplaceService:GetProductInfo(id, INFO_TYPES[kind])
    end)
    if ok and type(result) == "table" then
        infoCache[key] = { Name = result.Name, Description = result.Description }
    else
        infoCache[key] = false
    end
    return infoCache[key] or nil
end

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
    local manualTitle = pick(options, "title", "Title")
    local manualDescription = options.description or options.desc or options.Description
    local entryTitle
    local entryDescription
    local autoTitle
    local autoDescription
    local placeholder = tostring(pick(options, "placeholder", "Placeholder") or PLACEHOLDER_DEFAULT)
    local height = math.clamp(tonumber(options.height or options.Height) or HEIGHT_DEFAULT, HEIGHT_MIN, HEIGHT_MAX)
    local callback = pickFunction(options, "callback", "Callback") or pickFunction(options, "onLoaded", "OnLoaded")
    local onFail = pickFunction(options, "onFail", "OnFail") or pickFunction(options, "onError", "OnError")
    local onClear = pickFunction(options, "onClear", "OnClear")
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
    local styleKind = lookupStyle(pick(options, "style", "Style"))
    local viewOption = normalizeView(pick(options, "view", "View")) or "Auto"
    local fetchInfo = options.fetchInfo ~= false
    local displayMode = "Model"
    local activeKind
    local tanHalf = math.tan(math.rad(VIEW_FOV) / 2)
    local aspect = 1
    local radius = 5
    local loadId = 0
    local loading = false
    local dragging = false
    local partCount = 0
    local holder
    local getOrigin
    local loadedInstance
    local loadedSpec
    local lastTarget
    local imageConnection
    local propertyConnection
    local list = {}
    local index = 0
    local followedPlayer
    local followConnection
    local playerToken = 0
    local unwatchTheme

    local function report(message, duration)
        local text = ("Hologram '%s': %s"):format(tostring(manualTitle or autoTitle or "Hologram"), message)
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

    local root = create("Frame", {
        Name = tostring(manualTitle or "Hologram") .. "_Hologram",
        Size = UDim2.new(1, 0, 0, height),
        AutomaticSize = Enum.AutomaticSize.Y,
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
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, height),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Active = draggable,
    }, root)
    local footer = create("Frame", {
        Name = "Footer",
        Position = UDim2.new(0, 0, 0, height),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.None,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
    }, root)
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, FOOTER_GAP),
    }, footer)
    create("UIPadding", {
        PaddingTop = UDim.new(0, FOOTER_TOP),
        PaddingBottom = UDim.new(0, FOOTER_BOTTOM),
        PaddingLeft = UDim.new(0, SIDE_PAD),
        PaddingRight = UDim.new(0, SIDE_PAD),
    }, footer)
    local titleLabel = create("TextLabel", {
        Name = "Title",
        LayoutOrder = 1,
        Size = UDim2.new(1, 0, 0, TITLE_H),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        Font = fontBold,
        TextSize = 13,
        TextColor3 = Colors.Active,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, footer)
    local descLabel = create("TextLabel", {
        Name = "Description",
        LayoutOrder = 2,
        Size = UDim2.new(1, 0, 0, DESC_H),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        Font = fontRegular,
        TextSize = 11,
        TextColor3 = Colors.Dim,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextTruncate = Enum.TextTruncate.None,
    }, footer)
    local function layoutFooter()
        local titleText = entryTitle
        if titleText == nil then
            titleText = manualTitle
        end
        if titleText == nil then
            titleText = autoTitle
        end
        titleText = titleText ~= nil and tostring(titleText) or ""
        local descText = entryDescription
        if descText == nil then
            descText = manualDescription
        end
        if descText == nil then
            descText = autoDescription
        end
        descText = descText ~= nil and tostring(descText) or ""
        local hasTitle = titleText ~= ""
        local hasDesc = descText ~= ""
        titleLabel.Visible = hasTitle
        titleLabel.Text = titleText
        descLabel.Visible = hasDesc
        descLabel.Text = descText
        if hasTitle or hasDesc then
            footer.Visible = true
            footer.AutomaticSize = Enum.AutomaticSize.Y
        else
            footer.Visible = false
            footer.AutomaticSize = Enum.AutomaticSize.None
            footer.Size = UDim2.new(1, 0, 0, 0)
        end
        stage.Size = UDim2.new(1, 0, 0, height)
        footer.Position = UDim2.new(0, 0, 0, height)
        root.Name = tostring(manualTitle or "Hologram") .. "_Hologram"
    end
    layoutFooter()

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
        Size = UDim2.fromScale(IMAGE_FILL, IMAGE_FILL),
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
        displayMode = mode
        viewer.Visible = mode == "Model"
        textureView.Visible = mode == "Image"
    end

    local function updateCamera()
        if destroyed then
            return
        end
        if displayMode == "Image" then
            textureView.Size = UDim2.fromScale(IMAGE_FILL * zoom, IMAGE_FILL * zoom)
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

    local function disconnectImage()
        if imageConnection then
            imageConnection:Disconnect()
            imageConnection = nil
        end
        if propertyConnection then
            propertyConnection:Disconnect()
            propertyConnection = nil
        end
    end
    local function clearLoaded()
        if holder then
            holder:Destroy()
            holder = nil
        end
        disconnectStructure()
        disconnectImage()
        textureView.Image = ""
        links = {}
        reverse = {}
        originals = {}
        pending = {}
        getOrigin = nil
        partCount = 0
        loadedInstance = nil
        loadedSpec = nil
        autoTitle = nil
        autoDescription = nil
        activeKind = nil
    end
    local function fail(message)
        loadId = loadId + 1
        loading = false
        clearLoaded()
        showMode("Model")
        setStatus(EMPTY_TEXT)
        layoutFooter()
        if message then
            report(message)
            fire(onFail, message)
        end
        return false
    end
    local function loadInstance(instance, kind, info)
        loadId = loadId + 1
        local id = loadId
        clearLoaded()
        showMode("Model")
        loading = true
        setStatus(LOADING_TEXT)
        autoTitle = info and info.Name or instance.Name
        autoDescription = info and info.Description
        layoutFooter()
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
            activeKind = kind
            syncLinks()
            model.Parent = worldModel
            applyTint()
            setStatus(nil)
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
        autoTitle = material.Name
        activeKind = "Material"
        model.Parent = worldModel
        applyTint()
        setStatus(nil)
        layoutFooter()
        updateCamera()
        fire(callback, material, model, api, "Material")
        return true
    end

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
            player = findPlayer(player)
        end
        if typeof(player) ~= "Instance" or not player:IsA("Player") then
            return fail("player not found.")
        end
        unbindPlayer()
        local token = playerToken
        followedPlayer = player
        local info = { Name = player.DisplayName, Description = "@" .. player.Name }
        loadId = loadId + 1
        clearLoaded()
        showMode("Model")
        loading = true
        setStatus(LOADING_TEXT)
        autoTitle = info.Name
        autoDescription = info.Description
        layoutFooter()
        local function refreshPlayer()
            task.spawn(function()
                local character = waitCharacter(player, token)
                if destroyed or token ~= playerToken then
                    return
                end
                if character then
                    loadInstance(character, "Player", info)
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

    local function trackImage(token, fallback)
        if imageConnection then
            imageConnection:Disconnect()
            imageConnection = nil
        end
        if textureView.Image == "" then
            loading = false
            setStatus(EMPTY_TEXT)
            return
        end
        if textureView.IsLoaded then
            loading = false
            setStatus(nil)
            return
        end
        loading = true
        setStatus(LOADING_TEXT)
        imageConnection = textureView:GetPropertyChangedSignal("IsLoaded"):Connect(function()
            if destroyed or token ~= loadId then
                return
            end
            if textureView.IsLoaded then
                loading = false
                setStatus(nil)
                if imageConnection then
                    imageConnection:Disconnect()
                    imageConnection = nil
                end
            end
        end)
        task.delay(fallback and IMAGE_TIMEOUT or FALLBACK_TIMEOUT, function()
            if destroyed or token ~= loadId or textureView.IsLoaded then
                return
            end
            if fallback then
                textureView.Image = fallback
                trackImage(token, nil)
                return
            end
            loading = false
            setStatus(EMPTY_TEXT)
        end)
    end
    local function showImageSpec(spec, target, token)
        clearLoaded()
        showMode("Image")
        textureView.Image = spec.Image
        loadedSpec = spec
        loadedInstance = spec.Instance
        activeKind = "Image"
        autoTitle = spec.Name
        autoDescription = spec.Description
        if spec.Instance and spec.Property then
            local source = spec.Instance
            local property = spec.Property
            propertyConnection = source:GetPropertyChangedSignal(property):Connect(function()
                if destroyed or token ~= loadId then
                    return
                end
                local value = source[property]
                textureView.Image = type(value) == "string" and value or ""
                trackImage(token, nil)
            end)
        end
        trackImage(token, spec.Fallback)
        layoutFooter()
        updateCamera()
        if fetchInfo and spec.Id and INFO_TYPES[spec.Kind] then
            task.spawn(function()
                local info = requestInfo(spec.Kind, spec.Id)
                if destroyed or token ~= loadId or not info then
                    return
                end
                if type(info.Name) == "string" and info.Name ~= "" then
                    autoTitle = info.Name
                end
                if type(info.Description) == "string" and info.Description ~= "" then
                    autoDescription = info.Description
                end
                layoutFooter()
            end)
        end
        fire(callback, target, textureView, api, "Image", spec)
        return true
    end
    local function resolveName(name, token)
        clearLoaded()
        showMode("Image")
        loading = true
        setStatus(LOADING_TEXT)
        layoutFooter()
        task.spawn(function()
            local ok, userId = pcall(players.GetUserIdFromNameAsync, players, name)
            if destroyed or token ~= loadId then
                return
            end
            if ok and type(userId) == "number" then
                local kind = AVATAR_KINDS[styleKind] and styleKind or KIND_PLAYER
                showImageSpec(thumbSpec(kind, userId, THUMB_LARGE, name, "@" .. name), name, token)
                return
            end
            fail("target not found.")
        end)
        return true
    end
    local function loadImage(payload, style, token)
        local spec, message, notFound = resolveSource(payload, style, THUMB_LARGE, channel)
        if not spec then
            if notFound and type(payload) == "string" then
                local name = (payload:gsub("^@", ""))
                if name:match("^[%w_]+$") and #name >= 3 and #name <= 20 then
                    return resolveName(name, token)
                end
            end
            return fail(message)
        end
        return showImageSpec(spec, payload, token)
    end

    local function loadAuto(target)
        local inner, newTitle, newDescription, newView, newStyle = unpackEntry(target)
        entryTitle = newTitle
        entryDescription = newDescription
        local view = normalizeView(newView) or viewOption
        local style = lookupStyle(newStyle) or styleKind
        lastTarget = inner
        local kind, payload = classify(inner, view)
        if not kind then
            return fail(payload)
        end
        if kind == "Image" and view == "Hologram" then
            return fail("target cannot be shown as hologram.")
        end
        if kind == "Player" then
            return loadPlayer(payload, followOption)
        end
        unbindPlayer()
        if kind == "Material" then
            return loadMaterial(payload)
        end
        if kind == "Image" then
            loadId = loadId + 1
            return loadImage(payload, style, loadId)
        end
        return loadInstance(payload, kind)
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
            return loadAuto(lastTarget)
        end
        return true
    end
    local function loadFromData(data)
        local items = data.list or data.List or data.items or data.Items
        if type(items) == "table" then
            return api:LoadList(items, pick(data, "start", "Start"))
        end
        local target = findTarget(data)
        if target ~= nil then
            return api:Load(target)
        end
        return nil
    end

    function api:Load(target, newTitle, newDescription)
        if destroyed then
            return false
        end
        if target == nil then
            api:Clear()
            return false
        end
        index = 0
        list = {}
        if type(newTitle) == "table" then
            newDescription = pick(newTitle, "description", "Description")
            newTitle = pick(newTitle, "title", "Title")
        end
        if newTitle ~= nil or newDescription ~= nil then
            target = { target = target, title = newTitle, description = newDescription }
        end
        return loadAuto(target)
    end
    function api:Update(data)
        if destroyed or type(data) ~= "table" then
            return false
        end
        local value = pick(data, "title", "Title")
        if value ~= nil then
            api:SetTitle(value)
        end
        value = pick(data, "description", "Description")
        if value ~= nil then
            api:SetDescription(value)
        end
        value = pick(data, "placeholder", "Placeholder")
        if value ~= nil then
            api:SetPlaceholder(value)
        end
        value = pick(data, "channel", "Channel")
        if value ~= nil and CHANNELS[value] then
            channel = value
        end
        value = pick(data, "fetchInfo", "FetchInfo")
        if value ~= nil then
            fetchInfo = value == true
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
        value = pick(data, "style", "Style")
        if value ~= nil then
            local resolved = lookupStyle(value)
            if resolved ~= styleKind then
                styleKind = resolved
                changed = true
            end
        end
        value = pick(data, "view", "View")
        if value ~= nil then
            local resolved = normalizeView(value) or "Auto"
            if resolved ~= viewOption then
                viewOption = resolved
                changed = true
            end
        end
        local result = loadFromData(data)
        if result ~= nil then
            return result
        end
        if changed then
            return reloadCurrent()
        end
        return true
    end
    function api:LoadList(items, start)
        if destroyed or type(items) ~= "table" then
            return false
        end
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
        entryTitle = nil
        entryDescription = nil
        unbindPlayer()
        clearLoaded()
        showMode("Model")
        setStatus(placeholder)
        layoutFooter()
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
    function api:GetTarget()
        return lastTarget
    end
    function api:GetLoaded()
        return loadedInstance
    end
    function api:GetSpec()
        return loadedSpec
    end
    function api:GetName()
        return autoTitle or ""
    end
    function api:GetKind()
        return activeKind
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

    function api:SetView(value)
        local resolved = value == nil and "Auto" or normalizeView(value)
        if not resolved then
            report(("invalid view '%s'."):format(tostring(value)))
            return false
        end
        viewOption = resolved
        return reloadCurrent()
    end
    function api:GetView()
        return viewOption
    end
    function api:SetStyle(value)
        if value == nil then
            styleKind = nil
        else
            local resolved = lookupStyle(value)
            if not resolved then
                report(("invalid style '%s'."):format(tostring(value)))
                return false
            end
            styleKind = resolved
        end
        if activeKind == "Image" then
            return reloadCurrent()
        end
        return true
    end
    function api:GetStyle()
        return styleKind
    end
    function api:SetChannel(value)
        if not CHANNELS[value] then
            report(("invalid channel '%s'."):format(tostring(value)))
            return false
        end
        channel = value
        if activeKind == "Image" then
            return reloadCurrent()
        end
        return true
    end
    function api:SetFetchInfo(value)
        fetchInfo = value == true
    end

    function api:SetLive(value)
        live = value == true
    end
    function api:GetLive()
        return live
    end
    function api:SetLiveRate(value)
        liveRate = tonumber(value)
    end

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
        if not holder and not loading and activeKind == nil then
            setStatus(placeholder)
        end
    end

    function api:SetTitle(value)
        if destroyed then
            return
        end
        manualTitle = value ~= nil and value ~= false and tostring(value) or nil
        entryTitle = nil
        layoutFooter()
    end
    function api:SetDescription(value)
        if destroyed then
            return
        end
        manualDescription = value ~= nil and value ~= false and tostring(value) or nil
        entryDescription = nil
        layoutFooter()
    end
    function api:SetInfo(newTitle, newDescription)
        if destroyed then
            return
        end
        api:SetTitle(newTitle)
        api:SetDescription(newDescription)
    end
    function api:GetTitle()
        return titleLabel.Text
    end
    function api:GetDescription()
        return descLabel.Text
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
        layoutFooter()
        task.defer(updateCamera)
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
        disconnectImage()
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

    function api:SetCallback(handler)
        callback = type(handler) == "function" and handler or nil
    end
    function api:SetOnFail(handler)
        onFail = type(handler) == "function" and handler or nil
    end
    function api:SetOnClear(handler)
        onClear = type(handler) == "function" and handler or nil
    end
    api.Frame = root
    api.Instance = root

    local getters = {
        Title = function()
            return titleLabel.Text
        end,
        Description = function()
            return descLabel.Text
        end,
        Target = function()
            return lastTarget
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
        Style = function()
            return styleKind
        end,
        View = function()
            return viewOption
        end,
    }
    local setters = {
        Title = function(value)
            api:SetTitle(value)
        end,
        Description = function(value)
            api:SetDescription(value)
        end,
        Target = function(value)
            api:Load(value)
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
        Style = function(value)
            api:SetStyle(value)
        end,
        View = function(value)
            api:SetView(value)
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
        if not dragging or displayMode ~= "Model" then
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

    local liveElapsed = 0
    connections[#connections + 1] = runService.Heartbeat:Connect(function(dt)
        if not root.Visible or not holder or displayMode ~= "Model" then
            return
        end
        if live and not loading then
            liveElapsed = liveElapsed + dt
            local rate = liveRate or LIVE_RATES[activeKind] or LIVE_RATE_FALLBACK
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
    loadFromData(options)
    return api
end

Elements.Register("Hologram", buildHologram)
