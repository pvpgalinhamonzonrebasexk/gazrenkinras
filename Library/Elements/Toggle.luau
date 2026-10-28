-- // CheckBox
Elements.Register("Checkbox", function(section, options)
    options = type(options) == "table" and options or {}

    local COLORS = {
        TrackOn = Color3.fromRGB(250, 250, 250),
        TrackOff = Color3.fromRGB(39, 39, 42),
        TrackDisabled = Color3.fromRGB(28, 28, 30),
        KnobOn = Color3.fromRGB(24, 24, 27),
        KnobOff = Color3.fromRGB(250, 250, 250),
        KnobDisabled = Color3.fromRGB(90, 90, 96),
        TextOn = Color3.fromRGB(250, 250, 250),
        TextOff = Color3.fromRGB(161, 161, 170),
        TextDisabled = Color3.fromRGB(82, 82, 91),
        Description = Color3.fromRGB(113, 113, 122),
        KeyBg = Color3.fromRGB(30, 30, 32),
        KeyBorder = Color3.fromRGB(55, 55, 60),
        KeyText = Color3.fromRGB(180, 180, 190),
        KeyListening = Color3.fromRGB(50, 50, 56),
        KeyListenText = Color3.fromRGB(220, 220, 255),
    }

    local TITLE_SIZE = 13
    local DESC_SIZE = 11
    local KEY_SIZE = 11
    local SWITCH_W = 44
    local SWITCH_H = 24
    local KNOB = 18
    local KNOB_PAD = 3
    local SIDE_PAD = 10
    local PILL_W = 46
    local PILL_H = 22
    local WORD_MAX = 20
    local BASE_H = 40
    local NOTIFY_TITLE = "Sistema"

    local userInputService = UserInputService or game:GetService("UserInputService")
    local tweenService = game:GetService("TweenService")
    local fontBold = FONT_BOLD or Enum.Font.SourceSansBold
    local fontRegular = FONT or Enum.Font.SourceSans
    local tweenInfo = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local isDesktop = userInputService.KeyboardEnabled

    local connections = {}
    local destroyed = false
    local listeningConnection
    local listenStartedAt = 0

    local function connect(signal, fn)
        local conn = signal:Connect(fn)
        connections[#connections + 1] = conn
        return conn
    end

    local function notify(msg, duration)
        pcall(function()
            Notify({ Title = NOTIFY_TITLE, Description = msg, Duration = duration })
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

    local KEY_NAMES = {
        [Enum.KeyCode.LeftShift] = "LShift", [Enum.KeyCode.RightShift] = "RShift",
        [Enum.KeyCode.LeftControl] = "LCtrl", [Enum.KeyCode.RightControl] = "RCtrl",
        [Enum.KeyCode.LeftAlt] = "LAlt", [Enum.KeyCode.RightAlt] = "RAlt",
        [Enum.KeyCode.CapsLock] = "Caps", [Enum.KeyCode.Return] = "Enter",
        [Enum.KeyCode.Backspace] = "Back", [Enum.KeyCode.Delete] = "Del",
        [Enum.KeyCode.Insert] = "Ins", [Enum.KeyCode.PageUp] = "PgUp",
        [Enum.KeyCode.PageDown] = "PgDn", [Enum.KeyCode.Escape] = "Esc",
        [Enum.KeyCode.Zero] = "0", [Enum.KeyCode.One] = "1",
        [Enum.KeyCode.Two] = "2", [Enum.KeyCode.Three] = "3",
        [Enum.KeyCode.Four] = "4", [Enum.KeyCode.Five] = "5",
        [Enum.KeyCode.Six] = "6", [Enum.KeyCode.Seven] = "7",
        [Enum.KeyCode.Eight] = "8", [Enum.KeyCode.Nine] = "9",
        [Enum.KeyCode.KeypadZero] = "Num0", [Enum.KeyCode.KeypadOne] = "Num1",
        [Enum.KeyCode.KeypadTwo] = "Num2", [Enum.KeyCode.KeypadThree] = "Num3",
        [Enum.KeyCode.KeypadFour] = "Num4", [Enum.KeyCode.KeypadFive] = "Num5",
        [Enum.KeyCode.KeypadSix] = "Num6", [Enum.KeyCode.KeypadSeven] = "Num7",
        [Enum.KeyCode.KeypadEight] = "Num8", [Enum.KeyCode.KeypadNine] = "Num9",
        [Enum.UserInputType.MouseButton1] = "M1",
        [Enum.UserInputType.MouseButton2] = "M2",
        [Enum.UserInputType.MouseButton3] = "M3",
    }

    local function getKeyName(binding)
        if not binding then return "None" end
        local name = KEY_NAMES[binding]
        if name then return name end
        local ok, result = pcall(function() return binding.Name end)
        if ok and type(result) == "string" and result ~= "" then
            return result
        end
        return "?"
    end

    local function isValidBinding(binding)
        if typeof(binding) ~= "EnumItem" then return false end
        return binding.EnumType == Enum.KeyCode or binding.EnumType == Enum.UserInputType
    end

    local function normalizeBinding(binding)
        if typeof(binding) == "EnumItem" then
            return binding
        end
        if type(binding) == "string" and binding ~= "" then
            local candidates = { binding, binding:upper(), binding:sub(1, 1):upper() .. binding:sub(2) }
            for _, name in ipairs(candidates) do
                local ok, res = pcall(function() return Enum.KeyCode[name] end)
                if ok and res then return res end
                ok, res = pcall(function() return Enum.UserInputType[name] end)
                if ok and res then return res end
            end
        end
        return nil
    end

    local function matchInput(binding, input)
        if typeof(binding) ~= "EnumItem" then return false end
        if binding.EnumType == Enum.KeyCode then
            return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == binding
        elseif binding.EnumType == Enum.UserInputType then
            return input.UserInputType == binding
        end
        return false
    end

    local title = tostring(options.title or options.Name or "Checkbox")
    local description = tostring(options.description or "")
    local default = (options.default or options.Default) == true
    local disabled = options.disabled == true
    local callback = options.callback or options.Callback
    local keybind = normalizeBinding(options.keybind)
    local keybindCb = options.keybindCallback

    if type(callback) ~= "function" then
        callback = function() end
    end

    if type(keybindCb) ~= "function" then
        keybindCb = nil
    end

    if keybind ~= nil and not isValidBinding(keybind) then
        keybind = nil
    end

    local hasKeybind = options.keybind ~= nil and isDesktop

    local data = {
        state = default,
        disabled = disabled,
        keybind = keybind,
        listening = false,
    }

    local rightReserve = SWITCH_W + SIDE_PAD + 10
    if hasKeybind then
        rightReserve = rightReserve + PILL_W + 8
    end

    local container = Instance.new("Frame")
    container.Name = title .. "_Checkbox"
    container.Size = UDim2.new(1, 0, 0, BASE_H)
    container.BackgroundTransparency = 1
    container.Parent = section.frame

    local rowButton = Instance.new("TextButton")
    rowButton.Name = "RowButton"
    rowButton.Size = UDim2.new(1, 0, 1, 0)
    rowButton.BackgroundTransparency = 1
    rowButton.Text = ""
    rowButton.AutoButtonColor = false
    rowButton.Selectable = false
    rowButton.ZIndex = 1
    rowButton.Parent = container

    local textFrame = Instance.new("Frame")
    textFrame.Name = "TextFrame"
    textFrame.Size = UDim2.new(1, -rightReserve, 1, 0)
    textFrame.BackgroundTransparency = 1
    textFrame.ZIndex = 2
    textFrame.Parent = container

    local textLayout = Instance.new("UIListLayout")
    textLayout.FillDirection = Enum.FillDirection.Vertical
    textLayout.SortOrder = Enum.SortOrder.LayoutOrder
    textLayout.Padding = UDim.new(0, 2)
    textLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    textLayout.Parent = textFrame

    local label = Instance.new("TextLabel")
    label.Name = "Title"
    label.Size = UDim2.new(1, 0, 0, TITLE_SIZE + 3)
    label.BackgroundTransparency = 1
    label.Text = title
    label.TextColor3 = default and COLORS.TextOn or COLORS.TextOff
    label.TextSize = TITLE_SIZE
    label.Font = fontBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.LayoutOrder = 0
    label.ZIndex = 2
    label.Parent = textFrame

    local descLabel

    local function createDescription(text)
        descLabel = Instance.new("TextLabel")
        descLabel.Name = "Description"
        descLabel.Size = UDim2.new(1, 0, 0, 0)
        descLabel.AutomaticSize = Enum.AutomaticSize.Y
        descLabel.BackgroundTransparency = 1
        descLabel.Text = breakLongWords(text, WORD_MAX)
        descLabel.TextColor3 = COLORS.Description
        descLabel.TextSize = DESC_SIZE
        descLabel.Font = fontRegular
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextYAlignment = Enum.TextYAlignment.Top
        descLabel.TextWrapped = true
        descLabel.LineHeight = 1.15
        descLabel.LayoutOrder = 1
        descLabel.ZIndex = 2
        descLabel.Parent = textFrame
    end

    local function knobPosition(state)
        if state then
            return UDim2.new(1, -(KNOB + KNOB_PAD), 0.5, 0)
        end
        return UDim2.new(0, KNOB_PAD, 0.5, 0)
    end

    local track = Instance.new("Frame")
    track.Name = "Switch"
    track.Size = UDim2.new(0, SWITCH_W, 0, SWITCH_H)
    track.Position = UDim2.new(1, -SIDE_PAD, 0.5, 0)
    track.AnchorPoint = Vector2.new(1, 0.5)
    track.BackgroundColor3 = default and COLORS.TrackOn or COLORS.TrackOff
    track.BorderSizePixel = 0
    track.ZIndex = 3
    track.Parent = container

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.new(0, KNOB, 0, KNOB)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Position = knobPosition(default)
    knob.BackgroundColor3 = default and COLORS.KnobOn or COLORS.KnobOff
    knob.BorderSizePixel = 0
    knob.ZIndex = 4
    knob.Parent = track

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local keyBtn, keyLabel, keyStroke
    if hasKeybind then
        keyBtn = Instance.new("TextButton")
        keyBtn.Name = "KeyBind"
        keyBtn.Size = UDim2.new(0, PILL_W, 0, PILL_H)
        keyBtn.Position = UDim2.new(1, -(SWITCH_W + SIDE_PAD + 8 + PILL_W), 0.5, -PILL_H / 2)
        keyBtn.BackgroundColor3 = COLORS.KeyBg
        keyBtn.BorderSizePixel = 0
        keyBtn.Text = ""
        keyBtn.AutoButtonColor = false
        keyBtn.Selectable = false
        keyBtn.ClipsDescendants = true
        keyBtn.ZIndex = 3
        keyBtn.Parent = container

        local keyCorner = Instance.new("UICorner")
        keyCorner.CornerRadius = UDim.new(0, 5)
        keyCorner.Parent = keyBtn

        keyStroke = Instance.new("UIStroke")
        keyStroke.Color = COLORS.KeyBorder
        keyStroke.Thickness = 1
        keyStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        keyStroke.Parent = keyBtn

        keyLabel = Instance.new("TextLabel")
        keyLabel.Name = "KeyLabel"
        keyLabel.Size = UDim2.new(1, 0, 1, 0)
        keyLabel.BackgroundTransparency = 1
        keyLabel.Text = getKeyName(data.keybind)
        keyLabel.TextColor3 = COLORS.KeyText
        keyLabel.TextSize = KEY_SIZE
        keyLabel.Font = fontBold
        keyLabel.TextXAlignment = Enum.TextXAlignment.Center
        keyLabel.TextYAlignment = Enum.TextYAlignment.Center
        keyLabel.TextWrapped = false
        keyLabel.TextTruncate = Enum.TextTruncate.AtEnd
        keyLabel.ZIndex = 4
        keyLabel.Parent = keyBtn
    end

    local function resizeContainer()
        if destroyed then return end
        if not descLabel then
            container.Size = UDim2.new(1, 0, 0, BASE_H)
            return
        end
        container.Size = UDim2.new(1, 0, 0, math.max(textLayout.AbsoluteContentSize.Y + 16, BASE_H))
    end

    local function play(instance, props, animate)
        if animate then
            tweenService:Create(instance, tweenInfo, props):Play()
        else
            for property, value in pairs(props) do
                instance[property] = value
            end
        end
    end

    local function updateVisuals(animate)
        if destroyed then return end

        local trackColor = data.state and COLORS.TrackOn or COLORS.TrackOff
        local knobColor = data.state and COLORS.KnobOn or COLORS.KnobOff
        local textColor = data.state and COLORS.TextOn or COLORS.TextOff

        if data.disabled then
            trackColor = COLORS.TrackDisabled
            knobColor = COLORS.KnobDisabled
            textColor = COLORS.TextDisabled
        end

        play(track, { BackgroundColor3 = trackColor }, animate)
        play(knob, { BackgroundColor3 = knobColor, Position = knobPosition(data.state) }, animate)
        play(label, { TextColor3 = textColor }, animate)

        rowButton.Active = not data.disabled
    end

    local function fireCallback(value)
        local ok, err = pcall(callback, value)
        if not ok then
            notify(("Checkbox '%s': %s"):format(title, tostring(err)), 5)
        end
    end

    local function fireKeybindCallback(value)
        if not keybindCb then return end
        local ok, err = pcall(keybindCb, value)
        if not ok then
            notify(("Checkbox '%s' (keybind): %s"):format(title, tostring(err)), 5)
        end
    end

    local function toggle()
        if destroyed or data.disabled then return end
        data.state = not data.state
        updateVisuals(true)
        fireCallback(data.state)
    end

    local function resetKeyVisual()
        if not keyBtn then return end
        keyBtn.BackgroundColor3 = COLORS.KeyBg
        keyStroke.Color = COLORS.KeyBorder
        keyLabel.Text = getKeyName(data.keybind)
        keyLabel.TextColor3 = COLORS.KeyText
    end

    local function stopListening()
        if listeningConnection then
            listeningConnection:Disconnect()
            listeningConnection = nil
        end
        data.listening = false
        resetKeyVisual()
    end

    local function enterListenMode()
        if destroyed or not hasKeybind or data.disabled or data.listening then return end
        data.listening = true
        listenStartedAt = os.clock()

        keyBtn.BackgroundColor3 = COLORS.KeyListening
        keyStroke.Color = COLORS.KeyListenText
        keyLabel.Text = "..."
        keyLabel.TextColor3 = COLORS.KeyListenText

        listeningConnection = userInputService.InputBegan:Connect(function(input)
            if destroyed or not data.listening then return end
            if os.clock() - listenStartedAt < 0.15 then return end

            local newBind

            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.MouseButton2
            or input.UserInputType == Enum.UserInputType.MouseButton3 then
                newBind = input.UserInputType
            elseif input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.Escape then
                    data.keybind = nil
                    stopListening()
                    notify(("Keybind de '%s' removida."):format(title), 3)
                    return
                end
                newBind = input.KeyCode
            end

            if newBind then
                data.keybind = newBind
                stopListening()
                notify(("'%s' -> %s"):format(title, getKeyName(newBind)), 3)
            end
        end)
    end

    if hasKeybind then
        connect(userInputService.InputBegan, function(input, gp)
            if destroyed or gp or data.disabled or data.listening then return end
            if not data.keybind then return end
            if matchInput(data.keybind, input) then
                toggle()
                fireKeybindCallback(data.state)
            end
        end)
        connect(keyBtn.Activated, enterListenMode)
    end

    connect(rowButton.Activated, toggle)
    connect(textLayout:GetPropertyChangedSignal("AbsoluteContentSize"), resizeContainer)

    if description ~= "" then
        createDescription(description)
    end

    resizeContainer()
    updateVisuals(false)
    if default then fireCallback(default) end

    function data:Set(value)
        if destroyed then return end
        value = value == true
        if data.state == value then return end
        data.state = value
        updateVisuals(true)
        fireCallback(value)
    end

    function data:Get()
        return data.state
    end

    function data:Toggle()
        toggle()
    end

    function data:SetDisabled(value)
        if destroyed then return end
        data.disabled = value == true
        if data.disabled and data.listening then
            stopListening()
        end
        updateVisuals(true)
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

    function data:SetKeybind(newBind)
        if destroyed then return end
        newBind = normalizeBinding(newBind)
        if newBind ~= nil and not isValidBinding(newBind) then
            notify(("Checkbox '%s': keybind inválida."):format(title), 5)
            return
        end
        data.keybind = newBind
        if data.listening then
            stopListening()
        elseif keyLabel then
            keyLabel.Text = getKeyName(newBind)
        end
    end

    function data:GetKeybind()
        return data.keybind
    end

    function data:ClearKeybind()
        if destroyed then return end
        data.keybind = nil
        if data.listening then
            stopListening()
        elseif keyLabel then
            keyLabel.Text = "None"
        end
    end

    function data:Destroy()
        if destroyed then return end
        destroyed = true
        if listeningConnection then
            listeningConnection:Disconnect()
            listeningConnection = nil
        end
        for _, conn in ipairs(connections) do
            conn:Disconnect()
        end
        table.clear(connections)
        container:Destroy()
    end

    return data
end)