--[[
lerp.lua
the function that interpolates
]]--

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local task_wait = task.wait;
local os_clock = os.clock;
local math_min = math.min;
local math_floor = math.floor;
local typeof = typeof;

local stepped = (RunService:IsClient() and function() return RunService.RenderStepped:Wait() end) or task_wait;

local function getDelta()
	return stepped();
end

return function(lerpFunction, duration, from, to, update, easingStyle, easingDirection, activeFlag, speedFactor, targetFrameRate)
	local elasped = 0;
	local alpha;
	local frameRate = targetFrameRate and (1 / targetFrameRate)
	local isDynamic = typeof(to) == "function";
	local dynamicTo = if isDynamic then to else nil;
	
	repeat
		if activeFlag.Value == false then task_wait() continue end;
		if isDynamic then to = dynamicTo(alpha); end
		
		if elasped == 0 then
			update(lerpFunction(0, from, to));
		end

		local delta = getDelta() * speedFactor.Value;
		
		elasped += delta 
		alpha = math_min(elasped, duration) / duration;
		
		if alpha == 1 then break; end
		
		if easingStyle then
			alpha = TweenService:GetValue(alpha, easingStyle, easingDirection);
		end
		
		if frameRate then
			update(lerpFunction(math_floor(alpha / frameRate) * frameRate, from, to));
			continue;
		end
		
		update(lerpFunction(alpha, from, to));
	until elasped >= duration;

	update(lerpFunction(1, from, to));
end
