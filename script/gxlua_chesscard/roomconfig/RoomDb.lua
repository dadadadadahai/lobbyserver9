module('RoomDb', package.seeall)

-- 用来记录房间库存数据库初始化
function CmdRoomDbInit(gameId) 
	local DB_TABLE = tostring(gameId) .. "roominfo"
	unilight.createdb(DB_TABLE, "id")
	local subGameConfig = chessroomconfig.CmdSubGameConfigGetByGameId(gameId)
	for i, subGame in ipairs(subGameConfig) do
		local subGameId = subGame.subGameId
		local roomInfoCfg = chessroomconfig.CmdSubGameRoomConfigGetByGameIdSubGameId(gameId, subGameId)
		for i, roomInfo in ipairs(roomInfoCfg) do
			local key = CmdRoomKeyGetBySubGameIdRoomType(subGameId, roomInfo.roomType) 
			local roomData = unilight.getdata(DB_TABLE, key)
			if roomData == nil then
				roomData = {
					id = key,
					roomstock = 0,
					roomprofit = 0,
				}
				unilight.savedata(DB_TABLE, roomData)
			end
		end
	end
end

function CmdRoomStackGetByGameIdsubGameIdRoomType(gameId, subGameId, roomType)
	local DB_TABLE = tostring(gameId) .. "roominfo"
	local key = RoomKeyGetBySubGameIdRoomType(subGameId, roomType) 
	return unilight.getdata(DB_TABLE, key)
end

function CmdRoomStackGetByGameIdKey(gameId, key)
	local DB_TABLE = tostring(gameId) .. "roominfo"
	return unilight.getdata(DB_TABLE, key)
end

function CmdRoomStackSaveByGameIdRoomData(gameId, roomData)
	local DB_TABLE = tostring(gameId) .. "roominfo"
	unilight.savedata(DB_TABLE, roomData)
end

function CmdRoomKeyGetBySubGameIdRoomType(subGameId, roomType)
	local strSubGame = string.format("%04d", tonumber(subGameId)) 
	local strRoomType = string.format("%04d", tonumber(roomType)) 
	return strSubGame .. strRoomType
end
