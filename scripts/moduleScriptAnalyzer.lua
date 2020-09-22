local module = {}

function module.getModuleFunctionSignatures(moduleScript)
	local signatures = {}
	local moduleSource = moduleScript.Source
	
	for functionName, f in pairs(module) do
		if type(f) == "function" then
			local i, j = string.find(moduleSource, functionName .. " *= *function *%([^%)]*%)")
			if not (i and j) then
				i, j = string.find(moduleSource, functionName .. " *%([^%)]+%)")
			end
			if not (i and j) then
				i, j = string.find(moduleSource, "%[\"" .. functionName .. "\"%] *= *function%([^%)]*%)")
			end
			
			if i and j then
				local sigStr = string.sub(moduleSource, i, j)
				local i2, j2 = string.find(sigStr, "%([^%)]*%)")
				local parameters = string.sub(sigStr, i2, j2)
				
				signatures[#signatures + 1] = functionName .. parameters
			else
				signatures[#signatures + 1] = functionName .. "( ? )"
			end
		end	
	end

	table.sort(signatures, nil)
	
	return signatures
end

local function getTextLines(str)
	local lastNewline = -1
	local lines = {}
	for i = 1, string.len(str) do
		local c = string.sub(str, i, i)
		if c == '\n' then
			lines[#lines + 1] = string.sub(str, lastNewline + 1, i)
			lastNewline = i
		end
	end

	lines[#lines + 1] = string.sub(str, lastNewline + 1, string.len(str))

	return lines
end

local function findLastReturn(str)
	local lines = getTextLines(str)

	for i = #lines, 1, -1 do
		local line = lines[i]
		local j, k = string.find(line, "return *[%S]+")
		if j and k then
			local statement = string.sub(line, j, k)
			return statement
		end
	end
end

local function getModuleName(src)
	local moduleReturnStatement = findLastReturn(src)
	if moduleReturnStatement then
		local j, k = string.find(moduleReturnStatement, "[%S]+$")
		if j and k then
			return string.sub(moduleReturnStatement, j, k)
		end
	end
end

function module.getModuleFunctionSignatures(s)
	local src = s.Source
	local moduleName = getModuleName(src)

	local t = {}

	--suntax: module.functionName = function(args)
	local pattern1 = moduleName .. "%.%S+ *= *function *%([^%)]*%)"
	for match in string.gmatch(src, pattern1) do
		local i, j = string.find(match, "%.%S+")
		local y, z = string.find(match, "%(.*%)")

		local functionName = string.sub(match, i + 1, j)
		local arguments = string.sub(match, y, z)
		t[#t + 1] = "." .. functionName .. arguments
	end

	--suntax: function = module.functionName(args)
	local pattern2 = "function *" .. moduleName .. "[%.|:]%S+ *%([^%)]*%)"
	for match in string.gmatch(src, pattern2) do
		local i, j = string.find(match, "[%.|:][^%(]*")
		local y, z = string.find(match, "%(.*%)")

		local functionName = string.sub(match, i, j)
		local arguments = string.sub(match, y, z)
		t[#t + 1] = functionName .. arguments
	end

	--suntax: module["functionName"] = function(args)
	local pattern3 = moduleName .. "%[\"%S+%\"] *= *function *%([^%)]*%)"
	for match in string.gmatch(src, pattern3) do
		local i, j = string.find(match, "\"[^\"]+\"")
		local y, z = string.find(match, "%(.*%)")

		local functionName = string.sub(match, i + 1, j - 1)
		local arguments = string.sub(match, y, z)
		t[#t + 1] = "." .. functionName .. arguments
	end

	table.sort(t, nil)

	return t
end

return module
