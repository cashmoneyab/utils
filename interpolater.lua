local Interpolater = {}

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local types = loadstring(HttpService:GetAsync("https://raw.githubusercontent.com/cashmoneyab/utils/refs/heads/interpolater/types.lua"))()
local lerp = loadstring(HttpService:GetAsync("https://raw.githubusercontent.com/cashmoneyab/utils/refs/heads/interpolater/lerp.lua"))()

local task_cancel = task.cancel;
local task_defer = task.defer;
local Instance_new = Instance.new;

local pcall = pcall;
local typeof = typeof;
local pairs = pairs;
local pcall = pcall;
local assert = assert;
local setmetatable = setmetatable;

local function RunTween (object, time, properties, alphaData, cancel, uid, id, fps)
	local Threads = {}
	local finished = Instance_new('BindableEvent')
	local playing = Instance_new("BoolValue") 
	local speed = Instance_new("NumberValue") 
	local tweenOverwritten, ancestryChanged;
	
	local style = (alphaData and (alphaData["EasingStyle"] or alphaData[1]))
	local direction = (alphaData and (alphaData["EasingDirection"] or alphaData[2])) or Enum.EasingDirection.Out;

	if typeof(style) == "string" and Enum.EasingStyle[style] then style = Enum.EasingStyle[style] end;
	if typeof(style) == "string" and Enum.EasingDirection[direction] then direction = Enum.EasingDirection[direction] end;
	
	local function Stop(cancel, ...)
		tweenOverwritten:Disconnect()
		ancestryChanged:Disconnect()
		
		for i,v in pairs(Threads) do
			task_cancel(v[1])
			if cancel == true then object[v[3]] = v[2] end
			Threads[i] = nil;
		end
		finished:Fire(false, id, ...)
	end
	
	playing.Value = true;
	speed.Value = 1;
	object:SetAttribute("tween", uid)

	tweenOverwritten = object.AttributeChanged:Connect(function(str)
		if str == "tween" then
			Stop(cancel, true)
		end
	end)
	
	ancestryChanged = object.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			Stop(cancel, nil)
		end
	end)

	for property, value in pairs(properties) do
		local suc, originalValue = pcall(function() return object[property] end)
		if not suc then continue; end

		local type = typeof(originalValue)
		local lerpF = types[type]
		if lerpF then
			local i = #Threads + 1
			Threads[i] = {
				task_defer(function()
					lerp(lerpF, time, originalValue, value, function(updateValue)
							object[property] = updateValue;
						end, style, direction, playing, speed, fps)
					if i == 1 then
						finished:Fire(true, id)
					end
				end), 
				originalValue, property
			}
		end
	end

	return {Threads = Threads, Stop = function(...) return Stop(cancel, ...) end, Playing = playing, Finished = finished.Event, Speed = speed}
end

Interpolater.Playing = {}
Interpolater.properties_ = {}

function Interpolater : Play (time, properties, alphaData, startProperties, framesPerSecond, cancelWhenCompleted, id)
	if self.Enabled then
		local uid = self.UID;
		local object = self.Instance;
		local time = time or 1;
		local alphaData = alphaData or self.alphaData;
		local completed = self.completedEvent;
		local id = id or HttpService:GenerateGUID()
		local fps = framesPerSecond;
		local propertiesUsing = ""
		
		if object:GetAttribute("tween") ~= uid then self:Stop() end

		if startProperties and typeof(startProperties) == "table" then
			for property, value in pairs(startProperties) do
				local suc, originalValue = pcall(function() return object[property] end)
				if not suc then continue; end;
				
				if originalValue then
					if self.properties_[property] then self.properties_[property].Stop(true) end
					object[property] = value;
				end
			end
		end
		
		for property, value in pairs(properties) do
			local suc, originalValue = pcall(function() return object[property] end)
			if not suc then continue; end;

			if originalValue then
				if self.properties_[property] then
					self.properties_[property].Stop(true)
				end
				
				propertiesUsing = propertiesUsing .. property .. ";"
			end
		end

		local runningTween = RunTween(object, time, properties, alphaData, cancelWhenCompleted, uid, id, fps)
		
		for property in propertiesUsing:gmatch("(.-);") do
			self.properties_[property] = runningTween;
		end
		
		if Interpolater.Playing[id] then Interpolater.Playing[id].Stop() end
		
		runningTween.Speed.Value = self.Speed or 1;
		runningTween.Playing.Value = not self.Paused;
		runningTween.GetParameters = function() return {time, properties, alphaData, startProperties, id, cancelWhenCompleted} end;
		
		Interpolater.Playing[id] = runningTween;

		self.taskFinished = task_defer(function()
			self.stopFunc = runningTween.Stop;

			local complete, _, overWritten = runningTween.Finished:Wait()
			Interpolater.Playing[id] = nil;
			if complete then runningTween.Stop() end

			completed:Fire(complete, id, overWritten)
		end)

		return runningTween, id;
	end
end

function Interpolater : FromTweenInfo (tweenInfo, properties, startProperties, framesPerSecond, cancelWhenCompleted, id)
	if self.Enabled then
		local alphaData = {tweenInfo.EasingStyle, tweenInfo.EasingDirection}
		return self:Play(tweenInfo.Time, properties, alphaData, startProperties, framesPerSecond, cancelWhenCompleted, id)
	end
	return;
end

function Interpolater : Pos (alpha, properties, alphaData, startProperties)
	if self.Enabled then
		local alphaData = alphaData or self.alphaData;

		local style = (alphaData and (alphaData["EasingStyle"] or alphaData[1]))
		local direction = (alphaData and (alphaData["EasingDirection"] or alphaData[2])) or Enum.EasingDirection.Out; 

		if Enum.EasingStyle[style] then style = Enum.EasingStyle[style] end;
		if Enum.EasingDirection[direction] then style = Enum.EasingDirection[direction] end;

		local object = self.Instance;
		local alphaData = alphaData or self.alphaData;

		self:Stop(true, alpha)

		if style then
			alpha = TweenService:GetValue(alpha, style, direction)
		end

		if startProperties and typeof(startProperties) == "table" then
			for property, value in pairs(startProperties) do
				local suc, originalValue = pcall(function() return object[property] end)
				if not suc then continue end;
				
				if originalValue then
					object[property] = value;
				end
			end
		end

		for property, value in pairs(properties) do
			local suc, originalValue = pcall(function() return object[property] end)
			if not suc then continue end;

			local type = typeof(originalValue)
			local lerpF = types[type]

			object[property] = lerpF(alpha, originalValue, value)
		end
		return alpha;
	end
	return;
end

function Interpolater : Pause ()
	for i,v in pairs(self.Playing) do
		v.Playing.Value = false;
	end
	
	self.Paused = true;
	return self;
end

function Interpolater : Resume ()
	for i,v in pairs(self.Playing) do
		v.Playing.Value = true;
	end
	
	self.Paused = true;
	return self;
end

function Interpolater : Stop ()
	if self.Instance then self.Instance:SetAttribute("tween", nil) end
	if not self.stopFunc then return self; end

	if self.taskFinished then
		task_cancel(self.taskFinished)
		self.taskFinished = nil;
	end

	self.stopFunc()
	return self;
end

function Interpolater : Cancel ()
	if self.Instance then self.Instance:SetAttribute("tween", nil) end
	if not self.stopFunc then return self; end

	if self.taskFinished then
		task_cancel(self.taskFinished)
		self.taskFinished = nil;
	end

	self.stopFunc(true)
	return self;
end

function Interpolater : ChangeSpeed (speed)
	for i,v in pairs(self.Playing) do
		v.Speed.Value = speed;
	end
	
	self.Speed = speed;
	return self;
end

function Interpolater : Setup (Object, alphaData)
	self.Instance = Object;
	self.alphaData = alphaData;
	self.completedEvent = Instance_new("BindableEvent")
	self.Completed = self.completedEvent.Event;
	self.UID = HttpService:GenerateGUID()
	self.Enabled = true;
	self.Paused = false;
	self.Speed = 1;
end

function Interpolater : new (Object, alphaData)
	assert(typeof(Object) == "Instance", "Object must be an Instance!")
	local tween = setmetatable(Interpolater, {})
	tween:Setup(Object, alphaData)
	return tween;
end

function Interpolater : Create (Object, TweenInfo, Properties, StartProperties, framesPerSecond, cancelWhenCompleted, id)
	assert(typeof(Object) == "Instance", "Object must be an Instance!")
	local tween = setmetatable(Interpolater, {})
	
	tween:Setup(Object);
	return tween:FromTweenInfo(TweenInfo, Properties, StartProperties, framesPerSecond, cancelWhenCompleted, id);
end

return Interpolater;
