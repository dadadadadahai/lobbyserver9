module('racelamp', package.seeall)
--大厅跑马灯
--[[
    大厅
]]
table_jackpot_data = import 'table/table_jackpot_data'
SysLampData = {} --系统公告跑马灯数据
LimitNum = 300 --总记录
HallLampPools = {} --跑马灯池{timeStamp,uid,chip},大厅

--初始化模块
function Init()
    for i = 1, LimitNum do
        local datacfg = table_jackpot_data[gamecommon.CommRandInt(table_jackpot_data, 'gailv')]
        local randomchip = math.random(datacfg.low, datacfg.up)
        local ret, robotinfo = RobotDispatchMgr.GetRobotListByType(1, 1)
        if ret then 
            --print(json.encode(robotinfo))
            local uid = robotinfo.data.robotList[1].uid
            local nickname = robotinfo.data.robotList[1].nickName
            local uids = {}
            table.insert(uids, uid)
            RobotDispatchMgr.ReqRestoreRobot(1, uids)
            table.insert(HallLampPools, { os.time() + i, uid,nickname, randomchip })
        end
    end

end

--产生新的跑马灯条数
function timer()
    local datacfg = table_jackpot_data[gamecommon.CommRandInt(table_jackpot_data, 'gailv')]
    local randomchip = math.random(datacfg.low, datacfg.up)
    local ret, robotinfo = RobotDispatchMgr.GetRobotListByType(1, 1, 100000)
    if ret then 
        local uid = robotinfo.data.robotList[1].uid
        local nickname = robotinfo.data.robotList[1].nickName
        local uids = {}
        table.insert(uids, uid)
        RobotDispatchMgr.ReqRestoreRobot(1, uids)
        table.insert(HallLampPools, { os.time(), uid, nickname, randomchip })
        table.remove(HallLampPools, 1)
    end
end

function GetLampCmd_C(data)
    local timeStamp = data.timeStamp or 0
    local num = 0
    local lamps = {
        array = {}
    }
    --首先填充系统跑马灯
    for _, value in ipairs(SysLampData) do
        if value.timestamp >= timeStamp and value.endTime > os.time() then
            table.insert(lamps.array, value)
            num = num + 1
        end
    end
    for i = 1, LimitNum do
        if HallLampPools[i][1] >= timeStamp then
            table.insert(lamps.array, { timeStamp = HallLampPools[i][1], nickname = HallLampPools[i][3],
                chip = HallLampPools[i][4] })
            num = num + 1
        end
        if num >= 50 then
            break
        end
    end
    return lamps
end

--[[
content  内容
endTime  到期时间
大厅
]]
function AddSysLamp(id,content, endTime)
    local timestamp = os.time()
    local sysdata={ timestamp = timestamp,id=id,uid = 0, type = 100, endTime = endTime, content = content }
    table.insert(SysLampData, sysdata)
    --清理一下过期跑马灯
    for i = #SysLampData, 1, -1 do
        if SysLampData[i].endTime <= timestamp then
            table.remove(SysLampData, i)
        end
    end
    --广播到游戏服
    --将该条转发
    local send={}
    send['do'] = 'Cmd.SysNewsCmd_S'
    send['data'] = sysdata
    RoomInfo.BroadcastToAllZone('Cmd.SysNewsCmd_S', sysdata)
    unilight.broadcast(send)
end
function DelSysLamp(taskId)
    for index, value in ipairs(SysLampData) do
        if value.id == taskId then
            table.remove(SysLampData,index)
            break
        end
    end
    --广播删除
    local send={}
    send['do'] = 'Cmd.DelSysNewsCmd_S'
    send['data'] = {id = taskId}
    RoomInfo.BroadcastToAllZone('Cmd.DelSysNewsCmd_S', {id = taskId})
    unilight.broadcast(send)
end
