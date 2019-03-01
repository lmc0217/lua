local cjson = require "cjson"
-- 检查是否合法的请求头
local auth_req_headers = require "auth_req_headers"
local headerManager = auth_req_headers:new()

local is_has_token = true
if ngx.re.match(ngx.var.uri,"^(/iotapi/login).*$|(/iotapi/userauth).*$") then
	is_has_token = false
end

local headerResult = headerManager:check_req_headers(is_has_token)
if not headerResult then
	ngx.log(ngx.INFO, "请求头不合法")
	ngx.exit(403)
end

if not is_has_token then
	-- no token request, exec @auth_success
	return ngx.exec("@auth_success")
end

-- 令牌验证
local auth_token = require "auth_token"
local tokenManager = auth_token:new()
local checkResult, err = tokenManager:check_requst_validity()

-- 处理验证结果
local switch = {
	[10001] = function(response)
				-- Request Error The Token Is Timeout
				ngx.say(cjson.encode(response))
			end
}
local s_case = switch[checkResult["code"]]
if (s_case) then
	s_case(checkResult)
else
	-- for case default, success
	return ngx.exec("@auth_success")
end