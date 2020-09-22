local serverScriptService = game:GetService("ServerScriptService")
local functionSignatureWidgetHandler = require(script:WaitForChild("functionSignatureWidgetHandler"))
local mouse = plugin:GetMouse()
local runService = game:GetService("RunService")

local toolbar = plugin:CreateToolbar("Module Script Analyzer")

local functionSignaturesButton = toolbar:CreateButton("Function Signatures", "Toggle Function Signatures Widget", "http://www.roblox.com/asset/?id=5706845513")
functionSignaturesButton.ClickableWhenViewportHidden = true

local functionSignaturesActive = false

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,  -- Widget will be initialized in floating panel
	false,   -- Widget will be initially enabled
	false,  -- Don't override the previous enabled state
	300,    -- Default width of the floating window
	300,    -- Default height of the floating window
	280,    -- Minimum width of the floating window
	150     -- Minimum height of the floating window
)

local functionSignatureWidgetUi = plugin:CreateDockWidgetPluginGui("FunctionSignatures", widgetInfo)
functionSignatureWidgetUi.Title = "Function Signatures"
functionSignatureWidgetHandler.init(functionSignatureWidgetUi)
functionSignatureWidgetHandler.hide()

local pluginConnections = {}

local mouseInFrame = false
pluginConnections[#pluginConnections + 1] = script:WaitForChild("mouseEnter").Event:Connect(function()
	mouseInFrame = true
	plugin:Activate(true)
end)

pluginConnections[#pluginConnections + 1] = script:WaitForChild("mouseLeave").Event:Connect(function()
	mouseInFrame = false
	plugin:Deactivate()
end)

pluginConnections[#pluginConnections + 1] = runService.RenderStepped:Connect(function(dt)
	if mouseInFrame then
		mouse.Icon = "rbxasset://SystemCursors/Arrow"
	end
end)

pluginConnections[#pluginConnections + 1] = functionSignaturesButton.Click:Connect(function()
	functionSignaturesActive = not functionSignaturesActive
	
	if functionSignaturesActive then
		functionSignatureWidgetHandler.show()
	else
		functionSignatureWidgetHandler.hide()
	end
end)

plugin.Unloading:Connect(function()
	for i, connection in pairs(pluginConnections) do
		connection:Disconnect()
		pluginConnections[i] = nil
	end
	pluginConnections = nil
	
	functionSignatureWidgetHandler.destroy()
end)