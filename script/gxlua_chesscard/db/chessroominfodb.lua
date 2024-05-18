module('chessroominfodb', package.seeall) 

--[[
	创建游戏房间信息，没有就创建，有就直接返回房间信息 
	存档的房间数据 仅为 基础数据 
	斗牛等以一个类型的房间 作为 一个统一的房间数据存储
	gameId 统一数字
]]

function InitRoomInfoDb(gameId)
	if gameId == nil then
		return 
	end
	local dbName = tostring(gameId) .. "roominfo"	
	unilight.createdb(dbName, "roomId")
end

function CreateRoomInfo(gameId, roomId, profitPercent, roomName, stockThreshold, stock, stockBoss, bonusPercent, pumpPercent)
	stock 			= stock 			or 6000000		-- 默认	库存初始值 		600w 
	stockThreshold 	= stockThreshold 	or 6000000		-- 默认 阈值初始值		600w
	stockBoss 		= stockBoss 		or 6000000		-- 默认 boss库存初始值	600w （用于飞禽走兽）
	profitPercent  	= profitPercent  	or 0.05			-- 默认	纯利 抽玩家输的 百分之五
	bonusPercent	= bonusPercent 		or 0.05			-- 默认 彩金 抽玩家输的 百分之五
	pumpPercent		= pumpPercent 		or 0.005		-- 默认 抽水 抽玩家赢的 千分之五

	-- 可以重复调用，没有的就创建，有的话就可以更新
	local dbName = tostring(gameId) .. "roominfo"	
	local roomInfo = unilight.getdata(dbName, roomId)
	roomInfo = roomInfo or {}

	roomInfo.roomId 		= roomId 
	roomInfo.roomName 		= roomInfo.roomName 		or "房间" .. roomId 
	roomInfo.stock 			= roomInfo.stock 			or stock 				-- 当前库存
	roomInfo.stockBoss 		= roomInfo.stockBoss 		or stockBoss 			-- 当前boss库存
	roomInfo.stockThreshold = roomInfo.stockThreshold 	or stockThreshold		-- 当前库存阈值
	roomInfo.profitPercent 	= roomInfo.profitPercent 	or profitPercent 		-- 当前纯利 抽取比例
	roomInfo.bonusPercent 	= roomInfo.bonusPercent 	or bonusPercent			-- 当前彩金 抽取比例
	roomInfo.pumpPercent 	= roomInfo.pumpPercent 		or pumpPercent			-- 当前抽水 抽取比例
	roomInfo.bonus 			= roomInfo.bonus 			or 0 					-- 当前彩金
	roomInfo.pump 			= roomInfo.pump 			or 0 					-- 当前抽水

	unilight.savedata(dbName, roomInfo)
	return roomInfo
end

function GetRoomInfo(gameId, roomId, profitPercent, roomName, stockThreshold, stock, stockBoss, bonusPercent, pumpPercent)
	return CreateRoomInfo(gameId, roomId, profitPercent, roomName, stockThreshold, stock, stockBoss, bonusPercent, pumpPercent)
end

-- 减少库存
function RoomStockReduce(gameId, roomId, reduceChips)
	local roomStock = GetRoomInfo(gameId, roomId)
	roomStock.stock = roomStock.stock - reduceChips
	SaveRoomInfo(gameId, roomId, roomStock)
	return roomStock
end

-- 重设库存
function ResetRoomStock(gameId, roomId, stock)
	local roomStock = GetRoomInfo(gameId, roomId)
	roomStock.stock = stock 
	SaveRoomInfo(gameId, roomId, roomStock)
	return roomStock
end

function SaveRoomInfo(gameId, roomId, roomInfo)
	local dbName = tostring(gameId) .. "roominfo"	
	local dbRoomInfo = GetRoomInfo(gameId, roomId)

	roomInfo.stock 			= math.ceil(roomInfo.stock) or dbRoomInfo.stock 
	roomInfo.stockBoss		= math.ceil(roomInfo.stockBoss) or dbRoomInfo.stockBoss
	roomInfo.stockThreshold 	= roomInfo.stockThreshold or dbRoomInfo.stockThreshold
	roomInfo.profitPercent 	= roomInfo.profitPercent or dbRoomInfo.profitPercent
	roomInfo.bonusPercent 	= roomInfo.bonusPercent or dbRoomInfo.bonusPercent
	roomInfo.pumpPercent 		= roomInfo.pumpPercent or dbRoomInfo.pumpPercent
	roomInfo.bonus 			= math.ceil(roomInfo.bonus) or dbRoomInfo.bonus
	roomInfo.pump 			= math.ceil(roomInfo.pump) or dbRoomInfo.pump

	unilight.savedata(dbName, roomInfo)
	return roomInfo 
end

function GetRoomAllInfo(gameId)
	local dbName = tostring(gameId) .. "roominfo"	
	return unilight.getAll(dbName)
end

------------------------以一个类型作为一个房间存储的数据处理----------------------------

-- 类似斗牛游戏 的 房间基础数据 初始化处理
function InitUnifiedRoomInfoDb(gameId, profitPercent, roomName, stockThreshold, stock, stockBoss, bonusPercent, pumpPercent)
	-- 初始化表
	InitRoomInfoDb(gameId)

	-- 以一个类型 作为 房间 记录库存信息 所有类型 均在服务器开启时 初始化好具体信息
	local subGameConfig = chessroomconfig.CmdSubGameConfigGetByGameId(gameId)
	for i, subGame in ipairs(subGameConfig) do
		local subGameId = subGame.subGameId
		local roomInfoCfg = chessroomconfig.CmdSubGameRoomConfigGetByGameIdSubGameId(gameId, subGameId)
		for i, roomInfo in ipairs(roomInfoCfg) do
			local key = CmdRoomKeyGetBySubGameIdRoomType(subGameId, roomInfo.roomType) 
			-- 逐一类型 调用 创建 以key 作为 roomId
			CreateRoomInfo(gameId, key, profitPercent, roomName, stockThreshold, stock, stockBoss, bonusPercent, pumpPercent)
		end
	end	
end

-- 通过子游戏类型 与 房间类型 获取key 作为统一roomId
function CmdRoomKeyGetBySubGameIdRoomType(subGameId, roomType)
	return tonumber(subGameId)*10000+tonumber(roomType)
end

-- 通过key 获取 子游戏类型 与 房间类型 
function CmdGetSubGameIdRoomTypeByRoomKey(key)
	return math.floor(key/10000), key%10000
end
---王海军添加,希望升级成所有跟db相关的操作都叫Data而不叫Info
InitRoomDataDb = InitRoomInfoDb
CreateRoomData =  CreateRoomInfo
GetRoomData = GetRoomInfo
SaveRoomDataById = SaveRoomInfo
GetRoomAllData = GetRoomAllInfo
InitUnifiedRoomDataDb = InitUnifiedRoomInfoDb

GetRoomDataAll = GetRoomAllInfo
function SaveRoomData(roomdata)
	SaveRoomDataById(go.gamezone.Gameid,roomdata.roomId,roomdata)
end
