
--中心服收到消息处理
--同步实时消息通讯消息注册
Zone.CmdUserLoginInCmd_C = function(cmd,zonetask)
    --玩家进入
    -- print('rev enter',cmd.data.uid,zonetask.GetZoneId())
    local zoneId = zonetask.GetZoneId()
    local zone =  ZoneInfo.zoneIdInfoMap[zoneId]
    backRealtime.lobbyOnlineUserManageMap[cmd.data.uid] = {zone=zone,enterchip=cmd.data.chip,rInfo ={}}
    --更新redis状态
    
end

Zone.CmdUserLoginOutCmd_C=function(cmd,zonetask)
    --玩家离开
    -- print('rev leael',cmd.data.uid,zonetask.GetZoneId())
    local zoneId = zonetask.GetZoneId()
    local zone =  ZoneInfo.zoneIdInfoMap[zoneId]
    backRealtime.lobbyOnlineUserManageMap[cmd.data.uid] = nil
end


--大厅更新消息
Zone.CmdGameDataToLobbyCmd_C=function(cmd,zonetask)
    local data =cmd.data.data
    for _,onLineInfo in ipairs(data) do
        local uid = onLineInfo.uid
        if backRealtime.lobbyOnlineUserManageMap[uid]~=nil then
            backRealtime.lobbyOnlineUserManageMap[uid].rInfo = onLineInfo
        end
    end
end