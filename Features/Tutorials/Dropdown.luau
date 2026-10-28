-- // Tab
local DropTab = Window:CreateTab({
    tab = "Dropdown",
    section = "Librarys",
    icon = "list",
})

local DropSection = DropTab:CreateSection("Dropdown")

-- // Simples
local dropBasico = DropSection:CreateDropdown({
    title = "Arma",
    values = { "Espada", "Arco", "Machado" },
    default = "Espada",
    callback = function(value)
        print("Arma:", value)
    end,
})

-- // Com descrição
local dropDesc = DropSection:CreateDropdown({
    title = "Classe",
    description = "Escolha a classe do personagem",
    values = { "Guerreiro", "Mago", "Arqueiro" },
    default = "Guerreiro",
    callback = function(value)
        print("Classe:", value)
    end,
})

-- // Multi seleção
local dropMulti = DropSection:CreateDropdown({
    title = "Efeitos Ativos",
    values = { "Velocidade", "Forca", "Invisibilidade", "Voo" },
    default = { "Velocidade", "Forca" },
    multi = true,
    callback = function(value)
        for efeito, ativo in pairs(value) do
            print(efeito, ativo)
        end
    end,
})

-- // Desabilitado
local dropDisabled = DropSection:CreateDropdown({
    title = "Bloqueado",
    values = { "A", "B", "C" },
    default = "A",
    disabled = true,
    callback = function(value)
    end,
})

-- // Completo
local dropCompleto = DropSection:CreateDropdown({
    title = "Time",
    description = "Escolha seu time",
    values = { "Azul", "Vermelho", "Verde" },
    default = "Azul",
    multi = false,
    disabled = false,
    callback = function(value)
        print("Time:", value)
    end,
})