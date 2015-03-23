
return function( options )
	--[[
		number x
		number y
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
		x = "number";
		y = "number";
		colour = "number";
		textColour = "number";
		character = "string";
		target = { "drawable", "buffer" };
	} )

	options.target:setPixel( options.x, options.y, options.colour, options.textColour, options.character )
end
