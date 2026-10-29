-- // Colorpick
Elements.Register("ColorPicker", function(section, options)
    options = type(options) == "table" and options or {}

    local COLORS = {
        TextActive = Color3.fromRGB(240, 240, 240),
        TextInactive = Color3.fromRGB(165, 165, 165),
        TextDisabled = Color3.fromRGB(85, 85, 85),
        Line = Color3.fromRGB(55, 55, 55),
        Field = Color3.fromRGB(34, 34, 34),
        FieldAlt = Color3.fromRGB(42, 42, 42),
        MenuBackground = Color3.fromRGB(28, 28, 28),
        SectionBackground = Color3.fromRGB(34, 34, 34),
        DescriptionText = Color3.fromRGB(125, 125, 125),
        Accent = Color3.fromRGB(240, 240, 240),
    }

    local TITLE_TEXT_SIZE = 13
    local DESCRIPTION_TEXT_SIZE = 11
    local LABEL_TEXT_SIZE = 11
    local BASE_ROW_H = 34
    local FIELD_WIDTH = 96
    local FIELD_HEIGHT = 22
    local OVERLAY_ZINDEX = 1000
    local WORD_MAX = 30
    local MAP_HEIGHT = 100
    local HUE_HEIGHT = 14
    local ALPHA_HEIGHT = 14
    local OVERLAY_PADDING = 10
    local OVERLAY_GAP = 10
    local OVERLAY_HEIGHT = (OVERLAY_PADDING * 2) + MAP_HEIGHT + HUE_HEIGHT + ALPHA_HEIGHT + (OVERLAY_GAP * 2)
    local TITLE_Y = 3
    local TITLE_H = 15
    local DESC_Y = TITLE_Y + TITLE_H + 1
    local rowH = BASE_ROW_H
    local applyHeader

    local function overlayOffset()
        return rowH + 4
    end

    local function totalOpen()
        return overlayOffset() + OVERLAY_HEIGHT + 4
    end
    local NOTIFY_TITLE = "Sistema"

    local tweenService = TweenService or game:GetService("TweenService")
    local userInputService = UserInputService or game:GetService("UserInputService")
    local guiService = game:GetService("GuiService")
    local fontBold = FONT_BOLD or Enum.Font.SourceSansSemibold
    local fontRegular = FONT or Enum.Font.SourceSans

    local TI_OPEN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local TI_CLOSE = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

    local connections = {}
    local destroyed = false
    local activeTweens = {}
    local tweenDoneConn
    local lockedScroll
    local lockedScrollWas = true
    local pointerOffsets = {}

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

    local function rgbToHex(color)
        local r = math.round(color.R * 255)
        local g = math.round(color.G * 255)
        local b = math.round(color.B * 255)
        return string.format("%02X%02X%02X", r, g, b)
    end

    local function getContrastColor(color, transparency)
        transparency = transparency or 0
        local bg = 0.12
        local r = color.R * (1 - transparency) + bg * transparency
        local g = color.G * (1 - transparency) + bg * transparency
        local b = color.B * (1 - transparency) + bg * transparency
        local luminance = (0.299 * r) + (0.587 * g) + (0.114 * b)
        if luminance > 0.55 then
            return Color3.fromRGB(20, 20, 20)
        end
        return Color3.fromRGB(255, 255, 255)
    end

    local function isInside(guiObject, pos)
        local p = guiObject.AbsolutePosition
        local s = guiObject.AbsoluteSize
        return pos.X >= p.X and pos.X <= p.X + s.X and pos.Y >= p.Y and pos.Y <= p.Y + s.Y
    end

    local function isPointerInput(input)
        return input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
    end

    local function pointerKey(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            return "touch"
        end
        return "mouse"
    end

    local title = tostring(options.title or options.Name or "Color")
    local description = tostring(options.description or "")
    local defaultColor = options.default or options.Default
    local defaultTransparency = tonumber(options.transparency) or 0
    local disabled = options.disabled == true
    local callback = options.callback or options.Callback

    if typeof(defaultColor) ~= "Color3" then
        defaultColor = Color3.fromRGB(68, 120, 255)
    end

    defaultTransparency = math.clamp(defaultTransparency, 0, 1)

    if type(callback) ~= "function" then
        callback = function() end
    end

    local hasDescription = description ~= ""

    local data = {
        disabled = disabled,
        opened = false,
        value = defaultColor,
        transparency = defaultTransparency,
    }

    local hue, sat, vib = Color3.toHSV(data.value)

    local container = Instance.new("Frame")
    container.Name = title .. "_ColorPicker"
    container.Size = UDim2.new(1, 0, 0, rowH)
    container.BackgroundTransparency = 1
    container.ClipsDescendants = false
    container.Parent = section.frame

    local textContainer = Instance.new("Frame")
    textContainer.Name = "TextContainer"
    textContainer.Size = UDim2.new(1, -(FIELD_WIDTH + 16), 0, rowH)
    textContainer.BackgroundTransparency = 1
    textContainer.Parent = container

    local label = Instance.new("TextLabel")
    label.Name = "Title"
    label.Size = UDim2.new(1, 0, 0, TITLE_H)
    label.BackgroundTransparency = 1
    label.Text = title
    label.TextColor3 = disabled and COLORS.TextDisabled or COLORS.TextActive
    label.TextSize = TITLE_TEXT_SIZE
    label.Font = fontBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = textContainer

    local descLabel

    local function layoutText()
        if descLabel then
            label.Position = UDim2.new(0, 0, 0, TITLE_Y)
            label.AnchorPoint = Vector2.new(0, 0)
        else
            label.Position = UDim2.new(0, 0, 0.5, 0)
            label.AnchorPoint = Vector2.new(0, 0.5)
        end
    end

    local function createDescription(text)
        descLabel = Instance.new("TextLabel")
        descLabel.Name = "Desc"
        descLabel.Size = UDim2.new(1, 0, 0, 0)
        descLabel.Position = UDim2.new(0, 0, 0, DESC_Y)
        descLabel.AutomaticSize = Enum.AutomaticSize.Y
        descLabel.BackgroundTransparency = 1
        descLabel.Text = breakLongWords(text, WORD_MAX)
        descLabel.TextColor3 = COLORS.DescriptionText
        descLabel.TextSize = DESCRIPTION_TEXT_SIZE
        descLabel.Font = fontRegular
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextYAlignment = Enum.TextYAlignment.Top
        descLabel.TextWrapped = true
        descLabel.LineHeight = 1.1
        descLabel.Parent = textContainer
        connect(descLabel:GetPropertyChangedSignal("AbsoluteSize"), function()
            if applyHeader then
                applyHeader()
            end
        end)
    end

    if hasDescription then
        createDescription(description)
    end

    layoutText()

    local field = Instance.new("TextButton")
    field.Name = "Field"
    field.Size = UDim2.new(0, FIELD_WIDTH, 0, FIELD_HEIGHT)
    field.Position = UDim2.new(1, 0, 0, rowH / 2)
    field.AnchorPoint = Vector2.new(1, 0.5)
    field.BackgroundColor3 = COLORS.Field
    field.BorderSizePixel = 0
    field.Text = ""
    field.AutoButtonColor = false
    field.Selectable = false
    field.Active = not disabled
    field.ZIndex = 10
    field.Parent = container

    local fieldCorner = Instance.new("UICorner")
    fieldCorner.CornerRadius = UDim.new(0, 6)
    fieldCorner.Parent = field

    local fieldStroke = Instance.new("UIStroke")
    fieldStroke.Color = COLORS.Line
    fieldStroke.Thickness = 1
    fieldStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    fieldStroke.Parent = field

    local checkerBoard = Instance.new("ImageLabel")
    checkerBoard.Name = "CheckerBoard"
    checkerBoard.Size = UDim2.new(1, 0, 1, 0)
    checkerBoard.BackgroundTransparency = 1
    checkerBoard.Image = "rbxasset://textures/Checkerboard.png"
    checkerBoard.ImageTransparency = 0.45
    checkerBoard.ScaleType = Enum.ScaleType.Tile
    checkerBoard.TileSize = UDim2.fromOffset(8, 8)
    checkerBoard.ZIndex = 9
    checkerBoard.Parent = field

    local checkerCorner = Instance.new("UICorner")
    checkerCorner.CornerRadius = UDim.new(0, 6)
    checkerCorner.Parent = checkerBoard

    local fieldColor = Instance.new("Frame")
    fieldColor.Name = "FieldColor"
    fieldColor.Size = UDim2.new(1, 0, 1, 0)
    fieldColor.BackgroundColor3 = data.value
    fieldColor.BackgroundTransparency = data.transparency
    fieldColor.BorderSizePixel = 0
    fieldColor.ZIndex = 10
    fieldColor.Parent = field

    local fieldColorCorner = Instance.new("UICorner")
    fieldColorCorner.CornerRadius = UDim.new(0, 6)
    fieldColorCorner.Parent = fieldColor

    local fieldLabel = Instance.new("TextLabel")
    fieldLabel.Name = "FieldLabel"
    fieldLabel.Size = UDim2.new(1, 0, 1, 0)
    fieldLabel.BackgroundTransparency = 1
    fieldLabel.Text = rgbToHex(data.value)
    fieldLabel.TextColor3 = getContrastColor(data.value, data.transparency)
    fieldLabel.TextSize = LABEL_TEXT_SIZE
    fieldLabel.Font = fontBold
    fieldLabel.ZIndex = 11
    fieldLabel.Parent = fieldColor

    local overlayCanvas = Instance.new("Frame")
    overlayCanvas.Name = title .. "_PickerOverlay"
    overlayCanvas.Size = UDim2.new(1, 0, 0, 0)
    overlayCanvas.Position = UDim2.new(0, 0, 0, overlayOffset())
    overlayCanvas.AnchorPoint = Vector2.new(0, 0)
    overlayCanvas.BackgroundColor3 = COLORS.MenuBackground
    overlayCanvas.BorderSizePixel = 0
    overlayCanvas.ClipsDescendants = true
    overlayCanvas.Visible = false
    overlayCanvas.ZIndex = OVERLAY_ZINDEX
    overlayCanvas.Parent = container

    local overlayCorner = Instance.new("UICorner")
    overlayCorner.CornerRadius = UDim.new(0, 8)
    overlayCorner.Parent = overlayCanvas

    local overlayStroke = Instance.new("UIStroke")
    overlayStroke.Color = COLORS.Line
    overlayStroke.Thickness = 1
    overlayStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    overlayStroke.Parent = overlayCanvas

    local overlayPadding = Instance.new("UIPadding")
    overlayPadding.PaddingTop = UDim.new(0, OVERLAY_PADDING)
    overlayPadding.PaddingBottom = UDim.new(0, OVERLAY_PADDING)
    overlayPadding.PaddingLeft = UDim.new(0, OVERLAY_PADDING)
    overlayPadding.PaddingRight = UDim.new(0, OVERLAY_PADDING)
    overlayPadding.Parent = overlayCanvas

    local pickerLayout = Instance.new("UIListLayout")
    pickerLayout.Padding = UDim.new(0, OVERLAY_GAP)
    pickerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pickerLayout.Parent = overlayCanvas

    local satVibMap = Instance.new("Frame")
    satVibMap.Name = "SatVibMap"
    satVibMap.Size = UDim2.new(1, 0, 0, MAP_HEIGHT)
    satVibMap.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
    satVibMap.BorderSizePixel = 0
    satVibMap.LayoutOrder = 1
    satVibMap.ZIndex = OVERLAY_ZINDEX + 1
    satVibMap.Parent = overlayCanvas

    local satVibCorner = Instance.new("UICorner")
    satVibCorner.CornerRadius = UDim.new(0, 6)
    satVibCorner.Parent = satVibMap

    local satVibStroke = Instance.new("UIStroke")
    satVibStroke.Color = COLORS.Line
    satVibStroke.Thickness = 1
    satVibStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    satVibStroke.Parent = satVibMap

    local whiteLayer = Instance.new("Frame")
    whiteLayer.Name = "WhiteLayer"
    whiteLayer.Size = UDim2.new(1, 0, 1, 0)
    whiteLayer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    whiteLayer.BorderSizePixel = 0
    whiteLayer.ZIndex = OVERLAY_ZINDEX + 1
    whiteLayer.Parent = satVibMap

    local whiteCorner = Instance.new("UICorner")
    whiteCorner.CornerRadius = UDim.new(0, 6)
    whiteCorner.Parent = whiteLayer

    local whiteGradient = Instance.new("UIGradient")
    whiteGradient.Rotation = 0
    whiteGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    whiteGradient.Parent = whiteLayer

    local blackLayer = Instance.new("Frame")
    blackLayer.Name = "BlackLayer"
    blackLayer.Size = UDim2.new(1, 0, 1, 0)
    blackLayer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    blackLayer.BorderSizePixel = 0
    blackLayer.ZIndex = OVERLAY_ZINDEX + 1
    blackLayer.Parent = satVibMap

    local blackCorner = Instance.new("UICorner")
    blackCorner.CornerRadius = UDim.new(0, 6)
    blackCorner.Parent = blackLayer

    local blackGradient = Instance.new("UIGradient")
    blackGradient.Rotation = 90
    blackGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0),
    })
    blackGradient.Parent = blackLayer

    local satCursorOuter = Instance.new("Frame")
    satCursorOuter.Name = "SatCursorOuter"
    satCursorOuter.Size = UDim2.fromOffset(16, 16)
    satCursorOuter.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    satCursorOuter.BackgroundTransparency = 0.35
    satCursorOuter.BorderSizePixel = 0
    satCursorOuter.ZIndex = OVERLAY_ZINDEX + 2
    satCursorOuter.Parent = satVibMap

    local satCursorOuterCorner = Instance.new("UICorner")
    satCursorOuterCorner.CornerRadius = UDim.new(1, 0)
    satCursorOuterCorner.Parent = satCursorOuter

    local satCursor = Instance.new("Frame")
    satCursor.Name = "SatCursor"
    satCursor.Size = UDim2.fromOffset(12, 12)
    satCursor.Position = UDim2.new(0.5, 0, 0.5, 0)
    satCursor.AnchorPoint = Vector2.new(0.5, 0.5)
    satCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    satCursor.BorderSizePixel = 0
    satCursor.ZIndex = OVERLAY_ZINDEX + 3
    satCursor.Parent = satCursorOuter

    local satCursorCorner = Instance.new("UICorner")
    satCursorCorner.CornerRadius = UDim.new(1, 0)
    satCursorCorner.Parent = satCursor

    local satCursorInnerStroke = Instance.new("UIStroke")
    satCursorInnerStroke.Color = Color3.fromRGB(0, 0, 0)
    satCursorInnerStroke.Thickness = 1
    satCursorInnerStroke.Transparency = 0.5
    satCursorInnerStroke.Parent = satCursor

    local hueSlider = Instance.new("Frame")
    hueSlider.Name = "HueSlider"
    hueSlider.Size = UDim2.new(1, 0, 0, HUE_HEIGHT)
    hueSlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    hueSlider.LayoutOrder = 2
    hueSlider.BorderSizePixel = 0
    hueSlider.ZIndex = OVERLAY_ZINDEX + 1
    hueSlider.Parent = overlayCanvas

    local hueCorner = Instance.new("UICorner")
    hueCorner.CornerRadius = UDim.new(0, 6)
    hueCorner.Parent = hueSlider

    local hueStroke = Instance.new("UIStroke")
    hueStroke.Color = COLORS.Line
    hueStroke.Thickness = 1
    hueStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    hueStroke.Parent = hueSlider

    local hueSequence = {}
    for i = 0, 10 do
        local t = i / 10
        hueSequence[#hueSequence + 1] = ColorSequenceKeypoint.new(t, Color3.fromHSV(math.min(t, 0.999), 1, 1))
    end

    local hueGradient = Instance.new("UIGradient")
    hueGradient.Color = ColorSequence.new(hueSequence)
    hueGradient.Rotation = 0
    hueGradient.Parent = hueSlider

    local hueCursor = Instance.new("Frame")
    hueCursor.Name = "HueCursor"
    hueCursor.Size = UDim2.fromOffset(6, HUE_HEIGHT + 4)
    hueCursor.Position = UDim2.new(0, 0, 0.5, 0)
    hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
    hueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    hueCursor.BorderSizePixel = 0
    hueCursor.ZIndex = OVERLAY_ZINDEX + 2
    hueCursor.Parent = hueSlider

    local hueCursorCorner = Instance.new("UICorner")
    hueCursorCorner.CornerRadius = UDim.new(0, 3)
    hueCursorCorner.Parent = hueCursor

    local hueCursorStroke = Instance.new("UIStroke")
    hueCursorStroke.Color = Color3.fromRGB(0, 0, 0)
    hueCursorStroke.Thickness = 1.5
    hueCursorStroke.Transparency = 0.3
    hueCursorStroke.Parent = hueCursor

    local alphaSlider = Instance.new("Frame")
    alphaSlider.Name = "AlphaSlider"
    alphaSlider.Size = UDim2.new(1, 0, 0, ALPHA_HEIGHT)
    alphaSlider.BackgroundColor3 = COLORS.Field
    alphaSlider.LayoutOrder = 3
    alphaSlider.BorderSizePixel = 0
    alphaSlider.ZIndex = OVERLAY_ZINDEX + 1
    alphaSlider.Parent = overlayCanvas

    local alphaCorner = Instance.new("UICorner")
    alphaCorner.CornerRadius = UDim.new(0, 6)
    alphaCorner.Parent = alphaSlider

    local alphaStroke = Instance.new("UIStroke")
    alphaStroke.Color = COLORS.Line
    alphaStroke.Thickness = 1
    alphaStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    alphaStroke.Parent = alphaSlider

    local alphaChecker = Instance.new("ImageLabel")
    alphaChecker.Name = "AlphaChecker"
    alphaChecker.Size = UDim2.new(1, 0, 1, 0)
    alphaChecker.BackgroundTransparency = 1
    alphaChecker.Image = "rbxasset://textures/Checkerboard.png"
    alphaChecker.ImageTransparency = 0.45
    alphaChecker.ScaleType = Enum.ScaleType.Tile
    alphaChecker.TileSize = UDim2.fromOffset(8, 8)
    alphaChecker.ZIndex = OVERLAY_ZINDEX + 1
    alphaChecker.Parent = alphaSlider

    local alphaCheckerCorner = Instance.new("UICorner")
    alphaCheckerCorner.CornerRadius = UDim.new(0, 6)
    alphaCheckerCorner.Parent = alphaChecker

    local alphaFill = Instance.new("Frame")
    alphaFill.Name = "AlphaFill"
    alphaFill.Size = UDim2.new(1, 0, 1, 0)
    alphaFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    alphaFill.BorderSizePixel = 0
    alphaFill.ZIndex = OVERLAY_ZINDEX + 1
    alphaFill.Parent = alphaSlider

    local alphaFillCorner = Instance.new("UICorner")
    alphaFillCorner.CornerRadius = UDim.new(0, 6)
    alphaFillCorner.Parent = alphaFill

    local alphaGradient = Instance.new("UIGradient")
    alphaGradient.Rotation = 0
    alphaGradient.Color = ColorSequence.new(data.value)
    alphaGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    alphaGradient.Parent = alphaFill

    local alphaCursor = Instance.new("Frame")
    alphaCursor.Name = "AlphaCursor"
    alphaCursor.Size = UDim2.fromOffset(6, ALPHA_HEIGHT + 4)
    alphaCursor.Position = UDim2.new(0, 0, 0.5, 0)
    alphaCursor.AnchorPoint = Vector2.new(0.5, 0.5)
    alphaCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    alphaCursor.BorderSizePixel = 0
    alphaCursor.ZIndex = OVERLAY_ZINDEX + 2
    alphaCursor.Parent = alphaSlider

    local alphaCursorCorner = Instance.new("UICorner")
    alphaCursorCorner.CornerRadius = UDim.new(0, 3)
    alphaCursorCorner.Parent = alphaCursor

    local alphaCursorStroke = Instance.new("UIStroke")
    alphaCursorStroke.Color = Color3.fromRGB(0, 0, 0)
    alphaCursorStroke.Thickness = 1.5
    alphaCursorStroke.Transparency = 0.3
    alphaCursorStroke.Parent = alphaCursor

    local function fireCallback()
        local ok, err = pcall(callback, data.value, data.transparency)
        if not ok then
            warnf("callback error: " .. tostring(err))
        end
    end

    local function updateFieldVisuals()
        fieldColor.BackgroundColor3 = data.value
        fieldColor.BackgroundTransparency = data.transparency
        fieldLabel.Text = rgbToHex(data.value)
        fieldLabel.TextColor3 = getContrastColor(data.value, data.transparency)
        alphaGradient.Color = ColorSequence.new(data.value)
        field.BackgroundTransparency = data.disabled and 0.5 or 0
    end

    local function display()
        if destroyed then return end
        satVibMap.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        satCursorOuter.Position = UDim2.new(sat, -8, 1 - vib, -8)
        hueCursor.Position = UDim2.new(hue, 0, 0.5, 0)
        alphaCursor.Position = UDim2.new(data.transparency, 0, 0.5, 0)

        data.value = Color3.fromHSV(hue, sat, vib)
        updateFieldVisuals()
    end

    display()

    local dragging = nil
    local dragInput = nil
    local openedAt = 0
    local dragEndedAt = 0

    local function lockScroll(lock)
        if lock then
            if lockedScroll then return end
            local parent = container:FindFirstAncestorWhichIsA("ScrollingFrame")
            if parent then
                lockedScroll = parent
                lockedScrollWas = parent.ScrollingEnabled
                parent.ScrollingEnabled = false
            end
        elseif lockedScroll then
            lockedScroll.ScrollingEnabled = lockedScrollWas
            lockedScroll = nil
        end
    end

    local function defaultOffset()
        local screenGui = container:FindFirstAncestorWhichIsA("ScreenGui")
        if screenGui and screenGui.IgnoreGuiInset then
            return guiService:GetGuiInset().Y
        end
        return 0
    end

    local function calibrate(gui, input)
        local key = pointerKey(input)
        local pos = input.Position
        local cached = pointerOffsets[key]
        if cached and isInside(gui, Vector2.new(pos.X, pos.Y + cached)) then
            return
        end
        local inset = guiService:GetGuiInset().Y
        local candidates = { cached or defaultOffset(), defaultOffset(), 0, inset, -inset }
        for _, offset in ipairs(candidates) do
            if isInside(gui, Vector2.new(pos.X, pos.Y + offset)) then
                pointerOffsets[key] = offset
                return
            end
        end
        pointerOffsets[key] = cached or defaultOffset()
    end

    local function toGuiPosition(input)
        local key = pointerKey(input)
        local offset = pointerOffsets[key]
        if offset == nil then
            offset = defaultOffset()
        end
        return Vector2.new(input.Position.X, input.Position.Y + offset)
    end

    local function updateFromInput(kind, pos)
        if kind == "satvib" then
            local minX = satVibMap.AbsolutePosition.X
            local maxX = minX + satVibMap.AbsoluteSize.X
            local minY = satVibMap.AbsolutePosition.Y
            local maxY = minY + satVibMap.AbsoluteSize.Y
            local mouseX = math.clamp(pos.X, minX, maxX)
            local mouseY = math.clamp(pos.Y, minY, maxY)
            if maxX > minX then sat = (mouseX - minX) / (maxX - minX) end
            if maxY > minY then vib = 1 - ((mouseY - minY) / (maxY - minY)) end
        elseif kind == "hue" then
            local minX = hueSlider.AbsolutePosition.X
            local maxX = minX + hueSlider.AbsoluteSize.X
            local mouseX = math.clamp(pos.X, minX, maxX)
            if maxX > minX then hue = (mouseX - minX) / (maxX - minX) end
        elseif kind == "alpha" then
            local minX = alphaSlider.AbsolutePosition.X
            local maxX = minX + alphaSlider.AbsoluteSize.X
            local mouseX = math.clamp(pos.X, minX, maxX)
            if maxX > minX then data.transparency = (mouseX - minX) / (maxX - minX) end
        end
        display()
        fireCallback()
    end

    local function stopDrag()
        if not dragging then return end
        dragging = nil
        dragInput = nil
        dragEndedAt = os.clock()
        lockScroll(false)
    end

    local function bindDrag(gui, kind)
        connect(gui.InputBegan, function(input)
            if destroyed or data.disabled then return end
            if isPointerInput(input) then
                calibrate(gui, input)
                dragging = kind
                dragInput = input
                lockScroll(true)
                updateFromInput(kind, toGuiPosition(input))
            end
        end)
    end

    bindDrag(satVibMap, "satvib")
    bindDrag(hueSlider, "hue")
    bindDrag(alphaSlider, "alpha")

    connect(userInputService.InputChanged, function(input)
        if destroyed or not dragging or not dragInput then return end
        if dragInput.UserInputType == Enum.UserInputType.Touch then
            if input ~= dragInput then return end
        elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end
        updateFromInput(dragging, toGuiPosition(input))
    end)

    connect(userInputService.InputEnded, function(input)
        if not dragging or not dragInput then return end
        if input == dragInput
        or (dragInput.UserInputType == Enum.UserInputType.MouseButton1
            and input.UserInputType == Enum.UserInputType.MouseButton1) then
            stopDrag()
        end
    end)

    local function disconnectTweens()
        if tweenDoneConn then
            tweenDoneConn:Disconnect()
            tweenDoneConn = nil
        end
        for _, tween in ipairs(activeTweens) do
            tween:Cancel()
        end
        table.clear(activeTweens)
    end

    local function animateMenu(open)
        disconnectTweens()

        local info = open and TI_OPEN or TI_CLOSE
        local overlayHeight = open and OVERLAY_HEIGHT or 0
        local containerHeight = open and totalOpen() or rowH

        local overlayTween = tweenService:Create(overlayCanvas, info, {
            Size = UDim2.new(1, 0, 0, overlayHeight),
        })
        local containerTween = tweenService:Create(container, info, {
            Size = UDim2.new(1, 0, 0, containerHeight),
        })

        activeTweens = { overlayTween, containerTween }

        if not open then
            tweenDoneConn = overlayTween.Completed:Connect(function()
                if not data.opened and not destroyed then
                    overlayCanvas.Visible = false
                end
                if tweenDoneConn then
                    tweenDoneConn:Disconnect()
                    tweenDoneConn = nil
                end
            end)
        end

        overlayTween:Play()
        containerTween:Play()
    end

    local closeMenu

    local function openMenu()
        if destroyed or data.disabled or data.opened then return end
        data.opened = true
        openedAt = os.clock()

        overlayCanvas.Visible = true
        animateMenu(true)
    end

    closeMenu = function()
        if not data.opened then return end
        data.opened = false
        stopDrag()
        animateMenu(false)
    end

    applyHeader = function()
        if destroyed then return end
        local h = BASE_ROW_H
        if descLabel then
            h = math.max(BASE_ROW_H, DESC_Y + descLabel.AbsoluteSize.Y + 6)
        end
        if h == rowH then return end
        rowH = h
        textContainer.Size = UDim2.new(1, -(FIELD_WIDTH + 16), 0, rowH)
        field.Position = UDim2.new(1, 0, 0, rowH / 2)
        overlayCanvas.Position = UDim2.new(0, 0, 0, overlayOffset())
        disconnectTweens()
        if data.opened then
            container.Size = UDim2.new(1, 0, 0, totalOpen())
            overlayCanvas.Size = UDim2.new(1, 0, 0, OVERLAY_HEIGHT)
        else
            container.Size = UDim2.new(1, 0, 0, rowH)
            overlayCanvas.Size = UDim2.new(1, 0, 0, 0)
            overlayCanvas.Visible = false
        end
    end

    connect(field.MouseButton1Click, function()
        if data.opened then
            closeMenu()
        else
            openMenu()
        end
    end)

    connect(userInputService.InputBegan, function(input)
        if destroyed or not data.opened or dragging then return end
        if os.clock() - openedAt < 0.1 then return end
        if os.clock() - dragEndedAt < 0.1 then return end
        if not isPointerInput(input) then return end

        local pos = toGuiPosition(input)
        if not isInside(overlayCanvas, pos) and not isInside(field, pos) then
            closeMenu()
        end
    end)

    local function applyDisabledVisual()
        field.Active = not data.disabled
        label.TextColor3 = data.disabled and COLORS.TextDisabled or COLORS.TextActive
        field.BackgroundTransparency = data.disabled and 0.5 or 0
        fieldColor.BackgroundTransparency = data.disabled and math.clamp(data.transparency + 0.4, 0, 1) or data.transparency
    end

    applyDisabledVisual()

    function data:Set(color, transparency)
        if destroyed then return end
        if typeof(color) ~= "Color3" then
            warnf("Set() esperava Color3, recebeu " .. typeof(color))
            return
        end
        transparency = math.clamp(tonumber(transparency) or 0, 0, 1)
        if data.value == color and data.transparency == transparency then return end
        data.transparency = transparency
        local newHue, newSat, newVib = Color3.toHSV(color)
        if newSat > 0 and newVib > 0 then
            hue = newHue
        end
        sat, vib = newSat, newVib
        display()
        data.value = color
        updateFieldVisuals()
        fireCallback()
    end

    function data:Get()
        return data.value
    end

    function data:GetHex()
        return rgbToHex(data.value)
    end

    function data:GetTransparency()
        return data.transparency
    end

    function data:SetCallback(newCallback)
        if type(newCallback) ~= "function" then
            warnf("SetCallback() esperava function")
            return
        end
        callback = newCallback
    end

    function data:SetDisabled(value)
        if destroyed then return end
        data.disabled = value == true
        applyDisabledVisual()
        if data.disabled and data.opened then
            closeMenu()
        end
    end

    function data:SetTitle(newTitle)
        if destroyed then return end
        label.Text = tostring(newTitle or "")
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
            descLabel.Text = breakLongWords(newDesc, WORD_MAX)
        end
        layoutText()
        applyHeader()
    end

    function data:Open()
        openMenu()
    end

    function data:Close()
        closeMenu()
    end

    function data:Destroy()
        if destroyed then return end
        destroyed = true
        stopDrag()
        lockScroll(false)
        disconnectTweens()
        for _, conn in ipairs(connections) do
            conn:Disconnect()
        end
        table.clear(connections)
        overlayCanvas:Destroy()
        container:Destroy()
    end

    return data
end)