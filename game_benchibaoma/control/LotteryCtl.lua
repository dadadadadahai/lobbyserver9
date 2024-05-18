module('LotteryCtl', package.seeall)
-- 用来处理投注、开奖相关

USER_MAX_BET = 50000000		-- 单个玩家最大下注5000w

MapLtyId2SeatId 	= {} 	-- 开奖结果 对应 开奖位置

-- 整理表格数据
function Init()
	for i,v in ipairs(TableCarSeat) do
		MapLtyId2SeatId[v.id] = MapLtyId2SeatId[v.id] or {}
		table.insert(MapLtyId2SeatId[v.id], v.seatidx)
	end
end

-----------------------------------检测下注-------------------------------

-- 判断玩家是否可以下注
function CmdCouldBet(betId, chips, bankerInfo, allBet, userBetAll)
	local bankerUid 	= bankerInfo.uid
	local bankerChips 	= bankerInfo.bankerChips

	-- 玩家投注后 单局总投注额 (机器人不检查这一项)
	if userBetAll ~= nil then
		local userBetChipsAll = chips
		for k,v in pairs(userBetAll) do
			userBetChipsAll = userBetChipsAll + v
		end
		if userBetChipsAll > USER_MAX_BET then
			unilight.info("玩家当前下注已经超过单人每局下注上限 上限为:" .. USER_MAX_BET)
			return false
		end
	end

	-- 投上后 该位置 总共投注额为
	local betChipsAll = chips + (allBet[betId] or 0)

	-- 各个位置 有个最大下注值 先过滤
	if betChipsAll > TableCarTypeid[betId].maxbet then
		return false
	end

	-- 如果没有超过 位置上限 则 系统坐庄时 随便下 不需考虑赔付
	if bankerUid == 0 then
		return true
	end

	-- 计算该房间 总共投注了多少筹码
	local roomBetAll = chips
	for id=1,8 do
		allBet[id] = allBet[id] or 0
		roomBetAll = roomBetAll + allBet[id]
	end

	-- 读表查看倍率 看是否够赔付
	local mult = TableCarTypeid[betId].mult
	if bankerChips + roomBetAll >= betChipsAll * mult then
		return true
	end

	return false
end

-- 检测重复下注 假如全部投注成功 看是否能满足各项要求 如果不能满足 则依然按一个个下 
function CheckRepeatBet(uid, betReq, bankerInfo, allBet, userBet)
	local userData 		= UserInfo.GetUserDataById(uid)
	local bankerUid 	= bankerInfo.uid
	local bankerChips 	= bankerInfo.bankerChips

	local userBetChipsAll = 0
	
	-- 检测是否已手动投注过 
	if userBet ~= nil then
		for k,v in pairs(userBet) do
			userBetChipsAll = userBetChipsAll + v.chips
		end
		if userBetChipsAll > 0 then
			unilight.info("已经投注过了 不支持重复下注")
			return 6, "已经投注过了 不支持重复下注"
		end
	end

	-- 投注请求汇总起来
	local mapBetReq = {}
	for k,v in pairs(betReq) do
		if v ~= nil then
			mapBetReq[v.betId] = mapBetReq[v.betId] or 0
			mapBetReq[v.betId] = mapBetReq[v.betId] + v.chips

			userBetChipsAll = userBetChipsAll + v.chips
		end
	end

	-- 检测筹码是否足够
	if userBetChipsAll > userData.property.chips then
		unilight.info("玩家重复下注失败 筹码不足")
		return 7, "玩家重复下注失败 筹码不足" 		
	end

	-- 检测是否投注超过玩家单局上限 
	if userBetChipsAll > USER_MAX_BET then
		unilight.info("玩家重复下注额不正常 超过玩家单局投注上限")
		return 8, "玩家重复下注额不正常 超过玩家单局投注上限"
	end

	-- 检测是否某个位置超过下注上限
	for i=1,8 do
		if (mapBetReq[i] or 0) + (allBet[i] or 0) > TableCarTypeid[i].maxbet then
			unilight.info("玩家重复下注失败 某个下注位置超过上限了")
			return 9, "玩家重复下注失败 某个下注位置超过上限了"
		end
	end

	-- 检测庄家是否够赔付 系统坐庄时 随便下 不需考虑赔付
	if bankerUid == 0 then
		return 0, "重复下注成功"
	end

	-- 计算该房间 总共投注了多少筹码
	local roomBetAll = 0
	for id=1,8 do
		roomBetAll = roomBetAll + (allBet[id] or 0) + (mapBetReq[id] or 0)
	end

	-- 读表查看倍率 如果有一个位置不够赔付 则这次下注不能成功
	for id=1,8 do
		local mult = TableCarTypeid[id].mult
		if bankerChips + roomBetAll < ((allBet[id] or 0) + (mapBetReq[id] or 0)) * mult then
			unilight.info("玩家重复下注失败 庄家不够赔付")
			return 10, "玩家重复下注失败 庄家不够赔付"
		end
	end

	return 0, "重复下注成功"	
end

-----------------------------------获取开奖-------------------------------
-- 获取开奖结果
function GetLottery(control)
	-- 最终开奖结果
	local lotteryId = nil
	if control ~= nil then 
		lotteryId = control 
	else
		local random = math.random(1, 10000)
		for i,v in ipairs(TableCarTypeid) do
			if v.prob >= random then
				lotteryId = i
				break
			else
				random = random - v.prob
			end
		end
	end

	-- 随机指定该结果的位置
	local lotterySeatId = MapLtyId2SeatId[lotteryId][math.random(1, table.len(MapLtyId2SeatId[lotteryId]))] 

	return lotteryId, lotterySeatId
end

-- 开奖信息生成
function GetLotteryInfo(roomId)
	local roomInfo = RoomMgr.MapRoom[roomId] 

	-- 开奖结果、开奖位置
	local control = LotteryControl(roomInfo)
	local lotteryId, lotterySeatId = GetLottery(control)

	-- 打印开奖信息 
	PrintLottertyInfo(lotteryId, lotterySeatId)

	return lotteryId, lotterySeatId
end

-- 打印开奖信息
function PrintLottertyInfo(lotteryId, lotterySeatId)
	local openSources = {"SYSOP", "GMCTR", "STOCK", "PRTBK", "PRTPLR", "BLAWT", "EAT", "SPIT"} 	
	unilight.info("------------------------------- 开奖信息 -------------------------------")
	unilight.info("本局开奖来源:" .. openSources[chessprofitbet.OpenSource] .. " 结果:" .. TableCarTypeid[lotteryId].name .. "	位置:" .. lotterySeatId)
	unilight.info("------------------------------------------------------------------------")
end

-----------------------------------开奖控制-------------------------------
-- 开奖控制相关（一整套控制流程）
function LotteryControl(roomInfo)
	local userBet 		= roomInfo.betInfo.userBet
	local userBetAll	= roomInfo.lotteryInfo.userBetAll
	local robotBetAll	= roomInfo.lotteryInfo.robotBetAll

	local bankerUid		= roomInfo.betInfo.bankerInfo.uid
	local gmControl 	= roomInfo.gmControl
	local roomStock		= chessroominfodb.GetRoomInfo(go.gamezone.Gameid, roomInfo.roomId)	-- 房间当前库存信息
	local lineData 		= roomStock.stock - roomStock.stockThreshold						-- 真实库存额度

	local control 		= nil

	-- 默认为系统开牌
	chessprofitbet.OpenSource = chessprofitbet.ENUM_OPEN_SOURCE.SYSOP

	-- 如果该局游戏 没有玩家参与 则 随机开牌
	if RobotMgr.IsRobot(bankerUid) and table.len(userBet) == 0 then
		unilight.info("本局游戏没有真实玩家参与 随机开牌")
		return control
	end

	-- 如果存在gm控制 则 默认按照gm控制开牌
	if gmControl ~= nil then
		-- gm控制 当局有效
		roomInfo.gmControl = nil
		chessprofitbet.OpenSource = chessprofitbet.ENUM_OPEN_SOURCE.GMCTR
		return gmControl
	end

	-- 检测是否需要进行库存控制
	local isStockCtr = CheckStockCtrPoker(roomInfo)

	-- 如果进行库存控制了
	if isStockCtr ~= nil then
		chessprofitbet.OpenSource = chessprofitbet.ENUM_OPEN_SOURCE.STOCK
		return isStockCtr
	else
		-- 库存 保证足够 则 进入黑白名单 判断
		local users = {}
		for uid,_ in pairs(userBet) do
			table.insert(users, uid)
		end
		local blackWhiteInfo = BlackWhiteMgr.GetBestBlackWhiteInfo(go.gamezone.Gameid, users, bankerUid)

		-- 如果存在黑白名单 则 按照黑白名单 开牌 
		if blackWhiteInfo ~= nil then
			control = BlackWhiteCtrPoker(roomInfo, blackWhiteInfo)
		end		
		
		-- 执行了黑白名单
		if control ~= nil then
			chessprofitbet.OpenSource = chessprofitbet.ENUM_OPEN_SOURCE.BLAWT
		else
			-- 检测是否在吃吐分期  (暂时只处理系统坐庄的情况)
			if RobotMgr.IsRobot(bankerUid) then
				local stockMid 		= roomStock.stockMid 		-- 库存中心点
				local stockRange 	= roomStock.stockRange 		-- 库存上下正常范围

				-- 如果数据库中 并没有配置 这两个字段 则默认 不执行吃吐分逻辑
				if stockMid ~= nil and stockRange ~= nil then
					-- 吐分期
					if lineData > stockMid + stockRange then
						chessprofitbet.OpenSource = chessprofitbet.ENUM_OPEN_SOURCE.SPIT			
						control = EatSpitCtrPoker(roomInfo, chessprofitbet.OpenSource, lineData-stockMid)
					-- 吃分期
					elseif lineData < stockMid - stockRange then
						chessprofitbet.OpenSource = chessprofitbet.ENUM_OPEN_SOURCE.EAT			
						control = EatSpitCtrPoker(roomInfo, chessprofitbet.OpenSource, stockMid-lineData)
					end
				end
			end
		end
	end

	return control
end


-----------------------------------库存控制-------------------------------
-- 检测是否需要库存控制 考虑最糟糕的情况 
function CheckStockCtrPoker(roomInfo)
	local info 			= roomInfo.lotteryInfo 												-- 房间汇总各种下注情况
	local bankerChips 	= roomInfo.betInfo.bankerInfo.bankerChips 							-- 当前庄家的 上庄筹码
	local bankerUid 	= roomInfo.betInfo.bankerInfo.uid 									-- 当前庄家UID
	local bBankerRobot 	= RobotMgr.IsRobot(bankerUid)										-- 庄家是否为机器人
	local roomStock		= chessroominfodb.GetRoomInfo(go.gamezone.Gameid, roomInfo.roomId)	-- 房间当前库存信息	
	local lineData 		= roomStock.stock - roomStock.stockThreshold						-- 真实库存额度

	local control = nil

	if bBankerRobot then
		local  userBetAll 	= info.userBetAll	-- 真实玩家投注
		local  betAll 		= 0					-- 总投注额

		-- 获取玩家总投注额
		for k,v in pairs(userBetAll) do
			betAll = betAll + v
		end

		-- 随机出开奖结果
		local win, lose, bestWin, bestId = nil
		local possible = {} -- 所有可能的结果
		local randomNbrs = chessutil.RandNNumbers(8, 8) 

		for i,lotteryId in ipairs(randomNbrs) do
			win 	= betAll 													-- 当前开奖结果 庄家 赢入的 
			lose 	= userBetAll[lotteryId] * TableCarTypeid[lotteryId].mult 	-- 当前开奖结果 庄家 输出的
			if win + lineData > lose then
				table.insert(possible, lotteryId)
			end

			-- 把最佳结果缓存起来 如果8个结果 没有一个满足要求的 则 取 最佳
			if bestId == nil then
				bestWin = win - lose
				bestId 	= lotteryId
			else
				if win - lose > bestWin then
					bestWin = win - lose 
					bestId 	= lotteryId
				end
			end
		end

		if table.len(possible) == 0 then
			control = bestId
			unilight.info("系统坐庄 找不到合适开奖结果 取当前最佳")
		elseif table.len(possible) ~= 8 then
			-- 如果 合适的开奖个数 不为8 则 代表某些开奖结果是不满足库存需求的 所以需要进行库存控制
			control = possible[math.random(1, table.len(possible))]
		end
	else
		-- 玩家坐庄时 如果机器人全输 则是最差情况 
		local  robotBetAll 	= info.robotBetAll	-- 汇总机器人总投注
		local  betAll 		= 0					-- 总投注额

		-- 获取机器人总投注额
		for k,v in pairs(robotBetAll) do
			betAll = betAll + v
		end

		-- 随机出开奖结果
		local win, lose, bestWin, bestId = nil 
		local possible = {} -- 所有可能的结果
		local randomNbrs = chessutil.RandNNumbers(8, 8) 
		for i,lotteryId in ipairs(randomNbrs) do
			win 	= robotBetAll[lotteryId] * TableCarTypeid[lotteryId].mult 		-- 当前开奖结果 机器人 赢入的 
			lose 	= betAll 														-- 当前开奖结果 机器人 输出的
			if win + lineData >= lose then
				table.insert(possible, lotteryId)
			end

			-- 把最佳结果缓存起来 如果 8个结果 没有一个满足要求的 则 取 最佳
			if bestId == nil then
				bestWin = win - lose
				bestId 	= lotteryId
			else
				if win - lose > bestWin then
					bestWin = win - lose 
					bestId 	= lotteryId
				end
			end
		end

		if table.len(possible) == 0 then
			control = bestId
			unilight.info("玩家坐庄 找不到合适开奖结果 取当前最佳")
		elseif table.len(possible) ~= 8 then
			-- 如果 合适的开奖个数 不为8 则 代表某些开奖结果是不满足库存需求的 所以需要进行库存控制
			control = possible[math.random(1, table.len(possible))]
		end
	end

	return control
end


-----------------------------------黑白控制-------------------------------
-- 进行黑白名单控制 如果存在局部gm控制 则gm优先 
function BlackWhiteCtrPoker(roomInfo, blackWhiteInfo)
	local uid 		= blackWhiteInfo.charid
	local setChips 	= blackWhiteInfo.setchips
	local curChips 	= blackWhiteInfo.curchips
	local type 		= blackWhiteInfo.type 				-- 1白名单 2黑名单
	local allBetAll = roomInfo.lotteryInfo.allBetAll	-- 房间总投注
	local userBet 	= roomInfo.betInfo.userBet[uid]		-- 该玩家的投注
	local i 		= 0

	local topLimit 	= (setChips*1.2) - curChips 		-- 玩家白名单上限 如果当前局赢了超过这个数 则不生效
	local overTime  = 0									-- 玩家白名单 随机结果 多少次超过其可赢上限 如果有20次 则当前白名单直接不生效了
	-- 小于50w 就让他过了 小钱不要控得太死
	if topLimit < 500000 then
		topLimit = 500000
	end

	local control = nil 

	if roomInfo.betInfo.bankerInfo.uid == uid then
		-- 如果当前黑白名单 为庄家 

		-- 获取房间总投注额
		local  betAll = 0	
		for k,v in pairs(allBetAll) do
			betAll = betAll + v
		end

		local win, lose = nil 
		local randomNbrs = chessutil.RandNNumbers(8, 8) 
		for i,lotteryId in ipairs(randomNbrs) do
			win 	= betAll 															-- 当前开奖结果 庄家 赢入的 
			lose 	= (allBetAll[lotteryId] or 0) * TableCarTypeid[lotteryId].mult 		-- 当前开奖结果 庄家 输出的

			if type == 1 then
				-- 白名单 要其赢取 但是不能太多 
				if win > lose and win - lose <= topLimit then
					control = lotteryId
					break					
				end
			else
				-- 黑名单 要其输钱
				if win < lose then
					control = lotteryId
					break					
				end
			end
		end
	else
		-- 黑白名单为 玩家	

		-- 获取该玩家总投注额
		local betAll = 0	
		for k,v in pairs(userBet) do
			betAll = betAll + v
		end	

		local win, lose = nil 
		local randomNbrs = chessutil.RandNNumbers(8, 8) 
		for i,lotteryId in ipairs(randomNbrs) do
			win 	= (userBet[lotteryId] or 0) * TableCarTypeid[lotteryId].mult 		-- 当前开奖结果 该玩家 赢入的 
			lose 	= betAll 															-- 当前开奖结果 该玩家 输出的
			
			if type == 1 then
				-- 白名单 要其赢取 但是不能太多 
				if win > lose and win - lose <= topLimit then
					control = lotteryId
					break					
				end
			else
				-- 黑名单 要其输钱
				if win < lose then
					control = lotteryId
					break					
				end
			end
		end
	end

	if control == nil then
		unilight.info("本局游戏存在黑白名单 但是没找到合适的黑白名单开奖方案")
	else
		unilight.info("本局游戏存在黑白名单 黑白名单开奖")
	end
	return control
end

-----------------------------------吃吐分期-------------------------------
-- 进行吃吐分控制 如果存在局部gm控制 则gm优先 	goal:最终操作目标 吃吐分期望能执行这个数 目的使库存到达中心点 每次操作能完成30%以上即符合 
function EatSpitCtrPoker(roomInfo, openSources, goal)
	local userBetAll = roomInfo.lotteryInfo.userBetAll	-- 房间内真实玩家总投注

	-- 获取玩家总投注额
	local betAll = 0					
	for k,v in pairs(userBetAll) do
		betAll = betAll + v
	end

	-- 随机出开奖结果
	local win, lose, profit, bestProfit, bestId = nil 
	local randomNbrs = chessutil.RandNNumbers(8, 8) 
	for i,lotteryId in ipairs(randomNbrs) do
		win 	= betAll 													-- 当前开奖结果 庄家 赢入的 
		lose 	= (userBetAll[lotteryId] or 0) * TableCarTypeid[lotteryId].mult 	-- 当前开奖结果 庄家 输出的
		profit 	= win - lose
		
		-- 满足条件退出循环
		-- 吐分期
		if openSources == chessprofitbet.ENUM_OPEN_SOURCE.SPIT then	
			if profit < 0 then
				profit = - profit
				-- 满足条件的 
				if profit >= math.floor(goal*0.3) and profit <= goal then
					control = lotteryId
					unilight.info("找到符合 吐分期 的开奖结果 i:" .. i .. "	最终控制：" .. lotteryId)
					break
				-- 不满足条件的 保留最佳的 最终实在找不到 就拿最合适的丢出去
				elseif bestProfit == nil or (profit > bestProfit and profit <= goal) then
					bestProfit 	= profit
					bestId 		= lotteryId
					unilight.info("吐分期 保留当前：" .. i .. "	profit:" .. profit .. "	goal:" .. goal .. "	control:" .. bestId)
				end 
			end
		-- 吃分期
		elseif openSources == chessprofitbet.ENUM_OPEN_SOURCE.EAT then
			if profit > 0 then
				-- 满足条件的 
				if profit >= math.floor(goal*0.3) and profit <= goal then
					control = lotteryId
					unilight.info("找到符合 吃分期 的开奖结果 i:" .. i .. "	最终控制：" .. lotteryId)
					break
				-- 不满足条件的 保留最佳的 最终实在找不到  就拿最合适的丢出去
				elseif bestProfit == nil or (profit > bestProfit and profit <= goal) then
					bestProfit 	= profit
					bestId 		= lotteryId
					unilight.info("吃分期 保留当前：" .. i .. "	profit:" .. profit .. "	goal:" .. goal .. "	control:" .. bestId)
				end 
			end
		end
	end

	-- 都不满足 取 最接近的 
	if control == nil then
		control = bestId
	end

	return control
end
