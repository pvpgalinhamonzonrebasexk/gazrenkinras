-- // Paragraph
Elements.Register("Paragraph", function(section, options)
    options = type(options) == "table" and options or {}

    local C = {
        TextActive = Color3.fromRGB(250, 250, 250),
        TextDisabled = Color3.fromRGB(82, 82, 91),
        DescText = Color3.fromRGB(113, 113, 122),
        DescDisabled = Color3.fromRGB(70, 70, 78),
        Line = Color3.fromRGB(39, 39, 42),
        ThumbBg = Color3.fromRGB(24, 24, 27),
        CardBg = Color3.fromRGB(16, 16, 16),
        StatusBg = Color3.fromRGB(18, 18, 18),
        Grid = Color3.fromRGB(255, 255, 255),
        Icon = Color3.fromRGB(161, 161, 170),
        CornerText = Color3.fromRGB(212, 212, 216),
        DotActive = Color3.fromRGB(250, 250, 250),
        DotInactive = Color3.fromRGB(82, 82, 91),
        ScrollBar = Color3.fromRGB(82, 82, 91),
    }

    local REMOVABLE = {
        Script = true, LocalScript = true, ModuleScript = true, Sound = true,
        ForceField = true, BillboardGui = true, SurfaceGui = true, ParticleEmitter = true,
        Trail = true, Beam = true, Highlight = true, SelectionBox = true,
        PointLight = true, SpotLight = true, SurfaceLight = true, Smoke = true,
        Fire = true, Sparkles = true, Atmosphere = true, Sky = true, PostEffect = true,
    }

    local KIND_MAP = {
        character = "character", player = "character", user = "character", avatar = "character",
        item = "model", asset = "model", model = "model", mesh = "model",
        accessory = "model", hat = "model", tool = "model",
        image = "image", texture = "image", icon = "image", decal = "image", img = "image",
        thumbnail = "thumbnail", thumb = "thumbnail",
    }

    local THUMB_TYPES = {
        asset = "Asset", avatar = "Avatar", bust = "AvatarBust", avatarbust = "AvatarBust",
        headshot = "AvatarHeadShot", avatarheadshot = "AvatarHeadShot",
        bundle = "BundleThumbnail", bundlethumbnail = "BundleThumbnail",
        game = "GameIcon", gameicon = "GameIcon", gamepass = "GamePass",
        badge = "BadgeIcon", badgeicon = "BadgeIcon", group = "GroupIcon", groupicon = "GroupIcon",
        outfit = "Outfit", product = "DeveloperProduct", developerproduct = "DeveloperProduct",
    }

    local Svc = {
        players = Players or game:GetService("Players"),
        input = UserInputService or game:GetService("UserInputService"),
        tween = TweenService or game:GetService("TweenService"),
        run = RunService or game:GetService("RunService"),
        content = game:GetService("ContentProvider"),
        insert = game:GetService("InsertService"),
    }

    local fontBold = FONT_BOLD or Enum.Font.SourceSansBold
    local fontRegular = FONT or Enum.Font.SourceSans
    local ICON_RIGHT = (ICONS and ICONS.assets and ICONS.assets["lucide-chevron-right"]) or "rbxassetid://10709791437"
    local ICON_LEFT = (ICONS and ICONS.assets and ICONS.assets["lucide-chevron-left"]) or "rbxassetid://10709791281"

    local MOBILE = Svc.input.TouchEnabled and not Svc.input.KeyboardEnabled
    local LOW_END = MOBILE

    pcall(function()
        local level = settings().Rendering.QualityLevel.Value
        if level > 0 and level <= 5 then
            LOW_END = true
        end
    end)

    pcall(function()
        local saved = UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value
        if saved > 0 and saved <= 5 then
            LOW_END = true
        end
    end)

    local sizeOption = tonumber(options.size or options.Size)

    local K = {
        GRID_TILE = MOBILE and 28 or 32,
        GRID_ALPHA = 0.94,
        TITLE = MOBILE and 13 or 12,
        DESC = MOBILE and 11 or 10,
        CORNER = MOBILE and 11 or 10,
        THUMB = MOBILE and 40 or 36,
        CARD_H = math.clamp(sizeOption or (MOBILE and 156 or 140), 100, 320),
        ARROW = MOBILE and 38 or 28,
        ICON = MOBILE and 20 or 16,
        ARROW_PAD = 6,
        EDGE = 10,
        STATUS_LEFT = 14,
        STATUS_RIGHT = 14,
        STAT_H = MOBILE and 20 or 18,
        LIFT = MOBILE and 12 or 10,
        MARGIN = 1.08,
        STEP = 1 / (LOW_END and 20 or 30),
        STEP_SLOW = 1 / 8,
        STEP_HIDDEN = 0.5,
        BUDGET = LOW_END and 0.002 or 0.004,
        HIDDEN_ALPHA = 0.99,
        CACHE_MAX = LOW_END and 1 or 3,
        MAX_PARTS = LOW_END and 160 or 360,
        MAX_DESC = LOW_END and 2500 or 5000,
        ATTEMPTS = LOW_END and 2 or 3,
        RETRY = 0.8,
        PRELOAD = LOW_END and 5 or 8,
        IMAGE_ALT = 3,
        STABLE = LOW_END and 2 or 3,
        STREAM = 2,
        PITCH_ITEM = 16,
        PITCH_CHAR = 6,
        IMAGE_ALPHA = 0.1,
        PAD_Y = 10,
        THUMB_GAP = 10,
        MIN_H = 40,
        UPDATE = MOBILE and 5 or 3,
        WORD_MAX = 30,
        FOV = 40,
        SPEED = 40,
    }

    K.STATUS_LEFT_BACK = K.ARROW + K.ARROW_PAD + 4

    local TI = {
        PAGE = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        FAST = TweenInfo.new(0.12),
        FADE = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    }

    local S = {
        connections = {},
        watch = {},
        cache = {},
        tweens = setmetatable({}, { __mode = "k" }),
        destroyed = false,
        liveToken = 0,
        holoToken = 0,
        loopToken = 0,
        hideToken = 0,
        busy = nil,
        page = "hologram",
        layoutKey = nil,
        model = nil,
        cached = false,
        size = nil,
        pitch = K.PITCH_ITEM,
        angle = 0,
        lastAngle = nil,
        distance = 0,
        light = Vector3.new(0.3, -0.5, 1),
        signature = nil,
        rotateConn = nil,
        rotating = false,
        images = {},
        version = 0,
        reloadPending = false,
        status = {},
        rows = {},
        rich = options.richText ~= false,
        statusTitle = tostring(options.statusTitle or options.StatusTitle or "Status"),
        callback = options.callback or options.Callback,
    }

    if type(S.callback) ~= "function" then
        S.callback = function() end
    end

    local H = {}
    local U = {}

    function H.new(class, props, parent)
        local instance = Instance.new(class)
        for key, value in pairs(props) do
            instance[key] = value
        end
        if parent then
            instance.Parent = parent
        end
        return instance
    end

    function H.corner(instance, radius)
        return H.new("UICorner", { CornerRadius = UDim.new(0, radius) }, instance)
    end

    function H.connect(signal, fn)
        local conn = signal:Connect(fn)
        S.connections[#S.connections + 1] = conn
        return conn
    end

    function H.stopTween(object)
        local running = S.tweens[object]
        if running then
            S.tweens[object] = nil
            running:Cancel()
        end
    end

    function H.tween(object, info, props)
        if S.destroyed or not object or not object.Parent then return end
        H.stopTween(object)
        local ok, tween = pcall(Svc.tween.Create, Svc.tween, object, info, props)
        if ok and tween then
            S.tweens[object] = tween
            tween:Play()
        end
    end

    function H.breakWords(text, maxLen)
        text = tostring(text or "")
        local lines = {}
        for line in (text .. "\n"):gmatch("(.-)\n") do
            local result = {}
            for token in line:gmatch("%S+") do
                local word = token
                while #word > maxLen do
                    result[#result + 1] = word:sub(1, maxLen)
                    word = word:sub(maxLen + 1)
                end
                result[#result + 1] = word
            end
            lines[#lines + 1] = table.concat(result, " ")
        end
        return table.concat(lines, "\n")
    end

    function H.text(text)
        text = tostring(text or "")
        if S.rich then
            return text
        end
        return H.breakWords(text, K.WORD_MAX)
    end

    function H.normalizeImage(value)
        if value == nil or value == "" then return "" end
        local text = tostring(value)
        if text:match("^%d+$") then
            return "rbxassetid://" .. text
        end
        return text
    end

    function H.textOf(value)
        if type(value) == "number" then
            return string.format("%.0f", value)
        end
        return tostring(value)
    end

    function H.assetId(target)
        if typeof(target) == "Instance" then return nil end
        local text = H.textOf(target)
        if text:match("^rbxthumb://") then
            return text:match("[?&]id=(%d+)")
        end
        return text:match("^%d+$")
            or text:match("^rbxassetid://(%d+)")
            or text:match("/library/(%d+)")
            or text:match("/catalog/(%d+)")
            or text:match("[?&]id=(%d+)")
    end

    function H.kind(kind)
        if type(kind) ~= "string" then return nil end
        return KIND_MAP[kind:lower()]
    end

    function H.thumbType(value)
        if type(value) ~= "string" then return "Asset" end
        return THUMB_TYPES[value:lower()] or "Asset"
    end

    function H.thumbUrl(id, thumbType)
        return string.format("rbxthumb://type=%s&id=%s&w=420&h=420", H.thumbType(thumbType), tostring(id))
    end

    function H.isChar(kind)
        return kind == "character"
    end

    function H.isImage(kind)
        return kind == "image"
    end

    function H.isAsset(kind)
        return kind == "model" or kind == "image" or kind == "thumbnail"
    end

    function H.number(value)
        local number = tonumber(value)
        if not number then return tostring(value) end
        if number ~= number or math.abs(number) >= 1e15 then
            return tostring(number)
        end
        if number % 1 == 0 then
            return string.format("%d", number)
        end
        return string.format("%.1f", number)
    end

    function H.copy(source)
        local result = {}
        if type(source) == "table" then
            for key, value in pairs(source) do
                result[key] = value
            end
        end
        return result
    end

    function H.hologram(config)
        if config == nil then return nil end
        if type(config) ~= "table" then
            config = { target = config }
        end
        local tint = config.tint or config.Tint
        local speed = tonumber(config.speed or config.Speed)
        return {
            target = config.target or config.Target,
            type = H.kind(config.type or config.Type),
            thumbType = H.thumbType(config.thumbType or config.thumbnailType or config.thumb),
            corners = H.copy(config.corners or config.info),
            rotate = config.rotate ~= false,
            speed = speed or K.SPEED,
            tint = typeof(tint) == "Color3" and tint or nil,
            live = config.live == true or config.Live == true,
            nonce = config.nonce,
        }
    end

    function H.stat(entry)
        if type(entry) ~= "table" then return nil end
        local name = entry.name or entry.Name or entry[1]
        if name == nil then return nil end
        local value = entry.value
        if value == nil then value = entry.Value end
        if value == nil then value = entry[2] end
        if value == nil then value = "" end
        local max = entry.max or entry.Max or entry[3]
        return { name = tostring(name), value = value, max = tonumber(max) }
    end

    function H.statusList(list)
        local result = {}
        if type(list) == "table" then
            for _, entry in ipairs(list) do
                local stat = H.stat(entry)
                if stat then
                    result[#result + 1] = stat
                end
            end
        end
        return result
    end

    local data = {
        disabled = options.disabled == true or options.Disabled == true,
        title = tostring(options.title or options.Name or ""),
        description = tostring(options.description or options.Description or ""),
        thumbnail = options.thumbnail or options.Thumbnail,
        hologram = H.hologram(options.hologram or options.Hologram),
    }

    if data.thumbnail ~= nil and type(data.thumbnail) ~= "string" and type(data.thumbnail) ~= "number" and type(data.thumbnail) ~= "table" then
        data.thumbnail = nil
    end

    S.status = H.statusList(options.status or options.Status)

    U.container = H.new("Frame", {
        Name = (data.title ~= "" and data.title or "Paragraph") .. "_Paragraph",
        Size = UDim2.new(1, 0, 0, K.MIN_H),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        AutomaticSize = Enum.AutomaticSize.Y,
    }, section.frame)

    H.new("UISizeConstraint", { MinSize = Vector2.new(0, K.MIN_H) }, U.container)
    H.new("UIPadding", { PaddingTop = UDim.new(0, K.PAD_Y), PaddingBottom = UDim.new(0, K.PAD_Y) }, U.container)
    H.new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10),
    }, U.container)

    U.row = H.new("Frame", {
        Name = "Row",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1,
    }, U.container)

    U.rowConstraint = H.new("UISizeConstraint", { MinSize = Vector2.new(0, 0) }, U.row)

    U.thumbFrame = H.new("Frame", {
        Name = "Thumbnail",
        Size = UDim2.fromOffset(K.THUMB, K.THUMB),
        BackgroundColor3 = C.ThumbBg,
        BorderSizePixel = 0,
        Visible = false,
    }, U.row)
    H.corner(U.thumbFrame, 6)

    U.thumbImage = H.new("ImageLabel", {
        Name = "Image",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = "",
        ScaleType = Enum.ScaleType.Crop,
        ZIndex = 2,
    }, U.thumbFrame)
    H.corner(U.thumbImage, 6)

    U.textFrame = H.new("Frame", {
        Name = "TextBlock",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    }, U.row)

    H.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, U.textFrame)

    U.title = H.new("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = H.text(data.title),
        TextColor3 = C.TextActive,
        TextSize = K.TITLE,
        Font = fontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        RichText = S.rich,
        LayoutOrder = 1,
        Visible = data.title ~= "",
    }, U.textFrame)

    U.desc = H.new("TextLabel", {
        Name = "Description",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = H.text(data.description),
        TextColor3 = C.DescText,
        TextSize = K.DESC,
        Font = fontRegular,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        LineHeight = 1.2,
        RichText = S.rich,
        LayoutOrder = 2,
        Visible = data.description ~= "",
    }, U.textFrame)

    U.card = H.new("Frame", {
        Name = "Card",
        Size = UDim2.new(1, 0, 0, K.CARD_H),
        BackgroundColor3 = C.CardBg,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        LayoutOrder = 2,
        Visible = false,
    }, U.container)
    H.corner(U.card, 8)

    U.pages = H.new("Frame", {
        Name = "Pages",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 1,
    }, U.card)

    U.holoPage = H.new("Frame", {
        Name = "Hologram",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = C.CardBg,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, U.pages)
    H.corner(U.holoPage, 8)

    U.grid = H.new("ImageLabel", {
        Name = "Grid",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = "rbxasset://textures/Checkerboard.png",
        ImageColor3 = C.Grid,
        ImageTransparency = K.GRID_ALPHA,
        ScaleType = Enum.ScaleType.Tile,
        TileSize = UDim2.fromOffset(K.GRID_TILE, K.GRID_TILE),
        ZIndex = 1,
    }, U.holoPage)

    U.viewport = H.new("ViewportFrame", {
        Name = "Viewport",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, -K.LIFT),
        BackgroundTransparency = 1,
        ImageTransparency = 0,
        Ambient = Color3.fromRGB(190, 190, 200),
        LightColor = Color3.fromRGB(255, 255, 255),
        LightDirection = S.light,
        ZIndex = 3,
    }, U.holoPage)

    U.camera = H.new("Camera", { FieldOfView = K.FOV }, U.viewport)
    U.viewport.CurrentCamera = U.camera

    U.fallback = H.new("ImageLabel", {
        Name = "Fallback",
        Size = UDim2.fromOffset(K.CARD_H - 44, K.CARD_H - 44),
        Position = UDim2.new(0.5, 0, 0.5, -K.LIFT),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = "",
        ImageTransparency = K.IMAGE_ALPHA,
        ScaleType = Enum.ScaleType.Fit,
        Visible = false,
        ZIndex = 3,
    }, U.holoPage)

    function H.cornerLabel(name, position, anchor, alignX, alignY, font, color)
        return H.new("TextLabel", {
            Name = name,
            Size = UDim2.new(0.5, -(K.EDGE + 8), 0, 16),
            AnchorPoint = anchor,
            Position = position,
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = color,
            TextSize = K.CORNER,
            Font = font,
            TextXAlignment = alignX,
            TextYAlignment = alignY,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextStrokeTransparency = 0.75,
            RichText = S.rich,
            Visible = false,
            ZIndex = 5,
        }, U.holoPage)
    end

    U.corners = {
        topLeft = H.cornerLabel("TopLeft", UDim2.new(0, K.EDGE, 0, K.EDGE), Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Top, fontBold, C.TextActive),
        topRight = H.cornerLabel("TopRight", UDim2.new(1, -K.EDGE, 0, K.EDGE), Vector2.new(1, 0), Enum.TextXAlignment.Right, Enum.TextYAlignment.Top, fontRegular, C.DescText),
        bottomLeft = H.cornerLabel("BottomLeft", UDim2.new(0, K.EDGE, 1, -K.EDGE), Vector2.new(0, 1), Enum.TextXAlignment.Left, Enum.TextYAlignment.Bottom, fontRegular, C.CornerText),
        bottomRight = H.cornerLabel("BottomRight", UDim2.new(1, -K.EDGE, 1, -K.EDGE), Vector2.new(1, 1), Enum.TextXAlignment.Right, Enum.TextYAlignment.Bottom, fontRegular, C.DescText),
    }

    U.statusPage = H.new("Frame", {
        Name = "Status",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = C.StatusBg,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, U.pages)
    H.corner(U.statusPage, 8)

    U.statusHeader = H.new("TextLabel", {
        Name = "Header",
        Size = UDim2.new(1, -(K.STATUS_LEFT + K.STATUS_RIGHT), 0, 16),
        Position = UDim2.new(0, K.STATUS_LEFT, 0, 10),
        BackgroundTransparency = 1,
        Text = S.statusTitle,
        TextColor3 = C.TextActive,
        TextSize = K.TITLE,
        Font = fontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, U.statusPage)

    U.statusLine = H.new("Frame", {
        Name = "Line",
        Size = UDim2.new(1, -(K.STATUS_LEFT + K.STATUS_RIGHT), 0, 1),
        Position = UDim2.new(0, K.STATUS_LEFT, 0, 30),
        BackgroundColor3 = C.Line,
        BorderSizePixel = 0,
    }, U.statusPage)

    U.statusScroll = H.new("ScrollingFrame", {
        Name = "List",
        Size = UDim2.new(1, -(K.STATUS_LEFT + K.STATUS_RIGHT), 1, -46),
        Position = UDim2.new(0, K.STATUS_LEFT, 0, 38),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        ScrollBarImageColor3 = C.ScrollBar,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollingEnabled = false,
        ElasticBehavior = Enum.ElasticBehavior.Never,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, U.statusPage)

    H.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 7) }, U.statusScroll)
    H.new("UIPadding", { PaddingRight = UDim.new(0, 6) }, U.statusScroll)

    function H.updateScroll()
        local overflow = U.statusScroll.AbsoluteCanvasSize.Y > U.statusScroll.AbsoluteSize.Y + 1
        if U.statusScroll.ScrollingEnabled ~= overflow then
            U.statusScroll.ScrollingEnabled = overflow
        end
        local thickness = overflow and (MOBILE and 3 or 2) or 0
        if U.statusScroll.ScrollBarThickness ~= thickness then
            U.statusScroll.ScrollBarThickness = thickness
        end
    end

    H.connect(U.statusScroll:GetPropertyChangedSignal("AbsoluteCanvasSize"), H.updateScroll)
    H.connect(U.statusScroll:GetPropertyChangedSignal("AbsoluteSize"), H.updateScroll)

    function H.layoutStatus(hasBack)
        local left = hasBack and K.STATUS_LEFT_BACK or K.STATUS_LEFT
        local width = -(left + K.STATUS_RIGHT)
        U.statusHeader.Position = UDim2.new(0, left, 0, 10)
        U.statusHeader.Size = UDim2.new(1, width, 0, 16)
        U.statusLine.Position = UDim2.new(0, left, 0, 30)
        U.statusLine.Size = UDim2.new(1, width, 0, 1)
        U.statusScroll.Position = UDim2.new(0, left, 0, 38)
        U.statusScroll.Size = UDim2.new(1, width, 1, -46)
    end

    function H.arrow(name, image, anchor, position)
        local button = H.new("ImageButton", {
            Name = name,
            Size = UDim2.fromOffset(K.ARROW, K.ARROW),
            AnchorPoint = anchor,
            Position = position,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Selectable = false,
            Image = "",
            Visible = false,
            ZIndex = 8,
        }, U.card)

        local icon = H.new("ImageLabel", {
            Name = "Icon",
            Size = UDim2.fromOffset(K.ICON, K.ICON),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = image,
            ImageColor3 = C.Icon,
            ZIndex = 9,
        }, button)

        local function isPointer(input)
            return input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseButton1
        end

        H.connect(button.MouseEnter, function()
            if Svc.input:GetLastInputType() == Enum.UserInputType.Touch then return end
            H.tween(icon, TI.FAST, { ImageColor3 = C.TextActive })
        end)
        H.connect(button.MouseLeave, function()
            H.tween(icon, TI.FAST, { ImageColor3 = C.Icon })
        end)
        H.connect(button.InputBegan, function(input)
            if isPointer(input) then
                H.tween(icon, TI.FAST, { ImageColor3 = C.TextActive })
            end
        end)
        H.connect(button.InputEnded, function(input)
            if isPointer(input) then
                H.tween(icon, TI.FAST, { ImageColor3 = C.Icon })
            end
        end)

        return button
    end

    U.nextButton = H.arrow("Next", ICON_RIGHT, Vector2.new(1, 0.5), UDim2.new(1, -K.ARROW_PAD, 0.5, 0))
    U.backButton = H.arrow("Back", ICON_LEFT, Vector2.new(0, 0.5), UDim2.new(0, K.ARROW_PAD, 0.5, 0))

    U.dots = H.new("Frame", {
        Name = "Dots",
        Size = UDim2.new(0, 40, 0, 6),
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -8),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 8,
    }, U.card)

    H.new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    }, U.dots)

    function H.dot(name, order, active)
        local dot = H.new("Frame", {
            Name = name,
            Size = UDim2.fromOffset(active and 14 or 6, 6),
            BackgroundColor3 = active and C.DotActive or C.DotInactive,
            BorderSizePixel = 0,
            LayoutOrder = order,
            ZIndex = 8,
        }, U.dots)
        H.corner(dot, 99)
        return dot
    end

    U.dotHolo = H.dot("DotHologram", 1, true)
    U.dotStatus = H.dot("DotStatus", 2, false)

    U.veil = H.new("Frame", {
        Name = "Veil",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Active = true,
        Visible = false,
        ZIndex = 20,
    }, U.card)
    H.corner(U.veil, 8)

    function H.isShown()
        local node = U.container
        while node do
            if node:IsA("LayerCollector") then
                return node.Enabled
            end
            if node:IsA("GuiObject") and not node.Visible then
                return false
            end
            node = node.Parent
        end
        return false
    end

    function H.visible()
        return U.card.Visible and U.viewport.Visible and S.page == "hologram" and H.isShown()
    end

    function H.updateRow()
        U.row.Visible = data.title ~= "" or data.description ~= "" or (data.thumbnail ~= nil and data.thumbnail ~= "")
    end

    function H.applyDisabled()
        U.title.TextColor3 = data.disabled and C.TextDisabled or C.TextActive
        U.desc.TextColor3 = data.disabled and C.DescDisabled or C.DescText
        U.thumbImage.ImageTransparency = data.disabled and 0.5 or 0
        U.veil.Visible = data.disabled
    end

    function H.fire(page)
        task.spawn(pcall, S.callback, page, data)
    end

    function H.layoutThumb(hasThumb)
        U.rowConstraint.MinSize = Vector2.new(0, hasThumb and K.THUMB or 0)
        if hasThumb then
            local offset = K.THUMB + K.THUMB_GAP
            U.thumbFrame.Visible = true
            U.textFrame.Position = UDim2.new(0, offset, 0, 0)
            U.textFrame.Size = UDim2.new(1, -offset, 0, 0)
        else
            U.thumbFrame.Visible = false
            U.thumbImage.Image = ""
            U.textFrame.Position = UDim2.new(0, 0, 0, 0)
            U.textFrame.Size = UDim2.new(1, 0, 0, 0)
        end
    end

    function H.fetchUserThumb(userId)
        local ok, result, ready = pcall(function()
            return Svc.players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        if ok and result then
            return result, ready ~= false
        end
        return nil, false
    end

    function H.stopThumbLive()
        S.liveToken = S.liveToken + 1
    end

    function H.startThumbLive(userId)
        S.liveToken = S.liveToken + 1
        local token = S.liveToken
        task.spawn(function()
            while not S.destroyed and S.liveToken == token do
                local image, ready = H.fetchUserThumb(userId)
                if S.destroyed or S.liveToken ~= token then return end
                if image and U.thumbImage.Image ~= image then
                    U.thumbImage.Image = image
                end
                if image and ready then return end
                task.wait(K.UPDATE)
            end
        end)
    end

    function H.thumbValue(value)
        if type(value) == "table" then
            local id, kind
            local asset = value.asset or value.Asset
            local user = value.user or value.User
            if asset ~= nil then
                id, kind = H.assetId(asset), "Asset"
            elseif user ~= nil then
                id, kind = H.assetId(user), "AvatarHeadShot"
            else
                id = H.assetId(value.id or value.Id)
                kind = H.thumbType(value.type or value.Type)
            end
            if not id then return nil end
            return H.thumbUrl(id, kind)
        end
        if type(value) == "number" or type(value) == "string" then
            return value
        end
        return nil
    end

    function H.setThumbnail(value)
        H.stopThumbLive()
        data.thumbnail = value

        local resolved = H.thumbValue(value)

        if resolved == nil or resolved == "" then
            H.layoutThumb(false)
            H.updateRow()
            return
        end

        H.layoutThumb(true)

        if type(resolved) == "number" then
            U.thumbImage.Image = ""
            H.startThumbLive(resolved)
        else
            U.thumbImage.Image = H.normalizeImage(resolved)
        end

        H.updateRow()
    end

    function H.hasHologram()
        return data.hologram ~= nil
    end

    function H.hasStatus()
        return #S.status > 0
    end

    function H.pageKey()
        return S.page .. (H.hasHologram() and "1" or "0") .. (H.hasStatus() and "1" or "0")
    end

    function H.applyPage(animate)
        S.layoutKey = H.pageKey()

        local onHolo = S.page == "hologram"
        local holoPosition = onHolo and UDim2.new(0, 0, 0, 0) or UDim2.new(-1, 0, 0, 0)
        local statusPosition = onHolo and UDim2.new(1, 0, 0, 0) or UDim2.new(0, 0, 0, 0)

        S.hideToken = S.hideToken + 1
        local hideToken = S.hideToken

        if onHolo then
            U.viewport.Visible = true
        elseif animate then
            task.delay(TI.PAGE.Time + 0.05, function()
                if not S.destroyed and S.hideToken == hideToken then
                    U.viewport.Visible = false
                end
            end)
        else
            U.viewport.Visible = false
        end

        if animate then
            H.tween(U.holoPage, TI.PAGE, { Position = holoPosition })
            H.tween(U.statusPage, TI.PAGE, { Position = statusPosition })
        else
            H.stopTween(U.holoPage)
            H.stopTween(U.statusPage)
            U.holoPage.Position = holoPosition
            U.statusPage.Position = statusPosition
        end

        local both = H.hasHologram() and H.hasStatus()
        H.layoutStatus(both)
        U.card.Visible = H.hasHologram() or H.hasStatus()
        U.nextButton.Visible = both and onHolo
        U.backButton.Visible = both and not onHolo
        U.dots.Visible = both

        H.tween(U.dotHolo, TI.FAST, {
            Size = UDim2.fromOffset(onHolo and 14 or 6, 6),
            BackgroundColor3 = onHolo and C.DotActive or C.DotInactive,
        })
        H.tween(U.dotStatus, TI.FAST, {
            Size = UDim2.fromOffset(onHolo and 6 or 14, 6),
            BackgroundColor3 = onHolo and C.DotInactive or C.DotActive,
        })
    end

    function H.syncPage()
        if S.page == "status" and not H.hasStatus() then
            S.page = "hologram"
        end
        if S.page == "hologram" and not H.hasHologram() and H.hasStatus() then
            S.page = "status"
        end
        if H.pageKey() == S.layoutKey then return end
        H.applyPage(false)
    end

    function H.setPage(page, animate)
        if page ~= "hologram" and page ~= "status" then return end
        if page == "hologram" and not H.hasHologram() then return end
        if page == "status" and not H.hasStatus() then return end
        local changed = S.page ~= page
        S.page = page
        H.applyPage(animate)
        if changed then
            H.fire(page)
        end
    end

    function H.formatStat(stat)
        if stat.max ~= nil and tonumber(stat.value) ~= nil then
            return H.number(stat.value) .. "/" .. H.number(stat.max)
        end
        if type(stat.value) == "number" then
            return H.number(stat.value)
        end
        return tostring(stat.value)
    end

    function H.createStatRow(stat, index)
        local row = H.new("Frame", {
            Name = "Stat_" .. index,
            Size = UDim2.new(1, 0, 0, K.STAT_H),
            BackgroundTransparency = 1,
            LayoutOrder = index,
        }, U.statusScroll)

        local nameLabel = H.new("TextLabel", {
            Name = "Name",
            Size = UDim2.new(0.5, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = stat.name,
            TextColor3 = C.DescText,
            TextSize = K.DESC + 1,
            Font = fontRegular,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            RichText = S.rich,
        }, row)

        local valueLabel = H.new("TextLabel", {
            Name = "Value",
            Size = UDim2.new(0.5, 0, 1, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = H.formatStat(stat),
            TextColor3 = C.TextActive,
            TextSize = K.DESC + 1,
            Font = fontBold,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextTruncate = Enum.TextTruncate.AtEnd,
            RichText = S.rich,
        }, row)

        return { frame = row, nameLabel = nameLabel, valueLabel = valueLabel }
    end

    function H.refreshStat(index)
        local stat = S.status[index]
        local row = S.rows[index]
        if not stat or not row then return end
        local text = H.formatStat(stat)
        if row.nameLabel.Text ~= stat.name then
            row.nameLabel.Text = stat.name
        end
        if row.valueLabel.Text ~= text then
            row.valueLabel.Text = text
        end
    end

    function H.rebuildStatus()
        local saved = U.statusScroll.CanvasPosition
        for index = #S.rows, #S.status + 1, -1 do
            S.rows[index].frame:Destroy()
            S.rows[index] = nil
        end
        for index, stat in ipairs(S.status) do
            local row = S.rows[index]
            if row then
                row.frame.Name = "Stat_" .. index
                row.frame.LayoutOrder = index
                H.refreshStat(index)
            else
                S.rows[index] = H.createStatRow(stat, index)
            end
        end
        H.syncPage()
        task.defer(function()
            if not S.destroyed then
                U.statusScroll.CanvasPosition = saved
            end
        end)
    end

    function H.applyCorners()
        local corners = data.hologram and data.hologram.corners or {}
        for name, label in pairs(U.corners) do
            local text = corners[name]
            text = text == nil and "" or tostring(text)
            if label.Text ~= text then
                label.Text = text
            end
            local visible = text ~= ""
            if label.Visible ~= visible then
                label.Visible = visible
            end
        end
    end

    function H.applyOrbit()
        local rotation = CFrame.Angles(0, -math.rad(S.angle), 0)
        local pitch = math.rad(S.pitch)
        local offset = Vector3.new(0, math.sin(pitch) * S.distance, -math.cos(pitch) * S.distance)
        U.camera.CFrame = CFrame.lookAt(rotation * offset, Vector3.zero)
        if S.lastAngle ~= S.angle then
            S.lastAngle = S.angle
            U.viewport.LightDirection = rotation * S.light
        end
    end

    function H.fitCamera()
        if not S.size then return end
        local size = S.size
        local pitch = math.rad(S.pitch)
        local tanHalf = math.tan(math.rad(U.camera.FieldOfView * 0.5))
        local view = U.viewport.AbsoluteSize
        local aspect = view.Y > 0 and view.X / view.Y or 2.5
        local radius = math.sqrt(size.X * size.X + size.Z * size.Z) * 0.5
        local extentY = size.Y * math.cos(pitch) + 2 * radius * math.sin(pitch)
        local fitY = extentY * 0.5 / tanHalf
        local fitX = radius / (tanHalf * aspect)
        S.distance = math.max((math.max(fitY, fitX) + radius) * K.MARGIN, 0.5)
        H.applyOrbit()
    end

    function H.cacheFind(config)
        for index, entry in ipairs(S.cache) do
            if entry.target == config.target
                and entry.kind == config.type
                and entry.tint == config.tint
                and entry.nonce == config.nonce
                and entry.holder.Parent == nil then
                table.remove(S.cache, index)
                S.cache[#S.cache + 1] = entry
                return entry
            end
        end
        return nil
    end

    function H.cacheStore(config, holder, size, isCharacter)
        local entry = {
            target = config.target,
            kind = config.type,
            tint = config.tint,
            nonce = config.nonce,
            holder = holder,
            size = size,
            isCharacter = isCharacter,
        }
        S.cache[#S.cache + 1] = entry
        while #S.cache > K.CACHE_MAX do
            local old = table.remove(S.cache, 1)
            if old.holder ~= holder then
                old.holder:Destroy()
            end
        end
        return entry
    end

    function H.cacheClear()
        for _, entry in ipairs(S.cache) do
            entry.holder:Destroy()
        end
        S.cache = {}
    end

    function H.stopRotate()
        S.rotating = false
        if S.rotateConn then
            S.rotateConn:Disconnect()
            S.rotateConn = nil
        end
    end

    function H.startRotate()
        if S.rotating or S.destroyed then return end
        S.rotating = true
        local accumulated = 0
        local interval = K.STEP
        local checkedAt = 0
        local shown = H.visible()
        S.rotateConn = Svc.run.Heartbeat:Connect(function(delta)
            if S.destroyed then return end
            accumulated = accumulated + delta
            if accumulated < interval then return end
            local elapsed = accumulated
            accumulated = 0
            local now = os.clock()
            if now - checkedAt >= 0.5 then
                checkedAt = now
                shown = H.visible()
            end
            local config = data.hologram
            if shown and S.model and config and config.rotate then
                S.angle = (S.angle + math.min(elapsed, K.STEP_SLOW) * config.speed) % 360
                H.applyOrbit()
                interval = elapsed > K.STEP * 2.5 and K.STEP_SLOW or K.STEP
            else
                interval = K.STEP_HIDDEN
            end
        end)
    end

    function H.clearHologram()
        H.stopRotate()
        local old = S.model
        local wasCached = S.cached
        S.model = nil
        S.cached = false
        S.size = nil
        S.signature = nil
        if old then
            old.Parent = nil
            if not wasCached then
                task.defer(old.Destroy, old)
            end
        end
        U.fallback.Image = ""
        U.fallback.ImageColor3 = Color3.new(1, 1, 1)
        U.fallback.Visible = false
    end

    function H.mountHolder(holder, size, isCharacter, cacheEntry)
        S.pitch = isCharacter and K.PITCH_CHAR or K.PITCH_ITEM
        S.size = size
        H.stopTween(U.viewport)
        U.viewport.ImageTransparency = LOW_END and 0 or 1
        holder.Parent = U.viewport
        S.model = holder
        S.cached = cacheEntry ~= nil
        S.lastAngle = nil
        H.fitCamera()
        U.fallback.Visible = false
        if not LOW_END then
            H.tween(U.viewport, TI.FADE, { ImageTransparency = 0 })
        end
        local config = data.hologram
        if config and config.rotate then
            H.startRotate()
        end
    end

    function H.resetPose(model)
        local root = model:FindFirstChild("HumanoidRootPart")
        if not root or not root:IsA("BasePart") then return end

        local joints = {}
        for _, descendant in ipairs(model:GetDescendants()) do
            if descendant:IsA("JointInstance") and descendant.Part0 and descendant.Part1 then
                joints[#joints + 1] = descendant
            end
        end

        local targets = { [root] = root.CFrame }
        local progress = true
        local guard = 0
        while progress and guard < 64 do
            progress = false
            guard = guard + 1
            for _, joint in ipairs(joints) do
                local part0 = joint.Part0
                local part1 = joint.Part1
                if targets[part0] and not targets[part1] then
                    targets[part1] = targets[part0] * joint.C0 * joint.C1:Inverse()
                    progress = true
                elseif targets[part1] and not targets[part0] then
                    targets[part0] = targets[part1] * joint.C1 * joint.C0:Inverse()
                    progress = true
                end
            end
        end

        for _, joint in ipairs(joints) do
            joint:Destroy()
        end
        for part, cframe in pairs(targets) do
            part.CFrame = cframe
        end
    end

    function H.pacer(token)
        local last = os.clock()
        return function()
            if os.clock() - last < K.BUDGET then
                return false
            end
            task.wait()
            last = os.clock()
            return S.destroyed or S.holoToken ~= token
        end
    end

    function H.collectParts(model, token)
        local isCharacter = model:FindFirstChildOfClass("Humanoid") ~= nil

        if isCharacter then
            for _, child in ipairs(model:GetChildren()) do
                if child:IsA("Tool") then
                    child:Destroy()
                end
            end
        end

        pcall(function()
            model.LevelOfDetail = Enum.ModelLevelOfDetail.Disabled
        end)

        local parts = {}
        local pace = H.pacer(token)

        for _, descendant in ipairs(model:GetDescendants()) do
            if descendant:IsA("BasePart") then
                parts[#parts + 1] = descendant
            elseif REMOVABLE[descendant.ClassName] or descendant:IsA("PostEffect") then
                descendant:Destroy()
            end
            if pace() then
                return nil, isCharacter
            end
        end

        return parts, isCharacter
    end

    function H.setFidelity(part, value)
        part.RenderFidelity = value
    end

    function H.tuneParts(parts, tint, token)
        local fidelity = LOW_END and Enum.RenderFidelity.Performance or Enum.RenderFidelity.Automatic
        local pace = H.pacer(token)
        for _, part in ipairs(parts) do
            if part.Parent then
                part.Anchored = true
                part.CanCollide = false
                part.CanTouch = false
                part.CanQuery = false
                part.CastShadow = false
                if tint then
                    part.Color = part.Color:Lerp(tint, 0.4)
                end
                if part:IsA("MeshPart") then
                    pcall(H.setFidelity, part, fidelity)
                end
            end
            if pace() then
                return false
            end
        end
        return true
    end

    function H.dropInvisible(parts, token)
        local kept = {}
        local pace = H.pacer(token)
        for _, part in ipairs(parts) do
            if part.Parent then
                if part.Transparency >= K.HIDDEN_ALPHA then
                    part:Destroy()
                else
                    kept[#kept + 1] = part
                end
            end
            if pace() then
                return nil
            end
        end
        return kept
    end

    function H.limitParts(parts, maxParts, token)
        if #parts <= maxParts then
            return parts
        end

        local pace = H.pacer(token)
        local sizes = {}
        for _, part in ipairs(parts) do
            sizes[part] = part.Size.Magnitude
            if pace() then
                return nil
            end
        end

        local ranked = table.clone(parts)
        table.sort(ranked, function(a, b)
            return sizes[a] > sizes[b]
        end)

        local kept = table.create(maxParts)
        for index, part in ipairs(ranked) do
            if index <= maxParts then
                kept[index] = part
            elseif part.Parent then
                part:Destroy()
            end
            if pace() then
                return nil
            end
        end
        return kept
    end

    function H.measure(holder)
        local root = holder:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") then
            holder.PrimaryPart = root
        else
            holder.PrimaryPart = nil
            holder.WorldPivot = CFrame.new()
        end
        local measured, boxCFrame, boxSize = pcall(function()
            return holder:GetBoundingBox()
        end)
        holder.PrimaryPart = nil
        if not measured or boxSize.Magnitude <= 0 then
            return nil, nil
        end
        return boxCFrame, boxSize
    end

    function H.waitStable(source, token)
        if not workspace.StreamingEnabled or not source:IsDescendantOf(workspace) then
            return
        end

        pcall(function()
            local localPlayer = Svc.players.LocalPlayer
            if localPlayer then
                local position
                if source:IsA("Model") then
                    position = source:GetPivot().Position
                elseif source:IsA("BasePart") then
                    position = source.Position
                end
                if position then
                    localPlayer:RequestStreamAroundAsync(position, K.STREAM)
                end
            end
        end)

        local lastChange = os.clock()
        local watcher = source.DescendantAdded:Connect(function()
            lastChange = os.clock()
        end)
        local started = os.clock()
        while os.clock() - started < K.STABLE do
            if S.destroyed or S.holoToken ~= token then
                break
            end
            if os.clock() - lastChange >= 0.6 then
                break
            end
            task.wait(0.2)
        end
        watcher:Disconnect()
    end

    function H.cloneSource(source, token)
        local changed = {}
        local pace = token and H.pacer(token) or nil
        local cancelled = false
        local count = 0
        local limit = source:FindFirstChildOfClass("Humanoid") and math.huge or K.MAX_DESC

        local function force(instance)
            if not instance.Archivable then
                changed[#changed + 1] = instance
                pcall(function()
                    instance.Archivable = true
                end)
            end
        end

        force(source)
        for _, descendant in ipairs(source:GetDescendants()) do
            force(descendant)
            count = count + 1
            if count > limit then
                cancelled = true
                break
            end
            if pace and pace() then
                cancelled = true
                break
            end
        end

        local ok, clone = false, nil
        if not cancelled then
            ok, clone = pcall(function()
                return source:Clone()
            end)
        end

        for _, instance in ipairs(changed) do
            pcall(function()
                instance.Archivable = false
            end)
        end

        if ok then
            return clone
        end
        return nil
    end

    function H.preload(holder, token)
        local finished = false
        task.spawn(function()
            pcall(function()
                Svc.content:PreloadAsync({ holder })
            end)
            finished = true
        end)
        local started = os.clock()
        while not finished and os.clock() - started < K.PRELOAD do
            if S.destroyed or S.holoToken ~= token then return end
            task.wait(0.1)
        end
    end

    function H.buildHolder(source, tint, token, temporary)
        if not temporary and not source:FindFirstChildOfClass("Humanoid") then
            H.waitStable(source, token)
        end
        if S.destroyed or S.holoToken ~= token then return nil end

        local clone = temporary and source or H.cloneSource(source, token)
        if not clone then return nil end

        local holder = clone
        if not clone:IsA("Model") then
            holder = Instance.new("Model")
            clone.Parent = holder
        end

        local parts, isCharacter = H.collectParts(holder, token)
        if not parts or S.destroyed or S.holoToken ~= token then
            holder:Destroy()
            return nil
        end

        if not isCharacter then
            parts = H.dropInvisible(parts, token)
            if parts then
                parts = H.limitParts(parts, K.MAX_PARTS, token)
            end
            if not parts or S.destroyed or S.holoToken ~= token then
                holder:Destroy()
                return nil
            end
        end

        if #parts == 0 then
            holder:Destroy()
            return nil
        end

        if not H.tuneParts(parts, tint, token) or S.destroyed or S.holoToken ~= token then
            holder:Destroy()
            return nil
        end

        if isCharacter then
            H.resetPose(holder)
        end

        H.preload(holder, token)
        if S.destroyed or S.holoToken ~= token then
            holder:Destroy()
            return nil
        end

        local boxCFrame, boxSize = H.measure(holder)
        if not boxCFrame then
            holder:Destroy()
            return nil
        end

        holder.WorldPivot = boxCFrame
        holder:PivotTo(CFrame.new())
        return holder, boxSize, isCharacter
    end

    function H.resolveTarget(target, kind)
        if typeof(target) == "Instance" then
            if target:IsA("Player") then
                return target, target.UserId
            end
            if target:IsA("Model") then
                local owner = Svc.players:GetPlayerFromCharacter(target)
                if owner then
                    return owner, owner.UserId
                end
            end
            return nil, nil
        end

        if H.isAsset(kind) then return nil, nil end

        if type(target) == "number" then
            local found = Svc.players:GetPlayerByUserId(target)
            if found or H.isChar(kind) then
                return found, target
            end
            return nil, nil
        end

        if type(target) == "string" then
            local lower = target:lower()
            if lower == "localplayer" and Svc.players.LocalPlayer then
                return Svc.players.LocalPlayer, Svc.players.LocalPlayer.UserId
            end
            local number = tonumber(target)
            if number then
                local found = Svc.players:GetPlayerByUserId(number)
                if found or H.isChar(kind) then
                    return found, number
                end
                return nil, nil
            end
            for _, candidate in ipairs(Svc.players:GetPlayers()) do
                if candidate.Name:lower() == lower or candidate.DisplayName:lower() == lower then
                    return candidate, candidate.UserId
                end
            end
        end

        return nil, nil
    end

    function H.findByPath(text)
        local lowered = text:lower()
        local node, rest
        if lowered:sub(1, 5) == "game." then
            node = game
            rest = text:sub(6)
        elseif lowered:sub(1, 10) == "workspace." then
            node = workspace
            rest = text:sub(11)
        else
            return nil
        end
        for name in rest:gmatch("[^%.]+") do
            node = node and node:FindFirstChild(name)
            if not node then return nil end
        end
        return node
    end

    function H.packObjects(objects)
        local usable = {}
        for _, object in ipairs(objects) do
            if object:IsA("BasePart") or object:FindFirstChildWhichIsA("BasePart", true) then
                usable[#usable + 1] = object
            end
        end
        if #usable == 0 then return nil end

        for _, object in ipairs(objects) do
            if not table.find(usable, object) then
                pcall(object.Destroy, object)
            end
        end

        local only = usable[1]
        if #usable == 1 and (only:IsA("Model") or only:IsA("Tool") or only:IsA("Accessory") or only:IsA("BasePart")) then
            return only
        end

        local model = Instance.new("Model")
        for _, object in ipairs(usable) do
            object.Parent = model
        end
        return model
    end

    function H.findTexture(objects)
        for _, object in ipairs(objects) do
            if object:IsA("Decal") or object:IsA("Texture") then
                return object.Texture
            elseif object:IsA("Shirt") then
                return object.ShirtTemplate
            elseif object:IsA("Pants") then
                return object.PantsTemplate
            elseif object:IsA("ShirtGraphic") then
                return object.Graphic
            end
            local nested = object:FindFirstChildWhichIsA("Decal", true) or object:FindFirstChildWhichIsA("Texture", true)
            if nested then
                return nested.Texture
            end
        end
        return nil
    end

    function H.destroyAll(objects)
        for _, object in ipairs(objects) do
            pcall(object.Destroy, object)
        end
    end

    function H.resolveSource(target, kind)
        if type(target) == "string" then
            local found = H.findByPath(target)
            if found then
                target = found
            end
        end

        local player, userId = H.resolveTarget(target, kind)

        if typeof(target) == "Instance" and not player then
            if target:IsA("Decal") or target:IsA("Texture") then
                return nil, target.Texture, false
            end
            if target:IsA("ImageLabel") or target:IsA("ImageButton") then
                return nil, target.Image, false
            end
            return target, nil, false
        end

        if player and player.Character then
            return player.Character, nil, false
        end

        if userId then
            local modelOk, model = pcall(function()
                return Svc.players:CreateHumanoidModelFromUserId(userId)
            end)
            if modelOk and typeof(model) == "Instance" then
                return model, nil, true
            end
            local thumbOk, thumb = pcall(function()
                return Svc.players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
            end)
            if thumbOk and thumb then
                return nil, thumb, false
            end
            return nil, nil, false
        end

        if H.isChar(kind) then
            return nil, nil, false
        end

        local assetId = H.assetId(target)
        if not assetId then
            return nil, nil, false
        end

        local objectsOk, objects = pcall(function()
            return game:GetObjects("rbxassetid://" .. assetId)
        end)
        if objectsOk and type(objects) == "table" and #objects > 0 then
            local packed = H.packObjects(objects)
            if packed then
                return packed, nil, true
            end
            local texture = H.findTexture(objects)
            H.destroyAll(objects)
            if texture and texture ~= "" then
                return nil, texture, false
            end
        end

        local meshOk, meshPart = pcall(function()
            return Svc.insert:CreateMeshPartAsync("rbxassetid://" .. assetId, Enum.CollisionFidelity.Box, Enum.RenderFidelity.Automatic)
        end)
        if meshOk and typeof(meshPart) == "Instance" then
            return meshPart, nil, true
        end

        if kind == "model" then
            return nil, H.thumbUrl(assetId, "Asset"), false
        end
        return nil, "rbxassetid://" .. assetId, false
    end

    function H.resolveImage(config)
        local target = config.target

        if config.type == "thumbnail" then
            local id = H.assetId(target)
            if not id then return nil, nil end
            return H.thumbUrl(id, config.thumbType), id
        end

        if type(target) == "string" then
            local found = H.findByPath(target)
            if found then
                target = found
            end
        end

        if typeof(target) == "Instance" then
            if target:IsA("Decal") or target:IsA("Texture") then
                return target.Texture, nil
            end
            if target:IsA("ImageLabel") or target:IsA("ImageButton") then
                return target.Image, nil
            end
            return nil, nil
        end

        local text = H.textOf(target)
        if text:match("^rbxthumb://") or text:match("^rbxasset://") then
            return text, H.assetId(text)
        end

        local id = H.assetId(text)
        if not id then
            return H.normalizeImage(text), nil
        end

        local key = "img:" .. id
        local cached = S.images[key]
        if cached then
            return cached, id
        end

        local resolved = "rbxassetid://" .. id
        local objectsOk, objects = pcall(function()
            return game:GetObjects("rbxassetid://" .. id)
        end)
        if objectsOk and type(objects) == "table" and #objects > 0 then
            local texture = H.findTexture(objects)
            H.destroyAll(objects)
            if texture and texture ~= "" then
                resolved = texture
            end
        end

        S.images[key] = resolved
        return resolved, id
    end

    function H.showImage(image, token, assetId, tint)
        if not image or image == "" then return end
        if S.destroyed or S.holoToken ~= token then return end

        U.fallback.ImageColor3 = tint and Color3.new(1, 1, 1):Lerp(tint, 0.5) or Color3.new(1, 1, 1)
        U.fallback.ImageTransparency = LOW_END and K.IMAGE_ALPHA or 1
        U.fallback.Image = image
        U.fallback.Visible = true

        local started = os.clock()
        while not U.fallback.IsLoaded and os.clock() - started < K.PRELOAD do
            if S.destroyed or S.holoToken ~= token then return end
            task.wait(0.1)
        end
        if S.destroyed or S.holoToken ~= token then return end

        if not U.fallback.IsLoaded and assetId then
            local alternative = H.thumbUrl(assetId, "Asset")
            if alternative ~= image then
                U.fallback.Image = alternative
                started = os.clock()
                while not U.fallback.IsLoaded and os.clock() - started < K.IMAGE_ALT do
                    if S.destroyed or S.holoToken ~= token then return end
                    task.wait(0.1)
                end
                if S.destroyed or S.holoToken ~= token then return end
            end
        end

        if not LOW_END then
            H.tween(U.fallback, TI.FADE, { ImageTransparency = K.IMAGE_ALPHA })
        end
    end

    function H.signature(source)
        local parts = {}
        if not source:FindFirstChildOfClass("Humanoid") then
            parts[#parts + 1] = "V" .. tostring(S.version)
        end
        for _, child in ipairs(source:GetChildren()) do
            if child:IsA("Accessory") then
                parts[#parts + 1] = "A" .. child.Name
            elseif child:IsA("Shirt") then
                parts[#parts + 1] = "S" .. child.ShirtTemplate
            elseif child:IsA("Pants") then
                parts[#parts + 1] = "P" .. child.PantsTemplate
            elseif child:IsA("ShirtGraphic") then
                parts[#parts + 1] = "G" .. child.Graphic
            elseif child:IsA("BodyColors") then
                parts[#parts + 1] = "C" .. tostring(child.HeadColor3) .. tostring(child.TorsoColor3) .. tostring(child.LeftArmColor3) .. tostring(child.RightArmColor3) .. tostring(child.LeftLegColor3) .. tostring(child.RightLegColor3)
            elseif child:IsA("BasePart") and child.Name == "Head" then
                local face = child:FindFirstChildOfClass("Decal")
                parts[#parts + 1] = "H" .. (face and face.Texture or "")
            end
        end
        table.sort(parts)
        return table.concat(parts, "|")
    end

    function H.liveSource(config)
        local player = H.resolveTarget(config.target, config.type)
        if player then
            return player.Character
        end
        if config.live and typeof(config.target) == "Instance" then
            return config.target.Parent and config.target or nil
        end
        return nil
    end

    function H.poll()
        if S.busy ~= nil then return end
        local config = data.hologram
        if not config then return end
        local source = H.liveSource(config)
        if not source then return end
        local signature = H.signature(source)
        if signature == S.signature then return end

        local token = S.holoToken
        S.busy = token
        local ok, holder, size, isCharacter = pcall(H.buildHolder, source, config.tint, token, false)
        if S.busy == token then
            S.busy = nil
        end
        if not ok or not holder then return end
        if S.destroyed or S.holoToken ~= token then
            holder:Destroy()
            return
        end
        H.clearHologram()
        S.signature = signature
        H.mountHolder(holder, size, isCharacter, nil)
    end

    function H.clearWatch()
        for _, conn in ipairs(S.watch) do
            conn:Disconnect()
        end
        table.clear(S.watch)
    end

    function H.scheduleReload()
        if S.reloadPending or S.destroyed then return end
        S.reloadPending = true
        task.delay(0.6, function()
            S.reloadPending = false
            if not S.destroyed then
                pcall(H.poll)
            end
        end)
    end

    function H.bumpVersion()
        S.version = S.version + 1
    end

    function H.watchTarget(config)
        H.clearWatch()
        if not config or config.target == nil then return end
        local player = H.resolveTarget(config.target, config.type)
        if player then
            S.watch[#S.watch + 1] = player.CharacterAdded:Connect(H.scheduleReload)
            S.watch[#S.watch + 1] = player.CharacterAppearanceLoaded:Connect(H.scheduleReload)
            return
        end
        if config.live == true and typeof(config.target) == "Instance" then
            S.watch[#S.watch + 1] = config.target.DescendantAdded:Connect(H.bumpVersion)
            S.watch[#S.watch + 1] = config.target.DescendantRemoving:Connect(H.bumpVersion)
        end
    end

    function H.load()
        S.holoToken = S.holoToken + 1
        local token = S.holoToken
        local config = data.hologram

        H.watchTarget(config)
        H.clearHologram()

        if not config or config.target == nil then
            S.busy = nil
            return
        end

        if H.isImage(config.type) or config.type == "thumbnail" then
            S.busy = token
            task.spawn(function()
                local ok, image, assetId = pcall(H.resolveImage, config)
                if ok and image and not S.destroyed and S.holoToken == token then
                    H.showImage(image, token, assetId, config.tint)
                end
                if S.busy == token then
                    S.busy = nil
                end
            end)
            return
        end

        local knownImage = S.images[config.target]
        if knownImage then
            S.busy = nil
            U.fallback.ImageColor3 = config.tint and Color3.new(1, 1, 1):Lerp(config.tint, 0.5) or Color3.new(1, 1, 1)
            U.fallback.ImageTransparency = K.IMAGE_ALPHA
            U.fallback.Image = knownImage
            U.fallback.Visible = true
            return
        end

        local cached = H.cacheFind(config)
        if cached then
            S.busy = nil
            H.mountHolder(cached.holder, cached.size, cached.isCharacter, cached)
            return
        end

        S.busy = token

        task.spawn(function()
            local mounted = false
            local fallback = nil

            for attempt = 1, K.ATTEMPTS do
                if S.destroyed or S.holoToken ~= token then break end

                local resolvedOk, source, image, temporary = pcall(H.resolveSource, config.target, config.type)
                if not resolvedOk then
                    source, image, temporary = nil, nil, false
                end

                if S.destroyed or S.holoToken ~= token then
                    if temporary and source then
                        pcall(source.Destroy, source)
                    end
                    break
                end

                if source then
                    local signature = nil
                    if not temporary and H.liveSource(config) == source then
                        signature = H.signature(source)
                    end

                    local ok, holder, size, isCharacter = pcall(H.buildHolder, source, config.tint, token, temporary)

                    if not (ok and holder) and temporary then
                        pcall(source.Destroy, source)
                    end

                    if S.destroyed or S.holoToken ~= token then
                        if ok and holder then
                            holder:Destroy()
                        end
                        break
                    end

                    if ok and holder then
                        local cacheable = config.live ~= true and not isCharacter and signature == nil
                        local entry = nil
                        if cacheable then
                            entry = H.cacheStore(config, holder, size, isCharacter)
                        end
                        H.mountHolder(holder, size, isCharacter, entry)
                        S.signature = signature
                        mounted = true
                        break
                    end
                elseif image then
                    fallback = image
                    local key = config.target
                    if type(key) == "number" or type(key) == "string" then
                        S.images[key] = image
                    end
                    break
                end

                if attempt < K.ATTEMPTS then
                    task.wait(K.RETRY * attempt)
                end
            end

            if not mounted and not S.destroyed and S.holoToken == token then
                local assetId = H.assetId(config.target)
                if not fallback and assetId and not H.isChar(config.type) then
                    fallback = H.thumbUrl(assetId, "Asset")
                end
                if fallback then
                    H.showImage(fallback, token, assetId, config.tint)
                end
            end

            if S.busy == token then
                S.busy = nil
            end
        end)
    end

    function H.startLoop()
        S.loopToken = S.loopToken + 1
        local token = S.loopToken
        task.spawn(function()
            while not S.destroyed and S.loopToken == token do
                task.wait(K.UPDATE)
                if S.destroyed or S.loopToken ~= token then return end
                if data.hologram and H.visible() then
                    pcall(H.poll)
                end
            end
        end)
    end

    function H.ensureHologram()
        if not data.hologram then
            data.hologram = H.hologram({})
        end
        return data.hologram
    end

    function H.idle()
        return S.model == nil and not U.fallback.Visible and S.busy == nil
    end

    H.connect(U.viewport:GetPropertyChangedSignal("AbsoluteSize"), function()
        if S.model then
            H.fitCamera()
        end
    end)

    H.connect(U.nextButton.Activated, function()
        H.setPage("status", true)
    end)

    H.connect(U.backButton.Activated, function()
        H.setPage("hologram", true)
    end)

    H.setThumbnail(data.thumbnail)
    H.applyCorners()
    H.rebuildStatus()
    H.load()
    H.startLoop()
    H.applyDisabled()
    H.updateRow()
    H.updateScroll()

    function data:SetTitle(newTitle)
        if S.destroyed then return end
        newTitle = tostring(newTitle or "")
        if newTitle == data.title then return end
        data.title = newTitle
        U.title.Text = H.text(newTitle)
        U.title.Visible = newTitle ~= ""
        U.container.Name = (newTitle ~= "" and newTitle or "Paragraph") .. "_Paragraph"
        H.updateRow()
    end

    function data:SetDescription(newDesc)
        if S.destroyed then return end
        newDesc = tostring(newDesc or "")
        if newDesc == data.description then return end
        data.description = newDesc
        U.desc.Text = H.text(newDesc)
        U.desc.Visible = newDesc ~= ""
        H.updateRow()
    end

    function data:SetThumbnail(value)
        if S.destroyed then return end
        H.setThumbnail(value)
    end

    function data:SetDisabled(value)
        if S.destroyed then return end
        data.disabled = value == true
        H.applyDisabled()
    end

    function data:SetVisible(value)
        if S.destroyed then return end
        U.container.Visible = value ~= false
    end

    function data:SetCallback(fn)
        if S.destroyed or type(fn) ~= "function" then return end
        S.callback = fn
    end

    function data:SetSize(value)
        if S.destroyed then return end
        local number = tonumber(value)
        if not number then return end
        K.CARD_H = math.clamp(number, 100, 320)
        U.card.Size = UDim2.new(1, 0, 0, K.CARD_H)
        U.fallback.Size = UDim2.fromOffset(K.CARD_H - 44, K.CARD_H - 44)
        if S.model then
            H.fitCamera()
        end
    end

    function data:GetTitle()
        return data.title
    end

    function data:GetDescription()
        return data.description
    end

    function data:SetHologram(config)
        if S.destroyed then return end
        local previous = data.hologram
        local updated = H.hologram(config)
        data.hologram = updated
        H.applyCorners()
        local unchanged = previous ~= nil
            and updated ~= nil
            and previous.target == updated.target
            and previous.type == updated.type
            and previous.thumbType == updated.thumbType
            and previous.tint == updated.tint
            and previous.live == updated.live
            and previous.nonce == updated.nonce
            and not H.idle()
        if not unchanged then
            H.load()
        elseif updated and updated.rotate and S.model then
            H.startRotate()
        elseif updated and not updated.rotate then
            H.stopRotate()
        end
        H.syncPage()
    end

    function data:SetTarget(target, kind, thumbType)
        if S.destroyed then return end
        local config = H.ensureHologram()
        local previousTarget = config.target
        local previousKind = config.type
        local previousThumb = config.thumbType
        config.target = target
        if kind ~= nil then
            config.type = H.kind(kind)
        end
        if thumbType ~= nil then
            config.thumbType = H.thumbType(thumbType)
        end
        if previousTarget ~= target or previousKind ~= config.type or previousThumb ~= config.thumbType or H.idle() then
            H.load()
        end
        H.syncPage()
    end

    function data:SetBackground(value)
        if S.destroyed then return end
        U.grid.Visible = value ~= false
    end

    function data:SetCorners(corners)
        if S.destroyed then return end
        local config = H.ensureHologram()
        config.corners = H.copy(corners)
        H.applyCorners()
        H.syncPage()
    end

    function data:SetCorner(name, text)
        if S.destroyed then return end
        local config = H.ensureHologram()
        config.corners[name] = text
        H.applyCorners()
        H.syncPage()
    end

    function data:SetRotate(value)
        if S.destroyed then return end
        local config = H.ensureHologram()
        config.rotate = value ~= false
        if config.rotate then
            if S.model then
                H.startRotate()
            end
        else
            H.stopRotate()
        end
    end

    function data:SetSpeed(value)
        if S.destroyed then return end
        H.ensureHologram().speed = tonumber(value) or K.SPEED
    end

    function data:SetTint(color)
        if S.destroyed then return end
        local config = H.ensureHologram()
        local tint = typeof(color) == "Color3" and color or nil
        if config.tint == tint then return end
        config.tint = tint
        H.load()
        H.syncPage()
    end

    function data:Refresh()
        if S.destroyed or not data.hologram then return end
        H.clearHologram()
        H.cacheClear()
        S.images = {}
        H.load()
    end

    function data:IsLoading()
        return S.busy ~= nil
    end

    function data:HasHologramLoaded()
        return S.model ~= nil or U.fallback.Visible
    end

    function data:SetStatus(list)
        if S.destroyed then return end
        local newList = H.statusList(list)
        local same = #newList == #S.status
        if same then
            for index, stat in ipairs(newList) do
                if stat.name ~= S.status[index].name then
                    same = false
                    break
                end
            end
        end
        S.status = newList
        if same then
            for index = 1, #S.status do
                H.refreshStat(index)
            end
        else
            H.rebuildStatus()
        end
    end

    data.SetStats = data.SetStatus

    function data:GetStatus()
        local result = {}
        for index, stat in ipairs(S.status) do
            result[index] = { name = stat.name, value = stat.value, max = stat.max }
        end
        return result
    end

    function data:SetStatusTitle(newTitle)
        if S.destroyed then return end
        newTitle = tostring(newTitle or "")
        if newTitle == S.statusTitle then return end
        S.statusTitle = newTitle
        U.statusHeader.Text = newTitle
    end

    function data:SetStat(name, value, max)
        if S.destroyed then return end
        name = tostring(name)
        for index, stat in ipairs(S.status) do
            if stat.name == name then
                stat.value = value
                if max ~= nil then
                    stat.max = tonumber(max)
                end
                H.refreshStat(index)
                return
            end
        end
        S.status[#S.status + 1] = { name = name, value = value, max = tonumber(max) }
        local newIndex = #S.status
        S.rows[newIndex] = H.createStatRow(S.status[newIndex], newIndex)
        H.syncPage()
    end

    function data:GetStat(name)
        name = tostring(name)
        for _, stat in ipairs(S.status) do
            if stat.name == name then
                return stat.value
            end
        end
        return nil
    end

    function data:RemoveStat(name)
        if S.destroyed then return end
        name = tostring(name)
        for index, stat in ipairs(S.status) do
            if stat.name == name then
                table.remove(S.status, index)
                H.rebuildStatus()
                return
            end
        end
    end

    function data:Update(fields)
        if S.destroyed or type(fields) ~= "table" then return end
        if fields.title ~= nil then data:SetTitle(fields.title) end
        if fields.description ~= nil then data:SetDescription(fields.description) end
        if fields.thumbnail ~= nil then data:SetThumbnail(fields.thumbnail) end
        if fields.disabled ~= nil then data:SetDisabled(fields.disabled) end
        if fields.visible ~= nil then data:SetVisible(fields.visible) end
        if fields.size ~= nil then data:SetSize(fields.size) end
        if fields.statusTitle ~= nil then data:SetStatusTitle(fields.statusTitle) end
        if fields.status ~= nil then data:SetStatus(fields.status) end
        if fields.hologram ~= nil then data:SetHologram(fields.hologram) end
        if fields.page ~= nil then data:SetPage(fields.page) end
    end

    function data:Get()
        return {
            title = data.title,
            description = data.description,
            page = S.page,
            disabled = data.disabled,
            status = data:GetStatus(),
        }
    end

    function data:SetPage(page)
        if S.destroyed then return end
        H.setPage(page, true)
    end

    function data:GetPage()
        return S.page
    end

    function data:Destroy()
        if S.destroyed then return end
        S.destroyed = true
        S.busy = nil
        H.stopThumbLive()
        S.loopToken = S.loopToken + 1
        S.holoToken = S.holoToken + 1
        S.hideToken = S.hideToken + 1
        H.clearWatch()
        for _, conn in ipairs(S.connections) do
            conn:Disconnect()
        end
        table.clear(S.connections)
        H.clearHologram()
        H.cacheClear()
        U.container:Destroy()
    end

    S.connections[#S.connections + 1] = U.container.Destroying:Connect(function()
        if not S.destroyed then
            data:Destroy()
        end
    end)

    return data
end)