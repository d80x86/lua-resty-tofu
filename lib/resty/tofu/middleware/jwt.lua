--
-- tofu jwt 检验中间件
-- @file jwt.lua
-- @author d
-- @version 0.1.0
-- @deps luarocks cdbattagw/lua-resty-jwt
-- @see https://github.com/cdbattags/lua-resty-jwt
--
-- 正确
--	ngx.ctx.state[key] = jwt payload
--
-- 错误:
--	ngx.ctx.state.jwt_error = {
--		reason,
--		verified	: false
--
--		... jwt info
--		hader,
--		payload,
--		signature,
--		...
--	}

local _sub	= string.sub

local _jwt	= require 'resty.jwt'





local function _bearer_token()
	local str = ngx.req.get_headers()['authorization'] or ''
	if 'Bearer' ~= _sub(str, 1, 6) then
		return nil
	end
	return _sub(str, 8)
end



-- --------------------------------------------------------------------
--
-- @param opts {
--	secret					: string | function->string 安全码
--	key							: string 结果(payload) 保存到 ngx.ctx.state[key], key default: user
--	passthrough			: bool		default false
--	gettoken				: authorization bearer
-- }
--
return function (opts)

	--
	-- options
	--
	opts = opts or {}
	local _gettoken			= opts.gettoken or _bearer_token
	local _secret				= opts.secret
	local _key					= opts.key or 'user'
	local _passthrough	= opts.passthrough
	
	
	return function(ctx, flow)
		local token = _gettoken(ctx)
		local info	= _jwt:verify(_secret, token)
		if not ngx.ctx.state then
			ngx.ctx.state = {}
		end
		-- ok
		if info.verified then
			ngx.ctx.state[_key] = info.payload
			return flow()
		end
	
		-- err
		ngx.ctx.state['jwt_error'] = info
		if _passthrough then
			return flow()
		end
	end


end	-- end middleware
