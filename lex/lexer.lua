
local function cstring( str, pos, char )
	local f, e = false
	for i = pos, #str do
		if str:sub( i, i ) == "\\" then
			e = true
		elseif not e and str:sub( i, i ) == char then
			f = i
			break
		elseif str:sub( i, i ) == "\n" then
			return false, "unexpected [newline] in string"
		else
			e = false
		end
	end
	if not f then
		return false, "expected [" .. char .. "] to close string"
	end
	return f
end
local function lstring( str )
	local s, e = ""
	for i = 1, #str do
		if e then
			if str:sub( i, i ) == "\"" then
				s = s .. "\""
			elseif str:sub( i, i ) == "'" then
				s = s .. "'"
			elseif str:sub( i, i ) == "0" then
				s = s .. string.char( 0 )
			elseif str:sub( i, i ) == "\\" then
				s = s .. "\\"
			end
			e = false
		elseif str:sub( i, i ) == "\\" then
			e = true
		else
			s = s .. str:sub( i, i )
		end
	end
	return s
end

local slookup = {
	["{"] = "BRACKET";
	["}"] = "BRACKET";
	["["] = "BRACKET";
	["]"] = "BRACKET";
	["("] = "BRACKET";
	[")"] = "BRACKET";
	["+"] = "MATHOP";
	["-"] = "MATHOP";
	["*"] = "MATHOP";
	["/"] = "MATHOP";
	["^"] = "MATHOP";
	["%"] = "MATHOP";
	["=="] = "LOGICOP";
	["!="] = "LOGICOP";
	[">="] = "LOGICOP";
	["<="] = "LOGICOP";
	[">"] = "LOGICOP";
	["<"] = "LOGICOP";
	["!"] = "LOGICUNOP";
	["#"] = "UNOP";
	["@"] = "UNOP";
	["."] = "INDEX";
	[","] = "SEPARATOR";
	[";"] = "ENDSTAT";
}

local lexer = {}

function lexer:push( _type, value )
	table.insert( self.tokens, {
		type = "token";
		tokentype = _type;
		value = value;
		line = self.line;
	} )
end

function lexer:pop()
	table.remove( self.tokens, #self.tokens )
end

function lexer:throw( err )
	self.state = "errored"
	self.result = "[" .. self.line .. "]: " .. err
end

function lexer:next()
	if self.state ~= "lexing" then return end
	if self.pos > #self.text then
		self.result = "done"
		return
	end

	local c = self.text:sub( self.pos, self.pos )
	if c == '"' or c == "'" then
		local f, err = cstring( self.text, self.pos + 1, c )
		if f then
			local str = lstring( self.text:sub( self.pos + 1, f - 1 ) )
			self:push( "STRING", str )
			self.pos = f + 1
			return "STRING", str
		else
			self:throw( err )
		end
	elseif c == "\n" then
		self.line = self.line + 1
		self.pos = self.pos + 1
		return "NEWLINE"
	elseif c == "/" then
		if self.text:sub( self.pos + 1, self.pos + 1 ) == "/" then
			local p = self.text:find( "\n", self.pos + 2 )
			if p then
				self.pos = p + 1
			else
				self.pos = #self.text + 1
			end
			self.line = self.line + 1
			return "COMMENT"
		elseif self.text:sub( self.pos + 1, self.pos + 1 ) == "*" then
			local p = self.text:find( "*/", self.pos + 2 )
			if p then
				for i = self.pos + 2, p - 1 do
					if self.text:sub( i, i ) == "\n" then
						self.line = self.line + 1
					end
				end
				self.pos = p + 2
				return "MLCOMMENT"
			else
				self:throw "expected [*/] to close comment"
			end
		else
			self:push( "MATHOP", "/" )
			self.pos = self.pos + 1
			return "MATHOP", "/"
		end
	elseif c:find "%s" then
		self.pos = self.pos + 1
		return "WHITESPACE"
	elseif self.text:find( "^%-?%d*%.?%d+", self.pos ) then
		local num = self.text:match( "^(%-?%d*%.?%d+)", self.pos )
		self.pos = self.pos + #num
		local exp = self.text:match( "^(e%-?%d+)", self.pos )
		if exp then
			num = num .. exp
			self.pos = self.pos + #exp
		end
		local n = tonumber( num )
		if num:find "%." or num:find "e" or math.floor( n ) ~= n then
			self:push( "NUMBER", n )
			return "NUMBER", n
		else
			self:push( "INTEGER", n )
			return "INTEGER", n
		end
	elseif c:find "[a-zA-Z_]" then
		local s = c
		self.pos = self.pos + 1
		while self.text:sub( self.pos, self.pos ):find "[a-zA-Z_0-9]" do
			s = s .. self.text:sub( self.pos, self.pos )
			self.pos = self.pos + 1
		end
		self:push( "NAME", s )
		return "NAME", s
	else
		local n = slookup[c]
		if slookup[ self.text:sub( self.pos, self.pos + 1 ) ] then
			c = self.text:sub( self.pos, self.pos + 1 )
			n = slookup[ c ]
			self.pos = self.pos + 1
		end
		self.pos = self.pos + 1
		n = n or "SYMBOL"
		self:push( n, c )
		return n, c
	end
end

function lexer:lex()
	while self:next() do

	end
	if self.state == "errored" then
		return false, self.result
	end
	return self.result
end

function lexer:tostring()
	local s = ""
	for i = 1, #self.tokens do
		s = s .. self.tokens[i].tokentype .. " [" .. self.tokens[i].value .. "] : " .. self.tokens[i].line .. "\n"
	end
	return s:sub( 1, -2 )
end

return function( str )
	local t = {}

	t.state = "lexing"
	t.result = nil

	t.line = 1

	t.tokens = {}

	t.text = str
	t.pos = 1

	setmetatable( t, { __index = lexer, __tostring = function( self )
		return self:tostring()
	end } )
	return t
end
