
local drawable, c = {}

local function bbox( x1, y1, w1, h1, x2, y2, w2, h2 )
	local x = math.max( x1, x2 )
	local y = math.max( y1, y2 )
	local w = math.min( x1 + w1, x2 + w2 ) - x + 1
	local h = math.min( y1 + h1, y2 + h2 ) - y + 1
	if w < 1 or h < 1 then return false end
	return x, y, w, h
end

local _t = type
local function type( ob )
	local t = _t( ob )
	pcall( function()
		local mt = getmetatable( ob )
		t = _t( mt.__type ) == "string" and mt.__type or t
	end )
	return t
end

local function argCheck( ... )
	local t = { ... }
	local err = true
	if #t % 2 == 1 then
		err = t[1]
		table.remove( t, 1 )
	end
	local hl = #t / 2
	for i = 1, hl do
		if type( t[i + hl] ) ~= t[i] then
			if err then
				return error( "expected " .. t[i] .. " for arg #" .. i .. ", got " .. type( t[i + hl] ), 2 )
			end
			return false
		end
	end
	return true
end

function drawable:new( width, height )
	argCheck( "number", "number", width, height )

	local t = {}

	t.pixels = {}
	t.width = width
	t.height = height
	t.bound_list = {}
	t.bounds = false

	t.rotation = 0
	t.scale_x = 1
	t.scale_y = 1

	t.anchor_x = 0
	t.anchor_y = 0

	for y = 1, height do
		t.pixels[y] = {}
		for x = 1, width do
			t.pixels[y][x] = { bc = 1, tc = 32768, char = " " }
		end
	end

	return setmetatable( t, { __index = self, __type = "drawable" } )
end

function drawable:pixelInBounds( x, y )
	if self.bounds then
		if self.bounds.x then
			return x >= self.bounds.x and y >= self.bounds.y and x < self.bounds.x + self.bounds.width and y < self.bounds.y + self.bounds.height
		end
		return false
	end
	return true
end

function drawable:setPixel( x, y, bc, tc, char )
	argCheck( "number", "number", "number", "number", "string", x, y, bc, tc, char )
	if self.pixels[y] and self.pixels[y][x] then
		if not self:pixelInBounds( x, y ) then
			return false, "pixel not in bounds"
		end
		if char == "" then return end
		if bc == 0 then
			bc = self.pixels[y][x].bc
		end
		if tc == 0 then
			tc = self.pixels[y][x].tc
			char = self.pixels[y][x].char
		end
		self.pixels[y][x] = {
			bc = bc;
			tc = tc;
			char = char;
		}
		return true
	end
	return false, "pixel out of range"
end

function drawable:getPixel( x, y )
	argCheck( "number", "number", x, y )
	if self.pixels[y] and self.pixels[y][x] then
		return self.pixels[y][x].bc, self.pixels[y][x].tc, self.pixels[y][x].char
	end
end

function drawable:foreach( f )
	local t = {}
	for x = 1, self.width do
		t[x] = {}
		for y = 1, self.height do
			local bc, tc, char = self:getPixel( x, y )
			local nbc, ntc, nchar = f( bc, tc, char, x, y )
			t[x][y] = { bc = nbc or bc, tc = ntc or tc, char = nchar or char, same = not ( nbc or ntc or nchar ) }
		end
	end
	for x = 1, self.width do
		for y = 1, self.height do
			local p = t[x][y]
			if not p.same then
				self:setPixel( x, y, p.bc, p.tc, p.char )
			end
		end
	end
end

function drawable:setBounds( x, y, w, h )
	if x then
		argCheck( "number", "number", "number", "number", x, y, w, h )
		self.bounds = { x = x, y = y, width = w, height = h }
	else
		self.bounds = {}
	end
end

function drawable:addBound( x, y, w, h )
	argCheck( "number", "number", "number", "number", x, y, w, h )
	local id = {}
	self.bounds[id] = { x = x, y = y, w = w, h = h }
	if self.bounds then
		if self.bounds.x then
			local x, y, w, h = bbox( x, y, w, h, self.bounds.x, self.bounds.y, self.bounds.width, self.bounds.height )
			self.bounds = { x = x, y = y, width = w, height = h }
		end
	else
		self.bounds = { x = x, y = y, width = w, height = h }
	end
	return id
end

function drawable:removeBound( id )
	self.bound_list[id] = nil
	self:updateBounds()
end

function drawable:updateBounds()
	local x, y, w, h
	for k, v in pairs( self.bound_list ) do
		if x then
			x, y, w, h = bbox( x, y, w, h, v.x, v.y, v.w, v.h )
		else
			x, y, w, h = v.x, v.y, v.w, v.h
		end
		if not x then
			self.bounds = { x = false }
			return
		end
	end
	self.bounds = { x = x, y = y, width = w, height = h }
end

function drawable:clearBounds()
	self.bounds = false
	self.bound_list = {}
end

function drawable:resize( width, height, scale, repbc, reptc, repchar )
	if repbc or reptc or repchar then
		if scale then
			argCheck( "number", "number", "number", "number", "number", "string", width, height, scale, repbc, reptc, repchar )
		else
			argCheck( "number", "number", "nil", "number", "number", "string", width, height, nil, repbc, reptc, repchar )
		end
	else
		if scale then
			argCheck( "number", "number", "number", width, height, scale )
		else
			argCheck( "number", "number", width, height )
		end
	end
	repbc = repbc or 1
	reptc = reptc or 32768
	repchar = repchar or " "
	if scale then
		local sx = width / self.width
		local sy = height / self.height
		self.width = width
		self.height = height
		self:foreach( function( bc, tc, char, x, y )
			local bc, tc, char = self:getPixel( math.floor( x / sx + .5 ), math.floor( y / sy + .5 ) )
			return bc or repbc, tc or reptc, char or repchar
		end )
	else
		while self.height < h do
			local t = {}
			for i = 1, self.width do
				t[i] = { bc = repbc, tc = reptc, char = repchar }
			end
			table.insert( self.pixels, t )
			self.height = self.height + 1
		end
		while self.height > h do
			table.remove( self.pixels, #self.pixels )
			self.height = self.height - 1
		end
		while self.width < w do
			for i = 1, self.height do
				table.insert( self.pixels[i], { bc = repbc, tc = reptc, char = repchar } )
			end
			self.width = self.width + 1
		end
		while self.width > w do
			for i = 1, self.height do
				table.remove( self.pixels[i], #self.pixels[i] )
			end
			self.width = self.width - 1
		end
	end
end

function drawable:drawTo( target, ox, oy )

	ox, oy = ox or 1, oy or 1

	local p2 = 2 * math.pi

	local function local_translate( x, y, r, sx, sy )
		x, y = x - 1 - self.anchor_x * self.width, y - 1 - self.anchor_y * self.height
		x = x * sx
		y = y * sy
		local angle, dist = math.atan2( x, y ) - r, math.sqrt( x ^ 2 + y ^ 2 )
		return 1 + math.sin( angle ) * dist, 1 + math.cos( angle ) * dist
	end
	local function back_translate( x, y, r, sx, sy )
		x, y = x - 1, y - 1
		local angle, dist = math.atan2( x, y ) + r, math.sqrt( x ^ 2 + y ^ 2 )
		return 1 + math.sin( angle ) * dist / sx + self.anchor_x * self.width, 1 + math.cos( angle ) * dist / sy + self.anchor_y * self.height
	end

	local r = self.rotation * math.pi / 180
	local c1x, c1y = local_translate( 1, 1, r, self.scale_x, self.scale_y )
	local c2x, c2y = local_translate( self.width, 1, r, self.scale_x, self.scale_y )
	local c3x, c3y = local_translate( self.width, self.height, r, self.scale_x, self.scale_y )
	local c4x, c4y = local_translate( 1, self.height, r, self.scale_x, self.scale_y )

	local minx, maxx = math.min( c1x, c2x, c3x, c4x ), math.max( c1x, c2x, c3x, c4x )
	local miny, maxy = math.min( c1y, c2y, c3y, c4y ), math.max( c1y, c2y, c3y, c4y )

	for x = math.floor( minx ), math.ceil( maxx ) do
		for y = math.floor( miny ), math.ceil( maxy ) do
			local _x, _y = back_translate( x, y, r, self.scale_x, self.scale_y )
			local bc, tc, char = self:getPixel( math.floor( _x + .5 ), math.floor( _y + .5 ) )
			if bc then
				target:setPixel( math.floor( x + ox - .5 ), math.floor( y + oy - .5 ), bc, tc, char )
			end
		end
	end

end

function drawable:redirect()
	c = self
end

function drawable.current()
	return c
end

return drawable
