--
-- @file tofu.lua
-- @author d
-- 
-- 


local _TOFU_PATH	= debug.getinfo(1, 'S').source:sub(2,-1):match('^.*/')
-- package.path = package.path .. _TOFU_PATH .. '?.lua;'


--
-- 一些缺省配置
--
local _options = {
	env				= 'production',  -- | development
	app_path	= 'lua/',
}



local _mate = require 'resty.tofu.mate'
local _M		= { _VERSION = _mate._VERSION }
local _tofu = _mate.tofu
local _core = _mate.core

_tofu.VERSION		= _mate._VERSION
_tofu.TOFU_PATH	= _TOFU_PATH
_tofu.ROOT_PATH	= ngx.config.prefix()
_tofu.APP_PATH	= _tofu.ROOT_PATH .. _options.app_path
_tofu.ENV				= os.getenv('NGX_ENV') or _options.env

-- ----------------------------------------------------
-- hack
--
-- 把 tofu 设置为全局
local new_env = getfenv(0)
local old_mt	= getmetatable(new_env)
setmetatable(new_env, {})
new_env.tofu = _tofu
setmetatable(new_env, old_mt)


--
-- 重写 error 
-- 只为更友好地显示错误
--
local _log = require 'resty.tofu.extend.log'.ngxlog()
local function error(msg)
	_log.e(msg)
	ngx.exit()
	-- os.exit()
end



--
-- 读取 conf 下的配置
--
local _conf = require 'resty.tofu.extend.config'._install({
								env			= _tofu.ENV,
								prefix	= _tofu.ROOT_PATH .. 'conf/',
							})


-- ---------------------------------------------------
-- load extend 
--
--
do -- load extend begin --

	local _string_sub = string.sub


	local function _extend_install(named, handle, ...)
		if '' == named then
			error('extend named cannot be null("") ')
		end
		if _tofu[named] then
			error('extend '..named.. ' is already installed')
		end
		if 'string' == type(handle) then
			local src = _tofu.APP_PATH .. 'extend/'.. string.gsub(handle, '%.', '/').. '.lua'
			local ok, res = pcall(dofile, src)
			if not ok then
				if 'cannot open' == res:sub(1, 11) then
					ok, res = pcall(require, handle)
					if not ok then
						error('extend ' .. handle .. ' : ' .. res)
					end
				else
					error(res)
				end
			end
			handle = res
		end
	
		if 'function' == type(handle) then
			if not named or '' == named then
				error('extend named cannot be null("") ')
			end
			_tofu[named] = setfenv(handle, new_env)(...)
		elseif 'table' == type(handle) then
			if named then
				_tofu[named] = handle._install and handle._install(...) or handle
			else
				for k, v in pairs(handle) do
					if '_' ~= _string_sub(k,1,1) then								-- 忽略下划线开头的字段
						_tofu[k] = nil == _tofu[k] and v							-- 不能重复
							or error ('tofu.' .. k .. ' is already')
					end
				end
			end
		else
			error('load extend ' .. named .. ' error')
		end
	end
	
	
	--
	-- load extend from config
	--
	-- {
	--	{
	--		enable  = bool default true
	--		named		= 'string',
	--		[type]	=	<type name> | default,
	--		<type name> = {
	--			handle	= string | function | table<.new>
	--			options = { ... }
	--		}
	--	},
	--	...
	-- }
	--

	local extend  = _conf.extend or {}
	for _, ext in ipairs(extend) do
		if 'string' == type (ext) then
			_extend_install(nil, ext) 
		else
			if false ~= ext.enable then
				local item = ext[ext.type or 'default']
				_extend_install(ext.named, item.handle, item.options) 
			end
		end
	end



end -- load extend end --





-- --------------------------------------------------------
-- load middleware
--
--
do -- load middleware begin --

	_core._app	= require 'resty.tofu.x6' .new()
	

	-- 选项 match 处理
	local _mid_warp = function(match, handle)
		if not match then
			return handle
		end

		-- match 为正则方式
		if 'string' == type(match) then
			local re_match = ngx.re.match
			return function(ctx, flow)
				local ok = re_match(ngx.var.uri, match, 'jo')
				if ok then 
					return handle(ctx, flow)
				else 
					return flow()
				end
			end

		-- match 为函数方式
		elseif 'function' == type(match) then
			return function(ctx, flow)
				local ok = match(ctx)
				if ok then 
					return handle(ctx, flow)
				else
					return flow()
				end
			end
		end
	end
	
	--
	--
	--
	local function _middleware_install(mid)
		local handle = mid.handle
		local app = _core._app
		if 'string' == type(handle) then
			local src = _tofu.APP_PATH..'middleware/'..string.gsub(handle, '%.', '/')..'.lua'
			local ok, res = pcall(dofile, src)
			if not ok then
				if 'cannot open' == res:sub(1, 11) then
					ok, res = pcall(require, handle)
					if not ok then
						if string.find(res, 'not found', 1, true) then
							error('middleware ' .. handle .. ' not found', 2)
						else
							error(res)
						end
					end
				else
					error(res)
				end
			end
			handle = res
		end
	
		if 'function' == type(handle) then
			local h = setfenv(handle, new_env)(mid.options)
			local fn = _mid_warp(mid.match, h)
			app:use(fn)
		elseif 'table' == type(handle) then
			local h = setfenv(handle.new, new_env)(mid.options)
			local fn = _mid_warp(mid.match, h)
			app:use(fn)
		else
			error('load middleware  ' .. handle .. ' error')
		end
	end
	
	
	
	--
	-- load middleware from config
	--
	-- {
	--	{
	--		enable		= bool default:true
	--		handle		= function | string | table<.new>
	--		options		= { ... }
	--	},
	--	...
	-- }
	--
	local middleware = _conf.middleware or {}
	for _, mid in ipairs(middleware) do
		if 'string' == type(mid) then
			mid = {handle = mid}
		end
		if false ~= mid.enable then
			-- _middleware_install(mid.handle, mid.options)
			_middleware_install(mid)
		end
	end


end -- load middleware end --




-- -----------------------------------------------------
-- 
--
if 0 == ngx.worker.id() and _tofu.log then
	_tofu.log.n('tofu version:', _M._VERSION)
	_tofu.log.n('environment:', _tofu.ENV)
	if _conf.ngx_port then
		_tofu.log.n('listen:', _conf.ngx_port)
	end
end



-- -------------------------------------------------------
--
--
setmetatable(_tofu, old_mt)
-- ----- tofu setup end ---------------
--




-- -------------------------------------------------
-- api
--
local _ctx = require 'resty.tofu.ctx'

function _M.start()
	local ctx = _ctx.stash()
	local ok, err = pcall(_core._app.handle, _core._app, ctx)
	if not ok then
		if _tofu.log then
			_tofu.log.e(err)
		else
			ngx.log(ngx.ERR, err)
		end
		ngx.status = 500
	end
	_ctx.apply()
	ngx.exit(ngx.status)
end



return _M


