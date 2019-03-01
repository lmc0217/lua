token有效验证
---
# 前言

token系统，之前应项目需求写了token验证系统。基于nginx+lua+redis,通过redis设置token时效性来控制token的可用性。是一个完整的token系统，包含登录验证、token生成、token时效性控制、token验证、反向代理转发内部服务等功能。
此文并不打算封装完整的一个系统，因为后面小生在有空没事设计系统玩的时候，希望兼容第三方平台登录时，发现大多第三方都是有自己的一套登录授权与换取openid(或其他唯一的身份id)机制。此时如果多个第三方的登录由于差异性，又要在lua上去兼容和实现的话，显得很繁琐且扩展性不高。
故，此文只抽取了其中的token验证功能。

# 环境

* openresty（自带ngx_lua模块）
* redis
* linux或其他服务主机

# 一、基本设计思路

* 前端在请求头设置用户token，
* nginx上通过lua获取token，配合redis验证并转换成系统用户的userid
* 重写请求头再转发请求至内部服务。

# 二、redis设计

## 1.用户ID->Token对应关系

userid=> token (hash)
```
userid_(userid): {
  token:(token)
}
```

## 2.Token->用户ID对应关系

token=>userid
```
token_(token): {
  userid:(userid)
}
```

# Nginx+Lua+Redis实现token验证

## 1.lua脚本目录结构

```shell
lmc:tokenGateway chao$ tree lua/
lua/
├── auth_req_headers.lua  # 请求头校验脚本，失败直接中断请求403
├── auth_token.lua  # token处理脚本
├── handlefile
│   ├── handle_cors.lua # 请求跨域脚本
│   └── handle_request_provision.lua # 请求handle入口脚本
├── redis_mcredis.lua # redis操作工具封装（基本来自网络佚名前辈们封装，小生只是稍加修改，增加了redis域名解析，感谢前辈们的付出）
└── tool_dns_server.lua # 域名解析，获取域名对应的ip，并设置缓存

1 directory, 6 files
```

## 2.nginx配置

* nginx.conf
```shell
worker_processes  1; 
error_log logs/error.log info; 

events {
	worker_connections 1024;
}

upstream iotserver{
	server unix:/run/gunicorn/iot.sock fail_timeout=0;
}

http {
	# lua custom path, use absolute path please.
	lua_package_path "/etc/nginx/lua/?.lua;;";

	server {
		listen 8080;
		access_log logs/access.log;
		location @auth_success{
			proxy_set_header Host $http_host;
			proxy_pass  http://iotserver;
		}

		location / {
			# CORS
			header_filter_by_lua_file /etc/nginx/lua/handlefile/handle_cors.lua;
			if ($request_method = 'OPTIONS') {
						return 204;
			}
			
			access_by_lua_file /etc/nginx/lua/handlefile/handle_request_provision.lua;
		}
	}
}

```

* token验证失败错误码

| 错误码 | 描述      |
| :----- | :-------- |
| -1     | 系统错误  |
| 10001  | token失效 |