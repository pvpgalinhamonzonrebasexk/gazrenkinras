# Notifications

Módulo de notificações do Ecohub: toasts com título, descrição, thumbnail, tipos, sistema de loading com progresso e controle por handle. O visual usa `UIGradient` no fundo, na borda, na barra de destaque e na barra de progresso.

> [!TIP]
> Com pressa? Vá direto para o [Início rápido](#início-rápido).

---

## Sumário

- [Início rápido](#início-rápido)
1. [Carregar](#1-carregar)
2. [Notify](#2-notify)
3. [Propriedades](#3-propriedades)
4. [Tipos](#4-tipos)
5. [Loading](#5-loading)
6. [Handle](#6-handle)
7. [Id](#7-id)
8. [Setters](#8-setters)
9. [Controle](#9-controle)
10. [Config](#10-config)
11. [Tema](#11-tema)
12. [Utils](#12-utils)
13. [Exemplo completo](#13-exemplo-completo)

---

## Início rápido

```lua
-- // Notifications
local Notifications = loadstring(game:HttpGet("https://raw.githubusercontent.com/pvpgalinhamonzonrebasexk/gazrenkinras/refs/heads/main/Templates/Notification.lua"))()
local Notify = Notifications.Notify

-- // Notificação simples
Notify("Hello world", 3)

-- // Com título, descrição, duração e tipo
Notify("Title", "Description", 5, "Warning")

-- // Loading que vira sucesso
local loading = Notifications.Loading("Loading", "Fetching data...")
task.wait(2)
loading.Success("Done", "Data loaded", 3)
```

---

## 1. Carregar

```lua
-- // Notifications
local Notifications = loadstring(game:HttpGet("https://raw.githubusercontent.com/pvpgalinhamonzonrebasexk/gazrenkinras/refs/heads/main/Templates/Notification.lua"))()
local Notify = Notifications.Notify
```

| Item | Valor |
|------|-------|
| Repositório | `pvpgalinhamonzonrebasexk/gazrenkinras` |
| Arquivo | `Templates/Notification.lua` |
| Branch | `main` |

A library de UI já carrega este módulo sozinha e expõe em `Librarys.Notify` e `Librarys.Notifications`. Ela também aplica:

| Ajuste | Mobile | PC |
|--------|--------|----|
| `SetMaxVisible` | 3 | 5 |
| `SetGroup` | `true` | `true` |
| Largura da notificação | 260 | 320 |

---

## 2. Notify

Formas de chamar:

```lua
-- // Tabela completa
Notify({
    Title = "Early | Wave 1",
    Description = "This description is super long and should cause an overlap in wrapping",
    Duration = 5,
})

-- // Só descrição
Notify("Description only")

-- // Descrição e duração
Notify("Description only", 3)

-- // Descrição, duração e tipo
Notify("Description only", 3, "Success")

-- // Título, descrição, duração e tipo
Notify("Title", "Description", 5, "Warning")

-- // O módulo também é chamável
Notifications("Description only")
```

| Forma | Argumentos |
|-------|------------|
| `Notify(tabela)` | Todas as [propriedades](#3-propriedades) |
| `Notify(descrição)` | Só descrição |
| `Notify(descrição, duração, tipo)` | Descrição, duração e tipo |
| `Notify(título, descrição, duração, tipo)` | Forma completa |
| `Notifications(...)` | Igual a `Notify(...)` |

> [!NOTE]
> `Notify` retorna um [handle](#6-handle). Se a chamada não tiver título nem descrição, nada é mostrado e o retorno é `nil`.

---

## 3. Propriedades

```lua
-- // Todas as propriedades
Notify({
    Title = "Title",
    Description = "Description",
    Duration = 5,
    Type = "Info",
    Color = Color3.fromRGB(255, 0, 0),
    Name = "Hub",
    Thumbnail = "rbxassetid://123",
    RichText = true,
    Callback = function()
    end,
    ClickToClose = true,
    Id = "download",
    Loading = false,
    Progress = 0.5,
    Sound = "rbxassetid://123",
    Volume = 0.5,
})
```

| Propriedade | Tipo | Descrição |
|-------------|------|-----------|
| `Title` | string | Título |
| `Description` | string | Texto da notificação |
| `Duration` | number | Segundos na tela. `0` deixa fixa até fechar |
| `Type` | string | `Info`, `Success`, `Warning`, `Error` ou tipo customizado |
| `Color` | Color3 | Cor de destaque, sobrescreve a do tipo |
| `Name` | string ou false | Nome do painel. `false` esconde |
| `Thumbnail` | string ou false | Imagem. `false` esconde |
| `RichText` | boolean | Ativa tags como `<b>` e `<i>` |
| `Callback` | function | Chamado ao clicar |
| `ClickToClose` | boolean | Fecha ao clicar |
| `Id` | string | Identificador para atualizar a mesma notificação |
| `Loading` | boolean | Mostra o spinner e deixa a notificação fixa. Veja [Loading](#5-loading) |
| `Progress` | number | Progresso de `0` a `1`. Só vale em notificação fixa |
| `Sound` | string | Som ao aparecer |
| `Volume` | number | Volume do som |

### Exemplos

```lua
-- // Fixa
Notify({
    Title = "Persistent",
    Duration = 0,
})

-- // Sem nome
Notify({
    Title = "No name",
    Name = false,
})

-- // Sem thumbnail
Notify({
    Title = "No thumbnail",
    Thumbnail = false,
})

-- // Rich text
Notify({
    Title = "Rich",
    Description = "<b>bold</b> <i>italic</i>",
    RichText = true,
})

-- // Clique com callback
Notify({
    Title = "Click",
    Callback = function()
        print("clicked")
    end,
    ClickToClose = false,
})
```

---

## 4. Tipos

### Atalhos

```lua
Notifications.Info("Title", "Description", 4)
Notifications.Success("Title", "Description", 4)
Notifications.Warning("Title", "Description", 4)
Notifications.Error("Title", "Description", 4)
```

### Por propriedade

```lua
Notify({
    Title = "Info",
    Type = "Info",
})

Notify({
    Title = "Success",
    Type = "Success",
})

Notify({
    Title = "Warning",
    Type = "Warning",
})

Notify({
    Title = "Error",
    Type = "Error",
})
```

### Aliases

| Alias | Resolve para |
|-------|--------------|
| `ok` | `Success` |
| `warn` | `Warning` |
| `err` | `Error` |

```lua
Notify({
    Title = "Alias",
    Type = "ok",
})
```

> [!NOTE]
> A busca do tipo não diferencia maiúscula de minúscula, então `info`, `success`, `warning` e `error` também funcionam. Um tipo desconhecido passa sem alteração e usa a cor de destaque padrão.

### Tipo customizado

```lua
Notifications.Types.Custom = Color3.fromRGB(255, 120, 0)

Notify({
    Title = "Custom",
    Type = "Custom",
})
```

---

## 5. Loading

Notificação com spinner girando. Ela fica fixa até você finalizar ou fechar.

```lua
-- // Atalho
local loading = Notifications.Loading("Loading", "Fetching data...")

-- // Pela tabela
local loading = Notify({
    Title = "Loading",
    Description = "Fetching data...",
    Loading = true,
})
```

### Finalizar

Ao finalizar, o spinner para, o círculo ganha a cor do tipo e a notificação some depois da duração.

```lua
-- // Sucesso
loading.Success("Done", "Data loaded", 3)

-- // Erro
loading.Error("Failed", "Could not load", 4)

-- // Tabela completa
loading.Finish({
    Title = "Done",
    Description = "Data loaded",
    Type = "Success",
    Duration = 3,
})
```

> [!NOTE]
> Se um argumento for `nil`, o texto anterior é mantido. Exemplo: `loading.Success(nil, "Data loaded")` troca só a descrição.

### Progresso

A barra de progresso aparece quando você define um valor de `0` a `1`.

```lua
local loading = Notifications.Loading("Downloading", "0%")

for step = 1, 10 do
    task.wait(0.3)
    loading.Progress(step / 10)
    loading.Update({
        Description = (step * 10) .. "%",
    })
end

loading.Success("Done", "100%", 2)
```

### Finalizar pelo Id

Chamar `Notify` com o mesmo `Id` de um loading finaliza ele, sem precisar guardar o handle.

```lua
Notify({
    Id = "load",
    Title = "Loading",
    Description = "Please wait",
    Loading = true,
})

task.wait(2)

Notify({
    Id = "load",
    Title = "Done",
    Description = "Ready",
    Type = "Success",
    Duration = 3,
})
```

---

## 6. Handle

`Notify` retorna um handle para controlar a notificação depois de criada.

```lua
local handle = Notify({
    Title = "Downloading",
    Description = "0%",
    Duration = 0,
})

handle.Update({
    Description = "50%",
})

handle.Update({
    Title = "Done",
    Description = "100%",
    Type = "Success",
    Duration = 2,
})

handle.Close()
```

| Membro | Descrição |
|--------|-----------|
| `handle.Update(opts)` | Atualiza `Title`, `Description`, `Duration`, `Type`, `Color` e `Progress` |
| `handle.Progress(valor)` | Define o progresso de `0` a `1` |
| `handle.Finish(opts)` | Para o spinner e aplica as opções. Sem `Duration`, usa a duração padrão |
| `handle.Success(título, descrição, duração)` | `Finish` com o tipo `Success` |
| `handle.Error(título, descrição, duração)` | `Finish` com o tipo `Error` |
| `handle.Close()` | Fecha a notificação |
| `handle.IsClosed()` | Retorna se já foi fechada |
| `handle.Frame` | Frame da notificação |

> [!NOTE]
> `Update` com `Duration = 0` deixa a notificação fixa, e com `Duration` maior que zero reinicia a contagem. Para mudar outras propriedades, crie a notificação de novo ou use o mesmo [`Id`](#7-id).

---

## 7. Id

Notificações com o mesmo `Id` são atualizadas em vez de empilhar.

```lua
Notify({
    Id = "download",
    Title = "Downloading",
    Description = "10%",
    Duration = 5,
})

Notify({
    Id = "download",
    Title = "Downloading",
    Description = "60%",
    Duration = 5,
})

Notify({
    Id = "download",
    Title = "Done",
    Description = "100%",
    Type = "Success",
    Duration = 2,
})
```

---

## 8. Setters

Mudam o comportamento padrão de todas as notificações seguintes.

```lua
-- // Nome e thumbnail
Notifications.SetName("Hub")
Notifications.SetName(false)
Notifications.SetThumbnail("rbxassetid://123")

-- // Lado da tela
Notifications.SetSide("Left")
Notifications.SetSide("Right")

-- // Canto da tela
Notifications.SetPosition("TopLeft")
Notifications.SetPosition("TopRight")
Notifications.SetPosition("BottomLeft")
Notifications.SetPosition("BottomRight")

-- // Tamanho
Notifications.SetWidth(260)

-- // Comportamento
Notifications.SetDuration(4)
Notifications.SetGroup(true)
Notifications.SetMaxVisible(4)
Notifications.SetClickToClose(false)

-- // Som
Notifications.SetSound("rbxassetid://123", 0.5)
Notifications.SetSound(false)

-- // Visual
Notifications.SetTheme({
    Panel = Color3.fromRGB(16, 16, 18),
    PanelTop = Color3.fromRGB(30, 30, 34),
})
Notifications.SetFont(Enum.Font.Gotham)
```

| Setter | Descrição |
|--------|-----------|
| `SetName(texto ou false)` | Nome do painel |
| `SetThumbnail(imagem)` | Thumbnail padrão |
| `SetSide(lado)` | `Left` ou `Right` |
| `SetPosition(canto)` | `TopLeft`, `TopRight`, `BottomLeft`, `BottomRight` |
| `SetWidth(largura)` | Largura das notificações |
| `SetDuration(segundos)` | Duração padrão |
| `SetGroup(boolean)` | Agrupa notificações iguais |
| `SetMaxVisible(numero)` | Máximo de notificações na tela |
| `SetSound(som, volume)` | Som padrão. `false` desativa |
| `SetClickToClose(boolean)` | Fechar ao clicar |
| `SetTheme(tabela)` | Sobrescreve cores da tabela `Notifications.Theme`. Veja [Tema](#11-tema) |
| `SetFont(fonte)` | Define a fonte de título, descrição e nome |

---

## 9. Controle

```lua
-- // Fecha todas
Notifications.Clear()

-- // Remove o módulo da tela
Notifications.Destroy()
```

---

## 10. Config

Todas as opções ficam em `Notifications.Config`. Os valores abaixo são exemplos.

### Geral

```lua
Notifications.Config.Name = false
Notifications.Config.GuiName = "Notifications"
Notifications.Config.Thumbnail = "rbxassetid://0"
Notifications.Config.Side = "Left"
Notifications.Config.Vertical = "Bottom"
Notifications.Config.Width = 320
Notifications.Config.Margin = 20
Notifications.Config.Padding = 8
Notifications.Config.MaxVisible = 6
Notifications.Config.DefaultDuration = 5
Notifications.Config.ThumbnailSize = 44
Notifications.Config.RingSize = 20
```

### Comportamento

```lua
Notifications.Config.ShowProgress = true
Notifications.Config.ShowType = true
Notifications.Config.HoverPause = true
Notifications.Config.Group = false
Notifications.Config.ClickToClose = true
Notifications.Config.Sound = false
Notifications.Config.SoundVolume = 0.5
```

### Texto

```lua
Notifications.Config.TitleSize = 14
Notifications.Config.DescriptionSize = 13
Notifications.Config.NameSize = 11
Notifications.Config.TitleFont = Enum.Font.GothamSemibold
Notifications.Config.DescriptionFont = Enum.Font.Gotham
Notifications.Config.NameFont = Enum.Font.GothamBold
```

### Animações

```lua
Notifications.Config.TweenIn = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
Notifications.Config.TweenOut = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
```

### Referência das chaves

| Chave | Descrição |
|-------|-----------|
| `Name` | Nome do painel. `false` esconde |
| `GuiName` | Nome do ScreenGui |
| `Thumbnail` | Thumbnail padrão |
| `Side` | `Left` ou `Right` |
| `Vertical` | `Top` ou `Bottom` |
| `Width` | Largura da notificação |
| `Margin` | Distância da borda da tela |
| `Padding` | Espaço entre notificações |
| `MaxVisible` | Máximo na tela |
| `DefaultDuration` | Duração padrão |
| `ThumbnailSize` | Tamanho da thumbnail |
| `RingSize` | Tamanho do spinner do loading |
| `ShowProgress` | Barra de tempo visível |
| `ShowType` | Mostra o tipo em maiúsculas acima do título |
| `HoverPause` | Pausa a contagem com o mouse em cima |
| `Group` | Agrupa notificações iguais |
| `ClickToClose` | Fecha ao clicar |
| `Sound` / `SoundVolume` | Som e volume |
| `TitleSize` / `DescriptionSize` / `NameSize` | Tamanhos de texto |
| `TitleFont` / `DescriptionFont` / `NameFont` | Fontes |
| `TweenIn` / `TweenOut` | Animações de entrada e saída |

---

## 11. Tema

As cores ficam em `Notifications.Theme`. Mude com `SetTheme` ou direto na tabela. Vale para as próximas notificações.

```lua
Notifications.SetTheme({
    Panel = Color3.fromRGB(16, 16, 18),
    PanelTop = Color3.fromRGB(30, 30, 34),
    Accent = Color3.fromRGB(130, 110, 255),
})
```

| Chave | Descrição |
|-------|-----------|
| `Panel` | Cor de baixo do gradiente do fundo |
| `PanelTop` | Cor de cima do gradiente do fundo |
| `Line` | Cor final do gradiente da borda |
| `Track` | Fundo da barra de progresso e do círculo do loading |
| `Accent` | Cor de destaque quando não há tipo nem `Color` |
| `TitleText` | Cor do título |
| `TextSecondary` | Cor da descrição |
| `TextHeader` | Cor do nome do painel |
| `TextPrimary` | Cor do contador do agrupamento |
| `HoverFill` | Cor do brilho ao passar o mouse |

---

## 12. Utils

```lua
Notifications.NormalizeImage("rbxassetid://123")
Notifications.ResolveType("warn")
Notifications.GetParents()
Notifications.Protect(gui)
```

| Função | Descrição |
|--------|-----------|
| `NormalizeImage(valor)` | Converte número ou texto em um link de imagem válido |
| `ResolveType(tipo)` | Resolve aliases (`warn` vira `Warning`) |
| `GetParents()` | Retorna onde a GUI pode ser colocada |
| `Protect(gui)` | Protege a GUI no executor |
| `Normalize(...)` | Normaliza os argumentos de `Notify` (uso interno) |

---

## 13. Exemplo completo

```lua
-- // Notifications
local Notifications = loadstring(game:HttpGet("https://raw.githubusercontent.com/pvpgalinhamonzonrebasexk/gazrenkinras/refs/heads/main/Templates/Notification.lua"))()
local Notify = Notifications.Notify

task.wait(1)

-- // Duração 5
Notify({
    Title = "Early | Wave 1",
    Description = "This description is super long and should cause an overlap in wrapping",
    Duration = 5,
})

task.wait(1)

-- // Sem título
Notify({
    Description = "This description is super long and should cause an overlap in wrapping",
    Duration = 3,
})

task.wait(1)

-- // Loading com progresso
local loading = Notifications.Loading("Downloading", "0%")

for step = 1, 10 do
    task.wait(0.3)
    loading.Progress(step / 10)
    loading.Update({
        Description = (step * 10) .. "%",
    })
end

-- // Finaliza com sucesso
loading.Success("Done", "100%", 3)
```