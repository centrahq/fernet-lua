local aes = require "resty.aes"
local hmac = require "resty.hmac"
local os = require "os"

local _M = {_VERSION="0.1.1"}
local mt = {__index=_M}

local aesBlocksize = 16
local version = 0x80
local luaPush = 1
local versionOffset = 1 + 0
local tsOffset = 1 + 1
local ivOffset = 1 + 1 + 8
local payOffset = 1 + 1 + 8 + 16
local maxClockSkew = 60 * 1

getmetatable('').__call = string.sub

local function log(s)
    ngx.log(ngx.WARN, s)
end

-- function string.fromhex(str)
--    return (str:gsub('..', function (cc)
--        return string.char(tonumber(cc, 16))
--    end))
-- end

function string.tohex(str)
    return (str:gsub('.', function (c)
        return string.format('%02X', string.byte(c))
    end))
end
function string.bytes(str)
    return (str:gsub('.', function (c)
        return string.byte(c)
    end))
end

local function parse(token_str)
    local raw_payload = _M:fernet_decode(token_str)

    local len = string.len(raw_payload);
    local raw_version = string.byte(raw_payload(versionOffset, 1), 1, -1)
    local raw_ts = raw_payload(tsOffset, 1 + 8)

    local ts = tonumber("0x" .. string.tohex(raw_ts)) --uint64
    local iv = raw_payload(ivOffset, 1 + 8 + 16)
    local payload = raw_payload(payOffset, len - 32)
    local signed = raw_payload(1, len - 32)
    local sha256 = raw_payload(1 + len - 32, len)

    if raw_version ~= version then
        error({reason="invalid version: " .. raw_version})
    end

    return {
        ts=ts,
        iv=iv,
        payload=payload,
        signed=signed,
        sha256=sha256
    }
end

function _M.fernet_decode(self, b64_str)
    b64_str = ngx.unescape_uri(b64_str):gsub("-", "+"):gsub("_", "/")
    local reminder = #b64_str % 4
    if reminder > 0 then
        b64_str = b64_str .. string.rep("=", 4 - reminder)
    end
    local data = ngx.decode_base64(b64_str)
    if not data then
        return nil
    end
    return data
end

function _M.load_fernet(self, fernet_str)
    local success, ret = pcall(parse, fernet_str)
    if not success then
        return {
            valid=false,
            verified=false,
            reason=ret["reason"] or "invalid fernet string"
        }
    end

    local fernet_obj = ret
    fernet_obj["verified"] = false
    fernet_obj["valid"] = true
    return fernet_obj
end

function _M.unpad(payload)
    if payload == nil then return nil else return payload end
end

function _M.verify_fernet_obj(self, secret, fernet_obj, ttl, now)

    if not fernet_obj.valid then
        return fernet_obj
    end

    local secret_len = string.len(secret) / 2
    local sign_secret = secret(1, secret_len)
    local crypt_secret = secret(1 + secret_len, -1)

    if ttl > 0 then
        if tonumber(os.date(now)) > tonumber(os.date(fernet_obj.ts + ttl)) then
            fernet_obj["reason"] = "token expired"
        elseif tonumber(os.date(fernet_obj.ts)) > tonumber(os.date(now + maxClockSkew)) then
            fernet_obj["reason"] = "token expired"
        end
    end
    
    local signature = hmac:new(sign_secret, hmac.ALGOS.SHA256):final(fernet_obj.signed)

    if signature == fernet_obj.sha256 then
        -- token valid!

        if string.len(fernet_obj.payload) % aesBlocksize ~= 0 then
            fernet_obj["reason"] = "wrong blocksize"
        else
    
            local aes_128_cbc_with_iv = assert(aes:new(crypt_secret,
            nil, aes.cipher(128,"cbc"), {iv=fernet_obj.iv}))
    
            local payload = aes_128_cbc_with_iv:decrypt(fernet_obj.payload)
    
            payload = _M.unpad(payload)
    
            if payload == nil then
                fernet_obj["reason"] = "invalid padding"
            else
                fernet_obj["payload"] = payload
            end
        end
    else
        fernet_obj["reason"] = "invalid mac"
    end

    if not fernet_obj["reason"] then
        fernet_obj["verified"] = true
    end
    return fernet_obj
end

function _M.decode_base64url(secret)
    local r = #secret % 4
    if r == 2 then
        secret = secret .. "=="
    elseif r == 3 then
        secret = secret .. "="
    end
    secret = secret:gsub("-", "+"):gsub("_", "/")
    secret = ngx.decode_base64(secret)
    return secret
end

function _M.verify(self, secret, fernet_str, ttl, now)
    local secret = _M.decode_base64url(secret)

    fernet_obj = _M.load_fernet(self, fernet_str)
    if not fernet_obj.valid then
         return {verified=false, reason=fernet_obj["reason"]}
    end
    return _M.verify_fernet_obj(self, secret, fernet_obj, ttl, now)
end

return _M



