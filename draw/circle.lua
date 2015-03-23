
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
		target:setPixel( math.floor( x + .5 ), math.floor( y + .5 ), bc, tc, char )
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
		number x
		number y
		number radius
		number colour
		number textColour
		string character
		boolean filled
		drawable/buffer target
	]]

	options.radius = options.radius or options.r
	options.colour = options.colour or options.bc or options.col
	options.textColour = options.textColour or options.tc or options.colour
	options.character = options.character or options.char or " "
	options.target = options.target or drawable.current()

	checkArg( options, {
		x = "number";
		y = "number";
		radius = "number";
		colour = "number";
		textColour = "number";
		character = "string";
		target = { "drawable", "buffer" };
	} )

	if options.filled then
		filledcirc( options.x, options.y, options.radius, options.colour, options.textColour, options.character, options.target )
	else
		outlinecirc( options.x, options.y, options.radius, options.colour, options.textColour, options.character, options.target )
	end
end
