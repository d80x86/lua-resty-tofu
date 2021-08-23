--
-- 中间件配置
--

local _isdev	= 'development' == tofu.env

--
-- middleware list
--
middleware = {
	--
	-- <table confing> | <package string>
	--
	--
	-- example
	--
	-- {
	--		enable = false | true
	--		handle = package | function->function | table<:new>
	--		options = {
	--			...
	--		},
	--		match = <reg string> | function->bool
	--	},
	--		...
	--

	--
	-- 一个简单跟踪记录总响应并且记录的中间件
	--
	{
		enable = _isdev,
		handle = 'resty.tofu.middleware.trace',
		options = {
			logger = tofu.log.n
		}
	},

	-- 路由中间件
	'resty.tofu.middleware.router',

	-- 参数预处理中间件
	'resty.tofu.middleware.payload',

	-- 参数过滤中间件
	'resty.tofu.middleware.guard',

	-- 业务控制器中间件
	'resty.tofu.middleware.controller',

} -- end middleware

