--
-- @file extend.lua
-- @brief tofu 扩展配置
--

local	_log		= require 'resty.tofu.extend.log'

local _isdev	= 'development' == tofu.env


--
-- extend list
--
extend = {
	--
	-- example
	--
	-- {
	--		enable = false | true
	--		named = '<extend name>',
	--		[type]	= '<type name>' | default,
	--		<type name> = {
	--			handle = string | function | table<:new>
	--			options = { ... }
	--		} 
	--	},
	--		...
	--

	--
	-- 配置加载器
	--
	{
		named	= 'config',
		-- type = 'default',		-- 缺省为 default
		default = {
			handle	= 'resty.tofu.extend.config',
			options	= {
				env			= tofu.env,
				prefix	= tofu.ROOT_PATH .. 'conf/',
			}
		}
	},


	--
	-- 日志
	--
	{
		named	= 'log',
		type	= _isdev and 'console' or 'file',

		console = {
			handle	= _log.console,
			options = {
				level			=  _log.levels.DEBUG,
				formater	= '${datetime} [${level}] ${msg}\n',
				color			= true,
				pretty		= true, 
			}
		},

		file = {
			handle	= _log.file,
			options = {
				level			=  _log.levels.INFO,
				formater	= '${datetime} [${level}] ${msg}\n',
				file			= 'logs/tofu.log',
				rotate		= 'day',
			}
		},
	},


	--
	-- 对tofu的补充扩展
	-- util
	--
	{
		-- named=nil : 将所有非下划线_开头的方法和属性等直接绑定到 tofu, 访问使用 tofu.xxx
		default = {
			handle = 'resty.tofu.util'
		}
	},


	--
	-- 简写,-- 等同于上面的 util 配置
	--
	'resty.tofu.extend.builtin',




	--
	-- view
	-- 依赖: bungle/lua-resty-template
	--
	{
		named = 'view',
		default = {
			handle = 'resty.tofu.extend.view',
			options = {
				template_root = tofu.ROOT_PATH .. 'view/',	
				extname = '.html',
				cache = true, -- | false,
			}
		},
	},




	-- --
	-- -- 数据库访问
	-- --
	-- {
	-- 	named = 'model',
	-- 	default = {
	-- 		handle = 'resty.tofu.extend.model',
	-- 		options = {
	-- 			default = 'db1', -- table | string | function
	-- 			db1 = {
	-- 				host = '192.168.0.101',
	-- 				user = 'test',
	-- 				password = 'test******',
	-- 				database = 'test',
	-- 				prefix = '',

	-- 				logconnect = _isdev,
	-- 				logsql = _isdev,
	-- 			},

	-- 		},
	-- 	}
	-- },




	-- --
	-- --
	-- -- 依赖: bungle/lua-resty-session
	-- --
	-- {
	-- 	named = 'session',
	-- 	type	= 'default',
	-- 	default	= {
	-- 		handle = 'resty.tofu.extend.session',
	-- 		options = {
	-- 			ttl = 20 * 60, -- 过期时间秒
	-- 			-- secret	= '', -- 与 tofu.nginx.conf 中的 set $session_secret 相同
	-- 			--
	-- 			-- 存储方式配置 cookie | shm 两种方式
	-- 			-- storage	= 'cookie', -- 存储方式
	-- 			-- cookie = {},

	-- 			storage	= 'shm', -- 存储方式
	-- 			shm		= { store = 'tofu_sessions'},	-- 匹配 tofu.nginx.conf 中的 lua_shared_dict
	-- 			-- redis	= {},
	-- 		},
	-- 	}
	-- },




	-- -- 
	-- --
	-- --
	-- {
	-- 	named = 'cache',
	-- 	default = {
	-- 		handle = 'resty.tofu.extend.cache',
	-- 		options = {
	-- 			-- ttl = 90 * 60, -- 90 分钟
	-- 			-- shm = 'tofu_cache_dict', --  lua_shared_dict 配置的名称
	-- 		},
	-- 	}
	-- },




	-- --
	-- -- 计划/定时任务
	-- --
	-- {
	-- 	named = 'task',
	-- 	default = {
	-- 		handle = 'resty.tofu.extend.task',
	-- 	}
	-- },




	-- --
	-- -- 开发测试使用
	-- -- 自动检测已改动的lua文件,并加载
	-- -- 依赖: 系统库 inotify-tools
	-- --
	-- {
	-- 	named = 'watcher',
	-- 	enable = _isdev,
	-- 	default = {
	-- 		trace		= true,
	-- 		handle	= 'resty.tofu.extend.jili',
	-- 	}
	-- },


	

}-- end extend

