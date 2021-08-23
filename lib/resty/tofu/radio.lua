--
-- @file radio.lua
-- @author d
-- @version 0.1.1
-- @brief 低频广播消息服务
--
-- 依赖:
--		lua_shared_dict
--
-- ---------------------------
-- example
--
-- 创建频道
-- 1) M.new('chan name')
-- 2) M.turnon('chan name')
--
--
-- 广播消息
-- m:broadcast( 'string msg' )
-- ...
--


local _semaphore	= require 'ngx.semaphore'
local _abs				= math.abs


local _M = { _VERSION = 0.1 }


local _KEY_IDX		= ':idx'
local _KEY_SN			= ':sn'
local _KEY_DATA_	= ':data:'

local _conf = {
	store			= 'radio',
	maxn			= 2^52,
	ttl				= 0,
	chan			= '_',
}

local _chans = {}


--
--
--
local function _chan_new(opts)
	local obj = {}
	obj.store			= opts.store										or	_conf.store
	obj.maxn			= opts.maxn											or 	_conf.maxn
	obj.chan			= opts.chan											or	_conf.chan
	obj.key_idx		= obj.chan .. _KEY_IDX
	obj.key_sn		= obj.chan .. _KEY_SN
	obj.key_data_	= obj.chan .. _KEY_DATA_
	obj.shd				= ngx.shared[obj.store]
	obj.idx				= obj.shd:get(obj.key_idx)			or 0
	obj.sema			= _semaphore.new()

	return obj
end




--
--
--
local function _turnon(opts)
	if 'table' ~= type (opts) then
		opts = { chan = tostring (opts or _conf.chan)}
	end

	local chan = _chans[opts.chan]
	if not chan then
		chan = _chan_new(opts)
		_chans[opts.chan] = chan
	end

	return chan, opts
end




--
--
--
function _M.turnon(opts)
	_turnon(opts)
end




--
-- @param		opts		string | table
--									string: channel name
--									table: {
--										chan			: string		channel name
--										store			: string		shared DICT name	default:radio
--										ttl				: float			time-to-live in seconds		default: 0
--										maxn			: int				how many messages can be cached at most
--									}
--
function _M.new(opts)
	local chan, opts  = _turnon(opts)
	local obj = {
		ttl			= opts.ttl		or _conf.ttl,
		sn			= chan.shd:incr(chan.key_sn, 1, 0),
		_chan		= opts.chan		or _conf.chan,
		_idx		= chan.shd:incr(chan.key_idx, 0, 0),
	}

	return setmetatable(obj, {__index = _M})
end



--
-- 获取当前 chan 名称
--
function _M:chan()
	return self._chan
end




--
-- 广播一个消息
--
function _M:broadcast(msg)
	local chan	= _chans[self._chan]
	if not chan then
		return false, 'chan not exist'
	end

	local shd		= chan.shd
	local idx		= chan.shd:incr(chan.key_idx, 1, 0)
	if chan.maxn <= idx then
		-- need lock !!!
		idx = 0
		shd:set(chan.key_idx, idx)
	end

	chan.idx = idx
	shd:set(chan.key_data_ .. idx, msg, self.ttl) 
	local count = chan.sema:count()
	if count < 0 then
		chan.sema:post(_abs(count))
	end

	return true
end




-- 
-- wait and return message
-- 
-- @return msg, chan, err
--
function _M:ready()
	local chan = _chans[self._chan]
	if not chan then
		return nil, self._chan, 'chan not exist'
	end

	-- 再次检查 idx 的更新 (必须)
	-- 并发会使 self._idx > chan.idx
	if self._idx ~= chan.idx then
		chan.idx = chan.shd:get(chan.key_idx)
	end

	repeat until self._idx ~= chan.idx or chan.sema:wait(10)
	self._idx = (self._idx + 1) % chan.maxn 
	return chan.shd:get(chan.key_data_ .. self._idx), chan.chan
end




-- 
-- turn channel
--
function _M:turn(ch)
	local chan = _chans[ch]
	if not chan then
		return nil, 'chan not exist'
	end
	self._chan = ch
	-- self._idx = chan.shd:get(chan.key_idx)
	self._idx = chan.shd:incr(chan.key_idx,0, 0)
	return true
end




--
-- get history message
--
function _M:history(n)
	local msgs = {}
	local chan = _chans[self:chan()]
	if not chan then
		return nil, 'chan not exist'
	end

	local idx
	if n <= self._idx then
		idx = self._idx - n
	else
		idx = chan.maxn - n + self._idx
	end

	for i=1, n do
		local msg = chan.shd:get(chan.key_data_ .. ((idx + i) % chan.maxn))
		if msg then
			msgs[#msgs+1] = msg
		end
	end

	return msgs
end



--
-- synchronization frequency between workers
--

local _wsrate		= 1 / 24


local function _worker_sync ()
	for _, chan in pairs (_chans) do
		local curidx = chan.shd:get(chan.key_idx) or 0
		if chan.idx ~= curidx then
			chan.idx = curidx
			local count = chan.sema:count()
			if count < 0 then
				chan.sema:post(_abs(count))
			end
		end
	end
end


ngx.timer.every(_wsrate, _worker_sync)


return _M


