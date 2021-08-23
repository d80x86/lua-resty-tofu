--
-- @file util.lua
-- @author d
-- @version 0.1.1
-- @brief	tofu开箱即用工具箱
--

local _M = { _VERSION = '0.1.1' }


local _table_insert = table.insert
local _table_concat = table.concat
local _table_sort		= table.sort

local _str_reverse	= string.reverse
local _str_find			= string.find
local _str_sub			= string.sub
local _str_gsub			= string.gsub
local _str_match		= string.match
local _str_gmatch		= string.gmatch
local _str_format		= string.format
local _str_byte			= string.byte
local _str_char			= string.char
local _str_rep			= string.rep

local _ffi = require("ffi")



-- ----------------------------------
-- 其它
--

function _M.isempty(obj)
	return 
		not obj
		or '' == obj
		or 'table'==type(obj) and next(obj) == nil
end


function _M.isint(v)
	return 'number' == type(v) and v % 1 == 0
end


function _M.isfloat(v)
	return 'number' == type(v) and v % 1 ~= 0
end



--
-- 是否可执行
--
function _M.iscallable(f)
	local t = type(f)
	if 'function' == t then
		return true
	end

	if 'table' == t then
		local mt = getmetatable(f)
		return 'table'== type(mt) and 'function' == type(mt.__call)
	end
	
	return false
end


-- ----------------------------------
-- 字符串处理
--

--
-- 分割字符串
--
function _M.split(str, delimiter)
	local result = {}
	for match in (str .. delimiter):gmatch('(.-)'..delimiter) do
		_table_insert(result, match)
	end
	return result
end

function _M.msplit(str, sep)
	if not sep then
		sep = '%s+'
	end
	local result = {}
	for match in str:gmatch('([^'..sep..']+)') do
		_table_insert(result, match)
	end
	return result
end


--
--
--
function _M.dirname(str)
	if not str then
		str = debug.getinfo(2, 'S').source:sub(2, -1)
	end
	return string.match(str, '(.*/)') or ''
end

-- * 比上面快10+倍
-- 截取路径(/结尾)
-- str = nil 取当前调用者的路径
function _M.getpath(str)
	if not str then
		str = debug.getinfo(2, 'S').source:sub(2, -1)
	end
	local i= #str
	while 0 < i and '/' ~= _str_sub(str, i, i) do i = i - 1 end
	return i and _str_sub(str, 1, i)
end


-- 去两端空白
-- 长字符串比 match 效率好点
function _M.trim(str)
	-- return _str_gsub(_str_gsub(str, '^%s+', ''), '%s+$', '')
	return _str_gsub(str, '^%s+(.-)%s+$', '%1')
end




--
--
--
function _M.bin_hex(s)
	return _str_gsub(s, '(.)', function (x) return _str_format('%02x', _str_byte(x)) end)
end


function _M.hex_bin(s)
	return _str_gsub(s, '(..)', function(x) return _str_char(tonumber(x,16)) end)
end




--
-- 变量替换
-- 'string ${var}' ==> string xxx
--
function _M.envsubst(str, env)
	env = env or {}
	return _str_gsub(str, '%${%s*([%w_]*)%s*}', function(key) return env[key] or '' end)
end


-- -----------------------------------
-- 时间日期
--

if not pcall(_ffi.typeof, 'struct timeval') then

_ffi.cdef [[
	struct timeval {
		long int tv_sec;
		long int tv_usec;
	};
	
	int gettimeofday(struct timeval *tv, void *tz);
]]

end

local __c_s_tm = _ffi.new("struct timeval")
local __c_f_gettimeofday = _ffi.C.gettimeofday

-- 
-- 获取微秒级时间戳
--
function _M.getusec()
	__c_f_gettimeofday(__c_s_tm,nil);
 	local sec =  tonumber(__c_s_tm.tv_sec);
	local uec =  tonumber(__c_s_tm.tv_usec);
 	return sec * 1000000 + uec;
 	-- return sec + uec * 10^-6;
 	-- return sec, uec;
end


--
-- 日期字符串的datetime
-- @param d 'yyyy-mm-dd hh:mm:ss' or 'yyyy/m/d'
function _M.tosecond(d)
	local n = _str_gmatch(tostring(d) or '', '[^-/ :]+')
	return os.time({
		year	= n(),
		month	= n(),
		day		= n(),
		hour	= n() or 0,
		min		= n() or 0,
		sec		= n() or 0,
	}) -- or 0 | 253402271999
end




-- ----------------------------------
-- table
--

function _M.tab_merge(...)
	local ret = select(1, ...) or {}
	for i=2, select('#', ...) do
		local t = select(i, ...)
		if t then
			for k, v in pairs(t) do
				if 'table' == type(v) then
					if 'table' ~= type(ret[k]) then ret[k] = {} end
					ret[k] = _M.tab_merge(ret[k], v)
					local mt = getmetatable(v)
					if v then setmetatable(ret[k], mt) end
				else
					ret[k] = v
				end
			end
		end
	end
	return ret
end




-- 
--
--
if pcall(require, 'table.new') then
	_M.tab_new = require 'table.new'
else
function _M.tab_new(narr, nrec)
	return {}
end
end




--
-- 格式化 tab -> str
--
local function _tab_str(obj,  opt)
  if 'table' ~= type(obj) then
		return tostring(obj)
	end
	opt = opt or {level=1}
	local pretty = opt.pretty 
	local level = opt.level or 1
	local indent_str = pretty and _str_rep('\t', level) or ''
	local tpl = {}
	local keys = {}
	for k, _ in pairs(obj) do
		keys[#keys + 1] = k
	end
	if opt.sort then
		_table_sort(keys, function(a, b) return tostring(a) < tostring(b) end)
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
			tpl[#tpl + 1] = _str_format('%s%s%s', indent_str, k, _tab_str(v, opt))
		else
			if 'string' == vt then
				tpl[#tpl + 1] = _str_format('%s%s"%s"',indent_str, k, v) 
			elseif 'function' == vt then
				tpl[#tpl + 1] = _str_format('%s%s%s',indent_str, k, 'function')
			else
				tpl[#tpl + 1] = _str_format('%s%s%s',indent_str, k, tostring(v))	
			end
		end

	end
	
	return pretty
		and '{\n' .. _table_concat(tpl, ',\n') .. '\n'.. _str_rep('\t', level - 1) .. '}'
		or	'{' .. _table_concat(tpl, ',') .. '}'
					
end

_M.tab_str = _tab_str




-- 
-- 函数化, pointfree 化
-- 把 obj:method():method() 
-- 为 obj.method().method()
--
local _pf_mt = {
	__index = function (t, k)
		local fn = rawget(t, k)
		if fn then
			return fn
		end
		local target = rawget(t, 0)
		local fn = target[k]
		if 'function' ~= type(fn) then
			return fn
		end
		local fn2 = function (...)
			local ret = {fn(target, ...)}
			if target == ret[1] then
				return t
			else
				return unpack(ret)
			end
		end
		rawset(t, k, fn2)
		return fn2
	end
}

function _M.functional(obj)
	return setmetatable({[0]=obj}, _pf_mt)
end




--
-- 相对调用目录中查找
--
function _M.extends(t, o)
	if 'string' == type(t) then
		local info = debug.getinfo(2, 'S')
		local path = _M.getpath(_str_sub(info.source, 2)) or ''
	 	t = dofile(path .. t .. '.lua')
	end
	return setmetatable(o or {}, {__index = t})
end



-- -----------------------------------------------------
-- 文件处理
--

-- 文件/目录是否存在
function _M.file_exists(path)
	local f = io.open(path, 'rb')
	return f and f:close()
end



-- 读取文件
function _M.file_read(path)
	local f = io.open(path, 'rb')
	if not f then
		return nil, path .. ' file does not exist'
	end
	local data = f:read('*a')
	f:close()
	return data
end


-- 写文件
function _M.file_write(path, data)
	local f = io.open(path, 'w')
	if not f then
		return nil, path .. ' file does not exist'
	end
	return f:write(data) and f:close()
end



-- 目录是否存在
function _M.dir_exists(path)
	return os.execute('cd ' .. path .. ' >/dev/null 2>/dev/null') -- win 使用 /nul
end



-- 加载 lua 格式的配置文件
function _M.conf_load(conf_file, g)
	local res, err = loadfile(conf_file)
	if not res then
		return nil, err
	end

	local env = setmetatable({}, {__index = g or getfenv(1)})
	setfenv(res, env)()
	-- return setmetatable(env, {})
	return env
end


-- --------------------------------------
-- end
--
return _M

