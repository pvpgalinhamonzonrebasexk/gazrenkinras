local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local env = getgenv and getgenv() or _G
local isTouch = UserInputService.TouchEnabled
local function getViewport()
    local camera = workspace.CurrentCamera
    if camera then
        return camera.ViewportSize
    end
    return Vector2.new(1280, 720)
end
local connections = {}
local function connect(signal, callback)
    local connection = signal:Connect(callback)
    connections[#connections + 1] = connection
    return connection
end
local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FLASH_INFO = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local COLOR_ACTIVE = Color3.fromRGB(240, 240, 240)
local COLOR_INACTIVE = Color3.fromRGB(165, 165, 165)
local COLOR_DIM = Color3.fromRGB(115, 115, 115)
local COLOR_ACCENT = Color3.fromRGB(42, 42, 42)
local COLOR_FIELD = Color3.fromRGB(34, 34, 34)
local COLOR_BORDER = Color3.fromRGB(55, 55, 55)
local COLOR_PALETTE = Color3.fromRGB(28, 28, 28)
local REPO = "pvpgalinhamonzonrebasexk/monzonrebasexk"
local BRANCH = "main"
local ELEMENTS_PATH = "Library/Elements"
local ELEMENTS_API = "https://api.github.com/repos/" .. REPO .. "/contents/" .. ELEMENTS_PATH .. "?ref=" .. BRANCH
local ELEMENTS_RAW = "https://raw.githubusercontent.com/" .. REPO .. "/refs/heads/" .. BRANCH .. "/" .. ELEMENTS_PATH .. "/"
local FEATURES_SOURCE = "https://github.com/" .. REPO .. "/tree/main/Features"
local FEATURES_TREE_API = "https://api.github.com/repos/" .. REPO .. "/git/trees/" .. BRANCH .. "?recursive=1"
local FEATURES_RAW_BASE = "https://raw.githubusercontent.com/" .. REPO .. "/" .. BRANCH .. "/"
if type(env.EcoHubDestroy) == "function" then
    pcall(env.EcoHubDestroy)
end
for _, name in ipairs({"EcoHub", "EcoHubToggle"}) do
    local old = PlayerGui:FindFirstChild(name)
    if old then
        old:Destroy()
    end
end
local closePalette
local refreshPalette
local State = {Created = false, MinimizeKey = Enum.KeyCode.RightShift}
local iconAssets = env.EcoHubIcons
local pendingIcons = {}
local function applyIcon(icon, name)
    name = tostring(name or "circle")
    local id = iconAssets["lucide-" .. name] or iconAssets[name] or iconAssets["lucide-circle"] or iconAssets["circle"]
    if id then
        icon.Image = id
    end
end
local function createIcon(parent, name, size, color)
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, size, 0, size)
    icon.BackgroundTransparency = 1
    icon.ImageColor3 = color
    icon.Parent = parent
    if iconAssets then
        applyIcon(icon, name)
    else
        pendingIcons[#pendingIcons + 1] = {icon, name}
    end
    return icon
end
if not iconAssets then
    task.spawn(function()
        local ok, result = pcall(function()
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/" .. REPO .. "/refs/heads/" .. BRANCH .. "/Assets/Icons.lua"))()
        end)
        if ok and type(result) == "table" and type(result.assets) == "table" then
            iconAssets = result.assets
            env.EcoHubIcons = result.assets
            for _, item in ipairs(pendingIcons) do
                if item[1].Parent then
                    applyIcon(item[1], item[2])
                end
            end
        end
        pendingIcons = {}
    end)
end
local EcoHub = Instance.new("ScreenGui")
EcoHub.Name = "EcoHub"
EcoHub.Parent = PlayerGui
EcoHub.ResetOnSpawn = false
EcoHub.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
EcoHub.Enabled = false
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 580, 0, 350)
MainFrame.Position = UDim2.new(0.5, -290, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = EcoHub
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = COLOR_BORDER
MainStroke.Thickness = 1
MainStroke.Parent = MainFrame
local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Size = UDim2.new(1, 0, 1, 0)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame
local function applySize(size)
    local viewport = getViewport()
    local width = math.clamp(size.X.Offset + size.X.Scale * viewport.X, 320, math.max(320, viewport.X - 16))
    local height = math.clamp(size.Y.Offset + size.Y.Scale * viewport.Y, 240, math.max(240, viewport.Y - 16))
    MainFrame.Size = UDim2.fromOffset(width, height)
    MainFrame.Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2)
end
applySize(UDim2.fromOffset(580, 350))
local TabSidebar = Instance.new("Frame")
TabSidebar.Name = "TabSidebar"
TabSidebar.Size = UDim2.new(0, 140, 1, 0)
TabSidebar.BackgroundTransparency = 1
TabSidebar.BorderSizePixel = 0
TabSidebar.Parent = ContentContainer
local TabLine = Instance.new("Frame")
TabLine.Name = "TabLine"
TabLine.Size = UDim2.new(0, 1, 1, 0)
TabLine.Position = UDim2.new(1, 0, 0, 0)
TabLine.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
TabLine.BorderSizePixel = 0
TabLine.Parent = TabSidebar
local Dashboard = Instance.new("Frame")
Dashboard.Name = "Dashboard"
Dashboard.Size = UDim2.new(1, 0, 0, 56)
Dashboard.BackgroundTransparency = 1
Dashboard.BorderSizePixel = 0
Dashboard.Parent = TabSidebar
local TitleText = Instance.new("TextLabel")
TitleText.Name = "TitleText"
TitleText.Size = UDim2.new(1, -20, 0, 18)
TitleText.Position = UDim2.new(0, 12, 0, 16)
TitleText.BackgroundTransparency = 1
TitleText.Text = "EcoHub"
TitleText.TextColor3 = COLOR_ACTIVE
TitleText.TextSize = 15
TitleText.Font = Enum.Font.SourceSansBold
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.TextTruncate = Enum.TextTruncate.AtEnd
TitleText.Parent = Dashboard
local SubTitleText = Instance.new("TextLabel")
SubTitleText.Name = "SubTitleText"
SubTitleText.Size = UDim2.new(1, -20, 0, 14)
SubTitleText.Position = UDim2.new(0, 12, 0, 34)
SubTitleText.BackgroundTransparency = 1
SubTitleText.Text = "v1.0.0"
SubTitleText.TextColor3 = Color3.fromRGB(150, 150, 150)
SubTitleText.TextSize = 12
SubTitleText.Font = Enum.Font.SourceSans
SubTitleText.TextXAlignment = Enum.TextXAlignment.Left
SubTitleText.TextTruncate = Enum.TextTruncate.AtEnd
SubTitleText.Parent = Dashboard
local TabList = Instance.new("ScrollingFrame")
TabList.Name = "TabList"
TabList.Size = UDim2.new(1, 0, 1, -56)
TabList.Position = UDim2.new(0, 0, 0, 56)
TabList.BackgroundTransparency = 1
TabList.BorderSizePixel = 0
TabList.ScrollBarThickness = 0
TabList.CanvasSize = UDim2.new(0, 0, 0, 0)
TabList.AutomaticCanvasSize = Enum.AutomaticSize.Y
TabList.Parent = TabSidebar
local TabListPadding = Instance.new("UIPadding")
TabListPadding.PaddingTop = UDim.new(0, 2)
TabListPadding.PaddingBottom = UDim.new(0, 8)
TabListPadding.PaddingLeft = UDim.new(0, 8)
TabListPadding.PaddingRight = UDim.new(0, 8)
TabListPadding.Parent = TabList
local TabListLayout = Instance.new("UIListLayout")
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 8)
TabListLayout.Parent = TabList
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -141, 1, 0)
ContentArea.Position = UDim2.new(0, 141, 0, 0)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = ContentContainer
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundTransparency = 1
Header.Parent = ContentArea
local PageHolder = Instance.new("Frame")
PageHolder.Name = "PageHolder"
PageHolder.Size = UDim2.new(1, 0, 1, -40)
PageHolder.Position = UDim2.new(0, 0, 0, 40)
PageHolder.BackgroundTransparency = 1
PageHolder.Parent = ContentArea
local Breadcrumb = Instance.new("Frame")
Breadcrumb.Name = "Breadcrumb"
Breadcrumb.Size = UDim2.new(1, -176, 1, 0)
Breadcrumb.Position = UDim2.new(0, 14, 0, 0)
Breadcrumb.BackgroundTransparency = 1
Breadcrumb.ClipsDescendants = true
Breadcrumb.Parent = Header
local BreadcrumbLayout = Instance.new("UIListLayout")
BreadcrumbLayout.FillDirection = Enum.FillDirection.Horizontal
BreadcrumbLayout.VerticalAlignment = Enum.VerticalAlignment.Center
BreadcrumbLayout.SortOrder = Enum.SortOrder.LayoutOrder
BreadcrumbLayout.Padding = UDim.new(0, 4)
BreadcrumbLayout.Parent = Breadcrumb
local SearchFrame = Instance.new("Frame")
SearchFrame.Name = "SearchFrame"
SearchFrame.AnchorPoint = Vector2.new(1, 0.5)
SearchFrame.Position = UDim2.new(1, -12, 0.5, 0)
SearchFrame.Size = UDim2.new(0, 140, 0, isTouch and 30 or 26)
SearchFrame.BackgroundColor3 = COLOR_FIELD
SearchFrame.BorderSizePixel = 0
SearchFrame.Parent = Header
local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 6)
SearchCorner.Parent = SearchFrame
local SearchStroke = Instance.new("UIStroke")
SearchStroke.Color = COLOR_BORDER
SearchStroke.Thickness = 1
SearchStroke.Parent = SearchFrame
local SearchIcon = createIcon(SearchFrame, "search", 14, COLOR_DIM)
SearchIcon.AnchorPoint = Vector2.new(0, 0.5)
SearchIcon.Position = UDim2.new(0, 8, 0.5, 0)
local SearchButton = Instance.new("TextButton")
SearchButton.Name = "SearchButton"
SearchButton.Size = UDim2.new(1, -34, 1, 0)
SearchButton.Position = UDim2.new(0, 28, 0, 0)
SearchButton.BackgroundTransparency = 1
SearchButton.AutoButtonColor = false
SearchButton.Text = "Search..."
SearchButton.TextColor3 = Color3.fromRGB(110, 110, 110)
SearchButton.TextSize = 13
SearchButton.Font = Enum.Font.SourceSans
SearchButton.TextXAlignment = Enum.TextXAlignment.Left
SearchButton.Parent = SearchFrame
local ResizeButton = Instance.new("TextButton")
ResizeButton.Name = "ResizeButton"
ResizeButton.Size = UDim2.new(0, isTouch and 24 or 16, 0, isTouch and 24 or 16)
ResizeButton.Position = UDim2.new(1, isTouch and -24 or -16, 1, isTouch and -24 or -16)
ResizeButton.BackgroundTransparency = 1
ResizeButton.Text = ""
ResizeButton.ZIndex = 10
ResizeButton.Parent = MainFrame
local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "EcoHubToggle"
ToggleGui.Parent = PlayerGui
ToggleGui.ResetOnSpawn = false
ToggleGui.Enabled = false
ToggleGui.DisplayOrder = 99999
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 48, 0, 48)
ToggleButton.Position = UDim2.new(0, 20, 0.5, -24)
ToggleButton.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = ""
ToggleButton.AutoButtonColor = false
ToggleButton.ClipsDescendants = true
ToggleButton.Parent = ToggleGui
local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 10)
ToggleCorner.Parent = ToggleButton
local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = COLOR_BORDER
ToggleStroke.Thickness = 1.5
ToggleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
ToggleStroke.Parent = ToggleButton
local ToggleTexture = Instance.new("ImageLabel")
ToggleTexture.Name = "Texture"
ToggleTexture.Size = UDim2.new(1, 0, 1, 0)
ToggleTexture.Position = UDim2.new(0.5, 0, 0.5, 0)
ToggleTexture.AnchorPoint = Vector2.new(0.5, 0.5)
ToggleTexture.BackgroundTransparency = 1
ToggleTexture.Image = "rbxassetid://77526194033506"
ToggleTexture.ImageTransparency = 0.3
ToggleTexture.ScaleType = Enum.ScaleType.Crop
ToggleTexture.ZIndex = 1
ToggleTexture.Parent = ToggleButton
local ToggleTextureCorner = Instance.new("UICorner")
ToggleTextureCorner.CornerRadius = UDim.new(0, 10)
ToggleTextureCorner.Parent = ToggleTexture
local function setVisibility(state)
    if not State.Created then
        return
    end
    if not state and closePalette then
        closePalette()
    end
    EcoHub.Enabled = state
end
local Panel = {}
Panel.Header = Header
Panel.PageHolder = PageHolder
Panel.TabList = TabList
Panel.CreateIcon = createIcon
local sections = {}
local sectionsByName = {}
local allTabs = {}
local activeTab = nil
local sectionOrder = 0
function Panel.SetVisible(state)
    setVisibility(state)
end
function Panel.Toggle()
    setVisibility(not EcoHub.Enabled)
end
function Panel.SetBreadcrumb(items)
    for _, child in ipairs(Breadcrumb:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
    local total = #items
    for i, text in ipairs(items) do
        local item = Instance.new("TextLabel")
        item.Name = "Item" .. i
        item.AutomaticSize = Enum.AutomaticSize.X
        item.Size = UDim2.new(0, 0, 0, 20)
        item.BackgroundTransparency = 1
        item.Text = text
        item.TextSize = 14
        item.Font = i == total and Enum.Font.SourceSansBold or Enum.Font.SourceSans
        item.TextColor3 = i == total and COLOR_ACTIVE or COLOR_INACTIVE
        item.LayoutOrder = i * 2 - 1
        item.Parent = Breadcrumb
        if i < total then
            local sep = createIcon(Breadcrumb, "chevron-right", 14, COLOR_DIM)
            sep.Name = "Sep" .. i
            sep.LayoutOrder = i * 2
        end
    end
end
local function styleTab(tab)
    local isActive = activeTab == tab
    local color = isActive and COLOR_ACTIVE or COLOR_INACTIVE
    tab.Button.BackgroundTransparency = isActive and 0 or 1
    tab.Label.TextColor3 = color
    tab.Label.Font = isActive and Enum.Font.SourceSansSemibold or Enum.Font.SourceSans
    tab.Icon.ImageColor3 = color
end
local function selectTab(tab)
    if activeTab == tab then
        return
    end
    local previous = activeTab
    if previous then
        previous.Page.Visible = false
    end
    activeTab = tab
    tab.Page.Visible = true
    if previous then
        styleTab(previous)
    end
    styleTab(tab)
    Panel.SetBreadcrumb({tab.Section.Name, tab.Name})
end
local function animateMenu(section)
    local menu = section.Menu
    local count = 0
    for _, tab in ipairs(section.Tabs) do
        if tab.Button.Visible then
            count = count + 1
        end
    end
    local full = math.max(count * 34 - 2, 0)
    section.Token = section.Token + 1
    local token = section.Token
    menu.AutomaticSize = Enum.AutomaticSize.None
    if section.Open then
        menu.Visible = true
        local tween = TweenService:Create(menu, TWEEN_INFO, {Size = UDim2.new(1, 0, 0, full)})
        tween.Completed:Connect(function()
            if section.Token == token and section.Open then
                menu.AutomaticSize = Enum.AutomaticSize.Y
                menu.Size = UDim2.new(1, 0, 0, 0)
            end
        end)
        tween:Play()
    else
        menu.Size = UDim2.new(1, 0, 0, full)
        local tween = TweenService:Create(menu, TWEEN_INFO, {Size = UDim2.new(1, 0, 0, 0)})
        tween.Completed:Connect(function()
            if section.Token == token and not section.Open then
                menu.Visible = false
            end
        end)
        tween:Play()
    end
end
local Elements = {Registry = {}, Pending = {}, Files = {}, Active = 0}
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
local function resolveKey(name)
    local key = string.lower(tostring(name))
    return ELEMENT_ALIASES[key] or key
end
local function applyFrame(element, frameless)
    local pad = frameless and 0 or 4
    local side = frameless and 0 or 10
    element.Container.BackgroundTransparency = frameless and 1 or 0
    element.Border.Enabled = not frameless
    element.Inset.PaddingTop = UDim.new(0, pad)
    element.Inset.PaddingBottom = UDim.new(0, pad)
    element.Inset.PaddingLeft = UDim.new(0, side)
    element.Inset.PaddingRight = UDim.new(0, side)
end
local function buildElement(element, entry, options)
    if element.Destroyed then
        return
    end
    applyFrame(element, entry.Frameless)
    local scope = {
        frame = element.Container,
        Panel = Panel,
        Tab = element.Tab,
        Section = element.Section,
        Element = element,
        Elements = Elements,
        CreateIcon = createIcon
    }
    local ok, result = pcall(entry.Builder, scope, options)
    if not ok then
        warn("[EcoHub] element '" .. element.Type .. "' failed: " .. tostring(result))
        return
    end
    element.Container.Visible = true
    element.Built = true
    element.Instance = type(result) == "table" and result or {}
    local calls = element.Calls
    element.Calls = {}
    for _, call in ipairs(calls) do
        local method = element.Instance[call.Name]
        if type(method) == "function" then
            pcall(method, element.Instance, table.unpack(call.Args, 1, call.Count))
        end
    end
end
local function createHandle(element)
    return setmetatable({Element = element}, {
        __index = function(_, key)
            if key == "Destroy" then
                return function()
                    element.Destroyed = true
                    local api = element.Instance
                    if api and type(api.Destroy) == "function" then
                        pcall(api.Destroy, api)
                    end
                    local index = table.find(element.Tab.Elements, element)
                    if index then
                        table.remove(element.Tab.Elements, index)
                    end
                    element.Container:Destroy()
                    if refreshPalette then
                        refreshPalette()
                    end
                end
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
function Elements.Register(name, builder, meta)
    if type(name) ~= "string" or type(builder) ~= "function" then
        return
    end
    local key = resolveKey(name)
    local frameless = key == "button"
    if type(meta) == "table" and meta.Frameless ~= nil then
        frameless = meta.Frameless and true or false
    end
    local entry = {Name = name, Builder = builder, Frameless = frameless}
    Elements.Registry[key] = entry
    local queue = Elements.Pending[key]
    if queue then
        Elements.Pending[key] = nil
        for _, job in ipairs(queue) do
            buildElement(job.Element, entry, job.Options)
        end
    end
    if refreshPalette then
        refreshPalette()
    end
end
function Elements.Get(name)
    return Elements.Registry[resolveKey(name)]
end
function Elements.List()
    local names = {}
    for _, entry in pairs(Elements.Registry) do
        names[#names + 1] = entry.Name
    end
    table.sort(names)
    return names
end
local function runElementChunk(chunk)
    local scoped = false
    if type(setfenv) == "function" and type(getfenv) == "function" then
        scoped = pcall(function()
            local scope = setmetatable({Elements = Elements, Panel = Panel}, {__index = getfenv(chunk)})
            setfenv(chunk, scope :: any)
        end)
    end
    if not scoped then
        env.Elements = Elements
    end
    return chunk(Elements, Panel)
end
local function loadElementFile(file)
    local names = {file}
    if not string.match(file, "%.luau?$") then
        names = {file .. ".luau", file .. ".lua"}
    end
    local lastError = "not found"
    for _, candidate in ipairs(names) do
        local ok, result = pcall(function()
            local source = game:HttpGet(ELEMENTS_RAW .. candidate)
            local chunk, compileError = loadstring(source)
            if not chunk then
                error(compileError, 0)
            end
            return runElementChunk(chunk)
        end)
        if ok then
            return true
        end
        lastError = result
    end
    warn("[EcoHub] could not load element '" .. file .. "': " .. tostring(lastError))
    return false
end
function Elements.Load(names)
    names = names or env.EcoHubElementList
    Elements.Active = Elements.Active + 1
    task.spawn(function()
        local files = {}
        if type(names) == "table" then
            for _, name in ipairs(names) do
                files[#files + 1] = name
            end
        else
            local ok, list = pcall(function()
                return HttpService:JSONDecode(game:HttpGet(ELEMENTS_API))
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
        end
        local remaining = 0
        for _, file in ipairs(files) do
            local id = string.lower((string.gsub(file, "%.luau?$", "")))
            if not Elements.Files[id] then
                Elements.Files[id] = true
                remaining = remaining + 1
                task.spawn(function()
                    loadElementFile(file)
                    remaining = remaining - 1
                end)
            end
        end
        local waited = 0
        while remaining > 0 and waited < 30 do
            task.wait(0.1)
            waited = waited + 0.1
        end
        Elements.Active = Elements.Active - 1
        if Elements.Active == 0 then
            for key, queue in pairs(Elements.Pending) do
                for _, job in ipairs(queue) do
                    warn("[EcoHub] element type '" .. job.Element.Type .. "' was not found in " .. ELEMENTS_PATH)
                end
                Elements.Pending[key] = nil
            end
        end
    end)
end
Panel.Elements = Elements

local Features = {Loaded = {}}
local function getHttpRequest()
    return request or http_request or (syn and syn.request)
end
local function cleanFeatureName(name)
    name = name:gsub("\\", "/")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    name = name:gsub("^/+", ""):gsub("/+$", "")
    name = name:gsub("%.luau$", ""):gsub("%.lua$", "")
    return name
end
local function resolveFeatureUrl(nameOrUrl)
    if nameOrUrl:match("^https?://") then
        return nameOrUrl:gsub("^https?://github%.com/([^/]+)/([^/]+)/blob/", "https://raw.githubusercontent.com/%1/%2/")
    end
    local clean = cleanFeatureName(nameOrUrl)
    return FEATURES_RAW_BASE .. clean .. ".luau"
end
local function runFeatureSource(source, name)
    local fn, err = loadstring(source, "=" .. name)
    if not fn then
        warn("[EcoHub] feature compilation error '" .. name .. "': " .. tostring(err))
        return false
    end
    local ok, runErr = pcall(fn)
    if not ok then
        warn("[EcoHub] feature execution error '" .. name .. "': " .. tostring(runErr))
        return false
    end
    Features.Loaded[name] = true
    return true
end
function Features.Load(nameOrList)
    if type(nameOrList) == "table" then
        local results = {}
        for _, item in ipairs(nameOrList) do
            results[item] = Features.Load(item)
        end
        return results
    end
    if tostring(nameOrList):lower() == "all" then
        local ok, treeBody = pcall(function()
            local req = getHttpRequest()
            if req then
                local res = req({Url = FEATURES_TREE_API, Method = "GET"})
                return res and res.Body
            end
            return game:HttpGet(FEATURES_TREE_API)
        end)
        if ok and treeBody then
            local decoded = pcall(function() return HttpService:JSONDecode(treeBody) end)
            if type(decoded) == "table" and type(decoded.tree) == "table" then
                local loadedAny = false
                for _, node in ipairs(decoded.tree) do
                    if node.type == "blob" and type(node.path) == "string" and (node.path:sub(-5) == ".luau" or node.path:sub(-4) == ".lua") then
                        if node.path:sub(1, 9) == "Features/" or not node.path:find("/") then
                            local url = FEATURES_RAW_BASE .. node.path
                            local sOk, body = pcall(function()
                                local req = getHttpRequest()
                                if req then
                                    local res = req({Url = url, Method = "GET"})
                                    return res and res.Body
                                end
                                return game:HttpGet(url)
                            end)
                            if sOk and body then
                                runFeatureSource(body, node.path)
                                loadedAny = true
                            end
                        end
                    end
                end
                return loadedAny
            end
        end
        return false
    end
    local name = tostring(nameOrList)
    local url = resolveFeatureUrl(name)
    local ok, body = pcall(function()
        local req = getHttpRequest()
        if req then
            local res = req({Url = url, Method = "GET"})
            return res and res.Body
        end
        return game:HttpGet(url)
    end)
    if not ok or not body then
        local altUrl = FEATURES_RAW_BASE .. cleanFeatureName(name) .. ".lua"
        local sOk, sBody = pcall(function()
            local req = getHttpRequest()
            if req then
                local res = req({Url = altUrl, Method = "GET"})
                return res and res.Body
            end
            return game:HttpGet(altUrl)
        end)
        if sOk and sBody then
            body = sBody
        else
            warn("[EcoHub] could not fetch feature '" .. name .. "'")
            return false
        end
    end
    return runFeatureSource(body, name)
end
function Features.IsLoaded(name)
    return Features.Loaded[cleanFeatureName(tostring(name))] == true
end
function Features.ListLoaded()
    local list = {}
    for k, _ in pairs(Features.Loaded) do
        list[#list + 1] = k
    end
    table.sort(list)
    return list
end
Panel.Features = Features

function Panel.AddSection(name)
    sectionOrder = sectionOrder + 1
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = sectionOrder
    frame.Parent = TabList
    local frameLayout = Instance.new("UIListLayout")
    frameLayout.SortOrder = Enum.SortOrder.LayoutOrder
    frameLayout.Padding = UDim.new(0, 2)
    frameLayout.Parent = frame
    local labelButton = Instance.new("TextButton")
    labelButton.Name = "Label"
    labelButton.Size = UDim2.new(1, 0, 0, 24)
    labelButton.BackgroundTransparency = 1
    labelButton.AutoButtonColor = false
    labelButton.Text = name
    labelButton.TextColor3 = COLOR_DIM
    labelButton.TextSize = 12
    labelButton.Font = Enum.Font.SourceSansSemibold
    labelButton.TextXAlignment = Enum.TextXAlignment.Left
    labelButton.LayoutOrder = 0
    labelButton.Parent = frame
    local labelPadding = Instance.new("UIPadding")
    labelPadding.PaddingLeft = UDim.new(0, 8)
    labelPadding.Parent = labelButton
    local chevron = createIcon(labelButton, "chevron-down", 14, COLOR_DIM)
    chevron.AnchorPoint = Vector2.new(1, 0.5)
    chevron.Position = UDim2.new(1, -6, 0.5, 0)
    local menu = Instance.new("Frame")
    menu.Name = "Menu"
    menu.Size = UDim2.new(1, 0, 0, 0)
    menu.AutomaticSize = Enum.AutomaticSize.Y
    menu.BackgroundTransparency = 1
    menu.LayoutOrder = 1
    menu.ClipsDescendants = true
    menu.Parent = frame
    local menuLayout = Instance.new("UIListLayout")
    menuLayout.SortOrder = Enum.SortOrder.LayoutOrder
    menuLayout.Padding = UDim.new(0, 2)
    menuLayout.Parent = menu
    local section = {Name = name, Frame = frame, Menu = menu, Tabs = {}, Open = true, Token = 0}
    labelButton.Activated:Connect(function()
        section.Open = not section.Open
        TweenService:Create(chevron, TWEEN_INFO, {Rotation = section.Open and 0 or -90}):Play()
        animateMenu(section)
    end)
    function section:AddTab(tabName, iconName)
        local button = Instance.new("TextButton")
        button.Name = tabName
        button.Size = UDim2.new(1, 0, 0, 32)
        button.BackgroundColor3 = COLOR_ACCENT
        button.BackgroundTransparency = 1
        button.BorderSizePixel = 0
        button.AutoButtonColor = false
        button.Text = ""
        button.LayoutOrder = #self.Tabs + 1
        button.Parent = self.Menu
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = button
        local icon = createIcon(button, iconName or "circle", 16, COLOR_INACTIVE)
        icon.AnchorPoint = Vector2.new(0, 0.5)
        icon.Position = UDim2.new(0, 8, 0.5, 0)
        local label = Instance.new("TextLabel")
        label.Name = "Text"
        label.Size = UDim2.new(1, -36, 1, 0)
        label.Position = UDim2.new(0, 32, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = tabName
        label.TextColor3 = COLOR_INACTIVE
        label.TextSize = 14
        label.Font = Enum.Font.SourceSans
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.Parent = button
        local page = Instance.new("Frame")
        page.Name = tabName
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.Visible = false
        page.Parent = PageHolder
        local scroll = Instance.new("ScrollingFrame")
        scroll.Name = "Scroll"
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = isTouch and 3 or 2
        scroll.ScrollBarImageColor3 = COLOR_BORDER
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.ScrollingDirection = Enum.ScrollingDirection.Y
        scroll.Parent = page
        local scrollPadding = Instance.new("UIPadding")
        scrollPadding.PaddingTop = UDim.new(0, 4)
        scrollPadding.PaddingBottom = UDim.new(0, 12)
        scrollPadding.PaddingLeft = UDim.new(0, 12)
        scrollPadding.PaddingRight = UDim.new(0, 12)
        scrollPadding.Parent = scroll
        local scrollLayout = Instance.new("UIListLayout")
        scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
        scrollLayout.Padding = UDim.new(0, 14)
        scrollLayout.Parent = scroll
        local tab = {
            Name = tabName,
            IconName = iconName or "circle",
            Section = self,
            Button = button,
            Label = label,
            Icon = icon,
            Page = page,
            Scroll = scroll,
            Sections = {},
            Elements = {}
        }
        self.Tabs[#self.Tabs + 1] = tab
        allTabs[#allTabs + 1] = tab
        function tab:CreateSection(contentName)
            contentName = tostring(contentName or "Section")
            local contentSection = {Name = contentName, Tab = tab, Count = 0}
            local contentFrame = Instance.new("Frame")
            contentFrame.Name = contentName
            contentFrame.Size = UDim2.new(1, 0, 0, 0)
            contentFrame.AutomaticSize = Enum.AutomaticSize.Y
            contentFrame.BackgroundTransparency = 1
            contentFrame.LayoutOrder = #tab.Sections + 1
            contentFrame.Parent = scroll
            local contentLayout = Instance.new("UIListLayout")
            contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
            contentLayout.Padding = UDim.new(0, 6)
            contentLayout.Parent = contentFrame
            local title = Instance.new("TextLabel")
            title.Name = "Title"
            title.Size = UDim2.new(1, 0, 0, 16)
            title.BackgroundTransparency = 1
            title.Text = contentName
            title.TextColor3 = COLOR_DIM
            title.TextSize = 12
            title.Font = Enum.Font.SourceSansSemibold
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.LayoutOrder = 0
            title.Parent = contentFrame
            local titlePadding = Instance.new("UIPadding")
            titlePadding.PaddingLeft = UDim.new(0, 2)
            titlePadding.Parent = title
            local holder = Instance.new("Frame")
            holder.Name = "Holder"
            holder.Size = UDim2.new(1, 0, 0, 0)
            holder.AutomaticSize = Enum.AutomaticSize.Y
            holder.BackgroundTransparency = 1
            holder.LayoutOrder = 1
            holder.Parent = contentFrame
            local holderLayout = Instance.new("UIListLayout")
            holderLayout.SortOrder = Enum.SortOrder.LayoutOrder
            holderLayout.Padding = UDim.new(0, 6)
            holderLayout.Parent = holder
            contentSection.Frame = contentFrame
            contentSection.Holder = holder
            function contentSection:AddElement(elementType, options)
                options = type(options) == "table" and options or {}
                elementType = tostring(elementType)
                contentSection.Count = contentSection.Count + 1
                local key = resolveKey(elementType)
                local container = Instance.new("Frame")
                container.Name = elementType
                container.Size = UDim2.new(1, 0, 0, 0)
                container.AutomaticSize = Enum.AutomaticSize.Y
                container.BackgroundColor3 = COLOR_FIELD
                container.BorderSizePixel = 0
                container.LayoutOrder = contentSection.Count
                container.Visible = false
                container.Parent = holder
                local containerCorner = Instance.new("UICorner")
                containerCorner.CornerRadius = UDim.new(0, 6)
                containerCorner.Parent = container
                local containerLimit = Instance.new("UISizeConstraint")
                containerLimit.MinSize = Vector2.new(0, 32)
                containerLimit.Parent = container
                local border = Instance.new("UIStroke")
                border.Name = "Border"
                border.Color = COLOR_BORDER
                border.Thickness = 1
                border.Parent = container
                local flash = Instance.new("UIStroke")
                flash.Name = "Flash"
                flash.Color = COLOR_ACTIVE
                flash.Thickness = 1.5
                flash.Transparency = 1
                flash.Parent = container
                local inset = Instance.new("UIPadding")
                inset.Name = "Inset"
                inset.Parent = container
                local elementName = tostring(options.title or options.Title or options.name or options.Name or options.Text or options.Label or elementType)
                local description = tostring(options.description or options.Description or "")
                local element = {
                    Type = elementType,
                    Name = elementName,
                    Group = contentName,
                    Search = string.lower(elementName .. " " .. elementType .. " " .. contentName .. " " .. tabName .. " " .. description),
                    Tab = tab,
                    Section = contentSection,
                    Container = container,
                    Border = border,
                    Flash = flash,
                    Inset = inset,
                    Calls = {}
                }
                container.Name = element.Name
                tab.Elements[#tab.Elements + 1] = element
                local entry = Elements.Registry[key]
                if entry then
                    buildElement(element, entry, options)
                else
                    applyFrame(element, key == "button")
                    local queue = Elements.Pending[key]
                    if not queue then
                        queue = {}
                        Elements.Pending[key] = queue
                    end
                    queue[#queue + 1] = {Element = element, Options = options}
                end
                if refreshPalette then
                    refreshPalette()
                end
                return createHandle(element)
            end
            contentSection.CreateElement = contentSection.AddElement
            function contentSection:SetTitle(text)
                title.Text = tostring(text)
            end
            setmetatable(contentSection, {
                __index = function(_, key)
                    if type(key) ~= "string" then
                        return nil
                    end
                    local elementName = string.match(key, "^Create(%u%w*)$") or string.match(key, "^Add(%u%w*)$")
                    if not elementName then
                        return nil
                    end
                    return function(self, options)
                        return self:AddElement(elementName, options)
                    end
                end
            })
            tab.Sections[#tab.Sections + 1] = contentSection
            return contentSection
        end
        tab.AddSection = tab.CreateSection
        function tab:Select()
            selectTab(tab)
        end
        button.Activated:Connect(function()
            selectTab(tab)
        end)
        button.MouseEnter:Connect(function()
            if activeTab ~= tab then
                button.BackgroundTransparency = 0.5
                label.TextColor3 = COLOR_ACTIVE
                icon.ImageColor3 = COLOR_ACTIVE
            end
        end)
        button.MouseLeave:Connect(function()
            styleTab(tab)
        end)
        if not activeTab then
            selectTab(tab)
        end
        if refreshPalette then
            refreshPalette()
        end
        return page, tab
    end
    sections[#sections + 1] = section
    sectionsByName[name] = section
    return section
end

local Palette = {Open = false, Token = 0, Items = {}, Selected = 0}
local PaletteOverlay = Instance.new("TextButton")
PaletteOverlay.Name = "PaletteOverlay"
PaletteOverlay.Size = UDim2.new(1, 0, 1, 0)
PaletteOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
PaletteOverlay.BackgroundTransparency = 1
PaletteOverlay.BorderSizePixel = 0
PaletteOverlay.AutoButtonColor = false
PaletteOverlay.Text = ""
PaletteOverlay.Visible = false
PaletteOverlay.ZIndex = 20
PaletteOverlay.Parent = MainFrame
local PaletteOverlayCorner = Instance.new("UICorner")
PaletteOverlayCorner.CornerRadius = UDim.new(0, 8)
PaletteOverlayCorner.Parent = PaletteOverlay
local PaletteFrame = Instance.new("Frame")
PaletteFrame.Name = "PaletteFrame"
PaletteFrame.AnchorPoint = Vector2.new(0.5, 0)
PaletteFrame.Position = UDim2.new(0.5, 0, 0, 40)
PaletteFrame.Size = UDim2.new(1, -20, 0, 89)
PaletteFrame.BackgroundColor3 = COLOR_PALETTE
PaletteFrame.BorderSizePixel = 0
PaletteFrame.Active = true
PaletteFrame.Visible = false
PaletteFrame.ZIndex = 21
PaletteFrame.Parent = MainFrame
local PaletteCorner = Instance.new("UICorner")
PaletteCorner.CornerRadius = UDim.new(0, 10)
PaletteCorner.Parent = PaletteFrame
local PaletteStroke = Instance.new("UIStroke")
PaletteStroke.Color = COLOR_BORDER
PaletteStroke.Thickness = 1
PaletteStroke.Parent = PaletteFrame
local PaletteLimit = Instance.new("UISizeConstraint")
PaletteLimit.MaxSize = Vector2.new(340, math.huge)
PaletteLimit.Parent = PaletteFrame
local PaletteScale = Instance.new("UIScale")
PaletteScale.Scale = 0.96
PaletteScale.Parent = PaletteFrame
local PaletteInputRow = Instance.new("Frame")
PaletteInputRow.Name = "InputRow"
PaletteInputRow.Size = UDim2.new(1, 0, 0, 40)
PaletteInputRow.BackgroundTransparency = 1
PaletteInputRow.Parent = PaletteFrame
local PaletteSearchIcon = createIcon(PaletteInputRow, "search", 16, COLOR_DIM)
PaletteSearchIcon.AnchorPoint = Vector2.new(0, 0.5)
PaletteSearchIcon.Position = UDim2.new(0, 12, 0.5, 0)
local PaletteInput = Instance.new("TextBox")
PaletteInput.Name = "Input"
PaletteInput.Size = UDim2.new(1, -76, 1, 0)
PaletteInput.Position = UDim2.new(0, 36, 0, 0)
PaletteInput.BackgroundTransparency = 1
PaletteInput.Text = ""
PaletteInput.PlaceholderText = "Search tabs and elements..."
PaletteInput.PlaceholderColor3 = Color3.fromRGB(110, 110, 110)
PaletteInput.TextColor3 = Color3.fromRGB(230, 230, 230)
PaletteInput.TextSize = 14
PaletteInput.Font = Enum.Font.SourceSans
PaletteInput.TextXAlignment = Enum.TextXAlignment.Left
PaletteInput.ClearTextOnFocus = false
PaletteInput.Parent = PaletteInputRow
local PaletteClose = Instance.new("TextButton")
PaletteClose.Name = "Close"
PaletteClose.AnchorPoint = Vector2.new(1, 0.5)
PaletteClose.Position = UDim2.new(1, -8, 0.5, 0)
PaletteClose.Size = UDim2.new(0, 28, 0, 28)
PaletteClose.BackgroundColor3 = COLOR_ACCENT
PaletteClose.BorderSizePixel = 0
PaletteClose.AutoButtonColor = false
PaletteClose.Text = ""
PaletteClose.Parent = PaletteInputRow
local PaletteCloseCorner = Instance.new("UICorner")
PaletteCloseCorner.CornerRadius = UDim.new(0, 6)
PaletteCloseCorner.Parent = PaletteClose
local PaletteCloseIcon = createIcon(PaletteClose, "x", 14, COLOR_DIM)
PaletteCloseIcon.AnchorPoint = Vector2.new(0.5, 0.5)
PaletteCloseIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
local PaletteDivider = Instance.new("Frame")
PaletteDivider.Name = "Divider"
PaletteDivider.Size = UDim2.new(1, 0, 0, 1)
PaletteDivider.Position = UDim2.new(0, 0, 0, 40)
PaletteDivider.BackgroundColor3 = COLOR_BORDER
PaletteDivider.BorderSizePixel = 0
PaletteDivider.Parent = PaletteFrame
local PaletteList = Instance.new("ScrollingFrame")
PaletteList.Name = "List"
PaletteList.Size = UDim2.new(1, 0, 0, 48)
PaletteList.Position = UDim2.new(0, 0, 0, 41)
PaletteList.BackgroundTransparency = 1
PaletteList.BorderSizePixel = 0
PaletteList.ScrollBarThickness = isTouch and 3 or 2
PaletteList.ScrollBarImageColor3 = COLOR_BORDER
PaletteList.CanvasSize = UDim2.new(0, 0, 0, 0)
PaletteList.AutomaticCanvasSize = Enum.AutomaticSize.Y
PaletteList.ScrollingDirection = Enum.ScrollingDirection.Y
PaletteList.Parent = PaletteFrame
local PaletteListPadding = Instance.new("UIPadding")
PaletteListPadding.PaddingTop = UDim.new(0, 4)
PaletteListPadding.PaddingBottom = UDim.new(0, 4)
PaletteListPadding.PaddingLeft = UDim.new(0, 4)
PaletteListPadding.PaddingRight = UDim.new(0, 4)
PaletteListPadding.Parent = PaletteList
local PaletteLayout = Instance.new("UIListLayout")
PaletteLayout.SortOrder = Enum.SortOrder.LayoutOrder
PaletteLayout.Padding = UDim.new(0, 2)
PaletteLayout.Parent = PaletteList
local function resizePalette()
    local limit = math.clamp(MainFrame.AbsoluteSize.Y - 96, 96, 230)
    local height = math.clamp(PaletteLayout.AbsoluteContentSize.Y + 8, 48, limit)
    PaletteList.Size = UDim2.new(1, 0, 0, height)
    PaletteFrame.Size = UDim2.new(1, -20, 0, 41 + height)
end
PaletteLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resizePalette)
local function clearResults()
    for _, child in ipairs(PaletteList:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
    Palette.Items = {}
    Palette.Selected = 0
end
local function setSelected(index, scroll)
    local previous = Palette.Items[Palette.Selected]
    if previous then
        previous.Button.BackgroundTransparency = 1
    end
    Palette.Selected = index
    local item = Palette.Items[index]
    if not item then
        return
    end
    item.Button.BackgroundTransparency = 0
    if scroll then
        local current = PaletteList.CanvasPosition.Y
        local top = item.Button.AbsolutePosition.Y - PaletteList.AbsolutePosition.Y + current
        local bottom = top + item.Button.AbsoluteSize.Y
        local view = PaletteList.AbsoluteSize.Y
        if top < current then
            PaletteList.CanvasPosition = Vector2.new(0, math.max(top - 28, 0))
        elseif bottom > current + view then
            PaletteList.CanvasPosition = Vector2.new(0, bottom - view + 4)
        end
    end
end
local function focusElement(element)
    local container = element.Container
    local scroll = element.Tab.Scroll
    if not container.Parent then
        return
    end
    local target = container.AbsolutePosition.Y - scroll.AbsolutePosition.Y + scroll.CanvasPosition.Y - 34
    local limit = math.max(scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteSize.Y, 0)
    TweenService:Create(scroll, TWEEN_INFO, {CanvasPosition = Vector2.new(0, math.clamp(target, 0, limit))}):Play()
    element.Flash.Transparency = 0
    TweenService:Create(element.Flash, FLASH_INFO, {Transparency = 1}):Play()
end
local function activateItem(item)
    closePalette()
    if item.Kind == "tab" then
        selectTab(item.Tab)
    else
        selectTab(item.Element.Tab)
        task.delay(0.05, function()
            focusElement(item.Element)
        end)
    end
end
local function createHeading(order, text)
    local label = Instance.new("TextLabel")
    label.Name = "Heading"
    label.Size = UDim2.new(1, 0, 0, 24)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = COLOR_DIM
    label.TextSize = 12
    label.Font = Enum.Font.SourceSansSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = order
    label.Parent = PaletteList
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8)
    padding.Parent = label
end
local function createSeparator(order)
    local line = Instance.new("Frame")
    line.Name = "Separator"
    line.Size = UDim2.new(1, 0, 0, 1)
    line.BackgroundColor3 = COLOR_BORDER
    line.BorderSizePixel = 0
    line.LayoutOrder = order
    line.Parent = PaletteList
end
local function createRow(order, data)
    local button = Instance.new("TextButton")
    button.Name = "Item"
    button.Size = UDim2.new(1, 0, 0, isTouch and 36 or 32)
    button.BackgroundColor3 = COLOR_ACCENT
    button.BackgroundTransparency = 1
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Text = ""
    button.LayoutOrder = order
    button.Parent = PaletteList
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button
    local icon = createIcon(button, data.Icon, 16, COLOR_INACTIVE)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.Position = UDim2.new(0, 8, 0.5, 0)
    local hint = Instance.new("TextLabel")
    hint.Name = "Hint"
    hint.AnchorPoint = Vector2.new(1, 0.5)
    hint.Position = UDim2.new(1, -8, 0.5, 0)
    hint.Size = UDim2.new(0.4, 0, 0, 16)
    hint.BackgroundTransparency = 1
    hint.Text = data.Hint
    hint.TextColor3 = COLOR_DIM
    hint.TextSize = 12
    hint.Font = Enum.Font.SourceSans
    hint.TextXAlignment = Enum.TextXAlignment.Right
    hint.TextTruncate = Enum.TextTruncate.AtEnd
    hint.Parent = button
    local label = Instance.new("TextLabel")
    label.Name = "Text"
    label.Size = UDim2.new(0.6, -36, 1, 0)
    label.Position = UDim2.new(0, 32, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = data.Name
    label.TextColor3 = COLOR_ACTIVE
    label.TextSize = 14
    label.Font = Enum.Font.SourceSans
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = button
    data.Button = button
    Palette.Items[#Palette.Items + 1] = data
    local index = #Palette.Items
    button.MouseEnter:Connect(function()
        setSelected(index, false)
    end)
    button.Activated:Connect(function()
        activateItem(data)
    end)
end
local function contains(text, query)
    local lowered = string.lower(text)
    for word in string.gmatch(query, "%S+") do
        if not string.find(lowered, word, 1, true) then
            return false
        end
    end
    return true
end
local function renderResults(query)
    clearResults()
    local order = 0
    local groups = 0
    for _, section in ipairs(sections) do
        local sectionMatch = query ~= "" and contains(section.Name, query)
        local rows = {}
        for _, tab in ipairs(section.Tabs) do
            if query == "" or sectionMatch or contains(tab.Name .. " " .. section.Name, query) then
                rows[#rows + 1] = {Kind = "tab", Name = tab.Name, Icon = tab.IconName, Hint = section.Name, Tab = tab}
            end
            for _, element in ipairs(tab.Elements) do
                if query == "" or contains(element.Search, query) then
                    rows[#rows + 1] = {Kind = "element", Name = element.Name, Icon = ELEMENT_ICONS[resolveKey(element.Type)] or "box", Hint = tab.Name .. " > " .. element.Group, Element = element}
                end
            end
        end
        if #rows > 0 then
            groups = groups + 1
            if groups > 1 then
                order = order + 1
                createSeparator(order)
            end
            order = order + 1
            createHeading(order, section.Name)
            for _, row in ipairs(rows) do
                order = order + 1
                createRow(order, row)
            end
        end
    end
    if groups == 0 then
        local empty = Instance.new("TextLabel")
        empty.Name = "Empty"
        empty.Size = UDim2.new(1, 0, 0, 48)
        empty.BackgroundTransparency = 1
        empty.Text = "No results found."
        empty.TextColor3 = COLOR_DIM
        empty.TextSize = 14
        empty.Font = Enum.Font.SourceSans
        empty.Parent = PaletteList
    else
        setSelected(1, false)
    end
    PaletteList.CanvasPosition = Vector2.new(0, 0)
    resizePalette()
end
local function currentQuery()
    local text = string.lower(PaletteInput.Text)
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end
PaletteInput:GetPropertyChangedSignal("Text"):Connect(function()
    if Palette.Open then
        renderResults(currentQuery())
    end
end)
refreshPalette = function()
    if Palette.Open then
        renderResults(currentQuery())
    end
end
local function openPalette()
    if Palette.Open or not EcoHub.Enabled then
        return
    end
    Palette.Open = true
    Palette.Token = Palette.Token + 1
    PaletteInput.Text = ""
    renderResults("")
    PaletteOverlay.Visible = true
    PaletteFrame.Visible = true
    PaletteOverlay.BackgroundTransparency = 1
    PaletteScale.Scale = 0.96
    TweenService:Create(PaletteOverlay, TWEEN_INFO, {BackgroundTransparency = 0.5}):Play()
    TweenService:Create(PaletteScale, TWEEN_INFO, {Scale = 1}):Play()
    task.defer(function()
        if Palette.Open then
            PaletteInput:CaptureFocus()
        end
    end)
end
closePalette = function()
    if not Palette.Open then
        return
    end
    Palette.Open = false
    Palette.Token = Palette.Token + 1
    local token = Palette.Token
    PaletteInput:ReleaseFocus()
    TweenService:Create(PaletteScale, TWEEN_INFO, {Scale = 0.96}):Play()
    local tween = TweenService:Create(PaletteOverlay, TWEEN_INFO, {BackgroundTransparency = 1})
    tween.Completed:Connect(function()
        if Palette.Token == token and not Palette.Open then
            PaletteOverlay.Visible = false
            PaletteFrame.Visible = false
        end
    end)
    tween:Play()
end
Panel.OpenSearch = openPalette
Panel.CloseSearch = closePalette
SearchButton.Activated:Connect(openPalette)
PaletteOverlay.Activated:Connect(closePalette)
PaletteClose.Activated:Connect(closePalette)
PaletteInput.FocusLost:Connect(function(enterPressed)
    if not enterPressed or not Palette.Open then
        return
    end
    local item = Palette.Items[Palette.Selected]
    if item then
        activateItem(item)
    end
end)
connect(UserInputService.InputBegan, function(input, processed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then
        return
    end
    if State.Created and not processed and input.KeyCode == State.MinimizeKey then
        setVisibility(not EcoHub.Enabled)
        return
    end
    if not Palette.Open then
        return
    end
    if input.KeyCode == Enum.KeyCode.Escape then
        closePalette()
    elseif input.KeyCode == Enum.KeyCode.Down or input.KeyCode == Enum.KeyCode.Up then
        local count = #Palette.Items
        if count == 0 then
            return
        end
        local step = input.KeyCode == Enum.KeyCode.Down and 1 or -1
        local nextIndex = Palette.Selected + step
        if nextIndex > count then
            nextIndex = 1
        elseif nextIndex < 1 then
            nextIndex = count
        end
        setSelected(nextIndex, true)
    end
end)
local function makeDraggable(handle, target)
    local dragging = false
    local dragStart = Vector3.zero
    local startPosition = target.Position
    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
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
    connect(UserInputService.InputChanged, function(input)
        if not dragging then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)
end
makeDraggable(Dashboard, MainFrame)
makeDraggable(Header, MainFrame)
local resizing = false
local startSize, startMousePos
ResizeButton.InputBegan:Connect(function(input)
    if EcoHub.Enabled and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        resizing = true
        startSize = MainFrame.AbsoluteSize
        startMousePos = input.Position
    end
end)
connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = false
    end
end)
connect(UserInputService.InputChanged, function(input)
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - startMousePos
        local viewport = getViewport()
        local maxWidth = math.max(320, math.min(900, viewport.X - 16))
        local maxHeight = math.max(240, math.min(700, viewport.Y - 16))
        local newWidth = math.clamp(startSize.X + delta.X, math.min(450, maxWidth), maxWidth)
        local newHeight = math.clamp(startSize.Y + delta.Y, math.min(300, maxHeight), maxHeight)
        MainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
    end
end)
local isActualDrag = false
local dragStart = Vector3.zero
local startPosition = ToggleButton.Position
local moveConnection = nil
local endConnection = nil
local function stopTracking()
    if moveConnection then
        moveConnection:Disconnect()
        moveConnection = nil
    end
    if endConnection then
        endConnection:Disconnect()
        endConnection = nil
    end
end
ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end
    isActualDrag = false
    dragStart = input.Position
    startPosition = ToggleButton.Position
    stopTracking()
    moveConnection = UserInputService.InputChanged:Connect(function(moveInput)
        if moveInput.UserInputType ~= Enum.UserInputType.MouseMovement and moveInput.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local delta = moveInput.Position - dragStart
        if delta.Magnitude > 6 then
            isActualDrag = true
        end
        if isActualDrag then
            ToggleButton.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)
    endConnection = UserInputService.InputEnded:Connect(function(endInput)
        if endInput.UserInputType ~= Enum.UserInputType.MouseButton1 and endInput.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        stopTracking()
        if not isActualDrag then
            setVisibility(not EcoHub.Enabled)
        end
        isActualDrag = false
    end)
end)
local Window = {Panel = Panel, Elements = Elements, Features = Features, Gui = EcoHub}
function Window:CreateTab(config)
    config = type(config) == "table" and config or {tab = config}
    local tabName = tostring(config.tab or config.Tab or config.Name or config.Title or "Tab")
    local sectionName = tostring(config.section or config.Section or "Main")
    local iconName = config.icon or config.Icon
    local section = sectionsByName[sectionName] or Panel.AddSection(sectionName)
    local _, tab = section:AddTab(tabName, iconName)
    return tab
end
function Window:GetTab(key)
    if type(key) == "number" then
        return allTabs[key]
    end
    for _, tab in ipairs(allTabs) do
        if tab.Name == key then
            return tab
        end
    end
    return nil
end
function Window:SelectTab(tab)
    if type(tab) ~= "table" then
        tab = Window:GetTab(tab)
    end
    if tab and tab.Page then
        selectTab(tab)
    end
end
function Window:SetMinimized(state)
    setVisibility(not state)
end
function Window:IsMinimized()
    return not EcoHub.Enabled
end
function Window:ClearSearch()
    PaletteInput.Text = ""
end
function Window:SetTitle(text)
    TitleText.Text = tostring(text)
end
function Window:SetSubTitle(text)
    SubTitleText.Text = tostring(text)
end
function Window:SetMinimizeKey(keyCode)
    if typeof(keyCode) == "EnumItem" then
        State.MinimizeKey = keyCode
    end
end
function Window:SetVisible(state)
    setVisibility(state and true or false)
end
function Window:Toggle()
    setVisibility(not EcoHub.Enabled)
end
function Window:OpenSearch()
    openPalette()
end
function Window:CloseSearch()
    closePalette()
end
local function destroyLibrary()
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    table.clear(connections)
    stopTracking()
    EcoHub:Destroy()
    ToggleGui:Destroy()
    env.EcoHubPanel = nil
    env.EcoHubElements = nil
    env.EcoHubFeatures = nil
    env.EcoHubLibrary = nil
    env.EcoHubDestroy = nil
end
function Window:Destroy()
    destroyLibrary()
end
local Librarys = {}
function Librarys:CreateWindow(config)
    config = type(config) == "table" and config or {}
    TitleText.Text = tostring(config.Title or "EcoHub")
    SubTitleText.Text = tostring(config.SubTitle or "v1.0.0")
    if typeof(config.Size) == "UDim2" then
        applySize(config.Size)
    end
    if typeof(config.MinimizeKey) == "EnumItem" then
        State.MinimizeKey = config.MinimizeKey
    end
    State.Created = true
    EcoHub.Enabled = true
    ToggleGui.Enabled = true
    return Window
end
env.EcoHubPanel = Panel
env.EcoHubElements = Elements
env.EcoHubFeatures = Features
env.EcoHubLibrary = Librarys
env.EcoHubDestroy = destroyLibrary
Elements.Load()
return Librarys