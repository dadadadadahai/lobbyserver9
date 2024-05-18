-- 登陆时请求等待时间
Net.CmdUserNextTimesRequestSgnCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.UserNextTimesReturnSgnCmd_S"
	local uid = laccount.Id
	local nextTimes = DaySign.CmdUserNextTimesRequest(uid)
	res["data"] = {
		resultCode = 0,
		desc = "ok",
		nextTimes = nextTimes,
	}
	return res
end

-- 请求签到信息
Net.CmdUserTimeRewardRequestSgnCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.UserTimeRewardReturnSgnCmd_S"
	local uid = laccount.Id
	local bOk, nextTimes, rewardChips, index = DaySign.CmdUserTimeRewardRequest(uid) 
	if bOk == false then
		res["data"] = {
			resultCode = 1,
			desc = "时间未到",
			nextTimes = nextTimes,
		}
		return res
	end
	local summary = BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, rewardChips, Const.GOODS_SOURCE_TYPE.SIGN)
	local remainder = summary[Const.GOODS_ID.GOLD_BASE]
	local timeRewardItem = {
		id = index,
		times = TableOnTimeRewardConfig[index].seconds,
		rewardChips = rewardChips,
	}
	res["data"] = {
		resultCode = 0,
		desc = "ok",
		timeRewardInfo = timeRewardItem,
		nextTimes = nextTimes,
		remainder = remainder,
		index = index,
	}
	return res
end
