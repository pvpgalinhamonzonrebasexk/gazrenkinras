-- // Services
if not game:IsLoaded() then
	game.Loaded:Wait()
end

local cloneRef = cloneref or function(object)
	return object
end

local function getService(name)
	return cloneRef(game:GetService(name))
end

local UserInputService = getService("UserInputService")
local TweenService = getService("TweenService")
local RunService = getService("RunService")
local HttpService = getService("HttpService")
local Players = getService("Players")

local player = Players.LocalPlayer
if not player then
	repeat
		task.wait()
		player = Players.LocalPlayer
	until player
end

local env = (getgenv and getgenv()) or _G
local copyToClipboard = setclipboard or toclipboard
local executorName = (identifyexecutor and identifyexecutor()) or "Executor"
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local function px(value)
	if isMobile then
		return math.floor(value * 1.3)
	end
	return value
end

-- // Settings
local settings = {
	PathMode = "Index",
	PerPage = isMobile and 2 or 4,
	ShowExecutor = true,
	LogBlocked = true,
	AutoIgnore = false,
	LightMode = isMobile,
	CaptureOutgoing = false,
	CaptureIncoming = false,
}
local saveSettings
local settingsFolder = "Ecohub/Remotespy"
local settingsPath = settingsFolder .. "/Settings.json"

do
	pcall(function()
		if isfile and isfile(settingsPath) then
			for key, value in pairs(HttpService:JSONDecode(readfile(settingsPath))) do
				if settings[key] ~= nil and type(value) == type(settings[key]) then
					settings[key] = value
				end
			end
		end
	end)
	settings.CaptureOutgoing = false
	settings.CaptureIncoming = false

	function saveSettings()
		pcall(function()
			if not isfolder("Ecohub") then
				makefolder("Ecohub")
			end
			if not isfolder(settingsFolder) then
				makefolder(settingsFolder)
			end
			writefile(settingsPath, HttpService:JSONEncode(settings))
		end)
	end
end

-- // Utils
local Report
local NAME_CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
local SUSPICIOUS_NAMES = {"anticheat", "anti_cheat", "anti-cheat", "cheat", "exploit", "detection", "violation", "suspicious", "banplayer", "kickplayer", "securitycheck"}

local Utils = {
	Notices = {},
	NameCache = {},
}

function Utils:Notice(title, text)
	local key = title .. text
	local now = os.clock()
	local last = Utils.Notices[key]
	if last and now - last < 5 then
		return
	end
	Utils.Notices[key] = now
	task.defer(function()
		Report("Warning", title, text)
	end)
end

function Utils:Guard(fn)
	return function(...)
		local ok, err = pcall(fn, ...)
		if not ok then
			Utils:Notice("Erro", tostring(err))
		end
	end
end

function Utils:IsSuspicious(name)
	local cached = Utils.NameCache[name]
	if cached ~= nil then
		return cached
	end
	local lowered = string.lower(tostring(name))
	local result = false
	for _, word in ipairs(SUSPICIOUS_NAMES) do
		if string.find(lowered, word, 1, true) then
			result = true
			break
		end
	end
	Utils.NameCache[name] = result
	return result
end

function Utils:RandomName()
	local characters = {}
	for index = 1, math.random(8, 14) do
		local position = math.random(1, #NAME_CHARS)
		characters[index] = NAME_CHARS:sub(position, position)
	end
	return table.concat(characters)
end

function Utils:GetParent()
	if gethui then
		local ok, container = pcall(gethui)
		if ok and container then
			return container
		end
	end
	local ok, coreGui = pcall(getService, "CoreGui")
	if ok and coreGui then
		return coreGui
	end
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

function Utils:PlaceGui(gui)
	pcall(function()
		gui.Parent = Utils:GetParent()
	end)
	if not gui.Parent then
		gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
end

function Utils:Validate(body)
	if type(body) ~= "string" then
		return false
	end
	local size = #body
	if size == 0 or size > 4000000 then
		return false
	end
	local head = body:sub(1, 64):lower()
	if head:find("^%s*<!doctype") or head:find("^%s*<html") or head:sub(1, 3) == "404" then
		return false
	end
	return true
end

function Utils:Load(url)
	local fetched, body = pcall(function()
		return game:HttpGet(url)
	end)
	if not fetched or not Utils:Validate(body) then
		return nil
	end
	local chunk = loadstring(body)
	if not chunk then
		return nil
	end
	local executed, result = pcall(chunk)
	return executed and result or nil
end

-- // Constants
local Controls = {
	Close = "rbxassetid://9886659671",
	Min = "rbxassetid://9886659276",
	Max = "rbxassetid://9886659406",
	Restore = "rbxassetid://9886659001",
}

local ClassImages = {
	RemoteEvent = "rbxassetid://110803789420086",
	UnreliableRemoteEvent = "rbxassetid://126244162339059",
	RemoteFunction = "rbxassetid://108537517159060",
}

local Methods = {
	Outgoing = {
		RemoteEvent = "FireServer",
		UnreliableRemoteEvent = "FireServer",
		RemoteFunction = "InvokeServer",
	},
	Incoming = {
		RemoteEvent = "OnClientEvent",
		UnreliableRemoteEvent = "OnClientEvent",
	},
}

local Theme = {
	Panel = Color3.fromRGB(20, 20, 20),
	Sidebar = Color3.fromRGB(16, 16, 16),
	Card = Color3.fromRGB(25, 25, 30),
	Active = Color3.fromRGB(30, 30, 40),
	Hover = Color3.fromRGB(24, 24, 30),
	Line = Color3.fromRGB(45, 45, 52),
	Text = Color3.fromRGB(255, 255, 255),
	Muted = Color3.fromRGB(105, 105, 115),
	Error = Color3.fromRGB(220, 80, 80),
	Success = Color3.fromRGB(130, 200, 130),
	Number = Color3.fromRGB(255, 190, 60),
	Boolean = Color3.fromRGB(230, 130, 100),
	Value = Color3.fromRGB(210, 210, 215),
	Blocked = Color3.fromRGB(34, 18, 18),
	BlockedLine = Color3.fromRGB(222, 82, 82),
}

local AlignLeft = Enum.TextXAlignment.Left
local AlignRight = Enum.TextXAlignment.Right
local AlignTop = Enum.TextYAlignment.Top
local AutoX = Enum.AutomaticSize.X
local AutoY = Enum.AutomaticSize.Y
local AutoXY = Enum.AutomaticSize.XY
local Horizontal = Enum.FillDirection.Horizontal

-- // Notifications
local notify

do
	local Notify
	local Notifications = Utils:Load("https://raw.githubusercontent.com/pvpgalinhamonzonrebasexk/gazrenkinras/refs/heads/main/Templates/Notification.luau")
	if Notifications then
		pcall(function()
			Notify = Notifications.Notify
			Notifications.SetName("Ecohub")
			Notifications.SetPosition("BottomRight")
			Notifications.SetMaxVisible(3)
			Notifications.SetGroup(true)
		end)
	end
	function notify(title, description, kind, duration)
		if Notify then
			pcall(Notify, title, description, duration or 3, kind or "Info")
			return
		end
		pcall(function()
			getService("StarterGui"):SetCore("SendNotification", {Title = title, Text = description, Duration = duration or 3})
		end)
	end
end

function Report(kind, title, message, id, duration)
	notify(tostring(title), tostring(message), kind, duration)
end

-- // Reload
if env.EcohubUnload then
	pcall(env.EcohubUnload)
	env.EcohubUnload = nil
end

saveSettings()

-- // UI Helpers
local new, newIcon, setIcon, createPill, pad, tween, hover, sequencer, windowSize

do
	local running = setmetatable({}, {__mode = "k"})
	local iconModule = Utils:Load("https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua")
	if not iconModule then
		notify("Ecohub", "Falha ao carregar os ícones.", "Warning")
	end

	local function merge(base, extra)
		local result = {}
		for key, value in pairs(base) do
			result[key] = value
		end
		for key, value in pairs(extra) do
			result[key] = value
		end
		return result
	end

	local BaseGui = {BackgroundTransparency = 1, BorderSizePixel = 0}
	local BaseText = merge(BaseGui, {Font = Enum.Font.Gotham, TextColor3 = Theme.Text, TextSize = 12, ClipsDescendants = true})

	local Defaults = {
		Frame = BaseGui,
		ScrollingFrame = merge(BaseGui, {ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Muted, CanvasSize = UDim2.new()}),
		ImageLabel = BaseGui,
		ImageButton = merge(BaseGui, {AutoButtonColor = false}),
		TextLabel = BaseText,
		TextButton = merge(BaseText, {AutoButtonColor = false}),
		TextBox = merge(BaseText, {ClearTextOnFocus = false}),
		UICorner = {CornerRadius = UDim.new(0, 6)},
		UIStroke = {ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Theme.Line, Thickness = 1},
		UIListLayout = {SortOrder = Enum.SortOrder.LayoutOrder},
	}

	function setIcon(image, name)
		local icon
		if iconModule then
			local ok, result = pcall(iconModule.GetAsset, name)
			icon = ok and result or nil
		end
		if not icon then
			image.Visible = false
			return
		end
		image.Image = icon.Url
		image.ImageRectOffset = icon.ImageRectOffset
		image.ImageRectSize = icon.ImageRectSize
		image.Visible = true
	end

	function new(className, props)
		local object = Instance.new(className)
		for key, value in pairs(Defaults[className] or {}) do
			if props[key] == nil then
				object[key] = value
			end
		end
		if props.BackgroundColor3 and props.BackgroundTransparency == nil then
			object.BackgroundTransparency = 0
		end
		local parent
		for key, value in pairs(props) do
			if key == "Parent" then
				parent = value
			elseif type(key) == "string" and type(value) == "table" then
				value.Parent = object
				new(key, value)
			else
				object[key] = value
			end
		end
		object.Parent = parent
		return object
	end

	function newIcon(name, props, class)
		props.ImageColor3 = props.ImageColor3 or Theme.Muted
		local image = new(class or "ImageLabel", props)
		setIcon(image, name)
		return image
	end

	function createPill(parent, text, order, height, icon)
		local button = new("TextButton", {
			AutomaticSize = AutoX,
			BackgroundColor3 = Theme.Panel,
			LayoutOrder = order,
			Size = UDim2.new(0, 0, 0, height),
			Text = "",
			UICorner = {},
			UIStroke = {},
			Parent = parent,
		})
		local holder = new("Frame", {
			AutomaticSize = AutoX,
			Size = UDim2.new(0, 0, 1, 0),
			UIListLayout = {FillDirection = Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6)},
			UIPadding = {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)},
			Parent = button,
		})
		if icon then
			newIcon(icon, {LayoutOrder = 1, Size = UDim2.fromOffset(14, 14), Parent = holder})
		end
		local label = new("TextLabel", {
			AutomaticSize = AutoX,
			LayoutOrder = 2,
			Size = UDim2.new(0, 0, 1, 0),
			Text = text,
			Parent = holder,
		})
		return button, label
	end

	function pad(amount)
		local size = UDim.new(0, amount)
		return {PaddingTop = size, PaddingBottom = size, PaddingLeft = size, PaddingRight = size}
	end

	function tween(object, duration, props)
		if settings.LightMode then
			for property, value in pairs(props) do
				object[property] = value
			end
			return
		end
		local list = running[object]
		if not list then
			list = {}
			running[object] = list
		end
		for property in pairs(props) do
			local previous = list[property]
			if previous then
				previous:Cancel()
			end
		end
		local handle = TweenService:Create(object, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
		for property in pairs(props) do
			list[property] = handle
		end
		handle.Completed:Once(function()
			for property in pairs(props) do
				if list[property] == handle then
					list[property] = nil
				end
			end
		end)
		handle:Play()
	end

	function hover(object, property, normal, active)
		object.MouseEnter:Connect(function()
			tween(object, 0.15, {[property] = active})
		end)
		object.MouseLeave:Connect(function()
			local target = normal
			if type(normal) == "function" then
				target = normal()
			end
			tween(object, 0.15, {[property] = target})
		end)
	end

	function sequencer()
		local count = 0
		return function()
			count += 1
			return count
		end
	end

	function windowSize(big)
		local camera = workspace.CurrentCamera
		local view = camera and camera.ViewportSize or Vector2.new(1280, 720)
		local width = big and 620 or 550
		local height = big and 550 or 350
		return UDim2.fromOffset(math.min(width, view.X - 24), math.min(height, view.Y - 24))
	end
end

-- // Code Generator
local serialize, describe, typeColor, setCode, buildCode, buildPath, buildCallCode, buildHookCode, buildFunctionInfo, buildFunctionTable

do
	local SyntaxColors = {
		Keyword = "#f86d7c",
		String = "#adf195",
		Number = "#ffc600",
		Builtin = "#84d6f7",
		Comment = "#666666",
	}

	local function lookup(list)
		local result = {}
		for _, value in ipairs(list) do
			result[value] = true
		end
		return result
	end

	local Keywords = lookup({"and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while", "continue"})
	local Literals = lookup({"true", "false", "nil"})
	local Builtins = lookup({"game", "workspace", "script", "math", "string", "table", "task", "print", "warn", "pairs", "ipairs", "next", "select", "typeof", "type", "tostring", "tonumber", "pcall", "Enum", "Instance", "Vector2", "Vector3", "CFrame", "Color3", "UDim", "UDim2", "BrickColor", "NumberRange", "Rect", "Ray", "buffer", "getconnections", "hookfunction", "hookmetamethod", "getnamecallmethod", "firesignal", "rawequal", "getnilinstances", "newproxy"})

	local function escapeRich(text)
		return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
	end

	local function colorize(text, color)
		return '<font color="' .. color .. '">' .. escapeRich(text) .. "</font>"
	end

	local function highlight(source)
		local output = {}
		local index = 1
		local length = #source
		while index <= length do
			local char = source:sub(index, index)
			local token
			local color
			if source:sub(index, index + 1) == "--" then
				token = source:match("^[^\n]*", index)
				color = SyntaxColors.Comment
			elseif char == '"' or char == "'" then
				local finish = index + 1
				while finish <= length do
					local current = source:sub(finish, finish)
					if current == "\\" then
						finish += 2
					elseif current == char then
						break
					elseif current == "\n" then
						finish -= 1
						break
					else
						finish += 1
					end
				end
				token = source:sub(index, finish)
				color = SyntaxColors.String
			elseif char:match("%d") then
				token = source:match("^0[xX]%x+", index)
				if not token then
					token = source:match("^%d+%.?%d*", index)
					token = token .. (source:match("^[eE][+-]?%d+", index + #token) or "")
				end
				color = SyntaxColors.Number
			elseif char:match("[%a_]") then
				token = source:match("^[%w_]+", index)
				if Literals[token] then
					color = SyntaxColors.Number
				elseif Keywords[token] then
					color = SyntaxColors.Keyword
				elseif Builtins[token] then
					color = SyntaxColors.Builtin
				end
			else
				token = char
			end
			index += #token
			table.insert(output, color and colorize(token, color) or escapeRich(token))
		end
		return table.concat(output)
	end

	function setCode(label, text)
		local limit = settings.LightMode and 2500 or 6000
		if #text <= limit then
			local colored = highlight(text)
			if #colored <= 16000 then
				label.RichText = true
				label.Text = colored
				return
			end
		end
		label.RichText = false
		label.Text = text:sub(1, 16000)
	end

	local Escapes = {["\n"] = "\\n", ["\r"] = "\\r", ["\t"] = "\\t", ['"'] = '\\"', ["\\"] = "\\\\"}

	local function quote(text)
		local escaped = text:gsub('[%c"\\\127-\255]', function(char)
			return Escapes[char] or string.format("\\%03d", char:byte())
		end)
		return '"' .. escaped .. '"'
	end

	local function safeText(value)
		local kind = typeof(value)
		if kind == "table" or kind == "userdata" then
			return kind
		end
		return tostring(value)
	end

	local function formatNumber(number)
		if number ~= number then
			return "0/0"
		elseif number == math.huge then
			return "math.huge"
		elseif number == -math.huge then
			return "-math.huge"
		end
		return string.format("%.14g", number)
	end

	local function formatNumbers(...)
		local parts = {}
		for index, value in ipairs({...}) do
			parts[index] = formatNumber(value)
		end
		return table.concat(parts, ", ")
	end

	local function isIdentifier(name)
		return name:match("^[%a_][%w_]*$") ~= nil and not Keywords[name]
	end

	local function same(first, second)
		if compareinstances then
			return compareinstances(first, second)
		end
		return first == second
	end

	local function accessor(name)
		local mode = settings.PathMode
		if mode == "WaitForChild" then
			return ":WaitForChild(" .. quote(name) .. ")"
		elseif mode == "FindFirstChild" then
			return ":FindFirstChild(" .. quote(name) .. ")"
		elseif isIdentifier(name) then
			return "." .. name
		end
		return "[" .. quote(name) .. "]"
	end

	local usedNil = false

	local function getPath(object)
		local path = ""
		local current = object
		while current do
			if same(current, game) then
				return "game" .. path
			elseif same(current, workspace) then
				return "workspace" .. path
			elseif same(current, player) then
				return 'game:GetService("Players").LocalPlayer' .. path
			elseif player.Character and same(current, player.Character) then
				return 'game:GetService("Players").LocalPlayer.Character' .. path
			end
			local parent = current.Parent
			if not parent then
				usedNil = true
				local ok, id = pcall(current.GetDebugId, current)
				return "GetNil(" .. quote(current.Name) .. ", " .. quote(ok and id or "") .. ")" .. path
			end
			local service = same(parent, game) and game:FindService(current.ClassName)
			if service and same(service, current) then
				path = ":GetService(" .. quote(current.ClassName) .. ")" .. path
			else
				path = accessor(current.Name) .. path
			end
			current = parent
		end
		return path
	end

	local serializers = {}

	function serialize(value, level, seen)
		local serializer = serializers[typeof(value)]
		if not serializer then
			return "nil"
		end
		return serializer(value, level or 0, seen or {})
	end

	serializers["nil"] = function()
		return "nil"
	end
	serializers.boolean = function(value)
		return tostring(value)
	end
	serializers.number = function(value)
		return formatNumber(value)
	end
	serializers.string = function(value)
		return quote(value)
	end
	serializers.Instance = function(value)
		return getPath(value)
	end
	serializers["function"] = function()
		return "function() end"
	end
	serializers.userdata = function()
		return "newproxy()"
	end
	serializers.buffer = function(value)
		return "buffer.fromstring(" .. quote(buffer.tostring(value)) .. ")"
	end
	serializers.Vector2 = function(value)
		return "Vector2.new(" .. formatNumbers(value.X, value.Y) .. ")"
	end
	serializers.Vector3 = function(value)
		return "Vector3.new(" .. formatNumbers(value.X, value.Y, value.Z) .. ")"
	end
	serializers.CFrame = function(value)
		return "CFrame.new(" .. formatNumbers(value:GetComponents()) .. ")"
	end
	serializers.Color3 = function(value)
		return "Color3.new(" .. formatNumbers(value.R, value.G, value.B) .. ")"
	end
	serializers.UDim = function(value)
		return "UDim.new(" .. formatNumbers(value.Scale, value.Offset) .. ")"
	end
	serializers.UDim2 = function(value)
		return "UDim2.new(" .. formatNumbers(value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset) .. ")"
	end
	serializers.BrickColor = function(value)
		return "BrickColor.new(" .. quote(value.Name) .. ")"
	end
	serializers.EnumItem = function(value)
		return tostring(value)
	end
	serializers.Enum = function(value)
		return "Enum." .. tostring(value)
	end
	serializers.NumberRange = function(value)
		return "NumberRange.new(" .. formatNumbers(value.Min, value.Max) .. ")"
	end
	serializers.Rect = function(value)
		return "Rect.new(" .. formatNumbers(value.Min.X, value.Min.Y, value.Max.X, value.Max.Y) .. ")"
	end
	serializers.Ray = function(value)
		return "Ray.new(" .. serialize(value.Origin) .. ", " .. serialize(value.Direction) .. ")"
	end
	serializers.DateTime = function(value)
		return "DateTime.fromUnixTimestamp(" .. tostring(value.UnixTimestamp) .. ")"
	end
	serializers.table = function(value, level, seen)
		if seen[value] then
			return "{}"
		end
		seen[value] = true
		local entries = {}
		local arrayLength = rawlen(value)
		for index = 1, arrayLength do
			if #entries >= 150 then
				break
			end
			entries[#entries + 1] = serialize(rawget(value, index), level + 1, seen)
		end
		for key, item in next, value do
			if #entries >= 150 then
				break
			end
			local isArrayKey = type(key) == "number" and key >= 1 and key <= arrayLength and key % 1 == 0
			if not isArrayKey then
				local keyText = type(key) == "string" and isIdentifier(key) and key or "[" .. serialize(key, level + 1, seen) .. "]"
				entries[#entries + 1] = keyText .. " = " .. serialize(item, level + 1, seen)
			end
		end
		seen[value] = nil
		if #entries == 0 then
			return "{}"
		end
		local inline = table.concat(entries, ", ")
		if #inline <= 60 and not inline:find("\n") then
			return "{" .. inline .. "}"
		end
		local indent = string.rep("\t", level + 1)
		return "{\n" .. indent .. table.concat(entries, ",\n" .. indent) .. "\n" .. string.rep("\t", level) .. "}"
	end

	function describe(value)
		if typeof(value) == "Instance" then
			local ok, name = pcall(value.GetFullName, value)
			if ok then
				return name
			end
		end
		local ok, text = pcall(serialize, value, 0)
		text = ok and text or safeText(value)
		text = text:gsub("%s+", " ")
		if #text > 140 then
			text = text:sub(1, 140) .. "..."
		end
		return text
	end

	function typeColor(kind)
		if kind == "string" then
			return Theme.Success
		elseif kind == "boolean" then
			return Theme.Boolean
		elseif kind == "nil" then
			return Theme.Muted
		elseif kind == "Instance" or kind == "table" or kind == "function" or kind == "userdata" then
			return Theme.Value
		end
		return Theme.Number
	end

	local nilHelper = table.concat({
		"local function GetNil(name, debugId)",
		"\tfor _, object in getnilinstances() do",
		"\t\tif object.Name == name and object:GetDebugId() == debugId then",
		"\t\t\treturn object",
		"\t\tend",
		"\tend",
		"end",
	}, "\n")

	local OutgoingHookTemplate = table.concat({
		"local namecallHook",
		'namecallHook = hookmetamethod(game, "__namecall", function(...)',
		"\tlocal self = ...",
		'\tif rawequal(self, Event) and getnamecallmethod() == "{Method}" then',
		'\t\tprint("Intercepted (__namecall) " .. Event.Name .. ":{Method}()", select(2, ...))',
		"\tend",
		"\treturn namecallHook(...)",
		"end)",
		"",
		"local original{Method}",
		"original{Method} = hookfunction(Event.{Method}, function(...)",
		"\tlocal self = ...",
		"\tif rawequal(self, Event) then",
		'\t\tprint("Intercepted (__index) " .. Event.Name .. ":{Method}()", select(2, ...))',
		"\tend",
		"\treturn original{Method}(...)",
		"end)",
	}, "\n")

	local IncomingHookTemplate = table.concat({
		"for _, connection in getconnections(Event.{Method}) do",
		"\tlocal original",
		"\toriginal = hookfunction(connection.Function, function(...)",
		'\t\tprint("Intercepted ({Method}) " .. Event.Name, ...)',
		"\t\treturn original(...)",
		"\tend)",
		"end",
	}, "\n")

	local function joinArguments(arguments)
		if arguments.n == 0 then
			return ""
		end
		local parts = {}
		for index = 1, arguments.n do
			parts[index] = serialize(arguments[index], 1)
		end
		local joined = table.concat(parts, ", ")
		if #joined <= 80 and not joined:find("\n") then
			return joined
		end
		for index, part in ipairs(parts) do
			parts[index] = "\t" .. part
		end
		return "\n" .. table.concat(parts, ",\n") .. "\n"
	end

	function buildCode(object, variable, body)
		usedNil = false
		local path = getPath(object)
		local text = body and body() or ""
		local helper = usedNil and (nilHelper .. "\n\n") or ""
		return helper .. "local " .. (variable or "Event") .. " = " .. path .. (body and "\n\n" .. text or "")
	end

	function buildPath(object)
		usedNil = false
		local path = getPath(object)
		return (usedNil and (nilHelper .. "\n\n") or "") .. path
	end

	function buildCallCode(call, remote, direction)
		return buildCode(remote, "Event", function()
			local method = Methods[direction][remote.ClassName]
			local arguments = joinArguments(call.Arguments)
			if direction == "Incoming" then
				local separator = arguments:sub(1, 1) == "\n" and "," or ", "
				return "firesignal(Event." .. method .. (arguments == "" and "" or separator .. arguments) .. ")"
			end
			return "Event:" .. method .. "(" .. arguments .. ")"
		end)
	end

	function buildHookCode(remote, direction)
		return buildCode(remote, "Event", function()
			local method = Methods[direction][remote.ClassName]
			local template = direction == "Incoming" and IncomingHookTemplate or OutgoingHookTemplate
			return (template:gsub("{Method}", method))
		end)
	end

	local function countOf(getter, func)
		if not getter then
			return "N/A"
		end
		local ok, result = pcall(getter, func)
		return ok and type(result) == "table" and tostring(#result) or "N/A"
	end

	local function hashOf(func)
		if not getfunctionhash then
			return "N/A"
		end
		local ok, result = pcall(getfunctionhash, func)
		return ok and result and tostring(result) or "N/A"
	end

	function buildFunctionInfo(call)
		if call.Server then
			return "Chamada recebida do servidor.\nSem informações da função."
		elseif call.IsExecutor or not call.Function then
			return "Chamado por " .. (call.IsExecutor and executorName or "um chamador desconhecido") .. ".\nSem informações da função."
		end
		local func = call.Function
		local name = debug.info(func, "n")
		local script = typeof(call.Origin) == "Instance" and call.Origin:GetFullName() or "N/A"
		local lines = {
			"<b>Nome:</b> " .. escapeRich((name and name ~= "") and name or "Anônima"),
			"<b>Fonte:</b> " .. escapeRich(tostring(call.Source)),
			"<b>Linha:</b> " .. tostring(call.Line),
			"<b>Script:</b> " .. escapeRich(script),
		}
		if islclosure and islclosure(func) then
			table.insert(lines, "<b>Closure:</b> Luau")
			table.insert(lines, "<b>Hash:</b> " .. escapeRich(hashOf(func)))
			table.insert(lines, "<b>Constantes:</b> " .. countOf(debug.getconstants, func))
			table.insert(lines, "<b>Upvalues:</b> " .. countOf(debug.getupvalues, func))
			table.insert(lines, "<b>Protos:</b> " .. countOf(debug.getprotos, func))
		else
			table.insert(lines, "<b>Closure:</b> C")
		end
		return table.concat(lines, "\n")
	end

	function buildFunctionTable(call)
		local info = {Source = call.Source, Line = call.Line, Script = call.Origin}
		local func = call.Function
		if func then
			info.Name = debug.info(func, "n")
			if islclosure and islclosure(func) then
				pcall(function()
					info.Constants = debug.getconstants(func)
					info.Upvalues = debug.getupvalues(func)
				end)
			end
		end
		return "local Info = " .. serialize(info, 0)
	end

end

-- // Clipboard
local function copyText(text, message)
	if not copyToClipboard then
		notify("Área de transferência", "setclipboard não está disponível neste executor.", "Error")
		return
	end
	if pcall(copyToClipboard, text) then
		notify("Copiado", message, "Success")
	end
end

-- // Remote Hooks
local Spy = env.EcohubSpyV7
local setConnections, startIncoming, stopConnections

do
	local OutgoingMethods = {FireServer = true, InvokeServer = true}

	local function weakTable()
		return setmetatable({}, {__mode = "k"})
	end

	local function inspectCaller()
		local thread = oth.get_original_thread()
		if not thread then
			return false
		end
		if isourthread and isourthread(thread) then
			return true
		end
		local func, source, line
		pcall(function()
			for level = 0, 14 do
				local candidate, candidateSource, candidateLine = debug.info(thread, level, "fsl")
				if not candidate then
					break
				end
				if candidateSource ~= "[C]" and not (isexecutorclosure and isexecutorclosure(candidate)) then
					func, source, line = candidate, candidateSource, candidateLine
					break
				end
			end
		end)
		local origin
		if getscriptfromthread then
			local ok, result = pcall(getscriptfromthread, thread)
			origin = ok and result or nil
		end
		return false, func, source, line, origin
	end

	if not Spy then
		Spy = {Active = false, Hooked = false}
		env.EcohubSpyV7 = Spy
		Spy.Monitor = function(original, self, method, ...)
			return original(self, ...)
		end
	end

	local function installHooks()
		if Spy.Hooked then
			return
		end
		pcall(function()
			if not (oth and oth.hook) then
				return
			end
			local event = Instance.new("RemoteEvent")
			local func = Instance.new("RemoteFunction")
			local unreliable = Instance.new("UnreliableRemoteEvent")
			local targets = {
				{event.FireServer, "FireServer"},
				{func.InvokeServer, "InvokeServer"},
				{unreliable.FireServer, "FireServer"},
			}
			event:Destroy()
			func:Destroy()
			unreliable:Destroy()
			local seen = {}
			for _, item in ipairs(targets) do
				local target, method = item[1], item[2]
				if not seen[target] then
					seen[target] = true
					local original
					original = oth.hook(target, function(self, ...)
						return Spy.Monitor(original, self, method, ...)
					end)
				end
			end
			Spy.Hooked = true
		end)
		if Spy.Hooked then
			notify("Ecohub", "Hook de saída ativo.", "Success")
		else
			notify("Ecohub", "oth.hook indisponível neste executor: Saída indisponível.", "Warning")
		end
	end

	Spy.Install = installHooks

	Spy.Blocked = {Outgoing = weakTable(), Incoming = weakTable()}
	Spy.Ignored = {Outgoing = weakTable(), Incoming = weakTable()}

	local function prepare(remote, method, ...)
		local blocked = Spy.Blocked.Outgoing[remote] == true
		local ignored = Spy.Ignored.Outgoing[remote] == true
		if blocked and (ignored or not settings.LogBlocked) then
			return "skip"
		end
		if ignored then
			return "pass"
		end
		local isExecutor, func, source, line, origin = inspectCaller()
		return "log", {
			Arguments = table.pack(...),
			Origin = typeof(origin) == "Instance" and origin or nil,
			Function = func,
			Source = source,
			Line = line,
			IsExecutor = isExecutor,
			Blocked = blocked,
			Time = os.date("%X"),
		}
	end

	local function monitor(original, remote, method, ...)
		local handler = Spy.Active and settings.CaptureOutgoing and Spy.Handler
		if not (handler and OutgoingMethods[method] and typeof(remote) == "Instance" and Methods.Outgoing[remote.ClassName] == method) then
			return original(remote, ...)
		end
		local ok, action, call = pcall(prepare, remote, method, ...)
		if not ok then
			return original(remote, ...)
		end
		if action == "skip" then
			return
		elseif action == "pass" then
			return original(remote, ...)
		end
		task.defer(handler, "Outgoing", remote, call)
		if call.Blocked then
			return
		end
		if method == "InvokeServer" then
			local results = table.pack(original(remote, ...))
			call.Return = results
			task.defer(handler, "Return", remote, call)
			return table.unpack(results, 1, results.n)
		end
		return original(remote, ...)
	end

	Spy.Monitor = monitor

	local connections = {}
	local ownListeners = weakTable()
	local connectedObjects = weakTable()

	function setConnections(remote, enabled)
		if not getconnections then
			return
		end
		pcall(function()
			for _, connection in ipairs(getconnections(remote.OnClientEvent)) do
				local ok, callback = pcall(function()
					return connection.Function
				end)
				if not (ok and callback and ownListeners[callback]) then
					pcall(enabled and connection.Enable or connection.Disable, connection)
				end
			end
		end)
	end

	function stopConnections()
		for _, connection in ipairs(connections) do
			pcall(connection.Disconnect, connection)
		end
		connections = {}
		connectedObjects = weakTable()
	end

	local function connectIncoming(object)
		if Methods.Incoming[object.ClassName] ~= "OnClientEvent" or connectedObjects[object] then
			return
		end
		connectedObjects[object] = true
		local function listener(...)
			local handler = Spy.Handler
			if not Spy.Active or not settings.CaptureIncoming or not handler or Spy.Ignored.Incoming[object] then
				return
			end
			local blocked = Spy.Blocked.Incoming[object] == true
			if blocked and not settings.LogBlocked then
				return
			end
			handler("Incoming", object, {
				Arguments = table.pack(...),
				Server = true,
				Blocked = blocked,
				Time = os.date("%X"),
			})
		end
		ownListeners[listener] = true
		local ok, connection = pcall(function()
			return object.OnClientEvent:Connect(listener)
		end)
		if ok then
			table.insert(connections, connection)
		end
	end

	function startIncoming()
		stopConnections()
		local root = getService("ReplicatedStorage")
		table.insert(connections, root.DescendantAdded:Connect(Utils:Guard(connectIncoming)))
		task.spawn(function()
			local count = 0
			for _, object in ipairs(root:GetDescendants()) do
				pcall(connectIncoming, object)
				count += 1
				if count % 400 == 0 then
					task.wait()
				end
			end
		end)
		notify("Ecohub", "Entrada ativa em ReplicatedStorage.", "Success")
	end
end

-- // Window
local screenGui, mainFrame, topBar, body, openMenu, closeMenu, openModal, closeModal, createModal
local changelogButton, settingsButton, minButton, maxButton, closeButton

do
	local containers = {}
	if gethui then
		local ok, container = pcall(gethui)
		if ok and container then
			table.insert(containers, container)
		end
	end
	pcall(function()
		table.insert(containers, getService("CoreGui"))
	end)
	table.insert(containers, player:WaitForChild("PlayerGui"))

	for _, container in ipairs(containers) do
		for _, name in ipairs({"Ecohub", "MinimizarToggle"}) do
			pcall(function()
				local existing = container:FindFirstChild(name)
				if existing then
					existing:Destroy()
				end
			end)
		end
	end

	screenGui = new("ScreenGui", {
		Name = Utils:RandomName(),
		DisplayOrder = 1000,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	Utils:PlaceGui(screenGui)

	mainFrame = new("Frame", {
		Name = Utils:RandomName(),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Panel,
		ClipsDescendants = true,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = windowSize(false),
		UICorner = {CornerRadius = UDim.new(0, 8)},
		UIStroke = {Thickness = 1.5},
		Parent = screenGui,
	})

	topBar = new("Frame", {Size = UDim2.new(1, 0, 0, 40), Parent = mainFrame})

	new("Frame", {BackgroundColor3 = Theme.Line, Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), Parent = topBar})

	new("TextLabel", {
		Font = Enum.Font.GothamBold,
		Position = UDim2.fromOffset(14, 4),
		Size = UDim2.new(1, -240, 0, 18),
		Text = "Ecohub",
		TextSize = 14,
		TextXAlignment = AlignLeft,
		Parent = topBar,
	})

	new("TextLabel", {
		Position = UDim2.fromOffset(14, 22),
		Size = UDim2.new(1, -240, 0, 14),
		Text = "by rip_sheldoohz",
		TextColor3 = Theme.Muted,
		TextSize = 11,
		TextXAlignment = AlignLeft,
		Parent = topBar,
	})

	local controls = new("Frame", {
		Size = UDim2.new(1, -12, 1, 0),
		UIListLayout = {
			FillDirection = Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8),
		},
		Parent = topBar,
	})

	local function createTopIcon(order, icon)
		local button = newIcon(icon, {LayoutOrder = order, Size = UDim2.fromOffset(px(18), px(18)), Parent = controls}, "ImageButton")
		hover(button, "ImageColor3", Theme.Muted, Theme.Text)
		return button
	end

	local function createControl(order, image, hoverColor)
		local button = new("ImageButton", {
			Image = image,
			ImageColor3 = Theme.Muted,
			LayoutOrder = order,
			Size = UDim2.fromOffset(px(18), px(18)),
			Parent = controls,
		})
		hover(button, "ImageColor3", Theme.Muted, hoverColor or Theme.Text)
		return button
	end

	changelogButton = createTopIcon(1, "scroll-text")
	settingsButton = createTopIcon(2, "settings")
	new("Frame", {BackgroundColor3 = Theme.Line, LayoutOrder = 3, Size = UDim2.fromOffset(1, 14), Parent = controls})
	minButton = createControl(4, Controls.Min)
	maxButton = createControl(5, Controls.Max)
	closeButton = createControl(6, Controls.Close, Theme.Error)

	body = new("Frame", {Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 1, -40), Parent = mainFrame})

	local contextMenu = new("Frame", {
		AutomaticSize = AutoY,
		BackgroundColor3 = Theme.Panel,
		Size = UDim2.fromOffset(180, 0),
		Visible = false,
		ZIndex = 101,
		UICorner = {},
		UIStroke = {},
		UIListLayout = {},
		UIPadding = pad(4),
		Parent = screenGui,
	})

	local menuCatcher = new("TextButton", {Size = UDim2.fromScale(1, 1), Text = "", Visible = false, ZIndex = 100, Parent = screenGui})

	function closeMenu()
		menuCatcher.Visible = false
		contextMenu.Visible = false
	end

	function openMenu(anchor, options, mode)
		if mode == "mouse" and not UserInputService.MouseEnabled then
			mode = "below"
		end
		for _, child in ipairs(contextMenu:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		local shown = 0
		for index, option in ipairs(options) do
			if not option.Condition or option.Condition() then
				shown += 1
				local text = type(option.Text) == "function" and option.Text() or option.Text
				local icon = type(option.Icon) == "function" and option.Icon() or option.Icon
				local item = new("TextButton", {
					LayoutOrder = index,
					Size = UDim2.new(1, 0, 0, 28),
					Text = "",
					UICorner = {},
					Parent = contextMenu,
				})
				if icon then
					newIcon(icon, {Position = UDim2.new(0, 8, 0.5, -8), Size = UDim2.fromOffset(16, 16), Parent = item})
				end
				new("TextLabel", {
					Position = UDim2.fromOffset(icon and 32 or 10, 0),
					Size = UDim2.new(1, icon and -40 or -20, 1, 0),
					Text = text,
					TextXAlignment = AlignLeft,
					Parent = item,
				})
				item.MouseEnter:Connect(function()
					item.BackgroundTransparency = 0
					item.BackgroundColor3 = Theme.Active
				end)
				item.MouseLeave:Connect(function()
					item.BackgroundTransparency = 1
				end)
				item.MouseButton1Click:Connect(function()
					closeMenu()
					option.Callback()
				end)
			end
		end
		local camera = workspace.CurrentCamera
		local view = camera and camera.ViewportSize or Vector2.new(1280, 720)
		local height = shown * 28 + 8
		local x, y
		if mode == "mouse" then
			local mouse = UserInputService:GetMouseLocation()
			contextMenu.AnchorPoint = Vector2.zero
			x, y = mouse.X, math.min(mouse.Y, view.Y - height)
		elseif mode == "above" then
			contextMenu.AnchorPoint = Vector2.new(0, 1)
			x, y = anchor.AbsolutePosition.X, math.max(anchor.AbsolutePosition.Y - 4, height)
		else
			contextMenu.AnchorPoint = Vector2.zero
			x, y = anchor.AbsolutePosition.X, math.clamp(anchor.AbsolutePosition.Y + anchor.AbsoluteSize.Y + 4, 0, math.max(0, view.Y - height))
		end
		x = math.clamp(x, 0, math.max(0, view.X - 180))
		contextMenu.Position = UDim2.fromOffset(x, y)
		menuCatcher.Visible = true
		contextMenu.Visible = true
	end

	menuCatcher.MouseButton1Click:Connect(closeMenu)
	menuCatcher.MouseButton2Click:Connect(closeMenu)

	local modalLayer = new("TextButton", {
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		Visible = false,
		ZIndex = 50,
		Parent = mainFrame,
	})

	local openedModal

	function closeModal()
		if openedModal then
			openedModal.Visible = false
			openedModal = nil
		end
		modalLayer.Visible = false
		closeMenu()
	end

	function openModal(frame)
		if openedModal then
			openedModal.Visible = false
		end
		openedModal = frame
		frame.Visible = true
		modalLayer.Visible = true
	end

	modalLayer.MouseButton1Click:Connect(closeModal)

	function createModal(title, iconName, size)
		local frame = new("TextButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Theme.Panel,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = size,
			Text = "",
			Visible = false,
			UICorner = {CornerRadius = UDim.new(0, 8)},
			UIStroke = {},
			Parent = modalLayer,
		})
		local icon = newIcon(iconName, {Position = UDim2.fromOffset(12, 11), Size = UDim2.fromOffset(16, 16), Parent = frame})
		local label = new("TextLabel", {
			Font = Enum.Font.GothamBold,
			Position = UDim2.fromOffset(36, 0),
			Size = UDim2.new(1, -80, 0, 38),
			Text = title,
			TextSize = 14,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = AlignLeft,
			Parent = frame,
		})
		local close = newIcon("x", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 9),
			Size = UDim2.fromOffset(px(20), px(20)),
			Parent = frame,
		}, "ImageButton")
		hover(close, "ImageColor3", Theme.Muted, Theme.Text)
		close.MouseButton1Click:Connect(closeModal)
		new("Frame", {BackgroundColor3 = Theme.Line, Position = UDim2.fromOffset(0, 38), Size = UDim2.new(1, 0, 0, 1), Parent = frame})
		local content = new("Frame", {Position = UDim2.fromOffset(0, 39), Size = UDim2.new(1, 0, 1, -39), Parent = frame})
		return frame, content, label, icon
	end
end

-- // Remote List
local function noop(...)
end

local Actions = {
	OpenInfo = noop,
	Replay = noop,
	Ignore = noop,
	Block = noop,
	Clear = noop,
	RefreshList = noop,
}

do
	local entryMap = {Outgoing = {}, Incoming = {}}
	local entryList = {}
	local entryCount = 0
	local direction = "Outgoing"
	local selected
	local page = 1
	local renderPending = false
	local sidebarWidth = isMobile and 140 or 180

	local render
	local selectEntry
	local refreshActions
	local setDirection

	local sidebar = new("Frame", {BackgroundColor3 = Theme.Sidebar, Size = UDim2.new(0, sidebarWidth, 1, 0), Parent = body})
	new("Frame", {BackgroundColor3 = Theme.Line, Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), Parent = sidebar})

	local segments = new("Frame", {
		BackgroundColor3 = Theme.Panel,
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.new(1, -17, 0, 30),
		UICorner = {},
		UIStroke = {},
		Parent = sidebar,
	})

	local segmentButtons = {}

	local function createSegment(name, title, icon, position)
		local button = new("TextButton", {
			BackgroundColor3 = Theme.Active,
			BackgroundTransparency = 1,
			Position = position,
			Size = UDim2.new(0.5, -4, 1, -6),
			Text = "",
			UICorner = {CornerRadius = UDim.new(0, 5)},
			Parent = segments,
		})
		local holder = new("Frame", {
			Size = UDim2.fromScale(1, 1),
			UIListLayout = {
				FillDirection = Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 6),
			},
			Parent = button,
		})
		local image = newIcon(icon, {LayoutOrder = 1, Size = UDim2.fromOffset(14, 14), Parent = holder})
		local label = new("TextLabel", {
			AutomaticSize = AutoX,
			Font = Enum.Font.GothamMedium,
			LayoutOrder = 2,
			Size = UDim2.new(0, 0, 1, 0),
			Text = title,
			TextColor3 = Theme.Muted,
			Parent = holder,
		})
		segmentButtons[name] = {Button = button, Icon = image, Label = label}
		button.MouseButton1Click:Connect(function()
			setDirection(name)
		end)
	end

	createSegment("Outgoing", "Saída", "arrow-up-right", UDim2.fromOffset(3, 3))
	createSegment("Incoming", "Entrada", "arrow-down-left", UDim2.new(0.5, 1, 0, 3))

	local searchFrame = new("Frame", {
		BackgroundColor3 = Theme.Panel,
		ClipsDescendants = true,
		Position = UDim2.fromOffset(8, 44),
		Size = UDim2.new(1, -17, 0, 28),
		UICorner = {},
		UIStroke = {},
		Parent = sidebar,
	})
	local searchStroke = searchFrame:FindFirstChildOfClass("UIStroke")

	newIcon("search", {Position = UDim2.new(0, 8, 0.5, -7), Size = UDim2.fromOffset(14, 14), Parent = searchFrame})

	local searchBox = new("TextBox", {
		ClipsDescendants = true,
		PlaceholderColor3 = Theme.Muted,
		PlaceholderText = "Pesquisar remotes...",
		Position = UDim2.fromOffset(28, 0),
		Size = UDim2.new(1, -36, 1, 0),
		Text = "",
		TextXAlignment = AlignLeft,
		Parent = searchFrame,
	})
	searchBox.Focused:Connect(function()
		tween(searchStroke, 0.15, {Color = Theme.Muted})
	end)
	searchBox.FocusLost:Connect(function()
		tween(searchStroke, 0.15, {Color = Theme.Line})
	end)

	local remoteList = new("ScrollingFrame", {
		AutomaticCanvasSize = AutoY,
		Position = UDim2.fromOffset(8, 80),
		ScrollBarThickness = 2,
		Size = UDim2.new(1, -17, 1, -88),
		UIListLayout = {Padding = UDim.new(0, 3)},
		UIPadding = {PaddingRight = UDim.new(0, 4)},
		Parent = sidebar,
	})

	local detail = new("Frame", {Position = UDim2.fromOffset(sidebarWidth + 1, 0), Size = UDim2.new(1, -(sidebarWidth + 1), 1, 0), Parent = body})

	local header = new("Frame", {Size = UDim2.new(1, 0, 0, 46), Visible = false, Parent = detail})
	new("Frame", {BackgroundColor3 = Theme.Line, Position = UDim2.fromOffset(0, 45), Size = UDim2.new(1, 0, 0, 1), Parent = header})

	local headerIcon = new("ImageLabel", {Position = UDim2.fromOffset(12, 13), Size = UDim2.fromOffset(20, 20), Parent = header})

	local headerTitle = new("TextLabel", {
		Font = Enum.Font.GothamBold,
		Position = UDim2.fromOffset(40, 6),
		Size = UDim2.new(1, -200, 0, 18),
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = AlignLeft,
		Parent = header,
	})

	local headerPath = new("TextLabel", {
		Position = UDim2.fromOffset(40, 25),
		Size = UDim2.new(1, -200, 0, 14),
		TextColor3 = Theme.Muted,
		TextSize = 10,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = AlignLeft,
		Parent = header,
	})

	local actions = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		AutomaticSize = AutoX,
		Position = UDim2.new(1, -12, 0, 23),
		Size = UDim2.fromOffset(0, 24),
		UIListLayout = {
			FillDirection = Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8),
		},
		Parent = header,
	})

	local actionButtons = {}

	local function ignoreColor()
		return selected and Spy.Ignored[selected.Direction][selected.Remote] and Theme.Number or Theme.Muted
	end

	local function blockColor()
		return selected and Spy.Blocked[selected.Direction][selected.Remote] and Theme.Error or Theme.Muted
	end

	local function createAction(name, icon, order, getColor)
		local button = newIcon(icon, {LayoutOrder = order, Size = UDim2.fromOffset(px(20), px(20)), Parent = actions}, "ImageButton")
		hover(button, "ImageColor3", getColor or Theme.Muted, Theme.Text)
		actionButtons[name] = button
		return button
	end

	local cards = new("ScrollingFrame", {
		AutomaticCanvasSize = AutoY,
		Position = UDim2.fromOffset(0, 46),
		Size = UDim2.new(1, 0, 1, -80),
		Visible = false,
		UIListLayout = {Padding = UDim.new(0, 6)},
		UIPadding = {PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12)},
		Parent = detail,
	})

	local pager = new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 34),
		Visible = false,
		UIListLayout = {
			FillDirection = Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 10),
		},
		Parent = detail,
	})

	local function createPagerButton(icon, order)
		local button = newIcon(icon, {LayoutOrder = order, Size = UDim2.fromOffset(px(20), px(20)), Parent = pager}, "ImageButton")
		hover(button, "ImageColor3", Theme.Muted, Theme.Text)
		return button
	end

	local previousPage = createPagerButton("chevron-left", 1)
	local pageLabel = new("TextLabel", {LayoutOrder = 2, Size = UDim2.fromOffset(60, 22), Text = "1 / 1", TextColor3 = Theme.Muted, Parent = pager})
	local nextPage = createPagerButton("chevron-right", 3)

	local emptyLabel = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -40, 0, 50),
		TextColor3 = Theme.Muted,
		TextWrapped = true,
		Parent = detail,
	})

	local function styleEntry(entry)
		local active = selected == entry
		tween(entry.Button, 0.12, {BackgroundColor3 = active and Theme.Active or Theme.Sidebar})
		entry.Name.TextColor3 = active and Theme.Text or Theme.Muted
	end

	local function filterEntry(entry)
		local query = string.lower(searchBox.Text)
		entry.Button.Visible = entry.Direction == direction and (query == "" or string.find(string.lower(entry.Remote.Name), query, 1, true) ~= nil)
	end

	local function applyFilter()
		for _, entry in ipairs(entryList) do
			filterEntry(entry)
		end
	end

	local function getEntry(entryDirection, remote)
		local entry = entryMap[entryDirection][remote]
		if entry then
			return entry
		end
		entryCount += 1
		local button = new("TextButton", {
			BackgroundColor3 = Theme.Sidebar,
			LayoutOrder = entryCount,
			Size = UDim2.new(1, 0, 0, 30),
			Text = "",
			Visible = false,
			UICorner = {CornerRadius = UDim.new(0, 5)},
			Parent = remoteList,
		})
		new("ImageLabel", {Image = ClassImages[remote.ClassName], Position = UDim2.new(0, 8, 0.5, -8), Size = UDim2.fromOffset(16, 16), Parent = button})
		local name = new("TextLabel", {
			Font = Enum.Font.GothamMedium,
			Position = UDim2.fromOffset(30, 0),
			Size = UDim2.new(1, -78, 1, 0),
			Text = remote.Name,
			TextColor3 = Theme.Muted,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = AlignLeft,
			Parent = button,
		})
		local count = new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -8, 0, 0),
			Size = UDim2.fromOffset(36, 30),
			Text = "x0",
			TextColor3 = Theme.Muted,
			TextSize = 10,
			TextXAlignment = AlignRight,
			Parent = button,
		})
		entry = {
			Remote = remote,
			Direction = entryDirection,
			Total = 0,
			Calls = {},
			Stamps = {},
			Button = button,
			Name = name,
			Count = count,
		}
		entryMap[entryDirection][remote] = entry
		table.insert(entryList, entry)
		button.MouseEnter:Connect(function()
			if selected ~= entry then
				tween(button, 0.12, {BackgroundColor3 = Theme.Hover})
			end
		end)
		button.MouseLeave:Connect(function()
			styleEntry(entry)
		end)
		button.MouseButton1Click:Connect(function()
			selectEntry(entry)
		end)
		filterEntry(entry)
		return entry
	end

	local function visibleCalls(entry)
		if settings.ShowExecutor then
			return entry.Calls
		end
		local list = {}
		for _, call in ipairs(entry.Calls) do
			if not call.IsExecutor then
				table.insert(list, call)
			end
		end
		return list
	end

	local function createValueRow(parent, label, value, order)
		local kind = typeof(value)
		local row = new("Frame", {LayoutOrder = order, Size = UDim2.new(1, 0, 0, 16), Parent = parent})
		new("TextLabel", {
			Font = Enum.Font.RobotoMono,
			Size = UDim2.fromOffset(24, 16),
			Text = label,
			TextColor3 = Theme.Muted,
			TextSize = 10,
			TextXAlignment = AlignLeft,
			Parent = row,
		})
		new("TextLabel", {
			Font = Enum.Font.RobotoMono,
			Position = UDim2.fromOffset(28, 0),
			Size = UDim2.new(1, -100, 1, 0),
			Text = describe(value),
			TextColor3 = typeColor(kind),
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = AlignLeft,
			Parent = row,
		})
		new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.fromOffset(66, 16),
			Text = kind,
			TextColor3 = Theme.Muted,
			TextSize = 10,
			TextXAlignment = AlignRight,
			Parent = row,
		})
	end

	local function replayCall(call, entry)
		if Utils:IsSuspicious(entry.Remote.Name) then
			Report("Warning", "Repetir bloqueado", entry.Remote.Name .. " parece ser um remote de anti-cheat.")
			return
		end
		task.spawn(function()
			local ok, result = pcall(function()
				local method = Methods[entry.Direction][entry.Remote.ClassName]
				local arguments = call.Arguments
				if entry.Direction == "Incoming" then
					firesignal(entry.Remote[method], table.unpack(arguments, 1, arguments.n))
				else
					entry.Remote[method](entry.Remote, table.unpack(arguments, 1, arguments.n))
				end
			end)
			if not ok then
				Report("Error", "Falha ao repetir", tostring(result))
			end
		end)
	end

	local function toggleIgnore(entry)
		local map = Spy.Ignored[entry.Direction]
		map[entry.Remote] = not map[entry.Remote] or nil
		refreshActions()
	end

	local function toggleBlock(entry)
		local map = Spy.Blocked[entry.Direction]
		map[entry.Remote] = not map[entry.Remote] or nil
		if entry.Direction == "Incoming" then
			setConnections(entry.Remote, map[entry.Remote] == nil)
		end
		refreshActions()
	end

	local function clearEntry(entry)
		entry.Calls = {}
		entry.Total = 0
		entry.Count.Text = "x0"
		if selected == entry then
			page = 1
			render()
		end
	end

	local function cardOptions(call, entry)
		return {
			{Text = "Copiar Código de Chamada", Icon = "forward", Callback = function()
				copyText(buildCallCode(call, entry.Remote, entry.Direction), "Código de chamada copiado")
			end},
			{Text = "Copiar Código de Interceptação", Icon = "shield-alert", Callback = function()
				copyText(buildHookCode(entry.Remote, entry.Direction), "Código de interceptação copiado")
			end},
			{Text = "Copiar Caminho do Remote", Icon = "package-search", Callback = function()
				copyText(buildPath(entry.Remote), "Caminho do remote copiado")
			end},
			{Text = "Repetir", Icon = "play", Callback = function()
				replayCall(call, entry)
			end},
		}
	end

	local function originLabel(call)
		if call.IsExecutor then
			return executorName
		elseif call.Server then
			return "Servidor"
		elseif typeof(call.Origin) == "Instance" then
			return call.Origin.Name
		end
		return "Desconhecido"
	end

	local function createCard(call, entry, order)
		local blocked = call.Blocked == true
		local card = new("TextButton", {
			AutomaticSize = AutoY,
			BackgroundColor3 = blocked and Theme.Blocked or Theme.Card,
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 0),
			Text = "",
			UICorner = {},
			UIStroke = {Color = blocked and Theme.BlockedLine or Theme.Line, Transparency = blocked and 0.5 or 0},
			UIListLayout = {Padding = UDim.new(0, 4)},
			UIPadding = pad(8),
			Parent = cards,
		})
		local stroke = card:FindFirstChildOfClass("UIStroke")
		local nextOrder = sequencer()
		local arguments = call.Arguments
		local shown = math.min(arguments.n, 5)
		if arguments.n == 0 then
			new("TextLabel", {LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 16), Text = "Sem argumentos", TextColor3 = Theme.Muted, TextXAlignment = AlignLeft, Parent = card})
		end
		for index = 1, shown do
			createValueRow(card, tostring(index), arguments[index], nextOrder())
		end
		if arguments.n > shown then
			new("TextLabel", {LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 14), Text = "+ " .. (arguments.n - shown) .. " mais", TextColor3 = Theme.Muted, TextSize = 10, TextXAlignment = AlignLeft, Parent = card})
		end
		if call.Return then
			new("TextLabel", {Font = Enum.Font.GothamBold, LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 14), Text = "Retornos", TextColor3 = Theme.Muted, TextSize = 10, TextXAlignment = AlignLeft, Parent = card})
			for index = 1, math.min(call.Return.n, 3) do
				createValueRow(card, "r" .. index, call.Return[index], nextOrder())
			end
		end
		new("Frame", {BackgroundColor3 = Theme.Line, LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 1), Parent = card})
		local footer = new("Frame", {LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 18), Parent = card})
		local footerIcon = blocked and "ban" or call.IsExecutor and "terminal" or "gamepad-2"
		newIcon(footerIcon, {
			ImageColor3 = blocked and Theme.Error or Theme.Muted,
			Position = UDim2.fromOffset(0, 1),
			Size = UDim2.fromOffset(16, 16),
			Parent = footer,
		})
		new("TextLabel", {
			Font = Enum.Font.GothamMedium,
			Position = UDim2.fromOffset(22, 0),
			Size = UDim2.new(0.6, -22, 1, 0),
			Text = originLabel(call) .. (blocked and " (Bloqueado)" or ""),
			TextColor3 = blocked and Theme.Error or Theme.Muted,
			TextSize = 11,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = AlignLeft,
			Parent = footer,
		})
		new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.new(0.4, 0, 1, 0),
			Text = "Hora: " .. call.Time,
			TextColor3 = Theme.Muted,
			TextSize = 10,
			TextXAlignment = AlignRight,
			Parent = footer,
		})
		card.MouseEnter:Connect(function()
			tween(stroke, 0.15, {Color = Theme.Muted})
		end)
		card.MouseLeave:Connect(function()
			tween(stroke, 0.15, {Color = blocked and Theme.BlockedLine or Theme.Line})
		end)
		card.MouseButton1Click:Connect(function()
			Actions.OpenInfo(call, entry)
		end)
		card.MouseButton2Click:Connect(function()
			openMenu(card, cardOptions(call, entry), "mouse")
		end)
		card.TouchLongPress:Connect(function(_, state)
			if state == Enum.UserInputState.Begin then
				openMenu(card, cardOptions(call, entry), "below")
			end
		end)
	end

	function refreshActions()
		if not selected then
			return
		end
		local remote = selected.Remote
		local ignored = Spy.Ignored[selected.Direction][remote]
		local blocked = Spy.Blocked[selected.Direction][remote]
		setIcon(actionButtons.Ignore, ignored and "eye" or "eye-off")
		setIcon(actionButtons.Block, blocked and "lock" or "lock-open")
		tween(actionButtons.Block, 0.1, {ImageColor3 = blockColor()})
		tween(actionButtons.Ignore, 0.1, {ImageColor3 = ignoreColor()})
	end

	function render()
		renderPending = false
		if not screenGui.Parent then
			return
		end
		for _, child in ipairs(cards:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		if not selected then
			header.Visible = false
			cards.Visible = false
			pager.Visible = false
			emptyLabel.Visible = true
			local hasEntries = false
			for _, entry in ipairs(entryList) do
				if entry.Direction == direction then
					hasEntries = true
					break
				end
			end
			emptyLabel.Text = hasEntries and "Selecione um remote na lista." or "Nenhuma chamada registrada ainda."
			if direction == "Incoming" and not settings.CaptureIncoming then
				emptyLabel.Text = "Entrada desligada.\nAtive em Configurações para registrar."
			end
			if direction == "Outgoing" and not settings.CaptureOutgoing then
				emptyLabel.Text = "Saída desligada.\nAtive em Configurações para instalar o hook."
			elseif direction == "Outgoing" and not Spy.Hooked then
				emptyLabel.Text ..= "\nEste executor não tem suporte a hook: Saída indisponível."
			end
			return
		end
		emptyLabel.Visible = false
		header.Visible = true
		cards.Visible = true
		pager.Visible = true
		local remote = selected.Remote
		headerIcon.Image = ClassImages[remote.ClassName]
		headerTitle.Text = remote.Name
		headerPath.Text = remote.ClassName .. "  " .. remote:GetFullName()
		refreshActions()
		local calls = visibleCalls(selected)
		local totalPages = math.max(1, math.ceil(#calls / settings.PerPage))
		page = math.clamp(page, 1, totalPages)
		pageLabel.Text = page .. " / " .. totalPages
		local first = (page - 1) * settings.PerPage + 1
		for index = first, math.min(first + settings.PerPage - 1, #calls) do
			createCard(calls[index], selected, index - first + 1)
		end
		cards.CanvasPosition = Vector2.zero
	end

	local function scheduleRender()
		if renderPending then
			return
		end
		renderPending = true
		task.delay(settings.LightMode and 0.4 or 0.15, render)
	end

	function selectEntry(entry)
		selected = entry
		page = 1
		for _, item in ipairs(entryList) do
			styleEntry(item)
		end
		render()
	end

	local function trackSpam(entry)
		local now = tick()
		table.insert(entry.Stamps, now)
		while entry.Stamps[1] and now - entry.Stamps[1] > 1 do
			table.remove(entry.Stamps, 1)
		end
		local map = Spy.Ignored[entry.Direction]
		if #entry.Stamps > 15 and not map[entry.Remote] then
			map[entry.Remote] = true
			refreshActions()
		end
	end

	local function register(callDirection, remote, call)
		local entry = getEntry(callDirection, remote)
		entry.Total += 1
		table.insert(entry.Calls, 1, call)
		if #entry.Calls > (settings.LightMode and 80 or 200) then
			table.remove(entry.Calls)
		end
		entry.Count.Text = "x" .. entry.Total
		if settings.AutoIgnore then
			trackSpam(entry)
		end
		if selected == entry then
			scheduleRender()
		end
	end

	function setDirection(name)
		direction = name
		for key, data in pairs(segmentButtons) do
			local active = key == name
			data.Button.BackgroundTransparency = active and 0 or 1
			data.Label.TextColor3 = active and Theme.Text or Theme.Muted
			data.Icon.ImageColor3 = active and Theme.Text or Theme.Muted
		end
		if selected and selected.Direction ~= name then
			selected = nil
		end
		for _, entry in ipairs(entryList) do
			styleEntry(entry)
		end
		applyFilter()
		render()
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(applyFilter)

	previousPage.MouseButton1Click:Connect(function()
		if selected and page > 1 then
			page -= 1
			render()
		end
	end)

	nextPage.MouseButton1Click:Connect(function()
		if selected and page < math.ceil(#visibleCalls(selected) / settings.PerPage) then
			page += 1
			render()
		end
	end)

	createAction("Ignore", "eye-off", 1, ignoreColor).MouseButton1Click:Connect(function()
		if selected then
			toggleIgnore(selected)
		end
	end)

	createAction("Block", "lock-open", 2, blockColor).MouseButton1Click:Connect(function()
		if selected then
			toggleBlock(selected)
		end
	end)

	createAction("Clear", "trash", 3).MouseButton1Click:Connect(function()
		if selected then
			clearEntry(selected)
		end
	end)

	createAction("Path", "package-search", 4).MouseButton1Click:Connect(function()
		if selected then
			copyText(buildPath(selected.Remote), "Caminho do remote copiado")
		end
	end)

	Actions.Replay = replayCall
	Actions.Ignore = toggleIgnore
	Actions.Block = toggleBlock
	Actions.Clear = clearEntry
	Actions.RefreshList = function()
		page = 1
		render()
	end

	local queue = {}
	local first, last = 1, 0

	Spy.Handler = function(kind, remote, call)
		if last - first < 2000 then
			last += 1
			queue[last] = {kind, remote, call}
		end
	end

	Actions.Heartbeat = RunService.Heartbeat:Connect(Utils:Guard(function()
		local budget = settings.LightMode and 12 or 40
		while first <= last and budget > 0 do
			local item = queue[first]
			queue[first] = nil
			first += 1
			budget -= 1
			if item[1] == "Return" then
				if selected and selected.Remote == item[2] and selected.Direction == "Outgoing" then
					scheduleRender()
				end
			else
				register(item[1], item[2], item[3])
			end
		end
		if first > last then
			first, last = 1, 0
		end
	end))

	setDirection("Outgoing")
end

-- // Call Info
do
	local infoFrame, infoContent, infoTitle, infoIcon = createModal("Remote", "network", UDim2.new(0.94, 0, 0.94, 0))

	local infoTabRow = new("Frame", {
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.new(1, -16, 0, 30),
		UIListLayout = {FillDirection = Horizontal, Padding = UDim.new(0, 6)},
		Parent = infoContent,
	})

	local infoPages = {}
	local infoTabButtons = {}
	local activeInfo

	local function showInfoTab(name)
		activeInfo = name
		for tabName, infoPage in pairs(infoPages) do
			local active = tabName == name
			infoPage.Visible = active
			tween(infoTabButtons[tabName], 0.15, {BackgroundColor3 = active and Theme.Active or Theme.Panel})
		end
	end

	local function createInfoTab(name, icon, list)
		local button = createPill(infoTabRow, name, 0, 30, icon)
		local infoPage = new("ScrollingFrame", {
			AutomaticCanvasSize = list and AutoY or AutoXY,
			BackgroundColor3 = Theme.Sidebar,
			Position = UDim2.fromOffset(8, 46),
			ScrollingDirection = list and Enum.ScrollingDirection.Y or Enum.ScrollingDirection.XY,
			Size = UDim2.new(1, -16, 1, -98),
			Visible = false,
			UICorner = {},
			UIStroke = {},
			UIPadding = pad(8),
			Parent = infoContent,
		})
		if list then
			new("UIListLayout", {Padding = UDim.new(0, 6), Parent = infoPage})
		end
		infoPages[name] = infoPage
		infoTabButtons[name] = button
		button.MouseEnter:Connect(function()
			tween(button, 0.15, {BackgroundColor3 = activeInfo == name and Theme.Active or Theme.Hover})
		end)
		button.MouseLeave:Connect(function()
			tween(button, 0.15, {BackgroundColor3 = activeInfo == name and Theme.Active or Theme.Panel})
		end)
		button.MouseButton1Click:Connect(function()
			showInfoTab(name)
		end)
		return infoPage
	end

	local argumentsPage = createInfoTab("Argumentos", "ellipsis", true)
	local codePage = createInfoTab("Código", "code", false)
	local functionPage = createInfoTab("Info da Função", "parentheses", false)

	local codeLabel = new("TextLabel", {
		AutomaticSize = AutoXY,
		Font = Enum.Font.RobotoMono,
		Size = UDim2.new(0, 0, 0, 0),
		TextSize = 13,
		TextXAlignment = AlignLeft,
		TextYAlignment = AlignTop,
		Parent = codePage,
	})

	local functionLabel = new("TextLabel", {
		AutomaticSize = AutoXY,
		Font = Enum.Font.RobotoMono,
		RichText = true,
		Size = UDim2.new(0, 0, 0, 0),
		TextSize = 13,
		TextXAlignment = AlignLeft,
		TextYAlignment = AlignTop,
		Parent = functionPage,
	})

	local current = {}

	local function createValueBlock(label, value, order)
		local block = new("Frame", {
			AutomaticSize = AutoY,
			BackgroundColor3 = Theme.Card,
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 0),
			UICorner = {},
			UIListLayout = {Padding = UDim.new(0, 4)},
			UIPadding = pad(8),
			Parent = argumentsPage,
		})
		new("TextLabel", {LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 14), Text = label .. "  " .. typeof(value), TextColor3 = Theme.Muted, TextSize = 11, TextXAlignment = AlignLeft, Parent = block})
		local text = new("TextLabel", {
			AutomaticSize = AutoY,
			Font = Enum.Font.RobotoMono,
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 0),
			TextSize = 12,
			TextWrapped = true,
			TextXAlignment = AlignLeft,
			TextYAlignment = AlignTop,
			Parent = block,
		})
		local ok, serialized = pcall(serialize, value, 0)
		setCode(text, ok and serialized or describe(value))
	end

	Actions.OpenInfo = function(call, entry)
		current.Call = call
		current.Entry = entry
		infoTitle.Text = entry.Remote.Name .. (call.Blocked and " (Bloqueado)" or "")
		infoIcon.Image = ClassImages[entry.Remote.ClassName]
		infoIcon.ImageRectOffset = Vector2.zero
		infoIcon.ImageRectSize = Vector2.zero
		infoIcon.ImageColor3 = Theme.Text
		infoIcon.Visible = true
		for _, child in ipairs(argumentsPage:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		local order = 0
		if call.Arguments.n == 0 then
			order += 1
			new("TextLabel", {LayoutOrder = order, Size = UDim2.new(1, 0, 0, 20), Text = "Sem argumentos", TextColor3 = Theme.Muted, TextXAlignment = AlignLeft, Parent = argumentsPage})
		end
		for index = 1, call.Arguments.n do
			order += 1
			createValueBlock(tostring(index), call.Arguments[index], order)
		end
		if call.Return then
			for index = 1, call.Return.n do
				order += 1
				createValueBlock("Retorno " .. index, call.Return[index], order)
			end
		end
		setCode(codeLabel, buildCallCode(call, entry.Remote, entry.Direction))
		functionLabel.Text = buildFunctionInfo(call)
		showInfoTab("Argumentos")
		openModal(infoFrame)
	end

	local footer = new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 8, 1, -8),
		Size = UDim2.new(1, -16, 0, 32),
		UIListLayout = {FillDirection = Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6)},
		Parent = infoContent,
	})

	local function createFooterButton(icon, title, getOptions)
		local button = createPill(footer, title, 0, 32, icon)
		hover(button, "BackgroundColor3", Theme.Panel, Theme.Active)
		button.MouseButton1Click:Connect(function()
			openMenu(button, getOptions(), "above")
		end)
	end

	createFooterButton("code", "Código", function()
		return {
			{Text = "Código de Chamada", Icon = "forward", Callback = function()
				copyText(buildCallCode(current.Call, current.Entry.Remote, current.Entry.Direction), "Código de chamada copiado")
			end},
			{Text = "Código de Interceptação", Icon = "shield-alert", Callback = function()
				copyText(buildHookCode(current.Entry.Remote, current.Entry.Direction), "Código de interceptação copiado")
			end},
			{Text = "Info da Função", Icon = "parentheses", Callback = function()
				copyText(buildFunctionTable(current.Call), "Info da função copiada")
			end},
		}
	end)

	createFooterButton("scroll-text", "Origem", function()
		return {
			{Text = "Caminho do Remote", Icon = "package-search", Callback = function()
				copyText(buildPath(current.Entry.Remote), "Caminho do remote copiado")
			end},
			{Text = "Caminho do Script", Icon = "file-search", Condition = function()
				return typeof(current.Call.Origin) == "Instance"
			end, Callback = function()
				copyText(buildPath(current.Call.Origin), "Caminho do script copiado")
			end},
			{Text = "Script Decompilado", Icon = "file-text", Condition = function()
				return typeof(current.Call.Origin) == "Instance" and decompile ~= nil
			end, Callback = function()
				local ok, result = pcall(decompile, current.Call.Origin)
				if ok then
					copyText(result, "Script decompilado copiado")
				else
					Report("Error", "Falha ao decompilar", tostring(result))
				end
			end},
		}
	end)

	createFooterButton("network", "Evento", function()
		local entry = current.Entry
		return {
			{Text = "Repetir", Icon = "play", Callback = function()
				Actions.Replay(current.Call, entry)
			end},
			{Text = function()
				return Spy.Ignored[entry.Direction][entry.Remote] and "Parar de Ignorar" or "Ignorar"
			end, Icon = function()
				return Spy.Ignored[entry.Direction][entry.Remote] and "eye" or "eye-off"
			end, Callback = function()
				Actions.Ignore(entry)
			end},
			{Text = function()
				return Spy.Blocked[entry.Direction][entry.Remote] and "Desbloquear" or "Bloquear"
			end, Icon = function()
				return Spy.Blocked[entry.Direction][entry.Remote] and "lock" or "lock-open"
			end, Callback = function()
				Actions.Block(entry)
			end},
			{Text = "Limpar Registros", Icon = "trash", Callback = function()
				Actions.Clear(entry)
				closeModal()
			end},
		}
	end)
end

-- // Settings Menu
do
	local settingsFrame, settingsContent = createModal("Configurações", "settings", UDim2.new(0.86, 0, 0.9, 0))

	local settingsList = new("ScrollingFrame", {
		AutomaticCanvasSize = AutoY,
		Size = UDim2.fromScale(1, 1),
		UIListLayout = {Padding = UDim.new(0, 6)},
		UIPadding = pad(12),
		Parent = settingsContent,
	})

	local settingsOrder = sequencer()
	local group
	local groupRows = 0

	local function addSection(title)
		new("TextLabel", {
			Font = Enum.Font.GothamBold,
			LayoutOrder = settingsOrder(),
			Size = UDim2.new(1, 0, 0, 24),
			Text = title,
			TextColor3 = Theme.Muted,
			TextSize = 11,
			TextXAlignment = AlignLeft,
			TextYAlignment = Enum.TextYAlignment.Bottom,
			Parent = settingsList,
		})
		group = new("Frame", {
			AutomaticSize = AutoY,
			BackgroundColor3 = Theme.Card,
			LayoutOrder = settingsOrder(),
			Size = UDim2.new(1, 0, 0, 0),
			UICorner = {},
			UIStroke = {},
			UIListLayout = {},
			Parent = settingsList,
		})
		groupRows = 0
	end

	local function addRow(title, description, clickable)
		groupRows += 1
		local props = {LayoutOrder = groupRows, Size = UDim2.new(1, 0, 0, 48), Parent = group}
		if clickable then
			props.Text = ""
		end
		local row = new(clickable and "TextButton" or "Frame", props)
		if groupRows > 1 then
			new("Frame", {BackgroundColor3 = Theme.Line, Size = UDim2.new(1, 0, 0, 1), Parent = row})
		end
		new("TextLabel", {
			Font = Enum.Font.GothamMedium,
			Position = UDim2.fromOffset(14, 8),
			Size = UDim2.new(1, -190, 0, 16),
			Text = title,
			TextSize = 13,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = AlignLeft,
			Parent = row,
		})
		new("TextLabel", {
			Position = UDim2.fromOffset(14, 26),
			Size = UDim2.new(1, -190, 0, 14),
			Text = description,
			TextColor3 = Theme.Muted,
			TextSize = 10,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = AlignLeft,
			Parent = row,
		})
		return row
	end

	local function addToggle(title, description, key, onChange)
		local row = addRow(title, description, true)
		local track = new("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = Theme.Line,
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(36, 20),
			UICorner = {CornerRadius = UDim.new(1, 0)},
			Parent = row,
		})
		local knob = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Theme.Text,
			Position = UDim2.new(0, 10, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			UICorner = {CornerRadius = UDim.new(1, 0)},
			Parent = track,
		})
		local function refresh()
			local on = settings[key]
			tween(track, 0.15, {BackgroundColor3 = on and Color3.fromRGB(52, 199, 89) or Theme.Line})
			tween(knob, 0.15, {Position = on and UDim2.new(1, -10, 0.5, 0) or UDim2.new(0, 10, 0.5, 0)})
		end
		refresh()
		row.MouseButton1Click:Connect(function()
			settings[key] = not settings[key]
			saveSettings()
			refresh()
			if onChange then
				onChange()
			end
		end)
	end

	local function addChoice(title, description, key, values, labels, onChange)
		local row = addRow(title, description, false)
		local function textOf(value)
			return labels and labels[value] or tostring(value)
		end
		local button = new("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = Theme.Sidebar,
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(150, 26),
			Text = textOf(settings[key]),
			UICorner = {CornerRadius = UDim.new(0, 5)},
			UIStroke = {},
			Parent = row,
		})
		hover(button, "BackgroundColor3", Theme.Sidebar, Theme.Hover)
		button.MouseButton1Click:Connect(function()
			local options = {}
			for _, value in ipairs(values) do
				table.insert(options, {
					Text = textOf(value) .. (value == settings[key] and "  (atual)" or ""),
					Callback = function()
						settings[key] = value
						button.Text = textOf(value)
						saveSettings()
						if onChange then
							onChange()
						end
					end,
				})
			end
			openMenu(button, options, "below")
		end)
	end

	addSection("Diagnóstico")
	addToggle("Capturar Saída", "Desligado por padrão: o hook só é instalado ao ligar", "CaptureOutgoing", function()
		if settings.CaptureOutgoing then
			Spy.Install()
		end
		Actions.RefreshList()
	end)
	addToggle("Capturar Entrada", "Desligado por padrão: não conecta nos remotes do jogo", "CaptureIncoming", function()
		if settings.CaptureIncoming then
			startIncoming()
		else
			stopConnections()
		end
		Actions.RefreshList()
	end)

	addSection("Desempenho")
	addToggle("Modo Leve", "Sem animações e com menos itens, ideal para celular fraco", "LightMode", Actions.RefreshList)

	addSection("Geração de Código")
	addChoice("Busca de Instâncias", "Como os caminhos são escritos no código gerado", "PathMode", {"Index", "WaitForChild", "FindFirstChild"}, {Index = "Índice", WaitForChild = "WaitForChild", FindFirstChild = "FindFirstChild"})

	addSection("Exibição")
	addChoice("Chamadas por Página", "Quantidade de cartões mostrados por página", "PerPage", {2, 3, 4, 6, 8, 10}, {[2] = "2 chamadas", [3] = "3 chamadas", [4] = "4 chamadas", [6] = "6 chamadas", [8] = "8 chamadas", [10] = "10 chamadas"}, Actions.RefreshList)
	addToggle("Chamadas do Executor", "Mostra remotes disparados pelo seu executor", "ShowExecutor", Actions.RefreshList)

	addSection("Filtro")
	addToggle("Remotes Bloqueados", "Mantém no histórico as chamadas bloqueadas", "LogBlocked")
	addToggle("Ignorar Repetitivos", "Ignora remotes disparados mais de 15 vezes por segundo", "AutoIgnore")

	new("TextLabel", {
		LayoutOrder = settingsOrder(),
		Size = UDim2.new(1, 0, 0, 24),
		Text = "Salvo em " .. settingsPath,
		TextColor3 = Theme.Muted,
		TextSize = 10,
		TextXAlignment = AlignLeft,
		Parent = settingsList,
	})

	settingsButton.MouseButton1Click:Connect(function()
		openModal(settingsFrame)
	end)
end

-- // Changelog
do
	local changelogFrame, changelogContent = createModal("Histórico de Atualizações", "scroll-text", UDim2.new(0.92, 0, 0.92, 0))

	local changelogList = new("ScrollingFrame", {
		AutomaticCanvasSize = AutoY,
		Size = UDim2.fromScale(1, 1),
		UIListLayout = {Padding = UDim.new(0, 8)},
		UIPadding = pad(12),
		Parent = changelogContent,
	})

	local ChangeLog = {
		{
			Version = "v3.9",
			Current = true,
			Items = {
				"Código enxuto, sem partes sem uso, e cabeçalho em cada sistema.",
				"Notificações para o hook de saída, a entrada e falha ao carregar ícones.",
			},
		},
		{
			Version = "v3.8",
			Items = {
				"Hook de saída trocado do __namecall para oth.hook (off-thread) em FireServer e InvokeServer.",
				"Origem da chamada lida pela thread original do jogo.",
			},
		},
		{
			Version = "v3.7",
			Items = {
				"Anti-Kick e Proteger Remotes removidos.",
				"Entrada agora só escuta remotos dentro do ReplicatedStorage.",
				"Saída e Entrada sempre começam desligadas ao executar.",
			},
		},
	}

	for index, entry in ipairs(ChangeLog) do
		local card = new("Frame", {
			AutomaticSize = AutoY,
			BackgroundColor3 = Theme.Card,
			LayoutOrder = index,
			Size = UDim2.new(1, 0, 0, 0),
			UICorner = {},
			UIStroke = {},
			UIListLayout = {Padding = UDim.new(0, 6)},
			UIPadding = pad(10),
			Parent = changelogList,
		})
		local titleRow = new("Frame", {LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 20), Parent = card})
		new("TextLabel", {
			Font = Enum.Font.GothamBold,
			Size = UDim2.new(1, -52, 1, 0),
			Text = "Notas da Atualização - " .. entry.Version,
			TextSize = 13,
			TextXAlignment = AlignLeft,
			Parent = titleRow,
		})
		if entry.Current then
			new("TextLabel", {
				AnchorPoint = Vector2.new(1, 0),
				Font = Enum.Font.GothamBold,
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.fromOffset(50, 20),
				Text = "Atual",
				TextColor3 = Theme.Success,
				TextXAlignment = AlignRight,
				Parent = titleRow,
			})
		end
		local lines = {}
		for _, item in ipairs(entry.Items) do
			table.insert(lines, "- " .. item)
		end
		new("TextLabel", {
			AutomaticSize = AutoY,
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 0),
			Text = table.concat(lines, "\n"),
			TextColor3 = Theme.Muted,
			TextWrapped = true,
			TextXAlignment = AlignLeft,
			TextYAlignment = AlignTop,
			Parent = card,
		})
	end

	changelogButton.MouseButton1Click:Connect(function()
		openModal(changelogFrame)
	end)
end

-- // Window Controls
do
	local closeFrame, closeContent = createModal("Fechar Ecohub", "power", UDim2.fromOffset(300, 170))

	new("TextLabel", {
		Position = UDim2.fromOffset(16, 14),
		Size = UDim2.new(1, -32, 0, 40),
		Text = "O painel e o histórico de chamadas serão removidos.",
		TextColor3 = Theme.Muted,
		TextWrapped = true,
		TextXAlignment = AlignLeft,
		TextYAlignment = AlignTop,
		Parent = closeContent,
	})

	local function createDialogButton(text, position)
		local button = new("TextButton", {
			BackgroundColor3 = Theme.Panel,
			Font = Enum.Font.GothamBold,
			Position = position,
			Size = UDim2.new(0.5, -22, 0, 34),
			Text = text,
			TextSize = 13,
			UICorner = {},
			UIStroke = {Thickness = 1.5},
			Parent = closeContent,
		})
		hover(button, "BackgroundColor3", Theme.Panel, Theme.Active)
		return button
	end

	local acceptButton = createDialogButton("Aceitar", UDim2.new(0, 16, 1, -52))
	local cancelButton = createDialogButton("Cancelar", UDim2.new(0.5, 6, 1, -52))
	cancelButton.MouseButton1Click:Connect(closeModal)

	local restoreButton = new("TextButton", {
		BackgroundColor3 = Theme.Panel,
		ClipsDescendants = true,
		Position = UDim2.new(0, 20, 0.5, -24),
		Size = UDim2.fromOffset(px(48), px(48)),
		Text = "",
		Visible = false,
		ZIndex = 20,
		UICorner = {CornerRadius = UDim.new(0, 10)},
		UIStroke = {Thickness = 1.5},
		Parent = screenGui,
	})

	new("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Image = "rbxassetid://77526194033506",
		ImageTransparency = 0.3,
		Position = UDim2.fromScale(0.5, 0.5),
		ScaleType = Enum.ScaleType.Crop,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 21,
		UICorner = {CornerRadius = UDim.new(0, 10)},
		Parent = restoreButton,
	})

	local function bindDrag(handle, target, onClick, threshold)
		handle.InputBegan:Connect(function(input)
			local kind = input.UserInputType
			if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then
				return
			end
			local origin = input.Position
			local start = target.Position
			local moved = false
			local moveConnection
			local endConnection
			moveConnection = UserInputService.InputChanged:Connect(function(change)
				local changeKind = change.UserInputType
				if changeKind ~= Enum.UserInputType.MouseMovement and changeKind ~= Enum.UserInputType.Touch then
					return
				end
				if kind == Enum.UserInputType.Touch and change ~= input then
					return
				end
				local delta = change.Position - origin
				if delta.Magnitude > (threshold or 4) then
					moved = true
				end
				if moved then
					target.Position = UDim2.new(start.X.Scale, start.X.Offset + delta.X, start.Y.Scale, start.Y.Offset + delta.Y)
				end
			end)
			endConnection = UserInputService.InputEnded:Connect(function(finish)
				local finishKind = finish.UserInputType
				if finishKind ~= Enum.UserInputType.MouseButton1 and finishKind ~= Enum.UserInputType.Touch then
					return
				end
				if kind == Enum.UserInputType.Touch and finish ~= input then
					return
				end
				moveConnection:Disconnect()
				endConnection:Disconnect()
				if not moved and onClick then
					onClick()
				end
			end)
		end)
	end

	local maximized = false
	local minimizing = false

	local function restoreWindow()
		restoreButton.Visible = false
		mainFrame.Visible = true
		tween(mainFrame, 0.3, {Size = windowSize(maximized)})
	end

	bindDrag(topBar, mainFrame)
	bindDrag(restoreButton, restoreButton, restoreWindow, 7)

	minButton.MouseButton1Click:Connect(function()
		if minimizing then
			return
		end
		closeModal()
		if settings.LightMode then
			mainFrame.Visible = false
			restoreButton.Visible = true
			return
		end
		minimizing = true
		local animation = TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.fromOffset(0, 0)})
		animation.Completed:Once(function()
			mainFrame.Visible = false
			restoreButton.Visible = true
			minimizing = false
		end)
		animation:Play()
	end)

	maxButton.MouseButton1Click:Connect(function()
		maximized = not maximized
		maxButton.Image = maximized and Controls.Restore or Controls.Max
		mainFrame.Position = UDim2.fromScale(0.5, 0.5)
		tween(mainFrame, 0.3, {Size = windowSize(maximized)})
	end)

	closeButton.MouseButton1Click:Connect(function()
		openModal(closeFrame)
	end)

	local function unload()
		for remote in pairs(Spy.Blocked.Incoming) do
			setConnections(remote, true)
		end
		stopConnections()
		if Actions.Heartbeat then
			Actions.Heartbeat:Disconnect()
			Actions.Heartbeat = nil
		end
		Spy.Active = false
		Spy.Handler = nil
		screenGui:Destroy()
	end

	env.EcohubUnload = unload
	acceptButton.MouseButton1Click:Connect(unload)
end

-- // Startup
Spy.Active = true