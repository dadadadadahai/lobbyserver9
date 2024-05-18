module('KindQueen', package.seeall)
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
    local doInfo = 'Cmd.LongHuNewEnterCmd_S'
    local sdata = {
        uid = uid,
        headurl = Table.PlayMap[uid].headurl,
        gender = Table.PlayMap[uid].gender,
        nickname = Table.PlayMap[uid].nickname,
    }
    CmdMsgBrdExceptMe(doInfo, uid, sdata, Table.RoomId)
    MapUser[uid] = Table
    --print('board enter')
end

--机器人下注
function RobotBet(uid,betindex,area,Table)
    local betinfo = {area,betindex}
    --print('uid='..uid..',betindex='..betindex..',roomid='..Table.RoomId)
    local errno = Betting(Table.RoomId,betinfo,uid)
    -- print('bet errno='..errno.errno)
    return errno
end
--判断机器人是否应该离开
function IsRobotLeave(uid,Table)
    for _, value in ipairs(Table.leftSit) do
        if value.uid ==uid then
            return false
        end
    end
    for _, value in ipairs(Table.rightSit) do
        if value.uid==uid then
            return false
        end
    end
    return true
end
--机器人离开
function RobotLeavel(uid,Table)
    MapUser[uid]=nil
    local PlayMap = Table.PlayMap
    PlayMap[uid]=nil
    UserLeavel(uid,Table.RoomId)
end
