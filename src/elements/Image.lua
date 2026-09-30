local Creator = require("../modules/Creator")
local New = Creator.New
local Tween = Creator.Tween

local UserInputService = game:GetService("UserInputService")

local Element = {}

local function ParseAspectRatio(aspectRatio)
    if type(aspectRatio) == "string" then
        local width, height = aspectRatio:match("(%d+):(%d+)")
        if width and height then
            return tonumber(width) / tonumber(height)
        end
    elseif type(aspectRatio) == "number" then
        return aspectRatio
    end
    return nil
end

function Element:New(Config)
    local ImageModule = {
        __type = "Image",
        Image = Config.Image or "",
        AspectRatio = Config.AspectRatio or "16:9",
        Radius = Config.Radius or Config.Window.ElementConfig.UICorner,
        Lightbox = Config.Lightbox or false,
    }
    
    local MainImage = Creator.Image(
        ImageModule.Image,
        ImageModule.Image,
        ImageModule.Radius,
        Config.Window.Folder,
        "Image",
        false
    )
    
    if MainImage and MainImage.Parent then
        MainImage.Parent = Config.Parent
        MainImage.Size = UDim2.new(1,0,0,0)
        MainImage.BackgroundTransparency = 1
        
        local aspectRatio = ParseAspectRatio(ImageModule.AspectRatio)
        local aspectRatioConstraint = nil
        
        if aspectRatio then
            aspectRatioConstraint = New("UIAspectRatioConstraint", {
                Parent = MainImage,
                AspectRatio = aspectRatio,
                AspectType = "ScaleWithParentSize",
                DominantAxis = "Width"
            })
        end
        
        -- Lightbox implementation
        if ImageModule.Lightbox then
            local LightboxOverlay = nil
            local isDragging = false
            local dragStart = nil
            local startPos = nil
            local currentZoom = 1
            local currentPan = Vector2.new(0, 0)
            
            local function CreateLightbox()
                local ScreenGui = Config.Window.UIElements.Main.Main.Parent
                
                LightboxOverlay = New("Frame", {
                    Name = "LightboxOverlay",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = Color3.fromHex("#000000"),
                    BackgroundTransparency = 0.1,
                    ZIndex = 10000,
                    Visible = false,
                    Parent = ScreenGui,
                })
                
                local CloseButton = New("TextButton", {
                    Size = UDim2.new(0, 40, 0, 40),
                    Position = UDim2.new(1, -50, 0, 10),
                    BackgroundColor3 = Color3.fromHex("#ffffff"),
                    BackgroundTransparency = 0.9,
                    Text = "",
                    Parent = LightboxOverlay,
                }, {
                    New("UICorner", {
                        CornerRadius = UDim.new(1, 0)
                    }),
                    New("TextLabel", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Text = "✕",
                        TextSize = 20,
                        TextColor3 = Color3.fromHex("#ffffff"),
                        Font = Enum.Font.GothamBold,
                    })
                })
                
                local ImageContainer = New("Frame", {
                    Size = UDim2.new(0.9, 0, 0.9, 0),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Parent = LightboxOverlay,
                    ClipsDescendants = true,
                })
                
                local LightboxImage = New("ImageLabel", {
                    Name = "LightboxImage",
                    Size = UDim2.new(1, 0, 1, 0),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = MainImage.Image,
                    ScaleType = Enum.ScaleType.Fit,
                    Parent = ImageContainer,
                })
                
                -- Close button functionality
                CloseButton.MouseButton1Click:Connect(function()
                    LightboxOverlay.Visible = false
                    currentZoom = 1
                    currentPan = Vector2.new(0, 0)
                    LightboxImage.Size = UDim2.new(1, 0, 1, 0)
                    LightboxImage.Position = UDim2.new(0.5, 0, 0.5, 0)
                end)
                
                -- Zoom with mouse wheel
                LightboxOverlay.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseWheel then
                        local zoomDelta = input.Position.Z * 0.1
                        currentZoom = math.clamp(currentZoom + zoomDelta, 0.5, 5)
                        
                        Tween(LightboxImage, 0.1, {
                            Size = UDim2.new(currentZoom, 0, currentZoom, 0)
                        }):Play()
                    end
                end)
                
                -- Pan with drag
                LightboxImage.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
                       input.UserInputType == Enum.UserInputType.Touch then
                        isDragging = true
                        dragStart = input.Position
                        startPos = LightboxImage.Position
                    end
                end)
                
                LightboxImage.InputChanged:Connect(function(input)
                    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                       input.UserInputType == Enum.UserInputType.Touch) then
                        local delta = input.Position - dragStart
                        local newX = startPos.X.Scale + (delta.X / ImageContainer.AbsoluteSize.X)
                        local newY = startPos.Y.Scale + (delta.Y / ImageContainer.AbsoluteSize.Y)
                        LightboxImage.Position = UDim2.new(newX, 0, newY, 0)
                    end
                end)
                
                LightboxImage.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
                       input.UserInputType == Enum.UserInputType.Touch then
                        isDragging = false
                    end
                end)
                
                -- Close on background click
                LightboxOverlay.InputBegan:Connect(function(input)
                    if (input.UserInputType == Enum.UserInputType.MouseButton1 or 
                        input.UserInputType == Enum.UserInputType.Touch) then
                        LightboxOverlay.Visible = false
                        currentZoom = 1
                        currentPan = Vector2.new(0, 0)
                        LightboxImage.Size = UDim2.new(1, 0, 1, 0)
                        LightboxImage.Position = UDim2.new(0.5, 0, 0.5, 0)
                    end
                end)
                
                return LightboxOverlay
            end
            
            -- Make image clickable
            local ClickButton = New("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 2,
                Parent = MainImage,
            })
            
            ClickButton.MouseButton1Click:Connect(function()
                if not LightboxOverlay then
                    CreateLightbox()
                end
                LightboxOverlay.Visible = true
            end)
        end
        
        function ImageModule:Destroy()
            MainImage:Destroy()
            if LightboxOverlay then
                LightboxOverlay:Destroy()
            end
        end
    end
    
    return ImageModule.__type, ImageModule
end

return Element