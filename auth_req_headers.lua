-- auth_req_headers.lua

local _reqHeader = {}
_reqHeader._VERSION = '1.0.0'
_reqHeader._AUTHOR = 'Chao'

-- 查询请求头是否合法(登录接口)
function _reqHeader.is_headers_legal_notoken()
	local headers = ngx.req.get_headers()
	if not headers["language"] then
		return false
	else 
		--
		return true
	end
	return true
end

-- 查询请求头是否合法
function _reqHeader.is_headers_legal()
	local headers = ngx.req.get_headers()
	if not headers["language"] then
		return false
	elseif not headers["token"] then
		return false
	else 
		--
		return true
	end
	return true
end
-- 验证此次请求头合法性
-- 返回block结构休
--[[
_result = {
	status = 0,
	msg = "",
	data = {}
}
status说明：
0：默认值
101:没有该账号
102:账号与密码错误
--]]
function _reqHeader.check_req_headers(self, is_has_token)
	-- 优先验证是请求头合法性
	if is_has_token then
		if not self:is_headers_legal() then
			return false
		end
	else
		if not self:is_headers_legal_notoken() then
			return false
		end
	end
	return true
end
 
function _reqHeader.new(self, login_entity)
	local login_entity = login_entity or {}
	setmetatable(login_entity, self)
	self.__index = self
	return login_entity
end

return _reqHeader