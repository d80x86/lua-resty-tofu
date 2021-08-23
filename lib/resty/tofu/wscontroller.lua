--
-- @author d
-- @brief websocket controller
--
--

local _tabnew = table.new
local _concat = table.concat

local _wss		= require 'resty.websocket.server'
local _merge	= require 'resty.tofu.util'.tab_merge


local _opts = {
	timeout = 5000,
	max_payload_len = 65535,
	-- send_masked = false,
}



local _M = {}



-- 
-- @param m table event handler
-- {
--	 _open(wb) --> return state
--	 _close(wb, state)
--	 _data(wb, data, state)
--	 _ping(wb, data, state)
--	 _pong(wb, data, state)
--	 _timeout(wb, state)
-- }
--
-- @param opts = {
--	tiemout
--	max_payload_len
--	send_masked
-- }
--
function _M.upgrade(m, opts)
	assert('table' == type(m), 'argument #1 need table type')
	assert(not opts or 'table' == type(opts), 'argument #2 need table type')
	opts = _merge(opts or {}, _opts) 
	local wb, err = _wss:new(opts)
	if not wb then
		return false, err
	end

	-- event handle
	local handle_open			= m['_open']			-- fn(wb)
	local handle_close		= m['_close']			-- fn(wb, state)
	local handle_data			= m['_data']			-- fn(wb, data, state)
	local handle_ping			= m['_ping']			-- fn(wb, data, state)
	local handle_pong			= m['_pong']			-- fn(wb, data, state)
	local handle_timeout	= m['_timeout']		-- fn(wb, state)

	local state = nil
	local buf = _tabnew(8, 0)

	-- event: on open
	if handle_open then
		state = handle_open(wb)
	end

	repeat
		local data, typ, err = wb:recv_frame()
		-- ws event: on data
		if data and ('text' == typ or 'binary' == typ) then
			if handle_data then
				handle_data(wb, data, state)
			end

		-- data fragmentation (more frames data)
		elseif 'continuation' == typ then
			buf[#buf + 1] = data
			if not err then
				data = _concat(buf)
				buf = _tabnew(8, 0)
				if handle_data  then
					handle_data(wb, data, state)
				end
			end

		-- ws event: on ping
		elseif 'ping' == typ then
			if handle_ping then
				handle_ping(wb, data, state)
			else
				wb:send_pong(data)
			end

		-- ws event: on pong
		elseif 'pong' == typ then
			if handle_pong then
				handle_pong(wb, data, state)
			end
			-- just discard the incoming pong frame

		-- ws event: on timeout
		else
			if handle_timeout then
				handle_timeout(wb, state)
			end
		end
	until 'close' == typ

	-- event: on close
	if handle_close then
		handle_close(wb, state)
	end
										
end




return _M

