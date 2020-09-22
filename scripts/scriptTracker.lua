local module = {}

local trackedScripts = {} -- table of actual script objects this module is currently analyzing
local scriptData = {} -- table used for sorting scripts

function module.getTrackedScripts()
	return trackedScripts
end

function module.isScriptTracked(s: Instance)
	return table.find(trackedScripts, s)
end

local function getScriptPath(s: Instance)
	local path = s.Name
	s = s.Parent
	
	while s ~= game do
		path = s.Name .. "\\" .. path
		s = s.Parent
	end

	return path
end

local function compFunction(a, b)
	return a.name < b.name
end

local function updateScriptDataTable()
	table.sort(scriptData, compFunction)
end

local function updateScriptData(s)
	for i, data in pairs(scriptData) do
		if data.script == s then
			scriptData[i] = {
				["name"] = s.Name,
				["script"] = s,
				["path"] = getScriptPath(s)	
			}

			updateScriptDataTable()
			
			return
		end
	end
end

function module.trackScript(s: Instance)
	assert(not module.isScriptTracked(s), "Script is already tracked!")
	
	local connections = {}

	connections[#connections + 1] = s:GetPropertyChangedSignal("Name"):Connect(function()
		updateScriptData(s)
		
		script:WaitForChild("scriptPropertyChanged"):Fire(s)
	end)
	
	connections[#connections + 1] = s:GetPropertyChangedSignal("Parent"):Connect(function()
		if not s.Parent then
			for i, connection in pairs(connections) do
				connection:Disconnect()
				connections[i] = nil
			end
			connections = nil
			
			module.removeScript(s)
		else
			updateScriptData(s)
			
			script:WaitForChild("scriptPropertyChanged"):Fire(s)
		end
	end)

	local thisScriptData = {
		["name"] = s.Name,
		["script"] = s,
		["path"] = getScriptPath(s)
	}

	trackedScripts[#trackedScripts + 1] = s
	scriptData[#scriptData + 1] = thisScriptData
	
	updateScriptDataTable()
	
	script:WaitForChild("scriptAdded"):Fire(s)
end

function module.removeScript(s: Instance) 
	for i, data in pairs(scriptData) do
		if data.script == s then
			table.remove(scriptData, i)
		end
	end

	for i, sc in pairs(trackedScripts) do
		if sc == s then
			table.remove(trackedScripts, i)
		end
	end
	
	updateScriptDataTable()
	
	script:WaitForChild("scriptRemoved"):Fire(s)
end

function module.removeAllScripts()
	while #trackedScripts > 0 do
		module.removeScript(trackedScripts[1])
		wait()
	end
end

function module.getScriptPath(s)
	for i, data in pairs(scriptData) do
		if data.script == s then
			return data.path
		end
	end
	
	warn("could not find script " .. tostring(s))
end

function module.getScriptLayoutOrder(s)
	for i, data in pairs(scriptData) do
		if data.script == s then
			return i
		end
	end

	warn("could not find script " .. tostring(s))
end

function module.init()
	local serverStorage = game:GetService("ServerStorage")
	local scriptsDump = serverStorage:FindFirstChild("trackedScripts")

	if scriptsDump then
		for i, v in pairs(scriptsDump:GetChildren()) do
			if v:IsA("ObjectValue") and v.Value and v.Value:IsA("ModuleScript") then
				module.trackScript(v.Value)
			end
		end
	end
end

function module.destroy() -- cache currently tracked scripts so user doesn't have to re-track them every time the load up place
	local serverStorage = game:GetService("ServerStorage")
	local scriptsDump = serverStorage:FindFirstChild("trackedScripts") or Instance.new("Folder")
	if scriptsDump.Parent ~= serverStorage then
		scriptsDump.Name = "trackedScripts"
		scriptsDump.Parent = serverStorage
	end

	scriptsDump:ClearAllChildren()

	for i, s in pairs(trackedScripts) do
		if s then
			local referenceValue = Instance.new("ObjectValue")
			referenceValue.Value = s
			referenceValue.Name = s.Name
			referenceValue.Parent = scriptsDump
		end
	end
end




return module
