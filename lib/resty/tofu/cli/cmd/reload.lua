--
--
--

local _mate	= require 'resty.tofu.mate'
local _opts = require 'resty.tofu.cli.opts'


local _M = {
	_DESCRIPTION	= 'reload nginx.conf',

	_op_str	= 'epcg',
}


_M._USAGE = string.format([[

usage: %s reload [options]
%s

options:
-e	set environment(default production)
-c	configuration file
-p	override prefix directory
]], _mate._NAME, _M._DESCRIPTION)


local _cmd_tpl = [[
NGX_ENV=%s \
openresty \
-p %s \
-c %s \
-s reload \
-g " \
daemon on; \
%s \
"]]


function _M.exec(opts)
	local e = opts.e or 'production'
	local p = opts.p or '$PWD'
	local c = opts.c or _opts.ngx_runtime_dir .. '/' .. _opts.ngx_conf_file
	local g = opts.g or ''
	local cmd = string.format(_cmd_tpl, e, p, c, g)
	tofu.env = e
	_opts._init(opts)
	os.execute(cmd)		
end



return _M

