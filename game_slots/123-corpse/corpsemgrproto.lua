Net.CmdCorpseDoubleCmd_C= function(cmd, laccount)
    corpse.CmdCorpseDouble(laccount.Id,cmd.data)
end
Net.CmdCorpseRecvNormalScoreCmd_C=function (cmd,laccount)
    corpse.CmdCorpseRecvNormalScore(laccount.Id,cmd.data)
end