-- // Button
Elements.Register("Button", function(section, options)
    options = type(options) == "table" and options or {}

    local VARIANTS = {
        default = {
            bg = Color3.fromRGB(240, 240, 240), bgT = 0,
            hover = Color3.fromRGB(218, 218, 218), hoverT = 0,
            pressed = Color3.fromRGB(200, 200, 200),
            text = Color3.fromRGB(24, 24, 24), textHover = Color3.fromRGB(24, 24, 24),
            stroke = Color3.fromRGB(240, 240, 240), strokeT = 1,
        },
        secondary = {
            bg = Color3.fromRGB(42, 42, 42), bgT = 0,
            hover = Color3.fromRGB(52, 52, 52), hoverT = 0,
            pressed = Color3.fromRGB(62, 62, 62),
            text = Color3.fromRGB(240, 240, 240), textHover = Color3.fromRGB(240, 240, 240),
            stroke = Color3.fromRGB(42, 42, 42), strokeT = 1,
        },
        outline = {
            bg = Color3.fromRGB(34, 34, 34), bgT = 0,
            hover = Color3.fromRGB(42, 42, 42), hoverT = 0,
            pressed = Color3.fromRGB(52, 52, 52),
            text = Color3.fromRGB(240, 240, 240), textHover = Color3.fromRGB(240, 240, 240),
            stroke = Color3.fromRGB(55, 55, 55), strokeT = 0,
        },
        ghost = {
            bg = Color3.fromRGB(42, 42, 42), bgT = 1,
            hover = Color3.fromRGB(42, 42, 42), hoverT = 0,
            pressed = Color3.fromRGB(52, 52, 52),
            text = Color3.fromRGB(200, 200, 200), textHover = Color3.fromRGB(240, 240, 240),
            stroke = Color3.fromRGB(42, 42, 42), strokeT = 1,
        },
        destructive = {
            bg = Color3.fromRGB(58, 24, 27), bgT = 0,
            hover = Color3.fromRGB(78, 30, 34), hoverT = 0,
            pressed = Color3.fromRGB(98, 36, 40),
            text = Color3.fromRGB(248, 113, 113), textHover = Color3.fromRGB(252, 165, 165),
            stroke = Color3.fromRGB(58, 24, 27), strokeT = 1,
        },
        link = {
            bg = Color3.fromRGB(24, 24, 24), bgT = 1,
            hover = Color3.fromRGB(24, 24, 24), hoverT = 1,
            pressed = Color3.fromRGB(24, 24, 24),
            text = Color3.fromRGB(240, 240, 240), textHover = Color3.fromRGB(165, 165, 165),
            stroke = Color3.fromRGB(24, 24, 24), strokeT = 1,
        },
    }

    local SIZES = {
        xs = { height = 22, text = 11, pad = 8 },
        sm = { height = 26, text = 12, pad = 10 },
        default = { height = 30, text = 13, pad = 12 },
        lg = { height = 36, text = 14, pad = 16 },
    }

    local COLOR_DESC = Color3.fromRGB(125, 125, 125)
    local DISABLED_FADE = 0.5
    local WORD_MAX = 20
    local SPINNER = 12
    local NOTIFY_TITLE = "Sistema"

    local tweenService = TweenService or game:GetService("TweenService")
    local userInputService = UserInputService or game:GetService("UserInputService")
    local runService = game:GetService("RunService")
    local fontBold = FONT_BOLD or Enum.Font.SourceSansSemibold
    local fontRegular = FONT or Enum.Font.SourceSans
    local tweenInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local mobile = userInputService.TouchEnabled and not userInputService.KeyboardEnabled

    local connections = {}
    local spinnerConnection
    local destroyed = false
    local hovering = false
    local pressed = false

    local function connect(signal, fn)
        local conn = signal:Connect(fn)
        connections[#connections + 1] = conn
        return conn
    end

    local function notify(msg)
        pcall(function()
            Notify({ Title = NOTIFY_TITLE, Description = msg, Duration = 5 })
        end)
    end

    local function breakLongWords(text, maxLen)
        text = tostring(text or "")
        local lines = {}
        for line in (text .. "\n"):gmatch("(.-)\n") do
            local result = {}
            for word in line:gmatch("%S+") do
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

    local function isPointerInput(input)
        return input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
    end

    local function usingTouch()
        return userInputService:GetLastInputType() == Enum.UserInputType.Touch
    end

    local function pickKey(map, value, fallback)
        value = type(value) == "string" and value:lower() or ""
        if map[value] then return value end
        return fallback
    end

    local function fade(t)
        if t >= 1 then return 1 end
        return t + (1 - t) * DISABLED_FADE
    end

    local title = tostring(options.title or options.Name or "Button")
    local description = tostring(options.description or "")
    local callback = options.callback or options.Callback

    if type(callback) ~= "function" then
        callback = function() end
    end

    local data = {
        disabled = options.disabled == true,
        loading = options.loading == true,
        variant = pickKey(VARIANTS, options.variant or options.Variant, "default"),
        size = pickKey(SIZES, options.size or options.Size, "default"),
    }

    local function baseHeight()
        return SIZES[data.size].height + (mobile and 4 or 0)
    end

    local container = Instance.new("Frame")
    container.Name = title .. "_Button"
    container.Size = UDim2.new(1, 0, 0, baseHeight())
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    container.Parent = section.frame

    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 6)
    containerCorner.Parent = container

    local containerStroke = Instance.new("UIStroke")
    containerStroke.Thickness = 1
    containerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    containerStroke.Parent = container

    local textFrame = Instance.new("Frame")
    textFrame.Name = "TextFrame"
    textFrame.Size = UDim2.new(1, -(SIZES[data.size].pad * 2 + SPINNER * 2 + 8), 1, 0)
    textFrame.AnchorPoint = Vector2.new(0.5, 0)
    textFrame.Position = UDim2.new(0.5, 0, 0, 0)
    textFrame.BackgroundTransparency = 1
    textFrame.ZIndex = 1
    textFrame.Parent = container

    local textLayout = Instance.new("UIListLayout")
    textLayout.FillDirection = Enum.FillDirection.Vertical
    textLayout.SortOrder = Enum.SortOrder.LayoutOrder
    textLayout.Padding = UDim.new(0, 1)
    textLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    textLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    textLayout.Parent = textFrame

    local label = Instance.new("TextLabel")
    label.Name = "Title"
    label.BackgroundTransparency = 1
    label.RichText = true
    label.Font = fontBold
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.LayoutOrder = 0
    label.ZIndex = 1
    label.Parent = textFrame

    local descLabel

    local function displayTitle()
        local safe = title:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
        if data.variant == "link" then
            return "<u>" .. safe .. "</u>"
        end
        return safe
    end

    local function descSize()
        return math.max(SIZES[data.size].text - 2, 10)
    end

    local function createDescription(text)
        descLabel = Instance.new("TextLabel")
        descLabel.Name = "Description"
        descLabel.Size = UDim2.new(1, 0, 0, 0)
        descLabel.AutomaticSize = Enum.AutomaticSize.Y
        descLabel.BackgroundTransparency = 1
        descLabel.Text = breakLongWords(text, WORD_MAX)
        descLabel.TextColor3 = COLOR_DESC
        descLabel.TextSize = descSize()
        descLabel.Font = fontRegular
        descLabel.TextXAlignment = Enum.TextXAlignment.Center
        descLabel.TextYAlignment = Enum.TextYAlignment.Top
        descLabel.TextWrapped = true
        descLabel.LineHeight = 1.1
        descLabel.LayoutOrder = 1
        descLabel.ZIndex = 1
        descLabel.Parent = textFrame
    end

    local spinner = Instance.new("Frame")
    spinner.Name = "Spinner"
    spinner.Size = UDim2.new(0, SPINNER, 0, SPINNER)
    spinner.AnchorPoint = Vector2.new(0, 0.5)
    spinner.Position = UDim2.new(0, SIZES[data.size].pad, 0.5, 0)
    spinner.BackgroundTransparency = 1
    spinner.Visible = false
    spinner.ZIndex = 2
    spinner.Parent = container

    local spinnerCorner = Instance.new("UICorner")
    spinnerCorner.CornerRadius = UDim.new(1, 0)
    spinnerCorner.Parent = spinner

    local spinnerStroke = Instance.new("UIStroke")
    spinnerStroke.Thickness = 2
    spinnerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    spinnerStroke.Parent = spinner

    local spinnerGradient = Instance.new("UIGradient")
    spinnerGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(0.51, 1),
        NumberSequenceKeypoint.new(1, 1),
    })
    spinnerGradient.Parent = spinnerStroke

    local clickArea = Instance.new("TextButton")
    clickArea.Name = "ClickArea"
    clickArea.Size = UDim2.new(1, 0, 1, 0)
    clickArea.BackgroundTransparency = 1
    clickArea.Text = ""
    clickArea.AutoButtonColor = false
    clickArea.Selectable = false
    clickArea.ZIndex = 3
    clickArea.Parent = container

    local function stopSpinner()
        if spinnerConnection then
            spinnerConnection:Disconnect()
            spinnerConnection = nil
        end
        spinner.Visible = false
    end

    local function startSpinner()
        if spinnerConnection then return end
        spinner.Visible = true
        spinnerConnection = runService.Heartbeat:Connect(function(dt)
            spinnerGradient.Rotation = (spinnerGradient.Rotation + dt * 420) % 360
        end)
    end

    local function resizeContainer()
        if destroyed then return end
        local height = baseHeight()
        if descLabel then
            height = math.max(textLayout.AbsoluteContentSize.Y + 10, height)
        end
        container.Size = UDim2.new(1, 0, 0, height)
    end

    local function render(animate)
        if destroyed then return end

        local v = VARIANTS[data.variant]
        local live = not data.disabled and not data.loading

        local bg, bgT, textColor = v.bg, v.bgT, v.text
        if live and pressed then
            bg, bgT, textColor = v.pressed, data.variant == "link" and 1 or 0, v.textHover
        elseif live and hovering then
            bg, bgT, textColor = v.hover, v.hoverT, v.textHover
        end

        local strokeT = v.strokeT
        local textT = 0

        if data.disabled then
            bgT = fade(bgT)
            strokeT = fade(strokeT)
            textT = DISABLED_FADE
        end

        spinnerStroke.Color = v.text

        local containerProps = { BackgroundColor3 = bg, BackgroundTransparency = bgT }
        local strokeProps = { Color = v.stroke, Transparency = strokeT }
        local labelProps = { TextColor3 = textColor, TextTransparency = textT }

        if animate then
            tweenService:Create(container, tweenInfo, containerProps):Play()
            tweenService:Create(containerStroke, tweenInfo, strokeProps):Play()
            tweenService:Create(label, tweenInfo, labelProps):Play()
        else
            for k, val in pairs(containerProps) do container[k] = val end
            for k, val in pairs(strokeProps) do containerStroke[k] = val end
            for k, val in pairs(labelProps) do label[k] = val end
        end
    end

    local function applySize()
        local s = SIZES[data.size]
        label.Size = UDim2.new(1, 0, 0, s.text + 4)
        label.TextSize = s.text
        textFrame.Size = UDim2.new(1, -(s.pad * 2 + SPINNER * 2 + 8), 1, 0)
        spinner.Position = UDim2.new(0, s.pad, 0.5, 0)
        if descLabel then
            descLabel.TextSize = descSize()
        end
        resizeContainer()
    end

    local function applyAll(animate)
        label.Text = displayTitle()
        applySize()
        clickArea.Active = not data.disabled and not data.loading
        if data.loading then
            startSpinner()
        else
            stopSpinner()
        end
        render(animate)
    end

    local function fireCallback()
        local ok, err = pcall(callback)
        if not ok then
            notify(("Button '%s': %s"):format(title, tostring(err)))
        end
    end

    local function press()
        if destroyed or data.disabled or data.loading then return end
        fireCallback()
    end

    connect(clickArea.Activated, press)

    connect(clickArea.MouseEnter, function()
        if usingTouch() then return end
        hovering = true
        render(true)
    end)

    connect(clickArea.MouseLeave, function()
        hovering = false
        pressed = false
        render(true)
    end)

    connect(clickArea.InputBegan, function(input)
        if destroyed or data.disabled or data.loading then return end
        if isPointerInput(input) then
            pressed = true
            render(true)
        end
    end)

    connect(userInputService.InputEnded, function(input)
        if destroyed or not pressed then return end
        if isPointerInput(input) then
            pressed = false
            render(true)
        end
    end)

    connect(textLayout:GetPropertyChangedSignal("AbsoluteContentSize"), resizeContainer)

    if description ~= "" then
        createDescription(description)
    end

    applyAll(false)

    function data:SetDisabled(value)
        if destroyed then return end
        data.disabled = value == true
        if data.disabled then pressed = false end
        applyAll(true)
    end

    function data:SetLoading(value)
        if destroyed then return end
        data.loading = value == true
        if data.loading then pressed = false end
        applyAll(true)
    end

    function data:IsLoading()
        return data.loading
    end

    function data:SetVariant(value)
        if destroyed then return end
        data.variant = pickKey(VARIANTS, value, data.variant)
        applyAll(true)
    end

    function data:SetSize(value)
        if destroyed then return end
        data.size = pickKey(SIZES, value, data.size)
        applyAll(false)
    end

    function data:SetTitle(newTitle)
        if destroyed then return end
        title = tostring(newTitle or "")
        label.Text = displayTitle()
    end

    function data:SetDescription(newDesc)
        if destroyed then return end
        newDesc = tostring(newDesc or "")
        if newDesc == "" then
            if descLabel then
                descLabel:Destroy()
                descLabel = nil
            end
            resizeContainer()
            return
        end
        if not descLabel then
            createDescription(newDesc)
        else
            descLabel.Text = breakLongWords(newDesc, WORD_MAX)
        end
        resizeContainer()
    end

    function data:Fire()
        press()
    end

    function data:Destroy()
        if destroyed then return end
        destroyed = true
        stopSpinner()
        for _, conn in ipairs(connections) do
            conn:Disconnect()
        end
        table.clear(connections)
        container:Destroy()
    end

    return data
end)