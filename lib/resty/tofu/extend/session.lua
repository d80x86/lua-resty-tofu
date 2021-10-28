--
-- @author d
-- @version 0.1.0
-- @brief session
-- @see https://github.com/bungle/lua-resty-session
--


local _util = require 'resty.tofu.util'
local _tab_merge = _util.tab_merge



local _options = {
	name			= 'tofu_session',
	ttl				= 20 * 60,
	renewal		= true,
	-- storage		= 'shm',  -- | ''
	storage		= 'cookie',  -- | ''
	secret		= '5df7f1701b778d03d57456afea567922',
}



local _M = {}


--
-- 因为resty.session 无法在 init_worker_by_lua_* 阶段加载, 这里做一个hack
-- shm 模式有bug,这借ngx.ctx 保存ses的引用
--
local _ses = nil
local _get_ses = function (lock)
	if not _ses then
		_ses = require 'resty.session'
	end

	if not ngx.ctx.__tofu_session then
		local opts = _tab_merge({}, _options)
		ngx.ctx.__tofu_session = _ses.open(opts)
		-- 未知原因 使用 start() 会有问题 (锁死...)
		-- ngx.ctx.__tofu_session = lock and _ses.start(opts) or _ses.open(opts)
	end
	return ngx.ctx.__tofu_session
end

--
-- 适配 tofu expend 接口
--
function _M._install(opts)
	_tab_merge(_options, opts)
	_options.cookie = {lifetime = _options.ttl}
	return _M
end


-- ---------------------------------
-- api
--

--
--
--
function _M.get(key)
	local ses = _get_ses()
	local v = ses.data[key]
	if ses.expires and false ~= _options.renewal then
		ses:save()
	end
	ses:close()
	return v
end




--
--
--
function _M.set(key, value)
	if not key then
		return nil
	end

	local ses = _get_ses(true)
	local old = ses.data[key]
	ses.data[key] = value
	ses:save()
	return old
end




--
-- 删除相关session
--
function _M.destroy()
	_get_ses():destroy()
end


return _M

