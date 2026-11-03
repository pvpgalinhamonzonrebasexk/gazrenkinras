-- bytecode Versao v1

local NOTIF_URL = "https://raw.githubusercontent.com/pvpgalinhamonzonrebasexk/gazrenkinras/refs/heads/main/Templates/Notification.luau"

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local REMOTE_CLASSES = {
    "RemoteEvent",
    "RemoteFunction",
    "UnreliableRemoteEvent",
    "BindableEvent",
    "BindableFunction",
}

local SCRIPT_CLASSES = {
    LocalScript = true,
    Script = true,
    ModuleScript = true,
}

local IGNORED = {
    CoreGui = true,
    CorePackages = true,
    RobloxGui = true,
    RobloxPluginGuiService = true,
    PluginGuiService = true,
    RobloxReplicatedStorage = true,
    VirtualUser = true,
    VirtualInputManager = true,
    PlayerModule = true,
    RbxCharacterSounds = true,
    PlayerScriptsLoader = true,
    ChatScript = true,
    BubbleChat = true,
    ChatServiceRunner = true,
    ClientChatModules = true,
    DefaultChatSystemChatEvents = true,
}

local EXECUTOR_FUNCTIONS = {
    "decompile",
    "getscripts",
    "getloadedmodules",
    "getrunningscripts",
    "getnilinstances",
    "identifyexecutor",
    "writefile",
    "isfolder",
    "makefolder",
}

local EXTRA_SOURCES = {
    "getnilinstances",
    "getloadedmodules",
    "getrunningscripts",
    "getscripts",
}

local environment = {}

do
    local ok, env = pcall(getgenv)
    if ok and type(env) == "table" then
        environment = env
    end
end

local function read(container, key)
    local ok, value = pcall(function()
        return container[key]
    end)
    if ok then
        return value
    end
    return nil
end

local function resolve(name)
    for _, source in ipairs({ environment, _G, debug }) do
        local value = read(source, name)
        if type(value) == "function" then
            return value
        end
    end
    return nil
end

local api = {}

for _, name in ipairs(EXECUTOR_FUNCTIONS) do
    api[name] = resolve(name)
end

local lastYield = os.clock()

local function breathe()
    if os.clock() - lastYield > 0.01 then
        task.wait()
        lastYield = os.clock()
    end
end

local notifier

do
    local ok, lib = pcall(function()
        return loadstring(game:HttpGet(NOTIF_URL))()
    end)
    if ok and type(lib) == "table" and type(read(lib, "Notify")) == "function" then
        notifier = lib
        local settings = {
            SetName = "bytecore",
            SetMaxVisible = 4,
            SetGroup = false,
            SetClickToClose = true,
        }
        for method, value in pairs(settings) do
            local setter = read(lib, method)
            if type(setter) == "function" then
                pcall(setter, value)
            end
        end
    end
end

local NO_HANDLE = {
    Update = function() end,
    Close = function() end,
    IsClosed = function()
        return true
    end,
}

local function show(options)
    if notifier then
        local ok, handle = pcall(notifier.Notify, options)
        if ok and type(handle) == "table" then
            return handle
        end
    end
    print("[bytecore] " .. tostring(options.Title) .. " | " .. tostring(options.Description))
    return NO_HANDLE
end

local function refresh(handle, options)
    local update = read(handle, "Update")
    if type(update) == "function" then
        pcall(update, options)
    end
end

local function status(handle, title, description, kind, duration)
    refresh(handle, {
        Title = title,
        Description = description,
        Duration = duration or 0,
        Type = kind or "Info",
    })
    if not notifier then
        print("[bytecore] " .. title .. " | " .. description)
    end
end

local lastProgress = 0

local function progress(handle, title, description)
    local now = os.clock()
    if now - lastProgress < 0.3 then
        return
    end
    lastProgress = now
    refresh(handle, {
        Title = title,
        Description = description,
        Duration = 0,
        Type = "Info",
    })
end

local ACCENTS = {}

do
    local from = "áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ"
    local to = "aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN"
    local index = 1
    for character in from:gmatch("[\194-\244][\128-\191]*") do
        ACCENTS[character] = to:sub(index, index)
        index = index + 1
    end
end

local function sanitize(value)
    value = tostring(value):gsub("[\194-\244][\128-\191]*", function(character)
        return ACCENTS[character] or "_"
    end)
    value = value:gsub("[^%w%-_%. ]", "_")
    value = value:sub(1, 80)
    value = value:gsub("[%s%.]+$", "")
    value = value:gsub("^[%s%.]+", "")
    return value
end

local function safe_name(value)
    local name = sanitize(value)
    if name == "" then
        return "_"
    end
    return name
end

local function first_line(value)
    return tostring(value):match("^[^\n]*")
end

local function full_name(instance)
    local ok, path = pcall(instance.GetFullName, instance)
    if not ok then
        path = tostring(instance.Name)
    end
    if instance.Parent == nil and instance ~= game then
        path = "[nil] " .. path
    end
    return path
end

local function path_of(instance)
    local parts = {}
    local current = instance
    while current and current ~= game do
        table.insert(parts, 1, safe_name(current.Name))
        current = current.Parent
    end
    if current == nil then
        table.insert(parts, 1, "NilInstances")
    end
    return table.concat(parts, "/")
end

local function is_ignored(instance)
    local current = instance
    while current and current ~= game do
        if IGNORED[current.Name] then
            return true
        end
        current = current.Parent
    end
    return false
end

local folders = {}

local function ensure_parents(path)
    local parts = {}
    for part in path:gmatch("[^/]+") do
        parts[#parts + 1] = part
    end
    local current = ""
    for index = 1, #parts - 1 do
        if current == "" then
            current = parts[index]
        else
            current = current .. "/" .. parts[index]
        end
        if not folders[current] then
            local okCheck, exists = pcall(api.isfolder, current)
            if not (okCheck and exists) then
                if not pcall(api.makefolder, current) then
                    return false
                end
            end
            folders[current] = true
        end
    end
    return true
end

local function save(path, content)
    return ensure_parents(path) and pcall(api.writefile, path, content)
end

local function load_place()
    local placeId = game.PlaceId
    local gameName = "game"
    local okInfo, info = pcall(MarketplaceService.GetProductInfoAsync, MarketplaceService, placeId)
    if not okInfo or type(info) ~= "table" then
        info = nil
    end
    if info and info.Name then
        local name = sanitize(info.Name):gsub("%s+", " ")
        name = name:sub(1, 50):gsub("^%s+", ""):gsub("%s+$", "")
        if name ~= "" and not name:match("^[%s_]*$") then
            gameName = name
        end
    end
    return placeId, gameName, info
end

local function build_game_info(info, placeId, gameName)
    local lines = {}

    local function add(key, getter)
        local ok, value = pcall(getter)
        if ok and value ~= nil and value ~= "" then
            lines[#lines + 1] = key .. ": " .. tostring(value)
        end
    end

    add("Nome", function()
        return gameName
    end)
    add("PlaceId", function()
        return placeId
    end)
    add("GameId", function()
        return game.GameId
    end)
    add("JobId", function()
        return game.JobId
    end)
    add("PlaceVersion", function()
        return game.PlaceVersion
    end)
    add("Executor", function()
        local name, version = api.identifyexecutor()
        return tostring(name) .. " " .. tostring(version or "")
    end)
    if info then
        add("Criado", function()
            return info.Created
        end)
        add("Atualizado", function()
            return info.Updated
        end)
        add("Criador", function()
            local creator = info.Creator
            return tostring(creator.Name) .. " | " .. tostring(creator.CreatorType) .. " | " .. tostring(creator.CreatorTargetId or creator.Id)
        end)
    end
    add("Jogadores", function()
        return #Players:GetPlayers() .. "/" .. Players.MaxPlayers
    end)
    add("LocalPlayer", function()
        local player = Players.LocalPlayer
        return player.Name .. " | " .. player.DisplayName .. " | " .. player.UserId
    end)
    return table.concat(lines, "\n")
end

local function valid_source(source)
    if type(source) ~= "string" or #source < 16 then
        return false
    end
    local head = source:sub(1, 200):lower()
    if head:find("decompilation failed", 1, true) or head:find("^decompile error") or head:find("^error:") then
        return false
    end
    if head:find("unsupported", 1, true) and not head:find("local", 1, true) then
        return false
    end
    return not source:find("^%s*$")
end

local function collect(handle)
    local seen = {}
    local remotes = {}
    local scripts = {}
    local checked = 0

    for _, class in ipairs(REMOTE_CLASSES) do
        remotes[class] = {}
    end

    local function consider(instance)
        if seen[instance] then
            return
        end
        local class = instance.ClassName
        local bucket = remotes[class]
        if not bucket and not SCRIPT_CLASSES[class] then
            return
        end
        seen[instance] = true
        if is_ignored(instance) then
            return
        end
        if bucket then
            bucket[#bucket + 1] = full_name(instance)
        else
            scripts[#scripts + 1] = instance
        end
    end

    local function sweep(list)
        for _, instance in ipairs(list) do
            pcall(consider, instance)
            checked = checked + 1
            if checked % 1500 == 0 then
                progress(handle, "bytecore | Coletando", checked .. " verificados | Scripts: " .. #scripts)
                breathe()
            end
        end
    end

    local ok, descendants = pcall(game.GetDescendants, game)
    if ok and type(descendants) == "table" then
        sweep(descendants)
    end

    for _, name in ipairs(EXTRA_SOURCES) do
        local getter = api[name]
        if getter then
            local okList, list = pcall(getter)
            if okList and type(list) == "table" then
                sweep(list)
            end
        end
    end

    return remotes, scripts
end

local placeId, gameName, productInfo = load_place()
local ROOT = gameName .. "_" .. tostring(placeId)

local resuming = false

do
    local ok, exists = pcall(api.isfolder, ROOT)
    resuming = ok and exists == true
end

local main = show({
    Id = "bytecore",
    Title = "bytecore",
    Description = (resuming and "Continuando | " or "Iniciando | ") .. gameName .. " | " .. placeId,
    Duration = 0,
    Type = "Info",
})

if not api.writefile or not api.makefolder then
    status(main, "bytecore | Erro", "executor sem writefile/makefolder", "Error", 8)
    return
end

local errors = {}

local function traceback(message)
    return tostring(message) .. "\n" .. debug.traceback()
end

local function fail(where, err)
    errors[#errors + 1] = "[" .. where .. "] " .. tostring(err)
    print("[bytecore] erro em " .. where .. ": " .. first_line(err))
end

local function guarded(where, fn, ...)
    local ok, err = xpcall(fn, traceback, ...)
    if not ok then
        fail(where, err)
    end
    return ok
end

local function stage(name, fn)
    local ok, err = xpcall(fn, traceback)
    if not ok then
        fail(name, err)
        show({
            Title = "bytecore | Erro",
            Description = name .. ": " .. first_line(err),
            Duration = 6,
            Type = "Error",
        })
    end
end

local remotes = {}
local scriptInstances = {}
local scriptList = {}
local scriptPaths = {}
local remoteTotal = 0
local stats = { code = 0, empty = 0, failed = 0, skipped = 0 }

local function dump_script(instance)
    local class = instance.ClassName
    local fullName = full_name(instance)
    local basePath = path_of(instance)
    local result = "vazio"

    if api.decompile then
        local ok, source = pcall(api.decompile, instance)
        if ok and valid_source(source) then
            local count = (scriptPaths[basePath] or 0) + 1
            scriptPaths[basePath] = count
            local target = count > 1 and basePath .. "_" .. count or basePath
            if save(ROOT .. "/Scripts/" .. target .. ".lua", source) then
                result = "codigo"
                stats.code = stats.code + 1
            else
                result = "falha"
                stats.failed = stats.failed + 1
            end
        end
    end

    if result == "vazio" then
        stats.empty = stats.empty + 1
    end
    scriptList[#scriptList + 1] = class .. " | " .. fullName .. " | " .. result
end

stage("info", function()
    status(main, "bytecore | Info", gameName .. " | " .. placeId)
    save(ROOT .. "/Info/game.lua", build_game_info(productInfo, placeId, gameName))
end)

stage("coleta", function()
    status(main, "bytecore | Coletando", "varrendo o jogo")
    remotes, scriptInstances = collect(main)
end)

stage("remotes", function()
    for _, class in ipairs(REMOTE_CLASSES) do
        local paths = remotes[class]
        if paths and #paths > 0 then
            table.sort(paths)
            remoteTotal = remoteTotal + #paths
            save(ROOT .. "/Remotes/" .. class .. ".lua", class .. " (" .. #paths .. ")\n  " .. table.concat(paths, "\n  "))
        end
    end
end)

stage("scripts", function()
    local total = #scriptInstances
    status(main, "bytecore | Scripts", "0/" .. total .. " | Remotes: " .. remoteTotal)
    if not api.decompile then
        show({
            Title = "bytecore | Aviso",
            Description = "decompile indisponivel no executor",
            Duration = 6,
            Type = "Info",
        })
    end
    for index, instance in ipairs(scriptInstances) do
        if not guarded("script " .. index, dump_script, instance) then
            stats.skipped = stats.skipped + 1
        end
        progress(main, "bytecore | Scripts", index .. "/" .. total .. " | Codigo: " .. stats.code)
        breathe()
    end
end)

stage("relatorio", function()
    table.sort(scriptList)
    local lines = {
        "Jogo: " .. gameName,
        "PlaceId: " .. tostring(placeId),
        "Remotes: " .. remoteTotal,
        "Scripts listados: " .. #scriptList,
        "Codigo: " .. stats.code,
        "Vazios: " .. stats.empty,
        "Falhas: " .. stats.failed,
        "Pulados: " .. stats.skipped,
        "Erros: " .. #errors,
        "",
    }
    for _, line in ipairs(scriptList) do
        lines[#lines + 1] = line
    end
    save(ROOT .. "/Info/scripts.lua", table.concat(lines, "\n"))
    if #errors > 0 then
        save(ROOT .. "/Info/errors.lua", table.concat(errors, "\n"))
    end
end)

local summary = "Remotes: " .. remoteTotal .. " | Codigo: " .. stats.code
if #errors > 0 then
    summary = summary .. " | Erros: " .. #errors
end

status(main, "bytecore | Finalizado", summary, "Success", 8)