module('chessroomconfig', package.seeall)

table_game_list = import "table/table_game_list"
-- 返回某个游戏的所有子游戏相关配置
function CmdSubGameConfigGetByGameId(gameId)
	local subGameInfo = {}

	for i, v in pairs(table_game_list) do
		if v.gameId == gameId then
			subGameInfo[v.subGameId] = v.subGameName
		end
	end
	local subGameConfig = {}
	for i, v in pairs(subGameInfo) do
		table.insert(subGameConfig, {subGameId = i, subGameName = v})
	end
	return subGameConfig
end

-- 通过子游戏id 获取对应子游戏里所有房间配置
function CmdSubGameRoomConfigGetByGameIdSubGameId(gameId, subGameId)
	local roomInfo = {}
	for i, v in pairs(table_game_list) do
		if v.gameId == gameId and v.subGameId == subGameId then
			table.insert(roomInfo, v)
		end
	end
	return roomInfo
end

-- 通过子游戏id, 子游戏的roomId 获取对应场景详细配置
function CmdSubGameRoomInfoGetByGameIdSubgameIdRoomType(gameId, subGameId, roomType)
	for i, v in pairs(table_game_list) do
		if v.gameId == gameId and v.subGameId == subGameId and v.roomType == roomType then
			return v	
		end
	end
end

-- 获得本游戏所有配置信息
function CmdSubGameInfoGetByGameId(gameId)
	local subGameInfo = {}
	for i, v in pairs(table_game_list) do
		if v.gameId == gameId then
			table.insert(subGameInfo, v)
		end
	end
	return subGameInfo
end

-- 随机产生一份符合金钱条件的房间配置
function CmdRandRoomCfgInfoGetByGameIdRoomTypeUserRemainder(gameId, subGameId, remainder)
	local set = {}
	for i, v in pairs(table_game_list) do
		if v.gameId == gameId and (subGameId <= 0 or v.subGameId == subGameId) and remainder >= v.lowestCarry and (v.highestCarry == 0 or remainder <= v.highestCarry) then
			table.insert(set, v)
		end
	end
	local len = table.len(set)
	if len <= 0 then
		return nil
	end
	return set[math.random(1, len)]
end

function CmdRandRoomCfgInfoGetByGameIdSubGameIdRoomTypeRemainder(gameId, subGameId, remainder, roomType)
	local set = {}
	-- 积分场
	if roomType == 1 then
		for i, v in pairs(table_game_list) do
			if v.gameId == gameId and (subGameId <= 0 or v.subGameId == subGameId) and roomType == v.roomType then
				table.insert(set, v)
			end
		end
	end
	-- 金币场
	if roomType == 2 then
		for i, v in pairs(table_game_list) do
			if v.gameId == gameId and (subGameId <= 0 or v.subGameId == subGameId) and (v.highestCarry == 0 or remainder <= v.highestCarry) and roomType == v.roomType then
				table.insert(set, v)
			end
		end
	end
	local len = table.len(set)
	if len <= 0 then
		return nil
	end
	return set[math.random(1, len)]
end
