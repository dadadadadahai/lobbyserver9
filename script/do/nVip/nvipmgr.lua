--消息处理函数
Net.CmdGetVipInfoCmd_C=function (cmd,laccount)
    local res = {}
	res["do"] = "Cmd.GetVipInfoCmd_S"
	local uid = laccount.Id
    res['data'] = nvipmgr.GetVipInfoCmd_C(uid)
    return res
end
--领取vip奖励
Net.CmdRecvVipRewardCmd_C = function (cmd,laccount)
    local res = {}
	res["do"] = "Cmd.RecvVipRewardCmd_S"
	local uid = laccount.Id
    res['data'] = nvipmgr.RecvVipRewardCmd_C(uid)
    return res
end