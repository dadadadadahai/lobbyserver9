
--游戏上传游戏玩家在线信息
Zone.CmdReqZoneOnlineListLobby_CS = function(cmd, zonetask)
    annagent.SetZoneInfoList(zonetask.GetGameId(), zonetask.GetZoneId(), cmd.data.uids)
    annagent.SetZoneGameTypeOnline(zonetask.GetGameId(), zonetask.GetZoneId(), cmd.data.gameOnlineNum)

end 
