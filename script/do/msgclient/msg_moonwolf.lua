--请求游戏场景信息 初次进入游戏需要使用
Net.CmdWolfSceneCmd_C=function (cmd,laccount)
    local res = {}
    local uid = laccount.Id
	res["do"] = "Cmd.WolfSceneCmd_S"
    res["data"] =moonwolfmgr.WolfSceneCmd(uid)
    return res
end
--改变下注筹码消息体
Net.CmdChangeBetIndexCmd_C=function (cmd,laccount)
    local res = {}
    local uid = laccount.Id
    local betindex= cmd.data.betindex or 0
	res["do"] = "Cmd.ChangeBetIndexCmd_S"
    res["data"] =moonwolfmgr.ChangeBetIndexCmd(betindex,uid)
    return res
end
--拉动游戏过程
Net.CmdWolfPlayCmd_C=function (cmd,laccount)
    local res = {}
    local uid = laccount.Id
	res["do"] = "Cmd.WolfPlayCmd_S"
    res["data"] =moonwolfmgr.WolfPlayCmd(uid)
    return res
end
