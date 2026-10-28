-- // Tab
local ButtonTab = Window:CreateTab({
    tab = "Button",
    section = "Librarys",
    icon = "mouse-pointer",
})

local ButtonSection = ButtonTab:CreateSection("Button")

-- // Simples
local btn1 = ButtonSection:CreateButton({
    title = "Teleportar",
    callback = function()
        print("clicou")
    end,
})

-- // Com descrição
local btn2 = ButtonSection:CreateButton({
    title = "Resetar Personagem",
    description = "Respawna no spawn inicial",
    callback = function()
        print("resetou")
    end,
})

-- // Desabilitado
local btn3 = ButtonSection:CreateButton({
    title = "Bloqueado",
    disabled = true,
    callback = function()
    end,
})