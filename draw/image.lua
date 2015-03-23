
return function( options )
	--[[
		number x
		number y
		Image image
		number width
		number height
		drawable/buffer target
	]]

	options.width = options.width or options.w or options.image.width
	options.height = options.height or options.h or options.image.height
	options.target = options.target or drawable.current()

	checkArg( options, {
		x = "number";
		y = "number";
		image = "Image";
		width = "number";
		height = "number";
		target = { "drawable", "buffer" };
	} )

	local sx, sy = options.image.width / options.width, options.image.height / options.height
	for _x = 0, options.width - 1 do
		for _y = 0, options.height - 1 do
			local bc, tc, char = image:getPixel(
				math.min( math.max( _x * sx + 1, 1 ), options.image.width ),
				math.min( math.max( _y * sy + 1, 1 ), options.image.height )
			)
			if bc then
				options.target:setPixel( x + _x, y + _y, bc, tc, char )
			end
		end
	end
end
