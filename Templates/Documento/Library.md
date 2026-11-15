# Librarys

Documentação da library de UI do Ecohub: janela, tabs, sections, elements, themes, saves, features e idiomas.

## Índice

1. [Carregar a library](#1-carregar-a-library)
2. [Criar a janela](#2-criar-a-janela)
3. [Tabs e Sections](#3-tabs-e-sections)
   - [Layout das sections](#31-layout-das-sections)
   - [Tamanho automático da janela](#32-tamanho-automático-da-janela)
4. [Elements](#4-elements)
   - [Regras gerais](#40-regras-gerais)
   - [Toggle](#41-toggle)
   - [Button](#42-button)
   - [Slider](#43-slider)
   - [Dropdown](#44-dropdown)
   - [ColorPicker](#45-colorpicker)
   - [Paragraph](#46-paragraph)
   - [Hologram](#47-hologram)
5. [Themes](#5-themes)
6. [Saves](#6-saves)
7. [Settings do painel e Notificações](#7-settings-do-painel-e-notificações)
8. [Features](#8-features)
9. [Idiomas](#9-idiomas)
10. [Criar um element próprio](#10-criar-um-element-próprio)
11. [Exemplo completo: aba Status](#11-exemplo-completo-aba-status)
12. [Referência rápida](#12-referência-rápida)

---

## 1. Carregar a library

```lua
-- // Library
local Librarys = loadstring(game:HttpGet("https://raw.githubusercontent.com/pvpgalinhamonzonrebasexk/gazrenkinras/refs/heads/main/Library/Library.luau"))()
```

> Só existe **uma janela** por vez. Executar o script de novo destrói a janela anterior, descarrega as features dela e remove qualquer GUI que tenha sobrado.
>
> Se uma feature ainda estiver carregando (até 60 segundos, veja `ReloadGuard` na seção 8), o novo carregamento é ignorado e a library atual é devolvida.

Chamar `Librarys:CreateWindow` quando a janela já existe não cria outra: só atualiza título, subtítulo e tecla e devolve a janela atual.

A library também ativa um anti-AFK automático enquanto a janela existe.

---

## 2. Criar a janela

```lua
-- // Window
local Window = Librarys:CreateWindow({
    Title = "Eco Hub",
    SubTitle = "by rip_sheldoohz",
    Size = UDim2.fromOffset(620, 350),
    MinimizeKey = Enum.KeyCode.RightShift,
})
```

| Opção | Tipo | Padrão | Descrição |
|-------|------|--------|-----------|
| `Title` | string | `"Ecohub"` | Título da janela |
| `SubTitle` | string | `"Panel"` | Subtítulo (também aceita `Subtitle`) |
| `Size` | UDim2 | `620 x 350` | Tamanho base. Em offset o mínimo é `420 x 260` |
| `MinimizeKey` | Enum.KeyCode | `RightShift` | Tecla que abre e fecha a janela |

- Sem `MinimizeKey` na criação, vale a tecla que o jogador escolheu antes (ela fica salva). Com `MinimizeKey`, a tecla do script vence.
- O **quadrado flutuante** aparece sempre (PC e celular). Clicar abre e fecha a janela e dá para arrastar. A posição dele e a da janela **não são salvas**: ao executar de novo o quadrado volta ao lugar padrão e a janela abre centralizada.
- No topo da janela ficam a **pesquisa** e as **configurações** (engrenagem). `Esc` fecha as duas.
- O `Size` é a medida mínima da janela: ela pode crescer sozinha para caber o conteúdo (veja [3.2](#32-tamanho-automático-da-janela)).

### Métodos da janela

| Método | Descrição |
|--------|-----------|
| `Window:CreateTab(opts)` | Cria uma tab |
| `Window:GetTab(nomeOuIndice)` | Retorna uma tab |
| `Window:SelectTab(tab)` | Seleciona uma tab (objeto, nome ou índice) |
| `Window:SetTitle(texto)` | Troca o título |
| `Window:SetSubTitle(texto)` | Troca o subtítulo (também `SetSubtitle`) |
| `Window:SetMinimizeKey(tecla)` | Troca a tecla de minimizar (fica salva). Também `SetToggleKey` |
| `Window:Toggle()` | Abre ou fecha |
| `Window:SetVisible(estado)` | Mostra ou esconde |
| `Window:SetMinimized(estado)` | Define fechado (`true`) ou aberto (`false`) |
| `Window:IsMinimized()` | Retorna se está fechada |
| `Window:OpenSearch()` / `Window:CloseSearch()` | Abre e fecha a pesquisa |
| `Window:ClearSearch()` | Limpa o texto da pesquisa |
| `Window:OpenSettings()` / `Window:CloseSettings()` | Abre e fecha as configurações |
| `Window:CreateSettingsSection(nome)` | Cria uma section nas configurações (seção 7) |
| `Window:SetTheme(nome)` | Troca o tema (seção 5) |
| `Window:Notify(opts)` | Mostra uma notificação (seção 7) |
| `Window:SetLanguage(codigo)` | Troca o idioma (seção 9) |
| `Window:LoadFeature(nome)` | Carrega uma feature (seção 8) |
| `Window:Destroy()` | Destrói a janela e descarrega as features |

Também ficam disponíveis na janela:

| Campo | Descrição |
|-------|-----------|
| `Window.Theme` | Tabela com as cores atuais (os elements leem daqui) |
| `Window.ThemeName` | Nome do tema atual |
| `Window.Save` | Salva e lê valores seus (seção 6) |
| `Window.Config` | Configurações da library, como `AutoFit` e `ColumnMinWidth` |
| `Window.Elements` | Registro de elements (seção 10) |
| `Window.FeatureConfig` | Configurações do carregador de features (seção 8) |
| `Window.Tabs` / `Window.ActiveTab` | Lista de tabs e tab atual |
| `Window.CreateIcon(parent, nome, tamanho, cor)` | Cria um ícone lucide |
| `Window.Error(titulo, detalhe)` | Mostra um erro como notificação |

O próprio `Librarys` também repassa `CreateTab`, `GetTab`, `SelectTab`, `LoadFeature` (e as outras funções de feature), `TranslateGame`, `SetLanguage`, `GetLanguage`, `AddTranslations` e `Translate`, usando a janela atual. Se ainda não existir janela, mostra o erro `Window missing`.

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

| Opção da tab | Padrão | Descrição |
|--------------|--------|-----------|
| `tab` | `"Tab"` | Nome que aparece na barra lateral (também aceita `name`, `Name`, `Title`) |
| `section` | `"Main"` | Título do grupo na barra lateral. Tabs com a mesma `section` ficam juntas. Clicar no título do grupo recolhe e abre |
| `icon` | `"circle"` | Nome do ícone lucide, sem o prefixo `lucide-` |
| `layout` | `"Default"` | `"Default"` (duas colunas) ou `"Compact"` (uma coluna). Veja 3.1 |
| `OnSelect` | nenhum | `function(tab)` chamada quando a tab é selecionada |

Criar uma tab que já existe (mesmo grupo e mesmo nome) devolve a tab existente. A primeira tab criada já abre selecionada.

| Método | Descrição |
|--------|-----------|
| `Tab:CreateSection(titulo)` | Cria um bloco na página da tab. Se já existir uma section com esse título, devolve ela (também `AddSection`) |
| `Tab:Select()` | Seleciona a tab |
| `Tab:SetIcon(nome)` | Troca o ícone |
| `Tab:SetLayout("Default" ou "Compact")` | Troca o layout das sections |
| `Section:SetTitle(texto)` | Troca o título da section |
| `Section:CreateElement(nome, opts)` | Cria um element pelo nome (também `AddElement`) |
| `Section:CreateToggle(opts)` | Atalho: qualquer `Create...` ou `Add...` vira `CreateElement("...")` |

### 3.1 Layout das sections

Cada section é um **card** (fundo, borda e título) e os elements ficam dentro dele, sem frame próprio.

No layout `Default` as sections se dividem em **duas colunas**, alternando:

| Section | Coluna |
|---------|--------|
| 1ª | esquerda |
| 2ª | direita |
| 3ª | esquerda |
| 4ª | direita |
| ... | ... |

- Com **uma única section** na tab, ela ocupa a largura toda. Ao criar a segunda, as duas se dividem.
- `layout = "Compact"` (ou `Tab:SetLayout("Compact")`) coloca uma section embaixo da outra, em uma coluna só.
- Se a janela for estreita demais, a tab vira `Compact` sozinha. O limite é `Window.Config.ColumnMinWidth` (padrão `170` pixels por coluna).

```lua
-- // Layout
local TabA = Window:CreateTab({ tab = "Duas colunas", icon = "columns" })
local TabB = Window:CreateTab({ tab = "Uma coluna", icon = "rows", layout = "Compact" })

TabB:SetLayout("Default")
```

### 3.2 Tamanho automático da janela

A janela mede o conteúdo da tab aberta e se ajusta com uma animação suave, mesmo com `Size` já definido. O `Size` vira o tamanho mínimo: a janela nunca fica menor que ele.

| Eixo | Regra |
|------|-------|
| Altura | Cresce até caber o conteúdo, no máximo `FitHeight` da altura da tela (padrão 85%) |
| Largura | Com muitos elements ganha um pouco de largura, até `FitWidth` pixels (padrão 80) |

A largura extra começa em `FitStart` elements na tab (padrão 8) e chega no máximo em `FitFull` (padrão 24). Ao trocar para uma tab com pouco conteúdo, a janela volta ao tamanho base. A janela cresce a partir do centro.

Se o `Size` for em escala (`UDim2.fromScale`), o eixo em escala não é ajustado.

```lua
-- // Ajustes (em Window.Config)
Window.Config.AutoFit = true
Window.Config.FitHeight = 0.85
Window.Config.FitWidth = 80
Window.Config.FitStart = 8
Window.Config.FitFull = 24
Window.Config.ColumnMinWidth = 170
Window.Config.ColumnGap = 8
Window.Config.SectionLayout = "Default"
```

`AutoFit = false` desliga o ajuste automático. `SectionLayout` é o layout padrão das tabs novas.

---

## 4. Elements

### 4.0 Regras gerais

- Todos os elements aceitam `callback` (ou `Callback`). Erros dentro do callback são capturados e aparecem como notificação, sem derrubar o script.
- Todo element entra na **pesquisa** da janela pelo título (`title`, `name`, `text` ou `label`). Sem título, entra pelo nome do tipo.
- `Section:CreateX(opts)` devolve um **handle**. Se o element ainda estiver carregando, as chamadas de método (`Set`, `SetTitle`...) ficam na fila e rodam assim que ele existir. Depois disso o handle repassa direto para o element. `handle.Destroy()` remove o element.
- Criar de novo um element do **mesmo tipo e com o mesmo título** na mesma section substitui o anterior, mantendo a posição.
- Os elements ficam em `Library/Elements` no GitHub e são baixados ao abrir a janela. Se algum não for encontrado, aparece a notificação `Element missing`.
- Os nomes `Toggle` e `Checkbox` são o mesmo element. `ColorPicker` também pode ser chamado de `ColorPick`.
- Os elements acompanham o tema sozinhos (seção 5).

**Auto save.** Elements que têm `Get` e `Set` são salvos e restaurados quando o painel reinicia (seção 6):

| Element | Salva | Observação |
|---------|-------|------------|
| Toggle | `true` ou `false` | |
| Slider | número | |
| Dropdown | opção ou lista | |
| ColorPicker | cor | só a cor, a transparência não é salva |
| Button | não | |
| Paragraph | não | |
| Hologram | não | |

O callback é chamado quando o valor salvo é restaurado e é diferente do valor atual.

**Elements usam as cores do tema.** Os nomes dos elements usam a cor `Active` do tema. Em temas coloridos ela é a cor de destaque (veja a seção 5).

---

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

-- // Com emoji
local toggleEmoji = BoxSection:CreateToggle({
    title = "Auto Farm",
    emoji = ":fire:",
    description = "Farma sozinho :bolt:",
    default = false,
    callback = function(state)
        print("Auto Farm:", state)
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

-- // Com keybind por texto
local toggle6 = BoxSection:CreateToggle({
    title = "ESP",
    default = false,
    keybind = "M2",
    callback = function(state)
        print("ESP:", state)
    end,
})

-- // Ativado por padrão
local toggle7 = BoxSection:CreateToggle({
    title = "Auto Collect",
    default = true,
    callback = function(state)
        print("Auto Collect:", state)
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
| `title` | string | Texto principal (também `Name`) |
| `description` | string | Texto menor abaixo do título |
| `emoji` | string | Emoji antes do título. Aceita o emoji direto ou o código `:fire:` |
| `default` | boolean | Estado inicial |
| `disabled` | boolean | Bloqueia a interação |
| `keybind` | KeyCode, UserInputType, WheelUp/WheelDown ou string | Atalho que alterna o toggle. Só no PC |
| `keybindCallback` | function(state) | Chamado só quando o atalho é usado |
| `callback` | function(state) | Chamado sempre que o estado muda. Com `default = true`, também é chamado ao criar |

**Keybind**

- O botão da tecla só aparece no PC e só quando o toggle foi criado com `keybind`. No celular o toggle funciona normal, sem atalho.
- Clicar no botão da tecla entra em modo de escuta. Aperte uma tecla, `M1`, `M2`, `M3` ou role o mouse (`WhUp`/`WhDn`) para trocar. `Esc` remove o atalho. Só um toggle escuta por vez.
- Texto aceito em `keybind`: nome do `Enum.KeyCode` (`"G"`, `"LeftShift"`) ou os apelidos `LShift`, `RShift`, `LCtrl`, `RCtrl`, `LAlt`, `RAlt`, `Enter`, `Esc`, `Del`, `M1`, `M2`, `M3`, `WhUp`, `WhDn`, `Num0` a `Num9`, entre outros.
- Quando um toggle com atalho está **ligado**, ele aparece no painel **Key Bind** (um card arrastável no canto da tela). Nele dá para fechar, abrir as configurações (`Não mostrar mais`, `Permitir arrastar`, `Resetar posição`) e arrastar pela barra de cima.

**Emojis.** Os códigos `:nome:` funcionam em `title`, `description`, `emoji` e nas notificações do toggle:

`fire`, `star`, `heart`, `check`, `cross`, `warning`, `lock`, `unlock`, `gear`, `bolt`, `eye`, `target`, `sword`, `shield`, `gun`, `skull`, `crown`, `rocket`, `gem`, `fish`, `sparkles`, `bell`, `key`, `globe`, `music`, `moon`, `sun`, `pumpkin`, `ghost`, `candy`, `car`, `run`, `wrench`, `trophy`, `flag`, `wave`, `home`, `clock`, `diamond`

```lua
-- // Emojis próprios
local Emoji = getgenv().EcoHubEmoji

Emoji.Add("coin", "🪙")
print(Emoji.Get("coin"))
print(Emoji.Parse("Moedas :coin:"))
print(Emoji.Length("🔥🔥"))
Emoji.Remove("coin")
print(Emoji.List())
```

```lua
-- // API Toggle
toggle1:Set(true)
toggle1:Set(false)
toggle1:Toggle()
toggle1:SetTitle("Wallbang ATIVO")
toggle1:SetEmoji(":star:")
toggle2:SetDescription("Agora com dano 2x")
toggle8:SetDisabled(false)
toggle8:SetDisabled(true)
toggle3:SetKeybind(Enum.KeyCode.H)
toggle3:SetKeybind(Enum.UserInputType.MouseButton2)
toggle3:ClearKeybind()

local estado = toggle1:Get()
local bind = toggle3:GetKeybind()
local emoji = toggle1:GetEmoji()

toggle1:Destroy()
```

| Método | Descrição |
|--------|-----------|
| `Set(estado)` | Define o estado. Chama o `callback` se mudou |
| `Get()` | Retorna o estado |
| `Toggle()` | Alterna |
| `SetDisabled(estado)` | Bloqueia ou libera |
| `SetTitle(texto)` | Troca o título |
| `SetEmoji(emoji)` / `GetEmoji()` | Troca e lê o emoji |
| `SetDescription(texto)` | Troca a descrição (vazio remove) |
| `SetKeybind(tecla)` | Troca o atalho |
| `GetKeybind()` | Retorna o atalho |
| `ClearKeybind()` | Remove o atalho |
| `Destroy()` | Remove o element |

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

-- // Tamanhos
local btnPequeno = ButtonSection:CreateButton({
    title = "Pequeno",
    size = "sm",
    callback = function()
    end,
})

local btnGrande = ButtonSection:CreateButton({
    title = "Grande",
    size = "lg",
    callback = function()
    end,
})

-- // Carregando
local btnLoading = ButtonSection:CreateButton({
    title = "Baixando",
    loading = true,
    callback = function()
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

| Opção | Tipo | Padrão | Descrição |
|-------|------|--------|-----------|
| `title` | string | `"Button"` | Texto principal (também `Name`) |
| `description` | string | nenhum | Texto menor |
| `size` | string | `"default"` | `"xs"`, `"sm"`, `"default"` ou `"lg"` |
| `disabled` | boolean | `false` | Bloqueia o clique |
| `loading` | boolean | `false` | Mostra o círculo girando e bloqueia o clique |
| `callback` | function() | nenhum | Chamado ao clicar |

O Button desenha o próprio fundo e não é salvo no auto save.

```lua
-- // API Button
btn1:SetTitle("Novo Titulo")
btn2:SetDescription("Nova descricao")
btn3:SetDisabled(false)
btn1:SetSize("xs")
btn1:SetLoading(true)
btn1:SetLoading(false)
print(btn1:IsLoading())
btn1:Fire()
btn1:Destroy()
```

| Método | Descrição |
|--------|-----------|
| `SetTitle(texto)` | Troca o título |
| `SetDescription(texto)` | Troca a descrição (vazio remove) |
| `SetDisabled(estado)` | Bloqueia ou libera |
| `SetLoading(estado)` | Liga ou desliga o carregando |
| `IsLoading()` | Retorna se está carregando |
| `SetSize(tamanho)` | Troca o tamanho |
| `Fire()` | Chama o `callback` (ignora se bloqueado ou carregando) |
| `Destroy()` | Remove o element |

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

| Opção | Tipo | Padrão | Descrição |
|-------|------|--------|-----------|
| `title` | string | `"Slider"` | Texto principal (também `Name`) |
| `description` | string | nenhum | Texto menor |
| `min` | number | `0` | Valor mínimo (também `Min`) |
| `max` | number | `100` | Valor máximo (também `Max`) |
| `default` | number | `min` | Valor inicial |
| `rounding` | number | `0` | Casas decimais |
| `suffix` | string | nenhum | Texto depois do valor (`%`, `x`, ` sp`). Também `ValueName` |
| `disabled` | boolean | `false` | Bloqueia a interação |
| `callback` | function(value) | nenhum | Chamado quando o valor muda e uma vez ao criar, com o valor inicial |

O valor aparece em uma caixa à direita do título. **Clique nela e digite** um número para definir o valor direto (aceita `,` ou `.` como decimal).

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

sliderCompleto:Destroy()
```

| Método | Descrição |
|--------|-----------|
| `Set(valor)` | Define o valor (limitado entre `min` e `max`). Chama o `callback` se mudou |
| `Get()` | Retorna o valor |
| `SetMin(valor)` / `SetMax(valor)` | Troca os limites e reajusta o valor. `min` precisa ser menor que `max`, senão aparece um aviso e nada muda |
| `SetSuffix(texto)` | Troca o sufixo |
| `SetTitle(texto)` | Troca o título |
| `SetDescription(texto)` | Troca a descrição (vazio remove) |
| `SetDisabled(estado)` | Bloqueia ou libera |
| `Destroy()` | Remove o element |

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

-- // Sem seleção inicial
local dropVazio = DropSection:CreateDropdown({
    title = "Mapa",
    values = { "Floresta", "Deserto", "Neve" },
    placeholder = "Escolha um mapa",
    allowDeselect = true,
    callback = function(value)
        print("Mapa:", value)
    end,
})

-- // Multi seleção
local dropMulti = DropSection:CreateDropdown({
    title = "Efeitos Ativos",
    values = { "Velocidade", "Forca", "Invisibilidade", "Voo" },
    default = { "Velocidade", "Forca" },
    multi = true,
    callback = function(selecionados)
        for _, efeito in ipairs(selecionados) do
            print("Ativo:", efeito)
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
```

| Opção | Tipo | Padrão | Descrição |
|-------|------|--------|-----------|
| `title` | string | `"Dropdown"` | Texto principal (também `Name`) |
| `description` | string | nenhum | Texto menor |
| `values` | table | `{}` | Lista de opções (também `Options`) |
| `default` | valor ou table | nenhum | Opção inicial (lista quando `multi = true`) |
| `multi` | boolean | `false` | Permite escolher várias opções |
| `placeholder` | string | `"Select..."` | Texto quando não há seleção |
| `allowDeselect` | boolean | `false` | Permite ficar sem seleção (clicar de novo na opção marcada desmarca) |
| `disabled` | boolean | `false` | Bloqueia a interação |
| `callback` | function(value) | nenhum | Veja abaixo |

**O que o `callback` recebe**

| Modo | Valor |
|------|-------|
| Seleção única | A opção escolhida (ou `nil` quando desmarcada) |
| `multi = true` | **Lista** com as opções marcadas, na ordem de `values` |

- Em `multi`, sem `allowDeselect` a última opção marcada não pode ser desmarcada. Em seleção única, clicar de novo na opção marcada só fecha a lista.
- A lista abre com uma **caixa de pesquisa** embaixo (`Enter` escolhe o primeiro resultado) e fecha ao clicar fora.
- Se já houver seleção ao criar, o `callback` é chamado uma vez.

```lua
-- // API Dropdown
dropBasico:Set("Arco")
dropMulti:Set({ "Voo", "Forca" })
dropBasico:SetValues({ "Espada", "Arco", "Lanca" })
dropBasico:SetTitle("Arma principal")
dropBasico:SetDescription("Escolha a arma")
dropBasico:SetDisabled(true)
dropBasico:Open()
dropBasico:Close()

local escolhido = dropBasico:Get()
local lista = dropMulti:Get()

dropBasico:Destroy()
```

| Método | Descrição |
|--------|-----------|
| `Set(valor)` | Define a seleção (lista em `multi`). Valor que não existe em `values` mostra aviso. `Set(nil)` limpa |
| `Get()` | Retorna a seleção (lista em `multi`) |
| `SetValues(lista)` | Troca as opções. Seleções que não existem mais são removidas |
| `SetTitle(texto)` | Troca o título |
| `SetDescription(texto)` | Troca a descrição (vazio remove) |
| `SetDisabled(estado)` | Bloqueia ou libera |
| `Open()` / `Close()` | Abre e fecha a lista |
| `RefreshTheme()` | Reaplica as cores do tema |
| `Destroy()` | Remove o element |

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
```

| Opção | Tipo | Padrão | Descrição |
|-------|------|--------|-----------|
| `title` | string | `"Color"` | Texto principal (também `Name`) |
| `description` | string | nenhum | Texto menor |
| `default` | Color3 | `RGB(68, 120, 255)` | Cor inicial |
| `transparency` | number | `0` | Transparência inicial (0 a 1) |
| `disabled` | boolean | `false` | Bloqueia a interação |
| `callback` | function(color, transparency) | nenhum | Chamado quando a cor muda |

Clicar no campo da cor abre o seletor: quadrado de saturação e brilho, barra de matiz, barra de transparência e uma caixa de **hex** (aceita `RGB` ou `RRGGBB`, com ou sem `#`). Clicar fora fecha. O `callback` não é chamado ao criar e, enquanto você arrasta, é chamado no máximo a cada 0,05 segundo.

```lua
-- // API ColorPicker
cpBasico:Set(Color3.fromRGB(255, 0, 0))
cpBasico:Set(Color3.fromRGB(255, 0, 0), 0.3)
cpBasico:SetCallback(function(color, transparency)
    print(color, transparency)
end)
cpBasico:SetTitle("Cor")
cpBasico:SetDescription("Nova descrição")
cpBasico:SetDisabled(true)
cpBasico:Open()
cpBasico:Close()

local cor = cpBasico:Get()
local hex = cpBasico:GetHex()
local alpha = cpBasico:GetTransparency()

cpBasico:Destroy()
```

| Método | Descrição |
|--------|-----------|
| `Set(cor, transparencia)` | Define a cor. Sem o segundo valor a transparência vira `0` |
| `Get()` | Retorna a cor (Color3) |
| `GetHex()` | Retorna o hex, como `"4478FF"` |
| `GetTransparency()` | Retorna a transparência |
| `SetCallback(funcao)` | Troca o callback |
| `SetTitle(texto)` | Troca o título |
| `SetDescription(texto)` | Troca a descrição (vazio remove) |
| `SetDisabled(estado)` | Bloqueia ou libera |
| `Open()` / `Close()` | Abre e fecha o seletor |
| `RefreshTheme()` | Reaplica as cores do tema |
| `Destroy()` | Remove o element |

---

### 4.6 Paragraph

Card de informação. Pode ser só título e texto, ou uma lista de linhas: texto, nome e valor, barras de progresso, títulos de grupo, divisórias, etiquetas, galeria de imagens e imagem grande. Não tem `callback` e não é salvo no auto save.

Funciona em PC e celular.

#### 4.6.1 Opções

| Opção | Tipo | Padrão | Descrição |
|-------|------|--------|-----------|
| `title` | string | `""` | Título (também `Title`, `Name`) |
| `description` | string | `""` | Texto menor (também `Description`, `content`). Aceita `\n` |
| `tag` | string | `""` | Etiqueta pequena acima do título, como `"PLAYER"` |
| `info` | table | nenhum | Lista de linhas (também `Info`, `lines`, `items`) |
| `status` | table | nenhum | Lista de linhas igual a `info`, adicionada depois dela |
| `accent` | cor | cor do tema | Cor de destaque do card (títulos de grupo, barras, marcadores) |
| `titleColor` | cor | cor do tema | Cor do título |
| `descriptionColor` | cor | cor do tema | Cor da descrição (também `descColor`) |
| `defaultColor` | cor | cor do tema | Cor padrão das linhas (também `color`) |
| `colors` | table | nenhum | Cor por posição da linha: `{ [1] = "red", [3] = "#00FF88" }` |
| `marker` | string | `"none"` | Marcador antes das linhas: `"none"`, `"bar"` ou `"dot"` |
| `rule` | boolean | `false` | Linha fina entre o cabeçalho e as linhas |
| `richText` | boolean | `true` | Liga o RichText nas linhas de nome e valor |
| `disabled` | boolean | `false` | Escurece o card |

`bullets = false` força `marker = "none"`.

**Cores.** Onde uma cor é aceita, vale:

| Forma | Exemplo |
|-------|---------|
| Nome | `"red"`, `"yellow"`, `"green"`, `"blue"`, `"orange"`, `"purple"`, `"pink"`, `"cyan"`, `"white"`, `"gray"` |
| Nome em português | `"vermelho"`, `"amarelo"`, `"verde"`, `"azul"`, `"laranja"`, `"roxo"`, `"rosa"`, `"ciano"`, `"branco"`, `"cinza"` |
| Hex | `"#FF8800"`, `"FF8800"`, `"#F80"` |
| Color3 ou BrickColor | `Color3.fromRGB(255, 136, 0)` |
| Tabela | `{ 255, 136, 0 }` ou `{ r = 1, g = 0.5, b = 0 }` |
| Papel do tema | `"accent"`, `"text"`, `"muted"`, `"desc"`, `"title"`, `"line"` |

Os nomes de cor são ajustados sozinhos para temas claros e escuros. Sem cor definida, a linha usa a cor `Active` do tema.

#### 4.6.2 Linhas (`info` e `status`)

Cada linha pode ser:

```lua
-- // Formas
"Só um texto"
{ "Nome", "Valor" }
{ "Health", 80, 100 }
{ label = "Health", value = 80, max = 100 }
{ text = "Só um texto" }
```

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `label` | string | Nome da linha (também `name`) |
| `value` | qualquer | Valor (também `text`, `info`) |
| `max` | number | Com `value` numérico, vira barra de progresso |
| `color` | cor | Cor da linha |
| `labelColor` | cor | Cor só do nome |
| `inline` | boolean | Nome à esquerda e valor à direita, em vez de `Nome: valor` |
| `bullet` | boolean | `true` liga o marcador nessa linha, `false` desliga |
| `icon` | imagem | Ícone à esquerda do texto (também `texture`, `image`) |
| `tint` | cor ou `true` | Pinta a imagem. `true` usa a cor da linha |
| `size` | number | Tamanho do ícone ou dos quadrados da galeria |
| `visible` | boolean | `false` esconde a linha |
| `type` | string | Tipo da linha (tabela abaixo) |

**Tipos de linha.** Se `type` não for dado, o tipo é escolhido pelo conteúdo.

| Tipo (`type`) | Aliases | Como aparece | Campos |
|---------------|---------|--------------|--------|
| texto | | `Nome: valor`, ou só o texto | `label`, `value`, `inline` |
| `"bar"` | `"progress"` | Nome, `80/100  •  80%` e barra animada | `label`, `value`, `max` (maior que 0) |
| `"header"` | `"section"`, `"heading"` | Título de grupo na cor de destaque | `text` |
| `"divider"` | `"line"`, `"separator"` | Linha divisória | nenhum |
| `"badges"` | `"badge"`, `"chips"`, `"tags"`, `"tag"` | Etiquetas lado a lado | `items`: lista de textos ou `{ text, color }` |
| `"gallery"` | `"images"`, `"textures"` | Quadrados de imagem | `textures`: lista de imagens ou `{ texture, tint }`, `size` |
| `"preview"` | | Imagem grande com borda | `texture`, `height`, `fit`, `label`, `value` |

Escolha automática: `textures` vira galeria, `items`/`tags`/`badges` viram etiquetas, uma linha só com imagem vira preview, `value` com `max` vira barra. O resto é texto.

`fit` do preview: `"fit"` (padrão), `"crop"` ou `"stretch"`. `height` padrão `140` (`150` no celular).

**Imagens.** Aceita id numérico, `"rbxassetid://id"`, link com o id (`?id=`, `/library/`, `/catalog/`), URL `rbxthumb://` ou uma instância `Decal`, `Texture`, `ImageLabel` ou `ImageButton`.

#### 4.6.3 Exemplos

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

-- // Com etiqueta e linhas
ParaSection:CreateParagraph({
    title = "Servidor",
    tag = "INFO",
    description = "Informações do servidor",
    rule = true,
    info = {
        { "Jogadores", #game.Players:GetPlayers() },
        { "Tipo", "Público" },
        { "PlaceId", game.PlaceId },
    },
})

-- // Nome à esquerda e valor à direita
ParaSection:CreateParagraph({
    title = "Stats",
    info = {
        { label = "Level", value = 120, inline = true },
        { label = "Rank", value = "Legendary", inline = true, color = "yellow" },
    },
})

-- // Barras de progresso
ParaSection:CreateParagraph({
    title = "Status",
    info = {
        { label = "Health", value = 80, max = 100, color = "green" },
        { label = "Mana", value = 35, max = 100, color = "blue" },
    },
})

-- // Grupos, divisória e etiquetas
ParaSection:CreateParagraph({
    title = "Perfil",
    info = {
        { type = "header", text = "Conta" },
        { "Nome", "Player123" },
        { type = "divider" },
        { type = "header", text = "Selos" },
        { type = "badges", items = { "Premium", { text = "VIP", color = "yellow" } } },
    },
})

-- // Ícone, galeria e imagem grande
ParaSection:CreateParagraph({
    title = "Imagens",
    info = {
        { icon = 123456789, label = "Item", value = "Espada" },
        { type = "gallery", textures = { 123456789, 987654321 }, size = 54 },
        { type = "preview", texture = "rbxassetid://123456789", height = 120, fit = "crop" },
    },
})

-- // Cores por posição e marcador
ParaSection:CreateParagraph({
    title = "Lista",
    marker = "bar",
    colors = { [1] = "red", [2] = "green" },
    info = { "Primeira", "Segunda", "Terceira" },
})

-- // Desativado
ParaSection:CreateParagraph({
    title = "Em breve",
    description = "Ainda não disponível",
    disabled = true,
})
```

#### 4.6.4 Atualizar o card

Guarde a variável para mudar o card depois. As posições (`index`) contam a partir de `1`, na ordem de `info` e depois `status`.

```lua
local card = ParaSection:CreateParagraph({
    title = "Player Card",
    tag = "PLAYER",
    description = "Live status",
    info = {
        { label = "Level", value = 120, inline = true },
        { label = "Health", value = 80, max = 100 },
    },
})

-- // Texto
card:SetTitle("Novo título")
card:SetDescription("Novo texto")
card:SetTag("ONLINE")

-- // Linhas
card:UpdateInfo(1, 121)
card:UpdateInfo(2, { value = 50, max = 100 })
card:UpdateInfo(1, { label = "Lv", color = "yellow" })
card:SetInfoColor(2, "red")
local index = card:AddInfo({ label = "Coins", value = 1500 })
card:AddInfo({ type = "divider" }, 1)
card:RemoveInfo(index)
card:SetInfo({ { "Level", 122 } })
card:ClearInfo()
print(card:GetInfo())

-- // Cores
card:SetAccent("cyan")
card:SetTitleColor("white")
card:SetDescriptionColor("gray")
card:SetDefaultColor("#CCCCCC")
card:SetColors({ [1] = "red", [2] = "green" }, "gray")
card:SetAllColors("white")

-- // Geral
card:Update({ title = "Outro", tag = "OFF", disabled = true, info = { "Texto" } })
card:SetDisabled(false)
card:SetVisible(false)
card:Refresh()
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

#### 4.6.5 Métodos

| Método | Descrição |
|--------|-----------|
| `SetTitle(texto)` / `GetTitle()` | Troca e lê o título |
| `SetDescription(texto)` / `GetDescription()` | Troca e lê a descrição |
| `SetTag(texto)` | Troca a etiqueta (vazio remove) |
| `SetInfo(lista)` | Troca todas as linhas |
| `AddInfo(linha, posicao)` | Adiciona uma linha (no fim, ou na posição dada). Retorna a posição |
| `UpdateInfo(index, campos)` | Muda uma linha. `campos` pode ser uma tabela ou só o novo valor |
| `RemoveInfo(index)` | Remove uma linha |
| `ClearInfo()` | Remove todas as linhas |
| `GetInfo()` | Retorna cópias das linhas |
| `SetInfoColor(index, cor)` | Troca a cor de uma linha |
| `SetColors(tabela, padrao)` | Troca as cores por posição (e a cor padrão, se dada) |
| `SetDefaultColor(cor)` | Troca a cor padrão das linhas |
| `SetAllColors(cor)` | Coloca a mesma cor em todas as linhas |
| `SetAccent(cor)` | Troca a cor de destaque |
| `SetTitleColor(cor)` / `SetDescriptionColor(cor)` | Troca a cor do título e da descrição |
| `Update(campos)` | Muda vários campos de uma vez: `title`, `description`, `tag`, `disabled`, `visible`, `accent`, `colors`, `defaultColor`, `info` |
| `SetDisabled(estado)` | Ativa ou desativa o card |
| `SetVisible(estado)` | Mostra ou esconde |
| `Refresh()` | Recarrega as imagens e refaz as linhas |
| `RefreshTheme()` | Reaplica as cores do tema |
| `Destroy()` | Remove o card |

#### 4.6.6 Comportamento

- `UpdateInfo` refaz só aquela linha. `SetInfo`, `RemoveInfo` e `AddInfo` com posição refazem todas, e as barras animam de novo. Para atualizar valores em loop, use `UpdateInfo` e só quando o valor mudar.
- A barra mostra `valor/max  •  porcentagem` e anima ao aparecer. Sem `max` maior que 0, a linha vira texto.
- Linhas sem texto e sem imagem ficam escondidas.
- O card acompanha o tema sozinho. Cores dadas por nome mudam com o tema claro ou escuro.
- Quando a section ou a janela é destruída, o Paragraph limpa as conexões sozinho.

---

### 4.7 Hologram

Preview em 3D dentro do painel. Mostra o **personagem de um jogador** (o seu ou o de outro), um **modelo**, uma **tool**, um **mapa** ou um **material**. Também mostra **imagens**: id de item, link, thumbnail, textura e a foto do avatar.

O boneco gira sozinho e acompanha em tempo real as poses e animações do original. Dá para arrastar para girar e usar a rodinha para dar zoom. O título e a descrição ficam logo abaixo da imagem, e a descrição quebra de linha quando é grande. Não tem auto save.

O holograma é uma **cópia** desenhada dentro do painel. Ele não mexe em nada do jogo.

Funciona em PC e celular.

#### 4.7.1 Criar

```lua
-- // Tab
local HoloTab = Window:CreateTab({
    tab = "Hologram",
    section = "Librarys",
    icon = "scan",
})

local HoloSection = HoloTab:CreateSection("Hologram")

-- // Vazio (carrega depois com Load)
local holo = HoloSection:CreateHologram({
    title = "Preview",
    placeholder = "Nenhum item",
})

-- // Seu personagem
local holoMeu = HoloSection:CreateHologram({
    player = game.Players.LocalPlayer,
})

-- // Outro jogador pelo nome
local holoOutro = HoloSection:CreateHologram({
    player = "Fulano",
    height = 220,
})

-- // Com título e descrição
local holoInfo = HoloSection:CreateHologram({
    title = "Meu personagem",
    description = "Atualiza quando eu renascer",
    player = game.Players.LocalPlayer,
})

-- // Modelo, imagem e material
local holoCarro = HoloSection:CreateHologram({ target = workspace.Car })
local holoItem = HoloSection:CreateHologram({ target = 123456789 })
local holoMaterial = HoloSection:CreateHologram({ target = Enum.Material.Neon })
```

Cada exemplo acima é independente. Criar outro Hologram com o mesmo título na mesma section substitui o anterior (veja 4.0), então use títulos diferentes quando quiser vários na mesma section.

O alvo pode vir em qualquer uma destas opções: `target`, `item`, `map`, `player`, `source`, `icon`, `image` ou `id` (também com a primeira letra maiúscula). Sem alvo, o card mostra o `placeholder`.

#### 4.7.2 Opções

| Opção | Tipo | Padrão | Descrição |
|-------|------|--------|-----------|
| `target` | qualquer | nenhum | O que mostrar (veja 4.7.3) |
| `list` | table | nenhum | Lista de alvos (veja 4.7.8). Também `List`, `items`, `Items` |
| `start` | number | `1` | Posição inicial da lista (também `Start`) |
| `title` | string | automático | Título (também `Title`) |
| `description` | string | automático | Descrição (também `desc`, `Description`) |
| `placeholder` | string | `"No item loaded"` | Texto quando não há nada carregado (também `Placeholder`) |
| `height` | number | `180` | Altura da área da imagem, de `90` a `500` (também `Height`). O título e a descrição ficam embaixo e o card cresce |
| `view` | string | `"Auto"` | `"Auto"`, `"Hologram"` ou `"Image"` (veja 4.7.3) |
| `style` | string | automático | Tipo da imagem: `"Asset"`, `"Avatar"`, `"bust"`... (veja 4.7.6) |
| `follow` | boolean | `true` | Recarrega o personagem quando o jogador renasce (veja 4.7.4) |
| `spin` | boolean | `true` | Gira sozinho |
| `spinSpeed` | number | `30` | Graus por segundo |
| `draggable` | boolean | `true` | Arrastar gira e a rodinha dá zoom |
| `zoom` | number | `1` | Zoom inicial, de `0.25` a `3` |
| `yaw` | number | `0` | Giro inicial, em graus |
| `pitch` | number | `20` | Inclinação inicial, de `-85` a `85` |
| `tint` | boolean | `false` | Pinta o modelo com efeito de holograma (veja 4.7.10) |
| `color` | Color3 | `RGB(110, 190, 255)` | Cor do holograma quando `tint` está ligado |
| `live` | boolean | `true` | Acompanha o original em tempo real |
| `liveRate` | number | automático | Atualizações por segundo (veja 4.7.10) |
| `maxParts` | number | `2500` | Limite de parts copiadas |
| `skipInvisible` | boolean | `true` | Ignora parts totalmente transparentes |
| `excludePlayers` | boolean | `true` | Em mapas, ignora os personagens dos jogadores |
| `channel` | string | `"ColorMap"` | Textura lida de um `SurfaceAppearance` (veja 4.7.6) |
| `fetchInfo` | boolean | `true` | Busca o nome e a descrição de itens (veja 4.7.6) |
| `visible` | boolean | `true` | Mostra ou esconde o card (também `Visible`) |
| `callback` | function | nenhum | Chamado quando algo termina de carregar (veja 4.7.11). Também `Callback`, `onLoaded`, `OnLoaded` |
| `onFail` | function(mensagem) | nenhum | Chamado quando falha. Também `OnFail`, `onError`, `OnError` |
| `onClear` | function() | nenhum | Chamado quando o holograma é limpo (também `OnClear`) |

#### 4.7.3 O que o holograma aceita

O método `Load(alvo)` escolhe sozinho como mostrar, pelo tipo do alvo:

| Você passa | O que aparece |
|------------|---------------|
| `Player`, como `game.Players.LocalPlayer` | Holograma do personagem do jogador |
| Personagem de um jogador ou o `Humanoid` dele | Holograma do jogador dono do personagem |
| Texto com nome, display name ou `"@usuario"` | Holograma do jogador que está no servidor. Se ele não estiver, a foto do avatar pelo nome |
| `Model`, `BasePart`, `Tool`, `MeshPart` | Holograma do modelo |
| `Folder`, `Workspace`, `Terrain` | Holograma do mapa |
| Caminho em texto, como `"Workspace.Map.Car"` | Procura a partir de `game` e mostra pelo tipo do que achou |
| `Enum.Material.Neon` e outros | Esfera com o material |
| Id numérico, `"rbxassetid://id"`, link, `rbxthumb://` ou `"estilo:id"` | Imagem (veja 4.7.6) |
| `Decal`, `Texture`, `ImageLabel`, `ImageButton`, `SurfaceAppearance`, `Shirt`, `Pants`, `ShirtGraphic` | Imagem da textura |
| `ObjectValue` | O que estiver em `Value` |
| `IntValue`, `NumberValue`, `StringValue` | O valor, lido como acima. Vazio ou `0` mostra erro |
| function | É chamada na hora e o retorno é lido como acima |

Um item de **lista** também pode ser uma tabela com `target`, `title`, `description`, `view` e `style` (veja 4.7.8).

**`view`** muda o jeito de mostrar:

| `view` | Efeito |
|--------|--------|
| `"Auto"` | Escolhe pelo tipo do alvo (padrão) |
| `"Hologram"` (`"holo"`, `"model"`) | Só aceita alvos em 3D. Uma imagem mostra o erro `target cannot be shown as hologram.` |
| `"Image"` (`"icon"`, `"thumbnail"`, `"thumb"`, `"texture"`) | Força a imagem. Jogador vira foto do avatar. Instância vira textura ou ícone |

```lua
-- // Trocar o modo
holo:SetView("Image")
holo:SetView("Hologram")
holo:SetView(nil)
```

#### 4.7.4 Mostrar jogadores (o seu e outros)

```lua
-- // Meu personagem
holo:Load(game.Players.LocalPlayer)

-- // Meu personagem direto
holo:Load(game.Players.LocalPlayer.Character)

-- // Outro jogador pelo objeto
holo:Load(game.Players:FindFirstChild("Fulano"))

-- // Outro jogador pelo nome, display name ou @usuario
holo:Load("Fulano")
holo:Load("@fulano")

-- // Foto do avatar em vez do boneco
holo:SetView("Image")
holo:SetStyle("Avatar")
holo:Load(game.Players.LocalPlayer)
```

- O título automático é o **display name** e a descrição é o **@usuario**.
- O holograma espera o personagem carregar (até 10 segundos) e a aparência dele (até 5 segundos).
- O nome em texto aceita parte do começo do nome, com pelo menos 3 letras.
- Com `follow = true` (padrão), o holograma recarrega sozinho quando o jogador renasce. `holo:StopFollow()` para de recarregar e `holo:GetPlayer()` retorna o jogador seguido.
- Acessórios e roupas aparecem. Scripts, sons, GUIs, joints e o `Humanoid` não vão para a cópia.
- Se o nome não for de ninguém no servidor, o holograma tenta a foto do avatar pelo nome do usuário. Se o usuário também não existir, aparece `target not found.`
- Se o jogador não tiver personagem depois da espera, aparece `character not found.`
- Para ver outro jogador **e** o seu ao mesmo tempo, crie dois hologramas.

#### 4.7.5 Mostrar modelos, tools e mapas

```lua
-- // Modelo pelo objeto
holo:Load(workspace.Car)

-- // Caminho em texto
holo:Load("Workspace.Map.Car")

-- // Tool da mochila
holo:Load(game.Players.LocalPlayer.Backpack:FindFirstChildOfClass("Tool"))

-- // Mapa
holo:Load(workspace.Map)
```

- Todas as `BasePart` viram cópias fixas dentro do holograma. Uma `Tool` usa a `Handle` como centro.
- O holograma acompanha o original em tempo real: posição, tamanho, transparência, cor e material. Parts que entram ou saem do original entram e saem da cópia.
- Em **mapas** (`Folder`, `Workspace`), os personagens dos jogadores ficam de fora (`excludePlayers`). O `Terrain` não é desenhado, só as parts.
- Se passar de `maxParts`, o holograma mostra o limite e avisa `has too many parts`. Modelo sem nenhuma part mostra `nothing to display.`

#### 4.7.6 Mostrar imagens

```lua
-- // Id de item
holo:Load(123456789)
holo:Load("123456789")
holo:Load("rbxassetid://123456789")

-- // Estilo na hora de carregar
holo:SetStyle("bust")
holo:Load(1)

-- // Estilo dentro do texto
holo:Load("bust:1")
holo:Load("badge:2124475411")

-- // Tabela
holo:Load({ id = 1, style = "headshot" })
holo:Load({ userId = 1 })

-- // Link do site
holo:Load("https://www.roblox.com/catalog/123456789/Item")

-- // Textura de uma instância
holo:Load(workspace.Part.Decal)
```

**Estilos** (`style` ou o texto antes dos dois-pontos):

| Estilo | Tipo de imagem | Observação |
|--------|----------------|------------|
| `"Asset"`, `"item"` | Item | Padrão para ids soltos |
| `"Avatar"`, `"full"` | Avatar de corpo inteiro | |
| `"user"`, `"headshot"`, `"AvatarHeadShot"` | Foto do rosto | Padrão para jogadores e `userId` |
| `"bust"`, `"AvatarBust"` | Busto | |
| `"pass"`, `"gamepass"` | Game pass | |
| `"badge"`, `"BadgeIcon"` | Ícone de badge | |
| `"bundle"`, `"BundleThumbnail"` | Bundle | |
| `"group"`, `"GroupIcon"` | Ícone de grupo | |
| `"outfit"` | Outfit | |

**Links reconhecidos:** `/catalog/id` e `/library/id` (item), `/bundles/id`, `/game-pass/id`, `/users/id` (foto do rosto), `/badges/id`, `/groups/id`, `/communities/id` e `?id=` (item). Outro link mostra `unsupported link.`

- A imagem mantém a proporção original e preenche a altura da área, com uma margem pequena em cima e embaixo.
- Se a thumbnail de um item não carregar em 4 segundos, o holograma tenta `rbxassetid://`. Passados 8 segundos sem carregar, mostra `Nothing to display`.
- Com `fetchInfo = true`, o título e a descrição de itens, game passes e bundles vêm do próprio item. Título e descrição que você definir têm prioridade.
- `channel` escolhe a textura de um `SurfaceAppearance`: `"ColorMap"`, `"NormalMap"`, `"MetalnessMap"` ou `"RoughnessMap"`.
- Texturas de instâncias acompanham a propriedade: se o `Image` ou a `Texture` mudar no jogo, a imagem muda junto.
- Com `view = "Image"`, uma instância usa o attribute `AssetId`, `ImageId`, `Image`, `Icon`, `Thumbnail`, `TextureId` ou `Id`, ou a primeira textura que achar dentro dela.

#### 4.7.7 Mostrar materiais

```lua
-- // Material
holo:Load(Enum.Material.Neon)
holo:Load(Enum.Material.Glass)
```

Mostra uma esfera cinza com o material. O título automático é o nome do material, e `tint` pinta a esfera com a cor do holograma.

#### 4.7.8 Lista de alvos

Uma lista deixa o mesmo card trocar entre vários alvos.

```lua
-- // Lista simples
holo:LoadList({
    game.Players.LocalPlayer,
    "Fulano",
    "Ciclano",
})

-- // Lista com título, descrição, modo e estilo por item
holo:LoadList({
    { target = workspace.Car, title = "Carro", description = "Modelo do carro" },
    { target = 123456789, title = "Espada", view = "Image" },
    { target = 1, title = "Busto", style = "bust" },
}, 2)

-- // Navegar
holo:Next()
holo:Prev()
holo:Select(1)

print(holo:GetIndex(), holo:GetCount())
```

- `Next` e `Prev` voltam ao começo ou ao fim quando passam da lista.
- `Load` e `Clear` esvaziam a lista.
- O segundo valor de `LoadList` é a posição inicial. Sem ele começa no `1`.

```lua
-- // Botões de navegação
HoloSection:CreateButton({
    title = "Anterior",
    callback = function()
        holo:Prev()
    end,
})

HoloSection:CreateButton({
    title = "Próximo",
    callback = function()
        holo:Next()
    end,
})
```

#### 4.7.9 Título e descrição

O título e a descrição ficam **logo abaixo da imagem**. O título ocupa uma linha e corta com `...` se passar da largura. A descrição quebra de linha e o card cresce para baixo. Sem título e sem descrição, o rodapé some.

O texto mostrado vem de três fontes, nesta ordem de prioridade:

| Ordem | Fonte | Exemplo |
|-------|-------|---------|
| 1 | Item da lista ou `Load(alvo, titulo, descricao)` | `{ target = x, title = "Carro" }` |
| 2 | Opção ou método manual | `title = "Preview"` ou `SetTitle` |
| 3 | Automático | Jogador: display name e `@usuario`. Modelo: nome. Item: nome e descrição do item |

```lua
-- // Junto com o Load
holo:Load(workspace.Car, "Carro", "Modelo do carro")
holo:Load(workspace.Car, { title = "Carro", description = "Modelo do carro" })

-- // Manual
holo:SetTitle("Novo título")
holo:SetDescription("Texto grande que quebra de linha sozinho e empurra o card para baixo")
holo:SetInfo("Título", "Descrição")

-- // Voltar ao automático
holo:SetTitle(nil)
holo:SetDescription(nil)
```

#### 4.7.10 Visualização, cor e tempo real

```lua
-- // Girar e zoom
holo:SetSpin(true)
holo:SetSpinSpeed(60)
holo:SetZoom(1.5)
holo:SetRotation(45, 20)

-- // Efeito de holograma
holo:SetTint(true)
holo:SetColor(Color3.fromRGB(255, 120, 120))

-- // Tempo real
holo:SetLive(true)
holo:SetLiveRate(15)
holo:Sync()
```

- **Girar:** `spin` gira sozinho e pausa enquanto você arrasta.
- **Arrastar e zoom:** com `draggable`, arrastar gira (esquerda e direita, cima e baixo) e a rodinha muda o zoom de `0.25` a `3`. O zoom também funciona em imagens.
- **Tint:** pinta todas as parts com material `ForceField` na cor definida. Vale também para parts que entrarem depois.
- **Tempo real:** o holograma só atualiza com o card visível e em modo 3D. A taxa padrão é `30` por segundo para jogadores, `20` para modelos, `4` para mapas e `10` para o resto. `SetLive(false)` congela a cópia.
- **Sync:** força uma atualização na hora.

```lua
-- // Controles por elements
local ControlSection = HoloTab:CreateSection("Controles")

ControlSection:CreateToggle({
    title = "Girar",
    default = true,
    callback = function(state)
        holo:SetSpin(state)
    end,
})

ControlSection:CreateToggle({
    title = "Efeito holograma",
    default = false,
    callback = function(state)
        holo:SetTint(state)
    end,
})

ControlSection:CreateSlider({
    title = "Zoom",
    min = 0.25,
    max = 3,
    default = 1,
    rounding = 2,
    callback = function(value)
        holo:SetZoom(value)
    end,
})

ControlSection:CreateColorPicker({
    title = "Cor",
    default = Color3.fromRGB(110, 190, 255),
    callback = function(color)
        holo:SetColor(color)
    end,
})
```

#### 4.7.11 Callbacks

```lua
-- // Ao carregar
local holo = HoloSection:CreateHologram({
    player = game.Players.LocalPlayer,
    callback = function(alvo, objeto, holograma, tipo, spec)
        print("Carregou:", tipo, alvo)
    end,
    onFail = function(mensagem)
        print("Falhou:", mensagem)
    end,
    onClear = function()
        print("Limpou")
    end,
})
```

| Callback | Recebe | Quando |
|----------|--------|--------|
| `callback` | `alvo, objeto, holograma, tipo, spec` | Cada vez que termina de carregar |
| `onFail` | `mensagem` | Quando o alvo não pode ser mostrado |
| `onClear` | nada | Quando o holograma é limpo |

O que o `callback` recebe:

| Valor | Descrição |
|-------|-----------|
| `alvo` | O que foi carregado: personagem, modelo, material ou o valor da imagem |
| `objeto` | A cópia (`Model`) em 3D, ou o `ImageLabel` em imagens |
| `holograma` | O próprio holograma, para chamar métodos |
| `tipo` | `"Player"`, `"Model"`, `"Map"`, `"Material"` ou `"Image"` |
| `spec` | Só em imagens: tabela com `Image`, `Name`, `Description`, `Kind` e `Id` |

Erros dentro de um callback viram notificação e não derrubam o script. Falhas aparecem como notificação `Hologram 'Título': mensagem` (uma vez por mensagem) e também em `warn`. Mensagens comuns:

| Mensagem | Significado |
|----------|-------------|
| `target not found.` | O alvo não existe |
| `player not found.` | Jogador não encontrado |
| `character not found.` | O jogador não tem personagem |
| `'Nome' has no image.` | A instância não tem imagem |
| `'Nome' is empty.` | O `ObjectValue` ou o valor está vazio |
| `unsupported link.` | Link que o holograma não reconhece |
| `target cannot be shown as hologram.` | Imagem com `view = "Hologram"` |
| `nothing to display.` | Modelo sem nenhuma part |
| `invalid view`, `invalid style`, `invalid channel`, `invalid color` | Valor inválido em um `Set` |

#### 4.7.12 Métodos

**Carregar**

| Método | Descrição |
|--------|-----------|
| `Load(alvo, titulo, descricao)` | Carrega o alvo. `Load(nil)` limpa. A descrição e o título são opcionais (também aceita uma tabela `{ title, description }` no lugar do título). Retorna `true` se começou a carregar |
| `Update(tabela)` | Muda várias opções de uma vez e carrega o alvo ou a lista se vierem. Aceita `title`, `description`, `placeholder`, `channel`, `fetchInfo`, `color`, `tint`, `spin`, `spinSpeed`, `zoom`, `height`, `visible`, `style`, `view` e o alvo (`target`, `player`...) ou `list` |
| `LoadList(lista, inicio)` | Carrega uma lista de alvos (4.7.8) |
| `Select(posicao)` | Vai para o item da lista |
| `Next()` / `Prev()` | Próximo e anterior |
| `Reload()` | Carrega de novo o alvo atual |
| `Clear()` | Limpa o holograma e mostra o `placeholder` |
| `Sync()` | Atualiza a cópia agora |
| `StopFollow()` | Para de recarregar o personagem quando o jogador renasce |

**Consultar**

| Método | Descrição |
|--------|-----------|
| `GetTarget()` | Último alvo pedido |
| `GetLoaded()` | Instância carregada (personagem, modelo ou textura) |
| `GetSpec()` | Dados da imagem atual |
| `GetName()` | Nome automático |
| `GetKind()` | Tipo carregado (`nil` se vazio) |
| `GetPlayer()` | Jogador que está sendo seguido |
| `GetIndex()` / `GetCount()` | Posição atual e tamanho da lista |
| `IsLoading()` | Retorna se está carregando |
| `IsDestroyed()` | Retorna se foi destruído |

**Modo e imagem**

| Método | Descrição |
|--------|-----------|
| `SetView(valor)` / `GetView()` | Troca e lê o modo. `nil` volta para `"Auto"` |
| `SetStyle(valor)` / `GetStyle()` | Troca e lê o estilo da imagem. `nil` remove |
| `SetChannel(valor)` | Troca a textura do `SurfaceAppearance` |
| `SetFetchInfo(estado)` | Liga ou desliga a busca de nome e descrição |

**Visualização**

| Método | Descrição |
|--------|-----------|
| `SetSpin(estado)` / `GetSpin()` | Liga ou desliga o giro |
| `SetSpinSpeed(valor)` | Graus por segundo |
| `SetZoom(valor)` / `GetZoom()` | Troca e lê o zoom (`0.25` a `3`) |
| `SetRotation(yaw, pitch)` | Define o giro e a inclinação |
| `SetTint(estado)` / `GetTint()` | Liga ou desliga o efeito de holograma |
| `SetColor(cor)` / `GetColor()` | Troca e lê a cor do holograma |
| `SetLive(estado)` / `GetLive()` | Liga ou desliga o tempo real |
| `SetLiveRate(valor)` | Atualizações por segundo |
| `SetMaxParts(valor)` | Limite de parts |
| `SetPlaceholder(texto)` | Troca o texto de vazio |

**Texto e card**

| Método | Descrição |
|--------|-----------|
| `SetTitle(texto)` / `GetTitle()` | Troca e lê o título. `nil` volta ao automático |
| `SetDescription(texto)` / `GetDescription()` | Troca e lê a descrição. `nil` volta ao automático |
| `SetInfo(titulo, descricao)` | Troca os dois de uma vez |
| `SetHeight(valor)` | Altura da área da imagem (`90` a `500`) |
| `SetVisible(estado)` | Mostra ou esconde o card |
| `SetCallback(funcao)` | Troca o `callback` |
| `SetOnFail(funcao)` / `SetOnClear(funcao)` | Troca o `onFail` e o `onClear` |
| `Destroy()` | Remove o card e desconecta tudo |

#### 4.7.13 Propriedades

Estas propriedades podem ser lidas e escritas direto no holograma:

```lua
-- // Propriedades
holo.Zoom = 2
holo.Spin = false
holo.Tint = true
holo.Title = "Novo título"
holo.Description = "Nova descrição"
holo.View = "Image"
holo.Style = "bust"
holo.Height = 220
holo.Visible = true
holo.Target = game.Players.LocalPlayer

print(holo.Zoom, holo.Target)
```

| Propriedade | Equivale a |
|-------------|------------|
| `Title`, `Description` | `SetTitle` e `SetDescription` |
| `Target` | `Load` (escrever) e `GetTarget` (ler) |
| `View`, `Style` | `SetView` e `SetStyle` |
| `Spin`, `Zoom`, `Tint` | `SetSpin`, `SetZoom` e `SetTint` |
| `Height`, `Visible` | `SetHeight` e `SetVisible` |

`holo.Frame` e `holo.Instance` devolvem o `Frame` do card.

#### 4.7.14 Exemplo: meu personagem e outros jogadores

```lua
-- // Hologram
local holo = HoloSection:CreateHologram({
    height = 200,
    player = game.Players.LocalPlayer,
})

-- // Jogadores
local PlayersSection = HoloTab:CreateSection("Jogadores")

local function nomes()
    local lista = {}

    for _, player in ipairs(game.Players:GetPlayers()) do
        lista[#lista + 1] = player.Name
    end

    return lista
end

local dropdown = PlayersSection:CreateDropdown({
    title = "Jogador",
    values = nomes(),
    default = game.Players.LocalPlayer.Name,
    callback = function(nome)
        holo:Load(nome)
    end,
})

PlayersSection:CreateButton({
    title = "Meu personagem",
    callback = function()
        dropdown:Set(game.Players.LocalPlayer.Name)
    end,
})

PlayersSection:CreateButton({
    title = "Atualizar lista",
    callback = function()
        dropdown:SetValues(nomes())
    end,
})

-- // Foto do avatar
PlayersSection:CreateToggle({
    title = "Mostrar foto",
    default = false,
    callback = function(state)
        holo:SetView(state and "Image" or "Auto")
    end,
})
```

#### 4.7.15 Comportamento

- O holograma só gasta processamento com o card visível e com um modelo carregado. Imagens não rodam loop.
- Carregar um alvo novo cancela o anterior, mesmo que ele ainda esteja carregando.
- Scripts, sons, GUIs, joints, constraints e `Humanoid` não vão para a cópia.
- `Update` e os métodos `Set...` podem ser chamados antes do element terminar de carregar: ficam na fila (veja 4.0).
- Quando a section ou a janela é destruída, o holograma desconecta tudo sozinho.

---

## 5. Themes

O tema muda só a **interface do painel**: fundo da janela, cor das sections (onde ficam os elements), pesquisa, configurações, bordas e destaques. Os textos (nome da section, nome da tab, título, nomes dos elements que não usam a cor de destaque) continuam normais.

Para trocar, abra as **configurações** (engrenagem) e escolha em **Themes > Theme**. A escolha fica salva. Ou pelo código:

```lua
-- // Trocar tema
Window:SetTheme("Blue")
Window:SetTheme("Default")

print(Window.ThemeName)
```

`SetTheme` retorna `true` se o tema foi aplicado.

### Onde ficam os temas

Na pasta `Themes` do GitHub. O nome do tema é o nome do arquivo sem a extensão (`Blue.luau` vira `Blue`). Valem `.luau`, `.lua` e `.json`. O tema `Default` é o padrão da library e não precisa de arquivo. Os primeiros 24 temas são baixados em segundo plano, então trocar é rápido.

```lua
-- // Themes/Blue.luau
return {
    -- // Window
    Background = Color3.fromRGB(10, 18, 28),
    Divider = Color3.fromRGB(30, 50, 76),
    Subtitle = Color3.fromRGB(150, 150, 150),

    -- // Elements
    GradientTop = Color3.fromRGB(20, 34, 52),
    GradientBottom = Color3.fromRGB(12, 22, 34),
    Palette = Color3.fromRGB(14, 24, 38),
    Field = Color3.fromRGB(18, 30, 46),
    Accent = Color3.fromRGB(28, 48, 74),
    Border = Color3.fromRGB(36, 58, 88),
    BorderHover = Color3.fromRGB(64, 100, 150),
    Active = Color3.fromRGB(59, 130, 246),
    Text = Color3.fromRGB(255, 255, 255),
    Inactive = Color3.fromRGB(140, 165, 195),
    Dim = Color3.fromRGB(90, 115, 145),
    Placeholder = Color3.fromRGB(80, 104, 134),

    -- // Tab
    TabActive = Color3.fromRGB(255, 255, 255),
    TabInactive = Color3.fromRGB(145, 145, 145),
    TabHover = Color3.fromRGB(200, 200, 200)
}
```

Nesse arquivo, `Subtitle`, `Text`, `Inactive`, `Dim`, `Placeholder` e `TabActive`, `TabInactive`, `TabHover` são ignoradas (veja abaixo). As outras cores são aplicadas.

```json
{
  "Background": "#0A121C",
  "Accent": [28, 48, 74],
  "Active": "#3B82F6"
}
```

Cada cor aceita `Color3`, hex (`"#RRGGBB"`) ou tabela `{ R, G, B }` de 0 a 255. O JSON pode vir direto ou dentro de `{ "Colors": { ... } }`. Cores que faltam ficam com o valor do `Default`.

### O que cada cor muda

| Chave | Muda |
|-------|------|
| `Background` | Fundo da janela |
| `GradientTop`, `GradientBottom` | Gradiente das sections, da pesquisa e das configurações |
| `Field` | Barra de pesquisa e campos dos elements |
| `Accent` | Tab selecionada e áreas de destaque dos elements |
| `Border`, `BorderHover` | Bordas |
| `Divider` | Linhas divisórias |
| `Palette` | Cor de paleta usada por alguns elements |
| `Active` | Cor de destaque: toggle ligado, barra do slider, brilho da pesquisa e o texto dos elements que usam `Active` (como o Paragraph) |

**Cores que o tema não muda.** `Inactive`, `Dim`, `Subtitle`, `Placeholder`, `Text`, `TabActive`, `TabInactive` e `TabHover` são ignoradas, mesmo que o arquivo tenha. Os nomes de section, o último item do caminho no topo e os resultados da pesquisa usam uma cor fixa própria (`Theme.Name`), que também não muda.

Para o tema também mudar essas cores de texto, ligue `ThemeText = true` no `Config` dentro do `Library.luau`. Ele é lido quando a library carrega, então não adianta mudar pelo script depois.

### Nos seus scripts

`Window.Theme` é uma tabela com as cores atuais e é atualizada quando o tema muda. Os elements da library já acompanham sozinhos. Em features e elements próprios, leia as cores dali:

```lua
-- // Cor atual do tema
local Theme = Window.Theme

label.TextColor3 = Theme.Active
frame.BackgroundColor3 = Theme.Background
```

Objetos criados com as cores padrão do painel também são trocados sozinhos ao mudar o tema.

---

## 6. Saves

A library salva as escolhas no arquivo `Ecohub.json`, na pasta de trabalho do executor.

```lua
-- // Estrutura (resumo)
-- Player: nome, display e UserId
-- Games: um bloco por jogo, com AutoSave (valores dos elements) e Profiles
-- Panel: AutoSave, Theme, ThemeColors, ToggleKey
-- Translations: cache de traduções
```

| O que | Salvo |
|-------|-------|
| Valores dos elements (toggle, slider, dropdown, colorpicker) | Sim, por jogo, se o **Auto Save** estiver ligado |
| Tema | Sim |
| Tecla de minimizar | Sim |
| Idioma de tradução (cache) | Sim |
| Posição da janela e do quadrado flutuante | **Não** |

- O **Auto Save** fica nas configurações (engrenagem) em **Saves** e vem ligado. Desligado, os valores dos elements não são salvos nem restaurados. Tema e tecla continuam salvos.
- Cada element é salvo por `Tab/Section/Título`. Dois elements com o mesmo nome na mesma section ganham ` #2`, ` #3`...
- Elements das configurações do painel não são salvos.
- Grava 1 segundo depois de uma mudança, a cada 20 segundos e ao destruir a janela.
- Se o arquivo estiver corrompido, a library guarda uma cópia em `Ecohub.json.bak` e começa um novo.
- Se o executor não tiver funções de arquivo, aparece um aviso e nada é salvo.

### Salvar valores seus

`Window.Save` guarda qualquer valor seu no bloco do jogo atual. Aceita `boolean`, `number`, `string`, `Color3`, `EnumItem` e tabelas com esses valores.

```lua
-- // Window.Save
Window.Save:Set("UltimaArma", "Espada")
Window.Save:Set("Cor", Color3.fromRGB(255, 0, 0))

local arma = Window.Save:Get("UltimaArma", "Nenhuma")

Window.Save:Delete("UltimaArma")
```

### Perfis

Os valores dos elements podem ser guardados em perfis, por jogo. Não há botão para isso, só código:

```lua
-- // Perfis
local Saves = Window.Saves

print(Saves:ListProfiles())
Saves:CreateProfile("Farm")
Saves:SetProfile("AutoSave")
Saves:DeleteProfile("Farm")
```

`CreateProfile` copia os valores atuais e já ativa o perfil. `SetProfile` salva o atual e aplica o outro. O perfil `AutoSave` é o padrão e não pode ser apagado.

---

## 7. Settings do painel e Notificações

### Settings

A engrenagem do topo abre as configurações do painel (**Themes** e **Saves**). Dá para criar sections suas ali:

```lua
-- // Settings
local MinhaSection = Window:CreateSettingsSection("Meu Hub")

MinhaSection:CreateToggle({
    title = "Mostrar FPS",
    default = false,
    callback = function(state)
        print("FPS:", state)
    end,
})

MinhaSection:CreateButton({
    title = "Resetar tudo",
    callback = function()
    end,
})
```

Os elements das configurações funcionam como os normais, mas **não entram no auto save**.

### Notificações

```lua
-- // Notify
Window:Notify({
    Title = "Hub",
    Description = "Script carregado",
    Duration = 5,
})

Window:Notify("Só um texto")
```

| Opção | Descrição |
|-------|-----------|
| `Title` | Título |
| `Description` | Texto |
| `Type` | Tipo. A library usa `"Error"` e `"Warning"` |
| `Duration` | Segundos na tela |
| `RichText` | Liga o RichText no texto |

O módulo de notificação é baixado na primeira vez que alguém usa. Até lá as notificações esperam em fila (máximo 20). Se o download falhar, elas são descartadas e o motivo aparece no console.

A library mostra notificações sozinha quando algo falha: `Element failed`, `Element missing`, `Feature failed`, `Callback`, `Theme failed`, `Save failed` e outras.

---

## 8. Features

Uma feature é um script que fica na pasta `Features` do GitHub e é carregado pela janela. Ele recebe a janela e a library:

```lua
-- // Features/Status.luau
local Window, Library = ...

local Tab = Window:CreateTab({ tab = "Status", icon = "activity" })
local Section = Tab:CreateSection("Info")

Section:CreateButton({
    title = "Oi",
    callback = function()
        print("oi")
    end,
})

-- // Unload
getgenv().StatusUnload = function()
    print("descarregado")
end
```

`Window` e `Librarys` também ficam como variáveis globais enquanto a feature roda.

### Carregar

```lua
-- // Carregar
Window:LoadFeature("Status")
Window:LoadFeature("Farm/Auto")
Window:LoadFeature("Farm/")
Window:LoadFeature("https://github.com/usuario/repo/blob/main/Teste.lua")
Window:LoadFeature("Status", { Reload = true })

Window:LoadFeatures({ "Status", "Farm/Auto" })
Window:LoadAllFeatures()
Window:PreloadFeatures({ "Status", "Farm/Auto" })
```

| Nome | Carrega |
|------|---------|
| `"Status"` | O arquivo `Status.lua` ou `Status.luau` (acha pelo nome em qualquer pasta) |
| `"Farm/Auto"` | O arquivo dentro da pasta `Farm` |
| `"Farm/"` | Todos os arquivos da pasta `Farm` |
| URL | O link. Links `github.com/.../blob/...` viram o link raw sozinhos |

- `LoadFeature` retorna `true` se deu certo. `LoadFeatures` retorna `{ [nome] = boolean }` e `LoadAllFeatures` retorna `{ [caminho] = boolean }`.
- Carregar uma feature que já está carregada não faz nada. Com `{ Reload = true }` ela é descarregada e carregada de novo.
- `PreloadFeatures` só baixa antes, para carregar mais rápido depois.
- Pastas carregadas e `LoadAllFeatures` ficam **vigiadas**: a cada 20 segundos a library confere o GitHub e carrega arquivos novos sozinha.
- O download tenta vários espelhos ao mesmo tempo, valida o arquivo (menor que 8 MB, que compile e que não seja uma página web) e repete se falhar.
- Se a feature demorar mais de 8 segundos para terminar, a janela segue em frente e ela continua rodando. Erros que acontecerem depois aparecem como `Feature failed`.

### Descarregar e listar

```lua
-- // Descarregar
Window:UnloadFeature("Status")
Window:UnloadAllFeatures()

-- // Listar
print(Window:GetLoadedFeatures())
print(Window:IsFeatureLoaded("Status"))
print(Window:ListFeatures())
Window:RefreshFeatures()
```

| Método | Descrição |
|--------|-----------|
| `UnloadFeature(nome)` | Chama `getgenv().<Nome>Unload` (se existir) e remove os elements da feature |
| `UnloadAllFeatures()` | Faz isso com todas, da última para a primeira |
| `GetLoadedFeatures()` | Lista os caminhos carregados |
| `IsFeatureLoaded(nome)` | Retorna se está carregada |
| `ListFeatures()` | Lista as features do GitHub |
| `RefreshFeatures()` | Baixa a lista de novo. Retorna se mudou |
| `SetFeaturesSource(url)` | Troca a pasta de onde as features vêm (link de pasta do GitHub) |
| `SetElementsSource(url)` | Troca a pasta de onde os elements vêm |

- O nome da função de unload é o nome do arquivo + `Unload`: `Status.luau` chama `StatusUnload`. Use para desconectar loops e conexões.
- Só são removidos sozinhos os elements criados **direto** pelo script da feature. Elements criados dentro de `task.spawn`, callbacks ou loops não são, então remova esses no `Unload`.
- Com `{ Reload = true }`, o `Unload` antigo é chamado antes de a feature rodar de novo.
- `Window:Destroy()` descarrega todas as features.

### Ajustes

`Window.FeatureConfig` (e `Librarys.FeatureConfig`) guarda os tempos do carregador:

| Campo | Padrão | Descrição |
|-------|--------|-----------|
| `Retries` | `3` | Tentativas de download |
| `MaxParallel` | `6` | Downloads ao mesmo tempo |
| `Timeout` | `45` | Segundos esperando uma feature |
| `AttemptTimeout` | `20` | Segundos por tentativa de download |
| `RunTimeout` | `8` | Segundos esperando a feature terminar de rodar |
| `ElementsWait` | `12` | Segundos esperando os elements carregarem antes de rodar a feature |
| `AutoWatch` | `true` | Vigiar pastas por arquivos novos |
| `WatchInterval` | `20` | Segundos entre conferências |
| `ReloadGuard` | `60` | Segundos em que executar a library de novo é ignorado se uma feature estiver carregando |

---

## 9. Idiomas

O painel traduz os próprios textos sozinho, pelo idioma do Roblox do jogador.

```lua
-- // Idioma
Window:SetLanguage("pt")
Window:SetLanguage("en")
Window:SetLanguage("auto")

print(Window:GetLanguage())
```

| Método | Descrição |
|--------|-----------|
| `SetLanguage(codigo)` | Define o idioma (`"pt"`, `"es"`, `"en"`...). `"auto"` volta para o idioma do Roblox |
| `GetLanguage()` | Retorna o idioma atual |
| `AddTranslations(tabela)` | Adiciona traduções suas |
| `Translate(texto)` | Traduz um texto |
| `TranslateGame(estado)` | Também traduz as GUIs do jogo (menos as do Ecohub) |

```lua
-- // Traduções suas
Window:AddTranslations({
    pt = {
        ["Search..."] = "Pesquisar...",
        ["Auto Farm"] = "Farm automático",
    },
})

print(Window:Translate("Auto Farm"))
Window:TranslateGame(true)
```

A tradução segue esta ordem: suas traduções, o tradutor do Roblox e, por último, uma tradução automática online. Os textos traduzidos pela tradução online são enviados para um serviço externo, e o resultado fica guardado em cache no `Ecohub.json`. Em inglês nada é traduzido.

---

## 10. Criar um element próprio

Elements ficam em `Library/Elements` no GitHub (um arquivo por element) e se registram na library. Também dá para registrar um dentro de uma feature, usando `Window.Elements`.

```lua
-- // Registrar
Window.Elements.Register("Label", function(section, options)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = options.title or ""
    label.TextColor3 = section.Panel.Theme.Active
    label.Parent = section.frame

    local data = {}

    function data:SetTitle(texto)
        label.Text = texto
    end

    function data:Destroy()
        label:Destroy()
    end

    return data
end, { Frameless = true })

-- // Usar
Section:CreateLabel({ title = "Olá" })
```

`Register(nome, builder, meta)`:

| Parte | Descrição |
|-------|-----------|
| `nome` | Nome do element. `Section:CreateNome(...)` e `Section:CreateElement("Nome", ...)` passam a funcionar |
| `builder(section, options)` | Constrói o element e retorna uma tabela com os métodos |
| `meta.Frameless` | `true` tira a margem interna (usado pelo Button, que desenha o próprio fundo) |

O que o `builder` recebe em `section`:

| Campo | Descrição |
|-------|-----------|
| `section.frame` | O Frame onde o element deve ser criado |
| `section.Panel` | A janela (`section.Panel.Theme` tem as cores) |
| `section.Tab` / `section.Section` | A tab e a section onde ele está |
| `section.Element` | O objeto interno do element |
| `section.Elements` | O registro de elements |
| `section.CreateIcon(parent, nome, tamanho, cor)` | Cria um ícone lucide |

A tabela retornada pode ter:

| Método | Para que serve |
|--------|----------------|
| `Get()` e `Set(valor)` (ou `GetValue` e `SetValue`) | Ligam o element ao auto save |
| `Destroy()` | Chamado quando o element é removido |
| qualquer outro | Fica disponível no handle: `handle:SetTitle(...)` |

- A `frame` já vem com margem interna e a altura se ajusta ao conteúdo (`AutomaticSize`). Elements com frame têm altura mínima de 38.
- Cores criadas com as cores padrão do painel são trocadas sozinhas ao mudar o tema. Para acompanhar ao vivo, leia `section.Panel.Theme`.
- Se o `builder` der erro, a library tenta de novo algumas vezes antes de desistir e mostra `Element failed`.
- O handle aceita chamadas antes do element existir: elas ficam na fila e rodam depois.

Outras funções do registro:

```lua
-- // Registro
print(Window.Elements.List())
print(Window.Elements.Get("Slider"))
Window:LoadElements(true)
```

`List()` retorna os nomes registrados. `Get(nome)` retorna o registro. `LoadElements(true)` baixa e registra os elements de novo.

Nos arquivos de `Library/Elements`, as variáveis `Elements` e `Panel` já existem (`local Elements, Panel = ...`).

---

## 11. Exemplo completo: aba Status

Player Card e card do servidor, lado a lado (duas sections = duas colunas). Atualiza a cada 1 segundo, trocando só as linhas que mudaram.

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

local PlayerSection = ParaTab:CreateSection("Jogador")
local ServerSection = ParaTab:CreateSection("Servidor")

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

-- // Troca só o que mudou (UpdateInfo refaz a linha)
local last = {}

local setRow = function(card, index, value, max)
    local stamp = tostring(value) .. "/" .. tostring(max)

    last[card] = last[card] or {}

    if last[card][index] == stamp then
        return
    end

    last[card][index] = stamp

    if max then
        card:UpdateInfo(index, { value = value, max = max })
    else
        card:UpdateInfo(index, value)
    end
end

-- // Player Card
local playerCard = PlayerSection:CreateParagraph({
    title = player.DisplayName .. " (@" .. player.Name .. ")",
    tag = "PLAYER",
    description = "Live status",
    rule = true,
    info = {
        { type = "header", text = "Personagem" },                       -- 1
        { label = "Health", value = 0, max = 100, color = "green" },    -- 2
        { label = "Level", value = 0, inline = true },                  -- 3
        { label = "Rank", value = "Player", inline = true },            -- 4
        { label = "Velocidade", value = 0, inline = true },             -- 5
        { label = "Pulo", value = 0, inline = true },                   -- 6
        { label = "Posição", value = "0, 0, 0", inline = true },        -- 7
        { type = "divider" },                                           -- 8
        { type = "header", text = "Conta" },                            -- 9
        { label = "UserId", value = player.UserId, inline = true },     -- 10
        { label = "Conta", value = player.AccountAge .. " dias", inline = true }, -- 11
        { label = "Dispositivo", value = getDevice(), inline = true },  -- 12
        { label = "FPS", value = 0, inline = true },                    -- 13
        { label = "Ping", value = 0, inline = true },                   -- 14
        {
            type = "badges",                                            -- 15
            items = {
                {
                    text = player.MembershipType == Enum.MembershipType.Premium and "Premium" or "Free",
                    color = player.MembershipType == Enum.MembershipType.Premium and "yellow" or "gray",
                },
            },
        },
    },
})

-- // Servidor
local serverCard = ServerSection:CreateParagraph({
    title = "Servidor",
    tag = "INFO",
    description = "Informações do servidor",
    rule = true,
    info = {
        { label = "Jogo", value = gameName, inline = true },                           -- 1
        { label = "Jogadores", value = 1, max = Players.MaxPlayers, color = "blue" },  -- 2
        { label = "Tempo ativo", value = "00:00:00", inline = true },                  -- 3
        { label = "Hora", value = os.date("%H:%M:%S"), inline = true },                -- 4
        { label = "Ping", value = 0, inline = true },                                  -- 5
        { label = "FPS", value = 0, inline = true },                                   -- 6
        { label = "PlaceId", value = game.PlaceId, inline = true },                    -- 7
        { label = "Versão", value = game.PlaceVersion, inline = true },                -- 8
    },
})

-- // Atualização
local refresh = function()
    local humanoid = getHumanoid()
    local root = getRoot()
    local position = root and root.Position or Vector3.zero

    playerCard:SetTag(player.Character and "ONLINE" or "CARREGANDO")

    setRow(playerCard, 2, humanoid and math.floor(humanoid.Health) or 0, humanoid and math.floor(humanoid.MaxHealth) or 100)
    setRow(playerCard, 3, getLeaderstat(player, "Level", "Lv", "Nivel") or 0)
    setRow(playerCard, 4, tostring(getLeaderstat(player, "Rank") or "Player"))
    setRow(playerCard, 5, humanoid and math.floor(humanoid.WalkSpeed) or 0)
    setRow(playerCard, 6, humanoid and math.floor(humanoid.JumpPower) or 0)
    setRow(playerCard, 7, string.format("%d, %d, %d", position.X, position.Y, position.Z))
    setRow(playerCard, 13, fps)
    setRow(playerCard, 14, getPing())

    setRow(serverCard, 2, #Players:GetPlayers(), Players.MaxPlayers)
    setRow(serverCard, 3, formatTime(workspace.DistributedGameTime))
    setRow(serverCard, 4, os.date("%H:%M:%S"))
    setRow(serverCard, 5, getPing())
    setRow(serverCard, 6, fps)
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

> O `StatusUnload` é chamado automaticamente quando a feature `Status` é descarregada (veja a seção 8). Isso desconecta o loop e evita lag depois de fechar o hub.

> As duas sections da tab aparecem lado a lado. Se fosse só uma, ela ocuparia a largura toda.

---

## 12. Referência rápida

```lua
-- // Window
local Window = Librarys:CreateWindow({
    Title = "Hub",
    SubTitle = "by x",
    Size = UDim2.fromOffset(620, 350),
    MinimizeKey = Enum.KeyCode.RightShift,
})

-- // Tab e Section
local Tab = Window:CreateTab({
    tab = "Nome",
    section = "Grupo",
    icon = "icone",
    layout = "Default",
})

local Section = Tab:CreateSection("Titulo")
```

```lua
-- // Elements
Section:CreateToggle({
    title = "X",
    default = false,
    keybind = Enum.KeyCode.G,
    callback = function(state)
    end,
})

Section:CreateButton({
    title = "X",
    size = "default",
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

Section:CreateDropdown({
    title = "X",
    values = { "A", "B", "C" },
    default = { "A" },
    multi = true,
    callback = function(lista)
    end,
})

Section:CreateColorPicker({
    title = "X",
    default = Color3.new(1, 1, 1),
    callback = function(color, alpha)
    end,
})

local card = Section:CreateParagraph({
    title = "X",
    tag = "TAG",
    description = "Texto",
    info = {
        { label = "Level", value = 1, inline = true },
        { label = "Health", value = 80, max = 100 },
        { type = "header", text = "Grupo" },
        { type = "divider" },
        { type = "badges", items = { "A", "B" } },
    },
})

card:UpdateInfo(1, 2)
card:SetDescription("Novo")
card:SetTag("OK")

local holo = Section:CreateHologram({
    title = "X",
    height = 180,
    player = game.Players.LocalPlayer,
    callback = function(alvo, objeto, holograma, tipo)
    end,
})

holo:Load("Fulano")
holo:Load(workspace.Car)
holo:Load(123456789)
holo:Load(Enum.Material.Neon)
holo:LoadList({ "Fulano", workspace.Car }, 1)
holo:Next()
```

```lua
-- // Métodos mais usados dos elements
toggle:Set(true)           toggle:Get()
slider:Set(50)             slider:Get()
dropdown:Set("A")          dropdown:Get()
picker:Set(Color3.new())   picker:Get()
button:Fire()              button:SetLoading(true)
holo:Load(alvo)           holo:Clear()
holo:Next()                holo:Prev()
holo:SetTitle("X")         holo:SetDescription("Texto")
holo:SetSpin(true)         holo:SetZoom(1)
holo:SetTint(true)         holo:SetColor(color)
holo:SetView("Image")      holo:SetStyle("bust")
```

```lua
-- // Tema, saves, idioma e features
Window:SetTheme("Blue")
Window.Save:Set("chave", valor)
Window:SetLanguage("pt")
Window:LoadFeature("Status")
Window:Notify({ Title = "Hub", Description = "Pronto", Duration = 5 })

-- // Element próprio
Window.Elements.Register("Nome", function(section, options)
    return {}
end)
Section:CreateElement("Nome", { title = "X" })
```