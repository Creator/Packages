
local current = false

function set( mode, data )
	current = { mode = mode, data = data }
end

function get()
	if current then
		return current.mode, current.data
	end
	return "empty"
end

function clear()
	current = false
end
