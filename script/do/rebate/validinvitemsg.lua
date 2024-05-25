--领取vip奖励
Net.CmdValidinViteRewardCmd_C = function (cmd,laccount)
    local res = {}
	res["do"] = "Cmd.ValidinViteRewardCmd_S"
	local uid = laccount.Id
    res['data'] = rebate.GetInviteReward(uid,cmd.data.type)
    return res
end


--查询返利表
Net.CmdQueryRebateRelationCmd_C=function(cmd,laccount)
    local res = {}
	res["do"] = "Cmd.QueryRebateRelationCmd_S"
	local uid = laccount.Id
    res['data'] = rebate.QueryRebateRelation(uid,cmd.data.type)
    return res
end

--领取返利
Net.CmdRecvRebateRelationCmd_C = function(cmd,laccount)
    local res = {}
	res["do"] = "Cmd.RecvRebateRelationCmd_S"
	local uid = laccount.Id
    res['data'] = rebate.RecvRebateRelation(uid,cmd.data.type)
    return res
end