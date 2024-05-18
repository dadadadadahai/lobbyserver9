--服务器机器人
Lby.CmdGetLampCmd_C=function (cmd, lobbytask)
    local data=cmd.data
    lampgame.GetLampCmd_C(data)
end
--服务器广播添加
Lby.CmdReportLampCmd_S = function (cmd,lobbytask)
    lampgame.ZoneAddLamp(cmd.data)
end
--后台推送广播
Lby.CmdSysNewsCmd_S=function (cmd,lobbytask)
    lampgame.SysNewsCmd_C(cmd.data)
end
--删除系统广播
Lby.CmdDelSysNewsCmd_S=function (cmd,lobbytask)
    lampgame.DelSysNewsCmd_S(cmd.data)
end
