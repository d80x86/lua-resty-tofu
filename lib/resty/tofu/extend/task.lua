--
-- @author d
-- @version 0.1.1
-- @brief 定时任务
--



local _process	= require 'ngx.process'
local _crontab	= require 'resty.tofu.crontab'
local _config		= require 'resty.tofu.extend.config'
local _util			= require 'resty.tofu.util'


local _M = { _VERSION = '0.1.0' }


local _opts = {
	worker	= 'privileged agent',		-- 使用特权进程或指定worker进程执行
	task		= 'task', -- string | { task = {}}
}

-- task
-- {
--		after
--		every
--		cron
--		enable
--		handle
--		immediate
-- }
--

local _log = tofu and tofu.log.e or error


function _M.new(opts)
	_util.tab_merge(_opts, opts)

	if _process.type() ~= _opts.worker then
		if ngx.worker.id() ~= _opts.worker then
			return
		end
	end

	if 'string' == type(_opts.task) then
		local config = _config.new({ env = tofu.env, prefix = tofu.ROOT_PATH .. 'conf/'})
		_opts.task = config.task
	end

	local cur_env = getfenv()
	for _, t in ipairs(_opts.task) do
		if false ~= t.enable then
			local h = t.handle
			
			if 'string' == type(h) then
				h = require(t.handle)
			end

			if not _util.iscallable(h) then
				local cnf = '\n' .. _util.tab_str(t, {pretty = true})
				return _log('task config error: [handle] must callable' .. cnf)
			end

			if 'function' == type(h) then
				setfenv(h, cur_env)
			end

			if t.after then
				if 'number' ~= type(t.after) or t.after < 0 then
					local cnf = '\n' .. _util.tab_str(t, {pretty = true})
					return _log('task config error: [after] must be a positive number' .. cnf)
				end
				_crontab.add_after(t.after, h)

			elseif t.interval then
				if 'number' ~= type(t.interval) or t.interval < 1 then
					local cnf = '\n' .. _util.tab_str(t, {pretty = true})
					return _log('task config error: [interval] must be a positive number(>0)' .. cnf)
				end
				_crontab.add_every(t.interval, h)

			elseif t.cron then
				if 'string' ~= type(t.cron) then
					local cnf = '\n' .. _util.tab_str(t, {pretty = true})
					return _log('task config error: [cron] must be a crontab format string' .. cnf)
				end
				_crontab.add_cron(t.cron, h)
			end
			
			-- 立即执行一次
			if true == t.immediate then
				ngx.timer.at(0, h)
			end

		end
	end	-- end for

	_crontab.start()

end


return _M
