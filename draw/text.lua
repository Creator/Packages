
return function( options )
	--[[
		number x
		number y
		number width
		number height
		number colour
		number textColour
		string text
		string align
		boolean filled
		boolean wrap
		drawable/buffer target
	]]

	options.width = options.width or options.w or ( type( options.text ) == "string" and #options.text )
	options.height = options.height or options.h or 1
	options.colour = options.colour or options.bc or options.col
	options.textColour = options.textColour or options.tc or options.colour
	options.target = options.target or drawable.current()

	checkArg( options, {
		x = "number";
		y = "number";
		width = "number";
		height = "number";
		colour = "number";
		textColour = "number";
		text = "string";
		target = { "drawable", "buffer" };
	} )

	local lines
	if options.wrap then
		lines = sutils.wordwrap( options.text, options.width, options.height, options.align, options.width, options.height )
	else
		lines = sutils.wordwrap( options.text:gsub( "\n", " " ), nil, 1, options.align, options.width, options.height )
	end

	if options.filled then
		rectangle {
			x = options.x;
			y = options.y;
			width = options.width;
			height = options.height;
			colour = options.colour;
			filled = true;
			target = options.target;
		}
	end

	y = y + ( lines.padding.vertical or 0 )

	for line = 1, #lines do
		lines[line] = lines[line]:gsub( "\n$", "" )
		local px, py = x + ( lines.padding[line] or 0 ), y + line - 1
		for char = 1, #lines[line] do
			options.target:setPixel( px, py, 0, options.textColour, lines[line]:sub( char, char ) )
			px = px + 1
		end
	end
end
