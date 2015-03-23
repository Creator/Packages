
local _t = type
local function type( ob )
	local t = _t( ob )
	pcall( function()
		local mt = getmetatable( ob )
		t = _t( mt.__type ) == "string" and mt.__type or t
	end )
	return t
end

return function( values, types )
	for k, v in pairs( types ) do
		if type( v ) == "table" then
			local ok = false
			for i = 1, #v do
				if type( values[k] ) == v[i] then
					ok = true
					break
				end
			end
			if not ok then
				error( "expected <" .. v[1] .. "> " .. k .. ", got " .. type( values[k] ), 3 )
			end
		else
			if type( values[k] ) ~= v then
				error( "expected <" .. v .. "> " .. k .. ", got " .. type( values[k] ), 3 )
			end
		end
	end
end
