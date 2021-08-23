--
-- tofu cors 跨域中间件
-- @file cors.lua
-- @author d
-- @version 0.1.0
--


local function _set(name, value)
	if nil ~= value then
		ngx.header[name] = value
	end
end



-- --------------------------------------------------------------------------
--
-- @param opts {
--	allow_methods					'GET,HEAD,PUT,POST,DELETE,PATCH'
--	allow_credentials	
--	allow_origin	
--	allow_headers	
--	expose_headers
--	max_age	
-- }
--
return function(opts)

	-- 
	-- options
	--
	opts = opts or {}
	local _allow_methods			= opts.allow_methods or 'GET,HEAD,PUT,POST,DELETE,PATCH'
	local _allow_credentials	= opts.allow_credentials
	local _allow_origin				= opts.allow_origin
	local _allow_headers			= opts.allow_headers
	local _expose_headers			= opts.expose_headers
	local _max_age						= opts.max_age


	return function(ctx, flow)
		local headers = ngx.req.get_headers()
		_set('Access-Control-Allow-Origin',				_allow_origin or headers['origin'] or '*')
		_set('Access-Control-Allow-Credentials',	_allow_credentials)
		_set('Access-Control-Expose-Headers',			_expose_headers)
	
		if 'OPTIONS' == ngx.req.get_method() then
			local request_method= headers['access-control-request-method']
			if not request_method then
				return flow()
			end
	
			_set('Access-Control-Allow-Methods',	_allow_methods or request_method)
			_set('Access-Control-Allow-Headers',	_allow_headers or headers['access-control-request-headers'] or '*')
			_set('Access-Control-Max-Age',				_max_age)
	
			ngx.status = 204
			return
		end
	
		return flow()
	end


end	-- end middleware


