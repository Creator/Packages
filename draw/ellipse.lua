
local function filledellipse( x, y, w, h, bc, tc, char, target )
	local ww, hh, x0, dx = w ^ 2, h ^ 2, w, 0
	local hhww = hh*ww
	for _x = -w, w do
		target:setPixel( x + _x, y, bc, tc, char )
	end
	for _y = 1, h do
		local x1 = x0 - (dx - 1)
		for i = x1, 0, -1 do
			if (x1*x1*hh + _y*_y*ww <= hhww) then
				break
			end
			x1 = x1 - 1
		end
		dx, x0 = x0 - x1, x1
		for _x = -x0, x0 do
			target:setPixel( x + _x, y - _y, bc, tc, char )
			target:setPixel( x + _x, y + _y, bc, tc, char )
		end
	end
end

local function outlineellipse( x, y, w, h, bc, tc, char, target )
	local function pixel( x, y )
		target:setPixel( x, y, bc, tc, char )
	end

	local rx, ry = w / 2, h / 2
	local xc, yc, rxSq, rySq, x, y = x + rx, y + ry, rx ^ 2, ry ^ 2, 0, ry
	local px, py = 0, 2 * rxSq * y
	pixel( xc+x, yc+y )
	pixel( xc-x, yc+y )
	pixel( xc+x, yc-y )
	pixel( xc-x, yc-y )
	local p = rySq - (rxSq * ry) + (0.25 * rxSq)
	while (px < py) do
		x = x + 1
		px = px + 2 * rySq
		if (p < 0) then
			p = p + rySq + px
		else
			y = y - 1
			py = py - 2 * rxSq;
			p = p + rySq + px - py;
		end
		pixel( xc+x, yc+y )
		pixel( xc-x, yc+y )
		pixel( xc+x, yc-y )
		pixel( xc-x, yc-y )
	end
	p = rySq*(x+0.5)*(x+0.5) + rxSq*(y-1)*(y-1) - rxSq*rySq
	while (y > 0) do
		y = y - 1
		py = py - 2 * rxSq
		if (p > 0) then
			p = p + rxSq - py
		else
			x = x + 1
			px = px + 2 * rySq
			p = p + rxSq - py + px
		end
		pixel( xc+x, yc+y )
		pixel( xc-x, yc+y )
		pixel( xc+x, yc-y )
		pixel( xc-x, yc-y )
	end
end

return function( options )
	--[[
		number x
		number y
		number width
		number height
		number colour
		number textColour
		string character
		boolean filled
		drawable/buffer target
	]]

	options.width = options.width or options.w
	options.height = options.height or options.h
	options.colour = options.colour or options.bc or options.col
	options.textColour = options.textColour or options.tc or options.colour
	options.character = options.character or options.char or " "
	options.target = options.target or drawable.current()

	checkArg( options, {
		x = "number";
		y = "number";
		width = "number";
		height = "number";
		colour = "number";
		textColour = "number";
		character = "string";
		target = { "drawable", "buffer" };
	} )

	if options.filled then
		filledellipse( options.x, options.y, options.width, options.height, options.colour, options.textColour, options.character, options.target )
	else
		outlineellipse( options.x, options.y, options.width, options.height, options.colour, options.textColour, options.character, options.target )
	end
end
