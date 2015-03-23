
local _t = type
local function type( ob )
	local t = _t( ob )
	pcall( function()
		local mt = getmetatable( ob )
		t = _t( mt.__type ) == "string" and mt.__type or t
	end )
	return t
end

local math, type, table, current = math, type, table

local buffer = {}

buffer.textscale = 1
buffer.redraw = false
buffer.cursor = false

local function px( target, x, y, bc, tc, text )
	target.setCursorPos( x, y )
	target.setBackgroundColour( bc )
	target.setTextColour( tc )
	target.write( text )
end

function buffer:create( w, h )
	local b = setmetatable( {}, { __index = self, __type = "buffer" } )

	w = w or 0
	h = h or 0

	b.width = w or 0
	b.height = h or 0

	b.pixels = {}
	b.last = {}

	for y = 1, h do
		b.pixels[y] = {}
		b.last[y] = {}
		for x = 1, w do
			b.pixels[y][x] = { bc = 1, tc = 1, char = " " }
		end
	end

	return b
end

function buffer:setPixel( x, y, bc, tc, char )
	local self = self -- minifying optimisation
	x, y = math.floor( x + 0.5 ), math.floor( y + 0.5 )
	if self.pixels[y] and self.pixels[y][x] then
		local _bc, _tc, _char = self:getPixel( x, y )
		if type( bc ) == "function" then bc = bc( _bc ) end
		if bc == 0 then bc = _bc end
		if type( tc ) == "function" then tc = tc( _tc ) end
		if tc == 0 then tc, char = _tc, _char end
		if char ~= "" then
			self.pixels[y][x].bc = bc
			self.pixels[y][x].tc = tc
			self.pixels[y][x].char = char
		end
		return true
	end
	return false
end
function buffer:getPixel( x, y )
	x, y = math.floor( x + 0.5 ), math.floor( y + 0.5 )
	if self.pixels[y] and self.pixels[y][x] then
		local p = self.pixels[y][x]
		return p.bc, p.tc, p.char
	end
end

function buffer:foreach( f )
	local p = {}
	for x = 1, self.width do
		for y = 1, self.height do
			local bc, tc, char = self:getPixel( x, y )
			local _bc, _tc, _char = f( bc, tc, char, x, y )
			if ( _bc and _bc ~= bc ) or ( _tc and _tc ~= tc ) or ( _char and _char ~= char ) then
				p[#p+1] = { bc = _bc or bc, tc = _tc or tc, char = _char or char, x = x, y = y }
			end
		end
	end
	for i = 1, #p do
		self:setPixel( p[i].x, p[i].y, p[i].bc, p[i].tc, p[i].char )
	end
end

function buffer:setCursorBlink( x, y, tc )
	if x then
		x, y = math.floor( x + 0.5 ), math.floor( y + 0.5 )
		self.cursor = { x = x, y = y, tc = tc or 1 }
	else
		self.cursor = false
	end
end

function buffer:hasChanged( x, y )
	x, y = math.floor( x + 0.5 ), math.floor( y + 0.5 )
	if self.pixels[y] and self.pixels[y][x] then
		local p = self.pixels[y][x]
		if not self.last[y][x] then self.last[y][x] = {} return true end
		return p.bc ~= self.last[y][x].bc
		or p.char ~= self.last[y][x].char
		or ( p.tc ~= self.last[y][x].tc and p.char ~= " " )
	end
end
function buffer:draw( target, _x, _y )
	if self.redraw then
		return self:drawAll()
	end
	target = target or term
	_x = _x or 1
	_y = _y or 1
	if type( target.setTextScale ) == "function" then
		target.setTextScale( self.textScale )
	end
	for y = 1, self.height do
		local last
		for x = 1, self.width do
			if self:hasChanged( x, y ) then
				if last then
					if last.bc == self.pixels[y][x].bc and ( last.tc == self.pixels[y][x].tc or self.pixels[y][x].char == " " ) then
						last.char = last.char .. self.pixels[y][x].char
					else
						px( target, last.x + _x - 1, last.y + _y - 1, last.bc, last.tc, last.char )
						last = { x = x, y = y, bc = self.pixels[y][x].bc, tc = self.pixels[y][x].tc, char = self.pixels[y][x].char }
					end
				else
					last = { x = x, y = y, bc = self.pixels[y][x].bc, tc = self.pixels[y][x].tc, char = self.pixels[y][x].char }
				end
				self.last[y][x] = { bc = self.pixels[y][x].bc, tc = self.pixels[y][x].tc, char = self.pixels[y][x].char }
			elseif last then
				px( target, last.x + _x - 1, last.y + _y - 1, last.bc, last.tc, last.char )
				last = nil
			end
		end
		if last then
			px( target, last.x + _x - 1, last.y + _y - 1, last.bc, last.tc, last.char )
		end
	end
	if self.cursor then
		target.setCursorPos( _x + self.cursor.x - 1, _y + self.cursor.y - 1 )
		target.setTextColour( self.cursor.tc )
		target.setCursorBlink( true )
	else
		target.setCursorBlink( false )
	end
end
function buffer:drawAll( target, _x, _y )
	self.allchanged = false
	target = target or term
	_x = _x or 1
	_y = _y or 1
	if target.setTextScale then
		target.setTextScale( self.textScale )
	end
	for y = 1, self.height do
		target.setCursorPos( _x, y + _y - 1 )
		for x = 1, self.width do
			local bc, tc, char = self:getPixel( x, y )
			target.setBackgroundColour( bc )
			target.setTextColour( tc )
			target.write( char )
			if char == "" then
				target.setCursorPos( _x + x, y + _y - 1 )
			end
			self.last[y][x] = {
				bc = bc;
				tc = tc;
				char = char;
			}
		end
	end
	if self.cursor then
		target.setCursorPos( _x + self.cursor.x - 1, _y + self.cursor.y - 1 )
		target.setTextColour( self.cursor.tc )
		target.setCursorBlink( true )
	else
		target.setCursorBlink( false )
	end
end

function buffer:resize( width, height, bc, tc, char )
	bc = bc or 1
	tc = tc or 1
	char = char or " "
	while self.height < height do
		local t = {}
		for i = 1, self.width do
			t[i] = { bc = bc, tc = tc, char = char }
		end
		table.insert( self.pixels, t )
		table.insert( self.last, {} )
		self.height = self.height + 1
	end
	while self.height > height do
		table.remove( self.pixels, #self )
		table.remove( self.last, #self.last )
		self.height = self.height - 1
	end
	while self.width < width do
		for i = 1, self.height do
			table.insert( self.pixels[i], { bc = bc, tc = tc, char = char } )
		end
		self.width = self.width + 1
	end
	while self.width > width do
		for i = 1, self.height do
			table.remove( self.pixels[i], #self.pixels[i] )
		end
		self.width = self.width - 1
	end
end

function buffer:redirect( r )
	if type( r ) == "buffer" then
		current = r
	else
		return error "expected <buffer> redirect"
	end
end

function buffer.current()
	return current
end

return buffer
