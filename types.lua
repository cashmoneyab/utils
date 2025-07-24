local lerpFunctions = {};

function lerpFunctions.number(alpha, x, y)
	return x + (y - x) * alpha;
end

function lerpFunctions.string(alpha, _, x)
	return x:sub(0, math.floor(x:len() * alpha))
end

function lerpFunctions.CFrame(alpha, c, c2)
	return c:Lerp(c2, alpha);
end

function lerpFunctions.Vector3(alpha, c, c2)
	return c:Lerp(c2, alpha)
end

function lerpFunctions.Vector2(alpha, c, c2)
	return c:Lerp(c2, alpha)
end

function lerpFunctions.UDim2(alpha, c : UDim2, c2 : UDim2)
	local lerp = lerpFunctions.number;
	return 
		UDim2.new(
			lerp(alpha, c.X.Scale, c2.X.Scale), 
			lerp(alpha, c.X.Offset, c2.X.Offset),

			lerp(alpha, c.Y.Scale, c2.Y.Scale), 
			lerp(alpha, c.Y.Offset, c2.Y.Offset)
		);
end

function lerpFunctions.UDim(alpha, c : UDim, c2 : UDim)
	local lerp = lerpFunctions.number;
	return 
		UDim.new(
			lerp(alpha, c.Scale, c2.Scale), 
			lerp(alpha, c.Offset, c2.Offset)
		);
end

function lerpFunctions.Color3(alpha, c : Color3, c2 : Color3)
	local lerp = lerpFunctions.number;
	return 
		Color3.new(
			lerp(alpha, c.R, c2.R), 
			lerp(alpha, c.G, c2.G), 
			lerp(alpha, c.B, c2.B)
	);
end

return lerpFunctions
