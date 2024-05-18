Net.CmdKindQueenSceneCmd_C = function (cmd,laccount)
    local uid = laccount.Id
    local gameType = cmd.data.gameType
    local res={}
    res['do']='Cmd.KindQueenSceneCmd_S'
    res['data'] = KindQueen.Scene(gameType,laccount,uid)
    return res
end
Net.CmdKindQueenBetCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local gameType = cmd.data.gameType
    local res={}
    res['do'] = 'Cmd.KindQueenBetCmd_S'
    res['data'] = KindQueen.Betting(gameType,cmd.data.extraData.betinfo,uid)
    return res
end
Net.CmdKindQueenBatchBetCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local gameType = cmd.data.gameType
    local res={}
    res['do'] = 'Cmd.KindQueenBatchBetCmd_S'
    res['data'] = KindQueen.KindQueenBatchBetCmd_C(gameType,cmd.data.extraData.betinfo,uid)
    return res
end
Net.CmdKindQueenGetRankCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local gameType = cmd.data.gameType
    local res={}
    res['do'] = 'Cmd.KindQueenGetRankCmd_S'
    res['data'] = KindQueen.KindQueenGetRankCmd_C(gameType,uid)
    return res
end