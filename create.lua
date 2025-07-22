--!optimize 1
local Instance_new = Instance.new;
local string_format = string.format;

local tostring = tostring;
local warn = warn;
local pcall = pcall;
local pairs = pairs;
local error = error;
local typeof = typeof;
local ipairs = ipairs;

local function isType(val, type)
	local t = typeof(val)
	return t == type, t;
end

local function lookupify(t)
	local l = {}
	for i, v in pairs(t) do
		l[v] = i;
	end
	return l;
end

local forbidden = lookupify{"attributes", "Attributes"}

local function setAttributes(attributes, object)
	if not attributes then return end;
	
	for name, value in pairs(attributes) do
		local success = pcall(object.SetAttribute, object, name, value)
		if not success then
			warn(string_format("Invalid attribute, check the name or value if either one is supported : %s | %s", name, tostring(value), object.Name))
		end
	end
end

local function removeInstances(instanceName, parent)
	while parent:FindFirstChild(instanceName) do
		parent[instanceName]:Destroy()
	end

	return true;
end

local function setupObject(instanceData, object, parent)
	local nameFound;
	for key, val in ipairs(instanceData) do
		if isType(val, "Instance") and object.Parent == nil and object.Parent ~= val then
			object.Parent = val;
		elseif not nameFound and isType(val, "string") and object.ClassName ~= val then
			nameFound = true;
			object.Name = val;
		end
	end
end

local function addIntoDescendants(descendants, instance, order)
	if order == 1 then
		descendants[#descendants + 1] = instance;
	elseif descendants[instance.Name] then
		local index = 1;
		local key = instance.Name;

		repeat
			index += 1;
			key = string_format("%s#%s", instance.Name, index)
			if not descendants[key] then
				break
			end
		until false;

		descendants[key] = instance
	else
		descendants[instance.Name] = instance
	end	
end

local function setupInstance(instanceData)
	for _, val in pairs(instanceData) do
		local success, object = pcall(Instance_new, val)
		if success then
			return object
		end
	end
	error("Cannot create instance! You must add a valid Class!")
end

function CreateInstance(instanceData, listDescendants, parent)
	local object = setupInstance(instanceData)
	local descendants = {}

	if parent then object.Parent = parent; end;
	setupObject(instanceData, object, parent)

	local function setProp(property, value)
		if property == "Parent" and parent then return end;

		local propertyExists, typeof = pcall(function() return typeof(object[property]) end)
		if not propertyExists then return end;

		if isType(value, typeof) or typeof == "nil" then
			object[property] = value;
		else
			warn("Wrong value type!", value)
		end
	end

	local function createChild(instanceData)
		local instance, descendants2 = CreateInstance(instanceData, listDescendants, object)
		if not listDescendants then  return end

		addIntoDescendants(descendants, instance, listDescendants)

		for _, object in pairs(descendants2) do
			addIntoDescendants(descendants, object, listDescendants)
		end
	end

	for key, value in pairs(instanceData) do
		if forbidden[key] then continue end
		if typeof(value) == "table" then
			createChild(value)
		else
			setProp(key, value)
		end
	end

	if instanceData.attributes then
		setAttributes(instanceData.attributes, object)
	end

	return object, descendants;
end


return setmetatable({
	CreateInstance = CreateInstance,	
	RemoveInstances = removeInstances,
}, {__call = function(self, ...) return CreateInstance(...) end})

