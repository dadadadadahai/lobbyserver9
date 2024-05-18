--游戏处理大厅子游戏游戏相关协议

--游戏处理大厅发来的历史记录消息
Lby.CmdReqHistoryInfoGame_CS = function(cmd, lobbytask) 
    -- print("游戏11111111111111111="..table2json(cmd.data))
    local gameId = cmd.data.gameId
    local gameType = cmd.data.gameType

    local msg = {}
    msg["do"] = "Cmd.AddJackpotInfoGame_S"
    msg.data = cmd.data.jackpotInfo

    gamecommon.SendMsgToGameType(gameId, gameType, msg)

    gamecommon.SendPoolDataToGameType(gameId, gameType)
end 


--检测玩家是否在线，如果在线则通知客户端下线
Lby.CmdKickUserGame_S = function(cmd, lobbytask)
    local uid = cmd.data.uid
    local laccount = go.roomusermgr.GetRoomUserById(uid)
    if laccount ~= nil then
        cmd["do"] = "Cmd.KickUserGame_S"
        unilight.sendcmd(uid, cmd)
    end
end

--转发排行榜信息给客户端
Lby.CmdGetListRankCmd_S = function(cmd, lobbytask)
    local uid = cmd.data.uid
    unilight.sendcmd(uid, cmd)
end



