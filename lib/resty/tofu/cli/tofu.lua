-- 
-- @author d
-- @version 0.1.1
--


local function getworkdir()
	return io.popen('pwd'):read('*a'):sub(1, -2)
end

local function getcurdir()
	local info = debug.getinfo(1, 'S')
	return info.source:sub(2,-1):match('^.*/')
end


local function getrealdir()
	return io.popen('dirname $(readlink -f ' .. arg[0].. ')')
		:read('*a')
		:sub(1, -2)
end


local _workdir	= getworkdir()
-- local _curdir		= getcurdir()
-- local _tofudir	= getrealdir():match('^.*/')
local _lib	= getrealdir():gsub('/resty/tofu/cli', '')


--
-- set env
--
_G.TOFU_DIR = _lib .. '/resty/tofu'
_G.WORK_DIR = _workdir
_G.tofu			= {
								env = os.getenv('NGX_ENV') or 'production',
							}

package.path = table.concat({
									_workdir .. '/resty_modules/lualib/?.lua',
									_lib .. '/?.lua',
									package.path,
								}, ';')






local function _parse_opts(args, op_str)
	local op = {}
	if op_str then
		for o in string.gmatch(op_str, '%w') do
			op[o] = true
		end
	end

	local opts = {}
	local i, len = 1, #args
	while i <= len do
		local p = args[i]
		if '-' ~= p:sub(1,1) then
			opts[p] = true
			opts[#opts + 1] = p
		else
			local o = p:sub(2, 2)
			if o and '' ~= o then
				if not op[o] then
					opts[o] = true
				else
					local v = p:sub(3, -1)
					if '' == v then
						i = i + 1
						v = args[i] or ''
					end
					if '-' ~= v:sub(1,1) then
						opts[o] = v
					else
						opts[o] = ''
					end
				end
			end
		end

		i = i + 1
	end
	return opts
end

-- ------------------------------------------


do

	if arg[1] then
		local ok, cmd = pcall(require, 'resty.tofu.cli.cmd.'..arg[1])
		if ok then
			table.remove(arg, 1)
			local opts = _parse_opts(arg, cmd._op_str)
			opts.p = opts.p or WORK_DIR
			return cmd.exec(opts)
		end
	end
	
	local cmd_help = require 'resty.tofu.cli.cmd.help'
	cmd_help.exec()
end



-- ---------------------------------------------
--
-- ex: ft=lua
--

