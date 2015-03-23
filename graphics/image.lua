
function save( frame )
	local str = ""
	for y = 1, frame.height do
		for x = 1, frame.width do
			local bc, tc, char = frame:getPixel( x, y )
			bc = colour.save[bc]
			tc = colour.save[tc]
			if #char == 0 then
				char = " "
				bc = colours.save[0]
			end
			str = str .. bc .. tc .. char
		end
		str = str .. "\n"
	end
	return str:sub( 1, -2 )
end

function load( str )
	local lines = {}
	local last = 1
	for i = 1, #str do
		if str:sub( i, i ) == "\n" then
			table.insert( lines, str:sub( last, i - 1 ) )
			last = i + 1
		end
	end
	table.insert( lines, str:sub( last ) )
	local width = #lines[1] / 3
	local height = #lines
	local frame = drawable:new( width, height )
	for i = 1, #lines do
		local x = 1
		for pixel in lines[i]:gmatch( "[0123456789ABCDEF ][0123456789ABCDEF ]." ) do
			local bc = colour.lookup[pixel:sub( 1, 1 )]
			local tc = colour.lookup[pixel:sub( 2, 2 )]
			local ch = pixel:sub( 3, 3 )
			if frame.pixels[i] and frame.pixels[i][x] then
				frame.pixels[i][x] = {
					bc = bc;
					tc = tc;
					char = ch;
				}
			end
			x = x + 1
		end
	end
	return frame
end
