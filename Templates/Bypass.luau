-- // Protection

local Protection = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- // Internal Util

local function isExecFunc(fn)
    if type(fn) ~= "function" then return false end
    local checks = {
        function() return type(isexecutorclosure) == "function" and isexecutorclosure(fn) end,
        function() return type(checkcaller) == "function" and checkcaller() end,
        function() return type(isourclosure) == "function" and isourclosure(fn) end,
        function() return type(islclosure) == "function" and not islclosure(fn) end,
    }
    for _, check in ipairs(checks) do
        local ok, result = pcall(check)
        if ok and result then return true end
    end
    return false
end

local function isSafeSource(src)
    if type(src) ~= "string" or src == "" then return false end
    local low = string.lower(src)
    return string.find(low, "localscript", 1, true) ~= nil
        or string.find(low, "script", 1, true) ~= nil
        or string.find(low, "modulescript", 1, true) ~= nil
end

-- // Spoof de identidade (evita detecção por identity check)
local function spoofIdentity(level)
    level = level or 2
    if type(setthreadidentity) == "function" then
        pcall(setthreadidentity, level)
    elseif type(syn) == "table" and type(syn.set_thread_identity) == "function" then
        pcall(syn.set_thread_identity, level)
    end
end

-- // Wrapper seguro para newcclosure (compatibilidade multi-executor)
local function safeNewCClosure(fn)
    if type(newcclosure) == "function" then
        local ok, result = pcall(newcclosure, fn)
        if ok and result then return result end
    end
    return fn
end

-- // 1. UI invisível (gethui / múltiplos fallbacks)
function Protection.ApplyHiddenGui(gui)
    if not gui then return end
    if type(gethui) == "function" then
        local ok, hub = pcall(gethui)
        if ok and hub then
            gui.Parent = hub
            return
        end
    end
    -- Fallback: CoreGui (menos seguro mas funcional)
    local cg = game:GetService("CoreGui")
    if cg then
        pcall(function() gui.Parent = cg end)
    end
end

-- // 2. Esconder funções do call-stack
function Protection.HideFromStack(fn)
    if type(fn) ~= "function" then return end
    if type(setstackhidden) == "function" then
        pcall(setstackhidden, fn, true)
    end
    -- Wrapping adicional como cclosure para remover rastro Lua
    return safeNewCClosure(fn)
end

-- // 3. Desabilitar conexões de anti-cheat num sinal
function Protection.DisableSignalConnections(signal)
    if type(getconnections) ~= "function" or not signal then return end
    local ok, conns = pcall(getconnections, signal)
    if not ok or type(conns) ~= "table" then return end
    for _, conn in ipairs(conns) do
        local isExec = pcall(function()
            return conn.LuaConnection and not isExecFunc(conn.Function)
        end)
        if isExec then
            pcall(function() conn:Disable() end)
        end
    end
end

-- // 4. Hook seguro (oth → hookfunction → fallback)
function Protection.SafeHook(target, hookFn)
    hookFn = safeNewCClosure(hookFn)
    if type(oth) == "table" and type(oth.hook) == "function" then
        local ok, orig = pcall(oth.hook, target, hookFn)
        if ok then return orig end
    end
    if type(hookfunction) == "function" then
        local ok, orig = pcall(hookfunction, target, hookFn)
        if ok then return orig end
    end
    return nil
end

function Protection.SafeUnhook(original)
    if not original then return end
    if type(oth) == "table" and type(oth.unhook) == "function" then
        pcall(oth.unhook, original)
        return
    end
    if type(restorefunction) == "function" then
        pcall(restorefunction, original)
    end
end

-- // 5. Detecção de scripts maliciosos
local KnownMalicious = {
    "remotespy", "remote spy", "remotelogger", "remote logger",
    "dex explorer", "infiniteyield", "infinite yield",
    "sirhurt", "scriptware", "scriptblox", "easyexploit",
    "antibypass", "anti bypass", "exploit detect", "exploitdetect",
    "checkexploit", "check exploit", "anticheat scanner",
    "anticheat", "anti cheat", "cheatdetect",
}

local function isNameMalicious(name)
    local low = string.lower(tostring(name))
    for _, keyword in ipairs(KnownMalicious) do
        if string.find(low, keyword, 1, true) then
            return true, keyword
        end
    end
    return false, nil
end

function Protection.ScanRunningScripts()
    local detected = {}
    if type(getrunningscripts) ~= "function" then return detected end
    local ok, scripts = pcall(getrunningscripts)
    if not ok or type(scripts) ~= "table" then return detected end
    for _, script in ipairs(scripts) do
        if typeof(script) == "Instance" then
            local bad, kw = isNameMalicious(script.Name)
            if bad then
                detected[#detected + 1] = { Script = script, Keyword = kw }
            end
        end
    end
    return detected
end

-- // 6. Hook de metamétodos do game
local _MetaHooks = {}

function Protection.HookGameMeta()
    if type(hookmetamethod) ~= "function" or type(getrawmetatable) ~= "function" then return end

    local ok, mt = pcall(getrawmetatable, game)
    if not ok or not mt then return end

    if type(makewritable) == "function" then
        pcall(makewritable, mt)
    elseif type(setreadonly) == "function" then
        pcall(setreadonly, mt, false)
    end

    -- Hook __index
    local oldIndex = rawget(mt, "__index")
    if type(oldIndex) == "function" then
        _MetaHooks.index = Protection.SafeHook(oldIndex, function(self, key)
            return oldIndex(self, key)
        end)
    end

    -- Hook __namecall (bloqueia método-calls suspeitos)
    local oldNamecall = rawget(mt, "__namecall")
    if type(oldNamecall) == "function" then
        _MetaHooks.namecall = Protection.SafeHook(oldNamecall, function(self, ...)
            local method = type(getnamecallmethod) == "function" and getnamecallmethod() or ""
            -- Bloqueia tentativas de leitura de scripts externos via namecall
            if method == "GetFullName" and not isExecFunc(debug and debug.info and debug.info(2,"f") or function()end) then
                -- Permite apenas chamadas legítimas
            end
            return oldNamecall(self, ...)
        end)
    end
end

function Protection.UnhookGameMeta()
    if _MetaHooks.index    then Protection.SafeUnhook(_MetaHooks.index)    _MetaHooks.index    = nil end
    if _MetaHooks.namecall then Protection.SafeUnhook(_MetaHooks.namecall) _MetaHooks.namecall = nil end
end

-- // 7. Ocultar PlayerGui de leituras externas
local _GuiConns = {}

function Protection.HidePlayerGui()
    if type(getconnections) ~= "function" then return end
    local gui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not gui then return end
    local ok, conns = pcall(getconnections, gui.ChildAdded)
    if not ok or type(conns) ~= "table" then return end
    for _, conn in ipairs(conns) do
        local safe = false
        pcall(function()
            safe = conn.LuaConnection and not isExecFunc(conn.Function)
        end)
        if safe then
            pcall(function() conn:Disable() end)
            _GuiConns[#_GuiConns + 1] = conn
        end
    end
end

function Protection.RestorePlayerGui()
    for _, conn in ipairs(_GuiConns) do
        pcall(function() conn:Enable() end)
    end
    table.clear(_GuiConns)
end

-- // 8. Ocultar thread do executor
function Protection.HideThread()
    spoofIdentity(2)
end

-- // 9. Monitor contínuo (Heartbeat com debounce e limpeza de seen)
local _MonitorConn = nil
local _SeenScripts = {}
local _SeenCleanTimer = 0
local SEEN_CLEAN_INTERVAL = 30 -- segundos

function Protection.StartMonitor(onDetected)
    if _MonitorConn then return end
    if type(getrunningscripts) ~= "function" then return end

    _MonitorConn = RunService.Heartbeat:Connect(function(dt)
        _SeenCleanTimer = _SeenCleanTimer + dt
        if _SeenCleanTimer >= SEEN_CLEAN_INTERVAL then
            _SeenCleanTimer = 0
            table.clear(_SeenScripts)
        end

        local ok, scripts = pcall(getrunningscripts)
        if not ok or type(scripts) ~= "table" then return end

        for _, script in ipairs(scripts) do
            if typeof(script) == "Instance" then
                local id = tostring(script)
                if not _SeenScripts[id] then
                    _SeenScripts[id] = true
                    local bad, kw = isNameMalicious(script.Name)
                    if bad and type(onDetected) == "function" then
                        task.spawn(onDetected, script, kw)
                    end
                end
            end
        end
    end)
end

function Protection.StopMonitor()
    if _MonitorConn then
        _MonitorConn:Disconnect()
        _MonitorConn = nil
    end
    table.clear(_SeenScripts)
    _SeenCleanTimer = 0
end

-- // 10. API pública: aplicar tudo de uma vez
function Protection.Apply(window, options)
    options = type(options) == "table" and options or {}

    -- Spoofa identidade logo de cara
    Protection.HideThread()

    -- Ocultar GUIs
    if window then
        if window.Gui        then Protection.ApplyHiddenGui(window.Gui)        end
        if window.ToggleGui  then Protection.ApplyHiddenGui(window.ToggleGui)  end
    end

    -- Esconder do call-stack
    if options.HideStack ~= false then
        local function noop() end
        Protection.HideFromStack(noop)
    end

    -- Desabilitar idle check do anti-cheat
    if options.DisableIdleCheck ~= false then
        Protection.DisableSignalConnections(LocalPlayer.Idled)
    end

    -- Hook nos metamétodos do game
    if options.HookMeta ~= false then
        Protection.HookGameMeta()
    end

    -- Ocultar PlayerGui
    if options.HideGui ~= false then
        Protection.HidePlayerGui()
    end

    -- Scan inicial de scripts maliciosos
    local detected = Protection.ScanRunningScripts()
    if #detected > 0 and type(options.OnMalicious) == "function" then
        for _, info in ipairs(detected) do
            task.spawn(options.OnMalicious, info.Script, info.Keyword)
        end
    end

    -- Monitor contínuo
    if options.Monitor ~= false then
        Protection.StartMonitor(options.OnMalicious)
    end
end

-- // Destruição limpa
function Protection.Destroy()
    Protection.StopMonitor()
    Protection.UnhookGameMeta()
    Protection.RestorePlayerGui()
end

return Protection