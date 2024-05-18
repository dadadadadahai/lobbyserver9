--各自游戏跑马灯处理


--获取大厅存储的跑马灯数据
--[[
    uid
    gameId
    chip
    type
]]
Zone.CmdGetLampCmd_C=function (cmd,zonetask)
    local send={}
    send['do'] = 'Cmd.GetLampCmd_C'
    send['data'] = lampzone.GetLampCmd_C()
    unilight.success(zonetask, send)
end
--[[
    --子游戏服务上报产生跑马灯数据
    uid
    gameId
    chip
    type
]]
Zone.CmdReportLampCmd_C=function (cmd, zonetask)
    --print('CmdReportLampCmd_C=',json.encode(cmd.data))
    lampzone.ReportLampCmd_C(cmd.data)
    -- print('跑马灯数据中心服转发')
    -- unilight.info('跑马灯数据中心服转发')
    --将该条转发
    if cmd.data.gameId==109 then
        if math.random(100)<=90 then
            return
        end
    end
    RoomInfo.BroadcastToAllZone("Cmd.ReportLampCmd_S", cmd.data)
end