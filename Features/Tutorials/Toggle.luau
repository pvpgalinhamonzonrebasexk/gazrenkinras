-- // Tab
local ElementsTab = Window:CreateTab({
    tab = "CheckBox",
    section = "Librarys",
    icon = "check-square",
})

local BoxSection = ElementsTab:CreateSection("Checkbox")

-- // Simples
local toggle1 = BoxSection:CreateToggle({
    title = "Wallbang",
    default = false,
    callback = function(state)
        print("Wallbang:", state)
    end,
})

-- // Com descrição
local toggle2 = BoxSection:CreateToggle({
    title = "God Mode",
    description = "Ativa invencibilidade",
    default = false,
    callback = function(state)
        print("God Mode:", state)
    end,
})

-- // Com keybind de teclado
local toggle3 = BoxSection:CreateToggle({
    title = "Speed Hack",
    description = "Aumenta velocidade",
    default = false,
    keybind = Enum.KeyCode.G,
    callback = function(state)
        print("Speed:", state)
    end,
})

-- // Com keybindCallback
local toggle4 = BoxSection:CreateToggle({
    title = "Fly",
    description = "Ativa voo",
    default = false,
    keybind = Enum.KeyCode.F,
    keybindCallback = function(state)
        print("Pressionou F, estado:", state)
    end,
    callback = function(state)
        print("Fly:", state)
    end,
})

-- // Com keybind de mouse
local toggle5 = BoxSection:CreateToggle({
    title = "Aimbot",
    default = false,
    keybind = Enum.UserInputType.MouseButton1,
    callback = function(state)
        print("Aimbot:", state)
    end,
})

local toggle6 = BoxSection:CreateToggle({
    title = "ESP",
    default = false,
    keybind = Enum.UserInputType.MouseButton2,
    callback = function(state)
        print("ESP:", state)
    end,
})

-- // Ativado por padrão
local toggle7 = BoxSection:CreateToggle({
    title = "Auto Farm",
    default = true,
    callback = function(state)
        print("Auto Farm:", state)
    end,
})

-- // Desabilitado
local toggle8 = BoxSection:CreateToggle({
    title = "Bloqueado",
    default = false,
    disabled = true,
    callback = function(state)
    end,
})