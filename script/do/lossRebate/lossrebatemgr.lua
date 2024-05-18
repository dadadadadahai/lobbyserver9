--消息处理函数
Net.CmdGetLossRebateInfoCmd_C=function (cmd,laccount)
    local res = {}
	res["do"] = "Cmd.GetLossRebateInfoCmd_S"
	local uid = laccount.Id
    res['data'] = LossRebate.GetInfo(uid)
    return res
end
--领取vip奖励
Net.CmdLossRebateRewardCmd_C = function (cmd,laccount)
    local res = {}
	res["do"] = "Cmd.LossRebateRewardCmd_S"
	local uid = laccount.Id
    res['data'] = LossRebate.GetReward(uid)
    return res
end