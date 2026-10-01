--[[
    WindUI Viewport Demo
    Showcases all Viewport features:
    auto-rotate, interactive orbit/zoom/pan, grid floor,
    dynamic lighting, camera presets, FOV control
]]

local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/etoneaetobylkaktus-lang/WindUI/main/dist/main.lua"))()
end)

if not ok or not WindUI then
    return warn("[ Viewport Demo ] Failed to load WindUI: " .. tostring(WindUI))
end

local Window = WindUI:CreateWindow({
    Title = "WindUI Viewport Demo",
    Author = "viewport showcase",
    Folder = "WindUIViewportDemo",
    ToggleKey = Enum.KeyCode.RightShift,
})

-- */  Demo Object  /* --
local function MakeDemoModel()
    local Model = Instance.new("Model")

    local Core = Instance.new("Part")
    Core.Size = Vector3.new(3, 3, 3)
    Core.Color = Color3.fromHex("#7775F2")
    Core.Material = Enum.Material.Neon
    Core.Anchored = true
    Core.Parent = Model

    local Ring = Instance.new("Part")
    Ring.Size = Vector3.new(5, 0.5, 5)
    Ring.Color = Color3.fromHex("#30FF6A")
    Ring.Material = Enum.Material.Metal
    Ring.Transparency = 0.3
    Ring.Anchored = true
    Ring.CFrame = CFrame.new(0, 2.5, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45))
    Ring.Parent = Model

    local Base = Instance.new("Part")
    Base.Size = Vector3.new(6, 0.3, 6)
    Base.Color = Color3.fromHex("#1c1c1c")
    Base.Material = Enum.Material.SmoothPlastic
    Base.Anchored = true
    Base.CFrame = CFrame.new(0, -2.5, 0)
    Base.Parent = Model

    Model.PrimaryPart = Core
    return Model
end

local DemoModel = MakeDemoModel()

-- */  Viewport Tab  /* --
local ViewportTab = Window:Tab({
    Title = "Viewport",
    Icon = "box",
    Desc = "3D object inside a UI tab — drag to rotate, scroll to zoom",
})

local Viewport = ViewportTab:Viewport({
    Object = DemoModel,
    Interactive = true,
    AutoRotate = true,
    ShowGrid = true,
    Lighting = {
        Brightness = 2,
        Color = Color3.fromRGB(255, 255, 255),
        Range = 30,
    },
    Height = 280,
})

-- */  Camera Controls  /* --
local CameraSection = ViewportTab:Section({
    Title = "Camera Presets",
    Icon = "camera",
    Box = true,
    BoxBorder = true,
    Opened = true,
})

local HStack = CameraSection:HStack()
local VStackLeft = HStack:VStack()
local VStackRight = HStack:VStack()

local function PresetButton(parent, title, preset)
    parent:Button({
        Title = title,
        Justify = "Center",
        Callback = function()
            Viewport:SetCameraPreset(preset)
        end,
    })
end

PresetButton(VStackLeft, "Front", "Front")
PresetButton(VStackLeft, "Left", "Left")
PresetButton(VStackLeft, "Top", "Top")
PresetButton(VStackRight, "Back", "Back")
PresetButton(VStackRight, "Right", "Right")
PresetButton(VStackRight, "Isometric", "Isometric")

ViewportTab:Button({
    Title = "Reset Camera",
    Icon = "rotate-ccw",
    Justify = "Center",
    Callback = function()
        Viewport:ResetCamera()
    end,
})

-- */  Behaviour Controls  /* --
local SettingsSection = ViewportTab:Section({
    Title = "Settings",
    Icon = "settings",
    Box = true,
    BoxBorder = true,
    Opened = true,
})

SettingsSection:Toggle({
    Title = "Auto Rotate",
    Desc = "Object spins on its own, pauses while you interact",
    Value = true,
    Callback = function(v)
        Viewport:SetAutoRotate(v)
    end,
})

SettingsSection:Toggle({
    Title = "Grid Floor",
    Desc = "Reference grid under the object",
    Value = true,
    Callback = function(v)
        Viewport:SetGrid(v)
    end,
})

SettingsSection:Slider({
    Title = "Field of View",
    Min = 30,
    Max = 110,
    Value = 70,
    Callback = function(v)
        Viewport:SetFOV(v)
    end,
})

SettingsSection:Slider({
    Title = "Light Brightness",
    Min = 0,
    Max = 5,
    Value = 2,
    Callback = function(v)
        Viewport:SetLighting({ Brightness = v })
    end,
})

SettingsSection:Colorpicker({
    Title = "Light Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        Viewport:SetLighting({ Color = color })
    end,
})

SettingsSection:Button({
    Title = "Replace Object",
    Icon = "refresh-ccw",
    Callback = function()
        Viewport:SetObject(MakeDemoModel())
    end,
})

ViewportTab:Paragraph({
    Title = "Controls",
    Desc = "Drag — orbit  |  Scroll / Pinch — zoom  |  Shift+Drag / Right Click — pan  |  Two-finger drag (mobile) — pan",
})

Window:SelectTab(1)
