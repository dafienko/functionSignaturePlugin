local module = {}

local scriptTracker = script.Parent:WaitForChild("scriptTracker")
local scriptAddedEvent = scriptTracker:WaitForChild("scriptAdded")
local scriptRemovedEvent = scriptTracker:WaitForChild("scriptRemoved")
local scriptPropertyChanged = scriptTracker:WaitForChild("scriptPropertyChanged")
scriptTracker = require(scriptTracker)
local util = require(script.Parent.Parent:WaitForChild("util"))
local moduleScriptAnalyzer = require(script:WaitForChild("moduleScriptAnalyzer"))
local selectionService = game:GetService("Selection")

local uiConnections = nil
local currentSignaturesTabFrame
local searchBar

local function setSignatureTextColor(functionFrame)
	local fontColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	
	local textLabel = functionFrame:WaitForChild("TextLabel")
	textLabel.TextColor3 = fontColor
end

local function setSignatureFrameColor(sigFrame)
	local mainBackgroundColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
	local fontColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	local borderColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Border)
	local buttonColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.ButtonText)
	
	local functionsFrame = sigFrame:WaitForChild("functions")
	functionsFrame.BackgroundColor3 = mainBackgroundColor
	functionsFrame.BorderColor3 = borderColor
	for i, v in pairs(functionsFrame:GetChildren()) do
		if v:IsA("Frame") then
			setSignatureTextColor(v)
		end
	end
	
	local headerFrame = sigFrame:WaitForChild("header")
	local expandButton = headerFrame:WaitForChild("expand")
	local refreshButton = headerFrame:WaitForChild("refreshButton")
	local scriptNameLabel = headerFrame:WaitForChild("scriptName")
	
	expandButton.ImageColor3 = buttonColor
	refreshButton.ImageColor3 = buttonColor
	refreshButton.BackgroundColor3 = mainBackgroundColor
	scriptNameLabel.TextColor3 = fontColor
end

function module.updateColors()
	if currentSignaturesTabFrame then
		local inputFieldBackgroundColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground)
		local mainBackgroundColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
		local scrollBarColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.ScrollBar)
		local borderColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Border)
		local fontColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
		local buttonColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.ButtonText)
		local dimmedFontColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.DimmedText)
		local isDarkMode = (mainBackgroundColor.r + mainBackgroundColor.g + mainBackgroundColor.b) > 1.5
		
		local menuFrame = currentSignaturesTabFrame:WaitForChild("menuFrame")
		local searchFrame = menuFrame:WaitForChild("searchFrame")
		local searchTextBox = searchFrame:WaitForChild("TextBox")
		local addButton = menuFrame:WaitForChild("addButton")
		
		searchTextBox.BorderColor3 = borderColor
		searchTextBox.BackgroundColor3 = inputFieldBackgroundColor
		searchTextBox.TextColor3 = fontColor
		searchTextBox.PlaceholderColor3 = dimmedFontColor
		addButton.TextColor3 = buttonColor
		
		local addedScripts = currentSignaturesTabFrame:WaitForChild("addedScripts")
		for i, v in pairs(addedScripts:GetChildren()) do
			if v:IsA("Frame") then
				setSignatureFrameColor(v)
			end
		end
		addedScripts.ScrollBarImageColor3 = scrollBarColor
		
		local emptyTextLabel = currentSignaturesTabFrame:WaitForChild("emptyText")
		emptyTextLabel.TextColor3 = dimmedFontColor
	end
end

local function updateSearchFilter(filterStr)
	if currentSignaturesTabFrame then
		local addedScriptsFrame = currentSignaturesTabFrame:WaitForChild("addedScripts")
		local template = addedScriptsFrame:WaitForChild("scriptSignatureTemplate")

		if not filterStr or filterStr == "" then -- filter bar is empty
			for i, v in pairs(addedScriptsFrame:GetChildren()) do
				if v:IsA("Frame") and v ~= template then
					v.Visible = true
				end
			end
		else
			for i, v in pairs(addedScriptsFrame:GetChildren()) do
				if v:IsA("Frame") and v ~= template then
					v.Visible = string.find(v.Name, filterStr)
				end
			end
		end
	end
end


local function updateLayoutOrders()
	local addedScriptsFrame = currentSignaturesTabFrame:WaitForChild("addedScripts")
	for i, v in pairs(addedScriptsFrame:GetChildren()) do
		if v:IsA("Frame") then
			local scriptReference = v:WaitForChild("scriptReference").Value
			if scriptReference and scriptTracker.isScriptTracked(scriptReference) then
				v.LayoutOrder = scriptTracker.getScriptLayoutOrder(scriptReference)
			end
		end
	end
end

local function createModuleClone(original)
	local c = original:Clone()
	return c
end

local function updateScriptFrameFunctionSignatures(scriptFrame, s)
	local functionsFrame = scriptFrame:WaitForChild("functions")
	local signatureTemplate = functionsFrame:WaitForChild("signatureTemplate")
	for i, v in pairs(functionsFrame:GetChildren()) do
		if v:IsA("Frame") and v ~= signatureTemplate then
			v:Destroy()
		end
	end

	--local c = createModuleClone(s)
	local functionSignatures = moduleScriptAnalyzer.getModuleFunctionSignatures(s)
	--c:Destroy()
	--print("updating " .. s.Name .. " functions: Found " .. #functionSignatures .. " functions")
	for i, v in pairs(functionSignatures) do
		local signatureFrame = signatureTemplate:Clone()
		signatureFrame.Name = "functionSignature"
		signatureFrame.LayoutOrder = i

		local signatureTextLabel = signatureFrame:WaitForChild("TextLabel")
		signatureTextLabel.Text = v

		signatureFrame.Visible = true
		signatureFrame.Parent = functionsFrame
	end
end

local function adjustMainFrameSize()
	local addedScriptsFrame = currentSignaturesTabFrame:WaitForChild("addedScripts")
	local mainLayoutManager = addedScriptsFrame:WaitForChild("UIListLayout")
	addedScriptsFrame.CanvasSize = UDim2.new(0, 0, 0, mainLayoutManager.AbsoluteContentSize.Y + 50)
end

local function adjustScriptFrameSize(scriptFrame, showFunctions)
	local functionsFrame = scriptFrame:WaitForChild("functions")
	local headerHeight = functionsFrame.Position.Y.Offset
	--local signatureTemplate = functionsFrame:WaitForChild("signatureTemplate")
	local layoutManager = functionsFrame:WaitForChild("UIListLayout")
	--local numFunctions = #functionsFrame:GetChildren() - 2 -- subtract layout manager and template
	local signatureHeight = layoutManager.AbsoluteContentSize.Y

	functionsFrame.Size = UDim2.new(
		functionsFrame.Size.X.Scale,
		functionsFrame.Size.X.Offset,
		functionsFrame.Size.Y.Scale,
		signatureHeight
	)

	scriptFrame.Size = UDim2.new(
		scriptFrame.Size.X.Scale,
		scriptFrame.Size.X.Offset,
		scriptFrame.Size.Y.Scale,
		headerHeight + ((showFunctions and signatureHeight) or 0)
	)
	
	functionsFrame.Visible = showFunctions

	adjustMainFrameSize()
end

local function onScriptAdded(addedScript)
	local scriptConnections = {}

	local addedScriptsFrame = currentSignaturesTabFrame:WaitForChild("addedScripts")
	local scriptSignatureTemplate = addedScriptsFrame:WaitForChild("scriptSignatureTemplate")

	local thisScriptFrame = scriptSignatureTemplate:Clone()
	local headerFrame = thisScriptFrame:WaitForChild("header")
	local functionsFrame = thisScriptFrame:WaitForChild("functions")
	local refreshButton = headerFrame:WaitForChild("refreshButton")
	local expandButton = headerFrame:WaitForChild("expand")
	local scriptNameLabel = headerFrame:WaitForChild("scriptName")
	local scriptPathButton = headerFrame:WaitForChild("scriptPath")
	local scriptReferenceValue = thisScriptFrame:WaitForChild("scriptReference")
	
	local expanded = false
	
	thisScriptFrame.Name = addedScript.Name

	scriptReferenceValue.Value = addedScript
	scriptNameLabel.Text = addedScript.Name
	scriptPathButton.Text = scriptTracker.getScriptPath(addedScript)

	updateScriptFrameFunctionSignatures(thisScriptFrame, addedScript)

	scriptConnections[#scriptConnections + 1] = expandButton.Activated:Connect(function()
		expanded = not expanded 

		expandButton.Rotation = (expanded and 0) or -90
		adjustScriptFrameSize(thisScriptFrame, expanded)
		functionsFrame.Visible = expanded
	end)
	
	scriptConnections[#scriptConnections + 1] = refreshButton.Activated:Connect(function()
		updateScriptFrameFunctionSignatures(thisScriptFrame, addedScript)
		adjustScriptFrameSize(thisScriptFrame, expanded)
	end)
	
	scriptConnections[#scriptConnections + 1] = scriptPropertyChanged.Event:Connect(function(s)
		if s == addedScript then
			scriptNameLabel.Text = addedScript.Name
			scriptPathButton.Text = scriptTracker.getScriptPath(addedScript)

			updateLayoutOrders()
		end
	end)
	
	scriptConnections[#scriptConnections + 1] = scriptRemovedEvent.Event:Connect(function(s)
		if addedScript == s then
			for i, connection in pairs(scriptConnections) do
				connection:Disconnect()
				scriptConnections[i] = nil
			end
			scriptConnections = nil

			thisScriptFrame:Destroy()

			adjustMainFrameSize()
		end
	end)

	scriptConnections[#scriptConnections + 1] = scriptPathButton.Activated:Connect(function()
		selectionService:Set({addedScript})
	end)
	
	thisScriptFrame.Parent = addedScriptsFrame
	updateLayoutOrders()
	thisScriptFrame.Visible = true
	adjustScriptFrameSize(thisScriptFrame, expanded)
end

function module.init(signaturesTabFrame)
	currentSignaturesTabFrame = signaturesTabFrame

	uiConnections = {}
	
	local menuFrame = currentSignaturesTabFrame:WaitForChild("menuFrame")
	local searchFrame = menuFrame:WaitForChild("searchFrame")
	local searchTextBox = searchFrame:WaitForChild("TextBox")
	local addButton = menuFrame:WaitForChild("addButton")
	
	uiConnections[#uiConnections + 1] = searchTextBox:GetPropertyChangedSignal("Text"):Connect(function()
		updateSearchFilter(searchTextBox.Text)
	end)

	local addedScriptsFrame = currentSignaturesTabFrame:WaitForChild("addedScripts")
	local scriptSignatureTemplate = addedScriptsFrame:WaitForChild("scriptSignatureTemplate")

	uiConnections[#uiConnections + 1] = scriptAddedEvent.Event:Connect(function(s)
		onScriptAdded(s)
	end)
end



function module.destroy()
	for i, connection in pairs(uiConnections) do
		connection:Disconnect()
		uiConnections[i] = nil
	end
	uiConnections = nil


	
	currentSignaturesTabFrame:Destroy()
end


return module

































