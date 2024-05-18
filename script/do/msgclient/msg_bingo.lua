Net.CmdBingoInitCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    res['do']='Cmd.BingoInitCmd_S'
    res['data'] = bingomgr.BingoInitCmd_C(cmd.data,uid)
    return res
end
Net.CmdBingoPlayCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    res['do']='Cmd.BingoPlayCmd_S'
    res['data'] = bingomgr.BingoPlayCmd_C(cmd.data,uid)
    return res
end
Net.CmdBingoTaskInfoCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    res['do']='Cmd.BingoTaskInfoCmd_S'
    res['data'] = bingomgr.BingoTaskInfoCmd_C(cmd.data,uid)
    return res
end
Net.CmdBingoRecvTaskCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    res['do']='Cmd.BingoRecvTaskCmd_S'
    res['data'] = bingomgr.BingoRecvTaskCmd_C(cmd.data,uid)
    return res
end
Net.CmdBingoMainInfoCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    res['do']='Cmd.BingoMainInfoCmd_S'
    res['data'] = bingomgr.BingoMainInfoCmd_C(cmd.data,uid)
    return res
end