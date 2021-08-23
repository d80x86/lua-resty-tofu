--
-- @file view.lua
-- @author d
-- @version 0.1.1
--


local _str_sub		= string.sub
local _tab_merge	= require 'resty.tofu.util'.tab_merge
local _ctx				= require 'resty.tofu.ctx'
local _template		= require 'resty.template'



--
-- 配置
--
local _options = {
	template_root	= 'view/',		-- 模版搜索路径
	extname				= '.html',		-- 模板后缀
	cache					= false,			-- 缓存(建议开发或低内存限制时禁用)
}


local _ext_len =  #_options.extname

local function _template_init()
	-- fix template_root path
	if '/' ~= _options.template_root:sub(-1) then
		_options.template_root = _options.template_root .. '/'
	end

	_ext_len =  #_options.extname
	_template.root = _options.template_root
	_template.caching(_options.cache)

end






local function _getassign()
	local ctx = _ctx.fetch()
	if not ctx.assign then
		ctx.assign = {}
	end
	return ctx.assign
end


local _M = {}


function _M.assign(param1, param2)
	local assign = _getassign()
	local pt = type (param1)
	if 'table' == pt then
		_tab_merge(assign, param1)
	elseif 'string' == pt then
		assign[param1] = param2
	else
		error ('param 1 error')
	end
	return _M
end


function _M.render(tpl, param)
	local ctx = _ctx.fetch()
	tpl = tpl or (ctx.handler .. '_' .. ctx.action .. _options.extname)
	if  _str_sub(tpl, -_ext_len) ~= _options.extname then
		tpl = tpl .. _options.extname
	end
	_template.render(tpl, param)
end


function _M.display(tpl, param)
	local assign = _getassign()
	param = _tab_merge({}, assign, param)
	_M.render(tpl, param)
	return false
end



return function(options)
	_tab_merge(_options, optins)
	_template_init()
	return _M
end

