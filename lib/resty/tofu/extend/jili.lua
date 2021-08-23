--
-- tofu 扩展
-- @file jili.lua
-- @author d
-- @brief 一个watcher(开发使用)
--

local _process	= require 'ngx.process'
local _shell		= require 'resty.shell'

local _cli_opts	= require 'resty.tofu.cli.opts'
local _util			= require 'resty.tofu.util'
local _refile		= require 'resty.tofu.refile'
local _inotify	= require 'resty.tofu.inotify'
local _watcher	= _inotify.new()
local _IN				= _inotify.IN
local _band			= require 'bit'.band
local _match		= string.match
local _find			= string.find

local _is_show	= 0 == ngx.worker.id()


--
-- 缺省设置
--
local _opts = {
	-- 是否log
	trace		= true,	

	-- {监视的路径,与处理方式}
	path = {
		-- string | {string, string}
		{tofu.ROOT_PATH .. 'conf', 'ngx_restart'},
		{tofu.APP_PATH .. 'controller', 'reload'},
		{tofu.APP_PATH .. 'middleware', 'ngx_restart'},
		{tofu.APP_PATH .. 'task', 'ngx_restart'},
		{tofu.APP_PATH .. 'model', 'reload'},

		tofu.APP_PATH, -- default processor: ngx_restart
	},
}




local _plan = {
	-- path, handle
	-- {path, processor}
}


local _plan_handle = { }

--
-- @param m MOD | REM  : 修改 | 移除
--
function _plan_handle.reload(f, m)
	if 'MOD' == m then
		return _refile.reload(f)
	else
		return _refile.remove(f)
	end
end


--
--
--
function _plan_handle.ngx_reload(f, m)
	-- 只处理 lua 文件
	if not _match(f, '%.lua$') then return true end
	local pid = _process.get_master_pid()
	os.execute('kill -HUP ' .. pid)
	return true
end


--
--
--
function _plan_handle.ngx_restart(f, m)
	if 0 ~= ngx.worker.id() then
		return true
	end

	local pid = _process.get_master_pid()
	_cli_opts._init({})
	os.execute('kill -HUP ' .. pid)
	return true
end


--
--
--
_plan_handle.default = _plan_handle.ngx_reload




--
-- 处理lua文件变化
--
local function _handle(iev)
	if iev.isdir then return end
	local ph = _plan_handle.default

	for _, p in ipairs(_plan) do
		if _find(iev.path, p[1], 1, true) then
			ph = _plan_handle[p[2]]
			if not ph then
				tofu.log.e('not found plan handleer:', p, iev)
				return 
			end
			break
		end
	end


	-- if not _match(iev.name, '%.lua$') then return end
	local f = iev.path .. '/' .. iev.name

	-- 修改(新建 create 与 modify 会同时发生) | 改名(新文件名)
	-- 这些合并为修改 MOD 事件
	if 0 < _band(_IN.MODIFY, iev.mask) or 0 < _band(_IN.MOVED_TO, iev.mask) then
		local _, err = ph(f, 'MOD')
		if _opts.trace and _is_show then
			if err then
				tofu.log.e(err)
			else
				tofu.log.d('reload file:', iev.name)
			end
		end

	-- 删除 | 改名(旧文件名)
	elseif 0 < _band(_IN.MOVE, iev.mask) or 0 < _band(_IN.DELETE, iev.mask) then
		ph(f, 'REM')
	end

end

-- 设置缺省处理



local _M = { _VERSION = '0.1.0' }


function _M.new(opts)
	-- 只在 worker 上监视
	if 'worker' ~= _process.type() then
		return
	end

	_util.tab_merge(_opts, opts)
	for _, p in ipairs(_opts.path) do
		if 'table' == type(p) and p[1] then
			_plan[#_plan + 1] = {p[1], p[2]}
			if _util.file_exists(p[1]) then
				_watcher:add_watch(p[1])
			end

		elseif 'string' == type(p) then
			_plan[#_plan + 1] = {p, 'default'}
			if _util.file_exists(p) then
				_watcher:add_watch(p)
			end

		else
			if _is_show then
				tofu.log.e('watcher path param expect string or table')
			end
		end
		-- if _opts.trace and _is_show then	
		-- 	tofu.log.d('jili watch: ', p)
		-- end
	end

	_watcher:start( _handle )
	return
end


return _M

