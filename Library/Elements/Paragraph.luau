-- // Paragraph
Elements.Register("Paragraph", function(section, options)
    options = type(options) == "table" and options or {}

    local accentOption = options.accent or options.Accent

    local C = {
        Accent = typeof(accentOption) == "Color3" and accentOption or Color3.fromRGB(230, 230, 236),
        Card = Color3.fromRGB(13, 13, 16),
        CardTop = Color3.fromRGB(22, 22, 28),
        CardStroke = Color3.fromRGB(40, 40, 48),
        Row = Color3.fromRGB(20, 20, 25),
        RowStroke = Color3.fromRGB(36, 36, 44),
        HoloBg = Color3.fromRGB(13, 13, 16),
        HoloBorder = Color3.fromRGB(52, 52, 62),
        TextActive = Color3.fromRGB(247, 247, 250),
        TextDisabled = Color3.fromRGB(82, 82, 91),
        DescText = Color3.fromRGB(156, 156, 170),
        DescDisabled = Color3.fromRGB(82, 82, 91),
        Muted = Color3.fromRGB(112, 112, 126),
        ThumbBg = Color3.fromRGB(22, 22, 27),
        CornerText = Color3.fromRGB(205, 205, 216),
        Bar = Color3.fromRGB(32, 32, 39),
        Black = Color3.fromRGB(0, 0, 0),
        White = Color3.fromRGB(255, 255, 255),
    }

    local Svc = {
        players = Players or game:GetService("Players"),
        input = UserInputService or game:GetService("UserInputService"),
        tween = TweenService or game:GetService("TweenService"),
        run = RunService or game:GetService("RunService"),
        content = game:GetService("ContentProvider"),
        insert = game:GetService("InsertService"),
    }

    local CACHE = {
        templates = {},
        images = {},
    }

    local fontBold = FONT_BOLD or Enum.Font.GothamBold
    local fontRegular = FONT or Enum.Font.Gotham
    local fontMedium = Enum.Font.GothamMedium

    local MOBILE = Svc.input.TouchEnabled and not Svc.input.KeyboardEnabled
    local sizeOption = tonumber(options.size or options.Size)

    local K = {
        TAG = MOBILE and 10 or 9,
        TITLE = MOBILE and 17 or 16,
        DESC = MOBILE and 12 or 11,
        STAT = MOBILE and 11 or 10,
        STAT_VALUE = MOBILE and 14 or 13,
        HEAD = MOBILE and 11 or 10,
        CORNER = MOBILE and 10 or 9,

        CARD_H = math.clamp(sizeOption or (MOBILE and 160 or 150), 90, 420),
        MIN_H = 36,
        PAD = 12,
        GAP = 8,
        THUMB = MOBILE and 44 or 42,
        THUMB_GAP = 10,
        ROW_H = MOBILE and 46 or 44,
        EDGE = 12,
        IMAGE_ALPHA = 0.05,

        FOV = 40,
        SPEED = 40,
        MARGIN = 1.12,
        PITCH_ITEM = 14,
        PITCH_CHAR = 4,
        DRAG = 0.45,
        TILT_MIN = -15,
        TILT_MAX = 30,
        RESUME = 2,

        PRELOAD = 1.2,
        UPDATE = 3,
        WORD_MAX = 30,
    }

    local TI = {
        FADE = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        BAR = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    }

    local S = {
        connections = {},
        watch = {},
        tweens = setmetatable({}, { __mode = "k" }),
        destroyed = false,
        liveToken = 0,
        holoToken = 0,
        loopToken = 0,
        busy = nil,
        model = nil,
        size = nil,
        pitch = K.PITCH_ITEM,
        tilt = 0,
        angle = 0,
        lastAngle = nil,
        distance = 0,
        light = Vector3.new(0.3, -0.5, 1),
        signature = nil,
        version = 0,
        reloadPending = false,
        status = {},
        rows = {},
        rich = options.richText ~= false,
        statusTitle = tostring(options.statusTitle or options.StatusTitle or "Status"),
        dragging = false,
        dragInput = nil,
        velocity = 0,
        lastDrag = -1e9,
    }

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

    function H.stroke(instance, color, thickness, transparency)
        return H.new("UIStroke", {
            Color = color,
            Thickness = thickness or 1,
            Transparency = transparency or 0,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        }, instance)
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
            type = config.type or config.Type,
            thumbType = config.thumbType or config.thumbnailType or config.thumb or "Asset",
            corners = H.copy(config.corners or config.info),
            rotate = config.rotate == true or config.Rotate == true,
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
        tag = tostring(options.tag or options.Tag or ""),
        thumbnail = options.thumbnail or options.Thumbnail,
        hologram = H.hologram(options.hologram or options.Hologram),
    }

    if data.thumbnail ~= nil and type(data.thumbnail) ~= "string" and type(data.thumbnail) ~= "number" and type(data.thumbnail) ~= "table" then
        data.thumbnail = nil
    end

    S.status = H.statusList(options.status or options.Status)

    U.container = H.new("Frame", {
        Name = (data.title ~= "" and data.title or "Paragraph") .. "_Paragraph",
        Size = UDim2.new(1, 0, 0, K.CARD_H),
        BackgroundColor3 = C.Card,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, section.frame)
    H.corner(U.container, 12)
    H.stroke(U.container, C.CardStroke, 1)
    H.new("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, C.CardTop),
            ColorSequenceKeypoint.new(0.4, C.Card),
            ColorSequenceKeypoint.new(1, C.Card),
        }),
    }, U.container)

    U.content = H.new("Frame", {
        Name = "Content",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
    }, U.container)
    U.contentLayout = H.new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 0),
    }, U.content)

    U.topInfo = H.new("Frame", {
        Name = "TopInfo",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        Visible = false,
    }, U.content)
    U.topInfoPad = H.new("UIPadding", {
        PaddingTop = UDim.new(0, K.PAD),
        PaddingBottom = UDim.new(0, K.PAD),
        PaddingLeft = UDim.new(0, K.PAD + 2),
        PaddingRight = UDim.new(0, K.PAD + 2),
    }, U.topInfo)

    U.header = H.new("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, U.topInfo)
    U.headerConstraint = H.new("UISizeConstraint", { MinSize = Vector2.new(0, 0) }, U.header)

    U.thumbFrame = H.new("Frame", {
        Name = "Thumbnail",
        Size = UDim2.fromOffset(K.THUMB, K.THUMB),
        BackgroundColor3 = C.ThumbBg,
        BorderSizePixel = 0,
        Visible = false,
    }, U.header)
    H.corner(U.thumbFrame, 10)
    H.stroke(U.thumbFrame, C.CardStroke, 1)

    U.thumbImage = H.new("ImageLabel", {
        Name = "Image",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = "",
        ScaleType = Enum.ScaleType.Crop,
        ZIndex = 2,
    }, U.thumbFrame)
    H.corner(U.thumbImage, 10)

    U.textFrame = H.new("Frame", {
        Name = "TextBlock",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    }, U.header)
    H.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3) }, U.textFrame)

    U.tagPill = H.new("Frame", {
        Name = "TagPill",
        Size = UDim2.new(0, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = C.Row,
        BorderSizePixel = 0,
        LayoutOrder = 1,
        Visible = data.tag ~= "",
    }, U.textFrame)
    H.corner(U.tagPill, 99)
    H.stroke(U.tagPill, C.RowStroke, 1)
    H.new("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 2),
    }, U.tagPill)

    U.tag = H.new("TextLabel", {
        Name = "Tag",
        Size = UDim2.new(0, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Text = H.text(data.tag),
        TextColor3 = C.DescText,
        TextSize = K.TAG,
        Font = fontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = false,
        RichText = S.rich,
    }, U.tagPill)

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
        LayoutOrder = 2,
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
        LineHeight = 1.18,
        RichText = S.rich,
        LayoutOrder = 3,
        Visible = data.description ~= "",
    }, U.textFrame)

    U.holoWrapper = H.new("Frame", {
        Name = "HologramWrapper",
        Size = UDim2.new(1, 0, 0, K.CARD_H),
        BackgroundTransparency = 1,
        LayoutOrder = 2,
        Visible = false,
    }, U.content)
    U.holoWrapperPad = H.new("UIPadding", {
        PaddingTop = UDim.new(0, 0),
        PaddingBottom = UDim.new(0, K.PAD),
        PaddingLeft = UDim.new(0, K.PAD + 2),
        PaddingRight = UDim.new(0, K.PAD + 2),
    }, U.holoWrapper)

    U.holo = H.new("Frame", {
        Name = "Hologram",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = C.Card,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, U.holoWrapper)
    H.corner(U.holo, 10)
    H.stroke(U.holo, C.HoloBorder, 1, 0.25)

    H.new("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, C.CardTop),
            ColorSequenceKeypoint.new(0.45, C.Card),
            ColorSequenceKeypoint.new(1, C.Card),
        }),
    }, U.holo)

    U.decor = H.new("Frame", {
        Name = "BorderDecor",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 4,
    }, U.holo)

    local innerFrame = H.new("Frame", {
        Name = "InnerBorder",
        Size = UDim2.new(1, -8, 1, -8),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        ZIndex = 4,
    }, U.decor)
    H.corner(innerFrame, 7)
    H.stroke(innerFrame, C.CardStroke, 1, 0.55)

    local function createBracket(name, anchor, pos, xDir, yDir)
        local holder = H.new("Frame", {
            Name = name,
            Size = UDim2.fromOffset(14, 14),
            AnchorPoint = anchor,
            Position = pos,
            BackgroundTransparency = 1,
            ZIndex = 5,
        }, U.decor)

        H.new("Frame", {
            Name = "H",
            Size = UDim2.new(1, 0, 0, 2),
            AnchorPoint = Vector2.new(xDir == 1 and 0 or 1, yDir == 1 and 0 or 1),
            Position = UDim2.new(xDir == 1 and 0 or 1, 0, yDir == 1 and 0 or 1, 0),
            BackgroundColor3 = C.Accent,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            ZIndex = 5,
        }, holder)

        H.new("Frame", {
            Name = "V",
            Size = UDim2.new(0, 2, 1, 0),
            AnchorPoint = Vector2.new(xDir == 1 and 0 or 1, yDir == 1 and 0 or 1),
            Position = UDim2.new(xDir == 1 and 0 or 1, 0, yDir == 1 and 0 or 1, 0),
            BackgroundColor3 = C.Accent,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            ZIndex = 5,
        }, holder)
    end

    createBracket("BracketTL", Vector2.new(0, 0), UDim2.new(0, 6, 0, 6), 1, 1)
    createBracket("BracketTR", Vector2.new(1, 0), UDim2.new(1, -6, 0, 6), -1, 1)
    createBracket("BracketBL", Vector2.new(0, 1), UDim2.new(0, 6, 1, -6), 1, -1)
    createBracket("BracketBR", Vector2.new(1, 1), UDim2.new(1, -6, 1, -6), -1, -1)

    H.new("Frame", {
        Name = "TopTick",
        Size = UDim2.new(0, 36, 0, 2),
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        BackgroundColor3 = C.Accent,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, U.decor)

    H.new("Frame", {
        Name = "BottomTick",
        Size = UDim2.new(0, 36, 0, 2),
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, 0),
        BackgroundColor3 = C.Accent,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, U.decor)

    U.viewport = H.new("ViewportFrame", {
        Name = "Viewport",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ImageTransparency = 0,
        Ambient = Color3.fromRGB(205, 205, 215),
        LightColor = Color3.fromRGB(255, 255, 255),
        LightDirection = S.light,
        ZIndex = 2,
    }, U.holo)

    U.camera = H.new("Camera", { FieldOfView = K.FOV }, U.viewport)
    U.viewport.CurrentCamera = U.camera

    U.fallback = H.new("ImageLabel", {
        Name = "Fallback",
        Size = UDim2.new(0.8, 0, 0.8, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = "",
        ImageTransparency = K.IMAGE_ALPHA,
        ScaleType = Enum.ScaleType.Fit,
        Visible = false,
        ZIndex = 2,
    }, U.holo)
    H.new("UIAspectRatioConstraint", {
        AspectRatio = 1,
        AspectType = Enum.AspectType.FitWithinMaxSize,
    }, U.fallback)

    function H.cornerLabel(name, position, anchor, alignX, alignY, font, color)
        return H.new("TextLabel", {
            Name = name,
            Size = UDim2.new(0.4, -(K.EDGE + 8), 0, 14),
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
            TextStrokeTransparency = 0.6,
            TextStrokeColor3 = C.Black,
            RichText = S.rich,
            Visible = false,
            ZIndex = 6,
        }, U.holo)
    end

    U.corners = {
        topLeft = H.cornerLabel("TopLeft", UDim2.new(0, K.EDGE + 2, 0, K.EDGE), Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Top, fontBold, C.TextActive),
        topRight = H.cornerLabel("TopRight", UDim2.new(1, -(K.EDGE + 2), 0, K.EDGE), Vector2.new(1, 0), Enum.TextXAlignment.Right, Enum.TextYAlignment.Top, fontBold, C.Accent),
        bottomLeft = H.cornerLabel("BottomLeft", UDim2.new(0, K.EDGE + 2, 1, -K.EDGE), Vector2.new(0, 1), Enum.TextXAlignment.Left, Enum.TextYAlignment.Bottom, fontMedium, C.CornerText),
        bottomRight = H.cornerLabel("BottomRight", UDim2.new(1, -(K.EDGE + 2), 1, -K.EDGE), Vector2.new(1, 1), Enum.TextXAlignment.Right, Enum.TextYAlignment.Bottom, fontMedium, C.DescText),
    }

    U.loading = H.new("TextLabel", {
        Name = "Loading",
        Size = UDim2.new(1, 0, 0, 14),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1,
        Text = "Loading...",
        TextColor3 = C.Muted,
        TextSize = K.CORNER + 1,
        Font = fontMedium,
        Visible = false,
        ZIndex = 4,
    }, U.holo)

    U.drag = H.new("TextButton", {
        Name = "Drag",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Selectable = false,
        ZIndex = 7,
    }, U.holo)

    U.bottomInfo = H.new("Frame", {
        Name = "BottomInfo",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 3,
        Visible = false,
    }, U.content)
    U.bottomInfoPad = H.new("UIPadding", {
        PaddingTop = UDim.new(0, 0),
        PaddingBottom = UDim.new(0, K.PAD),
        PaddingLeft = UDim.new(0, K.PAD + 2),
        PaddingRight = UDim.new(0, K.PAD + 2),
    }, U.bottomInfo)

    U.stats = H.new("Frame", {
        Name = "Stats",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, U.bottomInfo)
    H.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }, U.stats)

    U.statusHead = H.new("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        LayoutOrder = 0,
    }, U.stats)

    U.statusHeader = H.new("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -34, 1, 0),
        BackgroundTransparency = 1,
        Text = S.statusTitle,
        TextColor3 = C.TextActive,
        TextSize = K.HEAD,
        Font = fontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, U.statusHead)

    U.statusCount = H.new("TextLabel", {
        Name = "Count",
        Size = UDim2.new(0, 30, 1, 0),
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = C.Muted,
        TextSize = K.HEAD,
        Font = fontMedium,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, U.statusHead)

    U.statGrid = H.new("Frame", {
        Name = "Grid",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 1,
    }, U.stats)
    U.statGridLayout = H.new("UIGridLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        CellSize = UDim2.new(0.5, -3, 0, K.ROW_H),
        CellPadding = UDim2.new(0, 6, 0, 6),
        FillDirection = Enum.FillDirection.Horizontal,
    }, U.statGrid)

    U.veil = H.new("Frame", {
        Name = "Veil",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = C.Black,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Active = true,
        Visible = false,
        ZIndex = 20,
    }, U.container)
    H.corner(U.veil, 12)

    function H.hasHologram()
        return data.hologram ~= nil
    end

    function H.hasStatus()
        return #S.status > 0
    end

    function H.hasHeader()
        return U.title.Visible or U.desc.Visible or U.tagPill.Visible or U.thumbFrame.Visible
    end

    function H.resize()
        if S.destroyed then return end
        local height = math.max(U.contentLayout.AbsoluteContentSize.Y, K.MIN_H)
        if U.container.Size.Y.Offset ~= height then
            U.container.Size = UDim2.new(1, 0, 0, height)
        end
    end

    function H.updateGrid()
        local single = #S.status == 1
        U.statGridLayout.CellSize = UDim2.new(single and 1 or 0.5, single and 0 or -3, 0, K.ROW_H)
    end

    function H.layout()
        local hasHolo = H.hasHologram()
        local hasHeader = H.hasHeader()
        local hasStatus = H.hasStatus()

        U.topInfo.Visible = hasHeader
        U.holoWrapper.Visible = hasHolo
        U.bottomInfo.Visible = hasStatus

        U.topInfoPad.PaddingBottom = UDim.new(0, (hasHolo or hasStatus) and 10 or K.PAD)
        U.holoWrapperPad.PaddingTop = UDim.new(0, hasHeader and 0 or K.PAD)
        U.holoWrapperPad.PaddingBottom = UDim.new(0, hasStatus and 10 or K.PAD)
        U.bottomInfoPad.PaddingTop = UDim.new(0, (hasHeader or hasHolo) and 0 or K.PAD)

        local extraPad = (hasHeader and 0 or K.PAD) + (hasStatus and 10 or K.PAD)
        U.holoWrapper.Size = UDim2.new(1, 0, 0, K.CARD_H + extraPad)

        H.resize()
    end

    H.connect(U.contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"), H.resize)

    function H.applyDisabled()
        U.title.TextColor3 = data.disabled and C.TextDisabled or C.TextActive
        U.desc.TextColor3 = data.disabled and C.DescDisabled or C.DescText
        U.thumbImage.ImageTransparency = data.disabled and 0.5 or 0
        U.veil.Visible = data.disabled
    end

    function H.setBusy(value)
        S.busy = value
        H.refreshLoading()
    end

    function H.refreshLoading()
        U.loading.Visible = S.busy ~= nil and S.model == nil and not U.fallback.Visible
    end

    function H.layoutThumb(hasThumb)
        U.headerConstraint.MinSize = Vector2.new(0, hasThumb and K.THUMB or 0)
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
            local id = H.assetId(value.asset or value.Asset or value.id or value.Id)
            if not id then return nil end
            return string.format("rbxthumb://type=Asset&id=%s&w=420&h=420", tostring(id))
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
            H.layout()
            return
        end

        H.layoutThumb(true)

        if type(resolved) == "number" then
            U.thumbImage.Image = ""
            H.startThumbLive(resolved)
        else
            U.thumbImage.Image = H.normalizeImage(resolved)
        end

        H.layout()
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

    function H.ratio(stat)
        local value = tonumber(stat.value)
        local max = stat.max
        if value and max and max > 0 then
            return math.clamp(value / max, 0, 1)
        end
        return nil
    end

    function H.percent(ratio)
        return string.format("%d%%", math.floor(ratio * 100 + 0.5))
    end

    function H.createStatRow(stat, index)
        local ratio = H.ratio(stat)

        local frame = H.new("Frame", {
            Name = "Stat_" .. index,
            BackgroundColor3 = C.Row,
            BorderSizePixel = 0,
            LayoutOrder = index,
        }, U.statGrid)
        H.corner(frame, 8)
        H.stroke(frame, C.RowStroke, 1)

        local nameLabel = H.new("TextLabel", {
            Name = "Name",
            Size = UDim2.new(1, -20, 0, 12),
            Position = UDim2.new(0, 10, 0, ratio and 6 or 8),
            BackgroundTransparency = 1,
            Text = stat.name,
            TextColor3 = C.Muted,
            TextSize = K.STAT,
            Font = fontMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            RichText = S.rich,
        }, frame)

        local valueLabel = H.new("TextLabel", {
            Name = "Value",
            Size = UDim2.new(ratio and 0.64 or 1, ratio and -10 or -20, 0, 18),
            Position = UDim2.new(0, 10, 0, ratio and 18 or 21),
            BackgroundTransparency = 1,
            Text = H.formatStat(stat),
            TextColor3 = C.TextActive,
            TextSize = K.STAT_VALUE,
            Font = fontBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            RichText = S.rich,
        }, frame)

        local percentLabel
        local fill
        if ratio then
            percentLabel = H.new("TextLabel", {
                Name = "Percent",
                Size = UDim2.new(0.36, -10, 0, 18),
                Position = UDim2.new(0.64, 0, 0, 18),
                BackgroundTransparency = 1,
                Text = H.percent(ratio),
                TextColor3 = C.DescText,
                TextSize = K.STAT,
                Font = fontBold,
                TextXAlignment = Enum.TextXAlignment.Right,
            }, frame)

            local track = H.new("Frame", {
                Name = "Track",
                Size = UDim2.new(1, -20, 0, 3),
                Position = UDim2.new(0, 10, 1, -9),
                BackgroundColor3 = C.Bar,
                BorderSizePixel = 0,
            }, frame)
            H.corner(track, 99)
            fill = H.new("Frame", {
                Name = "Fill",
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = C.Accent,
                BorderSizePixel = 0,
            }, track)
            H.corner(fill, 99)
            H.tween(fill, TI.BAR, { Size = UDim2.new(ratio, 0, 1, 0) })
        end

        return {
            frame = frame,
            nameLabel = nameLabel,
            valueLabel = valueLabel,
            percentLabel = percentLabel,
            fill = fill,
            hasBar = ratio ~= nil,
        }
    end

    function H.refreshStat(index)
        local stat = S.status[index]
        local row = S.rows[index]
        if not stat or not row then return end

        local ratio = H.ratio(stat)
        if (ratio ~= nil) ~= row.hasBar then
            row.frame:Destroy()
            S.rows[index] = H.createStatRow(stat, index)
            return
        end

        local text = H.formatStat(stat)
        if row.nameLabel.Text ~= stat.name then
            row.nameLabel.Text = stat.name
        end
        if row.valueLabel.Text ~= text then
            row.valueLabel.Text = text
        end
        if row.fill and ratio then
            row.percentLabel.Text = H.percent(ratio)
            H.tween(row.fill, TI.BAR, { Size = UDim2.new(ratio, 0, 1, 0) })
        end
    end

    function H.updateCount()
        U.statusCount.Text = #S.status > 0 and tostring(#S.status) or ""
    end

    function H.rebuildStatus()
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
        H.updateCount()
        H.updateGrid()
        H.layout()
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
        local pitch = math.rad(S.pitch + S.tilt)
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
        local aspect = view.Y > 0 and view.X / view.Y or 1
        local radius = math.sqrt(size.X * size.X + size.Z * size.Z) * 0.5
        local extentY = size.Y * math.cos(pitch) + 2 * radius * math.sin(pitch)
        local fitY = extentY * 0.5 / tanHalf
        local fitX = radius / (tanHalf * aspect)
        S.distance = math.max((math.max(fitY, fitX) + radius) * K.MARGIN, 0.5)
        H.applyOrbit()
    end

    function H.clearHologram()
        local old = S.model
        S.model = nil
        S.size = nil
        S.signature = nil
        S.velocity = 0
        S.tilt = 0
        if old then
            old.Parent = nil
            task.defer(old.Destroy, old)
        end
        U.fallback.Image = ""
        U.fallback.ImageColor3 = Color3.new(1, 1, 1)
        U.fallback.Visible = false
        H.refreshLoading()
    end

    function H.mountHolder(holder, size, isCharacter)
        S.pitch = isCharacter and K.PITCH_CHAR or K.PITCH_ITEM
        S.size = size
        S.tilt = 0
        H.stopTween(U.viewport)
        U.viewport.ImageTransparency = 1
        holder.Parent = U.viewport
        S.model = holder
        S.lastAngle = nil
        H.fitCamera()
        U.fallback.Visible = false
        H.tween(U.viewport, TI.FADE, { ImageTransparency = 0 })
        H.refreshLoading()
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

    function H.collectParts(model)
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
        for _, descendant in ipairs(model:GetDescendants()) do
            if descendant:IsA("BasePart") then
                parts[#parts + 1] = descendant
            elseif descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") or descendant:IsA("Sound") or descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or descendant:IsA("Beam") or descendant:IsA("Highlight") or descendant:IsA("Light") or descendant:IsA("PostEffect") then
                descendant:Destroy()
            end
        end

        return parts, isCharacter
    end

    function H.tuneParts(parts, tint)
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
                    pcall(function()
                        part.RenderFidelity = Enum.RenderFidelity.Precise
                    end)
                end
            end
        end
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

    function H.cloneSource(source)
        local ok, clone = pcall(function()
            return source:Clone()
        end)
        if ok then return clone end
        return nil
    end

    function H.prepareHolder(source, temporary, token)
        local clone = temporary and source or H.cloneSource(source)
        if not clone then return nil end

        local holder = clone
        if not clone:IsA("Model") then
            holder = Instance.new("Model")
            clone.Parent = holder
        end

        local parts, isCharacter = H.collectParts(holder)
        if #parts == 0 then
            holder:Destroy()
            return nil
        end

        H.tuneParts(parts, nil)

        if isCharacter then
            H.resetPose(holder)
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

    function H.clonePrepared(entry, tint)
        local clone = entry.template:Clone()
        if tint then
            for _, descendant in ipairs(clone:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    descendant.Color = descendant.Color:Lerp(tint, 0.4)
                end
            end
        end
        return clone, entry.size, entry.isCharacter
    end

    function H.buildHolder(source, tint, token, temporary, cacheKey)
        if cacheKey and CACHE.templates[cacheKey] then
            return H.clonePrepared(CACHE.templates[cacheKey], tint)
        end

        local holder, boxSize, isCharacter = H.prepareHolder(source, temporary, token)
        if not holder then return nil end

        if cacheKey then
            local template = holder:Clone()
            CACHE.templates[cacheKey] = {
                template = template,
                size = boxSize,
                isCharacter = isCharacter,
            }
        end

        if tint then
            for _, descendant in ipairs(holder:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    descendant.Color = descendant.Color:Lerp(tint, 0.4)
                end
            end
        end

        return holder, boxSize, isCharacter
    end

    function H.resolveTarget(target)
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

        if type(target) == "number" then
            local found = Svc.players:GetPlayerByUserId(target)
            if found then return found, target end
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
                if found then return found, number end
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

    function H.cacheKeyFor(target)
        if typeof(target) == "Instance" then
            return target
        end
        local assetId = H.assetId(target)
        if assetId then
            return "asset:" .. assetId
        end
        if type(target) == "string" or type(target) == "number" then
            return "target:" .. tostring(target)
        end
        return nil
    end

    function H.detectAutomaticSource(target)
        if type(target) == "string" then
            local found = H.findByPath(target)
            if found then target = found end
        end

        local player, userId = H.resolveTarget(target)

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

        local assetId = H.assetId(target)
        if not assetId then
            if typeof(target) == "Instance" then
                return target, nil, false
            end
            return nil, H.normalizeImage(target), false
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
            return Svc.insert:CreateMeshPartAsync("rbxassetid://" .. assetId, Enum.CollisionFidelity.Box, Enum.RenderFidelity.Precise)
        end)
        if meshOk and typeof(meshPart) == "Instance" then
            return meshPart, nil, true
        end

        return nil, H.thumbUrl(assetId, "Asset"), false
    end

    function H.resolveImage(config)
        local target = config.target
        if config.type == "thumbnail" then
            local id = H.assetId(target)
            if not id then return nil, nil end
            return H.thumbUrl(id, config.thumbType), id
        end
        return H.normalizeImage(target), H.assetId(target)
    end

    function H.showImage(image, token, assetId, tint)
        if not image or image == "" then return end
        if S.destroyed or S.holoToken ~= token then return end

        U.fallback.ImageColor3 = tint and Color3.new(1, 1, 1):Lerp(tint, 0.5) or Color3.new(1, 1, 1)
        U.fallback.ImageTransparency = 1
        U.fallback.Image = image
        U.fallback.Visible = true
        H.refreshLoading()

        H.tween(U.fallback, TI.FADE, { ImageTransparency = K.IMAGE_ALPHA })
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
            elseif child:IsA("BodyColors") then
                parts[#parts + 1] = "C" .. tostring(child.HeadColor3)
            end
        end
        table.sort(parts)
        return table.concat(parts, "|")
    end

    function H.liveSource(config)
        local player = H.resolveTarget(config.target)
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
        H.setBusy(token)
        local ok, holder, size, isCharacter = pcall(H.buildHolder, source, config.tint, token, false, nil)
        if S.busy == token then
            H.setBusy(nil)
        end
        if not ok or not holder then return end
        if S.destroyed or S.holoToken ~= token then
            holder:Destroy()
            return
        end
        H.clearHologram()
        S.signature = signature
        H.mountHolder(holder, size, isCharacter)
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
        task.delay(0.3, function()
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
        local player = H.resolveTarget(config.target)
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
            H.setBusy(nil)
            return
        end

        local cacheKey = not config.live and H.cacheKeyFor(config.target) or nil
        if cacheKey and CACHE.templates[cacheKey] then
            local holder, size, isCharacter = H.clonePrepared(CACHE.templates[cacheKey], config.tint)
            H.setBusy(nil)
            H.mountHolder(holder, size, isCharacter)
            return
        end

        H.setBusy(token)

        task.spawn(function()
            local resolvedOk, source, image, temporary = pcall(H.detectAutomaticSource, config.target)
            if not resolvedOk then
                source, image, temporary = nil, nil, false
            end

            if S.destroyed or S.holoToken ~= token then
                if temporary and source then pcall(source.Destroy, source) end
                return
            end

            if source then
                local signature = nil
                if not temporary and H.liveSource(config) == source then
                    signature = H.signature(source)
                end

                local ok, holder, size, isCharacter = pcall(H.buildHolder, source, config.tint, token, temporary, cacheKey)
                if not (ok and holder) and temporary then
                    pcall(source.Destroy, source)
                end

                if S.destroyed or S.holoToken ~= token then
                    if ok and holder then holder:Destroy() end
                    return
                end

                if ok and holder then
                    H.mountHolder(holder, size, isCharacter)
                    S.signature = signature
                end
            elseif image then
                H.showImage(image, token, H.assetId(config.target), config.tint)
            end

            if S.busy == token then
                H.setBusy(nil)
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
                if data.hologram then
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

    H.connect(U.drag.InputBegan, function(input)
        local kind = input.UserInputType
        if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
            S.dragging = true
            S.dragInput = input
            S.velocity = 0
        end
    end)

    H.connect(Svc.input.InputChanged, function(input)
        if not S.dragging or not S.model then return end
        local kind = input.UserInputType
        if kind == Enum.UserInputType.MouseMovement or (kind == Enum.UserInputType.Touch and input == S.dragInput) then
            local delta = input.Delta
            S.angle = (S.angle + delta.X * K.DRAG) % 360
            S.tilt = math.clamp(S.tilt + delta.Y * 0.3, K.TILT_MIN, K.TILT_MAX)
            S.velocity = math.clamp(S.velocity * 0.6 + (delta.X * K.DRAG * 60) * 0.4, -720, 720)
        end
    end)

    H.connect(Svc.input.InputEnded, function(input)
        if not S.dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input == S.dragInput then
            S.dragging = false
            S.dragInput = nil
            S.lastDrag = os.clock()
        end
    end)

    H.connect(Svc.run.RenderStepped, function(dt)
        if S.destroyed then return end
        if not S.model then return end

        if S.dragging then
            S.velocity = S.velocity * (1 - math.min(dt * 10, 1))
        else
            S.velocity = S.velocity * (1 - math.min(dt * 3, 1))
            S.tilt = S.tilt * (1 - math.min(dt * 3, 1))
            local step = S.velocity
            local config = data.hologram
            if config and config.rotate and os.clock() - S.lastDrag >= K.RESUME then
                step = step + config.speed
            end
            S.angle = (S.angle + step * dt) % 360
        end

        H.applyOrbit()
    end)

    H.connect(U.viewport:GetPropertyChangedSignal("AbsoluteSize"), function()
        if S.model then
            H.fitCamera()
        end
    end)

    H.setThumbnail(data.thumbnail)
    H.applyCorners()
    H.rebuildStatus()
    H.load()
    H.startLoop()
    H.applyDisabled()
    H.layout()

    function data:SetTitle(newTitle)
        if S.destroyed then return end
        newTitle = tostring(newTitle or "")
        if newTitle == data.title then return end
        data.title = newTitle
        U.title.Text = H.text(newTitle)
        U.title.Visible = newTitle ~= ""
        U.container.Name = (newTitle ~= "" and newTitle or "Paragraph") .. "_Paragraph"
        H.layout()
    end

    function data:SetDescription(newDesc)
        if S.destroyed then return end
        newDesc = tostring(newDesc or "")
        if newDesc == data.description then return end
        data.description = newDesc
        U.desc.Text = H.text(newDesc)
        U.desc.Visible = newDesc ~= ""
        H.layout()
    end

    function data:SetTag(newTag)
        if S.destroyed then return end
        newTag = tostring(newTag or "")
        if newTag == data.tag then return end
        data.tag = newTag
        U.tag.Text = H.text(newTag)
        U.tagPill.Visible = newTag ~= ""
        H.layout()
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

    function data:SetSize(value)
        if S.destroyed then return end
        local number = tonumber(value)
        if not number then return end
        K.CARD_H = math.clamp(number, 90, 420)
        H.layout()
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
            and previous.live == updated.live
            and previous.nonce == updated.nonce
            and not H.idle()
        if not unchanged then
            H.load()
        end
        H.layout()
    end

    function data:SetTarget(target, kind)
        if S.destroyed then return end
        local config = H.ensureHologram()
        local previousTarget = config.target
        config.target = target
        if kind ~= nil then config.type = kind end
        if previousTarget ~= target or H.idle() then
            H.load()
        end
        H.layout()
    end

    function data:PreloadHolograms(targets)
        if S.destroyed or type(targets) ~= "table" then return end
        task.spawn(function()
            for _, target in ipairs(targets) do
                if S.destroyed then return end
                local key = H.cacheKeyFor(target)
                if key and not CACHE.templates[key] then
                    local ok, source, _, temporary = pcall(H.detectAutomaticSource, target)
                    if ok and source then
                        local built, holder, boxSize, isCharacter = pcall(H.prepareHolder, source, temporary, S.holoToken)
                        if built and holder then
                            CACHE.templates[key] = {
                                template = holder,
                                size = boxSize,
                                isCharacter = isCharacter,
                            }
                        elseif temporary then
                            pcall(source.Destroy, source)
                        end
                    end
                end
                task.wait()
            end
        end)
    end

    function data:ClearHologramCache()
        for _, entry in pairs(CACHE.templates) do
            if entry.template then
                pcall(entry.template.Destroy, entry.template)
            end
        end
        table.clear(CACHE.templates)
        table.clear(CACHE.images)
    end

    function data:SetCorners(corners)
        if S.destroyed then return end
        local config = H.ensureHologram()
        config.corners = H.copy(corners)
        H.applyCorners()
        H.layout()
    end

    function data:SetCorner(name, text)
        if S.destroyed then return end
        local config = H.ensureHologram()
        config.corners[name] = text
        H.applyCorners()
        H.layout()
    end

    function data:SetRotate(value)
        if S.destroyed then return end
        H.ensureHologram().rotate = value == true
    end

    function data:SetTint(color)
        if S.destroyed then return end
        local config = H.ensureHologram()
        local tint = typeof(color) == "Color3" and color or nil
        if config.tint == tint then return end
        config.tint = tint
        H.load()
        H.layout()
    end

    function data:Refresh()
        if S.destroyed or not data.hologram then return end
        local key = H.cacheKeyFor(data.hologram.target)
        if key and CACHE.templates[key] then
            pcall(CACHE.templates[key].template.Destroy, CACHE.templates[key].template)
            CACHE.templates[key] = nil
        end
        H.clearHologram()
        table.clear(CACHE.images)
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
        S.status[#S.status + 1] = { name = name, value = value, max = tonumber(max)` }
        local newIndex = #S.status
        S.rows[newIndex] = H.createStatRow(S.status[newIndex], newIndex)
        H.updateCount()
        H.updateGrid()
        H.layout()
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
        if fields.tag ~= nil then data:SetTag(fields.tag) end
        if fields.thumbnail ~= nil then data:SetThumbnail(fields.thumbnail) end
        if fields.disabled ~= nil then data:SetDisabled(fields.disabled) end
        if fields.visible ~= nil then data:SetVisible(fields.visible) end
        if fields.size ~= nil then data:SetSize(fields.size) end
        if fields.statusTitle ~= nil then data:SetStatusTitle(fields.statusTitle) end
        if fields.status ~= nil then data:SetStatus(fields.status) end
        if fields.hologram ~= nil then data:SetHologram(fields.hologram) end
    end

    function data:Destroy()
        if S.destroyed then return end
        S.destroyed = true
        S.busy = nil
        H.stopThumbLive()
        S.loopToken = S.loopToken + 1
        S.holoToken = S.holoToken + 1
        H.clearWatch()
        for _, conn in ipairs(S.connections) do
            conn:Disconnect()
        end
        table.clear(S.connections)
        H.clearHologram()
        U.container:Destroy()
    end

    S.connections[#S.connections + 1] = U.container.Destroying:Connect(function()
        if not S.destroyed then
            data:Destroy()
        end
    end)

    return data
end)