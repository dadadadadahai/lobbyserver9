module('EnterGameMgr', package.seeall)
-- 处理选场 进入游戏相关逻辑

-- 检测选场是否成功
function CheckEnterGame(uid, gameId, subGameId, roomType)
	local info = {}
	local find = false
	for i,v in ipairs(TableGameRoomConfig) do
		if v.gameId == gameId and v.subGameId == subGameId and v.roomType == roomType then
			info = v
			find = true
			break
		end
	end

	if find == false then
		return 1, "表格中 不存在该场次 gameId:" .. gameId .. "	subGameId:" .. subGameId .. "	roomType:" .. roomType 
	end

	local userInfo = chessuserinfodb.RUserInfoGet(uid)
	-- 检测底限
	if info.lowestCarry ~= 0 and userInfo.property.chips < info.lowestCarry then 
		return 2, "筹码不足 不能进入该游戏场次"
	end

	if info.highestCarry ~= 0 and userInfo.property.chips > info.highestCarry then
		return 3, "筹码过多 不能进入该游戏场次"
	end

	return 0, "进入该场次成功"
end

-- 获取该玩家 最合适的场次
function GetCorrectRoomType(uid, gameId)
	local userInfo = chessuserinfodb.RUserInfoGet(uid)
	local chips = userInfo.property.chips

	-- 总共有几个子游戏
	local maxSubGame = 0
	local subGameId = 0
	for i,v in ipairs(TableGameRoomConfig) do
		if v.gameId == gameId then
			maxSubGame = v.subGameId
		end
	end
	if maxSubGame ~= 0 then
		subGameId = math.random(1, maxSubGame)
	end

	local roomType = 0
	-- 遍历房间配置表 找到该游戏 及 指定子游戏id  中 最合适的场
	for i,v in ipairs(TableGameRoomConfig) do
		if v.gameId == gameId and v.subGameId == subGameId then
			if chips >= v.lowestCarry and (v.highestCarry == 0 or chips < v.highestCarry) then 
				roomType = v.roomType
			end
		end
	end

	return subGameId, roomType
end