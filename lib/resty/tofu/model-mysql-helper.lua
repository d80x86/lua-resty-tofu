--
-- @author d
-- @version 0.1.0
-- @brief mysql访问助手
--

local _format			= string.format
local _gsub				= string.gsub
local _lower			= string.lower
local _match			= string.match
local _concat			= table.concat

local ok, _mysql  = pcall(require, 'resty.mysql')
if not ok then error('resty.mysql module required') end

local _util				= require 'resty.tofu.util'
local _merge			= _util.tab_merge
local _isempty		= _util.isempty
local _functional	= _util.functional
local _tabnew			= _util.tab_new
local _clock			= _util.getusec


--
-- 数据过虑器
--
local _nil = function() return 'NULL' end
local _boo = function(b) return tostring(b) end
local _num = function (num) return  tostring(tonumber(num or 0)) end
local _str = ngx.quote_sql_str

-- 有特殊不转换处理
-- {'xxxx'}
local _tab = function (obj) return 'string' == type(obj[1]) and obj[1] or '' end
local _use = function (obj) return ngx.null == obj and 'NULL' or '' end

-- 不支持的类型
-- function
-- thread
local _non = function (non) error('sql not support ' .. type(non) .. ' type') end


-- 
-- 
--
local _var_map = {
									 ['nil']			= _nil,
								   ['boolean']	= _boo,
									 ['number']		= _num,
								   ['string']		= _str,
									 ['table']		= _tab,
 									 ['userdata'] = _use,
								 }

-- 自动识别过虑处理函数
local _var = function (val)
	local typ = type (val)
	local vf = _var_map[typ] or _non
	return vf(val)
end



--
-- 扩展操作符处理
--
local _ext_operator = function (k, v)
	-- 一元
	if 1 == #v then
		return _format('`%s` %s', k, v[1] or '')
	end

	-- 多元
	local op = _lower(v[1])
	local ra, rb = v[2], v[3]

	-- 闭区间
	if 'between' == op then
		return _format('`%s` between %s and %s', k, _var(ra), _var(rb))

	-- 集合
	elseif 'in' == op or 'not in' == op then
		local list = {}
		for i = 2, #v do
			list[#list + 1] = _var(v[i])
		end
		return _format('`%s` %s (%s)', k, op, _concat(list, ','))

	-- 闭区间
	elseif '[]' == op then
		return _format('%s <= `%s` and `%s` <= %s', _var(ra), k, k, _var(rb))

	-- 半闭半开区间
	elseif '[)' == op then
		return _format('%s <= `%s` and `%s` < %s', _var(ra), k, k, _var(rb))

	-- 半开半闭区间
	elseif '(]' == op then
		return _format('%s < `%s` and `%s` <= %s', _var(ra), k, k, _var(rb))

	-- 开区间
	elseif '()' == op then
		return _format('%s < `%s` and `%s` < %s', _var(ra), k, k, _var(rb))

	-- 逻辑或
	elseif 'or' == op then
		local list = {}
		for i = 2, #v do
			list[#list + 1] = _format('`%s`=%s', k ,_var(v[i]))
		end
		return _concat(list, ' or ')

	-- < <= >= 等
	elseif 2 == #v then
		return _format('%s %s %s', k, op, _var(ra))
	end

	return '', 'condition:' .. k .. ' nonsupport'
end


--
--
--
local _fields	= function (fields)
	if _isempty(fields) then
		return '*'
	elseif 'table' == type(fields) then
		return '`' .. _concat(fields, '`,`') .. '`'
	end
	return fields
end


--
--
--
local _values = function (vals)
	local vls = {}
	for _, v in pairs(vals) do
		vls[#vls + 1] = _var(v)
	end
	return _concat(vls, ',')
end


--
-- 条件处理
--

local _cond_s = function (cond)
	return 'string' == type (cond)
		and cond
		or nil
end

-- {'string :key ::key', {key = 'val'}} -- ::key : 不进行安全过虑
local _cond_s_t = function (cond)
	if 'table' ~= type (cond) then
		return nil
	end
	if not ('string' == type (cond[1]) and 'table' == type (cond[2])) then
		return nil
	end
	local vals = cond[2]
	return _gsub(cond[1], '(::?)([a-zA-Z_0-9]+)', function (pre, key) 
		if ':' == pre then
			return _var(vals[key]) or ''
		else
			return vals[key] or ''
		end
	end)
end

-- {'string ? ? ??...', v1, v2 ...} -- 占位符 ??:不进行安全过虑
local _cond_s_s = function (cond)
	if 'table' ~= type (cond) then
		return nil
	end
	if 'string' ~= type (cond[1])  then
		return nil
	end
	local n = 1
	return _gsub(cond[1], '%?%??', function (pre)
		n = n + 1
		if '?' == pre then
			 return _var(cond[n]) or ''
		else
			 return cond[n] or ''
		end
	end)
end


-- {[1]='and | or', key = val}
local _cond_k_v = function (cond)
	if 'table' ~= type (cond) or nil ~= cond[2] then
		return nil
	end

	local wh = _tabnew(10, 0)
	for k, v in pairs(cond) do
		local typ = type(v)
		-- 1 key 特列不处理
		if 1 == k then
			-- 
			--
		elseif 'table' == typ then
			wh[#wh+1] = _ext_operator(k, v)

		elseif ngx.null == v then
			wh[#wh+1] = _format('`%s` is NULL', k)

		else
			wh[#wh+1] = _format('`%s`=%s', k,  _var(v))
		end
	end

	if _isempty(wh) then
		return ''
	end
	return _concat(wh, ' '.. (cond[1] or 'and') .. ' ')
end


-- 错误参数
local _cond_err = function ()
	error('cond params error')
end

local _cond_sizer = {
	_cond_k_v,
	_cond_s,
	_cond_s_t,
	_cond_s_s,

	-- _cond_err,
}


--
-- 条件轮询器
--
local _cond		= function (cond)
	for _, sizer in ipairs(_cond_sizer) do
		local where = sizer(cond)
		if not _isempty(where)  then
			return ' where ' .. where
		end
	end
	return ''
end


--
--
--
local _setter	= function (ps)
	if 'table' ~= type(ps) then
		return ''
	end

	local wh = {}
	for k, v in pairs(ps) do
		local typ = type(v)
		wh[#wh+1] = _format('`%s`=%s', k,  _var(v))
	end
	return _concat(wh, ',')
end


--
-- 分割kv
-- @return keys, values  字段名列表, 值列表
--
local _split = function (...)
	local keys	= {}
	local vals	= {}

	-- merge
	for i=1, select('#', ... ) do
		for k, v in pairs(select(i, ... )) do
			if not _match(k, '^[%a_][%w_]+$') then
				return nil, '[' .. k .. '] not a valid field name'
			end
			if 'table' == type(v) then
				return nil, 'the [' .. k .. '] value cannot be a structure type'
			end
			keys[#keys + 1] = k
			vals[#vals + 1] = v
		end
	end
	return keys, vals
end


--
--
--
local _orderby = function (v)
	if _isempty(v) or 'string' ~= type(v) then
		return ''
	end
	return 'order by ' .. v
end


--
-- 
--
local _limit = function (v)
	local typ = type(v)
	if 'number' == typ then
		return 'limit ' .. v
	elseif 'table' == typ and 'number' == type(v[1]) then 
		local lt = 0 < v[1] and v[1] or 1
		if 'number' == type(v[2]) then
			if 0 < v[2] then
				lt = (lt - 1) * v[2] .. ','..v[2]
			else
				lt = lt .. ',' .. v[2]
			end
		end
		return 'limit ' .. lt
	elseif 'string' == typ then
		return 'limit ' .. v
	elseif 'nil' == typ then
		return 'limit 1'
	end
	return ''
end



--
--
--
local _forupdate = function (v)
	return v and 'for update' or ''
end




-- 
--
--
local _M = { _VERSION = '1.0', }


local _mt = { __index = _M }

local _default_options = {
	-- path		= 'unix socket'
	host 			= '127.0.0.1',
	port 			= 3306,
	database	= 'mysql_db_name',
	prefix		= '',
	user			= 'root',
	password	= '',
	charset		= 'utf8',
	timeout		= 5 * 1000,
	max_packet_size = 2 * 1024 * 1024,
	pool_size	= 64,
	pool_idle_timeout = 900 * 1000,

	logger		= tofu and tofu.log.n or print,
}





function _M.new(options)
	local conf_opts = options
	local self = {}

	-- function model
	return function (name, opts)
		opts = opts or conf_opts.default
		if 'string' == type(opts) then
			opts = conf_opts[opts]
		end
		local obj = _merge({}, _default_options)
		local ot = type(opts) 
		if 'table' == ot then
			_merge(obj, opts)
		elseif 'function' == ot then
			obj._parser = opts
		else
			error('model-mysql-helper options invalid')
		end
		obj.name	= obj.prefix .. (name or '')
		setmetatable(obj, _mt)
		return _functional(obj)
	end
end


--
--
--
function _M:model(name, opts)
	self.name = name
	return self
end


--
--
--
function _M:getconn(options)
	if options then
		_merge(self, options)
	end

	local conn = rawget(self, '_conn')
	if conn then
		return conn
	end

	local conn, err = _mysql:new()
	if not conn then
		error('failed to instantiate mysql:' .. err)
	end
	conn:set_timeout(self.timeout or 5000)
	local st = _clock()
	local ok, err = conn:connect(self)
	if not ok then
		-- self.logger('failed to connect database ' .. err)
		error('failed to connect database ' .. err)
		return nil, err
	end
	-- 第一次连接时才log
	if self.logconnect and conn:get_reused_times() < 1 then
		self.logger(_format(
			'mysql connect: %s@%s:%s/%s -- %.2fms', 
			self.user,
			self.host,
			self.port,
			self.database,
			(_clock() - st) / 1000
		))
	end
	return conn
end


--
-- @param sql string | {'string ?', ...} | {'string :key', {key=value} }
--
function _M:exec(sql, options)
	if 'string' ~= type (sql) then
		sql = _cond_s_t(sql) or _cond_s_s(sql)	
	end

	local conn, err = rawget(self, '_conn')
	if not conn then 
		if not options and self._parser then
			options = self._parser(sql)
		end
		
		conn, err = _M.getconn(self, options)
		if not conn then
			return nil, err
		end
	end

	local st = _clock()
	local res, err, errcode, sqlstate =  conn:query(sql)
	if self.logsql and self.logger then
		local tail = _format('-- %.2fms', (_clock() - st) / 1000)
		self.logger(sql, tail)
	end

	if not res then
		self.logger('bad result: ' .. err, errcode, sqlstate)
		-- 在 trans 事务中
		if self._istrans then error(err) end
		return nil, err
	end

	if 'again' == err then
		local arr = {res}

		while 'again' == err do
			res, err, errcode, sqlstate = conn:read_result()
			if not res then
				self.logger('bad result: ' .. err, errcode, sqlstate)
				break;
			end
			arr[#arr + 1] = res
		end
		res = arr
	end
	-- 如果不在事务中则keepalive
	if not self._conn then
		local ok, err = conn:set_keepalive(self.pool_idle_timeout, self.pool_size)
		if not ok then
			self.logger('failed to keep alive: ' .. err)
		end
	end
	return res
end



-- 
-- @param cond
-- @param opts {
--	field,
--	limit,				: nil | number | table {number, number} | false
--	orderby,
--	forupdate,
-- }
--
function _M:get(cond, opts)
	opts = opts or {}
	local sql = 'select %s from `%s` %s %s %s %s'
	sql = _format(sql, _fields(opts.field), self.name,
		_cond(cond),
		_orderby(opts.orderby),
		_limit(opts.limit),
		_forupdate(opts.forupdate)
	)
	local res, err = _M.exec(self, sql)	
	if res then
		if nil == opts.limit then
			return res[1], nil
		else
			return res, nil
		end
	else
		return nil, err
	end
end


--
--
--
-- @restun id, err	id -- nil:error, 0:update/new, n:new id
--
function _M:set(cond, pair, add)
	assert(not _isempty(cond), 'the update condition cannot be nul')
	assert(not _isempty(pair), 'the update target cannot be nul')
	
	-- 添加模式: 不存在则添加 
	if add then
		local fvs = _merge({}, cond, pair)
		if 'table' == type(add) then
			_merge(fvs, add)
		end
		local fs, vs = _split(fvs)
		if not fs then
			return fs, vs
		end
		local sql = 'insert into `%s` (%s) values (%s) on duplicate key update %s'
		sql = _format(sql, self.name, _fields(fs), _values(vs), _setter(pair)) 
		local res, err = _M.exec(self, sql)
		if not res then
			return nil, err
		end
		return res.affected_rows, res.insert_id
	
	-- 更新模式
	else
		local sql = 'update `%s` set %s %s'
		sql = _format(sql, self.name, _setter(pair), _cond(cond)) 
		local res, err = _M.exec(self, sql)
		return res and res.affected_rows, err
	end
end



--
-- @restun id, err	id -- nil:error, 0:update/new, n:new id
--
function _M:add(...)
	local pair = select(1, ...)
	assert('table' == type(pair), 'bad argument #1 (table expected, got '.. type(pair) ..')')
	local sql = 'insert into `%s` (%s) values (%s)'
	local fs, vs = _split(pair)
	if not fs then
		return fs, vs
	end
	local vs_list = {_values(vs)}
	-- 多行
	for i=2, select('#', ...) do
		local obj = select(i, ...)
		if 'table' ~= type(obj) then
			return nil, 'bad argument #' .. (i + 1) .. '(table expected, got '.. type(obj) .. ')'
		end
		local ivs = {}
		for _, k in ipairs(fs) do
			if nil == obj[k] then
				ivs[#ivs + 1] = ngx.null
			else
				ivs[#ivs + 1] = obj[k]
			end
		end
		vs_list[#vs_list + 1] = _values(ivs)
	end

	sql = _format(sql, self.name, _fields(fs), _concat(vs_list, '),(')) 
	local res, err = _M.exec(self, sql)
	return res and res.insert_id, err
end





function _M:del(cond)
	if not cond then
			return nil, 'bad argument #1'
	end
	local sql = 'delete from `%s` %s'
	sql = _format(sql, self.name, _cond(cond))
	local res, err = _M.exec(self,sql)
	return res and res.affected_rows, err
end

-- ----------------------------------
-- 事务相关
--
function _M:begin(options)
	local conn = self:getconn(options)
	if not conn then
		return nil
	end
	self._conn = conn
	return _M.exec(self, 'BEGIN')
end


--
--
--
function _M:rollback()
	_M.exec(self, 'ROLLBACK')
	if self._conn then
		local ok, err = self._conn:set_keepalive(self.pool_idle_timeout, self.pool_size)
		if not ok then
			self.logger('failed to keep alive: ' .. err)
		end
		self._conn = nil
	end
end


--
--
--
function _M:commit()
	_M.exec(self, 'COMMIT')
	if self._conn then
		local ok, err = self._conn:set_keepalive(self.pool_idle_timeout, self.pool_size)
		if not ok then
			self.logger('failed to keep alive: ' .. err)
		end
		self._conn = nil
	end
end


--
-- @return ok, result
--
function _M:trans(fn, ...)
	self._istrans = true
	_M.begin(self)
	local ok, res = pcall(fn, ...)
	if ok then
		_M.commit(self)
	else
		self.logger('error: ', res)
		_M.rollback(self)
	end
	self._istrans = nil
	return ok, res
end




return _M



