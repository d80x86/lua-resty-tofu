--
-- @file aes.lua
-- @author	d
-- @version 0.1.0
-- @brief 扩展 resty.aes 支持 aes/gcm 模式
-- 

local _M		= require 'resty.aes'

local _ffi			= require 'ffi'
local _ffi_c		= _ffi.C
local _ffi_new	= _ffi.new
local _ffi_str	= _ffi.string


--
-- 增加 gcm 支持
--
_ffi.cdef [[

const EVP_CIPHER *EVP_aes_128_gcm(void);
const EVP_CIPHER *EVP_aes_256_gcm(void);

]]


--
-- 重写 decrypt 方法
--
function _M:decrypt(s)
	local s_len = #s
	local buf = _ffi_new("unsigned char[?]", s_len)
	local out_len = _ffi_new("int[1]")
	local tmp_len = _ffi_new("int[1]")
	local ctx = self._decrypt_ctx
	
	if _ffi_c.EVP_DecryptInit_ex(ctx, nil, nil, nil, nil) == 0 then
	  return nil
	end
	
	if _ffi_c.EVP_DecryptUpdate(ctx, buf, out_len, s, s_len) == 0 then
	  return nil
	end
	
	_ffi_c.EVP_DecryptFinal_ex(ctx, buf + out_len[0], tmp_len)
	return _ffi_str(buf, out_len[0] + tmp_len[0])
end



return _M
