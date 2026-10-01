local Creator = require("../modules/Creator")
local New = Creator.New

local Element = {}

function Element:New(Config)
	local Chart = {
		__type = "Chart",
		Type = Config.Type or "Line", -- "Line" or "Bar"
		Data = Config.Data or {}, -- массив {x, y} или просто значений
		Height = Config.Height or 200,
		Colors = Config.Colors or {Color3.fromRGB(56, 189, 248)}, -- массив цветов для линий/баров
		Title = Config.Title or "Chart",
		Desc = Config.Desc,
		UIElements = {},
	}

	Chart.ChartFrame = require("../components/window/Element")({
		Title = Chart.Title,
		Desc = Chart.Desc,
		Parent = Config.Parent,
		Window = Config.Window,
		Justify = "Between",
		Scalable = true,
		Tab = Config.Tab,
		Index = Config.Index,
		ElementTable = Chart,
		ParentConfig = Config,
		Size = Config.Size,
		Tags = Config.Tags,
	})

	-- контейнер для графика
	local ChartContainer = New("Frame", {
		Name = "ChartContainer",
		Parent = Chart.ChartFrame.UIElements.Main,
		BackgroundColor3 = Color3.fromRGB(10, 13, 18),
		BackgroundTransparency = 0,
		Size = UDim2.new(1, -20, 0, Chart.Height),
		Position = UDim2.new(0, 10, 0, 0),
		BorderSizePixel = 0,
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),
		New("UIStroke", {
			Color = Color3.fromRGB(30, 35, 45),
			Thickness = 1,
			Transparency = 0.5,
		}),
	})

	Chart.UIElements.Container = ChartContainer

	-- функция нормализации данных
	local function NormalizeData(data)
		local normalized = {}
		local minVal, maxVal = math.huge, -math.huge

		-- определяем формат данных и находим min/max
		for i, point in ipairs(data) do
			local value
			if typeof(point) == "table" then
				value = point.y or point[2]
			else
				value = point
			end

			minVal = math.min(minVal, value)
			maxVal = math.max(maxVal, value)
		end

		-- нормализуем к диапазону 0-1
		local range = maxVal - minVal
		if range == 0 then range = 1 end

		for i, point in ipairs(data) do
			local x, y
			if typeof(point) == "table" then
				x = point.x or point[1] or i
				y = point.y or point[2]
			else
				x = i
				y = point
			end

			table.insert(normalized, {
				x = x,
				y = (y - minVal) / range,
				originalY = y,
			})
		end

		return normalized, minVal, maxVal
	end

	-- рисуем график
	local function DrawChart()
		-- очищаем предыдущий график
		for _, child in ipairs(ChartContainer:GetChildren()) do
			if not child:IsA("UICorner") and not child:IsA("UIStroke") then
				child:Destroy()
			end
		end

		if #Chart.Data == 0 then
			return
		end

		local normalized, minVal, maxVal = NormalizeData(Chart.Data)
		local width = ChartContainer.AbsoluteSize.X
		local height = ChartContainer.AbsoluteSize.Y
		local padding = 10

		if Chart.Type == "Bar" then
			-- bar chart
			local barWidth = (width - padding * 2) / #normalized
			local maxBarWidth = 60
			if barWidth > maxBarWidth then
				barWidth = maxBarWidth
			end

			for i, point in ipairs(normalized) do
				local barHeight = point.y * (height - padding * 2)
				local xPos = padding + (i - 1) * ((width - padding * 2) / #normalized)

				local bar = New("Frame", {
					Name = "Bar" .. i,
					Parent = ChartContainer,
					BackgroundColor3 = Chart.Colors[1] or Color3.fromRGB(56, 189, 248),
					Size = UDim2.new(0, barWidth * 0.8, 0, barHeight),
					Position = UDim2.new(0, xPos, 1, -padding - barHeight),
					BorderSizePixel = 0,
				}, {
					New("UICorner", {
						CornerRadius = UDim.new(0, 4),
					}),
				})
			end

		elseif Chart.Type == "Line" then
			-- line chart с использованием Frame
			for i = 1, #normalized - 1 do
				local p1 = normalized[i]
				local p2 = normalized[i + 1]

				local x1 = padding + ((i - 1) / (#normalized - 1)) * (width - padding * 2)
				local y1 = height - padding - p1.y * (height - padding * 2)
				local x2 = padding + (i / (#normalized - 1)) * (width - padding * 2)
				local y2 = height - padding - p2.y * (height - padding * 2)

				-- вычисляем угол и длину линии
				local dx = x2 - x1
				local dy = y2 - y1
				local distance = math.sqrt(dx * dx + dy * dy)
				local angle = math.deg(math.atan2(dy, dx))

				-- создаём линию
				local line = New("Frame", {
					Name = "Line" .. i,
					Parent = ChartContainer,
					BackgroundColor3 = Chart.Colors[1] or Color3.fromRGB(56, 189, 248),
					Size = UDim2.new(0, distance, 0, 2),
					Position = UDim2.new(0, x1, 0, y1),
					AnchorPoint = Vector2.new(0, 0.5),
					Rotation = angle,
					BorderSizePixel = 0,
				})

				-- точки на линии
				local point = New("Frame", {
					Name = "Point" .. i,
					Parent = ChartContainer,
					BackgroundColor3 = Chart.Colors[1] or Color3.fromRGB(56, 189, 248),
					Size = UDim2.new(0, 6, 0, 6),
					Position = UDim2.new(0, x1, 0, y1),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BorderSizePixel = 0,
				}, {
					New("UICorner", {
						CornerRadius = UDim.new(1, 0),
					}),
				})
			end

			-- последняя точка
			if #normalized > 0 then
				local lastPoint = normalized[#normalized]
				local x = padding + (width - padding * 2)
				local y = height - padding - lastPoint.y * (height - padding * 2)

				New("Frame", {
					Name = "Point" .. #normalized,
					Parent = ChartContainer,
					BackgroundColor3 = Chart.Colors[1] or Color3.fromRGB(56, 189, 248),
					Size = UDim2.new(0, 6, 0, 6),
					Position = UDim2.new(0, x, 0, y),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BorderSizePixel = 0,
				}, {
					New("UICorner", {
						CornerRadius = UDim.new(1, 0),
					}),
				})
			end
		end
	end

	-- начальный рендер
	task.defer(DrawChart)

	-- обновление данных
	function Chart:SetData(data)
		Chart.Data = data
		DrawChart()
	end

	function Chart:SetType(chartType)
		Chart.Type = chartType
		DrawChart()
	end

	function Chart:SetColors(colors)
		Chart.Colors = colors
		DrawChart()
	end

	-- обновление при изменении размера
	ChartContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		DrawChart()
	end)

	Chart.ChartFrame.UIElements.Main.Size = UDim2.new(1, 0, 0, Chart.Height + 20)

	return Chart.ChartFrame, Chart
end

return Element
