module('lampgame', package.seeall)
--[[
    timestamp
    uid
    gameId
    chip
    type
]]
--客户端
ZoneLampData = {} --跑马灯数据池
SysLampData = {} --系统公告跑马灯数据

ZoneLampLimit = 1000 --最大跑马灯数据池长度 1000
RobotList = {} --缓存的机器人列表 默认缓存20个
GameId = 0    
InitRobotNum = 15       --初始机器人
ReqRobotNum = 10        --每次申请机器人
local isRequest = false


function Init()
    -- gamecommon.RegGame(GameId, lampgame)
    -- 112 114 123
    -- gamecommon.ReqRobotList(GameId, InitRobotNum, 1)
    --请求中心服
    ChessToLobbyMgr.SendCmdToLobby("Cmd.GetLampCmd_C", nil)
end

function reqRebotList(gameId,gmMgr)
    GameId=gameId
    gamecommon.ReqRobotList(gameId, InitRobotNum, 1)
    gmMgr.RspRobotList = RspRobotList
end


--增加机器人爆池记录
function AddRobotJackpotHistory(params)
    -- print('AddRobotJackpotHistory befor')
    local robotinfo = RobotList[1]
    if robotinfo == nil then 
        --请求机器人
        gamecommon.ReqRobotList(GameId, InitRobotNum, 1)
        return
    end
    -- print('AddRobotJackpotHistory')
    gamecommon.AddRobotJackpotHistory(robotinfo,params)
    table.remove(RobotList, 1)
    local robotIds = {}
    robotIds[1] = robotinfo.uid
    gamecommon.ReqRobotRestore(GameId, robotIds)
    if #RobotList<ReqRobotNum and isRequest==false then
        gamecommon.ReqRobotList(GameId, ReqRobotNum, nil)
        isRequest=true
    end
end



--添加类型
--type=1
function AddTypeOneRobot(gameId, chip)
    -- local robotinfo = RobotList[1]
    -- if robotinfo == nil then return end
    -- AddLampData(robotinfo.uid,robotinfo.nickName, gameId, chip, 1)
    -- table.remove(RobotList, 1)
    -- --gamecommon.ReqRobotList(GameId, 1, nil)
    -- local robotIds = {}
    -- robotIds[1] = robotinfo.uid
    -- gamecommon.ReqRobotRestore(GameId, robotIds)
    -- if #RobotList<ReqRobotNum and isRequest==false then
    --     gamecommon.ReqRobotList(GameId, ReqRobotNum, nil)
    --     isRequest=true
    -- end
end

--type=2
function AddTypeTwoRobot(gameId, chip)
    -- local robotinfo = RobotList[1]
    -- if robotinfo == nil then return end
    -- AddLampData(robotinfo.uid,robotinfo.nickName, gameId, chip, 2)
    -- table.remove(RobotList, 1)
    -- --gamecommon.ReqRobotList(GameId, 1, nil)
    -- local robotIds = {}
    -- robotIds[1] = robotinfo.uid
    -- gamecommon.ReqRobotRestore(GameId, robotIds)
    -- if #RobotList<ReqRobotNum and isRequest==false then
    --     gamecommon.ReqRobotList(GameId, ReqRobotNum, nil)
    --     isRequest=true
    -- end
end

--type=3
function AddTypeThreeRobot(gameId, type, chip)
    -- local robotinfo = RobotList[1]
    -- if robotinfo == nil then return end
    -- AddLampData(robotinfo.uid,robotinfo.nickName,gameId, chip, type)
    -- table.remove(RobotList, 1)
    -- --gamecommon.ReqRobotList(GameId, 1, nil)
    -- local robotIds = {}
    -- robotIds[1] = robotinfo.uid
    -- gamecommon.ReqRobotRestore(GameId, robotIds)
    -- if #RobotList<ReqRobotNum and isRequest==false then
    --     gamecommon.ReqRobotList(GameId, ReqRobotNum, nil)
    --     isRequest=true
    -- end
end

function RspRobotList(data)
    -- print('RspRobotList')
    isRequest=false
    for _, value in ipairs(data.robotList) do
        table.insert(RobotList, value)
    end
end

function GetLampCmd_C(data)
    for _, value in ipairs(data) do
        table.insert(ZoneLampData, value)
    end
end

function AddLampData(uid,nickname,gameId, chip, type)
    if uid==nil or nickname==nil or chip==nil then
        return
    end
    -- if gameId==109 and type~=2 then
    --     print('gameId=109')
    -- end
    local sdata = { timestamp = os.time(), uid = uid, nickname = nickname, gameId = gameId, chip = chip, type = type }
    -- if #ZoneLampData>ZoneLampLimit then
    --     table.remove(ZoneLampData,1)
    -- end
    -- print('上报到中心服')
    -- unilight.info('上报到中心服')
    --上报到中心服
    -- ChessToLobbyMgr.SendCmdToLobby("Cmd.ReportLampCmd_C", sdata)
end

--中心服广播抵达的数据
function ZoneAddLamp(data)
    -- unilight.info('收到中心服广播,timestamp='..json.encode(data))
    table.insert(ZoneLampData, data)
    if #ZoneLampData > ZoneLampLimit then
        table.remove(ZoneLampData, 1)
    end
end
--客户端获取跑马灯
function GetLampClientCmd_C(uid, data)
    local timestamp = data.timeStamp
    local res = {
        errno = 0,
        array = {}
    }
    local num = 0
    timestamp = timestamp or 0
    --首先填充系统跑马灯
    for _, value in ipairs(SysLampData) do
        if value.timestamp >= timestamp and value.endTime > os.time() then
            table.insert(res.array, value)
            num = num + 1
        end
    end
    local maxtimestamp = 0
    for i = 1, #ZoneLampData do
        if ZoneLampData[i].timestamp >= timestamp then
            if ZoneLampData[i].timestamp>maxtimestamp then
                maxtimestamp = ZoneLampData[i].timestamp
            end
            table.insert(res.array, ZoneLampData[i])
            num = num + 1
            if num >= 20 then
                break
            end
        end
    end
    -- unilight.info(string.format('client request timestamp=%d,num=%d,maxtimestamp=%d',timestamp,num,maxtimestamp))
    -- unilight.info('客户端获取跑马灯,'..json.encode(res))
    return res
end

----------------------------------------------------------------------------------------------
function SysNewsCmd_C(data)
    local timestamp = os.time()
    table.insert(SysLampData, data.data)
    --清理一下过期跑马灯
    for i = #SysLampData, 1, -1 do
        if SysLampData[i].endTime <= timestamp then
            table.remove(SysLampData, i)
        end
    end
    local send={}
    send['do'] = 'Cmd.SysNewsCmd_S'
    send['data'] = data.data
    unilight.broadcast(send)
end
--删除跑马灯
function DelSysNewsCmd_S(data)
    local id = data.id
    for index, value in ipairs(SysLampData) do
        if value.id == id then
            table.remove(SysLampData,index)
            break
        end
    end
    local send={}
    send['do'] = 'Cmd.DelSysNewsCmd_S'
    send['data'] = {id = id}
    unilight.broadcast(send)
end
