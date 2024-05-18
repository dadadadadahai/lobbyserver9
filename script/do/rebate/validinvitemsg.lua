--领取vip奖励
Net.CmdValidinViteRewardCmd_C = function (cmd,laccount)
    local res = {}
	res["do"] = "Cmd.ValidinViteRewardCmd_S"
	local uid = laccount.Id
    res['data'] = rebate.GetInviteReward(uid,cmd.data.type)
    return res
end