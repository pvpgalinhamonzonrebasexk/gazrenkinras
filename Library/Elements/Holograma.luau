local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")

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
local HEIGHT_DEFAULT = 200
local HEIGHT_MIN = 60
local HEIGHT_MAX = 600
local RATE_DEFAULT = 0.1
local RATE_MIN = 0.016
local RATE_MAX = 5

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

    local container = create("Frame", {
        Name = title .. "_Hologram",
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = Colors.Palette,
        BackgroundTransparency = showFrame and 0 or 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, section.frame)

    create("UICorner", { CornerRadius = UDim.new(0, 8) }, container)

    local containerStroke = create("UIStroke", {
        Color = Colors.Border,
        Thickness = 1,
        Enabled = showFrame,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, container)

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
    end

    local function step(dt)
        if destroyed or paused then
            return
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

        return false
    end

    refreshLoop = function()
        local needed = not destroyed and not paused and (reader ~= nil or hasLive())

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
            container.BackgroundColor3 = Colors.Palette
            containerStroke.Color = Colors.Border
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
        title = tostring(value or "")
        container.Name = title .. "_Hologram"
    end

    function api:SetVisible(value)
        if destroyed then
            return
        end

        container.Visible = value == true
    end

    function api:SetHeight(value)
        if destroyed then
            return
        end

        height = math.clamp(tonumber(value) or height, HEIGHT_MIN, HEIGHT_MAX)
        container.Size = UDim2.new(1, 0, 0, height)
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
        container:Destroy()
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