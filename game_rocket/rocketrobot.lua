module('rocket', package.seeall)
--机器人进入
function RobotEnter(rebots, Table)
    local uid = rebots.uid
    local bets = { 0, 0, 0, 0, 0, 0, 0, 0 }
    if Table.PlayMap[uid] ~= nil then
        Table.PlayMap[uid].isDrop = false
        bets = Table.PlayMap[uid].bets
    else
        Table.PlayMap[uid] = {
            bets = bets,
            IsRobot = true,
            headurl = rebots.frameId,
            gender = rebots.gender,
            nickname = rebots.nickName,
            isDrop = false,
        }
    end 
    --广播玩家进入消息
    local doInfo = 'Cmd.RocketNewEnterCmd_S'
    local sdata = {
        uid = uid,
        headurl = Table.PlayMap[uid].headurl,
        gender = Table.PlayMap[uid].gender,
        nickname = Table.PlayMap[uid].nickname,
    }
    CmdMsgBrdExceptMe(doInfo, uid, sdata, Table.RoomId)
    MapUser[uid] = Table
end

--机器人下注
function RobotBet(uid,betindex,area,Table)
    --local betinfo = {area,betindex}
    --print('uid='..uid..',betindex='..betindex..',roomid='..Table.RoomId)
    local gold = Table.robot:GetGold(uid)
    local betRatio = table_202ad_bili[gamecommon.CommRandInt(table_202ad_bili,'gailv')].betRatio
    local chip = math.floor(gold*betRatio/100)
    if chip<table_202_sessions[Table.RoomId].minBet then
        chip = table_202_sessions[Table.RoomId].minBet
    end
    chip = math.floor(chip/100)
    chip = chip*100
    local errno = Betting(Table.RoomId,chip,uid)
    return errno
end
--机器人初始化点击时间
function RobotClientTime(robot)
    for _, value in ipairs(robot.robot) do
        local table_202ad_ctrcfg = table_202ad_ctr[gamecommon.CommRandInt(table_202ad_ctr,'gailv')]
        local ctrTime = math.random(table_202ad_ctrcfg.low,table_202ad_ctrcfg.up)
        --print("ctrTime="..ctrTime)
        value.ctrTime = ctrTime
    end
end
function RobotClick(timeNow,Table)
    local passMin = timeNow - Table.TableStatus.sTime
    for _, value in ipairs(Table.robot.robot) do
        if value.ctrTime~=nil then
            if passMin>=value.ctrTime and value.ctrTime>0 then
                --print('passMin='..passMin..',value.ctrTime='..value.ctrTime)
                --执行点击
                ClickSettle(Table.RoomId,value.uid)
                value.ctrTime=nil
                break
            end
        end
    end
end
--判断机器人是否应该离开
function IsRobotLeave(uid,Table)
    return true
end
--机器人离开
function RobotLeavel(uid,Table)
    MapUser[uid]=nil
    local PlayMap = Table.PlayMap
    PlayMap[uid]=nil
    UserLeavel(uid,Table.RoomId)
end
