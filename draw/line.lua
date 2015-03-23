
local correction = .67

local function filledcirc( x, y, r, bc, tc, char, target )

	local r2 = ( r + .5 ) ^ 2
	for _x = x - r, x + r do
		for _y = -r, r do
			if ( ( x - _x ) ^ 2 + ( _y / correction ) ^ 2 ) <= r2 then
				target:setPixel( _x, y + _y, bc, tc, char )
			end
		end
	end
end

local function outlinecirc( x, y, r, bc, tc, char, target )

	local function pixel( x, y )
		target:setPixel( x, y, bc, tc, char )
	end

	local c = 2 * math.pi * r
	local n = 2 * math.pi * 2 / c
	local c8 = c / 8
	for i = 0, c8 do
		local _x, _y = math.sin( i * n ) * r, math.cos( i * n ) * r
		pixel( x + _x, y + _y * correction )
		pixel( x + _x, y - _y * correction )
		pixel( x - _x, y + _y * correction )
		pixel( x - _x, y - _y * correction )
		pixel( x + _y, y + _x * correction )
		pixel( x - _y, y + _x * correction )
		pixel( x + _y, y - _x * correction )
		pixel( x - _y, y - _x * correction )
	end
end

return function( options )
	--[[
		number x1
		number y1
		number x2
		number y2
		number colour
		number textColour
		string character
		drawable/buffer target
	]]

	options.colour = options.colour or options.bc or options.col
	options.textColour = options.textColour or options.tc or options.colour
	options.character = options.character or options.char or " "
	options.target = options.target or drawable.current()

	checkArg( options, {
		x1 = "number";
		y1 = "number";
		x2 = "number";
		y2 = "number";
		colour = "number";
		textColour = "number";
		character = "string";
		target = { "drawable", "buffer" };
	} )

	if options.x1 > options.x2 then
		options.x2, options.x1 = options.x1, options.x2
		options.y2, options.y1 = options.y1, options.y2
	end

	if options.x1 == options.x2 then
		for i = math.min( options.y1, options.y2 ), math.max( options.y1, options.y2 ) do
			options.target:setPixel( options.x1, i, options.colour, options.textColour, options.character )
		end
		return
	end

	local dx, dy = options.x2 - options.x1, options.y2 - options.y1
	local m = dy / dx
	local c = options.y1 - m * options.x1

	for x = options.x1, options.x2, math.min( 1 / math.abs( m ), 1 ) do
		local y = m * x + c
		options.target:setPixel( math.floor( x + .5 ), math.floor( y + .5 ), options.colour, options.textColour, options.character )
	end
end
