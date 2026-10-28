# Librarys

Documentação da library de UI do Ecohub: janela, tabs, sections e todos os elements.

## Índice

1. [Carregar a library](#1-carregar-a-library)
2. [Criar a janela](#2-criar-a-janela)
3. [Tabs e Sections](#3-tabs-e-sections)
4. [Elements](#4-elements)
   - [Toggle](#41-toggle)
   - [Button](#42-button)
   - [Slider](#43-slider)
   - [Dropdown](#44-dropdown)
   - [ColorPicker](#45-colorpicker)
   - [Paragraph](#46-paragraph)
     - [Opções](#461-opções)
     - [Opções do hologram](#462-opções-do-hologram)
     - [Entradas do status](#463-entradas-do-status)
     - [Sem função](#464-sem-função)
     - [Com função](#465-com-função)
     - [Métodos](#466-métodos)
     - [Comportamento](#467-comportamento)
5. [Exemplo completo: aba Status](#5-exemplo-completo-aba-status)
6. [Referência rápida](#6-referência-rápida)

---

## 1. Carregar a library

```lua
-- // Library
local Librarys = loadstring(game:HttpGet("https://raw.githubusercontent.com/pvpgalinhamonzonrebasexk/gazrenkinras/refs/heads/main/Library/Library.lua"))()
```

> Só existe **uma janela** por vez. Executar o script de novo destrói a janela anterior, descarrega as features dela e remove qualquer GUI que tenha sobrado.

---

## 2. Criar a janela

```lua
-- // Window
local Window = Librarys:CreateWindow({
    Title = "Eco Hub",
    SubTitle = "by rip_sheldoohz",
    Size = UDim2.fromOffset(580, 350),
    MinimizeKey = Enum.KeyCode.RightShift,
})
```

| Opção | Tipo | Padrão | Descrição |
|-------|------|--------|-----------|
| `Title` | string | `"UILib"` | Título da janela |
| `SubTitle` | string | `""` | Subtítulo (também aceita `Subtitle`) |
| `Size` | UDim2 | `580 x 460` | Tamanho base, limitado ao tamanho da tela |
| `MinimizeKey` | Enum.KeyCode | `LeftControl` | Tecla que abre e fecha a janela |

No mobile a tecla é ignorada e aparece um botão flutuante arrastável.

### Métodos da janela

| Método | Descrição |
|--------|-----------|
| `Window:CreateTab(opts)` | Cria uma tab |
| `Window:GetTab(nomeOuIndice)` | Retorna uma tab |
| `Window:SelectTab(tab)` | Seleciona uma tab (objeto, nome ou índice) |
| `Window:SetTitle(texto)` | Troca o título |
| `Window:SetSubTitle(texto)` | Troca o subtítulo |
| `Window:SetMinimizeKey(tecla)` | Troca a tecla de minimizar |
| `Window:Toggle()` | Abre ou fecha |
| `Window:SetMinimized(estado)` | Define aberto ou fechado |
| `Window:IsMinimized()` | Retorna se está fechada |
| `Window:ClearSearch()` | Limpa a pesquisa |
| `Window:Destroy()` | Destrói a janela e descarrega as features |

---

## 3. Tabs e Sections

```lua
-- // Tab
local ElementsTab = Window:CreateTab({
    tab = "CheckBox",
    section = "Librarys",
    icon = "check-square",
})

-- // Section
local CheckBoxSection = ElementsTab:CreateSection("Checkbox")
```

| Opção da tab | Descrição |
|--------------|-----------|
| `tab` | Nome que aparece na barra lateral (também aceita `name`) |
| `section` | Título do grupo na barra lateral. Tabs com a mesma `section` ficam juntas |
| `icon` | Nome do ícone lucide, sem o prefixo `lucide-` |

| Método | Descrição |
|--------|-----------|
| `Tab:CreateSection(titulo)` | Cria um bloco dentro da página da tab |
| `Tab:Select()` | Seleciona a tab |
| `Section:SetTitle(texto)` | Troca o título da section |

---

## 4. Elements

Todos os elements aceitam `callback` (ou `Callback`). Erros dentro do callback são capturados e aparecem como notificação, sem derrubar o script.

Se o element tiver `title`, `name`, `text` ou `label`, ele entra automaticamente na pesquisa da janela.

### 4.1 Toggle

```lua
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
```

| Opção | Tipo | Descrição |
|-------|------|-----------|
| `title` | string | Texto principal |
| `description` | string | Texto menor abaixo do título |
| `default` | boolean | Estado inicial |
| `disabled` | boolean | Bloqueia a interação |
| `keybind` | KeyCode ou UserInputType | Atalho que alterna o toggle |
| `keybindCallback` | function(state) | Chamado só quando o atalho é usado |
| `callback` | function(state) | Chamado sempre que o estado muda |

```lua
-- // API Toggle
toggle1:Set(true)
toggle1:Set(false)
toggle1:Toggle()
toggle1:SetTitle("Wallbang ATIVO")
toggle2:SetDescription("Agora com dano 2x")
toggle8:SetDisabled(false)
toggle8:SetDisabled(true)
toggle3:SetKeybind(Enum.KeyCode.H)
toggle3:SetKeybind(Enum.UserInputType.MouseButton2)
toggle3:ClearKeybind()

local estado = toggle1:Get()
local bind = toggle3:GetKeybind()

toggle1:Destroy()
```

---

### 4.2 Button

```lua
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
```

| Opção | Tipo | Descrição |
|-------|------|-----------|
| `title` | string | Texto principal |
| `description` | string | Texto menor |
| `disabled` | boolean | Bloqueia o clique |
| `callback` | function() | Chamado ao clicar |

```lua
-- // API Button
btn1:SetTitle("Novo Titulo")
btn2:SetDescription("Nova descricao")
btn3:SetDisabled(false)
btn1:Fire()
```

---

### 4.3 Slider

```lua
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
```

| Opção | Tipo | Descrição |
|-------|------|-----------|
| `title` | string | Texto principal |
| `description` | string | Texto menor |
| `min` | number | Valor mínimo |
| `max` | number | Valor máximo |
| `default` | number | Valor inicial |
| `rounding` | number | Casas decimais |
| `suffix` | string | Texto depois do valor (`%`, `x`, ` sp`) |
| `disabled` | boolean | Bloqueia a interação |
| `callback` | function(value) | Chamado quando o valor muda |

```lua
-- // API Slider
sliderCompleto:Set(100)
sliderCompleto:SetMin(10)
sliderCompleto:SetMax(300)
sliderCompleto:SetSuffix(" km/h")
sliderCompleto:SetTitle("Speed")
sliderCompleto:SetDescription("Velocidade atualizada")
sliderCompleto:SetDisabled(true)
sliderCompleto:SetDisabled(false)

local atual = sliderCompleto:Get()
```

---

### 4.4 Dropdown

```lua
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
```

| Opção | Tipo | Descrição |
|-------|------|-----------|
| `title` | string | Texto principal |
| `description` | string | Texto menor |
| `values` | table | Lista de opções |
| `default` | string ou table | Opção inicial (table quando `multi = true`) |
| `multi` | boolean | Permite escolher várias opções |
| `disabled` | boolean | Bloqueia a interação |
| `callback` | function(value) | Recebe a opção escolhida. Com `multi`, recebe uma tabela `{ [opção] = boolean }` |

---

### 4.5 ColorPicker

```lua
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
```

| Opção | Tipo | Descrição |
|-------|------|-----------|
| `title` | string | Texto principal |
| `description` | string | Texto menor |
| `default` | Color3 | Cor inicial |
| `transparency` | number | Transparência inicial (0 a 1) |
| `disabled` | boolean | Bloqueia a interação |
| `callback` | function(color, transparency) | Chamado quando a cor muda |

---

### 4.6 Paragraph

Card de informação. Pode ser só texto, texto com avatar, holograma 3D de personagem ou item, e uma página de status (lista de nome e valor). Com holograma e status juntos, o card ganha seta e bolinhas para trocar de página.

Funciona em PC e celular.

#### 4.6.1 Opções

| Opção | Tipo | Padrão | Descrição |
|-------|------|--------|-----------|
| `title` | string | `""` | Título (também aceita `Name`) |
| `description` | string | `""` | Texto menor (aceita `\n` para quebrar linha) |
| `thumbnail` | number ou string | nenhum | UserId para mostrar o avatar, ou id/link de imagem |
| `hologram` | table ou valor | nenhum | Holograma 3D. Se for só um valor, vira o `target` |
| `status` | table | nenhum | Lista de status (nome e valor) |
| `statusTitle` | string | `"Status"` | Título da página de status |
| `disabled` | boolean | `false` | Escurece e bloqueia o card |
| `richText` | boolean | `true` | Liga o RichText nos textos |
| `callback` | function(page) | nenhum | Chamado quando a página troca (`"hologram"` ou `"status"`) |

#### 4.6.2 Opções do `hologram`

| Opção | Tipo | Padrão | Descrição |
|-------|------|--------|-----------|
| `target` | número, string ou Instance | nenhum | O que aparece no holograma (veja a tabela abaixo) |
| `type` | string | automático | `"character"` (ou `"player"`) para jogador, `"item"` para item |
| `background` | number ou string | nenhum | Imagem de fundo (id ou link) |
| `backgroundTransparency` | number | `0.5` | Transparência do fundo (0 a 1) |
| `backgroundTile` | boolean | `false` | Repete a imagem em vez de esticar |
| `corners` | table | nenhum | Textos nos 4 cantos |
| `rotate` | boolean | `true` | Gira o modelo |
| `speed` | number | `40` | Velocidade da rotação (graus por segundo) |
| `tint` | Color3 | nenhum | Cor aplicada no modelo |

Cantos aceitos em `corners`: `topLeft`, `topRight`, `bottomLeft`, `bottomRight`.

| `target` | Resultado |
|----------|-----------|
| `player.UserId` (number) | Personagem desse jogador |
| `"NomeDoJogador"` ou DisplayName | Personagem do jogador que está no servidor |
| `"LocalPlayer"` | Seu personagem |
| `Player` (Instance) | Personagem desse jogador |
| `Model` ou `BasePart` (Instance) | Esse modelo |
| `123456789` com `type = "item"` | Item do catálogo (acessório, tool, modelo) |
| `"rbxassetid://123456789"` | Asset por id |

Quando o jogador está no servidor, o holograma acompanha: respawn e troca de roupa atualizam sozinhos. Se ele não estiver, usa o avatar pelo UserId.

#### 4.6.3 Entradas do `status`

Cada entrada é uma table. As duas formas funcionam:

```lua
-- // Formas
{ name = "Health", value = 80, max = 100 }
{ "Health", 80, 100 }
```

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `name` | string | Nome da linha |
| `value` | qualquer | Valor mostrado à direita |
| `max` | number | Opcional. Com número em `value`, mostra `80/100` |

O status mostra só números e texto, sem barra de progresso.

#### 4.6.4 Sem função

Cards estáticos, sem `callback` e sem precisar guardar a variável.

```lua
-- // Só título
ParaSection:CreateParagraph({
    title = "Aviso",
})

-- // Título e descrição
ParaSection:CreateParagraph({
    title = "Servidor",
    description = "Linha 1\nLinha 2",
})

-- // Com avatar (UserId)
ParaSection:CreateParagraph({
    title = player.DisplayName .. " (@" .. player.Name .. ")",
    description = "Online",
    thumbnail = player.UserId,
})

-- // Com imagem
ParaSection:CreateParagraph({
    title = "Logo",
    description = "Imagem por id",
    thumbnail = "rbxassetid://123456789",
})

-- // Desativado
ParaSection:CreateParagraph({
    title = "Em breve",
    description = "Ainda não disponível",
    disabled = true,
})
```

```lua
-- // Holograma do jogador
ParaSection:CreateParagraph({
    title = "Meu personagem",
    description = "Live preview",
    hologram = {
        target = player.UserId,
        type = "character",
        rotate = true,
        speed = 40,
    },
})

-- // Holograma com atalho
ParaSection:CreateParagraph({
    title = "Meu personagem",
    hologram = player.UserId,
})

-- // Holograma com fundo e cantos
ParaSection:CreateParagraph({
    title = "Player Card",
    description = "Live preview",
    hologram = {
        target = player.UserId,
        type = "character",
        background = 123456789,
        backgroundTransparency = 0.5,
        backgroundTile = false,
        rotate = true,
        speed = 40,
        tint = Color3.fromRGB(120, 180, 255),
        corners = {
            topLeft = player.DisplayName,
            topRight = "Lv. 120",
            bottomLeft = "Online",
            bottomRight = "Premium",
        },
    },
})

-- // Holograma de item
ParaSection:CreateParagraph({
    title = "Item",
    hologram = {
        target = 123456789,
        type = "item",
        rotate = true,
        speed = 30,
    },
})

-- // Holograma de um modelo do mapa
ParaSection:CreateParagraph({
    title = "Estátua",
    hologram = {
        target = workspace.Map.Statue,
    },
})
```

```lua
-- // Só status
ParaSection:CreateParagraph({
    title = "Servidor",
    description = "Informações do servidor",
    statusTitle = "Status",
    status = {
        { name = "Jogadores", value = 1, max = 8 },
        { name = "Tipo", value = "Público" },
        { name = "PlaceId", value = game.PlaceId },
    },
})

-- // Holograma e status (duas páginas)
ParaSection:CreateParagraph({
    title = "Player Card",
    description = "Live preview",
    hologram = {
        target = player.UserId,
        type = "character",
        corners = {
            topLeft = player.DisplayName,
            topRight = "Lv. 120",
            bottomLeft = "Online",
            bottomRight = "Premium",
        },
    },
    status = {
        { name = "Health", value = 80, max = 100 },
        { name = "Level", value = 120 },
        { name = "Rank", value = "Legendary" },
    },
})
```

#### 4.6.5 Com função

Guarde a variável para atualizar o card depois, e use `callback` para saber quando a página troca.

```lua
-- // Callback de página
local card = ParaSection:CreateParagraph({
    title = "Player Card",
    description = "Live preview",
    hologram = {
        target = player.UserId,
        type = "character",
    },
    status = {
        { name = "Level", value = 120 },
    },
    callback = function(page)
        print("Página:", page)
    end,
})
```

```lua
-- // Texto
card:SetTitle("Novo título")
card:SetDescription("Novo texto")
card:SetThumbnail(player.UserId)
card:SetDisabled(true)

-- // Holograma
card:SetTarget(otherPlayer.UserId, "character")
card:SetTarget(123456789, "item")
card:SetBackground(123456789, 0.5, false)
card:SetCorners({
    topLeft = "Nome",
    topRight = "Lv. 121",
    bottomLeft = "Online",
    bottomRight = "Free",
})
card:SetCorner("bottomRight", "Premium")
card:SetHologram({
    target = player.UserId,
    type = "character",
    rotate = false,
})
card:SetHologram(nil)

-- // Status
card:SetStatus({
    { name = "Health", value = 50, max = 100 },
    { name = "Level", value = 121 },
})
card:SetStat("Level", 122)
card:SetStat("Health", 40, 100)
card:SetStat("Coins", 1500)
print(card:GetStat("Level"))
card:RemoveStat("Coins")
card:SetStatusTitle("Atributos")

-- // Página
card:SetPage("status")
card:SetPage("hologram")
print(card:GetPage())

-- // Destruir
card:Destroy()
```

Atualizando a descrição em loop:

```lua
-- // Atualização por descrição
local paraServidor = ParaSection:CreateParagraph({
    title = "Servidor",
    description = "Carregando...",
})

task.spawn(function()
    while task.wait(1) do
        paraServidor:SetDescription("Jogadores: " .. #Players:GetPlayers() .. " / " .. Players.MaxPlayers)
    end
end)
```

#### 4.6.6 Métodos

| Método | Descrição |
|--------|-----------|
| `SetTitle(texto)` | Troca o título |
| `SetDescription(texto)` | Troca a descrição |
| `SetThumbnail(valor)` | Troca o avatar (UserId ou imagem). `nil` remove |
| `SetDisabled(estado)` | Ativa ou desativa o card |
| `GetTitle()` | Retorna o título |
| `GetDescription()` | Retorna a descrição |
| `SetHologram(config)` | Troca o holograma inteiro. `nil` remove |
| `SetTarget(target, tipo)` | Troca só o alvo do holograma |
| `SetBackground(id, transparencia, tile)` | Troca o fundo do holograma |
| `SetCorners(tabela)` | Troca os 4 cantos |
| `SetCorner(nome, texto)` | Troca um canto |
| `SetStatus(lista)` | Troca a lista de status |
| `SetStatusTitle(texto)` | Troca o título da página de status |
| `SetStat(nome, valor, max)` | Atualiza uma linha (cria se não existir) |
| `GetStat(nome)` | Retorna o valor de uma linha |
| `RemoveStat(nome)` | Remove uma linha |
| `SetPage(pagina)` | Vai para `"hologram"` ou `"status"` |
| `GetPage()` | Retorna a página atual |
| `Destroy()` | Remove o card |

#### 4.6.7 Comportamento

- Seta e bolinhas só aparecem quando o card tem holograma e status juntos. Só status ou só holograma fica sem botão, com o layout normal.
- O botão de próximo e o de voltar não têm fundo, só o ícone.
- `SetStatus` com os mesmos nomes na mesma ordem só atualiza os valores, sem piscar e sem resetar o scroll. Pode chamar em loop.
- A lista de status só rola quando passa da altura do card.
- Números grandes aparecem completos, como o PlaceId.
- O holograma volta o personagem para a pose padrão e não mostra tool na mão.
- A thumbnail por UserId atualiza a cada 30 segundos.
- O `callback` só é chamado quando a página muda, pelo botão ou por `SetPage`.
- Quando a section ou a janela é destruída, o Paragraph limpa as conexões sozinho.

---

## 5. Exemplo completo: aba Status

Player Card com holograma e status, card do servidor e linha do jogador. Atualiza tudo a cada 1 segundo.

```lua
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
```

> O `StatusUnload` é chamado automaticamente quando a feature é descarregada (veja a Features API). Isso desconecta o loop e evita lag depois de fechar o hub.

> Como `SetStatus` mantém os mesmos nomes na mesma ordem, o loop só troca os valores. O scroll da lista não volta pro topo.

---

## 6. Referência rápida

```lua
-- // Window
local Window = Librarys:CreateWindow({
    Title = "Hub",
    SubTitle = "by x",
    Size = UDim2.fromOffset(580, 350),
    MinimizeKey = Enum.KeyCode.RightShift,
})

-- // Tab e Section
local Tab = Window:CreateTab({
    tab = "Nome",
    section = "Grupo",
    icon = "icone",
})

local Section = Tab:CreateSection("Titulo")
```

```lua
-- // Elements
Section:CreateToggle({
    title = "X",
    default = false,
    callback = function(state)
    end,
})

Section:CreateButton({
    title = "X",
    callback = function()
    end,
})

Section:CreateSlider({
    title = "X",
    min = 0,
    max = 100,
    default = 50,
    callback = function(value)
    end,
})

Section:CreateDropdown({
    title = "X",
    values = { "A", "B" },
    default = "A",
    callback = function(value)
    end,
})

Section:CreateColorPicker({
    title = "X",
    default = Color3.new(1, 1, 1),
    callback = function(color, alpha)
    end,
})

Section:CreateParagraph({
    title = "X",
    description = "Texto",
})

Section:CreateParagraph({
    title = "X",
    thumbnail = player.UserId,
})

local card = Section:CreateParagraph({
    title = "X",
    hologram = {
        target = player.UserId,
        type = "character",
        corners = {
            topLeft = "A",
            topRight = "B",
            bottomLeft = "C",
            bottomRight = "D",
        },
    },
    status = {
        { name = "Level", value = 1 },
        { name = "Health", value = 80, max = 100 },
    },
    callback = function(page)
    end,
})

card:SetStat("Level", 2)
card:SetStatus({ { name = "Level", value = 2 } })
card:SetCorner("topRight", "Z")
card:SetTarget(player.UserId, "character")
card:SetPage("status")

Section:CreateElement("NomeRegistrado", {
    text = "X",
})
```
