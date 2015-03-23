
local packages = {
	class = true;
	clipboard = true;
	filesystem = true;
	IEEE754 = true;
	lex = true;
	network = true;
	peripheral = true;
	process = true;
	sha256 = true;
	sutils = true;
	time = true;
	tween = true;
}

if not fs.isDir ".package" then
	local h = http.get "https://raw.githubusercontent.com/awsumben13/Package-API/master/install.lua"
	if h then
		local content = h.readAll()
		h.close()

		local f, err = loadstring( content, "installer" )
		if f then
			f()
		else
			print( err )
			return
		end
	else
		print "Couldn't download package API"
		return
	end
end
local package = dofile ".package/api.lua"

local function download( package )
	package.install( package, "https://raw.githubusercontent.com/awsumben13/Misc-Packages/master/build/" .. package )
end

print "What packages would you like to install? (* for all, separate with space):"

local p = read()

if p == "*" then
	for k, v in pairs( packages ) do
		download( k )
	end
else
	for pack in p:gmatch "([%w_]+)" do
		if packages[pack] then
			download( pack )
		else
			error( "No such package " .. pack, 0 )
		end
	end
end
