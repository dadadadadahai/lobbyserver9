module('RoomInfo', package.seeall) -- 用户信息

table_game_list = import "table/table_game_list"

INIT_GLOBAL_ROOM_ID = 1000000				-- 初始房间id

SAVE_ROOM_DATA 		= 300 * 1000			-- 房间数据5分钟存档一次

ALL_LEAVE_OVERDUE 	= 1 * 86400 * 1000		-- 房间玩家全离开时 	一天后房间过期 从最后一个玩家离开计起
USER_IN_OVERDUE		= 2 * 86400 * 1000 		-- 房间有人但是未扣费 	后面两个规则 暂时待定吧 
STANDARD_OVERDUE	= 5 * 86400 * 1000 		-- 房间标准过期时间 	

DIAMOND_LIMIT 		= 0 					-- 赌钻玩家钻石下限

-- 通知游戏服准备房间的缘由
ENUM_CREATE_FLAG = {
	CREATE = 1,	-- 创建
	RETURN = 2,	-- 返回
	ENTER  = 3,	-- 进入
	PRACT  = 4,	-- 练习场
	CONTINUE  = 5,	-- 续局
}

if RoomClass == nil then
	CreateClass("RoomClass")
end
RoomClass:SetClassName("Room")

MapTableRoomCost 	= {} 	-- 房间消费表 缓存出来 MapTableRoomCost[lobbyId][usernbr][gamenbr]:{diamondcost, averdiamondcost}
MapTableCreateConfig= {}	-- 各个游戏房间创建选项
MapSendCreateConfig = {} 	-- 将发送给前端的大厅创建表格

MapPreLogin 		= {}	-- 用于玩家预登陆

MapUid2Room			= {}	-- 当前麻将大厅 正在开放的房间 通过玩家uid 	索引
GlobalRoomInfoMap 	= {} 	-- 全局房间管理

-- 调试模式赋予较容易输入的房间号
MapGoodRoomId 		= {
	111111,222222,333333,444444,555555,666666,777777,888888,999999,
	111112,222221,333332,444442,555552,666662,777772,888882,999992,
	111113,222223,333331,444443,555553,666663,777773,888883,999993,
	111114,222224,333334,444441,555554,666664,777774,888884,999994,
	111115,222225,333335,444445,555551,666665,777775,888885,999995,
	111116,222226,333336,444446,555556,666661,777776,888886,999996,
	111117,222227,333337,444447,555557,666667,777771,888887,999997,
	111118,222228,333338,444448,555558,666668,777778,888881,999998,
	111119,222229,333339,444449,555559,666669,777779,888889,999991,
	122222,211111,311111,411111,511111,611111,711111,811111,911111,
	133333,233333,322222,422222,522222,622222,722222,822222,922222,
	144444,244444,344444,433333,533333,633333,733333,833333,933333,
	155555,255555,355555,455555,544444,644444,744444,844444,944444,
	166666,266666,366666,466666,566666,655555,755555,855555,955555,
	177777,277777,377777,477777,577777,677777,766666,866666,966666,
	188888,288888,388888,488888,588888,688888,788888,877777,977777,
	199999,299999,399999,499999,599999,699999,799999,899999,988888,
}

MapLobbyMd5 		= {}

----------------------------------整理表格数据------------------------------
function InitTable()
	-- 房费表
	-- for i,v in pairs(TableRoomCostConfig) do
	-- 	MapTableRoomCost[v.lobbyId] = MapTableRoomCost[v.lobbyId] or {}
	-- 	MapTableRoomCost[v.lobbyId][v.usernbr] = MapTableRoomCost[v.lobbyId][v.usernbr] or {}
	-- 	MapTableRoomCost[v.lobbyId][v.usernbr][v.gamenbr] = {
	-- 		diamondcost 		= v.diamondcost,
	-- 		averdiamondcost		= v.averdiamondcost,
	-- 	}
	-- end

	-- 房间创建表
	-- for gameId,v in pairs(TableCreateConfigList) do
	-- 	MapTableCreateConfig[gameId] = {
	-- 		gameId 		= gameId,			-- 游戏id
	-- 		gameName 	= v.gameName,		-- 游戏名称
	-- 		baseUserNbr = {},				-- 几人模式(这个数据 前端没有选项 服务器都必须知道该数据)
	-- 		userNbr 	= {},				-- 几人模式(用于校验前端数据是否正常)
	-- 		gameNbr 	= {},				-- 局数选择
	-- 		payType 	= {},				-- 支付类型
	-- 		hostTip 	= {},				-- 支付类型
	-- 		open 		= v.open,			-- 是否显示开启
	-- 		gameshareTitle = v.gameshareTitle, 		-- 分享数据标题
	-- 		gameshareContent = v.gameshareContent 	-- 分享数据内容
	-- 	}

	-- 	-- 填充几人模式基础数据
	-- 	for _,vv in ipairs(v.baseUserNbr) do
	-- 		table.insert(MapTableCreateConfig[gameId].baseUserNbr, vv)
	-- 	end

	-- 	-- 填充几人模式
	-- 	for _,vv in ipairs(v.userNbr) do
	-- 		MapTableCreateConfig[gameId].userNbr[vv.value] = vv.label
	-- 	end

	-- 	-- 填充局数选择
	-- 	for _,vv in ipairs(v.gameNbr) do
	-- 		MapTableCreateConfig[gameId].gameNbr[vv.value] = vv.label
	-- 	end

	-- 	-- 填充支付模式
	-- 	for _,vv in ipairs(v.payType) do
	-- 		MapTableCreateConfig[gameId].payType[vv.value] = vv.label
	-- 	end

	-- 	-- 填充房主小费
	-- 	for _,vv in ipairs(v.hostTip) do
	-- 		MapTableCreateConfig[gameId].hostTip[vv.value] = vv.tipValue
	-- 	end
	-- end

	-- 提前缓存需要发送给前端的表格数据
	-- for i,v in ipairs(TableLobbyGameList) do
	-- 	local temp = {
	-- 		lobbyGameList = v,
	-- 	}
	-- 	local createRoomConfigs = {}

	-- 	for k,vv in pairs(v.mahjongList) do
	-- 		if TableCreateConfigList[vv].open == 0 then
	-- 			local temp = {
	-- 				gameId 		= TableCreateConfigList[vv].gameId,
	-- 				gameName 	= TableCreateConfigList[vv].gameName,
	-- 			}
	-- 			table.insert(createRoomConfigs, temp)
	-- 		else
	-- 			table.insert(createRoomConfigs, TableCreateConfigList[vv])
	-- 		end
	-- 	end

	-- 	temp.createRoomConfigs = createRoomConfigs

	-- 	MapSendCreateConfig[i] = json.encode(temp)
	-- end

	-- 预存各个lobby的MD5数据
	-- InitLobbyMd5()
end

-- 预存各个lobby的MD5数据
function InitLobbyMd5()
    local mapLobbyGameListJson = {}
    for line in io.lines("table/TableLobbyGameList.json") do
    	local _, _, lobbyId = string.find(line, "(%d+)") -- %d匹配数字 %D匹配除数字外的所有数据
    	if lobbyId ~= nil then
    		mapLobbyGameListJson[tonumber(lobbyId)] = line
    	end
    end 

    -- 统计出每个游戏所接入的大厅
    local mapGameIdToLobbyId = {}
    for lobbyId,v in ipairs(TableLobbyGameList) do
    	for _,gameId in ipairs(v.mahjongList) do
    		mapGameIdToLobbyId[gameId] = mapGameIdToLobbyId[gameId] or {}
    		mapGameIdToLobbyId[gameId][lobbyId] = true
    	end
    end

    local mapLobbyCreateConfigListJson = {}
    for line in io.lines("table/TableCreateConfigList.json") do
    	local _, _, _, gameId = string.find(line, "(%d+)%D+(%d+)") -- %d匹配数字 %D匹配除数字外的所有数据
    	if gameId ~= nil then
	    	gameId = tonumber(gameId)
	    	if mapGameIdToLobbyId[gameId] ~= nil then
		    	for lobbyId,_ in pairs(mapGameIdToLobbyId[gameId]) do
		    		mapLobbyCreateConfigListJson[lobbyId] = mapLobbyCreateConfigListJson[lobbyId] or ""
		        	mapLobbyCreateConfigListJson[lobbyId] = mapLobbyCreateConfigListJson[lobbyId] .. line
		    	end
		    end
    	end
    end

    -- 遍历所有大厅的json串 获取其md5
    for lobbyId,jsonStr in pairs(mapLobbyCreateConfigListJson) do
		MapLobbyMd5[lobbyId] = go.md5(HandleJson(mapLobbyGameListJson[lobbyId])) .. go.md5(HandleJson(jsonStr))
    end

    unilight.info("MD5数据初始化成功:" .. table.tostring(MapLobbyMd5))
end

-- 处理json串
function HandleJson(jsonStr)
	if string.sub(jsonStr, -1) == "," then
		jsonStr = string.sub(jsonStr, 1, -2)
	end
	return "[" .. jsonStr .. "]"
end

-----------------------------------获取房间id-------------------------------
-- 初始化一个全局唯一的 globalRoomId
function InitGlobalRoomId()
	local info = {
		_id 			= 1,
		globalroomid 	= INIT_GLOBAL_ROOM_ID,
	}
	unilight.savedata("globalroomid", info)
	return info 
end

-- 获取一个全局唯一的 globalRoomId
function GetGlobalRoomId()
	local info = unilight.getdata("globalroomid", 1)
	if info == nil then
		info = InitGlobalRoomId()
	end 

	-- 过滤掉 房间id从0开始的问题
	if info.globalroomid < INIT_GLOBAL_ROOM_ID then
		info.globalroomid = INIT_GLOBAL_ROOM_ID
	end

	info.globalroomid = info.globalroomid + 1
	unilight.savedata("globalroomid", info)
	return info.globalroomid
end

-- 随机一个当前并未在使用的房间id
function GetRandomRoomId()
	-- 如果为调试模式 则 赋给简单重复的房间号
	if unilight.getdebuglevel() > 0 then
		for i,v in ipairs(MapGoodRoomId) do
			if GlobalRoomInfoMap[v] == nil then
				unilight.debug("调试模式 赋予较优房间号")
				return v
			end			
		end
	end

	local index = 0
	while true do
		local randRoomId = math.random(100000, 999999)
		if GlobalRoomInfoMap[randRoomId] == nil then
			return randRoomId
		end
		index = index + 1 
		-- 最多尝试100次
		if index >= 100 then
			break
		end
	end

	-- 跑到这里 代表上面while循环没找到合适的 那么从100000开始递增获取合适房间号
	for randRoomId = 100000,999999 do
		if GlobalRoomInfoMap[randRoomId] == nil then
			return randRoomId
		end		
	end
end

-------------------------------------基础操作-------------------------------
-- 服务器开启时 把数据库中正常运行的房间 均缓存出来
function CreateRoomCache()
	local filter = unilight.a(unilight.gt("globalroomid", INIT_GLOBAL_ROOM_ID), unilight.eq("valid", 1), unilight.neq("paytype", 0))
	local globalRoomDatas = unilight.chainResponseSequence(unilight.startChain().Table("globalroomdata").Filter(filter))	
	for i,globalRoomData in ipairs(globalRoomDatas) do

		local room = RoomClass:New()

		room.id = globalRoomData.roomid
	 	room.data = globalRoomData
		room.base = table_game_list[globalRoomData.gameid]
	 	room.state = {
	 		zoneInfo 	= nil,
	 		shareInfo 	= nil
	 	}

	 	-- 去获取该游戏分享语句
	 	-- room.state.shareInfo = ShareMgr.ConstructShareInfo(room)

		-- 房间内已有人 则缓存起来
		for uid,pos in pairs(globalRoomData.history.position) do
			SetMapUid2RommData(globalRoomData.lobbyId, uid, room)
		end

		-- 如果房间未满人 则 房主依然可以优先返回 占位
		if table.len(globalRoomData.history.position) < globalRoomData.usernbr then
			SetMapUid2RommData(globalRoomData.lobbyId, globalRoomData.owner, room)
		end

		room.state.loopTimer = unitimer.addtimermsec(RoomClass.Loop, 500, room)
		--WHJ 只有新建的房间给定时存档,重启的感觉没必要,刷出一堆日志,后期再考虑必要性
		--room.state.timerSaveData = NewUniTimerRandomClass(RoomClass.TimerSaveData, SAVE_ROOM_DATA, room)

		local now = go.time.Msec()

		-- 检测销毁相关
		local remove = false
		local allleavetime = room.data.allleavetime
		if room.state.shareInfo == nil then
			remove = true
		end
		if remove == false and allleavetime ~= nil then
			if now - allleavetime >= ALL_LEAVE_OVERDUE then
				remove = true
			else
				room.state.eventEmpytTimeOut = NewUniEventClass(RoomClass.EventEmptyTimeOut, ALL_LEAVE_OVERDUE - (now - allleavetime), 1, room)
			end
		end

		-- 缓存起来(先得缓存起来 不然后续销毁不成功)
		GlobalRoomInfoMap[room.id] = room

		-- 未被销毁的房间 缓存起来
		if remove then
			-- 房间销毁
			RemoveRoom(room.id)
		end
	end
	unilight.info("大厅启动 数据库中的房间数据缓存出来")
end

-- 通过roomid获取当前正常开放的房间数据
function GetRoomInfoById(roomid)
    return GlobalRoomInfoMap[roomid]
end

function RoomClass:GetId()
	return self.data.roomid .. ":" .. self.data.globalroomid
end

function RoomClass:GetName()
	if self.base == nil then
		unilight.error("该房间不存在对应房间表格 :" .. table.tostring(self))
		return ""
	else
		return self.base.gameName
	end
end

-- 通过lobbyid、uid 获取玩家所属房间
function GetRoomByLobbyIdUid(lobbyId, uid)
	lobbyId = lobbyId or 0

	-- 兼容老客户端 
	if lobbyId == 0 then
		for lobbyId,roomInfos in pairs(MapUid2Room) do
			local room = roomInfos[uid]
			if room ~= nil then
				return room
			end
		end
		return
	end
	---------------

	if MapUid2Room[lobbyId] ~= nil then
		return MapUid2Room[lobbyId][uid]
	end
end

function SetMapUid2RommData(lobbyId, uid, room)
	if lobbyId == nil or uid == nil or room == nil or lobbyId == 0 then
		unilight.error("SetMapUid2RommData para err")
		return 
	end
 	MapUid2Room[lobbyId] = MapUid2Room[lobbyId] or {}
 	MapUid2Room[lobbyId][uid] = room
end

function RemoveMapUid2RommData(lobbyId, uid)
	if lobbyId == nil or lobbyId == 0 or uid == nil then
		unilight.error("RemoveMapUid2RommData para err")
		return 
	end
	if MapUid2Room[lobbyId] ~= nil then		
 		MapUid2Room[lobbyId][uid] = nil
	end
end

-- 通过globalRoomId 获取数据中的房间数据(获取战绩时 有用到)
function GetGlobalRoomData(globalRoomId)
	local globalRoomData = unilight.getdata("globalroomdata", globalRoomId)
	return globalRoomData
end

-- 房间数据存档
function SaveGlobalRoomData(globalRoomData)
	unilight.savedata("globalroomdata", globalRoomData)
	return globalRoomData
end

-- 存档
function RoomClass:Save()
	SaveGlobalRoomData(self.data) 
end

--关机存档所有房间数据
function SaveAllRoomData()
	for k,v in pairs(GlobalRoomInfoMap) do
		v:Save()
		v:Debug("停机存档:"..v.data.owner)
	end
end

-- 缓存房间销毁
function RoomClass:Destroy()
	GlobalRoomInfoMap[self.id] = nil
end

-- 数据库房间销毁
function RemoveGlobalRoomData(globalRoomData)
	if globalRoomData == nil then
		return 
	end
	unilight.delete("globalroomdata", globalRoomData.globalroomid) 
end

-- 房间销毁
function RemoveRoom(roomId, hostTip)
	local room = GetRoomInfoById(roomId)
	if room == nil then
		unilight.info("游戏服练习场 忽略:" .. roomId)
		return 
	end

	local owner = room.data.owner
	local remove = false

	-- 如果房间一局都没玩过 则房间销毁时 数据库的数据也不需要保留了  
	if room.data.curgamenbr == 0 then
		remove = true
	else
		-- 有战绩的房间 解散时 所有参与的玩家 加上play数据
		for uid,_ in pairs(room.data.history.position) do
			UserInfo.AddUserPlayData(uid, room)
		end

		-- 数据库中 房间是否有效置为 0
		room.data.valid = 0 
		room.data.allleavetime = nil
	end

	-- 保证handle处理到 房间内所有的玩家[重要]
	local handle = table.clone(room.data.history.position)
	handle[owner] = true
	for uid,_ in pairs(handle) do
		-- 缓存置空
		RemoveMapUid2RommData(room.data.lobbyId, uid)

		-- 房间销毁后 如果该玩家在线 则 通知大厅前端
		local userData = UserInfo.GetUserDataById(uid)
		local res = {}
		res["do"] 	= "Cmd.RemoveRoomCmd_Brd" 
		res["data"] = {
			card = userData.mahjong.card
		}
		local laccount = go.roomusermgr.GetRoomUserById(uid)
		if laccount ~= nil then
			unilight.success(laccount, res)	
			unilight.info("房间正式从数据库销毁 玩家在线 通知玩家：" .. uid)	
		else
			unilight.info("房间正式从数据库销毁 玩家离线 不用通知：" .. uid)	
		end
	end

	unilight.info("房间销毁 roomId：" .. roomId .. "	globalRoomId:" .. room.data.globalroomid)

	-- 是否直接销毁房间
	if remove then
		RemoveGlobalRoomData(room.data)
	else
		-- 如果是大赢家支付模式 则此处扣费(先扣费再发送给monitor)
		if room.data.isfree ~= true and room.data.hasDecrease == nil and room.data.paytype == 3 then
			WinnerDeductRoomCharge(room)
		end

		-- 如果房间有正常游戏数据 即可能存在房主小费 则 此处处理下
		SaveHostTip(room.data, hostTip)

		-- 此处发送给monitor进行数据统计
		SendRoomInfoToMonitor(room.data)

		-- 记录下玩家输赢积分
		PointRank.CheckSetUserDayPoint(room.data)

		-- 湖南湖北大厅 此刻需要检测给每天第一次游戏玩家 加5个钻石
		UserInfo.CheckRewardTodayFirstPlay(room.data)

		-- 存入最新数据
		SaveGlobalRoomData(room.data)
	end

	-- 房间定时器销毁
	room.state.loopTimer:Stop()
	room.state.timerSaveData = nil

	-- 缓存中清掉
	room:Destroy()
end

-- 定时存档
function RoomClass:TimerSaveData(me)
	local self = self or me
	--5分钟定时存档
	self:Save()
	self:Debug("定时存档")
end

-- 房间过期
function RoomClass:EventEmptyTimeOut(me)
	local self = self or me
	self:Debug("房间过期")
	RemoveRoom(self.id)
end

-- 轮询
function RoomClass:Loop(me)
	local self = self or me

	-- 检测五分钟定时存档 定时器
	if self.state.timerSaveData then
		self.state.timerSaveData:Check(unitimer.now)
	end

	-- 检测房间过期事件是否触发
	if self.state.eventEmpytTimeOut ~= nil then
		if self.state.eventEmpytTimeOut:Check(unitimer.now) == true then
			if self.state.eventEmpytTimeOut.maxtimes <= 0 then
				self.state.eventEmpytTimeOut = nil
			end
		end
	end
end

-- 最后一玩家请求进入时 检测下 其他玩家是否够扣除房费
function CheckOtherUserDiamond(room, laccount)
	local uid = laccount.Id
	local len = table.len(room.data.history.position)
	if room.data.history.position[uid] == nil then
		len = len + 1
	end

	-- 满人了 且还未扣费
	if room.data.hasDecrease == nil and len == room.data.usernbr then
		local enough = true
		if room.data.paytype == 1 then
			-- 房主支付
			local userData = UserInfo.GetUserDataById(room.data.owner)
			local cur = 0
		    -- 江西客家消耗房卡
		    if room.data.lobbyId == 7 then
		        cur = userData.mahjong.card
		    else
		        cur = userData.mahjong.diamond
		    end
			if cur < room.data.diamondcost then
				enough = false
			end
		elseif room.data.paytype == 2 or room.data.paytype == 3 then
			-- 均摊支付／大赢家支付  则 需要校验所有的玩家筹码
			for uid,_ in pairs(room.data.history.position) do
				local userData = UserInfo.GetUserDataById(uid)
				local cur = 0
			    -- 江西客家消耗房卡
			    if room.data.lobbyId == 7 then
			        cur = userData.mahjong.card
			    else
			        cur = userData.mahjong.diamond
			    end
				if cur < room.data.diamondcost then
					enough = false
					break
				end
			end
		end

		-- 不够扣费 弹个提示
		if enough == false then
			SendFailToUser("当前房间内有玩家不够支付房费 请提醒充值后进入房间", laccount)
			for uid,_ in pairs(room.data.history.position) do
				local laccount = go.accountmgr.GetAccountById(uid)
				SendFailToUser("当前房间内有玩家不够支付房费 新玩家进入被拒绝", laccount)
			end
		end

		-- 满人了 其他玩家均够扣则可进
		return enough	
	end

	-- 人还未满 该玩家可以进
	return true
end

-- 实际扣除房费
function DeductRoomCharge(room)
	local failUsers = 0
	local allcost 	= 0
	if room.data.paytype == 1 then
		-- 房主支付模式
		local owner = room.data.owner
		local ret = nil
		local returnNum = nil

		if room.data.lobbyId == 7 then
			ret,_,returnNum = UserInfo.CommonChangeUserCard(owner, 2, room.data.diamondcost, true, "房主支付", ItemStatistics.ENUM_STATIC_TYPE.NOR)
		else
			ret,_,returnNum = UserInfo.CommonChangeUserDiamond(owner, 2, room.data.diamondcost, true, "房主支付", ItemStatistics.ENUM_STATIC_TYPE.NOR)
		end

		if ret == 0 then
			allcost = allcost + room.data.diamondcost
		else
			room:Error("房主支付 玩家扣费失败:" .. owner .. "	cost:" .. room.data.diamondcost)
			-- 出现不够扣费的情况 能扣多少扣多少
			if ret == 2 and returnNum ~= nil and returnNum ~= 0 then
				if room.data.lobbyId == 7 then
					ret = UserInfo.CommonChangeUserCard(owner, 2, returnNum, true, "房主支付", ItemStatistics.ENUM_STATIC_TYPE.NOR)
				else
					ret = UserInfo.CommonChangeUserDiamond(owner, 2, returnNum, true, "房主支付", ItemStatistics.ENUM_STATIC_TYPE.NOR)
				end
				if ret == 0 then
					allcost = allcost + returnNum
					room:Error("房主支付 玩家扣全费失败:" .. owner .. "	只扣了cost:" .. returnNum)
				end
			end
		end
	elseif room.data.paytype == 2 then
		for uid,_ in pairs(room.data.history.position) do
			local ret = nil
			local returnNum = nil

			if room.data.lobbyId == 7 then
				ret,_,returnNum = UserInfo.CommonChangeUserCard(uid, 2, room.data.diamondcost, true, "均摊支付", ItemStatistics.ENUM_STATIC_TYPE.NOR)
			else
				ret,_,returnNum = UserInfo.CommonChangeUserDiamond(uid, 2, room.data.diamondcost, true, "均摊支付", ItemStatistics.ENUM_STATIC_TYPE.NOR)
			end
			
			if ret == 0 then
				allcost = allcost + room.data.diamondcost
			else
				failUsers = failUsers + 1
				room:Error("均摊支付 第" .. failUsers .. "个玩家扣费失败:" .. uid .. "	cost:" .. room.data.diamondcost)
				-- 出现不够扣费的情况 能扣多少扣多少
				if ret == 2 and returnNum ~= nil and returnNum ~= 0 then
					if room.data.lobbyId == 7 then
						ret = UserInfo.CommonChangeUserCard(uid, 2, returnNum, true, "均摊支付", ItemStatistics.ENUM_STATIC_TYPE.NOR)
					else
						ret = UserInfo.CommonChangeUserDiamond(uid, 2, returnNum, true, "均摊支付", ItemStatistics.ENUM_STATIC_TYPE.NOR)
					end
					if ret == 0 then
						allcost = allcost + returnNum
						room:Error("均摊支付 第" .. failUsers .. "个玩家扣全费失败:" .. uid .. "	只扣了cost:" .. returnNum)
					end
				end
			end
		end
	end
	room.data.hasDecrease = 1
	room.data.allcost = allcost
end

-- 大赢家模式 房间销毁时 扣费
function WinnerDeductRoomCharge(room)
    local winner = {}
    local integral = nil
	local failUsers = 0
	local allcost 	= 0
    for i,v in ipairs(room.data.history.statistics) do 
        if integral == nil or v.integral == integral then
            integral = v.integral
            table.insert(winner, v.uid)
        elseif v.integral > integral then
            integral = v.integral
            winner = {}
            table.insert(winner, v.uid)
        end
    end
    local cost = math.ceil((room.data.diamondcost*10)/(#winner))/10
	for _,uid in ipairs (winner) do
		local ret = nil
		if room.data.lobbyId == 7 then
			ret = UserInfo.CommonChangeUserCard(uid, 2, cost, true, "大赢家支付", ItemStatistics.ENUM_STATIC_TYPE.NOR)
		else
			ret = UserInfo.CommonChangeUserDiamond(uid, 2, cost, true, "大赢家支付", ItemStatistics.ENUM_STATIC_TYPE.NOR)
		end

		if ret == 0 then
			allcost = allcost + room.data.diamondcost
		else
			failUsers = failUsers + 1
			room:Error("大赢家支付 第" .. failUsers .. "个玩家扣费失败:" .. uid .. "	cost:" .. cost)
		end
	end 
	room.data.hasDecrease = 1
	room.data.allcost = allcost 
end

-- 发送砖石变化(房卡变化时 也在这里发送) 
function SendDiamondChange(zoneInfo, uid, diamond, change, zonetask, card, cardChange)
	local doinfo = "Cmd.UserDiamondChangeLobbyCmd_S"
	local data = {
		uid 	= uid, 
		diamond = diamond, 
		change 	= change,
		card 	= card,
		cardChange 	= cardChange,
	}
	if zoneInfo ~= nil then
		zoneInfo:SendCmdToMe(doinfo, data)
	elseif zonetask ~= nil then
	    local send = {}
	    send["do"] = doinfo
	    send["data"] = data
	    local s = json.encode(send)
	    unilight.info("sendCmdToMe" .. s)
	    zonetask.SendString(s) 		
	end
end

-- 砖石变化时(房卡变化时 也在这里发送) 检测是否需要发送给游戏服（正常在游戏玩的玩家都能收到  但是练习场的暂时就先不理了）
function CheckSendDiamondChange(uid, diamond, change, card, cardChange)
	for lobbyId,roomInfos in pairs(MapUid2Room) do
		local room = roomInfos[uid]
		if room ~= nil and room.state.zoneInfo ~= nil then
			-- 如果有在某个游戏服中 则给游戏服推送一下数据
			SendDiamondChange(room.state.zoneInfo, uid, diamond, change, nil, card, cardChange)
		end
	end
end

-- 房间结算时 处理游戏服过来的房主小费数据
function SaveHostTip(globalRoomData, hostTip)
	if hostTip == nil then
		return
	end

	if type(hostTip) ~= "string" then
		unilight.error("游戏服通知大厅房主小费 hostTip不为string")
		return		
	end

	local data = json2table(hostTip)
	if type(data) ~= "table" then
		unilight.error("游戏服通知大厅房主小费 hostTip解析后不为table")
		return
	end

	-- 小费汇总
	for i=1, globalRoomData.usernbr do
		if globalRoomData.history.statistics[i] == nil then
			globalRoomData.history.statistics[i] = 0
		else
			globalRoomData.history.statistics[i].integral = (globalRoomData.history.statistics[i].integral or 0) + data[i].integral
		end
	end

	-- 保存房主小费数据
	globalRoomData.history.hosttip = data
end

-- 房间结算 发送数据给monitor进行数据统计
function SendRoomInfoToMonitor(globalRoomData)
	local msg = {
		data 		= nil,							-- 房主信息
		charnum 	= globalRoomData.usernbr,		-- 2人场、4人场等
		repnum		= globalRoomData.gamenbr,		-- 局数,4局、8局等
		type		= (globalRoomData.paytype or 1)-1,	-- 1房主支付 2均摊支付 （老友系列 值有点不一致 需要-1）
		roomid		= globalRoomData.roomid,		-- 房间号
		realnum		= globalRoomData.curgamenbr,	-- 实际玩了几局
		extdata 	= "",							-- 玩法类型
		diamond 	= globalRoomData.allcost or 0 	-- 该房间实际总收费
	}

	-- 如果有小数 其实是分
	if msg.repnum%1 ~= 0 then
		msg.repnum = math.floor(msg.repnum)
	end

	-- 房主信息
	local owner = globalRoomData.owner
	local ownerInfo = UserInfo.GetUserDataById(owner) 
	local userData = {
		userid 		= owner,
		username 	= ownerInfo.base.nickname,
	}
	msg.data = userData

	-- 玩法类型
	local tableInfo = RoomInfo.MapTableCreateConfig[globalRoomData.gameid]
	if tableInfo ~= nil then
		local playType = ""
		if globalRoomData.props ~= nil then
			for i,v in ipairs(globalRoomData.props) do
				playType = playType .. TablePlayTypeList[v].desc .. " "
			end
		end
		msg.extdata = playType
	end

	-- 发送游戏数据给monitor 
	unilight.info("SendRoomInfoToMonitor:" .. table.tostring(msg))

	local ret = go.buildProtoFwdServer("*Smd.MahjongRecordMonitorSmd_C", table2json(msg), "MS")
end


-- 获取返回给游戏服的玩家数据(如果data数据存在的话 表示为创建房间时 获取返回给游戏服的数据 此时同时给玩家存入最新创建记录)
function GetUserDataForZone(uid, data)
	local userData = UserInfo.GetUserDataById(uid)
	local userInfo = {
		uid = userData.uid,
		base = {
			nickname = userData.base.nickname,
			headurl  = userData.base.headurl,
			gender   = userData.base.gender,
		},
		mahjong = {
			diamond  = 0, --userData.mahjong.diamond,
		},	
		vip 	= {
			level 	 = userData.property.vipLevel,
		}
	}

	if data ~= nil then
		userData.mahjong.lastcreate = userData.mahjong.lastcreate or {}
		userData.mahjong.lastcreate[data.lobbyId] = data
		UserInfo.SaveUserData(userData)
	end

	return userInfo
end

-- 获取返回给游戏服的房间数据
function GetRoomDataForZone(roomData)
	local roomInfo = table.clone(roomData)
	roomInfo.history.detail = nil
	-- roomInfo.history.statistics = nil
	return roomInfo
end

-- 检测是否发送 房间创建表格
function CheckSendCreateTable(laccount, lobbyId, md5Code)
	local sendData = MapSendCreateConfig[lobbyId]
    if sendData ~= nil then 
    	local send = false
    	if md5Code == nil then
    		send = true
    		laccount.Debug("MD5校验 前端没传MD5")
    	elseif MapLobbyMd5[lobbyId] == nil then
    		send = true
    		laccount.Debug("MD5校验 后端不存在该lobbyId的MD5:" .. lobbyId)
    	elseif md5Code ~= MapLobbyMd5[lobbyId] then
    		send = true
    		laccount.Debug("MD5校验 前后端不一致 前端[" .. md5Code .. "] 后端[" .. MapLobbyMd5[lobbyId] .. "]")
    	end
    	if send then
	        local data = {
	        	list = sendData
	    	}
			RoomInfo.SendCmdToUser("Cmd.CreateConfigListLobbyCmd_S",data,laccount,true)
    		laccount.Debug("MD5校验 失败 给前端发送表格")
		else
    		laccount.Debug("MD5校验 成功")
		end
    end
end
-----------------------------------业务需求-------------------------------------

-- 获取当前大厅正常连接的游戏区服
function GetConnectGameInfo()
	local zonelists = ZoneInfo.GlobalZoneInfoMap

	local mapGameInfoList = {}
	
	for k, v in pairs(zonelists) do
	    local gameId 		= v.gameid
		local zoneId 		= v.zoneid
		local onlineNum 	= annagent.GetZoneOnlineNum(gameId, zoneId)
		local maxOnlineNum 	= v.state.maxOnlineNum
		local priority 		= v.state.priority

		-- 缓存到map中
		mapGameInfoList[gameId] = mapGameInfoList[gameId] or {
			gameId 	 = gameId,
			zoneInfo = {}
		}
		mapGameInfoList[gameId].zoneInfo[zoneId] = {
			zoneId 			= zoneId,
			onlineNum 		= onlineNum,
			maxOnlineNum 	= maxOnlineNum,
			priority 		= priority,
		}
	end
	return mapGameInfoList
end

-- 检测连进当前大厅 指定游戏gameid 是否有正常开放的 普通场、练习场  typ 1/2
function CheckMapGameInfoList(mapGameInfoList, gameId, typ)
	-- print("checkmap="..table2json(mapGameInfoList))
	if mapGameInfoList[gameId] == nil then
		return false
	end
	for k,v in pairs(mapGameInfoList[gameId].zoneInfo) do
		if typ == 1 then
			-- 检测普通场 即 优先级 大于等于0的 
			if v.priority >= 0 then
				return true
			end
		else
			-- 检测练习场 即 优先级 小于等于0的 
			if v.priority <= 0 then
				return true
			end
		end
	end	
	return false
end

-- 获取当前大厅可以选择的游戏列表 普通场、练习场  typ 1/2
function GetNormalGameList(lobbyId, typ)
	typ = typ or 1 	-- 兼容老模式 默认寻找普通场

	-- 1.当前大厅正常连接着的游戏服 且 表格中配置其开启的
	local gameIdList 		= {}
	local mapGameIdList		= {}
	local mapGameInfoList 	= GetConnectGameInfo()

	local lobbyGameListInfo = TableLobbyGameList[lobbyId]
	if lobbyGameListInfo ~= nil then
		-- 遍历表格中配置的当前大厅所连接的游戏
		for i,gameId in ipairs(TableLobbyGameList[lobbyId].mahjongList) do
			if MapTableCreateConfig[gameId] ~= nil and MapTableCreateConfig[gameId].open == 1 then
				if CheckMapGameInfoList(mapGameInfoList, gameId, typ) then
					table.insert(gameIdList, gameId)
					mapGameIdList[gameId] = true
				end
			end
		end
	end
	-- 前端可选择的游戏id列表  map形式 所有连接该大厅游戏服
	return gameIdList, mapGameIdList, mapGameInfoList
end

-- 获取当前大厅玩家上次创建房间记录
function GetLastCreate(lobbyId, uid)
	local userData = UserInfo.GetUserDataById(uid)
	if userData ~= nil and userData.mahjong.lastcreate ~= nil then
		return userData.mahjong.lastcreate[lobbyId]
	end
end

-- 发送给游戏服的房间数据 填充其他数据 typ 1/2 练习场、普通钻石场
function FillOtherToCreateRoomData(data, typ, lobbyTableInfo, level)

	data.sendFlower = 1
	data.hostType = 1
	data.needDiamond = 0
	data.winDiamond = 0
	-- 托管类型
	-- data.hostType = lobbyTableInfo.autoMode + 1

	-- -- 礼物需要收费
	-- if lobbyTableInfo.giftCost ~= 0 then
	-- 	data.sendFlower = lobbyTableInfo.giftCost
	-- end

	-- 练习场
	if typ == 1 then
		-- 需要扣钻 传扣钻数量(练习场使用)
		-- if lobbyTableInfo.pracFee ~= 0 then
		-- 	data.needDiamond = lobbyTableInfo.pracFee
		-- end

		-- -- 当前场次赌钻 传赌钻底注
		-- if level ~= nil then
		-- 	data.winDiamond = lobbyTableInfo.exerciseList[level].bet
		-- end


	-- 普通钻石场
	else
		-- 暂时普通场 还没有赌钻需求 后续添加
	end
end

-- 进入练习场
function IntoPracticeRoom(laccount, lobbyId, gameId)
	-- 由服务器随机 则优先取表格中的第一个游戏
    local gameConfig = table_game_list[lobbyId]
	if gameId == nil then
		if gameConfig ~= nil then
			gameId = gameConfig.gameId
		else
			SendFailToUser("随机进入练习场 该lobby不存在数据:" .. lobbyId,laccount)
			return ErrorDefine.RANDOM_ROOM_ERROR
		end
	end

	local uid = laccount.Id

	if gameId == nil then
		SendFailToUser("进入练习场出错 gameId nil",laccount)
		return ErrorDefine.GAMEID_ERROR
	end
	local mapGameInfoList = GetConnectGameInfo()
	local zoneId, desc = ZoneInfo.GetBestZoneId(uid, mapGameInfoList, gameId, gameConfig.subGameId, gameConfig.roomType, true)

	if zoneId == nil then
		if desc == nil then
			SendFailToUser("练习场暂未开放",laccount)
			return ErrorDefine.SERVER_SHUTDOWN
		else
			SendFailToUser(desc,laccount)
			return ErrorDefine.SERVER_SHUTDOWN
		end
	else
		return nil, gameId, zoneId
	end
end

-- 校验创建房间参数是否有误  游戏id、游戏局数、玩法类型、人数、支付类型、峰值
function CheckCreateRoomPara(cmd,laccount)
	local lobbyId 	= cmd.data.lobbyId
	local gameId 	= cmd.data.gameId
	local gameNbr 	= cmd.data.gameNbr
	local userNbr 	= cmd.data.userNbr
	local payType 	= cmd.data.payType
	local hostTip 	= cmd.data.hostTip
	-- 这里默认获取出来的是 普通场
	local gameIdList, mapGameIdList, mapGameInfoList = GetNormalGameList(lobbyId)
    local gameConfig = table_game_list[lobbyId]
	-- 校验游戏id
	if mapGameIdList[gameId] == nil or gameConfig == nil then
		unilight.info("游戏暂未开放 gameid:" .. gameId)
		SendFailToUser("游戏暂未开放",laccount)
		return 4
	end

	local createTableInfo = MapTableCreateConfig[gameId]

	-- 检测游戏局数(局数必须传过来 所以不需要考虑其为nil 调用函数前已过滤)
	if createTableInfo.gameNbr[gameNbr] == nil then
		SendFailToUser("当前游戏不支持" .. gameNbr .. "局模式",laccount)
		return 5
	end

	-- 如果userNbr前端不需要选的话 实际上还是需要数据的 则默认从表格读取默认数据()
	if userNbr == 0 and table.len(createTableInfo.baseUserNbr) ~= 0 then
		cmd.data.userNbr = createTableInfo.baseUserNbr[1]
		userNbr = createTableInfo.baseUserNbr[1]
	end
	-- 检测玩家人数(如果表格中有配置 则 前端需要选 需要传 服务器需要去校验)
	if table.empty(createTableInfo.userNbr) == false and (createTableInfo.userNbr[userNbr] == nil) then
		SendFailToUser("当前游戏不支持" .. userNbr .. "人玩法",laccount)
		return 7
	end

	-- 检测支付类型(如果表格中有配置 则 前端需要选 需要传 服务器需要去校验)
	if table.empty(createTableInfo.payType) == false and (createTableInfo.payType[payType] == nil) then
		SendFailToUser("当前游戏不支持" .. payType .. "型支付模式玩法",laccount)
		return 8
	end

	-- 检测房主小费(如果表格中有配置 则 前端需要选 需要传 服务器需要去校验)
	if table.empty(createTableInfo.hostTip) == false and (createTableInfo.hostTip[hostTip] == nil) then
		SendFailToUser("当前游戏不支持" .. hostTip .. "型房主小费玩法",laccount)
		return 9
	end

	local uid = laccount.Id
	-- 获取最佳区服
	local zoneId = ZoneInfo.GetBestZoneId(uid, mapGameInfoList, gameId, gameConfig.subGameId, gameConfig.roomType)

	return 0, zoneId
end

-- 创建房间
function CreateRoom(cmd, uid, isFree)
	local room = RoomClass:New()

	-- 获取全局唯一的房间id
	local globalRoomId 	= cmd.data.globalroomid or GetGlobalRoomId()

	-- 随机一个当前并未在使用的房间id
	local randRoomId 	= cmd.data.roomid or GetRandomRoomId()

	-- 创建全局唯一房间信息
	local globalRoomData = {
		lobbyId 	= cmd.data.lobbyId, -- 该房间属于哪个大厅的
		globalroomid= globalRoomId,		-- 全局唯一房间id
		roomid 		= randRoomId, 		-- 随机一个房间号
		owner 		= uid,				-- 房主
		gameId 		= cmd.data.gameId,			-- 所属游戏id
		basegamenbr	= cmd.data.gameNbr or cmd.data.basegamenbr,		-- 创建时能玩几局(基数 不会改变)
		gamenbr		= cmd.data.gameNbr or cmd.data.gamenbr,			-- 该房间能玩几局(续局时 会改变)
		usernbr		= cmd.data.userNbr or cmd.data.usernbr,			-- 该房间为几人模式
		paytype		= cmd.data.payType or cmd.data.paytype,			-- 该房间支付模式
		hosttipkey  = nil, 				-- 本不应存 但为了方便续局 存房主小费的索引
		hosttip		= nil,				-- 该房间房主小费模式(如果小于1 为百分比。 如果大于等于1 则为固定分值)
		diamondcost = nil,				-- 钻石模式 房间消耗
		createtime 	= os.time(),		-- 创建时间
		curgamenbr  = 0,				-- 当前房间已玩局数
		valid 		= 1,				-- 是否有效  房间解散时 该值置为0
		allleavetime= nil,				-- 房间内所有玩家都离开的时刻 用于判断该房间是否要失效解散
		hasDecrease = nil,				-- 是否已经扣费了  如果扣费则赋值1
		isfree 		= isFree,			-- 该房间是否免费
		outtime 	= cmd.data.outTime , -- 操作时间
		props 		= cmd.data.props, 	-- 房间其余参数
		history 	= {
			position 	= {},			-- 确定每个uid在数组中的位置 填充第一局游戏数据时 填充该数据 map{uid:pos} 
			statistics 	= {},			-- 统计数据 （是个数组 里面4个数据 分别为四个玩家的数据 数据内容有{uid,nickname,integral})
			detail 		= {},			-- 详细每局数据 (是个数组 里面为每局游戏具体数据 数据内容为{timestamp,statistics:{uid,nickname,integral}})
			hosttip 	= {},			-- 房主小费(是个数组 {uid,nickname,integral})
		}
 	}

	room.id = globalRoomData.roomid
	room.base = table_game_list[cmd.data.lobbyId]

 	-- 如果为钻石模式 则 从表格中获取 当前类型的房间 所需支付钻石数 大厅统一读取游戏读数据库 并存档 游戏服同时使用该数据 不易出错。
 	local zoneType = go.getconfigint("zone_type")
 	if zoneType ~= nil and zoneType == 4 then
 		local costTableInfo = MapTableRoomCost[cmd.data.lobbyId] or MapTableRoomCost[1]
 		if cmd.data.payType == 1 or cmd.data.payType == 3 then
 			-- 房主支付/大赢家支付
 			globalRoomData.diamondcost = costTableInfo[cmd.data.userNbr][cmd.data.gameNbr].diamondcost
 		elseif cmd.data.payType == 2 then
 			-- 均摊模式
 			globalRoomData.diamondcost = costTableInfo[cmd.data.userNbr][cmd.data.gameNbr].averdiamondcost
 		end
 	end

 	-- 填充房主小费数据
 	if cmd.data.hostTip ~= nil and cmd.data.hostTip ~= 1 then
 		globalRoomData.hosttipkey 	= cmd.data.hostTip
 		globalRoomData.hosttip 		= MapTableCreateConfig[cmd.data.gameId].hostTip[cmd.data.hostTip]
 	end

 	-- 数据存档
 	room.data = SaveGlobalRoomData(globalRoomData)

 	-- 缓存该房间号当前数据
 	room.state = {
 		zoneInfo 	= nil,
 		shareInfo 	= nil
 	}

 	-- 去获取该游戏分享语句
 	-- room.state.shareInfo = ShareMgr.ConstructShareInfo(room)

 	-- 房主一旦房间创建就属于该房间 优先占位
	-- print("cmd=="..table2json(cmd))
	-- print("room="..table2json(room))
	-- print("gameid="..cmd.data.gameId)
	-- print("lobbyid="..cmd.data.lobbyId)
 	SetMapUid2RommData(cmd.data.lobbyId, uid, room)

 	room.state.loopTimer = unitimer.addtimermsec(RoomClass.Loop, 500, room)
	room.state.timerSaveData = NewUniTimerRandomClass(RoomClass.TimerSaveData, SAVE_ROOM_DATA, room)
	
	GlobalRoomInfoMap[globalRoomData.roomid] = room

	-- 免费房间打个日志
	if isFree then
		room:Info("当前创建为免费房间 创建者owner:" .. uid .. " roomid:" .. globalRoomData.roomid)
	end

	return room
end

-- 返回房间
function ReturnRoom(laccount, lobbyId)
	local uid = laccount.Id

	-- 检测当前uid 是否有正在运行的房间
	local room = GetRoomByLobbyIdUid(lobbyId, uid)
    local gameConfig = table_game_list[lobbyId]
	if room == nil then
		SendFailToUser("您当前不存在房间可返回",laccount)
		return 2
	end

	-- 如果房主创建了该房间 但是不玩 已经被被人玩了 那么此时也不让他进入 不然整个逻辑会有误
	if table.len(room.data.history.position) == room.data.usernbr and room.data.history.position[uid] == nil then
		RemoveMapUid2RommData(room.data.lobbyId, uid)
		SendFailToUser("您创建的房间已满人 不能再返回房间",laccount)
		return 3
	end

	-- 还未扣费的房间 检测扣费
	if room.data.isfree ~= true and room.data.hasDecrease == nil then
		-- 4-钻石模式
		if go.getconfigint("zone_type") == 4 then
			local isOwner = false
			if room.data.owner == uid then
				isOwner = true
			end
			-- 检测钻石是否足够进入
			local ret = UserInfo.CheckRoomCost(uid, room.data.usernbr, room.data.gamenbr, room.data.paytype, room.data.hasDecrease, isOwner, lobbyId)

			if ret == false then
				if lobbyId == 7 then
					SendFailToUser("您当前房卡不足以返回房间 请充值后再次尝试",laccount)
				else
					SendFailToUser("您当前钻石不足以返回房间 请充值后再次尝试",laccount)
				end
				return 4
			else
				-- 如果自己够入 则需要检测是否人将满 其他玩家是否够扣费
				local ret = CheckOtherUserDiamond(room, laccount)
				if ret == false then
					return 5
				end
			end
		end
	end
	
	local zoneId = nil
	if room.state.zoneInfo == nil then
		-- 本来没有 则去 获取最佳区服
		local mapGameInfoList = GetConnectGameInfo()
		zoneId = ZoneInfo.GetBestZoneId(uid, mapGameInfoList, room.data.gameid, gameConfig.subGameId, gameConfig.roomType)
		if zoneId == nil then
			unilight.info("游戏暂未开放 roomid:" .. room.data.roomid .. " gameid:" .. room.data.gameid)
			SendFailToUser("游戏暂未开放",laccount)
			return 6
		end
		room.state.zoneInfo = ZoneInfo.GetZoneInfoByGameIdZoneId(room.data.gameid, zoneId)

		-- 取到后 通知游戏服准备好 然后等待游戏服回调
		local userData = GetUserDataForZone(uid)

		local data = {
			uid = uid,
			roomId = room.id,
			roomData = table2json(room.data),
			userData = table2json(userData),
			userDataList = nil,
			flag 	 = ENUM_CREATE_FLAG.RETURN,
		}

		-- 当房间以前已存在 但是不存在合适区id 此时给分配时 还需带上其他座位上的玩家数据
		local userDatas = {}
		table.insert(userDatas, table2json(userData))
		-- 其余座位填充
		for tempUid,pos in pairs(room.data.history.position) do
			if uid ~= tempUid then
				local tempUserData = UserInfo.GetUserDataById(tempUid)
				table.insert(userDatas, table2json(tempUserData))
			end
		end
		data.userDataList = userDatas

		local lobbyTableInfo = TableLobbyGameList[lobbyId]
		FillOtherToCreateRoomData(data, 2, lobbyTableInfo)

		room.state.zoneInfo:SendCmdToMe("Cmd.CreateRoomRoomLobbyCmd_S",data)
		return 0
	else
		zoneId = room.state.zoneInfo.zoneid
	end

	-- local shareInfo = ShareMgr.GetShareInfoByRoom(room, nil, uid)

	return nil, room.data.gameId, zoneId, room.id, room.data.globalroomid, shareInfo
end

-- 加入房间
function EnterRoom(laccount, roomId)
	local uid = laccount.Id
	-- 房间是否存在
	local room = GetRoomInfoById(roomId)
    local gameConfig = table_game_list[lobbyId]
	if room == nil then
		SendFailToUser("房间号码不存在:"..roomId,laccount)
		return 2
	end

	local lobbyId = room.data.lobbyId
	-- 检测该uid是否已有所属房间号 如果跟当前要进入的房间对不上的 不给进入 直接返回
	local preRoom = GetRoomByLobbyIdUid(lobbyId, uid)
	if preRoom ~= nil and preRoom.id ~= roomId then
		SendFailToUser("您已有所属房间：" .. preRoom.id .. "	不能进入其他房间",laccount)
		return 3
	end

	-- 如果该房间已经有四个玩家了 那么必须只能是这四个玩家
	if table.len(room.data.history.position) >= room.data.usernbr then
		if room.data.history.position[uid] == nil then
			local userNames = ""
			for tempUid,pos in pairs(room.data.history.position) do
				if userNames ~= "" then
					userNames = userNames ..  ","
				end
				local tempUserData = UserInfo.GetUserDataById(tempUid)
				userNames = userNames ..  tempUserData.base.nickname
			end
			SendFailToUser("该房间人数已满,不能进入该房间:"..userNames,laccount)
			return 4
		end
	end

	-- 还未扣费的房间 检测扣费
	if room.data.isfree ~= true and room.data.hasDecrease == nil then
		-- 4-钻石模式
		if go.getconfigint("zone_type") == 4 then
			local isOwner = false
			if room.data.owner == uid then
				isOwner = true
			end
			-- 检测钻石是否足够进入
			local ret, cost = UserInfo.CheckRoomCost(uid, room.data.usernbr, room.data.gamenbr, room.data.paytype, room.data.hasDecrease, isOwner, lobbyId)
			if ret == false then
				local str = {"房主支付", "均摊支付", "大赢家支付"}
				local desc = "当前房间为" .. str[room.data.paytype] .. "模式, 需" .. cost
				if lobbyId == 7 then
					SendFailToUser(desc .. "房卡才可进入房间 请充值后再次尝试",laccount)
				else
					SendFailToUser(desc .. "钻石才可进入房间 请充值后再次尝试",laccount)
				end
				return 5
			else
				-- 如果自己够入 则需要检测是否人将满 其他玩家是否够扣费
				local ret = CheckOtherUserDiamond(room, laccount)
				if ret == false then
					return 6
				end
			end
		end
	end
	
	local zoneId = nil
	if room.state.zoneInfo == nil then
		-- 本来没有 则去 获取最佳区服
		local mapGameInfoList = GetConnectGameInfo()
		zoneId = ZoneInfo.GetBestZoneId(uid, mapGameInfoList, room.data.gameid,  gameConfig.subGameId, gameConfig.roomType)
		if zoneId == nil then
			unilight.info("游戏暂未开放 roomid:" .. room.data.roomid .. " gameid:" .. room.data.gameid)
			SendFailToUser("游戏暂未开放",laccount)
			return 6
		end
		room.state.zoneInfo = ZoneInfo.GetZoneInfoByGameIdZoneId(room.data.gameid, zoneId)

		-- 取到后 通知游戏服准备好 然后等待游戏服回调
		local userData = GetUserDataForZone(uid)

		local data = {
			uid = uid,
			roomId = room.id,
			roomData = table2json(room.data),
			userData = table2json(userData),
			userDataList = nil,
			flag 	 = ENUM_CREATE_FLAG.ENTER,
		}

		-- 当房间以前已存在 但是不存在合适区id 此时给分配时 还需带上其他座位上的玩家数据
		local userDatas = {}
		table.insert(userDatas, table2json(userData))
		-- 其余座位填充
		for tempUid,pos in pairs(room.data.history.position) do
			if uid ~= tempUid then
				local tempUserData = UserInfo.GetUserDataById(tempUid)
				table.insert(userDatas, table2json(tempUserData))
			end
		end
		data.userDataList = userDatas

		local lobbyTableInfo = TableLobbyGameList[lobbyId]
		FillOtherToCreateRoomData(data, 2, lobbyTableInfo)

		room.state.zoneInfo:SendCmdToMe("Cmd.CreateRoomRoomLobbyCmd_S",data)
		return 0		
	else
		zoneId = room.state.zoneInfo.zoneid

		-- 如果已经存在最佳区服 则 游戏服那边已经是准备好的 我们这边允许其进入 则检测是否是新进玩家 如果是 则还是要等回调(目的是传userdata过去)
		if room.data.history.position[uid] == nil then
			local userData = GetUserDataForZone(uid)
			local data = {
				uid = uid,
				roomId = room.id,
				userData = table2json(userData),
				userDataList = {table2json(userData)},
				flag 	 = ENUM_CREATE_FLAG.ENTER,
			}

			local lobbyTableInfo = TableLobbyGameList[lobbyId]
			FillOtherToCreateRoomData(data, 2, lobbyTableInfo)
		
			room.state.zoneInfo:SendCmdToMe("Cmd.CreateRoomRoomLobbyCmd_S",data)
			return 0
		end
	end

	local shareInfo = ShareMgr.GetShareInfoByRoom(room, nil, uid)

	return nil, room.data.gameid, zoneId, roomId, room.data.globalroomid, shareInfo
end

-- 请求续局
function ApplyContinuePlay(laccount)
	local uid = laccount.Id
	local userData = UserInfo.GetUserDataById(uid)
	local play = nil
	if userData.mahjong.play ~= nil and table.empty(userData.mahjong.play) ~= true then
		play = userData.mahjong.play[#userData.mahjong.play]
	end

	if play == nil then
		SendFailToUser("您并没有玩过任何牌局 续局失败", laccount)
		return 1
	end

	local preGlobalRoomData = GetGlobalRoomData(play)
	if preGlobalRoomData == nil then
		SendFailToUser("续局房间有误 续局失败", laccount)
		return 2
	end

	if preGlobalRoomData.owner ~= uid then
		SendFailToUser("您当前不是房主 续局失败", laccount)
		return 3	
	end

	local cmd = {}
	cmd.data = {
		lobbyId = preGlobalRoomData.lobbyId,
		gameId 	= preGlobalRoomData.gameid,
		gameNbr = preGlobalRoomData.basegamenbr,
		userNbr = preGlobalRoomData.usernbr,
		payType = preGlobalRoomData.paytype,
		outTime = preGlobalRoomData.outtime,
		props 	= preGlobalRoomData.props,
		hostTip = preGlobalRoomData.hosttipkey or 1,
	}

	-- 目的 分配一个最合适的区服回来
	local _, zoneId = RoomInfo.CheckCreateRoomPara(cmd,laccount)
	if zoneId == nil then
		SendFailToUser("当前没有合适的区服 续局失败", laccount)
		return 4
	end

	local isFree = FreeGame.CheckInFreeGameTime(cmd.data.lobbyId, uid, cmd.data.gameId, cmd.data.userNbr)

	-- 不免费的情况下 才去判断扣费
	if isFree ~= true then
		if go.getconfigint("zone_type") == 4 then
			-- 检测钻石是否足够加入该类房间 
			local ret = UserInfo.CheckRoomCost(uid, cmd.data.userNbr, cmd.data.gameNbr, cmd.data.payType, nil, true, cmd.data.lobbyId)
			if ret == false then     
				if cmd.data.lobbyId == 7 then
					SendFailToUser("房卡不足 续局失败", laccount)
				else        
					SendFailToUser("钻石不足 续局失败", laccount)
				end
				return 5
			end
		end
	end

	-- 创建房间
	local room = RoomInfo.CreateRoom(cmd, uid, isFree)
	local userData = RoomInfo.GetUserDataForZone(uid)
	local zoneInfo = ZoneInfo.GetZoneInfoByGameIdZoneId(cmd.data.gameId,zoneId)

	-- 最佳区服缓存起来 
	room.state.zoneInfo = zoneInfo

	local data = {
		uid = uid,
		roomId = room.id,
		roomData = table2json(room.data),
		userData = table2json(userData),
		userDataList = {table2json(userData)},
		flag 	 = RoomInfo.ENUM_CREATE_FLAG.CONTINUE,
	}

	local lobbyTableInfo = TableLobbyGameList[cmd.data.lobbyId]
	FillOtherToCreateRoomData(data, 2, lobbyTableInfo)

	zoneInfo:SendCmdToMe("Cmd.CreateRoomRoomLobbyCmd_S",data)
	return 0
end

------------------------------------消息处理--------------------------------

-- 给客户端发送冒泡消息
function SendFailToUser(msg, laccount, pos)
    local data = { 
            desc=msg,
            pos = pos,
    }   
    SendCmdToUser("Cmd.SysMessageMahjongLobbyCmd_S",data,laccount)
end

-- 消息回复
function SendCmdToUser(doinfo, data, laccount, noLog)
    local send = {}
    send["do"] = doinfo
    send["data"] = data
    local s = json.encode(send)
	if laccount then
		laccount.SendString(s)
		if noLog == nil then
			laccount.Info("SendCmdToUser:" .. s)
		else
			laccount.Info("SendCmdToUser:" .. doinfo .. " 数据量太大 不打印")
		end
	end
end

function CheckPreLogin(uid, laccount)
	if MapPreLogin[uid] ~= nil then
		local roomId = MapPreLogin[uid].roomId
		local ret = EnterRoom(laccount, roomId)
		-- 大于0代表有误 为nil代表直接正确回去 不需要等游戏服回调
		if ret ~= 0 then
			local data = {
				resultCode 		= ret,
				gameId 			= gameId,
				zoneId 			= zoneId,
				roomId 			= roomId,
				globalRoomId 	= globalRoomId,
				shareInfo 		= shareInfo,
			}
			SendCmdToUser("Cmd.CreateRoomCmd_S",data,laccount)
		end

		MapPreLogin[uid] = nil
	end
end


function BroadcastToAllZone(msg_name, data)
	local zonelists = ZoneInfo.GlobalZoneInfoMap

	for gameId, zoneInfo in pairs(zonelists) do
        zoneInfo:SendCmdToMe(msg_name,data)
    end
end
