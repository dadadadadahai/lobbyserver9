module('IntoGameMgr', package.seeall)
-- 玩家进入某个游戏 需要经过大厅校验

MapGameName = {
	[152] = "百家乐",
	[162] = "斗牛",
	[158] = "二人麻将",
	[157] = "28杠",
	[1000] = "飞禽走兽",
	[163] = "梭哈",
	[164] = "翻牌机",
	[165] = "扎金花",
	[166] = "老虎机",
	[167] = "百人牛牛",
	[169] = "新扎金花",
	[173] = "新二八杠",
	[174] = "新百家乐",
	[150] = "捕鱼乐园",
	[175] = "单挑",
	[168] = "大众麻将",
	[178] = "车行争霸",
}

-- 重载游戏名称
function ReloadMapGameName()
	local zoneType = go.getconfigint("zone_type")
	if zoneType == 5 then
		MapGameName[174] = "风驰30秒"
	end
end

-- 大厅调用: 检测该玩家能否进入 指定游戏 指定区服
function LobbyCheckIntoGame(uid, gameId, zoneId)
	-- 获取当前大厅所连接的游戏服 检测需要进入的游戏服是否存在
	local zoneList 	= go.zonelist.GetZonelist()
	local isExist 	= false
	for i=1,#zoneList do
		if gameId == zoneList[i].GetGameid() and zoneId == zoneList[i].GetZoneid() then
			isExist = true
			break
		end
	end

	if isExist == false then
		return 2, "当前大厅不存在该游戏服 gameid:" .. gameId .. " zoneid:" .. zoneId
	end

	local zone = go.zonemgr.GetZoneTaskByGameIdZoneId(gameId, zoneId)
	if zone == nil then
		return 3, "当前游戏服未开启 gameid:" .. gameId .. " zoneid:" .. zoneId 
	end

	-- 获取玩家数据 查看是否 在其他游戏中游戏
	local userData = chessuserinfodb.GetUserDataById(uid)

	-- 默认给用户信息中 加入curstatus 字段
	local curStatus = userData.curstatus or {}

	local canGo = false

	-- 如果玩家已经存在当前游戏信息
	if curStatus.status ~= nil then
		if gameId == curStatus.gameid and zoneId == curStatus.zoneid then
			-- 玩家已经正常在某一个游戏中 则 需要检测 当前请求进入的 和 本已在的是否为同一个游戏(这里不用更新mongo中的数据)
			return 0, "允许返回该游戏服", gameId, zoneId
		elseif curStatus.status == 2 then -- (status=1的时候 不需要理会 因为玩家并未正式进入 游戏服)
			-- 当前请求进入的 跟 当前玩家已经在的游戏 不在同一个 需要进行一定处理
			local oldZone = go.zonemgr.GetZoneTaskByGameIdZoneId(curStatus.gameid, curStatus.zoneid)
			if oldZone == nil then
				-- 如果老的游戏服 已down机 则允许其 进入其他游戏
				canGo = true
			else
				return 4, "请先从" .. MapGameName[curStatus.gameid] .. "游戏中正常退出", curStatus.gameid, curStatus.zoneid
			end				
		end
	else
		canGo = true
	end
	
	-- 允许玩家进入时 记录在mongo中 各个游戏通过维护这份数据 来监控玩家动态
	curStatus = {
		status 	= 1,			-- 经过大厅校验:1  正式进入游戏时为:2
		gameid 	= gameId,		-- 目标游戏
		zoneid 	= zoneId,		-- 目标区服
	}
	userData.curstatus = curStatus
	-- 存档
	chessuserinfodb.SaveUserData(userData)

	unilight.info("通过大厅检测进入游戏服：" .. uid .. "	gameid:" .. gameId .. "	zoneid:" .. zoneId)
	return 0, "允许进入该游戏服", gameId, zoneId	
end

-- 游戏调用: 检测该玩家能否进入当前游戏服(凡是接入大厅的游戏 都需要经过大厅检验才允许进入)
function CheckIntoGame(userData)
	local gameId = go.gamezone.Gameid
	local zoneId = go.gamezone.Zoneid
	if userData.curstatus ~= nil and userData.curstatus.gameid == gameId and userData.curstatus.zoneid == zoneId then
		if userData.curstatus.status ~= 2 then
			userData.curstatus.status = 2 
			chessuserinfodb.SaveUserData(userData)
		end
		return true
	end
	return false
end

-- 游戏调用: 正常离开游戏 清空玩家当前游戏状态信息 （不直接清空 而是设置为经过大厅检测）
function ClearUserCurStatus(userData)
	if userData == nil then
		return
	end
	if table.len(userData.curstatus) ~= 0 then
		if userData.curstatus.status == 2 then
			userData.curstatus.status = 1
			chessuserinfodb.SaveUserData(userData)
			unilight.info("玩家离开游戏 游戏内重置大厅监控：" .. userData.uid)
		end
	end
end