--
-- @file crontab.lua
-- @author d
-- @version 0.1.0
-- @brief 定时任务服务
--


local _os_time	= os.time
local _os_date	= os.date
local _gmatch		= string.gmatch


local _M = { _VERSION = '0.1.0' }




local _opts = {}


--
--
--
local function _check_positive_int(n, v)
	if 'number' ~= type(v) or v < 0 then
		error (n .. ' must be a positive number') 
	end
end



local function _is_callable(f)
	local t = type(f)

	if 'function' == t then
		return true
	end

	if 'table' == t then
		local mt = getmetatable(f)
		return 'table' == type(mt) and 'function' == type(mt.__call)
	end

	return false
end




-- 
--
--
local function _cron_calc(item, v)
	for r in _gmatch(item, '[^,]+') do
		-- 特殊 *
		do
			if '*' == r then
				return true, 0
			end
		end

		-- 每 */n
		do
			local _, _, a = string.find(r, '%*/(%d+)')
			if a then
				return true, tonumber(a) or 0
			end
		end

		-- 准点 a 
		do
			local a = tonumber(r)
			if 'number' == type(a) and a == v then
				return true, 0
			end
		end

		-- 范围 a-b/c
		do
			local _, _, a, b, c = string.find(r, '(%d+)%-(%d+)/?(%d*)')
			if a and b and tonumber(a) <= v and v <= tonumber(b) then
				return true, tonumber(c) or 0
			end
		end

	end

	return false, 0
end

-- 
--
--
local function _cron_test(self)
	local tm = self.time
	local now = _os_date('*t')
	for _, k in ipairs {'min', 'hour', 'day', 'month', 'wday'} do
		local ok, v = _cron_calc(tm[k], now[k])
		if not ok then 
			return false
		end
		if 0 < v then
			local run = self.running
			run[k] = (run[k] or -1) + 1		-- -1: 抵消第一次触发时间问题
			if run[k] ~= v then
				self.lst = _os_time()
				return false
			else
				run[k] = 0
			end
		end
	end
	return true
end



-- @param
--	update
--	time,
--	callback,
--	...args,
--
-- }
local function _clock_new(update, time, callback, ...)
	assert(update)
	assert(time)
	assert(_is_callable(callback), "callback must be a function")
	return {
		time			= time,
		callback	= callback,
		args			= {...},
		running		= 0,
		update		= update,
		lst				= 0,
	}
end



local function _clock_update_after(self, dt)
	if self.time < self.running then return true end
	self.running = self.running + dt
	if self.time <= self.running then
		self.callback(unpack(self.args))
		return true
	end
end

local function _clock_update_every(self, dt)
	self.running = self.running + dt
	if self.time <= self.running then
		self.callback(unpack(self.args))
		self.running = self.running - self.time
	end
end

local function _clock_update_cron(self, _dt)
	local now_time = _os_time()
	local tm	= self.time
	-- 要求间隔在于1分钟
	if 59 < now_time - self.lst	and _cron_test(self) then
		self.callback(unpack(self.args))
		self.lst = now_time
	end
end

local function _clock_reset(self, dt)
	dt = dt or 0
	_check_positive_int('dt', dt)
	self.running = dt
end


local function _clock_new_after(...)
	return _clock_new(_clock_update_after, ...)
end


local function _clock_new_every(...)
	return _clock_new(_clock_update_every, ...)
end


local function _clock_new_cron(...)
	local clock = _clock_new(_clock_update_cron, ...)
	clock.running = {}
	return clock
end




-- -----------------------------------------
--
--



local _is_runing	= false
local _clocks			= {}
local _last_time	= _os_time()


--
--
--
local function _isworker(id)
	return ngx.worker.id() == (id or 0)
end


--
--
--
local function _update(dt)
	for id, c in pairs(_clocks) do
		if c:update(dt) then
			_clocks[id] = nil
		end
	end
end


--
--
--
local function _loop()
	local t = _os_time()
	_update(t - _last_time)
	_last_time = t
	_is_runing = ngx.timer.at(1, _loop)

end


--
--
--
function _M.start()
	-- if not _isworker() then return end
	if _is_runing then 
		return
	end
	_last_time = _os_time()
	-- _loop()
	_is_runing = ngx.timer.at(0, _loop)
end


--
--
--
function _M.stop()
	-- if not _isworker() then return end
	if _is_runing then
		ngx.thread.kill(_is_runing)
		_is_runing = false
	end
end


-- @param [named],second, handle, ...
function _M.add_after(p1, p2, p3, ...)
	-- #3
	if 'string' == type(p1) then
		_check_positive_int('after', p2)
		local named = p1
		_clocks[named] = _clock_new_after(p2, p3, ...)
		return named

	-- #2
	else
		_check_positive_int('dt', p1)
		local named = #_clocks + 1
		_clocks[named] = _clock_new_after(p1, p2, p3, ...)
		return named
	end
end



-- @param [named], interval, handle, ...
function _M.add_every(p1, p2, p3, ...)
	-- #3
	if 'string' == type(p1) then
		_check_positive_int('interval', p2)
		local named = p1
		_clocks[named] = _clock_new_every(p2, p3, ...)
		return named

	-- #2
	else
		_check_positive_int('dt', p1)
		local named = #_clocks + 1
		_clocks[named] = _clock_new_every(p1, p2, p3, ...)
		return named
	end
end



--
-- @param [named], cron, handle, ...
function _M.add_cron(p1, p2, p3, ...)
	local named, cron, handle, n = p1, p2, p3, 3
	if 'string' == type(p1) and _is_callable(p2)  then
		named		= #_clocks + 1
		cron		= p1
		handle	= p2
		n				= 2
	end

	local t = {}
	for v in _gmatch(cron, '[%d/,%-*]+') do
		local i = tonumber(v) or v
		t[#t+1] = i
	end
	if 5 ~= #t then
		error ( string.format('crontab string "%s" error', cron))
	end
	local cron_time = {
		min		= t[1],
		hour	= t[2],
		day		= t[3],
		month	= t[4],
		wday	= t[5],
	}

	-- #3
	if 3 == n then
		_clocks[named] = _clock_new_cron(cron_time, handle, ...)
	
	-- #2
	else
		_clocks[named] = _clock_new_cron(cron_time, handle, p3, ...)
	end
	
	return named
end


function _M.rm(id)
end



return _M

