
--[[
	
	Old filled polygon renderer...

	local bc, tc, char = mode.getMode()
	local pixel = mode.getPixelFunction()

	local lines = {}
	for i = 1, #points do
		lines[i] = {
			points[i];
			points[i+1] or points[1];
		}
	end
	for i = #lines, 1, -1 do
		if lines[i][1].y == lines[i][2].y then
			table.remove( lines, i )
		end
	end

	local miny, maxy = lines[1][1].y, lines[1][1].y
	for i = 1, #lines do
		miny = math.min( math.min( lines[i][1].y, lines[i][2].y ), miny )
		maxy = math.max( math.max( lines[i][1].y, lines[i][2].y ), maxy )
	end

	miny = math.ceil( miny - 0.5 )
	maxy = math.floor( maxy + 0.5 )

	local intersections = {}

	for l = 1, #lines do
		local v1 = Math2D.Vec2( lines[l][1].x, lines[l][1].y )
		local v2 = Math2D.Vec2( lines[l][2].x, lines[l][2].y )
		for i = miny, maxy do
			intersections[i] = intersections[i] or {}

			local point = Math2D.pointOnLine( v1, v2, nil, i )
			if point and Math2D.collision.pointInLine( v1, v2, point ) then
				table.insert( intersections[i], math.floor( point.x + .5 ) )
			end
		end
	end

	local points = {}

	for i = miny, maxy do
		table.sort( intersections[i] )
		local state = false
		local last = 1
		local p = {}
		for int = 1, #intersections[i] do
			if last ~= intersections[i][int] then
				for _p = last, intersections[i][int] do
					p[_p] = state
				end
				state = not state
				last = intersections[i][int]
			else
				p[last] = state
			end
		end

		for x = 1, #p do
			if p[x] then
				pixel( x, i, bc, tc, char )
			end
		end
	end
]]

local function filledpoly( x, y, points, bc, tc, char, target )

	if not fixed then
		error( "draw.polygon (filled) not yet implemented", 3 )
	end

	local p1 = points[1]
	for i = 2, #points - 1 do
		local p2 = points[i]
		local p3 = points[i + 1]
		triangle {
			x1 = x + p1.x;
			y1 = y + p1.y;
			x2 = x + p2.x;
			y2 = y + p2.y;
			x3 = x + p3.x;
			y3 = y + p3.y;
			colour = bc;
			textColour = tc;
			character = char;
			target = target;
			filled = true;
		}
	end
end

local function outlinepoly( x, y, points, bc, tc, char, target )
	for i = 1, #points do
		local p1, p2 = points[i], points[i+1] or points[1]
		line {
			x1 = x + p1.x;
			y1 = y + p1.y;
			x2 = x + p2.x;
			y2 = y + p2.y;
			colour = bc;
			textColour = tc;
			character = char;
			target = target;
		}
	end
end

return function( options )
	--[[
		number x
		number y
		table points
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
		x = "number";
		y = "number";
		points = "table";
		colour = "number";
		textColour = "number";
		character = "string";
		target = { "drawable", "buffer" };
	} )

	if options.filled then
		filledpoly( options.x, options.y, options.points, options.colour, options.textColour, options.character, options.target )
	else
		outlinepoly( options.x, options.y, options.points, options.colour, options.textColour, options.character, options.target )
	end
end
