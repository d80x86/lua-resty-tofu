--
-- @file validation.lua
-- @author d
-- @version 0.1.1
-- @brief 参数验证/过虑器


local _util	= require 'resty.tofu.util'
local _ctx	= require 'resty.tofu.ctx'


local _str_lower			= string.lower
local _str_match			= string.match
local _util_isint			= _util.isint
local _util_tosecond	= _util.tosecond
local _util_trim			= _util.trim
local _util_tab_merge	= _util.tab_merge


--
-- 缺省配置 
--
local _options = {
	mode		= 1,					-- 0-检测所有参数, 1-有无效参数时立即返回(中断后面的参数检测)
	trim		= false,			-- 去两端空白
	amend		= false,			-- 自动修正参数(需指定method),如 bool 参:true|1'true',false 0 ...
	errmsg	= {						-- 缺省错误信息 string | {}, 优先级 指定>sgring>[0]
		-- 特殊的, 缺省信息
		[0]	= '参数错误',

		-- 指定验证器错误信息,
		required		= '参数不能为空',				-- 指定 required 验证器的错误信息
	}
}

--
-- 保留方法/属性
--
local _reserved = {
	required= true,
	errmsg	= true,
	value		= true,
	trim		= true,
	default = true,
	amend		= true,
	method	= true,
}


--
-- 从参数列中获得一个非空(nil)值
--
local function _getnonil(...)
	for i=1, select('#', ...) do
		local v = select(i, ...)
		if nil ~= v then
			return v
		end
	end
end


--
-- 获值 优先级： 设置 > 参数 > 缺省
--
local function _getvalue(p, r)
	local args = _ctx.fetch().args
	local m = r.method
	m = m and _str_lower(m)
	local v, a = _getnonil(r.value, m and args[m][p] or args(p), r.default)
	if v and _getnonil(r.trim, _options.trim) then
		if 'string' == type (v) then
			v = _util.trim(v)
		end
	end
	return v, m
end

--
-- 修改(回写) 请求参数到 ctx.args 中
--
local function _setvalue(p, value, m)
	if nil ~= value and m then
		local args = _ctx.fetch().args
		args[m][p] = value
	end
end


--
-- 获取错误信息
-- p 参数名称
-- k 验证器名称
-- r 规则
-- opts 
--
local function _geterrmsg(p, k, r, opts)
	local rt = type (r.errmsg)
	local ot = type (opts.errmsg)
	local msg = ('table' == rt and r.errmsg[k]) or ('table' == ot and opts.errmsg[k])
	if not msg then
		msg = ('string' == rt and r.errmsg) or ('string' == ot and opts.errmsg)
	end
	if not msg then
		msg = ('table' == rt and r.errmsg[0]) or ('table' == ot and opts.errmsg[0])
	end
	-- tofu.log.w(p, msg)
	return msg
end


-- 
-- 验证器表
--
local _validators = {}


--
-- 验证器 - 必选参数
-- @param v any 值
-- @param cond bool
--
function _validators.required(v, cond)
	return not cond or not not v
end


--
-- 验证器 - 整型
-- @param v any 值
-- @param cond true | {[min:int], [max:int]}, {a,b,c ... }
--
function _validators.int(v, cond)
	v = tonumber(v)
	if not _util_isint(v) then return false end
	local t = type(cond)
	if 'table' == t then
		-- {a,b,c ... }
		if 0 < #cond then
			for i in ipairs(cond) do
				if v == cond[i] then
					return true
				end
			end
			return false

		-- {min, max}
		else
			return (not cond.min or cond.min <= v) and (not cond.max or v <= cond.max), v
		end
	elseif 'number' == t then
		return v == cond, v
	end
	return true == cond, v
end


--
-- 验证器 - 数值型
-- @param v any 值
-- @param cond true | {[min:int], [max:int]}
--
function _validators.float(v, cond)
	v = tonumber(v)
	local t = type(cond)
	if 'table' == t then
		return (not cond.min or cond.min <= v) and (not cond.max or v <= cond.max), v
	elseif 'number' == t then
		return v == cond, v
	end
	return true == cond, v
end


--
-- 验证器 - 纯数字串
-- @param v any 值
-- @param cond true
--
function _validators.digit(v, cond)
	return true == cond and not _str_match(v, '[^0-9]')
end


--
-- 验证器 - 字符串
-- @param v any 值
-- @param cond true | {[min:int], [max:int]} | {'a', 'b', ...}
--
function _validators.string(v, cond)
	v = tostring(v)
	local t = type (cond)
	if 'table' == t then
		-- {a,b,c ...}
		if 0 < #cond then
			for i in ipairs(cond) do
				if v == cond[i] then
					return true
				end
			end
			return false	

		-- {min, max}
		else
			local len = #v
			return (not cond.min or cond.min <= len) and (not cond.max or len <= cond.max), v
		end
	elseif 'string' == t then
		return v == cond, v
	end
	return true == cond, v
end


--
-- 验证器 - 日期
-- @param v any 值
-- @param cond true | {[min:date], [max:date]}
--
function _validators.date(v, cond)
	local sec = _util_tosecond(v)
	if not sec then
		return false
	end
	if 'table' == type (cond) then
		return (not cond.min or (_util_tosecond(cond.min) or 253402271999) <= sec)
					 and
					 (not cond.max or sec <= (_util_tosecond(cond.max) or -1))
	end
	return true == cond and 0 < sec
end


--
-- 验证器 - 布尔
-- @param v any 值
-- @param cond true
--
function _validators.bool(v, cond)
	v = '' ~= v 
		and '0' ~= v and 0 ~= v 
		and 'false' ~= ('string' == type(v) and _str_lower(v))
		and not not v
	return true == cond, v
end


--
-- 验证器 - 字母
-- @param v any 值 
-- @param cond true
--
function _validators.alpha(v, cond)
	return true == cond and not _str_match(v, '[^a-zA-Z]')
end

--
-- 验证器 - 十六进制hex
-- @param v any 值 
-- @param cond true
--
function _validators.hex(v, cond)
	return true == cond and not _str_match(v, '[^0-9a-fA-F]')
end


--
-- 验证器 - 字母数字
-- @param v any 值 
-- @param cond true
--
function _validators.alphanumeric(v, cond)
	return true == cond and not _str_match(v, '[^0-9a-zA-Z]')
end



-- -----------------------------------------------------------------------


-- 
-- @param rules : {
-- 	<arg name> : { <validate name> : <value> }
-- 	...
-- }
-- 
-- opts : {mode: 0-检测所有参数 | 1-当有无效参数时立即退出检测}
--
local function _handle(rules, opts)
	opts = _util_tab_merge({}, _options, opts)
	if 'table' ~= type (rules) then
		error ('rules must be table')
	end
	local errs = {}
	for p, r in pairs(rules) do
		local v, m = _getvalue(p, r)
		-- 如果为nil, 验证是否为必填参数
		if nil == v then
			if r.required then
				errs[p] = _geterrmsg(p, 'required', r, opts)
				if 1 == opts.mode then return false, errs end
			end

		-- 其它验证
		else
			for k, cond in pairs(r) do
				if not _reserved[k] then
					local h = _validators[k]
					if not h then
						error ('validator '.. k .. ' not exist')
					end
					local ok, valid, v2 =  pcall(h, v, cond)
					if not ok then
						-- error (valid)
						tofu.log.e(valid)
					end
					if true ~= valid then
						errs[p] = _geterrmsg(p, k, r, opts)
						if 1 == opts.mode then return false, errs end
					end
					if nil ~= v2 then v = v2 end
				end
			end
		end

		-- 修正参数
		if _getnonil(r.amend, opts.amend) then
			_setvalue(p, v, m)
		end
	end
	return not next(errs), errs
end


local _M = {}


-- -- tofu extend 接口
-- function _M.new(opts)
-- 	_util.tab_merge(_options, optins)
-- 	return _M
-- end


function _M.options(opts)
	_util.tab_merge(_options, optins)
	return _M
end


function _M.register(fs, f)
	local t = type (fs)
	if 'table' == t then
		for k, f in pairs(fs) do
			if not _reserved[k] then
				_validators[k] = f
			end
		end
	elseif 'string' == t and 'function' == type (f) then
		if not _reserved[fs] then
			_validators[fs] = f
		end
	else
		error ('params error')
	end
end

_M.handle = _handle
return _M


