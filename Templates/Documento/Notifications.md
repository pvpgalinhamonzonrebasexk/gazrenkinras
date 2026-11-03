<div align="center">
<h1>Notifications</h1>
 
<p>Módulo de notificações do Ecohub com ícones por tipo, loading com progresso e controle por handle.<br>
Fundo, borda, brilho, ícone e barra de progresso usam <code>UIGradient</code>.</p>
<p>
<img src="https://img.shields.io/badge/Roblox-Lua-7c6cff?style=for-the-badge" alt="Roblox Lua">
<img src="https://img.shields.io/badge/Tipos-4-50c878?style=for-the-badge" alt="Tipos">
<img src="https://img.shields.io/badge/Loading-Progress-58a6ff?style=for-the-badge" alt="Loading">
<img src="https://img.shields.io/badge/Icons-Lucide-ffbe46?style=for-the-badge" alt="Icons">
</p>
</div>
<br>
<table>
<tr>
<td><b>Sem barra reta</b><br>O card não tem mais a barra lateral. O destaque vem do gradiente da borda e do brilho.</td>
<td><b>Sem círculo verde</b><br>Quando o loading termina, o spinner some e entra um ícone do tipo.</td>
<td><b>Ícones</b><br>Cada tipo tem o seu ícone. Dá para usar qualquer nome do <code>Icons.lua</code>.</td>
</tr>
</table>
<br>
<h2>Sumário</h2>
 
<table>
<tr>
<td><a href="#inicio-rapido">Início rápido</a></td>
<td><a href="#carregar">1. Carregar</a></td>
<td><a href="#notify">2. Notify</a></td>
<td><a href="#propriedades">3. Propriedades</a></td>
</tr>
<tr>
<td><a href="#tipos">4. Tipos</a></td>
<td><a href="#icones">5. Ícones</a></td>
<td><a href="#loading">6. Loading</a></td>
<td><a href="#handle">7. Handle</a></td>
</tr>
<tr>
<td><a href="#id">8. Id</a></td>
<td><a href="#setters">9. Setters</a></td>
<td><a href="#controle">10. Controle</a></td>
<td><a href="#config">11. Config</a></td>
</tr>
<tr>
<td><a href="#tema">12. Tema</a></td>
<td><a href="#utils">13. Utils</a></td>
<td><a href="#exemplo-completo">14. Exemplo completo</a></td>
<td></td>
</tr>
</table>
<br>
<h2 id="inicio-rapido">Início rápido</h2>
 
<pre lang="lua">-- // Notifications
local Notifications = loadstring(game:HttpGet("https://raw.githubusercontent.com/pvpgalinhamonzonrebasexk/gazrenkinras/refs/heads/main/Templates/Notification.lua"))()
local Notify = Notifications.Notify
Notify("Hello world", 3)
Notify("Title", "Description", 5, "Warning")
local loading = Notifications.Loading("Loading", "Fetching data...")
task.wait(2)
loading.Success("Done", "Data loaded", 3)
</pre>
 
<br>
<h2 id="carregar">1. Carregar</h2>
 
<pre lang="lua">-- // Notifications
local Notifications = loadstring(game:HttpGet("https://raw.githubusercontent.com/pvpgalinhamonzonrebasexk/gazrenkinras/refs/heads/main/Templates/Notification.lua"))()
local Notify = Notifications.Notify
</pre>
 
<table>
<tr><th align="left">Item</th><th align="left">Valor</th></tr>
<tr><td>Repositório</td><td><code>pvpgalinhamonzonrebasexk/gazrenkinras</code></td></tr>
<tr><td>Módulo</td><td><code>Templates/Notification.lua</code></td></tr>
<tr><td>Ícones</td><td><code>Assets/Icons.lua</code></td></tr>
<tr><td>Branch</td><td><code>main</code></td></tr>
</table>
<p>Os dois links terminam em <code>.lua</code>.</p>
<p>A library de UI já carrega este módulo sozinha e expõe em <code>Librarys.Notify</code> e <code>Librarys.Notifications</code>. Ela também aplica:</p>
<table>
<tr><th align="left">Ajuste</th><th align="left">Mobile</th><th align="left">PC</th></tr>
<tr><td><code>SetMaxVisible</code></td><td>3</td><td>5</td></tr>
<tr><td><code>SetGroup</code></td><td><code>true</code></td><td><code>true</code></td></tr>
<tr><td>Largura da notificação</td><td>260</td><td>320</td></tr>
</table>
<br>
<h2 id="notify">2. Notify</h2>
 
<h4>Tabela completa</h4>
 
<pre lang="lua">Notify({
    Title = "Early | Wave 1",
    Description = "This description is super long and should cause an overlap in wrapping",
    Duration = 5,
})
</pre>
 
<h4>Formas curtas</h4>
 
<pre lang="lua">Notify("Description only")
Notify("Description only", 3)
Notify("Description only", 3, "Success")
Notify("Title", "Description", 5, "Warning")
Notifications("Description only")
</pre>
 
<table>
<tr><th align="left">Forma</th><th align="left">Argumentos</th></tr>
<tr><td><code>Notify(tabela)</code></td><td>Todas as <a href="#propriedades">propriedades</a></td></tr>
<tr><td><code>Notify(descrição)</code></td><td>Só descrição</td></tr>
<tr><td><code>Notify(descrição, duração, tipo)</code></td><td>Descrição, duração e tipo</td></tr>
<tr><td><code>Notify(título, descrição, duração, tipo)</code></td><td>Forma completa</td></tr>
<tr><td><code>Notifications(...)</code></td><td>Igual a <code>Notify(...)</code></td></tr>
</table>
<blockquote>
<b>Nota</b><br>
<code>Notify</code> retorna um <a href="#handle">handle</a>. Se a chamada não tiver título nem descrição, nada é mostrado e o retorno é <code>nil</code>.
</blockquote>
<br>
<h2 id="propriedades">3. Propriedades</h2>
 
<pre lang="lua">Notify({
    Title = "Title",
    Description = "Description",
    Duration = 5,
    Type = "Info",
    Icon = "bell",
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
</pre>
 
<table>
<tr><th align="left">Propriedade</th><th align="left">Tipo</th><th align="left">Descrição</th></tr>
<tr><td><code>Title</code></td><td>string</td><td>Título</td></tr>
<tr><td><code>Description</code></td><td>string</td><td>Texto da notificação</td></tr>
<tr><td><code>Duration</code></td><td>number</td><td>Segundos na tela. <code>0</code> deixa fixa até fechar</td></tr>
<tr><td><code>Type</code></td><td>string</td><td><code>Info</code>, <code>Success</code>, <code>Warning</code>, <code>Error</code> ou tipo customizado</td></tr>
<tr><td><code>Icon</code></td><td>string, number ou false</td><td>Nome do <code>Icons.lua</code>, <code>rbxassetid</code> ou número. <code>false</code> esconde o ícone. Veja <a href="#icones">Ícones</a></td></tr>
<tr><td><code>Color</code></td><td>Color3</td><td>Cor de destaque, sobrescreve a do tipo</td></tr>
<tr><td><code>Name</code></td><td>string ou false</td><td>Nome do painel. <code>false</code> esconde</td></tr>
<tr><td><code>Thumbnail</code></td><td>string ou false</td><td>Imagem no lugar do ícone. <code>false</code> esconde</td></tr>
<tr><td><code>RichText</code></td><td>boolean</td><td>Ativa tags como <code>&lt;b&gt;</code> e <code>&lt;i&gt;</code></td></tr>
<tr><td><code>Callback</code></td><td>function</td><td>Chamado ao clicar</td></tr>
<tr><td><code>ClickToClose</code></td><td>boolean</td><td>Fecha ao clicar</td></tr>
<tr><td><code>Id</code></td><td>string</td><td>Identificador para atualizar a mesma notificação</td></tr>
<tr><td><code>Loading</code></td><td>boolean</td><td>Mostra o spinner e deixa a notificação fixa. Veja <a href="#loading">Loading</a></td></tr>
<tr><td><code>Progress</code></td><td>number</td><td>Progresso de <code>0</code> a <code>1</code>. Só vale em notificação fixa</td></tr>
<tr><td><code>Sound</code></td><td>string</td><td>Som ao aparecer</td></tr>
<tr><td><code>Volume</code></td><td>number</td><td>Volume do som</td></tr>
</table>
<h4>Fixa</h4>
 
<pre lang="lua">Notify({
    Title = "Persistent",
    Duration = 0,
})
</pre>
 
<h4>Sem nome e sem ícone</h4>
 
<pre lang="lua">Notify({
    Title = "No name",
    Name = false,
    Icon = false,
})
</pre>
 
<h4>Com thumbnail</h4>
 
<pre lang="lua">Notify({
    Title = "Thumbnail",
    Thumbnail = "rbxassetid://123",
})
</pre>
 
<h4>Rich text</h4>
 
<pre lang="lua">Notify({
    Title = "Rich",
    Description = "&lt;b&gt;bold&lt;/b&gt; &lt;i&gt;italic&lt;/i&gt;",
    RichText = true,
})
</pre>
 
<h4>Clique com callback</h4>
 
<pre lang="lua">Notify({
    Title = "Click",
    Callback = function()
        print("clicked")
    end,
    ClickToClose = false,
})
</pre>
 
<br>
<h2 id="tipos">4. Tipos</h2>
 
<table>
<tr><th align="left">Tipo</th><th align="left">Cor</th><th align="left">Ícone</th><th align="left">Alias</th></tr>
<tr><td><code>Info</code></td><td>Azul</td><td><code>lucide-info</code></td><td><code>info</code></td></tr>
<tr><td><code>Success</code></td><td>Verde</td><td><code>lucide-check</code></td><td><code>success</code>, <code>ok</code></td></tr>
<tr><td><code>Warning</code></td><td>Amarelo</td><td><code>lucide-alert-triangle</code></td><td><code>warning</code>, <code>warn</code></td></tr>
<tr><td><code>Error</code></td><td>Vermelho</td><td><code>lucide-x</code></td><td><code>error</code>, <code>err</code></td></tr>
</table>
<h4>Atalhos</h4>
 
<pre lang="lua">Notifications.Info("Title", "Description", 4)
Notifications.Success("Title", "Description", 4)
Notifications.Warning("Title", "Description", 4)
Notifications.Error("Title", "Description", 4)
</pre>
 
<h4>Por propriedade</h4>
 
<pre lang="lua">Notify({
    Title = "Success",
    Type = "Success",
})
Notify({
    Title = "Alias",
    Type = "ok",
})
</pre>
 
<blockquote>
<b>Nota</b><br>
A busca do tipo não diferencia maiúscula de minúscula. Um tipo desconhecido passa sem alteração e usa a cor de destaque padrão do tema.
</blockquote>
<h4>Tipo customizado</h4>
 
<pre lang="lua">Notifications.Types.Custom = Color3.fromRGB(255, 120, 0)
Notifications.SetIcon("Custom", "lucide-star")
Notify({
    Title = "Custom",
    Type = "Custom",
})
</pre>
 
<br>
<h2 id="icones">5. Ícones</h2>
 
<p>Cada tipo tem um ícone dentro de um quadrado com gradiente. Sem tipo, a notificação usa o ícone padrão.</p>
<h4>Ícone pelo nome</h4>
 
<pre lang="lua">Notify({
    Title = "Heart",
    Description = "Icon by name",
    Icon = "heart",
})
</pre>
 
<h4>Ícone por id</h4>
 
<pre lang="lua">Notify({
    Title = "Asset",
    Icon = "rbxassetid://10709790644",
})
</pre>
 
<h4>Trocar o ícone de um tipo</h4>
 
<pre lang="lua">Notifications.SetIcon("Success", "lucide-check-circle")
Notifications.SetIcon("Error", "lucide-x-circle")
</pre>
 
<table>
<tr><th align="left">Valor</th><th align="left">Resultado</th></tr>
<tr><td><code>"heart"</code></td><td>Procura <code>lucide-heart</code> no <code>Icons.lua</code></td></tr>
<tr><td><code>"lucide-heart"</code></td><td>Procura direto no <code>Icons.lua</code></td></tr>
<tr><td><code>"rbxassetid://123"</code> ou <code>123</code></td><td>Usa o id</td></tr>
<tr><td><code>false</code></td><td>Sem ícone</td></tr>
</table>
<blockquote>
<b>Nota</b><br>
O <code>Icons.lua</code> só é baixado na primeira vez que um nome é usado. Os ícones dos quatro tipos já vêm embutidos, então não dependem do download.
</blockquote>
<br>
<h2 id="loading">6. Loading</h2>
 
<p>Notificação com spinner girando. Ela fica fixa até você finalizar ou fechar.</p>
<pre lang="lua">local loading = Notifications.Loading("Loading", "Fetching data...")
local loading = Notify({
    Title = "Loading",
    Description = "Fetching data...",
    Loading = true,
})
</pre>
 
<h3>Finalizar</h3>
 
<p>Ao finalizar, o spinner some e o ícone do tipo aparece com uma animação. A notificação fecha depois da duração.</p>
<pre lang="lua">loading.Success("Done", "Data loaded", 3)
loading.Error("Failed", "Could not load", 4)
loading.Finish({
    Title = "Done",
    Description = "Data loaded",
    Type = "Success",
    Duration = 3,
})
</pre>
 
<blockquote>
<b>Nota</b><br>
Se um argumento for <code>nil</code>, o texto anterior é mantido. Exemplo: <code>loading.Success(nil, "Data loaded")</code> troca só a descrição. <code>Finish</code> sem tipo e sem cor usa <code>Success</code>.
</blockquote>
<h3>Progresso</h3>
 
<pre lang="lua">local loading = Notifications.Loading("Downloading", "0%")
for step = 1, 10 do
    task.wait(0.3)
    loading.Progress(step / 10)
    loading.Update({
        Description = (step * 10) .. "%",
    })
end
loading.Success("Done", "100%", 2)
</pre>
 
<h3>Finalizar pelo Id</h3>
 
<p>Chamar <code>Notify</code> com o mesmo <code>Id</code> de um loading finaliza ele, sem precisar guardar o handle.</p>
<pre lang="lua">Notify({
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
</pre>
 
<br>
<h2 id="handle">7. Handle</h2>
 
<p><code>Notify</code> retorna um handle para controlar a notificação depois de criada.</p>
<pre lang="lua">local handle = Notify({
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
</pre>
 
<table>
<tr><th align="left">Membro</th><th align="left">Descrição</th></tr>
<tr><td><code>handle.Update(opts)</code></td><td>Atualiza <code>Title</code>, <code>Description</code>, <code>Duration</code>, <code>Type</code>, <code>Icon</code>, <code>Color</code> e <code>Progress</code></td></tr>
<tr><td><code>handle.Progress(valor)</code></td><td>Define o progresso de <code>0</code> a <code>1</code></td></tr>
<tr><td><code>handle.Finish(opts)</code></td><td>Para o spinner e aplica as opções. Sem <code>Duration</code>, usa a duração padrão</td></tr>
<tr><td><code>handle.Success(título, descrição, duração)</code></td><td><code>Finish</code> com o tipo <code>Success</code></td></tr>
<tr><td><code>handle.Error(título, descrição, duração)</code></td><td><code>Finish</code> com o tipo <code>Error</code></td></tr>
<tr><td><code>handle.Close()</code></td><td>Fecha a notificação</td></tr>
<tr><td><code>handle.IsClosed()</code></td><td>Retorna se já foi fechada</td></tr>
<tr><td><code>handle.Frame</code></td><td>Frame da notificação</td></tr>
</table>
<blockquote>
<b>Nota</b><br>
<code>Update</code> com <code>Duration = 0</code> deixa a notificação fixa, e com <code>Duration</code> maior que zero reinicia a contagem.
</blockquote>
<br>
<h2 id="id">8. Id</h2>
 
<p>Notificações com o mesmo <code>Id</code> são atualizadas em vez de empilhar.</p>
<pre lang="lua">Notify({
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
</pre>
 
<br>
<h2 id="setters">9. Setters</h2>
 
<p>Mudam o comportamento padrão de todas as notificações seguintes.</p>
<pre lang="lua">Notifications.SetName("Hub")
Notifications.SetName(false)
Notifications.SetThumbnail("rbxassetid://123")
Notifications.SetIcon("Success", "lucide-check-circle")
Notifications.SetSide("Left")
Notifications.SetPosition("TopRight")
Notifications.SetWidth(260)
Notifications.SetDuration(4)
Notifications.SetGroup(true)
Notifications.SetMaxVisible(4)
Notifications.SetClickToClose(false)
Notifications.SetSound("rbxassetid://123", 0.5)
Notifications.SetSound(false)
Notifications.SetTheme({
    Panel = Color3.fromRGB(16, 16, 18),
    PanelTop = Color3.fromRGB(30, 30, 34),
})
Notifications.SetFont(Enum.Font.Gotham)
</pre>
 
<table>
<tr><th align="left">Setter</th><th align="left">Descrição</th></tr>
<tr><td><code>SetName(texto ou false)</code></td><td>Nome do painel</td></tr>
<tr><td><code>SetThumbnail(imagem)</code></td><td>Thumbnail padrão</td></tr>
<tr><td><code>SetIcon(tipo, ícone)</code></td><td>Ícone de um tipo</td></tr>
<tr><td><code>SetSide(lado)</code></td><td><code>Left</code> ou <code>Right</code></td></tr>
<tr><td><code>SetPosition(canto)</code></td><td><code>TopLeft</code>, <code>TopRight</code>, <code>BottomLeft</code>, <code>BottomRight</code></td></tr>
<tr><td><code>SetWidth(largura)</code></td><td>Largura das notificações</td></tr>
<tr><td><code>SetDuration(segundos)</code></td><td>Duração padrão</td></tr>
<tr><td><code>SetGroup(boolean)</code></td><td>Agrupa notificações iguais</td></tr>
<tr><td><code>SetMaxVisible(numero)</code></td><td>Máximo de notificações na tela</td></tr>
<tr><td><code>SetSound(som, volume)</code></td><td>Som padrão. <code>false</code> desativa</td></tr>
<tr><td><code>SetClickToClose(boolean)</code></td><td>Fechar ao clicar</td></tr>
<tr><td><code>SetTheme(tabela)</code></td><td>Sobrescreve cores de <code>Notifications.Theme</code>. Veja <a href="#tema">Tema</a></td></tr>
<tr><td><code>SetFont(fonte)</code></td><td>Define a fonte de título, descrição e nome</td></tr>
</table>
<br>
<h2 id="controle">10. Controle</h2>
 
<pre lang="lua">Notifications.Clear()
Notifications.Destroy()
</pre>
 
<table>
<tr><th align="left">Função</th><th align="left">Descrição</th></tr>
<tr><td><code>Clear()</code></td><td>Fecha todas as notificações</td></tr>
<tr><td><code>Destroy()</code></td><td>Remove o módulo da tela</td></tr>
</table>
<br>
<h2 id="config">11. Config</h2>
 
<p>Todas as opções ficam em <code>Notifications.Config</code>. Os valores abaixo são exemplos.</p>
<h4>Geral</h4>
 
<pre lang="lua">Notifications.Config.Name = false
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
</pre>
 
<h4>Visual</h4>
 
<pre lang="lua">Notifications.Config.ShowIcon = true
Notifications.Config.Glow = true
Notifications.Config.IconBox = 32
Notifications.Config.IconSize = 18
Notifications.Config.Radius = 10
</pre>
 
<h4>Comportamento</h4>
 
<pre lang="lua">Notifications.Config.ShowProgress = true
Notifications.Config.ShowType = true
Notifications.Config.HoverPause = true
Notifications.Config.Group = false
Notifications.Config.ClickToClose = true
Notifications.Config.Sound = false
Notifications.Config.SoundVolume = 0.5
</pre>
 
<h4>Texto</h4>
 
<pre lang="lua">Notifications.Config.TitleSize = 14
Notifications.Config.DescriptionSize = 13
Notifications.Config.NameSize = 11
Notifications.Config.TitleFont = Enum.Font.GothamSemibold
Notifications.Config.DescriptionFont = Enum.Font.Gotham
Notifications.Config.NameFont = Enum.Font.GothamBold
</pre>
 
<h4>Animações</h4>
 
<pre lang="lua">Notifications.Config.TweenIn = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
Notifications.Config.TweenOut = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
</pre>
 
<h4>Referência das chaves</h4>
 
<table>
<tr><th align="left">Chave</th><th align="left">Descrição</th></tr>
<tr><td><code>Name</code></td><td>Nome do painel. <code>false</code> esconde</td></tr>
<tr><td><code>GuiName</code></td><td>Nome do ScreenGui</td></tr>
<tr><td><code>Thumbnail</code></td><td>Thumbnail padrão</td></tr>
<tr><td><code>Side</code></td><td><code>Left</code> ou <code>Right</code></td></tr>
<tr><td><code>Vertical</code></td><td><code>Top</code> ou <code>Bottom</code></td></tr>
<tr><td><code>Width</code></td><td>Largura da notificação</td></tr>
<tr><td><code>Margin</code></td><td>Distância da borda da tela</td></tr>
<tr><td><code>Padding</code></td><td>Espaço entre notificações</td></tr>
<tr><td><code>MaxVisible</code></td><td>Máximo na tela</td></tr>
<tr><td><code>DefaultDuration</code></td><td>Duração padrão</td></tr>
<tr><td><code>ThumbnailSize</code></td><td>Tamanho da thumbnail</td></tr>
<tr><td><code>RingSize</code></td><td>Tamanho do spinner do loading</td></tr>
<tr><td><code>ShowIcon</code></td><td>Mostra o ícone nas notificações normais</td></tr>
<tr><td><code>Glow</code></td><td>Brilho colorido no lado esquerdo do card</td></tr>
<tr><td><code>IconBox</code></td><td>Tamanho do quadrado do ícone</td></tr>
<tr><td><code>IconSize</code></td><td>Tamanho do ícone dentro do quadrado</td></tr>
<tr><td><code>Radius</code></td><td>Arredondamento do card</td></tr>
<tr><td><code>ShowProgress</code></td><td>Barra de tempo visível</td></tr>
<tr><td><code>ShowType</code></td><td>Mostra o tipo em maiúsculas acima do título</td></tr>
<tr><td><code>HoverPause</code></td><td>Pausa a contagem com o mouse em cima</td></tr>
<tr><td><code>Group</code></td><td>Agrupa notificações iguais</td></tr>
<tr><td><code>ClickToClose</code></td><td>Fecha ao clicar</td></tr>
<tr><td><code>Sound</code> / <code>SoundVolume</code></td><td>Som e volume</td></tr>
<tr><td><code>TitleSize</code> / <code>DescriptionSize</code> / <code>NameSize</code></td><td>Tamanhos de texto</td></tr>
<tr><td><code>TitleFont</code> / <code>DescriptionFont</code> / <code>NameFont</code></td><td>Fontes</td></tr>
<tr><td><code>TweenIn</code> / <code>TweenOut</code></td><td>Animações de entrada e saída</td></tr>
</table>
<br>
<h2 id="tema">12. Tema</h2>
 
<p>As cores ficam em <code>Notifications.Theme</code>. Mude com <code>SetTheme</code> ou direto na tabela. Vale para as próximas notificações.</p>
<pre lang="lua">Notifications.SetTheme({
    Panel = Color3.fromRGB(16, 16, 18),
    PanelTop = Color3.fromRGB(30, 30, 34),
    Accent = Color3.fromRGB(130, 110, 255),
})
</pre>
 
<table>
<tr><th align="left">Chave</th><th align="left">Descrição</th></tr>
<tr><td><code>Panel</code></td><td>Cor de baixo do gradiente do fundo</td></tr>
<tr><td><code>PanelTop</code></td><td>Cor de cima do gradiente do fundo</td></tr>
<tr><td><code>Line</code></td><td>Cor final do gradiente da borda</td></tr>
<tr><td><code>Track</code></td><td>Fundo da barra de progresso e do círculo do loading</td></tr>
<tr><td><code>Accent</code></td><td>Cor de destaque quando não há tipo nem <code>Color</code></td></tr>
<tr><td><code>TitleText</code></td><td>Cor do título</td></tr>
<tr><td><code>TextSecondary</code></td><td>Cor da descrição</td></tr>
<tr><td><code>TextHeader</code></td><td>Cor do nome do painel</td></tr>
<tr><td><code>TextPrimary</code></td><td>Cor do contador do agrupamento</td></tr>
<tr><td><code>HoverFill</code></td><td>Cor do brilho ao passar o mouse</td></tr>
</table>
<br>
<h2 id="utils">13. Utils</h2>
 
<pre lang="lua">Notifications.NormalizeImage("rbxassetid://123")
Notifications.ResolveIcon("heart")
Notifications.ResolveType("warn")
Notifications.GetParents()
Notifications.Protect(gui)
</pre>
 
<table>
<tr><th align="left">Função</th><th align="left">Descrição</th></tr>
<tr><td><code>NormalizeImage(valor)</code></td><td>Converte número ou texto em um link de imagem válido</td></tr>
<tr><td><code>ResolveIcon(valor)</code></td><td>Converte nome, id ou tipo em um link de imagem. Retorna <code>nil</code> se não achar</td></tr>
<tr><td><code>ResolveType(tipo)</code></td><td>Resolve aliases (<code>warn</code> vira <code>Warning</code>)</td></tr>
<tr><td><code>GetParents()</code></td><td>Retorna onde a GUI pode ser colocada</td></tr>
<tr><td><code>Protect(gui)</code></td><td>Protege a GUI no executor</td></tr>
<tr><td><code>Normalize(...)</code></td><td>Normaliza os argumentos de <code>Notify</code> (uso interno)</td></tr>
</table>
<br>
<h2 id="exemplo-completo">14. Exemplo completo</h2>
 
<pre lang="lua">-- // Notifications
local Notifications = loadstring(game:HttpGet("https://raw.githubusercontent.com/pvpgalinhamonzonrebasexk/gazrenkinras/refs/heads/main/Templates/Notification.lua"))()
local Notify = Notifications.Notify
task.wait(1)
Notifications.Info("Info", "Something happened", 4)
task.wait(1)
Notifications.Success("Success", "Everything worked", 4)
task.wait(1)
Notifications.Warning("Warning", "Be careful", 4)
task.wait(1)
Notifications.Error("Error", "Something failed", 4)
task.wait(1)
Notify({
    Title = "Custom icon",
    Description = "Icon by name",
    Icon = "heart",
    Duration = 4,
})
task.wait(1)
local loading = Notifications.Loading("Downloading", "0%")
for step = 1, 10 do
    task.wait(0.3)
    loading.Progress(step / 10)
    loading.Update({
        Description = (step * 10) .. "%",
    })
end
loading.Success("Done", "100%", 3)
</pre>