local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local TweenService = cloneref(game:GetService("TweenService"))

local Creator = require("../modules/Creator")
local New = Creator.New

local Element = {}

type ConfigType = {
	Object: Instance,
	Camera: Instance?,
	Interactive: boolean?,
	Height: number?,
	Focused: boolean,
	AutoRotate: boolean?,
	Lighting: { Brightness: number?, Color: Color3?, Range: number? }?,
	ShowGrid: boolean?,
	RotateOnly: boolean?,

	Window: any, -- later
	WindUI: any, -- later
	Tab: any, -- later
	Parent: Instance,
}

function Element:New(Config: ConfigType)
	local Viewport = {
		__type = "Viewport",
		Object = Config.Object,
		Camera = Config.Camera or Instance.new("Camera"),
		Interactive = Config.Interactive or false,
		Height = Config.Height or 200,
		Focused = Config.Focused ~= false,
		AutoRotate = Config.AutoRotate or false,
		RotateOnly = Config.RotateOnly or false,
		PointLight = nil,
		GridFrame = nil,
	}

	local Dragging = false
	local Panning = false
	local Pinching = false
	local LastMousePos, LastPinchDist = nil, 0
	local PanTouchCount = 0
	
	local AutoRotateConnection = nil
	local AutoRotateActive = false
	local AutoRotateResumeTimer = nil
	local InitialCameraCFrame = nil

	local Main = Creator.NewRoundFrame(Config.Window.ElementConfig.UICorner, "Squircle", {
		Size = UDim2.new(1, 0, 0, Viewport.Height),
		Parent = Config.Parent,
		ThemeTag = {
			ImageColor3 = "ViewportBackground",
			ImageTransparency = "ViewportBackgroundTransparency",
		},
	}, {
		New("CanvasGroup", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, Config.Window.ElementConfig.UICorner),
			}),
			New("ViewportFrame", {
				Name = "Viewport",
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				CurrentCamera = Viewport.Camera,
				Active = Viewport.Interactive,
			}, {
				Viewport.Object,
			}),
			Config.ShowGrid and New("Frame", {
				Name = "GridOverlay",
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				ZIndex = 10,
			}, {
				New("UICorner", {
					CornerRadius = UDim.new(0, Config.Window.ElementConfig.UICorner),
				}),
				New("ImageLabel", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Image = "rbxasset://textures/ui/GridLine.png",
					ImageTransparency = 0.85,
					ScaleType = Enum.ScaleType.Tile,
					TileSize = UDim2.new(0, 50, 0, 50),
					ImageColor3 = Color3.fromRGB(255, 255, 255),
				}),
			}) or nil,
		}),
	})

	local function IsTouchInsideViewport(Position)
		local AbsPos = Main.CanvasGroup.Viewport.AbsolutePosition
		local Size = Main.CanvasGroup.Viewport.AbsoluteSize

		return Position.X >= AbsPos.X
			and Position.X <= AbsPos.X + Size.X
			and Position.Y >= AbsPos.Y
			and Position.Y <= AbsPos.Y + Size.Y
	end

	-- Initialize lighting if provided
	if Config.Lighting then
		local Light = Instance.new("PointLight")
		Light.Brightness = Config.Lighting.Brightness or 1
		Light.Color = Config.Lighting.Color or Color3.fromRGB(255, 255, 255)
		Light.Range = Config.Lighting.Range or 30
		Light.Parent = Main.CanvasGroup.Viewport
		Viewport.PointLight = Light
	end

	-- Store grid reference if enabled
	if Config.ShowGrid then
		Viewport.GridFrame = Main.CanvasGroup:FindFirstChild("GridOverlay")
	end

	local CurInput = Config.WindUI.GenerateGUID()

	Creator.AddSignal(Main.CanvasGroup.Viewport.MouseEnter, function()
		if Viewport.Interactive then
			Config.Tab.UIElements.ContainerFrame.ScrollingEnabled = false
		end
	end)

	Creator.AddSignal(Main.CanvasGroup.Viewport.InputEnded, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseMovement
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			Config.Tab.UIElements.ContainerFrame.ScrollingEnabled = true
		end
	end)

	Creator.AddSignal(Main.CanvasGroup.Viewport.InputBegan, function(Input)
		if Viewport.Interactive then
			local ShiftHeld = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
			
			if not Viewport.RotateOnly and (
				(Input.UserInputType == Enum.UserInputType.MouseButton1 and ShiftHeld)
				or (Input.UserInputType == Enum.UserInputType.MouseButton2)
			)
			then
				if Config.WindUI.CurrentInput and Config.WindUI.CurrentInput ~= CurInput then
					return
				end

				Config.WindUI.CurrentInput = CurInput
				Panning = true
				LastMousePos = Input.Position
			elseif
				(Input.UserInputType == Enum.UserInputType.MouseButton1)
				or (Input.UserInputType == Enum.UserInputType.Touch and not Pinching)
			then
				if Config.WindUI.CurrentInput and Config.WindUI.CurrentInput ~= CurInput then
					return
				end

				Config.WindUI.CurrentInput = CurInput

				Dragging = true
				LastMousePos = Input.Position
				
				StopAutoRotate()
			end
		end
	end)

	Creator.AddSignal(UserInputService.InputEnded, function(Input)
		if Viewport.Interactive then
			if
				Input.UserInputType == Enum.UserInputType.MouseButton1
				or Input.UserInputType == Enum.UserInputType.MouseButton2
				or Input.UserInputType == Enum.UserInputType.Touch
			then
				if Config.WindUI.CurrentInput and Config.WindUI.CurrentInput ~= CurInput then
					return
				end

				Config.WindUI.CurrentInput = nil

				Dragging = false
				Panning = false
				
				ScheduleAutoRotateResume()
			end
		end
	end)

	Creator.AddSignal(UserInputService.InputChanged, function(Input)
		if Viewport.Interactive and not Viewport.RotateOnly and Panning and not Pinching then
			if
				Input.UserInputType == Enum.UserInputType.MouseMovement
				or Input.UserInputType == Enum.UserInputType.Touch
			then
				local MouseDelta = Input.Position - LastMousePos
				LastMousePos = Input.Position

				local Camera = Viewport.Camera
				local PanSpeed = 0.01
				local Right = Camera.CFrame.RightVector
				local Up = Camera.CFrame.UpVector

				Camera.CFrame = Camera.CFrame - Right * MouseDelta.X * PanSpeed + Up * MouseDelta.Y * PanSpeed
			end
		elseif Viewport.Interactive and Dragging and not Pinching then
			if
				Input.UserInputType == Enum.UserInputType.MouseMovement
				or Input.UserInputType == Enum.UserInputType.Touch
			then
				local MouseDelta = Input.Position - LastMousePos
				LastMousePos = Input.Position

				local Position = Viewport.Object:GetPivot().Position
				local Camera = Viewport.Camera

				local RotationY = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), -MouseDelta.X * 0.02)
				Camera.CFrame = CFrame.new(Position) * RotationY * CFrame.new(-Position) * Camera.CFrame

				local RotationX = CFrame.fromAxisAngle(Camera.CFrame.RightVector, -MouseDelta.Y * 0.02)
				local PitchedCFrame = CFrame.new(Position) * RotationX * CFrame.new(-Position) * Camera.CFrame

				if PitchedCFrame.UpVector.Y > 0.1 then
					Camera.CFrame = PitchedCFrame
				end
			end
		end
	end)

	Creator.AddSignal(Main.CanvasGroup.Viewport.InputChanged, function(Input)
		if Viewport.Interactive then
			if not Viewport.RotateOnly and Input.UserInputType == Enum.UserInputType.MouseWheel then
				local ZoomAmount = Input.Position.Z * 2
				Viewport.Camera.CFrame += Viewport.Camera.CFrame.LookVector * ZoomAmount
				
				StopAutoRotate()
				ScheduleAutoRotateResume()
			end
		end
	end)

	Creator.AddSignal(UserInputService.TouchPinch, function(touchPositions, scale, velocity, state)
		if not IsTouchInsideViewport(touchPositions[1]) or not IsTouchInsideViewport(touchPositions[2]) then
			return
		end
		if Viewport.Interactive and not Viewport.RotateOnly then
			if state == Enum.UserInputState.Begin then
				Pinching = true
				Dragging = false
				Panning = false
				LastPinchDist = (touchPositions[1] - touchPositions[2]).Magnitude
				
				StopAutoRotate()
			elseif state == Enum.UserInputState.Change then
				if Pinching then
					local currentDist = (touchPositions[1] - touchPositions[2]).Magnitude
					local delta = (currentDist - LastPinchDist) * 0.03
					LastPinchDist = currentDist
					Viewport.Camera.CFrame += Viewport.Camera.CFrame.LookVector * delta
				end
			elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
				Pinching = false
				
				ScheduleAutoRotateResume()
			end
		end
	end)

	-- Two-finger pan detection for mobile
	Creator.AddSignal(UserInputService.TouchStarted, function(touch, gameProcessed)
		if IsTouchInsideViewport(touch.Position) and Viewport.Interactive and not Viewport.RotateOnly then
			PanTouchCount = PanTouchCount + 1
			if PanTouchCount == 2 and not Pinching then
				Panning = true
				Dragging = false
				LastMousePos = touch.Position
			end
		end
	end)

	Creator.AddSignal(UserInputService.TouchEnded, function(touch, gameProcessed)
		if Viewport.Interactive then
			PanTouchCount = math.max(0, PanTouchCount - 1)
			if PanTouchCount < 2 then
				Panning = false
			end
		end
	end)

	local function FocusCamera()
		local ModelSize = Viewport.Object:IsA("BasePart") and Viewport.Object.Size
			or select(2, Viewport.Object:GetBoundingBox(0))
		local MaxExtent = math.max(ModelSize.X, ModelSize.Y, ModelSize.Z)
		local CameraDistance = MaxExtent * 2
		local ModelPosition = Viewport.Object:GetPivot().Position

		Viewport.Camera.CFrame =
			CFrame.new(ModelPosition + Vector3.new(0, MaxExtent / 2, CameraDistance), ModelPosition)
		InitialCameraCFrame = Viewport.Camera.CFrame
	end

	if Viewport.Focused then
		FocusCamera()
	end
	
	local function StopAutoRotate()
		if AutoRotateConnection then
			AutoRotateConnection:Disconnect()
			AutoRotateConnection = nil
		end
		AutoRotateActive = false
		if AutoRotateResumeTimer then
			task.cancel(AutoRotateResumeTimer)
			AutoRotateResumeTimer = nil
		end
	end
	
	local function StartAutoRotate()
		if not Viewport.AutoRotate then return end
		
		StopAutoRotate()
		AutoRotateActive = true
		
		AutoRotateConnection = RunService.RenderStepped:Connect(function(dt)
			if not AutoRotateActive or Dragging or Pinching or Panning then
				return
			end
			
			local Position = Viewport.Object:GetPivot().Position
			local RotationY = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), -0.5 * dt)
			Viewport.Camera.CFrame = CFrame.new(Position) * RotationY * CFrame.new(-Position) * Viewport.Camera.CFrame
		end)
	end
	
	local function ScheduleAutoRotateResume()
		if not Viewport.AutoRotate then return end
		
		if AutoRotateResumeTimer then
			task.cancel(AutoRotateResumeTimer)
		end
		
		AutoRotateResumeTimer = task.delay(2, function()
			StartAutoRotate()
		end)
	end
	
	if Viewport.AutoRotate then
		StartAutoRotate()
	end

	function Viewport:SetObject(Object, IsClone)
		if IsClone then
			Object = Object:Clone()
		end
		if Viewport.Object then
			Viewport.Object:Destroy()
		end

		Viewport.Object = Object
		Viewport.Object.Parent = Main.CanvasGroup.Viewport
	end

	function Viewport:SetHeight(Height)
		Main.Size = UDim2.new(1, 0, 0, Height)
	end

	function Viewport:Focus()
		if Viewport.Object then
			FocusCamera()
		end
	end

	function Viewport:SetCamera(Camera)
		Viewport.Camera = Camera
		Main.CanvasGroup.Viewport.CurrentCamera = Camera
	end

	function Viewport:SetInteractive(Interactive)
		Viewport.Interactive = Interactive
		Main.CanvasGroup.Viewport.Active = Interactive
	end

	function Viewport:SetLighting(LightConfig)
		if not Viewport.PointLight then
			local Light = Instance.new("PointLight")
			Light.Parent = Main.CanvasGroup.Viewport
			Viewport.PointLight = Light
		end

		if LightConfig.Brightness then
			Viewport.PointLight.Brightness = LightConfig.Brightness
		end
		if LightConfig.Color then
			Viewport.PointLight.Color = LightConfig.Color
		end
		if LightConfig.Range then
			Viewport.PointLight.Range = LightConfig.Range
		end
	end

	function Viewport:SetGrid(Enabled)
		if Enabled and not Viewport.GridFrame then
			local Grid = New("Frame", {
				Name = "GridOverlay",
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				ZIndex = 10,
				Parent = Main.CanvasGroup,
			}, {
				New("UICorner", {
					CornerRadius = UDim.new(0, Config.Window.ElementConfig.UICorner),
				}),
				New("ImageLabel", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Image = "rbxasset://textures/ui/GridLine.png",
					ImageTransparency = 0.85,
					ScaleType = Enum.ScaleType.Tile,
					TileSize = UDim2.new(0, 50, 0, 50),
					ImageColor3 = Color3.fromRGB(255, 255, 255),
				}),
			})
			Viewport.GridFrame = Grid
		elseif not Enabled and Viewport.GridFrame then
			Viewport.GridFrame:Destroy()
			Viewport.GridFrame = nil
		end
	end
	
	function Viewport:SetAutoRotate(Enabled)
		Viewport.AutoRotate = Enabled
		
		if Enabled then
			StartAutoRotate()
		else
			StopAutoRotate()
		end
	end
	
	function Viewport:SetCameraPreset(preset)
		if not Viewport.Object then return end
		
		local ModelSize = Viewport.Object:IsA("BasePart") and Viewport.Object.Size
			or select(2, Viewport.Object:GetBoundingBox(0))
		local MaxExtent = math.max(ModelSize.X, ModelSize.Y, ModelSize.Z)
		local CameraDistance = MaxExtent * 2
		local ModelPosition = Viewport.Object:GetPivot().Position
		
		local PresetCFrames = {
			Front = CFrame.new(ModelPosition + Vector3.new(0, 0, CameraDistance), ModelPosition),
			Back = CFrame.new(ModelPosition + Vector3.new(0, 0, -CameraDistance), ModelPosition),
			Left = CFrame.new(ModelPosition + Vector3.new(-CameraDistance, 0, 0), ModelPosition),
			Right = CFrame.new(ModelPosition + Vector3.new(CameraDistance, 0, 0), ModelPosition),
			Top = CFrame.new(ModelPosition + Vector3.new(0, CameraDistance, 0), ModelPosition),
			Bottom = CFrame.new(ModelPosition + Vector3.new(0, -CameraDistance, 0), ModelPosition),
			Isometric = CFrame.new(ModelPosition + Vector3.new(CameraDistance, CameraDistance, CameraDistance), ModelPosition),
		}
		
		local TargetCFrame = PresetCFrames[preset]
		if not TargetCFrame then return end
		
		StopAutoRotate()
		
		local TweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local CameraTween = TweenService:Create(Viewport.Camera, TweenInfo, { CFrame = TargetCFrame })
		CameraTween:Play()
		
		CameraTween.Completed:Connect(function()
			ScheduleAutoRotateResume()
		end)
	end
	
	function Viewport:ResetCamera()
		if not InitialCameraCFrame then return end
		
		StopAutoRotate()
		
		local TweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local CameraTween = TweenService:Create(Viewport.Camera, TweenInfo, { CFrame = InitialCameraCFrame })
		CameraTween:Play()
		
		CameraTween.Completed:Connect(function()
			ScheduleAutoRotateResume()
		end)
	end
	
	function Viewport:SetFOV(fov)
		Viewport.Camera.FieldOfView = fov
	end

	Viewport.Main = Main

	return Viewport.__type, Viewport
end

return Element
