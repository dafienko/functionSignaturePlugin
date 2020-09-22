local module = {}

local pluginGui = script:WaitForChild("pluginGui")
local widgetFrame = pluginGui:WaitForChild("widget")
local tweenService = game:GetService("TweenService")
local signaturesTabHandler = require(script:WaitForChild("signaturesTab"))
local addedScriptsTabHandler = require(script:WaitForChild("addedScriptsTab"))
local scriptTracker = require(script:WaitForChild("scriptTracker"))

local initialized = false
local widgetUi = nil
local widgetMainFrame = nil
local currentSelectedTabName = "signatures"
local uiConnections = {}

local backgroundColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground, Enum.StudioStyleGuideModifier.Default)
local isDarkMode = (backgroundColor.r + backgroundColor.g + backgroundColor.b) < 1.5
local textColor = (isDarkMode and Color3.fromRGB(255, 255, 255)) or Color3.fromRGB(0, 0, 0)
local tabButtonColor = (isDarkMode and Color3.fromRGB(255, 255, 255)) or Color3.fromRGB(0, 120, 215)

local function setColors()
	assert(initialized and widgetUi, "Cannot set colors, widget is not initialized!")
	backgroundColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
	isDarkMode = (backgroundColor.r + backgroundColor.g + backgroundColor.b) < 1.5
	textColor = (isDarkMode and Color3.fromRGB(255, 255, 255)) or Color3.fromRGB(0, 0, 0)
	tabButtonColor = (isDarkMode and Color3.fromRGB(255, 255, 255)) or Color3.fromRGB(0, 120, 215)
	
	widgetMainFrame.BackgroundColor3 = backgroundColor
	
	local trackedScriptsButton = widgetMainFrame:WaitForChild("trackedScripts")
	trackedScriptsButton.BackgroundColor3 = tabButtonColor
	if currentSelectedTabName == trackedScriptsButton.Name then
		trackedScriptsButton.TextColor3 = Color3.fromRGB(0, 0, 0) -- black regardless of theme
	else
		trackedScriptsButton.TextColor3 = textColor
	end
		
	local signaturesButton = widgetMainFrame:WaitForChild("signatures")
	signaturesButton.BackgroundColor3 = tabButtonColor
	if currentSelectedTabName == signaturesButton.Name then
		signaturesButton.TextColor3 = Color3.fromRGB(0, 0, 0) 
	else
		signaturesButton.TextColor3 = textColor
	end
	
	
	signaturesTabHandler.updateColors()
	addedScriptsTabHandler.updateColors()
end

settings().Studio.ThemeChanged:Connect(function()
	if initialized then
		setColors()
	end
end)

local function selectTabButton(selectedButton)
	assert(initialized and widgetUi, "Cannot switch tabs, widget is not initialized!")
	
	local tabButtons = {
		signaturesButton = widgetMainFrame:WaitForChild("signatures"),
		trackedScriptsButton = widgetMainFrame:WaitForChild("trackedScripts")
	}
	
	currentSelectedTabName = selectedButton.Name
	
	local tweenInfo = TweenInfo.new(
		.1, 
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.InOut,
		0,
		false,
		0
	)
	
	-- select button effect
	for i, button in pairs(tabButtons) do
		local tween
		if button == selectedButton then
			tween = tweenService:Create(
				button,
				tweenInfo,
				{
					["BackgroundTransparency"]=0,
					["TextColor3"]=Color3.fromRGB(0, 0, 0)
				}
			)
		else
			tween = tweenService:Create(
				button,
				tweenInfo,
				{
					["BackgroundTransparency"]=1,
					["TextColor3"]=textColor
				}
			)
		end
		
		tween:Play()
	end
	
	-- scroll to button's corresponding frame in tabScrollingFrame
	local tabScrollingFrame = widgetMainFrame:WaitForChild("tabScrollingFrame")
	local tabFrame = tabScrollingFrame:WaitForChild(currentSelectedTabName)
	local tabXPos = tabFrame.Position.X.Scale * 
		tabScrollingFrame.CanvasSize.X.Scale * 
		tabScrollingFrame.AbsoluteWindowSize.X
	
	local scrollTween = tweenService:Create(
		tabScrollingFrame, 
		tweenInfo,
		{
			["CanvasPosition"]=Vector2.new(tabXPos, 0)
		}
	)
	
	scrollTween:Play()
end

function module.init(widgetUiArg)
	widgetUi = widgetUiArg
	if not initialized then
		
		widgetMainFrame = Instance.new("Frame")
		widgetMainFrame.Size = UDim2.new(1, 0, 1, 0)
		widgetMainFrame.Name = "main"
		widgetMainFrame.BorderSizePixel = 0
		widgetMainFrame.Position = UDim2.new(0, 0, 0, 0)
		widgetMainFrame.BackgroundColor3 = backgroundColor
		widgetMainFrame.Parent = widgetUi
		
		for i, v in pairs(widgetFrame:GetChildren()) do
			v:Clone().Parent = widgetMainFrame
		end

		uiConnections[#uiConnections + 1] = widgetMainFrame.MouseEnter:Connect(function()
			script.Parent:WaitForChild("mouseEnter"):Fire()
		end)

		uiConnections[#uiConnections + 1] = widgetMainFrame.MouseLeave:Connect(function()
			script.Parent:WaitForChild("mouseLeave"):Fire()
		end)
		
		local signaturesButton = widgetMainFrame:WaitForChild("signatures")
		uiConnections[#uiConnections + 1] = signaturesButton.Activated:Connect(function()
			selectTabButton(signaturesButton)
		end)
		
		local trackedScriptsButton = widgetMainFrame:WaitForChild("trackedScripts")
		uiConnections[#uiConnections + 1] = trackedScriptsButton.Activated:Connect(function()
			selectTabButton(trackedScriptsButton)
		end)
		
		initialized = true
		
		local tabScrollingFrame = widgetMainFrame:WaitForChild("tabScrollingFrame")
		uiConnections[#uiConnections + 1] = 
			widgetMainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			
			local tabFrame = tabScrollingFrame:WaitForChild(currentSelectedTabName)
			local tabXPos = tabFrame.Position.X.Scale * 
				tabScrollingFrame.CanvasSize.X.Scale * 
				tabScrollingFrame.AbsoluteWindowSize.X
			
			tabScrollingFrame.CanvasPosition = Vector2.new(tabXPos, 0)
		end)
		
		signaturesTabHandler.init(tabScrollingFrame:WaitForChild("signatures"))
		addedScriptsTabHandler.init(tabScrollingFrame:WaitForChild("trackedScripts"))
		setColors()

		scriptTracker.init()
	end
end

function module.show()
	widgetUi.Enabled = true
end

function module.hide()
	if initialized and widgetUi then
		widgetUi.Enabled = false
	end
end

function module.destroy()
	if initialized then
		initialized = false
		
		for i, connection in pairs(uiConnections) do
			connection:Disconnect()
			uiConnections[i] = nil
		end
		uiConnections = nil

		scriptTracker.destroy()
		
		signaturesTabHandler.destroy()
		addedScriptsTabHandler.destroy()
		
		widgetUi:Destroy()
		widgetUi = nil
		widgetMainFrame = nil
	end
end

return module
