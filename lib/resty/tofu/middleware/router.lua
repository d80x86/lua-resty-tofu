--
-- tofu router 路由中间件
-- @file router.lua
-- @author d
-- @version 0.1.1
--

local _concat = table.concat
local _insert = table.insert

local _util					= require 'resty.tofu.util'
local _split				=	_util.msplit
local _tab_merge		= _util.tab_merge
local _file_exists	= _util.file_exists

-- local _log = tofu.log
local _PATH = tofu.APP_PATH .. 'controller/'



local _cache = {}
local function _rule_exists(p)
	local ok = _cache[p]
	if not ok then
		ok = _file_exists(p)
		if ok then
			_cache[p] = true
		end
	end
	return ok
end

local function _rule_cache(uri, r)
	if r then
		_cache[uri] = r
		return r
	else
		return _cache[uri]
	end
end


--
-- @param uri /module/[.../../]controller/action[/arg1/arg2.../...]
--
local function _rule_default(uri, options) 
	local r = _rule_cache(uri)
	if r then
		return r
	end

	local resolve = _split(uri, '/')
	local flag, len = 1, #resolve
	local p = '' -- _PATH
	local m = options.module
	local c 
	local a
	local args = {}

	-- find module
	if 0 < len and _rule_exists(_PATH .. resolve[flag]) then
		m = resolve[flag]
		flag = flag + 1
	-- check default module
	elseif not _rule_exists(_PATH .. m) then
		return nil, 'router: module not exists'
	end
	p = m

	-- find controller
	while flag <= len do
		p = p ..'/'.. resolve[flag]
		if (_rule_exists(_PATH .. p .. '.lua')) then
			c = resolve[flag]
			break
		end
		flag = flag + 1
	end
	if not c then
		if not _rule_exists(_PATH .. p .. '/'.. options.controller .. '.lua') then
			return nil, 'router: controller not exists'
		else
			c = options.controller
			p = p .. '/' .. c
		end
	end

	flag = flag + 1
	-- find action
	a = resolve[flag] or options.action

	-- find args
	for i = flag + 1, len do
		_insert(args, resolve[i])
	end
	
	r =  {
		handler = p,
		module	= m,
		controller = c,
		action = a,
		args = args
	}

	if #args < 1 then
		_rule_cache(uri, r)
	end
		
	return r
end




--
--
--
return function (options)
	-- default
	local _options = {
		module			= 'default',
		controller	= 'index',
		action			= 'index',
	}

	_tab_merge(_options, options)

	return function (ctx, flow)
		local r, err = _rule_default(ngx.var.uri, _options)
		if not r then
			ngx.status = ngx.HTTP_NOT_FOUND
			return nil, err
		end
		-- ctx.route = r
		_tab_merge(ctx, r)
		flow()
	end

end -- end middleware


