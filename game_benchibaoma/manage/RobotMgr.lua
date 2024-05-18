module('RobotMgr', package.seeall)
RobotOn 		= true 		-- 用于控制 机器人是否开启

RobotRoom 		= {}   		-- 通过房间id 		索引 里面的所有机器人相关信息
RobotUid2Room 	= {}		-- 通过机器人uid 	索引 其id 及 是否 busy 
MapAllBetInfo 	= {} 		-- 用于存储模拟投注数据 roomid --> info {betReq, index, all}

MapRobotRandomBankerNbr= {}	-- 当前局 机器人上庄个数 （每局投注开始时 会随机 1--10 但 如果当前上庄个数 大于随机值时 并不会对机器人进行下庄）

USER_BANKER_ROBOT_BET_CHIPS = 200000000 	-- 玩家坐庄时 机器人
GM_BANKER_ROBOT_BET_CHIPS 	= 200000000 	-- 系统坐庄时 机器人


-----------------------------------初始化-------------------------------
function Init()
	if RobotOn ~= true then
		return 
	end

	-- 把表格中的机器人 随机初始化 并 索引 至 RobotUid2Room
	for i, userInfo in ipairs(TableRobotUserInfo) do
		RobotUid2Room[userInfo.uid] = {
			id = i,
			bBusy = false,
		} 

		userInfo.headurl 		= chessuserinfodb.RandomIcon() 
		userInfo.bankerchips 	= 0
		userInfo.chips 			= 0
		userInfo.giftCoupon 	= math.random(1,1000)
	end

	-- 统一管理 所有房间内的 机器人相关信息
	local roomCfg = chessroominfodb.GetRoomAllInfo(go.gamezone.Gameid)
	for i, v in ipairs(roomCfg) do
		RobotRoom[v.roomId] = {
			roomId 				= v.roomId,
			roomStock 			= v,
			robotBetAll 		= 0,
			robotUid 			= {},
			robotNbr 			= 0,		-- 房间内 机器人总数
			robotBankerNbr 		= 0,		-- 房间内 申请上庄的机器人总数
			robotBet 			= {},
			bBeginBet 			= false,	-- 机器人 是否开始投注(投注提前结束时 置false)
			tickTime 			= 0,		-- 本局 时间滴答
			robotBetTickTime 	= 0,		-- 本局 机器人 从哪个时间点 开始下注
			timeIndex 			= 0, 		-- 用于标记 没到10表示一秒
		}
	end
end
-------------------------------数据获取、操作处理-----------------------
-- 检测该uid是否为机器人
function IsRobot(uid)
	if uid == 0 then
		return true
	end
	if RobotUid2Room[uid] == nil then
		return false
	end
	return true
end

-- 通过机器人uid 获取到其所有信息（索引后 读表）
function GetRobotInfo(uid)
	if RobotUid2Room[uid] == nil then
		unilight.error("GetRobotInfo(uid) is nill" .. uid)
		return nil
	end
	local userInfo = TableRobotUserInfo[RobotUid2Room[uid].id]
	return userInfo
end

-- 通过机器人uid 获取到机器人当前筹码
function GetRobotChips(uid)
	local robotInfo = GetRobotInfo(uid)
	if robotInfo ~= nil then
		return robotInfo.chips
	end
end

-- 修改指定uid机器人的 筹码 及 上庄筹码(int型)
function ChangeRobotChips(uid, chips, bankerChips)
	chips 		= chips or 0
	bankerChips = bankerChips or 0
	if RobotUid2Room[uid] == nil then
		unilight.error("GetRobotInfo(uid) is nill" .. uid)
		return nil
	end
	local userInfo = TableRobotUserInfo[RobotUid2Room[uid].id]
	userInfo.chips = userInfo.chips + chips
	userInfo.bankerchips = userInfo.bankerchips + bankerChips 
	return userInfo
end

-- 获取一个空闲的机器人(bRobot 为true 的时候 表示 该机器人 进入后 还会申请上庄)
function GetLeisureRobot(roomId, bRobot)
	local index = 1 
	local uid = 0
	local time = os.time()

	while true do
		local id = math.random(1, #TableRobotUserInfo)
		local userInfo = TableRobotUserInfo[id]	
		uid = userInfo.uid
		if RobotUid2Room[uid].bBusy == false then
			RobotUid2Room[uid].bBusy = true
			RobotUid2Room[uid].roomId = roomId
			local leaveTime = time
			-- 需要进行上庄申请的机器人 待在房间的时间长一点 并保证上庄筹码足够
			if bRobot then
				leaveTime = leaveTime + math.random(200, 400)

				-- 如果该机器人进入后 需要申请上庄的 则需要保证上庄筹码足够上庄
				userInfo.bankerchips = math.random(TableBankerConfig[1].chips, 200000000)
				userInfo.bankerchips = userInfo.bankerchips - userInfo.bankerchips%100
			else
				leaveTime = leaveTime + math.random(120, 240)
			end

			-- 每次机器人进入 均重新分配筹码 2亿到4亿
			userInfo.chips = math.random(200000000, 400000000)
			
			RobotRoom[roomId].robotUid[uid] = {
				leaveTime = leaveTime,
				bRobot = bRobot,
			} 
			RobotRoom[roomId].robotNbr = RobotRoom[roomId].robotNbr + 1
			return uid 
		end
		if index > 1000 then
			unilight.error("找了一千次机器人，既然都没有找到，可能不够用，或者有bug")
			return uid 
		end
		index = index + 1
	end
	return uid
end

-- 将一个机器人设置为空闲
function ResetRobot(uid) 
	if RobotUid2Room[uid] == nil then
		unilight.error("设置为空闲的机器人为null" .. uid)
		return false
	end
	local roomId = RobotUid2Room[uid].roomId
	RobotUid2Room[uid].bBusy = false
	RobotUid2Room[uid].roomId = nil
	RobotRoom[roomId].robotUid[uid] = nil
	RobotRoom[roomId].robotNbr = RobotRoom[roomId].robotNbr - 1
end

-- 下次牌局开始时 当前不符合筹码要求的机器人离开房间
function CheckRobotChips(roomId, bankerUid)
	if RobotOn == false then
		return 
	end
	local robotRoom = RobotRoom[roomId]
	for uid, userInfo in pairs(robotRoom.robotUid) do
		if uid ~= bankerUid then
			local chips = GetRobotChips(uid)
			if chips < 40000000 then
				RoomMgr.RobotLeaveRoom(uid, roomId)	
			end
		end
	end
end

---------------------------------机器人流程------------------------------
-- 机器人控制 0.1秒 轮询时钟 操作 所有房间
function RobotTime()
	for roomId, roomInfo in pairs(RobotRoom) do
		RobotControlRoom(roomInfo)
	end
end

-- 指定房间 的 所有机器人相关操作控制  进出、下注、上庄
function RobotControlRoom(roomInfo)
	-- 整秒 操作进出房间 上下庄
	if roomInfo.timeIndex == 0 then
		RobotControlNumber(roomInfo)
		RobotControlBanker(roomInfo)
	end
	roomInfo.timeIndex = roomInfo.timeIndex + 1 
	if roomInfo.timeIndex == 10 then
		roomInfo.timeIndex = 0
	end

	-- 0.1秒 操作一次投注
	RobotControlBet(roomInfo)

	-- 前面投注 不会实时广播 汇总在此处 广播一个list(真实玩家 现在实时广播 不汇总)
	RoomMgr.SendBetBrd(roomInfo.roomId)
end

-- 机器人进出 控制
function RobotControlNumber(roomInfo)
	local time = os.time()
	local roomStock = roomInfo.roomStock	
	local roomId = roomInfo.roomId
	local robotNbr = 6
	local robotRandomNbr = math.random(robotNbr, 1.5*robotNbr)

	-- 如果房间中的实际机器人个数 小于 当前随机出来的机器人个数 则 再进去一个
	if roomInfo.robotNbr < robotRandomNbr then
		local uid = GetLeisureRobot(roomInfo.roomId, false)
		-- 机器人进入房间
		RoomMgr.RobotEnterRoom(uid, roomId)	
	end
	-- 检测什么时候离开
	for uid, userInfo in pairs(roomInfo.robotUid) do
		local leaveTime = userInfo.leaveTime 
		if leaveTime < time then
			RoomMgr.RobotLeaveRoom(uid, roomId)	
		end
	end
end
 
-- 机器人下注 控制
function RobotControlBet(roomInfo)
	if roomInfo.bBeginBet == false then
		return 
	end
	local roomId = roomInfo.roomId

	-- 每局游戏 第一次进入 则随机一个总投注数据
	if roomInfo.tickTime == 0 then
		-- 如果 不是系统上庄 则获取可下注金额上限（机器人 等同真实玩家处理）
		local bankerUid = RoomMgr.MapRoom[roomId].betInfo.bankerInfo.uid
		MapAllBetInfo[roomId] = {
			betReq = CreateSimulatedBet(bankerUid),							-- 整个投注 需投注的 所有筹码
			index  = 0,														-- 当前已经投注到哪一个了
		}
		MapAllBetInfo[roomId].all = table.len(MapAllBetInfo[roomId].betReq)	-- 投注筹码总个数
	end

	roomInfo.tickTime = roomInfo.tickTime + 1
	-- 未到时间不下 最后两秒也不下 
	if roomInfo.tickTime < roomInfo.robotBetTickTime or roomInfo.tickTime > (RoomMgr.ENUM_GAME_TIME.BET - 2) * 10 then
		return
	end

	local allBetInfo = MapAllBetInfo[roomId]

	-- 剩余可下注时间 (多少个0.1秒 以0.1秒为单位)  --lbx 最后两秒不下了
	local remainderTime = (RoomMgr.ENUM_GAME_TIME.BET - 2) * 10 - roomInfo.tickTime + 1 

	-- 还需下注个数(已经下完 该局该下的所有筹码 则返回)
	local betTimes = allBetInfo.all - allBetInfo.index
	if betTimes <= 0 then
		roomInfo.bBeginBet = false
		unilight.info("已提前完成下注任务 直接返回")
		return 
	end

	-- 当前秒数 下注 这么多个即可
	local nowBetTimes = math.ceil(betTimes/remainderTime)
	-- 当前时刻 已经下了多少个筹码 如果大于nowBetTimes 则该时刻 不再下注
	local nowAlreadyBetTimes = 0

	-- 当前可下注机器人总数(只要不是庄家 即可下注)
	local bankerUid = RoomMgr.MapRoom[roomId].betInfo.bankerInfo.uid
	local robotNbr = 0
	for uid, v in pairs(roomInfo.robotUid) do
		if uid ~= bankerUid then
			robotNbr = robotNbr + 1
		end
	end

	if robotNbr == 0 then
		unilight.info("当前房间内 不存在非庄机器人 不能模拟投注")
		return 
	end

	-- 当前每个机器人 只需投注 这个多个筹码 即可 	-- 个数乘4 机器人出手概率4分之1  
	local whichBetTimes = math.ceil(nowBetTimes/robotNbr) * 4 


	-- unilight.info("当前还需要下几个筹码：" .. betTimes)
	-- unilight.info("当前还剩多少个0.1秒：" .. remainderTime)
	-- unilight.info("当前时刻下注这么多个即可：" .. nowBetTimes)
	-- unilight.info("当前时刻可下注机器人个数：" .. robotNbr)
	-- unilight.info("当前时刻下注这么多个即可：" .. whichBetTimes)

	-- 开始正式下注
	local len = table.len(roomInfo.robotUid)
	for uid, v in pairs(roomInfo.robotUid) do
		if uid ~= bankerUid then
			-- 检测是否已经下注结束了
			if allBetInfo.index + 1 > allBetInfo.all then
				-- unilight.info("当前局 模拟下注已结束")
				break
			end
			-- 检测当前时刻 需要投注的总数nowBetTimes 是否已经下够了 如果够了 其他机器人就不下了 下一时刻再来
			if nowAlreadyBetTimes >= nowBetTimes then
				-- unilight.info("当前时刻 模拟下注已结束")
				break
			end

			-- 调节机器人出手的概率 
			if math.random(1, 8*len) == 1 then
				local head = allBetInfo.index + 1
				local tail = allBetInfo.index + math.random(1, 2*whichBetTimes-1)

				-- 获取下注数据
				local betReq = table.slice(allBetInfo.betReq,head,tail)

				-- 检测 这批投注 能否正常下出去 是否超过 庄家上庄筹码限制
				local willBetAll = 0
				local maxCouldBet= RoomMgr.MapRoom[roomId].maxCouldBet
				local allBet 	 = RoomMgr.MapRoom[roomId].lotteryInfo.allBetAll
				local robotBet   = roomInfo.robotBet[uid] or {}
				local robotBetAll= 0
				
				-- 汇总该机器人 该局已经下注了多少筹码
				for i,v in pairs(robotBet) do
					robotBetAll = robotBetAll + v
				end

				-- 获取当前机器人的信息
				local robotInfo = GetRobotInfo(uid)
				
				-- 下注
				local betRes = RoomMgr.RobotBetReq(uid, roomId, betReq)
				if table.empty(betRes) == false then
					for i, v in ipairs(betRes) do
						roomInfo.robotBetAll = roomInfo.robotBetAll + v.chips						
						roomInfo.robotBet[uid] = roomInfo.robotBet[uid] or {} 
						roomInfo.robotBet[uid][v.betId] = roomInfo.robotBet[uid][v.betId] or 0
						roomInfo.robotBet[uid][v.betId] = roomInfo.robotBet[uid][v.betId] + v.chips 
					end
				end

				-- index 记录
				allBetInfo.index = tail
				nowAlreadyBetTimes = nowAlreadyBetTimes + whichBetTimes		
			end
		end
	end
end

-- 机器人上庄 控制
function RobotControlBanker(roomInfo)
	local roomId = roomInfo.roomId
	local RobotRandomBankerNbr = MapRobotRandomBankerNbr[roomId] or 1
	if roomInfo.robotBankerNbr < RobotRandomBankerNbr then
		roomInfo.robotBankerNbr = roomInfo.robotBankerNbr + 1
		local uid = GetLeisureRobot(roomInfo.roomId, true)
		RoomMgr.RobotEnterRoom(uid, roomId)	
		local bOk, index = BankerRoomMgr.UserApply(roomId, uid)
		if bOk == true then
			local userInfo = GetRobotInfo(uid)
			local bankerInfo = {
				uid = uid,
				bankerChips = userInfo.bankerchips, 
				headUrl = userInfo.headurl,
				nickName = userInfo.nickname,
				index = index,
				bankerNbr = 0,
			}
			local doInfo = "Cmd.ApplyBankerRoomCmd_Brd"
			local doData = {
				bankerInfo = bankerInfo,
			}
			RoomMgr.CmdMsgBrd(doInfo, doData, roomId)
			unilight.debug("机器人申请上庄成功：" .. uid)
		end
	end
end

--------------------------------机器人 模拟投注 -----------------------------
-- 获取机器人投注方案
function GetRobotWillBet(bankerUid)
	local willBet = {}

	if bankerUid ~= 0 then
		-- 玩家、机器人坐庄
		local robotBetChipsAll 	= USER_BANKER_ROBOT_BET_CHIPS * math.random(0.8, 1.2)

		-- 为每个位置分配投注金额
		local pos = chessutil.RandNNumbers(4, 4) 
		local all = 1000

		local temp1 = math.random(270, 290)	 
		local temp2 = math.random(270, 290)		
		local temp3 = math.random(100, 120)	
		local temp4 = math.random(100, 120)	-- 前四个 随机分配给 5倍的位置
		local temp5 = math.random(20, 30)		-- 大保时捷
		local temp6 = math.random(30, 50)		-- 大宝马
		local temp7 = math.random(30, 50)		-- 大奥迪
		local temp8 = all - temp1 - temp2 - temp3 - temp4 - temp5 - temp6 - temp7

		willBet[pos[1]*2] = temp1 / 1000 * robotBetChipsAll
		willBet[pos[2]*2] = temp2 / 1000 * robotBetChipsAll
		willBet[pos[3]*2] = temp3 / 1000 * robotBetChipsAll
		willBet[pos[4]*2] = temp4 / 1000 * robotBetChipsAll
		willBet[1] = temp5 / 1000 * robotBetChipsAll
		willBet[3] = temp6 / 1000 * robotBetChipsAll
		willBet[5] = temp7 / 1000 * robotBetChipsAll
		willBet[7] = temp8 / 1000 * robotBetChipsAll
	else
		-- 系统坐庄（系统坐庄 随机可以比较随便 随机值temp1+++temp8>1000 也无所谓）
		local robotBetChipsAll = GM_BANKER_ROBOT_BET_CHIPS * math.random(0.8, 1.2)

		-- 为每个位置分配投注金额
		local pos = chessutil.RandNNumbers(4, 4) 
		local all = 1000

		local temp1 = math.random(190, 210)	 
		local temp2 = math.random(190, 210)		
		local temp3 = math.random(190, 210)	
		local temp4 = math.random(190, 210)	-- 前四个 随机分配给 5倍的位置 均在百分之二十左右随机
		local temp5 = math.random(40, 60)		-- 大保时捷
		local temp6 = math.random(40, 60)		-- 大宝马
		local temp7 = math.random(40, 60)		-- 大奥迪
		local temp8 = math.random(40, 60)		-- 大大众 后面四个均在百分之5左右随机 

		willBet[2] = temp1 / 1000 * robotBetChipsAll
		willBet[4] = temp2 / 1000 * robotBetChipsAll
		willBet[6] = temp3 / 1000 * robotBetChipsAll
		willBet[8] = temp4 / 1000 * robotBetChipsAll
		willBet[1] = temp5 / 1000 * robotBetChipsAll
		willBet[3] = temp6 / 1000 * robotBetChipsAll
		willBet[5] = temp7 / 1000 * robotBetChipsAll
		willBet[7] = temp8 / 1000 * robotBetChipsAll
	end
	return willBet
end

-- 生成投注数据 如果为玩家上庄 则传入总投注上限
function CreateSimulatedBet(bankerUid)
	local betReq = {}
	local willBet = GetRobotWillBet(bankerUid)
	for i,v in ipairs(willBet) do
		local bet = v
		while true do
			if bet > 1000000 then
				local temp1 = math.ceil((bet - 1000000)/1000000)
				HandleSimulatedBet(betReq, temp1, i, 1000000)
				bet = bet - temp1*1000000					
			elseif bet > 500000 then
				local temp2 = math.ceil((bet - 500000)/500000)
				HandleSimulatedBet(betReq, temp2, i, 500000)
				bet = bet - temp2*500000
			elseif bet > 100000 then
				local temp3 = math.ceil((bet - 100000)/100000)
				HandleSimulatedBet(betReq, temp3, i, 100000)
				bet = bet - temp3*100000
			elseif bet > 10000 then
				local temp4 = math.ceil(bet/10000)
				HandleSimulatedBet(betReq, temp4, i, 10000)
				break			
			else
				break
			end
		end	
	end
	-- 打乱一下次序 
	math.shuffle(betReq)

	return betReq
end

-- 模拟投注 整合
function HandleSimulatedBet(betReq, nbr, betId, chips)
	for i=1,nbr do
		local betItem = {
			betId = betId,
			chips = chips			
		}
		table.insert(betReq, betItem)	
	end
	return betReq
end

--------------------------------机器人 开启、关闭----------------------------
-- 开始下注时  房间机器人相关信息重置 机器人 允许下注
function RobotResetBegin(roomId, roomStock)
	if RobotOn ~= true then
		return 
	end
	if RobotRoom[roomId] == nil then
		return 
	end
	
	local roomInfo = RobotRoom[roomId]
	roomInfo.bBeginBet 				= true
	roomInfo.robotBetAll 			= 0
	roomInfo.robotBet 				= {}
	roomInfo.roomStock 				= roomStock
	roomInfo.tickTime 				= 0
	roomInfo.robotBetTickTime 		= math.random(10, 20)
	roomInfo.timeIndex 				= 0
	MapRobotRandomBankerNbr[roomId] = math.random(1, 3)
end

function RoomRobotEnd(roomId)
	if RobotOn ~= true then
		return 
	end
	if RobotRoom[roomId] == nil then
		unilight.error("room is  NULL " .. roomId)
		return 
	end
	local roomInfo = RobotRoom[roomId]
	roomInfo.bBeginBet = false
end
