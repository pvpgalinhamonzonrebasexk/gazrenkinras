--bytecode
local NOTIF_URL = "https://raw.githubusercontent.com/pvpgalinhamonzonrebasexk/gazrenkinras/refs/heads/main/Templates/Notification.luau"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local genv = {}

do
    local ok, env = pcall(getgenv)
    if ok and type(env) == "table" then
        genv = env
    end
end

local function safe_index(container, key)
    local ok, value = pcall(function()
        return container[key]
    end)
    if ok then
        return value
    end
    return nil
end

local function global(name)
    local value = safe_index(genv, name)
    if value == nil then
        value = safe_index(_G, name)
    end
    return value
end

local function executor_function(name)
    local value = global(name)
    if type(value) == "function" then
        return value
    end
    value = safe_index(debug, name)
    if type(value) == "function" then
        return value
    end
    return nil
end

local function try(fn, ...)
    if type(fn) ~= "function" then
        return false, nil
    end
    return pcall(fn, ...)
end

local decompile_fn = executor_function("decompile")
local getscripts_fn = executor_function("getscripts")
local getloadedmodules_fn = executor_function("getloadedmodules")
local getrunningscripts_fn = executor_function("getrunningscripts")
local getnilinstances_fn = executor_function("getnilinstances")
local getinstances_fn = executor_function("getinstances")
local identifyexecutor_fn = executor_function("identifyexecutor")
local writefile_fn = executor_function("writefile")
local readfile_fn = executor_function("readfile")
local isfile_fn = executor_function("isfile")
local isfolder_fn = executor_function("isfolder")
local makefolder_fn = executor_function("makefolder")

local Notifications

do
    local ok, lib = pcall(function()
        return loadstring(game:HttpGet(NOTIF_URL))()
    end)
    if ok and type(lib) == "table" and type(safe_index(lib, "Notify")) == "function" then
        Notifications = lib
        try(safe_index(lib, "SetName"), "bytecore")
        try(safe_index(lib, "SetMaxVisible"), 4)
        try(safe_index(lib, "SetGroup"), false)
        try(safe_index(lib, "SetClickToClose"), true)
    end
end

local DUMMY = {
    Update = function()
    end,
    Close = function()
    end,
    IsClosed = function()
        return true
    end,
}

local function notify(options)
    if Notifications then
        local ok, handle = pcall(Notifications.Notify, options)
        if ok and type(handle) == "table" then
            return handle
        end
        if ok then
            return DUMMY
        end
    end
    print("[bytecore] " .. tostring(options.Title) .. " | " .. tostring(options.Description))
    return DUMMY
end

local function update(handle, options, quiet)
    try(safe_index(handle, "Update"), options)
    if not Notifications and not quiet then
        print("[bytecore] " .. tostring(options.Title) .. " | " .. tostring(options.Description))
    end
end

local lastProgress = 0

local function progress(handle, title, description, force)
    local now = os.clock()
    if not force and now - lastProgress < 0.3 then
        return
    end
    lastProgress = now
    update(handle, {
        Title = title,
        Description = description,
        Duration = 0,
        Type = "Info",
    }, true)
end

local ACCENT_PAIRS = {
    {"谩", "a"}, {"脿", "a"}, {"芒", "a"}, {"茫", "a"}, {"盲", "a"},
    {"茅", "e"}, {"猫", "e"}, {"锚", "e"}, {"毛", "e"},
    {"铆", "i"}, {"矛", "i"}, {"卯", "i"}, {"茂", "i"},
    {"贸", "o"}, {"貌", "o"}, {"么", "o"}, {"玫", "o"}, {"枚", "o"},
    {"煤", "u"}, {"霉", "u"}, {"没", "u"}, {"眉", "u"},
    {"莽", "c"}, {"帽", "n"},
    {"脕", "A"}, {"脌", "A"}, {"脗", "A"}, {"脙", "A"}, {"脛", "A"},
    {"脡", "E"}, {"脠", "E"}, {"脢", "E"}, {"脣", "E"},
    {"脥", "I"}, {"脤", "I"}, {"脦", "I"}, {"脧", "I"},
    {"脫", "O"}, {"脪", "O"}, {"脭", "O"}, {"脮", "O"}, {"脰", "O"},
    {"脷", "U"}, {"脵", "U"}, {"脹", "U"}, {"脺", "U"},
    {"脟", "C"}, {"脩", "N"},
}

local ACCENT_LOOKUP = {}

for _, pair in ipairs(ACCENT_PAIRS) do
    ACCENT_LOOKUP[pair[1]] = pair[2]
end

local function remove_accents(value)
    local result = value:gsub("[\194-\244][\128-\191]*", function(character)
        return ACCENT_LOOKUP[character]
    end)
    return result
end

local function sanitize(value)
    value = tostring(value)
    if value:find("[\128-\255]") then
        value = remove_accents(value)
    end
    value = (value:gsub("[^%w%-%_%. ]", "_"))
    value = value:sub(1, 80)
    value = (value:gsub("[%s%.]+$", ""))
    value = (value:gsub("^[%s%.]+", ""))
    return value
end

local function safe_name(value, limit)
    local name = sanitize(value)
    if limit then
        name = name:sub(1, limit)
    end
    if name == "" or name:match("^%s*$") then
        return "_"
    end
    return name
end

local function get_placeinfo()
    local placeId = game.PlaceId
    local gameName = "game"
    local info
    pcall(function()
        info = MarketplaceService:GetProductInfoAsync(placeId)
    end)
    if type(info) == "table" and info.Name then
        local name = sanitize(info.Name)
        name = (name:gsub("%s+", " "))
        name = name:match("^%s*(.-)%s*$")
        name = name:sub(1, 50)
        if name ~= "" and not name:match("^[%s_]*$") then
            gameName = name
        end
    end
    return placeId, gameName, info
end

local function build_path(object)
    local reversed = {}
    local current = object
    while current and current ~= game do
        reversed[#reversed + 1] = safe_name(current.Name)
        current = current.Parent
    end
    if current == nil then
        reversed[#reversed + 1] = "NilInstances"
    end
    local segments = {}
    for index = #reversed, 1, -1 do
        segments[#segments + 1] = reversed[index]
    end
    return table.concat(segments, "/")
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

local knownFolders = {}

local function folder_exists(path)
    if knownFolders[path] then
        return true
    end
    local ok, result = try(isfolder_fn, path)
    return ok and result == true
end

local function ensure_dirs(path)
    local parts = {}
    for part in path:gmatch("[^/]+") do
        table.insert(parts, part)
    end
    local current = ""
    for index = 1, #parts - 1 do
        if current == "" then
            current = parts[index]
        else
            current = current .. "/" .. parts[index]
        end
        if not knownFolders[current] then
            if not folder_exists(current) then
                local ok = try(makefolder_fn, current)
                if not ok then
                    return false
                end
            end
            knownFolders[current] = true
        end
    end
    return true
end

local function write_file(path, content)
    if not ensure_dirs(path) then
        return false
    end
    local ok = try(writefile_fn, path, content)
    return ok
end

local function write_lines(base, lines)
    if #lines == 0 then
        return
    end
    write_file(base .. ".lua", table.concat(lines, "\n"))
end

local function log_detect(tag, msg)
    print("[bytecore][" .. tag .. "] " .. tostring(msg))
end

local IGNORED_SERVICES = {
    CoreGui = true,
    CorePackages = true,
    RobloxPluginGuiService = true,
    PluginGuiService = true,
    VirtualUser = true,
    VirtualInputManager = true,
    RobloxReplicatedStorage = true,
    TimerService = true,
    LogService = true,
    ScriptContext = true,
    ScriptEditorService = true,
    LuaChat = true,
    Chat = true,
    Packages = true,
    StudioService = true,
    PluginDebugService = true,
    UserInputService = true,
    GuiService = true,
    ContextActionService = true,
    VRService = true,
    HapticService = true,
    GamepadService = true,
    MouseService = true,
    TouchInputService = true,
    KeyboardService = true,
    AccessibilityService = true,
    MemStorageService = true,
    MessageBusService = true,
    RobloxServerStorage = true,
}

local IGNORED_NAME_PATTERNS = {
    "^Roblox",
    "^Core",
    "^_",
    "^%%",
    "^Loader",
    "^Init",
    "^Default",
    "^App$",
    "^Game$",
    "^NetworkClient$",
    "^NetworkServer$",
    "^Chat$",
    "^LuaChat$",
    "^RobloxReplicatedStorage$",
    "^CoreGui$",
    "^CorePackages$",
    "^PluginGuiService$",
    "^PluginDebugService$",
    "^StudioService$",
    "^ScriptEditorService$",
    "^ScriptContext$",
    "^LogService$",
    "^TimerService$",
    "^VirtualUser$",
    "^VirtualInputManager$",
}

local function has_ignored_name(name)
    for _, pattern in ipairs(IGNORED_NAME_PATTERNS) do
        if name:match(pattern) then
            return true
        end
    end
    return false
end

local function is_ignored_ancestor(instance)
    local current = instance.Parent
    while current and current ~= game do
        if IGNORED_SERVICES[current.Name] then
            return true
        end
        current = current.Parent
    end
    return false
end

local REMOTE_CLASSES = {
    "RemoteEvent",
    "RemoteFunction",
    "UnreliableRemoteEvent",
    "BindableEvent",
    "BindableFunction",
}

local remotes = {}

for _, class in ipairs(REMOTE_CLASSES) do
    remotes[class] = {}
end

local function collect_remotes()
    local found = {}
    local totalSeen = 0

    local function consider(instance)
        local ok, class = pcall(function()
            return instance.ClassName
        end)
        if not ok or not remotes[class] then
            return
        end
        totalSeen = totalSeen + 1

        if is_ignored_ancestor(instance) then
            return
        end

        local okName, name = pcall(function()
            return instance.Name
        end)
        if okName and type(name) == "string" and has_ignored_name(name) then
            return
        end

        found[#found + 1] = instance
    end

    local TARGET_SERVICES = {
        "Workspace",
        "Players",
        "ReplicatedFirst",
        "ReplicatedStorage",
        "ServerScriptService",
        "ServerStorage",
        "StarterGui",
        "StarterPack",
        "StarterPlayer",
    }

    for _, serviceName in ipairs(TARGET_SERVICES) do
        local okService, service = pcall(function()
            return game:GetService(serviceName)
        end)
        if okService and service then
            local okDesc, descendants = pcall(function()
                return service:GetDescendants()
            end)
            if okDesc and type(descendants) == "table" then
                for _, descendant in ipairs(descendants) do
                    consider(descendant)
                end
            end
        end
    end

    if getinstances_fn then
        local okAll, all = try(getinstances_fn)
        if okAll and type(all) == "table" then
            for _, instance in ipairs(all) do
                consider(instance)
            end
        end
    end

    if getnilinstances_fn then
        local okNil, nilInstances = try(getnilinstances_fn)
        if okNil and type(nilInstances) == "table" then
            for _, instance in ipairs(nilInstances) do
                consider(instance)
            end
        end
    end

    log_detect("remotes", "candidatos: " .. #found .. " | checados " .. totalSeen)
    return found
end

local function build_game_info(info, placeId, gameName)
    local lines = {}

    local function add(key, value)
        lines[#lines + 1] = key .. ": " .. tostring(value)
    end

    local function add_safe(key, getter)
        local ok, value = pcall(getter)
        if ok and value ~= nil and value ~= "" then
            add(key, value)
        end
    end

    add("Nome", gameName)
    add("PlaceId", placeId)
    add_safe("GameId", function()
        return game.GameId
    end)
    add_safe("JobId", function()
        return game.JobId
    end)
    add_safe("PlaceVersion", function()
        return game.PlaceVersion
    end)
    add_safe("Executor", function()
        local name, version = identifyexecutor_fn()
        return tostring(name) .. " " .. tostring(version or "")
    end)
    if info then
        add_safe("Criado", function()
            return info.Created
        end)
        add_safe("Atualizado", function()
            return info.Updated
        end)
        add_safe("Criador", function()
            return tostring(info.Creator.Name)
                .. " | "
                .. tostring(info.Creator.CreatorType)
                .. " | "
                .. tostring(info.Creator.CreatorTargetId or info.Creator.Id)
        end)
    end
    add_safe("Jogadores", function()
        return #Players:GetPlayers() .. "/" .. Players.MaxPlayers
    end)
    add_safe("LocalPlayer", function()
        local player = Players.LocalPlayer
        return player.Name
            .. " | "
            .. player.DisplayName
            .. " | "
            .. player.UserId
            .. " | AccountAge "
            .. player.AccountAge
    end)
    return table.concat(lines, "\n")
end

local function build_players()
    local lines = {}
    for _, player in ipairs(Players:GetPlayers()) do
        pcall(function()
            local team = "-"
            if player.Team then
                team = player.Team.Name
            end
            lines[#lines + 1] = player.Name
                .. " | "
                .. player.DisplayName
                .. " | "
                .. player.UserId
                .. " | "
                .. team
                .. " | "
                .. player.AccountAge
        end)
    end
    return table.concat(lines, "\n")
end

local placeId, gameName, productInfo = get_placeinfo()
local ROOT = gameName .. "_" .. tostring(placeId)
local isResuming = folder_exists(ROOT)

if not isResuming then
    local ok = try(makefolder_fn, ROOT)
    if ok then
        knownFolders[ROOT] = true
    else
        ROOT = "bytecore_" .. tostring(placeId)
        isResuming = folder_exists(ROOT)
        if not isResuming then
            try(makefolder_fn, ROOT)
        end
    end
end

local startLabel = "Iniciando | "

if isResuming then
    startLabel = "Continuando | "
end

local main = notify({
    Id = "bytecore",
    Title = "bytecore",
    Description = startLabel .. gameName .. " | " .. placeId,
    Duration = 0,
    Type = "Info",
})

local errorLog = {}

local function error_handler(message)
    return tostring(message) .. "\n" .. debug.traceback()
end

local function log_error(where, err)
    local text = "[" .. where .. "] " .. tostring(err)
    errorLog[#errorLog + 1] = text
    print("[bytecore][error] " .. text)
end

local function guarded(where, fn, ...)
    local ok, err = xpcall(fn, error_handler, ...)
    if not ok then
        log_error(where, err)
    end
    return ok
end

local function stage(name, fn)
    local ok, err = xpcall(fn, error_handler)
    if not ok then
        log_error(name, err)
        local firstLine = tostring(err):match("^[^\n]*")
        notify({
            Title = "bytecore | Erro",
            Description = name .. ": " .. tostring(firstLine),
            Duration = 6,
            Type = "Error",
        })
    end
end

log_detect("executor", "identifyexecutor: " .. tostring(identifyexecutor_fn and select(1, identifyexecutor_fn()) or "nil"))
log_detect("executor", "decompile: " .. tostring(decompile_fn ~= nil))
log_detect("executor", "getscripts: " .. tostring(getscripts_fn ~= nil))
log_detect("executor", "getloadedmodules: " .. tostring(getloadedmodules_fn ~= nil))
log_detect("executor", "getrunningscripts: " .. tostring(getrunningscripts_fn ~= nil))
log_detect("executor", "getinstances: " .. tostring(getinstances_fn ~= nil))
log_detect("executor", "getnilinstances: " .. tostring(getnilinstances_fn ~= nil))

stage("info", function()
    write_file(ROOT .. "/Info/game.lua", build_game_info(productInfo, placeId, gameName))
    local playersText = build_players()
    if playersText ~= "" then
        write_file(ROOT .. "/Info/players.lua", playersText)
    end
end)

stage("remotes", function()
    local candidates = collect_remotes()
    local total = #candidates
    log_detect("remotes", "processando " .. total .. " candidatos")
    for index, instance in ipairs(candidates) do
        guarded("remotes " .. index, function()
            local ok, class = pcall(function()
                return instance.ClassName
            end)
            if not ok then
                return
            end
            local bucket = remotes[class]
            if not bucket then
                return
            end
            bucket[#bucket + 1] = full_name(instance)
        end)
        if index % 2500 == 0 then
            task.wait()
            progress(main, "bytecore | Remotes", index .. "/" .. total)
        end
    end

    for _, class in ipairs(REMOTE_CLASSES) do
        log_detect("remotes", class .. ": " .. #remotes[class])
    end
end)

local SCRIPT_CLASSES = {
    LocalScript = true,
    Script = true,
    ModuleScript = true,
}

local scriptCount = 0
local scriptFail = 0
local scriptSkip = 0
local scriptEmpty = 0
local scriptList = {}

local function is_valid_source(source)
    if type(source) ~= "string" or source == "" then
        return false
    end
    local lower = source:lower()
    if lower:find("^%s*$") then
        return false
    end
    if lower:find("decompilation failed") then
        return false
    end
    if lower:find("unsupported") and not lower:find("local") then
        return false
    end
    if lower:find("^decompile error") then
        return false
    end
    if lower:find("^error:") then
        return false
    end
    if #source < 16 then
        return false
    end
    return true
end

local function write_script(filePath, source)
    return write_file(ROOT .. "/Scripts/" .. filePath .. ".lua", source)
end

local function collect_all_scripts()
    local seen = {}
    local list = {}
    local ignored = 0

    local function is_valid(instance)
        local okClass, class = pcall(function()
            return instance.ClassName
        end)
        if not okClass or not SCRIPT_CLASSES[class] then
            return false
        end

        local okName, name = pcall(function()
            return instance.Name
        end)
        if not okName or type(name) ~= "string" then
            return false
        end

        if has_ignored_name(name) then
            return false
        end

        if is_ignored_ancestor(instance) then
            return false
        end

        return true
    end

    local function add(items, source)
        if type(items) ~= "table" then
            return
        end
        local added = 0
        for _, instance in ipairs(items) do
            if is_valid(instance) and not seen[instance] then
                seen[instance] = true
                list[#list + 1] = instance
                added = added + 1
            else
                ignored = ignored + 1
            end
        end
        log_detect("scripts", source .. " -> " .. added .. " (total " .. #list .. ")")
    end

    if getscripts_fn then
        local ok, scripts = pcall(getscripts_fn)
        if ok then
            add(scripts, "getscripts")
        else
            log_detect("scripts", "getscripts erro: " .. tostring(scripts))
        end
    else
        log_detect("scripts", "getscripts indisponivel")
    end

    if getloadedmodules_fn then
        local ok, modules = pcall(getloadedmodules_fn)
        if ok then
            add(modules, "getloadedmodules")
        else
            log_detect("scripts", "getloadedmodules erro: " .. tostring(modules))
        end
    else
        log_detect("scripts", "getloadedmodules indisponivel")
    end

    if getrunningscripts_fn then
        local ok, running = pcall(getrunningscripts_fn)
        if ok then
            add(running, "getrunningscripts")
        else
            log_detect("scripts", "getrunningscripts erro: " .. tostring(running))
        end
    else
        log_detect("scripts", "getrunningscripts indisponivel")
    end

    if #list == 0 then
        log_detect("scripts", "varredura direcionada nos servicos alvo")

        local TARGET_SERVICES = {
            "Workspace",
            "Players",
            "ReplicatedFirst",
            "ReplicatedStorage",
            "ServerScriptService",
            "ServerStorage",
            "StarterGui",
            "StarterPack",
            "StarterPlayer",
        }

        for _, serviceName in ipairs(TARGET_SERVICES) do
            local okService, service = pcall(function()
                return game:GetService(serviceName)
            end)
            if okService and service then
                local okDesc, descendants = pcall(function()
                    return service:GetDescendants()
                end)
                if okDesc and type(descendants) == "table" then
                    local addedHere = 0
                    for _, descendant in ipairs(descendants) do
                        if is_valid(descendant) and not seen[descendant] then
                            seen[descendant] = true
                            list[#list + 1] = descendant
                            addedHere = addedHere + 1
                        end
                    end
                    log_detect("scripts", serviceName .. " -> " .. addedHere .. " (total " .. #list .. ")")
                end
            end
        end
    end

    if getnilinstances_fn then
        local ok, nilInstances = pcall(getnilinstances_fn)
        if ok and type(nilInstances) == "table" then
            local added = 0
            for _, instance in ipairs(nilInstances) do
                if is_valid(instance) and not seen[instance] then
                    seen[instance] = true
                    list[#list + 1] = instance
                    added = added + 1
                end
            end
            if added > 0 then
                log_detect("scripts", "getnilinstances -> " .. added .. " (total " .. #list .. ")")
            end
        end
    end

    log_detect("scripts", "ignorados: " .. ignored)
    return list
end

stage("scripts", function()
    local allScripts = collect_all_scripts()
    log_detect("scripts", "total coletado: " .. #allScripts)

    if #allScripts == 0 then
        log_detect("scripts", "nenhum script encontrado")
        return
    end

    local scriptPaths = {}
    local lastLog = 0

    for index, instance in ipairs(allScripts) do
        guarded("scripts " .. index, function()
            local okName, instanceName = pcall(function()
                return instance.Name
            end)
            if not okName or type(instanceName) ~= "string" then
                scriptSkip = scriptSkip + 1
                return
            end

            local okClass, class = pcall(function()
                return instance.ClassName
            end)
            if not okClass then
                scriptSkip = scriptSkip + 1
                return
            end

            local fullName = full_name(instance)
            local basePath = build_path(instance)
            if basePath == "" then
                basePath = safe_name(instanceName)
            end

            if decompile_fn then
                local okDec, source = pcall(decompile_fn, instance)
                if okDec and is_valid_source(source) then
                    local occurrence = (scriptPaths[basePath] or 0) + 1
                    scriptPaths[basePath] = occurrence
                    local scriptPath = basePath
                    if occurrence > 1 then
                        scriptPath = basePath .. "_" .. occurrence
                    end
                    if write_script(scriptPath, source) then
                        scriptCount = scriptCount + 1
                        scriptList[#scriptList + 1] = class .. " | " .. fullName .. " | codigo"
                        return
                    else
                        scriptFail = scriptFail + 1
                        scriptList[#scriptList + 1] = class .. " | " .. fullName .. " | falha"
                        return
                    end
                end
            end

            scriptEmpty = scriptEmpty + 1
            scriptList[#scriptList + 1] = class .. " | " .. fullName .. " | vazio"
        end)

        if index % 25 == 0 then
            local now = os.clock()
            if now - lastLog > 1 then
                lastLog = now
                progress(main, "bytecore | Scripts", index .. "/" .. #allScripts .. " | Codigo: " .. scriptCount)
                log_detect("scripts", index .. "/" .. #allScripts .. " codigo " .. scriptCount .. " vazios " .. scriptEmpty .. " falhas " .. scriptFail .. " pulados " .. scriptSkip)
            end
        end
        task.wait()
    end

    log_detect("scripts", "finalizado: codigo " .. scriptCount .. " | vazios " .. scriptEmpty .. " | falhas " .. scriptFail .. " | pulados " .. scriptSkip)
end)

local totalRemotes = 0

stage("saida", function()
    for _, class in ipairs(REMOTE_CLASSES) do
        local paths = remotes[class]
        if #paths > 0 then
            table.sort(paths)
            totalRemotes = totalRemotes + #paths
            local lines = {class .. " (" .. #paths .. ")"}
            for _, path in ipairs(paths) do
                table.insert(lines, "  " .. path)
            end
            write_lines(ROOT .. "/Remotes/" .. class, lines)
        end
    end
    log_detect("remotes", "total salvo: " .. totalRemotes)
end)

stage("relatorios", function()
    table.sort(scriptList)

    local scriptLines = {
        "Jogo: " .. gameName,
        "PlaceId: " .. tostring(placeId),
        "Total listado: " .. #scriptList,
        "Codigo: " .. scriptCount,
        "Vazios: " .. scriptEmpty,
        "Falhas: " .. scriptFail,
        "Pulados: " .. scriptSkip,
        "",
    }
    for _, line in ipairs(scriptList) do
        scriptLines[#scriptLines + 1] = line
    end
    write_file(ROOT .. "/Info/scripts.lua", table.concat(scriptLines, "\n"))

    local statusLines = {
        "Jogo: " .. gameName,
        "PlaceId: " .. tostring(placeId),
        "GameId: " .. tostring(game.GameId),
        "JobId: " .. tostring(game.JobId),
        "PlaceVersion: " .. tostring(game.PlaceVersion),
        "LocalPlayer: " .. tostring(Players.LocalPlayer and Players.LocalPlayer.Name or "nil"),
        "Jogadores: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers,
        "",
        "Remotes: " .. totalRemotes,
        "Scripts com codigo: " .. scriptCount,
        "Scripts vazios: " .. scriptEmpty,
        "Scripts falhas: " .. scriptFail,
        "Scripts pulados: " .. scriptSkip,
        "",
        "Erros: " .. #errorLog,
    }
    write_file(ROOT .. "/Info/status.lua", table.concat(statusLines, "\n"))

    log_detect("relatorios", "scripts.lua | status.lua")
end)

notify({
    Title = "bytecore | Finalizado",
    Description = "Remotes: " .. totalRemotes .. " | Codigo: " .. scriptCount,
    Duration = 6,
    Type = "Success",
})

write_lines(ROOT .. "/Info/errors", errorLog)

task.wait(1)

update(main, {
    Title = "bytecore | Finalizado",
    Description = gameName .. " | " .. placeId .. " | Codigo: " .. scriptCount,
    Duration = 8,
    Type = "Success",
})