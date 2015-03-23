
local table, math = table, math

function gfind( str, pat, pos )
	local t = { }
	local params = { str:find( pat, pos ) }
	while params[1] do
		table.insert( t, params )
		params = { str:find( pat, params[2] + 1 ) }
	end
	local i = 0
	return function( )
		i = i + 1
		if t[i] then
			return unpack( t[i] )
		end
	end
end

function camelCase( s )
	for pos in gfind( s, " %w" ) do
		s = s:sub( 1, pos ) .. s:sub( pos + 1, pos + 1 ):upper() .. s:sub( pos + 2 )
	end
	return s:sub( 1, 1 ):upper() .. s:sub( 2 )
end

function split( str, pat, pos )
	local last = 1
	local parts = { }
	for s, f in gfind( str, pat, pos ) do
		table.insert( parts, str:sub( last, s - 1 ) )
		last = f + 1
	end
	table.insert( parts, str:sub( last ) )
	return parts
end

function linewrap( str, w )
	local ww = 0
	for i = 1, w + 1 do
		ww = ww + ( str:sub( i, i ) == "\t" and 4 or 1 )
		if ww > w + 1 then
			break
		end
		if str:sub( i, i ) == "\n" then
			return str:sub( 1, i ), str:sub( i + 1 )
		end
	end
	if #str:gsub( "\t", "    " ) <= w then
		return str, false
	end
	local wrapto
	for s, f in gfind( str, "%s+" ) do
		if #str:sub( 1, s ):gsub( "\t", "    " ) > w + 1 then
			break
		end
		wrapto = f
	end
	if wrapto then return str:sub( 1, wrapto ), str:sub( wrapto + 1 ) end
	local ww = 0
	for i = 1, #str do
		ww = ww + ( str:sub( i, i ) == "\t" and 4 or 1 )
		if ww > w then
			return str:sub( 1, math.max( i - 1, 1 ) ), str:sub( math.max( i - 1, 1 ) + 1 )
		end
	end
end

function wordwrap( f, w, h, align, rw, rh )
	local lines = {}
	if w then
		local s
		while f do
			s, f = linewrap( f, w )
			table.insert( lines, s )
		end
	else
		lines = split( f, "\n" )
		for i = 1, #lines - 1 do
			lines[i] = lines[i] .. "\n"
		end
	end
	if h then
		while #lines > h do
			table.remove( lines, #lines )
		end
	end
	lines.padding = {}
	if align then
		local v, h = align:match "(%w+), ?(%w+)"
		if v then
			if rh and ( v == "middle" or v == "centre" or v == "center" ) then
				lines.padding.vertical = math.floor( rh / 2 - #lines / 2 )
			elseif rh and v == "bottom" then
				lines.padding.vertical = rh - #lines
			end
			if rw and ( h == "middle" or h == "centre" or h == "center" ) then
				for i = 1, #lines do
					lines.padding[i] = math.floor( rw / 2 - #lines[i]:gsub( "\n$", "" ) / 2 )
				end
			elseif rw and h == "right" then
				for i = 1, #lines do
					lines.padding[i] = rw - #lines[i]:gsub( "\n$", "" )
				end
			else
				for i = 1, #lines do
					lines.padding[i] = 0
				end
			end
		end
	end
	return lines
end

local function cweight( c )
	local char = 2 * c:lower():byte() - 1
	if c:upper() == c then
		return char + 1
	end
	return char
end

function weight( str )
	local n = 0
	for i = 1, #str do
		n = n + cweight( str:sub( i, i ) ) * 256 ^ ( 1 - i )
	end
	return n
end
