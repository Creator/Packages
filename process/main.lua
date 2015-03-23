
local getfenv, setmetatable, coroutine, table = getfenv, setmetatable, coroutine, table

local running = {}

function newThread( f, name )
	local t = {}

	t.state = "running"
	t.name = name or "unnamed thread"
	t.environment = setmetatable( {}, { __index = getfenv( 2 ) } )
	setfenv( f, setmetatable( {}, { __index = function( _, k )
		return t.environment[k]
	end, __newindex = function( _, k, v )
		t.environment[k] = v
	end } ) )
	t.func = f
	t.co = coroutine.create( f )

	function t:stop()
		self.state = "stopped"
	end
	function t:pause()
		if self.state == "running" then
			self.state = "paused"
		end
	end
	function t:resume()
		if self.state == "paused" then
			self.state = "running"
		end
	end

	function t:restart()
		self.state = "running"
		self.co = coroutine.create( self.func )
	end

	function t:update( ... )
		if self.state ~= "running" then return end
		local ok, err = coroutine.resume( self.co, ... )
		if not ok then
			self.state = "stopped"
			if type( self.onException ) == "function" then
				self:onException( err )
			end
		end
		if coroutine.status( self.co ) == "dead" then
			self.state = "stopped"
			if type( self.onFinish ) == "function" then
				self:onFinish()
			end
		end
	end

	table.insert( running, 1, t )
	return t
end

function newTask( name )
	local t = {}

	t.environment = setmetatable( {}, { __index = getfenv( 2 ) } )
	t.threads = {}
	t.name = name or "unnamed task"

	function t:newThread( f )
		local thread = newThread( f )
		thread.environment = self.environment
		function thread.onException( t, err )
			if type( self.onException ) == "function" then
				self.onException( t, err )
			end
		end
		function thread.onFinish( t, err )
			if type( self.onFinish ) == "function" then
				self.onFinish( t, err )
			end
		end
		table.insert( self.threads, thread )
		return thread
	end

	function t:stop()
		for i = #self.threads, 1, -1 do
			self.threads[i]:stop()
		end
	end
	function t:pause()
		for i = #self.threads, 1, -1 do
			self.threads[i]:pause()
		end
	end
	function t:resume()
		for i = #self.threads, 1, -1 do
			self.threads[i]:resume()
		end
	end

	function t:restart()
		for i = #self.threads, 1, -1 do
			self.threads[i]:restart()
		end
	end

	function t:update( ... )
		for i = #self.threads, 1, -1 do
			self.threads[i]:update( ... )
		end
	end

	function t:removeDeadThreads()
		for i = #self.threads, 1, -1 do
			if self.threads[i].state == "dead" then
				table.remove( self.threads, i )
			end
		end
	end

	function t:count()
		return #self.threads
	end

	function t:list()
		local t = {}
		for i = 1, #self.threads do
			t[i] = self.threads[i]
		end
		return t
	end

	return t
end

function resume( ... )
	for i = #running, 1, -1 do
		running[i]:update( ... )
		if running[i].state == "stopped" then
			running[i].state = "dead"
			table.remove( running, i )
		end
	end
end

function count()
	return #running
end

function list()
	local t = {}
	for i = 1, #running do
		t[i] = running[i]
	end
	return t
end
