Net.CmdGetLampCmd_C=function (cmd,laccount)
    local send={}
    send['do'] = 'Cmd.GetLampCmd_S'
    send['data'] = racelamp.GetLampCmd_C(cmd.data)
    return send
end