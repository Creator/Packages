
local correction = .67

local function filledtriangle( x1, y1, x2, y2, x3, y3, bc, tc, char, target )

	if not fixed then
		error( "draw.triangle (filled) not yet implemented", 3 )
	end

	local l1 = { x1, y1, x2, y2 }
	local l2 = { x2, y2, x3, y3 }
	local l3 = { x3, y3, x1, y1 }

	if l1[1] > l1[3] then
		l1 = { l1[3], l1[4], l1[1], l1[2] }
	end
	if l2[1] > l2[3] then
		l2 = { l2[3], l2[4], l2[1], l2[2] }
	end
	if l3[1] > l3[3] then
		l3 = { l3[3], l3[4], l3[1], l3[2] }
	end

	l1.m = ( l1[3] - l1[1] ) / ( l1[4] - l1[2] )
	l2.m = ( l2[3] - l2[1] ) / ( l2[4] - l2[2] )
	l3.m = ( l3[3] - l3[1] ) / ( l3[4] - l3[2] )

	l1.c = l1[2] - l1.m * l1[1]
	l2.c = l2[2] - l2.m * l2[1]
	l3.c = l3[2] - l3.m * l3[1]

	local function intersect( y )
		if l1[2] == l1[4] and l1[2] == y then return l1[1], l1[3] end
		if l2[2] == l2[4] and l2[2] == y then return l2[1], l2[3] end
		if l3[2] == l3[4] and l3[2] == y then return l3[1], l3[3] end

		local x1 = ( y - l1.c ) / l1.m
		if l1[1] == l1[3] then
			if y >= math.min( l1[2], l1[4] ) and y <= math.max( l1[2], l1[4] ) then
				x1 = l1[1]
			else
				x1 = nil
			end
		end
		if l1[2] == l1[4] then x1 = nil end
		if x1 and ( x1 < l1[1] or x1 > l1[3] ) then x1 = nil end

		local x2 = ( y - l2.c ) / l2.m
		if l2[1] == l2[3] then
			if y >= math.min( l2[2], l2[4] ) and y <= math.max( l2[2], l2[4] ) then
				x2 = l2[1]
			else
				x2 = nil
			end
		end
		if l2[2] == l2[4] then x2 = nil end
		if x2 and ( x2 < l2[1] or x2 > l2[3] ) then x2 = nil end

		local x3 = ( y - l3.c ) / l3.m
		if l3[1] == l3[3] then
			if y >= math.min( l3[2], l3[4] ) and y <= math.max( l3[2], l3[4] ) then
				x3 = l3[1]
			else
				x3 = nil
			end
		end
		if l3[2] == l3[4] then x3 = nil end
		if x3 and ( x3 < l3[1] or x3 > l3[3] ) then x3 = nil end

		if x1 and x2 then return math.min( x1, x2 ), math.max( x1, x2 ) end
		if x1 and x3 then return math.min( x1, x3 ), math.max( x1, x3 ) end
		if x2 and x3 then return math.min( x2, x3 ), math.max( x2, x3 ) end
		return false
	end
	for _y = math.min( y1, y2, y3 ), math.max( y1, y2, y3 ) do
		local p1, p2 = intersect( _y )
		if p1 then
			for _x = math.floor( p1 + .5 ), math.floor( p2 + .5 ) do
				target:setPixel( _x, _y, bc, tc, char )
			end
		end
	end
end

local function outlinetriangle( x1, y1, x2, y2, x3, y3, bc, tc, char, target )
	line { x1 = x1, y1 = y1, x2 = x2, y2 = y2, colour = bc, textColour = tc, character = char, target = target }
	line { x1 = x2, y1 = y2, x2 = x3, y2 = y3, colour = bc, textColour = tc, character = char, target = target }
	line { x1 = x3, y1 = y3, x2 = x1, y2 = y1, colour = bc, textColour = tc, character = char, target = target }
end

return function( options )
	--[[
		number x1
		number y1
		number x2
		number y2
		number x3
		number y3
		number colour
		number textColour
		string character
		boolean filled
		drawable/buffer target
	]]

	options.x = options.x or 0
	options.y = options.y or 0
	options.colour = options.colour or options.bc or options.col
	options.textColour = options.textColour or options.tc or options.colour
	options.character = options.character or options.char or " "
	options.target = options.target or drawable.current()

	checkArg( options, {
		x1 = "number";
		y1 = "number";
		x2 = "number";
		y2 = "number";
		x3 = "number";
		y3 = "number";
		colour = "number";
		textColour = "number";
		character = "string";
		target = { "drawable", "buffer" };
	} )

	if options.filled then
		filledtriangle( options.x1, options.y1, options.x2, options.y2, options.x3, options.y3, options.colour, options.textColour, options.character, options.target )
	else
		outlinetriangle( options.x1, options.y1, options.x2, options.y2, options.x3, options.y3, options.colour, options.textColour, options.character, options.target )
	end
end
