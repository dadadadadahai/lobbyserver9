--获取基本信息
Net.CmdGetCofrinhoInfoCmd_C =function (cmd,laccount)
    local res = {}
	res["do"] = "Cmd.GetCofrinhoInfoCmd_S"
	local uid = laccount.Id
    res['data'] = cofrinho.GetcofrinhoInfoCmd_C(uid,cmd.data)
    return res
end
Net.CmdRecvSilverCmd_C = function (cmd,laccount)
    local res = {}
	res["do"] = "Cmd.RecvSilverCmd_S"
	local uid = laccount.Id
    res['data'] = cofrinho.RecvSilverCmd_C(uid,cmd.data)
    return res
end