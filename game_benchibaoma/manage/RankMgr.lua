module("RankMgr", package.seeall)

RANK_ROBOT_NBR_MILLION 			= 10	-- 排行榜百万级机器人个数
RANK_ROBOT_NBR_TEN_MILLION		= 5		-- 排行榜千万级机器人个数
RANK_ROBOT_NBR_HUNDRED_MILLION	= 1		-- 排行榜亿级机器人个数

RANK_USER_NBR 					= 10 	-- 排行榜上榜玩家个数

-- 通过 roomid、uid 获取key 
function GetRankKeyByRoomIdUid(roomId, uid)
	local key = roomId .. "-" .. uid
	return key
end

-- 通过key 获取roomid uid
function GetRoomIdUidByRankKey(key)
	local temps = string.split(key)
	return tonumber(temps[1]), tonumber(temps[2])
end

-- 初始化指定玩家排行榜数据
function InitUserRankInfo(roomId, uid, key, willProfit)
	local userBaseInfo = RoomMgr.GetUserRoomInfo(uid)

	local rankInfo = {
		key 		= key,
		uid 		= uid,
		nickname 	= userBaseInfo.nickName,
		roomid 		= roomId,
		profit 		= 0,
		willprofit	= willProfit, -- 只有机器人才存在这个参数
	}

	-- 存档
	SaveRankInfo(rankInfo)

	return rankInfo
end

-- 存档排行榜数据
function SaveRankInfo(userRankInfo)
	unilight.savedata("chehangrank", userRankInfo)
end

-- 清空排行榜数据 
function ClearRankInfo()
	unilight.cleardb("chehangrank")
end

-- 更新排行榜数据
function UpdateRankInfo(roomId, uid, profit)
	local userRankInfo = GetUserRankInfo(roomId, uid)
	userRankInfo.profit = userRankInfo.profit + profit
	-- 存档
	SaveRankInfo(userRankInfo)
end

-- 重置排行榜数据 (由于需要加入机器人数据 所以每当我们清掉排行榜数据的时候 都会重新添加上一份 机器人的计划数据)
function ResetRankInfo()
	-- 清空数据
	ClearRankInfo()

	-- 添加机器人计划
	CreateRobotRankInfo()

	unilight.info("重置排行榜数据成功")
end

-- 检测指定时间是否在排行榜开启时间(这里会做清空排行榜的操作 获取排行榜数据时、游戏结算时 都会检测 )
function CheckRankOpenTime()
	local ret, startTime, endTime, nextStartTime, nextEndTime, rankCtr = ChessGmCheHangRankMgr.GetRankOpenTime()
	if ret then
		local curTime = os.time()

		if startTime ~= nil and endTime ~= nil and curTime >= startTime and curTime <= endTime then
			-- 当前正在排行榜活动时间中
			return 0, startTime, endTime, nextStartTime, nextEndTime
		else
			if nextStartTime ~= nil and nextEndTime ~= nil and curTime >= nextStartTime and curTime <= nextEndTime then
				-- 当前到达新排行榜开启了 则 重置老排行榜数据
				ResetRankInfo()

				-- 把下期时间 转移 到当前时间 中 然后把下期时间清空
				rankCtr.starttime 	= rankCtr.nextstarttime
				rankCtr.endtime 	= rankCtr.nextendtime
				rankCtr.nextstarttime 	= nil
				rankCtr.nextendtime 	= nil

				-- 存档
				ChessGmCheHangRankMgr.SaveRankCtr(rankCtr)

				return 0, rankCtr.starttime, rankCtr.endtime
			else
				-- 当前不在排行榜时间段内
				return 2, startTime, endTime, nextStartTime, nextEndTime
			end
		end
	end
	-- 排行榜从未开启过 1480492101   1480492200 1480491600 
	return 1
end

-- 通过key 获取指定玩家排行榜数据
function GetUserRankInfo(roomId, uid)
	local key = GetRankKeyByRoomIdUid(roomId, uid)
	local rankInfo = unilight.getdata("chehangrank", key)

	if rankInfo == nil then
		rankInfo = InitUserRankInfo(roomId, uid, key)
	end

	return rankInfo
end

-- 组装前端需要的排行榜数据
function HandleRankInfoList(rankDatas)
	local rankInfoList ={}
	for i,rankData in ipairs(rankDatas) do
		local rankInfo = {
			id 		= i, 
			uid 	= rankData.uid,
			nickName= rankData.nickname, 
			profit 	= rankData.profit,
		}
		table.insert(rankInfoList, rankInfo)
	end
	return rankInfoList
end

-- 获取排行榜列表
function GetRankInfoList(roomId)
	-- 检测当前是否在活动开启时间 如果当前在活动时间内 函数内部会清除老的排行榜数据
	local ret, startTime, endTime, nextStartTime, nextEndTime = CheckRankOpenTime()

	if ret ~= 1 then
		-- 获取当前排行榜数据
		local filter = unilight.a(unilight.eq("roomid", roomId))
		local rankDatas = unilight.chainResponseSequence(unilight.startChain().Table("chehangrank").Filter(filter).OrderBy(unilight.desc("profit")).Limit(RANK_USER_NBR))
		
		-- 其中某些数据 前端 时不需要的 所以自己整理一下
		local rankInfoList = HandleRankInfoList(rankDatas)

		return 0, "获取排行榜成功", startTime, endTime, nextStartTime, nextEndTime, rankInfoList
	else
		return 2, "排行榜未开启"
	end
end


---------------------------------排行榜机器人模拟数据-------------------------------------
-- 添加机器人计划
function CreateRobotRankInfo()
	if RobotMgr.RobotOn == false then
		return
	end
	-- 获取参与机器人计划所需的所有机器人
	local allRobotNbr = (RANK_ROBOT_NBR_MILLION + RANK_ROBOT_NBR_HUNDRED_MILLION + RANK_ROBOT_NBR_TEN_MILLION) * table.len(RoomMgr.MapRoom)

	local allRobots   = chessutil.RandNNumbers(#TableRobotUserInfo, allRobotNbr) 
	local index = 1

	-- 所有房间都需要加上机器人排行榜计划
	for roomId,roomInfo in pairs(RoomMgr.MapRoom) do
		-- 百万级
		for i=1,RANK_ROBOT_NBR_MILLION do
			local willProfit = math.random(1000000, 10000000)
			local uid = TableRobotUserInfo[allRobots[index]].uid
			local key = GetRankKeyByRoomIdUid(roomId, uid)	
			InitUserRankInfo(roomId, uid, key, willProfit)
			index = index + 1
		end
		-- 千万级
		for i=1,RANK_ROBOT_NBR_TEN_MILLION do
			local willProfit = math.random(10000000, 100000000)
			local uid = TableRobotUserInfo[allRobots[index]].uid
			local key = GetRankKeyByRoomIdUid(roomId, uid)	
			InitUserRankInfo(roomId, uid, key, willProfit)
			index = index + 1
		end
		-- 亿级
		for i=1,RANK_ROBOT_NBR_HUNDRED_MILLION do
			local willProfit = math.random(100000000, 500000000)
			local uid = TableRobotUserInfo[allRobots[index]].uid
			local key = GetRankKeyByRoomIdUid(roomId, uid)	
			InitUserRankInfo(roomId, uid, key, willProfit)
			index = index + 1
		end		
	end
end

-- 获取指定房间内的机器人排行榜数据
function GetRobotRankInfoByRoomId(roomId)
	local filter = unilight.a(unilight.eq("roomid", roomId), unilight.gt("willprofit", 0))
	local robotRankInfos = unilight.chainResponseSequence(unilight.startChain().Table("chehangrank").Filter(filter))
	return robotRankInfos
end

-- 指定房间内的机器人 根据目标计划 进行profit变动
function UpdateRobotRankInfo(roomId)
	-- unilight.info("*********0:" .. roomId)
	local robotRankInfos = GetRobotRankInfoByRoomId(roomId)

	-- unilight.info("********1：" .. table.tostring(robotRankInfos))
	-- 机器人根据计划进行变动
	for i,robotRankInfo in ipairs(robotRankInfos) do
		-- unilight.info("********2")

		-- 如果已经在计划值 附近 则不用变动了(附近暂时定义为 2% 范围内)
		if math.abs(robotRankInfo.profit - robotRankInfo.willprofit) > robotRankInfo.willprofit*0.02 then
			-- unilight.info("********3")
			local random = math.random(1, 10)

			-- 每局输赢也控制在 2% 左右 (w为单位)
			local profit = robotRankInfo.willprofit * math.random(15, 25) / 1000
			profit = math.ceil(profit/10000)*10000

			if robotRankInfo.profit > robotRankInfo.willprofit then
				-- unilight.info("********4")
				-- 要输 7输 3赢
				if random <= 7 then
					-- unilight.info("********5")
					robotRankInfo.profit = robotRankInfo.profit - profit
				else
					-- unilight.info("********6")
					robotRankInfo.profit = robotRankInfo.profit + profit
				end
			else
				-- unilight.info("********7")
				-- 要赢 3输 7赢
				if random <= 3 then
					-- unilight.info("********8")
					robotRankInfo.profit = robotRankInfo.profit - profit
				else
					-- unilight.info("********9")
					robotRankInfo.profit = robotRankInfo.profit + profit
				end
			end
			-- unilight.info("********10")

			-- 存档
			SaveRankInfo(robotRankInfo)
		end
		-- unilight.info("********11")
	end
	-- unilight.info("********12")
end