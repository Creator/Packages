
-- Handshake
-- Used with permission from 1lann
-- Compressed using Lua Minifier (https://mothereff.in/lua-minifier)
local math = math
local Handshake={}Handshake.prime=625210769;Handshake.base=-1;Handshake.secret=-1;Handshake.sharedSecret=-1;function Handshake.exponentWithModulo(a,b,c)local d=a;for e=1,b-1 do d=d*d;if d>=c then d=d%c end end;return d end;function Handshake.clear()Handshake.base=-1;Handshake.secret=-1;Handshake.sharedSecret=-1 end;function Handshake.generateInitiatorData()Handshake.base=math.random(10,99999)Handshake.secret=math.random(10,99999)return{type="initiate",prime=Handshake.prime,base=Handshake.base,moddedSecret=Handshake.exponentWithModulo(Handshake.base,Handshake.secret,Handshake.prime)}end;function Handshake.generateResponseData(f)local g=type(f.prime)=="number"local h=f.prime==Handshake.prime;local i=type(f.base)=="number"local j=f.type=="initiate"local k=type(f.moddedSecret)=="number"local l=g and i and k;if l and h then if j then Handshake.base=f.base;Handshake.secret=math.random(10,99999)Handshake.sharedSecret=Handshake.exponentWithModulo(f.moddedSecret,Handshake.secret,Handshake.prime)return{type="response",prime=Handshake.prime,base=Handshake.base,moddedSecret=Handshake.exponentWithModulo(Handshake.base,Handshake.secret,Handshake.prime)},Handshake.sharedSecret elseif f.type=="response"and Handshake.base>0 and Handshake.secret>0 then Handshake.sharedSecret=Handshake.exponentWithModulo(f.moddedSecret,Handshake.secret,Handshake.prime)return Handshake.sharedSecret else return false end else return false end end;
-- Network library (awsumben13)
local forwarding = {}
local banned = {}
local wl = {}
local establishing = false
local keys = {}

local function genkey( nKey )
	local sKey = ""
	math.randomseed( nKey )
	for i = 1, 32 do
		sKey = sKey .. string.char( math.random( 0, 255 ) )
	end
	return sKey
end

local modem, modemside
function updateModem()
	if modemside and peripheral.getType( modemside ) == "modem" then
		return true
	end
	for _, side in pairs( peripheral.getNames() ) do
		if peripheral.getType( side ) == "modem" then
			modem = peripheral.wrap( side )
			modemside = side
			modem.open( 2514 )
			return true
		end
	end
	return false
end

function forward( side, side2 )
	forwarding[side] = forwarding[side] or {}
	forwarding[side][#forwarding[side]+1] = side2
end
function unforward( side, side2 )
	if forwarding[side] then
		for i = #forwarding[side], 1, -1 do
			if forwarding[side][i] == side2 then
				table.remove( forwarding[side], i )
			end
		end
	end
end

function block( id )
	banned[id] = true
end
function allow( id )
	banned[id] = false
end

function whitelist( id )
	whitelist[id] = true
end
function unwhitelist( id )
	whitelist[id] = nil
end

function send( id, data, protocol, keyindex )
	if keyindex and not keys[keyindex] then
		return false, "no such key"
	end
	if id == os.getComputerID() then
		os.queueEvent( "nova_network_message", id, data, protocol )
		return true
	end
	updateModem()
	if modem then
		if keyindex then
			data = Encryption.encrypt( textutils.serialize( data ), keys[keyindex] )
		end
		modem.transmit( 2514, 2514, {
			isNovaNetworkMessage = true;
			sender = os.getComputerID();
			target = id;
			data = data;
			keyindex = keyindex;
			protocol = protocol or "NONE";
		} )
		return true
	end
	return false, "no modem found"
end
function receive( id, timeout, protocol )
	local timer
	if timeout then
		timer = os.startTimer( timeout )
	end
	while true do
		local ev, p1, p2, p3, p4 = coroutine.yield()
		if ev == "timer" and p1 == timer then
			return false
		end
		if ev == "nova_network_message" and ( p1 == id or not id ) and ( p3 == protocol or not protocol ) then
			return p1, p2, p3, p4
		end
	end
end

function response( id, data, protocol, keyindex, timeout )
	local ok, err = send( id, data, protocol, keyindex )
	if not ok then
		return false, err
	end
	return receive( id, timeout )
end

function establishKey( id, timeout )
	if id == os.getComputerID() then
		local index, key = math.random( 0, 32767 ), math.random( 0, 32767 )
		keys[index] = genkey( key )
		return index
	end
	while establishing do
		coroutine.yield()
	end
	establishing = true
	send( id, { request = "KeyEstablish", data = Handshake.generateInitiatorData(), keyIndex = Handshake.generateInitiatorData() }, "KeyExchange" )
	local _, data = receive( id, timeout or 1, "KeyExchange" )
	if type( data ) == "table" then
		local key = Handshake.generateResponseData( data.data )
		local index = Handshake.generateResponseData( data.keyIndex )
		establishing = false
		keys[index] = genkey( key )
		return index
	end
	establishing = false
	return false
end

function event( ... )
	local event = { ... }
	local msg, sender, protocol, keyindex
	if event[1] == "modem_message" then
		if type( event[5] ) == "table" and event[5].isNovaNetworkMessage and event[5].target == os.getComputerID( ) then
			sender = event[5].sender
			msg = event[5].data
			protocol = event[5].protocol
			if event[5].keyindex then
				if keys[event[5].keyindex] then
					msg = textutils.unserialize( Encryption.decrypt( msg, keys[event[5].keyindex] ) )
					keyindex = event[5].keyindex
				else
					sender = nil
				end
			end
			if protocol == "KeyExchange" and type( msg ) == "table" and msg.request == "KeyEstablish" then
				local data, key = Handshake.generateResponseData( msg.data )
				local data2, keyIndex = Handshake.generateResponseData( msg.keyIndex )
				send( sender, { data = data, keyIndex = data2 }, "KeyExchange" )
				keys[keyIndex] = genkey( key )
				sender = nil
			end
		end
		if forwarding[event[2]] then
			for i, v in pairs( forwarding[event[2]] ) do
				if peripheral.getType( v ) == "modem" then
					local p = peripheral.wrap( v )
					p.transmit( event[3], event[4], v )
				end
			end
		end
	elseif event[1] == "rednet_message" then
		sender = event[2]
		msg = event[3]
		protocol = event[4]
	end
	if sender then
		if not banned[sender] and ( not next( wl ) or wl[sender] ) then
			os.queueEvent( "nova_network_message", sender, msg, protocol, keyindex )
		end
	end
end
