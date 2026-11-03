-- // Notification
local Services = {
    Tween = game:GetService("TweenService"),
    Run = game:GetService("RunService"),
    Players = game:GetService("Players"),
}

local White = Color3.new(1, 1, 1)
local Black = Color3.new(0, 0, 0)

local IconsUrl = "https://raw.githubusercontent.com/pvpgalinhamonzonrebasexk/gazrenkinras/refs/heads/main/Assets/Icons.lua"
local IconAssets = nil

local IconFill = 0.8
local IconLine = 0.55

local HoverInfo = TweenInfo.new(0.15)
local FadeInfo = TweenInfo.new(0.25)
local PopInfo = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local ProgressInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SpinInfo = TweenInfo.new(0.9, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1)
local SpinFade = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(0.75, 1),
    NumberSequenceKeypoint.new(1, 1),
})
local GlowFade = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.76),
    NumberSequenceKeypoint.new(0.55, 0.95),
    NumberSequenceKeypoint.new(1, 1),
})

local Notifications = {
    Theme = {
        Panel = Color3.fromRGB(14, 14, 17),
        PanelTop = Color3.fromRGB(32, 32, 38),
        HoverFill = White,
        TextPrimary = White,
        TextSecondary = Color3.fromRGB(150, 150, 162),
        TextHeader = Color3.fromRGB(130, 130, 140),
        TitleText = White,
        Line = Color3.fromRGB(40, 40, 46),
        Track = Color3.fromRGB(42, 42, 48),
        Accent = Color3.fromRGB(140, 120, 255),
    },
    Config = {
        Name = false,
        GuiName = "Notifications",
        Thumbnail = false,
        Side = "Left",
        Vertical = "Bottom",
        Width = 320,
        Margin = 20,
        Padding = 8,
        MaxVisible = 6,
        DefaultDuration = 5,
        ThumbnailSize = 44,
        RingSize = 20,
        IconBox = 32,
        IconSize = 18,
        Radius = 10,
        ShowIcon = true,
        Glow = true,
        ShowProgress = false,
        ShowType = true,
        HoverPause = true,
        Group = false,
        ClickToClose = true,
        Sound = false,
        SoundVolume = 0.5,
        TitleSize = 16,
        DescriptionSize = 14,
        NameSize = 12,
        TitleFont = Enum.Font.Arcade,
        DescriptionFont = Enum.Font.Arcade,
        NameFont = Enum.Font.Arcade,
        TweenIn = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        TweenOut = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
    },
    Types = {
        Info = Color3.fromRGB(88, 166, 255),
        Success = Color3.fromRGB(80, 200, 120),
        Warning = Color3.fromRGB(255, 190, 70),
        Error = Color3.fromRGB(255, 85, 85),
    },
    Icons = {
        Info = "rbxassetid://10723415903",
        Success = "rbxassetid://10709790644",
        Warning = "rbxassetid://10709753149",
        Error = "rbxassetid://10747384394",
        Default = "rbxassetid://10709775704",
    },
    State = {
        Gui = nil,
        Container = nil,
        Items = {},
    },
}

local TypeAliases = {
    info = "Info",
    success = "Success",
    ok = "Success",
    warning = "Warning",
    warn = "Warning",
    error = "Error",
    err = "Error",
}

local function New(class, props, children)
    local inst = Instance.new(class)
    for key, value in pairs(props) do
        if key ~= "Parent" then
            inst[key] = value
        end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    inst.Parent = props.Parent
    return inst
end

local function Play(inst, info, props)
    local tween = Services.Tween:Create(inst, info, props)
    tween:Play()
    return tween
end

local function NewLabel(parent, text, font, size, color, wrapped, richText, order)
    return New("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Text = text,
        Visible = text ~= "",
        Font = font,
        TextSize = size,
        TextColor3 = color,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = wrapped,
        TextTruncate = wrapped and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd,
        RichText = richText,
        LineHeight = 1.1,
        LayoutOrder = order,
        Parent = parent,
    })
end

local function MakeKey(title, description, Properties)
    return (title or "") .. "\n" .. (description or "") .. "\n" .. tostring(Properties.Type)
end

local function HiddenX()
    local Config = Notifications.Config
    local distance = Config.Width + Config.Margin + 20
    return Config.Side == "Left" and -distance or distance
end

local function CardPosition(offset)
    if Notifications.Config.Vertical == "Top" then
        return UDim2.new(0, 0, 0, offset)
    end
    return UDim2.new(0, 0, 1, -offset)
end

local function ApplySide()
    local container = Notifications.State.Container
    if not container then
        return
    end
    local Config = Notifications.Config
    container.Size = UDim2.new(0, Config.Width, 1, -Config.Margin * 2)
    if Config.Side == "Left" then
        container.Position = UDim2.new(0, Config.Margin, 0, Config.Margin)
    else
        container.Position = UDim2.new(1, -(Config.Width + Config.Margin), 0, Config.Margin)
    end
end

local function Relayout()
    local Config = Notifications.Config
    local Items = Notifications.State.Items
    local offset = 0
    for index = #Items, 1, -1 do
        local item = Items[index]
        if item.Height > 0 then
            if item.Offset ~= offset then
                item.Offset = offset
                if item.Tween then
                    item.Tween:Cancel()
                end
                item.Tween = Play(item.Frame, Config.TweenIn, { Position = CardPosition(offset) })
            end
            offset = offset + item.Height + Config.Padding
        end
    end
end

local function StopSpin(item)
    if item.SpinTween then
        item.SpinTween:Cancel()
        item.SpinTween = nil
    end
    if item.Spin then
        item.Spin:Destroy()
        item.Spin = nil
        item.SpinGradient = nil
    end
end

local function HideRing(item)
    local ring = item.Ring
    if not ring then
        return
    end
    local stroke = item.RingStroke
    item.Ring = nil
    item.RingStroke = nil
    if stroke and stroke.Parent then
        local tween = Play(stroke, FadeInfo, { Transparency = 1 })
        tween.Completed:Connect(function()
            ring:Destroy()
        end)
    else
        ring:Destroy()
    end
end

local function ShowIcon(item)
    if not item.IconFrame or item.IconShown then
        return
    end
    item.IconShown = true
    Play(item.IconFrame, FadeInfo, { BackgroundTransparency = IconFill })
    Play(item.IconStroke, FadeInfo, { Transparency = IconLine })
    Play(item.IconImage, FadeInfo, { ImageTransparency = 0 })
    Play(item.IconScale, PopInfo, { Scale = 1 })
end

local function ApplyIcon(item, source)
    if not item.IconImage or source == nil then
        return
    end
    local image = Notifications.ResolveIcon(source)
    if image then
        item.IconImage.Image = image
    end
end

local function Remove(item)
    if not item or item.Closed then
        return
    end
    item.Closed = true
    local Items = Notifications.State.Items
    local index = table.find(Items, item)
    if index then
        table.remove(Items, index)
    end
    if item.Tween then
        item.Tween:Cancel()
    end
    if item.Timer then
        item.Timer:Cancel()
    end
    if item.FillTween then
        item.FillTween:Cancel()
    end
    StopSpin(item)
    local frame = item.Frame
    if frame and frame.Parent then
        local position = frame.Position
        local out = Play(frame, Notifications.Config.TweenOut, {
            Position = UDim2.new(0, HiddenX(), position.Y.Scale, position.Y.Offset),
        })
        out.Completed:Connect(function()
            frame:Destroy()
        end)
    end
    Relayout()
end

local function StopTimer(item)
    if item.Timer then
        item.Timer:Cancel()
        item.Timer = nil
    end
    if item.FillTween then
        item.FillTween:Cancel()
        item.FillTween = nil
    end
    item.Persistent = true
    item.ProgressShown = false
    item.Fill.Size = UDim2.fromScale(1, 1)
    item.Track.Visible = Notifications.Config.ShowProgress and not item.Spin
end

local function StartTimer(item, duration)
    StopTimer(item)
    item.Persistent = false
    local tween = Services.Tween:Create(item.Fill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 1, 0),
    })
    item.Timer = tween
    tween.Completed:Connect(function(state)
        if state == Enum.PlaybackState.Completed and item.Timer == tween then
            Remove(item)
        end
    end)
    tween:Play()
    if Notifications.Config.HoverPause and item.Hover then
        tween:Pause()
    end
end

local function SetProgress(item, value)
    if item.Closed or not item.Persistent then
        return
    end
    value = math.clamp(value, 0, 1)
    if not item.ProgressShown then
        item.ProgressShown = true
        item.Fill.Size = UDim2.fromScale(0, 1)
        item.Track.Visible = true
    elseif item.FillTween then
        item.FillTween:Cancel()
    end
    item.FillTween = Play(item.Fill, ProgressInfo, { Size = UDim2.fromScale(value, 1) })
end

local function Tint(item, color)
    local Theme = Notifications.Theme
    item.Accent = color
    item.StrokeGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color),
        ColorSequenceKeypoint.new(0.6, color:Lerp(Theme.Line, 0.75)),
        ColorSequenceKeypoint.new(1, Theme.Line),
    })
    item.Glow.BackgroundColor3 = color
    item.FillGradient.Color = ColorSequence.new(color:Lerp(White, 0.3), color)
    if item.IconGradient then
        item.IconGradient.Color = ColorSequence.new(color:Lerp(White, 0.25), color:Lerp(Black, 0.35))
        item.IconStroke.Color = color
        item.IconImage.ImageColor3 = color:Lerp(White, 0.35)
    end
    if item.SpinGradient then
        item.SpinGradient.Color = ColorSequence.new(color)
    end
end

local function SetText(label, value)
    if value == nil then
        return
    end
    value = tostring(value)
    label.Text = value
    label.Visible = value ~= ""
end

local function Update(item, Properties)
    if item.Closed or type(Properties) ~= "table" then
        return
    end
    SetText(item.TitleLabel, Properties.Title)
    SetText(item.DescriptionLabel, Properties.Description)

    local typeName = Notifications.ResolveType(Properties.Type) or Properties.Type
    local typeColor = Notifications.Types[typeName]
    local color = Properties.Color or typeColor
    if color then
        Tint(item, color)
    end
    if typeColor and not item.CustomName and Notifications.Config.ShowType then
        item.NameLabel.Text = tostring(typeName):upper()
        item.NameLabel.TextColor3 = typeColor
        item.NameLabel.Visible = true
    end

    local iconSource = Properties.Icon
    if iconSource == nil and typeColor then
        iconSource = Notifications.Icons[typeName] or Notifications.Icons.Default
    end
    if iconSource ~= false then
        ApplyIcon(item, iconSource)
    end

    local seconds = tonumber(Properties.Duration)
    if seconds then
        if seconds > 0 and seconds ~= math.huge then
            StartTimer(item, seconds)
        else
            StopTimer(item)
        end
    end

    local progress = tonumber(Properties.Progress)
    if progress then
        SetProgress(item, progress)
    end
end

local function Finish(item, Properties)
    if item.Closed then
        return
    end
    Properties = type(Properties) == "table" and table.clone(Properties) or {}
    if Properties.Duration == nil then
        Properties.Duration = Notifications.Config.DefaultDuration
    end
    local wasLoading = item.Spin ~= nil
    if wasLoading and Properties.Type == nil and Properties.Color == nil then
        Properties.Type = "Success"
    end
    StopSpin(item)
    HideRing(item)
    Update(item, Properties)
    ShowIcon(item)
end

local function MakeHandle(item)
    local handle = { Frame = item.Frame }
    function handle.Close()
        Remove(item)
    end
    function handle.IsClosed()
        return item.Closed
    end
    function handle.Update(Properties)
        Update(item, Properties)
    end
    function handle.Progress(value)
        SetProgress(item, tonumber(value) or 0)
    end
    function handle.Finish(Properties)
        Finish(item, Properties)
    end
    function handle.Success(title, description, duration)
        Finish(item, { Title = title, Description = description, Duration = duration, Type = "Success" })
    end
    function handle.Error(title, description, duration)
        Finish(item, { Title = title, Description = description, Duration = duration, Type = "Error" })
    end
    return handle
end

local function CreateCard(Properties, title, description, persistent)
    local Config = Notifications.Config
    local Theme = Notifications.Theme
    local loading = Properties.Loading == true

    local thumb = nil
    if Properties.Thumbnail ~= false and not loading then
        local source = Properties.Thumbnail
        if source == nil then
            source = Config.Thumbnail
        end
        thumb = Notifications.NormalizeImage(source)
    end

    local typeColor = Notifications.Types[Properties.Type]
    local accent = Properties.Color or typeColor or Theme.Accent

    local name = Properties.Name
    if name == nil then
        name = Config.Name
    end
    if name == false or name == "" then
        name = nil
    end

    local header, headerColor
    if name then
        header, headerColor = tostring(name), Theme.TextHeader
    elseif Config.ShowType and typeColor then
        header, headerColor = tostring(Properties.Type):upper(), typeColor
    end

    local clickToClose = Properties.ClickToClose
    if clickToClose == nil then
        clickToClose = Config.ClickToClose
    end

    local richText = Properties.RichText ~= false
    local isTop = Config.Vertical == "Top"
    local radius = UDim.new(0, Config.Radius)
    local hasIcon = thumb == nil and Properties.Icon ~= false and (loading or Config.ShowIcon)
    local leftSlot = thumb and Config.ThumbnailSize or ((loading or hasIcon) and Config.IconBox or 0)
    local textX = leftSlot > 0 and (18 + leftSlot + 12) or 18
    local minHeight = math.max(48, leftSlot + 24)
    local slotCenter = 18 + Config.IconBox / 2

    local Card = New("Frame", {
        Name = "Notification",
        AnchorPoint = Vector2.new(0, isTop and 0 or 1),
        Position = UDim2.new(0, HiddenX(), isTop and 0 or 1, 0),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = White,
        BackgroundTransparency = 0.03,
        BorderSizePixel = 0,
    }, {
        New("UISizeConstraint", { MinSize = Vector2.new(0, minHeight) }),
        New("UICorner", { CornerRadius = radius }),
        New("UIGradient", {
            Color = ColorSequence.new(Theme.PanelTop, Theme.Panel),
            Rotation = 90,
        }),
    })

    local Stroke = New("UIStroke", {
        Color = White,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = Card,
    })
    local StrokeGradient = New("UIGradient", { Parent = Stroke })

    local Glow = New("Frame", {
        Name = "Glow",
        BackgroundColor3 = White,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Visible = Config.Glow,
        Parent = Card,
    }, {
        New("UICorner", { CornerRadius = radius }),
        New("UIGradient", { Transparency = GlowFade }),
    })

    local Hover = New("Frame", {
        Name = "Hover",
        BackgroundColor3 = Theme.HoverFill,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Parent = Card,
    }, { New("UICorner", { CornerRadius = radius }) })

    if thumb then
        New("ImageLabel", {
            Name = "Thumbnail",
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Theme.Line,
            BorderSizePixel = 0,
            Image = thumb,
            ScaleType = Enum.ScaleType.Crop,
            Position = UDim2.new(0, 18, 0.5, 0),
            Size = UDim2.new(0, Config.ThumbnailSize, 0, Config.ThumbnailSize),
            Parent = Card,
        }, { New("UICorner", { CornerRadius = UDim.new(0, 8) }) })
    end

    local Ring, RingStroke, Spin, SpinGradient, SpinTween
    if loading then
        Ring = New("Frame", {
            Name = "Ring",
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, slotCenter, 0.5, 0),
            Size = UDim2.fromOffset(Config.RingSize, Config.RingSize),
            Parent = Card,
        }, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })
        RingStroke = New("UIStroke", {
            Color = Theme.Track,
            Thickness = 2.5,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = Ring,
        })
        Spin = New("Frame", {
            Name = "Spin",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            Parent = Ring,
        }, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })
        local SpinStroke = New("UIStroke", {
            Color = White,
            Thickness = 2.5,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = Spin,
        })
        SpinGradient = New("UIGradient", {
            Color = ColorSequence.new(accent),
            Transparency = SpinFade,
            Parent = SpinStroke,
        })
        SpinTween = Play(SpinGradient, SpinInfo, { Rotation = 360 })
    end

    local IconFrame, IconScale, IconStroke, IconGradient, IconImage
    if hasIcon then
        local source = Properties.Icon
        if source == nil and typeColor then
            source = Notifications.Icons[Properties.Type] or Notifications.Icons.Default
        end
        if source == nil then
            source = Notifications.Icons.Default
        end
        IconFrame = New("Frame", {
            Name = "Icon",
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = White,
            BackgroundTransparency = loading and 1 or IconFill,
            BorderSizePixel = 0,
            Position = UDim2.new(0, slotCenter, 0.5, 0),
            Size = UDim2.fromOffset(Config.IconBox, Config.IconBox),
            Parent = Card,
        }, { New("UICorner", { CornerRadius = UDim.new(0, 9) }) })
        IconScale = New("UIScale", {
            Scale = loading and 0.4 or 1,
            Parent = IconFrame,
        })
        IconStroke = New("UIStroke", {
            Color = accent,
            Thickness = 1,
            Transparency = loading and 1 or IconLine,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = IconFrame,
        })
        IconGradient = New("UIGradient", { Rotation = 45, Parent = IconFrame })
        IconImage = New("ImageLabel", {
            Name = "Image",
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = Notifications.ResolveIcon(source) or "",
            ImageTransparency = loading and 1 or 0,
            ScaleType = Enum.ScaleType.Fit,
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(Config.IconSize, Config.IconSize),
            Parent = IconFrame,
        })
    end

    local Column = New("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0, textX, 0, 0),
        Size = UDim2.new(1, -(textX + 14), 0, 0),
        Parent = Card,
    }, {
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 2),
        }),
        New("UIPadding", {
            PaddingTop = UDim.new(0, 12),
            PaddingBottom = UDim.new(0, 14),
        }),
    })

    local NameLabel = NewLabel(Column, header or "", Config.NameFont, Config.NameSize, headerColor or Theme.TextHeader, false, false, 1)
    NameLabel.Name = "Name"
    local TitleLabel = NewLabel(Column, title or "", Config.TitleFont, Config.TitleSize, Theme.TitleText, true, richText, 2)
    TitleLabel.Name = "Title"
    local DescriptionLabel = NewLabel(Column, description or "", Config.DescriptionFont, Config.DescriptionSize, Theme.TextSecondary, true, richText, 3)
    DescriptionLabel.Name = "Description"

    local Track = New("Frame", {
        Name = "Track",
        BackgroundColor3 = Theme.Track,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 18, 1, -8),
        Size = UDim2.new(1, -32, 0, 3),
        Visible = Config.ShowProgress and not loading,
        Parent = Card,
    }, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    local Fill = New("Frame", {
        Name = "Fill",
        BackgroundColor3 = White,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Parent = Track,
    }, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    local FillGradient = New("UIGradient", { Parent = Fill })

    local item = {
        Frame = Card,
        Id = Properties.Id,
        Key = MakeKey(title, description, Properties),
        Height = 0,
        Offset = nil,
        Closed = false,
        Hover = false,
        Count = 1,
        Persistent = persistent,
        ProgressShown = false,
        CustomName = name ~= nil,
        Accent = accent,
        Tween = nil,
        Timer = nil,
        FillTween = nil,
        Ring = Ring,
        RingStroke = RingStroke,
        Spin = Spin,
        SpinGradient = SpinGradient,
        SpinTween = SpinTween,
        IconFrame = IconFrame,
        IconScale = IconScale,
        IconStroke = IconStroke,
        IconGradient = IconGradient,
        IconImage = IconImage,
        IconShown = hasIcon and not loading,
        Glow = Glow,
        Track = Track,
        Fill = Fill,
        StrokeGradient = StrokeGradient,
        FillGradient = FillGradient,
        NameLabel = NameLabel,
        TitleLabel = TitleLabel,
        DescriptionLabel = DescriptionLabel,
        Badge = nil,
        Callback = Properties.Callback,
    }

    Tint(item, accent)

    if Config.Group then
        item.Badge = New("TextLabel", {
            Name = "Count",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -12, 0, 8),
            Size = UDim2.fromOffset(0, 14),
            AutomaticSize = Enum.AutomaticSize.X,
            Font = Config.NameFont,
            TextSize = Config.NameSize,
            TextColor3 = Theme.TextPrimary,
            Text = "",
            Visible = false,
            Parent = Card,
        })
    end

    local Button = New("TextButton", {
        Name = "Click",
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 10,
        Parent = Card,
    })

    Button.MouseButton1Click:Connect(function()
        if item.Callback then
            task.spawn(pcall, item.Callback)
        end
        if clickToClose then
            Remove(item)
        end
    end)

    Button.MouseEnter:Connect(function()
        item.Hover = true
        Play(Hover, HoverInfo, { BackgroundTransparency = 0.94 })
        local tween = item.Timer
        if Notifications.Config.HoverPause and tween and tween.PlaybackState == Enum.PlaybackState.Playing then
            tween:Pause()
        end
    end)

    Button.MouseLeave:Connect(function()
        item.Hover = false
        Play(Hover, HoverInfo, { BackgroundTransparency = 1 })
        local tween = item.Timer
        if tween and tween.PlaybackState == Enum.PlaybackState.Paused then
            tween:Play()
        end
    end)

    Card:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        local height = Card.AbsoluteSize.Y
        if not item.Closed and height > 0 and math.abs(height - item.Height) > 0.5 then
            item.Height = height
            Relayout()
        end
    end)

    return item
end

local function PlaySound(Properties)
    local source = Properties.Sound
    if source == nil then
        source = Notifications.Config.Sound
    end
    local id = source and Notifications.NormalizeImage(source)
    local gui = Notifications.State.Gui
    if not id or not gui then
        return
    end
    local sound = New("Sound", {
        SoundId = id,
        Volume = tonumber(Properties.Volume) or Notifications.Config.SoundVolume,
        Parent = gui,
    })
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
    sound:Play()
    task.delay(10, function()
        if sound.Parent then
            sound:Destroy()
        end
    end)
end

local function Build()
    local State = Notifications.State
    if State.Gui and State.Gui.Parent and State.Container and State.Container.Parent then
        return
    end
    if State.Gui then
        pcall(State.Gui.Destroy, State.Gui)
    end
    State.Items = {}
    local Config = Notifications.Config
    local parents = Notifications.GetParents()
    for _, candidate in ipairs(parents) do
        local ok, old = pcall(candidate.FindFirstChild, candidate, Config.GuiName)
        if ok and old then
            pcall(old.Destroy, old)
        end
    end
    local Gui = New("ScreenGui", {
        Name = Config.GuiName,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 999,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    Notifications.Protect(Gui)
    for _, candidate in ipairs(parents) do
        local ok = pcall(function()
            Gui.Parent = candidate
        end)
        if ok and Gui.Parent then
            break
        end
    end
    State.Gui = Gui
    State.Container = New("Frame", {
        Name = "Container",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, Config.Width, 1, -Config.Margin * 2),
        Parent = Gui,
    })
    ApplySide()
end

local function LoadIcons()
    if IconAssets ~= nil then
        return IconAssets
    end
    IconAssets = false
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(IconsUrl))()
    end)
    if ok and type(result) == "table" then
        IconAssets = result.assets or result
    end
    return IconAssets
end

function Notifications.NormalizeImage(id)
    if type(id) == "number" then
        if id <= 0 then
            return nil
        end
        return "rbxassetid://" .. math.floor(id)
    end
    if type(id) == "string" then
        id = id:gsub("%s+", "")
        if id == "" or id:match("^rbxassetid://0*$") then
            return nil
        end
        if id:match("^%d+$") then
            if tonumber(id) == 0 then
                return nil
            end
            return "rbxassetid://" .. id
        end
        return id
    end
    return nil
end

function Notifications.ResolveIcon(value)
    if value == nil or value == false then
        return nil
    end
    if type(value) == "number" then
        return Notifications.NormalizeImage(value)
    end
    if type(value) ~= "string" then
        return nil
    end
    local direct = Notifications.Icons[value] or Notifications.Icons[Notifications.ResolveType(value) or ""]
    if direct then
        return direct
    end
    if value:match("^rbxassetid://") or value:match("^https?://") or value:match("^%d+$") then
        return Notifications.NormalizeImage(value)
    end
    local key = value:lower():gsub("%s+", "-")
    if not key:find("^lucide%-") then
        key = "lucide-" .. key
    end
    local assets = LoadIcons()
    return assets and assets[key] or nil
end

function Notifications.ResolveType(value)
    if type(value) ~= "string" then
        return nil
    end
    return TypeAliases[value:lower()]
end

function Notifications.GetPlayerGui()
    local ok, gui = pcall(function()
        local player = Services.Players.LocalPlayer
        if not player then
            return nil
        end
        return player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 5)
    end)
    return ok and gui or nil
end

function Notifications.GetParents()
    local list = {}
    if not Services.Run:IsStudio() then
        local ok, ui = pcall(function()
            return gethui and gethui()
        end)
        if ok and typeof(ui) == "Instance" then
            table.insert(list, ui)
        end
        table.insert(list, game:GetService("CoreGui"))
    end
    local playerGui = Notifications.GetPlayerGui()
    if playerGui then
        table.insert(list, playerGui)
    end
    return list
end

function Notifications.Protect(gui)
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(gui)
        elseif protect_gui then
            protect_gui(gui)
        elseif protectgui then
            protectgui(gui)
        end
    end)
end

function Notifications.Normalize(first, second, third, fourth)
    if type(first) == "table" then
        return table.clone(first)
    end
    if first == nil then
        return nil
    end
    if type(second) == "number" then
        return { Description = tostring(first), Duration = second, Type = third }
    end
    if second == nil then
        return { Description = tostring(first) }
    end
    return { Title = tostring(first), Description = tostring(second), Duration = third, Type = fourth }
end

function Notifications.Notify(first, second, third, fourth)
    local Properties = Notifications.Normalize(first, second, third, fourth)
    if not Properties then
        return nil
    end
    Properties.Type = Notifications.ResolveType(Properties.Type) or Properties.Type

    local title = Properties.Title
    local description = Properties.Description
    if title ~= nil then
        title = tostring(title)
    end
    if description ~= nil then
        description = tostring(description)
    end
    if title == "" then
        title = nil
    end
    if description == "" then
        description = nil
    end
    if not title and not description then
        return nil
    end

    local Config = Notifications.Config
    local loading = Properties.Loading == true
    local duration = tonumber(Properties.Duration) or (loading and 0 or Config.DefaultDuration)
    local persistent = duration <= 0 or duration == math.huge

    Build()
    local State = Notifications.State

    if Properties.Id ~= nil then
        for _, existing in ipairs(State.Items) do
            if existing.Id == Properties.Id then
                local changes = {
                    Title = title,
                    Description = description,
                    Duration = Properties.Duration,
                    Type = Properties.Type,
                    Color = Properties.Color,
                    Progress = Properties.Progress,
                    Icon = Properties.Icon,
                }
                if existing.Spin and not loading then
                    Finish(existing, changes)
                else
                    Update(existing, changes)
                end
                return MakeHandle(existing)
            end
        end
    end

    if Config.Group and not loading then
        local key = MakeKey(title, description, Properties)
        for _, existing in ipairs(State.Items) do
            if existing.Key == key and existing.Badge then
                existing.Count = existing.Count + 1
                existing.Badge.Text = "x" .. existing.Count
                existing.Badge.Visible = true
                if not persistent then
                    StartTimer(existing, duration)
                end
                return MakeHandle(existing)
            end
        end
    end

    local item = CreateCard(Properties, title, description, persistent)
    item.Frame.Parent = State.Container
    table.insert(State.Items, item)
    pcall(PlaySound, Properties)

    while #State.Items > math.max(1, Config.MaxVisible) do
        Remove(State.Items[1])
    end

    if persistent then
        local progress = tonumber(Properties.Progress)
        if progress then
            SetProgress(item, progress)
        end
    else
        StartTimer(item, duration)
    end

    task.delay(1, function()
        if not item.Closed and item.Height <= 0 then
            item.Height = 64
            Relayout()
        end
    end)

    return MakeHandle(item)
end

for typeName in pairs(Notifications.Types) do
    Notifications[typeName] = function(title, description, duration)
        return Notifications.Notify({
            Title = title,
            Description = description,
            Duration = duration,
            Type = typeName,
        })
    end
end

function Notifications.Loading(title, description, progress)
    return Notifications.Notify({
        Title = title,
        Description = description,
        Duration = 0,
        Loading = true,
        Progress = progress,
    })
end

function Notifications.Clear()
    for _, item in ipairs(table.clone(Notifications.State.Items)) do
        Remove(item)
    end
end

function Notifications.SetTheme(overrides)
    for key, value in pairs(overrides) do
        if Notifications.Theme[key] ~= nil then
            Notifications.Theme[key] = value
        end
    end
end

function Notifications.SetThumbnail(id)
    Notifications.Config.Thumbnail = id
end

function Notifications.SetIcon(typeName, icon)
    local resolved = Notifications.ResolveType(typeName) or typeName
    Notifications.Icons[resolved] = icon
end

function Notifications.SetFont(font)
    local Config = Notifications.Config
    Config.TitleFont = font
    Config.DescriptionFont = font
    Config.NameFont = font
end

function Notifications.SetName(name)
    Notifications.Config.Name = name
end

function Notifications.SetSide(side)
    Notifications.Config.Side = side == "Right" and "Right" or "Left"
    ApplySide()
end

function Notifications.SetWidth(width)
    Notifications.Config.Width = tonumber(width) or Notifications.Config.Width
    ApplySide()
end

function Notifications.SetPosition(position)
    local key = tostring(position):lower():gsub("[%s_%-]", "")
    local Config = Notifications.Config
    Config.Vertical = key:find("top") and "Top" or "Bottom"
    Config.Side = key:find("right") and "Right" or "Left"
    ApplySide()
    for _, item in ipairs(Notifications.State.Items) do
        item.Frame.AnchorPoint = Vector2.new(0, Config.Vertical == "Top" and 0 or 1)
        item.Offset = nil
    end
    Relayout()
end

function Notifications.SetDuration(seconds)
    Notifications.Config.DefaultDuration = tonumber(seconds) or Notifications.Config.DefaultDuration
end

function Notifications.SetGroup(value)
    Notifications.Config.Group = value == true
end

function Notifications.SetMaxVisible(count)
    Notifications.Config.MaxVisible = math.max(1, tonumber(count) or Notifications.Config.MaxVisible)
end

function Notifications.SetSound(id, volume)
    Notifications.Config.Sound = id or false
    Notifications.Config.SoundVolume = tonumber(volume) or Notifications.Config.SoundVolume
end

function Notifications.SetClickToClose(value)
    Notifications.Config.ClickToClose = value ~= false
end

function Notifications.Destroy()
    local State = Notifications.State
    Notifications.Clear()
    if State.Gui then
        pcall(State.Gui.Destroy, State.Gui)
    end
    State.Gui = nil
    State.Container = nil
    State.Items = {}
end

return setmetatable(Notifications, {
    __call = function(_, ...)
        return Notifications.Notify(...)
    end,
})