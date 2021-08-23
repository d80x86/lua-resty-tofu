--
-- @file inotify.lua
-- @author d
-- @brif 文件监测
-- 依赖: inotify 库
--
--
-- example --
--
--	local w = _M.new(opts)
--	w:add_watch('.')
--	w:start( function (iev)
--		print ('mask:', iev.mask, ' # ',iev.path ..'/'.. iev.name)
--	end)


-- -----------------------------------------------
-- @param opts {
--	buf_size : 4096 byte
--	timeout	 : 0.23 s
-- }
--
-- @param iev (inotify_event) {
--	isdir
--	mask
--	path
--	name
-- }





local _bit	= require 'bit'
local _ffi	= require 'ffi'
local _c		= _ffi.C


_ffi.cdef [[

int inotify_init(void);
int inotify_init1(int __flags);
int inotify_add_watch(int fd, const char *pathname, uint32_t mask);
int inotify_rm_watch(int __fd, int __wd);

int read(int fd, void *buf, size_t count);


struct inotify_event {
	int				wd; 
	uint32_t	mask;
	uint32_t	cookie;
	uint32_t	len;
	char name	[];
};


]]



local _IN = {
	ACCESS				= 0x00000001,
	MODIFY				= 0x00000002,
  ATTRIB				= 0x00000004,
	CLOSE_WRITE		= 0x00000008,
	CLOSE_NOWRITE	= 0x00000010,
	CLOSE					= _bit.bor(0x8, 0x10),
	OPEN					= 0x00000020,
	MOVED_FROM		= 0x00000040,
	MOVED_TO			= 0x00000080,
	MOVE					= _bit.bor(0x40, 0x80), -- MOVED_FROM | MOVED_TO
	CREATE				= 0x00000100,
	DELETE				= 0x00000200,
	DELETE_SELF		= 0x00000400,
	MOVE_SELF			= 0x00000800,

	UNMOUNT				= 0x00002000,
	Q_OVERFLOW		= 0x00004000,
	IGNORED				= 0x00008000,



	ISDIR					= 0x40000000,
	
	NONBLOCK			= 0x00000800,	-- 00004000
	CLOEXEC				= 0x00080000, -- 02000000
}

_IN.ALL_EVENTS = _bit.bor(
	_IN.ACCESS				,
	_IN.MODIFY				,
  _IN.ATTRIB				,
	_IN.CLOSE_WRITE		,
	_IN.CLOSE_NOWRITE	,
	_IN.CLOSE					,
	_IN.OPEN					,
	_IN.MOVED_FROM		,
	_IN.MOVED_TO			,
	_IN.MOVE					,
	_IN.CREATE				,
	_IN.DELETE				,
	_IN.DELETE_SELF		,
	_IN.MOVE_SELF		
)



local _IN_MAP = {}
for k, v in pairs(_IN) do
	_IN_MAP[v] = k
end


local _EVT_MASK = _bit.bor(
	_IN.MODIFY,
	_IN.CREATE,
	_IN.DELETE,
	_IN.MOVE
)





local _M = { _VERSION = '0.1.1' }
_M.IN = _IN
_M.IN_MAP = _IN_MAP




--
-- @param opts {
--	buf_size	: 4096 byte
--	timeout		: 0.23 s
-- }
--
function _M.new(opts)
	opts = opts or {}
	local obj = {
								_buf_size = opts.buf_size or 4096,
								_timeout	= 0.23,
							  _wds = {},
							}
	obj._fd = _c.inotify_init1(0x80800) -- NONBLOCK | CLOEXEC
	return setmetatable(obj, { __index = _M })
end




--
-- @param dir 目录
--
function _M:add_watch(dir)
	local cmd = 'find ' .. dir .. ' -type d'
	local f = io.popen(cmd)
	for line in f:lines() do
		local wd = _c.inotify_add_watch(self._fd, line, _EVT_MASK)
		if 0 < wd then
			self._wds[wd] = line
		end
	end
end




--
--
--
function _M:rm_watch(wd)
	self._wds[wd] = nil
	_c.inotify_rm_watch(self._fd, wd)
end




--
--
--
function _M:stop()
	self._iswork = nil
end




--
--
--
function _M:start(handler)
	if self._iswork then return end
	self._iswork = true
	local iev = _ffi.new('struct inotify_event')
	local iev_size = _ffi.sizeof(iev)
	local buf = _ffi.new('uint8_t[?]', self._buf_size)
	local ret = 0
	
	-- -- 
	-- while self._iswork do
	-- 	ret = _c.read(self._fd, buf, self._buf_size)
	-- 	if 0 < ret then
	-- 		local i = 0
	-- 		while i < ret do	
	-- 			local iev = _ffi.cast('struct inotify_event *', buf + i)
	-- 			i = i + iev_size + iev.len
	-- 			local info = {
	-- 					isdir = 0 < _bit.band(iev.mask, _IN.ISDIR),
	-- 					mask	= _bit.band(iev.mask, 0xffff) or iev.mask,
	-- 					path	= self._wds[iev.wd] or '.',
	-- 					name	= _ffi.string(iev.name, iev.len)
	-- 			}

	-- 				-- pass
	-- 			if _IN.IGNORED == info.mask then

	-- 			--
	-- 			elseif info.isdir and _IN.CREATE == info.mask then
	-- 				self:add_watch(info.path .. '/' .. info.name)

	-- 			--
	-- 			elseif info.isdir and _IN.DELETE_SELF == info.mask then
	-- 				self:rm_watch(iev.wd)

	-- 			--
	-- 			elseif handler then
	-- 				handler(info)
	-- 			end
	-- 		end
	-- 	end
	-- 	ngx.sleep(self._timeout)
	-- end

	local function loop()
		if not self._iswork then return end
		ret = _c.read(self._fd, buf, self._buf_size)
		if 0 < ret then
			local i = 0
			while i < ret do	
				local iev = _ffi.cast('struct inotify_event *', buf + i)
				i = i + iev_size + iev.len
				local info = {
						isdir = 0 < _bit.band(iev.mask, _IN.ISDIR),
						mask	= _bit.band(iev.mask, 0xffff) or iev.mask,
						path	= self._wds[iev.wd] or '.',
						name	= _ffi.string(iev.name)
				}

					-- pass
				if _IN.IGNORED == info.mask then

				--
				elseif info.isdir and _IN.CREATE == info.mask then
					self:add_watch(info.path .. '/' .. info.name)

				--
				elseif info.isdir and _IN.DELETE_SELF == info.mask then
					self:rm_watch(iev.wd)

				--
				elseif handler then
					handler(info)
				end
			end
		end
		ngx.timer.at(self._timeout, loop)
	end

	loop()

end



return _M





