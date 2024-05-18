--获取个人中心小游戏场景
Net.CmdCenterDiceInitCmd_C =function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    res['do']='Cmd.CenterDiceInitCmd_S'
    res['data'] = centerdicemgr.CenterDiceInitCmd_C(cmd.data,uid)
    return res
end
--开始玩骰子
Net.CmdCenterDicePlayCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    res['do']='Cmd.CenterDicePlayCmd_S'
    res['data'] = centerdicemgr.CenterDicePlayCmd_C(cmd.data,uid)
    return res
end