--[[
    WindUI Viewport Container Test
    Tests Viewport inside: Section, Group, and plain Tab
    One tab per container
]]

local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/etoneaetobylkaktus-lang/WindUI/main/dist/main.lua"))()
end)

if not ok or not WindUI then
    return warn("[ Viewport Test ] Failed to load WindUI: " .. tostring(WindUI))
end

local Window = WindUI:CreateWindow({
    Title = "WindUI Viewport Containers",
    Author = "section / group / tab",
    Folder = "WindUIViewportContainers",
    ToggleKey = Enum.KeyCode.RightShift,
})

-- */  Demo Models  /* --
local function MakeCube(color, size)
    local Part = Instance.new("Part")
    Part.Size = Vector3.new(size or 3, size or 3, size or 3)
    Part.Color = color or Color3.fromHex("#7775F2")
    Part.Material = Enum.Material.Neon
    Part.Anchored = true
    return Part
end

local function MakeSphere(color)
    local Part = Instance.new("Part")
    Part.Shape = Enum.PartType.Ball
    Part.Size = Vector3.new(4, 4, 4)
    Part.Color = color or Color3.fromHex("#30FF6A")
    Part.Material = Enum.Material.Neon
    Part.Anchored = true
    return Part
end

local function MakeStack()
    local Model = Instance.new("Model")
    local colors = { "#ECA201", "#257AF7", "#EF4F1D" }
    for i, hex in ipairs(colors) do
        local Part = Instance.new("Part")
        Part.Size = Vector3.new(3 - i * 0.5, 1, 3 - i * 0.5)
        Part.Color = Color3.fromHex(hex)
        Part.Material = Enum.Material.SmoothPlastic
        Part.Anchored = true
        Part.CFrame = CFrame.new(0, -1.5 + i, 0)
        Part.Parent = Model
    end
    return Model
end

-- */  Tab 1: Viewport inside Section  /* --
local SectionTab = Window:Tab({
    Title = "In Section",
    Icon = "square-stack",
    Desc = "Viewport nested inside a Section box",
})

local Section = SectionTab:Section({
    Title = "Section Container",
    Icon = "box",
    Box = true,
    BoxBorder = true,
    Opened = true,
})

local SectionViewport = Section:Viewport({
    Object = MakeCube(Color3.fromHex("#7775F2")),
    Interactive = true,
    AutoRotate = true,
    Height = 200,
})

Section:Toggle({
    Title = "Auto Rotate",
    Value = true,
    Callback = function(v)
        SectionViewport:SetAutoRotate(v)
    end,
})

-- viewport BELOW the section, still in same tab (section closed state test)
local ClosedSection = SectionTab:Section({
    Title = "Collapsed Section",
    Icon = "package",
    Box = true,
    Opened = false,
})

local CollapsedViewport = ClosedSection:Viewport({
    Object = MakeSphere(Color3.fromHex("#ECA201")),
    Interactive = true,
    Height = 200,
})

-- */  Tab 2: Viewport inside Group  /* --
local GroupTab = Window:Tab({
    Title = "In Group",
    Icon = "layers",
    Desc = "Two viewports side by side in an HStack group",
})

GroupTab:Paragraph({
    Title = "Group Test",
    Desc = "Viewports inside HStack > VStack groups",
})

local HStack = GroupTab:HStack()
local VStackLeft = HStack:VStack()
local VStackRight = HStack:VStack()

local GroupViewportLeft = VStackLeft:Viewport({
    Object = MakeCube(Color3.fromHex("#257AF7"), 2.5),
    Interactive = true,
    AutoRotate = true,
    Height = 160,
})

local GroupViewportRight = VStackRight:Viewport({
    Object = MakeSphere(Color3.fromHex("#30FF6A")),
    Interactive = true,
    Height = 160,
})

VStackLeft:Button({
    Title = "Spin Left",
    Justify = "Center",
    Callback = function()
        GroupViewportLeft:SetAutoRotate(not GroupViewportLeft.AutoRotate)
    end,
})

VStackRight:Button({
    Title = "Spin Right",
    Justify = "Center",
    Callback = function()
        GroupViewportRight:SetAutoRotate(not GroupViewportRight.AutoRotate)
    end,
})

-- viewport in a plain (borderless) group, full width
local PlainGroup = GroupTab:Group()

local GroupViewportWide = PlainGroup:Viewport({
    Object = MakeStack(),
    Interactive = true,
    ShowGrid = true,
    Height = 180,
})

PlainGroup:Button({
    Title = "Swap Wide Object",
    Icon = "refresh-ccw",
    Justify = "Center",
    Callback = function()
        GroupViewportWide:SetObject(MakeCube(Color3.fromHex("#EF4F1D")))
    end,
})

-- */  Tab 3: Viewport directly in Tab  /* --
local PlainTab = Window:Tab({
    Title = "In Tab",
    Icon = "monitor",
    Desc = "Viewport directly inside a Tab, no wrappers",
})

local PlainViewport = PlainTab:Viewport({
    Object = MakeStack(),
    Interactive = true,
    AutoRotate = true,
    ShowGrid = true,
    Lighting = {
        Brightness = 2,
        Color = Color3.fromRGB(255, 255, 255),
        Range = 30,
    },
    Height = 260,
})

PlainTab:Paragraph({
    Title = "Controls",
    Desc = "Drag — orbit  |  Scroll / Pinch — zoom  |  Shift+Drag / Right Click — pan",
})

local HStackPresets = PlainTab:HStack()
local PresetLeft = HStackPresets:VStack()
local PresetRight = HStackPresets:VStack()

PresetLeft:Button({
    Title = "Isometric",
    Justify = "Center",
    Callback = function()
        PlainViewport:SetCameraPreset("Isometric")
    end,
})

PresetLeft:Button({
    Title = "Top",
    Justify = "Center",
    Callback = function()
        PlainViewport:SetCameraPreset("Top")
    end,
})

PresetRight:Button({
    Title = "Front",
    Justify = "Center",
    Callback = function()
        PlainViewport:SetCameraPreset("Front")
    end,
})

PresetRight:Button({
    Title = "Reset",
    Icon = "rotate-ccw",
    Justify = "Center",
    Callback = function()
        PlainViewport:ResetCamera()
    end,
})

PlainTab:Slider({
    Title = "Height",
    Min = 120,
    Max = 400,
    Value = 260,
    Callback = function(v)
        PlainViewport:SetHeight(v)
    end,
})

Window:SelectTab(1)
