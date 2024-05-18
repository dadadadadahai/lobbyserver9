--跑马灯 游戏类客户端调用
Net.CmdGetLampClientCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local send={}
    send['do'] = 'Cmd.GetLampClientCmd_S'
    send['data'] = lampgame.GetLampClientCmd_C(uid,cmd.data)
    return send
end