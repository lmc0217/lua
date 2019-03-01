-- auth_token.lua
-- 请求验证模块
local cjson = require "cjson"
local redis = require "redis_mcredis"
local red = redis:new()

local _reqnManager = {}
_reqnManager._VERSION = '1.0.0'
_reqnManager._AUTHOR = 'Chao'

-- 判断Redis值是否为空
local function is_redis_null( res )
    if type(res) == "table" then
        for k,v in pairs(res) do
            if v ~= ngx.null then
                return false
            end
        end
        return true
    elseif res == ngx.null then
        return true
    elseif res == nil then
        return true
    end
    return false
end

-- 验证Auth Token合法性并返回User ID
function _reqnManager.check_auth_token(self, requst_headers)
	local user_id, err = red:hget("token_"..requst_headers["token"], "userid")
	if is_redis_null(user_id) then
		ngx.log(ngx.INFO, string.format("Token:%s, 找不到对应UserID", requst_headers["token"]))
		return nil
	end
	return user_id
end

-- 验证入口，验证请求合法性
-- 返回block结构休
--[[
_result = {
	code = 0,
	msg = "",
	data = {}
}
code说明：
0：默认值
10001:token过期
--]]
function _reqnManager.check_requst_validity(self)
	local _result = {
		code = 0,
		msg = "",
		data = {}
	}
	local headers = ngx.req.get_headers()
	ngx.log(ngx.INFO, string.format("请求接口传入headers :%s\n", cjson.encode(headers)))
	-- 验证Token合法性并返回User ID
	local user_id = self:check_auth_token(headers)
	if not user_id then
		_result.code = 10001
		_result.msg = "token has been invalid"
		return _result, nil
	end
	ngx.req.set_header("userid", user_id);
	return _result, nil
end
 

 
function _reqnManager.new(self, req_entity)
	local req_entity = req_entity or {}
	setmetatable(req_entity, self)
	self.__index = self
	return req_entity
end

return _reqnManager