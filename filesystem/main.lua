
-- fs.copy and fs.move should be able to work with directories

--[[
combine
isReadOnly
getSize
move
exists
copy
getFreeSpace
makeDir
find
getDir
delete
open
list
getDrive
getName
isDir
]]

local fso, fs = fs, {}

local function resolvePath( path )
	local parts = sutils.split( path, "/" )
	for i = #parts, 1, -1 do
		if parts[i] == ".." then
			table.remove( parts, i )
			table.remove( parts, i - 1 )
		elseif parts[i] == "." or parts[i] == "" then
			table.remove( parts, i )
		end
	end
	return table.concat( parts, "/" )
end

function fs.create()
	local t = {}

	t.mounts = {}
	t.banned = {}
	t.fsobj = {}

	function t:resolvePath( path )
		path = path:lower()
		return resolvePath( path )
	end

	function t:getFilesystemAndPath( path )
		path = self:resolvePath( path )
		local m = { fs = self, len = 0, path = path }
		for k, v in pairs( self.mounts ) do
			if #k > m.len and path:find( "^" .. k ) then
				m = { fs = v, len = #k, path = path:sub( #k + 1 ) }
			end
		end
		if m.fs ~= self then
			return m.fs:getFilesystemAndPath( m.path )
		end
		for k, v in pairs( self.banned ) do
			if path:find( "^" .. k ) then
				return false
			end
		end
		return self, m.path
	end

	function t:write( path, data )
		local h = self:open( path, "w" )
		if h then
			h.write( data )
			h.close()
		end
		return false
	end

	function t:read( path )
		local h = self:open( path, "r" )
		if h then
			local content = h.readAll()
			h.close()
			return content
		end
	end

	local methods = { "list", "delete", "open", "exists", "isDir", "getFreeSpace", "isReadOnly", "makeDir", "getDrive" }
	for i = 1, #methods do
		t[methods[i]] = function( self, path, ... )
			local fs, path = self:getFilesystemAndPath( path )
			if fs then
				return fs.fsobj[methods[i]]( path, ... )
			end
		end
	end

	function t:getSize( path, dir )
		local fs, path = self:getFilesystemAndPath( path )
		if fs then
			if dir and fs.fsobj.isDir( path ) then
				local n, files = 0, fs.fsobj.list( path )
				for i = 1, #files do
					n = n + fs:getSize( path .. "/" .. files[i], dir )
				end
				return n
			end
			return fs.fsobj.getSize( path )
		end
		return 0
	end

	function t:copy( path1, path2 )
		if self:isDir( path1 ) then
			return error "directories aren't currently supported"
		end
		local fs, path = self:getFilesystemAndPath( path1 )
		local fs2, path2 = self:getFilesystemAndPath( path2 )
		if fs and fs2 then
			local content = fs:read( path )
			if content then
				fs2:write( path2, content )
				return true
			end
		end
	end

	function t:move( path1, path2 )
		return self:copy( path1, path2 ) and self:delete( path1 )
	end

	function t:combine( path, ... )
		local args = { ... }
		for i = 1, #args do
			path = path .. "/" .. tostring( args[i] )
		end
		return path:gsub( "//+", "/" )
	end

	function t:getDir( path )
		local path = self:resolvePath( path )
		if path:find "/" then
			return path:match "^(.+)/"
		else
			return ""
		end
	end
	function t:getName( path )
		local path = self:resolvePath( path )
		return path:gsub( "^.+/", "" )
	end
	function t:getExtension( path )
		local path = self:resolvePath( path )
		local name = path:gsub( "^.+/", "" )
		if name:find "%." then
			return name:gsub( ".+%.", "" )
		end
		return ""
	end

	function t:find( file )
		return self.fsobj.find( file )
	end

	function t:mount( path, filesystem )
		self.mounts[path] = filesystem
	end

	function t:unmount( path )
		self.mounts[path] = nil
	end

	function t:ban( path )
		self.banned[self:resolvePath( path )] = true
	end

	function t:allow( path )
		self.banned[self:resolvePath( path )] = nil
	end

	function t:normalFS()
		local methods = { "combine", "isReadOnly", "getSize", "move", "exists", "copy", "getFreeSpace", "makeDir", "find", "getDir", "delete", "open", "list", "getDrive", "getName", "isDir" }
		local t = {}
		for i = 1, #methods do
			t[methods[i]] = function( ... )
				return self[methods[i]]( self, ... )
			end
		end
		return t
	end

	setmetatable( t, { __type = "filesystem" } )

	return t
end

function fs.createRedirect( p )
	p = resolvePath( p )
	local t = {}
	local methods = { "list", "delete", "open", "exists", "isDir", "getSize", "getFreeSpace", "isReadOnly", "makeDir", "getDrive", "find" }
	for i = 1, #methods do
		t[methods[i]] = function( path, ... )
			if type( path ) ~= "string" then
				return error( "expected string path, got " .. type( path ) )
			end
			path = resolvePath( path )
			return fso[methods[i]]( p .. "/" .. path, ... )
		end
	end

	function t.copy( path1, path2 )
		if type( path1 ) ~= "string" or type( path2 ) ~= "string" then
			return error "Expected string, string"
		end

		path1, path2 = resolvePath( path1, path2 )
		return fso.copy( p .. "/" .. path1, p .. "/" .. path2 )
	end
	function t.move( path1, path2 )
		if type( path1 ) ~= "string" or type( path2 ) ~= "string" then
			return error "Expected string, string"
		end

		path1, path2 = resolvePath( path1, path2 )
		return fso.move( p .. "/" .. path1, p .. "/" .. path2 )
	end

	t.combine = fso.combine
	t.getDir = fso.getDir
	t.getName = fso.getName

	return t
end

return fs
