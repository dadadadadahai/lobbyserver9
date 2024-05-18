-- 处理转盘相关协议

-- 获取转盘信息
Net.CmdGetInfoTurnTableCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetInfoTurnTableCmd_S"

	local uid = laccount.Id

	local ret, desc, turnTableInfo, turnCoupon = TurnTableMgr.GetTurnTableInfo(uid)
	res["data"] = {
		resultCode = ret,
		desc = desc,
		days = turnTableInfo.days,
		times = turnTableInfo.times,
		turnCoupon = turnCoupon,
		isOpen = turnTableInfo.isOpen,
	}
	return res
end

-- 转动转盘
Net.CmdTurnTurnTableCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.TurnTurnTableCmd_S"

	local uid = laccount.Id

	local ret, desc, times, turnId, mul, turnCoupon, remainder = TurnTableMgr.TurnTurnTable(uid)
	res["data"] = {
		resultCode = ret,
		desc = desc,
		times = times,
		turnId = turnId,
		multiple = mul,
		turnCoupon = turnCoupon,
		remainder = remainder,
	}
	return res
end

-- 获取累计奖励
Net.CmdGetCumulativeRewordTurnTableCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetCumulativeRewordTurnTableCmd_S"

	local uid = laccount.Id

	local ret, desc, getId, remainder = TurnTableMgr.GetCumulativeReword(uid)
	res["data"] = {
		resultCode = ret,
		desc = desc,
		getId = getId,
		remainder = remainder,
	}
	return res
end