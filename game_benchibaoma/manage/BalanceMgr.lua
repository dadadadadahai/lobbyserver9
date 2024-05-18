module('BalanceMgr', package.seeall)

BROAD_LIMIT = 10000000 -- 达到1000w收入则广播

TempBroadInfo 	= {} 	-- 临时缓存盈利公告 等到空闲时间再发送出去

-- 结算统一管理
function RoomBanlance(userBet, robotBet, lotteryId, bankerChips, bankerUid, roomId)
	local roomStock = chessroominfodb.GetRoomInfo(go.gamezone.Gameid, roomId)

	-- 对所有玩家遍历
	local allChipsPayment 	= 0	--总赔付
	local allChipsBetAll 	= 0
	local userChipsPayment 	= 0	--玩家总赔付
	local userChipsBetAll 	= 0
	local robotChipsPayment = 0	--机器人总赔付
	local robotChipsBetAll 	= 0

	local lotterUser 	= {}	-- 各个玩家 的具体获奖信息
	local userNbr 		= 0		-- 统计该局 下注 玩家个数
	local robotNbr 		= 0		-- 统计该局 下注 机器人个数

	local pumps 		= 0		-- 本局总抽水

	-- 检测当前是否在排行榜时间段内 (0/1/2  正在排行榜时间内、未曾开启过、不在时间内但是存在以前老的排行榜数据)
	local isOnRankTime = RankMgr.CheckRankOpenTime()

	-- 处理真正玩家的开奖
	for uid, betInfo in pairs(userBet) do
		-- 获取玩家收益
		local oneUserBetChips, addChips = OneUserProfit(uid, betInfo, lotteryId, false)
		
		-- 真实收益
		local profit = addChips - oneUserBetChips

		-- 返回给玩家看的得分是 未抽水前的 数值
		local preAddChips 	= addChips
		local preProfit 	= profit

		-- 抽水（如果此时profit 大于0 则抽水）
		local pump = nil
		if profit > 0 then
			pump 			= math.ceil(profit * roomStock.pumpPercent)	
			addChips 		= addChips - pump
			profit 			= profit - pump 		 
			pumps 			= pumps + pump
		end

		-- 有得分则加上
		local remainder = 0
		if addChips > 0 then
			remainder = chessuserinfodb.WChipsChange(uid, 1, addChips)
		else
			remainder = chessuserinfodb.RUserChipsGet(uid)
		end

		userNbr = userNbr + 1
		userChipsBetAll 	= userChipsBetAll + oneUserBetChips
		userChipsPayment 	= userChipsPayment + addChips 

		-- 调用 统一筹码统计
		local lotteryInfo = {
			id 			= lotteryId,
			multiple	= TableCarTypeid[lotteryId].mult,
		}		
		chessprofitbet.CmdRecordUserProfitBet(uid, go.gamezone.Gameid, oneUserBetChips, addChips, RoomMgr.RoundId, betInfo, lotteryInfo, chessprofitbet.OpenSource, true, nil, pump)
	
		-- 如果当前输钱了 而且 remainder小于1000 则破产了
		if profit < 0 and remainder < ChessToLobbyMgr.CHIPS_WARN_THRESHOLD then
			RoomMgr.CheckBankrupt(uid, roomId)
		end

		-- 成绩更新
		RoomMgr.MapUid2Room[uid].mark = RoomMgr.MapUid2Room[uid].mark + profit

		local lotteryUserInfo = {
			uid 		= uid,
			seatId 		= 0,
			betChips 	= oneUserBetChips,
			addChips 	= preAddChips,
			remainder 	= remainder,
			mark 		= RoomMgr.MapUid2Room[uid].mark
		}
		table.insert(lotterUser, lotteryUserInfo)

		-- 排行榜数据更新
		if isOnRankTime == 0 then
			RankMgr.UpdateRankInfo(roomId, uid, preProfit)
		end

		-- 检测是否推个公告
		CheckBroad(uid, preAddChips)
	end
	
	-- 处理机器人赢取
	for uid, betInfo in pairs(robotBet) do
		local oneUserBetChips, addChips = OneUserProfit(uid, betInfo, lotteryId, true)
		robotNbr = robotNbr + 1
		robotChipsBetAll = robotChipsBetAll + oneUserBetChips
		robotChipsPayment = robotChipsPayment + addChips

		-- 检测是否推个公告
		CheckBroad(uid, oneUserBetChips, true)
	end
	

	allChipsBetAll = userChipsBetAll + robotChipsBetAll
	allChipsPayment = userChipsPayment + robotChipsPayment
	unilight.info("------------------------------- 结算信息 -------------------------------")
	unilight.info("本局下注玩家数: 	" .. "机器人:" .. robotNbr .. "		玩家:" .. userNbr)
	
	local bBankerRobot = RobotMgr.IsRobot(bankerUid) 
	local profitAll = 0										-- 系统本局总输赢
	local bankerChipsRemainder = 0
	local bankerProfit = allChipsBetAll - allChipsPayment 	-- 庄家本局收益
	local preBankerProfit = bankerProfit 					-- 庄家本局收益(不考虑抽水等)
	local bankerMark = 0									-- 庄家成绩
	if bBankerRobot == true then
		unilight.info("本局最终统计  : 	为机器人上庄		利润为:" .. userChipsBetAll - userChipsPayment)
		unilight.info("本局玩家共下注:" .. userChipsBetAll .. "	赢取:" .. userChipsPayment .. "			利润为:" .. userChipsPayment - userChipsBetAll)
		-- 获取一下最新的stock
		profitAll = userChipsBetAll - userChipsPayment

		-- 机器人坐庄 也修改其筹码
		if bankerUid ~= 0 then
			local info = RobotMgr.ChangeRobotChips(bankerUid,0, bankerProfit)
			bankerChipsRemainder = info.bankerchips
		end
	else
		unilight.info("本局最终统计  : 	为玩家参与上庄	利润为:" .. allChipsBetAll - allChipsPayment)
		unilight.info("本局玩家共下注:" .. userChipsBetAll .. "	赢取:" .. userChipsPayment .. "			利润为:" .. userChipsPayment - userChipsBetAll)
		unilight.info("本局机器共下注: 	" .. robotChipsBetAll .. "	赢取:" .. robotChipsPayment .. "			利润为:" .. robotChipsPayment - robotChipsBetAll)
		
		profitAll =  robotChipsPayment - robotChipsBetAll 

		-- 真实玩家坐庄 本局收益
		local pump = nil
		if bankerProfit > 0 then
			pump 			= math.ceil(bankerProfit * roomStock.pumpPercent)	
			bankerProfit 	= bankerProfit - pump	
			pumps 			= pumps + pump		
		end

		-- 更新庄家上庄 筹码
		_,_,bankerChipsRemainder = chessuserinfodb.WUpdateBankerChips(bankerUid, bankerChips, bankerProfit + bankerChips)

		-- 上庄信息统计
		chessprofitbet.CmdRecordUserBeBanker(bankerUid, go.gamezone.Gameid, bankerChips, bankerChipsRemainder, nil, RoomMgr.RoundId, nil, nil, pump)
		-- 如果当前输钱了 而且 remainder小于1000 则有可能破产了
		if bankerProfit < 0 and bankerChipsRemainder < ChessToLobbyMgr.CHIPS_WARN_THRESHOLD then
			RoomMgr.CheckBankrupt(bankerUid, roomId)
		end	

		-- 成绩更新
		RoomMgr.MapUid2Room[bankerUid].mark = RoomMgr.MapUid2Room[bankerUid].mark + bankerProfit
		bankerMark = RoomMgr.MapUid2Room[bankerUid].mark

		-- 排行榜数据更新
		if isOnRankTime == 0 then
			RankMgr.UpdateRankInfo(roomId, bankerUid, preBankerProfit)
		end

		-- 检测是否推个公告
		CheckBroad(bankerUid, preBankerProfit)
	end
	
	-- 在结算时 如果在排行榜时间段内 则开始模拟机器人排行榜数据
	if isOnRankTime == 0 then
		RankMgr.UpdateRobotRankInfo(roomId)
	end

	-- 这里更新库存，也涉及到 纯利 彩金
	local stockAdd 	= 0
	local profit 	= 0
	local bonus 	= 0
	if profitAll > 0 then
		-- 纯利
		profit = math.ceil(profitAll * roomStock.profitPercent)	
		roomStock.profitAll= roomStock.profitAll + profit

		-- 彩金（暂时彩金不扣 mark）

		stockAdd = profitAll - profit - bonus
	else
		stockAdd = profitAll
	end
	roomStock.stock = roomStock.stock + stockAdd
	roomStock.pump 	= roomStock.pump + pumps
	chessroominfodb.SaveRoomInfo(go.gamezone.Gameid, roomId, roomStock)
	unilight.info("最新库存为    :" .. roomStock.stock - roomStock.stockThreshold)
	unilight.info("最新房间总抽水:" .. roomStock.pump.. "	本局抽水:" .. pumps)
	unilight.info("最新房间总纯利:" .. roomStock.profitAll.. "	本局纯利:" .. profit)
	unilight.info("------------------------------------------------------------------------")

	-- 获取玩家身上总筹码 
	local bankerRemainder = chessuserinfodb.RUserChipsGet(bankerUid) + bankerChipsRemainder

	return lotterUser, bankerProfit, bankerChipsRemainder, bankerRemainder, bankerMark
end

-- 每个玩家 收益计算
function OneUserProfit(uid, betInfo, lotteryId, bRobot)
	local betChipsAll = 0	
	-- 计算总共投注了多少
	for betId, chips in pairs(betInfo) do
		betChipsAll = betChipsAll + chips
	end
	
	-- 计算玩家结算时 收入多少分
	local addChips = (betInfo[lotteryId] or 0) * TableCarTypeid[lotteryId].mult

	if bRobot == false then
		unilight.info("玩家 uid:" .. uid .. "共下注(已扣款)：" .. betChipsAll .. "  开奖得分(未抽水前)：" .. addChips)
	end
	return betChipsAll, addChips
end

-- 检测是否推送盈利公告
function CheckBroad(uid, profit, brotot)
	if ZONETYPE ~= 5 then
		return
	end
	if profit >= BROAD_LIMIT then
		local nickName 	= nil
		if brotot then
			local robotInfo = RobotMgr.GetRobotInfo(uid)
			nickName = robotInfo.nickname
		else
			local userData = UserInfo.GetUserDataById(uid)
			if userData ~= nil then
				nickName = userData.base.nickname
			end
		end
		if nickName ~= nil then
			local value 	= math.floor(profit/10000)
			local brdInfo 	= "恭喜玩家:" .. nickName .. "在车行争霸中赢取" .. value .. "万金币！"
			-- 先缓存起来
			table.insert(TempBroadInfo, brdInfo)
		end
	end
end

-- 实际发送
function SendBroad()
	local chatPos 	= chesscommonchat.ENUM_CHAT_POS.GM
	local chatType 	= chesscommonchat.ENUM_CHAT_TYPE.LOBBY
	for i,brdInfo in ipairs(TempBroadInfo) do
		ChessToLobbyMgr.SendBroadToLobby(0, "系统公告", true, chatPos, chatType, brdInfo)
		unilight.debug("游戏服已经发送给大厅了:" .. brdInfo)	
	end
	TempBroadInfo = {}
end
