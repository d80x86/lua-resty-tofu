--
--
--

local _mate	= require 'resty.tofu.mate'
local _util = require 'resty.tofu.util'


local _usage = string.format([[

usage: %s install
]], _mate._NAME)


local _M = {
	_DESCRIPTION	= 'install deps to current resty_module',
	_USAGE				= _usage,
}


local _resty_modules_path = 'lua_modules/resty'
local _rocks_modules_path = 'lua_modules/rocks'

local function _init_dir()
	local cmd_list = table.concat({
											'mkdir -p ' .. _resty_modules_path ,
											'mkdir -p ' .. _rocks_modules_path ,
										}, ' & ')
	return os.execute(cmd_list)
end


local function _opm_installer(package)
	local cmd = 'opm --install-dir=' .. _resty_modules_path .. ' install ' .. package
	return os.execute(cmd)
end


local function _luarocks_installer(package)
	local cmd = 'luarocks --tree ' .. _rocks_modules_path .. ' install ' .. package
	return os.execute(cmd)
end


local _installers = {
	opm				= _opm_installer,
	luarocks	= _luarocks_installer,
}


function _M.exec(opts)
	local tofu_package_file = 'tofu.package.lua' 
	local f = loadfile(tofu_package_file)
	if not f then
		print('can not found ' .. tofu_package_file)
		return
	end


	local mf = {}
	setfenv(f, mf)()

	if mf.deps and #mf.deps then
		_init_dir()
	end

	local name = nil
	for _, p in ipairs( mf.deps ) do
		-- default opm
		if 'string' == type(p) then
			name = 'opm'

		-- luarocks | opm
		elseif 'table' == type(p) and p[1] and p[2] then
			name = p[1]
			p = p[2]
		else
			print('\27[0;31merror config in ' .. tofu_package_file .. ':' .. type(p) .. '\27[m')
			return
		end

		local installer = _installers[name]
		if not installer then
			print('\27[0;31merror installer ' .. name .. '\27[m')
		end
		print('install ' .. '\27[0;32m' .. p .. '\27[m')
		if not installer(p) then
			return
		end
	end

end



return _M
