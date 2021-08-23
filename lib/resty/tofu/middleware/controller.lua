-- 
-- tofu controller 中间件
-- @file controller.lua
-- @author d
-- @version 0.1.1
--


local _sub				= string.sub

local _refile			= require 'resty.tofu.refile'
local _tab_merge	= require 'resty.tofu.util'.tab_merge
local _ctx				= require 'resty.tofu.ctx'




local _default = {
	suffix	= '',																			-- _action 后缀如 _action
	logger	= tofu and tofu.log.e or print,						-- function
	controller_root = tofu.APP_PATH .. 'controller/',
	controller_allow_underscore = false,							-- 是否允许下划线开头的controller
	action_allow_underscore = false,									-- 是否允许下划线开头的action
}


--
--
--
return function(options)
	options = _tab_merge(options, _default)

	local _suffix = options.suffix
	local _controller_root = options.controller_root
	local _controller_allow_underscore = options.controller_allow_underscore
	local _action_allow_underscore = options.action_allow_underscore
	local _log = options.logger


	local function _gethandler(p)
		local f = _controller_root .. p .. '.lua'
		local h, err = _refile.load(f)
		if err then
			error(err)
		end
		return h
	end

	return function (ctx, flow)
		if not ctx.controller then 
			ngx.status = ngx.HTTP_NOT_FOUND
			return
		end

		--
		-- 
		--
		if not _controller_allow_underscore and '_' == _sub(ctx.controller, 1,1) then
			ngx.status = ngx.HTTP_NOT_FOUND
			return
		end
		if _action_allow_underscore and '_' == _sub(ctx.action or '', 1,1) then
			ngx.status = ngx.HTTP_NOT_FOUND
			return
		end
		

		local handler = _gethandler(ctx.handler) 
		if not handler then
			_log('controller must return table')
			ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
			return 
		end

		-- enter event
		local fn_enter = handler['_enter']
		if 'function' == type(fn_enter) and false == fn_enter(ctx.args) then
			return
		end

		-- action
		local fn = handler[ctx.action .. _suffix]
		if not fn then
			ngx.status = ngx.HTTP_NOT_FOUND
			_log('controller[', ctx.handler, '] action [', ctx.action, '] not exists')
			return
		end
		if false == fn(ctx.args) then
			return
		end

		-- leave event
		local fn_leave = handler['_leave']
		if 'function' == type(fn_leave) and false == fn_leave(ctx.args) then
				return
		end

		-- next
		flow()
	end


end -- end middleware

