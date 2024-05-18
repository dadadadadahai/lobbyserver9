--获取场景信息
Net.CmdWorldCupSceneCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local gameType = cmd.data.gameType
    local res={}
    res['do']='Cmd.WorldCupSceneCmd_S'
    res['data'] = WorldCup.Scene(gameType,laccount,uid)
    return res
end
Net.CmdWorldCupBetCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local gameType = cmd.data.gameType
    local res={}
    res['do'] = 'Cmd.WorldCupBetCmd_S'
    res['data'] = WorldCup.Betting(gameType,cmd.data.extraData.betinfo,uid)
    return res
end
Net.CmdWorldCupBatchBetCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local gameType = cmd.data.gameType
    local res={}
    res['do'] = 'Cmd.WorldCupBatchBetCmd_S'
    res['data'] = WorldCup.WorldCupBatchBetCmd_S(gameType,cmd.data.extraData.betinfo,uid)
    return res
end
Net.CmdWorldCupGetRankCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local gameType = cmd.data.gameType
    local res={}
    res['do'] = 'Cmd.WorldCupGetRankCmd_S'
    res['data'] = WorldCup.WorldCupGetRankCmd_C(gameType,uid)
    return res
end