-- // Serviços
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- // Tema
local Theme = {
    Active = Color3.fromRGB(240, 240, 240),
    Inactive = Color3.fromRGB(165, 165, 165),
    Dim = Color3.fromRGB(115, 115, 115),
    Accent = Color3.fromRGB(42, 42, 42),
    Field = Color3.fromRGB(34, 34, 34),
    Border = Color3.fromRGB(55, 55, 55),
    Palette = Color3.fromRGB(28, 28, 28),
    Background = Color3.fromRGB(24, 24, 24),
    Divider = Color3.fromRGB(50, 50, 50),
    Subtitle = Color3.fromRGB(150, 150, 150),
    Placeholder = Color3.fromRGB(110, 110, 110),
    Text = Color3.fromRGB(230, 230, 230),
    TabLight = Color3.fromRGB(240, 240, 240),
    TabDark = Color3.fromRGB(60, 60, 60)
}

-- // Configurações
local Config = {
    Repo = "pvpgalinhamonzonrebasexk/gazrenkinras",
    Branch = "main",
    ElementsPath = "Library/Elements",
    TweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    FlashInfo = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    DefaultSize = UDim2.fromOffset(580, 350),
    ToggleImage = "rbxassetid://77526194033506",
    LoadTimeout = 30,
    TabActiveTransparency = 0.72,
    TabHoverTransparency = 0.88,
    TabGradientRotation = 25
}

Config.ElementsApi = "https://api.github.com/repos/" .. Config.Repo .. "/contents/" .. Config.ElementsPath .. "?ref=" .. Config.Branch
Config.ElementsRaw = "https://raw.githubusercontent.com/" .. Config.Repo .. "/refs/heads/" .. Config.Branch .. "/" .. Config.ElementsPath .. "/"
Config.IconsUrl = "https://raw.githubusercontent.com/" .. Config.Repo .. "/refs/heads/" .. Config.Branch .. "/Assets/Icons.lua"

local ELEMENT_ALIASES = {toggle = "checkbox", colorpick = "colorpicker"}
local ELEMENT_ICONS = {
    button = "mouse-pointer-click",
    checkbox = "toggle-right",
    slider = "sliders-horizontal",
    dropdown = "chevrons-up-down",
    colorpicker = "palette",
    paragraph = "align-left"
}
local ELEMENT_DEFAULTS = {"Button", "Toggle", "Slider", "Paragraph", "Dropdown", "ColorPicker"}

-- // Ambiente
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local env = getgenv and getgenv() or _G
local isTouch = UserInputService.TouchEnabled

-- // Util
local Util = {}

function Util.Create(className, props, parent)
    local instance = Instance.new(className)
    for property, value in pairs(props or {}) do
        instance[property] = value
    end
    if parent then
        instance.Parent = parent
    end
    return instance
end

function Util.Corner(parent, radius)
    return Util.Create("UICorner", {CornerRadius = UDim.new(0, radius)}, parent)
end

function Util.Stroke(parent, color, thickness)
    return Util.Create("UIStroke", {Color = color, Thickness = thickness}, parent)
end

function Util.Padding(parent, top, bottom, left, right)
    return Util.Create("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0)
    }, parent)
end

function Util.List(parent, padding, extra)
    local layout = Util.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, padding or 0)
    }, parent)
    for property, value in pairs(extra or {}) do
        layout[property] = value
    end
    return layout
end

function Util.Tween(instance, info, goals)
    local tween = TweenService:Create(instance, info, goals)
    tween:Play()
    return tween
end

function Util.GetViewport()
    local camera = workspace.CurrentCamera
    if camera then
        return camera.ViewportSize
    end
    return Vector2.new(1280, 720)
end

function Util.IsPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

function Util.IsMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

function Util.ResolveKey(name)
    local key = string.lower(tostring(name))
    return ELEMENT_ALIASES[key] or key
end

function Util.Contains(text, query)
    local lowered = string.lower(tostring(text))
    for word in string.gmatch(query, "%S+") do
        if not string.find(lowered, word, 1, true) then
            return false
        end
    end
    return true
end

-- // Maid
local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({Tasks = {}}, Maid)
end

function Maid:Add(item)
    self.Tasks[#self.Tasks + 1] = item
    return item
end

function Maid:Connect(signal, callback)
    return self:Add(signal:Connect(callback))
end

function Maid:Destroy()
    for _, item in ipairs(self.Tasks) do
        local kind = typeof(item)
        if kind == "RBXScriptConnection" then
            item:Disconnect()
        elseif kind == "Instance" then
            item:Destroy()
        elseif kind == "function" then
            pcall(item)
        elseif kind == "table" and type(item.Destroy) == "function" then
            pcall(item.Destroy, item)
        end
    end
    table.clear(self.Tasks)
end

-- // Icons
local Icons = {Assets = env.EcoHubIcons, Pending = {}, Loading = false}

function Icons.Apply(icon, name)
    local assets = Icons.Assets
    if not assets then
        return
    end
    name = tostring(name or "circle")
    local id = assets["lucide-" .. name] or assets[name] or assets["lucide-circle"] or assets["circle"]
    if id then
        icon.Image = id
    end
end

function Icons.Create(parent, name, size, color)
    local icon = Util.Create("ImageLabel", {
        Name = "Icon",
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 1,
        ImageColor3 = color
    }, parent)
    if Icons.Assets then
        Icons.Apply(icon, name)
    else
        Icons.Pending[#Icons.Pending + 1] = {icon, name}
    end
    return icon
end

function Icons.Load()
    if Icons.Assets or Icons.Loading then
        return
    end
    Icons.Loading = true
    task.spawn(function()
        local ok, result = pcall(function()
            return loadstring(game:HttpGet(Config.IconsUrl))()
        end)
        if ok and type(result) == "table" and type(result.assets) == "table" then
            Icons.Assets = result.assets
            env.EcoHubIcons = result.assets
            for _, item in ipairs(Icons.Pending) do
                if item[1].Parent then
                    Icons.Apply(item[1], item[2])
                end
            end
        end
        Icons.Pending = {}
        Icons.Loading = false
    end)
end

-- // Library
local Library = {Window = nil}
Library.__index = Library

-- // ElementRegistry
local ElementRegistry = {}
ElementRegistry.__index = ElementRegistry

local function bind(self, impl)
    return function(first, ...)
        if rawequal(first, self) then
            return impl(self, ...)
        end
        return impl(self, first, ...)
    end
end

function ElementRegistry.new()
    local self = setmetatable({}, ElementRegistry)
    self.Registry = {}
    self.Pending = {}
    self.Files = {}
    self.Active = 0
    self.Panel = nil
    self.Destroyed = false
    self.OnChanged = nil

    self.Register = bind(self, ElementRegistry._Register)
    self.Get = bind(self, ElementRegistry._Get)
    self.List = bind(self, ElementRegistry._List)
    self.Load = bind(self, ElementRegistry._Load)
    return self
end

function ElementRegistry:_Changed()
    if self.OnChanged and not self.Destroyed then
        self.OnChanged()
    end
end

function ElementRegistry:_Register(name, builder, meta)
    if self.Destroyed or type(name) ~= "string" or type(builder) ~= "function" then
        return
    end
    local key = Util.ResolveKey(name)
    local frameless = key == "button"
    if type(meta) == "table" and meta.Frameless ~= nil then
        frameless = meta.Frameless and true or false
    end
    local entry = {Name = name, Builder = builder, Frameless = frameless}
    self.Registry[key] = entry

    local queue = self.Pending[key]
    if queue then
        self.Pending[key] = nil
        for _, job in ipairs(queue) do
            job.Element:Build(entry, job.Options)
        end
    end
    self:_Changed()
end

function ElementRegistry:_Get(name)
    return self.Registry[Util.ResolveKey(name)]
end

function ElementRegistry:_List()
    local names = {}
    for _, entry in pairs(self.Registry) do
        names[#names + 1] = entry.Name
    end
    table.sort(names)
    return names
end

function ElementRegistry:Enqueue(key, element, options)
    local queue = self.Pending[key]
    if not queue then
        queue = {}
        self.Pending[key] = queue
    end
    queue[#queue + 1] = {Element = element, Options = options}
end

function ElementRegistry:_RunChunk(chunk)
    local scoped = false
    if type(setfenv) == "function" and type(getfenv) == "function" then
        scoped = pcall(function()
            local scope = setmetatable({Elements = self, Panel = self.Panel}, {__index = getfenv(chunk)})
            setfenv(chunk, scope)
        end)
    end
    if not scoped then
        env.Elements = self
    end
    return chunk(self, self.Panel)
end

function ElementRegistry:_LoadFile(file)
    local names = {file}
    if not string.match(file, "%.luau?$") then
        names = {file .. ".luau", file .. ".lua"}
    end
    local lastError = "not found"
    for _, candidate in ipairs(names) do
        local ok, result = pcall(function()
            local source = game:HttpGet(Config.ElementsRaw .. candidate)
            local chunk, compileError = loadstring(source)
            if not chunk then
                error(compileError, 0)
            end
            return self:_RunChunk(chunk)
        end)
        if ok then
            return true
        end
        lastError = result
    end
    warn("[EcoHub] could not load element '" .. file .. "': " .. tostring(lastError))
    return false
end

function ElementRegistry:_ListFiles(names)
    local files = {}
    if type(names) == "table" then
        for _, name in ipairs(names) do
            files[#files + 1] = name
        end
        return files
    end

    local ok, list = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(Config.ElementsApi))
    end)
    if ok and type(list) == "table" then
        for _, item in ipairs(list) do
            if type(item) == "table" and item.type == "file" and type(item.name) == "string" then
                if string.match(item.name, "%.luau?$") then
                    files[#files + 1] = item.name
                end
            end
        end
    end
    if #files == 0 then
        for _, name in ipairs(ELEMENT_DEFAULTS) do
            files[#files + 1] = name
        end
    end
    return files
end

function ElementRegistry:_WarnPending()
    for key, queue in pairs(self.Pending) do
        for _, job in ipairs(queue) do
            if not job.Element.Destroyed then
                warn("[EcoHub] element type '" .. job.Element.Type .. "' was not found in " .. Config.ElementsPath)
            end
        end
        self.Pending[key] = nil
    end
end

function ElementRegistry:_Load(names)
    names = names or env.EcoHubElementList
    self.Active = self.Active + 1
    task.spawn(function()
        local files = self:_ListFiles(names)
        local remaining = 0

        for _, file in ipairs(files) do
            local id = string.lower((string.gsub(file, "%.luau?$", "")))
            if not self.Files[id] then
                self.Files[id] = true
                remaining = remaining + 1
                task.spawn(function()
                    pcall(self._LoadFile, self, file)
                    remaining = remaining - 1
                end)
            end
        end

        local waited = 0
        while remaining > 0 and waited < Config.LoadTimeout and not self.Destroyed do
            task.wait(0.1)
            waited = waited + 0.1
        end

        self.Active = self.Active - 1
        if self.Active == 0 and not self.Destroyed then
            self:_WarnPending()
        end
    end)
end

-- // Element
local Element = {}
Element.__index = Element

function Element.new(contentSection, elementType, options)
    local self = setmetatable({}, Element)
    local tab = contentSection.Tab

    local container = Util.Create("Frame", {
        Name = elementType,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Field,
        BorderSizePixel = 0,
        LayoutOrder = contentSection.Count,
        Visible = false
    }, contentSection.Holder)
    Util.Corner(container, 6)
    Util.Create("UISizeConstraint", {MinSize = Vector2.new(0, 32)}, container)

    local border = Util.Create("UIStroke", {Name = "Border", Color = Theme.Border, Thickness = 1}, container)
    local flash = Util.Create("UIStroke", {Name = "Flash", Color = Theme.Active, Thickness = 1.5, Transparency = 1}, container)
    local inset = Util.Create("UIPadding", {Name = "Inset"}, container)

    local name = tostring(options.title or options.Title or options.name or options.Name or options.Text or options.Label or elementType)
    local description = tostring(options.description or options.Description or "")

    self.Type = elementType
    self.Name = name
    self.Group = contentSection.Name
    self.Search = string.lower(name .. " " .. elementType .. " " .. contentSection.Name .. " " .. tab.Name .. " " .. description)
    self.Tab = tab
    self.Section = contentSection
    self.Container = container
    self.Border = border
    self.Flash = flash
    self.Inset = inset
    self.Calls = {}
    self.Built = false
    self.Destroyed = false
    self.Instance = nil
    self.Registry = tab.Window.Elements

    container.Name = name
    return self
end

function Element:ApplyFrame(frameless)
    local pad = frameless and 0 or 4
    local side = frameless and 0 or 10
    self.Container.BackgroundTransparency = frameless and 1 or 0
    self.Border.Enabled = not frameless
    self.Inset.PaddingTop = UDim.new(0, pad)
    self.Inset.PaddingBottom = UDim.new(0, pad)
    self.Inset.PaddingLeft = UDim.new(0, side)
    self.Inset.PaddingRight = UDim.new(0, side)
end

function Element:Attach(options)
    local key = Util.ResolveKey(self.Type)
    local entry = self.Registry.Registry[key]
    if entry then
        self:Build(entry, options)
    else
        self:ApplyFrame(key == "button")
        self.Registry:Enqueue(key, self, options)
    end
end

function Element:Build(entry, options)
    if self.Destroyed then
        return
    end
    self:ApplyFrame(entry.Frameless)

    local scope = {
        frame = self.Container,
        Panel = self.Registry.Panel,
        Tab = self.Tab,
        Section = self.Section,
        Element = self,
        Elements = self.Registry,
        CreateIcon = Icons.Create
    }

    local ok, result = pcall(entry.Builder, scope, options)
    if not ok then
        warn("[EcoHub] element '" .. self.Type .. "' failed: " .. tostring(result))
        self:Destroy()
        return
    end

    self.Container.Visible = true
    self.Built = true
    self.Instance = type(result) == "table" and result or {}

    local calls = self.Calls
    self.Calls = {}
    for _, call in ipairs(calls) do
        local method = self.Instance[call.Name]
        if type(method) == "function" then
            pcall(method, self.Instance, table.unpack(call.Args, 1, call.Count))
        end
    end
end

function Element:Destroy()
    if self.Destroyed then
        return
    end
    self.Destroyed = true

    local api = self.Instance
    if api and type(api.Destroy) == "function" then
        pcall(api.Destroy, api)
    end

    local index = table.find(self.Tab.Elements, self)
    if index then
        table.remove(self.Tab.Elements, index)
    end
    self.Container:Destroy()
    self.Registry:_Changed()
end

function Element:CreateHandle()
    local element = self
    return setmetatable({Element = element}, {
        __index = function(_, key)
            if key == "Destroy" then
                return function()
                    element:Destroy()
                end
            end
            if element.Destroyed then
                return function() end
            end
            if element.Built then
                local value = element.Instance[key]
                if type(value) == "function" then
                    return function(_, ...)
                        return value(element.Instance, ...)
                    end
                end
                return value
            end
            return function(_, ...)
                element.Calls[#element.Calls + 1] = {Name = key, Args = {...}, Count = select("#", ...)}
            end
        end
    })
end

-- // ContentSection
local ContentSection = {}

ContentSection.__index = function(self, key)
    local method = rawget(ContentSection, key)
    if method ~= nil then
        return method
    end
    if type(key) ~= "string" then
        return nil
    end
    local elementName = string.match(key, "^Create(%u%w*)$") or string.match(key, "^Add(%u%w*)$")
    if not elementName then
        return nil
    end
    return function(section, options)
        return section:AddElement(elementName, options)
    end
end

function ContentSection.new(tab, name)
    local self = setmetatable({}, ContentSection)
    self.Name = name
    self.Tab = tab
    self.Count = 0

    local frame = Util.Create("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = #tab.Sections + 1
    }, tab.Scroll)
    Util.List(frame, 6)

    local title = Util.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Theme.Dim,
        TextSize = 12,
        Font = Enum.Font.SourceSansSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 0
    }, frame)
    Util.Padding(title, 0, 0, 2, 0)

    local holder = Util.Create("Frame", {
        Name = "Holder",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 1
    }, frame)
    Util.List(holder, 6)

    self.Frame = frame
    self.TitleLabel = title
    self.Holder = holder
    return self
end

function ContentSection:AddElement(elementType, options)
    options = type(options) == "table" and options or {}
    elementType = tostring(elementType)
    self.Count = self.Count + 1

    local element = Element.new(self, elementType, options)
    self.Tab.Elements[#self.Tab.Elements + 1] = element
    element:Attach(options)

    self.Tab.Window:RefreshSearch()
    return element:CreateHandle()
end

ContentSection.CreateElement = ContentSection.AddElement

function ContentSection:SetTitle(text)
    self.TitleLabel.Text = tostring(text)
end

-- // Tab
local Tab = {}
Tab.__index = Tab

function Tab.new(window, sideSection, name, iconName)
    local self = setmetatable({}, Tab)
    iconName = iconName or "circle"

    self.Window = window
    self.Section = sideSection
    self.Name = name
    self.IconName = iconName
    self.Sections = {}
    self.Elements = {}

    local button = Util.Create("TextButton", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = #sideSection.Tabs + 1
    }, sideSection.Menu)
    Util.Corner(button, 6)

    Util.Create("UIGradient", {
        Name = "Gradient",
        Color = ColorSequence.new(Theme.TabLight, Theme.TabDark),
        Rotation = Config.TabGradientRotation
    }, button)

    local stroke = Util.Create("UIStroke", {
        Name = "Stroke",
        Color = Theme.Inactive,
        Thickness = 1,
        Transparency = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, button)

    local icon = Icons.Create(button, iconName, 16, Theme.Inactive)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.Position = UDim2.new(0, 8, 0.5, 0)

    local label = Util.Create("TextLabel", {
        Name = "Text",
        Size = UDim2.new(1, -36, 1, 0),
        Position = UDim2.new(0, 32, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Theme.Inactive,
        TextSize = 14,
        Font = Enum.Font.SourceSans,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, button)

    local page = Util.Create("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false
    }, window.PageHolder)

    local scroll = Util.Create("ScrollingFrame", {
        Name = "Scroll",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = isTouch and 3 or 2,
        ScrollBarImageColor3 = Theme.Border,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y
    }, page)
    Util.Padding(scroll, 4, 12, 12, 12)
    Util.List(scroll, 14)

    self.Button = button
    self.Stroke = stroke
    self.Icon = icon
    self.Label = label
    self.Page = page
    self.Scroll = scroll

    button.Activated:Connect(function()
        self:Select()
    end)
    button.MouseEnter:Connect(function()
        if window.ActiveTab ~= self then
            Util.Tween(button, Config.TweenInfo, {BackgroundTransparency = Config.TabHoverTransparency})
            label.TextColor3 = Theme.Active
            icon.ImageColor3 = Theme.Active
        end
    end)
    button.MouseLeave:Connect(function()
        self:Style()
    end)

    return self
end

function Tab:Style()
    local isActive = self.Window.ActiveTab == self
    local color = isActive and Theme.Active or Theme.Inactive
    Util.Tween(self.Button, Config.TweenInfo, {
        BackgroundTransparency = isActive and Config.TabActiveTransparency or 1
    })
    Util.Tween(self.Stroke, Config.TweenInfo, {Transparency = isActive and 0.55 or 1})
    self.Label.TextColor3 = color
    self.Label.Font = isActive and Enum.Font.SourceSansSemibold or Enum.Font.SourceSans
    self.Icon.ImageColor3 = color
end

function Tab:Select()
    self.Window:SelectTab(self)
end

function Tab:CreateSection(name)
    local section = ContentSection.new(self, tostring(name or "Section"))
    self.Sections[#self.Sections + 1] = section
    return section
end

Tab.AddSection = Tab.CreateSection

-- // SideSection
local SideSection = {}
SideSection.__index = SideSection

function SideSection.new(window, name)
    local self = setmetatable({}, SideSection)
    window.SectionOrder = window.SectionOrder + 1

    self.Window = window
    self.Name = name
    self.Tabs = {}
    self.Open = true
    self.Token = 0

    local frame = Util.Create("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = window.SectionOrder
    }, window.TabList)
    Util.List(frame, 2)

    local labelButton = Util.Create("TextButton", {
        Name = "Label",
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = name,
        TextColor3 = Theme.Dim,
        TextSize = 12,
        Font = Enum.Font.SourceSansSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 0
    }, frame)
    Util.Padding(labelButton, 0, 0, 8, 0)

    local chevron = Icons.Create(labelButton, "chevron-down", 14, Theme.Dim)
    chevron.AnchorPoint = Vector2.new(1, 0.5)
    chevron.Position = UDim2.new(1, -6, 0.5, 0)

    local menu = Util.Create("Frame", {
        Name = "Menu",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        ClipsDescendants = true
    }, frame)
    Util.List(menu, 2)

    self.Frame = frame
    self.Menu = menu
    self.Chevron = chevron

    labelButton.Activated:Connect(function()
        self:SetOpen(not self.Open)
    end)

    return self
end

function SideSection:SetOpen(state)
    self.Open = state
    Util.Tween(self.Chevron, Config.TweenInfo, {Rotation = state and 0 or -90})
    self:_Animate()
end

function SideSection:_Animate()
    local menu = self.Menu
    local full = math.max(menu.AbsoluteSize.Y, #self.Tabs * 34 - 2, 0)

    self.Token = self.Token + 1
    local token = self.Token
    menu.AutomaticSize = Enum.AutomaticSize.None

    if self.Open then
        menu.Visible = true
        local tween = Util.Tween(menu, Config.TweenInfo, {Size = UDim2.new(1, 0, 0, #self.Tabs * 34 - 2)})
        tween.Completed:Connect(function()
            if self.Token == token and self.Open then
                menu.AutomaticSize = Enum.AutomaticSize.Y
                menu.Size = UDim2.new(1, 0, 0, 0)
            end
        end)
    else
        menu.Size = UDim2.new(1, 0, 0, full)
        local tween = Util.Tween(menu, Config.TweenInfo, {Size = UDim2.new(1, 0, 0, 0)})
        tween.Completed:Connect(function()
            if self.Token == token and not self.Open then
                menu.Visible = false
            end
        end)
    end
end

function SideSection:AddTab(tabName, iconName)
    local tab = Tab.new(self.Window, self, tabName, iconName)
    self.Tabs[#self.Tabs + 1] = tab
    self.Window:_RegisterTab(tab)
    return tab.Page, tab
end

-- // Palette
local Palette = {}
Palette.__index = Palette

function Palette.new(window)
    local self = setmetatable({}, Palette)
    self.Window = window
    self.IsOpen = false
    self.Token = 0
    self.Items = {}
    self.Selected = 0
    self:_Build()
    return self
end

function Palette:_Build()
    local main = self.Window.Main

    local overlay = Util.Create("TextButton", {
        Name = "PaletteOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Visible = false,
        ZIndex = 20
    }, main)
    Util.Corner(overlay, 8)

    local frame = Util.Create("Frame", {
        Name = "PaletteFrame",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 40),
        Size = UDim2.new(1, -20, 0, 89),
        BackgroundColor3 = Theme.Palette,
        BorderSizePixel = 0,
        Active = true,
        Visible = false,
        ZIndex = 21
    }, main)
    Util.Corner(frame, 10)
    Util.Stroke(frame, Theme.Border, 1)
    Util.Create("UISizeConstraint", {MaxSize = Vector2.new(340, math.huge)}, frame)
    local scale = Util.Create("UIScale", {Scale = 0.96}, frame)

    local inputRow = Util.Create("Frame", {
        Name = "InputRow",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1
    }, frame)

    local searchIcon = Icons.Create(inputRow, "search", 16, Theme.Dim)
    searchIcon.AnchorPoint = Vector2.new(0, 0.5)
    searchIcon.Position = UDim2.new(0, 12, 0.5, 0)

    local input = Util.Create("TextBox", {
        Name = "Input",
        Size = UDim2.new(1, -76, 1, 0),
        Position = UDim2.new(0, 36, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Search tabs and elements...",
        PlaceholderColor3 = Theme.Placeholder,
        TextColor3 = Theme.Text,
        TextSize = 14,
        Font = Enum.Font.SourceSans,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false
    }, inputRow)

    local close = Util.Create("TextButton", {
        Name = "Close",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0, 28, 0, 28),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = ""
    }, inputRow)
    Util.Corner(close, 6)

    local closeIcon = Icons.Create(close, "x", 14, Theme.Dim)
    closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    closeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)

    Util.Create("Frame", {
        Name = "Divider",
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0
    }, frame)

    local list = Util.Create("ScrollingFrame", {
        Name = "List",
        Size = UDim2.new(1, 0, 0, 48),
        Position = UDim2.new(0, 0, 0, 41),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = isTouch and 3 or 2,
        ScrollBarImageColor3 = Theme.Border,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y
    }, frame)
    Util.Padding(list, 4, 4, 4, 4)
    local layout = Util.List(list, 2)

    self.Overlay = overlay
    self.Frame = frame
    self.Scale = scale
    self.Input = input
    self.List = list
    self.Layout = layout

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self:_Resize()
    end)
    input:GetPropertyChangedSignal("Text"):Connect(function()
        if self.IsOpen then
            self:Render(self:_Query())
        end
    end)
    overlay.Activated:Connect(function()
        self:Close()
    end)
    close.Activated:Connect(function()
        self:Close()
    end)
    input.FocusLost:Connect(function(enterPressed)
        if not enterPressed or not self.IsOpen then
            return
        end
        local item = self.Items[self.Selected]
        if item then
            self:Activate(item)
        end
    end)
end

function Palette:_Resize()
    local limit = math.clamp(self.Window.Main.AbsoluteSize.Y - 96, 96, 230)
    local height = math.clamp(self.Layout.AbsoluteContentSize.Y + 8, 48, limit)
    self.List.Size = UDim2.new(1, 0, 0, height)
    self.Frame.Size = UDim2.new(1, -20, 0, 41 + height)
end

function Palette:_Query()
    local text = string.lower(self.Input.Text)
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end

function Palette:_Clear()
    for _, child in ipairs(self.List:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
    self.Items = {}
    self.Selected = 0
end

function Palette:SetSelected(index, scroll)
    local previous = self.Items[self.Selected]
    if previous and previous.Button.Parent then
        previous.Button.BackgroundTransparency = 1
    end
    self.Selected = index
    local item = self.Items[index]
    if not item then
        return
    end
    item.Button.BackgroundTransparency = 0

    if scroll then
        local list = self.List
        local current = list.CanvasPosition.Y
        local top = item.Button.AbsolutePosition.Y - list.AbsolutePosition.Y + current
        local bottom = top + item.Button.AbsoluteSize.Y
        local view = list.AbsoluteSize.Y
        if top < current then
            list.CanvasPosition = Vector2.new(0, math.max(top - 28, 0))
        elseif bottom > current + view then
            list.CanvasPosition = Vector2.new(0, bottom - view + 4)
        end
    end
end

function Palette:Move(step)
    local count = #self.Items
    if count == 0 then
        return
    end
    local nextIndex = self.Selected + step
    if nextIndex > count then
        nextIndex = 1
    elseif nextIndex < 1 then
        nextIndex = count
    end
    self:SetSelected(nextIndex, true)
end

function Palette:_FocusElement(element)
    local container = element.Container
    local scroll = element.Tab.Scroll
    if not container.Parent then
        return
    end
    local target = container.AbsolutePosition.Y - scroll.AbsolutePosition.Y + scroll.CanvasPosition.Y - 34
    local limit = math.max(scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteSize.Y, 0)
    Util.Tween(scroll, Config.TweenInfo, {CanvasPosition = Vector2.new(0, math.clamp(target, 0, limit))})
    element.Flash.Transparency = 0
    Util.Tween(element.Flash, Config.FlashInfo, {Transparency = 1})
end

function Palette:Activate(item)
    self:Close()
    if item.Kind == "tab" then
        self.Window:SelectTab(item.Tab)
    else
        self.Window:SelectTab(item.Element.Tab)
        task.delay(0.05, function()
            if not item.Element.Destroyed then
                self:_FocusElement(item.Element)
            end
        end)
    end
end

function Palette:_CreateHeading(order, text)
    local label = Util.Create("TextLabel", {
        Name = "Heading",
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.Dim,
        TextSize = 12,
        Font = Enum.Font.SourceSansSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = order
    }, self.List)
    Util.Padding(label, 0, 0, 8, 0)
end

function Palette:_CreateSeparator(order)
    Util.Create("Frame", {
        Name = "Separator",
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        LayoutOrder = order
    }, self.List)
end

function Palette:_CreateRow(order, data)
    local button = Util.Create("TextButton", {
        Name = "Item",
        Size = UDim2.new(1, 0, 0, isTouch and 36 or 32),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = order
    }, self.List)
    Util.Corner(button, 6)

    local icon = Icons.Create(button, data.Icon, 16, Theme.Inactive)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.Position = UDim2.new(0, 8, 0.5, 0)

    Util.Create("TextLabel", {
        Name = "Hint",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0.4, 0, 0, 16),
        BackgroundTransparency = 1,
        Text = data.Hint,
        TextColor3 = Theme.Dim,
        TextSize = 12,
        Font = Enum.Font.SourceSans,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, button)

    Util.Create("TextLabel", {
        Name = "Text",
        Size = UDim2.new(0.6, -36, 1, 0),
        Position = UDim2.new(0, 32, 0, 0),
        BackgroundTransparency = 1,
        Text = data.Name,
        TextColor3 = Theme.Active,
        TextSize = 14,
        Font = Enum.Font.SourceSans,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, button)

    data.Button = button
    self.Items[#self.Items + 1] = data
    local index = #self.Items

    button.MouseEnter:Connect(function()
        self:SetSelected(index, false)
    end)
    button.Activated:Connect(function()
        self:Activate(data)
    end)
end

function Palette:Render(query)
    self:_Clear()
    local order = 0
    local groups = 0

    for _, section in ipairs(self.Window.SideSections) do
        local sectionMatch = query ~= "" and Util.Contains(section.Name, query)
        local rows = {}

        for _, tab in ipairs(section.Tabs) do
            if query == "" or sectionMatch or Util.Contains(tab.Name .. " " .. section.Name, query) then
                rows[#rows + 1] = {Kind = "tab", Name = tab.Name, Icon = tab.IconName, Hint = section.Name, Tab = tab}
            end
            for _, element in ipairs(tab.Elements) do
                if element.Built and (query == "" or Util.Contains(element.Search, query)) then
                    rows[#rows + 1] = {
                        Kind = "element",
                        Name = element.Name,
                        Icon = ELEMENT_ICONS[Util.ResolveKey(element.Type)] or "box",
                        Hint = tab.Name .. " > " .. element.Group,
                        Element = element
                    }
                end
            end
        end

        if #rows > 0 then
            groups = groups + 1
            if groups > 1 then
                order = order + 1
                self:_CreateSeparator(order)
            end
            order = order + 1
            self:_CreateHeading(order, section.Name)
            for _, row in ipairs(rows) do
                order = order + 1
                self:_CreateRow(order, row)
            end
        end
    end

    if groups == 0 then
        Util.Create("TextLabel", {
            Name = "Empty",
            Size = UDim2.new(1, 0, 0, 48),
            BackgroundTransparency = 1,
            Text = "No results found.",
            TextColor3 = Theme.Dim,
            TextSize = 14,
            Font = Enum.Font.SourceSans
        }, self.List)
    else
        self:SetSelected(1, false)
    end

    self.List.CanvasPosition = Vector2.new(0, 0)
    self:_Resize()
end

function Palette:Refresh()
    if self.IsOpen then
        self:Render(self:_Query())
    end
end

function Palette:Open()
    if self.IsOpen or not self.Window.Gui.Enabled then
        return
    end
    self.IsOpen = true
    self.Token = self.Token + 1
    self.Input.Text = ""
    self:Render("")

    self.Overlay.Visible = true
    self.Frame.Visible = true
    self.Overlay.BackgroundTransparency = 1
    self.Scale.Scale = 0.96
    Util.Tween(self.Overlay, Config.TweenInfo, {BackgroundTransparency = 0.5})
    Util.Tween(self.Scale, Config.TweenInfo, {Scale = 1})

    task.defer(function()
        if self.IsOpen then
            self.Input:CaptureFocus()
        end
    end)
end

function Palette:Close()
    if not self.IsOpen then
        return
    end
    self.IsOpen = false
    self.Token = self.Token + 1
    local token = self.Token

    self.Input:ReleaseFocus()
    Util.Tween(self.Scale, Config.TweenInfo, {Scale = 0.96})
    local tween = Util.Tween(self.Overlay, Config.TweenInfo, {BackgroundTransparency = 1})
    tween.Completed:Connect(function()
        if self.Token == token and not self.IsOpen then
            self.Overlay.Visible = false
            self.Frame.Visible = false
        end
    end)
end

-- // Window
local Window = {}
Window.__index = Window

function Window.new(config)
    local self = setmetatable({}, Window)
    self.Maid = Maid.new()
    self.Created = false
    self.Destroyed = false
    self.MinimizeKey = Enum.KeyCode.RightShift
    self.SideSections = {}
    self.SideSectionsByName = {}
    self.Tabs = {}
    self.ActiveTab = nil
    self.SectionOrder = 0

    self:_BuildMain()
    self:_BuildPanel()
    self.Palette = Palette.new(self)
    self:_BuildToggle()
    self:_BindInput()
    self:_MakeDraggable(self.Dashboard, self.Main)
    self:_MakeDraggable(self.Header, self.Main)
    self:_BindResize()
    self:_BindToggleDrag()
    self:Configure(config)
    return self
end

function Window:_BuildMain()
    local gui = Util.Create("ScreenGui", {
        Name = "EcoHub",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Enabled = false
    }, PlayerGui)

    local main = Util.Create("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 580, 0, 350),
        Position = UDim2.new(0.5, -290, 0.5, -175),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Active = true
    }, gui)
    Util.Corner(main, 8)
    Util.Stroke(main, Theme.Border, 1)

    local content = Util.Create("Frame", {
        Name = "ContentContainer",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1
    }, main)

    local sidebar = Util.Create("Frame", {
        Name = "TabSidebar",
        Size = UDim2.new(0, 140, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    }, content)

    Util.Create("Frame", {
        Name = "TabLine",
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Theme.Divider,
        BorderSizePixel = 0
    }, sidebar)

    local dashboard = Util.Create("Frame", {
        Name = "Dashboard",
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    }, sidebar)

    local titleText = Util.Create("TextLabel", {
        Name = "TitleText",
        Size = UDim2.new(1, -20, 0, 18),
        Position = UDim2.new(0, 12, 0, 16),
        BackgroundTransparency = 1,
        Text = "EcoHub",
        TextColor3 = Theme.Active,
        TextSize = 15,
        Font = Enum.Font.SourceSansBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, dashboard)

    local subTitleText = Util.Create("TextLabel", {
        Name = "SubTitleText",
        Size = UDim2.new(1, -20, 0, 14),
        Position = UDim2.new(0, 12, 0, 34),
        BackgroundTransparency = 1,
        Text = "v1.0.0",
        TextColor3 = Theme.Subtitle,
        TextSize = 12,
        Font = Enum.Font.SourceSans,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, dashboard)

    local tabList = Util.Create("ScrollingFrame", {
        Name = "TabList",
        Size = UDim2.new(1, 0, 1, -56),
        Position = UDim2.new(0, 0, 0, 56),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    }, sidebar)
    Util.Padding(tabList, 2, 8, 8, 8)
    Util.List(tabList, 8)

    local contentArea = Util.Create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -141, 1, 0),
        Position = UDim2.new(0, 141, 0, 0),
        BackgroundTransparency = 1
    }, content)

    local header = Util.Create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1
    }, contentArea)

    local pageHolder = Util.Create("Frame", {
        Name = "PageHolder",
        Size = UDim2.new(1, 0, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundTransparency = 1
    }, contentArea)

    local breadcrumb = Util.Create("Frame", {
        Name = "Breadcrumb",
        Size = UDim2.new(1, -176, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true
    }, header)
    Util.List(breadcrumb, 4, {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center
    })

    local searchFrame = Util.Create("Frame", {
        Name = "SearchFrame",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 140, 0, isTouch and 30 or 26),
        BackgroundColor3 = Theme.Field,
        BorderSizePixel = 0
    }, header)
    Util.Corner(searchFrame, 6)
    Util.Stroke(searchFrame, Theme.Border, 1)

    local searchIcon = Icons.Create(searchFrame, "search", 14, Theme.Dim)
    searchIcon.AnchorPoint = Vector2.new(0, 0.5)
    searchIcon.Position = UDim2.new(0, 8, 0.5, 0)

    local searchButton = Util.Create("TextButton", {
        Name = "SearchButton",
        Size = UDim2.new(1, -34, 1, 0),
        Position = UDim2.new(0, 28, 0, 0),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "Search...",
        TextColor3 = Theme.Placeholder,
        TextSize = 13,
        Font = Enum.Font.SourceSans,
        TextXAlignment = Enum.TextXAlignment.Left
    }, searchFrame)

    local resizeButton = Util.Create("TextButton", {
        Name = "ResizeButton",
        Size = UDim2.new(0, isTouch and 24 or 16, 0, isTouch and 24 or 16),
        Position = UDim2.new(1, isTouch and -24 or -16, 1, isTouch and -24 or -16),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 10
    }, main)

    self.Gui = gui
    self.Main = main
    self.Sidebar = sidebar
    self.Dashboard = dashboard
    self.TitleText = titleText
    self.SubTitleText = subTitleText
    self.TabList = tabList
    self.Header = header
    self.PageHolder = pageHolder
    self.Breadcrumb = breadcrumb
    self.SearchButton = searchButton
    self.ResizeButton = resizeButton

    self:_ApplySize(Config.DefaultSize)

    searchButton.Activated:Connect(function()
        self:OpenSearch()
    end)
end

function Window:_BuildPanel()
    local window = self
    local Panel = {}

    local function arg(first, second)
        if rawequal(first, Panel) then
            return second
        end
        return first
    end

    Panel.Header = self.Header
    Panel.PageHolder = self.PageHolder
    Panel.TabList = self.TabList
    Panel.CreateIcon = Icons.Create

    function Panel.SetVisible(a, b)
        window:SetVisible(arg(a, b))
    end
    function Panel.Toggle()
        window:Toggle()
    end
    function Panel.SetBreadcrumb(a, b)
        window:_SetBreadcrumb(arg(a, b))
    end
    function Panel.OpenSearch()
        window:OpenSearch()
    end
    function Panel.CloseSearch()
        window:CloseSearch()
    end

    local registry = ElementRegistry.new()
    registry.Panel = Panel
    registry.OnChanged = function()
        window:RefreshSearch()
    end
    Panel.Elements = registry

    self.Panel = Panel
    self.Elements = registry
end

function Window:_BuildToggle()
    local toggleGui = Util.Create("ScreenGui", {
        Name = "EcoHubToggle",
        ResetOnSpawn = false,
        Enabled = false,
        DisplayOrder = 99999
    }, PlayerGui)

    local button = Util.Create("TextButton", {
        Name = "ToggleButton",
        Size = UDim2.new(0, 48, 0, 48),
        Position = UDim2.new(0, 20, 0.5, -24),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ClipsDescendants = true
    }, toggleGui)
    Util.Corner(button, 10)
    Util.Create("UIStroke", {
        Color = Theme.Border,
        Thickness = 1.5,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, button)

    local texture = Util.Create("ImageLabel", {
        Name = "Texture",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = Config.ToggleImage,
        ImageTransparency = 0.3,
        ScaleType = Enum.ScaleType.Crop,
        ZIndex = 1
    }, button)
    Util.Corner(texture, 10)

    self.ToggleGui = toggleGui
    self.ToggleButton = button
end

function Window:_BindToggleDrag()
    local button = self.ToggleButton
    local isDrag = false
    local dragStart = Vector3.zero
    local startPosition = button.Position
    local moveConnection, endConnection

    local function stop()
        if moveConnection then
            moveConnection:Disconnect()
            moveConnection = nil
        end
        if endConnection then
            endConnection:Disconnect()
            endConnection = nil
        end
    end
    self.Maid:Add(stop)

    button.InputBegan:Connect(function(input)
        if not Util.IsPress(input) then
            return
        end
        isDrag = false
        dragStart = input.Position
        startPosition = button.Position
        stop()

        moveConnection = UserInputService.InputChanged:Connect(function(moveInput)
            if not Util.IsMove(moveInput) then
                return
            end
            local delta = moveInput.Position - dragStart
            if delta.Magnitude > 6 then
                isDrag = true
            end
            if isDrag then
                button.Position = UDim2.new(
                    startPosition.X.Scale, startPosition.X.Offset + delta.X,
                    startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
                )
            end
        end)

        endConnection = UserInputService.InputEnded:Connect(function(endInput)
            if not Util.IsPress(endInput) then
                return
            end
            stop()
            if not isDrag then
                self:Toggle()
            end
            isDrag = false
        end)
    end)
end

function Window:_BindInput()
    self.Maid:Connect(UserInputService.InputBegan, function(input, processed)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end
        if self.Created and not processed and input.KeyCode == self.MinimizeKey then
            self:Toggle()
            return
        end

        local palette = self.Palette
        if not palette.IsOpen then
            return
        end
        if input.KeyCode == Enum.KeyCode.Escape then
            palette:Close()
        elseif input.KeyCode == Enum.KeyCode.Down then
            palette:Move(1)
        elseif input.KeyCode == Enum.KeyCode.Up then
            palette:Move(-1)
        end
    end)
end

function Window:_MakeDraggable(handle, target)
    local dragging = false
    local dragStart = Vector3.zero
    local startPosition = target.Position

    handle.InputBegan:Connect(function(input)
        if not Util.IsPress(input) then
            return
        end
        dragging = true
        dragStart = input.Position
        startPosition = target.Position

        local changed
        changed = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                changed:Disconnect()
            end
        end)
    end)

    self.Maid:Connect(UserInputService.InputChanged, function(input)
        if not dragging or not Util.IsMove(input) then
            return
        end
        local delta = input.Position - dragStart
        target.Position = UDim2.new(
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
    end)
end

function Window:_BindResize()
    local resizing = false
    local startSize = Vector2.zero
    local startMouse = Vector3.zero

    self.ResizeButton.InputBegan:Connect(function(input)
        if self.Gui.Enabled and Util.IsPress(input) then
            resizing = true
            startSize = self.Main.AbsoluteSize
            startMouse = input.Position
        end
    end)

    self.Maid:Connect(UserInputService.InputEnded, function(input)
        if Util.IsPress(input) then
            resizing = false
        end
    end)

    self.Maid:Connect(UserInputService.InputChanged, function(input)
        if not resizing or not Util.IsMove(input) then
            return
        end
        local delta = input.Position - startMouse
        local viewport = Util.GetViewport()
        local maxWidth = math.max(320, math.min(900, viewport.X - 16))
        local maxHeight = math.max(240, math.min(700, viewport.Y - 16))
        local newWidth = math.clamp(startSize.X + delta.X, math.min(450, maxWidth), maxWidth)
        local newHeight = math.clamp(startSize.Y + delta.Y, math.min(300, maxHeight), maxHeight)
        self.Main.Size = UDim2.new(0, newWidth, 0, newHeight)
    end)
end

function Window:_ApplySize(size)
    local viewport = Util.GetViewport()
    local width = math.clamp(size.X.Offset + size.X.Scale * viewport.X, 320, math.max(320, viewport.X - 16))
    local height = math.clamp(size.Y.Offset + size.Y.Scale * viewport.Y, 240, math.max(240, viewport.Y - 16))
    self.Main.Size = UDim2.fromOffset(width, height)
    self.Main.Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2)
end

function Window:_SetBreadcrumb(items)
    if type(items) ~= "table" then
        return
    end
    for _, child in ipairs(self.Breadcrumb:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end

    local total = #items
    for i, text in ipairs(items) do
        local isLast = i == total
        Util.Create("TextLabel", {
            Name = "Item" .. i,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 0, 20),
            BackgroundTransparency = 1,
            Text = tostring(text),
            TextSize = 14,
            Font = isLast and Enum.Font.SourceSansBold or Enum.Font.SourceSans,
            TextColor3 = isLast and Theme.Active or Theme.Inactive,
            LayoutOrder = i * 2 - 1
        }, self.Breadcrumb)

        if not isLast then
            local sep = Icons.Create(self.Breadcrumb, "chevron-right", 14, Theme.Dim)
            sep.Name = "Sep" .. i
            sep.LayoutOrder = i * 2
        end
    end
end

function Window:_RegisterTab(tab)
    self.Tabs[#self.Tabs + 1] = tab
    if not self.ActiveTab then
        self:SelectTab(tab)
    end
    self:RefreshSearch()
end

function Window:Configure(config)
    config = type(config) == "table" and config or {}
    if config.Title ~= nil then
        self.TitleText.Text = tostring(config.Title)
    end
    if config.SubTitle ~= nil then
        self.SubTitleText.Text = tostring(config.SubTitle)
    end
    if typeof(config.Size) == "UDim2" then
        self:_ApplySize(config.Size)
    end
    if typeof(config.MinimizeKey) == "EnumItem" then
        self.MinimizeKey = config.MinimizeKey
    end
end

function Window:CreateTab(config)
    config = type(config) == "table" and config or {tab = config}
    local tabName = tostring(config.tab or config.Tab or config.Name or config.Title or "Tab")
    local sectionName = tostring(config.section or config.Section or "Main")
    local iconName = config.icon or config.Icon

    local section = self.SideSectionsByName[sectionName]
    if not section then
        section = SideSection.new(self, sectionName)
        self.SideSections[#self.SideSections + 1] = section
        self.SideSectionsByName[sectionName] = section
    end

    local _, tab = section:AddTab(tabName, iconName)
    return tab
end

function Window:GetTab(key)
    if type(key) == "number" then
        return self.Tabs[key]
    end
    for _, tab in ipairs(self.Tabs) do
        if tab.Name == key then
            return tab
        end
    end
    return nil
end

function Window:SelectTab(tab)
    if type(tab) ~= "table" then
        tab = self:GetTab(tab)
    end
    if not tab or not tab.Page or self.ActiveTab == tab then
        return
    end

    local previous = self.ActiveTab
    if previous then
        previous.Page.Visible = false
    end
    self.ActiveTab = tab
    tab.Page.Visible = true
    if previous then
        previous:Style()
    end
    tab:Style()
    self:_SetBreadcrumb({tab.Section.Name, tab.Name})
end

function Window:SetVisible(state)
    if not self.Created or self.Destroyed then
        return
    end
    state = state and true or false
    if not state then
        self.Palette:Close()
    end
    self.Gui.Enabled = state
end

function Window:Toggle()
    self:SetVisible(not self.Gui.Enabled)
end

function Window:SetMinimized(state)
    self:SetVisible(not state)
end

function Window:IsMinimized()
    return not self.Gui.Enabled
end

function Window:OpenSearch()
    self.Palette:Open()
end

function Window:CloseSearch()
    self.Palette:Close()
end

function Window:RefreshSearch()
    if self.Palette then
        self.Palette:Refresh()
    end
end

function Window:ClearSearch()
    self.Palette.Input.Text = ""
end

function Window:SetTitle(text)
    self.TitleText.Text = tostring(text)
end

function Window:SetSubTitle(text)
    self.SubTitleText.Text = tostring(text)
end

function Window:SetMinimizeKey(keyCode)
    if typeof(keyCode) == "EnumItem" then
        self.MinimizeKey = keyCode
    end
end

function Window:Destroy()
    if self.Destroyed then
        return
    end
    self.Destroyed = true
    self.Elements.Destroyed = true
    self.Maid:Destroy()
    self.Gui:Destroy()
    self.ToggleGui:Destroy()

    env.EcoHubPanel = nil
    env.EcoHubElements = nil
    env.EcoHubDestroy = nil
    if Library.Window == self then
        Library.Window = nil
    end
end

-- // Library API
function Library:CreateWindow(config)
    if not rawequal(self, Library) and config == nil then
        config = self
    end

    local window = Library.Window
    if window and not window.Destroyed then
        window:Configure(config)
        return window
    end

    window = Window.new(config)
    Library.Window = window

    env.EcoHubPanel = window.Panel
    env.EcoHubElements = window.Elements
    env.EcoHubDestroy = function()
        window:Destroy()
    end

    window.Created = true
    window.Gui.Enabled = true
    window.ToggleGui.Enabled = true
    window.Elements:Load()
    return window
end

-- // Inicialização
if type(env.EcoHubDestroy) == "function" then
    pcall(env.EcoHubDestroy)
end
for _, name in ipairs({"EcoHub", "EcoHubToggle"}) do
    local old = PlayerGui:FindFirstChild(name)
    if old then
        old:Destroy()
    end
end

env.EcoHubLibrary = Library
Icons.Load()

return Library