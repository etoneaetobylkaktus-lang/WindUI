--[[
    WindUI Example
    Loads the library from the GitHub repository
]]

local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/sker4ik/WindUI/main/dist/main.lua"))()
end)

if not ok or not WindUI then
    return warn("[ Example ] Failed to load WindUI: " .. tostring(WindUI))
end

local Window = WindUI:CreateWindow({
    Title = "WindUI Local Example",
    Author = "local build",
    Folder = "WindUIExample",
})

Window:Tag({
    Title = "local",
    Icon = "package",
})

-- */  Main Tab  /* --
local MainTab = Window:Tab({
    Title = "Main",
    Icon = "house",
})

MainTab:Paragraph({
    Title = "Local Build",
    Desc = "This window was loaded from the GitHub repository (dist/main.lua)",
    Icon = "package",
})

MainTab:Toggle({
    Title = "Example Toggle",
    Value = false,
    Callback = function(v)
        print("[ Example ] Toggle:", v)
    end,
})

MainTab:Slider({
    Title = "Example Slider",
    Min = 0,
    Max = 100,
    Value = 50,
    Callback = function(v)
        print("[ Example ] Slider:", v)
    end,
})

MainTab:Input({
    Title = "Example Input",
    Placeholder = "type something...",
    Callback = function(text)
        print("[ Example ] Input:", text)
    end,
})

-- */  Viewport Tab  /* --
local ViewportTab = Window:Tab({
    Title = "Viewport",
    Icon = "box",
})

local Part = Instance.new("Part")
Part.Size = Vector3.new(4, 4, 4)
Part.Color = Color3.fromHex("#7775F2")
Part.Material = Enum.Material.Neon
Part.Anchored = true

local Viewport = ViewportTab:Viewport({
    Object = Part,
    Interactive = true,
    AutoRotate = true,
    ShowGrid = true,
    Lighting = {
        Brightness = 2,
        Color = Color3.fromRGB(255, 255, 255),
        Range = 30,
    },
    Height = 250,
})

ViewportTab:Button({
    Title = "Camera: Isometric",
    Icon = "camera",
    Callback = function()
        Viewport:SetCameraPreset("Isometric")
    end,
})

ViewportTab:Button({
    Title = "Camera: Top",
    Icon = "camera",
    Callback = function()
        Viewport:SetCameraPreset("Top")
    end,
})

ViewportTab:Button({
    Title = "Reset Camera",
    Icon = "rotate-ccw",
    Callback = function()
        Viewport:ResetCamera()
    end,
})

-- */  Chart Tab  /* --
local ChartTab = Window:Tab({
    Title = "Chart",
    Icon = "line-chart",
})

local Chart = ChartTab:Chart({
    Title = "Example Chart",
    Type = "Line",
    Data = { 5, 12, 8, 20, 15, 30, 25 },
    Height = 180,
    Colors = { Color3.fromHex("#30FF6A") },
})

ChartTab:Button({
    Title = "Switch to Bar",
    Icon = "bar-chart-3",
    Callback = function()
        Chart:SetType("Bar")
    end,
})

ChartTab:Button({
    Title = "Randomize Data",
    Icon = "dices",
    Callback = function()
        local data = {}
        for _ = 1, 7 do
            table.insert(data, math.random(1, 40))
        end
        Chart:SetData(data)
    end,
})

-- */  Info Tab  /* --
local InfoTab = Window:Tab({
    Title = "Info",
    Icon = "badge-info",
})

InfoTab:Paragraph({
    Title = "WindUI",
    Desc = "Version: " .. WindUI.Version,
    Buttons = {
        {
            Title = "GitHub",
            Icon = "github",
            Callback = function()
                print("[ Example ] GitHub")
            end,
        },
    },
})

Window:SelectTab(1)
