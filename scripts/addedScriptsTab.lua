local module = {}

local scriptTracker = script.Parent:WaitForChild("scriptTracker")
local scriptAddedEvent = scriptTracker:WaitForChild("scriptAdded")
local scriptRemovedEvent = scriptTracker:WaitForChild("scriptRemoved")
local scriptPropertyChanged = scriptTracker:WaitForChild("scriptPropertyChanged")
scriptTracker = require(scriptTracker)
local selectionService = game:GetService("Selection")
local tweenService = game:GetService("TweenService")

local currentAddedScriptsFrame
local uiConnections = nil

local function setAddedScriptFrameColors(addedScriptFrame)
	local fontColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	local mainBackgroundColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
	
	local scriptNameLabel = addedScriptFrame:WaitForChild("scriptName")
	local scriptPathLabel = addedScriptFrame:WaitForChild("scriptPath")
	local removeButton = addedScriptFrame:WaitForChild("remove") 

	removeButton.BackgroundColor3 = mainBackgroundColor
	scriptNameLabel.TextColor3 = fontColor
	scriptPathLabel.TextColor3 = fontColor
end

function module.updateColors()
	if currentAddedScriptsFrame then
		local inputFieldBackgroundColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground)
		local mainBackgroundColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
		local scrollBarColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.ScrollBar)
		local borderColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Border)
		local fontColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
		local buttonColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.ButtonText)
		local dimmedFontColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.DimmedText)
		local isDarkMode = (mainBackgroundColor.r + mainBackgroundColor.g + mainBackgroundColor.b) > 1.5
		
		local menuFrame = currentAddedScriptsFrame:WaitForChild("menuFrame")
		
		local addedScriptsFrame = currentAddedScriptsFrame:WaitForChild("addedScripts")
		for i, v in pairs(addedScriptsFrame:GetChildren()) do
			if v:IsA("Frame") then
				setAddedScriptFrameColors(v)
			end
		end
	end
end

function module.init(addedScriptsFrame)
	currentAddedScriptsFrame = addedScriptsFrame

	local menuFrame = currentAddedScriptsFrame:WaitForChild("menuFrame")
	local removeAllButton = menuFrame:WaitForChild("removeAll")
	local addScriptsButton = menuFrame:WaitForChild("addScripts")
	
	uiConnections = {}

	uiConnections[#uiConnections + 1] = selectionService.SelectionChanged:Connect(function()
		local selectedInstances = selectionService:Get()
		local numValidScripts = 0
		
		for i, inst in pairs(selectedInstances) do
			if inst:IsA("ModuleScript") and not scriptTracker.isScriptTracked(inst) then
				numValidScripts += 1
			end
		end

		addScriptsButton.Text = "Add " .. numValidScripts .. " selected script(s)"
	end)
	
	uiConnections[#uiConnections + 1] = addScriptsButton.Activated:Connect(function()
		local selectedInstances = selectionService:Get()

		for i, inst in pairs(selectedInstances) do
			if inst:IsA("ModuleScript") and not scriptTracker.isScriptTracked(inst) then
				scriptTracker.trackScript(inst)
			end
		end
	end)

	uiConnections[#uiConnections + 1] = removeAllButton.Activated:Connect(function()
		scriptTracker.removeAllScripts()
	end)
end


local function updateLayoutOrders()
	local addedScriptsFrame = currentAddedScriptsFrame:WaitForChild("addedScripts")
	for i, v in pairs(addedScriptsFrame:GetChildren()) do
		if v:IsA("Frame") then
			local scriptReference = v:WaitForChild("scriptReference").Value
			if scriptReference and scriptTracker.isScriptTracked(scriptReference) then
				v.LayoutOrder = scriptTracker.getScriptLayoutOrder(scriptReference)
			end
		end
	end
end

local function playScriptAddedEffect(scriptFrame)
	local tweenInfo = TweenInfo.new(.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0)

	local tweenTable = {
		["BackgroundTransparency"]=1
	}

	local tween = tweenService:Create(scriptFrame, tweenInfo, tweenTable)
	tween:Play()
end

local function adjustMainFrameSize()
	local addedScriptsFrame = currentAddedScriptsFrame:WaitForChild("addedScripts")
	local mainLayoutManager = addedScriptsFrame:WaitForChild("UIListLayout")
	addedScriptsFrame.CanvasSize = UDim2.new(0, 0, 0, mainLayoutManager.AbsoluteContentSize.Y + 50)
end

scriptAddedEvent.Event:Connect(function(addedScript)
	assert(currentAddedScriptsFrame, "Can not add a script with no current plugin ui!")
	
	local scriptConnections = {}

	local addedScriptsFrame = currentAddedScriptsFrame:WaitForChild("addedScripts")
	local template = addedScriptsFrame:WaitForChild("template")
	local thisScriptFrame = template:Clone()
	local removeButton = thisScriptFrame:WaitForChild("remove")
	local scriptNameLabel = thisScriptFrame:WaitForChild("scriptName")
	local pathButton = thisScriptFrame:WaitForChild("scriptPath")
	local scriptReferenceValue = thisScriptFrame:WaitForChild("scriptReference")

	scriptReferenceValue.Value = addedScript
	scriptNameLabel.Text = addedScript.Name
	pathButton.Text = scriptTracker.getScriptPath(addedScript)
	
	scriptConnections[#scriptConnections + 1] = pathButton.Activated:Connect(function()
		selectionService:Set({addedScript})
	end)
	
	scriptConnections[#scriptConnections + 1] = removeButton.Activated:Connect(function()
		scriptTracker.removeScript(addedScript)
	end)
	
	scriptConnections[#scriptConnections + 1] = scriptRemovedEvent.Event:Connect(function(s)
		if addedScript == s then
			for i, connection in pairs(scriptConnections) do
				connection:Disconnect()
				scriptConnections[i] = nil
			end
			scriptConnections = nil

			thisScriptFrame:Destroy()
			updateLayoutOrders()

			adjustMainFrameSize()
		end
	end)

	scriptConnections[#scriptConnections + 1] = scriptPropertyChanged.Event:Connect(function(s)
		if s == addedScript then
			scriptNameLabel.Text = addedScript.Name
			pathButton.Text = scriptTracker.getScriptPath(addedScript)

			updateLayoutOrders()
		end
	end)
	
	thisScriptFrame.Name = addedScript.Name
	thisScriptFrame.BackgroundTransparency = 0
	thisScriptFrame.Parent = addedScriptsFrame
	updateLayoutOrders()
	thisScriptFrame.Visible = true
	playScriptAddedEffect(thisScriptFrame)

	adjustMainFrameSize()
end)

function module.destroy()
	for i, connection in pairs(uiConnections) do
		connection:Disconnect()
		uiConnections[i] = nil
	end
	uiConnections = nil
	
	currentAddedScriptsFrame:Destroy()
	currentAddedScriptsFrame = nil
end

return module
