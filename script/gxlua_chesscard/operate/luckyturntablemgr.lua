module("LuckyTurnTableMgr", package.seeall)
-- 运营活动 幸运大转盘

-- 初始化 幸运转盘相关
function Init(uid, isFollow)
	local info = {
		uid 		= uid,		-- 玩家id
		integral 	= 0,		-- 积分
		timeStamp	= 0,		-- 最后一次修改数据的时间戳 
		tasks		= nil,		-- 用于记录那些任务 已经增加过积分了
		isFollow	= isFollow,	-- 是否关注过公众号
	}
	Update(info)
	return info
end

-- 更新幸运转盘信息
function Update(info)
	info.timeStamp = os.time()
	unilight.savedata("luckyturntable", info)
end

-- 积分获取
function GetIntegral(uid, integral)
	-- 先检测当前是否在活动时间 如果是 则加 不是 则跳过
	if OperateSwitchMgr.CheckInOprateTime(OperateSwitchMgr.ENUM_OPRATE_TYPE.TURNTABLE) ~= true then
		return 
	end

	local info = unilight.getdata("luckyturntable", uid)
	-- 如果不存在转盘数据 或者 数据不是今天的 则重置
	if info == nil then
		info = Init(uid)
	elseif chessutil.DateDayDistanceByTimeGet(info.timeStamp, os.time()) > 0 then
		info = Init(uid, info.isFollow)
	end
	info.integral = info.integral + integral
	Update(info)
end

-- 同步 完成任务 获取的 积分
function GetIntegralByTasks(uid, info)
	local bUpdate = false
	info.tasks = info.tasks or {}
	local taskLists = DaysTaskMgr.GetTaskList(uid)
	for i,v in ipairs(taskLists) do
		-- 已完成 或 已领取 均可
		if v.taskStatus ~= DaysTaskMgr.ENUM_TASK_STATUS.PROGRESS then
			taskInfo = TableLobbyTaskConfig[v.taskId]
			
			-- 统计任务 不算在内
			if taskInfo.taskType ~= 4 then
				if info.tasks[v.taskId] == nil then
					bUpdate = true
					info.integral = info.integral + 2
					info.tasks[v.taskId] = true
				end
			end
		end
	end
	if bUpdate then
		Update(info)
	end
	return info
end

-- 获取幸运转盘信息
function GetInfoLuckyTurnTable(uid)
	local info = unilight.getdata("luckyturntable", uid)
	-- 如果不存在转盘数据 或者 数据不是今天的 则重置
	if info == nil then
		info = Init(uid)
	elseif chessutil.DateDayDistanceByTimeGet(info.timeStamp, os.time()) > 0 then
		info = Init(uid, info.isFollow)
	end
	-- 获取完成任务的积分（由于大厅每日任务 每次都会去获取统计数据 所以只能在这里 进行任务积分的获取）
	info = GetIntegralByTasks(uid, info)

	return 0, "获取转盘信息成功", info
end

-- 转动转盘
function TurnLuckyTurnTable(uid)
	local info = unilight.getdata("luckyturntable", uid)
	if info == nil then
		info = Init(uid)
	elseif chessutil.DateDayDistanceByTimeGet(info.timeStamp, os.time()) > 0 then
		info = Init(uid, info.isFollow)
	end

	-- 检测积分
	if info.integral < 50 then
		return 2, "积分不足"
	end

	-- 扣除积分
	info.integral = info.integral - 50

	-- 随机物品 等表格
	local turnId = RandomReward(uid)

	-- 当前转到物品
	local goodId  = TableOperateTurnTable[turnId].giftGoods.goodId
	local goodNum = TableOperateTurnTable[turnId].giftGoods.goodNum

	local tableGoodInfo = TableGoodsConfig[goodId]

	-- 去获取 
	BackpackMgr.GetRewardGood(uid, goodId, goodNum, Const.GOODS_SOURCE_TYPE.OPERATE)
	
	-- 所有种类奖励 均 记录起来（运营相关的 统一记录在一个表中 operaterecord）
	OprateRecordMgr.SaveRecords(uid, OperateSwitchMgr.ENUM_OPRATE_TYPE.TURNTABLE, TableOperateTurnTable[turnId].turnName, goodId, goodNum, tableGoodInfo.goodType)

	-- 积分数据存档
	Update(info)

	local remainder = chessuserinfodb.RUserChipsGet(uid)
	
	-- 返回
	return 0, "转动转盘成功", turnId, info.integral, remainder
end

-- 当日玩牌50局＜累计玩牌超过200局＜连续7日登陆＜当日首充＜累计充值100 			权重对比
-- 确定当前转盘所使用概率
function EnsureProbability(uid)
	local userInfo = chessuserinfodb.RUserInfoGet(uid)

	local probability = {}
	local selected = "normal"
	-- 检测 是否累计充值100
	local sumRecharge = chessrechargemgr.CmdUserSumRechargeGetByUid(uid) -- 单位分
	if sumRecharge >= 10000 then
		selected = "rechargeOneHundred"
	else
		-- 检测 是否当日首充
		if userInfo.recharge.firstTime ~= nil and chessutil.DateDayDistanceByTimeGet(userInfo.recharge.firstTime, os.time()) == 0 then 
			selected = "firstRecharge"
		else
			-- 检测 是否连续7天登陆
			if userInfo.status.continueDays >= 7 then
				selected = "sevenDays"
			else
				-- 检测 是否玩牌超过200局
				local allCounts = chessprofitbet.CmdAllGamePlayNmuberGetByUid(uid)
				if allCounts >= 200 then
					selected = "playTwoHundred"
				else
					-- 检测 是否当日50局
					local temp = os.date("*t", os.time())
					local zeroTime = os.time({year=temp.year, month=temp.month, day=temp.day, hour=0})
					local todayCounts = chessprofitbet.CmdGamePlayNmuberGetByUidBetween(uid, zeroTime, os.time())
					if todayCounts >= 50 then
						selected = "playFifty"
					end
				end
			end
		end
	end

	-- 最终概率填充
	for i,v in ipairs(TableOperateTurnTable) do
		table.insert(probability, v[selected])
	end

	unilight.info("当前幸运大转盘 选中的概率为: " .. selected)
	return probability
end

-- 随机奖励
function RandomReward(uid)
	-- 找到当前使用的概率
	local probability = EnsureProbability(uid)
	local turnId = 0

	local rand = math.random(1,TableOperateTurnTable[1].reference)
	for i,v in ipairs(probability) do
		if rand <= v then
			turnId = i 
			break
		end 
		rand = rand - v
	end
	if turnId == 0 then
		unilight.info("当前运营幸运大转盘奖励随机算法有误")
		turnId = 1
	end
	return turnId
end