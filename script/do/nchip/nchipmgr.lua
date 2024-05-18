--消息处理函数
--领取返利金币
Net.CmdRecvNchipCmd_C=function (cmd,laccount)
    local res = {}
	res["do"] = "Cmd.RecvNchipCmd_S"
	local uid = laccount.Id
    res['data'] = nchip.CmdRecvNchipCmd_C(uid,cmd.data)
    return res
end
--领取免费有效玩家金币
Net.CmdRecvFreeViteChipsCmd_C=function(cmd,laccount)
    local res = {}
	res["do"] = "Cmd.RecvFreeViteChipsCmd_S"
	local uid = laccount.Id
    res['data'] = nchip.RecvFreeViteChipsCmd_S(uid,cmd.data)
    return res
end