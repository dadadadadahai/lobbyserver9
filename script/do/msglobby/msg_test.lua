--游戏处理来自大厅的消息

--测试消息
Lby.CmdLobbyTest_S = function(cmd, lobbytask) 
    unilight.info("游戏服收到来自大厅消息：" .. lobbytask.GetGameId() .. ":" .. lobbytask.GetZoneId())
    --向大厅发送消息
    local lobbytask = unilobby.getlobbytask()
    local req = {
        ["do"] = "Cmd.ZoneTest_S",
        ["data"] = {
            errno   = 0, 
            desc = "ok"
        }

    }
    
    unilight.success(lobbytask, req)
end