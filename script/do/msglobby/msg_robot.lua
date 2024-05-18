--游戏处理来自大厅的消息

--测试消息
Lby.CmdGetRobotListSmd_S = function(cmd, lobbytask) 
    if cmd.data == nil or cmd.data.errno ~= 0 then
        unilight.error("大厅返回机器人列表失败, 原因:"..cmd.data.desc) 
        return
    end
    gamecommon.RspRobotList(cmd.data)
end
