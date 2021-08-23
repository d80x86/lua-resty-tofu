--
-- tofu guard 参数过滤中间件
-- @file guard.lua
-- @author d
-- @version 0.1.1
--


local _refile				= require 'resty.tofu.refile'
local _ctx					= require 'resty.tofu.ctx'
local _log					= tofu.log
local _sub					= string.sub


--
--
--
--
return function(options)
	options = options or {}

	-- default
	local _guard_root = options.guard_root or tofu.APP_PATH .. 'guard/'
	local _suffix			= options.suffix or ''
	

	local function _gethandler(p)
		if not p then return nil end
		local f = _guard_root .. p .. '.lua'
		local h, err =  _refile.load(f, false)
		if err and 'cannot open' ~= _sub(err, 1, 11)then
			tofu.log.w(err)
		end
		return h
	end
	
	
	return function (ctx, flow)
		local handler = _gethandler(ctx.handler) 
		if not handler then
			return flow()
		end
	
		-- enter
		local fn_enter = handler['_enter']
		if 'function' == type(fn_enter)
		and false == fn_enter(ctx.args) then
			return
		end
	
		-- validate
		local fn = handler[ctx.action .. _suffix]
		if fn and false == fn(ctx.args) then
			return
		end
	
		flow()
	end


end -- end middleware

