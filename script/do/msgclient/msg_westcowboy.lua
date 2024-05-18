--客户端请求场景信息
Net.CmdWestSceneCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local send={}
    send['do']='Cmd.WestSceneCmd_S'
    send['data'] = westcowboymgr.WestSceneCmd_C(cmd.data,uid)
    return send
end
--客户端请求筹码信息
Net.CmdWestChangeBetIndexCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local send={}
    send['do']='Cmd.WestChangeBetIndexCmd_S'
    send['data'] = westcowboymgr.WestChangeBetIndexCmd_C(cmd.data,uid)
    return send
end
--拉动游戏
Net.CmdWestPlayCmd_C = function (cmd,laccount)
    local uid = laccount.Id
    local send={}
    send['do']='Cmd.WestPlayCmd_S'
    send['data'] = westcowboymgr.WestPlayCmd_C(cmd.data,uid)
    return send
end