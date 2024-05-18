module('chessprofitbonus', package.seeall) 
-- 玩家彩金相关数据
TABLE_NAME = "userprofitbonus"
sequence = 1
-- 记得一个玩家一次彩金收益 
function CmdRecordOneUserProfitBonus(uid, gameId, roomId, betChips, profitChips)
	local time = os.time()
    local sequence = sequence + 1 
	local _id = string.format("%08d", sequence) .. time 
	local record = {
        _id = _id,
        timestamp = time,
        date = chessutil.FormatDateGet(),
        uid = uid,
        gameId = gameId,
        betChips = betChips,
        profitChips = profitChips,
        roomId = roomId,
    }
	unilight.savedata(TABLE_NAME, record)
end

-- 公共调用,获取某个游戏,某个房间前多少名的排行数据
function CmdGetTopNumRecord(gameId, roomId, topNum)
    local orderby = unilight.desc("profitChips")
    local filterGameId = unilight.eq("gameId", gameId)
    local filterRoomId = unilight.eq("roomId", roomId)
    local filter = unilight.a(filterGameId, filterRoomId)
    local userGroup = unilight.topdata(TABLE_NAME, topNum, orderby, filter)
    return ReturnBonusRecord(userGroup)
end

-- 公共调用,获取某个游戏,某个房间最近多少名的最近数据
function CmdGetRecentNumRecord(gameId, roomId, num)
    local orderby = unilight.desc("timestamp")
    local filterGameId = unilight.eq("gameId", gameId)
    local filterRoomId = unilight.eq("roomId", roomId)
    local filter = unilight.a(filterGameId, filterRoomId)
    local userGroup = unilight.topdata(TABLE_NAME, num, orderby, filter)
    return ReturnBonusRecord(userGroup)
end

function ReturnBonusRecord(userGroup)
    local userBonus = {}
    for i, user in ipairs(userGroup) do
        local userInfo = chessuserinfodb.RUserInfoGet(user.uid)
        local userBonusItem = {
            rankIndex = i,
            uid = user.uid,
            bonusChips = user.profitChips,
            date = user.date,
            nickName = userInfo.base.nickname,
            headUrl = userInfo.base.headurl,
        } 
        table.insert(userBonus, userBonusItem)
    end
    return userBonus
end
