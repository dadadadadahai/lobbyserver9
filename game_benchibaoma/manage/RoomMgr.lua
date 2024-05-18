module('RoomMgr', package.seeall)
-- 房间公共信息存储

-- 房间游戏状态
ENUM_GAME_STATUS = {
	FREE	= 1, 	-- 空闲
	BET 	= 2, 	-- 下注
	LTY 	= 3, 	-- 开奖
}

-- 游戏流程时间
ENUM_GAME_TIME = {
	FREE	= 3, 	-- 空闲时间
	BET 	= 20, 	-- 下注时间
	LTY 	= 18, 	-- 开奖时间
}

-- 常量用于 获取枚举状态 打印日志
Status = {"空闲时间","下注时间","开奖时间"}

-- 游戏重新开始时候 重新获取庄家 庄家下庄原因列表
ENUM_BANKER_DOWN_RES = {
	IS_TEN  = 1,	-- 已经十局了
	NO_CHIP = 2,	-- 筹码不足
	IS_ACT	= 3, 	-- 主动下庄 
}

RoundId = 0 		-- 全局唯一牌局id

-- 风驰需求下庄折扣
BANKER_DOWN_RATE 	= 0.75

-- 用来处理游戏房间内部数据
MapUid2Room 	= {} 	-- uid->room
MapRoom 		= {} 	-- room uid
MapRoomSeat2uid = {} 	-- 玩家对应房间坐位映射关系（暂时 没有 预留）

BetBrdInfo		= {}	-- 真实玩家投注广播消息 不即时响应 汇总到0.25秒 跟机器人 一起发出去

TempBankChips 	= {}	-- 用于临时标记该玩家 将以多少筹码上庄  uid -- chips 

-----------------------------------初始化-------------------------------
function Init()
	local roomCfg = chessroominfodb.GetRoomAllInfo(go.gamezone.Gameid)
	for i, v in ipairs(roomCfg) do
		MapRoom[v.roomId] = {
			-- 房间的需要存储的信息
			roomId 		= v.roomId,
			roomStock 	= v,
			status 		= ENUM_GAME_STATUS.FREE,	-- 默认在空闲状态
			gmControl 	= nil,						-- GM控制牌面生成 (值为 id)
			betInfo = {
				userBet 	= {}, 					-- 所有玩家下注情况 	通过uid索引到 指定玩家的下注情况
				robotBet 	= {}, 					-- 所有机器人下注情况
				bankerInfo 	= {
					uid 		= 0,
					bankerChips = 0,
				},
			},
			lotteryInfo = {
				history 		= {},
				userBetAll 		= {}, 				-- 所有汇总后的下注情况
				robotBetAll 	= {},
				allBetAll 		= {},  				-- 所有玩家共同下注情况
				bankerChipsAll 	= 0,
			},
			brdInfo 	= {}, 	 					-- 开奖时 把结算信息缓存起来 结算时发送出去
			roomUser 	= {},						-- {uid:1}
			roomRobot 	= {},						-- {uid:1}
			timeTick 	= os.time(),
			bankruptInfo = nil,						-- 破产信息缓存
		}

		-- 历史记录 前端要求 初始化时随便给20个
		for i=1,20 do
			table.insert(MapRoom[v.roomId].lotteryInfo.history, math.random(1, 8))
		end

		MapRoomSeat2uid[v.roomId] = {}

		unilight.info("开启房间" .. v.roomId)

		-- 初始化投注广播信息
		BetBrdInfo[v.roomId] = {}
	end	
	
	-- 服务器开启 即开启一个 1秒 轮询时钟
	unilight.addtimer("RoomMgr.OnTimer", 1)

	-- 房间初始化完成后 开启机器人 0.1秒轮询时钟
	if RobotMgr.RobotOn then
		unilight.addtimermsec("RobotMgr.RobotTime", 100)
	end	
end
-------------------------------数据获取、操作处理-----------------------

-- 查看指定玩家的房间id
function GetRoomId(uid)
	if MapUid2Room[uid] ~= nil then
		local info = MapUid2Room[uid]
		return info.roomId, info.laccount, info.seatId, info.bRobot
	end
	return nil	
end

-- 检测指定玩家是否为庄家
function IsBanker(uid)
	local bBanker = false
	for roomId, roomInfo in pairs(MapRoom) do
		if roomInfo.betInfo.bankerInfo.uid == uid then
			bBanker = true
			break
		end
	end
	return bBanker
end

-- 判断是否可进入此房间
function CheckCouldEnter(uid, roomId)
	local roomInfo = MapRoom[roomId]
	if roomInfo == nil then
		unilight.info("玩家uid" .. uid .."   进入的roomId不存在" .. roomId)
		return false
	end	
	return true
end

-- 通过uid来组装成玩家进入房间基本信息
function GetUserRoomInfo(uid)
	local roomId, laccout, seatId, bRobot = GetRoomId(uid)
	local roomUser = {}
	-- 真实玩家
	if bRobot == false then
		local userInfo = chessuserinfodb.RUserInfoGet(uid)
		if userInfo == nil then
			unilight.error("uid is null " .. uid)
		end
		roomUser = {
			uid 		= uid,
			headUrl 	= userInfo.base.headurl,
			nickName 	= userInfo.base.nickname,
			roomId 		= roomId,
			seatId 		= seatId,
			remainder 	= userInfo.property.chips,
			gender 		= userInfo.base.gender,
			giftCoupon 	= userInfo.property.giftCoupon,
			signature 	= userInfo.base.signature,
            bankerChips = userInfo.property.bankerchips,
		}

	-- 机器人
	else
		local userInfo = RobotMgr.GetRobotInfo(uid)
		roomUser = {
			uid 		= uid,
			headUrl 	= userInfo.headurl,
			nickName 	= userInfo.nickname,
			roomId 		= roomId,
			seatId 		= seatId,
			remainder 	= userInfo.chips,
			gender 		= userInfo.gender,
			giftCoupon 	= userInfo.giftCoupon,
			signature 	= userInfo.signature or "",
		}
	end
	return roomUser	
end

-- 玩家进入时 获取当前房间的各类信息 返回给该玩家
function GetRoomStatus(roomInfo)
	local roomId = roomInfo.roomId
	--房间状态获取
	local roomStatus = roomInfo.status
	-- 当前状态剩余时间
	local remainderTime = 0
	local allTime 		= 0
	-- 当前状态已过去多久
	local passTime = os.time() - roomInfo.timeTick

	if roomStatus == ENUM_GAME_STATUS.FREE then
		remainderTime = ENUM_GAME_TIME.FREE - passTime
		allTime = ENUM_GAME_TIME.FREE	
	elseif roomStatus == ENUM_GAME_STATUS.BET then
		remainderTime = ENUM_GAME_TIME.BET - passTime
		allTime = ENUM_GAME_TIME.BET	
	elseif roomStatus == ENUM_GAME_STATUS.LTY then
		remainderTime = ENUM_GAME_TIME.LTY - passTime
		allTime = ENUM_GAME_TIME.LTY	
	end

	-- 当前房间信息
	local curRoomInfo = {
		roomStatus 		= roomStatus,
		remainderTime 	= remainderTime,
		allTime 		= allTime,
	}
	
	-- 当前房间投注信息
	local curRoomBet = {}
	for i, v in pairs (roomInfo.lotteryInfo.allBetAll) do
		local betItem = {
			betId = i,
			chips = v,
		}
		table.insert(curRoomBet, betItem)
	end

	local curBankerInfo  	= roomInfo.betInfo.bankerInfo
	local lotteryHistorys 	= roomInfo.lotteryInfo.history
	local bankerList 		= RoomMgr.GetBankerList(roomId)

	return curRoomInfo, curRoomBet, curBankerInfo, lotteryHistorys, bankerList
end

-- 获取房间内所有玩家的Uid
function GetRoomUserUid(roomId)
	local roomInfo = MapRoom[roomId]	
	if roomInfo == nil then
		unilight.error("GetRoomUserUid is nill ")
		return nil
	end
	local user = {}
	for uid, _ in pairs(roomInfo.roomUser) do
		table.insert(user, uid)
	end
	for uid, _ in pairs(roomInfo.roomRobot) do
		table.insert(user, uid)
	end
	return user
end

-- 获取庄家详细信息
function GetBankerList(roomId)
	local bOk, bankerList = BankerRoomMgr.GetBankerList(roomId)
	local bankerInfo = {}
	if bOk == true then
		for _, v in ipairs(bankerList)	do
			local bankerItem = BankerRoomMgr.ConsructBankerInfo(v.uid, v.bankerNbr, v.index)
			table.insert(bankerInfo, bankerItem)
		end
	end
	return bankerInfo
end

-- 最终下注 房间信息修改 
function UserBet(roomId, uid, betId, chips, bRobot)
	local betName = "userBet"
	local betAllName = "userBetAll"
	if bRobot then
		betName = "robotBet"
		betAllName = "robotBetAll"
	end
	local roomInfo = MapRoom[roomId]
	roomInfo.betInfo[betName][uid] = roomInfo.betInfo[betName][uid] or {}
	roomInfo.betInfo[betName][uid][betId] = roomInfo.betInfo[betName][uid][betId] or 0
	roomInfo.betInfo[betName][uid][betId] = roomInfo.betInfo[betName][uid][betId] + chips

	roomInfo.lotteryInfo[betAllName][betId] = roomInfo.lotteryInfo[betAllName][betId] or 0 
	roomInfo.lotteryInfo[betAllName][betId] = roomInfo.lotteryInfo[betAllName][betId] + chips

	roomInfo.lotteryInfo.allBetAll[betId] = roomInfo.lotteryInfo.allBetAll[betId] or 0 
	roomInfo.lotteryInfo.allBetAll[betId] = roomInfo.lotteryInfo.allBetAll[betId] + chips
end

-- 房间总投注信息、该玩家总投注信息 获取
function GetRoomAndUserBet(uid, roomId, bRobot)
	local roomInfo = MapRoom[roomId]
	local roomBet = {}

	for i=1,8 do
		roomInfo.lotteryInfo.userBetAll[i] = roomInfo.lotteryInfo.userBetAll[i] or 0 
		roomInfo.lotteryInfo.robotBetAll[i] = roomInfo.lotteryInfo.robotBetAll[i] or 0 
		local chips = roomInfo.lotteryInfo.userBetAll[i] + roomInfo.lotteryInfo.robotBetAll[i] 
		local betItem = {
			betId = i,
			chips = chips,
		}
		table.insert(roomBet, betItem)
	end
	local userBet = {}
	local BetInfo = {}
	if bRobot == true then
		BetInfo = roomInfo.betInfo.robotBet[uid] or {}
	else
		BetInfo = roomInfo.betInfo.userBet[uid] or {}
	end

	for i=1,8 do
		local chips = BetInfo[i] or 0
		local betItem = {
			betId = i,
			chips = chips,
		}
		table.insert(userBet, betItem)		
	end
	return roomBet, userBet
end

-- 结算前离开房间 筹码返还
function ReturnChips(uid, roomInfo)
	local userBet = roomInfo.betInfo.userBet[uid]
	if userBet == nil or table.len(userBet) == 0 then
		unilight.debug("当前玩家投注期间退出 但该局并未投注：" .. uid)
		return
	end
	-- 汇总需返回的筹码 统一返回
	local returnChips = 0
	for betId, chips in pairs(userBet) do
		if chips > 0 then
			roomInfo.lotteryInfo.userBetAll[betId] 	= roomInfo.lotteryInfo.userBetAll[betId] - chips
			roomInfo.lotteryInfo.allBetAll[betId] 	= roomInfo.lotteryInfo.allBetAll[betId]  - chips
			returnChips = returnChips + chips
		end
	end
	roomInfo.betInfo.userBet[uid] = nil

	-- 给玩家返回筹码
	local remainder = chessuserinfodb.WChipsChange(uid, 1, returnChips, "开奖前离房筹码返还")

	unilight.info("当前玩家投注期间退出 uid:" .. uid ..  " 返回筹码：" .. returnChips .. " 当前筹码：" .. remainder)
	return returnChips, remainder
end

-- 投注0.1秒汇总 发送一次广播
function SendBetBrd(roomId)
	if table.len(BetBrdInfo[roomId]) ~= 0 then
		local doInfo = "Cmd.BetListRoomCmd_Brd"

		local roomInfo = MapRoom[roomId]
		local roomBet  = {}
		local tempRoomBet = {}
		local isBet = {}

		-- 获取当前 房间总投注数据
		for i=1,8 do
			roomInfo.lotteryInfo.userBetAll[i] = roomInfo.lotteryInfo.userBetAll[i] or 0 
			roomInfo.lotteryInfo.robotBetAll[i] = roomInfo.lotteryInfo.robotBetAll[i] or 0 
			local chips = roomInfo.lotteryInfo.userBetAll[i] + roomInfo.lotteryInfo.robotBetAll[i] 
			local betItem = {
				betId = i,
				chips = chips,
			}
			table.insert(tempRoomBet, betItem)
		end

		-- 检测一下 哪些位置有投注
		for i,v in ipairs(BetBrdInfo[roomId]) do
			isBet[v.betId] = true
		end

		-- 有投注的位置 才发送数据
		for i=1,8 do
			if isBet[i] then
				table.insert(roomBet, tempRoomBet[i])
			end
		end

		local doData = {
			betInfoList = BetBrdInfo[roomId],
			roomBet 	= roomBet,
		}
		-- unilight.info("当前广播玩家投注 投注个数：" .. table.len(BetBrdInfo[roomId]))
		-- unilight.info("当前广播玩家投注 投注数据：" .. table.tostring(doData))
		CmdMsgBrd(doInfo, doData, roomId) 
		BetBrdInfo[roomId] = {}	
	end
end

-------------------------------消息请求函数调用-------------------------
-- 玩家进入房间
function EnterRoom(laccount, uid, roomId)
	-- 如果已经进入过房间了 则直接返回该 房间即可
	if MapUid2Room[uid] ~= nil then
		unilight.info("已经进入过房间了 则直接返回该房间 uid:" .. uid)
		local preRoomId = MapUid2Room[uid].roomId
		local preRoomInfo = MapRoom[preRoomId]
		MapUid2Room[uid].isDisconnect = nil
		return GetRoomStatus(preRoomInfo)
	else
		local roomInfo = MapRoom[roomId]

		-- 首个玩家进入房间时 创建指定brdroom 用于广播消息使用
		if roomInfo.BrdRoom == nil then
			roomInfo.BrdRoom = chesstcplib.TcpRoomCreate(laccount)
		end

		-- 玩家信息更新
		chesstcplib.TcpUserRoomIn(roomInfo.BrdRoom, laccount)
		-- MapUid2Room定义
		MapUid2Room[uid] = {
			roomId 		= roomId,	-- 房间id
			laccount 	= laccount,	-- 玩家对象
			bRobot 		= false,	-- 是否为机器人
			seatId 		= nil,		-- 如果玩家坐下了 则为其座位号
			mark 		= 0,  		-- 成绩
		}
		-- 标记该玩家进入该房间了
		roomInfo.roomUser[uid] = 1

		-- 单独返回给玩家 当前房间的 各类信息
		return GetRoomStatus(roomInfo)  	
	end
end

-- 机器人进入房间
function RobotEnterRoom(uid, roomId)
	local roomInfo = MapRoom[roomId]

	roomInfo.roomRobot[uid] = 1
	MapUid2Room[uid] = {
		roomId = roomId,
		bRobot = true,
	}
end

-- 玩家离开房间
function LeaveRoom(uid, isDisconnect)
	local roomId, laccount, seatId = GetRoomId(uid)
	local roomInfo = MapRoom[roomId]
	if table.empty(roomInfo) then
		MapUid2Room[uid] = nil
		return 
	end

	-- 如果玩家只是断线 且 当前在庄上 则保留上庄 只标记下 他断线了	
	if isDisconnect and IsBanker(uid) then
		MapUid2Room[uid].isDisconnect = true 
		return
	end

	-- 如果玩家在投注期间 退出房间  则返还当前局 投注筹码 
	if roomInfo.status == ENUM_GAME_STATUS.BET then
		ReturnChips(uid, roomInfo)
	end

	-- 减去广播
	chesstcplib.TcpUserRoomOut(roomInfo.BrdRoom, laccount)
	roomInfo.roomUser[uid] = nil
	MapUid2Room[uid] = nil

	-- 置空玩家 在大厅的监控数据
	local userData = UserInfo.GetUserDataById(uid)
	IntoGameMgr.ClearUserCurStatus(userData)

	return 0, "离开房间成功"
end

-- 机器人离开房间
function RobotLeaveRoom(uid)
	local roomId, laccount, seatId = GetRoomId(uid)
	
	-- 如果在座位上则先站起
	if seatId ~= nil then
		StandUp(uid)
	end

	-- 当前房间信息
	local roomInfo = MapRoom[roomId]
	if table.empty(roomInfo) then
		MapUid2Room[uid] = nil
		return 
	end

	-- 机器人房间信息
	local robotRoomInfo = RobotMgr.RobotRoom[roomId]
	local userInfo 		= robotRoomInfo.robotUid[uid]
	-- 如果进来时 是以上庄机器人的身份进入的  则出去时 nbr计数 -1
	if userInfo.bRobot == true then
		robotRoomInfo.robotBankerNbr = robotRoomInfo.robotBankerNbr - 1

		-- 如果当前还在上庄列表中 则先下庄
		if BankerRoomMgr.GetUserApplyIndex(roomId, uid) ~= 0 or uid == roomInfo.betInfo.bankerInfo.uid then
			RobotCancelBanker(uid)
		end
	end

	-- delete
	roomInfo.roomRobot[uid] = nil
	MapUid2Room[uid] = nil

	-- 重置机器人信息
	RobotMgr.ResetRobot(uid)
end

-- 玩家下庄处理
function CancelBanker(uid)
	local roomId, laccount, seatId = GetRoomId(uid)
	if roomId ~= nil then
		local bOk = BankerRoomMgr.UserLeave(roomId, uid)
		if bOk == true then
			-- 下庄成功 则把 上庄筹码 给回到 自身筹码中
			if IsBanker(uid) == false then 
				chessuserinfodb.WMoveBankerChipsToChips(uid) 

				-- 前端要求 玩家如果当前在庄上的时候 不需要广播这条消息
				local doInfo = "Cmd.CancelBankerRoomCmd_Brd"
				local doData = {
					uid = uid,
				}
				RoomMgr.CmdMsgBrd(doInfo, doData, roomId)	
			end
			unilight.info("玩家下庄成功,uid:" .. uid)
		end
	else
		unilight.error("玩家下庄失败，该玩家不在房间内 :" .. uid)
	end
end

-- 机器人下庄处理
function RobotCancelBanker(uid)
	local roomId, laccount, seatId = GetRoomId(uid)
	if roomId ~= nil then
		BankerRoomMgr.UserLeave(roomId, uid)
		local doInfo = "Cmd.CancelBankerRoomCmd_Brd"
		local doData = {
			uid = uid,
		}
		RoomMgr.CmdMsgBrd(doInfo, doData, roomId)	
		unilight.debug("机器人下庄成功：" .. uid)
	else
		unilight.error("机器人取消下庄失败，原因找不到roomId  机器人id：" .. uid)
	end
end

-- 玩家申请下注
function BetReq(uid, roomId, betReq)
	local betRes = {}
	local remainder = 0
	local bOk = false
	local roomInfo = MapRoom[roomId]
	local bankerInfo = roomInfo.betInfo.bankerInfo
	local allBet = roomInfo.lotteryInfo.allBetAll
	local userBet = roomInfo.betInfo.userBet[uid] or {}

	-- 如果为重复下注 则 检测全部下去的时候是否正常 如果正常 则直接全下
	if table.len(betReq) > 1 then
		local ret,desc  = LotteryCtl.CheckRepeatBet(uid, betReq, bankerInfo, allBet, userBet)
		-- 重复下注成功 则 直接下注
		if ret == 0 then
			for i, v in ipairs(betReq) do
				local betId = v.betId
				local chips = v.chips
				if chips ~= nil and betId ~= nil and chips > 0 then
					--正确投注位置 1--8 
					if betId>=1 and betId <=8  then
						-- 首先扣钱吧
						remainder, bSubOk = chessuserinfodb.WChipsChange(uid, 2, v.chips)
						if bSubOk == true then
							UserBet(roomId, uid, betId, chips, false)
							-- 返回信息
							table.insert(betRes, v)
							bOk = true
						else
							unilight.debug("玩家扣钱失败" .. uid)
						end
					else
						unilight.error("cmdBetReq: uid:" .. uid .. "   betId:"..betId.." is error")
					end	
				else
					unilight.error("cmdBetReq: uid:" .. uid .. "   betinfo is null")
				end
			end
		else
			unilight.info("重复下注失败")
			return ret, desc
		end
	else
		local bet = betReq[1]
		local betId = bet.betId
		local chips = bet.chips
		if chips ~= nil and betId ~= nil and chips > 0 then
			--正确投注位置 1--8 
			if betId>=1 and betId <=8  then
				-- TODO这里需要考虑是否在可下注范围内
				local bCouldBet = LotteryCtl.CmdCouldBet(betId, chips, bankerInfo, allBet, userBet)
				if bCouldBet then
					-- 首先扣钱吧
					remainder, bSubOk = chessuserinfodb.WChipsChange(uid, 2, bet.chips)
					if bSubOk == true then
						UserBet(roomId, uid, betId, chips, false)
						-- 返回信息
						table.insert(betRes, bet)
						bOk = true
					else
						unilight.debug("玩家扣钱失败" .. uid)
					end
				else
					unilight.debug("受收庄家库存控制，不可以下注" .. uid)
				end
			else
				unilight.error("cmdBetReq: uid:" .. uid .. "   betId:"..betId.." is error")
			end	
		else
			unilight.error("cmdBetReq: uid:" .. uid .. "   betinfo is null")
		end
	end

	if bOk then
		local roomBet, userBet = GetRoomAndUserBet(uid, roomId, false)
		return 0, "投注成功", remainder, betRes, roomBet, userBet
	else
		return 5, "玩家筹码不足或者下注超上限啦～"
	end
end

-- 机器人申请下注（在这里检测 是否能投注 能投一个是一个）
function RobotBetReq(uid, roomId, betReq)
	local roomInfo = MapRoom[roomId]
	local betRes = {}
	local bankerInfo = roomInfo.betInfo.bankerInfo
	local allBet = roomInfo.lotteryInfo.allBetAll

	for i, v in ipairs(betReq) do
		local betId = v.betId
		local chips = v.chips

		local ret = LotteryCtl.CmdCouldBet(betId, chips, bankerInfo, allBet)
		if ret then
			-- 机器人也扣钱
			RobotMgr.ChangeRobotChips(uid, -chips)
			-- 正式投注 并记录在roomInfo中（机器人投注数据维护两份数据 一份在robotInfo中）
			UserBet(roomId, uid, betId, chips, true)
			-- 返回信息
			table.insert(betRes, v)
			
			local roomBet, userBet = GetRoomAndUserBet(uid, roomId, true) 
			local robotInfo = RobotMgr.GetRobotInfo(uid)

			-- 投注缓存起来
			table.insert(RoomMgr.BetBrdInfo[roomId], v)
		end
	end

	return betRes
end

-- 获取历史开奖记录
function GetLotteryInfoHistory(roomId)
	local roomInfo = MapRoom[roomId]
	if roomInfo == nil then
		return 2, "房间id有误：" .. roomId
	end
	return 0, "获取开奖历史记录成功", roomInfo.lotteryInfo.history
end

-- 检测是否破产 
function CheckBankrupt(uid, roomId)
	local roomInfo = MapRoom[roomId]
	local info = ChessToLobbyMgr.CheckSendChipsWarnToLobby(uid)
	if info ~= nil then
		local bankruptInfo = roomInfo.bankruptInfo or {}
		table.insert(bankruptInfo, info)
		roomInfo.bankruptInfo = bankruptInfo
	end
end

-----------------------------------房间流程----------------------------------
-- 定时操作函数
function OnTimerDo(roomId)
	local roomInfo = MapRoom[roomId]
	local doInfo = ""
	local brdInfo = {}

	local status 	= roomInfo.status
	local timeTick  = roomInfo.timeTick	-- 上次时钟处理时间点

	-- 空闲结束  切换到下一个状态 下注
	if status == ENUM_GAME_STATUS.FREE and (os.time() - timeTick) >= ENUM_GAME_TIME.FREE then
		doInfo, brdInfo = BetTime(roomId)
	-- 下注结束  切换到下一个状态 发牌
	elseif status == ENUM_GAME_STATUS.BET and os.time() - timeTick >= ENUM_GAME_TIME.BET then
		doInfo, brdInfo = LotteryTime(roomId)	
	-- 开奖结束  切换到下一个状态 空闲
	elseif status == ENUM_GAME_STATUS.LTY and os.time() - timeTick >= ENUM_GAME_TIME.LTY then
		doInfo, brdInfo = FreeTime(roomId)
	end

	if doInfo ~= "" then
		CmdMsgBrd(doInfo, brdInfo, roomId)
	end
end

-- 空闲时间(房间状态重置)
function FreeTime(roomId)
	local roomInfo = MapRoom[roomId]

	-- 更新房间状态
	roomInfo.status = ENUM_GAME_STATUS.FREE
	unilight.debug("房间：" .. roomId .. "-" .. Status[roomInfo.status])

	-- 房间状态重置
	ResetRoomInfo(roomId)	

	-- 筹码不符合条件的机器人 离开房间
	RobotMgr.CheckRobotChips(roomId, roomInfo.betInfo.bankerInfo.uid)

	-- 空闲时间再推送 盈利公告
	BalanceMgr.SendBroad()

	local doInfo = "Cmd.FreeRoomCmd_Brd"
	local brdInfo = {
		roomId 	 = roomId,
		freeTime = ENUM_GAME_TIME.FREE,
	}
	roomInfo.timeTick = os.time()
	return doInfo, brdInfo
end

-- 下注时间(1.获取最新的庄家 2.机器人投注开关开启)
function BetTime(roomId)
    local roomInfo = MapRoom[roomId]

	-- 更新房间状态
	roomInfo.status = ENUM_GAME_STATUS.BET
	unilight.debug("房间：" .. roomId .. "-" .. Status[roomInfo.status])
	
    -- 庄家信息
	local bankerUid = 0
	local bankerNbr = 0
	local bRobot = false
	local lastBankerUid =  roomInfo.betInfo.bankerInfo.uid
	local lastBankerNbr =  roomInfo.betInfo.bankerInfo.bankerNbr
	roomInfo.betInfo.bankerInfo.uid = 0

	-- 上局玩家因何下庄
	local bankerDownInfo = nil

	-- 如果上局庄家 断线了 则 此时才下庄 并离房
	if MapUid2Room[lastBankerUid] ~= nil and MapUid2Room[lastBankerUid].isDisconnect then
		CancelBanker(lastBankerUid)
		LeaveRoom(lastBankerUid)

		bankerDownInfo = {
			uid 	= lastBankerUid,
			reason 	= ENUM_BANKER_DOWN_RES.IS_ACT
		}		
		unilight.info("断线庄家 uid:" .. lastBankerUid .. "下庄并离房")
	else
		-- 如果是10局满了 被动下庄的 给前端提示
		if lastBankerNbr == 10 then 
			bankerDownInfo = {
				uid = lastBankerUid,
				reason = ENUM_BANKER_DOWN_RES.IS_TEN
			}
		end		
	end

	while true do
		-- 获取当前庄家
		while true do 
			bankerUid, bankerNbr = BankerRoomMgr.GetBankerUser(roomId)
			-- 如果不是系统 且 首次上庄的真实玩家 需要扣钱 
			if bankerUid ~= 0 and bankerNbr == 1 then
				-- 如果为机器人 则要保证机器人的bankchips 足够上庄(已在上庄机器人 进入房间时 做了处理)
				local bRobot = RobotMgr.IsRobot(bankerUid)
				if bRobot then
					break
				end
				-- 真实玩家扣款
				local userInfo = chessuserinfodb.RUserInfoGet(bankerUid)
				local bankerChips = RoomMgr.TempBankChips[bankerUid] or 0 
				-- 身上筹码只剩这么多了 只能携带这么多上庄
				if userInfo.property.chips < bankerChips then
					bankerChips = userInfo.property.chips
				end
				-- 检测这些筹码 能不能达到最低限额
				if bankerChips < TableBankerConfig[1].chips then
					-- 如果当前筹码 已经不够上庄了 则 自动退出队列
					CancelBanker(bankerUid)
					unilight.info("神俊要求系列之正在上庄才扣钱 该玩家不够钱了：" .. bankerUid .. "	chips:" .. bankerChips)
				else
					chessuserinfodb.WMoveChipsToBankerChips(bankerUid, bankerChips)
					break
				end
			else
				break
			end
		end

		-- 如果上局庄家 不是10局满 被动下庄的 那么在此处 如果庄家已经换人 那么其 只能是自动下庄
		if lastBankerUid ~= bankerUid and bankerDownInfo == nil then 
			bankerDownInfo = {
				uid = lastBankerUid,
				reason = ENUM_BANKER_DOWN_RES.IS_ACT
			}	
		end
		
		local userInfo = chessuserinfodb.RUserInfoGet(bankerUid)

		-- 如果是系统坐庄 则跳过
		if bankerUid == 0 then
			break
		end

		-- 如果是机器人 则用另一种方法判断
		local bRobot = RobotMgr.IsRobot(bankerUid)
		if bRobot then
			-- 获取机器人信息
			local userInfo = RobotMgr.GetRobotInfo(bankerUid)
			if userInfo.bankerchips >= TableBankerConfig[1].chips then
				break
			else
				-- 机器人房间信息 里面 庄家个数要减去
				local robotRoomInfo = RobotMgr.RobotRoom[roomId]
				-- lbx 这里上庄人数不能直接减1 因为在该机器人离开房间的时候 还会再次减1 会出现机器人数量不断上升 从而出错 
				-- robotRoomInfo.robotBankerNbr = robotRoomInfo.robotBankerNbr - 1
				RobotCancelBanker(bankerUid)
			end
		else -- 正常玩家上庄
			-- 下庄下限 如果为风驰大厅则为最低上庄筹码的百分之七十五
			local bankerChipsLimit = TableBankerConfig[1].chips
			if ZONETYPE == 5 then
				bankerChipsLimit = bankerChipsLimit * BANKER_DOWN_RATE
			end			
			if userInfo.property.bankerchips >= bankerChipsLimit then 
				break
			else
				CancelBanker(bankerUid, true)
			end
			-- 庄家是在此处换人的 则为 筹码不足 被动下庄的
			if bankerUid == lastBankerUid then 
				bankerDownInfo = {
					uid = lastBankerUid,
					reason = ENUM_BANKER_DOWN_RES.NO_CHIP
				}	
			end
		end
	end

	-- 上一局是，但这一局不是的玩家把相应的bankerchips -> chips
	local bankerInfo = {}
	if bankerUid ~= 0 and lastBankerUid ~= bankerUid then
		if RobotMgr.IsRobot(lastBankerUid) ~= true then
			chessuserinfodb.WMoveBankerChipsToChips(lastBankerUid) 
		end
	end

	local bankerInfo = BankerRoomMgr.ConsructBankerInfo(bankerUid, bankerNbr, 0) 
	
	-- 玩家下去的时候 再把他当前的金币 同步给前端
	if bankerDownInfo ~= nil then
		bankerDownInfo.userAllChips = chessuserinfodb.RUserChipsGet(bankerDownInfo.uid)
	end

	roomInfo.betInfo.bankerInfo = bankerInfo

	-- 当前上庄列表
	local bankerList = RoomMgr.GetBankerList(roomId)

    local doInfo = "Cmd.BeginBetRoomCmd_Brd"
    local brdInfo = {
		roomId 		= roomId,
    	betTime 	= ENUM_GAME_TIME.BET,
		bankerInfo 	= bankerInfo,
		bankerDown 	= bankerDownInfo,
		bankerList 	= bankerList,
	}

	-- 机器人 开始准备投注
	RobotMgr.RobotResetBegin(roomId, roomInfo.roomStock)
	roomInfo.timeTick = os.time()

	return doInfo, brdInfo
end

-- 开奖时间(0.获取最新牌局id 1.发送缓存中未发的投注广播 2.关闭机器人投注 3.生成最终开奖结果 4.开奖后更新保护、黑白列表 -- 清除无效的、添加新的)
function LotteryTime(roomId)
	local roomInfo = MapRoom[roomId]	

	-- 每次开奖获取一次 最新 全局唯一牌局id
	RoomMgr.RoundId = chessprofitbet.GetRoundId()

	-- 更新房间状态
	roomInfo.status = ENUM_GAME_STATUS.LTY
	unilight.debug("房间：" .. roomId .. "-" .. Status[roomInfo.status] .. "  当前牌局id：" .. RoundId)
	
	-- 去生成开奖结果前 查看缓存中 是否还有投注消息未广播
	SendBetBrd(roomId)

	--关闭机器人投注
	RobotMgr.RoomRobotEnd(roomId)

	local bankerChips = roomInfo.betInfo.bankerInfo.bankerChips
	local bankerUid = roomInfo.betInfo.bankerInfo.uid

	-- 正式开奖 获取开奖结果
	local lotteryId, lotterySeatId = LotteryCtl.GetLotteryInfo(roomId)

	-- 给玩家结算中奖钱
	local userBet = roomInfo.betInfo.userBet or {}
	local robotBet = roomInfo.betInfo.robotBet or {}
	local allBet = roomInfo.lotteryInfo.allBetAll or {}

	local lotteryUser, bankerProfit, bankerChipsRemainder, bankerRemainder, bankerMark = BalanceMgr.RoomBanlance(userBet, robotBet, lotteryId, bankerChips, bankerUid, roomId)

	-- 广播数据组装
	local doInfo = "Cmd.LotteryRoomCmd_Brd"
	local brdInfo = {
    	roomId 					= roomId,
		lotteryTime 			= ENUM_GAME_TIME.LTY,
		lotterySeatId 			= lotterySeatId,
		lotteryId 				= lotteryId,
		lotteryUsers 			= lotteryUser,
		bankerUid				= bankerUid,			
		bankerProfit			= bankerProfit,			
		bankerChipsRemainder	= bankerChipsRemainder,		-- 庄家剩余上庄筹码	
		bankerRemainder			= bankerRemainder,			-- 庄家剩余总筹码
		bankerMark 				= bankerMark				-- 庄家成绩
	}

 	local users = {}	
 	for uid, _ in pairs(userBet) do
 		table.insert(users, uid)
 	end

	-- 在库存房间中 配置有 保护额、保护返点
	local roomStock = chessroominfodb.GetRoomInfo(go.gamezone.Gameid, roomId)	

	-- 风驰大厅 暂时不开启保护流程
	if ZONETYPE ~= 5 then
		-- 开奖、结算结束 更新保护列表(暂时不启用自动黑白名单 功能)
		ProtectMgr.UpdateProtectInfo(go.gamezone.Gameid, users, bankerUid, RoundId, roomStock.protectChips, roomStock.protectRetn)
	end

	-- 开奖、结算结束 更新黑白名单 
	BlackWhiteMgr.ExecuteBlackWhiteInfo(go.gamezone.Gameid, users, bankerUid, RoundId)

	-- 更新开奖历史(缓存20条)
	UpdateLotteryHistory(roomInfo, lotteryId)

	-- 时间戳更新
	roomInfo.timeTick = os.time()
	return doInfo, brdInfo
end

-- 开奖结束后 房间信息重置
function ResetRoomInfo(roomId)
	local roomInfo = MapRoom[roomId]
	-- 玩家下注信息清零
	roomInfo.betInfo.userBet = {}
	roomInfo.betInfo.robotBet = {}
	-- 系统总的记录信息清零
	for i, _ in pairs(roomInfo.lotteryInfo.userBetAll) do
		roomInfo.lotteryInfo.userBetAll[i] = 0
	end
	for i, _ in pairs(roomInfo.lotteryInfo.robotBetAll) do
		roomInfo.lotteryInfo.robotBetAll[i] = 0
	end
	for i, _ in pairs(roomInfo.lotteryInfo.allBetAll) do
		roomInfo.lotteryInfo.allBetAll[i] = 0
	end
end

-- 1秒跑一次
function OnTimer()
	local roomCfg = chessroominfodb.GetRoomAllInfo(go.gamezone.Gameid)
	for i,v in ipairs(roomCfg) do
		RoomMgr.OnTimerDo(v.roomId)
	end
end

-- 增加开奖历史（缓存20条）
function UpdateLotteryHistory(roomInfo, lotteryId)
	table.insert(roomInfo.lotteryInfo.history, lotteryId)
	local len = table.len(roomInfo.lotteryInfo.history)
	if len > 20 then
		roomInfo.lotteryInfo.history = table.slice(roomInfo.lotteryInfo.history, len-19, len)
	end
end

-------------------------------------GM---------------------------------------
-- GM控制函数
function GmControl(control)
	local roomInfo = MapRoom[roomId]
	if roomInfo == nil then
		unilight.error("当前不存在该房间 不能进行gm控制:" .. roomId)
		return 2, "控制的房间有误：" .. roomId
	end
	-- 整理检测 GM控制命令
	local control = tonumber(control)
	if control == nil or control < 1 or control > 8 then
		return 3, "输入的GM控制有误"
	end
	
	-- 写入
	roomInfo.gmControl = control
	return 0, "GM已正常进行控制"
end

------------------------------------广播---------------------------------------

-- 广播包装
function CmdMsgBrd(doInfo, data, roomId)
	local roomInfo = MapRoom[roomId]
	if roomInfo.BrdRoom ~= nil then
		chesstcplib.TcpRoomInfoBrd(roomInfo.BrdRoom, doInfo, data)
	end	
end

-- 广播包装
function CmdMsgBrdExceptMe(doInfo,uid, data, roomId)
	local roomInfo = MapRoom[roomId]
	local laccount = MapUid2Room[uid].laccount
	if roomInfo.BrdRoom ~= nil then
		chesstcplib.TcpRoomInfoBrdExceptMe(roomInfo.BrdRoom, laccount, doInfo, data)
	end	
end
