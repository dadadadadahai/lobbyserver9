Net.CmdRocketSceneCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local gameType = cmd.data.gameType
    local res={}
    res['do']='Cmd.RocketSceneCmd_S'
    res['data'] = rocket.Scene(gameType,laccount,uid)
    return res
end
Net.CmdRocketBetCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local gameType = cmd.data.gameType
    local res={}
    res['do'] = 'Cmd.RocketBetCmd_S'
    res['data'] = rocket.Betting(gameType,cmd.data.chip,uid)
    return res
end
Net.CmdClickSettleCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local gameType = cmd.data.gameType
    local res={}
    res['do'] = 'Cmd.ClickSettleCmd_S'
    res['data'] = rocket.ClickSettle(gameType,uid)
    return res
end