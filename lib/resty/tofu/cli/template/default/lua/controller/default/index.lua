


local _M = tofu.extends('_base')


--
-- api: /index/index
--
function _M.index()
	local format = tofu.args('format')

	local result = {
		version		= 'tofu-0.1.1 alpha ...',
		message		= '欢迎欢迎，热烈欢迎',
		datetime	= ngx.localtime(),
	}

	-- json 输出
	if 'json' == format then
		return tofu.success(result)
	end

	tofu.view.assign(result).display()
end



return _M


