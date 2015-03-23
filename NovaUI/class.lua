
local class = {}

function class.new( name )
	local c = setmetatable( { name = name, typeOf = class.typeOf }, { __type = "Class" } )

	function c:new( ... )
		local o = setmetatable( {}, { __index = self, __type = name } )
		if o[name] then
			o[name]( o, ... )
		end
		return o
	end

	function c:extends( c )
		setmetatable( self, { __index = c, __type = "Class" } )
		self.extend = c
	end

	return c
end

local function typep( v )
	local t = type( v )
	pcall( function()
		t = getmetatable( v ).__type or t
	end )
	return t
end

function class.typeOf( ob, ... )
	if #arg == 1 then
		if typep( ob ) == arg[1] then return true end
		if type( arg[1] ) == "table" then
			if typep( ob ) == arg[1].name then
				return true
			end
			if type( ob ) == "table" then
				while ob.extend do
					if ob.extend.name == arg[1].name then
						return true
					end
					ob = ob.extend
				end
			end
		end
		return false
	else
		for i = 1, #arg do
			if class.typeOf( ob, arg[i] ) then
				return arg[i]
			end
		end
	end
end

return class
