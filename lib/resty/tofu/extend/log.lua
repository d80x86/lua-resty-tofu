--
-- @file log.lua
-- @author d
-- @brief 日志
--


local _M = { _VERSION = '0.1.1' }

local _fmt		= string.format
local _gsub		= string.gsub
local _match	= string.match
local _rep		= string.rep
local _date		= os.date
local _concat	= table.concat
local _sort		= table.sort



local _levels = {
	STDERR	= ngx.STDERR,
	EMERG		= ngx.EMERG,
	ALERT		= ngx.ALERT,
	CRIT		= ngx.CRIT,
	ERR			= ngx.ERR,
	WARN		= ngx.WARN,
	NOTICE	= ngx.NOTICE,
	INFO		= ngx.INFO,
	DEBUG		= ngx.DEBUG,
}
_M.levels = _levels

local _r_levels = {}
for k, v in pairs(_levels) do
	_r_levels[v] = string.lower(k)
end


local _colors = {
	BLACK		= 30,
	RED			= 31,
	GREEN		= 32,
	YELLOW	= 33,
	BLUE		= 34,
	MAGENTA	= 35,
	CYAN		= 36,
	WHITE		= 37,
}
_M.colors = _colors


local _lvl_colors = {
	stderr	= _colors.RED,
	emerg		= _colors.MAGENTA,
	alert		= _colors.BLUE,
	crit		= _colors.BLUE,
	err			= _colors.RED,
	warn		= _colors.YELLOW,
	notice	= _colors.CYAN,
	info		= _colors.WHITE,
	debug		= _colors.GREEN,
}


-- --
-- --
-- opt {
--	pretty
--	sort
-- }
local function _dump(obj, opt)
  if 'table' ~= type(obj) then
		return tostring(obj)
	end
	opt = opt or {level=1}
	local pretty = opt.pretty 
	local level = opt.level or 1
	local indent_str = pretty and _rep('\t', level) or ''
	local tpl = {}
	local keys = {}
	for k, _ in pairs(obj) do
		keys[#keys + 1] = k
	end
	if opt.sort then
		_sort(keys, function(a, b) return tostring(a) < tostring(b) end)
	end
	for _, k in ipairs(keys) do
		local v = obj[k]
		if 'number' ~= type(k) then
			k =  k .. (pretty and ': ' or ':')
		else
			k = ''
		end
		
		local vt = type(v)
		if 'table' == vt then
				opt.level = level + 1
				tpl[#tpl + 1] = _fmt('%s%s%s', indent_str, k, _dump(v, opt))
		else
			if 'string' == vt then
				tpl[#tpl + 1] = _fmt('%s%s"%s"',indent_str, k, v) -- _gsub(v,'\n', '\\n'))
			elseif 'function' == vt then
				tpl[#tpl + 1] = _fmt('%s%s%s',indent_str, k, 'function')
			else
				tpl[#tpl + 1] = _fmt('%s%s%s',indent_str, k, tostring(v))	
			end
		end

	end
	
	return pretty
		and '{\n' .. _concat(tpl, ',\n') .. '\n'.. _rep('\t', level - 1) .. '}'
		or	'{' .. _concat(tpl, ',') .. '}'
					
end



local function _color_fmt(lvl, msg)
	local r_lvl = _r_levels[lvl]
	return '\27['.._lvl_colors[r_lvl]..'m' .. msg .. '\27[m'
end



local function _log(self, lvl, ...)
	if self._level < lvl then
		return
	end


	local dump = self._dump
	local t = {}
	for i=1, select('#', ...) do
		t[#t+1] = dump((select(i, ...)))
	end

	if self._trace then
		local info	= debug.getinfo(3)
		t[#t + 1] = ' -- ' .. (info.short_src or '') .. ':' .. info.currentline
	end

	local r_lvl = _r_levels[lvl]
	
	local assobj = {
		datetime	= _date('%Y-%m-%d %H:%M:%S'),
		level			= r_lvl,
		msg				= _concat(t, ' '),
	}
	local assignor = function(v)
		return assobj[v] or ''
	end
	local msg = _gsub(self._fmter, '${%s*(.-)%s*}', assignor)
	if self._color then
		msg = _color_fmt(lvl, msg)
	end

	self._printer(lvl, msg)
end





--
--
--
local function _new(opts)
	opts = opts or {}
	local self = {
		_level		= opts.level	or _levels.DEBUG,
		_color		= opts.color and true,
		_colors		= opts.colors or _lvl_colors,
		_printer	= opts.printer,
		_fmter		= opts.formater or '${datetime} [${level}] ${msg}\n',
		_pretty		= opts.pretty,
		_trace		= opts.trace,
		_dump			= opts.pretty and function(v) return _dump(v, {pretty=true, sort=true}) end
														or	_dump
	}

	-- ---------------------------
	-- make pointfree style 
	--
	local obj = {}

	function obj.level(lvl)
		if lvl and _r_levels[lvl] then
			self._level = lvl
		end
		return self._level
	end
	
	
	function obj.d(...)
		-- local info	= debug.getinfo(2)
		-- local fn		= info.short_src
		-- local line	= info.currentline
		-- local pre = ' ' .. (fn or '') .. ':' .. line
		-- _log(self, _levels.DEBUG, pre, ...)
		_log(self, _levels.DEBUG, ...)
	end
	
	function obj.i(...)
		_log(self, _levels.INFO, ...)
	end

	function obj.n(...)
		_log(self, _levels.NOTICE, ...)
	end
	
	function obj.w(...)
		_log(self, _levels.WARN, ...)
	end
	
	function obj.e(...)
		_log(self, _levels.ERR, ...)
	end

	return obj
	
end



--
--
--
function _M.ngxlog(opts)
	opts = opts or {}
	local el = require 'ngx.errlog'
	local raw_log = el.raw_log
	local function printer()
		el.raw_log = function (lvl, msg)
			raw_log(lvl, _color_fmt(lvl, msg))
		end
		return el.raw_log
	end

	return _new({
		level			= opts.level or _levels.DEBUG,
		formater	= '${msg}',
		printer		= opts.printer or printer(),
		color			= opts.color,
		pretty		= opts.pretty,
		trace			= opts.trace,
	})
end

--
--
--
function _M.console(opts)
	opts = opts or {}
	local function printer()
		local fd = io.open('/dev/stdout', 'ab')
		fd:setvbuf('no')
		return function (lvl, msg) 
			fd:write(msg)
		end
	end

	return _new({
		level			= opts.level or _levels.DEBUG,
		formater	= opts.formater or '${datetime} [${level}] ${msg}\n',
		printer		= opts.printer or printer(),
		color			= opts.color,
		pretty		= opts.pretty,
		trace			= opts.trace,
	})
end


--
--
--
function _M.file(opts)
	local function printer()
		local rotate	= opts.rotate
		local file = opts.file
		local prefix, suffix
		if rotate then
			prefix, suffix = _match(opts.file, '^(.+)%.(.-)$')
			prefix = prefix or opts.file
			suffix = suffix or ''
		end
		local fd = nil
		return function (lvl, msg) 
			if 'day' == rotate and file then
				local day = os.date('%Y-%m-%d')
				local cur_file = prefix .. '.' .. day .. '.' .. suffix
				if file ~= cur_file then
					file = cur_file
					if fd then
						fd:close()
						fd = nil
					end
				end
			end

			if not fd then
				fd = io.open(file or '/dev/stdout', 'ab')
				fd:setvbuf('no')
			end
			fd:write(msg)
		end
	end

	return _new({
		level			= opts.level or _levels.INFO,
		formater	= opts.formater or '${datetime} [${level}] ${msg}\n',
		printer		= opts.printer or printer(),
		pretty		= opts.pretty,
		color			= opts.color,
		trace			= opts.trace,
	})
end



return _M

