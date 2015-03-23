
local error, tostring, assert, type, setmetatable, getmetatable, pcall = error, tostring, assert, type, setmetatable, getmetatable, pcall

local class = {}

function class.new( name )

	local object = {}
	local public = {}

	object.public = {}
	object.private = {}
	object.static = {}
	object.name = name
	object.extends = false
	object.class = public

	public.name = name

	local customindex = false
	local customnewindex = false
	local objectmeta = {}

	function public:new( ... )

		local ob = { }
		local pb = { }

		ob.class = public
		ob.public = pb

		setmetatable( ob, {
			__index = object.private;
		} )

		function pb:type( full )
			return ob.class:type( full )
		end

		function pb:typeOf( class )
			return ob.class:typeOf( class )
		end

		local obmeta = {}
		function obmeta.__index( _, k )
			if object.public[k] then
				if object.public[k].read then
					local val
					if customindex then
						if type( customindex ) == "function" then
							return customindex( ob, k )
						else
							return customindex[k]
						end
					elseif type( object.public[k].read ) == "function" then
						val = object.public[k].read( ob )
					elseif object.public[k].value ~= nil then
						val = object.public[k].value
					else
						val = ob[k]
					end
					if type( val ) == "function" then
						return function( self, ... )
							if self == pb then
								return val( ob, ... )
							end
							return val( self, ... )
						end
					end
					return val
				else
					error( "variable has no read access", 2 )
				end
			elseif customindex then
				if type( customindex ) == "function" then
					return customindex( ob, k )
				else
					return customindex[k]
				end
			else
				error( "no such variable \"" .. tostring( k ) .. "\"", 2 )
			end
		end;
		function obmeta.__newindex( _, k, v )
			if object.public[k] then
				if object.public[k].write then
					if customnewindex then
						if type( customnewindex ) == "function" then
							return customnewindex( ob, k, v )
						else
							customnewindex[k] = v
						end
					elseif type( object.public[k].write ) == "function" then
						object.public[k].write( ob, v )
					else
						ob[k] = v
					end
				else
					error( "variable has no write access", 2 )
				end
			else
				error( "no such variable \"" .. tostring( k ) .. "\"", 2 )
			end
		end;
		function obmeta.__tostring()
			return object.name
		end;
		obmeta.__metatable = { SwiftClassObject = true, __type = object.name }

		for k, v in pairs( objectmeta ) do
			obmeta["__" .. tostring( k )] = v
		end

		setmetatable( pb, obmeta )

		local c = object
		while true do
			if type( c.private[c.name] ) == "function" then
				return c.private[c.name]( ob, ... )
			end
			if c.extends then
				c = c.extends
			else
				break
			end
		end

		return pb
	end

	function public:type( full )
		local str = ""
		if full then
			local c = object.extends
			while c do
				str = c.name .. "." .. str
				c = c.extends
			end
		end
		return str .. object.name
	end

	function public:typeOf( other )
		if type( other ) == "table" then
			if pcall( function() assert( getmetatable( other ).SwiftClass ) end, "err" ) then
				local ob = object
				while ob do
					if ob.class == other then
						return true
					end
					ob = ob.extends
				end
			end
		end
		return false
	end

	function public:extends( ob )
		ob:extend( object )
	end

	function public:extend( ob )
		setmetatable( ob.static, { __index = object.static } )
		setmetatable( ob.public, { __index = object.public } )
		setmetatable( ob.private, { __index = object.private } )
		ob.extends = object
	end

	local meta = { }
	meta.__index = function( _, k )
		if k == "static" then
			return setmetatable( { }, {
				__newindex = function( _, k, v )
					object.static[k] = v
				end;
				__metatable = { };
			} )
		elseif k == "public" then
			return setmetatable( { }, {
				__newindex = function( _, k, v )
					object.public[k] = {
						read = true;
						write = false;
						value = v;
					}
				end;
				__call = function( _, k )
					object.public[k] = {
						read = true;
						write = true;
						value = nil;
					}
					return function( _type )
						local types = { _type }
						object.public[k].write = function( ob, value )
							for i = 1, #types do
								if class.typeOf( value, types[i] ) then
									ob[k] = value
									return
								end
							end
							if class.type( types[1] ) == "Class" then
								error( "expected <" .. types[1]:type( ) .. "> " .. k, 3 )
							else
								error( "expected <" .. tostring( types[1] ) .. "> " .. k, 3 )
							end
						end
						local function f( _type )
							table.insert( types, _type )
							return f
						end
						return f
					end
				end;
				__index = function( _, k )
					if object.public[k] then
						return setmetatable( { }, {
							__newindex = function( _, name, v )
								if name == "read" then
									if type( v ) == "boolean" or type( v ) == "function" then
										object.public[k].read = v
									else
										error( "invalid modifier value", 2 )
									end
								elseif name == "write" then
									if type( v ) == "boolean" or type( v ) == "function" then
										object.public[k].write = v
									else
										error( "invalid modifier value", 2 )
									end
								else
									error( "invalid modifier name", 2 )
								end
							end;
							__metatable = { };
						} )
					else
						error( "public index " .. tostring( k ) .. " not found", 2 )
					end
				end;
				__metatable = { };
			} )
		elseif k == "meta" then
			return setmetatable( { }, {
				__index = function( _, k )
					if k == "index" then
						return customindex
					elseif k == "newindex" then
						return customnewindex
					else
						return objectmeta[k]
					end
				end;
				__newindex = function( _, k, v )
					if k == "metatable" then
						error( "cannot change this metamethod", 2 )
					elseif k == "index" then
						if type( v ) == "function" or type( v ) == "table" or v == nil then
							customindex = v
						else
							error( "cannot use type " .. type( v ) .. " for index metamethod", 2 )
						end
					elseif k == "newindex" then
						if type( v ) == "function" or type( v ) == "table" or v == nil then
							customnewindex = v
						else
							error( "cannot use type " .. type( v ) .. " for newindex metamethod", 2 )
						end
					else
						objectmeta[k] = v
					end
				end;
				__metatable = { };
			} )
		else
			return object.static[k]
		end
	end
	function meta.__newindex( _, k, v )
		object.private[k] = v
	end;
	function meta.__call( self, ... )
		return self:new( ... )
	end;
	function meta.__tostring()
		return "Class"
	end;
	meta.__metatable = { SwiftClass = true, __type = "Class" }

	setmetatable( public, meta )

	return public
end

function class.public( name )
	local object = class.new( name )
	getfenv( 2 )[name] = object
end

function class.type( object )
	if type( object ) == "table" then
		if pcall( function() assert( getmetatable( object ).SwiftClass ) end, "err" ) then
			return "Class"
		end
		if pcall( function() assert( getmetatable( object ).SwiftClassObject ) end, "err" ) then
			return object:type( )
		end
	end
	return type( object )
end

function class.typeOf( object, ... )
	local types = { ... }
	for i = 1, #types do
		if type( object ) == "table" and pcall( function() assert( getmetatable( object ).SwiftClassObject ) end, "err" ) then
			if object:typeOf( types[i] ) then
				return types[i]
			end
		elseif type( object ) == "table" and pcall( function() assert( getmetatable( object ).SwiftClass ) end, "err" ) then
			if types[i] == "Class" then
				return "Class"
			end
		else
			if type( object ) == types[i] then
				return types[i]
			end
		end
	end
	return false
end

setmetatable( class, { __call = function( _, ... ) return class.new( ... ) end } )

return class
