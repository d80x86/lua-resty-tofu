--
-- @file help.lua
--

local _mate	= require 'resty.tofu.mate'
local _opts	= require 'resty.tofu.cli.opts'

local _CMD_PKG = 'resty.tofu.cli.cmd'

local _usage = string.format([[
usage: %s help <command>
]], _mate._NAME)


local _M = {
	_DESCRIPTION	= 'help',
	_USAGE				= _usage,
}


local function _scan_cmds()
	local cmds = {}
	local info = debug.getinfo(1, 'S')
	local cmd = info.source:sub(2, -1):match('^.*/') .. '*.lua'
	local ret = io.popen('ls -1 ' .. cmd):read('*a'):sub(1, -2)
	for c in string.gmatch(ret, '(%w-)%.lua') do
		cmds[#cmds + 1] = c
	end
	return cmds
end

local _cmds = _scan_cmds()
table.sort(_cmds)

local _tpl = [[

usage:tofu COMMADN [OPTIONS]...

the available commands are:
%s

]]



local function _help()
	local cmds_desc = {}
	for i, name in ipairs(_cmds) do
		local ok, cmd = pcall(require, _CMD_PKG .. '.' .. name)
		if ok then
			cmds_desc[#cmds_desc + 1] = name .. '\t\t' .. cmd._DESCRIPTION
		else
			error(cmd)
		end
	end

	print(string.format(_tpl, table.concat(cmds_desc, '\n')))
end


function _M.exec(opts)
	if opts and opts[1] then
		local ok, cmd = pcall(require, _CMD_PKG .. '.' ..opts[1])
		if ok then
			print(cmd._USAGE)
		else
			-- _help()
			print(_usage)
		end
	else
		_help()
	end
end



return _M


-- ---------------------------------------------
--
-- ex: ft=lua
--

