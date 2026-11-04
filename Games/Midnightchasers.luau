-- // Games
local Librarys = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/pvpgalinhamonzonrebasexk/gazrenkinras/refs/heads/main/Library/Library.luau"
    ))()
local Bypass = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/pvpgalinhamonzonrebasexk/gazrenkinras/refs/heads/main/Templates/Bypass.luau"
    ))()

local Windows = Librarys:CreateWindow({
    Title = "Eco Hub",
    SubTitle = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
    Size = UDim2.fromOffset(580, 350),
    MinimizeKey = Enum.KeyCode.RightShift,
})

-- // API
Windows:LoadFeatures({
    "MidnightChasers/Farm",
    "MidnightChasers/Event",
    "MidnightChasers/Misc"
})