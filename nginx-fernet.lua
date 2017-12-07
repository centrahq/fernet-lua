local cjson = require "cjson"
local fernet = require "resty.fernet"
local secret = os.getenv("FERNET_SECRET")
local ttl = tonumber(os.getenv("FERNET_TTL"))

--testing the lib
--local test = require "resty.test_fernet"
--test.test()

assert(secret ~= nil, "Environment variable FERNET_SECRET not set")

-- ngx.log(ngx.WARN, "secret: " .. secret)

local M = {}

function M.auth(claim_specs)
    -- require Authorization request header
    local auth_header = ngx.var.http_Authorization

    token_site = os.getenv("NGINX_FERNET_TOKEN_SITE")
    
    if token_site == nil then 
        ngx.log(ngx.WARN, "No token site found, use default: HEADER")
        token_site = "HEADER"
    end
    
    if token_site == "HEADER" then
        if auth_header == nil then
            ngx.log(ngx.WARN, "No Authorization header")
            ngx.exit(ngx.HTTP_UNAUTHORIZED)
        end

        ngx.log(ngx.INFO, "Authorization: " .. auth_header)

    -- require Bearer token
        local _, _, token = string.find(auth_header, "Bearer%s+(.+)")

    end
    
    if token_site == "COOKIE" then
        token = ngx.var.cookie_bearer
    end
    
    if token_site == "REQUEST" then
        token = ngx.var.arg_bearer
    end
    
    if token == nil then
       ngx.log(ngx.WARN, "Missing token")
       ngx.exit(ngx.HTTP_UNAUTHORIZED)
    end   
    
    ngx.log(ngx.INFO, "Token: " .. token)

    local fernet_obj = fernet:verify(secret, token, ttl, ngx.time())
    if fernet_obj.verified == false then
        ngx.log(ngx.WARN, "Invalid token: ".. fernet_obj.reason)
        ngx.exit(ngx.HTTP_UNAUTHORIZED)
    end

    fernet_obj.payload = cjson.decode(fernet_obj.payload)

    -- write the X-Auth-UserId header
    -- ngx.header["X-Auth-UserId"] = fernet_obj.payload.sub
end


function M.table_contains(table, item)
    for _, value in pairs(table) do
        if value == item then return true end
    end
    return false
end

return M
