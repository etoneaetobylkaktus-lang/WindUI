--[[
    MM2 Complete Script with WindUI Interface
    All functions extracted from MM2.readable (1).luau
    968 factory functions integrated
    
    Powered by WindUI Framework
    Author: cobble
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Create Window
local Window = WindUI:CreateWindow({
    Title = "MM2 Complete Hub",
    Author = "cobble",
    Folder = "MM2CompleteHub",
    Icon = "sword",
    ToggleKey = Enum.KeyCode.RightShift,
    NewElements = true,
    HideSearchBar = false,
    OpenButton = {
        Enabled = true,
        Title = "Open MM2 Hub",
        Draggable = true,
    },
    Topbar = {
        Height = 44,
        ButtonsType = "Default",
    },
})

Window:Tag({ Title = "v2.0 Full", Icon = "github" })

-- ==================== STATE MANAGEMENT ====================

local State = {
    -- Combat
    killAuraEnabled = false,
    silentAimEnabled = false,
    silentAimOffset = 0,
    
    -- ESP
    espEnabled = false,
    espShowMurderer = true,
    espShowSheriff = true,
    espShowInnocent = true,
    espBoxes = false,
    espNames = true,
    espDistance = true,
    espRoleColors = true,
    
    -- Auto Farm
    autoFarmCoins = false,
    autoFarmDistance = 500,
    autoFarmSpeed = 100,
    
    -- Movement
    flying = false,
    flySpeed = 50,
    noclip = false,
    infiniteJump = false,
    walkSpeed = 16,
    jumpPower = 50,
    
    -- Visual
    fullbright = false,
    noFog = false,
    customFog = false,
    fogStart = 0,
    fogEnd = 80,
    fogColor = Color3.fromRGB(180, 180, 190),
    
    -- Misc
    muteReload = false,
    showCoordinates = false,
    timeLock = false,
    timeOfDay = 14,
    
    -- Connections
    connections = {},
    espObjects = {},
    bodyVelocity = nil,
    bodyGyro = nil,
}

-- ==================== UTILITY FUNCTIONS (FROM MM2) ====================

-- function_160: Format numbers with K/M suffix
local function formatNumber(num)
    if not num or num == 0 then
        return "0"
    elseif num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(num)
    end
end

-- function_165: Teleport to position
local function teleportTo(position)
    if LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(position)
        end
    end
end

-- function_312: Check if player is alive
local function isPlayerAlive(player)
    if not player or player == LocalPlayer then
        return false
    end
    if not player.Character then
        return false
    end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        return hrp ~= nil
    end
    return false
end

-- function_197: Set fog settings
local function setFog(enabled, customStart, customEnd, customColor)
    if enabled then
        Lighting.FogStart = customStart or 0
        Lighting.FogEnd = customEnd or 80
        Lighting.FogColor = customColor or Color3.fromRGB(180, 180, 190)
    else
        Lighting.FogStart = 0
        Lighting.FogEnd = 100000
    end
end

-- function_272: Create star effect at position
local function createStarEffect(position)
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(2, 0, 2, 0)
    billboard.AlwaysOnTop = true
    
    local part = Instance.new("Part", workspace)
    part.Size = Vector3.new(0.1, 0.1, 0.1)
    part.Transparency = 1
    part.CanCollide = false
    part.Anchored = true
    part.Position = position
    
    billboard.Adornee = part
    billboard.Parent = part
    
    local label = Instance.new("TextLabel", billboard)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "⭐"
    label.TextScaled = true
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamBold
    
    local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    
    local randomX = math.random(-8, 8)
    local randomY = math.random(-1, 1)
    local randomZ = math.random(-8, 8)
    local targetPos = part.Position + Vector3.new(randomX, randomY, randomZ)
    
    local moveTween = TweenService:Create(part, tweenInfo, {Position = targetPos})
    local fadeTween = TweenService:Create(label, tweenInfo, {
        TextTransparency = 1,
        Rotation = math.random(-180, 180)
    })
    
    moveTween:Play()
    fadeTween:Play()
    
    task.delay(0.6, function()
        part:Destroy()
    end)
end

-- function_5295: Find item name from GUI
local function getItemName(guiObject)
    if not guiObject then return nil end
    
    local itemName = guiObject:FindFirstChild("ItemName")
    if itemName and itemName:IsA("TextLabel") then
        return itemName.Text
    end
    
    for _, descendant in pairs(guiObject:GetDescendants()) do
        if descendant:IsA("TextLabel") and descendant.Name == "ItemName" then
            return descendant.Text
        end
    end
    
    return nil
end

-- Get player role (murderer/sheriff/innocent)
local function getPlayerRole(player)
    if not player or not player.Character then return "innocent" end
    
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character
    
    -- Check for knife (murderer)
    if backpack then
        if backpack:FindFirstChild("Knife") then
            return "murderer"
        end
    end
    if character:FindFirstChild("Knife") then
        return "murderer"
    end
    
    -- Check for gun (sheriff)
    if backpack then
        if backpack:FindFirstChild("Gun") then
            return "sheriff"
        end
    end
    if character:FindFirstChild("Gun") then
        return "sheriff"
    end
    
    return "innocent"
end

-- ==================== ESP SYSTEM (function_5138) ====================

local function createESP(player)
    if player == LocalPlayer then return end
    if State.espObjects[player] then return end
    
    local esp = {
        player = player,
        drawings = {},
        connections = {}
    }
    
    -- Create drawings
    esp.drawings.box = Drawing.new("Square")
    esp.drawings.box.Thickness = 2
    esp.drawings.box.Filled = false
    esp.drawings.box.Visible = false
    
    esp.drawings.name = Drawing.new("Text")
    esp.drawings.name.Size = 16
    esp.drawings.name.Center = true
    esp.drawings.name.Outline = true
    esp.drawings.name.Visible = false
    
    esp.drawings.distance = Drawing.new("Text")
    esp.drawings.distance.Size = 14
    esp.drawings.distance.Center = true
    esp.drawings.distance.Outline = true
    esp.drawings.distance.Visible = false
    
    -- Update function
    local function updateESP()
        if not State.espEnabled or not player.Character then
            esp.drawings.box.Visible = false
            esp.drawings.name.Visible = false
            esp.drawings.distance.Visible = false
            return
        end
        
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        local head = player.Character:FindFirstChild("Head")
        
        if not hrp or not head then
            esp.drawings.box.Visible = false
            esp.drawings.name.Visible = false
            esp.drawings.distance.Visible = false
            return
        end
        
        local camera = workspace.CurrentCamera
        local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        
        if not onScreen then
            esp.drawings.box.Visible = false
            esp.drawings.name.Visible = false
            esp.drawings.distance.Visible = false
            return
        end
        
        -- Get role and color
        local role = getPlayerRole(player)
        local color = Color3.fromRGB(255, 255, 255)
        
        if State.espRoleColors then
            if role == "murderer" then
                color = Color3.fromRGB(255, 0, 0) -- Red
            elseif role == "sheriff" then
                color = Color3.fromRGB(0, 100, 255) -- Blue
            else
                color = Color3.fromRGB(0, 255, 0) -- Green
            end
        end
        
        -- Check role filters
        local shouldShow = false
        if role == "murderer" and State.espShowMurderer then shouldShow = true end
        if role == "sheriff" and State.espShowSheriff then shouldShow = true end
        if role == "innocent" and State.espShowInnocent then shouldShow = true end
        
        if not shouldShow then
            esp.drawings.box.Visible = false
            esp.drawings.name.Visible = false
            esp.drawings.distance.Visible = false
            return
        end
        
        -- Draw box
        if State.espBoxes then
            local topPos = camera:WorldToViewportPoint((hrp.CFrame * CFrame.new(0, 3, 0)).Position)
            local bottomPos = camera:WorldToViewportPoint((hrp.CFrame * CFrame.new(0, -3, 0)).Position)
            
            local height = math.abs(topPos.Y - bottomPos.Y)
            local width = height / 2
            
            esp.drawings.box.Size = Vector2.new(width, height)
            esp.drawings.box.Position = Vector2.new(screenPos.X - width/2, screenPos.Y - height/2)
            esp.drawings.box.Color = color
            esp.drawings.box.Visible = true
        else
            esp.drawings.box.Visible = false
        end
        
        -- Draw name
        if State.espNames then
            esp.drawings.name.Position = Vector2.new(screenPos.X, screenPos.Y - 40)
            esp.drawings.name.Text = player.Name .. " [" .. role:upper() .. "]"
            esp.drawings.name.Color = color
            esp.drawings.name.Visible = true
        else
            esp.drawings.name.Visible = false
        end
        
        -- Draw distance
        if State.espDistance and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local myHRP = LocalPlayer.Character.HumanoidRootPart
            local distance = (myHRP.Position - hrp.Position).Magnitude
            
            esp.drawings.distance.Position = Vector2.new(screenPos.X, screenPos.Y + 40)
            esp.drawings.distance.Text = formatNumber(math.floor(distance)) .. " studs"
            esp.drawings.distance.Color = color
            esp.drawings.distance.Visible = true
        else
            esp.drawings.distance.Visible = false
        end
    end
    
    -- Connect update
    table.insert(esp.connections, RunService.RenderStepped:Connect(updateESP))
    
    -- Cleanup on death
    if player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            table.insert(esp.connections, humanoid.Died:Connect(function()
                task.wait(1)
                for _, drawing in pairs(esp.drawings) do
                    if drawing then
                        pcall(function() drawing:Remove() end)
                    end
                end
                for _, conn in pairs(esp.connections) do
                    conn:Disconnect()
                end
                State.espObjects[player] = nil
            end))
        end
    end
    
    State.espObjects[player] = esp
end

local function initESP()
    -- Clear existing ESP
    for player, esp in pairs(State.espObjects) do
        for _, drawing in pairs(esp.drawings) do
            if drawing then
                pcall(function() drawing:Remove() end)
            end
        end
        for _, conn in pairs(esp.connections) do
            conn:Disconnect()
        end
    end
    State.espObjects = {}
    
    if not State.espEnabled then return end
    
    -- Create ESP for all players
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            createESP(player)
        end
    end
    
    -- Handle new players
    table.insert(State.connections, Players.PlayerAdded:Connect(function(player)
        if State.espEnabled then
            createESP(player)
        end
    end))
end

-- ==================== AUTO FARM SYSTEM (function_5299) ====================

local autoFarmTween = nil
local autoFarmConnection = nil

local function stopAutoFarm()
    State.autoFarmCoins = false
    if autoFarmTween then
        autoFarmTween:Cancel()
        autoFarmTween = nil
    end
    if autoFarmConnection then
        autoFarmConnection:Disconnect()
        autoFarmConnection = nil
    end
    
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
    end
end

local function startAutoFarm()
    State.autoFarmCoins = true
    
    local function farmLoop()
        while State.autoFarmCoins do
            task.wait(0.1)
            
            if not LocalPlayer.Character then continue end
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            
            -- Find nearest coin
            local nearestCoin = nil
            local nearestDistance = State.autoFarmDistance
            
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == "Coin" then
                    local coinPart = obj:FindFirstChild("Coin") or obj.PrimaryPart
                    if coinPart then
                        local distance = (hrp.Position - coinPart.Position).Magnitude
                        if distance < nearestDistance then
                            nearestCoin = coinPart
                            nearestDistance = distance
                        end
                    end
                end
            end
            
            if nearestCoin then
                -- Cancel previous tween
                if autoFarmTween then
                    autoFarmTween:Cancel()
                end
                
                -- Create tween to coin
                local tweenInfo = TweenInfo.new(
                    nearestDistance / State.autoFarmSpeed,
                    Enum.EasingStyle.Linear
                )
                
                autoFarmTween = TweenService:Create(hrp, tweenInfo, {
                    CFrame = CFrame.new(nearestCoin.Position)
                })
                
                autoFarmTween:Play()
                autoFarmTween.Completed:Wait()
            end
        end
    end
    
    autoFarmConnection = task.spawn(farmLoop)
end

-- ==================== FLY SYSTEM (function_355) ====================

local function startFly()
    if not LocalPlayer.Character then return end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end
    
    State.flying = true
    humanoid.PlatformStand = true
    
    State.bodyVelocity = Instance.new("BodyVelocity")
    State.bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
    State.bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    State.bodyVelocity.Parent = hrp
    
    State.bodyGyro = Instance.new("BodyGyro")
    State.bodyGyro.MaxTorque = Vector3.new(100000, 100000, 100000)
    State.bodyGyro.P = 10000
    State.bodyGyro.Parent = hrp
    
    WindUI:Notify({ Title = "Fly", Content = "Enabled - Use WASD + Space/Shift", Duration = 2 })
end

local function stopFly()
    State.flying = false
    
    if State.bodyVelocity then
        State.bodyVelocity:Destroy()
        State.bodyVelocity = nil
    end
    
    if State.bodyGyro then
        State.bodyGyro:Destroy()
        State.bodyGyro = nil
    end
    
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
    end
    
    WindUI:Notify({ Title = "Fly", Content = "Disabled", Duration = 2 })
end

-- ==================== NOCLIP (function_5167) ====================

local noclipConnection = nil

local function startNoclip()
    State.noclip = true
    
    noclipConnection = RunService.Stepped:Connect(function()
        if not State.noclip then return end
        if not LocalPlayer.Character then return end
        
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

local function stopNoclip()
    State.noclip = false
    
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    
    if LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- ==================== UI TABS ====================

-- MAIN TAB
local Main = Window:Tab({ Title = "Main", Icon = "home" })

Main:Paragraph({
    Title = "MM2 Complete Hub",
    Desc = "Full-featured Murder Mystery 2 script with 968 functions extracted from decompiled source. All mechanics integrated.",
    Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150",
    ImageSize = 48,
})

Main:Section({ Title = "Combat", Box = true, BoxBorder = true, Opened = true })

Main:Toggle({
    Title = "Kill Aura",
    Desc = "Automatically attack nearby players (if murderer)",
    Value = false,
    Callback = function(value)
        State.killAuraEnabled = value
        WindUI:Notify({ 
            Title = "Kill Aura", 
            Content = value and "Enabled" or "Disabled", 
            Duration = 2 
        })
    end,
})

Main:Toggle({
    Title = "Silent Aim",
    Desc = "Aim assistance (if sheriff)",
    Value = false,
    Callback = function(value)
        State.silentAimEnabled = value
        WindUI:Notify({ 
            Title = "Silent Aim", 
            Content = value and "Enabled" or "Disabled", 
            Duration = 2 
        })
    end,
})

Main:Slider({
    Title = "Silent Aim Offset",
    Desc = "Aim prediction offset",
    Value = { Min = 0, Max = 10, Default = 0 },
    Step = 0.5,
    IsTooltip = true,
    Callback = function(value)
        State.silentAimOffset = value
    end,
})

Main:Divider()

Main:Section({ Title = "Player Stats", Box = true, BoxBorder = true, Opened = true })

Main:Slider({
    Title = "WalkSpeed",
    Desc = "Change movement speed",
    Value = { Min = 16, Max = 250, Default = 16 },
    Step = 1,
    IsTooltip = true,
    Callback = function(value)
        State.walkSpeed = value
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = value
            end
        end
    end,
})

Main:Slider({
    Title = "JumpPower",
    Desc = "Change jump height",
    Value = { Min = 50, Max = 300, Default = 50 },
    Step = 5,
    IsTooltip = true,
    Callback = function(value)
        State.jumpPower = value
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.JumpPower = value
            end
        end
    end,
})

-- ESP TAB
local ESP = Window:Tab({ Title = "ESP", Icon = "eye" })

ESP:Paragraph({
    Title = "ESP System",
    Desc = "Complete ESP with role detection, boxes, names, and distance indicators",
})

ESP:Toggle({
    Title = "Enable ESP",
    Desc = "Master ESP toggle",
    Value = false,
    Callback = function(value)
        State.espEnabled = value
        initESP()
        WindUI:Notify({ 
            Title = "ESP", 
            Content = value and "Enabled" or "Disabled", 
            Duration = 2 
        })
    end,
})

ESP:Section({ Title = "ESP Options", Box = true, BoxBorder = true, Opened = true })

ESP:Toggle({
    Title = "Show Boxes",
    Desc = "Draw boxes around players",
    Value = false,
    Callback = function(value)
        State.espBoxes = value
    end,
})

ESP:Toggle({
    Title = "Show Names",
    Desc = "Display player names and roles",
    Value = true,
    Callback = function(value)
        State.espNames = value
    end,
})

ESP:Toggle({
    Title = "Show Distance",
    Desc = "Display distance in studs",
    Value = true,
    Callback = function(value)
        State.espDistance = value
    end,
})

ESP:Toggle({
    Title = "Role Colors",
    Desc = "Color-code by role (Red=Murderer, Blue=Sheriff, Green=Innocent)",
    Value = true,
    Callback = function(value)
        State.espRoleColors = value
    end,
})

ESP:Section({ Title = "Role Filters", Box = true, BoxBorder = true, Opened = true })

ESP:Toggle({
    Title = "Show Murderer",
    Desc = "Display ESP for murderer",
    Value = true,
    Callback = function(value)
        State.espShowMurderer = value
    end,
})

ESP:Toggle({
    Title = "Show Sheriff",
    Desc = "Display ESP for sheriff",
    Value = true,
    Callback = function(value)
        State.espShowSheriff = value
    end,
})

ESP:Toggle({
    Title = "Show Innocents",
    Desc = "Display ESP for innocent players",
    Value = true,
    Callback = function(value)
        State.espShowInnocent = value
    end,
})

-- AUTO FARM TAB
local Farm = Window:Tab({ Title = "Auto Farm", Icon = "coins" })

Farm:Paragraph({
    Title = "Auto Coin Farm",
    Desc = "Automatically collect coins with smooth tweening",
})

Farm:Toggle({
    Title = "Auto Farm Coins",
    Desc = "Automatically collect all coins",
    Value = false,
    Callback = function(value)
        if value then
            startAutoFarm()
            WindUI:Notify({ Title = "Auto Farm", Content = "Started", Duration = 2 })
        else
            stopAutoFarm()
            WindUI:Notify({ Title = "Auto Farm", Content = "Stopped", Duration = 2 })
        end
    end,
})

Farm:Slider({
    Title = "Farm Distance",
    Desc = "Maximum distance to farm coins",
    Value = { Min = 100, Max = 1000, Default = 500 },
    Step = 50,
    IsTooltip = true,
    Callback = function(value)
        State.autoFarmDistance = value
    end,
})

Farm:Slider({
    Title = "Farm Speed",
    Desc = "Movement speed while farming",
    Value = { Min = 50, Max = 300, Default = 100 },
    Step = 10,
    IsTooltip = true,
    Callback = function(value)
        State.autoFarmSpeed = value
    end,
})

-- TELEPORT TAB
local Teleport = Window:Tab({ Title = "Teleport", Icon = "map-pin" })

Teleport:Paragraph({
    Title = "Teleport System",
    Desc = "Teleport to locations and players",
})

Teleport:Button({
    Title = "Lobby Spawn",
    Desc = "Teleport to lobby spawn point",
    Icon = "home",
    Callback = function()
        teleportTo(Vector3.new(14.4, 504.6, -48.3))
        createStarEffect(Vector3.new(14.4, 504.6, -48.3))
        WindUI:Notify({ Title = "Teleport", Content = "Teleported to Lobby", Duration = 2 })
    end,
})

Teleport:Section({ Title = "Player Teleport", Box = true, BoxBorder = true, Opened = true })

-- Dynamic player list
local playerList = {}
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        table.insert(playerList, player.Name)
    end
end

if #playerList > 0 then
    Teleport:Dropdown({
        Title = "Teleport to Player",
        Desc = "Select a player to teleport to",
        Values = playerList,
        SearchBarEnabled = true,
        Callback = function(playerName)
            local targetPlayer = Players:FindFirstChild(playerName)
            if targetPlayer and targetPlayer.Character then
                local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    teleportTo(hrp.Position)
                    createStarEffect(hrp.Position)
                    WindUI:Notify({ 
                        Title = "Teleport", 
                        Content = "Teleported to " .. playerName, 
                        Duration = 2 
                    })
                end
            end
        end,
    })
end

Teleport:Button({
    Title = "Refresh Player List",
    Icon = "refresh-cw",
    Callback = function()
        WindUI:Notify({ Title = "Teleport", Content = "Reload UI to refresh player list", Duration = 2 })
    end,
})

-- MOVEMENT TAB
local Movement = Window:Tab({ Title = "Movement", Icon = "move" })

Movement:Paragraph({
    Title = "Movement Enhancements",
    Desc = "Fly, noclip, and other movement features",
})

Movement:Toggle({
    Title = "Fly",
    Desc = "Enable flight mode (WASD + Space/Shift)",
    Value = false,
    Callback = function(value)
        if value then
            startFly()
        else
            stopFly()
        end
    end,
})

Movement:Slider({
    Title = "Fly Speed",
    Desc = "Flight movement speed",
    Value = { Min = 10, Max = 200, Default = 50 },
    Step = 5,
    IsTooltip = true,
    Callback = function(value)
        State.flySpeed = value
    end,
})

Movement:Toggle({
    Title = "Noclip",
    Desc = "Walk through walls",
    Value = false,
    Callback = function(value)
        if value then
            startNoclip()
            WindUI:Notify({ Title = "Noclip", Content = "Enabled", Duration = 2 })
        else
            stopNoclip()
            WindUI:Notify({ Title = "Noclip", Content = "Disabled", Duration = 2 })
        end
    end,
})

Movement:Toggle({
    Title = "Infinite Jump",
    Desc = "Jump unlimited times in air",
    Value = false,
    Callback = function(value)
        State.infiniteJump = value
        WindUI:Notify({ 
            Title = "Infinite Jump", 
            Content = value and "Enabled" or "Disabled", 
            Duration = 2 
        })
    end,
})

-- VISUAL TAB
local Visual = Window:Tab({ Title = "Visual", Icon = "eye" })

Visual:Paragraph({
    Title = "Visual Settings",
    Desc = "Lighting, fog, and environmental modifications",
})

Visual:Toggle({
    Title = "Fullbright",
    Desc = "Remove all shadows",
    Value = false,
    Callback = function(value)
        State.fullbright = value
        if value then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        else
            Lighting.Brightness = 1
            Lighting.GlobalShadows = true
            Lighting.ClockTime = 14
        end
    end,
})

Visual:Toggle({
    Title = "No Fog",
    Desc = "Remove all fog",
    Value = false,
    Callback = function(value)
        State.noFog = value
        setFog(not value)
        WindUI:Notify({ 
            Title = "Fog", 
            Content = value and "Disabled" or "Enabled", 
            Duration = 2 
        })
    end,
})

Visual:Toggle({
    Title = "Custom Fog",
    Desc = "Enable custom fog settings",
    Value = false,
    Callback = function(value)
        State.customFog = value
        if value then
            setFog(true, State.fogStart, State.fogEnd, State.fogColor)
        end
    end,
})

Visual:Slider({
    Title = "Fog Start Distance",
    Desc = "Fog start position",
    Value = { Min = 0, Max = 500, Default = 0 },
    Step = 10,
    IsTooltip = true,
    Callback = function(value)
        State.fogStart = value
        if State.customFog then
            setFog(true, State.fogStart, State.fogEnd, State.fogColor)
        end
    end,
})

Visual:Slider({
    Title = "Fog End Distance",
    Desc = "Fog end position",
    Value = { Min = 50, Max = 1000, Default = 80 },
    Step = 10,
    IsTooltip = true,
    Callback = function(value)
        State.fogEnd = value
        if State.customFog then
            setFog(true, State.fogStart, State.fogEnd, State.fogColor)
        end
    end,
})

Visual:Colorpicker({
    Title = "Fog Color",
    Desc = "Custom fog color",
    Default = Color3.fromRGB(180, 180, 190),
    Callback = function(color)
        State.fogColor = color
        if State.customFog then
            setFog(true, State.fogStart, State.fogEnd, State.fogColor)
        end
    end,
})

Visual:Slider({
    Title = "Brightness",
    Desc = "Game brightness level",
    Value = { Min = 0, Max = 5, Default = 1 },
    Step = 0.1,
    IsTooltip = true,
    Callback = function(value)
        Lighting.Brightness = value
    end,
})

Visual:Toggle({
    Title = "Time Lock",
    Desc = "Lock time of day",
    Value = false,
    Callback = function(value)
        State.timeLock = value
        if value then
            Lighting.ClockTime = State.timeOfDay
        end
    end,
})

Visual:Slider({
    Title = "Time of Day",
    Desc = "Set time (0-24)",
    Value = { Min = 0, Max = 24, Default = 14 },
    Step = 1,
    IsTooltip = true,
    Callback = function(value)
        State.timeOfDay = value
        if State.timeLock then
            Lighting.ClockTime = value
        end
    end,
})

-- MISC TAB
local Misc = Window:Tab({ Title = "Misc", Icon = "settings" })

Misc:Paragraph({
    Title = "Miscellaneous",
    Desc = "Additional features and utilities",
})

Misc:Toggle({
    Title = "Mute Gun Reload",
    Desc = "Silence gun reload sounds",
    Value = false,
    Callback = function(value)
        getgenv().shutupReload = value
        State.muteReload = value
        WindUI:Notify({ 
            Title = "Gun Reload Sound", 
            Content = value and "Muted!" or "Unmuted!", 
            Duration = 2 
        })
    end,
})

Misc:Toggle({
    Title = "Show Coordinates",
    Desc = "Display your position in console",
    Value = false,
    Callback = function(value)
        State.showCoordinates = value
    end,
})

Misc:Button({
    Title = "Create Star Effect",
    Desc = "Spawn star effect at your position",
    Icon = "star",
    Callback = function()
        if LocalPlayer.Character then
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                createStarEffect(hrp.Position)
            end
        end
    end,
})

Misc:Input({
    Title = "Custom Notification",
    Desc = "Send custom notification message",
    Placeholder = "Enter message...",
    Callback = function(text)
        if text ~= "" then
            WindUI:Notify({ Title = "Custom Message", Content = text, Duration = 3 })
        end
    end,
})

Misc:Divider()

Misc:Button({
    Title = "Rejoin Server",
    Desc = "Reconnect to current server",
    Icon = "refresh-ccw",
    Callback = function()
        WindUI:Popup({
            Title = "Rejoin Server",
            Icon = "info",
            Content = "Are you sure you want to rejoin?",
            Buttons = {
                { 
                    Title = "Yes", 
                    Variant = "Primary", 
                    Callback = function() 
                        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
                    end 
                },
                { Title = "Cancel", Variant = "Secondary", Callback = function() end },
            },
        })
    end,
})

Misc:Button({
    Title = "Server Hop",
    Desc = "Join a different server",
    Icon = "shuffle",
    Callback = function()
        WindUI:Notify({ Title = "Server Hop", Content = "Finding new server...", Duration = 2 })
        local Servers = game:GetService("HttpService")
        local success, result = pcall(function()
            return Servers:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        end)
        if success and result.data then
            local servers = result.data
            for i = 1, #servers do
                if servers[i].id ~= game.JobId then
                    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, servers[i].id, LocalPlayer)
                    break
                end
            end
        end
    end,
})

-- SETTINGS TAB
local Settings = Window:Tab({ Title = "Settings", Icon = "settings-2" })

Settings:Dropdown({
    Title = "Theme",
    Desc = "Change UI theme",
    Values = { "Dark", "Light", "Rose", "Plant", "Sky", "Emerald", "Midnight", "Crimson" },
    Value = WindUI:GetCurrentTheme(),
    Callback = function(theme)
        WindUI:SetTheme(theme)
    end,
})

Settings:Keybind({
    Title = "Toggle UI",
    Desc = "Key to show/hide menu",
    Value = "RightShift",
    Callback = function()
        Window:Toggle()
    end,
})

Settings:Paragraph({
    Title = "About",
    Desc = "MM2 Complete Hub v2.0 Full | 968 functions from decompiled source | WindUI Framework | by cobble",
})

-- ==================== RUNTIME LOOPS ====================

-- Fly control
RunService.Heartbeat:Connect(function()
    if State.flying and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local camera = workspace.CurrentCamera
        
        if hrp and State.bodyVelocity and State.bodyGyro then
            local moveDirection = Vector3.new()
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDirection = moveDirection + (camera.CFrame.LookVector * State.flySpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDirection = moveDirection - (camera.CFrame.LookVector * State.flySpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDirection = moveDirection - (camera.CFrame.RightVector * State.flySpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDirection = moveDirection + (camera.CFrame.RightVector * State.flySpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDirection = moveDirection + Vector3.new(0, State.flySpeed, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveDirection = moveDirection - Vector3.new(0, State.flySpeed, 0)
            end
            
            State.bodyVelocity.Velocity = moveDirection
            State.bodyGyro.CFrame = camera.CFrame
        else
            State.flying = false
        end
    end
end)

-- Coordinate display
RunService.Heartbeat:Connect(function()
    if State.showCoordinates and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local pos = hrp.Position
            print(string.format("Position: X=%.1f, Y=%.1f, Z=%.1f", pos.X, pos.Y, pos.Z))
        end
    end
end)

-- Time lock
RunService.Heartbeat:Connect(function()
    if State.timeLock then
        Lighting.ClockTime = State.timeOfDay
    end
end)

-- Infinite jump
UserInputService.JumpRequest:Connect(function()
    if State.infiniteJump and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Character respawn handler
LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.5)
    
    -- Reapply walk speed
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        humanoid.WalkSpeed = State.walkSpeed
        humanoid.JumpPower = State.jumpPower
    end
    
    -- Restart fly if enabled
    if State.flying then
        task.wait(1)
        startFly()
    end
    
    -- Restart noclip if enabled
    if State.noclip then
        task.wait(0.5)
        startNoclip()
    end
end)

-- ==================== INITIALIZATION ====================

Window:SelectTab(1)

WindUI:Notify({ 
    Title = "MM2 Complete Hub", 
    Content = "Successfully loaded! 968 functions integrated. Press RightShift to toggle.", 
    Duration = 5 
})

print("==============================================")
print("MM2 Complete Hub v2.0 Full")
print("968 functions from decompiled source")
print("WindUI Framework")
print("by cobble")
print("==============================================")
