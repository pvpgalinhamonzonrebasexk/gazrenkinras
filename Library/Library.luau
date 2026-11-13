-- // Github
local Github = {
    Repo = "pvpgalinhamonzonrebasexk/gazrenkinras",
    Branch = "main"
}

Github.IconsUrl = "https://raw.githubusercontent.com/" .. Github.Repo .. "/refs/heads/" .. Github.Branch .. "/Assets/Icons.lua"
Github.IconsCdn = "https://cdn.jsdelivr.net/gh/" .. Github.Repo .. "@" .. Github.Branch .. "/Assets/Icons.lua"

Github.NotificationsUrl = "https://raw.githubusercontent.com/" .. Github.Repo .. "/refs/heads/" .. Github.Branch .. "/Templates/Documento/Notifications.md"

Github.ElementsPath = "Library/Elements"
Github.ElementsApi = "https://api.github.com/repos/" .. Github.Repo .. "/contents/" .. Github.ElementsPath .. "?ref=" .. Github.Branch
Github.ElementsRaw = "https://raw.githubusercontent.com/" .. Github.Repo .. "/refs/heads/" .. Github.Branch .. "/" .. Github.ElementsPath .. "/"
Github.ElementsCdn = "https://cdn.jsdelivr.net/gh/" .. Github.Repo .. "@" .. Github.Branch .. "/" .. Github.ElementsPath .. "/"
Github.ElementsList = "https://data.jsdelivr.com/v1/packages/gh/" .. Github.Repo .. "@" .. Github.Branch .. "?structure=flat"

Github.ThemesPath = "Themes"
Github.ThemesApi = "https://api.github.com/repos/" .. Github.Repo .. "/contents/" .. Github.ThemesPath .. "?ref=" .. Github.Branch
Github.ThemesRaw = "https://raw.githubusercontent.com/" .. Github.Repo .. "/refs/heads/" .. Github.Branch .. "/" .. Github.ThemesPath .. "/"
Github.ThemesCdn = "https://cdn.jsdelivr.net/gh/" .. Github.Repo .. "@" .. Github.Branch .. "/" .. Github.ThemesPath .. "/"

Github.FeaturesPath = "Features"

local IconError = nil

local function LoadIcons()
    local Sources = { Github.IconsUrl, Github.IconsCdn }

    for _, Url in ipairs(Sources) do
        local Success, Result = pcall(function()
            return loadstring(game:HttpGet(Url))()
        end)

        if Success and type(Result) == "table" and type(Result.assets) == "table" then
            return Result.assets
        end

        local Reason = Success and "invalid icon file" or tostring(Result)
        warn("[Ecohub] Icons: failed to load " .. Url .. " (" .. Reason .. ")")
    end

    IconError = "no icon source could be loaded"
    return {}
end

local IconAssets = LoadIcons()

local function GetIcon(Name)
    if not Name then
        return ""
    end

    local Asset = IconAssets["lucide-" .. Name] or IconAssets[Name]

    if Asset then
        return Asset
    end

    if string.find(Name, "rbxassetid://", 1, true) then
        return Name
    end

    return ""
end

-- // Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalizationService = game:GetService("LocalizationService")

local env = getgenv and getgenv() or _G
local IsTouch = UserInputService.TouchEnabled

local function GetPlayerGui()
    local Player = Players.LocalPlayer
    return Player and Player:FindFirstChildOfClass("PlayerGui")
end

local Config = {
    TweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    FlashInfo = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    ToggleImage = "rbxassetid://77526194033506",
    LoadTimeout = 45,
    LoadRounds = 3,
    RetryDelay = 2,
    BuildRetries = 5,
    BuildLateRetries = 6,
    BuildLateDelay = 10,
    LoadAttempts = 3,
    WatchRetries = 4,
    WatchDelay = 15,
    MaxParallel = 4,
    SaveFile = "Ecohub.json",
    SaveDelay = 1,
    AutoSaveInterval = 20,
    SidebarWidth = 180,
    TabHeight = 34,
    TabFillTransparency = 0.3,
    TabHoverTransparency = 0.85,
    TabTween = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TabPress = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TabRelease = TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    TabPop = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    ScrollTween = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    ScrollHold = 0.9,
    ScrollWidth = 6,
    RestoreFires = true,
    ThemePrefetch = true,
    ThemePrefetchLimit = 24
}

local ElementIcons = {
    button = "mouse-pointer-click",
    checkbox = "toggle-right",
    toggle = "toggle-right",
    slider = "sliders-horizontal",
    dropdown = "chevrons-up-down",
    colorpicker = "palette",
    paragraph = "align-left"
}

local ElementAliases = { toggle = "checkbox", colorpick = "colorpicker" }

local ElementDefaults = { "Button", "Checkbox", "Toggle", "Slider", "Paragraph", "Dropdown", "ColorPicker" }

-- // Util
local Util = {}

Util.Owners = setmetatable({}, { __mode = "k" })

function Util.Create(ClassName, Props, Parent)
    local Object = Instance.new(ClassName)

    for Property, Value in pairs(Props or {}) do
        Object[Property] = Value
    end

    if Parent then
        Object.Parent = Parent
    end

    return Object
end

function Util.Corner(Parent, Radius)
    return Util.Create("UICorner", { CornerRadius = UDim.new(0, Radius) }, Parent)
end

function Util.Stroke(Parent, Color, Thickness)
    return Util.Create("UIStroke", { Color = Color, Thickness = Thickness }, Parent)
end

function Util.Padding(Parent, Top, Bottom, Left, Right)
    return Util.Create("UIPadding", {
        PaddingTop = UDim.new(0, Top or 0),
        PaddingBottom = UDim.new(0, Bottom or 0),
        PaddingLeft = UDim.new(0, Left or 0),
        PaddingRight = UDim.new(0, Right or 0)
    }, Parent)
end

function Util.List(Parent, Padding, Extra)
    local Layout = Util.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, Padding or 0)
    }, Parent)

    for Property, Value in pairs(Extra or {}) do
        Layout[Property] = Value
    end

    return Layout
end

function Util.Tween(Object, Info, Goals)
    local Tween = TweenService:Create(Object, Info, Goals)
    Tween:Play()
    return Tween
end

function Util.Icon(Parent, Name, Size, Color)
    local Image = GetIcon(Name)

    if Image == "" then
        Image = GetIcon("circle")
    end

    return Util.Create("ImageLabel", {
        Name = "Icon",
        Size = UDim2.fromOffset(Size, Size),
        BackgroundTransparency = 1,
        Image = Image,
        ImageColor3 = Color
    }, Parent)
end

function Util.IsPress(Input)
    return Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch
end

function Util.IsMove(Input)
    return Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch
end

local FoldMap = {}

for Base, Letters in pairs({ a = "àáâãäå", c = "ç", e = "èéêë", i = "ìíîï", n = "ñ", o = "òóôõö", u = "ùúûü", y = "ý" }) do
    for _, Code in utf8.codes(Letters) do
        FoldMap[utf8.char(Code)] = Base
        FoldMap[utf8.char(Code - 32)] = Base
    end
end

FoldMap[utf8.char(255)] = "y"

function Util.Fold(Text)
    Text = string.lower(tostring(Text))

    if string.find(Text, "\195", 1, true) then
        Text = string.gsub(Text, "\195[\128-\191]", FoldMap)
    end

    return Text
end

function Util.Contains(Text, Query)
    for Word in string.gmatch(Query, "%S+") do
        if not string.find(Text, Word, 1, true) then
            return false
        end
    end

    return true
end

function Util.ResolveKey(Name)
    local Key = string.lower(tostring(Name))
    return ElementAliases[Key] or Key
end

function Util.Prepare(Source, Header)
    Source = string.gsub(Source, "^\239\187\191", "")
    return Header .. Source
end

-- // Http
local Http = {}

function Http.Get(Url)
    local Failure = "request failed"
    local Success, Body = pcall(game.HttpGet, game, Url)

    if Success and type(Body) == "string" and Body ~= "" then
        return Body
    end

    if not Success then
        Failure = tostring(Body)
    end

    local Requester = nil

    if type(request) == "function" then
        Requester = request
    elseif type(http_request) == "function" then
        Requester = http_request
    elseif type(syn) == "table" and type(syn.request) == "function" then
        Requester = syn.request
    end

    if Requester and not string.find(Failure, "404", 1, true) then
        local Sent, Response = pcall(Requester, { Url = Url, Method = "GET" })

        if Sent and type(Response) == "table" then
            local Status = Response.StatusCode or Response.Status

            if type(Response.Body) == "string" and Response.Body ~= "" and (Response.Success or Status == 200) then
                return Response.Body
            end

            Failure = "HTTP " .. tostring(Status)
        elseif not Sent then
            Failure = tostring(Response)
        end
    end

    error(Failure, 0)
end

function Http.Try(Urls, Rounds)
    Rounds = Rounds or 2

    local LastError = "not found"
    local Retry = false

    for Round = 1, Rounds do
        Retry = false

        for _, Url in ipairs(Urls) do
            local Success, Result = pcall(Http.Get, Url)

            if Success then
                return Result
            end

            LastError = tostring(Result)

            if not string.find(LastError, "404", 1, true) then
                Retry = true
            end
        end

        if not Retry or Round == Rounds then
            break
        end

        task.wait(0.4 * Round)
    end

    return nil, LastError, not Retry
end

function Http.Fetch(Urls, Rounds)
    local Body, Failure = Http.Try(Urls, Rounds)

    if Body then
        return Body
    end

    error(Failure, 0)
end

function Http.Race(urls, validate, options)
    options = options or {}
    local delay = options.Delay or 1.2
    local limit = options.Timeout or 20
    local parallel = options.Parallel or 3
    local total = #urls
    local fatalLimit = math.min(2, total)
    local state = { Done = false, Value = nil, Active = 0, Failures = 0, Missing = 0, Fatal = 0, Reason = nil }

    local function attempt(url)
        local ok, body = pcall(Http.Get, url)
        state.Active = state.Active - 1
        if state.Done then
            return
        end
        if not ok then
            state.Failures = state.Failures + 1
            state.Reason = tostring(body)
            if string.find(state.Reason, "404", 1, true) then
                state.Missing = state.Missing + 1
            end
            return
        end
        local valid, value, reason, fatal = pcall(validate, body)
        if valid and value then
            state.Value = value
            state.Done = true
            return
        end
        state.Failures = state.Failures + 1
        state.Reason = valid and tostring(reason or "invalid response") or tostring(value)
        if valid and fatal then
            state.Fatal = state.Fatal + 1
        end
    end

    local started = 0
    local lastStart = 0
    local deadline = os.clock() + limit

    while not state.Done do
        local now = os.clock()
        if now >= deadline or state.Fatal >= fatalLimit then
            break
        end
        if started < total then
            if state.Active < parallel and (state.Active == 0 or now - lastStart >= delay) then
                started = started + 1
                state.Active = state.Active + 1
                lastStart = now
                task.spawn(attempt, urls[started])
            end
        elseif state.Active == 0 then
            break
        end
        task.wait(0.03)
    end

    local value = state.Value
    state.Done = true
    if value then
        return value, nil, false
    end
    local gone = total > 0 and (state.Missing >= total or state.Fatal >= fatalLimit)
    return nil, state.Reason or "download timed out", gone
end

-- // Notifications
local Notifications = { Module = (nil :: any), Loading = false, Failed = false, Queue = ({} :: { any }), Duration = 8, MaxText = 220, MaxQueue = 20 }

function Notifications.Send(Options)
    local Module = Notifications.Module

    if Module then
        pcall(Module.Notify, Options)
        return
    end

    if Notifications.Failed then
        return
    end

    if #Notifications.Queue < Notifications.MaxQueue then
        table.insert(Notifications.Queue, Options)
    end

    Notifications.Load()
end

function Notifications.Load()
    if Notifications.Module or Notifications.Loading or Notifications.Failed then
        return
    end

    Notifications.Loading = true

    task.spawn(function()
        local Source, Failure = Http.Try({ Github.NotificationsUrl .. "?t=" .. tostring(os.time()) }, 3)
        local Module = nil

        if Source then
            local Chunk, CompileError = loadstring(Source)

            if Chunk then
                local Ran, Result = pcall(Chunk)

                if Ran and type(Result) == "table" then
                    Module = Result
                else
                    Failure = tostring(Result)
                end
            else
                Failure = tostring(CompileError)
            end
        end

        Notifications.Loading = false

        if not Module then
            Notifications.Failed = true
            Notifications.Queue = {}
            warn("[Ecohub] Notifications failed: " .. tostring(Failure))
            return
        end

        pcall(Module.SetSide, "Right")
        pcall(Module.SetGroup, true)

        Notifications.Module = Module

        local Queue = Notifications.Queue
        Notifications.Queue = {}

        for _, Options in ipairs(Queue) do
            Notifications.Send(Options)
        end
    end)
end

local function Report(Title, Detail, Kind)
    local Message = tostring(Detail)
    local Short = Message

    warn("[Ecohub] " .. tostring(Title) .. ": " .. Message)

    if #Short > Notifications.MaxText then
        Short = string.sub(Short, 1, Notifications.MaxText) .. "..."
    end

    task.spawn(Notifications.Send, {
        Title = tostring(Title),
        Description = Short,
        Type = Kind == "Warning" and "Warning" or "Error",
        Duration = Notifications.Duration,
        RichText = false
    })
end

if IconError then
    Report("Icons failed", IconError)
end

-- // Locale
local Locale = {
    Lang = nil,
    Version = 0,
    States = {},
    Custom = {},
    Records = setmetatable({}, { __mode = "k" }),
    Roots = setmetatable({}, { __mode = "k" }),
    Listeners = {},
    NextListener = 0
}

local TEXT_PROPERTIES = { TextLabel = "Text", TextButton = "Text", TextBox = "PlaceholderText" }
local WIDE_LETTERS = "[\195-\197\208-\219\224\227-\237]"

Locale.Fold = Util.Fold

function Locale.GetId()
    local player = Players.LocalPlayer
    local readers = {
        function()
            return player and player.LocaleId
        end,
        function()
            return LocalizationService.RobloxLocaleId
        end,
        function()
            return LocalizationService.SystemLocaleId
        end
    }
    for _, read in ipairs(readers) do
        local ok, id = pcall(read)
        if ok and type(id) == "string" and id ~= "" then
            return string.lower(id)
        end
    end
    return nil
end

function Locale.Detect()
    local id = Locale.GetId()
    if id then
        Locale.Detected = string.match(id, "^([^%-_]+)") or "en"
    end
    return Locale.Detected
end

function Locale.GetLang()
    return Locale.Lang or Locale.Detected or Locale.Detect() or "en"
end

function Locale.Watch(maid)
    local function update()
        local before = Locale.Detected
        Locale.Detected = nil
        Locale.Detect()
        if Locale.Detected ~= before and not Locale.Lang then
            Locale.Refresh()
        end
    end
    local player = Players.LocalPlayer
    if player then
        maid:Connect(player:GetPropertyChangedSignal("LocaleId"), update)
    end
    for _, name in ipairs({ "RobloxLocaleId", "SystemLocaleId" }) do
        local ok, signal = pcall(function()
            return LocalizationService:GetPropertyChangedSignal(name)
        end)
        if ok and signal then
            maid:Connect(signal, update)
        end
    end
    task.spawn(function()
        local tries = 0
        while not Locale.GetId() and tries < 20 do
            tries = tries + 1
            task.wait(0.5)
        end
        update()
    end)
end

function Locale.SetLang(lang)
    local code = nil
    if type(lang) == "string" then
        code = string.match(string.lower(lang), "^([^%-_]+)")
    end
    if code == "auto" then
        code = nil
    end
    Locale.Lang = code
    Locale.Refresh()
end

function Locale.Is(lang)
    return Locale.GetLang() == string.lower(tostring(lang))
end

function Locale.Upper(text)
    text = string.upper(text)
    if not string.find(text, "\195", 1, true) then
        return text
    end
    return (string.gsub(text, "\195([\160-\190])", function(byte)
        local code = string.byte(byte)
        if code == 183 then
            return nil
        end
        return "\195" .. string.char(code - 32)
    end))
end

function Locale.Adapt(source, translated)
    if not string.find(source, "%l") then
        if string.find(source, "%u") then
            return Locale.Upper(translated)
        end
        return translated
    end
    if string.find(source, "^%l") then
        return (string.gsub(translated, "^%u", string.lower))
    end
    return translated
end

function Locale.State(lang)
    local state = Locale.States[lang]
    if state ~= nil then
        return state or nil
    end

    local index = {}
    local count = 0
    local longest = 1

    local function put(key, value)
        key = string.lower(key)
        if index[key] == nil then
            count = count + 1
        end
        index[key] = value
        local words = select(2, string.gsub(key, "%S+", ""))
        if words > longest then
            longest = math.min(words, 6)
        end
    end

    for key, value in pairs(Locale.Custom[lang] or {}) do
        put(key, value)
    end

    if count == 0 then
        Locale.States[lang] = false
        return nil
    end

    state = { Index = index, Max = longest, Cache = {}, Miss = {}, MissCount = 0 }
    Locale.States[lang] = state
    return state
end

function Locale.IsActive()
    return Locale.GetLang() ~= "en"
end

function Locale.Resolve(state, text, lang)
    local direct = state.Index[string.lower(text)]
    if direct then
        return Locale.Adapt(text, direct)
    end

    if string.find(text, "<", 1, true) and string.find(text, ">", 1, true) then
        local parts = {}
        local cursor = 1
        local tagged = false
        for first, after in string.gmatch(text, "()%b<>()") do
            tagged = true
            if first > cursor then
                parts[#parts + 1] = Locale.Translate(string.sub(text, cursor, first - 1))
            end
            parts[#parts + 1] = string.sub(text, first, after - 1)
            cursor = after
        end
        if tagged then
            if cursor <= #text then
                parts[#parts + 1] = Locale.Translate(string.sub(text, cursor))
            end
            return table.concat(parts)
        end
    end

    local words = {}
    for first, _, after in string.gmatch(text, "()(%a[%w']*)()") do
        words[#words + 1] = { first, after - 1 }
        if #words > 6 then
            return text
        end
    end

    local total = #words
    if total == 0 then
        return text
    end

    local joinable = {}
    for position = 1, total - 1 do
        joinable[position] = string.sub(text, words[position][2] + 1, words[position + 1][1] - 1) == " "
    end

    local parts = {}
    local cursor = 1
    local changed = false
    local position = 1

    while position <= total do
        local reach = 1
        while reach < state.Max and position + reach <= total and joinable[position + reach - 1] do
            reach = reach + 1
        end

        local matched = false
        for span = reach, 1, -1 do
            local first = words[position][1]
            local last = words[position + span - 1][2]
            local piece = string.sub(text, first, last)
            local hit = state.Index[string.lower(piece)]
            if hit then
                parts[#parts + 1] = string.sub(text, cursor, first - 1)
                parts[#parts + 1] = Locale.Adapt(piece, hit)
                cursor = last + 1
                position = position + span
                changed = true
                matched = true
                break
            end
        end

        if not matched then
            position = position + 1
        end
    end

    if not changed then
        return text
    end
    parts[#parts + 1] = string.sub(text, cursor)
    return table.concat(parts)
end

function Locale.TranslateTagged(text)
    local parts, cursor, tagged = {}, 1, false
    for first, after in string.gmatch(text, "()%b<>()") do
        tagged = true
        if first > cursor then
            parts[#parts + 1] = Locale.Translate(string.sub(text, cursor, first - 1))
        end
        parts[#parts + 1] = string.sub(text, first, after - 1)
        cursor = after
    end
    if not tagged then
        return nil
    end
    if cursor <= #text then
        parts[#parts + 1] = Locale.Translate(string.sub(text, cursor))
    end
    return table.concat(parts)
end

function Locale.Translate(text)
    if type(text) ~= "string" or text == "" then
        return text
    end
    local lang = Locale.GetLang()
    if lang == "en" or (not string.find(text, "%a") and not string.find(text, WIDE_LETTERS)) then
        return text
    end

    local state = Locale.State(lang)
    if state then
        local cached = state.Cache[text]
        if cached then
            return cached
        end
        local direct = state.Index[string.lower(text)]
        if direct then
            local result = Locale.Adapt(text, direct)
            state.Cache[text] = result
            return result
        end
    end

    if string.find(text, "<", 1, true) and string.find(text, ">", 1, true) then
        local tagged = Locale.TranslateTagged(text)
        if tagged then
            return tagged
        end
    end

    local roblox = Locale.Roblox
    if roblox then
        local result = roblox.Get(text, lang)
        if result then
            return result
        end
    end

    local machine = Locale.Machine
    if machine then
        local result = machine.Get(text, lang)
        if result then
            return result
        end
    end

    if state then
        return Locale.Resolve(state, text, lang)
    end
    return text
end

function Locale.Add(lang, map, silent)
    if type(lang) ~= "string" or type(map) ~= "table" then
        return false
    end
    lang = string.lower(lang)
    lang = string.match(lang, "^([^%-_]+)") or lang

    local custom = Locale.Custom[lang]
    if not custom then
        custom = {}
        Locale.Custom[lang] = custom
    end
    for key, value in pairs(map) do
        if type(key) == "string" and type(value) == "string" then
            custom[key] = value
        elseif type(value) == "table" and type(value[1]) == "string" and type(value[2]) == "string" then
            custom[value[1]] = value[2]
        end
    end

    Locale.States[lang] = nil
    if not silent then
        Locale.Refresh()
    end
    return true
end

function Locale.AddMany(languages)
    if type(languages) ~= "table" then
        return false
    end
    for lang, map in pairs(languages) do
        Locale.Add(lang, map, true)
    end
    Locale.Refresh()
    return true
end

function Locale.Paint(instance, property, record)
    local translated = Locale.Translate(record.Source)
    if record.Transform then
        translated = record.Transform(translated)
    end
    record.Applied = translated
    if instance[property] ~= translated then
        instance[property] = translated
    end
end

function Locale.Bind(instance, property, transform)
    local records = Locale.Records[instance]
    if not records then
        records = {}
        Locale.Records[instance] = records
    end
    if records[property] then
        return
    end

    local record = { Source = instance[property], Applied = nil, Transform = transform }
    records[property] = record
    Locale.Paint(instance, property, record)

    instance:GetPropertyChangedSignal(property):Connect(function()
        local text = instance[property]
        if text == record.Applied then
            return
        end
        record.Source = text
        Locale.Paint(instance, property, record)
    end)
end

function Locale.BindInstance(instance)
    local property = TEXT_PROPERTIES[instance.ClassName]
    if not property then
        return
    end
    if instance.ClassName ~= "TextLabel" and instance[property] == "" then
        return
    end
    Locale.Bind(instance, property)
end

function Locale.Scan(root, entry)
    if entry.Done then
        return
    end
    if not root.Parent then
        Locale.Roots[root] = nil
        return
    end
    entry.Done = true
    Locale.BindInstance(root)
    for _, descendant in ipairs(root:GetDescendants()) do
        Locale.BindInstance(descendant)
    end
    root.DescendantAdded:Connect(Locale.BindInstance)
end

function Locale.Attach(root)
    if Locale.Roots[root] then
        return
    end
    local entry = { Done = false }
    Locale.Roots[root] = entry
    if Locale.IsActive() then
        Locale.Scan(root, entry)
    end
end

function Locale.OnChange(callback)
    Locale.NextListener = Locale.NextListener + 1
    local id = Locale.NextListener
    Locale.Listeners[id] = callback
    return function()
        Locale.Listeners[id] = nil
    end
end

function Locale.Refresh()
    Locale.Version = Locale.Version + 1

    for instance, records in pairs(Locale.Records) do
        for property, record in pairs(records) do
            Locale.Paint(instance, property, record)
        end
    end

    if Locale.IsActive() then
        for root, entry in pairs(Locale.Roots) do
            if not entry.Done then
                Locale.Scan(root, entry)
            end
        end
    end

    for _, listener in pairs(Locale.Listeners) do
        task.spawn(pcall, listener)
    end
end

local Roblox = { Translator = nil, Lang = nil, Loading = false, Cache = {}, Count = 0 }
Locale.Roblox = Roblox

function Roblox.Load()
    if Roblox.Translator or Roblox.Loading then
        return
    end
    Roblox.Loading = true
    task.spawn(function()
        local ok, translator = pcall(function()
            return LocalizationService:GetTranslatorForPlayerAsync(Players.LocalPlayer)
        end)
        Roblox.Loading = false
        if not ok or not translator then
            return
        end
        local readable, id = pcall(function()
            return translator.LocaleId
        end)
        if not readable or type(id) ~= "string" then
            return
        end
        Roblox.Lang = string.match(string.lower(id), "^([^%-_]+)")
        Roblox.Translator = translator
        Roblox.Cache = {}
        Roblox.Count = 0
        Locale.Refresh()
    end)
end

function Roblox.Get(text, lang)
    local translator = Roblox.Translator
    if not translator or Roblox.Lang ~= lang then
        return nil
    end
    local cached = Roblox.Cache[text]
    if cached ~= nil then
        return cached or nil
    end
    if Roblox.Count > 2000 then
        Roblox.Cache = {}
        Roblox.Count = 0
    end
    Roblox.Count = Roblox.Count + 1
    local ok, result = pcall(translator.Translate, translator, GetPlayerGui(), text)
    if ok and type(result) == "string" and result ~= "" and result ~= text then
        Roblox.Cache[text] = result
        return result
    end
    Roblox.Cache[text] = false
    return nil
end

local Machine = {
    Cache = {},
    Queue = {},
    Queued = {},
    Failed = {},
    Active = 0,
    Limit = 6,
    Retries = 4,
    Cooldown = 20,
    BatchSize = 30,
    BatchChars = 1000,
    SingleChars = 200,
    Waiting = false,
    Recovering = false,
    Ready = false,
    Saves = nil
}
Locale.Machine = Machine

local MACHINE_CODES = { zh = "zh-CN", he = "iw", fil = "tl" }
local MACHINE_HOSTS = { "translate.googleapis.com", "translate.google.com" }

function Machine.Load()
    if Machine.Ready then
        return
    end
    local saves = Machine.Saves
    if not saves or not saves.Data then
        return
    end
    Machine.Ready = true
    local data = saves.Data
    if type(data.Translations) ~= "table" then
        data.Translations = {}
    end
    Machine.Cache = data.Translations
end

function Machine.Attach(saves)
    Machine.Saves = saves
    Machine.Ready = false
    Machine.Load()
end

function Machine.Trim(text)
    return (string.gsub(string.gsub(text, "^%s+", ""), "%s+$", ""))
end

function Machine.Template(text)
    local numbers = {}
    local template = string.gsub(text, "%d+", function(number)
        numbers[#numbers + 1] = number
        return "{" .. #numbers .. "}"
    end)
    return template, numbers
end

function Machine.Restore(text, numbers)
    return (string.gsub(text, "{%s*(%d+)%s*}", function(index)
        return numbers[tonumber(index)]
    end))
end

function Machine.Valid(text, slots)
    local found = 0
    for index in string.gmatch(text, "{%s*(%d+)%s*}") do
        local number = tonumber(index)
        if not number or number < 1 or number > slots then
            return false
        end
        found = found + 1
    end
    return found == slots
end

function Machine.Chunks(text)
    if #text <= 300 then
        return { text }
    end
    local chunks, current = {}, ""
    for sentence in string.gmatch(text, "[^%.!?\n]*[%.!?\n]*%s*") do
        if sentence ~= "" then
            if #current + #sentence > 300 and current ~= "" then
                chunks[#chunks + 1] = current
                current = ""
            end
            current = current .. sentence
        end
    end
    if current ~= "" then
        chunks[#chunks + 1] = current
    end
    return chunks
end

function Machine.Request(text, code)
    local failure = "request failed"
    local query = HttpService:UrlEncode(text)
    for _, host in ipairs(MACHINE_HOSTS) do
        local url = "https://" .. host .. "/translate_a/single?client=gtx&sl=auto&tl=" .. code .. "&dt=t&q=" .. query
        local ok, body = pcall(Http.Get, url)
        if ok then
            local parsed, data = pcall(HttpService.JSONDecode, HttpService, body)
            if parsed and type(data) == "table" and type(data[1]) == "table" then
                local pieces = {}
                for _, segment in ipairs(data[1]) do
                    if type(segment) == "table" and type(segment[1]) == "string" then
                        pieces[#pieces + 1] = segment[1]
                    end
                end
                local joined = table.concat(pieces)
                if joined ~= "" then
                    return joined
                end
                failure = "empty translation"
            else
                failure = "invalid response"
            end
        else
            failure = tostring(body)
        end
    end
    error(failure, 0)
end

function Machine.FetchOne(text, lang)
    local code = MACHINE_CODES[lang] or lang
    local result = ""
    for _, chunk in ipairs(Machine.Chunks(text)) do
        local piece = Machine.Request(chunk, code)
        if result ~= "" and not string.find(result, "%s$") and not string.find(piece, "^%s") then
            result = result .. " "
        end
        result = result .. piece
    end
    result = Machine.Trim(result)
    if result == "" then
        error("empty translation", 0)
    end
    return result
end

function Machine.FetchBatch(jobs, lang)
    local code = MACHINE_CODES[lang] or lang
    local lines = {}
    for index, job in ipairs(jobs) do
        lines[index] = job.Text
    end
    local joined = Machine.Trim(Machine.Request(table.concat(lines, "\n"), code))
    local results = {}
    for line in string.gmatch(joined .. "\n", "([^\n]*)\n") do
        results[#results + 1] = Machine.Trim(line)
    end
    if #results ~= #jobs then
        return nil
    end
    for _, line in ipairs(results) do
        if line == "" then
            return nil
        end
    end
    return results
end

function Machine.Schedule()
    if Machine.Waiting then
        return
    end
    Machine.Waiting = true
    task.delay(0.1, function()
        Machine.Waiting = false
        Locale.Refresh()
    end)
end

function Machine.Recover()
    if Machine.Recovering then
        return
    end
    Machine.Recovering = true
    task.delay(Machine.Cooldown + 1, function()
        Machine.Recovering = false
        if Locale.IsActive() then
            Locale.Refresh()
        end
    end)
end

function Machine.Store(lang, key, result)
    local bucket = Machine.Cache[lang]
    if type(bucket) ~= "table" then
        bucket = {}
        Machine.Cache[lang] = bucket
    end
    bucket[key] = result
    if Machine.Saves then
        Machine.Saves:Queue()
    end
    Machine.Schedule()
end

function Machine.Fail(job)
    if not Machine.Queued[job.Key] then
        return
    end
    job.Attempts = (job.Attempts or 0) + 1
    if job.Attempts < Machine.Retries then
        task.delay(job.Attempts * 1.5, function()
            Machine.Queue[#Machine.Queue + 1] = job
            Machine.Start()
        end)
        return
    end
    Machine.Queued[job.Key] = nil
    Machine.Failed[job.Key] = os.clock()
    Machine.Recover()
end

function Machine.Batchable(job)
    return #job.Text <= Machine.SingleChars and not string.find(job.Text, "\n", 1, true)
end

function Machine.Take()
    local first = table.remove(Machine.Queue, 1)
    if not first then
        return nil
    end
    local jobs = { first }
    if not Machine.Batchable(first) then
        return jobs, first.Lang
    end
    local chars = #first.Text + 1
    local index = 1
    while index <= #Machine.Queue and #jobs < Machine.BatchSize do
        local job = Machine.Queue[index]
        if job.Lang == first.Lang and Machine.Batchable(job) and chars + #job.Text + 1 <= Machine.BatchChars then
            table.remove(Machine.Queue, index)
            jobs[#jobs + 1] = job
            chars = chars + #job.Text + 1
        else
            index = index + 1
        end
    end
    return jobs, first.Lang
end

function Machine.Solve(job, lang, preset)
    if preset then
        if Machine.Valid(preset, job.Slots) then
            return job.Text, preset
        end
    else
        local ok, value = pcall(Machine.FetchOne, job.Text, lang)
        if ok and Machine.Valid(value, job.Slots) then
            return job.Text, value
        end
        if not ok then
            return nil
        end
    end
    if job.Raw then
        local ok, value = pcall(Machine.FetchOne, job.Raw, lang)
        if ok then
            return job.Raw, value
        end
    end
    return nil
end

function Machine.Process(jobs, lang)
    local results = nil
    if #jobs > 1 then
        local ok, value = pcall(Machine.FetchBatch, jobs, lang)
        if not ok then
            for _, job in ipairs(jobs) do
                Machine.Fail(job)
            end
            return
        end
        results = value
    end
    for index, job in ipairs(jobs) do
        local key, value = Machine.Solve(job, lang, results and results[index] or nil)
        if key then
            Machine.Queued[job.Key] = nil
            Machine.Store(lang, key, value)
        else
            Machine.Fail(job)
        end
    end
end

function Machine.Start()
    if Machine.Active >= Machine.Limit then
        return
    end
    Machine.Active = Machine.Active + 1
    task.spawn(function()
        task.wait(0.05)
        while true do
            local jobs, lang = Machine.Take()
            if not jobs then
                break
            end
            local ok = pcall(Machine.Process, jobs, lang)
            if not ok then
                for _, job in ipairs(jobs) do
                    Machine.Fail(job)
                end
            end
        end
        Machine.Active = Machine.Active - 1
    end)
end

function Machine.Enqueue(template, lang, slots, raw)
    local key = lang .. "|" .. template
    if Machine.Queued[key] then
        return
    end
    local failed = Machine.Failed[key]
    if failed and os.clock() - failed < Machine.Cooldown then
        return
    end
    Machine.Failed[key] = nil
    Machine.Queued[key] = true
    Machine.Queue[#Machine.Queue + 1] = {
        Text = template,
        Lang = lang,
        Key = key,
        Slots = slots,
        Raw = slots > 0 and raw or nil,
        Attempts = 0
    }
    Machine.Start()
end

function Machine.Get(text, lang)
    Machine.Load()
    local lead, core, tail = string.match(text, "^(%s*)(.-)(%s*)$")
    if core == "" then
        return nil
    end
    local template, numbers = Machine.Template(core)
    if not string.find(template, "%a%a") and not string.find(template, WIDE_LETTERS) then
        return nil
    end
    local bucket = Machine.Cache[lang]
    if type(bucket) == "table" then
        local hit = bucket[template]
        if type(hit) == "string" and Machine.Valid(hit, #numbers) then
            return lead .. Machine.Restore(hit, numbers) .. tail
        end
        local exact = bucket[core]
        if type(exact) == "string" then
            return lead .. exact .. tail
        end
    end
    Machine.Enqueue(template, lang, #numbers, core)
    return nil
end

-- // Source
local Source = {}

function Source.Build(repo, branch, path)
    path = string.gsub(tostring(path or ""), "^/+", "")
    path = string.gsub(path, "/+$", "")
    local prefix = path ~= "" and (path .. "/") or ""
    return {
        Repo = repo,
        Branch = branch,
        Path = path,
        Prefix = prefix,
        Raw = "https://raw.githubusercontent.com/" .. repo .. "/refs/heads/" .. branch .. "/" .. prefix,
        Cdn = "https://cdn.jsdelivr.net/gh/" .. repo .. "@" .. branch .. "/" .. prefix,
        Tree = "https://api.github.com/repos/" .. repo .. "/git/trees/" .. branch .. "?recursive=1",
        List = "https://data.jsdelivr.com/v1/packages/gh/" .. repo .. "@" .. branch .. "?structure=flat",
        Flat = "https://data.jsdelivr.com/v1/package/gh/" .. repo .. "@" .. branch .. "/flat"
    }
end

function Source.Parse(url)
    url = string.match(tostring(url), "^[^%?#]+") or ""
    local owner, repo, branch, path = string.match(url, "github%.com/([^/]+)/([^/]+)/tree/([^/]+)/?(.*)$")
    if not owner then
        owner, repo, branch, path = string.match(url, "github%.com/([^/]+)/([^/]+)/blob/([^/]+)/?(.*)$")
    end
    if not owner then
        owner, repo, branch, path = string.match(url, "raw%.githubusercontent%.com/([^/]+)/([^/]+)/refs/heads/([^/]+)/?(.*)$")
    end
    if not owner then
        owner, repo, branch, path = string.match(url, "raw%.githubusercontent%.com/([^/]+)/([^/]+)/([^/]+)/?(.*)$")
    end
    if not owner then
        return nil
    end
    return Source.Build(owner .. "/" .. repo, branch, path)
end

function Source.Urls(repo, branch, file, stamp)
    stamp = stamp or ""
    return {
        "https://raw.githubusercontent.com/" .. repo .. "/refs/heads/" .. branch .. "/" .. file .. stamp,
        "https://github.com/" .. repo .. "/raw/" .. branch .. "/" .. file .. stamp,
        "https://raw.githack.com/" .. repo .. "/" .. branch .. "/" .. file,
        "https://cdn.statically.io/gh/" .. repo .. "/" .. branch .. "/" .. file,
        "https://cdn.jsdelivr.net/gh/" .. repo .. "@" .. branch .. "/" .. file,
        "https://fastly.jsdelivr.net/gh/" .. repo .. "@" .. branch .. "/" .. file,
        "https://gcore.jsdelivr.net/gh/" .. repo .. "@" .. branch .. "/" .. file,
        "https://testingcf.jsdelivr.net/gh/" .. repo .. "@" .. branch .. "/" .. file
    }
end

-- // ElementRegistry
local ElementRegistry = {}
ElementRegistry.__index = ElementRegistry

local function Bind(Self, Impl)
    return function(First, ...)
        if rawequal(First, Self) then
            return Impl(Self, ...)
        end

        return Impl(Self, First, ...)
    end
end

function ElementRegistry.new()
    local self = setmetatable({}, ElementRegistry)

    self.Registry = {}
    self.Pending = {}
    self.Files = {}
    self.Attempts = {}
    self.Active = 0
    self.Watching = false
    self.Panel = nil
    self.Destroyed = false
    self.OnChanged = nil

    self.Register = Bind(self, ElementRegistry._Register)
    self.Get = Bind(self, ElementRegistry._Get)
    self.List = Bind(self, ElementRegistry._List)
    self.Load = Bind(self, ElementRegistry._Load)

    return self
end

function ElementRegistry:_Changed()
    if self.OnChanged and not self.Destroyed then
        self.OnChanged()
    end
end

function ElementRegistry:_Register(Name, Builder, Meta)
    if self.Destroyed or type(Name) ~= "string" or type(Builder) ~= "function" then
        return
    end

    local Key = Util.ResolveKey(Name)
    local Frameless = Key == "button"

    if type(Meta) == "table" and Meta.Frameless ~= nil then
        Frameless = Meta.Frameless and true or false
    end

    local Entry = { Name = Name, Builder = Builder, Frameless = Frameless }
    self.Registry[Key] = Entry

    local Queue = self.Pending[Key]

    if Queue then
        self.Pending[Key] = nil

        for _, Job in ipairs(Queue) do
            local Element = Job.Element

            task.spawn(function()
                local Success, Failure = pcall(Element.Build, Element, Entry, Job.Options)

                if not Success then
                    Report("Element failed", tostring(Element.Type) .. ": " .. tostring(Failure))
                end
            end)
        end
    end

    self:_Changed()
end

function ElementRegistry:_Get(Name)
    return self.Registry[Util.ResolveKey(Name)]
end

function ElementRegistry:_List()
    local Names = {}

    for _, Entry in pairs(self.Registry) do
        table.insert(Names, Entry.Name)
    end

    table.sort(Names)
    return Names
end

function ElementRegistry:Enqueue(Key, Element, Options)
    local Queue = self.Pending[Key]

    if not Queue then
        Queue = {}
        self.Pending[Key] = Queue
    end

    table.insert(Queue, { Element = Element, Options = Options })

    if self.Active == 0 then
        self:_Watch()
    end
end

function ElementRegistry:_RunChunk(Source)
    env.Elements = self
    env.Panel = self.Panel

    local Chunk, CompileError = loadstring(Util.Prepare(Source, "local Elements, Panel = ...; "))

    if not Chunk then
        error(CompileError, 0)
    end

    return Chunk(self, self.Panel)
end

function ElementRegistry:_LoadFile(File, Optional)
    local Names = { File }

    if not string.match(File, "%.luau?$") then
        Names = { File .. ".lua", File .. ".luau" }
    end

    local Stamp = "?t=" .. tostring(os.time())
    local Urls = {}

    for _, Candidate in ipairs(Names) do
        table.insert(Urls, Github.ElementsRaw .. Candidate .. Stamp)
    end

    for _, Candidate in ipairs(Names) do
        table.insert(Urls, Github.ElementsCdn .. Candidate)
    end

    local Source, Failure, Missing = Http.Try(Urls, 2)

    if not Source then
        if not Optional then
            Report("Element load failed", File .. ": " .. tostring(Failure))
        end

        return false, Missing, false
    end

    local Ran, Result = pcall(self._RunChunk, self, Source)

    if not Ran then
        Report("Element load failed", File .. ": " .. tostring(Result))
        return false, false, true
    end

    return true, false, false
end

function ElementRegistry:_LoadRound(Files, Optional)
    local Queue = {}

    for _, File in ipairs(Files) do
        local Id = string.lower((string.gsub(File, "%.luau?$", "")))

        if not self.Files[Id] then
            self.Files[Id] = true
            table.insert(Queue, { File = File, Id = Id })
        end
    end

    local Cursor = 0
    local Running = 0
    local Loaded = 0
    local Retryable = 0
    local Progress = os.clock()
    local Finished = {}

    local function Worker()
        while not self.Destroyed do
            Cursor = Cursor + 1

            local Job = Queue[Cursor]

            if not Job then
                break
            end

            local Success, Permanent, Broken = self:_LoadFile(Job.File, Optional)
            Finished[Job.Id] = true

            if Success then
                Loaded = Loaded + 1
                self.Files[Job.Id] = true
                self.Attempts[Job.Id] = nil
            elseif Permanent then
                self.Files[Job.Id] = "missing"
            else
                local Count = (self.Attempts[Job.Id] or 0) + (Broken and 1 or 0)
                self.Attempts[Job.Id] = Count

                if Broken and Count >= Config.LoadAttempts then
                    self.Files[Job.Id] = "broken"
                else
                    self.Files[Job.Id] = nil
                    Retryable = Retryable + 1
                end
            end

            Progress = os.clock()
        end

        Running = Running - 1
    end

    for _ = 1, math.min(Config.MaxParallel, #Queue) do
        Running = Running + 1
        task.spawn(Worker)
    end

    while Running > 0 and os.clock() - Progress < Config.LoadTimeout and not self.Destroyed do
        task.wait(0.1)
    end

    for _, Job in ipairs(Queue) do
        if not Finished[Job.Id] and self.Files[Job.Id] == true then
            self.Files[Job.Id] = nil
            Retryable = Retryable + 1
        end
    end

    return Loaded, #Queue, Retryable
end

function ElementRegistry:_ParseApi(Body)
    local Files = {}
    local Success, List = pcall(HttpService.JSONDecode, HttpService, Body)

    if Success and type(List) == "table" then
        for _, Item in ipairs(List) do
            if type(Item) == "table" and Item.type == "file" and type(Item.name) == "string" then
                if string.match(Item.name, "%.luau?$") then
                    table.insert(Files, Item.name)
                end
            end
        end
    end

    table.sort(Files)
    return Files
end

function ElementRegistry:_ParseCdn(Body)
    local Files = {}
    local Success, Data = pcall(HttpService.JSONDecode, HttpService, Body)

    if Success and type(Data) == "table" and type(Data.files) == "table" then
        local Prefix = "/" .. Github.ElementsPath .. "/"

        for _, Item in ipairs(Data.files) do
            local Path = type(Item) == "table" and Item.name

            if type(Path) == "string" and string.sub(Path, 1, #Prefix) == Prefix then
                local Name = string.sub(Path, #Prefix + 1)

                if not string.find(Name, "/", 1, true) and string.match(Name, "%.luau?$") then
                    table.insert(Files, Name)
                end
            end
        end
    end

    table.sort(Files)
    return Files
end

function ElementRegistry:_ListFiles(Names)
    if type(Names) == "table" then
        local Files = {}

        for _, Name in ipairs(Names) do
            table.insert(Files, Name)
        end

        return Files, false
    end

    local Sources = {
        { Github.ElementsApi, self._ParseApi },
        { Github.ElementsList, self._ParseCdn }
    }

    for _, Source in ipairs(Sources) do
        local Success, Body = pcall(Http.Fetch, { Source[1] }, 1)

        if Success then
            local Files = Source[2](self, Body)

            if #Files > 0 then
                return Files, false
            end
        end
    end

    local Files = {}

    for _, Name in ipairs(ElementDefaults) do
        table.insert(Files, Name)
    end

    return Files, true
end

function ElementRegistry:_WarnPending()
    for Key, Queue in pairs(self.Pending) do
        local Alive = {}

        for _, Job in ipairs(Queue) do
            if not Job.Element.Destroyed then
                table.insert(Alive, Job)

                if not Job.Warned then
                    Job.Warned = true
                    Report("Element missing", Job.Element.Type .. " was not found in " .. Github.ElementsPath)
                end
            end
        end

        if #Alive > 0 then
            self.Pending[Key] = Alive
        else
            self.Pending[Key] = nil
        end
    end
end

function ElementRegistry:_HasPending()
    for Key, Queue in pairs(self.Pending) do
        local Alive = {}

        for _, Job in ipairs(Queue) do
            if not Job.Element.Destroyed then
                table.insert(Alive, Job)
            end
        end

        if #Alive > 0 then
            self.Pending[Key] = Alive
        else
            self.Pending[Key] = nil
        end
    end

    return next(self.Pending) ~= nil
end

function ElementRegistry:_PendingNames()
    local Names = {}

    for _, Queue in pairs(self.Pending) do
        for _, Job in ipairs(Queue) do
            local Name = tostring(Job.Element.Type)

            if not Job.Element.Destroyed and not table.find(Names, Name) then
                table.insert(Names, Name)
            end
        end
    end

    table.sort(Names)
    return Names
end

function ElementRegistry:_Watch()
    if self.Watching or self.Destroyed then
        return
    end

    self.Watching = true

    task.spawn(function()
        for Attempt = 1, Config.WatchRetries do
            task.wait(Config.WatchDelay * Attempt)

            if self.Destroyed or not self:_HasPending() then
                break
            end

            if self.Active == 0 then
                for Id, State in pairs(self.Files) do
                    if State == "missing" or State == "broken" then
                        self.Files[Id] = nil
                    end
                end

                self.Attempts = {}
                self:_Load(nil, false, true)
            end
        end

        self.Watching = false
    end)
end

function ElementRegistry:_Load(Names, Force, Quiet)
    if self.Active > 0 and not Force then
        return
    end

    Names = Names or env.EcoHubElementList

    if Force then
        self.Files = {}
        self.Attempts = {}
    end

    self.Active = self.Active + 1

    task.spawn(function()
        local Queued = 0
        local Loaded = 0
        local Files, Optional = self:_ListFiles(Names)

        for Round = 1, Config.LoadRounds do
            if self.Destroyed then
                break
            end

            local RoundLoaded, RoundQueued, Retryable = self:_LoadRound(Files, Optional)
            Loaded = Loaded + RoundLoaded
            Queued = Queued + RoundQueued

            local Missing = next(self.Pending) ~= nil

            if Round == Config.LoadRounds or (Retryable == 0 and not (Optional and Missing)) then
                break
            end

            task.wait(Config.RetryDelay * Round)

            if Optional and not self.Destroyed then
                Files, Optional = self:_ListFiles(Names)
            end
        end

        if not self.Destroyed and self:_HasPending() then
            local Extra = self:_PendingNames()

            if #Extra > 0 then
                self:_LoadRound(Extra, true)
            end
        end

        self.Active = self.Active - 1

        if self.Destroyed then
            return
        end

        if Queued > 0 and Loaded == 0 and not Quiet then
            Report("Elements failed", "no elements could be loaded, check your connection or the repository")
        end

        if self.Active == 0 then
            if not Quiet then
                self:_WarnPending()
            end

            self:_Watch()
        end
    end)
end

-- // Themes
local Theme = {
    Active = Color3.fromRGB(240, 240, 240),
    Inactive = Color3.fromRGB(165, 165, 165),
    Dim = Color3.fromRGB(115, 115, 115),
    Accent = Color3.fromRGB(42, 42, 42),
    Field = Color3.fromRGB(34, 34, 34),
    Border = Color3.fromRGB(55, 55, 55),
    BorderHover = Color3.fromRGB(88, 88, 88),
    Palette = Color3.fromRGB(28, 28, 28),
    Background = Color3.fromRGB(24, 24, 24),
    Divider = Color3.fromRGB(50, 50, 50),
    Subtitle = Color3.fromRGB(150, 150, 150),
    Placeholder = Color3.fromRGB(110, 110, 110),
    Text = Color3.fromRGB(230, 230, 230),
    TabActive = Color3.fromRGB(255, 255, 255),
    TabInactive = Color3.fromRGB(145, 145, 145),
    TabHover = Color3.fromRGB(200, 200, 200),
    GradientTop = Color3.fromRGB(38, 38, 38),
    GradientBottom = Color3.fromRGB(25, 25, 25)
}

local DefaultTheme = {}
local ThemeKeys = {}

for Key, Color in pairs(Theme) do
    DefaultTheme[Key] = Color
    table.insert(ThemeKeys, Key)
end

table.sort(ThemeKeys)

local Themes = { Extensions = { "lua", "luau", "json" }, Cache = {}, Files = {} }

local ThemeProps = {
    Frame = { "BackgroundColor3" },
    CanvasGroup = { "BackgroundColor3" },
    TextLabel = { "BackgroundColor3", "TextColor3" },
    TextButton = { "BackgroundColor3", "TextColor3" },
    TextBox = { "BackgroundColor3", "TextColor3", "PlaceholderColor3" },
    ImageLabel = { "BackgroundColor3", "ImageColor3" },
    ImageButton = { "BackgroundColor3", "ImageColor3" },
    ViewportFrame = { "BackgroundColor3", "ImageColor3" },
    ScrollingFrame = { "BackgroundColor3", "ScrollBarImageColor3" },
    UIStroke = { "Color" }
}

local function Pack(Color)
    return math.floor(Color.R * 255 + 0.5) * 65536 + math.floor(Color.G * 255 + 0.5) * 256 + math.floor(Color.B * 255 + 0.5)
end

local function ToColor(Value)
    if typeof(Value) == "Color3" then
        return Value
    end

    if type(Value) == "string" then
        local Hex = string.match(Value, "^#?(%x%x%x%x%x%x)$")

        if Hex then
            return Color3.fromRGB(
                tonumber(string.sub(Hex, 1, 2), 16),
                tonumber(string.sub(Hex, 3, 4), 16),
                tonumber(string.sub(Hex, 5, 6), 16)
            )
        end
    elseif type(Value) == "table" then
        local R = tonumber(Value[1] or Value.R or Value.r)
        local G = tonumber(Value[2] or Value.G or Value.g)
        local B = tonumber(Value[3] or Value.B or Value.b)

        if R and G and B then
            return Color3.fromRGB(R, G, B)
        end
    end

    return nil
end

local function BuildPalette(Colors)
    Colors = Colors or DefaultTheme

    local Palette = {}
    local Used = {}

    for _, Key in ipairs(ThemeKeys) do
        local Color = Colors[Key] or DefaultTheme[Key]
        local R = math.floor(Color.R * 255 + 0.5)
        local G = math.floor(Color.G * 255 + 0.5)
        local B = math.floor(Color.B * 255 + 0.5)
        local Code = Pack(Color)
        local Step = 0

        while Used[Code] do
            Step = Step + 1
            Color = Color3.fromRGB(R, G, B + Step <= 255 and B + Step or B - Step)
            Code = Pack(Color)
        end

        Used[Code] = true
        Palette[Key] = Color
    end

    return Palette
end

local function RemapObject(Object, Map)
    local Class = Object.ClassName
    local Props = ThemeProps[Class]

    if Props then
        if not Object:GetAttribute("NoTheme") then
            for _, Property in ipairs(Props) do
                local Target = Map[Pack(Object[Property])]

                if Target then
                    Object[Property] = Target
                end
            end
        end
    elseif Class == "UIGradient" then
        local Keypoints = Object.Color.Keypoints
        local Points = table.create(#Keypoints)
        local Dirty = false

        for Index, Point in ipairs(Keypoints) do
            local Target = Map[Pack(Point.Value)]

            if Target then
                Dirty = true
            end

            Points[Index] = ColorSequenceKeypoint.new(Point.Time, Target or Point.Value)
        end

        if Dirty then
            Object.Color = ColorSequence.new(Points)
        end
    end
end

local function SplitFile(File)
    local Name, Ext = string.match(File, "^(.+)%.(%w+)$")

    if Name then
        Ext = string.lower(Ext)

        for _, Allowed in ipairs(Themes.Extensions) do
            if Allowed == Ext then
                return Name, Ext
            end
        end
    end

    return nil
end

local function ListApi(Body)
    local Files = {}
    local Success, List = pcall(HttpService.JSONDecode, HttpService, Body)

    if Success and type(List) == "table" then
        for _, Item in ipairs(List) do
            if type(Item) == "table" and Item.type == "file" and type(Item.name) == "string" then
                table.insert(Files, Item.name)
            end
        end
    end

    return Files
end

local function ListCdn(Body)
    local Files = {}
    local Success, Data = pcall(HttpService.JSONDecode, HttpService, Body)

    if Success and type(Data) == "table" and type(Data.files) == "table" then
        local Prefix = "/" .. Github.ThemesPath .. "/"

        for _, Item in ipairs(Data.files) do
            local Path = type(Item) == "table" and Item.name

            if type(Path) == "string" and string.sub(Path, 1, #Prefix) == Prefix then
                local Name = string.sub(Path, #Prefix + 1)

                if not string.find(Name, "/", 1, true) then
                    table.insert(Files, Name)
                end
            end
        end
    end

    return Files
end

function Themes.Names()
    local Sources = {
        { Github.ThemesApi, ListApi },
        { Github.ElementsList, ListCdn }
    }

    for _, Source in ipairs(Sources) do
        local Success, Body = pcall(Http.Fetch, { Source[1] }, 1)

        if Success then
            local Names = {}
            local Seen = {}

            for _, File in ipairs(Source[2](Body)) do
                local Name = SplitFile(File)

                if Name and string.lower(Name) ~= "default" and not Seen[string.lower(Name)] then
                    Seen[string.lower(Name)] = true
                    Themes.Files[string.lower(Name)] = File
                    table.insert(Names, Name)
                end
            end

            if #Names > 0 then
                table.sort(Names)
                return Names
            end
        end
    end

    return {}
end

function Themes.Fetch(Name)
    local Files = {}
    local Known = Themes.Files[string.lower(Name)]

    if Known then
        Files = { Known }
    elseif SplitFile(Name) then
        Files = { Name }
    else
        for _, Ext in ipairs(Themes.Extensions) do
            table.insert(Files, Name .. "." .. Ext)
        end
    end

    local Stamp = "?t=" .. tostring(os.time())
    local Urls = {}

    for _, File in ipairs(Files) do
        table.insert(Urls, Github.ThemesRaw .. HttpService:UrlEncode(File) .. Stamp)
    end

    for _, File in ipairs(Files) do
        table.insert(Urls, Github.ThemesCdn .. HttpService:UrlEncode(File))
    end

    local Body, Failure = Http.Try(Urls, 2)

    if not Body then
        return nil, Failure
    end

    Body = (string.gsub(Body, "^\239\187\191", ""))

    local Lead = string.match(Body, "^%s*(.)")

    if Lead == "{" or Lead == "[" then
        local Success, Data = pcall(HttpService.JSONDecode, HttpService, Body)

        if Success then
            return Data
        end

        return nil, tostring(Data)
    end

    local Chunk, CompileError = loadstring(Body)

    if not Chunk then
        return nil, tostring(CompileError)
    end

    local Success, Data = pcall(Chunk)

    if not Success then
        return nil, tostring(Data)
    end

    return Data
end

function Themes.Parse(Result)
    if type(Result) ~= "table" then
        return nil
    end

    local Source = type(Result.Colors) == "table" and Result.Colors or Result
    local Lookup = {}

    for _, Key in ipairs(ThemeKeys) do
        Lookup[string.lower(Key)] = Key
    end

    local Colors = {}
    local Count = 0

    for Key, Value in pairs(Source) do
        local Canonical = type(Key) == "string" and Lookup[string.lower(Key)]
        local Color = Canonical and ToColor(Value)

        if Color then
            Colors[Canonical] = Color
            Count = Count + 1
        end
    end

    if Count == 0 then
        return nil
    end

    return Colors
end

function Themes.Load(Name)
    local Key = string.lower(Name)
    local Cached = Themes.Cache[Key]

    if Cached then
        return Cached
    end

    local Result, Failure = Themes.Fetch(Name)
    local Colors = Result and Themes.Parse(Result)

    if not Colors then
        return nil, Failure or "file has no valid colors"
    end

    Themes.Cache[Key] = Colors
    return Colors
end

function Themes.Prefetch(Names, IsAlive)
    if not Config.ThemePrefetch then
        return
    end

    task.spawn(function()
        for Index, Name in ipairs(Names) do
            if Index > Config.ThemePrefetchLimit or (IsAlive and not IsAlive()) then
                break
            end

            if not Themes.Cache[string.lower(Name)] then
                pcall(Themes.Load, Name)
                task.wait(0.15)
            end
        end
    end)
end

-- // Saves
local FileApi = {
    Ready = type(isfile) == "function" and type(readfile) == "function" and type(writefile) == "function"
}

local Json = {}

function Json.EncodeString(Text)
    Text = string.gsub(Text, "\\", "\\\\")
    Text = string.gsub(Text, "\"", "\\\"")
    Text = string.gsub(Text, "\n", "\\n")
    Text = string.gsub(Text, "\r", "\\r")
    Text = string.gsub(Text, "\t", "\\t")
    return "\"" .. Text .. "\""
end

function Json.Encode(Value, Indent)
    Indent = Indent or 0

    local Pad = string.rep("    ", Indent)
    local Inner = string.rep("    ", Indent + 1)

    if type(Value) == "table" then
        local IsList = true
        local Count = 0

        for Key in pairs(Value) do
            Count = Count + 1

            if type(Key) ~= "number" then
                IsList = false
            end
        end

        if Count == 0 then
            return "{}"
        end

        if IsList then
            local Parts = {}

            for Index = 1, Count do
                Parts[#Parts + 1] = Inner .. Json.Encode(Value[Index], Indent + 1)
            end

            return "[\n" .. table.concat(Parts, ",\n") .. "\n" .. Pad .. "]"
        end

        local Keys = {}

        for Key in pairs(Value) do
            Keys[#Keys + 1] = Key
        end

        table.sort(Keys, function(A, B)
            return tostring(A) < tostring(B)
        end)

        local Parts = {}

        for _, Key in ipairs(Keys) do
            Parts[#Parts + 1] = Inner .. Json.EncodeString(tostring(Key)) .. ": " .. Json.Encode(Value[Key], Indent + 1)
        end

        return "{\n" .. table.concat(Parts, ",\n") .. "\n" .. Pad .. "}"
    elseif type(Value) == "string" then
        return Json.EncodeString(Value)
    elseif type(Value) == "number" or type(Value) == "boolean" then
        return tostring(Value)
    end

    return "null"
end

local SaveManager = {}
SaveManager.__index = SaveManager

local BaseProfile = "AutoSave"

local function IsArray(Table)
    local Count = 0

    for Key in pairs(Table) do
        if type(Key) ~= "number" or Key < 1 or Key % 1 ~= 0 then
            return false
        end

        Count = Count + 1
    end

    return Count == #Table
end

local function Encode(Value, Depth)
    Depth = Depth or 0

    local Kind = typeof(Value)

    if Kind == "boolean" or Kind == "string" then
        return Value
    end

    if Kind == "number" then
        if Value ~= Value or Value == math.huge or Value == -math.huge then
            return nil
        end

        return Value
    end

    if Kind == "Color3" then
        return { __t = "Color3", v = Value:ToHex() }
    end

    if Kind == "EnumItem" then
        return { __t = "Enum", v = tostring(Value) }
    end

    if Kind == "table" and Depth < 6 then
        local Result: { [any]: any } = {}

        if IsArray(Value) then
            for _, Item in ipairs(Value) do
                local Encoded = Encode(Item, Depth + 1)

                if Encoded ~= nil then
                    table.insert(Result, Encoded)
                end
            end
        else
            for Key, Item in pairs(Value) do
                local Encoded = Encode(Item, Depth + 1)

                if Encoded ~= nil then
                    Result[tostring(Key)] = Encoded
                end
            end
        end

        return Result
    end

    return nil
end

local function Decode(Value, Depth)
    if type(Value) ~= "table" then
        return Value
    end

    Depth = Depth or 0

    if Depth > 6 then
        return nil
    end

    local Tag = Value.__t

    if Tag == "Color3" then
        return ToColor(Value.v)
    end

    if Tag == "Enum" then
        local Kind, Name = string.match(tostring(Value.v), "^Enum%.([%w_]+)%.([%w_]+)$")

        if Kind then
            local Success, Item = pcall(function()
                return Enum[Kind][Name]
            end)

            if Success then
                return Item
            end
        end

        return nil
    end

    local Result = {}

    for Key, Item in pairs(Value) do
        Result[Key] = Decode(Item, Depth + 1)
    end

    return Result
end

function SaveManager.new(Path)
    local self = setmetatable({}, SaveManager)

    self.Path = Path
    self.Entries = {}
    self.Token = 0
    self.Suspended = false
    self.Destroyed = false
    self.Warned = false
    self.Data = nil
    self.Game = nil
    self.GameKey = nil
    self.Active = BaseProfile
    self.AutoEnabled = true
    self.Last = nil

    self:Read()
    self:_Rename()

    return self
end

function SaveManager:Read()
    local Data = nil

    if FileApi.Ready then
        local Found, Exists = pcall(isfile, self.Path)

        if Found and Exists then
            local Opened, Body = pcall(readfile, self.Path)

            if Opened and type(Body) == "string" and Body ~= "" then
                local Parsed, Decoded = pcall(HttpService.JSONDecode, HttpService, Body)

                if Parsed and type(Decoded) == "table" then
                    Data = Decoded
                else
                    pcall(writefile, self.Path .. ".bak", Body)
                    Report("Saves", self.Path .. " is corrupted, a copy was kept as " .. self.Path .. ".bak")
                end
            end
        end
    end

    Data = Data or {}

    if type(Data.Player) ~= "table" then
        Data.Player = {}
    end

    if type(Data.Games) ~= "table" then
        Data.Games = {}
    end

    if type(Data.Panel) ~= "table" then
        Data.Panel = {}
    end

    self.Data = Data
    self.AutoEnabled = Data.Panel.AutoSave ~= false

    local Player = Players.LocalPlayer

    if Player then
        local Info = { Name = Player.Name, DisplayName = Player.DisplayName, UserId = Player.UserId }

        for Key, Value in pairs(Info) do
            Data.Player[Key] = Value
        end
    end

    self:_Class()
end

function SaveManager:_Class()
    local PlaceId = tostring(game.PlaceId)
    local Games = self.Data.Games
    local Key = nil
    local Entry = nil

    for Name, Item in pairs(Games) do
        if type(Item) == "table" and tostring(Item.PlaceId) == PlaceId then
            Key = Name
            Entry = Item
            break
        end
    end

    if not Entry then
        Key = "Place " .. PlaceId

        if Games[Key] then
            Key = Key .. " [" .. PlaceId .. "]"
        end

        Entry = { PlaceId = game.PlaceId, AutoSave = {} }
        Games[Key] = Entry
    end

    if type(Entry.AutoSave) ~= "table" then
        Entry.AutoSave = {}
    end

    if type(Entry.Profiles) ~= "table" then
        Entry.Profiles = {}
    end

    Entry.GameId = game.GameId
    Entry.LastPlayed = os.time()

    local Active = Entry.Profile

    if type(Active) ~= "string" or (Active ~= BaseProfile and type(Entry.Profiles[Active]) ~= "table") then
        Active = BaseProfile
    end

    Entry.Profile = Active

    self.Game = Entry
    self.GameKey = Key
    self.Active = Active

    self:Queue()
end

function SaveManager:_Rename()
    task.spawn(function()
        local Success, Info = pcall(function()
            return MarketplaceService:GetProductInfo(game.PlaceId)
        end)

        if self.Destroyed or not Success or type(Info) ~= "table" or type(Info.Name) ~= "string" or Info.Name == "" then
            return
        end

        local Name = Info.Name
        local Games = self.Data.Games

        if self.GameKey == Name then
            return
        end

        if Games[Name] and Games[Name] ~= self.Game then
            Name = Name .. " [" .. tostring(game.PlaceId) .. "]"

            if self.GameKey == Name then
                return
            end
        end

        Games[self.GameKey] = nil
        Games[Name] = self.Game
        self.GameKey = Name

        self:Queue()
    end)
end

function SaveManager:Values()
    if self.Active == BaseProfile then
        return self.Game.AutoSave
    end

    return self.Game.Profiles[self.Active]
end

function SaveManager:GetSetting(Key, Default)
    local Value = self.Data.Panel[Key]

    if Value == nil then
        return Default
    end

    local Decoded = Decode(Value)

    if Decoded == nil then
        return Default
    end

    return Decoded
end

function SaveManager:SetSetting(Key, Value)
    self.Data.Panel[Key] = Encode(Value)
    self:Queue()
end

function SaveManager:GetAuto(Key, Default)
    local Value = self.Game.AutoSave[tostring(Key)]

    if Value == nil then
        return Default
    end

    local Decoded = Decode(Value)

    if Decoded == nil then
        return Default
    end

    return Decoded
end

function SaveManager:SetAuto(Key, Value)
    self.Game.AutoSave[tostring(Key)] = Encode(Value)
    self:Queue()
end

function SaveManager:DeleteAuto(Key)
    self.Game.AutoSave[tostring(Key)] = nil
    self:Queue()
end

function SaveManager:Register(Flag, Getter, Setter)
    if self.Destroyed or type(Flag) ~= "string" or type(Getter) ~= "function" or type(Setter) ~= "function" then
        return
    end

    self.Entries[Flag] = { Get = Getter, Set = Setter }

    local Stored = self:Values()[Flag]

    if self.AutoEnabled and Stored ~= nil then
        self:_Apply(Flag, Stored)
    end
end

function SaveManager:Unregister(Flag)
    self.Entries[Flag] = nil
end

function SaveManager:_Apply(Flag, Stored)
    local Entry = self.Entries[Flag]
    local Value = Decode(Stored)

    if not Entry or Value == nil then
        return
    end

    local WasSuspended = self.Suspended
    self.Suspended = true

    local Success, Failure = pcall(Entry.Set, Value, not Config.RestoreFires)

    self.Suspended = WasSuspended

    if not Success then
        Report("Save restore failed", Flag .. ": " .. tostring(Failure))
    end
end

function SaveManager:Apply()
    local Values = self:Values()
    local Flags = {}

    for Flag in pairs(self.Entries) do
        table.insert(Flags, Flag)
    end

    for _, Flag in ipairs(Flags) do
        local Stored = Values[Flag]

        if Stored ~= nil then
            self:_Apply(Flag, Stored)
        end
    end

    self:Queue()
end

function SaveManager:Collect()
    if not self.AutoEnabled then
        return
    end

    local Values = self:Values()

    for Flag, Entry in pairs(self.Entries) do
        local Success, Value = pcall(Entry.Get)

        if Success then
            Values[Flag] = Encode(Value)
        end
    end
end

function SaveManager:Write()
    if self.Destroyed then
        return false
    end

    self:Collect()

    local Encoded, Body = pcall(Json.Encode, self.Data)

    if not Encoded then
        Report("Save failed", Body)
        return false
    end

    if not FileApi.Ready then
        if not self.Warned then
            self.Warned = true
            Report("Saves", "this executor has no file functions, nothing will be saved", "Warning")
        end

        return false
    end

    if Body == self.Last then
        return true
    end

    local Written, Failure = pcall(writefile, self.Path, Body)

    if not Written then
        Report("Save failed", Failure)
        return false
    end

    self.Last = Body

    return true
end

function SaveManager:Queue()
    if self.Destroyed or self.Suspended then
        return
    end

    self.Token = self.Token + 1

    local Token = self.Token

    task.delay(Config.SaveDelay, function()
        if not self.Destroyed and self.Token == Token then
            self:Write()
        end
    end)
end

function SaveManager:Changed(Flag)
    if self.AutoEnabled and self.Entries[Flag] then
        self:Queue()
    end
end

function SaveManager:Flush()
    self.Token = self.Token + 1
    return self:Write()
end

function SaveManager:SetAutoSave(State)
    State = State and true or false

    if State == self.AutoEnabled then
        return
    end

    self.AutoEnabled = State
    self.Data.Panel.AutoSave = State
    self:Queue()
end

function SaveManager:ListProfiles()
    local Names = {}

    for Name, Profile in pairs(self.Game.Profiles) do
        if type(Profile) == "table" then
            table.insert(Names, Name)
        end
    end

    table.sort(Names)
    table.insert(Names, 1, BaseProfile)

    return Names
end

function SaveManager:NextName()
    local Index = 1

    while self.Game.Profiles["Profile " .. Index] do
        Index = Index + 1
    end

    return "Profile " .. Index
end

function SaveManager:SetProfile(Name)
    if Name == self.Active or (Name ~= BaseProfile and type(self.Game.Profiles[Name]) ~= "table") then
        return false
    end

    self:Write()

    self.Active = Name
    self.Game.Profile = Name

    self:Apply()
    return true
end

function SaveManager:CreateProfile(Name)
    if type(Name) ~= "string" or Name == "" or Name == BaseProfile then
        Name = self:NextName()
    end

    if self.Game.Profiles[Name] then
        return nil
    end

    self:Collect()

    local Copy = {}

    for Flag, Stored in pairs(self:Values()) do
        Copy[Flag] = Stored
    end

    self.Game.Profiles[Name] = Copy
    self.Active = Name
    self.Game.Profile = Name

    self:Queue()
    return Name
end

function SaveManager:DeleteProfile(Name)
    if Name == BaseProfile or type(self.Game.Profiles[Name]) ~= "table" then
        return false
    end

    self.Game.Profiles[Name] = nil

    if self.Active == Name then
        self.Active = BaseProfile
        self.Game.Profile = BaseProfile
        self:Apply()
    else
        self:Queue()
    end

    return true
end

function SaveManager:Destroy()
    self.Destroyed = true
    self.Entries = {}
end

-- // Features
local Librarys = { Window = nil }

local FEATURE_HEADER = "local Window, Library = ...; local Windows, Librarys = Window, Library; "

local Features = {}
Features.__index = Features

function Features.new(window)
    local self = setmetatable({}, Features)
    self.Window = window
    self.Loaded = {}
    self.Order = {}
    self.Loading = {}
    self.Downloads = {}
    self.Queue = {}
    self.Running = 0
    self.ElementsReady = false
    self.Index = nil
    self.IndexLoading = false
    self.IndexToken = 0
    self.IndexFailed = 0
    self.IndexStamp = 0
    self.Known = nil
    self.Head = nil
    self.Watched = {}
    self.WatchAll = false
    self.Watching = false
    self.Active = {}
    self.Source = Source.Build(Github.Repo, Github.Branch, Github.FeaturesPath)
    self.Config = {
        Retries = 3,
        MaxParallel = 6,
        Parallel = 3,
        MaxSize = 8388608,
        Timeout = 45,
        AttemptTimeout = 20,
        HedgeDelay = 1.2,
        RunTimeout = 8,
        IndexRefresh = 5,
        IndexCooldown = 15,
        IndexWait = 8,
        FolderFresh = 10,
        ElementsWait = 12,
        PreloadTtl = 90,
        AutoWatch = true,
        WatchInterval = 20,
        WatchBlind = 120,
        ReloadGuard = 60
    }
    return self
end

function Features._ToRaw(url)
    local owner, repo, rest = string.match(url, "^https?://github%.com/([^/]+)/([^/]+)/blob/(.+)$")
    if owner then
        return "https://raw.githubusercontent.com/" .. owner .. "/" .. repo .. "/" .. rest
    end
    return url
end

function Features._IsScript(path)
    return string.match(string.lower(tostring(path)), "%.luau?$") ~= nil
end

function Features._Strip(path)
    local stripped = string.gsub(tostring(path), "%.[Ll][Uu][Aa][Uu]?$", "")
    return stripped
end

function Features._Encode(path)
    local encoded = string.gsub(path, "[^/]+", function(segment)
        local safe = string.gsub(segment, "[^%w%-%._~]", function(char)
            return string.format("%%%02X", string.byte(char))
        end)
        return safe
    end)
    return encoded
end

function Features._ParseTree(body, prefix)
    local files = {}
    local ok, data = pcall(HttpService.JSONDecode, HttpService, body)
    if not ok or type(data) ~= "table" or type(data.tree) ~= "table" then
        return files, false, false
    end
    for _, item in ipairs(data.tree) do
        if type(item) == "table" and item.type == "blob" and type(item.path) == "string" then
            if string.sub(item.path, 1, #prefix) == prefix then
                local rel = string.sub(item.path, #prefix + 1)
                if rel ~= "" and Features._IsScript(rel) then
                    files[#files + 1] = rel
                end
            end
        end
    end
    return files, data.truncated == true, true
end

function Features._ParseFlat(body, prefix)
    local files = {}
    local ok, data = pcall(HttpService.JSONDecode, HttpService, body)
    if not ok or type(data) ~= "table" or type(data.files) ~= "table" then
        return files, false, false
    end
    local full = "/" .. prefix
    for _, item in ipairs(data.files) do
        local path = type(item) == "table" and item.name
        if type(path) == "string" and string.sub(path, 1, #full) == full then
            local rel = string.sub(path, #full + 1)
            if rel ~= "" and Features._IsScript(rel) then
                files[#files + 1] = rel
            end
        end
    end
    return files, false, true
end

function Features._ParseAny(body, prefix)
    local files, truncated, valid = Features._ParseTree(body, prefix)
    if valid then
        return files, truncated, true
    end
    return Features._ParseFlat(body, prefix)
end

function Features._Atom(source)
    return "https://github.com/" .. source.Repo .. "/commits/" .. source.Branch .. ".atom"
end

function Features._Pinned(source, head)
    return {
        "https://data.jsdelivr.com/v1/packages/gh/" .. source.Repo .. "@" .. head .. "?structure=flat",
        "https://data.jsdelivr.com/v1/package/gh/" .. source.Repo .. "@" .. head .. "/flat"
    }
end

function Features:_Head(source)
    local ok, body = pcall(Http.Fetch, { Features._Atom(source) }, 1)
    if not ok or type(body) ~= "string" then
        return nil
    end
    local sha = string.match(body, "Grit::Commit/(%x+)") or string.match(body, "/commit/(%x+)")
    if sha and #sha >= 7 then
        return sha
    end
    return nil
end

function Features:_Gather(urls, prefix)
    local found = {}
    local pending = #urls
    local deadline = os.clock() + self.Config.AttemptTimeout

    for _, url in ipairs(urls) do
        task.spawn(function()
            local ok, body = pcall(Http.Get, url)
            if ok then
                local parsed, files = pcall(Features._ParseAny, body, prefix)
                if parsed and type(files) == "table" then
                    for _, rel in ipairs(files) do
                        found[#found + 1] = rel
                    end
                end
            end
            pending = pending - 1
        end)
    end

    while pending > 0 and os.clock() < deadline and not self.Window.Destroyed do
        task.wait(0.03)
    end
    return found
end

function Features:_Collect(source)
    local prefix = source.Prefix
    local seed = {}

    local ok, body = pcall(Http.Fetch, { source.Tree }, 2)
    if ok then
        local files, truncated, valid = Features._ParseAny(body, prefix)
        if valid and not truncated then
            return files, true
        end
        for _, rel in ipairs(files) do
            seed[#seed + 1] = rel
        end
    end

    local head = self:_Head(source)
    if head then
        local found = self:_Gather(Features._Pinned(source, head), prefix)
        for _, rel in ipairs(seed) do
            found[#found + 1] = rel
        end
        if #found > 0 then
            return found, true
        end
    end

    local found = self:_Gather({ source.List, source.Flat }, prefix)
    for _, rel in ipairs(seed) do
        found[#found + 1] = rel
    end
    if #found > 0 then
        return found, false
    end
    return nil, false
end

function Features:_BuildIndex(source)
    local files, exact = self:_Collect(source)
    if not files then
        return nil
    end

    table.sort(files, function(a, b)
        return string.lower(a) < string.lower(b)
    end)

    local index = { Files = {}, ByPath = {}, ByStem = {}, Folders = {}, Exact = exact }
    for _, rel in ipairs(files) do
        local key = string.lower(Features._Strip(rel))
        if not index.ByPath[key] then
            index.ByPath[key] = rel
            index.Files[#index.Files + 1] = rel
            local stem = string.match(key, "([^/]+)$")
            if not index.ByStem[stem] then
                index.ByStem[stem] = rel
            end
            local folder = key
            while true do
                folder = string.match(folder, "^(.+)/[^/]+$")
                if not folder then
                    break
                end
                index.Folders[folder] = true
            end
        end
    end
    return index
end

function Features:_Diff(index)
    local added = {}
    local first = self.Known == nil
    local known = self.Known or {}
    for _, rel in ipairs(index.Files) do
        local key = string.lower(Features._Strip(rel))
        if not known[key] then
            known[key] = true
            if not first then
                added[#added + 1] = rel
            end
        end
    end
    self.Known = known
    return added
end

function Features:_LoadIndex(force, maxWait)
    if self.Index and not force then
        return self.Index
    end

    if not self.IndexLoading then
        local cooling = self.IndexFailed > 0 and os.clock() - self.IndexFailed < self.Config.IndexCooldown
        if cooling and not force then
            return self.Index
        end

        self.IndexToken = self.IndexToken + 1
        local token = self.IndexToken
        local source = self.Source
        self.IndexLoading = true

        task.spawn(function()
            local ok, index = pcall(self._BuildIndex, self, source)
            if self.IndexToken ~= token then
                return
            end
            self.IndexLoading = false
            if ok and index then
                local added = self:_Diff(index)
                self.Index = index
                self.IndexFailed = 0
                self.IndexStamp = os.clock()
                self:_AutoLoad(added)
            else
                if not ok then
                    Report("Feature index failed", index)
                end
                self.IndexFailed = os.clock()
            end
        end)
    end

    local started = os.clock()
    local limit = maxWait or self.Config.Timeout
    while self.IndexLoading and os.clock() - started < limit and not self.Window.Destroyed do
        task.wait(0.05)
    end
    return self.Index
end

function Features:_Fresh(maxAge)
    local now = os.clock()
    if self.Index and now - self.IndexStamp <= maxAge then
        return self.Index
    end
    local cooled = self.IndexFailed == 0 or now - self.IndexFailed > self.Config.IndexCooldown
    if self.Index and not cooled then
        return self.Index
    end
    return self:_LoadIndex(true, self.Config.IndexWait) or self.Index
end

function Features:Warm()
    if self.Index or self.IndexLoading or self.Window.Destroyed then
        return
    end
    task.spawn(function()
        self:_LoadIndex()
    end)
end

function Features:_Watches(key)
    if self.WatchAll then
        return true
    end
    for folder in pairs(self.Watched) do
        if string.sub(key, 1, #folder + 1) == folder .. "/" then
            return true
        end
    end
    return false
end

function Features:_AutoLoad(added)
    if not added or #added == 0 or self.Window.Destroyed then
        return
    end
    local jobs = {}
    for _, rel in ipairs(added) do
        local job = self:_Job(rel)
        if not self.Loaded[job.Key] and not self.Loading[job.Key] and self:_Watches(job.Key) then
            jobs[#jobs + 1] = job
        end
    end
    if #jobs == 0 then
        return
    end
    task.spawn(function()
        local outcomes = self:_LoadJobs(jobs, nil, true)
        for _, outcome in ipairs(outcomes) do
            if not outcome.Success then
                warn("[Ecohub] Feature failed: " .. tostring(outcome.Name) .. ": " .. tostring(outcome.Error))
            end
        end
    end)
end

function Features:_Poll()
    if self.IndexLoading or self.Window.Destroyed then
        return
    end
    local index = self.Index
    local stale = not index or not index.Exact
    local head = self:_Head(self.Source)

    if head then
        if head ~= self.Head or stale then
            local before = self.IndexStamp
            self:_LoadIndex(true, self.Config.IndexWait)
            if self.IndexStamp ~= before then
                self.Head = head
            end
        end
    elseif stale or os.clock() - self.IndexStamp >= self.Config.WatchBlind then
        self:_LoadIndex(true, self.Config.IndexWait)
    end
end

function Features:_StartWatch()
    if self.Watching or self.Window.Destroyed or not self.Config.AutoWatch then
        return
    end
    if not self.WatchAll and next(self.Watched) == nil then
        return
    end
    self.Watching = true
    task.spawn(function()
        while not self.Window.Destroyed and self.Config.AutoWatch do
            task.wait(self.Config.WatchInterval)
            if self.Window.Destroyed then
                break
            end
            pcall(self._Poll, self)
        end
        self.Watching = false
    end)
end

function Features:_Normalize(name)
    local text = string.gsub(tostring(name), "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    text = string.gsub(text, "\\", "/")
    text = string.gsub(text, "^/+", "")
    text = string.gsub(text, "/+$", "")
    local prefix = string.lower(self.Source.Prefix)
    if prefix ~= "" and string.lower(string.sub(text, 1, #prefix)) == prefix then
        text = string.sub(text, #prefix + 1)
    end
    text = Features._Strip(text)
    return text
end

function Features:_Job(rel)
    local source = self.Source
    local stripped = Features._Strip(rel)
    local stamp = "?t=" .. tostring(os.time())
    return {
        Key = string.lower(stripped),
        Path = stripped,
        Name = string.match(stripped, "([^/]+)$") or stripped,
        Urls = Source.Urls(source.Repo, source.Branch, Features._Encode(source.Prefix .. rel), stamp)
    }
end

function Features:_Lookup(index, lowered, folderOnly)
    if not folderOnly then
        local rel = index.ByPath[lowered]
        if rel then
            return { self:_Job(rel) }
        end
    end
    if index.Folders[lowered] then
        local jobs = {}
        local folder = lowered .. "/"
        for _, file in ipairs(index.Files) do
            if string.sub(string.lower(file), 1, #folder) == folder then
                local job = self:_Job(file)
                job.Folder = lowered
                jobs[#jobs + 1] = job
            end
        end
        return jobs
    end
    if not folderOnly then
        local rel = index.ByStem[lowered]
        if rel then
            return { self:_Job(rel) }
        end
    end
    return nil
end

function Features:_UrlKey(clean)
    local source = self.Source
    local parsed = Source.Parse(clean)

    if parsed and source.Prefix ~= "" and Features._IsScript(parsed.Path)
        and string.lower(parsed.Repo) == string.lower(source.Repo)
        and string.lower(parsed.Branch) == string.lower(source.Branch)
        and string.lower(string.sub(parsed.Path, 1, #source.Prefix)) == string.lower(source.Prefix) then
        return string.lower(Features._Strip(string.sub(parsed.Path, #source.Prefix + 1)))
    end

    return string.lower(clean)
end

function Features:_Resolve(name, final)
    local original = string.gsub(tostring(name), "^%s+", "")
    original = string.gsub(original, "%s+$", "")

    if string.match(original, "^https?://") then
        local raw = Features._ToRaw(original)
        local clean = string.match(raw, "^[^%?#]+") or raw
        local display = string.match(Features._Strip(clean), "([^/]+)$") or clean
        local urls = { raw }
        local parsed = Source.Parse(clean)
        if parsed and Features._IsScript(parsed.Path) then
            local mirrors = Source.Urls(parsed.Repo, parsed.Branch, Features._Encode(parsed.Path), "?t=" .. tostring(os.time()))
            for i = 2, #mirrors do
                urls[#urls + 1] = mirrors[i]
            end
        end
        return { { Key = self:_UrlKey(clean), Path = clean, Name = display, Urls = urls } }
    end

    local clean = self:_Normalize(original)
    if clean == "" then
        return nil, "empty feature name"
    end
    local lowered = string.lower(clean)
    local trailing = string.sub(original, -1) == "/"

    local index = self:_LoadIndex(false, final and self.Config.Timeout or self.Config.IndexWait)
    if index then
        local jobs = self:_Lookup(index, lowered, trailing)
        if jobs and jobs[1] and jobs[1].Folder then
            local fresh = self:_Fresh(self.Config.FolderFresh)
            if fresh and fresh ~= index then
                index = fresh
                jobs = self:_Lookup(index, lowered, trailing) or jobs
            end
        end
        if jobs then
            return jobs
        end
        local now = os.clock()
        local cooled = self.IndexFailed == 0 or now - self.IndexFailed > self.Config.IndexCooldown
        if now - self.IndexStamp > self.Config.IndexRefresh and cooled then
            local fresh = self:_LoadIndex(true, self.Config.IndexWait)
            if fresh and fresh ~= index then
                jobs = self:_Lookup(fresh, lowered, trailing)
                if jobs then
                    return jobs
                end
            end
        end
        if trailing then
            return nil, "not found in " .. self.Source.Path
        end
    elseif trailing then
        return nil, "loading a folder needs the GitHub index"
    end

    local source = self.Source
    local stamp = "?t=" .. tostring(os.time())
    local lua = Source.Urls(source.Repo, source.Branch, Features._Encode(source.Prefix .. clean .. ".lua"), stamp)
    local luau = Source.Urls(source.Repo, source.Branch, Features._Encode(source.Prefix .. clean .. ".luau"), stamp)
    local urls = {}
    for i = 1, #lua do
        urls[#urls + 1] = lua[i]
        urls[#urls + 1] = luau[i]
    end
    return { {
        Key = lowered,
        Path = clean,
        Name = string.match(clean, "([^/]+)$") or clean,
        Urls = urls,
        Guess = index == nil,
        Origin = original
    } }
end

function Features:_Validate(body)
    if type(body) ~= "string" then
        return nil, "invalid response"
    end
    if #body > self.Config.MaxSize then
        return nil, "file is too large"
    end
    if string.match(body, "^%s*$") then
        return nil, "file is empty"
    end
    local head = string.lower(string.sub(body, 1, 200))
    if string.find(head, "^%s*<!doctype html") or string.find(head, "^%s*<html") then
        return nil, "response is a web page, not a script"
    end
    local chunk, failure = loadstring(Util.Prepare(body, FEATURE_HEADER))
    if not chunk then
        return nil, "compile: " .. tostring(failure), true
    end
    return { Body = body, Chunk = chunk }
end

function Features:_Download(future)
    local job = future.Job
    local config = self.Config
    local failure = "download timed out"
    local missing = false

    local ok, err = pcall(function()
        for round = 1, config.Retries do
            if self.Window.Destroyed then
                failure = "window was destroyed"
                return
            end
            local value, reason, gone = Http.Race(job.Urls, function(body)
                return self:_Validate(body)
            end, { Delay = config.HedgeDelay, Timeout = config.AttemptTimeout, Parallel = config.Parallel })
            if value then
                future.Body = value.Body
                future.Chunk = value.Chunk
                return
            end
            failure = reason or failure
            missing = gone
            if gone then
                return
            end
            if round < config.Retries then
                task.wait(round * 0.5)
            end
        end
    end)

    if not ok then
        failure = tostring(err)
    end
    if not future.Chunk then
        future.Error = tostring(failure)
        future.Missing = missing
    end
    future.Done = true
    self.Running = self.Running - 1
    self:_Pump()
end

function Features:_Pump()
    while self.Running < self.Config.MaxParallel and #self.Queue > 0 do
        local future = table.remove(self.Queue, 1)
        self.Running = self.Running + 1
        future.Started = os.clock()
        task.spawn(self._Download, self, future)
    end
end

function Features:_Start(job, fresh)
    local current = self.Downloads[job.Key]
    if current and not fresh then
        local age = os.clock() - current.Created
        local failed = current.Done and not current.Chunk
        if age < self.Config.PreloadTtl and not failed then
            return current
        end
    end
    local future = {
        Job = job,
        Created = os.clock(),
        Started = nil,
        Done = false,
        Body = nil,
        Chunk = nil,
        Error = nil,
        Missing = false
    }
    self.Downloads[job.Key] = future
    self.Queue[#self.Queue + 1] = future
    self:_Pump()
    return future
end

function Features:_Await(future)
    local limit = self.Config.Timeout * 3
    while not future.Done and not self.Window.Destroyed do
        if future.Started and os.clock() - future.Started > limit then
            break
        end
        task.wait(0.03)
    end
    if not future.Done and not future.Error then
        future.Error = self.Window.Destroyed and "window was destroyed" or "download timed out"
    end
    return future
end

function Features:_WaitElements()
    if self.ElementsReady then
        return
    end
    local registry = self.Window.Elements
    local started = os.clock()
    while registry and registry.Active > 0 and os.clock() - started < self.Config.ElementsWait and not self.Window.Destroyed do
        task.wait(0.05)
    end
    self.ElementsReady = true
end

function Features:_Purge(key)
    for _, tab in ipairs(self.Window.Tabs) do
        for index = #tab.Elements, 1, -1 do
            local element = tab.Elements[index]
            if element and element.Owner == key then
                element:Destroy()
            end
        end
    end
end

function Features:_Count()
    local counts = {}
    for _, tab in ipairs(self.Window.Tabs) do
        for _, element in ipairs(tab.Elements) do
            if not element.Destroyed then
                local owner = element.Owner or "?"
                counts[owner] = (counts[owner] or 0) + 1
            end
        end
    end
    return counts
end

function Features:_Audit(job, before)
    local window = self.Window
    if window.Destroyed or Librarys.Window ~= window then
        warn("[Ecohub] " .. tostring(job.Name) .. " replaced or destroyed the window while loading")
        return
    end
    local after = self:_Count()
    for owner, count in pairs(before) do
        local left = after[owner] or 0
        if owner ~= job.Key and left < count then
            warn("[Ecohub] " .. tostring(job.Name) .. " removed " .. tostring(count - left) .. " element(s) of " .. tostring(owner))
        end
    end
end

function Features:Busy(limit)
    local now = os.clock()
    for key, started in pairs(self.Active) do
        if now - started <= limit then
            return key
        end
    end
    return nil
end

function Features:_Run(job, chunk)
    if self.Window.Destroyed then
        return false, "window was destroyed", "run"
    end
    local window = self.Window
    local finished = false
    local late = false
    local ok = false
    local result = nil

    self:_Purge(job.Key)

    local before = self:_Count()

    self.Active[job.Key] = os.clock()

    task.spawn(function()
        Util.Owners[coroutine.running()] = job.Key
        local success, value = pcall(function()
            env.Window = window
            env.Windows = window
            env.Library = Librarys
            env.Librarys = Librarys
            return chunk(window, Librarys)
        end)
        ok = success
        result = value
        finished = true
        self.Active[job.Key] = nil
        if late and not success then
            Report("Feature failed", job.Name .. ": " .. tostring(value))
        end
    end)

    local started = os.clock()
    while not finished and not window.Destroyed and os.clock() - started < self.Config.RunTimeout do
        task.wait(0.05)
    end

    if not finished then
        if window.Destroyed then
            return false, "window was destroyed", "run"
        end
        late = true
        ok = true
        result = nil
    end

    self:_Audit(job, before)

    if ok then
        self.Loaded[job.Key] = { Name = job.Name, Path = job.Path, Key = job.Key }
        if not table.find(self.Order, job.Key) then
            self.Order[#self.Order + 1] = job.Key
        end
    else
        self:_Purge(job.Key)
    end
    return ok, result, "run"
end

function Features:_FindLoaded(name)
    local text = string.gsub(tostring(name), "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    local key
    if string.match(text, "^https?://") then
        local raw = Features._ToRaw(text)
        key = self:_UrlKey(string.match(raw, "^[^%?#]+") or raw)
    else
        key = string.lower(self:_Normalize(text))
    end
    if self.Loaded[key] then
        return key
    end
    for loadedKey, entry in pairs(self.Loaded) do
        if string.lower(entry.Name) == key then
            return loadedKey
        end
    end
    return nil
end

function Features:_Finish(job, future, options)
    self:_Await(future)
    if self.Downloads[job.Key] == future then
        self.Downloads[job.Key] = nil
    end

    if not future.Chunk then
        if job.Guess and job.Origin and not self.Window.Destroyed then
            local again = self:_Resolve(job.Origin, true)
            if again and #again > 0 and not again[1].Guess and again[1].Key ~= job.Key then
                local outcomes = self:_LoadJobs(again, options, true)
                for _, outcome in ipairs(outcomes) do
                    if not outcome.Success then
                        return false, outcome.Error
                    end
                end
                return true
            end
        end
        return false, future.Error
    end

    local ok, result = self:_Run(job, future.Chunk)
    if ok then
        return true
    end
    return false, tostring(result)
end

function Features:_LoadJobs(jobs, options, quiet)
    local reload = type(options) == "table" and options.Reload == true
    local outcomes = {}
    local pending = {}
    local first = {}
    local duplicate = {}

    for i, job in ipairs(jobs) do
        if job.Folder then
            self.Watched[job.Folder] = true
        end
        outcomes[i] = { Name = job.Name, Success = false }
        if first[job.Key] then
            duplicate[i] = first[job.Key]
        else
            first[job.Key] = i
            local waited = os.clock()
            while self.Loading[job.Key] and os.clock() - waited < self.Config.Timeout do
                task.wait(0.05)
            end
            if self.Loading[job.Key] then
                outcomes[i].Error = "still loading"
            elseif self.Loaded[job.Key] and not reload then
                outcomes[i].Success = true
            else
                if self.Loaded[job.Key] then
                    self:Unload(job.Key)
                end
                self.Loading[job.Key] = true
                pending[#pending + 1] = i
            end
        end
    end

    self:_StartWatch()

    local futures = {}
    for position, i in ipairs(pending) do
        futures[position] = self:_Start(jobs[i], reload)
    end

    if #pending > 0 then
        self:_WaitElements()
    end

    for position, i in ipairs(pending) do
        local job = jobs[i]
        local handled, success, failure = pcall(self._Finish, self, job, futures[position], options)
        self.Loading[job.Key] = nil
        if handled and success then
            outcomes[i].Success = true
        else
            local message = handled and failure or success
            outcomes[i].Error = tostring(message or "unknown error")
            if not quiet then
                Report("Feature failed", job.Name .. ": " .. outcomes[i].Error)
            end
        end
    end

    for i, target in pairs(duplicate) do
        outcomes[i].Success = outcomes[target].Success
        outcomes[i].Error = outcomes[target].Error
    end
    return outcomes
end

function Features:Load(name, options)
    if self.Window.Destroyed then
        return false
    end
    local jobs, reason = self:_Resolve(name)
    if not jobs or #jobs == 0 then
        Report("Feature failed", tostring(name) .. ": " .. tostring(reason or "no files found"))
        return false
    end
    local outcomes = self:_LoadJobs(jobs, options)
    for _, outcome in ipairs(outcomes) do
        if not outcome.Success then
            return false
        end
    end
    return true
end

function Features:LoadMany(list, options)
    local results = {}
    if self.Window.Destroyed or type(list) ~= "table" then
        return results
    end

    local jobs = {}
    local owners = {}
    for _, name in ipairs(list) do
        local label = tostring(name)
        local resolved, reason = self:_Resolve(name)
        if not resolved or #resolved == 0 then
            Report("Feature failed", label .. ": " .. tostring(reason or "no files found"))
            results[label] = false
        else
            if results[label] == nil then
                results[label] = true
            end
            for _, job in ipairs(resolved) do
                jobs[#jobs + 1] = job
                owners[#jobs] = label
            end
        end
    end

    local outcomes = self:_LoadJobs(jobs, options)
    for i, outcome in ipairs(outcomes) do
        if not outcome.Success then
            results[owners[i]] = false
        end
    end
    return results
end

function Features:LoadAll(options)
    local results = {}
    if self.Window.Destroyed then
        return results
    end
    local index = self:_Fresh(self.Config.FolderFresh) or self:_LoadIndex(false, self.Config.Timeout)
    if not index then
        Report("Feature index failed", "LoadAllFeatures needs the GitHub index, which could not be loaded")
        return results
    end

    local jobs = {}
    for _, rel in ipairs(index.Files) do
        jobs[#jobs + 1] = self:_Job(rel)
    end
    self.WatchAll = true
    local outcomes = self:_LoadJobs(jobs, options)
    for i, outcome in ipairs(outcomes) do
        results[jobs[i].Path] = outcome.Success
    end
    return results
end

function Features:Preload(list)
    if self.Window.Destroyed or type(list) ~= "table" then
        return false
    end
    task.spawn(function()
        for _, name in ipairs(list) do
            local jobs = self:_Resolve(name)
            if jobs then
                for _, job in ipairs(jobs) do
                    if not self.Loaded[job.Key] then
                        self:_Start(job, false)
                    end
                end
            end
        end
    end)
    return true
end

function Features:Unload(name)
    local key = self:_FindLoaded(name)
    if not key then
        return false
    end
    local entry = self.Loaded[key]
    self.Loaded[key] = nil
    local position = table.find(self.Order, key)
    if position then
        table.remove(self.Order, position)
    end

    local callback = env[entry.Name .. "Unload"]
    if type(callback) == "function" then
        local ok, failure = pcall(callback)
        if not ok then
            Report("Feature failed", "unload of " .. entry.Name .. ": " .. tostring(failure))
        end
        env[entry.Name .. "Unload"] = nil
    end

    self:_Purge(key)
    return true
end

function Features:UnloadAll()
    for i = #self.Order, 1, -1 do
        local key = self.Order[i]
        if key then
            self:Unload(key)
        end
    end
    return true
end

function Features:GetLoaded()
    local names = {}
    for _, key in ipairs(self.Order) do
        local entry = self.Loaded[key]
        if entry then
            names[#names + 1] = entry.Path
        end
    end
    return names
end

function Features:IsLoaded(name)
    return self:_FindLoaded(name) ~= nil
end

function Features:List()
    local names = {}
    local index = self:_LoadIndex()
    if not index then
        Report("Feature index failed", "the feature index could not be loaded")
        return names
    end
    for _, rel in ipairs(index.Files) do
        names[#names + 1] = Features._Strip(rel)
    end
    return names
end

function Features:Refresh()
    local before = self.IndexStamp
    self:_LoadIndex(true)
    return self.IndexStamp ~= before
end

function Features:SetSource(url)
    local source = Source.Parse(url)
    if not source then
        Report("Invalid source", "features source: " .. tostring(url))
        return false
    end
    self.Source = source
    self.Index = nil
    self.IndexToken = self.IndexToken + 1
    self.IndexLoading = false
    self.IndexFailed = 0
    self.IndexStamp = 0
    self.Known = nil
    self.Head = nil
    self.Watched = {}
    self.WatchAll = false
    self.Downloads = {}
    return true
end

-- // Windows
-- // ScrollArea
function Util.ScrollArea(scroll)
    scroll.ScrollBarThickness = 0
    scroll.ScrollBarImageTransparency = 1

    local parent = scroll.Parent
    local width = Config.ScrollWidth

    local bar = Util.Create("Frame", {
        Name = "ScrollArea",
        AnchorPoint = scroll.AnchorPoint,
        Position = scroll.Position,
        Size = scroll.Size,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = scroll.ZIndex + 5
    }, parent)

    local track = Util.Create("Frame", {
        Name = "Track",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -2, 0, 2),
        Size = UDim2.new(0, width + 2, 1, -4),
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    }, bar)

    local thumb = Util.Create("Frame", {
        Name = "Thumb",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        Size = UDim2.fromOffset(width, 24),
        BackgroundColor3 = Theme.Inactive,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = false,
        Visible = false
    }, track)
    Util.Corner(thumb, width / 2)

    local shown = false
    local overScroll = false
    local overThumb = false
    local dragging = false
    local last = 0

    local function paint()
        local target = 1

        if shown then
            target = (overThumb or dragging) and 0.2 or 0.55
        end

        Util.Tween(thumb, Config.ScrollTween, { BackgroundTransparency = target })
    end

    local function reveal()
        last = os.clock()

        if shown then
            return
        end

        shown = true
        thumb.Active = true
        paint()

        task.spawn(function()
            while shown and thumb.Parent do
                task.wait(0.15)

                if not (overScroll or overThumb or dragging) and os.clock() - last > Config.ScrollHold then
                    shown = false
                    thumb.Active = false
                    paint()
                end
            end
        end)
    end

    local function update()
        local view = scroll.AbsoluteSize.Y
        local canvas = scroll.AbsoluteCanvasSize.Y
        local room = track.AbsoluteSize.Y
        local range = canvas - view

        if range <= 1 or view <= 0 or room <= 0 then
            thumb.Visible = false
            return
        end

        local height = math.clamp(room * view / canvas, 24, room)
        local alpha = math.clamp(scroll.CanvasPosition.Y / range, 0, 1)

        thumb.Size = UDim2.fromOffset(width, height)
        thumb.Position = UDim2.new(1, -1, 0, alpha * (room - height))
        thumb.Visible = true
    end

    local function mirror()
        bar.AnchorPoint = scroll.AnchorPoint
        bar.Position = scroll.Position
        bar.Size = scroll.Size
        update()
    end

    for _, property in ipairs({ "AnchorPoint", "Position", "Size" }) do
        scroll:GetPropertyChangedSignal(property):Connect(mirror)
    end

    scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
    scroll:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(update)
    track:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
    scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        update()
        reveal()
    end)

    if parent:IsA("GuiObject") then
        parent:GetPropertyChangedSignal("Visible"):Connect(update)
    end

    scroll.MouseEnter:Connect(function()
        overScroll = true
        reveal()
    end)

    scroll.MouseLeave:Connect(function()
        overScroll = false
        last = os.clock()
    end)

    scroll.MouseMoved:Connect(function()
        if shown then
            last = os.clock()
        else
            reveal()
        end
    end)

    thumb.MouseEnter:Connect(function()
        overThumb = true
        paint()
    end)

    thumb.MouseLeave:Connect(function()
        overThumb = false
        last = os.clock()
        paint()
    end)

    thumb.InputBegan:Connect(function(input)
        if not shown or not Util.IsPress(input) then
            return
        end

        dragging = true
        paint()

        local startY = input.Position.Y
        local startCanvas = scroll.CanvasPosition.Y
        local moveConnection
        local endConnection

        local function finish()
            dragging = false
            last = os.clock()

            if moveConnection then
                moveConnection:Disconnect()
            end

            if endConnection then
                endConnection:Disconnect()
            end

            paint()
        end

        moveConnection = UserInputService.InputChanged:Connect(function(move)
            if not Util.IsMove(move) then
                return
            end

            local room = track.AbsoluteSize.Y
            local travel = room - thumb.AbsoluteSize.Y
            local range = scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteSize.Y

            if travel <= 0 or range <= 0 then
                return
            end

            local delta = move.Position.Y - startY
            scroll.CanvasPosition = Vector2.new(scroll.CanvasPosition.X, math.clamp(startCanvas + delta * range / travel, 0, range))
        end)

        endConnection = UserInputService.InputEnded:Connect(function(ended)
            if Util.IsPress(ended) then
                finish()
            end
        end)
    end)

    task.defer(update)
    return bar
end

local Windows = {}
Windows.__index = Windows
Windows.Font = Enum.Font.Gotham

local function ClampPosition(Position, Pad)
    local Camera = workspace.CurrentCamera
    local View = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
    local X = math.clamp(Position.X.Scale * View.X + Position.X.Offset, 0, math.max(View.X - Pad.X, 0))
    local Y = math.clamp(Position.Y.Scale * View.Y + Position.Y.Offset, 0, math.max(View.Y - Pad.Y, 0))

    return UDim2.fromOffset(X, Y)
end

local function ToUDim2(Value)
    if type(Value) == "table" and type(Value[1]) == "number" and type(Value[2]) == "number" and type(Value[3]) == "number" and type(Value[4]) == "number" then
        return UDim2.new(Value[1], Value[2], Value[3], Value[4])
    end

    return nil
end

local function FromUDim2(Position)
    return { Position.X.Scale, Position.X.Offset, Position.Y.Scale, Position.Y.Offset }
end

local function ResolveSize(Value)
    if typeof(Value) ~= "UDim2" then
        return UDim2.fromOffset(620, 350)
    end

    local Width = Value.X.Scale == 0 and math.max(Value.X.Offset, 420) or Value.X.Offset
    local Height = Value.Y.Scale == 0 and math.max(Value.Y.Offset, 260) or Value.Y.Offset

    return UDim2.new(Value.X.Scale, Width, Value.Y.Scale, Height)
end

function Windows.new(Options)
    Options = type(Options) == "table" and Options or {}

    local Previous = env.EcoHubPanel

    if type(Previous) == "table" and type(Previous.Destroy) == "function" then
        pcall(Previous.Destroy, Previous)
    end

    local self = setmetatable({}, Windows)

    self.Name = "Ecohub"
    self.Title = tostring(Options.Title or "Ecohub")
    self.Subtitle = tostring(Options.SubTitle or Options.Subtitle or "Panel")
    self.Size = ResolveSize(Options.Size)
    self.ToggleKey = typeof(Options.MinimizeKey) == "EnumItem" and Options.MinimizeKey or Enum.KeyCode.RightShift
    self.KeyLocked = typeof(Options.MinimizeKey) == "EnumItem"
    self.MaxQuery = 48
    self.Query = ""
    self.Visible = true
    self.Connections = {}
    self.SearchChanged = Instance.new("BindableEvent")

    self.SearchOpen = false
    self.SearchRenderId = 0
    self.SearchItems = {}
    self.SearchSelected = 0

    self.SettingsOpen = false
    self.SettingsSections = {}

    self.Theme = Theme
    self.ThemeName = "Default"
    self.ThemeToken = 0

    self.SectionOrder = 0
    self.SideSections = {}
    self.SideSectionsByName = {}
    self.Tabs = {}
    self.ActiveTab = nil

    self.Elements = nil

    self.Util = Util
    self.Config = Config
    self.GetIcon = GetIcon
    self.Report = Report
    self.IsTouch = IsTouch
    self.Destroyed = false
    self.Crumbs = nil
    self.Features = Features.new(self)
    self.FeatureConfig = self.Features.Config

    self.Saves = SaveManager.new(Config.SaveFile)
    Machine.Attach(self.Saves)
    self:_BuildPanelApi()
    self:_LoadSaved()

    local Success, Result = pcall(function()
        self:_Build()
        self:_BuildElements()
        self:_BuildSearch()
        self:_BuildSettings()
        self:_BuildToggle()
        self:_BindSearch()
        self:_BindSearchKeys()
        self:_BindSettings()
        self:_BindDrag()
        self:_BindToggle()
        self:_BindToggleDrag()
        self:_BuildThemeSettings()
        self:_BuildSaveSettings()
        self:_RestorePositions()
        self:_BindAutoSave()
        self:_BindLocale()
    end)

    if not Success then
        Report("Window failed", Result)
        self:Destroy()
        return nil
    end

    return self
end

function Windows:_BuildPanelApi()
    local Window = self

    local function Unwrap(Owner, First, Second, Third)
        if rawequal(First, Owner) then
            return Second, Third
        end

        return First, Second
    end

    self.CreateIcon = Util.Icon

    self.Locale = Locale

    self.Error = function(First, Second, Third)
        local Title, Detail = Unwrap(Window, First, Second, Third)
        Report(tostring(Title or "Error"), tostring(Detail or ""))
    end

    local SaveApi = {}

    function SaveApi.Get(First, Second, Third)
        local Key, Default = Unwrap(SaveApi, First, Second, Third)

        if not Window.Saves then
            return Default
        end

        return Window.Saves:GetAuto(Key, Default)
    end

    function SaveApi.Set(First, Second, Third)
        local Key, Value = Unwrap(SaveApi, First, Second, Third)

        if Window.Saves then
            Window.Saves:SetAuto(Key, Value)
        end
    end

    function SaveApi.Delete(First, Second)
        local Key = Unwrap(SaveApi, First, Second)

        if Window.Saves then
            Window.Saves:DeleteAuto(Key)
        end
    end

    self.Save = SaveApi
end

function Windows:_LoadSaved()
    local KeyName = self.Saves:GetSetting("ToggleKey")

    if not self.KeyLocked and type(KeyName) == "string" then
        local Success, Key = pcall(function()
            return Enum.KeyCode[KeyName]
        end)

        if Success and Key then
            self.ToggleKey = Key
        end
    end

    local Name = self.Saves:GetSetting("Theme", "Default")
    local Colors = Themes.Parse(self.Saves:GetSetting("ThemeColors"))

    if type(Name) == "string" and string.lower(Name) ~= "default" and Colors then
        for Key, Color in pairs(BuildPalette(Colors)) do
            Theme[Key] = Color
        end

        self.ThemeName = Name
    end
end

function Windows:_SavePosition(Key, Position)
    if self.Saves then
        self.Saves:SetSetting(Key, FromUDim2(Position))
    end
end

function Windows:_RestorePositions()
    local WindowPosition = ToUDim2(self.Saves:GetSetting("WindowPosition"))
    local TogglePosition = ToUDim2(self.Saves:GetSetting("TogglePosition"))

    if WindowPosition then
        self.Window.Position = ClampPosition(WindowPosition, Vector2.zero)
    end

    if TogglePosition then
        self.ToggleButton.Position = ClampPosition(TogglePosition, Vector2.new(48, 48))
    end
end

function Windows:_Build()
    local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local Old = PlayerGui:FindFirstChild(self.Name)

    if Old then
        Old:Destroy()
    end

    self.Gui = Util.Create("ScreenGui", {
        Name = self.Name,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 100,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, PlayerGui)

    table.insert(self.Connections, self.Gui.Destroying:Connect(function()
        self:Destroy()
    end))

    self.Window = Util.Create("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = self.Size,
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    }, self.Gui)

    self.Main = Util.Create("Frame", {
        Name = "Main",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, self.Window)
    Util.Corner(self.Main, 10)

    local Border = Util.Create("Frame", {
        Name = "Border",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 50
    }, self.Window)
    Util.Corner(Border, 10)
    Util.Create("UIStroke", {
        Color = Theme.Border,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, Border)

    self.Sidebar = Util.Create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, Config.SidebarWidth, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    }, self.Main)

    Util.Create("Frame", {
        Name = "Line",
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = Theme.Divider,
        BorderSizePixel = 0
    }, self.Sidebar)

    self.Dashboard = Util.Create("Frame", {
        Name = "Dashboard",
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    }, self.Sidebar)

    self.TitleLabel = Util.Create("TextLabel", {
        Name = "Title",
        Position = UDim2.fromOffset(14, 16),
        Size = UDim2.new(1, -24, 0, 18),
        BackgroundTransparency = 1,
        Text = self.Title,
        TextColor3 = Theme.Text,
        TextSize = 15,
        Font = Enum.Font.SourceSansBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, self.Dashboard)

    self.SubtitleLabel = Util.Create("TextLabel", {
        Name = "Subtitle",
        Position = UDim2.fromOffset(14, 34),
        Size = UDim2.new(1, -24, 0, 14),
        BackgroundTransparency = 1,
        Text = self.Subtitle,
        TextColor3 = Theme.Subtitle,
        TextSize = 12,
        Font = Enum.Font.SourceSans,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, self.Dashboard)

    self.TabList = Util.Create("ScrollingFrame", {
        Name = "TabList",
        Position = UDim2.fromOffset(0, 56),
        Size = UDim2.new(1, 0, 1, -56),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    }, self.Sidebar)
    Util.Padding(self.TabList, 2, 8, 10, 10)
    Util.List(self.TabList, 8)
    Util.ScrollArea(self.TabList)

    self.ContentArea = Util.Create("Frame", {
        Name = "ContentArea",
        Position = UDim2.fromOffset(Config.SidebarWidth + 1, 0),
        Size = UDim2.new(1, -(Config.SidebarWidth + 1), 1, 0),
        BackgroundTransparency = 1
    }, self.Main)

    self.Header = Util.Create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1
    }, self.ContentArea)

    self.PageHolder = Util.Create("Frame", {
        Name = "PageHolder",
        Position = UDim2.fromOffset(0, 40),
        Size = UDim2.new(1, 0, 1, -40),
        BackgroundTransparency = 1
    }, self.ContentArea)

    self.Breadcrumb = Util.Create("Frame", {
        Name = "Breadcrumb",
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -200, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true
    }, self.Header)
    Util.List(self.Breadcrumb, 4, {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center
    })

    self.SettingsButton = Util.Create("ImageButton", {
        Name = "Settings",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(20, 20),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Image = GetIcon("settings"),
        ImageColor3 = Theme.Inactive
    }, self.Header)

    self.SearchBar = Util.Create("Frame", {
        Name = "SearchBar",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -44, 0.5, 0),
        Size = UDim2.fromOffset(140, IsTouch and 30 or 26),
        BackgroundColor3 = Theme.Field,
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, self.Header)
    Util.Corner(self.SearchBar, 6)
    Util.Create("UIStroke", {
        Color = Theme.Border,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, self.SearchBar)

    local SearchIcon = Util.Icon(self.SearchBar, "search", 14, Theme.Dim)
    SearchIcon.AnchorPoint = Vector2.new(0, 0.5)
    SearchIcon.Position = UDim2.new(0, 8, 0.5, 0)

    self.SearchButton = Util.Create("TextButton", {
        Name = "SearchButton",
        Position = UDim2.fromOffset(28, 0),
        Size = UDim2.new(1, -34, 1, 0),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = Locale.Translate("Search..."),
        TextColor3 = Theme.Placeholder,
        TextSize = 13,
        Font = Enum.Font.SourceSans,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, self.SearchBar)
end

function Windows:_BuildElements()
    local Previous = env.EcoHubElements

    if type(Previous) == "table" then
        Previous.Destroyed = true
    end

    self.Elements = ElementRegistry.new()
    self.Elements.Panel = self
    self.Elements.OnChanged = function()
        self:RefreshSearch()
    end

    env.EcoHubPanel = self
    env.EcoHubElements = self.Elements
    env.EcoHubSaves = self.Saves
end

function Windows:LoadElements(Force)
    if self.Elements then
        self.Elements.Load(nil, Force)
    end
end

function Windows:ListElements()
    if self.Elements then
        return self.Elements.List()
    end

    return {}
end

function Windows:_CreatePalette(Name, IconName, Side)
    local Palette = { Token = 0 }

    Palette.Overlay = Util.Create("TextButton", {
        Name = Name .. "Overlay",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Visible = false,
        ZIndex = 20
    }, self.Main)
    Util.Corner(Palette.Overlay, 10)

    Palette.Frame = Util.Create("Frame", {
        Name = Name .. "Frame",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 46),
        Size = UDim2.new(1, -20, 0, 93),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Active = true,
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 21
    }, self.Main)
    Palette.Frame:SetAttribute("NoTheme", true)
    Util.Corner(Palette.Frame, 12)
    Util.Stroke(Palette.Frame, Theme.BorderHover, 1)
    Util.Create("UIGradient", {
        Color = ColorSequence.new(Theme.GradientTop, Theme.GradientBottom),
        Rotation = 90
    }, Palette.Frame)
    Util.Create("UISizeConstraint", { MaxSize = Vector2.new(340, math.huge) }, Palette.Frame)
    Palette.Scale = Util.Create("UIScale", { Scale = 0.96 }, Palette.Frame)

    Palette.Header = Util.Create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        ClipsDescendants = true
    }, Palette.Frame)

    local Icon = Util.Icon(Palette.Header, IconName, 16, Theme.Dim)
    Icon.AnchorPoint = Vector2.new(0, 0.5)
    Icon.Position = UDim2.new(0, 12, 0.5, 0)

    Palette.Close = Util.Create("TextButton", {
        Name = "Close",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(28, 28),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = ""
    }, Palette.Header)

    Palette.CloseIcon = Util.Icon(Palette.Close, "x", 14, Theme.Dim)
    Palette.CloseIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    Palette.CloseIcon.Position = UDim2.fromScale(0.5, 0.5)

    Util.Create("Frame", {
        Name = "Divider",
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.fromOffset(0, 44),
        BackgroundColor3 = Theme.Divider,
        BorderSizePixel = 0
    }, Palette.Frame)

    Palette.List = Util.Create("ScrollingFrame", {
        Name = "List",
        Size = UDim2.new(1, 0, 0, 48),
        Position = UDim2.fromOffset(0, 45),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.Inactive,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ClipsDescendants = true
    }, Palette.Frame)
    Util.Padding(Palette.List, 4, 4, Side, Side)
    Palette.Layout = Util.List(Palette.List, 2)

    table.insert(self.Connections, Palette.Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self:_ResizePalette(Palette)
    end))

    table.insert(self.Connections, Palette.Close.MouseEnter:Connect(function()
        Util.Tween(Palette.CloseIcon, Config.TweenInfo, { ImageColor3 = Theme.Active })
    end))

    table.insert(self.Connections, Palette.Close.MouseLeave:Connect(function()
        Util.Tween(Palette.CloseIcon, Config.TweenInfo, { ImageColor3 = Theme.Dim })
    end))

    return Palette
end

function Windows:_ResizePalette(Palette)
    local Limit = math.clamp(self.Main.AbsoluteSize.Y - 112, 96, 230)
    local Height = math.clamp(Palette.Layout.AbsoluteContentSize.Y + 8, 48, Limit)

    Palette.List.Size = UDim2.new(1, 0, 0, Height)
    Palette.Frame.Size = UDim2.new(1, -20, 0, 45 + Height)
end

function Windows:_ShowPalette(Palette)
    Palette.Token = Palette.Token + 1

    Palette.Overlay.Visible = true
    Palette.Frame.Visible = true
    Palette.Overlay.BackgroundTransparency = 1
    Palette.Scale.Scale = 0.96

    Util.Tween(Palette.Overlay, Config.TweenInfo, { BackgroundTransparency = 0.5 })
    Util.Tween(Palette.Scale, Config.TweenInfo, { Scale = 1 })
end

function Windows:_HidePalette(Palette)
    Palette.Token = Palette.Token + 1

    local Token = Palette.Token

    Util.Tween(Palette.Scale, Config.TweenInfo, { Scale = 0.96 })

    local Tween = Util.Tween(Palette.Overlay, Config.TweenInfo, { BackgroundTransparency = 1 })

    Tween.Completed:Connect(function()
        if Palette.Token == Token then
            Palette.Overlay.Visible = false
            Palette.Frame.Visible = false
        end
    end)
end

function Windows:_BuildSearch()
    self.SearchPalette = self:_CreatePalette("Search", "search", 4)

    self.PaletteInput = Util.Create("TextBox", {
        Name = "Input",
        Size = UDim2.new(1, -76, 1, 0),
        Position = UDim2.new(0, 36, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = Locale.Translate("Search tabs and elements..."),
        PlaceholderColor3 = Theme.Placeholder,
        TextColor3 = Theme.Text,
        TextSize = 13,
        Font = Windows.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ClipsDescendants = true,
        TextWrapped = false,
        MultiLine = false
    }, self.SearchPalette.Header)
end

function Windows:_BindSearch()
    local Palette = self.SearchPalette

    table.insert(self.Connections, self.PaletteInput:GetPropertyChangedSignal("Text"):Connect(function()
        local Text = self.PaletteInput.Text
        local Clean = (string.gsub(Text, "%c", " "))
        local Length = utf8.len(Clean) or #Clean

        if Length > self.MaxQuery then
            local Cut = utf8.offset(Clean, self.MaxQuery + 1)

            if Cut then
                Clean = string.sub(Clean, 1, Cut - 1)
            else
                Clean = string.sub(Clean, 1, self.MaxQuery)
            end
        end

        if Clean ~= Text then
            self.PaletteInput.Text = Clean
            return
        end

        self.Query = Util.Fold(string.match(Clean, "^%s*(.-)%s*$") or "")
        self.SearchChanged:Fire(self.Query)

        if not self.SearchOpen then
            return
        end

        self.SearchRenderId = self.SearchRenderId + 1
        local Id = self.SearchRenderId

        task.delay(0.06, function()
            if self.SearchOpen and self.SearchRenderId == Id then
                self:RenderSearch(self.Query)
            end
        end)
    end))

    table.insert(self.Connections, self.SearchButton.Activated:Connect(function()
        self:OpenSearch()
    end))

    table.insert(self.Connections, Palette.Overlay.Activated:Connect(function()
        self:CloseSearch()
    end))

    table.insert(self.Connections, Palette.Close.Activated:Connect(function()
        self:CloseSearch()
    end))

    table.insert(self.Connections, self.PaletteInput.FocusLost:Connect(function(EnterPressed)
        if not EnterPressed or not self.SearchOpen then
            return
        end

        local Item = self.SearchItems[self.SearchSelected]

        if Item then
            self:_ActivateSearch(Item)
        end
    end))
end

function Windows:_BindSearchKeys()
    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(Input)
        if Input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end

        if Input.KeyCode == Enum.KeyCode.Escape then
            if self.SettingsOpen then
                self:CloseSettings()
            elseif self.SearchOpen then
                self:CloseSearch()
            end
        elseif self.SearchOpen then
            if Input.KeyCode == Enum.KeyCode.Down then
                self:_MoveSearch(1)
            elseif Input.KeyCode == Enum.KeyCode.Up then
                self:_MoveSearch(-1)
            end
        end
    end))
end

function Windows:_ClearSearch()
    for _, Child in ipairs(self.SearchPalette.List:GetChildren()) do
        if Child:IsA("GuiObject") then
            Child:Destroy()
        end
    end

    self.SearchItems = {}
    self.SearchSelected = 0
end

function Windows:_SetSearchSelected(Index, Scroll)
    local Previous = self.SearchItems[self.SearchSelected]

    if Previous and Previous.Button.Parent then
        Previous.Button.BackgroundTransparency = 1
        Previous.Stroke.Transparency = 1
    end

    self.SearchSelected = Index

    local Item = self.SearchItems[Index]

    if not Item then
        return
    end

    Item.Button.BackgroundTransparency = 0
    Item.Stroke.Transparency = 0.55

    if Scroll then
        local List = self.SearchPalette.List
        local Current = List.CanvasPosition.Y
        local Top = Item.Button.AbsolutePosition.Y - List.AbsolutePosition.Y + Current
        local Bottom = Top + Item.Button.AbsoluteSize.Y
        local View = List.AbsoluteSize.Y

        if Top < Current then
            List.CanvasPosition = Vector2.new(0, math.max(Top - 28, 0))
        elseif Bottom > Current + View then
            List.CanvasPosition = Vector2.new(0, Bottom - View + 4)
        end
    end
end

function Windows:_MoveSearch(Step)
    local Count = #self.SearchItems

    if Count == 0 then
        return
    end

    local Next = self.SearchSelected + Step

    if Next > Count then
        Next = 1
    elseif Next < 1 then
        Next = Count
    end

    self:_SetSearchSelected(Next, true)
end

function Windows:_FocusElement(Element)
    local Container = Element.Container
    local Scroll = Element.Tab.Scroll

    if Container and Container.Parent and Scroll then
        local Target = Container.AbsolutePosition.Y - Scroll.AbsolutePosition.Y + Scroll.CanvasPosition.Y - 34
        local Limit = math.max(Scroll.AbsoluteCanvasSize.Y - Scroll.AbsoluteSize.Y, 0)

        Util.Tween(Scroll, Config.TweenInfo, { CanvasPosition = Vector2.new(0, math.clamp(Target, 0, Limit)) })
    end

    if Element.Flash then
        Element.Flash.Transparency = 0
        Util.Tween(Element.Flash, Config.FlashInfo, { Transparency = 1 })
    end

    if type(Element.OnFocus) == "function" then
        pcall(Element.OnFocus, Element)
    end
end

function Windows:_ActivateSearch(Item)
    self:CloseSearch()

    if Item.Kind == "tab" then
        self:SelectTab(Item.Tab)
    else
        self:SelectTab(Item.Element.Tab)

        task.delay(0.05, function()
            if not Item.Element.Destroyed then
                self:_FocusElement(Item.Element)
            end
        end)
    end
end

function Windows:_CreateSearchHeading(Order, Text)
    local Label = Util.Create("TextLabel", {
        Name = "Heading",
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = Text,
        TextColor3 = Theme.Dim,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = Order
    }, self.SearchPalette.List)

    Util.Padding(Label, 0, 0, 8, 8)
end

function Windows:_CreateSearchSeparator(Order)
    Util.Create("Frame", {
        Name = "Separator",
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Divider,
        BorderSizePixel = 0,
        LayoutOrder = Order
    }, self.SearchPalette.List)
end

function Windows:_CreateSearchRow(Order, Data)
    local Button = Util.Create("TextButton", {
        Name = "Item",
        Size = UDim2.new(1, 0, 0, IsTouch and 38 or 34),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        ClipsDescendants = true,
        LayoutOrder = Order
    }, self.SearchPalette.List)
    Util.Corner(Button, 8)

    Data.Stroke = Util.Create("UIStroke", {
        Color = Theme.BorderHover,
        Thickness = 1,
        Transparency = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, Button)

    local Icon = Util.Icon(Button, Data.Icon, 16, Theme.Inactive)
    Icon.AnchorPoint = Vector2.new(0, 0.5)
    Icon.Position = UDim2.new(0, 8, 0.5, 0)

    local Hint = Util.Create("Frame", {
        Name = "Hint",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0.4, 0, 0, 16),
        BackgroundTransparency = 1,
        ClipsDescendants = true
    }, Button)
    Util.List(Hint, 4, {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center
    })

    local Trail = Data.Trail

    for Index, Part in ipairs(Trail) do
        Util.Create("TextLabel", {
            Name = "Part" .. Index,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = tostring(Part),
            TextColor3 = Theme.Dim,
            TextSize = 11,
            Font = Windows.Font,
            LayoutOrder = Index * 2 - 1
        }, Hint)

        if Index < #Trail then
            local Separator = Util.Icon(Hint, "chevron-right", 12, Theme.Dim)
            Separator.Name = "Sep" .. Index
            Separator.LayoutOrder = Index * 2
        end
    end

    Util.Create("TextLabel", {
        Name = "Text",
        Size = UDim2.new(0.6, -44, 1, 0),
        Position = UDim2.new(0, 32, 0, 0),
        BackgroundTransparency = 1,
        Text = Data.Name,
        TextColor3 = Theme.Active,
        TextSize = 13,
        Font = Windows.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, Button)

    Data.Button = Button
    table.insert(self.SearchItems, Data)

    local Index = #self.SearchItems

    Button.MouseEnter:Connect(function()
        self:_SetSearchSelected(Index, false)
    end)

    Button.Activated:Connect(function()
        self:_ActivateSearch(Data)
    end)
end

local function Haystack(Item, Parts)
    if Item.SearchVersion ~= Locale.Version then
        Item.SearchVersion = Locale.Version

        local Text = table.concat(Parts, " ")

        if Locale.IsActive() then
            for _, Part in ipairs(Parts) do
                Text = Text .. " " .. Locale.Translate(Part)
            end
        end

        Item.SearchText = Util.Fold(Text)
    end

    return Item.SearchText
end

function Windows:RenderSearch(Query)
    self:_ClearSearch()

    local Order = 0
    local Groups = 0

    for _, Section in ipairs(self.SideSections) do
        local SectionName = Locale.Translate(Section.Name)

        for _, Tab in ipairs(Section.Tabs) do
            local TabName = Locale.Translate(Tab.Name)
            local TabMatch = Query ~= "" and Util.Contains(Haystack(Tab, { Tab.Name, Section.Name }), Query)
            local Rows = {}

            for _, Element in ipairs(Tab.Elements) do
                if Element.Built and not Element.Destroyed then
                    local Parts = { Element.Name, Element.Type, Element.Group, Tab.Name, Element.Description }

                    if Query == "" or TabMatch or Util.Contains(Haystack(Element, Parts), Query) then
                        table.insert(Rows, {
                            Kind = "element",
                            Name = Locale.Translate(Element.Name),
                            Icon = ElementIcons[string.lower(Element.Type)] or "box",
                            Trail = { Locale.Translate(Element.Group) },
                            Element = Element
                        })
                    end
                end
            end

            if Query == "" or TabMatch or #Rows > 0 then
                table.insert(Rows, 1, { Kind = "tab", Name = TabName, Icon = Tab.IconName, Trail = { SectionName }, Tab = Tab })
            end

            if #Rows > 0 then
                Groups = Groups + 1

                if Groups > 1 then
                    Order = Order + 1
                    self:_CreateSearchSeparator(Order)
                end

                Order = Order + 1
                self:_CreateSearchHeading(Order, TabName)

                for _, Row in ipairs(Rows) do
                    Order = Order + 1
                    self:_CreateSearchRow(Order, Row)
                end
            end
        end
    end

    if Groups == 0 then
        Util.Create("TextLabel", {
            Name = "Empty",
            Size = UDim2.new(1, 0, 0, 48),
            BackgroundTransparency = 1,
            Text = Locale.Translate("No results found."),
            TextColor3 = Theme.Dim,
            TextSize = 13,
            Font = Windows.Font
        }, self.SearchPalette.List)
    else
        self:_SetSearchSelected(1, false)
    end

    self.SearchPalette.List.CanvasPosition = Vector2.new(0, 0)
    self:_ResizePalette(self.SearchPalette)
end

function Windows:RefreshSearch()
    if self.SearchOpen then
        self:RenderSearch(self.Query)
    end
end

function Windows:OpenSearch()
    if self.SearchOpen or not self.Visible then
        return
    end

    self:CloseSettings()

    self.SearchOpen = true
    self.PaletteInput.Text = ""
    self:RenderSearch("")
    self:_ShowPalette(self.SearchPalette)

    task.defer(function()
        if self.SearchOpen then
            self.PaletteInput:CaptureFocus()
        end
    end)
end

function Windows:CloseSearch()
    if not self.SearchOpen then
        return
    end

    self.SearchOpen = false
    self.SearchRenderId = self.SearchRenderId + 1

    self.PaletteInput:ReleaseFocus()
    self:_HidePalette(self.SearchPalette)
end

function Windows:ClearSearch()
    self.PaletteInput.Text = ""
end

function Windows:_BuildSettings()
    self.SettingsPalette = self:_CreatePalette("Settings", "settings", 8)
    self.SettingsPalette.Layout.Padding = UDim.new(0, 8)

    self.SettingsTab = {
        Name = "Settings",
        Window = self,
        Sections = {},
        Elements = {},
        Scroll = self.SettingsPalette.List,
        Page = self.SettingsPalette.Frame
    }

    Util.Create("TextLabel", {
        Name = "Title",
        Position = UDim2.new(0, 36, 0, 0),
        Size = UDim2.new(1, -76, 1, 0),
        BackgroundTransparency = 1,
        Text = "Settings",
        TextColor3 = Theme.Text,
        TextSize = 13,
        Font = Windows.Font,
        TextXAlignment = Enum.TextXAlignment.Left
    }, self.SettingsPalette.Header)

    Locale.Bind(self.SettingsPalette.Header.Title, "Text")
end

function Windows:_BindSettings()
    local Palette = self.SettingsPalette

    table.insert(self.Connections, self.SettingsButton.Activated:Connect(function()
        if self.SettingsOpen then
            self:CloseSettings()
        else
            self:OpenSettings()
        end
    end))

    table.insert(self.Connections, self.SettingsButton.MouseEnter:Connect(function()
        Util.Tween(self.SettingsButton, Config.TweenInfo, { ImageColor3 = Theme.Active })
    end))

    table.insert(self.Connections, self.SettingsButton.MouseLeave:Connect(function()
        Util.Tween(self.SettingsButton, Config.TweenInfo, { ImageColor3 = Theme.Inactive })
    end))

    table.insert(self.Connections, Palette.Overlay.Activated:Connect(function()
        self:CloseSettings()
    end))

    table.insert(self.Connections, Palette.Close.Activated:Connect(function()
        self:CloseSettings()
    end))
end

function Windows:OpenSettings()
    if self.SettingsOpen or not self.Visible then
        return
    end

    self:CloseSearch()

    self.SettingsOpen = true
    self.SettingsPalette.List.CanvasPosition = Vector2.new(0, 0)
    self:_ResizePalette(self.SettingsPalette)
    self:_ShowPalette(self.SettingsPalette)
end

function Windows:CloseSettings()
    if not self.SettingsOpen then
        return
    end

    self.SettingsOpen = false
    self:_HidePalette(self.SettingsPalette)
end

function Windows:_CreateRegistered(Section, Name, Options)
    local Window = self
    local Registry = self.Elements

    Options = type(Options) == "table" and Options or {}
    Name = tostring(Name)

    local Key = Util.ResolveKey(Name)
    local Core = nil
    local Savable = not Section.NoSave and self.Saves ~= nil

    if Savable then
        local Original = Options.callback
        local Copy = {}

        for OptionKey, OptionValue in pairs(Options) do
            Copy[OptionKey] = OptionValue
        end

        Copy.callback = function(...)
            if type(Original) == "function" then
                local Success, Failure = pcall(Original, ...)

                if not Success then
                    Report("Callback", Name .. ": " .. tostring(Failure))
                end
            end

            if Core and Core.Flag and Window.Saves then
                Window.Saves:Changed(Core.Flag)
            end
        end

        Options = Copy
    end

    local Owner = Util.Owners[coroutine.running()]
    local ElementName = tostring(Options.title or Options.Title or Options.name or Options.Name or Options.Text or Options.Label or Name)
    local DedupeKey = string.gsub(ElementName, "%d+%s*[dhms]%f[%A]", "#")
    local Order = nil

    for Index = #Section.Tab.Elements, 1, -1 do
        local Existing = Section.Tab.Elements[Index]

        if Existing and not Existing.Destroyed and Existing.Section == Section and Existing.Type == Name and Existing.Key == DedupeKey then
            Order = Existing.Container.LayoutOrder
            Section.Used[Existing.Name] = math.max((Section.Used[Existing.Name] or 1) - 1, 0)
            Existing:Destroy()
        end
    end

    Section.Count = Section.Count + 1

    local Container = Util.Create("Frame", {
        Name = Name,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        LayoutOrder = Section.Count,
        Visible = false
    }, Section.Holder or Section.Frame)
    Container:SetAttribute("NoTheme", true)
    Util.Corner(Container, 8)

    if Order then
        Container.LayoutOrder = Order
    end

    local Constraint = Util.Create("UISizeConstraint", { MinSize = Vector2.new(0, 38) }, Container)
    Util.Create("UIGradient", {
        Color = ColorSequence.new(Theme.GradientTop, Theme.GradientBottom),
        Rotation = 90
    }, Container)

    local Border = Util.Create("UIStroke", { Name = "Border", Color = Theme.Border, Thickness = 1 }, Container)
    local Flash = Util.Create("UIStroke", { Name = "Flash", Color = Theme.Active, Thickness = 1.5, Transparency = 1 }, Container)
    local Inset = Util.Create("UIPadding", { Name = "Inset" }, Container)

    local Deco = Util.Create("Frame", {
        Name = "Hover",
        BackgroundColor3 = Theme.Active,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Visible = false
    }, Container)
    Util.Corner(Deco, 8)

    if not IsTouch then
        Container.MouseEnter:Connect(function()
            Util.Tween(Deco, Config.TweenInfo, { BackgroundTransparency = 0.94 })
            Util.Tween(Border, Config.TweenInfo, { Color = Theme.BorderHover })
        end)

        Container.MouseLeave:Connect(function()
            Util.Tween(Deco, Config.TweenInfo, { BackgroundTransparency = 1 })
            Util.Tween(Border, Config.TweenInfo, { Color = Theme.Border })
        end)
    end

    Core = {
        Type = Name,
        Name = tostring(Options.title or Options.Title or Options.name or Options.Name or Options.Text or Options.Label or Name),
        Key = DedupeKey,
        Group = Section.Name,
        Description = tostring(Options.description or Options.Description or ""),
        Tab = Section.Tab,
        Section = Section,
        Container = Container,
        Constraint = Constraint,
        Border = Border,
        Flash = Flash,
        Inset = Inset,
        Deco = Deco,
        Calls = {},
        Built = false,
        Building = false,
        Destroyed = false,
        Instance = nil,
        Owner = Owner,
        Registry = Registry,
        Flag = nil
    }

    local function ApplyFrame(Frameless)
        local Pad = Frameless and 0 or 5
        local Side = Frameless and 0 or 12

        Container.BackgroundTransparency = Frameless and 1 or 0
        Constraint.MinSize = Vector2.new(0, Frameless and 0 or 38)
        Border.Enabled = not Frameless
        Inset.PaddingTop = UDim.new(0, Pad)
        Inset.PaddingBottom = UDim.new(0, Pad)
        Inset.PaddingLeft = UDim.new(0, Side)
        Inset.PaddingRight = UDim.new(0, Side)
        Deco.Position = UDim2.fromOffset(-Side, -Pad)
        Deco.Size = UDim2.new(1, Side * 2, 1, Pad * 2)
        Deco.Visible = not Frameless
    end

    function Core:Build(Entry, BuildOptions, Attempt)
        if self.Destroyed or self.Built or self.Building then
            return
        end

        self.Building = true
        Attempt = Attempt or 1
        ApplyFrame(Entry.Frameless)

        local Scope = {
            frame = Container,
            Panel = Registry.Panel,
            Tab = Section.Tab,
            Section = Section,
            Element = self,
            Elements = Registry,
            CreateIcon = Util.Icon
        }

        local Existing = {}

        for _, Child in ipairs(Container:GetChildren()) do
            Existing[Child] = true
        end

        local Success, Result = pcall(Entry.Builder, Scope, BuildOptions or Options)
        self.Building = false

        if self.Destroyed then
            return
        end

        if not Success then
            for _, Child in ipairs(Container:GetChildren()) do
                if not Existing[Child] then
                    Child:Destroy()
                end
            end

            if Attempt == 1 or Attempt == Config.BuildRetries then
                Report("Element failed", Name .. " (try " .. Attempt .. "): " .. tostring(Result))
            end

            if Attempt < Config.BuildRetries + Config.BuildLateRetries then
                local Delay = Attempt < Config.BuildRetries and 0.5 * Attempt or Config.BuildLateDelay

                task.delay(Delay, function()
                    if not self.Destroyed and not self.Built then
                        self:Build(Entry, BuildOptions, Attempt + 1)
                        Registry:_Changed()
                    end
                end)

                return
            end

            Report("Element failed", Name .. " could not be built: " .. tostring(Result))
            return
        end

        local Fresh = {}

        for _, Child in ipairs(Container:GetChildren()) do
            if not Existing[Child] then
                table.insert(Fresh, Child)
            end
        end

        Window:_ThemeObjects(Fresh)
        Locale.Attach(Container)

        Container.DescendantAdded:Connect(function(Object)
            Window:_ThemeObjects({ Object })
        end)

        Container.Visible = true
        self.Built = true
        self.Instance = type(Result) == "table" and Result or {}

        local Calls = self.Calls
        self.Calls = {}

        for _, Call in ipairs(Calls) do
            local Method = self.Instance[Call.Name]

            if type(Method) == "function" then
                pcall(Method, self.Instance, table.unpack(Call.Args, 1, Call.Count))
            end
        end

        local Api = self.Instance
        local GetName = type(Api.Get) == "function" and "Get" or (type(Api.GetValue) == "function" and "GetValue" or nil)
        local SetName = type(Api.Set) == "function" and "Set" or (type(Api.SetValue) == "function" and "SetValue" or nil)

        if Savable and Window.Saves and GetName and SetName then
            local Used = Section.Used
            Used[self.Name] = (Used[self.Name] or 0) + 1

            local Flag = Section.Tab.Name .. "/" .. Section.Name .. "/" .. self.Name

            if Used[self.Name] > 1 then
                Flag = Flag .. " #" .. Used[self.Name]
            end

            self.Flag = Flag

            Window.Saves:Register(Flag, function()
                return Api[GetName](Api)
            end, function(Value, Silent)
                return Api[SetName](Api, Value, Silent)
            end)
        end

        Registry:_Changed()
    end

    function Core:Destroy()
        if self.Destroyed then
            return
        end

        self.Destroyed = true

        if self.Flag and Window.Saves then
            Window.Saves:Unregister(self.Flag)
        end

        local Api = self.Instance

        if type(Api) == "table" and type(Api.Destroy) == "function" then
            pcall(Api.Destroy, Api)
        end

        local Index = table.find(Section.Tab.Elements, self)

        if Index then
            table.remove(Section.Tab.Elements, Index)
        end

        Container:Destroy()
        Registry:_Changed()
    end

    table.insert(Section.Tab.Elements, Core)

    local Handle = setmetatable({ Element = Core }, {
        __index = function(_, Method)
            if Method == "Destroy" then
                return function()
                    Core:Destroy()
                end
            end

            if Core.Destroyed then
                return function() end
            end

            if Core.Built then
                local Value = Core.Instance[Method]

                if type(Value) == "function" then
                    return function(_, ...)
                        return Value(Core.Instance, ...)
                    end
                end

                return Value
            end

            return function(_, ...)
                Core.Calls[#Core.Calls + 1] = { Name = Method, Args = { ... }, Count = select("#", ...) }
            end
        end
    })

    local Entry = Registry.Registry[Key]

    if Entry then
        Core:Build(Entry, Options)
    else
        ApplyFrame(Key == "button")
        Registry:Enqueue(Key, Core, Options)
    end

    return Handle
end

function Windows:_ReplaceElement(Field, Section, Name, Options)
    local Old = self[Field]
    local Order = nil

    if Old then
        local Core = rawget(Old, "Element")

        if Core and Core.Container then
            Order = Core.Container.LayoutOrder
        end

        Old.Destroy()
    end

    local New = Section:CreateElement(Name, Options)
    local Core = rawget(New, "Element")

    if Order and Core and Core.Container then
        Core.Container.LayoutOrder = Order
    end

    self[Field] = New
    return New
end

function Windows:CreateSettingsSection(Name)
    local Section = {
        Name = tostring(Name or "Geral"),
        Panel = self,
        Tab = self.SettingsTab,
        Elements = {},
        Used = {},
        Count = 0
    }

    table.insert(self.SettingsSections, Section)

    Section.Frame = Util.Create("Frame", {
        Name = "Section",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = #self.SettingsSections
    }, self.SettingsPalette.List)
    Util.List(Section.Frame, 4)
    Section.Holder = Section.Frame

    local Heading = Util.Create("TextLabel", {
        Name = "Heading",
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = Section.Name,
        TextColor3 = Theme.Dim,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = 0
    }, Section.Frame)
    Util.Padding(Heading, 0, 0, 4, 4)
    Locale.Bind(Heading, "Text", Locale.Upper)

    Section.TitleLabel = Heading
    Section.NoSave = true
    self:_AttachSectionApi(Section)

    return Section
end

function Windows:_ThemeObjects(Roots)
    local Map = {}
    local Changed = false

    for _, Key in ipairs(ThemeKeys) do
        local From = Pack(DefaultTheme[Key])

        if From ~= Pack(Theme[Key]) then
            Map[From] = Theme[Key]
            Changed = true
        end
    end

    if not Changed then
        return
    end

    for _, Root in ipairs(Roots) do
        RemapObject(Root, Map)

        for _, Object in ipairs(Root:GetDescendants()) do
            RemapObject(Object, Map)
        end
    end
end

function Windows:ApplyTheme(Colors)
    if not self.Gui then
        return
    end

    local New = BuildPalette(Colors or DefaultTheme)
    local Map = {}
    local Changed = false

    for _, Key in ipairs(ThemeKeys) do
        local Code = Pack(Theme[Key])

        if Code ~= Pack(New[Key]) then
            Map[Code] = New[Key]
            Changed = true
        end
    end

    if Changed then
        for _, Object in ipairs(self.Gui:GetDescendants()) do
            RemapObject(Object, Map)
        end
    end

    for Key, Color in pairs(New) do
        Theme[Key] = Color
    end
end

function Windows:_SaveTheme(Name)
    if not self.Saves then
        return
    end

    self.Saves:SetSetting("Theme", Name or "Default")

    if Name then
        local Hex = {}

        for _, Key in ipairs(ThemeKeys) do
            Hex[Key] = Theme[Key]:ToHex()
        end

        self.Saves:SetSetting("ThemeColors", Hex)
    else
        self.Saves:SetSetting("ThemeColors", nil)
    end
end

function Windows:SetTheme(Name, Quiet)
    Name = tostring(Name or "Default")

    self.ThemeToken = self.ThemeToken + 1

    local Token = self.ThemeToken

    if string.lower(Name) == "default" then
        self.ThemeName = "Default"
        self:ApplyTheme(DefaultTheme)
        self:_SaveTheme(nil)
        return true
    end

    local Colors, Failure = Themes.Load(Name)

    if self.ThemeToken ~= Token or not self.Gui then
        return false
    end

    if not Colors then
        if not Quiet then
            Report("Theme failed", Name .. ": " .. tostring(Failure))
        end

        return false
    end

    self.ThemeName = Name
    self:ApplyTheme(Colors)
    self:_SaveTheme(Name)
    return true
end

function Windows:_ThemeDropdown()
    self:_ReplaceElement("ThemeDropdown", self.ThemeSection, "Dropdown", {
        title = "Theme",
        description = "Panel colors",
        values = self.ThemeValues,
        default = self.ThemeName,
        multi = false,
        disabled = false,
        callback = function(Value)
            if type(Value) ~= "string" or Value == self.ThemeName then
                return
            end

            task.spawn(function()
                if not self:SetTheme(Value) and self.Gui then
                    self:_ThemeDropdown()
                end
            end)
        end
    })
end

function Windows:_BuildThemeSettings()
    self.ThemeSection = self:CreateSettingsSection("Themes")
    self.ThemeValues = { "Default" }

    if self.ThemeName ~= "Default" then
        table.insert(self.ThemeValues, self.ThemeName)
    end

    self:_ThemeDropdown()

    task.spawn(function()
        local Names = Themes.Names()

        if not self.Gui then
            return
        end

        local List = { "Default" }

        for _, Name in ipairs(Names) do
            table.insert(List, Name)
        end

        if self.ThemeName ~= "Default" and not table.find(List, self.ThemeName) then
            table.insert(List, self.ThemeName)
        end

        self.ThemeValues = List
        self:_ThemeDropdown()

        if self.ThemeName ~= "Default" then
            self:SetTheme(self.ThemeName, true)
        end

        Themes.Prefetch(Names, function()
            return self.Gui ~= nil
        end)
    end)
end

function Windows:_BuildSaveSettings()
    self.SaveSection = self:CreateSettingsSection("Saves")

    local Enabled = self.Saves ~= nil and self.Saves.AutoEnabled

    self.SaveSection:CreateToggle({
        title = "Auto Save",
        description = "Saves every element and restores it when the panel restarts",
        default = Enabled,
        value = Enabled,
        callback = function(Value)
            if self.Saves then
                self.Saves:SetAutoSave(Value and true or false)
            end
        end
    })
end

function Windows:_BindAutoSave()
    task.spawn(function()
        while self.Gui and self.Saves do
            task.wait(Config.AutoSaveInterval)

            local Saves = self.Saves

            if Saves and Saves.AutoEnabled then
                Saves:Write()
            end
        end
    end)
end

function Windows:_AttachSectionApi(Section)
    local Window = self

    function Section:CreateElement(ElementName, Options)
        local Handle = Window:_CreateRegistered(Section, ElementName, Options)
        Window:RefreshSearch()
        return Handle
    end

    Section.AddElement = Section.CreateElement

    function Section:SetTitle(Text)
        if Section.TitleLabel then
            Section.TitleLabel.Text = tostring(Text)
        end
    end

    setmetatable(Section, {
        __index = function(_, Key)
            if type(Key) ~= "string" then
                return nil
            end

            local ElementName = string.match(Key, "^Create(%u%w*)$") or string.match(Key, "^Add(%u%w*)$")

            if not ElementName then
                return nil
            end

            return function(First, Options)
                if rawequal(First, Section) then
                    return Section:CreateElement(ElementName, Options)
                end

                return Section:CreateElement(ElementName, First)
            end
        end
    })
end

function Windows:_CreateTabSection(Tab, Name)
    local Section = {
        Name = Name,
        Panel = self,
        Tab = Tab,
        Elements = {},
        Used = {},
        Count = 0
    }

    Section.Frame = Util.Create("Frame", {
        Name = Name,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = #Tab.Sections + 1
    }, Tab.Scroll)
    Util.List(Section.Frame, 6)

    local Header = Util.Create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        LayoutOrder = 0
    }, Section.Frame)
    Util.Padding(Header, 0, 0, 2, 0)
    Util.List(Header, 6, {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center
    })

    Section.TitleLabel = Util.Create("TextLabel", {
        Name = "Title",
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = Name,
        TextColor3 = Theme.Active,
        TextSize = 12,
        Font = Enum.Font.SourceSansBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = 1
    }, Header)
    Locale.Bind(Section.TitleLabel, "Text", Locale.Upper)

    Section.Holder = Util.Create("Frame", {
        Name = "Holder",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 1
    }, Section.Frame)
    Util.List(Section.Holder, 6)

    self:_AttachSectionApi(Section)
    return Section
end

function Windows:_SetBreadcrumb(Items)
    if type(Items) ~= "table" then
        return
    end

    self.Crumbs = Items

    for _, Child in ipairs(self.Breadcrumb:GetChildren()) do
        if Child:IsA("GuiObject") then
            Child:Destroy()
        end
    end

    local Total = #Items

    for Index, Text in ipairs(Items) do
        local IsLast = Index == Total

        Util.Create("TextLabel", {
            Name = "Item" .. Index,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 0, 20),
            BackgroundTransparency = 1,
            Text = Locale.Translate(tostring(Text)),
            TextSize = 14,
            Font = IsLast and Enum.Font.SourceSansBold or Enum.Font.SourceSans,
            TextColor3 = IsLast and Theme.Active or Theme.Inactive,
            LayoutOrder = Index * 2 - 1
        }, self.Breadcrumb)

        if not IsLast then
            local Separator = Util.Icon(self.Breadcrumb, "chevron-right", 14, Theme.Dim)
            Separator.Name = "Sep" .. Index
            Separator.LayoutOrder = Index * 2
        end
    end
end

function Windows:_CreateSideSection(Name)
    self.SectionOrder = self.SectionOrder + 1

    local Section = { Name = Name, Tabs = {}, Open = true, Token = 0, Window = self }

    Section.Frame = Util.Create("Frame", {
        Name = Name,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = self.SectionOrder
    }, self.TabList)
    Util.List(Section.Frame, 2)

    local LabelButton = Util.Create("TextButton", {
        Name = "Label",
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = Name,
        TextColor3 = Theme.TabInactive,
        TextSize = 12,
        Font = Enum.Font.SourceSansBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = 0
    }, Section.Frame)
    Util.Padding(LabelButton, 0, 0, 10, 26)
    Locale.Bind(LabelButton, "Text", Locale.Upper)

    Section.Chevron = Util.Icon(LabelButton, "chevron-down", 14, Theme.TabInactive)
    Section.Chevron.AnchorPoint = Vector2.new(1, 0.5)
    Section.Chevron.Position = UDim2.new(1, 18, 0.5, 0)

    Section.Menu = Util.Create("Frame", {
        Name = "Menu",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        ClipsDescendants = true
    }, Section.Frame)
    Util.List(Section.Menu, 2)

    function Section:FullHeight()
        return math.max(#self.Tabs * (Config.TabHeight + 2) - 2, 0)
    end

    function Section:Animate()
        local Menu = self.Menu
        local Full = math.max(Menu.AbsoluteSize.Y, self:FullHeight())

        self.Token = self.Token + 1

        local Token = self.Token

        Menu.AutomaticSize = Enum.AutomaticSize.None

        if self.Open then
            Menu.Visible = true

            local Tween = Util.Tween(Menu, Config.TweenInfo, { Size = UDim2.new(1, 0, 0, self:FullHeight()) })

            Tween.Completed:Connect(function()
                if self.Token == Token and self.Open then
                    Menu.AutomaticSize = Enum.AutomaticSize.Y
                    Menu.Size = UDim2.new(1, 0, 0, 0)
                end
            end)
        else
            Menu.Size = UDim2.new(1, 0, 0, Full)

            local Tween = Util.Tween(Menu, Config.TweenInfo, { Size = UDim2.new(1, 0, 0, 0) })

            Tween.Completed:Connect(function()
                if self.Token == Token and not self.Open then
                    Menu.Visible = false
                end
            end)
        end
    end

    function Section:SetOpen(State)
        self.Open = State and true or false
        Util.Tween(self.Chevron, Config.TweenInfo, { Rotation = self.Open and 0 or -90 })
        self:Animate()
    end

    LabelButton.Activated:Connect(function()
        Section:SetOpen(not Section.Open)
    end)

    LabelButton.MouseEnter:Connect(function()
        if not IsTouch then
            Util.Tween(LabelButton, Config.TabTween, { TextColor3 = Theme.TabHover })
            Util.Tween(Section.Chevron, Config.TabTween, { ImageColor3 = Theme.TabHover })
        end
    end)

    LabelButton.MouseLeave:Connect(function()
        Util.Tween(LabelButton, Config.TabTween, { TextColor3 = Theme.TabInactive })
        Util.Tween(Section.Chevron, Config.TabTween, { ImageColor3 = Theme.TabInactive })
    end)

    return Section
end

function Windows:_CreateTabUI(Section, Tab)
    local Window = self

    local Button = Util.Create("TextButton", {
        Name = Tab.Name,
        Size = UDim2.new(1, 0, 0, Config.TabHeight),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = #Section.Tabs + 1
    }, Section.Menu)
    Util.Corner(Button, 6)

    local Scale = Util.Create("UIScale", { Scale = 1 }, Button)

    local Stroke = Util.Create("UIStroke", {
        Color = Theme.BorderHover,
        Thickness = 1,
        Transparency = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, Button)

    local Icon = Util.Icon(Button, Tab.IconName, 16, Theme.TabInactive)
    Icon.AnchorPoint = Vector2.new(0.5, 0.5)
    Icon.Position = UDim2.new(0, 18, 0.5, 0)

    local IconScale = Util.Create("UIScale", { Scale = 1 }, Icon)

    local Label = Util.Create("TextLabel", {
        Name = "Text",
        Position = UDim2.new(0, 36, 0, 0),
        Size = UDim2.new(1, -46, 1, 0),
        BackgroundTransparency = 1,
        Text = Tab.Name,
        TextColor3 = Theme.TabInactive,
        TextSize = 14,
        Font = Enum.Font.SourceSans,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, Button)
    Locale.Bind(Label, "Text")

    local Page = Util.Create("Frame", {
        Name = Tab.Name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false
    }, self.PageHolder)

    local Scroll = Util.Create("ScrollingFrame", {
        Name = "Scroll",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y
    }, Page)
    Util.Padding(Scroll, 4, 12, 12, 12)
    Util.List(Scroll, 14)
    Util.ScrollArea(Scroll)

    Tab.Button = Button
    Tab.Stroke = Stroke
    Tab.Icon = Icon
    Tab.Label = Label
    Tab.Scale = Scale
    Tab.IconScale = IconScale
    Tab.Page = Page
    Tab.Scroll = Scroll

    function Tab:Style()
        local Active = Window.ActiveTab == self
        local Color = Active and Theme.TabActive or Theme.TabInactive

        self.Label.Font = Active and Enum.Font.SourceSansSemibold or Enum.Font.SourceSans

        Util.Tween(self.Button, Config.TabTween, { BackgroundTransparency = Active and Config.TabFillTransparency or 1 })
        Util.Tween(self.Label, Config.TabTween, { TextColor3 = Color })
        Util.Tween(self.Icon, Config.TabTween, { ImageColor3 = Color })
        Util.Tween(self.Stroke, Config.TabTween, { Transparency = Active and 0.55 or 1 })
    end

    function Tab:SetIcon(Name)
        self.IconName = Name or self.IconName

        local Image = GetIcon(self.IconName)

        if Image ~= "" then
            self.Icon.Image = Image
        end
    end

    function Tab:Pop()
        self.IconScale.Scale = 0.65
        Util.Tween(self.IconScale, Config.TabPop, { Scale = 1 })
        self.Button.BackgroundTransparency = 0.05
    end

    function Tab:Select()
        self:Pop()
        Window:SelectTab(self)
        self:Style()
    end

    function Tab:CreateSection(SectionName)
        SectionName = tostring(SectionName or "Section")

        for _, Existing in ipairs(self.Sections) do
            if Existing.Name == SectionName then
                return Existing
            end
        end

        local NewSection = Window:_CreateTabSection(self, SectionName)
        table.insert(self.Sections, NewSection)
        return NewSection
    end

    Tab.AddSection = Tab.CreateSection

    local Pressed = false

    local function Release()
        if not Pressed then
            return
        end

        Pressed = false
        Util.Tween(Scale, Config.TabRelease, { Scale = 1 })
    end

    Button.InputBegan:Connect(function(Input)
        if Util.IsPress(Input) then
            Pressed = true
            Util.Tween(Scale, Config.TabPress, { Scale = 0.94 })
        end
    end)

    Button.InputEnded:Connect(function(Input)
        if Util.IsPress(Input) then
            Release()
        end
    end)

    table.insert(self.Connections, UserInputService.InputEnded:Connect(function(Input)
        if Util.IsPress(Input) then
            Release()
        end
    end))

    Button.Activated:Connect(function()
        Tab:Select()
    end)

    Button.MouseEnter:Connect(function()
        if IsTouch or Window.ActiveTab == Tab then
            return
        end

        Util.Tween(Button, Config.TabTween, { BackgroundTransparency = Config.TabHoverTransparency })
        Util.Tween(Label, Config.TabTween, { TextColor3 = Theme.TabHover })
        Util.Tween(Icon, Config.TabTween, { ImageColor3 = Theme.TabHover })
    end)

    Button.MouseLeave:Connect(function()
        Release()
        Tab:Style()
    end)
end

function Windows:AddTab(SectionName, TabName, IconName, OnSelect)
    local Window = self

    SectionName = tostring(SectionName or "Main")
    TabName = tostring(TabName)

    local Section = self.SideSectionsByName[SectionName]

    if not Section then
        Section = self:_CreateSideSection(SectionName)
        table.insert(self.SideSections, Section)
        self.SideSectionsByName[SectionName] = Section
    end

    for _, Existing in ipairs(Section.Tabs) do
        if Existing.Name == TabName then
            return Existing
        end
    end

    local Tab = {
        Name = TabName,
        IconName = IconName or "circle",
        Section = Section,
        Window = self,
        Sections = {},
        Elements = {},
        OnSelect = OnSelect,
        Scroll = nil
    }

    self:_CreateTabUI(Section, Tab)

    function Tab:AddElement(Name, Type, ElementOptions)
        ElementOptions = ElementOptions or {}

        local Element = {
            Name = tostring(Name),
            Type = tostring(Type or "Element"),
            Group = tostring(ElementOptions.Group or Section.Name),
            Description = tostring(ElementOptions.Description or ""),
            Container = ElementOptions.Container,
            Flash = ElementOptions.Flash,
            OnFocus = ElementOptions.OnFocus,
            Tab = Tab,
            Flag = nil,
            Built = true,
            Destroyed = false
        }

        if Window.Saves and type(ElementOptions.Get) == "function" and type(ElementOptions.Set) == "function" then
            Element.Flag = tostring(ElementOptions.Flag or (Tab.Name .. "/" .. Element.Group .. "/" .. Element.Name))
            Window.Saves:Register(Element.Flag, ElementOptions.Get, ElementOptions.Set)
        end

        function Element:Changed()
            if Element.Flag and Window.Saves then
                Window.Saves:Changed(Element.Flag)
            end
        end

        function Element:Destroy()
            Element.Destroyed = true

            if Element.Flag and Window.Saves then
                Window.Saves:Unregister(Element.Flag)
            end

            local Index = table.find(Tab.Elements, Element)

            if Index then
                table.remove(Tab.Elements, Index)
            end
        end

        table.insert(Tab.Elements, Element)
        return Element
    end

    table.insert(Section.Tabs, Tab)
    table.insert(self.Tabs, Tab)

    if Section.Open then
        Section.Menu.Visible = true
    end

    if not self.ActiveTab then
        self:SelectTab(Tab)
    end

    self:RefreshSearch()
    return Tab
end

function Windows:CreateTab(Options)
    Options = type(Options) == "table" and Options or { tab = Options }

    local TabName = tostring(Options.tab or Options.Tab or Options.Name or Options.Title or "Tab")
    local SectionName = tostring(Options.section or Options.Section or "Main")

    return self:AddTab(SectionName, TabName, Options.icon or Options.Icon, Options.OnSelect)
end

function Windows:GetTab(Key)
    if type(Key) == "number" then
        return self.Tabs[Key]
    end

    for _, Tab in ipairs(self.Tabs) do
        if Tab.Name == Key then
            return Tab
        end
    end

    return nil
end

function Windows:SelectTab(Tab)
    if type(Tab) ~= "table" then
        Tab = self:GetTab(Tab)
    end

    if type(Tab) ~= "table" or self.ActiveTab == Tab then
        return
    end

    local Previous = self.ActiveTab

    if Previous and Previous.Page then
        Previous.Page.Visible = false
    end

    self.ActiveTab = Tab

    if Tab.Page then
        Tab.Page.Visible = true
    end

    if Previous and Previous.Style then
        Previous:Style()
    end

    if Tab.Style then
        Tab:Style()
    end

    self:_SetBreadcrumb({ Tab.Section.Name, Tab.Name })

    if type(Tab.OnSelect) == "function" then
        pcall(Tab.OnSelect, Tab)
    end
end

function Windows:_BuildToggle()
    self.ToggleGui = Util.Create("ScreenGui", {
        Name = "EcohubToggle",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 99,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, self.Gui.Parent)

    self.ToggleButton = Util.Create("TextButton", {
        Name = "ToggleButton",
        Size = UDim2.fromOffset(48, 48),
        Position = UDim2.new(0, 20, 0.5, -24),
        BackgroundColor3 = DefaultTheme.Background,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ClipsDescendants = true
    }, self.ToggleGui)
    self.ToggleButton:SetAttribute("NoTheme", true)
    Util.Corner(self.ToggleButton, 10)

    local Stroke = Util.Create("UIStroke", {
        Color = DefaultTheme.Border,
        Thickness = 1.5,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, self.ToggleButton)
    Stroke:SetAttribute("NoTheme", true)

    local Texture = Util.Create("ImageLabel", {
        Name = "Texture",
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = Config.ToggleImage,
        ImageTransparency = 0.3,
        ScaleType = Enum.ScaleType.Crop,
        ZIndex = 1
    }, self.ToggleButton)
    Texture:SetAttribute("NoTheme", true)
    Util.Corner(Texture, 10)
end

function Windows:_BindToggleDrag()
    local Pressed = false
    local Moved = false
    local DragStart = nil
    local StartPosition = nil

    table.insert(self.Connections, self.ToggleButton.InputBegan:Connect(function(Input)
        if not Util.IsPress(Input) then
            return
        end

        Pressed = true
        Moved = false
        DragStart = Input.Position
        StartPosition = self.ToggleButton.Position
    end))

    table.insert(self.Connections, UserInputService.InputChanged:Connect(function(Input)
        if not Pressed or not Util.IsMove(Input) then
            return
        end

        local Delta = Input.Position - DragStart

        if Delta.Magnitude > 6 then
            Moved = true
        end

        if Moved then
            self.ToggleButton.Position = UDim2.new(
                StartPosition.X.Scale,
                StartPosition.X.Offset + Delta.X,
                StartPosition.Y.Scale,
                StartPosition.Y.Offset + Delta.Y
            )
        end
    end))

    table.insert(self.Connections, UserInputService.InputEnded:Connect(function(Input)
        if not Pressed or not Util.IsPress(Input) then
            return
        end

        Pressed = false

        if not Moved then
            self:Toggle()
        else
            self:_SavePosition("TogglePosition", self.ToggleButton.Position)
        end

        Moved = false
    end))
end

function Windows:_BindDrag()
    local Dragging = false
    local DragStart = nil
    local StartPosition = nil

    local function Begin(Input)
        if Util.IsPress(Input) then
            Dragging = true
            DragStart = Input.Position
            StartPosition = self.Window.Position
        end
    end

    table.insert(self.Connections, self.Dashboard.InputBegan:Connect(Begin))
    table.insert(self.Connections, self.Header.InputBegan:Connect(Begin))

    table.insert(self.Connections, UserInputService.InputChanged:Connect(function(Input)
        if not Dragging or not Util.IsMove(Input) then
            return
        end

        local Delta = Input.Position - DragStart

        self.Window.Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + Delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + Delta.Y
        )
    end))

    table.insert(self.Connections, UserInputService.InputEnded:Connect(function(Input)
        if Util.IsPress(Input) then
            if Dragging and self.Window.Position ~= StartPosition then
                self:_SavePosition("WindowPosition", self.Window.Position)
            end

            Dragging = false
        end
    end))
end

function Windows:_BindToggle()
    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(Input, Processed)
        if Processed then
            return
        end

        if Input.KeyCode == self.ToggleKey then
            self:Toggle()
        end
    end))
end

function Windows:SetVisible(State)
    State = State and true or false

    if not State then
        self:CloseSearch()
        self:CloseSettings()
    end

    self.Visible = State
    self.Window.Visible = State
end

function Windows:Toggle()
    self:SetVisible(not self.Visible)
end

function Windows:SetMinimized(State)
    self:SetVisible(not State)
end

function Windows:IsMinimized()
    return not self.Visible
end

function Windows:SetToggleKey(KeyCode)
    if typeof(KeyCode) == "EnumItem" then
        self.ToggleKey = KeyCode

        if self.Saves then
            self.Saves:SetSetting("ToggleKey", KeyCode.Name)
        end
    end
end

Windows.SetMinimizeKey = Windows.SetToggleKey

function Windows:Configure(Options, KeepLayout)
    Options = type(Options) == "table" and Options or {}

    if Options.Title ~= nil then
        self:SetTitle(tostring(Options.Title))
    end

    local SubTitle = Options.SubTitle

    if SubTitle == nil then
        SubTitle = Options.Subtitle
    end

    if SubTitle ~= nil then
        self:SetSubtitle(tostring(SubTitle))
    end

    if not KeepLayout and typeof(Options.Size) == "UDim2" then
        self.Window.Size = ResolveSize(Options.Size)
    end

    if typeof(Options.MinimizeKey) == "EnumItem" then
        self.ToggleKey = Options.MinimizeKey
        self.KeyLocked = true
    end
end

function Windows:SetTitle(Text)
    self.Title = Text
    self.TitleLabel.Text = Text
end

function Windows:SetSubtitle(Text)
    self.Subtitle = Text
    self.SubtitleLabel.Text = Text
end

Windows.SetSubTitle = Windows.SetSubtitle

function Windows:Notify(Options)
    if type(Options) ~= "table" then
        Options = { Description = tostring(Options) }
    end

    Notifications.Send(Options)
end

function Windows:_BindLocale()
    local Window = self
    local Link = {
        Connect = function(_, Signal, Callback)
            local Connection = Signal:Connect(Callback)
            table.insert(Window.Connections, Connection)
            return Connection
        end
    }

    Locale.Watch(Link)
    Roblox.Load()

    local Unsubscribe = Locale.OnChange(function()
        Window:_Relocalize()
    end)

    table.insert(self.Connections, { Disconnect = Unsubscribe })
end

function Windows:_Relocalize()
    if self.Destroyed or not self.Gui then
        return
    end

    self.SearchButton.Text = Locale.Translate("Search...")
    self.PaletteInput.PlaceholderText = Locale.Translate("Search tabs and elements...")

    if self.Crumbs then
        self:_SetBreadcrumb(self.Crumbs)
    end

    self:RefreshSearch()
end

function Windows:SetLanguage(Lang)
    Locale.SetLang(Lang)
end

function Windows:GetLanguage()
    return Locale.GetLang()
end

function Windows:AddTranslations(Languages)
    return Locale.AddMany(Languages)
end

function Windows:Translate(Text)
    return Locale.Translate(tostring(Text))
end

function Windows:TranslateGame(State)
    if self.GameConnection then
        self.GameConnection:Disconnect()
        self.GameConnection = nil
    end

    if not State then
        return
    end

    local PlayerGui = GetPlayerGui()

    if not PlayerGui then
        return
    end

    local function Attach(Gui)
        if Gui:IsA("ScreenGui") and not string.find(string.lower(Gui.Name), "^ecohub") then
            Locale.Attach(Gui)
        end
    end

    for _, Gui in ipairs(PlayerGui:GetChildren()) do
        Attach(Gui)
    end

    self.GameConnection = PlayerGui.ChildAdded:Connect(Attach)
    table.insert(self.Connections, self.GameConnection)
end

function Windows:LoadFeature(Name, Options)
    return self.Features:Load(Name, Options)
end

function Windows:LoadFeatures(List, Options)
    return self.Features:LoadMany(List, Options)
end

function Windows:LoadAllFeatures(Options)
    return self.Features:LoadAll(Options)
end

function Windows:PreloadFeatures(List)
    return self.Features:Preload(List)
end

function Windows:UnloadFeature(Name)
    return self.Features:Unload(Name)
end

function Windows:UnloadAllFeatures()
    return self.Features:UnloadAll()
end

function Windows:GetLoadedFeatures()
    return self.Features:GetLoaded()
end

function Windows:IsFeatureLoaded(Name)
    return self.Features:IsLoaded(Name)
end

function Windows:ListFeatures()
    return self.Features:List()
end

function Windows:RefreshFeatures()
    return self.Features:Refresh()
end

function Windows:SetFeaturesSource(Url)
    return self.Features:SetSource(Url)
end

function Windows:SetElementsSource(Url)
    local Parsed = Source.Parse(Url)

    if not Parsed then
        Report("Invalid source", "elements source: " .. tostring(Url))
        return false
    end

    Github.ElementsPath = Parsed.Path
    Github.ElementsApi = "https://api.github.com/repos/" .. Parsed.Repo .. "/contents/" .. Parsed.Path .. "?ref=" .. Parsed.Branch
    Github.ElementsRaw = Parsed.Raw
    Github.ElementsCdn = Parsed.Cdn
    Github.ElementsList = Parsed.List

    return true
end

function Windows:Destroy()
    if self.Destroyed then
        return
    end

    self.Destroyed = true

    if self.Features then
        self.Features:UnloadAll()
    end

    for _, Connection in ipairs(self.Connections) do
        Connection:Disconnect()
    end

    self.Connections = {}

    if self.Saves then
        local Saves = self.Saves

        self.Saves = nil
        Saves:Flush()
        Saves:Destroy()

        if rawequal(env.EcoHubSaves, Saves) then
            env.EcoHubSaves = nil
        end
    end

    if self.Elements then
        self.Elements.Destroyed = true

        if rawequal(env.EcoHubElements, self.Elements) then
            env.EcoHubElements = nil
        end

        if rawequal(env.EcoHubPanel, self) then
            env.EcoHubPanel = nil
        end
    end

    if self.SearchChanged then
        self.SearchChanged:Destroy()
        self.SearchChanged = nil
    end

    if self.Gui then
        local Gui = self.Gui
        self.Gui = nil
        Gui:Destroy()
    end

    if self.ToggleGui then
        local ToggleGui = self.ToggleGui
        self.ToggleGui = nil
        ToggleGui:Destroy()
    end

    env.EcoHubDestroy = nil

    if Librarys.Window == self then
        Librarys.Window = nil
        Librarys.Windows = nil
        Librarys.Elements = nil
        Librarys.FeatureConfig = nil
    end
end

-- // Librarys

function Librarys:CreateWindow(Options)
    if Options == nil and type(self) == "table" and not rawequal(self, Librarys) then
        Options = self
    end

    local Existing = Librarys.Window

    if Existing and not Existing.Destroyed then
        Existing:Configure(Options, true)
        return Existing
    end

    local Window = Windows.new(Options)

    if Window then
        Librarys.Window = Window

        env.EcoHubDestroy = function()
            Window:Destroy()
        end

        Librarys.Windows = Window
        Librarys.Elements = Window.Elements
        Librarys.FeatureConfig = Window.FeatureConfig

        Window:LoadElements()
        Window.Features:Warm()
    end

    return Window
end

local ForwardMethods = {
    "LoadFeature",
    "LoadFeatures",
    "LoadAllFeatures",
    "PreloadFeatures",
    "UnloadFeature",
    "UnloadAllFeatures",
    "GetLoadedFeatures",
    "IsFeatureLoaded",
    "ListFeatures",
    "RefreshFeatures",
    "SetFeaturesSource",
    "SetElementsSource",
    "ListElements",
    "LoadElements",
    "CreateTab",
    "GetTab",
    "SelectTab",
    "TranslateGame"
}

for _, Method in ipairs(ForwardMethods) do
    Librarys[Method] = function(_, ...)
        local Window = Librarys.Window

        if not Window or Window.Destroyed then
            Report("Window missing", Method .. " needs a window, call CreateWindow first")
            return nil
        end

        return Window[Method](Window, ...)
    end
end

Librarys.Locale = Locale

function Librarys.SetLanguage(First, Second)
    Locale.SetLang(rawequal(First, Librarys) and Second or First)
end

function Librarys.GetLanguage()
    return Locale.GetLang()
end

function Librarys.AddTranslations(First, Second)
    return Locale.AddMany(rawequal(First, Librarys) and Second or First)
end

function Librarys.Translate(First, Second)
    local Text = rawequal(First, Librarys) and Second or First
    return Locale.Translate(tostring(Text))
end

-- // Init
local function ReusePrevious()
    local Previous = env.EcoHubLibrary

    if type(Previous) ~= "table" then
        return nil
    end

    local Old = rawget(Previous, "Window")

    if type(Old) ~= "table" or Old.Destroyed then
        return nil
    end

    local Loader = Old.Features

    if type(Loader) ~= "table" or type(Loader.Busy) ~= "function" then
        return nil
    end

    local Limit = type(Old.FeatureConfig) == "table" and Old.FeatureConfig.ReloadGuard or 60
    local Busy = Loader:Busy(Limit)

    if Busy then
        warn("[Ecohub] library reload ignored while feature " .. tostring(Busy) .. " is loading")
        return Previous
    end

    return nil
end

local function RemovePrevious()
    local Previous = env.EcoHubLibrary

    if type(env.EcoHubDestroy) == "function" then
        pcall(env.EcoHubDestroy)
    end

    local Panel = env.EcoHubPanel

    if type(Panel) == "table" and not Panel.Destroyed and type(Panel.Destroy) == "function" then
        pcall(Panel.Destroy, Panel)
    end

    if type(Previous) == "table" then
        local Old = rawget(Previous, "Window")

        if type(Old) == "table" and not Old.Destroyed and type(Old.Destroy) == "function" then
            pcall(Old.Destroy, Old)
        end
    end

    local PlayerGui = GetPlayerGui()

    if PlayerGui then
        for _, Name in ipairs({ "Ecohub", "EcohubToggle" }) do
            for _, Child in ipairs(PlayerGui:GetChildren()) do
                if Child.Name == Name then
                    pcall(Child.Destroy, Child)
                end
            end
        end
    end

    env.EcoHubDestroy = nil
    env.EcoHubPanel = nil
    env.EcoHubElements = nil
    env.EcoHubLibrary = nil
end

local Reused = ReusePrevious()

if Reused then
    return Reused
end

RemovePrevious()

env.EcoHubLibrary = Librarys
env.Librarys = Librarys

return Librarys