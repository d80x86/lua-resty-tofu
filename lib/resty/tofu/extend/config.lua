--
-- @file conf.lua
-- @author d
-- @brief 加载lua语法的配置文件
--


local _util				= require 'resty.tofu.util'
local _conf_load	= _util.conf_load
local _tab_merge	= _util.tab_merge



local _M = { _VERSION = '0.1.1'}



--
-- 缺省配置
--
local _opts = {
	prefix	= 'conf',
	env			= nil,
	default	= 'config',
}




--
--
--
local function _load(conf_file, opts)
	opts = opts or {}
	if opts.prefix then
		conf_file = opts.prefix .. '/' .. conf_file
	end
  local res, err = _conf_load(conf_file .. '.lua')
	if err and 'cannot open' ~= err:sub(1, 11) then
		return nil, err
	end

	local conf = res

	if opts.env then
		res, err = _conf_load(conf_file .. '.' .. opts.env .. '.lua')
		if res then
			_tab_merge(conf, res)
		elseif err and 'cannot open' ~= err:sub(1, 11) then
			return nil, err
		end
	end

	return conf
end




--
--
--
function _M._install(opts)
	opts = _tab_merge({}, _opts, opts)

	-- cache
	local	_conf		= {}
	local _ready	= {}

	local __index = function(t, key)
								local v = rawget(_conf, key)
								if not v and not rawget(_ready, key) then
									local conf, err = _load(key, opts)
									if conf then
										_tab_merge(_conf, conf)
										v = rawget(_conf, key)
										rawset(_ready, key, true)
									elseif err then
										(tofu and tofu.log and tofu.log.e or error)(err)
									end
								end
								return v
							end

	local __newindex = function(t, key, v)
		rawset(_conf, key, v)
		rawset(_ready, key, true)
	end

	-- preload config
	__index(opts, opts.default)

	return setmetatable({}, {__index = __index, __newindex = __newindex})
end



--
--
--
function _M.read(conf_file, opts)
	opts = opts or {}
	return _load(conf_file, opts)
end


--
--
--
function _M.new(opts)
	return _M._install(opts)
end



return _M 

