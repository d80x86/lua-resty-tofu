--
--
--

local _mate	= require 'resty.tofu.mate'

local _usage = string.format([[

usage: %s version
]], _mate._NAME)


local _M = {
	_DESCRIPTION	= 'show version information',
	_USAGE				= _usage,
}


function _M.exec(opts)
	print(_mate._SERVER_TOKENS)
end



return _M
