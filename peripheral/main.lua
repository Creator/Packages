
local sides = {}

function connect( id )
	if sides[id] then
		return sides[id].driver
	end
	local p = peripheral.wrap( id )
	sides[id] = { driver = p, type = peripheral.getType( id ) }
	return p
end

function getType( id )
	if sides[id] then
		return sides[id].type
	end
	local p = peripheral.wrap( id )
	sides[id] = { driver = p, type = peripheral.getType( id ) }
	return p
end

function disconnect( id )
	sides[id] = nil
end

function connectVirtual( id, type, driver )
	sides[id] = {
		driver = driver;
		type = type;
	}
end
