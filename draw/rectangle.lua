
local function filledrect( x, y, w, h, bc, tc, char, target )
	for _x = x, x + w - 1 do
		for _y = y, y + h - 1 do
			target:setPixel( _x, _y, bc, tc, char )
		end
	end
end

local function outlinerect( x, y, w, h, bc, tc, char, target )
	local x2, y2 = x + w - 1, y + h - 1
	for _x = x, x2 do
		target:setPixel( _x, y, bc, tc, char )
		target:setPixel( _x, y2, bc, tc, char )
	end
	for _y = y + 1, y2 - 1 do
		target:setPixel( x, _y, bc, tc, char )
		target:setPixel( x2, _y, bc, tc, char )
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
		filledrect( options.x, options.y, options.width, options.height, options.colour, options.textColour, options.character, options.target )
	else
		outlinerect( options.x, options.y, options.width, options.height, options.colour, options.textColour, options.character, options.target )
	end
end
