--请求等级模块基本信息
Net.CmdLevelRequestCmd_C = function(cmd,laccount)

    local res={}
    res["do"] = "Cmd.LevelRequestCmd_S"
    --调用处理方法
    res['data'] = levelmgr.CmdGetLevelInfo(laccount.Id)
   return res
end
--请求宝箱信息
Net.CmdGetBoxAwardCmd_C=function(cmd,laccount)
    local res={}
    res["do"] = "Cmd.GetBoxAwardCmd_S"
    res["data"]={}
    local uid=laccount.Id
    local resdata = levelmgr.GetBoxAwardCmd(uid)
    res["data"]=resdata
    return res
end
--请求领取宝箱信息
Net.CmdGetRecvBoxAwardCmd_C=function(cmd,laccount)
    local res={}
    res["do"] = "Cmd.GetRecvBoxAwardCmd_S"
    res["data"]={}
    local uid=laccount.Id
    local resdata = levelmgr.GetRecvBoxAwardCmd(cmd.data,uid)
    res["data"]=resdata
    return res
end
--初始化小游戏场景数据
Net.CmdInitSmallGameCmd_C=function(cmd,laccount)
    local res={}
    res["do"] = "Cmd.InitSmallGameCmd_S"
    res["data"]={}
    local uid=laccount.Id
    local resdata=levelmgr.InitSmallGameCmd(cmd.data,uid)
    res["data"]=resdata
    return res
end
--玩小游戏
Net.CmdPlayBoxGameCmd_C=function(cmd,laccount)
    local res={}
    res["do"] = "Cmd.PlayBoxGameCmd_S"
    res["data"]={}
    local uid=laccount.Id
    local resdata=levelmgr.PlayBoxGameCmd(cmd.data,uid)
    res["data"]=resdata
    return res
end
Net.CmdPlayBoxFinallyGameCmd_C=function(cmd,laccount)
    local res={}
    res["do"] = "Cmd.PlayBoxFinallyGameCmd_S"
    res["data"]={}
    local resdata={}
    local uid=laccount.Id
    local data=cmd.data
    if data~=nil then
        resdata=levelmgr.PlayBoxFinallyGameCmd(data,uid) 
    end
    res["data"]=resdata
    return res
end
Net.CmdSGameMainInfoCmd_C=function (cmd,laccount)
    local uid=laccount.Id
    local res={}
    res["do"] = "Cmd.SGameMainInfoCmd_S"
    res["data"]=levelmgr.SGameMainInfoCmd_C(cmd.data,uid)
    return res
end