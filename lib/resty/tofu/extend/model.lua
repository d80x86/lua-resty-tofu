--
-- @file mode.lua
-- @author d
-- @version 0.1.0
--

local _base		= require 'resty.tofu.model-mysql-helper'
local _refile	= require 'resty.tofu.refile'
local _util		= require 'resty.tofu.util'
local _merge	= _util.tab_merge
local _func		= _util.functional


local _default = {
  -- path   = 'unix socket'
  host      = '127.0.0.1',
  port      = 3306,
  database  = 'mysql_db_name',
  prefix    = '',
  user      = 'root',
  password  = '',
  charset   = 'utf8',
  timeout   = 5 * 1000,
  max_packet_size = 2 * 1024 * 1024,
  pool_size = 64,
  pool_idle_timeout = 900 * 1000,

  logger    = tofu and tofu.log.n or print,
}


--
--
--
local _model_root = tofu.APP_PATH .. 'model/'


--
--
--
local function _getmodel(name)
	if not name then return end
	local f = _model_root .. name .. '.lua'
	return _refile.load(f)
end




--
--
--
return function(options)

	--
	-- @param name 表名 | model/<name>.lua
	-- @run_opts 配置 | model
	--
	local function _model(name, run_opts)
		local model, err = _getmodel(name) or {}
		local obj = _merge({}, _default, model)

		run_opts = run_opts or options.default
		if 'string' == type(run_opts) then
			run_opts = options[run_opts]
		end

		local ot = type(run_opts)
		if 'table' == ot then
			_merge(obj, run_opts[0] or run_opts) -- 兼容函数化的run_opts
		elseif 'function' == ot then
			obj._parser = run_opts
		else
			error('model invalid argment #2')
		end

		-- 表名
		obj.name = obj.prefix .. (name or '')

		-- 重写 x.model()方法, 继成当前配置(状态, 如链接等...)
		obj.model = function(_, name, new_opts)
									new_opts = _merge({}, obj, new_opts)
									return _model(name, new_opts)
								end

		setmetatable(obj, {__index = _base})
		-- 函数化table,仅是为了支持链式
		return _func(obj)
	end

	return _model

end


