--
-- @file refile.lua
-- @author d
-- @version 0.1.0
-- @brief 文件加载管理器
--


local _M = { _VERSION='0.1.0' }



local _cache = {}


--
-- @param f string 完整文件路径
--
function _M.reload(f)
	local ok, h = pcall(dofile, f)
	if not ok then
		return nil, h
	end
	_cache[f] = h
	return h
end


function _M.remove(f)
	if _cache[f] then
		_cache[f] = nil
	end
end



--
-- @param f string 完整文件路径
-- @param default any 缺省
--
function _M.load(f, default)
	local h = _cache[f]
	if nil == h then 
		return _M.reload(f)
	end
	return h
end




return _M

