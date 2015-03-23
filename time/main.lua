
local os, math = os, math
-- Credits to lbphacker for code below
local a=math.floor;local b=24*60*60;local c=365*b;local d=c+b;local e=4*c+b;local f=4;local g=1970;local h={-1,30,58,89,119,150,180,211,242,272,303,333,364}local i={}for j=1,2 do i[j]=h[j]end;for j=3,13 do i[j]=h[j]+1 end;local function gmtime(k)local m,n,o,p,q,r,s,t;local u=h;t=k;m=a(t/e)t=t-m*e;m=m*4+g;if t>=c then m=m+1;t=t-c;if t>=c then m=m+1;t=t-c;if t>=d then m=m+1;t=t-d else u=i end end end;n=a(t/b)t=t-n*b;local o=1;while u[o]<n do o=o+1 end;o=o-1;local p=n-u[o]q=(a(k/b)+f)%7;r=a(t/3600)t=t-r*3600;s=a(t/60)t=t-s*60;return m,n+1,o,p,q,r,s,t end
--time since last update
local firstepoch, firstclock, tslu

local function update()
	if not firstepoch or os.clock( ) - tslu > 300 then
		pcall( function( )
			local httpResponseHandle = http.get "http://lbphacker.hu/cctime.php"
			if not httpResponseHandle then
				return false
			end
			firstepoch = tonumber(httpResponseHandle.readAll())
			if not firstepoch then
				return false
			end
			firstclock = os.clock()
			httpResponseHandle.close()
			tslu = os.clock( )
		end )
	end
end

function getTime(gmtoffset)
	update()
	if firstepoch then
		local y, j, m, d, w, h, n, s = gmtime(firstepoch + math.floor(os.clock() - firstclock) + (gmtoffset or 0) * 3600)
		return {h = h, m = n, s = s}
	end
	return { h = math.floor( os.time( ) / 60 ), m = os.time( ) % 60, s = 0 }
end

local months = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

function getDate(gmtoffset)
	update()
	if firstepoch then
		local y, j, m, d, w, h, n, s = gmtime(firstepoch + math.floor(os.clock() - firstclock) + (gmtoffset or 0) * 3600)
		return {y = y, j = j, m = m, d = d, w = w}
	end
	local day = os.day( )
	local month = 12
	local year = math.floor( day / 365 )
	day = day - year * 365
	for i = 1, #months do
		if day < months[i] then
			month = i
			break
		else
			day = day - months[i]
		end
	end
	return { y = year, j = os.day( ), m = month, d = day, w = os.day() % 7 }
end

function isConnected()
	return not not firstepoch
end
