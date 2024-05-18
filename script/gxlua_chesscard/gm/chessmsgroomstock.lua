-- gm指指令列表，是和游戏相关的游戏自定义指令 
GmSvr.Help= function(cmd, laccount)
	res = {}
	res["do"] = "RequestGmListGmCmd_S" 
	res["data"] = {}
	if chessgm.GmList == nil then
		chessgm.GmCommandInit()
	end
	res.data = chessgm.GmList
	return res
end

-- 获取游戏所有房间的库存相关信息 
GmSvr.RequestRoomStockGmCmd_C = function(cmd, laccount)
	res = {}
	res["do"] = "RequestRoomStockGmCmd_S" 
	res["data"] = {}
	res.data = chessroominfodb.GetRoomAllInfo(go.gamezone.Gameid)
	return res
end

-- 请求库存信息
GmSvr.PmdRequestStockInfoGmUserPmd_CS = function(cmd, laccount)
	res = {}
	res["do"] = "RequestStockInfoGmUserPmd_CS" 
	res["data"] = {}

	local subGameId = cmd.data.subgameid
	
	-- 获取库存信息
	local roomInfo = chessroominfodb.GetRoomAllInfo(subGameId)

	-- 返回的数据组装
	local stockDatas = {}
	for i,v in ipairs(roomInfo) do
		local stockData = {
			id 			= v.roomId,			-- 序列 使用roomid回去吧
			realstock 	= v.stock-v.stockThreshold,  -- 真实库存
			stock 		= v.stock, 			-- 库存
			threshold 	= v.stockThreshold,	-- 阈值
			lottery 	= v.bonus,			-- 彩金
			subgameid 	= subGameId 		-- 大厅内的具体游戏id
		}	
		table.insert(stockDatas, stockData)
	end

	res.data.gameid = cmd.data.gameid
	res.data.zoneid = cmd.data.zoneid	
	res.data.data = stockDatas
	
	unilight.info("请求库存信息 成功")
	return res
end

-- 修改库存信息
GmSvr.PmdRequestModStockInfoGmUserPmd_CS = function(cmd, laccount)
	res = {}
	res["do"] = "RequestModStockInfoGmUserPmd_CS" 
	res["data"] = {}

	if cmd.data.subgameid == nil or cmd.data.data == nil or cmd.data.data.id == nil or cmd.data.data.stock == nil then
		res.data.retcode = 1
		res.data.retdesc = "参数有误"		
		return res 			
	end

	local subGameId = cmd.data.subgameid
	local id 		= cmd.data.data.id
	local stock 	= cmd.data.data.stock
	
	-- 获取库存信息
	local roomInfo = chessroominfodb.GetRoomInfo(subGameId, id)
	if roomInfo == nil then
		res.data.retcode = 2
		res.data.retdesc = "不存在该房间 subGameId:" .. subGameId .. " id" .. id
		return res 			
	end

	-- 库存修改日志
	unilight.warn("库存修改 gmid:" .. cmd.data.gmid .. "	gameid:" .. subGameId .. " roomid:" .. id .. "	pre:" .. roomInfo.stock .. "	cur:" .. stock .. "	change:" .. stock-roomInfo.stock)

	-- 修改库存 
	roomInfo.stock = stock 
	chessroominfodb.SaveRoomInfo(subGameId, id, roomInfo)

	local stockData = {
		id 			= id,										-- 序列 使用roomid回去吧
		realstock 	= roomInfo.stock-roomInfo.stockThreshold,  	-- 真实库存
		stock 		= roomInfo.stock, 							-- 库存
		threshold 	= roomInfo.stockThreshold,					-- 阈值
		lottery 	= roomInfo.bonus,							-- 彩金
		subgameid 	= subGameId 								-- 大厅内的具体游戏id
	}		

	res.data.retcode 	= 0
	res.data.retdesc 	= "修改库存成功"
	res.data.gameid 	= cmd.data.gameid
	res.data.zoneid 	= cmd.data.zoneid	
	res.data.data 		= stockData
	return res
end

GmSvr.PmdRequestedSubgameListGmUserPmd_CS = function(cmd, laccount)
	local res 		= cmd
	local zoneid 	= cmd.zoneid 
	local datas 	= {}
	
	-- 老友系列麻将通过这个获取
	if ZoneInfo ~= nil and ZoneInfo.GlobalZoneInfoMap ~= nil then
		local zoneInfos = ZoneInfo.GlobalZoneInfoMap
		local gameMap = {}
		for k,zoneInfo in pairs(zoneInfos) do
			gameMap[zoneInfo.gameid] = true
		end
		for gameId,_ in pairs(gameMap) do
			local data = {
				gameid 		= gameId,	
			}
			if RoomInfo ~= nil and RoomInfo.MapTableCreateConfig ~= nil and RoomInfo.MapTableCreateConfig[gameId] ~= nil then
				data.gamename = RoomInfo.MapTableCreateConfig[gameId].gameName
			else
				data.gamename = tostring(gameId)
			end
			table.insert(datas, data)
		end
	else
	    local list = go.zonelist.GetZonelist()
	    for i=1, #list do
			local data = {
				gameid 		= list[i].GetGameid(),
				gamename 	= list[i].GetGamename()
			}
			table.insert(datas, data)
	    end
	end

	res.data.data = datas

	return res
end

