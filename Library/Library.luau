-- // Serviços
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LocalizationService = game:GetService("LocalizationService")
local MarketplaceService = game:GetService("MarketplaceService")

-- // Tema
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
    TabInactive = Color3.fromRGB(128, 128, 128),
    TabHover = Color3.fromRGB(175, 175, 175)
}

-- // Configurações
local Config = {
    Repo = "pvpgalinhamonzonrebasexk/gazrenkinras",
    Branch = "main",
    ElementsPath = "Library/Elements",
    FeaturesPath = "Features",
    TweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    FlashInfo = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    DefaultSize = UDim2.fromOffset(620, 350),
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
    MaxQuery = 48,
    SidebarWidth = 180,
    TabHeight = 34,
    TabFillTransparency = 0.3,
    TabTween = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TabPress = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TabRelease = TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    TabPop = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    ScrollTween = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    ScrollHold = 0.9,
    ScrollWidth = 6,
    SaveFile = "Ecohub.json",
    SaveDelay = 1
}

Config.ElementsApi = "https://api.github.com/repos/" .. Config.Repo .. "/contents/" .. Config.ElementsPath .. "?ref=" .. Config.Branch
Config.ElementsRaw = "https://raw.githubusercontent.com/" .. Config.Repo .. "/refs/heads/" .. Config.Branch .. "/" .. Config.ElementsPath .. "/"
Config.ElementsCdn = "https://cdn.jsdelivr.net/gh/" .. Config.Repo .. "@" .. Config.Branch .. "/" .. Config.ElementsPath .. "/"
Config.ElementsList = "https://data.jsdelivr.com/v1/packages/gh/" .. Config.Repo .. "@" .. Config.Branch .. "?structure=flat"
Config.IconsUrl = "https://raw.githubusercontent.com/" .. Config.Repo .. "/refs/heads/" .. Config.Branch .. "/Assets/Icons.lua"
Config.IconsCdn = "https://cdn.jsdelivr.net/gh/" .. Config.Repo .. "@" .. Config.Branch .. "/Assets/Icons.lua"

local ELEMENT_ALIASES = {toggle = "checkbox", colorpick = "colorpicker"}
local ELEMENT_ICONS = {
    button = "mouse-pointer-click",
    checkbox = "toggle-right",
    slider = "sliders-horizontal",
    dropdown = "chevrons-up-down",
    colorpicker = "palette",
    paragraph = "align-left"
}
local ELEMENT_DEFAULTS = {"Button", "Checkbox", "Toggle", "Slider", "Paragraph", "Dropdown", "ColorPicker"}

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

function Util.Prepare(source, header)
    source = string.gsub(source, "^\239\187\191", "")
    return header .. source
end

function Util.DeepEqual(a, b)
    if a == b then return true end
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    for key, value in pairs(a) do
        if not Util.DeepEqual(value, b[key]) then return false end
    end
    for key in pairs(b) do
        if a[key] == nil then return false end
    end
    return true
end

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
        Util.Tween(thumb, Config.ScrollTween, {BackgroundTransparency = target})
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

    for _, property in ipairs({"AnchorPoint", "Position", "Size"}) do
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
        local moveConnection, endConnection

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

-- // Json
local Json = {}

function Json.EncodeString(text)
    text = string.gsub(text, "\\", "\\\\")
    text = string.gsub(text, "\"", "\\\"")
    text = string.gsub(text, "\n", "\\n")
    text = string.gsub(text, "\r", "\\r")
    text = string.gsub(text, "\t", "\\t")
    return "\"" .. text .. "\""
end

function Json.Encode(value, indent)
    indent = indent or 0
    local pad = string.rep("    ", indent)
    local inner = string.rep("    ", indent + 1)

    if type(value) == "table" then
        local isArray = true
        local count = 0
        for key in pairs(value) do
            count = count + 1
            if type(key) ~= "number" then
                isArray = false
            end
        end
        if count == 0 then
            return "{}"
        end
        if isArray then
            local parts = {}
            for i = 1, count do
                parts[#parts + 1] = inner .. Json.Encode(value[i], indent + 1)
            end
            return "[\n" .. table.concat(parts, ",\n") .. "\n" .. pad .. "]"
        end
        local keys = {}
        for key in pairs(value) do
            keys[#keys + 1] = key
        end
        table.sort(keys, function(a, b)
            return tostring(a) < tostring(b)
        end)
        local parts = {}
        for _, key in ipairs(keys) do
            parts[#parts + 1] = inner .. Json.EncodeString(tostring(key)) .. ": " .. Json.Encode(value[key], indent + 1)
        end
        return "{\n" .. table.concat(parts, ",\n") .. "\n" .. pad .. "}"
    elseif type(value) == "string" then
        return Json.EncodeString(value)
    elseif type(value) == "number" or type(value) == "boolean" then
        return tostring(value)
    end
    return "null"
end

-- // Locale
local Locale = {
    Lang = nil,
    Version = 0,
    States = {},
    Custom = {},
    Records = setmetatable({}, {__mode = "k"}),
    Roots = setmetatable({}, {__mode = "k"}),
    Listeners = {},
    NextListener = 0
}

local TEXT_PROPERTIES = {TextLabel = "Text", TextButton = "Text", TextBox = "PlaceholderText"}

local LOCALE_STRINGS = {
    en = {
        SearchPlaceholder = "Search...",
        SearchPrompt = "Search tabs and elements...",
        NoResults = "No results found.",
        ErrorLabel = "Error"
    },
    pt = {
        SearchPlaceholder = "Pesquisar...",
        SearchPrompt = "Pesquisar abas e elementos...",
        NoResults = "Nenhum resultado encontrado.",
        ErrorLabel = "Erro"
    },
    es = {
        SearchPlaceholder = "Buscar...",
        SearchPrompt = "Buscar pestañas y elementos...",
        NoResults = "No se encontraron resultados.",
        ErrorLabel = "Error"
    }
}

local LOCALE_PATTERNS = {
    pt = {
        {"^(%d+) selected$", "%1 selecionados"}
    },
    es = {
        {"^(%d+) selected$", "%1 seleccionados"}
    }
}

local LOCALE_WORDS = {
    pt = {
        ["Main"] = "Principal", ["Home"] = "Início", ["General"] = "Geral", ["Settings"] = "Configurações", ["Configuration"] = "Configuração",
        ["Options"] = "Opções", ["Misc"] = "Diversos", ["Miscellaneous"] = "Diversos", ["Other"] = "Outros", ["Tools"] = "Ferramentas",
        ["Utilities"] = "Utilitários", ["Utility"] = "Utilitário", ["Info"] = "Informações", ["Information"] = "Informações", ["About"] = "Sobre",
        ["Credits"] = "Créditos", ["Status"] = "Status", ["Search"] = "Pesquisar", ["Search..."] = "Pesquisar...", ["Select"] = "Selecionar",
        ["Select..."] = "Selecionar...", ["No results found"] = "Nenhum resultado encontrado", ["None"] = "Nenhum", ["Selected"] = "Selecionado",
        ["Enable"] = "Ativar", ["Enabled"] = "Ativado", ["Disable"] = "Desativar", ["Disabled"] = "Desativado", ["Start"] = "Iniciar",
        ["Stop"] = "Parar", ["Pause"] = "Pausar", ["Resume"] = "Continuar", ["Reset"] = "Redefinir", ["Save"] = "Salvar",
        ["Load"] = "Carregar", ["Delete"] = "Excluir", ["Remove"] = "Remover", ["Add"] = "Adicionar", ["Apply"] = "Aplicar",
        ["Cancel"] = "Cancelar", ["Confirm"] = "Confirmar", ["Close"] = "Fechar", ["Open"] = "Abrir", ["Refresh"] = "Atualizar",
        ["Update"] = "Atualizar", ["Copy"] = "Copiar", ["Paste"] = "Colar", ["Clear"] = "Limpar", ["Hide"] = "Ocultar",
        ["Show"] = "Mostrar", ["Loading"] = "Carregando", ["Ready"] = "Pronto", ["Error"] = "Erro", ["Warning"] = "Aviso",
        ["Success"] = "Sucesso", ["Toggle"] = "Alternar", ["Button"] = "Botão", ["Checkbox"] = "Caixa de seleção", ["Slider"] = "Controle deslizante",
        ["Dropdown"] = "Menu suspenso", ["Paragraph"] = "Parágrafo", ["Color Picker"] = "Seletor de cor", ["ColorPicker"] = "Seletor de cor",
        ["Tutorial"] = "Tutorial", ["Tutorials"] = "Tutoriais", ["Example"] = "Exemplo", ["Examples"] = "Exemplos",
        ["Auto Farm"] = "Farm Automático", ["Auto Fish"] = "Pesca Automática", ["Auto Fishing"] = "Pesca Automática", ["Fishing"] = "Pesca",
        ["Fish"] = "Peixe", ["Auto Collect"] = "Coleta Automática", ["Auto Quest"] = "Missão Automática", ["Auto Buy"] = "Compra Automática",
        ["Auto Sell"] = "Venda Automática", ["Auto Race"] = "Corrida Automática", ["Auto Click"] = "Clique Automático", ["Auto Clicker"] = "Clicador Automático",
        ["Auto Rejoin"] = "Reentrada Automática", ["Auto Equip"] = "Equipar Automático", ["Auto Heal"] = "Cura Automática", ["Auto Open"] = "Abertura Automática",
        ["Auto Claim"] = "Resgate Automático", ["Quest"] = "Missão", ["Quests"] = "Missões", ["Event"] = "Evento", ["Events"] = "Eventos",
        ["Shop"] = "Loja", ["Store"] = "Loja", ["Buy"] = "Comprar", ["Sell"] = "Vender", ["Buy All"] = "Comprar Tudo",
        ["Sell All"] = "Vender Tudo", ["Inventory"] = "Inventário", ["Item"] = "Item", ["Items"] = "Itens", ["Weapon"] = "Arma",
        ["Weapons"] = "Armas", ["Knife"] = "Faca", ["Melee"] = "Corpo a Corpo", ["Skins"] = "Skins", ["Skin Changer"] = "Trocador de Skin",
        ["Effect"] = "Efeito", ["Effects"] = "Efeitos", ["Garage"] = "Garagem", ["Race"] = "Corrida", ["Races"] = "Corridas",
        ["Car"] = "Carro", ["Cars"] = "Carros", ["Vehicle"] = "Veículo", ["Vehicles"] = "Veículos", ["Teleport"] = "Teleporte",
        ["Teleports"] = "Teleportes", ["Teleport To"] = "Teleportar para", ["Location"] = "Local", ["Locations"] = "Locais", ["Map"] = "Mapa",
        ["World"] = "Mundo", ["Island"] = "Ilha", ["Islands"] = "Ilhas", ["Reward"] = "Recompensa", ["Rewards"] = "Recompensas",
        ["Collect"] = "Coletar", ["Boost"] = "Impulso", ["Boosts"] = "Impulsos", ["Notification"] = "Notificação", ["Notifications"] = "Notificações",
        ["Theme"] = "Tema", ["Language"] = "Idioma", ["Keybind"] = "Atalho", ["Keybinds"] = "Atalhos", ["Color"] = "Cor",
        ["Colors"] = "Cores", ["Transparency"] = "Transparência", ["Size"] = "Tamanho", ["Range"] = "Alcance", ["Distance"] = "Distância",
        ["Delay"] = "Atraso", ["Amount"] = "Quantidade", ["Value"] = "Valor", ["Mode"] = "Modo", ["Type"] = "Tipo",
        ["Target"] = "Alvo", ["Targets"] = "Alvos", ["Radius"] = "Raio", ["Speed"] = "Velocidade", ["Walk Speed"] = "Velocidade de Caminhada",
        ["Jump Power"] = "Força do Pulo", ["Jump"] = "Pulo", ["Infinite Jump"] = "Pulo Infinito", ["Fly"] = "Voar", ["Gravity"] = "Gravidade",
        ["Health"] = "Vida", ["Money"] = "Dinheiro", ["Cash"] = "Dinheiro", ["Coins"] = "Moedas", ["Level"] = "Nível",
        ["Experience"] = "Experiência", ["Stats"] = "Estatísticas", ["Statistics"] = "Estatísticas", ["Player"] = "Jogador", ["Players"] = "Jogadores",
        ["Character"] = "Personagem", ["Movement"] = "Movimento", ["Combat"] = "Combate", ["Visuals"] = "Visuais", ["Visual"] = "Visual",
        ["Server"] = "Servidor", ["Server Hop"] = "Trocar de Servidor", ["Rejoin"] = "Reentrar", ["Performance"] = "Desempenho", ["FPS Boost"] = "Aumento de FPS",
        ["Optimization"] = "Otimização", ["Graphics"] = "Gráficos", ["Lighting"] = "Iluminação", ["Time"] = "Tempo", ["Day"] = "Dia",
        ["Night"] = "Noite", ["Weather"] = "Clima", ["Fog"] = "Neblina", ["Sky"] = "Céu", ["Debug"] = "Depuração",
        ["Developer"] = "Desenvolvedor", ["Luck"] = "Sorte", ["Potion"] = "Poção", ["Potions"] = "Poções", ["Craft"] = "Criar",
        ["Crafting"] = "Criação", ["Enemy"] = "Inimigo", ["Enemies"] = "Inimigos", ["Boss"] = "Chefe", ["Bosses"] = "Chefes",
        ["Pet"] = "Pet", ["Pets"] = "Pets", ["Profile"] = "Perfil", ["Profiles"] = "Perfis", ["Unlock"] = "Desbloquear",
        ["Lock"] = "Bloquear", ["Unlock All"] = "Desbloquear Tudo", ["Minimum"] = "Mínimo", ["Maximum"] = "Máximo", ["Minimum Time"] = "Tempo Mínimo"
    },
    es = {
        ["Main"] = "Principal", ["Home"] = "Inicio", ["General"] = "General", ["Settings"] = "Configuración", ["Configuration"] = "Configuración",
        ["Options"] = "Opciones", ["Misc"] = "Varios", ["Miscellaneous"] = "Varios", ["Other"] = "Otros", ["Tools"] = "Herramientas",
        ["Utilities"] = "Utilidades", ["Utility"] = "Utilidad", ["Info"] = "Información", ["Information"] = "Información", ["About"] = "Acerca de",
        ["Credits"] = "Créditos", ["Status"] = "Estado", ["Search"] = "Buscar", ["Search..."] = "Buscar...", ["Select"] = "Seleccionar",
        ["Select..."] = "Seleccionar...", ["No results found"] = "No se encontraron resultados", ["None"] = "Ninguno", ["Selected"] = "Seleccionado",
        ["Enable"] = "Activar", ["Enabled"] = "Activado", ["Disable"] = "Desactivar", ["Disabled"] = "Desactivado", ["Start"] = "Iniciar",
        ["Stop"] = "Detener", ["Pause"] = "Pausar", ["Resume"] = "Continuar", ["Reset"] = "Restablecer", ["Save"] = "Guardar",
        ["Load"] = "Cargar", ["Delete"] = "Eliminar", ["Remove"] = "Quitar", ["Add"] = "Añadir", ["Apply"] = "Aplicar",
        ["Cancel"] = "Cancelar", ["Confirm"] = "Confirmar", ["Close"] = "Cerrar", ["Open"] = "Abrir", ["Refresh"] = "Actualizar",
        ["Update"] = "Actualizar", ["Copy"] = "Copiar", ["Paste"] = "Pegar", ["Clear"] = "Limpiar", ["Hide"] = "Ocultar",
        ["Show"] = "Mostrar", ["Loading"] = "Cargando", ["Ready"] = "Listo", ["Error"] = "Error", ["Warning"] = "Advertencia",
        ["Success"] = "Éxito", ["Toggle"] = "Alternar", ["Button"] = "Botón", ["Checkbox"] = "Casilla de verificación", ["Slider"] = "Deslizador",
        ["Dropdown"] = "Menú desplegable", ["Paragraph"] = "Párrafo", ["Color Picker"] = "Selector de color", ["ColorPicker"] = "Selector de color",
        ["Tutorial"] = "Tutorial", ["Tutorials"] = "Tutoriales", ["Example"] = "Ejemplo", ["Examples"] = "Ejemplos",
        ["Auto Farm"] = "Farmeo Automático", ["Auto Fish"] = "Pesca Automática", ["Auto Fishing"] = "Pesca Automática", ["Fishing"] = "Pesca",
        ["Fish"] = "Pez", ["Auto Collect"] = "Recolección Automática", ["Auto Quest"] = "Misión Automática", ["Auto Buy"] = "Compra Automática",
        ["Auto Sell"] = "Venta Automática", ["Auto Race"] = "Carrera Automática", ["Auto Click"] = "Clic Automático", ["Auto Clicker"] = "Autoclicker",
        ["Auto Rejoin"] = "Reingreso Automático", ["Auto Equip"] = "Equipar Automático", ["Auto Heal"] = "Curación Automática", ["Auto Open"] = "Apertura Automática",
        ["Auto Claim"] = "Reclamo Automático", ["Quest"] = "Misión", ["Quests"] = "Misiones", ["Event"] = "Evento", ["Events"] = "Eventos",
        ["Shop"] = "Tienda", ["Store"] = "Tienda", ["Buy"] = "Comprar", ["Sell"] = "Vender", ["Buy All"] = "Comprar Todo",
        ["Sell All"] = "Vender Todo", ["Inventory"] = "Inventario", ["Item"] = "Objeto", ["Items"] = "Objetos", ["Weapon"] = "Arma",
        ["Weapons"] = "Armas", ["Knife"] = "Cuchillo", ["Melee"] = "Cuerpo a Cuerpo", ["Skins"] = "Skins", ["Skin Changer"] = "Cambiador de Skin",
        ["Effect"] = "Efecto", ["Effects"] = "Efectos", ["Garage"] = "Garaje", ["Race"] = "Carrera", ["Races"] = "Carreras",
        ["Car"] = "Auto", ["Cars"] = "Autos", ["Vehicle"] = "Vehículo", ["Vehicles"] = "Vehículos", ["Teleport"] = "Teletransporte",
        ["Teleports"] = "Teletransportes", ["Teleport To"] = "Teletransportar a", ["Location"] = "Ubicación", ["Locations"] = "Ubicaciones", ["Map"] = "Mapa",
        ["World"] = "Mundo", ["Island"] = "Isla", ["Islands"] = "Islas", ["Reward"] = "Recompensa", ["Rewards"] = "Recompensas",
        ["Collect"] = "Recolectar", ["Boost"] = "Impulso", ["Boosts"] = "Impulsos", ["Notification"] = "Notificación", ["Notifications"] = "Notificaciones",
        ["Theme"] = "Tema", ["Language"] = "Idioma", ["Keybind"] = "Atajo", ["Keybinds"] = "Atajos", ["Color"] = "Color",
        ["Colors"] = "Colores", ["Transparency"] = "Transparencia", ["Size"] = "Tamaño", ["Range"] = "Alcance", ["Distance"] = "Distancia",
        ["Delay"] = "Retraso", ["Amount"] = "Cantidad", ["Value"] = "Valor", ["Mode"] = "Modo", ["Type"] = "Tipo",
        ["Target"] = "Objetivo", ["Targets"] = "Objetivos", ["Radius"] = "Radio", ["Speed"] = "Velocidad", ["Walk Speed"] = "Velocidad de Caminata",
        ["Jump Power"] = "Fuerza de Salto", ["Jump"] = "Salto", ["Infinite Jump"] = "Salto Infinito", ["Fly"] = "Volar", ["Gravity"] = "Gravedad",
        ["Health"] = "Vida", ["Money"] = "Dinero", ["Cash"] = "Efectivo", ["Coins"] = "Monedas", ["Level"] = "Nivel",
        ["Experience"] = "Experiencia", ["Stats"] = "Estadísticas", ["Statistics"] = "Estadísticas", ["Player"] = "Jugador", ["Players"] = "Jugadores",
        ["Character"] = "Personaje", ["Movement"] = "Movimiento", ["Combat"] = "Combate", ["Visuals"] = "Visuales", ["Visual"] = "Visual",
        ["Server"] = "Servidor", ["Server Hop"] = "Cambiar de Servidor", ["Rejoin"] = "Reingresar", ["Performance"] = "Rendimiento", ["FPS Boost"] = "Aumento de FPS",
        ["Optimization"] = "Optimización", ["Graphics"] = "Gráficos", ["Lighting"] = "Iluminación", ["Time"] = "Tiempo", ["Day"] = "Día",
        ["Night"] = "Noche", ["Weather"] = "Clima", ["Fog"] = "Niebla", ["Sky"] = "Cielo", ["Debug"] = "Depuración",
        ["Developer"] = "Desarrollador", ["Luck"] = "Suerte", ["Potion"] = "Poción", ["Potions"] = "Pociones", ["Craft"] = "Fabricar",
        ["Crafting"] = "Fabricación", ["Enemy"] = "Enemigo", ["Enemies"] = "Enemigos", ["Boss"] = "Jefe", ["Bosses"] = "Jefes",
        ["Pet"] = "Mascota", ["Pets"] = "Mascotas", ["Profile"] = "Perfil", ["Profiles"] = "Perfiles", ["Unlock"] = "Desbloquear",
        ["Lock"] = "Bloquear", ["Unlock All"] = "Desbloquear Todo", ["Minimum"] = "Mínimo", ["Maximum"] = "Máximo", ["Minimum Time"] = "Tiempo Mínimo"
    }
}

local FOLD_MAP = {}
for base, letters in pairs({a = "àáâãäå", c = "ç", e = "èéêë", i = "ìíîï", n = "ñ", o = "òóôõö", u = "ùúûü", y = "ý"}) do
    for _, code in utf8.codes(letters) do
        FOLD_MAP[utf8.char(code)] = base
        FOLD_MAP[utf8.char(code - 32)] = base
    end
end
FOLD_MAP[utf8.char(255)] = "y"

function Locale.GetId()
    local ok, id = pcall(function()
        return LocalizationService.RobloxLocaleId
    end)
    if ok and type(id) == "string" and id ~= "" then
        return string.lower(id)
    end
    local ok2, id2 = pcall(function()
        return Players.LocalPlayer.LocaleId
    end)
    if ok2 and type(id2) == "string" and id2 ~= "" then
        return string.lower(id2)
    end
    return "en-us"
end

function Locale.GetLang()
    local lang = Locale.Lang
    if lang then
        return lang
    end
    lang = string.match(Locale.GetId(), "^([^%-_]+)") or "en"
    Locale.Lang = lang
    return lang
end

function Locale.SetLang(lang)
    local code = nil
    if type(lang) == "string" then
        code = string.match(string.lower(lang), "^([^%-_]+)")
    end
    Locale.Lang = code
    Locale.Refresh()
end

function Locale.Is(lang)
    return Locale.GetLang() == string.lower(tostring(lang))
end

function Locale.T(key)
    local set = LOCALE_STRINGS[Locale.GetLang()] or LOCALE_STRINGS.en
    return set[key] or LOCALE_STRINGS.en[key] or key
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

function Locale.Fold(text)
    text = string.lower(text)
    if string.find(text, "\195", 1, true) then
        text = string.gsub(text, "\195[\128-\191]", FOLD_MAP)
    end
    return text
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

    for key, value in pairs(LOCALE_WORDS[lang] or {}) do
        put(key, value)
    end
    for key, value in pairs(Locale.Custom[lang] or {}) do
        put(key, value)
    end

    if count == 0 then
        Locale.States[lang] = false
        return nil
    end

    state = {Index = index, Max = longest, Cache = {}, Miss = {}, MissCount = 0}
    Locale.States[lang] = state
    return state
end

function Locale.IsActive()
    return Locale.State(Locale.GetLang()) ~= nil
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

    local rules = LOCALE_PATTERNS[lang]
    if rules then
        for _, rule in ipairs(rules) do
            local replaced, count = string.gsub(text, rule[1], rule[2])
            if count > 0 then
                return replaced
            end
        end
    end

    local words = {}
    for first, _, after in string.gmatch(text, "()(%a[%w']*)()") do
        words[#words + 1] = {first, after - 1}
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

function Locale.Translate(text)
    if type(text) ~= "string" or text == "" then
        return text
    end
    local lang = Locale.GetLang()
    local state = Locale.State(lang)
    if not state or not string.find(text, "%a") then
        return text
    end

    local hit = state.Cache[text]
    if hit then
        return hit
    end
    if state.Miss[text] then
        return text
    end

    local result = Locale.Resolve(state, text, lang)
    if result ~= text then
        state.Cache[text] = result
    else
        if state.MissCount >= 1500 then
            state.Miss = {}
            state.MissCount = 0
        end
        state.Miss[text] = true
        state.MissCount = state.MissCount + 1
    end
    return result
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

    local record = {Source = instance[property], Applied = nil, Transform = transform}
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
    local entry = {Done = false}
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

-- // Notificação
local Notify = {
    Config = {
        GuiName = "EcoHubNotification",
        Width = 320,
        Margin = 20,
        Radius = 10,
        Duration = 6,
        Icon = "rbxassetid://10747384394",
        TitleSize = 16,
        DescriptionSize = 14,
        NameSize = 12,
        Font = Enum.Font.Arcade,
        TweenIn = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        TweenOut = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
        HoverInfo = TweenInfo.new(0.15),
        PopInfo = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    },
    Theme = {
        Panel = Color3.fromRGB(14, 14, 17),
        PanelTop = Color3.fromRGB(32, 32, 38),
        Line = Color3.fromRGB(40, 40, 46),
        Text = Color3.fromRGB(255, 255, 255),
        Muted = Color3.fromRGB(150, 150, 162),
        Error = Color3.fromRGB(255, 85, 85)
    },
    State = {Gui = nil, Container = nil, Item = nil}
}

function Notify.HiddenX()
    return Notify.Config.Width + Notify.Config.Margin + 20
end

function Notify.Build()
    local state = Notify.State
    local config = Notify.Config
    if state.Gui and state.Gui.Parent and state.Container and state.Container.Parent then
        return
    end
    if state.Gui then
        pcall(state.Gui.Destroy, state.Gui)
    end
    state.Item = nil
    local old = PlayerGui:FindFirstChild(config.GuiName)
    if old then
        old:Destroy()
    end
    local gui = Util.Create("ScreenGui", {
        Name = config.GuiName,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 999999,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, PlayerGui)
    state.Gui = gui
    state.Container = Util.Create("Frame", {
        Name = "Container",
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -(config.Width + config.Margin), 0, config.Margin),
        Size = UDim2.new(0, config.Width, 1, -config.Margin * 2)
    }, gui)
end

function Notify.Label(parent, text, size, color, wrapped, order)
    return Util.Create("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Text = text,
        Visible = text ~= "",
        Font = Notify.Config.Font,
        TextSize = size,
        TextColor3 = color,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = wrapped,
        TextTruncate = wrapped and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd,
        RichText = false,
        LineHeight = 1.1,
        LayoutOrder = order
    }, parent)
end

function Notify.Start(item)
    if item.Timer then
        item.Timer:Cancel()
    end
    item.Fill.Size = UDim2.fromScale(1, 1)
    local tween = TweenService:Create(item.Fill, TweenInfo.new(Notify.Config.Duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 1, 0)
    })
    item.Timer = tween
    tween.Completed:Connect(function(state)
        if state == Enum.PlaybackState.Completed and item.Timer == tween then
            Notify.Remove(item)
        end
    end)
    tween:Play()
    if item.Hover then
        tween:Pause()
    end
end

function Notify.Remove(item, instant)
    if not item or item.Closed then
        return
    end
    item.Closed = true
    local state = Notify.State
    if state.Item == item then
        state.Item = nil
    end
    if item.Timer then
        item.Timer:Cancel()
        item.Timer = nil
    end
    if item.Tween then
        item.Tween:Cancel()
    end
    local frame = item.Frame
    if not frame.Parent then
        return
    end
    if instant then
        frame:Destroy()
        return
    end
    local out = Util.Tween(frame, Notify.Config.TweenOut, {Position = UDim2.new(0, Notify.HiddenX(), 1, 0)})
    out.Completed:Connect(function()
        frame:Destroy()
    end)
end

function Notify.Create(title, description, key)
    local config = Notify.Config
    local theme = Notify.Theme
    local color = theme.Error
    local white = Color3.new(1, 1, 1)
    local black = Color3.new(0, 0, 0)
    local radius = UDim.new(0, config.Radius)

    local card = Util.Create("Frame", {
        Name = "Notification",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, Notify.HiddenX(), 1, 0),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = white,
        BackgroundTransparency = 0.03,
        BorderSizePixel = 0
    }, Notify.State.Container)
    Util.Create("UISizeConstraint", {MinSize = Vector2.new(0, 64)}, card)
    Util.Create("UICorner", {CornerRadius = radius}, card)
    Util.Create("UIGradient", {Color = ColorSequence.new(theme.PanelTop, theme.Panel), Rotation = 90}, card)

    local stroke = Util.Create("UIStroke", {
        Color = white,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, card)
    Util.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, color),
            ColorSequenceKeypoint.new(0.6, color:Lerp(theme.Line, 0.75)),
            ColorSequenceKeypoint.new(1, theme.Line)
        })
    }, stroke)

    local glow = Util.Create("Frame", {
        Name = "Glow",
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1)
    }, card)
    Util.Create("UICorner", {CornerRadius = radius}, glow)
    Util.Create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.76),
            NumberSequenceKeypoint.new(0.55, 0.95),
            NumberSequenceKeypoint.new(1, 1)
        })
    }, glow)

    local hover = Util.Create("Frame", {
        Name = "Hover",
        BackgroundColor3 = white,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1)
    }, card)
    Util.Create("UICorner", {CornerRadius = radius}, hover)

    local iconFrame = Util.Create("Frame", {
        Name = "Icon",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = white,
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 34, 0.5, 0),
        Size = UDim2.fromOffset(32, 32)
    }, card)
    Util.Corner(iconFrame, 9)
    Util.Create("UIGradient", {
        Color = ColorSequence.new(color:Lerp(white, 0.25), color:Lerp(black, 0.35)),
        Rotation = 45
    }, iconFrame)
    Util.Create("UIStroke", {
        Color = color,
        Thickness = 1,
        Transparency = 0.55,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, iconFrame)
    local iconScale = Util.Create("UIScale", {Scale = 0.4}, iconFrame)
    Util.Create("ImageLabel", {
        Name = "Image",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = config.Icon,
        ImageColor3 = color:Lerp(white, 0.35),
        ScaleType = Enum.ScaleType.Fit,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(18, 18)
    }, iconFrame)
    Util.Tween(iconScale, config.PopInfo, {Scale = 1})

    local column = Util.Create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0, 62, 0, 0),
        Size = UDim2.new(1, -76, 0, 0)
    }, card)
    Util.List(column, 2)
    Util.Padding(column, 12, 14, 0, 0)
    Notify.Label(column, Locale.Upper(Locale.T("ErrorLabel")), config.NameSize, color, false, 1).Name = "Name"
    Notify.Label(column, title, config.TitleSize, theme.Text, true, 2).Name = "Title"
    Notify.Label(column, description, config.DescriptionSize, theme.Muted, true, 3).Name = "Description"

    local track = Util.Create("Frame", {
        Name = "Track",
        BackgroundTransparency = 1,
        Visible = false,
        Size = UDim2.new(1, 0, 0, 1)
    }, card)
    local fill = Util.Create("Frame", {
        Name = "Fill",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1)
    }, track)

    local item = {
        Frame = card,
        Fill = fill,
        Key = key,
        Hover = false,
        Closed = false,
        Timer = nil,
        Tween = nil
    }

    local button = Util.Create("TextButton", {
        Name = "Click",
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 10
    }, card)

    button.Activated:Connect(function()
        Notify.Remove(item)
    end)

    button.MouseEnter:Connect(function()
        item.Hover = true
        Util.Tween(hover, config.HoverInfo, {BackgroundTransparency = 0.94})
        local tween = item.Timer
        if tween and tween.PlaybackState == Enum.PlaybackState.Playing then
            tween:Pause()
        end
    end)

    button.MouseLeave:Connect(function()
        item.Hover = false
        Util.Tween(hover, config.HoverInfo, {BackgroundTransparency = 1})
        local tween = item.Timer
        if tween and tween.PlaybackState == Enum.PlaybackState.Paused then
            tween:Play()
        end
    end)

    return item
end

function Notify.Error(title, description)
    title = title ~= nil and tostring(title) or ""
    description = description ~= nil and tostring(description) or ""
    if title == "" and description == "" then
        return
    end
    Notify.Build()
    local state = Notify.State
    local key = title .. "\n" .. description
    local current = state.Item
    if current and not current.Closed then
        if current.Key == key then
            Notify.Start(current)
            return
        end
        Notify.Remove(current, true)
    end
    local item = Notify.Create(title, description, key)
    state.Item = item
    item.Tween = Util.Tween(item.Frame, Notify.Config.TweenIn, {Position = UDim2.new(0, 0, 1, 0)})
    Notify.Start(item)
end

function Notify.Destroy()
    local state = Notify.State
    if state.Item then
        Notify.Remove(state.Item, true)
    end
    if state.Gui then
        pcall(state.Gui.Destroy, state.Gui)
    end
    state.Gui = nil
    state.Container = nil
    state.Item = nil
end

local function Report(title, detail)
    local message = tostring(detail)
    warn("[EcoHub] " .. title .. ": " .. message)
    pcall(Notify.Error, title, message)
end

-- // Salvamento
local Save = {Data = nil, Entry = nil, Key = nil, Name = nil, Dirty = false, Token = 0, Started = false}

function Save.Read()
    if Save.Data then
        return Save.Data
    end
    local data = nil
    if type(isfile) == "function" and type(readfile) == "function" then
        local ok, body = pcall(function()
            if isfile(Config.SaveFile) then
                return readfile(Config.SaveFile)
            end
            return nil
        end)
        if ok and type(body) == "string" and body ~= "" then
            local parsed, decoded = pcall(HttpService.JSONDecode, HttpService, body)
            if parsed and type(decoded) == "table" then
                data = decoded
            end
        end
    end
    data = data or {}
    if type(data.Player) ~= "table" then
        data.Player = {}
    end
    if type(data.Games) ~= "table" then
        data.Games = {}
    end
    Save.Data = data
    Save.Identify()
    return data
end

function Save.Identify()
    local player = Save.Data.Player
    local info = {
        Name = LocalPlayer.Name,
        DisplayName = LocalPlayer.DisplayName,
        UserId = LocalPlayer.UserId
    }
    local changed = false
    for key, value in pairs(info) do
        if player[key] ~= value then
            player[key] = value
            changed = true
        end
    end
    if changed then
        Save.Touch()
    end
end

function Save.Find()
    local data = Save.Read()
    local placeId = tostring(game.PlaceId)
    for name, entry in pairs(data.Games) do
        if type(entry) == "table" and tostring(entry.PlaceId) == placeId then
            return name, entry
        end
    end
    return nil, nil
end

function Save.Class()
    if Save.Entry then
        return Save.Entry
    end
    local data = Save.Read()
    local name, entry = Save.Find()
    if not entry then
        name = Save.Name or ("Place " .. tostring(game.PlaceId))
        if data.Games[name] then
            name = name .. " [" .. tostring(game.PlaceId) .. "]"
        end
        entry = {PlaceId = game.PlaceId, AutoSave = {}}
        data.Games[name] = entry
    end
    if type(entry.AutoSave) ~= "table" then
        entry.AutoSave = {}
    end
    entry.GameId = game.GameId
    entry.LastPlayed = os.time()
    Save.Key = name
    Save.Entry = entry
    Save.Touch()
    return entry
end

function Save.Rename(name)
    local entry = Save.Entry
    if not entry or Save.Key == name then
        return
    end
    local data = Save.Read()
    if data.Games[name] and data.Games[name] ~= entry then
        name = name .. " [" .. tostring(game.PlaceId) .. "]"
        if Save.Key == name then
            return
        end
    end
    data.Games[Save.Key] = nil
    data.Games[name] = entry
    Save.Key = name
    Save.Touch()
end

function Save.Init()
    if Save.Started then
        return
    end
    Save.Started = true
    task.spawn(function()
        local ok, info = pcall(function()
            return MarketplaceService:GetProductInfo(game.PlaceId)
        end)
        if not ok or type(info) ~= "table" or type(info.Name) ~= "string" or info.Name == "" then
            return
        end
        Save.Name = info.Name
        Save.Rename(info.Name)
    end)
end

function Save.Touch()
    Save.Dirty = true
    Save.Token = Save.Token + 1
    local token = Save.Token
    task.delay(Config.SaveDelay, function()
        if Save.Token == token then
            Save.Flush()
        end
    end)
end

function Save.Flush()
    if not Save.Dirty or not Save.Data then
        return
    end
    Save.Dirty = false
    Save.Token = Save.Token + 1
    if type(writefile) ~= "function" then
        return
    end
    local ok, failure = pcall(function()
        writefile(Config.SaveFile, Json.Encode(Save.Data))
    end)
    if not ok then
        Report("Save failed", failure)
    end
end

function Save.Get(key, default)
    local value = Save.Class().AutoSave[tostring(key)]
    if value == nil then
        return default
    end
    return value
end

function Save.Set(key, value)
    Save.Class().AutoSave[tostring(key)] = value
    Save.Touch()
end

function Save.Delete(key)
    Save.Class().AutoSave[tostring(key)] = nil
    Save.Touch()
end

-- // Http
local Http = {}

function Http.Get(url)
    local failure = "request failed"
    local ok, body = pcall(game.HttpGet, game, url)
    if ok and type(body) == "string" and body ~= "" then
        return body
    end
    if not ok then
        failure = tostring(body)
    end

    local requester = nil
    if type(request) == "function" then
        requester = request
    elseif type(http_request) == "function" then
        requester = http_request
    elseif type(syn) == "table" and type(syn.request) == "function" then
        requester = syn.request
    end

    if requester and not string.find(failure, "404", 1, true) then
        local sent, response = pcall(requester, {Url = url, Method = "GET"})
        if sent and type(response) == "table" then
            local status = response.StatusCode or response.Status
            if type(response.Body) == "string" and response.Body ~= "" and (response.Success or status == 200) then
                return response.Body
            end
            failure = "HTTP " .. tostring(status)
        elseif not sent then
            failure = tostring(response)
        end
    end
    error(failure, 0)
end

function Http.Try(urls, rounds)
    rounds = rounds or 2
    local lastError = "not found"
    local retry = false
    for round = 1, rounds do
        retry = false
        for _, url in ipairs(urls) do
            local ok, result = pcall(Http.Get, url)
            if ok then
                return result
            end
            lastError = tostring(result)
            if not string.find(lastError, "404", 1, true) then
                retry = true
            end
        end
        if not retry or round == rounds then
            break
        end
        task.wait(0.4 * round)
    end
    return nil, lastError, not retry
end

function Http.Fetch(urls, rounds)
    local body, failure = Http.Try(urls, rounds)
    if body then
        return body
    end
    error(failure, 0)
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
        List = "https://data.jsdelivr.com/v1/packages/gh/" .. repo .. "@" .. branch .. "?structure=flat"
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
local Icons = {Assets = env.EcoHubIcons, Pending = {}, Loading = false, Failed = -100, Retries = 0}

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
        if not Icons.Loading and os.clock() - Icons.Failed > 10 then
            Icons.Load()
        end
    end
    return icon
end

function Icons.Flush()
    local pending = Icons.Pending
    Icons.Pending = {}
    for _, item in ipairs(pending) do
        if item[1].Parent then
            Icons.Apply(item[1], item[2])
        end
    end
end

function Icons.Load()
    if Icons.Assets or Icons.Loading then
        return
    end
    Icons.Loading = true
    task.spawn(function()
        local failure = "unknown error"
        for attempt = 1, 4 do
            local ok, result = pcall(function()
                return loadstring(Http.Fetch({Config.IconsUrl, Config.IconsCdn}, 1))()
            end)
            if ok and type(result) == "table" and type(result.assets) == "table" then
                Icons.Assets = result.assets
                Icons.Retries = 0
                env.EcoHubIcons = result.assets
                Icons.Loading = false
                Icons.Flush()
                return
            end
            failure = tostring(result)
            task.wait(attempt)
        end
        Icons.Failed = os.clock()
        Icons.Loading = false
        Icons.Retries = Icons.Retries + 1
        local alive = {}
        for _, item in ipairs(Icons.Pending) do
            if item[1].Parent then
                alive[#alive + 1] = item
            end
        end
        Icons.Pending = alive
        Report("Icons failed", failure)
        if Icons.Retries <= 5 then
            task.delay(10 * Icons.Retries, function()
                if not Icons.Assets and not Icons.Loading then
                    Icons.Load()
                end
            end)
        end
    end)
end

-- // Library
local Library = {Window = nil, Locale = Locale}
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
    self.Attempts = {}
    self.Active = 0
    self.Watching = false
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
            local element = job.Element
            task.spawn(function()
                local ok, failure = pcall(element.Build, element, entry, job.Options)
                if not ok then
                    Report("Element failed", tostring(element.Type) .. ": " .. tostring(failure))
                end
            end)
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
    if self.Active == 0 then
        self:_Watch()
    end
end

function ElementRegistry:_RunChunk(source)
    env.Elements = self
    env.Panel = self.Panel
    local chunk, compileError = loadstring(Util.Prepare(source, "local Elements, Panel = ...; "))
    if not chunk then
        error(compileError, 0)
    end
    return chunk(self, self.Panel)
end

function ElementRegistry:_LoadFile(file, optional)
    local names = {file}
    if not string.match(file, "%.luau?$") then
        names = {file .. ".lua", file .. ".luau"}
    end

    local stamp = "?t=" .. tostring(os.time())
    local urls = {}
    for _, candidate in ipairs(names) do
        urls[#urls + 1] = Config.ElementsRaw .. candidate .. stamp
    end
    for _, candidate in ipairs(names) do
        urls[#urls + 1] = Config.ElementsCdn .. candidate
    end

    local source, failure, missing = Http.Try(urls, 2)
    if not source then
        if not optional then
            Report("Element load failed", file .. ": " .. tostring(failure))
        end
        return false, missing, false
    end

    local ran, result = pcall(self._RunChunk, self, source)
    if not ran then
        Report("Element load failed", file .. ": " .. tostring(result))
        return false, false, true
    end
    return true, false, false
end

function ElementRegistry:_LoadRound(files, optional)
    local queue = {}
    for _, file in ipairs(files) do
        local id = string.lower((string.gsub(file, "%.luau?$", "")))
        if not self.Files[id] then
            self.Files[id] = true
            queue[#queue + 1] = {File = file, Id = id}
        end
    end

    local cursor = 0
    local running = 0
    local loaded = 0
    local retryable = 0
    local progress = os.clock()

    local function worker()
        while not self.Destroyed do
            cursor = cursor + 1
            local job = queue[cursor]
            if not job then
                break
            end
            local ok, permanent, broken = self:_LoadFile(job.File, optional)
            if ok then
                loaded = loaded + 1
                self.Attempts[job.Id] = nil
            elseif permanent then
                self.Files[job.Id] = "missing"
            else
                local count = (self.Attempts[job.Id] or 0) + (broken and 1 or 0)
                self.Attempts[job.Id] = count
                if broken and count >= Config.LoadAttempts then
                    self.Files[job.Id] = "broken"
                else
                    self.Files[job.Id] = nil
                    retryable = retryable + 1
                end
            end
            progress = os.clock()
        end
        running = running - 1
    end

    for _ = 1, math.min(Config.MaxParallel, #queue) do
        running = running + 1
        task.spawn(worker)
    end

    while running > 0 and os.clock() - progress < Config.LoadTimeout and not self.Destroyed do
        task.wait(0.1)
    end
    return loaded, #queue, retryable
end

function ElementRegistry:_ParseApi(body)
    local files = {}
    local ok, list = pcall(HttpService.JSONDecode, HttpService, body)
    if ok and type(list) == "table" then
        for _, item in ipairs(list) do
            if type(item) == "table" and item.type == "file" and type(item.name) == "string" then
                if string.match(item.name, "%.luau?$") then
                    files[#files + 1] = item.name
                end
            end
        end
    end
    table.sort(files)
    return files
end

function ElementRegistry:_ParseCdn(body)
    local files = {}
    local ok, data = pcall(HttpService.JSONDecode, HttpService, body)
    if ok and type(data) == "table" and type(data.files) == "table" then
        local prefix = "/" .. Config.ElementsPath .. "/"
        for _, item in ipairs(data.files) do
            local path = type(item) == "table" and item.name
            if type(path) == "string" and string.sub(path, 1, #prefix) == prefix then
                local name = string.sub(path, #prefix + 1)
                if not string.find(name, "/", 1, true) and string.match(name, "%.luau?$") then
                    files[#files + 1] = name
                end
            end
        end
    end
    table.sort(files)
    return files
end

function ElementRegistry:_ListFiles(names)
    if type(names) == "table" then
        local files = {}
        for _, name in ipairs(names) do
            files[#files + 1] = name
        end
        return files, false
    end

    local sources = {
        {Config.ElementsApi, self._ParseApi},
        {Config.ElementsList, self._ParseCdn}
    }
    for _, source in ipairs(sources) do
        local ok, body = pcall(Http.Fetch, {source[1]}, 1)
        if ok then
            local files = source[2](self, body)
            if #files > 0 then
                return files, false
            end
        end
    end

    local files = {}
    for _, name in ipairs(ELEMENT_DEFAULTS) do
        files[#files + 1] = name
    end
    return files, true
end

function ElementRegistry:_WarnPending()
    for key, queue in pairs(self.Pending) do
        local alive = {}
        for _, job in ipairs(queue) do
            if not job.Element.Destroyed then
                alive[#alive + 1] = job
                if not job.Warned then
                    job.Warned = true
                    Report("Element missing", job.Element.Type .. " was not found in " .. Config.ElementsPath)
                end
            end
        end
        if #alive > 0 then
            self.Pending[key] = alive
        else
            self.Pending[key] = nil
        end
    end
end

function ElementRegistry:_HasPending()
    for key, queue in pairs(self.Pending) do
        local alive = {}
        for _, job in ipairs(queue) do
            if not job.Element.Destroyed then
                alive[#alive + 1] = job
            end
        end
        if #alive > 0 then
            self.Pending[key] = alive
        else
            self.Pending[key] = nil
        end
    end
    return next(self.Pending) ~= nil
end

function ElementRegistry:_Watch()
    if self.Watching or self.Destroyed then
        return
    end
    self.Watching = true
    task.spawn(function()
        for attempt = 1, Config.WatchRetries do
            task.wait(Config.WatchDelay * attempt)
            if self.Destroyed or not self:_HasPending() then
                break
            end
            if self.Active == 0 then
                for id, state in pairs(self.Files) do
                    if state == "missing" or state == "broken" then
                        self.Files[id] = nil
                    end
                end
                self.Attempts = {}
                self:_Load(nil, false, true)
            end
        end
        self.Watching = false
    end)
end

function ElementRegistry:_Load(names, force, quiet)
    names = names or env.EcoHubElementList
    if force then
        self.Files = {}
        self.Attempts = {}
    end
    self.Active = self.Active + 1
    task.spawn(function()
        local queued = 0
        local loaded = 0
        local files, optional = self:_ListFiles(names)

        for round = 1, Config.LoadRounds do
            if self.Destroyed then
                break
            end
            local roundLoaded, roundQueued, retryable = self:_LoadRound(files, optional)
            loaded = loaded + roundLoaded
            queued = queued + roundQueued

            local missing = next(self.Pending) ~= nil
            if round == Config.LoadRounds or (retryable == 0 and not (optional and missing)) then
                break
            end

            task.wait(Config.RetryDelay * round)
            if optional and not self.Destroyed then
                files, optional = self:_ListFiles(names)
            end
        end

        self.Active = self.Active - 1
        if self.Destroyed then
            return
        end
        if queued > 0 and loaded == 0 and not quiet then
            Report("Elements failed", "no elements could be loaded, check your connection or the repository")
        end
        if self.Active == 0 then
            if not quiet then
                self:_WarnPending()
            end
            self:_Watch()
        end
    end)
end

-- // Element
local Element = {}
Element.__index = Element

function Element.NameOf(elementType, options)
    return tostring(options.title or options.Title or options.name or options.Name or options.Text or options.Label or elementType)
end

function Element.new(contentSection, elementType, options)
    local self = setmetatable({}, Element)
    local tab = contentSection.Tab

    local container = Util.Create("Frame", {
        Name = elementType,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        LayoutOrder = contentSection.Count,
        Visible = false
    }, contentSection.Holder)
    Util.Corner(container, 8)
    local constraint = Util.Create("UISizeConstraint", {MinSize = Vector2.new(0, 38)}, container)
    Util.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(44, 44, 44)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 28, 28))
        }),
        Rotation = 90
    }, container)

    local border = Util.Create("UIStroke", {Name = "Border", Color = Theme.Border, Thickness = 1}, container)
    local flash = Util.Create("UIStroke", {Name = "Flash", Color = Theme.Active, Thickness = 1.5, Transparency = 1}, container)
    local inset = Util.Create("UIPadding", {Name = "Inset"}, container)

    local deco = Util.Create("Frame", {
        Name = "Hover",
        BackgroundColor3 = Theme.Active,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Visible = false
    }, container)
    Util.Corner(deco, 8)

    if not isTouch then
        container.MouseEnter:Connect(function()
            Util.Tween(deco, Config.TweenInfo, {BackgroundTransparency = 0.94})
            Util.Tween(border, Config.TweenInfo, {Color = Theme.BorderHover})
        end)
        container.MouseLeave:Connect(function()
            Util.Tween(deco, Config.TweenInfo, {BackgroundTransparency = 1})
            Util.Tween(border, Config.TweenInfo, {Color = Theme.Border})
        end)
    end

    local name = Element.NameOf(elementType, options)
    local description = tostring(options.description or options.Description or "")

    local used = contentSection.Used
    used[name] = (used[name] or 0) + 1

    self.Type = elementType
    self.Name = name
    self.Group = contentSection.Name
    self.Description = description
    self.SearchText = ""
    self.SearchVersion = -1
    self.Tab = tab
    self.Section = contentSection
    self.Container = container
    self.Constraint = constraint
    self.Border = border
    self.Flash = flash
    self.Inset = inset
    self.Deco = deco
    self.Calls = {}
    self.Built = false
    self.Building = false
    self.Destroyed = false
    self.Instance = nil
    self.Registry = tab.Window.Elements

    container.Name = name
    return self
end

function Element:GetSearch()
    if self.SearchVersion ~= Locale.Version then
        self.SearchVersion = Locale.Version
        local parts = {self.Name, self.Type, self.Group, self.Tab.Name, self.Description}
        local text = table.concat(parts, " ")
        if Locale.IsActive() then
            for _, part in ipairs(parts) do
                text = text .. " " .. Locale.Translate(part)
            end
        end
        self.SearchText = Locale.Fold(text)
    end
    return self.SearchText
end

function Element:ApplyFrame(frameless)
    local pad = frameless and 0 or 5
    local side = frameless and 0 or 12
    self.Container.BackgroundTransparency = frameless and 1 or 0
    self.Constraint.MinSize = Vector2.new(0, frameless and 0 or 38)
    self.Border.Enabled = not frameless
    self.Inset.PaddingTop = UDim.new(0, pad)
    self.Inset.PaddingBottom = UDim.new(0, pad)
    self.Inset.PaddingLeft = UDim.new(0, side)
    self.Inset.PaddingRight = UDim.new(0, side)
    self.Deco.Position = UDim2.fromOffset(-side, -pad)
    self.Deco.Size = UDim2.new(1, side * 2, 1, pad * 2)
    self.Deco.Visible = not frameless
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

function Element:Build(entry, options, attempt)
    if self.Destroyed or self.Built or self.Building then
        return
    end
    self.Building = true
    attempt = attempt or 1
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

    local existing = {}
    for _, child in ipairs(self.Container:GetChildren()) do
        existing[child] = true
    end

    local ok, result = pcall(entry.Builder, scope, options)
    self.Building = false
    if self.Destroyed then
        return
    end
    if not ok then
        for _, child in ipairs(self.Container:GetChildren()) do
            if not existing[child] then
                child:Destroy()
            end
        end
        if attempt == Config.BuildRetries then
            Report("Element failed", self.Type .. " failed, retrying later: " .. tostring(result))
        end
        if attempt < Config.BuildRetries + Config.BuildLateRetries then
            local delay = attempt < Config.BuildRetries and 0.5 * attempt or Config.BuildLateDelay
            task.delay(delay, function()
                if not self.Destroyed and not self.Built then
                    self:Build(entry, options, attempt + 1)
                    self.Registry:_Changed()
                end
            end)
            return
        end
        Report("Element failed", self.Type .. " could not be built: " .. tostring(result))
        return
    end

    Locale.Attach(self.Container)
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
    self.Used = {}

    local frame = Util.Create("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = #tab.Sections + 1
    }, tab.Scroll)
    Util.List(frame, 6)

    local header = Util.Create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        LayoutOrder = 0
    }, frame)
    Util.Padding(header, 0, 0, 2, 0)
    Util.List(header, 6, {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center
    })

    local title = Util.Create("TextLabel", {
        Name = "Title",
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Theme.Active,
        TextSize = 12,
        Font = Enum.Font.SourceSansBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = 1
    }, header)
    Locale.Bind(title, "Text", Locale.Upper)

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

    local name = Element.NameOf(elementType, options)
    local order = nil
    for _, existing in ipairs(self.Tab.Elements) do
        if existing.Section == self and existing.Type == elementType and existing.Name == name and not existing.Destroyed then
            order = existing.Container.LayoutOrder
            existing:Destroy()
            self.Used[name] = math.max((self.Used[name] or 1) - 1, 0)
            break
        end
    end

    local element = Element.new(self, elementType, options)
    if order then
        element.Container.LayoutOrder = order
    end
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
    self.SearchText = ""
    self.SearchVersion = -1

    local button = Util.Create("TextButton", {
        Name = name,
        Size = UDim2.new(1, 0, 0, Config.TabHeight),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = #sideSection.Tabs + 1
    }, sideSection.Menu)
    Util.Corner(button, 6)
    local scale = Util.Create("UIScale", {Scale = 1}, button)

    local icon = Icons.Create(button, iconName, 16, Theme.TabInactive)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Position = UDim2.new(0, 18, 0.5, 0)
    local iconScale = Util.Create("UIScale", {Scale = 1}, icon)

    local label = Util.Create("TextLabel", {
        Name = "Text",
        Size = UDim2.new(1, -46, 1, 0),
        Position = UDim2.new(0, 36, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Theme.TabInactive,
        TextSize = 14,
        Font = Enum.Font.SourceSans,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, button)
    Locale.Bind(label, "Text")

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
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y
    }, page)
    Util.Padding(scroll, 4, 12, 12, 12)
    Util.List(scroll, 14)
    Util.ScrollArea(scroll)

    self.Button = button
    self.Icon = icon
    self.Label = label
    self.Scale = scale
    self.IconScale = iconScale
    self.Page = page
    self.Scroll = scroll

    local pressed = false
    local function release()
        if not pressed then
            return
        end
        pressed = false
        Util.Tween(scale, Config.TabRelease, {Scale = 1})
    end

    button.InputBegan:Connect(function(input)
        if Util.IsPress(input) then
            pressed = true
            Util.Tween(scale, Config.TabPress, {Scale = 0.94})
        end
    end)
    button.InputEnded:Connect(function(input)
        if Util.IsPress(input) then
            release()
        end
    end)
    window.Maid:Connect(UserInputService.InputEnded, function(input)
        if Util.IsPress(input) then
            release()
        end
    end)
    button.Activated:Connect(function()
        self:Select()
    end)
    button.MouseEnter:Connect(function()
        if isTouch or window.ActiveTab == self then
            return
        end
        Util.Tween(label, Config.TabTween, {TextColor3 = Theme.TabHover})
        Util.Tween(icon, Config.TabTween, {ImageColor3 = Theme.TabHover})
    end)
    button.MouseLeave:Connect(function()
        release()
        self:Style()
    end)

    return self
end

function Tab:GetSearch()
    if self.SearchVersion ~= Locale.Version then
        self.SearchVersion = Locale.Version
        local text = self.Name .. " " .. self.Section.Name
        if Locale.IsActive() then
            text = text .. " " .. Locale.Translate(self.Name) .. " " .. Locale.Translate(self.Section.Name)
        end
        self.SearchText = Locale.Fold(text)
    end
    return self.SearchText
end

function Tab:Style()
    local isActive = self.Window.ActiveTab == self
    local color = isActive and Theme.TabActive or Theme.TabInactive
    Util.Tween(self.Button, Config.TabTween, {BackgroundTransparency = isActive and Config.TabFillTransparency or 1})
    Util.Tween(self.Label, Config.TabTween, {TextColor3 = color})
    Util.Tween(self.Icon, Config.TabTween, {ImageColor3 = color})
end

function Tab:Pop()
    self.IconScale.Scale = 0.65
    Util.Tween(self.IconScale, Config.TabPop, {Scale = 1})
    self.Button.BackgroundTransparency = 0.05
end

function Tab:Select()
    self:Pop()
    self.Window:SelectTab(self)
    self:Style()
end

function Tab:CreateSection(name)
    name = tostring(name or "Section")
    for _, existing in ipairs(self.Sections) do
        if existing.Name == name then
            return existing
        end
    end
    local section = ContentSection.new(self, name)
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
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = 0
    }, frame)
    Util.Padding(labelButton, 0, 0, 10, 26)
    Locale.Bind(labelButton, "Text")

    local chevron = Icons.Create(labelButton, "chevron-down", 14, Theme.Dim)
    chevron.AnchorPoint = Vector2.new(1, 0.5)
    chevron.Position = UDim2.new(1, 18, 0.5, 0)

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

function SideSection:_FullHeight()
    return math.max(#self.Tabs * (Config.TabHeight + 2) - 2, 0)
end

function SideSection:SetOpen(state)
    self.Open = state
    Util.Tween(self.Chevron, Config.TweenInfo, {Rotation = state and 0 or -90})
    self:_Animate()
end

function SideSection:_Animate()
    local menu = self.Menu
    local full = math.max(menu.AbsoluteSize.Y, self:_FullHeight())

    self.Token = self.Token + 1
    local token = self.Token
    menu.AutomaticSize = Enum.AutomaticSize.None

    if self.Open then
        menu.Visible = true
        local tween = Util.Tween(menu, Config.TweenInfo, {Size = UDim2.new(1, 0, 0, self:_FullHeight())})
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
    if self.Open then
        self.Menu.Visible = true
    end
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
    self.RenderId = 0
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
        ClipsDescendants = true,
        ZIndex = 21
    }, main)
    Util.Corner(frame, 10)
    Util.Stroke(frame, Theme.Border, 1)
    Util.Create("UISizeConstraint", {MaxSize = Vector2.new(340, math.huge)}, frame)
    local scale = Util.Create("UIScale", {Scale = 0.96}, frame)

    local inputRow = Util.Create("Frame", {
        Name = "InputRow",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        ClipsDescendants = true
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
        PlaceholderText = Locale.T("SearchPrompt"),
        PlaceholderColor3 = Theme.Placeholder,
        TextColor3 = Theme.Text,
        TextSize = 14,
        Font = Enum.Font.SourceSans,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ClipsDescendants = true,
        TextWrapped = false,
        MultiLine = false
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
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ClipsDescendants = true
    }, frame)
    Util.Padding(list, 4, 4, 4, 4)
    local layout = Util.List(list, 2)
    Util.ScrollArea(list)

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
        local text = input.Text
        local clean = (string.gsub(text, "%c", " "))
        local length = utf8.len(clean) or #clean
        if length > Config.MaxQuery then
            local cut = utf8.offset(clean, Config.MaxQuery + 1)
            clean = cut and string.sub(clean, 1, cut - 1) or string.sub(clean, 1, Config.MaxQuery)
        end
        if clean ~= text then
            input.Text = clean
            return
        end
        if not self.IsOpen then
            return
        end
        self.RenderId = self.RenderId + 1
        local id = self.RenderId
        task.delay(0.06, function()
            if self.IsOpen and self.RenderId == id then
                self:Render(self:_Query())
            end
        end)
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
    local text = Locale.Fold(self.Input.Text)
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
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = order
    }, self.List)
    Util.Padding(label, 0, 0, 8, 8)
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
        ClipsDescendants = true,
        LayoutOrder = order
    }, self.List)
    Util.Corner(button, 6)

    local icon = Icons.Create(button, data.Icon, 16, Theme.Inactive)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.Position = UDim2.new(0, 8, 0.5, 0)

    local hint = Util.Create("Frame", {
        Name = "Hint",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0.4, 0, 0, 16),
        BackgroundTransparency = 1,
        ClipsDescendants = true
    }, button)
    Util.List(hint, 4, {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center
    })

    local trail = data.Trail
    for i, part in ipairs(trail) do
        Util.Create("TextLabel", {
            Name = "Part" .. i,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = tostring(part),
            TextColor3 = Theme.Dim,
            TextSize = 12,
            Font = Enum.Font.SourceSans,
            LayoutOrder = i * 2 - 1
        }, hint)
        if i < #trail then
            local separator = Icons.Create(hint, "chevron-right", 12, Theme.Dim)
            separator.Name = "Sep" .. i
            separator.LayoutOrder = i * 2
        end
    end

    Util.Create("TextLabel", {
        Name = "Text",
        Size = UDim2.new(0.6, -44, 1, 0),
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
        local sectionName = Locale.Translate(section.Name)
        for _, tab in ipairs(section.Tabs) do
            local tabName = Locale.Translate(tab.Name)
            local tabMatch = query ~= "" and Util.Contains(tab:GetSearch(), query)
            local rows = {}

            if query == "" or tabMatch then
                rows[#rows + 1] = {Kind = "tab", Name = tabName, Icon = tab.IconName, Trail = {sectionName}, Tab = tab}
            end
            for _, element in ipairs(tab.Elements) do
                if element.Built and (query == "" or tabMatch or Util.Contains(element:GetSearch(), query)) then
                    rows[#rows + 1] = {
                        Kind = "element",
                        Name = Locale.Translate(element.Name),
                        Icon = ELEMENT_ICONS[Util.ResolveKey(element.Type)] or "box",
                        Trail = {Locale.Translate(element.Group)},
                        Element = element
                    }
                end
            end

            if #rows > 0 then
                groups = groups + 1
                if groups > 1 then
                    order = order + 1
                    self:_CreateSeparator(order)
                end
                order = order + 1
                self:_CreateHeading(order, tabName)
                for _, row in ipairs(rows) do
                    order = order + 1
                    self:_CreateRow(order, row)
                end
            end
        end
    end

    if groups == 0 then
        Util.Create("TextLabel", {
            Name = "Empty",
            Size = UDim2.new(1, 0, 0, 48),
            BackgroundTransparency = 1,
            Text = Locale.T("NoResults"),
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
    self.RenderId = self.RenderId + 1
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

-- // Features
local Features = {}
Features.__index = Features

function Features.new(window)
    local self = setmetatable({}, Features)
    self.Window = window
    self.Loaded = {}
    self.Order = {}
    self.Loading = {}
    self.Index = nil
    self.IndexLoading = false
    self.IndexFailed = 0
    self.Source = Source.Build(Config.Repo, Config.Branch, Config.FeaturesPath)
    self.Config = {
        Retries = 3,
        MaxParallel = 4,
        MaxSize = 1048576,
        Timeout = 45,
        RunTimeout = 15
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

function Features._ParseTree(body, prefix)
    local files = {}
    local ok, data = pcall(HttpService.JSONDecode, HttpService, body)
    if ok and type(data) == "table" and type(data.tree) == "table" then
        for _, item in ipairs(data.tree) do
            if type(item) == "table" and item.type == "blob" and type(item.path) == "string" then
                if string.sub(item.path, 1, #prefix) == prefix then
                    local rel = string.sub(item.path, #prefix + 1)
                    if rel ~= "" and string.match(rel, "%.luau?$") then
                        files[#files + 1] = rel
                    end
                end
            end
        end
    end
    return files
end

function Features._ParseFlat(body, prefix)
    local files = {}
    local ok, data = pcall(HttpService.JSONDecode, HttpService, body)
    if ok and type(data) == "table" and type(data.files) == "table" then
        local full = "/" .. prefix
        for _, item in ipairs(data.files) do
            local path = type(item) == "table" and item.name
            if type(path) == "string" and string.sub(path, 1, #full) == full then
                local rel = string.sub(path, #full + 1)
                if rel ~= "" and string.match(rel, "%.luau?$") then
                    files[#files + 1] = rel
                end
            end
        end
    end
    return files
end

function Features:_BuildIndex()
    local source = self.Source
    local files = {}

    local ok, body = pcall(Http.Fetch, {source.Tree}, 1)
    if ok then
        files = Features._ParseTree(body, source.Prefix)
    end
    if #files == 0 then
        ok, body = pcall(Http.Fetch, {source.List}, 1)
        if ok then
            files = Features._ParseFlat(body, source.Prefix)
        end
    end
    if #files == 0 then
        return nil
    end

    table.sort(files, function(a, b)
        return string.lower(a) < string.lower(b)
    end)

    local index = {Files = {}, ByPath = {}, ByStem = {}, Folders = {}}
    for _, rel in ipairs(files) do
        local stripped = string.gsub(rel, "%.luau?$", "")
        local key = string.lower(stripped)
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

function Features:_LoadIndex(force)
    if self.Index and not force then
        return self.Index
    end
    if self.IndexLoading then
        local waited = 0
        while self.IndexLoading and waited < self.Config.Timeout do
            task.wait(0.05)
            waited = waited + 0.05
        end
        return self.Index
    end
    if not force and self.IndexFailed > 0 and os.clock() - self.IndexFailed < 30 then
        return nil
    end

    self.IndexLoading = true
    local ok, index = pcall(self._BuildIndex, self)
    self.IndexLoading = false

    if ok and index then
        self.Index = index
        self.IndexFailed = 0
    else
        if not ok then
            Report("Feature index failed", index)
        end
        self.IndexFailed = os.clock()
    end
    return self.Index
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
    text = string.gsub(text, "%.luau?$", "")
    return text
end

function Features:_Job(rel)
    local source = self.Source
    local stripped = string.gsub(rel, "%.luau?$", "")
    local stamp = "?t=" .. tostring(os.time())
    return {
        Key = string.lower(stripped),
        Path = stripped,
        Name = string.match(stripped, "([^/]+)$") or stripped,
        Urls = {source.Raw .. rel .. stamp, source.Cdn .. rel}
    }
end

function Features:_Resolve(name)
    local original = string.gsub(tostring(name), "^%s+", "")
    original = string.gsub(original, "%s+$", "")

    if string.match(original, "^https?://") then
        local raw = Features._ToRaw(original)
        local clean = string.match(raw, "^[^%?#]+") or raw
        local display = string.match(clean, "([^/]+)%.luau?$") or string.match(clean, "([^/]+)$") or clean
        return {{Key = string.lower(clean), Path = clean, Name = display, Urls = {raw}}}
    end

    local clean = self:_Normalize(original)
    if clean == "" then
        return nil, "empty feature name"
    end
    local lowered = string.lower(clean)

    local index = self:_LoadIndex()
    if index then
        local rel = index.ByPath[lowered] or index.ByStem[lowered]
        if rel then
            return {self:_Job(rel)}
        end
        if index.Folders[lowered] then
            local jobs = {}
            local folder = lowered .. "/"
            for _, file in ipairs(index.Files) do
                if string.sub(string.lower(file), 1, #folder) == folder then
                    jobs[#jobs + 1] = self:_Job(file)
                end
            end
            return jobs
        end
        if string.sub(original, -1) == "/" then
            return nil, "not found in " .. self.Source.Path
        end
    end

    if string.sub(original, -1) == "/" then
        return nil, "loading a folder needs the GitHub index"
    end

    local source = self.Source
    local stamp = "?t=" .. tostring(os.time())
    local urls = {}
    for _, extension in ipairs({".lua", ".luau"}) do
        urls[#urls + 1] = source.Raw .. clean .. extension .. stamp
    end
    for _, extension in ipairs({".lua", ".luau"}) do
        urls[#urls + 1] = source.Cdn .. clean .. extension
    end
    return {{Key = lowered, Path = clean, Name = string.match(clean, "([^/]+)$") or clean, Urls = urls}}
end

function Features:_Download(job)
    local ok, body = pcall(Http.Fetch, job.Urls, self.Config.Retries)
    if not ok then
        return nil, tostring(body)
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
    return body
end

function Features:_DownloadAll(jobs)
    local sources = {}
    local failures = {}
    local cursor = 0
    local running = 0
    local progress = os.clock()
    local limit = math.max(1, math.min(self.Config.MaxParallel, #jobs))

    local function worker()
        while not self.Window.Destroyed do
            cursor = cursor + 1
            local index = cursor
            local job = jobs[index]
            if not job then
                break
            end
            local body, failure = self:_Download(job)
            sources[index] = body or false
            failures[index] = failure
            progress = os.clock()
        end
        running = running - 1
    end

    for _ = 1, limit do
        running = running + 1
        task.spawn(worker)
    end

    while running > 0 and os.clock() - progress < self.Config.Timeout and not self.Window.Destroyed do
        task.wait(0.05)
    end
    return sources, failures
end

function Features:_Run(job, body)
    if self.Window.Destroyed then
        return false, "window was destroyed"
    end
    local window = self.Window
    local finished = false
    local late = false
    local ok = false
    local result = nil

    task.spawn(function()
        local success, value = pcall(function()
            env.Window = window
            env.Windows = window
            env.Library = Library
            env.Librarys = Library
            local header = "local Window, Library = ...; local Windows, Librarys = Window, Library; "
            local chunk, compileError = loadstring(Util.Prepare(body, header))
            if not chunk then
                error(compileError, 0)
            end
            return chunk(window, Library)
        end)
        ok = success
        result = value
        finished = true
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
            return false, "window was destroyed"
        end
        late = true
        ok = true
        result = nil
    end

    if ok then
        self.Loaded[job.Key] = {Name = job.Name, Path = job.Path, Key = job.Key}
        if not table.find(self.Order, job.Key) then
            self.Order[#self.Order + 1] = job.Key
        end
    end
    return ok, result
end

function Features:_FindLoaded(name)
    local text = string.gsub(tostring(name), "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    local key
    if string.match(text, "^https?://") then
        local raw = Features._ToRaw(text)
        key = string.lower(string.match(raw, "^[^%?#]+") or raw)
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

function Features:_LoadJobs(jobs, options)
    local reload = type(options) == "table" and options.Reload == true
    local outcomes = {}
    local pending = {}
    local first = {}
    local duplicate = {}

    for i, job in ipairs(jobs) do
        outcomes[i] = {Name = job.Name, Success = false}
        if first[job.Key] then
            duplicate[i] = first[job.Key]
        else
            first[job.Key] = i
            if self.Loading[job.Key] then
                local waited = 0
                while self.Loading[job.Key] and waited < self.Config.Timeout do
                    task.wait(0.05)
                    waited = waited + 0.05
                end
            end
            if self.Loaded[job.Key] and not reload then
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

    local list = {}
    for _, i in ipairs(pending) do
        list[#list + 1] = jobs[i]
    end

    local sources, failures = {}, {}
    if #list > 0 then
        local downloaded, result, reasons = pcall(self._DownloadAll, self, list)
        if downloaded then
            sources, failures = result, reasons
        else
            for position = 1, #list do
                failures[position] = tostring(result)
            end
        end
    end

    for position, i in ipairs(pending) do
        local job = jobs[i]
        local body = sources[position]
        local handled, failure = pcall(function()
            if body then
                local ok, result = self:_Run(job, body)
                if ok then
                    outcomes[i].Success = true
                else
                    outcomes[i].Error = tostring(result)
                    Report("Feature failed", job.Name .. ": " .. tostring(result))
                end
            else
                outcomes[i].Error = failures[position] or "download timed out"
                Report("Feature failed", job.Name .. ": " .. tostring(outcomes[i].Error))
            end
        end)
        self.Loading[job.Key] = nil
        if not handled then
            outcomes[i].Error = tostring(failure)
            Report("Feature failed", job.Name .. ": " .. tostring(failure))
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
    local index = self:_LoadIndex()
    if not index then
        Report("Feature index failed", "LoadAllFeatures needs the GitHub index, which could not be loaded")
        return results
    end

    local jobs = {}
    for _, rel in ipairs(index.Files) do
        jobs[#jobs + 1] = self:_Job(rel)
    end
    local outcomes = self:_LoadJobs(jobs, options)
    for i, outcome in ipairs(outcomes) do
        results[jobs[i].Path] = outcome.Success
    end
    return results
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
    end
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
        names[#names + 1] = (string.gsub(rel, "%.luau?$", ""))
    end
    return names
end

function Features:Refresh()
    return self:_LoadIndex(true) ~= nil
end

function Features:SetSource(url)
    local source = Source.Parse(url)
    if not source then
        Report("Invalid source", "features source: " .. tostring(url))
        return false
    end
    self.Source = source
    self.Index = nil
    self.IndexFailed = 0
    return true
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
    self.SidebarWidth = Config.SidebarWidth
    self.Features = Features.new(self)
    self.FeatureConfig = self.Features.Config
    self.Locale = Locale
    self.Crumbs = nil

    Save.Init()
    self:_BuildMain()
    self:_BuildPanel()
    self.Palette = Palette.new(self)
    self.Maid:Add(Locale.OnChange(function()
        self:_Relocalize()
    end))
    self:_BuildToggle()
    self:_Guard(self.Gui)
    self:_Guard(self.ToggleGui)
    self:_BindInput()
    self:_MakeDraggable(self.Dashboard, self.Main)
    self:_MakeDraggable(self.Header, self.Main)
    self:_BindResize()
    self:_BindToggleDrag()
    self:Configure(config)
    self:_RestoreSize()
    return self
end

function Window:_Relocalize()
    if self.Destroyed then
        return
    end
    self.SearchButton.Text = Locale.T("SearchPlaceholder")
    self.Palette.Input.PlaceholderText = Locale.T("SearchPrompt")
    if self.Crumbs then
        self:_SetBreadcrumb(self.Crumbs)
    end
    self:RefreshSearch()
end

function Window:_Guard(gui)
    self.Maid:Connect(gui.AncestryChanged, function()
        if self.Destroyed or gui.Parent then
            return
        end
        task.defer(function()
            if self.Destroyed or gui.Parent then
                return
            end
            pcall(function()
                gui.Parent = PlayerGui
            end)
        end)
    end)
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
        Size = UDim2.new(0, self.SidebarWidth, 1, 0),
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
        Size = UDim2.new(1, -24, 0, 18),
        Position = UDim2.new(0, 14, 0, 16),
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
        Size = UDim2.new(1, -24, 0, 14),
        Position = UDim2.new(0, 14, 0, 34),
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
    Util.Padding(tabList, 2, 8, 10, 10)
    Util.List(tabList, 8)
    Util.ScrollArea(tabList)

    local contentArea = Util.Create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -(self.SidebarWidth + 1), 1, 0),
        Position = UDim2.new(0, self.SidebarWidth + 1, 0, 0),
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
        BorderSizePixel = 0,
        ClipsDescendants = true
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
        Text = Locale.T("SearchPlaceholder"),
        TextColor3 = Theme.Placeholder,
        TextSize = 13,
        Font = Enum.Font.SourceSans,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, searchFrame)

    local corner = isTouch and 30 or 22
    local handles = {}

    local gripButton = Util.Create("TextButton", {
        Name = "ResizeButton",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 0, 1, 0),
        Size = UDim2.fromOffset(corner, corner),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 11
    }, main)
    local dots = {}
    local step = isTouch and 7 or 5
    local dotSize = isTouch and 3 or 2
    local margin = isTouch and 9 or 6
    for row = 0, 2 do
        for column = 0, 2 do
            if row + column >= 2 then
                local dot = Util.Create("Frame", {
                    Name = "Dot",
                    AnchorPoint = Vector2.new(1, 1),
                    Position = UDim2.new(1, -(margin + (2 - column) * step), 1, -(margin + (2 - row) * step)),
                    Size = UDim2.fromOffset(dotSize, dotSize),
                    BackgroundColor3 = Theme.Dim,
                    BorderSizePixel = 0
                }, gripButton)
                Util.Corner(dot, 1)
                dots[#dots + 1] = dot
            end
        end
    end
    handles[#handles + 1] = {
        Button = gripButton,
        X = true,
        Y = true,
        Paint = function(lit)
            for _, dot in ipairs(dots) do
                Util.Tween(dot, Config.TweenInfo, {BackgroundColor3 = lit and Theme.Active or Theme.Dim})
            end
        end
    }

    self.Gui = gui
    self.Main = main
    self.Sidebar = sidebar
    self.Dashboard = dashboard
    self.TitleText = titleText
    self.SubTitleText = subTitleText
    self.TabList = tabList
    self.ContentArea = contentArea
    self.Header = header
    self.PageHolder = pageHolder
    self.Breadcrumb = breadcrumb
    self.SearchButton = searchButton
    self.ResizeHandles = handles

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

    local function unwrap(owner, first, second, third)
        if rawequal(first, owner) then
            return second, third
        end
        return first, second
    end

    Panel.Header = self.Header
    Panel.PageHolder = self.PageHolder
    Panel.TabList = self.TabList
    Panel.CreateIcon = Icons.Create
    Panel.Locale = Locale

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
    function Panel.Error(first, second, third)
        local title, detail = unwrap(Panel, first, second, third)
        Report(tostring(title or "Error"), tostring(detail or ""))
    end

    local SaveApi = {}
    function SaveApi.Get(first, second, third)
        local key, default = unwrap(SaveApi, first, second, third)
        return Save.Get(key, default)
    end
    function SaveApi.Set(first, second, third)
        local key, value = unwrap(SaveApi, first, second, third)
        Save.Set(key, value)
    end
    function SaveApi.Delete(first, second)
        local key = unwrap(SaveApi, first, second)
        Save.Delete(key)
    end
    Panel.Save = SaveApi

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
    local active = nil
    local hovered = {}
    local startSize = Vector2.zero
    local startMouse = Vector3.zero

    for _, handle in ipairs(self.ResizeHandles) do
        handle.Button.InputBegan:Connect(function(input)
            if active == nil and self.Gui.Enabled and Util.IsPress(input) then
                active = handle
                startSize = self.Main.AbsoluteSize
                startMouse = input.Position
                handle.Paint(true)
            end
        end)
        if not isTouch then
            handle.Button.MouseEnter:Connect(function()
                hovered[handle] = true
                if active == nil then
                    handle.Paint(true)
                end
            end)
            handle.Button.MouseLeave:Connect(function()
                hovered[handle] = nil
                if active ~= handle then
                    handle.Paint(false)
                end
            end)
        end
    end

    self.Maid:Connect(UserInputService.InputEnded, function(input)
        if active and Util.IsPress(input) then
            local finished = active
            active = nil
            finished.Paint(hovered[finished] == true)
            local size = self.Main.AbsoluteSize
            if size ~= startSize then
                Save.Set("WindowSize", {Width = math.floor(size.X), Height = math.floor(size.Y)})
            end
        end
    end)

    self.Maid:Connect(UserInputService.InputChanged, function(input)
        if not active or not Util.IsMove(input) then
            return
        end
        local delta = input.Position - startMouse
        local viewport = Util.GetViewport()
        local maxWidth = math.max(320, math.min(900, viewport.X - 16))
        local maxHeight = math.max(240, math.min(700, viewport.Y - 16))
        local minWidth = math.min(self.SidebarWidth + 300, maxWidth)
        local minHeight = math.min(300, maxHeight)
        local newWidth = startSize.X
        local newHeight = startSize.Y
        if active.X then
            newWidth = math.clamp(startSize.X + delta.X, minWidth, maxWidth)
        end
        if active.Y then
            newHeight = math.clamp(startSize.Y + delta.Y, minHeight, maxHeight)
        end
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

function Window:_RestoreSize()
    local saved = Save.Get("WindowSize")
    if type(saved) == "table" and tonumber(saved.Width) and tonumber(saved.Height) then
        self:_ApplySize(UDim2.fromOffset(tonumber(saved.Width), tonumber(saved.Height)))
    end
end

function Window:_SetBreadcrumb(items)
    if type(items) ~= "table" then
        return
    end
    self.Crumbs = items
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
            Text = Locale.Translate(tostring(text)),
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

function Window:Configure(config, keepLayout)
    config = type(config) == "table" and config or {}
    if config.Title ~= nil then
        self.TitleText.Text = tostring(config.Title)
    end
    if config.SubTitle ~= nil then
        self.SubTitleText.Text = tostring(config.SubTitle)
    end
    if not keepLayout and tonumber(config.SidebarWidth) then
        self:SetSidebarWidth(config.SidebarWidth)
    end
    if not keepLayout and typeof(config.Size) == "UDim2" then
        self:_ApplySize(config.Size)
    end
    if typeof(config.MinimizeKey) == "EnumItem" then
        self.MinimizeKey = config.MinimizeKey
    end
end

function Window:SetSidebarWidth(width)
    width = math.clamp(tonumber(width) or Config.SidebarWidth, 120, 320)
    self.SidebarWidth = width
    self.Sidebar.Size = UDim2.new(0, width, 1, 0)
    self.ContentArea.Size = UDim2.new(1, -(width + 1), 1, 0)
    self.ContentArea.Position = UDim2.new(0, width + 1, 0, 0)
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

    for _, existing in ipairs(section.Tabs) do
        if existing.Name == tabName then
            return existing
        end
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

function Window:Error(title, detail)
    Report(tostring(title or "Error"), tostring(detail or ""))
end

function Window:SetLanguage(lang)
    Locale.SetLang(lang)
end

function Window:GetLanguage()
    return Locale.GetLang()
end

function Window:AddTranslations(languages)
    return Locale.AddMany(languages)
end

function Window:Translate(text)
    return Locale.Translate(tostring(text))
end

function Window:LoadFeature(name, options)
    return self.Features:Load(name, options)
end

function Window:LoadFeatures(list, options)
    return self.Features:LoadMany(list, options)
end

function Window:LoadAllFeatures(options)
    return self.Features:LoadAll(options)
end

function Window:UnloadFeature(name)
    return self.Features:Unload(name)
end

function Window:UnloadAllFeatures()
    return self.Features:UnloadAll()
end

function Window:GetLoadedFeatures()
    return self.Features:GetLoaded()
end

function Window:IsFeatureLoaded(name)
    return self.Features:IsLoaded(name)
end

function Window:ListFeatures()
    return self.Features:List()
end

function Window:RefreshFeatures()
    return self.Features:Refresh()
end

function Window:SetFeaturesSource(url)
    return self.Features:SetSource(url)
end

function Window:SetElementsSource(url)
    local source = Source.Parse(url)
    if not source then
        Report("Invalid source", "elements source: " .. tostring(url))
        return false
    end
    Config.ElementsPath = source.Path
    Config.ElementsApi = "https://api.github.com/repos/" .. source.Repo .. "/contents/" .. source.Path .. "?ref=" .. source.Branch
    Config.ElementsRaw = source.Raw
    Config.ElementsCdn = source.Cdn
    Config.ElementsList = source.List
    return true
end

function Window:ListElements()
    return self.Elements:List()
end

function Window:LoadElements(force)
    self.Elements.Load(nil, force)
end

function Window:Destroy()
    if self.Destroyed then
        return
    end
    self.Destroyed = true
    self.Features:UnloadAll()
    self.Elements.Destroyed = true
    Save.Flush()
    Notify.Destroy()
    self.Maid:Destroy()
    self.Gui:Destroy()
    self.ToggleGui:Destroy()

    env.EcoHubPanel = nil
    env.EcoHubElements = nil
    env.EcoHubDestroy = nil
    if rawequal(env.Window, self) then
        env.Window = nil
        env.Windows = nil
    end
    if Library.Window == self then
        Library.Window = nil
        Library.Windows = nil
        Library.Elements = nil
        Library.FeatureConfig = nil
    end
end

-- // Library API
function Library:CreateWindow(config)
    if not rawequal(self, Library) and config == nil then
        config = self
    end

    local window = Library.Window
    if window and not window.Destroyed then
        window:Configure(config, true)
        return window
    end

    window = Window.new(config)
    Library.Window = window
    Library.Windows = window
    Library.Elements = window.Elements
    Library.FeatureConfig = window.FeatureConfig

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

function Library.SetLanguage(first, second)
    Locale.SetLang(rawequal(first, Library) and second or first)
end

function Library.GetLanguage()
    return Locale.GetLang()
end

function Library.AddTranslations(first, second)
    return Locale.AddMany(rawequal(first, Library) and second or first)
end

function Library.Translate(first, second)
    local text = rawequal(first, Library) and second or first
    return Locale.Translate(tostring(text))
end

-- // Library Features
local FEATURE_METHODS = {
    "LoadFeature",
    "LoadFeatures",
    "LoadAllFeatures",
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
    "SelectTab"
}

for _, method in ipairs(FEATURE_METHODS) do
    Library[method] = function(_, ...)
        local window = Library.Window
        if not window or window.Destroyed then
            Report("Window missing", method .. " needs a window, call CreateWindow first")
            return nil
        end
        return window[method](window, ...)
    end
end

-- // Inicialização
if type(env.EcoHubDestroy) == "function" then
    pcall(env.EcoHubDestroy)
end
for _, name in ipairs({"EcoHub", "EcoHubToggle", "EcoHubNotification"}) do
    local old = PlayerGui:FindFirstChild(name)
    if old then
        old:Destroy()
    end
end

env.EcoHubLibrary = Library
Icons.Load()

return Library