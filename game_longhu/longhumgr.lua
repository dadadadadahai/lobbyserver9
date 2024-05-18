Net.CmdLongHuSceneCmd_C = function (cmd,laccount)
    local uid = laccount.Id
    local gameType = cmd.data.gameType
    local res={}
    res['do']='Cmd.LongHuSceneCmd_S'
    res['data'] = LongHu.Scene(gameType,laccount,uid)
    return res
end
Net.CmdLongHuBetCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local gameType = cmd.data.gameType
    local res={}
    res['do'] = 'Cmd.LongHuBetCmd_S'
    res['data'] = LongHu.Betting(gameType,cmd.data.extraData.betinfo,uid)
    return res
end
Net.CmdLongHuBatchBetCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local gameType = cmd.data.gameType
    local res={}
    res['do'] = 'Cmd.LongHuBatchBetCmd_S'
    res['data'] = LongHu.LongHuBatchBetCmd_C(gameType,cmd.data.extraData.betinfo,uid)
    return res
end
Net.CmdLongHuGetRankCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local gameType = cmd.data.gameType
    local res={}
    res['do'] = 'Cmd.LongHuGetRankCmd_S'
    res['data'] = LongHu.LongHuGetRankCmd_C(gameType,uid)
    return res
end