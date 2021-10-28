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
--
--
local _prefix = 'conf'
local _env = nil
local _default = 'config'




--
--
--
local function _load(conf_file, opts)
	conf_file = opts._prefix .. '/' .. conf_file
  local res, err = _conf_load(conf_file .. '.lua')
	if err and 'cannot open' ~= err:sub(1, 11) then
		return nil, err
	end

	local conf = res

	if _env then
		res, err = _conf_load(conf_file .. '.' .. opts._env .. '.lua')
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
	local _opts = {
		_env			= opts.env		or _env,
		_prefix		= opts.prefix	or _prefix,
	}

	-- cache
	local	_conf		= {}
	local _ready	= {}

	local mt = function(t, key)
								local v = rawget(_conf, key)
								if not v or not rawget(_ready, key) then
									rawset(_ready, key, true)
									local conf, err = _load(key, _opts)
									if conf then
										_tab_merge(_conf, conf)
										v = rawget(_conf, key)
									elseif err then
										(tofu and tofu.log and tofu.log.e or error)(err)
									end
								end
								return v
							end


	mt(_opts, opts.default or _default)
	return setmetatable({}, {__index = mt})
	
end


--
--
--
function _M.new(opts)
	return _M._install(opts)
end



return _M 

