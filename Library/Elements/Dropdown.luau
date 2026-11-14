-- // Services
local tweenService = game:GetService("TweenService")
local userInputService = game:GetService("UserInputService")
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
    local colors

    colors = setmetatable({}, {
        __index = function(_, key)
            local theme = panel and panel.Theme
            local live = type(theme) == "table" and theme[key] or nil

            if typeof(live) == "Color3" then
                return live
            end

            local base = Default[key]

            if base then
                return base
            end

            local derive = DERIVED[key]

            if derive then
                return derive(colors)
            end

            return nil
        end
    })

    local function watch(apply)
        local last = {}

        for _, key in ipairs(THEME_KEYS) do
            last[key] = colors[key]
        end

        local function check()
            local changed = false

            for _, key in ipairs(THEME_KEYS) do
                local current = colors[key]

                if last[key] ~= current then
                    last[key] = current
                    changed = true
                end
            end

            if changed then
                pcall(apply)
            end
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

-- // Dropdown
Elements.Register("Dropdown", function(section, options)
    options = type(options) == "table" and options or {}

    local Colors, watchTheme = createColors(section.Panel or Panel)

    local env = getgenv and getgenv() or _G
    local fontRegular = FONT or Enum.Font.SourceSans
    local fontTitle = FONT_BOLD or Enum.Font.SourceSansSemibold
    local iconAssets = env.EcoHubIcons or (ICONS and ICONS.assets)

    local function iconId(name, fallback)
        return (iconAssets and iconAssets["lucide-" .. name]) or fallback
    end

    local checkImage = iconId("check", "rbxassetid://10709790644")
    local searchImage = iconId("search", "rbxassetid://10734943674")
    local clearImage = iconId("x", "rbxassetid://10747384394")
    local chevronImage = iconId("chevron-down", "rbxassetid://10709790948")

    local MOBILE = userInputService.TouchEnabled and not userInputService.KeyboardEnabled
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

    local TITLE_SIZE = MOBILE and 14 or 13
    local DESC_SIZE = 11
    local LABEL_SIZE = MOBILE and 13 or 12
    local BASE_ROW_H = MOBILE and 40 or 34
    local FIELD_W = 130
    local FIELD_MIN_W = 90
    local FIELD_H = MOBILE and 30 or 24
    local OPT_H = MOBILE and 34 or 28
    local OPT_GAP = 2
    local SEARCH_H = MOBILE and 32 or 26
    local SEARCH_AREA = SEARCH_H + 10
    local MAX_H = MOBILE and 250 or 210
    local MAX_SCREEN = MOBILE and 0.42 or 0.5
    local CHECK_SIZE = 12
    local GAP = 4
    local TITLE_Y = 4
    local TITLE_H = 15
    local DESC_Y = TITLE_Y + TITLE_H + 1
    local MAX_QUERY = 40
    local ANIM_T = LOW_END and 0.1 or 0.14
    local WORD_BREAK = 20
    local TAP_SLOP = 14
    local SEARCH_DELAY = LOW_END and 0.12 or 0.05
    local BUILD_BUDGET = LOW_END and 0.003 or 0.006
    local NOTIFY_TITLE = "Sistema"
    local Z = 2
    local rowH = BASE_ROW_H
    local applyHeader

    local TI_FAST = TweenInfo.new(0.1)
    local TI_ROW = TweenInfo.new(0.09)
    local TI_HOVER = TweenInfo.new(0.07)
    local TI_OPEN = TweenInfo.new(ANIM_T, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local TI_CLOSE = TweenInfo.new(ANIM_T, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local TI_RESIZE = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local TI_REVEAL = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local TI_ICON = TweenInfo.new(ANIM_T)

    local connections = {}
    local rowConnections = {}
    local destroyed = false
    local sizeTween
    local unwatchTheme
    local fieldHover = false
    local fieldPressed = false
    local searchFocused = false
    local openedAt = 0
    local visibleCount = 0
    local outsideStart
    local searchToken = 0
    local buildToken = 0
    local building = false

    local function connect(signal, fn)
        local conn = signal:Connect(fn)
        connections[#connections + 1] = conn
        return conn
    end

    local function warnf(msg)
        pcall(function()
            Notify({ Title = NOTIFY_TITLE, Description = msg, Duration = 5 })
        end)
    end

    local function breakWords(text, maxRun)
        text = tostring(text or "")
        local lines = {}
        for line in (text .. "\n"):gmatch("(.-)\n") do
            local r = {}
            for w in line:gmatch("%S+") do
                while #w > maxRun do
                    r[#r + 1] = w:sub(1, maxRun)
                    w = w:sub(maxRun + 1)
                end
                r[#r + 1] = w
            end
            lines[#lines + 1] = table.concat(r, " ")
        end
        return table.concat(lines, "\n")
    end

    local function tw(obj, info, props, force)
        if destroyed or not obj or not obj.Parent then return end
        if LOW_END and not force then
            for property, value in pairs(props) do
                obj[property] = value
            end
            return
        end
        pcall(function()
            tweenService:Create(obj, info, props):Play()
        end)
    end

    local function isPointerInput(input)
        return input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
    end

    local function usingTouch()
        return userInputService:GetLastInputType() == Enum.UserInputType.Touch
    end

    local function isInside(guiObject, pos)
        local p = guiObject.AbsolutePosition
        local s = guiObject.AbsoluteSize
        return pos.X >= p.X and pos.X <= p.X + s.X and pos.Y >= p.Y and pos.Y <= p.Y + s.Y
    end

    local title = tostring(options.title or options.Name or "Dropdown")
    local desc = tostring(options.description or "")
    local values = type(options.values or options.Options) == "table" and (options.values or options.Options) or {}
    local multi = options.multi == true
    local disabled = options.disabled == true
    local callback = options.callback or options.Callback
    local placeholder = tostring(options.placeholder or "Select...")
    local allowDeselect = options.allowDeselect ~= false

    if type(callback) ~= "function" then
        callback = function() end
    end

    local hasDesc = desc ~= ""

    local data = {
        disabled = disabled,
        expanded = false,
    }

    local valueKeys = {}

    local function rebuildKeys()
        valueKeys = {}
        for index, value in ipairs(values) do
            valueKeys[index] = tostring(value):lower()
        end
    end

    rebuildKeys()

    local function hasValue(v)
        return table.find(values, v) ~= nil
    end

    if multi then
        data.value = {}
        if type(options.default) == "table" then
            for _, v in ipairs(options.default) do
                if hasValue(v) then data.value[v] = true end
            end
        end
    else
        data.value = nil
        if options.default ~= nil and hasValue(options.default) then
            data.value = options.default
        end
    end

    local function fieldStrokeColor()
        local hot = (fieldHover or fieldPressed or data.expanded) and not data.disabled
        return hot and Colors.BorderHover or Colors.Border
    end

    local function fieldBgColor()
        if data.disabled then
            return Colors.Palette
        end
        if fieldPressed then
            return Colors.Pressed
        end
        if fieldHover or data.expanded then
            return Colors.Hover
        end
        return Colors.Palette
    end

    local function searchIconColor()
        return searchFocused and Colors.Inactive or Colors.Dim
    end

    local container = Instance.new("Frame")
    container.Name = title .. "_Dropdown"
    container.Size = UDim2.new(1, 0, 0, rowH)
    container.BackgroundTransparency = 1
    container.ClipsDescendants = true
    container.Parent = section.frame

    local headerRow = Instance.new("Frame")
    headerRow.Name = "Header"
    headerRow.Size = UDim2.new(1, 0, 0, rowH)
    headerRow.BackgroundTransparency = 1
    headerRow.Parent = container

    local headerButton = Instance.new("TextButton")
    headerButton.Name = "HeaderButton"
    headerButton.Size = UDim2.new(1, 0, 1, 0)
    headerButton.BackgroundTransparency = 1
    headerButton.Text = ""
    headerButton.AutoButtonColor = false
    headerButton.Selectable = false
    headerButton.Active = not disabled
    headerButton.Parent = headerRow

    local textSide = Instance.new("Frame")
    textSide.Name = "TextSide"
    textSide.Size = UDim2.new(1, -(FIELD_W + 16), 1, 0)
    textSide.BackgroundTransparency = 1
    textSide.Parent = headerRow

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = disabled and Colors.BorderHover or Colors.Active
    titleLabel.TextSize = TITLE_SIZE
    titleLabel.Font = fontTitle
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.Parent = textSide

    local descLabel

    local function layoutText()
        if descLabel then
            titleLabel.Size = UDim2.new(1, 0, 0, TITLE_H)
            titleLabel.Position = UDim2.new(0, 0, 0, TITLE_Y)
        else
            titleLabel.Size = UDim2.new(1, 0, 1, 0)
            titleLabel.Position = UDim2.new(0, 0, 0, 0)
        end
    end

    local function createDescription(text)
        descLabel = Instance.new("TextLabel")
        descLabel.Name = "Desc"
        descLabel.Size = UDim2.new(1, 0, 0, 0)
        descLabel.Position = UDim2.new(0, 0, 0, DESC_Y)
        descLabel.AutomaticSize = Enum.AutomaticSize.Y
        descLabel.BackgroundTransparency = 1
        descLabel.Text = breakWords(text, WORD_BREAK)
        descLabel.TextColor3 = Colors.Dim
        descLabel.TextSize = DESC_SIZE
        descLabel.Font = fontRegular
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextYAlignment = Enum.TextYAlignment.Top
        descLabel.TextWrapped = true
        descLabel.LineHeight = 1.1
        descLabel.Parent = textSide
        connect(descLabel:GetPropertyChangedSignal("AbsoluteSize"), function()
            if applyHeader then
                applyHeader()
            end
        end)
    end

    if hasDesc then
        createDescription(desc)
    end

    layoutText()

    local field = Instance.new("TextButton")
    field.Name = "Field"
    field.Size = UDim2.new(0, FIELD_W, 0, FIELD_H)
    field.Position = UDim2.new(1, -1, 0.5, 0)
    field.AnchorPoint = Vector2.new(1, 0.5)
    field.BackgroundColor3 = Colors.Palette
    field.BorderSizePixel = 0
    field.Text = ""
    field.AutoButtonColor = false
    field.Selectable = false
    field.Active = not disabled
    field.Parent = headerRow

    local fieldCorner = Instance.new("UICorner")
    fieldCorner.CornerRadius = UDim.new(0, 6)
    fieldCorner.Parent = field

    local fStroke = Instance.new("UIStroke")
    fStroke.Color = Colors.Border
    fStroke.Thickness = 1
    fStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    fStroke.Parent = field

    local fieldText = Instance.new("TextLabel")
    fieldText.Name = "FieldText"
    fieldText.Size = UDim2.new(1, -28, 1, 0)
    fieldText.Position = UDim2.new(0, 9, 0, 0)
    fieldText.BackgroundTransparency = 1
    fieldText.Text = placeholder
    fieldText.TextColor3 = Colors.Inactive
    fieldText.TextSize = LABEL_SIZE
    fieldText.Font = fontRegular
    fieldText.TextXAlignment = Enum.TextXAlignment.Left
    fieldText.TextTruncate = Enum.TextTruncate.AtEnd
    fieldText.Parent = field

    local fieldIcon = Instance.new("ImageLabel")
    fieldIcon.Name = "Icon"
    fieldIcon.Size = UDim2.new(0, 12, 0, 12)
    fieldIcon.Position = UDim2.new(1, -8, 0.5, 0)
    fieldIcon.AnchorPoint = Vector2.new(1, 0.5)
    fieldIcon.BackgroundTransparency = 1
    fieldIcon.Image = chevronImage
    fieldIcon.ImageColor3 = Colors.Dim
    fieldIcon.Parent = field

    local function applyWidth()
        if destroyed then return end
        local width = container.AbsoluteSize.X
        local fieldW = FIELD_W
        if width > 0 then
            fieldW = math.clamp(math.floor(width * 0.5), FIELD_MIN_W, FIELD_W)
        end
        field.Size = UDim2.new(0, fieldW, 0, FIELD_H)
        textSide.Size = UDim2.new(1, -(fieldW + 16), 1, 0)
    end

    connect(container:GetPropertyChangedSignal("AbsoluteSize"), applyWidth)
    applyWidth()

    local panel = Instance.new("Frame")
    panel.Name = title .. "_Panel"
    panel.BackgroundColor3 = Colors.Background
    panel.BorderSizePixel = 0
    panel.Position = UDim2.new(0, 1, 0, rowH + GAP)
    panel.Size = UDim2.new(1, -2, 0, 0)
    panel.Visible = false
    panel.Active = true
    panel.ClipsDescendants = true
    panel.ZIndex = Z
    panel.Parent = container

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 8)
    panelCorner.Parent = panel

    local pStroke = Instance.new("UIStroke")
    pStroke.Color = Colors.Border
    pStroke.Thickness = 1
    pStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    pStroke.Parent = panel

    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "Scroll"
    scroll.Size = UDim2.new(1, -4, 1, -(SEARCH_AREA + 4))
    scroll.Position = UDim2.new(0, 2, 0, 2)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = MOBILE and 3 or 2
    scroll.ScrollBarImageColor3 = Colors.BorderHover
    scroll.ScrollBarImageTransparency = 0
    scroll.ScrollingDirection = Enum.ScrollingDirection.Y
    scroll.ElasticBehavior = Enum.ElasticBehavior.Never
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ZIndex = Z
    scroll.Parent = panel

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, OPT_GAP)
    listLayout.Parent = scroll

    local listPad = Instance.new("UIPadding")
    listPad.PaddingTop = UDim.new(0, 2)
    listPad.PaddingBottom = UDim.new(0, 4)
    listPad.PaddingLeft = UDim.new(0, 4)
    listPad.PaddingRight = UDim.new(0, 6)
    listPad.Parent = scroll

    local emptyLabel = Instance.new("TextLabel")
    emptyLabel.Name = "Empty"
    emptyLabel.Size = UDim2.new(1, 0, 0, OPT_H)
    emptyLabel.Position = UDim2.new(0, 0, 0, 2)
    emptyLabel.BackgroundTransparency = 1
    emptyLabel.Text = "No results found"
    emptyLabel.TextColor3 = Colors.Inactive
    emptyLabel.TextSize = LABEL_SIZE
    emptyLabel.Font = fontRegular
    emptyLabel.Visible = false
    emptyLabel.ZIndex = Z + 1
    emptyLabel.Parent = panel

    local searchFrame = Instance.new("Frame")
    searchFrame.Name = "Search"
    searchFrame.Size = UDim2.new(1, -16, 0, SEARCH_H)
    searchFrame.Position = UDim2.new(0, 8, 1, -(SEARCH_H + 5))
    searchFrame.BackgroundTransparency = 1
    searchFrame.BorderSizePixel = 0
    searchFrame.ClipsDescendants = true
    searchFrame.ZIndex = Z + 1
    searchFrame.Parent = panel

    local searchIcon = Instance.new("ImageLabel")
    searchIcon.Name = "Icon"
    searchIcon.Size = UDim2.new(0, 12, 0, 12)
    searchIcon.Position = UDim2.new(0, 6, 0.5, 0)
    searchIcon.AnchorPoint = Vector2.new(0, 0.5)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Image = searchImage
    searchIcon.ImageColor3 = Colors.Dim
    searchIcon.ZIndex = Z + 2
    searchIcon.Parent = searchFrame

    local searchBox = Instance.new("TextBox")
    searchBox.Name = "Input"
    searchBox.Size = UDim2.new(1, -52, 1, 0)
    searchBox.Position = UDim2.new(0, 26, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.Text = ""
    searchBox.PlaceholderText = "Search..."
    searchBox.PlaceholderColor3 = Colors.Dim
    searchBox.TextColor3 = Colors.Active
    searchBox.TextSize = LABEL_SIZE
    searchBox.Font = fontRegular
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.TextTruncate = Enum.TextTruncate.AtEnd
    searchBox.ClearTextOnFocus = false
    searchBox.ClipsDescendants = true
    searchBox.TextWrapped = false
    searchBox.MultiLine = false
    searchBox.ZIndex = Z + 2
    searchBox.Parent = searchFrame

    local clearBtn = Instance.new("ImageButton")
    clearBtn.Name = "Clear"
    clearBtn.Size = UDim2.new(0, 16, 0, 16)
    clearBtn.Position = UDim2.new(1, -4, 0.5, 0)
    clearBtn.AnchorPoint = Vector2.new(1, 0.5)
    clearBtn.BackgroundTransparency = 1
    clearBtn.Image = clearImage
    clearBtn.ImageColor3 = Colors.Dim
    clearBtn.AutoButtonColor = false
    clearBtn.Selectable = false
    clearBtn.Visible = false
    clearBtn.ZIndex = Z + 3
    clearBtn.Parent = searchFrame

    local optRows = {}
    local optionsBuilt = false

    local function isSelected(value)
        if multi then
            return data.value[value] == true
        end
        return data.value == value
    end

    local function hasSelection()
        if multi then
            return next(data.value) ~= nil
        end
        return data.value ~= nil
    end

    local function getSelectedList()
        local sel = {}
        for _, v in ipairs(values) do
            if data.value[v] then
                sel[#sel + 1] = v
            end
        end
        return sel
    end

    local function getOutput()
        if multi then
            return getSelectedList()
        end
        return data.value
    end

    local function getDisplayText()
        if multi then
            local sel = getSelectedList()
            if #sel == 0 then return placeholder end
            if #sel > 2 then return #sel .. " selected" end
            local names = {}
            for i, v in ipairs(sel) do
                names[i] = tostring(v)
            end
            return table.concat(names, ", ")
        end
        if data.value == nil then return placeholder end
        return tostring(data.value)
    end

    local function updateField(animate)
        local col
        if data.disabled then
            col = Colors.BorderHover
        elseif hasSelection() then
            col = Colors.Active
        else
            col = Colors.Inactive
        end
        local text = getDisplayText()
        if fieldText.Text ~= text then
            fieldText.Text = text
        end
        titleLabel.TextColor3 = data.disabled and Colors.BorderHover or Colors.Active
        if animate then
            tw(fieldText, TI_FAST, { TextColor3 = col })
        else
            fieldText.TextColor3 = col
        end
    end

    local function updateFieldBorder()
        if destroyed then return end
        tw(fStroke, TI_HOVER, { Color = fieldStrokeColor() })
        tw(field, TI_HOVER, { BackgroundColor3 = fieldBgColor() })
    end

    local function updateRow(row, animate)
        local sel = isSelected(row.value)
        local pressed = row.pressed and not data.disabled
        local hover = row.hover and not data.disabled
        local bg
        local tc
        if pressed then
            bg = Colors.Pressed
        elseif sel then
            bg = Colors.Accent
        elseif hover then
            bg = Colors.Hover
        else
            bg = Colors.Background
        end
        if data.disabled then
            tc = sel and Colors.Inactive or Colors.BorderHover
        elseif sel then
            tc = Colors.Active
        elseif hover or pressed then
            tc = Colors.TextHover
        else
            tc = Colors.Inactive
        end
        local checkT = sel and 0 or 1
        if animate then
            tw(row.frame, TI_ROW, { BackgroundColor3 = bg })
            tw(row.label, TI_ROW, { TextColor3 = tc })
            tw(row.check, TI_ROW, { ImageTransparency = checkT })
        else
            row.frame.BackgroundColor3 = bg
            row.label.TextColor3 = tc
            row.check.ImageTransparency = checkT
        end
    end

    local function applyTheme()
        if destroyed then return end

        titleLabel.TextColor3 = data.disabled and Colors.BorderHover or Colors.Active

        if descLabel then
            descLabel.TextColor3 = Colors.Dim
        end

        field.BackgroundColor3 = fieldBgColor()
        fStroke.Color = fieldStrokeColor()
        fieldIcon.ImageColor3 = data.expanded and Colors.Inactive or Colors.Dim

        panel.BackgroundColor3 = Colors.Background
        pStroke.Color = Colors.Border
        searchIcon.ImageColor3 = searchIconColor()
        searchBox.TextColor3 = Colors.Active
        searchBox.PlaceholderColor3 = Colors.Dim
        clearBtn.ImageColor3 = Colors.Dim
        scroll.ScrollBarImageColor3 = Colors.BorderHover
        emptyLabel.TextColor3 = Colors.Inactive

        for _, row in ipairs(optRows) do
            row.check.ImageColor3 = Colors.Inactive
            updateRow(row, false)
        end

        updateField(false)
    end

    local function setFieldPressed(value)
        if data.disabled then
            value = false
        end
        if fieldPressed == value then return end
        fieldPressed = value
        updateFieldBorder()
    end

    local function fireCallback()
        local ok, err = pcall(callback, getOutput())
        if not ok then warnf("callback: " .. tostring(err)) end
    end

    local function getScreenH()
        local cam = workspace.CurrentCamera
        return cam and cam.ViewportSize.Y or 600
    end

    local function panelHeight()
        local listH = visibleCount == 0 and OPT_H or visibleCount * (OPT_H + OPT_GAP)
        local h = SEARCH_AREA + listH + 8
        local limit = math.min(MAX_H, math.floor(getScreenH() * MAX_SCREEN))
        return math.max(math.min(h, limit), SEARCH_AREA + OPT_H + 8)
    end

    local function tweenContainer(height, info, onDone)
        if sizeTween then
            sizeTween:Cancel()
            sizeTween = nil
        end
        local current = tweenService:Create(container, info, { Size = UDim2.new(1, 0, 0, height) })
        sizeTween = current
        current.Completed:Connect(function(state)
            if sizeTween == current then
                sizeTween = nil
            end
            if onDone and state == Enum.PlaybackState.Completed then
                onDone()
            end
        end)
        current:Play()
    end

    local function revealPanel()
        if destroyed or not data.expanded then return end
        local scrollFrame = container:FindFirstAncestorWhichIsA("ScrollingFrame")
        if not scrollFrame then return end
        local bottom = container.AbsolutePosition.Y + container.AbsoluteSize.Y - scrollFrame.AbsolutePosition.Y
        local overflow = bottom - scrollFrame.AbsoluteSize.Y + 8
        if overflow > 0 then
            local current = scrollFrame.CanvasPosition
            tw(scrollFrame, TI_REVEAL, { CanvasPosition = Vector2.new(current.X, current.Y + overflow) }, true)
        end
    end

    local function resizeOpen()
        if destroyed or not data.expanded then return end
        local h = panelHeight()
        tweenContainer(rowH + GAP + h + 2, TI_RESIZE)
        tw(panel, TI_RESIZE, { Size = UDim2.new(1, -2, 0, h) }, true)
    end

    applyHeader = function()
        if destroyed then return end
        local h = BASE_ROW_H
        if descLabel then
            h = math.max(BASE_ROW_H, DESC_Y + descLabel.AbsoluteSize.Y + 6)
        end
        if h == rowH then return end
        rowH = h
        headerRow.Size = UDim2.new(1, 0, 0, rowH)
        panel.Position = UDim2.new(0, 1, 0, rowH + GAP)
        if data.expanded then
            resizeOpen()
        else
            if sizeTween then
                sizeTween:Cancel()
                sizeTween = nil
            end
            panel.Visible = false
            container.Size = UDim2.new(1, 0, 0, rowH)
        end
    end

    local function applyFilter()
        if destroyed then return end
        local query = searchBox.Text:lower()
        local shown = 0
        for index = 1, #values do
            if query == "" or string.find(valueKeys[index], query, 1, true) ~= nil then
                shown = shown + 1
            end
        end
        visibleCount = shown
        for _, row in ipairs(optRows) do
            local match = query == "" or string.find(row.key, query, 1, true) ~= nil
            if row.frame.Visible ~= match then
                row.frame.Visible = match
            end
        end
        emptyLabel.Visible = shown == 0
        clearBtn.Visible = query ~= ""
        scroll.CanvasPosition = Vector2.new(0, 0)
        resizeOpen()
    end

    local function closeOverlay(instant)
        if not data.expanded then return end
        data.expanded = false
        outsideStart = nil
        searchBox:ReleaseFocus()
        tw(fieldIcon, TI_ICON, { Rotation = 0, ImageColor3 = Colors.Dim })
        updateFieldBorder()

        if instant then
            if sizeTween then
                sizeTween:Cancel()
                sizeTween = nil
            end
            container.Size = UDim2.new(1, 0, 0, rowH)
            panel.Visible = false
            return
        end

        tweenContainer(rowH, TI_CLOSE, function()
            if not data.expanded and not destroyed then
                panel.Visible = false
            end
        end)
    end

    local function selectValue(value)
        if destroyed or data.disabled then return end
        if multi then
            if data.value[value] then
                data.value[value] = nil
            else
                data.value[value] = true
            end
        else
            if data.value == value then
                if not allowDeselect then
                    closeOverlay(false)
                    return
                end
                data.value = nil
            else
                data.value = value
            end
        end
        for _, row in ipairs(optRows) do updateRow(row, true) end
        updateField(true)
        fireCallback()
        if not multi then closeOverlay(false) end
    end

    local function clearRowConnections()
        for _, conn in ipairs(rowConnections) do
            conn:Disconnect()
        end
        table.clear(rowConnections)
    end

    local function createRow(index, value)
        local optFrame = Instance.new("Frame")
        optFrame.Name = "Opt_" .. index
        optFrame.Size = UDim2.new(1, 0, 0, OPT_H)
        optFrame.BackgroundColor3 = Colors.Background
        optFrame.BorderSizePixel = 0
        optFrame.LayoutOrder = index
        optFrame.ZIndex = Z

        local optCorner = Instance.new("UICorner")
        optCorner.CornerRadius = UDim.new(0, 5)
        optCorner.Parent = optFrame

        local optLabel = Instance.new("TextLabel")
        optLabel.Name = "Label"
        optLabel.Size = UDim2.new(1, -(CHECK_SIZE + 26), 1, 0)
        optLabel.Position = UDim2.new(0, 9, 0, 0)
        optLabel.BackgroundTransparency = 1
        optLabel.Text = tostring(value)
        optLabel.TextColor3 = Colors.Inactive
        optLabel.TextSize = LABEL_SIZE
        optLabel.Font = fontRegular
        optLabel.TextXAlignment = Enum.TextXAlignment.Left
        optLabel.TextTruncate = Enum.TextTruncate.AtEnd
        optLabel.ZIndex = Z + 1
        optLabel.Parent = optFrame

        local optCheck = Instance.new("ImageLabel")
        optCheck.Name = "Check"
        optCheck.Size = UDim2.new(0, CHECK_SIZE, 0, CHECK_SIZE)
        optCheck.Position = UDim2.new(1, -8, 0.5, 0)
        optCheck.AnchorPoint = Vector2.new(1, 0.5)
        optCheck.BackgroundTransparency = 1
        optCheck.Image = checkImage
        optCheck.ImageColor3 = Colors.Inactive
        optCheck.ImageTransparency = 1
        optCheck.ZIndex = Z + 1
        optCheck.Parent = optFrame

        local btn = Instance.new("TextButton")
        btn.Name = "Btn"
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Selectable = false
        btn.ZIndex = Z + 2
        btn.Parent = optFrame

        local row = {
            frame = optFrame,
            label = optLabel,
            check = optCheck,
            value = value,
            key = valueKeys[index] or tostring(value):lower(),
            hover = false,
            pressed = false,
        }
        optRows[#optRows + 1] = row

        local query = searchBox.Text:lower()
        if query ~= "" and string.find(row.key, query, 1, true) == nil then
            optFrame.Visible = false
        end

        optFrame.Parent = scroll

        updateRow(row, false)

        local pressPos = nil

        rowConnections[#rowConnections + 1] = btn.MouseEnter:Connect(function()
            if usingTouch() then return end
            row.hover = true
            updateRow(row, true)
        end)
        rowConnections[#rowConnections + 1] = btn.MouseLeave:Connect(function()
            row.hover = false
            row.pressed = false
            updateRow(row, true)
        end)
        rowConnections[#rowConnections + 1] = btn.InputBegan:Connect(function(input)
            if not isPointerInput(input) then return end
            pressPos = Vector2.new(input.Position.X, input.Position.Y)
            row.pressed = true
            updateRow(row, true)
        end)
        rowConnections[#rowConnections + 1] = btn.InputEnded:Connect(function(input)
            if not isPointerInput(input) then return end
            row.pressed = false
            if input.UserInputType == Enum.UserInputType.Touch then
                row.hover = false
            end
            updateRow(row, true)
        end)
        rowConnections[#rowConnections + 1] = btn.Activated:Connect(function(input)
            if pressPos and input then
                local endPos = Vector2.new(input.Position.X, input.Position.Y)
                if (endPos - pressPos).Magnitude > TAP_SLOP then
                    pressPos = nil
                    row.pressed = false
                    updateRow(row, false)
                    return
                end
            end
            pressPos = nil
            selectValue(value)
        end)
    end

    local function buildOptions()
        optionsBuilt = true
        buildToken = buildToken + 1
        local token = buildToken
        clearRowConnections()
        for _, row in ipairs(optRows) do
            if row.frame then row.frame:Destroy() end
        end
        optRows = {}
        rebuildKeys()
        building = true
        applyFilter()

        task.spawn(function()
            local last = os.clock()
            for index, value in ipairs(values) do
                if destroyed or buildToken ~= token then return end
                createRow(index, value)
                if os.clock() - last > BUILD_BUDGET then
                    task.wait()
                    last = os.clock()
                end
            end
            if destroyed or buildToken ~= token then return end
            building = false
        end)
    end

    local function openOverlay()
        if destroyed or data.disabled or data.expanded or #values == 0 then return end
        if not optionsBuilt then buildOptions() end

        if searchBox.Text ~= "" then
            searchBox.Text = ""
        end
        searchToken = searchToken + 1
        applyFilter()

        data.expanded = true
        openedAt = os.clock()

        local h = panelHeight()
        panel.Size = UDim2.new(1, -2, 0, h)
        panel.Visible = true
        scroll.CanvasPosition = Vector2.new(0, 0)

        tweenContainer(rowH + GAP + h + 2, TI_OPEN, revealPanel)
        tw(fieldIcon, TI_ICON, { Rotation = 180, ImageColor3 = Colors.Inactive })
        updateFieldBorder()

        if not MOBILE then
            task.defer(function()
                if not destroyed and data.expanded then
                    searchBox:CaptureFocus()
                end
            end)
        end
    end

    local function toggle()
        if data.expanded then
            closeOverlay(false)
        else
            openOverlay()
        end
    end

    connect(field.Activated, toggle)
    connect(headerButton.Activated, toggle)

    local function setHover(value)
        fieldHover = value
        updateFieldBorder()
    end

    connect(field.MouseEnter, function()
        if usingTouch() then return end
        setHover(true)
    end)

    connect(field.MouseLeave, function()
        setHover(false)
        setFieldPressed(false)
    end)

    connect(headerButton.MouseEnter, function()
        if usingTouch() then return end
        setHover(true)
    end)

    connect(headerButton.MouseLeave, function()
        setHover(false)
        setFieldPressed(false)
    end)

    for _, target in ipairs({ field, headerButton }) do
        connect(target.InputBegan, function(input)
            if isPointerInput(input) then
                setFieldPressed(true)
            end
        end)
        connect(target.InputEnded, function(input)
            if isPointerInput(input) then
                setFieldPressed(false)
                if input.UserInputType == Enum.UserInputType.Touch then
                    setHover(false)
                end
            end
        end)
    end

    connect(searchBox:GetPropertyChangedSignal("Text"), function()
        local raw = searchBox.Text
        local clean = (string.gsub(raw, "%c", " "))
        local length = utf8.len(clean) or #clean
        if length > MAX_QUERY then
            local cut = utf8.offset(clean, MAX_QUERY + 1)
            clean = cut and string.sub(clean, 1, cut - 1) or string.sub(clean, 1, MAX_QUERY)
        end
        if clean ~= raw then
            searchBox.Text = clean
            return
        end
        searchToken = searchToken + 1
        local current = searchToken
        clearBtn.Visible = searchBox.Text ~= ""
        task.delay(SEARCH_DELAY, function()
            if not destroyed and searchToken == current then
                applyFilter()
            end
        end)
    end)

    connect(searchBox.Focused, function()
        searchFocused = true
        tw(searchIcon, TI_HOVER, { ImageColor3 = searchIconColor() })
    end)

    connect(searchBox.FocusLost, function(enterPressed)
        searchFocused = false
        tw(searchIcon, TI_HOVER, { ImageColor3 = searchIconColor() })
        if enterPressed and data.expanded and searchBox.Text ~= "" then
            searchToken = searchToken + 1
            applyFilter()
            for _, row in ipairs(optRows) do
                if row.frame.Visible then
                    selectValue(row.value)
                    break
                end
            end
        end
    end)

    connect(clearBtn.Activated, function()
        searchBox.Text = ""
        if not MOBILE then
            searchBox:CaptureFocus()
        end
    end)

    connect(clearBtn.MouseEnter, function()
        if usingTouch() then return end
        tw(clearBtn, TI_HOVER, { ImageColor3 = Colors.Inactive })
    end)

    connect(clearBtn.MouseLeave, function()
        tw(clearBtn, TI_HOVER, { ImageColor3 = Colors.Dim })
    end)

    connect(userInputService.InputBegan, function(input)
        if destroyed or not data.expanded then return end
        if not isPointerInput(input) then return end
        if os.clock() - openedAt < 0.15 then return end
        local pos = Vector2.new(input.Position.X, input.Position.Y)
        if isInside(container, pos) then
            outsideStart = nil
        else
            outsideStart = pos
        end
    end)

    connect(userInputService.InputEnded, function(input)
        if not outsideStart then return end
        if not isPointerInput(input) then return end
        local pos = Vector2.new(input.Position.X, input.Position.Y)
        local moved = (pos - outsideStart).Magnitude
        outsideStart = nil
        if destroyed or not data.expanded then return end
        if moved < TAP_SLOP then
            closeOverlay(false)
        end
    end)

    updateField(false)

    if hasSelection() then
        fireCallback()
    end

    local function sameSelection(a, b)
        if multi then
            for k in pairs(a) do
                if not b[k] then return false end
            end
            for k in pairs(b) do
                if not a[k] then return false end
            end
            return true
        end
        return a == b
    end

    function data:Set(value)
        if destroyed then return end
        local new
        if multi then
            new = {}
            if type(value) == "table" then
                for _, v in ipairs(value) do
                    if hasValue(v) then new[v] = true end
                end
            end
        else
            if value ~= nil and not hasValue(value) then
                warnf("valor '" .. tostring(value) .. "' não existe.")
                return
            end
            new = value
        end
        if sameSelection(data.value, new) then return end
        data.value = new
        for _, row in ipairs(optRows) do updateRow(row, true) end
        updateField(true)
        fireCallback()
    end

    function data:Get()
        return getOutput()
    end

    function data:SetValues(newValues)
        if destroyed then return end
        values = type(newValues) == "table" and newValues or {}
        rebuildKeys()

        local changed = false
        if multi then
            local f = {}
            for v in pairs(data.value) do
                if hasValue(v) then
                    f[v] = true
                else
                    changed = true
                end
            end
            data.value = f
        elseif data.value ~= nil and not hasValue(data.value) then
            data.value = nil
            changed = true
        end

        if #values == 0 and data.expanded then
            closeOverlay(true)
        end

        if data.expanded then
            buildOptions()
        else
            buildToken = buildToken + 1
            optionsBuilt = false
        end
        updateField(false)

        if changed then
            fireCallback()
        end
    end

    function data:SetDisabled(value)
        if destroyed then return end
        data.disabled = value == true
        field.Active = not data.disabled
        headerButton.Active = not data.disabled
        if data.disabled then
            fieldPressed = false
            closeOverlay(true)
        end
        for _, row in ipairs(optRows) do updateRow(row, false) end
        updateField(true)
        updateFieldBorder()
    end

    function data:SetTitle(newTitle)
        if destroyed then return end
        title = tostring(newTitle or "")
        titleLabel.Text = title
        container.Name = title .. "_Dropdown"
        panel.Name = title .. "_Panel"
    end

    function data:SetDescription(newDesc)
        if destroyed then return end
        newDesc = tostring(newDesc or "")
        if newDesc == "" then
            if descLabel then
                descLabel:Destroy()
                descLabel = nil
            end
            layoutText()
            applyHeader()
            return
        end
        if not descLabel then
            createDescription(newDesc)
        else
            descLabel.Text = breakWords(newDesc, WORD_BREAK)
        end
        layoutText()
        applyHeader()
    end

    function data:Open()
        openOverlay()
    end

    function data:Close()
        closeOverlay(false)
    end

    function data:Destroy()
        if destroyed then return end
        destroyed = true
        buildToken = buildToken + 1
        searchToken = searchToken + 1
        if sizeTween then
            sizeTween:Cancel()
            sizeTween = nil
        end
        if unwatchTheme then
            unwatchTheme()
            unwatchTheme = nil
        end
        clearRowConnections()
        for _, conn in ipairs(connections) do
            conn:Disconnect()
        end
        table.clear(connections)
        container:Destroy()
    end

    connect(container.Destroying, function()
        data:Destroy()
    end)

    unwatchTheme = watchTheme(applyTheme)

    return data
end)