local fernet = require "resty.fernet"

local M = { _VERSION = '0.10' }

function M.makeTimeStamp(dateString)
    local pattern = "(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)([%+%-])(%d+)%:(%d+)"
    local xyear, xmonth, xday, xhour, xminute, 
        xseconds, xoffset, xoffsethour, xoffsetmin = dateString:match(pattern)
    local convertedTimestamp = os.time({year = xyear, month = xmonth, 
        day = xday, hour = xhour, min = xminute, sec = xseconds})
    local offset = xoffsethour * 60 + xoffsetmin -- offsetminutes
	offset = offset * 60 --seconds
    if xoffset ~= "-" then offset = offset * -1 end
	local timezoneoffset = M.get_timezone_offset(convertedTimestamp)
    return convertedTimestamp + offset + timezoneoffset
end

-- debug
-- print("fernet: " .. os.date("!%Y-%m-%dT%TZ", M.makeTimeStamp("1985-10-26T01:20:01-07:00")))

function M.get_timezone_offset(ts)
	local utcdate   = os.date("!*t", ts)
	local localdate = os.date("*t", ts)
	localdate.isdst = false -- this is the trick
	return os.difftime(os.time(localdate), os.time(utcdate))
end

function M.test()
    local fernet_obj = fernet:verify("cw_0x689RpI-jtRR7oE8h_eQsKImvJapLeSbXpwF4e4=", "gAAAAAAdwJ6wAAECAwQFBgcICQoLDA0ODy021cpGVWKZ_eEwCGM4BLLF_5CV9dOPmrhuVUPgJobwOz7JcbmrR64jVmpU4IwqDA==", 60, M.makeTimeStamp("1985-10-26T01:20:01-07:00"))
    if fernet_obj.verified == false then
        print("Invalid token: ".. fernet_obj.reason)
    else
		print("Success 1")
	end

    local fernet_obj = fernet:verify("cw_0x689RpI-jtRR7oE8h_eQsKImvJapLeSbXpwF4e4=", "gAAAAAAdwJ6wAAECAwQFBgcICQoLDA0ODy021cpGVWKZ_eEwCGM4BLLF_5CV9dOPmrhuVUPgJobwOz7JcbmrR64jVmpU4IwqDA==", -1, M.makeTimeStamp("1985-10-26T01:20:01-07:00"))
    if fernet_obj.verified == false then
        print("Invalid token: ".. fernet_obj.reason)
    else
		print("Success 2")
	end

	-- invalid 

    local fernet_obj = fernet:verify("cw_0x689RpI-jtRR7oE8h_eQsKImvJapLeSbXpwF4e4=", "gAAAAAAdwJ6xAAECAwQFBgcICQoLDA0OD3HkMATM5lFqGaerZ-fWPAl1-szkFVzXTuGb4hR8AKtwcaX1YdykQUFBQUFBQUFBQQ==", 60, M.makeTimeStamp("1985-10-26T01:20:01-07:00"))
    if fernet_obj.verified == false then
		print("Success 1 " .. fernet_obj.reason)
    else
        print("Valid token should be invalid")
	end

    local fernet_obj = fernet:verify("cw_0x689RpI-jtRR7oE8h_eQsKImvJapLeSbXpwF4e4=", "gAAAAAAdwJ6xAAECAwQFBgcICQoLDA0OD3HkMATM5lFqGaerZ-fWPA==", 60, M.makeTimeStamp("1985-10-26T01:20:01-07:00"))
    if fernet_obj.verified == false then
		print("Success 2 " .. fernet_obj.reason)
    else
        print("Valid token should be invalid")
	end

    local fernet_obj = fernet:verify("cw_0x689RpI-jtRR7oE8h_eQsKImvJapLeSbXpwF4e4=", "%%%%%%%%%%%%%AECAwQFBgcICQoLDA0OD3HkMATM5lFqGaerZ-fWPAl1-szkFVzXTuGb4hR8AKtwcaX1YdykRtfsH-p1YsUD2Q==", 60, M.makeTimeStamp("1985-10-26T01:20:01-07:00"))
    if fernet_obj.verified == false then
		print("Success 3 " .. fernet_obj.reason)
    else
        print("Valid token should be invalid")
	end

    local fernet_obj = fernet:verify("cw_0x689RpI-jtRR7oE8h_eQsKImvJapLeSbXpwF4e4=", "gAAAAAAdwJ6xAAECAwQFBgcICQoLDA0OD3HkMATM5lFqGaerZ-fWPOm73QeoCk9uGib28Xe5vz6oxq5nmxbx_v7mrfyudzUm", 60, M.makeTimeStamp("1985-10-26T01:20:01-07:00"))
    if fernet_obj.verified == false then
		print("Success 4 " .. fernet_obj.reason)
    else
        print("Valid token should be invalid")
	end

    local fernet_obj = fernet:verify("cw_0x689RpI-jtRR7oE8h_eQsKImvJapLeSbXpwF4e4=", "gAAAAAAdwJ6xAAECAwQFBgcICQoLDA0ODz4LEpdELGQAad7aNEHbf-JkLPIpuiYRLQ3RtXatOYREu2FWke6CnJNYIbkuKNqOhw==", 60, M.makeTimeStamp("1985-10-26T01:20:01-07:00"))
    if fernet_obj.verified == false then
		print("Success 5 " .. fernet_obj.reason)
    else
        print("Valid token should be invalid")
	end

    local fernet_obj = fernet:verify("cw_0x689RpI-jtRR7oE8h_eQsKImvJapLeSbXpwF4e4=", "gAAAAAAdwStRAAECAwQFBgcICQoLDA0OD3HkMATM5lFqGaerZ-fWPAnja1xKYyhd-Y6mSkTOyTGJmw2Xc2a6kBd-iX9b_qXQcw==", 60, M.makeTimeStamp("1985-10-26T01:20:01-07:00"))
    if fernet_obj.verified == false then
		print("Success 6 " .. fernet_obj.reason)
    else
        print("Valid token should be invalid")
	end

    local fernet_obj = fernet:verify("cw_0x689RpI-jtRR7oE8h_eQsKImvJapLeSbXpwF4e4=", "gAAAAAAdwJ6xAAECAwQFBgcICQoLDA0OD3HkMATM5lFqGaerZ-fWPAl1-szkFVzXTuGb4hR8AKtwcaX1YdykRtfsH-p1YsUD2Q==", 60, M.makeTimeStamp("1985-10-26T01:21:31-07:00"))
    if fernet_obj.verified == false then
		print("Success 7 " .. fernet_obj.reason)
    else
        print("Valid token should be invalid")
	end

    local fernet_obj = fernet:verify("cw_0x689RpI-jtRR7oE8h_eQsKImvJapLeSbXpwF4e4=", "gAAAAAAdwJ6xBQECAwQFBgcICQoLDA0OD3HkMATM5lFqGaerZ-fWPAkLhFLHpGtDBRLRTZeUfWgHSv49TF2AUEZ1TIvcZjK1zQ==", 60, M.makeTimeStamp("1985-10-26T01:20:01-07:00"))
    if fernet_obj.verified == false then
		print("Success 8 " .. fernet_obj.reason)
    else
        print("Valid token should be invalid")
	end

    local fernet_obj = fernet:verify("cw_0x689RpI-jtRR7oE8h_eQsKImvJapLeSbXpwF4e", "gAAAAAAdwJ6wAAECAwQFBgcICQoLDA0ODy021cpGVWKZ_eEwCGM4BLLF_5CV9dOPmrhuVUPgJobwOz7JcbmrR64jVmpU4IwqDA==", -1, M.makeTimeStamp("1985-10-26T01:20:01-07:00"))
    if fernet_obj.verified == false then
		print("Success 9 " .. fernet_obj.reason)
    else
        print("Valid token should be invalid")
	end
end

return M

