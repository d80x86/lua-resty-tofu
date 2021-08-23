--
-- @file x6.lua
-- @author d
-- @version 0.1.1
-- @brief 中间件发动机
--

local _M = { _VERSION = '0.1.1' }
local _mt = { __index = _M }


--
--
--
local function _iscallable(t)
	local t = type (t)
	if 'table' == t then
		local mt = getmetatable(t) or {}
		t = type (mt.__call)
	end
	return 'function' == t
end


-- 
-- new
-- 
-- @return x6
--
function _M.new()
	local obj = {
		_middleware = {}
	}
	return setmetatable(obj, _mt)
end




--
-- 添加中间件
-- @param fn
--
function _M:use(fn)
	if not _iscallable(fn) then
		error('middleware must de a function or callable')
	end
	table.insert(self._middleware, fn)
	return self
end




--
-- 开始处理
--
function _M:handle(ctx)
	ctx = ctx or {}
	local n		= 0
	local middleware = self._middleware
	local function _flow()
		n = n + 1
		local fn = middleware[n]
		if fn then
			fn(ctx, _flow)	
		end
	end
	_flow()
end





return _M

