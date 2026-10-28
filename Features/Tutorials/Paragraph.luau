-- // Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer

-- // Tab
local ParaTab = Window:CreateTab({
    tab = "Status",
    section = "Librarys",
    icon = "activity",
})

local ParaSection = ParaTab:CreateSection("Paragraph")

-- // Estado
local fps = 60
local fpsTime = 0
local fpsFrames = 0
local gameName = "Desconhecido"

task.spawn(function()
    local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, game.PlaceId)

    if ok and info and info.Name then
        gameName = info.Name
    end
end)

-- // Helpers
local getLeaderstat = function(target, ...)
    local leaderstats = target:FindFirstChild("leaderstats")

    if not leaderstats then
        return nil
    end

    for _, name in ipairs({ ... }) do
        local stat = leaderstats:FindFirstChild(name)

        if stat and stat:IsA("ValueBase") then
            return stat.Value
        end
    end

    return nil
end

local getHumanoid = function()
    local character = player.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

local getRoot = function()
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local getPing = function()
    local ok, value = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)

    return ok and math.floor(value) or 0
end

local formatTime = function(seconds)
    seconds = math.floor(seconds)

    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local rest = seconds % 60

    return string.format("%02d:%02d:%02d", hours, minutes, rest)
end

local getDevice = function()
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        return "Mobile"
    end

    if UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then
        return "Console"
    end

    return "PC"
end

-- // Player Card
local getPlayerStatus = function()
    local humanoid = getHumanoid()
    local root = getRoot()
    local position = root and root.Position or Vector3.zero
    local level = getLeaderstat(player, "Level", "Lv", "Nivel") or 0
    local rank = getLeaderstat(player, "Rank") or "Player"

    return {
        { name = "Health", value = humanoid and math.floor(humanoid.Health) or 0, max = humanoid and math.floor(humanoid.MaxHealth) or 100 },
        { name = "Level", value = level },
        { name = "Rank", value = tostring(rank) },
        { name = "Nome", value = player.Name },
        { name = "Display", value = player.DisplayName },
        { name = "UserId", value = player.UserId },
        { name = "Conta", value = player.AccountAge .. " dias" },
        { name = "Time", value = player.Team and player.Team.Name or "Nenhum" },
        { name = "Velocidade", value = humanoid and math.floor(humanoid.WalkSpeed) or 0 },
        { name = "Pulo", value = humanoid and math.floor(humanoid.JumpPower) or 0 },
        { name = "Posição", value = string.format("%d, %d, %d", position.X, position.Y, position.Z) },
        { name = "Dispositivo", value = getDevice() },
        { name = "FPS", value = fps },
        { name = "Ping", value = getPing() },
    }
end

local getPlayerCorners = function()
    local level = getLeaderstat(player, "Level", "Lv", "Nivel") or 0

    return {
        topLeft = player.DisplayName,
        topRight = "Lv. " .. tostring(level),
        bottomLeft = player.Character and "Online" or "Carregando",
        bottomRight = player.MembershipType == Enum.MembershipType.Premium and "Premium" or "Free",
    }
end

local playerCard = ParaSection:CreateParagraph({
    title = "Player Card",
    description = "Live preview",
    hologram = {
        target = player.UserId,
        type = "character",
        rotate = true,
        speed = 40,
        corners = getPlayerCorners(),
    },
    status = getPlayerStatus(),
    callback = function(page)
        print("Player Card:", page)
    end,
})

-- // Servidor
local getServerStatus = function()
    local jobId = game.JobId ~= "" and game.JobId:sub(1, 18) or "Studio"
    local serverType = "Público"

    if game.PrivateServerId ~= "" then
        serverType = game.PrivateServerOwnerId ~= 0 and "VIP" or "Reservado"
    end

    return {
        { name = "Jogo", value = gameName },
        { name = "Jogadores", value = #Players:GetPlayers(), max = Players.MaxPlayers },
        { name = "Tipo", value = serverType },
        { name = "Tempo ativo", value = formatTime(workspace.DistributedGameTime) },
        { name = "Hora", value = os.date("%H:%M:%S") },
        { name = "Ping", value = getPing() },
        { name = "FPS", value = fps },
        { name = "PlaceId", value = game.PlaceId },
        { name = "JobId", value = jobId },
        { name = "Versão", value = game.PlaceVersion },
    }
end

local serverCard = ParaSection:CreateParagraph({
    title = "Servidor",
    description = "Informações do servidor",
    status = getServerStatus(),
})

-- // Jogador
local playerRow = ParaSection:CreateParagraph({
    title = player.DisplayName .. " (@" .. player.Name .. ")",
    description = "Carregando...",
    thumbnail = player.UserId,
})

-- // Atualização
local refresh = function()
    playerCard:SetStatus(getPlayerStatus())
    playerCard:SetCorners(getPlayerCorners())
    serverCard:SetStatus(getServerStatus())
    playerRow:SetDescription(player.Character and "Online" or "Sem personagem")
end

-- // Loop
local elapsed = 0

local connection = RunService.Heartbeat:Connect(function(dt)
    fpsTime = fpsTime + dt
    fpsFrames = fpsFrames + 1

    if fpsTime >= 0.5 then
        fps = math.floor(fpsFrames / fpsTime)
        fpsTime = 0
        fpsFrames = 0
    end

    elapsed = elapsed + dt

    if elapsed < 1 then
        return
    end

    elapsed = 0

    pcall(refresh)
end)

-- // Unload
getgenv().StatusUnload = function()
    connection:Disconnect()
end