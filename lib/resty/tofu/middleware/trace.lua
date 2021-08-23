--
-- tofu trace 中间件
-- @file trace.lua
-- @author d
-- @version 0.1.0
--

local _clock = require 'resty.tofu.util'.getusec
local _fmt = string.format




local _logger = function(msg)
	ngx.log(ngx.INFO, msg)
end


local function trace(ctx, flow)
	local st = _clock()
	flow()
	_logger(
		ngx.req.get_method(),
		ngx.var.request_uri,
		ngx.status,
		_fmt('%.2fms', (_clock() - st) / 1000)
	)	
end


--
-- @param options {
--	logger
-- }
--
return function (options)
	options = options or {}
	_logger = options.logger or _logger
	return trace
end
