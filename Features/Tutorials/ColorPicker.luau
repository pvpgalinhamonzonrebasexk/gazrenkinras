-- // Tab
local ColorTab = Window:CreateTab({
    tab = "ColorPicker",
    section = "Librarys",
    icon = "palette",
})

local ColorSection = ColorTab:CreateSection("ColorPicker")

-- // Simples
local cpBasico = ColorSection:CreateColorPicker({
    title = "Cor Principal",
    default = Color3.fromRGB(68, 120, 255),
    callback = function(color, transparency)
        print("Cor:", color)
    end,
})

-- // Com descrição
local cpDesc = ColorSection:CreateColorPicker({
    title = "Cor do Personagem",
    description = "Escolha a cor do seu personagem",
    default = Color3.fromRGB(255, 80, 80),
    callback = function(color, transparency)
        print("Cor Personagem:", color)
    end,
})

-- // Com transparência
local cpTransparency = ColorSection:CreateColorPicker({
    title = "Cor com Transparência",
    description = "Suporta transparência",
    default = Color3.fromRGB(80, 200, 120),
    transparency = 0.5,
    callback = function(color, transparency)
        print("Cor:", color, "Transparência:", transparency)
    end,
})

-- // Desabilitado
local cpDisabled = ColorSection:CreateColorPicker({
    title = "Bloqueado",
    default = Color3.fromRGB(150, 150, 150),
    disabled = true,
    callback = function(color, transparency)
    end,
})

-- // Completo
local cpCompleto = ColorSection:CreateColorPicker({
    title = "Cor do Time",
    description = "Escolha a cor do seu time",
    default = Color3.fromRGB(68, 120, 255),
    transparency = 0,
    disabled = false,
    callback = function(color, transparency)
        print("Time cor:", color, "alpha:", transparency)
    end,
})