--
-- 配置 计划/定时任务
--
--

task = {

	--
	-- 配置
	--
	-- {
	--	after				= N,							-- N 秒后执行一次
	-- 	interval		= N,							-- 每隔 N 秒执行一次
	-- 	cron				= '* * * * *',		-- crontab 格式: 分 时 天 月 星期
	-- 	enable			= true,						-- 是否开启
	-- 	immediate		= false,					-- 是否立即执行
	-- 	handle			= function | package
	-- }
	

	-- ---------------------------------------------------
	-- example
	-- -- 启动 N 秒后，执行一次
	-- {
	-- 	after			= 3,
	-- 	handle		= function()
	-- 								tofu.log.d('after: 3秒后只执行一次')
	-- 							end
	-- },

	-- -- 每N秒执行一次
	-- {
	-- 	interval	= 5,
	-- 	handle = function()
	-- 		tofu.log.d('interval: 每隔5秒执行一次')
	-- 	end
	-- },

	-- -- crontab 方式
	-- {
	-- 	cron = '* * * * *',
	-- 	handle = function()
	-- 		tofu.log.d('crontab: 每分钟里执行一次')
	-- 	end
	-- }
	
	-- -- 
	-- {
	-- 	after			= 0,
	-- 	handle		= 'task.example'
	-- },


}
