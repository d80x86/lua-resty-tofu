--
-- @author d
-- @version 0.1.1
-- @brief cache (shm)
--


local _resty_lock		= require 'resty.lock'
local _util					= require 'resty.tofu.util'
local _encode				= require 'cjson'.encode
local _decode				= require 'cjson'.decode

local _M = { _VERSION = '0.1.0' }


local _opts = {
	ttl = 90 * 60,		-- 秒	 -- 90分钟
	shm = 'tofu_cache_dict', -- lua_shared_dict 配置
}


local _KEY_ = 'cache:'
local _store


local function _get_and_lock(key)
	local lock, err = _resty_lock:new(_opts.shm)
	if not lock then
		error (err)
	end
	local elapsed, err = lock:lock('lock:'..key)
	if not elapsed then
		error (err)
	end
	return lock
end



--
--
--
function _M._install(opts)
	_util.tab_merge(_opts, opts)
	_store = ngx.shared[_opts.shm]
	if not _store then
		error ('extend cache shm need config lua_shared_dict name on tofu.nginx.conf')
	end
	return _M
end


-- ----------------------------
-- api
--

-- 获取cache的值
-- @param key string
-- @param init value | function()
-- @param ... init(...) v
--
function _M.get(key, init, ...)
	if not key then
		error 'key error'
	end
	key = _KEY_ .. key
	local val = _store:get(key)
	if nil ~= val then
		return _decode(val)
	end

	local lock = _get_and_lock(key)
	val = _store:get(key)
	if nil == val then
		if 'function' == type(init) then
			val = init(...)
		else
			val = init
		end
		if nil ~= val then
			local ok, err = _store:set(key, _encode(val), _opts.ttl)
			if not ok then
				-- error (err) -- 'no memory'
				return nil, err
			end
		end
	end
	lock:unlock()
	return val
end


--
--
--
function _M.set(key, val, ttl)
	if not key then
		error 'key error'
	end
	key = _KEY_ .. key
	local ok, err = _store:set(key, _encode(val), ttl or _opts.ttl)
	if not ok then
		error (err)
	end
end


--
--
--
function _M.del(key)
	key = _KEY_ .. key
	_store:delete(key)
end



--
--
--
function _M.incr(key, val, init, ttl)
	if not key then
		error 'key error'
	end
	key = _KEY_ .. key
	local newval, err = _store:incr(key, val, init, ttl or _opts.ttl)
	if err then
		error (err)
	end
	return newval
end


--
--
--
function _M.capacity()
	return _store:capacity()
end


return _M

