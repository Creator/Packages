
local lexanalyser = {}

function lexanalyser:peek( n )
	n = n or 0
	if self.tokens[self.token + n] then
		return
			self.tokens[self.token + n].tokentype,
			self.tokens[self.token + n].value,
			self.tokens[self.token + n].line
	end
end

function lexanalyser:is( _type, n, val )
	n = n or 0
	if self.tokens[self.token + n] then
		local t = self.tokens[self.token + n]
		return t.type == _type and ( val == nil or t.value == val )
	end
end

function lexanalyser:next()
	self.token = self.token + 1
	if self.tokens[self.token] then
		self.line = self.tokens[self.token].line
	else
		self.ended = true
	end
end

function lexanalyser:closing( closet, closev, opent, openv )
	local l = 1
	for i = 1, #self.tokens - self.token + 1 do
		if self:is( closet, i, closev ) then
			l = l - 1
			if l == 0 then
				return i + self.tokens - 1
			end
		elseif self:is( opent, i, openv ) then
			l = l + 1
		end
	end
end

return function( lexer )

	local t = {}

	t.ended = false

	t.tokens = lexer.tokens
	t.token = 1

	t.line = ( lexer.tokens[1] or {} ).line or 1

	return setmetatable( t, { __index = lexanalyser } )

end
