-- // Tab
local SliderTab = Window:CreateTab({
    tab = "Slider",
    section = "Librarys",
    icon = "sliders",
})

local SliderSection = SliderTab:CreateSection("Slider")

-- // Simples
local sliderBasico = SliderSection:CreateSlider({
    title = "Velocidade",
    min = 0,
    max = 100,
    default = 16,
    callback = function(value)
        print("Velocidade:", value)
    end,
})

-- // Com descrição
local sliderDesc = SliderSection:CreateSlider({
    title = "Dano",
    description = "Multiplicador de dano do jogador",
    min = 1,
    max = 10,
    default = 1,
    callback = function(value)
        print("Dano:", value)
    end,
})

-- // Com sufixo
local sliderSufixo = SliderSection:CreateSlider({
    title = "Volume",
    min = 0,
    max = 100,
    default = 50,
    suffix = "%",
    callback = function(value)
        print("Volume:", value)
    end,
})

-- // Com decimais
local sliderDecimal = SliderSection:CreateSlider({
    title = "Gravidade",
    min = 0,
    max = 1,
    default = 0.5,
    rounding = 2,
    suffix = "x",
    callback = function(value)
        print("Gravidade:", value)
    end,
})

-- // Desabilitado
local sliderDisabled = SliderSection:CreateSlider({
    title = "Bloqueado",
    min = 0,
    max = 100,
    default = 30,
    disabled = true,
    callback = function(value)
    end,
})

-- // Completo
local sliderCompleto = SliderSection:CreateSlider({
    title = "Walk Speed",
    description = "Velocidade de caminhada",
    min = 0,
    max = 500,
    default = 16,
    rounding = 0,
    suffix = " sp",
    disabled = false,
    callback = function(value)
        local character = game.Players.LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = value
        end
    end,
})