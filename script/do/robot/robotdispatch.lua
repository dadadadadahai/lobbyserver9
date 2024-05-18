------------------------------------------------------------
--desc: 机器要派发、回收， 主要是保证同一个游戏机器人不重复
------------------------------------------------------------
module('RobotDispatchMgr', package.seeall)


table_robot_config = import "table/table_robot_config"

robotUseList    = {}            --机器人已使用列表
robotUnusedList = {}            --机器人未使用列表
local unusedNum= 0          --实际机器人数量
last_req_time = {}           --上次请求的时间

--按商品类型初始化表
function InitConfig()
    robotUseList = {}
    robotUnusedList = {}
    for _, robotConfig in pairs(table_robot_config) do
        local uid         = robotConfig.uid
        local robotType   = robotConfig.robotType
        if robotUnusedList[robotType] == nil then
            robotUnusedList[robotType] = {}
        end
        unusedNum=unusedNum+1
        table.insert(robotUnusedList[robotType], robotConfig)
        -- robotUnusedList[robotType][uid] = robotConfig

        -- unilight.info("加载机器人配置, 类型:"..robotType..", 数量:"..table.len(robotUnusedList[robotType]))
    end
end


--根据类型、数量获得机器人配置
function GetRobotListByType(robotType, robotNum, zoneId)
    --[[
    if zoneId ~= nil then
        local curmSec = os.msectime()
        if last_req_time[zoneId] == nil then
            last_req_time[zoneId] = curmSec
        else

            if curmSec - last_req_time[zoneId] <= 200 then
                -- print("1111111111="..curmSec - last_req_time[zoneId]..", zoneid="..zoneId)
                return false ,nil
            end
            last_req_time[zoneId] = curmSec
        end
    end
    ]]
    local send = {}
    send["do"] = "Cmd.GetRobotListSmd_S"
    send.data = {}
    local retRobotList = {}
    local robotList    = robotUnusedList[robotType]
    -- local unusedNum    = table.getn(robotList)
    if unusedNum < robotNum then
        send.data.errno = 1
        send.data.desc  = "机器人可用数据不足, 可用机器人:"..unusedNum.." ,请求数量:"..robotNum
        unilight.error(send.data.desc)
        send.data.robotList = {}
        return false, nil 
    end

    while robotNum > 0 do
        local randomId = math.random(1, unusedNum)
        robotNum       = robotNum - 1            --需求的机器人数量减1
        unusedNum      = unusedNum - 1           --可用数量也要减1
        local robotConfig = robotList[randomId]
        retRobotList[#retRobotList+1] = robotConfig
        -- table.insert(retRobotList, robotConfig)
        robotUseList[robotConfig.uid] = robotConfig
        table.remove(robotList, randomId)
    end
    unusedNum = unusedNum - robotNum
    send.data.errno = 0
    send.data.desc  = "获得成功"
    send.data.robotList = retRobotList
    -- unilight.info(string.format("机器人类型:(%d)剩余数量:(%d)", robotType, table.getn(robotList)))

    return true, send
end


--归还机器人
function ReqRestoreRobot(robotType, robotIds)
    local robotList    = robotUnusedList[robotType]
    for k, uid in ipairs(robotIds) do
        local robotConfig = robotUseList[uid]
        if robotConfig ~= nil then
            unusedNum = unusedNum + 1
            -- table.insert(robotList, robotConfig)
            robotList[#robotList + 1] = robotConfig
        end
        robotUseList[k] = nil
    end

    -- unilight.info(string.format("归还机器人, 类型:%d, 可用机器人数量:%d, 归还机器人列表:%s", robotType, table.getn(robotList), table2json(robotIds)))
end


--加载时初始化下数据
InitConfig()

