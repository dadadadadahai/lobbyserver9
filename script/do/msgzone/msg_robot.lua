--大厅处理来自游戏的消息

--游戏请求机器人列表
Zone.CmdGetRobotListSmd_C = function(cmd, zonetask) 
    if cmd.data == nil or cmd.data.robotType == nil then
        local send = {}
        send["do"] = "Cmd.GetRobotListSmd_S"
        send.data = {
            errno = ErrorDefine.ERROR_PARAM,
            desc  = "参数错误"
        }
        unilight.sucess(zonetask, send)
        return
    end
    local ret, send = RobotDispatchMgr.GetRobotListByType(cmd.data.robotType, cmd.data.robotNum, zonetask.GetZoneId())
    -- if cmd.data.gameId==123 then
    --     print('ret',ret)
    -- end
    if ret  then
        --原参数返回
        send.data.params = cmd.data.params
        send.data.gameId = cmd.data.gameId
        unilight.success(zonetask, send)
    end
end
--游戏请求还回机器人
Zone.CmdRestoreRobotSmd_C = function(cmd, zonetask)
    RobotDispatchMgr.ReqRestoreRobot(cmd.data.robotType, cmd.data.robotIds)
end
