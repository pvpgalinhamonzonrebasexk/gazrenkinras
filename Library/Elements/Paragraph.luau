-- // Services
local runService = game:GetService("RunService")

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

local DERIVED = {
    Hover = function(colors)
        return colors.Palette:Lerp(colors.Accent, 0.6)
    end,
    Pressed = function(colors)
        return colors.Accent:Lerp(colors.BorderHover, 0.35)
    end,
    TextHover = function(colors)
        return colors.Inactive:Lerp(colors.Active, 0.25)
    end,
}

-- // ThemeWatcher
local themeGroups = {}
local themeConnection
local NO_PANEL = {}

local function resolveColor(panel, key)
    local theme = type(panel) == "table" and panel.Theme or nil
    local live = type(theme) == "table" and theme[key] or nil

    if typeof(live) == "Color3" then
        return live
    end

    return Default[key]
end

local function checkGroup(group)
    local changed = false

    for _, key in ipairs(THEME_KEYS) do
        local current = resolveColor(group.panel, key)

        if group.last[key] ~= current then
            group.last[key] = current
            changed = true
        end
    end

    if not changed then
        return
    end

    for apply in pairs(group.callbacks) do
        pcall(apply)
    end
end

local function startThemeWatcher()
    if themeConnection then
        return
    end

    themeConnection = runService.Heartbeat:Connect(function()
        for _, group in pairs(themeGroups) do
            checkGroup(group)
        end
    end)
end

local function stopThemeWatcher()
    if themeConnection and next(themeGroups) == nil then
        themeConnection:Disconnect()
        themeConnection = nil
    end
end

local function watchGroup(panel, apply)
    local id = panel or NO_PANEL
    local group = themeGroups[id]

    if not group then
        group = { panel = panel, last = {}, callbacks = {} }

        for _, key in ipairs(THEME_KEYS) do
            group.last[key] = resolveColor(panel, key)
        end

        if type(panel) == "table" then
            pcall(function()
                local signal = panel.ThemeChanged

                if typeof(signal) == "RBXScriptSignal" then
                    group.signal = signal:Connect(function()
                        checkGroup(group)
                    end)
                end
            end)
        end

        themeGroups[id] = group
    end

    group.callbacks[apply] = true
    startThemeWatcher()

    return function()
        group.callbacks[apply] = nil

        if next(group.callbacks) == nil then
            if group.signal then
                group.signal:Disconnect()
                group.signal = nil
            end

            themeGroups[id] = nil
            stopThemeWatcher()
        end
    end
end

local function createColors(panel)
    local colors

    colors = setmetatable({}, {
        __index = function(_, key)
            if Default[key] then
                return resolveColor(panel, key)
            end

            local theme = type(panel) == "table" and panel.Theme or nil
            local live = type(theme) == "table" and theme[key] or nil

            if typeof(live) == "Color3" then
                return live
            end

            local derive = DERIVED[key]

            if derive then
                return derive(colors)
            end

            return nil
        end
    })

    local function watch(apply)
        return watchGroup(panel, apply)
    end

    return colors, watch
end

-- // Palette

local PALETTE_DARK = {
    red = Color3.fromRGB(255, 82, 82),
    yellow = Color3.fromRGB(255, 210, 64),
    green = Color3.fromRGB(88, 222, 130),
    blue = Color3.fromRGB(96, 165, 255),
    orange = Color3.fromRGB(255, 152, 60),
    purple = Color3.fromRGB(186, 130, 255),
    pink = Color3.fromRGB(255, 122, 190),
    cyan = Color3.fromRGB(64, 220, 235),
    white = Color3.fromRGB(247, 247, 250),
    gray = Color3.fromRGB(156, 156, 170),
}

local PALETTE_LIGHT = {
    red = Color3.fromRGB(214, 40, 40),
    yellow = Color3.fromRGB(184, 134, 0),
    green = Color3.fromRGB(22, 140, 70),
    blue = Color3.fromRGB(30, 100, 220),
    orange = Color3.fromRGB(214, 100, 10),
    purple = Color3.fromRGB(130, 60, 210),
    pink = Color3.fromRGB(200, 50, 130),
    cyan = Color3.fromRGB(0, 140, 160),
    white = Color3.fromRGB(60, 60, 70),
    gray = Color3.fromRGB(110, 110, 125),
}

local COLOR_ALIAS = {
    vermelho = "red", amarelo = "yellow", verde = "green", azul = "blue",
    laranja = "orange", roxo = "purple", rosa = "pink", ciano = "cyan",
    branco = "white", cinza = "gray", grey = "gray", magenta = "pink",
    gold = "yellow", dourado = "yellow",
}

local THEME_ROLE = {
    accent = "Accent", text = "Text", muted = "Muted",
    desc = "Desc", title = "Title", line = "Line",
}

local function pick(source, ...)
    for index = 1, select("#", ...) do
        local value = source[select(index, ...)]
        if value ~= nil then
            return value
        end
    end
    return nil
end

local function copyTable(source)
    local result = {}
    if type(source) == "table" then
        for key, value in pairs(source) do
            result[key] = value
        end
    end
    return result
end

Elements.Register("Paragraph", function(section, options)
    options = type(options) == "table" and options or {}

    local function opt(...)
        return pick(options, ...)
    end

    local Colors, watchTheme = createColors(section.Panel or Panel)
    local unwatchTheme

    local Svc = {
        input = UserInputService or game:GetService("UserInputService"),
        tween = TweenService or game:GetService("TweenService"),
    }

    local fontBold = FONT_BOLD or Enum.Font.GothamBold
    local fontRegular = FONT or Enum.Font.Gotham
    local fontMedium = Enum.Font.GothamMedium

    local MOBILE = Svc.input.TouchEnabled and not Svc.input.KeyboardEnabled

    local K = {
        TAG = MOBILE and 11 or 10,
        TITLE = MOBILE and 18 or 17,
        DESC = MOBILE and 13 or 12,
        INFO = MOBILE and 14 or 13,
        LABEL = MOBILE and 12 or 11,
        HEAD = MOBILE and 12 or 11,
        BADGE = MOBILE and 12 or 11,
        ICON = MOBILE and 24 or 22,
        TILE = MOBILE and 60 or 54,
        PREVIEW_H = MOBILE and 150 or 140,
        BAR_H = 5,
        DIVIDER_H = 11,
        GAP = 6,
        ROW_GAP = MOBILE and 6 or 5,
        PAD = 2,
        MIN_H = 4,
        LOAD_WAIT = 4,
    }

    local TI = {
        FADE = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        BAR = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    }

    local S = {
        connections = {},
        tweens = setmetatable({}, { __mode = "k" }),
        destroyed = false,
        theme = nil,
        accent = opt("accent", "Accent"),
        titleColor = opt("titleColor", "TitleColor"),
        descColor = opt("descriptionColor", "DescriptionColor", "descColor"),
        colors = {},
        defaultColor = opt("defaultColor", "DefaultColor", "color", "Color"),
        items = {},
        rows = {},
        textures = {},
        rich = options.richText ~= false,
        marker = "none",
        rule = options.rule == true,
    }

    local markerOption = opt("marker", "Marker")
    if type(markerOption) == "string" then
        local mode = markerOption:lower()
        if mode == "bar" or mode == "dot" or mode == "none" then
            S.marker = mode
        end
    end
    if options.bullets == false then
        S.marker = "none"
    end

    local colorsOption = opt("colors", "Colors")
    if type(colorsOption) == "table" then
        for key, value in pairs(colorsOption) do
            if type(key) == "number" then
                S.colors[key] = value
            end
        end
    end

    local H = {}
    local U = {}

    -- // Helpers

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

    function H.display(value)
        if type(value) == "number" then
            return H.number(value)
        end
        return tostring(value)
    end

    function H.color(value)
        local kind = typeof(value)
        if kind == "Color3" then
            return value
        end
        if kind == "BrickColor" then
            return value.Color
        end
        if kind == "string" then
            local key = (value:lower():gsub("[%s_%-]", ""))
            key = COLOR_ALIAS[key] or key
            local theme = S.theme
            local palette = (theme and theme.Light) and PALETTE_LIGHT or PALETTE_DARK
            if palette[key] then
                return palette[key]
            end
            if theme and THEME_ROLE[key] then
                return theme[THEME_ROLE[key]]
            end
            local hex = key:match("^#?(%x%x%x%x%x%x)$")
            local short = key:match("^#(%x%x%x)$")
            if short then
                hex = short:gsub("%x", "%0%0")
            end
            if hex then
                return Color3.fromRGB(
                    tonumber(hex:sub(1, 2), 16),
                    tonumber(hex:sub(3, 4), 16),
                    tonumber(hex:sub(5, 6), 16)
                )
            end
        elseif kind == "table" then
            local r = value.r or value.R or value[1]
            local g = value.g or value.G or value[2]
            local b = value.b or value.B or value[3]
            if type(r) == "number" and type(g) == "number" and type(b) == "number" then
                if r <= 1 and g <= 1 and b <= 1 then
                    return Color3.new(r, g, b)
                end
                return Color3.fromRGB(math.clamp(r, 0, 255), math.clamp(g, 0, 255), math.clamp(b, 0, 255))
            end
        end
        return nil
    end

    -- // Temas

    function H.buildTheme()
        local background = Colors.Background
        local luminance = (0.299 * background.R) + (0.587 * background.G) + (0.114 * background.B)
        local theme = {
            Title = Colors.Active,
            Text = Colors.Active,
            Desc = Colors.Inactive,
            Muted = Colors.Dim,
            Line = Colors.Border,
            Track = Colors.Accent,
            Accent = Colors.Active,
            Light = luminance > 0.6,
        }
        S.theme = theme

        local accent = H.color(S.accent)
        if accent then
            theme.Accent = accent
        end
        return theme
    end

    function H.refreshTheme()
        if S.destroyed or not U.container then return end
        H.buildTheme()
        H.applyTheme()
        H.rebuildRows()
    end

    H.buildTheme()

    -- // Texturas (ID)

    function H.thumbUrl(id)
        return string.format("rbxthumb://type=Asset&id=%s&w=420&h=420", tostring(id))
    end

    function H.textureSource(value)
        if typeof(value) == "Instance" then
            if value:IsA("Decal") or value:IsA("Texture") then
                return H.textureSource(value.Texture)
            end
            if value:IsA("ImageLabel") or value:IsA("ImageButton") then
                return H.textureSource(value.Image)
            end
            return nil, nil
        end
        if value == nil or value == "" then
            return nil, nil
        end

        local text = type(value) == "number" and string.format("%.0f", value) or tostring(value)
        if text:match("^%d+$") then
            return "rbxassetid://" .. text, text
        end

        local id = text:match("^rbxassetid://(%d+)")
            or text:match("[?&]id=(%d+)")
            or text:match("/library/(%d+)")
            or text:match("/catalog/(%d+)")

        if text:match("^https?://") and id then
            return "rbxassetid://" .. id, id
        end
        return text, id
    end

    function H.extractTexture(id)
        local ok, objects = pcall(function()
            return game:GetObjects("rbxassetid://" .. id)
        end)
        if not ok or type(objects) ~= "table" then
            return nil
        end

        local found = nil
        for _, object in ipairs(objects) do
            if object:IsA("Decal") or object:IsA("Texture") then
                found = object.Texture
            elseif object:IsA("Shirt") then
                found = object.ShirtTemplate
            elseif object:IsA("Pants") then
                found = object.PantsTemplate
            elseif object:IsA("ShirtGraphic") then
                found = object.Graphic
            else
                local nested = object:FindFirstChildWhichIsA("Decal", true)
                    or object:FindFirstChildWhichIsA("Texture", true)
                if nested then
                    found = nested.Texture
                end
            end
            if found and found ~= "" then
                break
            end
        end

        for _, object in ipairs(objects) do
            pcall(object.Destroy, object)
        end
        return found
    end

    function H.applyTexture(image, value)
        local source, id = H.textureSource(value)
        if not source then return end

        local cached = id and S.textures[id] or nil
        image.Image = cached or source

        task.spawn(function()
            local function alive()
                return not S.destroyed and image.Parent ~= nil
            end

            local function waitLoaded(seconds)
                local started = os.clock()
                while alive() and not image.IsLoaded and os.clock() - started < seconds do
                    task.wait(0.1)
                end
                return alive() and image.IsLoaded
            end

            local loaded = waitLoaded(K.LOAD_WAIT)

            if not loaded and alive() and id and not cached then
                local extracted = H.extractTexture(id)
                if extracted and extracted ~= "" and alive() then
                    image.Image = extracted
                    loaded = waitLoaded(K.LOAD_WAIT)
                    if loaded then
                        S.textures[id] = extracted
                    end
                end
            end

            if not loaded and alive() and id then
                image.Image = H.thumbUrl(id)
                waitLoaded(K.LOAD_WAIT)
            end

            if alive() then
                H.tween(image, TI.FADE, { ImageTransparency = 0 })
            end
        end)
    end

    -- // Normalizacao das informacoes

    function H.entry(raw)
        if raw == nil then return nil end
        if type(raw) ~= "table" then
            raw = { text = tostring(raw) }
        else
            raw = copyTable(raw)
        end

        local e = { raw = raw }

        local kindText = pick(raw, "type", "Type", "kind", "Kind")
        kindText = type(kindText) == "string" and kindText:lower() or nil

        local label = pick(raw, "label", "Label", "name", "Name")
        local main = pick(raw, "value", "Value", "text", "Text", "info", "Info")
        local max = pick(raw, "max", "Max")

        if label == nil and main == nil and raw[1] ~= nil then
            if raw[2] ~= nil then
                label, main = raw[1], raw[2]
                if max == nil then max = raw[3] end
            else
                main = raw[1]
            end
        end
        if main == nil and label ~= nil then
            main, label = label, nil
        end

        e.label = label ~= nil and tostring(label) or nil
        e.text = main ~= nil and H.display(main) or nil
        e.value = tonumber(main)
        e.max = tonumber(max)
        e.color = pick(raw, "color", "Color")
        e.labelColor = pick(raw, "labelColor", "LabelColor")
        e.tint = pick(raw, "tint", "Tint")
        e.tex = pick(raw, "texture", "Texture", "textureId", "TextureId", "textureID", "image", "Image", "icon", "Icon")
        e.list = pick(raw, "items", "Items", "tags", "Tags", "badges", "Badges", "textures", "Textures")
        e.inline = pick(raw, "inline", "Inline") == true
        e.preview = pick(raw, "preview", "Preview") == true
        e.height = tonumber(pick(raw, "height", "Height"))
        e.size = tonumber(pick(raw, "size", "Size"))
        e.fit = pick(raw, "fit", "Fit", "scale", "Scale")
        e.bullet = pick(raw, "bullet", "Bullet")
        e.visible = pick(raw, "visible", "Visible") ~= false

        local hintGallery = raw.textures ~= nil or raw.Textures ~= nil
        local hintList = pick(raw, "items", "Items", "tags", "Tags", "badges", "Badges") ~= nil

        local kind = nil
        if kindText == "divider" or kindText == "line" or kindText == "separator" then
            kind = "divider"
        elseif kindText == "header" or kindText == "section" or kindText == "heading" then
            kind = "header"
        elseif kindText == "gallery" or kindText == "images" or kindText == "textures" then
            kind = "gallery"
        elseif kindText == "badge" or kindText == "badges" or kindText == "chips" or kindText == "tags" or kindText == "tag" then
            kind = "badges"
        elseif kindText == "bar" or kindText == "progress" then
            kind = "bar"
        elseif kindText == "preview" then
            kind = "preview"
        end

        if not kind then
            if hintGallery then
                kind = "gallery"
            elseif hintList then
                kind = "badges"
            elseif e.tex ~= nil and (e.preview or (e.text == nil and e.label == nil and kindText ~= "icon")) then
                kind = "preview"
            elseif e.max and e.value then
                kind = "bar"
            else
                kind = "text"
            end
        end

        if kind == "badges" and not e.list and e.text then
            e.list = { e.text }
        end
        if kind == "bar" and not (e.max and e.max > 0 and e.value) then
            kind = "text"
        end
        if kind == "preview" and e.tex == nil then
            kind = "text"
        end

        e.kind = kind
        return e
    end

    function H.entries(list)
        local result = {}
        if type(list) ~= "table" then
            return result
        end
        if list[1] == nil and next(list) ~= nil then
            list = { list }
        end
        for _, raw in ipairs(list) do
            local entry = H.entry(raw)
            if entry then
                result[#result + 1] = entry
            end
        end
        return result
    end

    function H.entryColor(entry, index)
        local own = H.color(entry.color)
        if own then return own end

        if entry.kind == "header" then
            return S.theme.Accent
        end
        if entry.kind == "divider" then
            return S.theme.Line
        end

        local byIndex = S.colors[index]
        if byIndex ~= nil then
            local color = H.color(byIndex)
            if color then return color end
        end

        if S.defaultColor ~= nil then
            local color = H.color(S.defaultColor)
            if color then return color end
        end

        return S.theme.Text
    end

    -- // Dados

    local data = {
        disabled = opt("disabled", "Disabled") == true,
        title = tostring(opt("title", "Title", "Name") or ""),
        description = tostring(opt("description", "Description", "content", "Content") or ""),
        tag = tostring(opt("tag", "Tag") or ""),
    }

    -- // UI base

    function H.label(parent, props)
        local base = {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            RichText = S.rich,
            Font = fontMedium,
            TextSize = K.INFO,
            TextColor3 = S.theme.Text,
            LineHeight = 1.1,
        }
        for key, value in pairs(props) do
            base[key] = value
        end
        return H.new("TextLabel", base, parent)
    end

    local function vlist(instance, padding)
        return H.new("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, padding),
        }, instance)
    end

    U.container = H.new("Frame", {
        Name = (data.title ~= "" and data.title or "Paragraph") .. "_Paragraph",
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, section.frame)

    U.content = H.new("CanvasGroup", {
        Name = "Content",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        GroupTransparency = 0,
    }, U.container)
    U.contentLayout = vlist(U.content, 0)

    U.body = H.new("Frame", {
        Name = "Body",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = 1,
    }, U.content)
    vlist(U.body, K.GAP)
    H.new("UIPadding", {
        PaddingTop = UDim.new(0, K.PAD),
        PaddingBottom = UDim.new(0, K.PAD),
        PaddingLeft = UDim.new(0, K.PAD),
        PaddingRight = UDim.new(0, K.PAD),
    }, U.body)

    U.header = H.new("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = 1,
    }, U.body)
    vlist(U.header, 4)

    U.tagPill = H.new("Frame", {
        Name = "TagPill",
        Size = UDim2.new(0, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = 1,
    }, U.header)
    H.corner(U.tagPill, 99)
    U.tagStroke = H.stroke(U.tagPill, S.theme.Accent, 1, 0.4)
    H.new("UIPadding", {
        PaddingLeft = UDim.new(0, 9),
        PaddingRight = UDim.new(0, 9),
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 2),
    }, U.tagPill)

    U.tag = H.new("TextLabel", {
        Name = "Tag",
        Size = UDim2.new(0, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Text = data.tag,
        TextColor3 = S.theme.Accent,
        TextSize = K.TAG,
        Font = fontBold,
        TextWrapped = false,
        RichText = S.rich,
    }, U.tagPill)

    U.title = H.label(U.header, {
        Name = "Title",
        Text = data.title,
        TextSize = K.TITLE,
        Font = fontBold,
        LineHeight = 1.05,
        LayoutOrder = 2,
    })

    U.desc = H.label(U.header, {
        Name = "Description",
        Text = data.description,
        TextSize = K.DESC,
        Font = fontRegular,
        LineHeight = 1.2,
        LayoutOrder = 3,
    })

    U.rule = H.new("Frame", {
        Name = "Rule",
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = S.theme.Line,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        LayoutOrder = 2,
    }, U.body)

    U.list = H.new("Frame", {
        Name = "Info",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = 3,
    }, U.body)
    vlist(U.list, K.ROW_GAP)

    -- // Layout / tema

    function H.resize()
        if S.destroyed then return end
        local height = math.max(U.contentLayout.AbsoluteContentSize.Y, K.MIN_H)
        if U.container.Size.Y.Offset ~= height then
            U.container.Size = UDim2.new(1, 0, 0, height)
        end
    end

    function H.layout()
        if S.destroyed then return end
        local hasHeader = data.tag ~= "" or data.title ~= "" or data.description ~= ""
        local hasItems = #S.items > 0

        U.tagPill.Visible = data.tag ~= ""
        U.title.Visible = data.title ~= ""
        U.desc.Visible = data.description ~= ""
        U.header.Visible = hasHeader
        U.rule.Visible = S.rule and hasHeader and hasItems
        U.list.Visible = hasItems
        H.resize()
    end

    function H.applyTheme()
        local theme = S.theme
        U.title.TextColor3 = H.color(S.titleColor) or theme.Title
        U.desc.TextColor3 = H.color(S.descColor) or theme.Desc
        U.tag.TextColor3 = theme.Accent
        U.tagStroke.Color = theme.Accent
        U.rule.BackgroundColor3 = theme.Line
    end

    function H.applyDisabled()
        U.content.GroupTransparency = data.disabled and 0.55 or 0
    end

    U.contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(H.resize)

    -- // Linhas de informacao

    function H.createRow(entry, index)
        local theme = S.theme
        local color = H.entryColor(entry, index)
        local kind = entry.kind
        local row = { paints = {} }

        local function paint(instance, property)
            row.paints[#row.paints + 1] = { instance, property }
            instance[property] = color
        end

        function row.recolor(newColor)
            color = newColor
            for _, item in ipairs(row.paints) do
                if item[1].Parent then
                    item[1][item[2]] = newColor
                end
            end
        end

        local frame = H.new("Frame", {
            Name = "Info_" .. index,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = index,
            Visible = entry.visible,
        }, U.list)
        row.frame = frame

        local labelColor = H.color(entry.labelColor) or theme.Muted

        if kind == "text" and entry.text == nil and entry.tex == nil then
            frame.Visible = false
            return row
        end

        if kind == "divider" then
            frame.AutomaticSize = Enum.AutomaticSize.None
            frame.Size = UDim2.new(1, 0, 0, K.DIVIDER_H)
            local line = H.new("Frame", {
                Name = "Line",
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(1, 0, 0, 1),
                BorderSizePixel = 0,
            }, frame)
            paint(line, "BackgroundColor3")
            return row
        end

        if kind == "header" then
            vlist(frame, 4)
            local title = H.label(frame, {
                Name = "Header",
                Text = entry.text or entry.label or "",
                TextSize = K.HEAD,
                Font = fontBold,
                LayoutOrder = 1,
            })
            paint(title, "TextColor3")
            return row
        end

        if kind == "badges" then
            vlist(frame, 5)
            if entry.label then
                H.label(frame, {
                    Text = entry.label,
                    TextSize = K.LABEL,
                    TextColor3 = labelColor,
                    LayoutOrder = 1,
                })
            end
            local wrap = H.new("Frame", {
                Name = "Badges",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                LayoutOrder = 2,
            }, frame)
            H.new("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Wraps = true,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6),
            }, wrap)

            for i, item in ipairs(entry.list or {}) do
                local text = item
                local own = nil
                if type(item) == "table" then
                    text = pick(item, "text", "Text", "name", "Name", "label", "Label", "value", "Value")
                    own = H.color(pick(item, "color", "Color"))
                end
                local tone = own or color

                local pill = H.new("Frame", {
                    Name = "Badge_" .. i,
                    Size = UDim2.new(0, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.XY,
                    BackgroundColor3 = tone,
                    BackgroundTransparency = 0.88,
                    BorderSizePixel = 0,
                    LayoutOrder = i,
                }, wrap)
                H.corner(pill, 99)
                local pillStroke = H.stroke(pill, tone, 1, 0.55)
                H.new("UIPadding", {
                    PaddingLeft = UDim.new(0, 10),
                    PaddingRight = UDim.new(0, 10),
                    PaddingTop = UDim.new(0, 3),
                    PaddingBottom = UDim.new(0, 3),
                }, pill)
                local pillText = H.new("TextLabel", {
                    Size = UDim2.new(0, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.XY,
                    BackgroundTransparency = 1,
                    Text = H.display(text == nil and "" or text),
                    TextColor3 = tone,
                    TextSize = K.BADGE,
                    Font = fontBold,
                    TextWrapped = false,
                    RichText = S.rich,
                }, pill)

                if not own then
                    paint(pill, "BackgroundColor3")
                    paint(pillStroke, "Color")
                    paint(pillText, "TextColor3")
                end
            end
            return row
        end

        if kind == "gallery" then
            vlist(frame, 5)
            if entry.label then
                H.label(frame, {
                    Text = entry.label,
                    TextSize = K.LABEL,
                    TextColor3 = labelColor,
                    LayoutOrder = 1,
                })
            end
            local wrap = H.new("Frame", {
                Name = "Gallery",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                LayoutOrder = 2,
            }, frame)
            H.new("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Wraps = true,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 8),
            }, wrap)

            local tile = entry.size or K.TILE
            for i, item in ipairs(entry.list or {}) do
                local texture = item
                local tint = nil
                if type(item) == "table" then
                    texture = pick(item, "texture", "Texture", "image", "Image", "id", "Id")
                    tint = H.color(pick(item, "tint", "Tint"))
                end

                local holder = H.new("Frame", {
                    Name = "Tile_" .. i,
                    Size = UDim2.fromOffset(tile, tile),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    LayoutOrder = i,
                }, wrap)
                H.corner(holder, 8)
                H.stroke(holder, theme.Line, 1, 0.2)

                local image = H.new("ImageLabel", {
                    Size = UDim2.new(1, -10, 1, -10),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    ScaleType = Enum.ScaleType.Fit,
                    ImageTransparency = 1,
                }, holder)
                if tint then
                    image.ImageColor3 = tint
                end
                H.applyTexture(image, texture)
            end
            return row
        end

        if kind == "preview" then
            vlist(frame, 6)
            local height = entry.height or K.PREVIEW_H
            local holder = H.new("Frame", {
                Name = "Preview",
                Size = UDim2.new(1, 0, 0, height),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                LayoutOrder = 1,
            }, frame)
            H.corner(holder, 10)
            H.stroke(holder, theme.Line, 1, 0.1)

            local fit = type(entry.fit) == "string" and entry.fit:lower() or "fit"
            local scaleType = Enum.ScaleType.Fit
            if fit == "crop" then
                scaleType = Enum.ScaleType.Crop
            elseif fit == "stretch" then
                scaleType = Enum.ScaleType.Stretch
            end

            local image = H.new("ImageLabel", {
                Size = UDim2.new(1, -12, 1, -12),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                ScaleType = scaleType,
                ImageTransparency = 1,
            }, holder)
            if entry.tint == true then
                paint(image, "ImageColor3")
            else
                local tint = H.color(entry.tint)
                if tint then
                    image.ImageColor3 = tint
                end
            end
            H.applyTexture(image, entry.tex)

            if entry.label then
                H.label(frame, {
                    Text = entry.label,
                    TextSize = K.LABEL,
                    TextColor3 = labelColor,
                    LayoutOrder = 2,
                })
            end
            if entry.text then
                local caption = H.label(frame, {
                    Text = entry.text,
                    TextSize = K.INFO,
                    Font = fontBold,
                    LayoutOrder = 3,
                })
                paint(caption, "TextColor3")
            end
            return row
        end

        local indent = 0
        local style = S.marker
        if entry.bullet == false then
            style = "none"
        elseif entry.bullet == true and style == "none" then
            style = "bar"
        end

        local hasIcon = entry.tex ~= nil
        if hasIcon then
            local size = entry.size or K.ICON
            local icon = H.new("ImageLabel", {
                Name = "Icon",
                Size = UDim2.fromOffset(size, size),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                ScaleType = Enum.ScaleType.Fit,
                ImageTransparency = 1,
            }, frame)
            if entry.tint == true then
                paint(icon, "ImageColor3")
            else
                local tint = H.color(entry.tint)
                if tint then
                    icon.ImageColor3 = tint
                end
            end
            H.applyTexture(icon, entry.tex)
            indent = size + 10
        elseif style == "bar" then
            local marker = H.new("Frame", {
                Name = "Marker",
                Size = UDim2.new(0, 3, 1, 0),
                BorderSizePixel = 0,
            }, frame)
            H.corner(marker, 99)
            paint(marker, "BackgroundColor3")
            indent = 13
        elseif style == "dot" then
            local marker = H.new("Frame", {
                Name = "Marker",
                Position = UDim2.new(0, 1, 0, 5),
                Size = UDim2.fromOffset(6, 6),
                BorderSizePixel = 0,
            }, frame)
            H.corner(marker, 99)
            paint(marker, "BackgroundColor3")
            indent = 14
        end

        local content = H.new("Frame", {
            Name = "Content",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, indent, 0, 0),
            Size = UDim2.new(1, -indent, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
        }, frame)
        vlist(content, kind == "bar" and 5 or 2)
        if hasIcon then
            H.new("UIPadding", { PaddingTop = UDim.new(0, 2) }, content)
        end

        if kind == "bar" then
            local ratio = math.clamp(entry.value / entry.max, 0, 1)

            local top = H.new("Frame", {
                Name = "Top",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                LayoutOrder = 1,
            }, content)
            H.new("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 8),
            }, top)

            H.label(top, {
                Name = "Name",
                Size = UDim2.new(0.5, -4, 0, 0),
                Text = entry.label or "",
                TextSize = K.LABEL,
                TextColor3 = labelColor,
                LayoutOrder = 1,
            })
            local amount = H.label(top, {
                Name = "Value",
                Size = UDim2.new(0.5, -4, 0, 0),
                Text = string.format("%s/%s  •  %d%%", H.number(entry.value), H.number(entry.max), math.floor(ratio * 100 + 0.5)),
                TextSize = K.INFO,
                Font = fontBold,
                TextXAlignment = Enum.TextXAlignment.Right,
                LayoutOrder = 2,
            })
            paint(amount, "TextColor3")

            local track = H.new("Frame", {
                Name = "Track",
                Size = UDim2.new(1, 0, 0, K.BAR_H),
                BackgroundColor3 = theme.Track,
                BorderSizePixel = 0,
                LayoutOrder = 2,
            }, content)
            H.corner(track, 99)
            local fill = H.new("Frame", {
                Name = "Fill",
                Size = UDim2.new(0, 0, 1, 0),
                BorderSizePixel = 0,
            }, track)
            H.corner(fill, 99)
            paint(fill, "BackgroundColor3")
            H.tween(fill, TI.BAR, { Size = UDim2.new(ratio, 0, 1, 0) })
            return row
        end

        if entry.label and entry.text then
            if entry.inline then
                local line = H.new("Frame", {
                    Name = "Line",
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    LayoutOrder = 1,
                }, content)
                H.new("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 8),
                }, line)
                H.label(line, {
                    Name = "Label",
                    Size = UDim2.new(0.42, -4, 0, 0),
                    Text = entry.label,
                    TextSize = K.LABEL + 1,
                    TextColor3 = labelColor,
                    LayoutOrder = 1,
                })
                local value = H.label(line, {
                    Name = "Value",
                    Size = UDim2.new(0.58, -4, 0, 0),
                    Text = entry.text,
                    Font = fontBold,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    LayoutOrder = 2,
                })
                paint(value, "TextColor3")
            else
                local name = (entry.label:gsub(":%s*$", ""))
                local text = name .. ": " .. entry.text
                if S.rich then
                    local head = "<b>" .. name .. ":</b>"
                    local custom = H.color(entry.labelColor)
                    if custom then
                        head = string.format('<font color="#%s">%s</font>', custom:ToHex(), head)
                    end
                    text = head .. " " .. entry.text
                end
                local line = H.label(content, {
                    Name = "Line",
                    Text = text,
                    LayoutOrder = 1,
                })
                paint(line, "TextColor3")
            end
        else
            local text = H.label(content, {
                Name = "Text",
                Text = entry.text or entry.label or "",
                LayoutOrder = 1,
            })
            paint(text, "TextColor3")
        end

        return row
    end

    function H.clearRows()
        for _, row in ipairs(S.rows) do
            if row.frame then
                row.frame:Destroy()
            end
        end
        S.rows = {}
    end

    function H.rebuildRows()
        H.clearRows()
        for index, entry in ipairs(S.items) do
            S.rows[index] = H.createRow(entry, index)
        end
        H.layout()
    end

    function H.rebuildRow(index)
        local old = S.rows[index]
        if old and old.frame then
            old.frame:Destroy()
        end
        S.rows[index] = H.createRow(S.items[index], index)
        H.layout()
    end

    function H.recolorAll()
        for index, row in ipairs(S.rows) do
            local entry = S.items[index]
            if entry and row.recolor then
                row.recolor(H.entryColor(entry, index))
            end
        end
    end

    -- // Inicializacao

    do
        local items = H.entries(opt("info", "Info", "lines", "Lines", "items", "Items"))
        for _, entry in ipairs(H.entries(opt("status", "Status"))) do
            items[#items + 1] = entry
        end
        S.items = items
    end

    H.applyTheme()
    H.applyDisabled()
    H.rebuildRows()

    unwatchTheme = watchTheme(function()
        H.refreshTheme()
    end)

    -- // API

    function data:SetTitle(value)
        if S.destroyed then return end
        value = tostring(value or "")
        if value == data.title then return end
        data.title = value
        U.title.Text = value
        U.container.Name = (value ~= "" and value or "Paragraph") .. "_Paragraph"
        H.layout()
    end

    function data:SetDescription(value)
        if S.destroyed then return end
        value = tostring(value or "")
        if value == data.description then return end
        data.description = value
        U.desc.Text = value
        H.layout()
    end

    function data:SetTag(value)
        if S.destroyed then return end
        value = tostring(value or "")
        if value == data.tag then return end
        data.tag = value
        U.tag.Text = value
        H.layout()
    end

    function data:GetTitle()
        return data.title
    end

    function data:GetDescription()
        return data.description
    end

    function data:SetTitleColor(color)
        if S.destroyed then return end
        S.titleColor = color
        H.applyTheme()
    end

    function data:SetDescriptionColor(color)
        if S.destroyed then return end
        S.descColor = color
        H.applyTheme()
    end

    function data:RefreshTheme()
        if S.destroyed then return end
        H.refreshTheme()
    end

    function data:SetAccent(color)
        if S.destroyed then return end
        S.accent = color
        H.refreshTheme()
    end

    function data:SetInfo(list)
        if S.destroyed then return end
        S.items = H.entries(list)
        H.rebuildRows()
    end

    function data:AddInfo(raw, position)
        if S.destroyed then return nil end
        local entry = H.entry(raw)
        if not entry then return nil end

        if type(position) == "number" and position >= 1 and position <= #S.items then
            table.insert(S.items, position, entry)
            H.rebuildRows()
            return position
        end

        S.items[#S.items + 1] = entry
        local index = #S.items
        S.rows[index] = H.createRow(entry, index)
        H.layout()
        return index
    end

    function data:UpdateInfo(index, fields)
        if S.destroyed then return end
        local entry = S.items[index]
        if not entry then return end

        local mainKeys = { "value", "Value", "text", "Text", "info", "Info" }
        local merged = copyTable(entry.raw)

        local update = fields
        if type(update) ~= "table" then
            update = { value = fields }
        end

        local touchesMain = false
        for _, key in ipairs(mainKeys) do
            if update[key] ~= nil then
                touchesMain = true
                break
            end
        end
        if touchesMain then
            for _, key in ipairs(mainKeys) do
                merged[key] = nil
            end
        end
        for key, value in pairs(update) do
            merged[key] = value
        end

        local newEntry = H.entry(merged)
        if not newEntry then return end
        S.items[index] = newEntry
        H.rebuildRow(index)
    end

    function data:SetInfoColor(index, color)
        if S.destroyed then return end
        local entry = S.items[index]
        if not entry then return end
        entry.color = color
        entry.raw.color = color
        entry.raw.Color = nil
        local row = S.rows[index]
        if row and row.recolor then
            row.recolor(H.entryColor(entry, index))
        end
    end

    function data:SetColors(colors, default)
        if S.destroyed then return end
        S.colors = {}
        if type(colors) == "table" then
            for key, value in pairs(colors) do
                if type(key) == "number" then
                    S.colors[key] = value
                end
            end
        end
        if default ~= nil then
            S.defaultColor = default
        end
        H.recolorAll()
    end

    function data:SetDefaultColor(color)
        if S.destroyed then return end
        S.defaultColor = color
        H.recolorAll()
    end

    function data:SetAllColors(color)
        if S.destroyed then return end
        S.colors = {}
        S.defaultColor = color
        for _, entry in ipairs(S.items) do
            entry.color = nil
            entry.raw.color = nil
            entry.raw.Color = nil
        end
        H.recolorAll()
    end

    function data:RemoveInfo(index)
        if S.destroyed then return end
        if not S.items[index] then return end
        table.remove(S.items, index)
        H.rebuildRows()
    end

    function data:ClearInfo()
        if S.destroyed then return end
        S.items = {}
        H.rebuildRows()
    end

    function data:GetInfo()
        local result = {}
        for index, entry in ipairs(S.items) do
            result[index] = copyTable(entry.raw)
        end
        return result
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

    function data:Refresh()
        if S.destroyed then return end
        S.textures = {}
        H.rebuildRows()
    end

    function data:Update(fields)
        if S.destroyed or type(fields) ~= "table" then return end
        if fields.title ~= nil then data:SetTitle(fields.title) end
        if fields.description ~= nil then data:SetDescription(fields.description) end
        if fields.tag ~= nil then data:SetTag(fields.tag) end
        if fields.disabled ~= nil then data:SetDisabled(fields.disabled) end
        if fields.visible ~= nil then data:SetVisible(fields.visible) end
        if fields.accent ~= nil then data:SetAccent(fields.accent) end
        if fields.colors ~= nil or fields.defaultColor ~= nil then
            data:SetColors(fields.colors or S.colors, fields.defaultColor)
        end
        if fields.info ~= nil then data:SetInfo(fields.info) end
    end

    function data:Destroy()
        if S.destroyed then return end
        S.destroyed = true
        if unwatchTheme then
            unwatchTheme()
            unwatchTheme = nil
        end
        for _, connection in ipairs(S.connections) do
            connection:Disconnect()
        end
        table.clear(S.connections)
        U.container:Destroy()
    end

    S.connections[#S.connections + 1] = U.container.Destroying:Connect(function()
        if not S.destroyed then
            data:Destroy()
        end
    end)

    return data
end)