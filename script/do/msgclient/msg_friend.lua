--获取推荐好友列表
Net.CmdFriendRecommendCmd_C=function (cmd,laccount)
    local res={}
    res["do"]="Cmd.FriendRecommendCmd_S"
    res["data"]={}
    local uid=laccount.Id
    local resdata=friendmgr.FriendRecommendCmd(uid)
    res["data"]=resdata
    return res
end
--获取本人好友名单
Net.CmdGetSelfFriendListCmd_C=function (cmd,laccount)
    local res={}
    res["do"]="Cmd.GetSelfFriendListCmd_S"
    res["data"]={}
    local uid=laccount.Id
    if cmd.data~=nil then
        local resdata=friendmgr.GetSelfFriendListCmd(cmd.data,uid)
        res["data"]=resdata
    end
    return res
end
--获取申请好友列表
Net.CmdGetSelfFriendApplyCmd_C=function (cmd,laccount)
    local res={}
    res["do"]="Cmd.GetSelfFriendApplyCmd_S"
    res["data"]={}
    local uid=laccount.Id
    if cmd.data~=nil then
        local resdata=friendmgr.GetSelfFriendApplyCmd(cmd.data,uid)
        res["data"]=resdata
    end
    return res
end

--定向搜索好友
Net.CmdSearchFriendCmd_C=function (cmd,laccount)
    local res={}
    res["do"]="Cmd.SearchFriendCmd_S"
    res["data"]={}
    if cmd.data~=nil or cmd.data._id ~=nil then
        local resdata=friendmgr.SearchFriendCmd(cmd.data._id)
        res["data"]=resdata
    end
    return res
end
--提交好友申请
Net.CmdApplyFriendCmd_C=function (cmd,laccount)
    local res={}
    res["do"]="Cmd.ApplyFriendCmd_S"
    res["data"]={}
    local uid=laccount.Id
    local data=cmd.data
    if data~=nil and data._id ~=nil then
        local resdata=friendmgr.ApplyFriendCmd(data._id,uid)
        res["data"]=resdata
        return res
    end
    res["data"]={
        error=0,
        msg='参数错误(34)',
    }
    return res
end
--批准好友申请
Net.CmdSureFriendCmd_C=function (cmd,laccount)
    local res={}
    res["do"]="Cmd.SureFriendCmd_S"
    res["data"]={}
    local uid=laccount.Id
    local data= cmd.data
    if data~=nil and data._id ~=nil and data.ctr~=nil then
        local resdata=friendmgr.SureFriendCmd(data._id,data.ctr,uid)
        res["data"]=resdata
        return res
    end
    res["data"]={
        error=0,
        msg='参数错误(34)',
    }
    return res
end
--删除好友
Net.CmdDelFriendCmd_C=function (cmd,laccount)
    local res={}
    res["do"]="Cmd.DelFriendCmd_S"
    res["data"]={}
    local data = cmd.data
    local uid = laccount.Id
    if data~=nil or data._id ~=nil then
        local resdata=friendmgr.DelFriendCmd(data._id,uid)
        res["data"]=resdata
        return res
    end
    res["data"]={
        error=0,
        msg='参数错误(34)',
    }
    return res
end
--私聊消息
Net.CmdSendMessageCmd_C=function (cmd,laccount)
    local res={}
    res["do"]="Cmd.SendMessageCmd_S"
    res["data"]={}
    local data=cmd.data
    local uid=laccount.Id
    if data~=nil and data._id~=nil and data.msg~=nil then
        local resdata=friendmgr.SendMessageCmd(data._id,data.msg,uid)
        res["data"]=resdata
        return res
    end
    res["data"]={
        error=0,
        msg='参数错误'
    }
    return res
end
--获取离线消息概要
Net.CmdGetMessageAbsCmd_C=function (cmd,laccount)
    local res={}
    res["do"]="Cmd.GetMessageAbsCmd_S"
    res["data"]={}
    local uid=laccount.Id
    local resdata=friendmgr.GetMessageAbsCmd(uid)
    res["data"]=resdata
    return res
end
--获取离线消息
Net.CmdGetOfflineMsgCmd_C=function (cmd,laccount)
    local res={}
    res["do"]="Cmd.GetOfflineMsgCmd_S"
    res["data"]={}
    local uid=laccount.Id
    if cmd.data~=nil and cmd.data._id~=nil then
        local resdata=friendmgr.GetOfflineMsgCmd(cmd.data._id,uid)
        res["data"]=resdata
    end
    return res
end
--赠送好友礼物
Net.CmdGiveGiftCmd_C=function (cmd,laccount)
    local res={}
    res["do"]="Cmd.GiveGiftCmd_S"
    res["data"]={}
    local uid = laccount.Id
    if cmd.data~=nil then
        res["data"] = friendmgr.GiveGiftCmd(cmd.data,uid)
    end
    return res
end