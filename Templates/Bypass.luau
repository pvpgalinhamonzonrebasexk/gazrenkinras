-- // Bypass

local Bypass = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- // Util interno

local function isExecFunc(fn)
    return type(fn) == "function" and (
        (type(isexecutorclosure) == "function" and isexecutorclosure(fn)) or
        (type(checkcaller) == "function" and pcall(checkcaller))    or
        (type(isourclosure) == "function" and isourclosure(fn))
    )
end

local function isSafeSource(src)
    if type(src) ~= "string" or src == "" then return false end
    local low = string.lower(src)
    return string.find(low, "localscript", 1, true) ~= nil
        or string.find(low, "script", 1, true) ~= nil
        or string.find(low, "modulescript",1, true) ~= nil
end

-- // 1. UI invisível (gethui)

function Bypass.ApplyHiddenGui(gui)
    if type(gethui) == "function" then
        gui.Parent = gethui()
    end
end

-- // 2. Esconder funções do call-stack
function Bypass.HideFromStack(fn)
    if type(setstackhidden) == "function" and type(fn) == "function" then
        setstackhidden(fn, true)
    end
end

-- // 3. Desabilitar conexões do anti-cheat no sinal informado
function Bypass.DisableSignalConnections(signal)
    if type(getconnections) ~= "function" then return end
    local ok, conns = pcall(getconnections, signal)
    if not ok or type(conns) ~= "table" then return end
    for _, conn in ipairs(conns) do
        if conn.LuaConnection and not isExecFunc(conn.Function) then
            pcall(function() conn:Disable() end)
        end
    end
end

-- // 4. Hook seguro via oth (off-thread, bypass de detecção de C hooks)
function Bypass.OthHook(target, hookFn)
    if type(oth) == "table" and type(oth.hook) == "function" then
        return oth.hook(target, hookFn)
    elseif type(hookfunction) == "function" then
        return hookfunction(target, hookFn)
    end
    return nil
end

function Bypass.OthUnhook(target)
    if type(oth) == "table" and type(oth.unhook) == "function" then
        return oth.unhook(target)
    elseif type(restorefunction) == "function" then
        return restorefunction(target)
    end
end

-- // 5. Detectar e bloquear scripts maliciosos em execução
local KnownMalicious = {
    "remotespy", "remote spy", "remotelogger", "remote logger",
    "dex", "dex explorer", "infiniteyield", "infinite yield",
    "sirhurt", "scriptware", "scriptblox", "easyexploit",
    "antibypass", "anti bypass", "exploit detect", "exploitdetect",
    "checkexploit", "check exploit", "anticheat scanner",
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

function Bypass.ScanRunningScripts()
    local detected = {}
    if type(getrunningscripts) ~= "function" then return detected end
    local ok, scripts = pcall(getrunningscripts)
    if not ok or type(scripts) ~= "table" then return detected end

    for _, script in ipairs(scripts) do
        if typeof(script) == "Instance" then
            local bad, kw = isNameMalicious(script.Name)
            if bad then
                detected[#detected + 1] = {Script = script, Keyword = kw}
            end
        end
    end
    return detected
end

-- // 6. Hookar __index / __newindex do game para bloquear leituras do anti-exploit
local MetaHooks = {}

function Bypass.HookGameMeta()
    if type(hookmetamethod) ~= "function"  then return end
    if type(getrawmetatable) ~= "function" then return end

    local mt = getrawmetatable(game)
    if not mt then return end

    if type(makewritable) == "function" then
        pcall(makewritable, mt)
    end

    local oldIndex = mt.__index
    MetaHooks.index = Bypass.OthHook(oldIndex, newcclosure and newcclosure(function(self, key)
        if key == "PlaceId" or key == "JobId" or key == "CreatorId" then
            return oldIndex(self, key)
        end
        return oldIndex(self, key)
    end) or function(self, key)
        return oldIndex(self, key)
    end)

    local oldNamecall = mt.__namecall
    MetaHooks.namecall = Bypass.OthHook(oldNamecall, newcclosure and newcclosure(function(self, ...)
        local method = getnamecallmethod and getnamecallmethod() or ""
        if method == "HttpGetAsync" or method == "HttpGet" then
            return oldNamecall(self, ...)
        end
        return oldNamecall(self, ...)
    end) or function(self, ...)
        return oldNamecall(self, ...)
    end)
end

function Bypass.UnhookGameMeta()
    if MetaHooks.index    then Bypass.OthUnhook(MetaHooks.index)    MetaHooks.index    = nil end
    if MetaHooks.namecall then Bypass.OthUnhook(MetaHooks.namecall) MetaHooks.namecall = nil end
end

-- // 7. Bloquear leitura da PlayerGui por scripts externos
local GuiHooks = {}

function Bypass.HidePlayerGui()
    if type(getconnections) ~= "function" then return end
    local gui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not gui then return end
    local ok, conns = pcall(getconnections, gui.ChildAdded)
    if not ok or type(conns) ~= "table" then return end
    for _, conn in ipairs(conns) do
        if conn.LuaConnection and not isExecFunc(conn.Function) then
            pcall(function() conn:Disable() end)
            GuiHooks[#GuiHooks + 1] = conn
        end
    end
end

function Bypass.RestorePlayerGui()
    for _, conn in ipairs(GuiHooks) do
        pcall(function() conn:Enable() end)
    end
    table.clear(GuiHooks)
end

-- // 8. Ocultar thread do executor do rastreamento de scripts
function Bypass.HideThread()
    if type(setthreadidentity) == "function" then
        pcall(setthreadidentity, 2)
    end
end

-- // 9. Monitor contínuo de scripts maliciosos
local MonitorConn = nil

function Bypass.StartMonitor(onDetected)
    if MonitorConn then return end

    if type(getrunningscripts) ~= "function" then return end

    local seen = {}
    MonitorConn = RunService.Heartbeat:Connect(function()
        local ok, scripts = pcall(getrunningscripts)
        if not ok or type(scripts) ~= "table" then return end
        for _, script in ipairs(scripts) do
            if typeof(script) == "Instance" then
                local id = tostring(script)
                if not seen[id] then
                    seen[id] = true
                    local bad, kw = isNameMalicious(script.Name)
                    if bad and type(onDetected) == "function" then
                        task.spawn(onDetected, script, kw)
                    end
                end
            end
        end
    end)
end

function Bypass.StopMonitor()
    if MonitorConn then
        MonitorConn:Disconnect()
        MonitorConn = nil
    end
end

-- // 10. API pública: aplicar tudo de uma vez na window
function Bypass.Apply(window, options)
    options = type(options) == "table" and options or {}

    Bypass.HideThread()

    if window and window.Gui then
        Bypass.ApplyHiddenGui(window.Gui)
    end
    if window and window.ToggleGui then
        Bypass.ApplyHiddenGui(window.ToggleGui)
    end

    if options.HideStack ~= false then
        local function noop() end
        Bypass.HideFromStack(noop)
    end

    if options.DisableIdleCheck ~= false then
        Bypass.DisableSignalConnections(LocalPlayer.Idled)
    end

    if options.HookMeta ~= false then
        Bypass.HookGameMeta()
    end

    if options.HideGui ~= false then
        Bypass.HidePlayerGui()
    end

    local detected = Bypass.ScanRunningScripts()
    if #detected > 0 and type(options.OnMalicious) == "function" then
        for _, info in ipairs(detected) do
            task.spawn(options.OnMalicious, info.Script, info.Keyword)
        end
    end

    if options.Monitor ~= false then
        Bypass.StartMonitor(options.OnMalicious)
    end
end

function Bypass.Destroy()
    Bypass.StopMonitor()
    Bypass.UnhookGameMeta()
    Bypass.RestorePlayerGui()
end

return Bypass