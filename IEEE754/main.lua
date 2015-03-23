-- no nan and inf support yet
local math = math
local function ieee754_impl(a,b,c,d)local z,y,e,f,g=math,string.byte if a then e=1-z.min(y(a)-45,1)a=z.abs(a)f=z.floor(z.log(a)/z.log(2))g=a*.5^f+f+2^(d-1)-2 for l=d-1,d-c+1,-1 do e=e..z.floor(g/2^l)g=g%2^l end else e=1 for l=-1,d-c+2,-1 do e=e+2^l*(y(b,d+1-l)-48)end f=-1*2^(d-1)+1 for l=d-1,0,-1 do f=f+2^l*(y(b,d+1-l)-48)end e=e*2^f*(-1)^(y(b)-48)end return e end

return function( n, s, w, e )
	w = w or math.max( 32, ( e or 8 ) * 2 + 1 )
	return ieee754_impl( n, s, w, e or math.min( 8, math.floor( ( ( w or 32 ) - 1 ) / 2 ) ) )
end
