-- 
-- tofu payload 参数预处理中间件
-- @file payload.lua
-- @author d
-- @version 0.1.1
--

local _concat			= table.concat
local _match			= string.match
local _sub				= string.sub
local _find				= string.find

local _upload			= require 'resty.upload'
local _json				= require 'cjson.safe'
local _util				= require 'resty.tofu.util'
local _tab_merge	= _util.tab_merge
local _isempty		= _util.isempty


--
-- 解析器 function -> {get={}, post={}, file={}}
--
local _parser = {

	['application/x-www-form-urlencoded'] = function() 
		ngx.req.read_body()
		return { post=ngx.req.get_post_args() }
	end,



	['application/json'] = function()
		ngx.req.read_body()
		local data = ngx.req.get_body_data()
		return { post = (_json.decode(data)) }
	end,

	--
	--
	-- @return {
	--	post	= {},
	--	file	= {
	--						<name> = {
	--												name,
	--												type,
	--												data,
	--												size
	--										 }
	--					}
	-- }
	--
	['multipart/form-data'] = function()
		local form, err = _upload:new()
		if not form then
			return 
		end
		form:set_timeout(1000)
		-- 参数存放
		local post, file = {}, {}
		local vals, name, filename, filetype, datasize
		repeat
			local typ, res, err = form:read()
			if not typ then
				return
			end
			if 'header' == typ then
				vals = {}
				datasize = 0
				local cd = res[#res]
				name = _match(cd, 'name="(.-)"')
				filename = _match(cd, 'filename="(.-)"')
				if filename then
					local _, res, err = form:read()
					filetype = res[2]
				end

			elseif 'body' == typ then
				vals[#vals + 1] = res
				if filename then
					datasize = datasize + #res
				end

			elseif 'part_end' == typ then
				if name then
					if filename and not _isempty(vals) then 
						file[name] = {
													 name		= filename,
													 type		= filetype,
													 data		= _concat(vals),
													 size		= datasize,
												 }
					else
						post[name] = _concat(vals)
					end
				end

			end

		until 'eof' == typ

		return {post = post, file = file}

	end
}


--
-- 参数元表:用于支持tofu.args接口实现: args.get/post/file[key] | args('key')
--
local _args_mt = {
	__call = function (t, k)
		return rawget(t.post, k)
				or rawget(t.file, k)
				or rawget(t.get,  k)
				or rawget(t, k)
	end
}


local function _payload(ctx, flow)
	if not ctx.args then
		ctx.args = {}
	end
	local args = ctx.args
	_tab_merge(args, { get = {}, post={}, file={} })
	
	-- get 参数
	local uri_args, err = ngx.req.get_uri_args()
	_tab_merge(args, { get = uri_args })

	-- 非get, 非options 请求, post | put ...
	local method = ngx.req.get_method()
	if 'GET' ~= method and 'OPTIONS' ~= method then
		local content_type = (ngx.req.get_headers()['content-type'] or '')
		local isep = _find(content_type, ';', 1, true)
		if isep then
			content_type = _sub(content_type, 1, isep - 1)
		end
		local handle = _parser[ content_type ]
		if handle then
			_tab_merge(args, handle() or {})
		end
	end

	setmetatable(args, _args_mt)
	flow()
end


-- module
return function (options)
	options = options or {}
	_tab_merge(_parser, options.parser)
	return _payload
end

