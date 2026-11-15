-- // Services
local runService = game:GetService("RunService")
local players = game:GetService("Players")
local marketplaceService = game:GetService("MarketplaceService")

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
local PAD = 10
local TITLE_H = 16
local TITLE_GAP = 2
local IMAGE_SIZE_DEFAULT = 64
local IMAGE_SIZE_MIN = 32
local IMAGE_SIZE_MAX = 160
local HEIGHT_MIN = 56
local HEIGHT_MAX = 300
local THUMB_SMALL = 150
local THUMB_LARGE = 420
local THUMB_SWITCH = 75
local IMAGE_TIMEOUT = 4
local FALLBACK_TIMEOUT = 8
local LOADING_TEXT = "..."
local EMPTY_TEXT = "No image"
local SIDE_DEFAULT = "Right"
local KIND_DEFAULT = "Asset"
local KIND_PLAYER = "AvatarHeadShot"
local CHANNEL_DEFAULT = "ColorMap"
local CHANNELS = { ColorMap = true, NormalMap = true, MetalnessMap = true, RoughnessMap = true }
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
    "player",
    "Player",
    "icon",
    "Icon",
    "image",
    "Image",
    "id",
    "Id",
}
local ATTRIBUTE_KEYS = { "AssetId", "ImageId", "Image", "Icon", "Thumbnail", "TextureId", "Id" }
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
local infoCache = {}

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
local function lookupStyle(value)
    if value == nil then
        return nil
    end
    return STYLE_LOOKUP[tostring(value):lower()]
end
local function unpackEntry(value)
    if type(value) ~= "table" then
        return value
    end
    local inner = pick(value, "target", "Target")
    if inner == nil then
        return value
    end
    return inner, pick(value, "title", "Title"), pick(value, "description", "Description"), pick(value, "style", "Style")
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
local function resolveLink(text, style, pixels)
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
            return resolveLink(text, style, pixels)
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

-- // Hologram
local function buildHologram(section, options)
    options = type(options) == "table" and options or {}
    local Colors, watchTheme = createColors(section.Panel or Panel)

    local api = {}
    local connections = {}
    local reported = {}
    local destroyed = false
    local manualTitle = pick(options, "title", "Title")
    local manualDescription = options.description or options.desc or options.Description
    local entryTitle
    local entryDescription
    local autoTitle
    local autoDescription
    local callback = pickFunction(options, "callback", "Callback") or pickFunction(options, "onLoaded", "OnLoaded")
    local onFail = pickFunction(options, "onFail", "OnFail") or pickFunction(options, "onError", "OnError")
    local onClear = pickFunction(options, "onClear", "OnClear")
    local imageSize = math.clamp(math.floor(tonumber(options.size or options.imageSize or options.Size) or IMAGE_SIZE_DEFAULT), IMAGE_SIZE_MIN, IMAGE_SIZE_MAX)
    local heightOption = tonumber(options.height or options.Height)
    local side = tostring(pick(options, "side", "Side") or SIDE_DEFAULT):lower() == "left" and "Left" or "Right"
    local styleKind = lookupStyle(pick(options, "style", "Style"))
    local fetchInfo = options.fetchInfo ~= false
    local channel = CHANNELS[options.channel] and options.channel or CHANNEL_DEFAULT
    local loadId = 0
    local loading = false
    local imageConnection
    local propertyConnection
    local lastTarget
    local loadedSpec
    local list = {}
    local index = 0
    local unwatchTheme

    -- // Callback
    local function report(message)
        local text = ("Hologram '%s': %s"):format(tostring(manualTitle or entryTitle or "Hologram"), message)
        if reported[text] then
            return
        end
        reported[text] = true
        warn(text)
        notify(text, 5)
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

    -- // Interface
    local function getHeight()
        local auto = imageSize + PAD * 2
        if heightOption then
            return math.clamp(heightOption, HEIGHT_MIN, HEIGHT_MAX)
        end
        return math.clamp(auto, HEIGHT_MIN, HEIGHT_MAX)
    end
    local root = create("Frame", {
        Name = tostring(manualTitle or "Hologram") .. "_Hologram",
        Size = UDim2.new(1, 0, 0, getHeight()),
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
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, root)
    local box = create("Frame", {
        Name = "Thumbnail",
        BackgroundColor3 = Colors.Border,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, root)
    create("UICorner", { CornerRadius = UDim.new(0, 6) }, box)
    local image = create("ImageLabel", {
        Name = "Image",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = "",
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 1,
    }, box)
    local statusLabel = create("TextLabel", {
        Name = "Status",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = EMPTY_TEXT,
        Font = fontRegular,
        TextSize = 10,
        TextColor3 = Colors.Dim,
        TextWrapped = true,
        ZIndex = 2,
    }, box)
    local function setStatus(text)
        statusLabel.Text = text or ""
        statusLabel.Visible = text ~= nil
    end
    local function layout()
        root.Size = UDim2.new(1, 0, 0, getHeight())
        box.Size = UDim2.new(0, imageSize, 0, imageSize)
        local textX = PAD
        if side == "Left" then
            box.AnchorPoint = Vector2.new(0, 0.5)
            box.Position = UDim2.new(0, PAD, 0.5, 0)
            textX = imageSize + PAD * 2
        else
            box.AnchorPoint = Vector2.new(1, 0.5)
            box.Position = UDim2.new(1, -PAD, 0.5, 0)
        end
        local textWidth = -(imageSize + PAD * 3)
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
        titleLabel.Text = titleText
        titleLabel.Visible = hasTitle
        descLabel.Text = descText
        descLabel.Visible = hasDesc
        if hasTitle and hasDesc then
            titleLabel.Position = UDim2.new(0, textX, 0, PAD)
            titleLabel.Size = UDim2.new(1, textWidth, 0, TITLE_H)
            descLabel.Position = UDim2.new(0, textX, 0, PAD + TITLE_H + TITLE_GAP)
            descLabel.Size = UDim2.new(1, textWidth, 1, -(PAD * 2 + TITLE_H + TITLE_GAP))
        elseif hasTitle then
            titleLabel.Position = UDim2.new(0, textX, 0.5, -TITLE_H / 2)
            titleLabel.Size = UDim2.new(1, textWidth, 0, TITLE_H)
        else
            descLabel.Position = UDim2.new(0, textX, 0, PAD)
            descLabel.Size = UDim2.new(1, textWidth, 1, -PAD * 2)
        end
        root.Name = tostring(manualTitle or "Hologram") .. "_Hologram"
    end
    layout()
    setStatus(nil)

    -- // Loader
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
    local function clearImage()
        disconnectImage()
        image.Image = ""
        loadedSpec = nil
        autoTitle = nil
        autoDescription = nil
        loading = false
    end
    local function trackImage(token, fallback)
        if imageConnection then
            imageConnection:Disconnect()
            imageConnection = nil
        end
        if image.Image == "" then
            loading = false
            setStatus(EMPTY_TEXT)
            return
        end
        if image.IsLoaded then
            loading = false
            setStatus(nil)
            return
        end
        loading = true
        setStatus(LOADING_TEXT)
        imageConnection = image:GetPropertyChangedSignal("IsLoaded"):Connect(function()
            if destroyed or token ~= loadId then
                return
            end
            if image.IsLoaded then
                loading = false
                setStatus(nil)
                if imageConnection then
                    imageConnection:Disconnect()
                    imageConnection = nil
                end
            end
        end)
        task.delay(fallback and IMAGE_TIMEOUT or FALLBACK_TIMEOUT, function()
            if destroyed or token ~= loadId or image.IsLoaded then
                return
            end
            if fallback then
                image.Image = fallback
                trackImage(token, nil)
                return
            end
            loading = false
            setStatus(EMPTY_TEXT)
        end)
    end
    local function fail(message)
        loadId = loadId + 1
        clearImage()
        setStatus(EMPTY_TEXT)
        layout()
        if message then
            report(message)
            fire(onFail, message)
        end
        return false
    end
    local function showSpec(spec, target, token)
        clearImage()
        image.Image = spec.Image
        loadedSpec = spec
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
                image.Image = type(value) == "string" and value or ""
                trackImage(token, nil)
            end)
        end
        trackImage(token, spec.Fallback)
        layout()
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
                layout()
            end)
        end
        fire(callback, target, image, api, spec)
        return true
    end
    local function resolveName(name, token)
        loading = true
        setStatus(LOADING_TEXT)
        task.spawn(function()
            local ok, userId = pcall(players.GetUserIdFromNameAsync, players, name)
            if destroyed or token ~= loadId then
                return
            end
            if ok and type(userId) == "number" then
                local kind = AVATAR_KINDS[styleKind] and styleKind or KIND_PLAYER
                local pixels = imageSize > THUMB_SWITCH and THUMB_LARGE or THUMB_SMALL
                showSpec(thumbSpec(kind, userId, pixels, name, "@" .. name), name, token)
                return
            end
            fail("target not found.")
        end)
        return true
    end
    local function loadTarget(target)
        if target == nil then
            api:Clear()
            return false
        end
        local inner, newTitle, newDescription, newStyle = unpackEntry(target)
        entryTitle = newTitle
        entryDescription = newDescription
        local style = lookupStyle(newStyle) or styleKind
        local pixels = imageSize > THUMB_SWITCH and THUMB_LARGE or THUMB_SMALL
        loadId = loadId + 1
        local token = loadId
        lastTarget = inner
        local spec, message, notFound = resolveSource(inner, style, pixels, channel)
        if not spec then
            if notFound and type(inner) == "string" and inner:match("^@?[%w_]+$") and #inner >= 3 and #inner <= 20 then
                clearImage()
                layout()
                return resolveName(inner:gsub("^@", ""), token)
            end
            return fail(message)
        end
        return showSpec(spec, inner, token)
    end
    local function selectIndex(position)
        if #list == 0 then
            return false
        end
        index = ((position - 1) % #list) + 1
        return loadTarget(list[index])
    end
    local function reloadCurrent()
        if index > 0 and list[index] ~= nil then
            return loadTarget(list[index])
        end
        if lastTarget ~= nil then
            return loadTarget(lastTarget)
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

    -- // Load API
    function api:Load(target, newTitle, newDescription)
        if destroyed then
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
        return loadTarget(target)
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
        value = pick(data, "channel", "Channel")
        if value ~= nil and CHANNELS[value] then
            channel = value
        end
        value = pick(data, "fetchInfo", "FetchInfo")
        if value ~= nil then
            fetchInfo = value == true
        end
        value = pick(data, "side", "Side")
        if value ~= nil then
            api:SetSide(value)
        end
        value = pick(data, "size", "Size")
        if value ~= nil then
            imageSize = math.clamp(math.floor(tonumber(value) or imageSize), IMAGE_SIZE_MIN, IMAGE_SIZE_MAX)
            layout()
        end
        value = pick(data, "visible", "Visible")
        if value ~= nil then
            api:SetVisible(value)
        end
        local styleChanged = false
        value = pick(data, "style", "Style")
        if value ~= nil then
            local resolved = lookupStyle(value)
            if resolved ~= styleKind then
                styleKind = resolved
                styleChanged = true
            end
        end
        local result = loadFromData(data)
        if result ~= nil then
            return result
        end
        if styleChanged then
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
        index = 0
        list = {}
        lastTarget = nil
        entryTitle = nil
        entryDescription = nil
        clearImage()
        setStatus(nil)
        layout()
        fire(onClear)
    end
    function api:GetTarget()
        return lastTarget
    end
    function api:GetSpec()
        return loadedSpec
    end
    function api:GetName()
        return autoTitle or ""
    end
    function api:GetImage()
        return image.Image
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

    -- // Style API
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
        return reloadCurrent()
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
        return reloadCurrent()
    end
    function api:SetFetchInfo(value)
        fetchInfo = value == true
    end
    function api:SetSize(value)
        if destroyed then
            return
        end
        imageSize = math.clamp(math.floor(tonumber(value) or imageSize), IMAGE_SIZE_MIN, IMAGE_SIZE_MAX)
        layout()
        if lastTarget ~= nil then
            reloadCurrent()
        end
    end
    function api:GetSize()
        return imageSize
    end
    function api:SetSide(value)
        if destroyed then
            return
        end
        side = tostring(value):lower() == "left" and "Left" or "Right"
        layout()
    end
    function api:GetSide()
        return side
    end
    function api:SetHeight(value)
        if destroyed then
            return
        end
        heightOption = tonumber(value)
        layout()
    end

    -- // Control API
    function api:SetTitle(value)
        if destroyed then
            return
        end
        manualTitle = value ~= nil and value ~= false and tostring(value) or nil
        entryTitle = nil
        layout()
    end
    function api:SetDescription(value)
        if destroyed then
            return
        end
        manualDescription = value ~= nil and value ~= false and tostring(value) or nil
        entryDescription = nil
        layout()
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
    api.Frame = root
    api.Instance = root
    api.Image = image

    -- // Properties
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
        Style = function()
            return styleKind
        end,
        Size = function()
            return imageSize
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
        Style = function(value)
            api:SetStyle(value)
        end,
        Size = function(value)
            api:SetSize(value)
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

    -- // Initialization
    unwatchTheme = watchTheme(function()
        if destroyed then
            return
        end
        root.BackgroundColor3 = Colors.Palette
        rootStroke.Color = Colors.Border
        titleLabel.TextColor3 = Colors.Active
        descLabel.TextColor3 = Colors.Dim
        box.BackgroundColor3 = Colors.Border
        statusLabel.TextColor3 = Colors.Dim
    end)
    loadFromData(options)
    return api
end

-- // Register
Elements.Register("Hologram", buildHologram)