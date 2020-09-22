-- this script contains various "utility" functions for use in other script
-- this script contains no external dependences

local chatService = game:GetService("Chat")
local players = game:GetService("Players")

local module = {}

function module.numLerp(a, b, alpha)
	return (1 - alpha) * a + b * alpha
end
	
-- clones a table (rather than just assigning a variable to a reference of the same table)
module.cloneTable = function(t)
	local c = {}
	
	for i, v in pairs(t) do
		if type(v) == "table" then
			c[i] = module.cloneTable(v)
		else
			c[i] = v
		end
	end
	
	return c
end

module.p_assert = function(condition, issue: string) -- like assert, just doesn't throw an error on fail. "Protected" assert
	if not condition then
		warn(issue)
	end
	
	return condition
end

--[[
parent1
	child1
		child2
			child3
				child4

module.GetClosestParentOf(child4, parent1) would return child1
]]
module.getClosestParentOf = function(childInstance, parentInstance)
	while childInstance.Parent and childInstance.Parent ~= game do
		if childInstance.Parent == parentInstance then
			return childInstance
		end
		childInstance = childInstance.Parent
	end
	
	return nil
end

module.playerIsInGame = function(player)
	return player and players:FindFirstChild(player.Name) 
end

module.hasProperty = function(instance, property)
	local success, err = pcall(function()
		local p = instance[property]
	end)
	return success
end

function module.printRect(rect)
	print("{")
	print("\ttop:" .. rect.top)
	print("\tleft:" .. rect.left)
	print("\tbottom:" .. rect.bottom)
	print("\tright:" .. rect.right)
	print("}")
end

module.c3ToV3 = function(c3)
	return Vector3.new(c3.r, c3.g, c3.b)
end

module.v3ToC3 = function(v3)
	return Color3.new(
		math.clamp(v3.X, 0, 1),
		math.clamp(v3.Y, 0, 1),
		math.clamp(v3.Z, 0, 1))
end

module.mulColor = function(c3, factor)
	return module.v3ToC3(module.c3ToV3(c3) * factor)
end

module.addColorScalar = function(c3, s)
	return module.v3ToC3(module.c3ToV3(c3) + Vector3.new(s, s, s))
end

module.removeAllChildren = function(parent, ignore, preRemoveItem)
	ignore = ignore or {}
	
	for i, v in pairs(parent:GetChildren()) do
		if not table.find(ignore, v) then
			preRemoveItem(v)
			v:Destroy()
		end
	end
end

-- indices will be 1, 2, ... regardless of t1/t2 indices
module.combineArrays = function(t1, t2)
	local returnTable = {}
	
	for i, v in pairs(t1) do
		returnTable[#returnTable + 1] = v
	end
	
	for i, v in pairs(t2) do
		returnTable[#returnTable + 1] = v
	end
	
	return returnTable
end

module.tableLen = function(tbl)
	local len = 0
	
	for i, v in pairs(tbl) do
		len = len + 1
	end
	
	return len
end

module.roundToInt = function(float)
	local decimal = math.abs(float) - math.floor(math.abs(float))
	if decimal >= .5 then
		return math.ceil(math.abs(float)) * math.sign(float)
	else
		return math.floor(math.abs(float)) * math.sign(float)
	end
end

module.absFloor = function(float)
	return math.floor(math.abs(float)) * math.sign(float)
end

module.absCeil = function(float)
	return math.ceil(math.abs(float)) * math.sign(float)
end

module.formatNumberToString = function(number) -- takes a number and returns a string with the number formatted with commas and stuff
	number = math.floor(number * 100) / 100
	local sign = math.sign(number)
	number = math.abs(number)
	
	local s = tostring(number)
	local decimalIndex = nil
	for i = 1, #s do
		local c = string.sub(s, i, i)
		if c == "." then
			decimalIndex = i
			break
		end
	end
	local num = s
	local decimal = ""
	if decimalIndex then
		num = string.sub(s, 1, decimalIndex-1)
		decimal = string.sub(s, decimalIndex, #s)
	end
	
	local newNum = ""
	local count = 1
	for i = #num, 1, -1 do
		local c = string.sub(num, i, i)
		newNum = c .. newNum
		if (count % 3 == 0 and i ~= 1) then
			newNum = "," .. newNum
		end
		count = count + 1
	end
	
	if decimal ~= "" then
		for i = 1, 3 - #decimal do
			decimal = decimal .. "0"
		end
	end
	
	if sign == -1 then
		newNum = "-" .. newNum
	end
	
	return newNum .. decimal
end

module.formattedNumberStringToNumber = function(str)
	local noCommas = string.gsub(str, ",", "")
	return tonumber(noCommas)
end

module.getBaseParts = function(parent)
	local t = {}
	for i, v in pairs(parent:GetDescendants()) do
		if v:IsA("BasePart") then
			t[#t + 1] = v
		end
	end
	
	return t
end

module.formatSecondsToTimeString = function(seconds)
	local days = math.floor(seconds / (3600 * 24))
	seconds -= days * 3600 * 24
	
	local hours = math.floor(seconds / 3600)
	seconds -= hours * 3600
	
	local minutes = math.floor(seconds / 60)  
	seconds -= minutes * 60
	
	seconds = math.floor(seconds)
	
	local str = ""
	if days > 0 then
		str ..= " " .. days .. " day" 
		if days > 1 then
			str ..= "s"
		end
	end
	if hours > 0 then
		str ..= " " .. hours .. " hr"
		if hours > 1 then
			str ..= "s"
		end
	end
	if minutes > 0 then
		str ..= " " .. minutes .. " min"
		if minutes > 1 then
			str ..= "s"
		end
	end
	if seconds > 0 then
		str ..= " " .. seconds .. " sec"
	end
	
	return str
end

module.findParentNamed = function(child, parentName)
	while child ~= game and child ~= nil do
		if child.Parent then
			child = child.Parent 
			
			if child.Name == parentName then
				return child
			end
		else
			return nil
		end
	end
end


 -- no two instances in the src model can have the same name
function module.scaleSimilarModel(src, model, alpha) -- src and model most have an identical hierarchy
	local srcOrigin = src.PrimaryPart
	local mOrigin = model.PrimaryPart
	
	-- add corresponding parts in src/similar models to table
	local partTable = {}
	local function addToPartTable(srcParent, mParent)
		for i, srcPart in pairs(srcParent:GetChildren()) do
			local mPart = mParent:FindFirstChild(srcPart.Name)
			
			if srcPart:IsA("BasePart") then
				partTable[srcPart] = mPart
			end
			
			addToPartTable(srcPart, mPart)
		end
	end
	
	addToPartTable(src, model)
	
	
	for srcPart, mPart in pairs(partTable) do
		local srcOffset = srcOrigin.CFrame:ToObjectSpace(srcPart.CFrame)
		local srcPosition = srcOffset.Position
		local srcSize = srcPart.Size
		
		local newOffset = (srcOffset - srcPosition) + (srcPosition * alpha)
		local newSize = srcPart.Size * alpha
		
		mPart.CFrame = mOrigin.CFrame * newOffset
		mPart.Size = newSize
	end
end

function module.getScaleSimilarModelTable(src, model, alpha)
	local srcOrigin = src.PrimaryPart
	local mOrigin = model.PrimaryPart
	
	-- add corresponding parts in src/similar models to table
	local partTable = {}
	local function addToPartTable(srcParent, mParent)
		for i, srcPart in pairs(srcParent:GetChildren()) do
			local mPart = mParent:FindFirstChild(srcPart.Name)
			
			if srcPart:IsA("BasePart") then
				partTable[srcPart] = mPart
			end
			
			addToPartTable(srcPart, mPart)
		end
	end
	
	addToPartTable(src, model)
	
	local t = {}
	for srcPart, mPart in pairs(partTable) do
		local srcOffset = srcOrigin.CFrame:ToObjectSpace(srcPart.CFrame)
		local srcPosition = srcOffset.Position
		local srcSize = srcPart.Size
		
		local newOffset = (srcOffset - srcPosition) + (srcPosition * alpha)
		local newSize = srcPart.Size * alpha
		
		t[mPart].offsetCF = newOffset -- NOT THE SAME AS PLAIN CFRAME (offset from primary part instead)
		t[mPart].size = newSize
	end
	
	return t
end

function module.getTableString(t, tabLevel)
	if not tabLevel then
		tabLevel = 0
	end
	
	local s = ""
	
	local tabs = ""
	if tabLevel > 0 then
		tabs = string.rep('\t', tabLevel)
	end
	s = "{\n"
	
	local count = 1 -- i isn't an int, must use some other variable to track iteration number
	for i, v in pairs(t) do
		s ..= tabs .. "\t[\"".. tostring(i) .. "\"] = " 
		
		if type(v) == "table" then
			s ..= module.getTableString(v, tabLevel + 1)
		else
			if type(v) == "number" then
				s ..= tostring(v)
			else
				s ..= "\"" .. tostring(v) .. "\""
			end
		end
		
		if count < module.tableLen(t) then
			s ..= ",\n\n"
		else
			s ..= '\n'
		end
		count += 1
	end
	
	s ..= tabs .. "}"
	
	return s
end

function module.getModelHeight(model) -- assumes each part's most vertical axis is the Y-axis
	local mTop = nil
	local mBottom = nil 
	for i, v in pairs(model:GetChildren()) do
		if v:IsA("BasePart") then
			local y = v.Position.Y
			local height = v.Size.Y
			
			local pTop = (v.CFrame * CFrame.new(0, height / 2, 0)).Position.Y
			local pBottom = (v.CFrame * CFrame.new(0, -height / 2, 0)).Position.Y
			
			if not mTop then
				mTop = pTop
				mBottom = pBottom
			else
				mTop = math.max(mTop, pTop)
				mBottom = math.min(mBottom, pBottom)
			end
		end
	end
	
	mTop = mTop or 0
	mBottom = mBottom or 0
	
	return mTop - mBottom
end

function module.printFolderTable(folder) --
	local str = "{\n"
	for i, category in pairs(folder:GetChildren()) do
		str ..= "\t[\"" .. category.Name .. "\"]={\n"
		
		for j, model in pairs(category:GetChildren()) do
			str ..= "\t\t[\"" .. model.Name .. "\"]=\t10,\n"
		end
		
		str ..= "\t},"
		if i < #folder:GetChildren() then
			str ..= "\n\n"
		end
	end
	
	str ..= "\n}"
end

module.numDigitsI = function(int)
	local numDigits = 0
	
	repeat
		int = math.floor(int / 10)
		numDigits += 1
	until int == 0
	
	return numDigits
end


return module





































