--请求创建团队命令
Net.CmdTeamCreateRequestCmd_C = function (cmd,laccount)
    local res={}
    res["do"]="Cmd.TeamCreateRequestCmd_S"
    --进入参数正确性判读
    if cmd.data==nil or cmd.data.icon==nil or cmd.data.name==nil or cmd.data.des==nil or cmd.data.type==nil or cmd.data.minVip==nil then
        res["data"]={
            status= 0,
            msg='参数错误(9)',
        }
        return res
    end
    --校验参数合法性
    local data=cmd.data
    if tonumber(data.icon) and tonumber(data.type) and tonumber(data.minVip) then
        --继续判断合理性
        if (data.type==0 or data.type==1) and data.minVip>=-1 then
            local uid = laccount.Id
            local resdata = teammgr.CmdTeamCreateRequestCmd(data,uid)
            res["data"]=resdata
            return res
        end
    end
    res["data"]={
        status= 0,
        msg='参数错误(26)',
    }
    return res
end
--查询团队信息
Net.CmdTeamQueryRequestCmd_C=function (cmd,laccount)
    local res={}
    res["do"]="Cmd.TeamQueryRequestCmd_S"
    if cmd.data==nil then
        res["data"]={
            status= 0,
            msg='参数错误(37)',
        }
        return res
    end
    local uid = laccount.Id
    local data=cmd.data
    local resdata={}
    if data.teamid~=nil then
        resdata = teammgr.CmdTeamQueryRequestCmdByID(data.teamid,uid)
        res["data"]=resdata
    elseif  data.teamName~=nil then
        resdata = teammgr.CmdTeamQueryRequestCmdByName(data.teamName,uid)
        res["data"]=resdata
    else
        res["data"]={
            status= 0,
            msg='参数错误(53)',
        }
    end
    return res
end
--请求加入团队
Net.CmdTeamJoinRequestCmd_C=function (cmd,laccount)
    local res={}
    res["do"]="Cmd.TeamJoinRequestCmd_S"
    if cmd.data==nil or cmd.data.teamid==nil then
        res["data"]={
            status= 0,
            msg='参数错误(37)',
        }
        return res
    end
    if tonumber(cmd.data.teamid) then
        local data = cmd.data
        local uid = laccount.Id
        local resdata = teammgr.CmdTeamJoinRequestCmd(data.teamid,uid)
        res["data"]=resdata
        return res
    end
    res["data"]={
        status= 0,
        msg='参数错误(43)',
    }
    return res
end
--退出团队
Net.CmdTeamQuitCmd_C=function (cmd,laccount)
    local res={}
    res["do"]="Cmd.TeamQuitCmd_S"
    local uid = laccount.Id
    local resdata= teammgr.CmdTeamQuitCmd(uid)
    res["data"] = resdata
    return res
end
--踢出团队
Net.CmdTeamKickoutCmd_C = function (cmd,laccount)
    local res={}
    res["do"]="Cmd.TeamKickoutCmd_S"
    local uid = laccount.Id
    if cmd.data==nil or cmd.data._id==nil then
        res['data']={
            status= 0,
            msg='参数错误(98)',
        }
        return res
    end
    local _id = cmd.data._id
    local resdata = teammgr.CmdTeamKickoutCmd(_id,uid)
    res['data']=resdata
    return res
end
--查询审核列表
Net.CmdTeamQueryWaitForJoinCmd_C = function (cmd,laccount)
    local res={}
    res["do"]="Cmd.TeamQueryWaitForJoinCmd_S"
    local uid = laccount.Id
    local resdata = teammgr.TeamQueryWaitForJoinCmd(uid)
    res['data'] = resdata
    return res
end

Net.CmdTeamAllowJoinCmd_C =function (cmd,laccount)
    local res={}
    res["do"]="Cmd.TeamAllowJoinCmd_S"
    local uid = laccount.Id
    if cmd.data==nil or cmd.data._id==nil or cmd.data.ctr==nil then
        res['data']={
            status= 0,
            msg='参数错误(125)',
        }
        return res
    end
    if tonumber(cmd.data._id) and tonumber(cmd.data.ctr) then
        if cmd.data.ctr==1 or cmd.data.ctr==2 then
            local resdata=teammgr.TeamAllowJoinCmd(cmd.data._id,cmd.data.ctr,uid)
            res['data']=resdata
            return res
        end
    end
    res['data']={
        status= 0,
        msg='参数错误(136)',
    }
    return res
end
--查看团队成员命令
Net.CmdTeamQueryMemCmd_C=function (cmd,laccount)
    local res={}
    res["do"]="Cmd.TeamQueryMemCmd_S"
    local uid = laccount.Id
    local resdata=teammgr.TeamQueryMemCmd(uid)
    res['data']=resdata
    return res
end
--编辑团队信息
Net.CmdTeamEditInfoCmd_C=function (cmd,laccount)
    local res={}
    res["do"]="Cmd.TeamEditInfoCmd_S"
    local uid = laccount.Id
    local data=cmd.data
    local resdata=teammgr.TeamEditInfoCmd(data,uid)
    res['data']=resdata
    return res
end
--发送团队群聊消息
Net.CmdGroupChatCmd_C=function (cmd,laccount)
    local res={}
    res["do"]="Cmd.GroupChatCmd_S"
    local uid = laccount.Id
    local data=cmd.data

    if data~=nil then
        res["data"]=teammgr.GroupChatCmd(cmd.data,uid)
    else
        res["data"]={
            status=0,
            msg='参数不完整'
        }
    end
    return res
end
--获取团队消息 20条
Net.CmdGetChartCmd_C=function (cmd,laccount)
    local res={}
    res["do"]="Cmd.GetChartCmd_S"
    local uid = laccount.Id
    local data=cmd.data
    if data~=nil then
        res["data"]=teammgr.GetChartCmd(cmd.data,uid)
    else
        res["data"]={
            status=0,
            msg='参数不完整'
        }
    end
    return res
end
--赠送礼物处理
Net.CmdGiveCollectionCmd_C=function (cmd,laccount)
    local res={}
    res["do"]="Cmd.GiveCollectionCmd_S"
    local uid = laccount.Id
    local data=cmd.data
    if data~=nil then
        res["data"]=teammgr.GiveCollectionCmd(cmd.data,uid)
    else
        res["data"]={
            status=0,
            msg='参数不完整'
        }
    end
    return res
end
--获取返回10个随机团队信息
Net.CmdRandomTeamCmd_C=function (cmd,laccount)
    local res={}
    local uid = laccount.Id
    res["do"]="Cmd.RandomTeamCmd_S"
    res["data"] = teammgr.RandomTeamCmd(uid)
    return res
end
--邀请玩家加入团队
Net.CmdInviteCmd_C=function (cmd,laccount)
    local res={}
    local uid=laccount.Id
    local data = cmd.data
    res["do"] ="Cmd.InviteCmd_S"
    res['data']={}
    if data~=nil then
        res['data'] = teammgr.InviteCmd(data,uid)
    end
    return res
end
--获取邀请我的团队列表
Net.CmdGetInviteListsCmd_C=function (cmd,laccount)
    local res={}
    local uid=laccount.Id
    local data=cmd.data
    local curpage = data.curpage or 1
    res["do"] ="Cmd.GetInviteListsCmd_S"
    res['data']=teammgr.GetInviteListsCmd(curpage,uid)
    return res
end
--同意经过邀请加入团队
Net.CmdJoinTeamByInviteCmd_C=function (cmd,laccount)
    local res={}
    local uid=laccount.Id
    local data = cmd.data
    res["do"] ="Cmd.JoinTeamByInviteCmd_S"
    res['data']={}
    if data~=nil then
        res['data'] = teammgr.JoinTeamByInviteCmd(data,uid)
    end
    return res
end
--查询个人团队信息
Net.CmdGetPersonalTeamInfoCmd_C=function (cmd,laccount)
    local res={}
    local uid = laccount.Id
    res['do'] = 'Cmd.GetPersonalTeamInfoCmd_S'
    res['data'] = teammgr.GetPersonalTeamInfoCmd(uid)
    return res
end
--领取团队互助金
Net.CmdTeamRecvGiftRecvCmd_C=function (cmd,laccount)
    local res={}
    local uid = laccount.Id
    local data=cmd.data
    res['do'] = 'Cmd.TeamRecvGiftRecvCmd_S'
    res['data'] = teammgr.CmdTeamRecvGiftRecvCmd_C(data,uid)
    return res
end
Net.CmdTeamQueryRankDetailCmd_C=function (cmd,laccount)
    local res={}
    local uid = laccount.Id
    local data=cmd.data
    res['do'] = 'Cmd.TeamQueryRankDetailCmd_S'
    res['data'] = teammgr.TeamQueryRankDetailCmd_S(data,uid)
    return res
end
Net.CmdTeamQAndGBxCmd_C=function (cmd,laccount)
    local res={}
    local uid = laccount.Id
    local data=cmd.data
    res['do'] = 'Cmd.TeamQAndGBxCmd_S'
    res['data'] = teammgr.TeamQAndGBxCmd_S(data,uid)
    return res
end
Net.CmdTeamTaskGetCmd_C=function (cmd,laccount)
    local res={}
    local uid = laccount.Id
    local data=cmd.data
    res['do'] = 'Cmd.TeamTaskGetCmd_S'
    res['data'] = teammgr.TeamTaskGetCmd_S(data,uid)
    return res
end