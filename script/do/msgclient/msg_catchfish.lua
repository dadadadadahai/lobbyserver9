--获取捕鱼基础信息
Net.CmdCachFishInitCmd_C =function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    res['do']='Cmd.CachFishInitCmd_S'
    res['data'] = catchfishmgr.CachFishInitCmd_C(cmd.data,uid)
    return res
end
--通过入场卷进场
Net.CmdCatchFishEnterCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    res['do']='Cmd.CatchFishEnterCmd_S'
    res['data'] = catchfishmgr.CatchFishEnterCmd_C(cmd.data,uid)
    return res
end
--挖出命令
Net.CmdCatchFishPlayCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    res['do']='Cmd.CatchFishPlayCmd_S'
    res['data'] = catchfishmgr.CatchFishPlayCmd_C(cmd.data,uid)
    return res
end
--领取集齐奖励
Net.CmdCatchFishJiQiCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    res['do']='Cmd.CatchFishJiQiCmd_S'
    res['data'] = catchfishmgr.CatchFishJiQiCmd_C(cmd.data,uid)
    return res
end
--领取关卡进度奖励
Net.CmdCatchFishRecvAwardCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    res['do']='Cmd.CatchFishRecvAwardCmd_S'
    res['data'] = catchfishmgr.CatchFishRecvAwardCmd_C(cmd.data,uid)
    return res
end
--领取通关奖励
Net.CmdCatchFishRecvPassCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    res['do']='Cmd.CatchFishRecvPassCmd_S'
    res['data'] = catchfishmgr.CatchFishRecvPassCmd_C(cmd.data,uid)
    return res
end
--请求或刷新商店
Net.CmdCatchFishFreshShopCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    res['do']='Cmd.CatchFishFreshShopCmd_S'
    res['data'] = catchfishmgr.CatchFishFreshShopCmd_C(cmd.data,uid)
    return res
end
--卖出鱼
Net.CmdCatchFishSoldFishCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    res['do']='Cmd.CatchFishSoldFishCmd_S'
    res['data'] = catchfishmgr.CatchFishSoldFishCmd_C(cmd.data,uid)
    return res
end
--获取任务相关信息
Net.CmdCatchFishGetTaskCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    res['do']='Cmd.CatchFishGetTaskCmd_S'
    res['data'] = catchfishmgr.CatchFishGetTaskCmd_C(cmd.data,uid)
    return res
end
--领取任务奖励
Net.CmdCatchFishRecvTaskCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    res['do']='Cmd.CatchFishRecvTaskCmd_S'
    res['data'] = catchfishmgr.CatchFishRecvTaskCmd_C(cmd.data,uid)
    return res
end
--捕鱼主界面信息展示
Net.CmdCatchFishMainInfoCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    res['do']='Cmd.CatchFishMainInfoCmd_S'
    res['data'] = catchfishmgr.CatchFishMainInfoCmd_C(cmd.data,uid)
    return res
end