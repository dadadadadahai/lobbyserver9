--消息处理函数
Net.CmdGetInviteRouletteInfoCmd_C=function (cmd,laccount)
    local res = {}
	res["do"] = "Cmd.GetInviteRouletteInfoCmd_S"
	local uid = laccount.Id
    res['data'] = InviteRoulette.ReturnInviteRouletteInfo(uid)
    return res
end
--查询电话号码
Net.CmdGetInviteRoulettePhoneInfoCmd_C=function (cmd,laccount)
    local res = {}
	res["do"] = "Cmd.GetInviteRoulettePhoneInfoCmd_S"
	local uid = laccount.Id
    res['data'] = InviteRoulette.GetPhoneNumber()
    return res
end
--领取转盘奖励
Net.CmdRecvInviteRouletteRewardCmd_C = function (cmd,laccount)
    local res = {}
	res["do"] = "Cmd.RecvInviteRouletteRewardCmd_S"
	local uid = laccount.Id
    res['data'] = InviteRoulette.GetDayRoulette(uid)
    return res
end