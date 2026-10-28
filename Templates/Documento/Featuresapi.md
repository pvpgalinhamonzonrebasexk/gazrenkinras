# Ecohub Features API

Guia completo de como carregar outros arquivos (tabs + elements) dentro da mesma janela da Ecohub.

## Índice

1. [O que é](#1-o-que-é)
2. [O que significa "baixar"](#2-o-que-significa-baixar)
3. [Estrutura de pastas no GitHub](#3-estrutura-de-pastas-no-github)
4. [Script principal](#4-script-principal)
5. [Formas de carregar](#5-formas-de-carregar)
6. [Como a lib acha o arquivo](#6-como-a-lib-acha-o-arquivo)
7. [Como o arquivo de feature enxerga a janela](#7-como-o-arquivo-de-feature-enxerga-a-janela)
8. [Criando tab, section e elements](#8-criando-tab-section-e-elements)
9. [Criando um element novo](#9-criando-um-element-novo)
10. [Descarregar features](#10-descarregar-features)
11. [Uma pasta por jogo](#11-uma-pasta-por-jogo)
12. [Ordem de carregamento](#12-ordem-de-carregamento)
13. [Funções de consulta](#13-funções-de-consulta)
14. [Configuração](#14-configuração)
15. [Erros e notificações](#15-erros-e-notificações)
16. [Referência rápida](#16-referência-rápida)

---

## 1. O que é

A Features API deixa você dividir o hub em vários arquivos. Em vez de um script gigante com todas as tabs, você tem um script principal pequeno que cria a janela e manda carregar arquivos separados. Cada arquivo cria as próprias tabs, sections e elements na mesma janela.

Vantagens:

- O script principal fica curto.
- Cada jogo pode ter a própria pasta de features.
- Você edita um arquivo no GitHub sem mexer nos outros.
- O mesmo script principal serve para vários jogos.
- Uma feature com erro não derruba as outras.

> Só existe **uma janela** por vez. Executar o script principal de novo destrói a janela anterior, descarrega as features dela e limpa qualquer GUI que tenha sobrado.

---

## 2. O que significa "baixar"

Quando se diz que a lib "baixa" um arquivo, quer dizer que ela busca o texto do arquivo no seu GitHub pela internet e roda esse texto como código com `loadstring`. Nada é salvo no PC nem no celular.

Quando você faz:

```lua
Windows:LoadFeature("meianoite/Corrida")
```

a lib monta este link:

```
https://raw.githubusercontent.com/pvpgalinhamonzonrebasexk/monzonrebasexk/main/Features/meianoite/Corrida.luau
```

Depois ela busca o código nesse link, executa, e as tabs e elements aparecem na janela.

Detalhes do download:

- Usa `request` do executor quando existe, senão `game:HttpGet`.
- Cada requisição leva um `?cb=` na URL para não pegar cache velho.
- Tenta até 3 vezes com espera crescente entre as tentativas.
- Vários arquivos baixam em paralelo (3 no mobile, 6 no PC).
- Arquivo vazio, grande demais (mais de 4 MB) ou página HTML é rejeitado.

Por isso o arquivo precisa existir no GitHub, no caminho certo.

---

## 3. Estrutura de pastas no GitHub

```
monzonrebasexk/
├── Assets/
│   └── Icons.luau
├── Library/
│   ├── Librarys.luau
│   ├── Notifications.luau
│   └── Elements/
│       ├── Checkbox.luau
│       ├── Button.luau
│       ├── Slider.luau
│       ├── Dropdown.luau
│       ├── ColorPicker.luau
│       └── Paragraph.luau
└── Features/
    ├── Visual.luau
    ├── Combate.luau
    ├── meianoite/
    │   ├── Corrida.luau
    │   ├── Farm.luau
    │   └── Visual.luau
    └── boneville/
        ├── Corrida.luau
        └── Teleporte.luau
```

| Pasta | Conteúdo |
|-------|----------|
| `Features/` | Features dos jogos (tabs + elements) |
| `Library/Elements/` | Um arquivo por tipo de element |
| `Assets/Icons.luau` | Tabela de ícones lucide |

Regras:

- Arquivo solto: `Features/Combate.luau`.
- Arquivo dentro de pasta: `Features/meianoite/Farm.luau`.
- A extensão pode ser `.luau` ou `.lua`. Se existirem os dois com o mesmo nome, vale o `.luau`.
- Pode ter pasta dentro de pasta, sem limite fixo de níveis.

---

## 4. Script principal

```lua
-- // Library
local Librarys = loadstring(game:HttpGet("https://raw.githubusercontent.com/pvpgalinhamonzonrebasexk/monzonrebasexk/refs/heads/main/Library/Librarys.luau"))()

-- // Nome do jogo
local gameName = "Game"

local nameOk, productInfo = pcall(function()
    return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
end)

if nameOk and productInfo then
    gameName = productInfo.Name
end

-- // Window
local Windows = Librarys:CreateWindow({
    Title = "Ecohub [" .. gameName .. "]",
    SubTitle = "by rip_sheldoohz",
    Size = UDim2.fromOffset(580, 350),
    MinimizeKey = Enum.KeyCode.RightShift,
})

-- // Features
Windows:LoadFeatures({
    "meianoite/Corrida",
    "meianoite/Farm",
    "meianoite/Visual",
})
```

No script principal a janela se chama `Windows` (nome que você escolheu). Dentro dos arquivos de feature ela já existe como `Window` e também como `Windows`. Veja a seção 7.

O `pcall` no `GetProductInfo` evita que o script caia se o Roblox não responder.

---

## 5. Formas de carregar

Todos os métodos são chamados na **janela** (`Windows:`), nunca na lib (`Librarys:`).

### 5.1 LoadFeature (uma feature)

```lua
Windows:LoadFeature("Combate")
```

Carrega `Features/Combate.luau`. Retorna `true` se carregou e `false` se falhou.

### 5.2 Arquivo dentro de pasta

```lua
Windows:LoadFeature("meianoite/Farm")
```

Carrega `Features/meianoite/Farm.luau`. Use `/` para separar pasta e arquivo.

### 5.3 Pasta inteira

```lua
Windows:LoadFeature("meianoite")
```

Carrega todos os arquivos de `Features/meianoite/`, incluindo subpastas, em ordem alfabética.

### 5.4 Várias de uma vez

```lua
Windows:LoadFeatures({
    "Combate",
    "meianoite/Farm",
    "Visual",
})
```

Faz o mesmo que três linhas de `LoadFeature`, na ordem da lista.

- Se uma falhar, as outras continuam.
- Retorna uma tabela com o resultado de cada item, por exemplo `{ Combate = true, ["meianoite/Farm"] = true, Visual = false }`.
- Aceita também uma string única, que vira uma lista de um item.

### 5.5 Todas as features

```lua
Windows:LoadAllFeatures()
```

Equivale a `LoadFeature("all")`. Também funciona com `"*"`. Carrega todos os arquivos de `Features/`. Precisa do índice do GitHub (seção 6).

### 5.6 Link direto

```lua
Windows:LoadFeature("https://raw.githubusercontent.com/usuario/repo/refs/heads/main/Teste.luau")
```

Se o texto começar com `http://` ou `https://`, a lib usa o link como está. Links `github.com/.../blob/...` são convertidos para `raw.githubusercontent.com` automaticamente.

### 5.7 Recarregar

```lua
Windows:LoadFeature("meianoite/Farm", { Reload = true })
```

Com `Reload = true`, se a feature já estiver carregada, ela é descarregada (veja a seção 10) e baixada de novo.

---

## 6. Como a lib acha o arquivo

### 6.1 Pelo índice do GitHub (padrão)

A lib faz uma única chamada à API do GitHub (`git/trees`) que lista todos os arquivos `.luau` e `.lua` da branch. O resultado fica em cache:

| Situação | Tempo |
|----------|-------|
| Índice fresco, sem nova chamada | 60 segundos |
| Espera após uma falha antes de tentar de novo | 30 segundos |
| Arquivo não encontrado, lembrado como inexistente | 10 segundos |

Com o índice, o nome que você passa é comparado nesta ordem, **sem diferenciar maiúscula de minúscula**:

1. Caminho exato: `"meianoite/Farm"`.
2. Pasta: `"meianoite"` carrega tudo que está dentro.
3. Nome do arquivo sozinho: `"Farm"` acha `meianoite/Farm`.

Se o nome sozinho existir em mais de uma pasta, a lib avisa `Ambiguous name` e sugere o caminho completo. Se nada for achado, ela força uma atualização do índice e tenta de novo uma vez.

### 6.2 Sem índice (plano B)

Se a API do GitHub falhar ou estourar o limite de requisições, a lib mostra o aviso `GitHub index unavailable, using direct links` e tenta links diretos, nesta ordem, com o nome original, em maiúsculas e em minúsculas:

1. `Features/NOME.luau`
2. `Features/NOME.lua`
3. `Features/NOME/ULTIMA_PARTE.luau`
4. `Features/NOME/init.luau`

Nesse modo carregar pasta inteira e `LoadAllFeatures` não funcionam. Arquivo direto (`pasta/arquivo`) continua funcionando porque usa o `raw.githubusercontent.com`, que não tem esse limite.

### 6.3 Detalhes do nome

- A extensão é opcional: `"Combate"` e `"Combate.luau"` funcionam igual.
- `\` é trocado por `/`.
- Espaços e barras sobrando no começo e no fim são removidos.
- Se o nome começar com o nome da pasta raiz (`Features/`), esse prefixo é ignorado.

---

## 7. Como o arquivo de feature enxerga a janela

Antes de rodar o arquivo, a lib cria quatro variáveis globais:

| Variável | O que é |
|----------|---------|
| `Window` | a janela criada no script principal |
| `Windows` | a mesma janela (outro nome) |
| `Librarys` | a própria lib (Theme, Elements, Notify, etc.) |
| `Library` | a mesma lib (outro nome) |

Dentro do arquivo você usa direto, sem `loadstring`, sem `require`, sem criar janela nova:

```lua
-- // Combate
local Tab = Window:CreateTab({
    tab = "Combate",
    section = "Features",
    icon = "swords",
})

local Section = Tab:CreateSection("Aimbot")

Section:CreateToggle({
    title = "Aimbot",
    default = false,
    callback = function(state)
        print("Aimbot:", state)
    end,
})
```

Como a feature roda:

- Em uma thread separada, com identidade elevada quando o executor permite.
- A lib espera até 2 segundos o arquivo terminar de iniciar. Depois disso a feature segue rodando em segundo plano, então loops longos não travam o carregamento.
- Erro de sintaxe ou erro ao rodar vira uma notificação com o nome da feature, sem derrubar as outras.

---

## 8. Criando tab, section e elements

Dentro de qualquer feature:

```lua
-- // Tab
local Tab = Window:CreateTab({
    tab = "Farm",
    section = "Corrida",
    icon = "flag",
})

-- // Section
local Section = Tab:CreateSection("Auto Farm")
```

| Opção | Descrição |
|-------|-----------|
| `tab` | Nome que aparece na barra lateral (também aceita `name`) |
| `section` | Título do grupo na barra lateral. Tabs com a mesma `section` ficam agrupadas |
| `icon` | Nome de um ícone lucide, sem o prefixo `lucide-`. Se não existir, a tab fica sem ícone |

`CreateSection` cria o bloco dentro da página da tab.

Elements disponíveis em uma section:

| Método | Element |
|--------|---------|
| `Section:CreateToggle(opts)` | Checkbox |
| `Section:CreateButton(opts)` | Button |
| `Section:CreateSlider(opts)` | Slider |
| `Section:CreateDropdown(opts)` | Dropdown |
| `Section:CreateColorPicker(opts)` | ColorPicker |
| `Section:CreateParagraph(opts)` | Paragraph |
| `Section:CreateElement(nome, opts)` | qualquer element registrado |
| `Section:CreateNome(opts)` | atalho para um element registrado com o nome `Nome` |

Exemplo completo de uma feature:

```lua
-- // Farm
local Tab = Window:CreateTab({
    tab = "Farm",
    section = "meianoite",
    icon = "flag",
})

local Section = Tab:CreateSection("Auto Farm")

-- // Toggle
local farm = Section:CreateToggle({
    title = "Auto Farm",
    description = "Farma automaticamente",
    default = false,
    callback = function(state)
        print("Auto Farm:", state)
    end,
})

-- // Slider
Section:CreateSlider({
    title = "Delay",
    min = 0,
    max = 5,
    default = 1,
    rounding = 1,
    suffix = "s",
    callback = function(value)
        print("Delay:", value)
    end,
})

-- // Button
Section:CreateButton({
    title = "Teleportar",
    callback = function()
        print("teleportou")
    end,
})
```

Proteção de callback: qualquer erro dentro de `callback` é capturado e aparece como notificação, o hub não cai.

Pesquisa: se `opts` tiver `name`, `title`, `text` ou `label`, o element entra automaticamente na pesquisa da janela.

---

## 9. Criando um element novo

Os elements ficam em `Librarys.Elements.List`. Para criar um novo, registre o construtor com um nome e depois chame com `CreateElement`.

```lua
-- // Element Label
Librarys.Elements.Register("Label", function(section, opts)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = opts.text
    label.Font = Librarys.FONT
    label.TextSize = 13
    label.TextColor3 = Librarys.Theme.TextPrimary
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = section.frame

    return {
        SetText = function(_, text)
            label.Text = text
        end,
    }
end)

-- // Usar Label
local info = Section:CreateElement("Label", {
    text = "Olá",
})

info:SetText("Novo texto")
```

- O construtor recebe `section` (use `section.frame` como pai) e `opts` (a tabela que você passou).
- O que o construtor retornar é o objeto que você usa depois.
- Quem registra o element precisa carregar antes de quem usa. Se o element novo está numa feature, carregue essa feature primeiro.
- Se você chamar `CreateElement("Nome", ...)` e o nome não estiver registrado, a lib tenta baixar `Library/Elements/Nome.luau` automaticamente (uma tentativa por nome).

Arquivos dentro de `Library/Elements/` rodam com estas variáveis já disponíveis:

| Variável | Conteúdo |
|----------|----------|
| `Elements` | tabela de elements (`Register`, `List`) |
| `Library` | a lib |
| `Notify` / `Report` | notificações |
| `Theme` / `Metrics` | cores e medidas |
| `FONT` / `FONT_BOLD` | fontes |
| `Icon` / `ICONS` | ícones |
| `TweenService`, `UserInputService`, `Players`, `HttpService` | serviços |

---

## 10. Descarregar features

```lua
Windows:UnloadFeature("meianoite/Farm")
Windows:UnloadFeature("meianoite")
Windows:UnloadAllFeatures()
```

| Método | O que faz |
|--------|-----------|
| `UnloadFeature(nome)` | Descarrega um arquivo ou uma pasta inteira. Retorna `true` se achou algo |
| `UnloadAllFeatures()` | Descarrega todas |

Como funciona:

1. Para cada feature carregada que bate com o nome, a lib procura uma função global chamada `NOMEUnload`, onde `NOME` é a última parte do caminho. Para `meianoite/Farm` a função é `FarmUnload`.
2. Se a função existir, ela é chamada. Erro dentro dela vira notificação.
3. A feature sai da lista de carregadas e pode ser carregada de novo.

O descarregamento **não remove as tabs da janela**. Ele chama a sua função de limpeza e libera o nome para recarregar. Por isso, toda feature com loop, conexão ou ESP deve definir a função de limpeza:

```lua
-- // Farm
local RunService = game:GetService("RunService")

local running = false

local connection = RunService.Heartbeat:Connect(function()
    if not running then
        return
    end
end)

-- // Unload
getgenv().FarmUnload = function()
    running = false
    connection:Disconnect()
end
```

`Window:Destroy()` descarrega todas as features automaticamente antes de apagar a janela.

---

## 11. Uma pasta por jogo

Para usar o mesmo script principal em vários jogos, escolha a pasta pelo `PlaceId`:

```lua
-- // Jogos
local Jogos = {
    [123456789] = "meianoite",
    [987654321] = "boneville",
}

-- // Carregar jogo
local pasta = Jogos[game.PlaceId]

if pasta then
    Windows:LoadFeature(pasta)
end
```

Troque os números e os nomes pelos seus. Cada jogo carrega só a própria pasta.

Para carregar features comuns a todos os jogos e depois as do jogo atual:

```lua
-- // Features gerais
Windows:LoadFeatures({
    "Visual",
    "Player",
})

-- // Features do jogo
local pasta = Jogos[game.PlaceId]

if pasta then
    Windows:LoadFeature(pasta)
end
```

---

## 12. Ordem de carregamento

- Os downloads acontecem em paralelo, mas a execução segue a ordem do pedido.
- `LoadFeatures` executa exatamente na ordem da lista.
- Pasta inteira (`LoadFeature("pasta")`) executa em ordem alfabética do caminho.
- As tabs aparecem na janela na ordem em que foram criadas. A primeira tab criada fica selecionada.
- Se a ordem das tabs importa, use a lista, ou nomeie os arquivos para a ordem alfabética ficar certa (`1_Combate.luau`, `2_Visual.luau`).

---

## 13. Funções de consulta

| Método | Retorno |
|--------|---------|
| `Librarys:ListFeatures()` | Lista de todas as features do GitHub (sem extensão) |
| `Librarys:RefreshFeatures()` | Força atualizar o índice. Retorna `true` se conseguiu |
| `Windows:GetLoadedFeatures()` | Lista ordenada das features carregadas |
| `Windows:IsFeatureLoaded(nome)` | `true` se o nome (caminho ou nome do arquivo) está carregado |
| `Librarys:ListElements()` | Lista dos elements registrados |
| `Librarys:LoadElements(force)` | Baixa os elements da pasta. Com `true`, baixa de novo os que já existem |

Exemplo:

```lua
if not Windows:IsFeatureLoaded("Visual") then
    Windows:LoadFeature("Visual")
end

for _, name in ipairs(Windows:GetLoadedFeatures()) do
    print(name)
end
```

---

## 14. Configuração

### 14.1 Trocar o repositório

```lua
Librarys:SetFeaturesSource("https://github.com/usuario/repo/tree/main/Features")
Librarys:SetElementsSource("https://github.com/usuario/repo/tree/main/Library/Elements")
```

O formato é sempre `https://github.com/DONO/REPO/tree/BRANCH/PASTA`. Retorna `false` se o link não for nesse formato. Depois de trocar, a lib preenche estas informações:

| Campo | Conteúdo |
|-------|----------|
| `Librarys.FeaturesSource` | link original |
| `Librarys.FeaturesRepo` | `dono/repo` |
| `Librarys.FeaturesBranch` | branch |
| `Librarys.FeaturesRoot` | pasta raiz |
| `Librarys.FeaturesUrl` | base dos links raw |
| `Librarys.FeaturesTreeApi` | link da API de índice |
| `Librarys.ElementsSource` / `Librarys.ElementsUrl` | o mesmo, para elements |

Só precisa trocar se mover as features para outro repositório, branch ou pasta.

### 14.2 Ajustes de rede

Ficam em `Librarys.FeatureConfig`:

| Campo | Padrão | Descrição |
|-------|--------|-----------|
| `TreeTtl` | 60 | Segundos que o índice fica fresco |
| `TreeRetry` | 30 | Segundos de espera depois de uma falha no índice |
| `MissTtl` | 10 | Segundos lembrando que um arquivo não existe |
| `Retries` | 3 | Tentativas por arquivo |
| `RetryDelay` | 0.3 | Espera base entre tentativas (multiplica pela tentativa) |
| `MaxParallel` | 3 mobile, 6 PC | Downloads simultâneos |
| `Timeout` | 30 | Segundos máximos esperando os downloads |
| `StartTimeout` | 2 | Segundos esperando a feature iniciar |

```lua
Librarys.FeatureConfig.MaxParallel = 4
Librarys.FeatureConfig.Retries = 2
```

Erros `403` e `429` (limite de requisições) não são repetidos. Erro `404` é lembrado por `MissTtl` segundos.

---

## 15. Erros e notificações

As notificações aparecem em inglês.

| Notificação | Causa |
|-------------|-------|
| `Use Window:LoadFeature(...), not Librarys:LoadFeature(...)` | você chamou com `Librarys:` em vez da janela |
| `LoadFeature needs a name or link` | passou vazio ou algo que não é texto |
| `Feature not found: nome` | nenhum caminho existe no GitHub |
| `Ambiguous name: nome. Use folder/file, e.g. pasta/nome` | o nome existe em mais de uma pasta |
| `No features found in the folder` | `LoadAllFeatures` rodou e a pasta `Features/` não tem nenhum arquivo |
| `GitHub index unavailable, using direct links` | a API do GitHub falhou, usando o plano B |
| `GitHub index unavailable, cannot load all features` | `all` precisa do índice |
| `Loaded N feature(s)` | tudo carregou |
| `Loaded N, failed M: lista` | algumas falharam, com o motivo de cada uma (`not found`, `rate limited`, `HTTP 500`, `empty file`, `html page`) |
| Título `Ecohub \| nome` com uma mensagem | erro de sintaxe ou erro ao rodar o arquivo |

Dicas:

- O GitHub pode demorar alguns minutos para atualizar o arquivo depois de um commit (cache do `raw`).
- Com o índice ativo, maiúscula e minúscula não importam. No plano B e nos links diretos, `combate.luau` e `Combate.luau` são arquivos diferentes.
- `rate limited` significa limite da API do GitHub. Espere alguns minutos ou carregue por `pasta/arquivo`.

---

## 16. Referência rápida

```lua
-- // Carregar
Windows:LoadFeature("Combate")
Windows:LoadFeature("meianoite/Farm")
Windows:LoadFeature("meianoite")
Windows:LoadFeature("https://link/direto.luau")
Windows:LoadFeature("meianoite/Farm", { Reload = true })
Windows:LoadFeatures({ "Combate", "meianoite/Farm", "Visual" })
Windows:LoadAllFeatures()

-- // Descarregar
Windows:UnloadFeature("meianoite/Farm")
Windows:UnloadAllFeatures()

-- // Consultar
Windows:GetLoadedFeatures()
Windows:IsFeatureLoaded("Visual")
Librarys:ListFeatures()
Librarys:RefreshFeatures()
```

```lua
-- // Dentro da feature
local Tab = Window:CreateTab({
    tab = "Nome",
    section = "Grupo",
    icon = "icone",
})

local Section = Tab:CreateSection("Titulo")

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
    callback = function(color)
    end,
})

Section:CreateParagraph({
    title = "X",
    description = "Texto",
})

Section:CreateElement("NomeRegistrado", {
    text = "X",
})
```