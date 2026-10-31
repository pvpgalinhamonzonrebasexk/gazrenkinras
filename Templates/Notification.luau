local Services = {
    Tween = game:GetService("TweenService"),
    Run = game:GetService("RunService"),
    Players = game:GetService("Players"),
}

local Notifications = {
    Theme = {
        Panel = Color3.fromRGB(20, 20, 20),
        HoverFill = Color3.fromRGB(255, 255, 255),
        TextPrimary = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(105, 105, 115),
        TextHeader = Color3.fromRGB(130, 130, 140),
        TitleText = Color3.fromRGB(255, 255, 255),
        Line = Color3.fromRGB(32, 32, 32),
        Accent = Color3.fromRGB(255, 255, 255),
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
    if item.BarTween then
        item.BarTween:Cancel()
    end
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

local function StartTimer(item, duration)
    if not item.Bar then
        return
    end
    if item.BarTween then
        item.BarTween:Cancel()
    end
    item.Bar.Size = UDim2.new(1, -24, 0, 2)
    local tween = Services.Tween:Create(item.Bar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, 2),
    })
    item.BarTween = tween
    tween.Completed:Connect(function(state)
        if state == Enum.PlaybackState.Completed and item.BarTween == tween then
            Remove(item)
        end
    end)
    tween:Play()
    if Notifications.Config.HoverPause and item.Hover then
        tween:Pause()
    end
end

local function MakeHandle(item)
    return {
        Frame = item.Frame,
        Close = function()
            Remove(item)
        end,
        IsClosed = function()
            return item.Closed
        end,
        Update = function(Properties)
            if item.Closed or type(Properties) ~= "table" then
                return
            end
            if Properties.Title ~= nil and item.TitleLabel then
                item.TitleLabel.Text = tostring(Properties.Title)
            end
            if Properties.Description ~= nil and item.DescriptionLabel then
                item.DescriptionLabel.Text = tostring(Properties.Description)
            end
            local seconds = tonumber(Properties.Duration)
            if seconds and item.Bar then
                if seconds > 0 and seconds ~= math.huge then
                    StartTimer(item, seconds)
                else
                    if item.BarTween then
                        item.BarTween:Cancel()
                    end
                    item.Bar.Size = UDim2.new(1, -24, 0, 2)
                end
            end
        end,
    }
end

local function CreateCard(Properties, title, description, persistent)
    local Config = Notifications.Config
    local Theme = Notifications.Theme

    local thumb = nil
    if Properties.Thumbnail ~= false then
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
    local textX = thumb and (14 + Config.ThumbnailSize + 10) or 14
    local minHeight = thumb and (Config.ThumbnailSize + 24) or 48

    local Card = New("Frame", {
        Name = "Notification",
        AnchorPoint = Vector2.new(0, isTop and 0 or 1),
        Position = UDim2.new(0, HiddenX(), isTop and 0 or 1, 0),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
    }, {
        New("UISizeConstraint", { MinSize = Vector2.new(0, minHeight) }),
        New("UICorner", { CornerRadius = UDim.new(0, 6) }),
        New("UIStroke", {
            Color = Theme.Line,
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        }),
    })

    local Hover = New("Frame", {
        Name = "Hover",
        BackgroundColor3 = Theme.HoverFill,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Parent = Card,
    }, { New("UICorner", { CornerRadius = UDim.new(0, 6) }) })

    if thumb then
        New("ImageLabel", {
            Name = "Thumbnail",
            BackgroundColor3 = Theme.Line,
            BorderSizePixel = 0,
            Image = thumb,
            ScaleType = Enum.ScaleType.Crop,
            Position = UDim2.new(0, 14, 0, 12),
            Size = UDim2.new(0, Config.ThumbnailSize, 0, Config.ThumbnailSize),
            Parent = Card,
        }, { New("UICorner", { CornerRadius = UDim.new(0, 6) }) })
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
            PaddingBottom = UDim.new(0, Config.ShowProgress and 18 or 12),
        }),
    })

    local TitleLabel
    local DescriptionLabel

    if header then
        NewLabel(Column, header, Config.NameFont, Config.NameSize, headerColor, false, false, 1).Name = "Name"
    end

    if title then
        TitleLabel = NewLabel(Column, title, Config.TitleFont, Config.TitleSize, Theme.TitleText, true, richText, 2)
        TitleLabel.Name = "Title"
    end

    if description then
        DescriptionLabel = NewLabel(Column, description, Config.DescriptionFont, Config.DescriptionSize, Theme.TextSecondary, true, richText, 3)
        DescriptionLabel.Name = "Description"
    end

    local item = {
        Frame = Card,
        Id = Properties.Id,
        Key = MakeKey(title, description, Properties),
        Height = 0,
        Offset = nil,
        Closed = false,
        Hover = false,
        Count = 1,
        Tween = nil,
        BarTween = nil,
        Bar = nil,
        Badge = nil,
        TitleLabel = TitleLabel,
        DescriptionLabel = DescriptionLabel,
        Callback = Properties.Callback,
    }

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

    if not persistent then
        item.Bar = New("Frame", {
            Name = "Progress",
            BackgroundColor3 = accent,
            BackgroundTransparency = Config.ShowProgress and 0.35 or 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 12, 1, -6),
            Size = UDim2.new(1, -24, 0, 2),
            Parent = Card,
        }, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })
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
        Play(Hover, TweenInfo.new(0.15), { BackgroundTransparency = 0.94 })
        local tween = item.BarTween
        if Config.HoverPause and tween and tween.PlaybackState == Enum.PlaybackState.Playing then
            tween:Pause()
        end
    end)

    Button.MouseLeave:Connect(function()
        item.Hover = false
        Play(Hover, TweenInfo.new(0.15), { BackgroundTransparency = 1 })
        local tween = item.BarTween
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
    local duration = tonumber(Properties.Duration) or Config.DefaultDuration
    local persistent = duration <= 0 or duration == math.huge

    Build()
    local State = Notifications.State

    if Properties.Id ~= nil then
        for _, existing in ipairs(State.Items) do
            if existing.Id == Properties.Id then
                local handle = MakeHandle(existing)
                handle.Update({
                    Title = title,
                    Description = description,
                    Duration = Properties.Duration,
                })
                return handle
            end
        end
    end

    if Config.Group then
        local key = MakeKey(title, description, Properties)
        for _, existing in ipairs(State.Items) do
            if existing.Key == key then
                existing.Count = existing.Count + 1
                if existing.Badge then
                    existing.Badge.Text = "x" .. existing.Count
                    existing.Badge.Visible = true
                end
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

    if not persistent then
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