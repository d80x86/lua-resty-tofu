--
--
--
local _M = {

	--
	ngx_conf_file = 'tofu.nginx.conf',

	--
	ngx_conf_file_template = false,

	--
	ngx_runtime_dir = '.runtime',


}


local _util				= require 'resty.tofu.util'
local _conf_load  = _util.conf_load

--
function _M._init(opts) 
	local p = opts.p or '.'
	local e = opts.e or tofu.env or '.'
	local conf, err = _conf_load(p .. '/conf/config.lua')
	if err then
		error(err)
	end
	_util.tab_merge(_M, conf)
	os.execute('mkdir -p ' .. p .. '/logs')
	os.execute('mkdir -p ' .. p .. '/' .. _M.ngx_runtime_dir)
	os.execute('mkdir -p ' .. p .. '/' .. _M.ngx_runtime_dir .. '/conf')
	local txt = _util.file_read(p .. '/conf/' .. _M.ngx_conf_file)

	if _M.ngx_conf_file_template then
		local tpl = require 'resty.template.safe'.new({
									root			= p .. '/conf',
									location	= p .. '/conf'
								})
		txt = tpl.process_string(txt, _M)
		if not txt  then
			error(_M.ngx_conf_file .. ' template error ')
		end
	end

	if txt then
		os.execute('rm -rf ' .. p .. '/' .. _M.ngx_runtime_dir .. '/conf/*.conf')
		os.execute('cp -rf ' .. p .. '/conf/*.conf ' ..p..'/'.. _M.ngx_runtime_dir..'/conf/')

		txt = _util.envsubst(txt, _M)
		_util.file_write(p .. '/' .. _M.ngx_runtime_dir .. '/conf/' .. _M.ngx_conf_file, txt)
	end
	
end


return _M





