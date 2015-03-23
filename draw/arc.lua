
local correction = .685

local function filledarc( x, y, r, a1, a2, bc, tc, char, target )
	a1, a2 = a1 / 180 * math.pi, a2 / 180 * math.pi
	r = r + .5
	local r2 = r ^ 2
	for _x = x - r, x + r do
		for _y = y - r, y + r do
			local dx, dy = _x - x, ( _y - y ) / correction
			if dx ^ 2 + dy ^ 2 < r2 then
				local a = math.atan2( dx, -dy )
				while a < 0 do a = a + math.pi * 2 end
				if ( dx == 0 and dy == 0 ) or ( a >= a1 and a <= a2 ) then
					target:setPixel( _x, _y, bc, tc, char )
				end
			end
		end
	end
end

local function outlinearc( x, y, r, a1, a2, bc, tc, char, target )
	local function pixel( _x, _y )
		target:setPixel( math.floor( x + _x * r + .5 ), math.floor( y + _y * r + .5 ), bc, tc, char )
	end

	local circ = math.pi * 2 * r
	local p2 = math.pi * 2
	a1 = a1 / 360 * p2
	a2 = a2 / 360 * p2

	for i = a1, a2, 1 / circ / math.pi do
		pixel( math.sin( i ), -math.cos( i ) * correction )
	end
end

return function( options )
	--[[
		number x
		number y
		number radius
		number angle1
		number angle2
		number colour
		number textColour
		string character
		boolean filled
		drawable/buffer target
	]]

	options.radius = options.radius or options.r
	options.angle1 = options.angle1 or options.a1
	options.angle2 = options.angle2 or options.a2
	options.colour = options.colour or options.bc or options.col
	options.textColour = options.textColour or options.tc or options.colour
	options.character = options.character or options.char or " "
	options.target = options.target or drawable.current()

	checkArg( options, {
		x = "number";
		y = "number";
		radius = "number";
		angle1 = "number";
		angle2 = "number";
		colour = "number";
		textColour = "number";
		character = "string";
		target = { "drawable", "buffer" };
	} )

	if options.filled then
		filledarc( options.x, options.y, options.radius, options.angle1, options.angle2, options.colour, options.textColour, options.character, options.target )
	else
		outlinearc( options.x, options.y, options.radius, options.angle1, options.angle2, options.colour, options.textColour, options.character, options.target )
	end
end
