--[[
    WindUI Visuals Demo — CS2 style ESP preview
    2D ESP box rendered over a live Viewport with full color customization
]]

local RunService = game:GetService("RunService")

local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/etoneaetobylkaktus-lang/WindUI/main/dist/main.lua"))()
end)

if not ok or not WindUI then
    return warn("[ Visuals ] Failed to load WindUI: " .. tostring(WindUI))
end

local Window = WindUI:CreateWindow({
    Title = "WindUI Visuals — CS2 Style",
    Author = "esp preview",
    Folder = "WindUIVisuals",
    ToggleKey = Enum.KeyCode.RightShift,
})

-- */  Target — your own character  /* --
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function CloneCharacter()
    local char = LocalPlayer.Character
    if not char or not char.Parent then
        char = LocalPlayer.CharacterAppearanceLoaded:Wait()
    end

    local Clone = Instance.new("Model")
    Clone.Name = LocalPlayer.Name

    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("BasePart") then
            local copy = obj:Clone()
            copy.Anchored = true
            copy.CanCollide = false
            copy.Parent = Clone
        end
    end

    -- fallback if nothing cloned (rare)
    if not Clone:FindFirstChildOfClass("BasePart") then
        local P = Instance.new("Part")
        P.Size = Vector3.new(2, 5, 1)
        P.Anchored = true
        P.Color = Color3.fromHex("#7775F2")
        P.Parent = Clone
    end

    return Clone
end

-- */  Visuals Tab  /* --
local VisualsTab = Window:Tab({
    Title = "Visuals",
    Icon = "eye",
    Desc = "CS2 style ESP — live preview over viewport",
})

local PreviewSection = VisualsTab:Section({
    Title = "Preview",
    Icon = "monitor",
    Box = true,
    BoxBorder = true,
    Opened = true,
})

local Viewport = PreviewSection:Viewport({
    Object = CloneCharacter(),
    Interactive = true,
    RotateOnly = true,
    AutoRotate = false,
    Lighting = {
        Brightness = 1.5,
        Color = Color3.fromRGB(255, 255, 255),
        Range = 40,
    },
    Height = 220,
})

-- */  ESP Overlay (2D, drawn over the viewport)  /* --
local New = WindUI.Creator.New

local Canvas = Viewport.Main:FindFirstChild("CanvasGroup", true)
local ViewportFrame = Canvas and Canvas:FindFirstChildOfClass("ViewportFrame")

local Overlay = New("Frame", {
    Name = "ESPOverlay",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    ZIndex = 50,
    ClipsDescendants = true,
    Parent = Canvas,
})

local Settings = {
    Enabled = true,
    Style = "Corners", -- Corners | Full
    BoxColor = Color3.fromHex("#EF4444"),
    FillColor = Color3.fromHex("#EF4444"),
    SnapColor = Color3.fromHex("#FFFFFF"),
    Thickness = 2,
    HealthBar = true,
    Name = true,
    Distance = true,
    Fill = false,
    Snapline = false,
    WorldESP = true,
}

-- AlwaysOnTop billboard boxes for every other player.
local WorldBoxes = {}

local function RemoveWorldBox(player)
    if WorldBoxes[player] then
        WorldBoxes[player]:Destroy()
        WorldBoxes[player] = nil
    end
end

local function CreateWorldBox(player)
    RemoveWorldBox(player)
    if player == LocalPlayer then return end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "WindUI_ESP_" .. player.Name
    billboard.Adornee = root
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.Size = UDim2.fromOffset(100, 150)
    billboard.StudsOffset = Vector3.new(0, 1.5, 0)
    billboard.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local box = Instance.new("Frame")
    box.Name = "Box"
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Size = UDim2.fromScale(1, 1)
    box.Parent = billboard

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Thickness = Settings.Thickness
    stroke.Color = Settings.BoxColor
    stroke.Parent = box

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = Settings.BoxColor
    label.TextStrokeTransparency = 0.25
    label.TextSize = 11
    label.Text = player.Name
    label.Size = UDim2.new(1, 0, 0, 18)
    label.Position = UDim2.new(0, 0, 0, -18)
    label.Parent = billboard

    WorldBoxes[player] = billboard
end

local function RefreshWorldBoxes()
    for _, player in ipairs(Players:GetPlayers()) do
        CreateWorldBox(player)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function()
            task.wait(0.25)
            CreateWorldBox(player)
        end)
        CreateWorldBox(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.25)
        CreateWorldBox(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveWorldBox(player)
end)

RunService.RenderStepped:Connect(function()
    for player, billboard in pairs(WorldBoxes) do
        local stroke = billboard:FindFirstChild("Box", true)
            and billboard.Box:FindFirstChildOfClass("UIStroke")
        local visible = Settings.Enabled and Settings.WorldESP and player.Character ~= nil
        billboard.Enabled = visible
        if stroke then
            stroke.Color = Settings.BoxColor
            stroke.Thickness = Settings.Thickness
        end
        local label = billboard:FindFirstChildOfClass("TextLabel")
        if label then label.TextColor3 = Settings.BoxColor end
    end
end)

-- full box (one frame + stroke)
local FullBox = New("Frame", {
    BackgroundTransparency = 1,
    ZIndex = 51,
    Visible = false,
    Parent = Overlay,
}, {
    New("UIStroke", { Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
})

-- corner box: 8 segments (4 corners x 2 axes), each with black backing
local Segments = {}
local CornerNames = { "TL_H", "TL_V", "TR_H", "TR_V", "BL_H", "BL_V", "BR_H", "BR_V" }
local Anchors = {
    TL_H = Vector2.new(0, 0), TL_V = Vector2.new(0, 0),
    TR_H = Vector2.new(1, 0), TR_V = Vector2.new(1, 0),
    BL_H = Vector2.new(0, 1), BL_V = Vector2.new(0, 1),
    BR_H = Vector2.new(1, 1), BR_V = Vector2.new(1, 1),
}

for _, name in ipairs(CornerNames) do
    Segments[name] = {
        Back = New("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            ZIndex = 51,
            AnchorPoint = Anchors[name],
            Visible = false,
            Parent = Overlay,
        }),
        Front = New("Frame", {
            BorderSizePixel = 0,
            ZIndex = 52,
            AnchorPoint = Anchors[name],
            Visible = false,
            Parent = Overlay,
        }),
    }
end

local Fill = New("Frame", {
    BorderSizePixel = 0,
    ZIndex = 50,
    BackgroundTransparency = 0.65,
    Visible = false,
    Parent = Overlay,
})

local HealthBack = New("Frame", {
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 0.3,
    BorderSizePixel = 0,
    ZIndex = 51,
    AnchorPoint = Vector2.new(1, 0),
    Visible = false,
    Parent = Overlay,
}, {
    New("UICorner", { CornerRadius = UDim.new(0, 2) }),
})

local HealthFill = New("Frame", {
    BorderSizePixel = 0,
    ZIndex = 52,
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 0, 1, 0),
    Visible = false,
    Parent = HealthBack,
}, {
    New("UICorner", { CornerRadius = UDim.new(0, 2) }),
})

local NameLabel = New("TextLabel", {
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = Color3.new(1, 1, 1),
    TextStrokeTransparency = 0.4,
    Text = LocalPlayer.Name,
    ZIndex = 52,
    AnchorPoint = Vector2.new(0.5, 1),
    Visible = false,
    Parent = Overlay,
})

local DistLabel = New("TextLabel", {
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    TextColor3 = Color3.fromRGB(200, 200, 200),
    TextStrokeTransparency = 0.4,
    ZIndex = 52,
    AnchorPoint = Vector2.new(0.5, 0),
    Visible = false,
    Parent = Overlay,
})

local Snapline = New("Frame", {
    BackgroundColor3 = Color3.new(1, 1, 1),
    BorderSizePixel = 0,
    ZIndex = 50,
    AnchorPoint = Vector2.new(0, 0.5),
    Size = UDim2.new(0, 0, 0, 1),
    Visible = false,
    Parent = Overlay,
})

-- */  Projection + Draw  /* --
local Corners = {}

local function UpdateCorners()
    local bboxCF, bboxSize = Viewport.Object:GetBoundingBox()
    table.clear(Corners)
    for i = 0, 7 do
        local off = Vector3.new(
            (i % 2 == 0) and -0.5 or 0.5,
            (math.floor(i / 2) % 2 == 0) and -0.5 or 0.5,
            (math.floor(i / 4) % 2 == 0) and -0.5 or 0.5
        )
        Corners[i + 1] = (bboxCF * CFrame.new(off * bboxSize)).Position
    end
end

UpdateCorners()

local function SetAll(visible)
    FullBox.Visible = visible and Settings.Style == "Full"
    local cornerVis = visible and Settings.Style == "Corners"
    for _, seg in pairs(Segments) do
        seg.Back.Visible = cornerVis
        seg.Front.Visible = cornerVis
    end
    Fill.Visible = visible and Settings.Fill
    HealthBack.Visible = visible and Settings.HealthBar
    HealthFill.Visible = HealthBack.Visible
    NameLabel.Visible = visible and Settings.Name
    DistLabel.Visible = visible and Settings.Distance
    Snapline.Visible = visible and Settings.Snapline
end

local Clock = 0

local Conn = RunService.RenderStepped:Connect(function(dt)
    Clock += dt

    if not ViewportFrame or not ViewportFrame.Parent then
        Conn:Disconnect()
        return
    end

    if not Settings.Enabled then
        SetAll(false)
        return
    end

    local Size = ViewportFrame.AbsoluteSize
    if Size.X < 10 or Size.Y < 10 then
        SetAll(false)
        return
    end

    local CamCF = Viewport.Camera.CFrame
    local Scale = (Size.Y / 2) / math.tan(math.rad(Viewport.Camera.FieldOfView / 2))

    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge

    for _, worldPos in ipairs(Corners) do
        local rel = CamCF:PointToObjectSpace(worldPos)
        if rel.Z >= -0.05 then
            SetAll(false)
            return
        end
        local px = (rel.X / -rel.Z) * Scale
        local py = (rel.Y / -rel.Z) * Scale
        local sx = Size.X / 2 + px
        local sy = Size.Y / 2 - py
        minX = math.min(minX, sx)
        minY = math.min(minY, sy)
        maxX = math.max(maxX, sx)
        maxY = math.max(maxY, sy)
    end

    local x, y = minX, minY
    local x2, y2 = maxX, maxY
    local w, h = x2 - x, y2 - y
    local t = Settings.Thickness

    SetAll(true)

    -- full box
    FullBox.Position = UDim2.fromOffset(x, y)
    FullBox.Size = UDim2.fromOffset(w, h)
    FullBox.UIStroke.Color = Settings.BoxColor
    FullBox.UIStroke.Thickness = t

    -- corner segments
    local lenH = math.clamp(w * 0.25, 8, 34)
    local lenV = math.clamp(h * 0.25, 8, 34)

    local function Seg(name, px, py, isH)
        local seg = Segments[name]
        local len = isH and lenH or lenV
        local thick = isH and t or t
        seg.Back.Position = UDim2.fromOffset(px, py)
        seg.Back.Size = isH and UDim2.fromOffset(len + 2, t + 2) or UDim2.fromOffset(t + 2, len + 2)
        seg.Front.Position = UDim2.fromOffset(px, py)
        seg.Front.Size = isH and UDim2.fromOffset(len, t) or UDim2.fromOffset(t, len)
        seg.Front.BackgroundColor3 = Settings.BoxColor
    end

    Seg("TL_H", x, y, true)      Seg("TL_V", x, y, false)
    Seg("TR_H", x2, y, true)     Seg("TR_V", x2, y, false)
    Seg("BL_H", x, y2, true)     Seg("BL_V", x, y2, false)
    Seg("BR_H", x2, y2, true)    Seg("BR_V", x2, y2, false)

    -- fill
    Fill.Position = UDim2.fromOffset(x, y)
    Fill.Size = UDim2.fromOffset(w, h)
    Fill.BackgroundColor3 = Settings.FillColor

    -- health bar (pulsing to show gradient)
    local pct = 0.5 + 0.5 * math.sin(Clock * 1.4)
    HealthBack.Position = UDim2.fromOffset(x - 7, y)
    HealthBack.Size = UDim2.fromOffset(4, h)
    HealthFill.Size = UDim2.new(1, 0, pct, 0)
    HealthFill.BackgroundColor3 = Color3.fromRGB(255, math.floor(255 * pct), 0)

    -- name / distance
    NameLabel.Position = UDim2.fromOffset((x + x2) / 2, y - 4)
    DistLabel.Position = UDim2.fromOffset((x + x2) / 2, y2 + 4)

    local camDist = (CamCF.Position - Viewport.Object:GetPivot().Position).Magnitude
    DistLabel.Text = string.format("%dm", math.floor(camDist / 3))

    -- snapline: screen bottom center -> box bottom center
    local dx = (x + x2) / 2 - Size.X / 2
    local dy = y2 - Size.Y
    local len = math.sqrt(dx * dx + dy * dy)
    Snapline.Position = UDim2.fromOffset(Size.X / 2, Size.Y)
    Snapline.Size = UDim2.fromOffset(len, 1)
    Snapline.Rotation = math.deg(math.atan2(dy, dx))
    Snapline.BackgroundColor3 = Settings.SnapColor
end)

-- */  ESP Settings  /* --
local BoxSection = VisualsTab:Section({
    Title = "Box ESP",
    Icon = "square-dashed",
    Box = true,
    BoxBorder = true,
    Opened = true,
})

BoxSection:Toggle({
    Title = "Enabled",
    Desc = "Master toggle for the preview ESP",
    Value = true,
    Callback = function(v)
        Settings.Enabled = v
    end,
})

BoxSection:Dropdown({
    Title = "Box Style",
    Options = { "Corners", "Full" },
    Default = "Corners",
    Callback = function(option)
        Settings.Style = option
    end,
})

BoxSection:Slider({
    Title = "Thickness",
    Min = 1,
    Max = 4,
    Value = 2,
    Callback = function(v)
        Settings.Thickness = math.floor(v)
    end,
})

BoxSection:Toggle({
    Title = "Fill",
    Value = false,
    Callback = function(v)
        Settings.Fill = v
    end,
})

BoxSection:Colorpicker({
    Title = "Box Color",
    Default = Settings.BoxColor,
    Callback = function(color)
        Settings.BoxColor = color
    end,
})

BoxSection:Colorpicker({
    Title = "Fill Color",
    Default = Settings.FillColor,
    Callback = function(color)
        Settings.FillColor = color
    end,
})

local InfoSection = VisualsTab:Section({
    Title = "Extra",
    Icon = "tag",
    Box = true,
    BoxBorder = true,
    Opened = true,
})

InfoSection:Toggle({
    Title = "Health Bar",
    Value = true,
    Callback = function(v)
        Settings.HealthBar = v
    end,
})

InfoSection:Toggle({
    Title = "Name",
    Value = true,
    Callback = function(v)
        Settings.Name = v
    end,
})

InfoSection:Toggle({
    Title = "Distance",
    Value = true,
    Callback = function(v)
        Settings.Distance = v
    end,
})

InfoSection:Toggle({
    Title = "Snapline",
    Value = false,
    Callback = function(v)
        Settings.Snapline = v
    end,
})

InfoSection:Toggle({
    Title = "World ESP",
    Desc = "Always-on-top boxes for every other player",
    Value = true,
    Callback = function(v)
        Settings.WorldESP = v
    end,
})

InfoSection:Colorpicker({
    Title = "Snapline Color",
    Default = Settings.SnapColor,
    Callback = function(color)
        Settings.SnapColor = color
    end,
})

InfoSection:Button({
    Title = "Refresh Character",
    Icon = "refresh-ccw",
    Desc = "Re-clone your character into the preview",
    Callback = function()
        Viewport:SetObject(CloneCharacter())
        UpdateCorners()
        Viewport:Focus()
    end,
})

VisualsTab:Paragraph({
    Title = "How it works",
    Desc = "Your character is cloned into the viewport and a billboard box is projected around it every frame — orbit the camera and the ESP tracks the model, just like in game",
})

Window:SelectTab(1)
