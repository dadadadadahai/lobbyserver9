Net.CmdClubScoreTest_C=function (cmd,laccount)
    local res={}
    local uid =laccount.Id
    res['do']='Cmd.CmdClubTest_S'
    res['data'] = clubmgr.ClubScoreTest(cmd.data,uid)
    return res
end
--庄园入口命令
Net.CmdClubInitCmd_C=function (cmd,laccount)
    local res={}
    local uid = laccount.Id
    res['do']='Cmd.ClubInitCmd_S'
    res['data'] = clubmgr.ClubInitCmd(uid)
    return res
end
--领取通行证溢出奖励
Net.CmdClubRecvExChangeCmd_C=function (cmd,laccount)
    local res={}
    local uid = laccount.Id
    res['do']='Cmd.ClubRecvExChangeCmd_S'
    res['data'] = clubmgr.ClubRecvExChangeCmd(uid)
    return res
end

--离开庄园界面
Net.CmdLeaveClubCmd_C=function (cmd,laccount)
    local res={}
    local uid = laccount.Id
    res['do']='Cmd.ClubInitCmd_S'
    res['data'] = clubmgr.LeaveClubCmd(uid)
    return res
end
--获取城堡信息
Net.CmdCastleInfoGetCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    res['do'] = 'Cmd.CastleInfoGetCmd_S'
    res['data'] = clubmgr.GetCastleInfoCmd(uid)
    return res
end
--领取每日奖励
Net.CmdCastleRecvDayBoxCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    local data=  cmd.data
    res['do'] = 'Cmd.CastleRecvDayBoxCmd_S'
    if data~=nil then
        res['data'] = clubmgr.CastleRecvDayBoxCmd(data,uid)
    end
    return res
end
--蓝宝石购买普通材料
Net.CmdCastleBuyNormalCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    local data=  cmd.data
    res['do'] = 'Cmd.CastleBuyNormalCmd_S'
    if data~=nil then
        res['data'] = clubmgr.CastleBuyNormalCmd(data,uid)
    end
    return res
end
--绿宝石购买高级材料
Net.CmdCastleBuyHighCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    local data=  cmd.data
    res['do'] = 'Cmd.CastleBuyHighCmd_S'
    if data~=nil then
        res['data'] = clubmgr.CastleBuyHighCmd(data,uid)
    end
    return res
end
--领取首次合成高级材料奖励
Net.CmdCastleRecvStuffCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    local data=  cmd.data
    res['do'] = 'Cmd.CastleRecvStuffCmd_S'
    if data~=nil then
        res['data'] = clubmgr.CastleRecvStuffCmd(data,uid)
    end
    return res
end
--领取进度奖励
Net.CmdCastleRecvRateCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    local data=  cmd.data
    res['do'] = 'Cmd.CastleRecvRateCmd_S'
    if data~=nil then
        res['data'] = clubmgr.CastleRecvRateCmd(data,uid)
    end
    return res
end
--领取通关奖励
Net.CmdCastlePassCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    local data=  cmd.data
    res['do'] = 'Cmd.CastlePassCmd_S'
    if data~=nil then
        res['data'] = clubmgr.CastlePassCmd(data,uid)
    end
    return res
end
--使用宝箱
Net.CmdCastleUseBlueBoxCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    local data=  cmd.data
    res['do'] = 'Cmd.CastleUseBlueBoxCmd_S'
    if data~=nil then
        res['data'] = clubmgr.CastleUseBlueBoxCmd(data,uid)
    end
    return res
end
--领取最终大奖
Net.CmdCastleRecvFinalCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    local data=  cmd.data
    res['do'] = 'Cmd.CastleRecvFinalCmd_S'
    if true then
        res['data'] = clubmgr.CastleRecvFinalCmd(data,uid)
    end
    return res
end