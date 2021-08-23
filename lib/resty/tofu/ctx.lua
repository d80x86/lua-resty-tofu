--
-- @file ctx.lua
-- @author d
--


local _M = { _VERSION = '0.1.0' }


local _ctxs = {}


function _M.stash()
	local ref = ngx.var.request_id
	local t = _ctxs[ref]
	if not t then
		t = {}
		_ctxs[ref] = t
	end
	return t
end


function _M.fetch(ref)
	ref = ref or ngx.var.request_id
	return _ctxs[ref]
end



function _M.apply()
	local ref = ngx.var.request_id
	_ctxs[ref] = nil
end


function _M.new()
	return _M
end


return _M
