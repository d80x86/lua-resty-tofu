--
-- @file builtin.lua
-- @author d
-- @version 0.1.1
--

local _json = require 'cjson.safe'

local _tofu			= require 'resty.tofu.mate'.tofu
local _ctx			= require 'resty.tofu.ctx'
local _util			= require 'resty.tofu.util'
local _merge		= _util.tab_merge
local _isempty	= _util.isempty




local _M = {_VERSION='0.1.1'}




local _options = {
	state_field		= 'errno',
	message_field = 'errmsg',
	data_field		= 'data',
	default_state	= 0,
}

local _conf = _util.conf_load(_tofu.ROOT_PATH .. 'conf/config.lua')
_merge(_options, _conf)



--
-- 获取请求参 (优先级 post > get > uri )
-- 依赖中间件: tofu.middlewate.payload
-- 
function _M.args(name) 
	local args = _ctx.fetch().args

	if name then
		-- return args[name]
		return args(name)
	end

	return args
end


function _M.response(sts, msg, data)
	if _isempty(ngx.header['Content-Type']) then
		ngx.header['Content-Type'] = 'application/json'
	end
	local result = {
		[_options.state_field]		= sts or _options.default_state,
		[_options.message_field]	= msg or '',
		[_options.data_field]			= data,
	}
	ngx.print(_json.encode(result))
end


--
--
--
function _M.success(data, msg)
	_M.response(_options.default_state, msg, data) 
	return false
end



--
--
--
function _M.fail(sts, msg, data)
	_M.response(sts, msg, data) 
	return false
end




return _M


