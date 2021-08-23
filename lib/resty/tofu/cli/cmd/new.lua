--
--
--

local _mate	= require 'resty.tofu.mate'
local _util = require 'resty.tofu.util'
local _str_format = string.format
local _str_match	= string.match
local _str_gsub		= string.gsub
local _str_lower	= string.lower




local _M = {
	_DESCRIPTION	= 'create a new project in the directory',

	_op_str				= 't',
}

_M._USAGE = string.format([[

usage: %s new [PATH] [options]
%s

options:
-t	template name
]], _mate._NAME, _M._DESCRIPTION)



local function _is_dir(path)
	-- return os.execute('cd ' .. path .. ' >nul 2>nul')			-- windows
	return os.execute('cd ' .. path .. ' >/dev/null 2>/dev/null')
end


local function _comfirm(title, yes, no)
	if title then
		io.write(title)
	end
	local c = io.read()
	if not c or 'y' ~= _str_lower(c) then
		return no and no()
	end

	return yes and yes() or true	
end




--
--
--
local _handle = {}

function _handle.default(src, dest)
	local cmd = nil
	-- 目录处理
	if _is_dir(src) then
		cmd = _str_format('mkdir -p "%s"', dest)
	
	-- 文件处理
	else
		cmd = _str_format('cp %s %s', src, dest)
		local dir = _str_match(dest, '(.*)/')
		if dir then
			cmd = _str_format('mkdir -p "%s" && ', dir) .. cmd
		end
	end
	os.execute(cmd)
	print('- \27[0;32mcreate ' .. dest .. ' ok\27[m')
end


--
--
--
math.randomseed(os.time())
local _MACRO = {
	RAND = math.random(111111111111, 999999999999)
}

function _handle.macro(src, dest)

	local f, err = io.open(src, 'r')
	if err then error(err) end

	local dir = _str_match(dest, '(.*)/')
	if dir then
		local cmd = _str_format('mkdir -p "%s"', dir)
		if not os.execute(cmd) then
			return
		end
	end

	local txt = f:read('*a') f:close()
	txt = _str_gsub(txt, '__TOFU_MACRO_(.-)__', _MACRO)
	f, err = io.open(dest, 'w+')
	if err then error(err) end
	f:write(txt)
	f:flush()
	f:close()

	print('- \27[0;32mcreate ' .. dest .. ' ok\27[m')
end



function _M.exec(opts)
	local proj_name = opts[1]
	if proj_name and _is_dir(proj_name) then
		print('the project ' .. proj_name .. ' directory already exists.')
		if not _comfirm('overwrite[y/n]: ') then
			return
		end
	elseif not proj_name then
		print('the project already exists.')
		if not _comfirm('overwrite[y/n]: ') then
			return
		end
	end
	local dest_path = (proj_name or '.') .. '/'
	local tpl = opts.t or 'default'
	local src_path = TOFU_DIR .. '/cli/template/' .. tpl .. '/'
	local manifest = src_path .. 'manifest.lua' 
	local mf = {}
	setfenv(loadfile(manifest), mf)()

	for _, it in pairs( mf.list ) do
		local h = _handle[ it[3] or 'default' ]
		if h then
			h(src_path .. it[1], dest_path .. it[2])
		end
	end

	print('-------------------------------')
	print('\n to get started: \n')
	print('# get dependencies:')
	print('$ ./tofu install')
	print('')
	print('# run the app on development')
	print('$ ./tofu console')
	print('')
	print('# run the app on production')
	print('$ ./tofu start')

	print('\n\27[0;33mdone, have fun!\27[m')
end



return _M
