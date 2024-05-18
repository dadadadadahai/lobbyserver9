--大厅处理来自游戏的消息

--测试消息
Zone.CmdZoneTest_S = function(cmd, zonetask) 
    unilight.info("大厅收到游戏服测试消息：" .. zonetask.GetGameId() .. ":" .. zonetask.GetZoneId())
    --回复
    --[[
    local req = {
        ["do"] = "Cmd.LobbyTest_S",
        ["data"] = {
            uid = 10000,
        },
    }
    unilight.success(zonetask, req)
    ]]
end 
