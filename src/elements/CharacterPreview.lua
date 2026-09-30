local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))

local Creator = require("../modules/Creator")
local New = Creator.New

local Element = {}

type ConfigType = {
	UserId: number?,
	Character: Model?,
	Height: number?,
	Interactive: boolean?,
	PlayAnimation: boolean?,
	AnimationId: string?,
	Focused: boolean?,

	Window: any,
	WindUI: any,
	Tab: any,
	Parent: Instance,
}

function Element:New(Config: ConfigType)
	local CharacterPreview = {
		__type = "CharacterPreview",
		UserId = Config.UserId,
		Character = Config.Character,
		Height = Config.Height or 250,
		Interactive = Config.Interactive ~= false,
		PlayAnimation = Config.PlayAnimation or false,
		AnimationId = Config.AnimationId,
		Focused = Config.Focused ~= false,
		CurrentAnimTrack = nil,
		UIElements = {},
	}

	local Dragging = false
	local Pinching = false
	local LastMousePos, LastPinchDist = nil, 0

	local Camera = Instance.new("Camera")
	local CharacterModel = nil

	local Main = Creator.NewRoundFrame(Config.Window.ElementConfig.UICorner, "Squircle", {
		Size = UDim2.new(1, 0, 0, CharacterPreview.Height),
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
				CurrentCamera = Camera,
				Active = CharacterPreview.Interactive,
			}),
		}),
	})

	local ViewportFrame = Main.CanvasGroup.Viewport

	local function LoadCharacterFromUserId(UserId)
		local success, characterModel = pcall(function()
			return Players:GetCharacterAppearanceAsync(UserId)
		end)

		if success and characterModel then
			if CharacterModel then
				CharacterModel:Destroy()
			end

			CharacterModel = characterModel
			CharacterModel.Parent = ViewportFrame

			if CharacterPreview.Focused then
				CharacterPreview:Focus()
			end

			if CharacterPreview.PlayAnimation and CharacterPreview.AnimationId then
				CharacterPreview:PlayAnimation(CharacterPreview.AnimationId)
			end
		else
			warn("[WindUI] CharacterPreview: Failed to load character for UserId " .. tostring(UserId))
		end
	end

	local function LoadCharacterFromModel(Model)
		if CharacterModel then
			CharacterModel:Destroy()
		end

		CharacterModel = Model:Clone()
		CharacterModel.Parent = ViewportFrame

		if CharacterPreview.Focused then
			CharacterPreview:Focus()
		end

		if CharacterPreview.PlayAnimation and CharacterPreview.AnimationId then
			CharacterPreview:PlayAnimation(CharacterPreview.AnimationId)
		end
	end

	if CharacterPreview.UserId then
		LoadCharacterFromUserId(CharacterPreview.UserId)
	elseif CharacterPreview.Character then
		LoadCharacterFromModel(CharacterPreview.Character)
	end

	local function IsTouchInsideViewport(Position)
		local AbsPos = ViewportFrame.AbsolutePosition
		local Size = ViewportFrame.AbsoluteSize

		return Position.X >= AbsPos.X
			and Position.X <= AbsPos.X + Size.X
			and Position.Y >= AbsPos.Y
			and Position.Y <= AbsPos.Y + Size.Y
	end

	local CurInput = Config.WindUI.GenerateGUID()

	Creator.AddSignal(ViewportFrame.MouseEnter, function()
		if CharacterPreview.Interactive then
			Config.Tab.UIElements.ContainerFrame.ScrollingEnabled = false
		end
	end)

	Creator.AddSignal(ViewportFrame.InputEnded, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseMovement
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			Config.Tab.UIElements.ContainerFrame.ScrollingEnabled = true
		end
	end)

	Creator.AddSignal(ViewportFrame.InputBegan, function(Input)
		if CharacterPreview.Interactive then
			if
				(Input.UserInputType == Enum.UserInputType.MouseButton1)
				or (Input.UserInputType == Enum.UserInputType.Touch and not Pinching)
			then
				if Config.WindUI.CurrentInput and Config.WindUI.CurrentInput ~= CurInput then
					return
				end

				Config.WindUI.CurrentInput = CurInput

				Dragging = true
				LastMousePos = Input.Position
			end
		end
	end)

	Creator.AddSignal(UserInputService.InputEnded, function(Input)
		if CharacterPreview.Interactive then
			if
				Input.UserInputType == Enum.UserInputType.MouseButton1
				or Input.UserInputType == Enum.UserInputType.Touch
			then
				if Config.WindUI.CurrentInput and Config.WindUI.CurrentInput ~= CurInput then
					return
				end

				Config.WindUI.CurrentInput = nil

				Dragging = false
			end
		end
	end)

	Creator.AddSignal(UserInputService.InputChanged, function(Input)
		if CharacterPreview.Interactive and Dragging and not Pinching and CharacterModel then
			if
				Input.UserInputType == Enum.UserInputType.MouseMovement
				or Input.UserInputType == Enum.UserInputType.Touch
			then
				local MouseDelta = Input.Position - LastMousePos
				LastMousePos = Input.Position

				local Position = CharacterModel:GetPivot().Position

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

	Creator.AddSignal(ViewportFrame.InputChanged, function(Input)
		if CharacterPreview.Interactive then
			if Input.UserInputType == Enum.UserInputType.MouseWheel then
				local ZoomAmount = Input.Position.Z * 2
				Camera.CFrame += Camera.CFrame.LookVector * ZoomAmount
			end
		end
	end)

	Creator.AddSignal(UserInputService.TouchPinch, function(touchPositions, scale, velocity, state)
		if not IsTouchInsideViewport(touchPositions[1]) or not IsTouchInsideViewport(touchPositions[2]) then
			return
		end
		if CharacterPreview.Interactive then
			if state == Enum.UserInputState.Begin then
				Pinching = true
				Dragging = false
				LastPinchDist = (touchPositions[1] - touchPositions[2]).Magnitude
			elseif state == Enum.UserInputState.Change then
				if Pinching then
					local currentDist = (touchPositions[1] - touchPositions[2]).Magnitude
					local delta = (currentDist - LastPinchDist) * 0.03
					LastPinchDist = currentDist
					Camera.CFrame += Camera.CFrame.LookVector * delta
				end
			elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
				Pinching = false
			end
		end
	end)

	local function FocusCamera()
		if not CharacterModel then
			return
		end

		local ModelSize = select(2, CharacterModel:GetBoundingBox())
		local MaxExtent = math.max(ModelSize.X, ModelSize.Y, ModelSize.Z)
		local CameraDistance = MaxExtent * 2
		local ModelPosition = CharacterModel:GetPivot().Position

		Camera.CFrame = CFrame.new(ModelPosition + Vector3.new(0, MaxExtent / 2, CameraDistance), ModelPosition)
	end

	function CharacterPreview:SetUserId(UserId)
		CharacterPreview.UserId = UserId
		CharacterPreview.Character = nil
		LoadCharacterFromUserId(UserId)
	end

	function CharacterPreview:SetCharacter(Model)
		CharacterPreview.Character = Model
		CharacterPreview.UserId = nil
		LoadCharacterFromModel(Model)
	end

	function CharacterPreview:PlayAnimation(AnimationId)
		if not CharacterModel then
			return
		end

		local Humanoid = CharacterModel:FindFirstChildOfClass("Humanoid")
		if not Humanoid then
			return
		end

		local Animator = Humanoid:FindFirstChildOfClass("Animator")
		if not Animator then
			Animator = Instance.new("Animator")
			Animator.Parent = Humanoid
		end

		if CharacterPreview.CurrentAnimTrack then
			CharacterPreview.CurrentAnimTrack:Stop()
		end

		local Animation = Instance.new("Animation")
		Animation.AnimationId = "rbxassetid://" .. tostring(AnimationId):gsub("rbxassetid://", "")

		local AnimationTrack = Animator:LoadAnimation(Animation)
		AnimationTrack.Looped = true
		AnimationTrack:Play()

		CharacterPreview.CurrentAnimTrack = AnimationTrack
	end

	function CharacterPreview:StopAnimation()
		if CharacterPreview.CurrentAnimTrack then
			CharacterPreview.CurrentAnimTrack:Stop()
			CharacterPreview.CurrentAnimTrack = nil
		end
	end

	function CharacterPreview:Focus()
		FocusCamera()
	end

	function CharacterPreview:SetHeight(Height)
		CharacterPreview.Height = Height
		Main.Size = UDim2.new(1, 0, 0, Height)
	end

	function CharacterPreview:SetInteractive(Interactive)
		CharacterPreview.Interactive = Interactive
		ViewportFrame.Active = Interactive
	end

	CharacterPreview.Main = Main

	return CharacterPreview.__type, CharacterPreview
end

return Element
