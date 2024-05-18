-- 请求签到信息
Net.CmdUserSignInfoRequestSgnCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.UserSignInfoReturnSgnCmd_S"
	local uid = laccount.Id
	local signData = DaySign.CmdUserMonthSignInfoGet(uid)
	res["data"] = signData
	return res
end

-- 用户今日签到
Net.CmdUserSignTodayRequestSgnCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.UserSignTodayReturnSgnCmd_S"
	local uid = laccount.Id
	local signData = DaySign.CmdUserSignDayRequest(uid)
	res["data"] = signData
	return res
end