--[[
    WindUI Feature Showcase
    Loads the current published build and demonstrates the public UI API.
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ok, WindUI = pcall(function()
	return loadstring(game:HttpGet("https://raw.githubusercontent.com/etoneaetobylkaktus-lang/WindUI/main/dist/main.lua"))()
end)

if not ok or not WindUI then
	return warn("[ WindUI Showcase ] Failed to load: " .. tostring(WindUI))
end

local Window = WindUI:CreateWindow({
	Title = "WindUI Feature Showcase",
	Author = "WindUI",
	Folder = "WindUIShowcase",
	Icon = "solar:wind-bold",
	ToggleKey = Enum.KeyCode.RightShift,
	NewElements = true,
	HideSearchBar = false,
	OpenButton = {
		Enabled = true,
		Title = "Open WindUI Showcase",
		Draggable = true,
	},
	Topbar = {
		Height = 44,
		ButtonsType = "Default",
	},
})

Window:Tag({ Title = "v" .. tostring(WindUI.Version), Icon = "github" })

-- Overview and basic controls
local Overview = Window:Tab({ Title = "Overview", Icon = "house" })

Overview:Paragraph({
	Title = "WindUI",
	Desc = "Interactive showcase of the library's elements, layouts, media, 3D preview, charts, and window APIs.",
	Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150",
	ImageSize = 48,
})

local ClickCount = 0
local ClickParagraph = Overview:Paragraph({ Title = "Button callbacks", Desc = "Clicked 0 times" })

Overview:Button({
	Title = "Button",
	Desc = "Click to update the paragraph and show a notification",
	Icon = "mouse-pointer-click",
	Callback = function()
		ClickCount += 1
		ClickParagraph:SetDesc("Clicked " .. ClickCount .. " times")
		WindUI:Notify({ Title = "Button pressed", Content = "Callback count: " .. ClickCount, Duration = 3 })
	end,
})

Overview:Toggle({
	Title = "Toggle",
	Desc = "Boolean control",
	Value = true,
	Callback = function(value) print("Toggle:", value) end,
})

Overview:Toggle({
	Title = "Checkbox",
	Type = "Checkbox",
	Desc = "Checkbox variant",
	Callback = function(value) print("Checkbox:", value) end,
})

Overview:Slider({
	Title = "Slider",
	Desc = "Range with step and tooltip",
	Value = { Min = 0, Max = 100, Default = 35 },
	Step = 5,
	IsTooltip = true,
	Callback = function(value) print("Slider:", value) end,
})

local Progress = Overview:ProgressBar({
	Title = "Progress Bar",
	Desc = "Determinate progress; use the buttons below to update it",
	Value = { Min = 0, Max = 100, Default = 35 },
})

Overview:Button({
	Title = "Advance Progress",
	Icon = "arrow-up-right",
	Callback = function()
		Progress:Set(math.min(Progress:Get() + 10, 100))
	end,
})

Overview:ProgressBar({
	Title = "Indeterminate Progress",
	Indeterminate = true,
	IndeterminateText = "Working",
})

Overview:Input({
	Title = "Input",
	Desc = "Single-line text input",
	Placeholder = "Enter text...",
	Callback = function(text) print("Input:", text) end,
})

Overview:Input({
	Title = "Textarea",
	Type = "Textarea",
	Placeholder = "Write a few lines...",
	Callback = function(text) print("Textarea length:", #text) end,
})

Overview:Dropdown({
	Title = "Dropdown",
	Desc = "Searchable, multi-select options",
	Values = { "Alpha", "Bravo", "Charlie", "Delta" },
	Value = "Alpha",
	SearchBarEnabled = true,
	Multi = true,
	Callback = function(value) print("Dropdown:", value) end,
})

Overview:Keybind({
	Title = "Keybind",
	Desc = "Click to choose a key",
	Value = "K",
	Callback = function(value) print("Keybind activated:", value) end,
})

Overview:Colorpicker({
	Title = "Colorpicker",
	Desc = "Choose a color and transparency",
	Default = Color3.fromHex("#30C5A5"),
	Callback = function(color) print("Color:", color) end,
})

Overview:Divider()
Overview:Space({ Columns = 1 })

-- Layout primitives
local Layout = Window:Tab({ Title = "Layout", Icon = "layout-dashboard" })

Layout:Section({ Title = "Sections", Desc = "Expandable grouping for related elements", Box = true, BoxBorder = true, Opened = true })
Layout:Paragraph({ Title = "Inside a section", Desc = "Sections can group controls and collapse their contents." })

local Group = Layout:Group({})
Group:Button({ Title = "Group item A", Justify = "Center", Callback = function() print("Group A") end })
Group:Button({ Title = "Group item B", Justify = "Center", Callback = function() print("Group B") end })

local HStack = Layout:HStack()
local LeftColumn = HStack:VStack()
local RightColumn = HStack:VStack()
LeftColumn:Button({ Title = "HStack / VStack left", Justify = "Center", Callback = function() end })
RightColumn:Toggle({ Title = "Right column", Value = true })

Layout:Divider()
Layout:Paragraph({ Title = "Spacing", Desc = "Space and Divider control rhythm between elements." })
Layout:Space({ Columns = 2 })
Layout:Section({ Title = "Collapsed section", Desc = "Expand to reveal the nested button", Box = true, Opened = false })
Layout:Button({ Title = "Nested action", Callback = function() print("Nested section") end })

-- Media and code
local Media = Window:Tab({ Title = "Media & Code", Icon = "image" })

Media:Image({
	Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=420&h=420",
	AspectRatio = "16:9",
	Lightbox = true,
})

Media:Code({
	Title = "Code Block",
	Code = "local WindUI = loadstring(game:HttpGet(url))()\nlocal Window = WindUI:CreateWindow({\n    Title = 'My Window'\n})",
	ShowLineNumbers = true,
	CanCopied = true,
})

-- 3D and data visualisation
local Visuals = Window:Tab({ Title = "3D & Charts", Icon = "box" })

local DemoModel = Instance.new("Model")
local Core = Instance.new("Part")
Core.Name = "Core"
Core.Size = Vector3.new(3, 3, 3)
Core.Anchored = true
Core.Material = Enum.Material.Neon
Core.Color = Color3.fromHex("#30C5A5")
Core.Parent = DemoModel

local Ring = Instance.new("Part")
Ring.Name = "Ring"
Ring.Size = Vector3.new(5, 0.4, 5)
Ring.Anchored = true
Ring.Material = Enum.Material.Metal
Ring.Color = Color3.fromHex("#E8B04A")
Ring.CFrame = CFrame.new(0, 2.2, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45))
Ring.Parent = DemoModel

local Viewport = Visuals:Viewport({
	Object = DemoModel,
	Height = 210,
	Interactive = true,
	RotateOnly = true,
	AutoRotate = true,
	ShowGrid = true,
	Lighting = { Brightness = 2, Color = Color3.new(1, 1, 1), Range = 32 },
})

local Presets = Visuals:HStack()
local PresetColumnA = Presets:VStack()
local PresetColumnB = Presets:VStack()
PresetColumnA:Button({ Title = "Isometric camera", Callback = function() Viewport:SetCameraPreset("Isometric") end })
PresetColumnB:Button({ Title = "Reset camera", Callback = function() Viewport:ResetCamera() end })

Visuals:Slider({
	Title = "Viewport FOV",
	Value = { Min = 35, Max = 100, Default = 70 },
	Callback = function(value) Viewport:SetFOV(value) end,
})

Visuals:Toggle({
	Title = "Auto rotate",
	Value = true,
	Callback = function(value) Viewport:SetAutoRotate(value) end,
})

local Chart = Visuals:Chart({
	Title = "Line Chart",
	Type = "Line",
	Data = { 8, 14, 11, 25, 19, 32, 27 },
	Height = 160,
	Colors = { Color3.fromHex("#30C5A5") },
})

Visuals:Button({ Title = "Switch chart to bars", Callback = function() Chart:SetType("Bar") end })
Visuals:Button({
	Title = "Randomize chart data",
	Callback = function()
		local values = {}
		for index = 1, 7 do values[index] = math.random(5, 40) end
		Chart:SetData(values)
	end,
})

Visuals:CharacterPreview({
	UserId = LocalPlayer.UserId,
	Height = 210,
	Interactive = true,
	PlayAnimation = false,
})

-- Telegram channel card (metadata requires executor HTTP support)
local Social = Window:Tab({ Title = "Telegram", Icon = "send" })
Social:Paragraph({
	Title = "Telegram Channel Card",
	Desc = "Public channel metadata is fetched from t.me. Change ChannelUser to your channel username.",
})
local TelegramCard = Social:TelegramParagraph({
	ChannelUser = "yasosalpeniskakloh",
	Title = "Наш Telegram-канал",
	ButtonTitle = "Copy link and open Telegram",
})
Social:Button({ Title = "Refresh channel details", Callback = function() TelegramCard:Refresh() end })

-- Window and library APIs
local Actions = Window:Tab({ Title = "Window & Themes", Icon = "settings-2" })

Actions:Dropdown({
	Title = "Theme",
	Values = { "Dark", "Light", "Rose", "Plant", "Sky", "Emerald", "Midnight", "Crimson" },
	Value = WindUI:GetCurrentTheme(),
	Callback = function(theme) WindUI:SetTheme(theme) end,
})

Actions:Button({
	Title = "Show notification",
	Callback = function()
		WindUI:Notify({ Title = "WindUI", Content = "Notifications are controlled through WindUI:Notify().", Duration = 4 })
	end,
})

Actions:Button({
	Title = "Open popup",
	Callback = function()
		WindUI:Popup({
			Title = "WindUI Popup",
			Icon = "info",
			Content = "Popup windows can contain actions and status information.",
			Buttons = {
				{ Title = "Close", Variant = "Primary", Callback = function() end },
			},
		})
	end,
})

Actions:Button({
	Title = "Open dialog",
	Callback = function()
		Window:Dialog({
			Title = "WindUI Dialog",
			Content = "Dialog actions are configured with a title, content, and button callbacks.",
			Buttons = {
				{ Title = "Okay", Variant = "Primary", Callback = function() print("Dialog confirmed") end },
				{ Title = "Cancel", Variant = "Secondary", Callback = function() end },
			},
		})
	end,
})

Actions:Keybind({
	Title = "Showcase toggle key",
	Value = "RightShift",
	Callback = function() Window:Toggle() end,
})

Actions:Paragraph({
	Title = "Window API",
	Desc = "The window also exposes Open, Close, Toggle, SetTitle, SetSize, SetUIScale, ToggleFullscreen, LockAll, UnlockAll, and tab selection methods.",
})

Window:SelectTab(1)
