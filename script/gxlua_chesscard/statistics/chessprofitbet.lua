-- tips：进行筹码统一时 gameId 统一使用数字 

module('chessprofitbet', package.seeall) 

TABLE_NAME = "userprofitbet"
TABLE_NAME_DAY = "userprofitbet_day"

sequence 	= 1 -- 玩家每局下注信息统计
OpenSource 	= 1	-- 默认为系统开牌
-- 开牌来源
ENUM_OPEN_SOURCE = {
	SYSOP 	= 1,	-- 系统开牌
	GMCTR 	= 2,	-- GM控制
	STOCK	= 3,	-- 库存控制
	PRTBK	= 4,	-- 保庄
	PRTPL	= 5,	-- 保玩家
	BLAWT	= 6,	-- 黑白名单
	EAT		= 7,	-- 吃分期
	SPIT	= 8,	-- 吐分期
}

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
	[150] = "捕鱼",
	[178] = "车行争霸",
}


-- 初始化一个全局唯一的 牌局id
function InitRoundId()
	local info = {
		_id 	= 1,
		roundid = 0,
	}
	unilight.savedata("roundid", info)
	return info 
end

-- 获取一个全局唯一的 牌局id
function GetRoundId()
	local info = unilight.getdata("roundid", 1)
	if info == nil then
		info = InitRoundId()
	end 
	info.roundid = info.roundid + 1
	unilight.savedata("roundid", info)
	return info.roundid
end

-- 百人场 记录 投注信息 及 开奖信息 最后一个参数remiander兼容不同接入时 remiander计算不一致的情况
function CmdRecordUserProfitBet(uid, gameId, betChips, profitChips, roundId, betInfo, lotteryInfo, openSource, isAddItemsHistory, remainder, pump)
	openSource = openSource or 0

	local userInfo = chessuserinfodb.RUserInfoGet(uid)
	if userInfo == nil then
		unilight.error("chessprofitbet.CmdRecordUserProfitBet err " .. uid .. " is null")
		return 
	end
	-- 把玩家下注相关的数据记录在自身身上
	unilight.savedata("userinfo", userInfo)
	-- 兼容 百家乐、28gang、百人牛牛 接入捕鱼大厅时 数据记录应该转换为币
	if go.getconfigint("zone_type") == 1 then
		if gameId == 173 or gameId == 174 or gameId == 167 then
			betChips 	= math.floor(betChips/RoomMgr.ONE_COIN_TO_CHIP)
			profitChips = math.floor(profitChips/RoomMgr.ONE_COIN_TO_CHIP)

			-- 此时的remainder 应为为该玩家所有的coin
			remainder = userInfo.fish.goldroom.coin + math.floor(userInfo.property.chips/RoomMgr.ONE_COIN_TO_CHIP)
		end
	end

	local time = os.time()
	local _id = string.format("%08d", sequence)
	sequence = sequence + 1
	_id = tostring(time) .. _id
	local bProfit = false
	if profitChips > betChips then
		bProfit = true
	end
	-- 这里只统计净利润
	profitChips = profitChips - betChips

	-- 存入平台账号
	local laccount = go.accountmgr.GetAccountById(uid)
	local platAccount = laccount.JsMessage.GetPlataccount() 

	local record = {
		_id = _id,
		roundid = roundId,
		uid = uid,
		nickname = userInfo.base.nickname,
		type = 1,
		gameid = gameId,
		betchips = betChips,
		profitchips = profitChips,
		bprofit = bProfit, 
		remainder = remainder or userInfo.property.chips,
		opensource = openSource,
		pump = pump,
		platid = userInfo.base.platid,
		subplatid = userInfo.base.subplatid,
		time = chessutil.FormatDateGet(),
		timestamp = time,
		plataccount = platAccount,
	}

	-- 各个游戏 存进去的开奖结果 可能不同 获取统计数据时 再针对性提取
	if gameId == 152 or gameId == 157 or gameId == 1000 or gameId == 167 or gameId == 173 or gameId == 174 or gameId == 178 then
		local detail = {
			betInfo 	= betInfo,
			lotteryInfo = lotteryInfo,
		}
		record.detail = detail
	end
	unilight.savedata(TABLE_NAME, record)

	-- 每局游戏 均能记录记录1积分 (过滤掉 slot一局多结算的情况) --  幸运大转盘活动开始的时候 才操作
	if gameId ~= 166 or betChips ~= 0 then
		LuckyTurnTableMgr.GetIntegral(uid, 1)
	end

	-- 是否添加金币变动记录（百人场游戏 才会最后统计时结算  --11.1 捕鱼也在这里加入统计）
	if isAddItemsHistory then
		ChessItemsHistory.AddItemsHistory(uid, 1, remainder or userInfo.property.chips, profitChips, MapGameName[gameId] .. "输赢")
	end

	-- 记录玩家以月为单位人查询，为了方便统计相关
	local day = chessutil.FormatDayGet2(time)
	local _id = tostring(day ..":"..uid)
	local recordDay = unilight.getdata(TABLE_NAME_DAY,id)	
	if recordDay == nil then
		recordDay = {
			_id = _id,
			uid = uid,
			day = tonumber(day),
			nickname = userInfo.base.nickname,
			betchips = 0,
			profitchips = 0,
			platid = userInfo.base.platid,
			plataccount = platAccount,
		}
		unilight.info("uid今天第一次玩游戏，生成日汇总数据" .. uid)
	end
	recordDay.betchips = recordDay.betchips + betChips
	recordDay.profitchips = recordDay.profitchips + profitChips
	unilight.info("recordDay:" .. uid .. table.tostring(recordDay))
	unilight.savedata(TABLE_NAME_DAY, recordDay)
end

-- 公共调用,玩家所有游戏中赢的局数
function CmdAllGameWinNmuberGetByUid(uid, timestamp)
	if timestamp == nil then
		unilight.info(" 统计相关：timestamp is null, default is 0" )
		timestamp = 0
	end
	local count = unilight.startChain().Table(TABLE_NAME).Filter(unilight.a(unilight.gt("timestamp", timestamp), unilight.eq("uid", uid), unilight.eq("bprofit", "true"))).Count()
	local tempCount = GetSlotInvalidPlayNmuberGetByGameIdUid(uid, timestamp)

	return count - tempCount
end

-- 公共调用,玩家单局赢取超过某个值的数
function CmdGameWinOverThresholdNmuberGetByGameIdUid(uid, gameId, threshold, timestamp)
	if timestamp == nil then
		unilight.info(" 统计相关：timestamp is null, default is 0" )
		timestamp = 0
	end
	local count = unilight.startChain().Table(TABLE_NAME).Filter(unilight.a(unilight.eq("gameid", gameId), unilight.gt("timestamp", timestamp), unilight.eq("uid", uid), unilight.gt("profitchips", threshold))).Count()
	return count
end
-- 公共调用,玩家指定游戏赢多少局
function CmdGameWinNmuberGetByGameIdUid(uid, gameId, timestamp)
	if timestamp == nil then
		unilight.info(" 统计相关：timestamp is null, default is 0" )
		timestamp = 0
	end
	local count = unilight.startChain().Table(TABLE_NAME).Filter(unilight.a(unilight.field("gameid").Eq(gameId), unilight.gt("timestamp", timestamp), unilight.field("uid").Eq(uid), unilight.field("bprofit").Eq(true))).Count()
	
	local tempCount = 0
	-- 如果当前是统计slot 则需要过滤掉与局数无关的筹码统计
	if gameId == 166 then
		tempCount = GetSlotInvalidPlayNmuberGetByGameIdUid(uid, timestamp)
	end
	return count - tempCount
end

-- 公共调用,玩家所有游戏玩多少局
function CmdAllGamePlayNmuberGetByUid(uid, timestamp)
	if timestamp == nil then
		unilight.info(" 统计相关：timestamp is null, default is 0" )
		timestamp = 0
	end
	local count = unilight.startChain().Table(TABLE_NAME).Filter(unilight.a(unilight.gt("timestamp", timestamp), unilight.field("uid").Eq(uid))).Count()
	local tempCount = GetSlotInvalidPlayNmuberGetByGameIdUid(uid, timestamp)

	return count - tempCount
end

-- 公共调用,玩家指定游戏玩多少局
function CmdGamePlayNmuberGetByGameIdUid(uid, gameId, timestamp)
	if timestamp == nil then
		unilight.info(" 统计相关：timestamp is null, default is 0" )
		timestamp = 0
	end
	local count = unilight.startChain().Table(TABLE_NAME).Filter(unilight.a(unilight.field("gameid").Eq(gameId), unilight.gt("timestamp", timestamp), unilight.field("uid").Eq(uid))).Count()
	
	local tempCount = 0
	-- 如果当前是统计slot 则需要过滤掉与局数无关的筹码统计
	if gameId == 166 then
		tempCount = GetSlotInvalidPlayNmuberGetByGameIdUid(uid, timestamp)
	end

	return count - tempCount
end

-- 公共调用,玩家所有游戏在指定时间段内玩多少局
function CmdGamePlayNmuberGetByUidBetween(uid, timestamp1, timestamp2)
	local count = unilight.startChain().Table(TABLE_NAME).Filter(unilight.a(unilight.gt("timestamp", timestamp1), unilight.le("timestamp", timestamp2), unilight.field("uid").Eq(uid))).Count()
	
	-- 需要过滤掉slot与局数无关的筹码统计
	local tempCount = GetSlotInvalidPlayNmuberGetByGameIdUidBetween(uid, timestamp1, timestamp2)

	return count - tempCount
end

-- 公共调用,玩家指定游戏在指定时间段内赢多少局
function CmdGameWinNmuberGetByGameIdUidBetween(uid, gameId, timestamp1, timestamp2)
	local count = unilight.startChain().Table(TABLE_NAME).Filter(unilight.a(unilight.field("gameid").Eq(gameId), unilight.gt("timestamp", timestamp1), unilight.le("timestamp", timestamp2), unilight.field("uid").Eq(uid), unilight.field("bprofit").Eq(true))).Count()
	
	local tempCount = 0
	-- 如果当前是统计slot 则需要过滤掉与局数无关的筹码统计
	if gameId == 166 then
		tempCount = GetSlotInvalidPlayNmuberGetByGameIdUidBetween(uid, timestamp1, timestamp2)
	end
	return count - tempCount
end


-- 公共调用,玩家指定游戏在指定时间段内玩多少局
function CmdGamePlayNmuberGetByGameIdUidBetween(uid, gameId, timestamp1, timestamp2)
	local count = unilight.startChain().Table(TABLE_NAME).Filter(unilight.a(unilight.gt("timestamp", timestamp1), unilight.le("timestamp", timestamp2), unilight.field("uid").Eq(uid), unilight.field("gameid").Eq(gameId))).Count()
	
	local tempCount = 0
	-- 如果当前是统计slot 则需要过滤掉与局数无关的筹码统计
	if gameId == 166 then
		tempCount = GetSlotInvalidPlayNmuberGetByGameIdUidBetween(uid, timestamp1, timestamp2)
	end

	return count - tempCount
end

-- 公共调用 获取该玩家在指定时间段内的所有游戏 赢得数据 (目的用于 统计该玩家指定时间内 赢了多少筹码)
function CmdGamePlayInfoGetByUidBetween(uid, timestamp1, timestamp2)
	local info = unilight.getByFilter(TABLE_NAME, unilight.a(unilight.gt("timestamp", timestamp1), unilight.le("timestamp", timestamp2), unilight.field("uid").Eq(uid), unilight.field("bprofit").Eq(true)), 10000000)
	return info
end

-- 公共调用 获取 所有玩家指定时间段内指定游戏 的 所有投注数据 (兼容分页查询)
function CmdGamePlayInfoGetByGameIdBetween(gameId, timestamp1, timestamp2, skip, limit, openSource)
	openSource = openSource or 0
	local filter = unilight.a(unilight.field("gameid").Eq(gameId), unilight.gt("timestamp", timestamp1), unilight.le("timestamp", timestamp2), unilight.eq("type", 1))
	-- 如果指定开奖来源
	if openSource ~= 0 then
		filter = unilight.a(filter, unilight.eq("opensource", openSource))
	end
	if skip ~= nil then
		local info = unilight.chainResponseSequence(unilight.startChain().Table(TABLE_NAME).Filter(filter).Skip(skip).Limit(limit))
		local infoNum = unilight.startChain().Table(TABLE_NAME).Filter(filter).Count()
		local maxpage = math.ceil(infoNum/limit)
		return info, maxpage
	else
		local info = unilight.chainResponseSequence(unilight.startChain().Table(TABLE_NAME).Filter(filter))
		return info
	end
end

-- 公共调用 获取该玩家在指定时间段内的指定游戏 的 所有投注数据 (兼容分页查询)
function CmdGamePlayInfoGetByGameIdUidBetween(uid, gameId, timestamp1, timestamp2, skip, limit, openSource)
	openSource = openSource or 0
	local filter = unilight.a(unilight.field("gameid").Eq(gameId), unilight.gt("timestamp", timestamp1), unilight.le("timestamp", timestamp2), unilight.eq("type", 1), unilight.field("uid").Eq(uid))
	-- 如果指定开奖来源
	if openSource ~= 0 then
		filter = unilight.a(filter, unilight.eq("opensource", openSource))
	end
	if skip ~= nil then
		local info = unilight.chainResponseSequence(unilight.startChain().Table(TABLE_NAME).Filter(filter).OrderBy(unilight.asc("timestamp")).Skip(skip).Limit(limit))
		local infoNum = unilight.startChain().Table(TABLE_NAME).Filter(filter).Count()
		local maxpage = math.ceil(infoNum/limit)
		return info, maxpage
	else
		local info = unilight.chainResponseSequence(unilight.startChain().Table(TABLE_NAME).Filter(filter).OrderBy(unilight.asc("timestamp")))
		return info
	end
end

function CmdPlayInfoGetByPlatidList(platidList, timestamp1, timestamp2, skip, limit)
    local o = unilight.eq("platid", platidList[1]) --nilight.o(unilight.eq("platid", platidList[1]), unilight.eq("eq", platidList[2]))
	local filter = unilight.a(unilight.gt("timestamp", timestamp1), unilight.le("timestamp", timestamp2), o,unilight.eq("type", 1))
    if skip ~= nil then
		local info = unilight.chainResponseSequence(unilight.startChain().Table(TABLE_NAME).Filter(filter).Skip(skip).Limit(limit))
		local infoNum = unilight.startChain().Table(TABLE_NAME).Filter(filter).Count()
		local maxpage = math.ceil(infoNum/limit)
		return info, maxpage
	else
		local info = unilight.chainResponseSequence(unilight.startChain().Table(TABLE_NAME).Filter(filter))
        return info
	end
end

-- 查询指定列表数据
function CmdUserInfoGetByPlatidList(platidList, skip, limit)
    local filter = unilight.eq("base.platid", platidList[1]) --nilight.o(unilight.eq("platid", platidList[1]), unilight.eq("eq", platidList[2]))
	--local filter = unilight.a(unilight.le("timestamp", timestamp2), o,unilight.eq("type", 1))
    local infoNum = unilight.startChain().Table("userinfo").Filter(filter).Count()
    local info = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Filter(filter).Skip(skip).Limit(limit))
    local maxpage = math.ceil(infoNum/limit)
    return info, maxpage
end

function QueryPlatDayUserBetByPlatId(platId, startDay, endDay)
    --unilight.info("alll" .. table.tostring(unilight.getAll(TABLE_NAME_DAY)))
    local ret = unilight.chainResponseSequence(unilight.startChain().Table(TABLE_NAME_DAY).Aggregate('{"$match":{"platid":{"$eq":' .. platId.. '}, "day":{ "$gte" : ' .. startDay.. ', "$lte" : ' .. endDay.. '}}}','{"$group":{"_id":"$day","count":{"$sum":1}, "profit":{"$sum":"$profitchips"}}}'))
   local rdata = {}
    for i, v in ipairs(ret) do
	local item = {
		dau = v.count,
		profit = v.profit,
		payout = v.profit,
		betusers = v.count,
	}
	table.insert(rdata, item)
    end
    return rdata
end

function QueryPlatUserBetByPlatId(platId, startDay, endDay)
    local dau = 0
    local betusers = 0
    local bet = 0
    local payout = 0
    local profit = 0
    local count = unilight.chainResponseSequence(unilight.startChain().Table(TABLE_NAME_DAY).Aggregate('{"$match":{"platid":{"$eq":' .. platId.. '}, "day":{ "$gte" : ' .. startDay.. ', "$lte" : ' .. endDay.. '}}}','{"$group":{"_id":"$uid","count":{"$sum":1}}}'))
    dau = (count[1] and count[1].count) or 0
    betusers = dau
    local info = unilight.chainResponseSequence(unilight.startChain().Table(TABLE_NAME_DAY).Aggregate('{"$match":{"platid":{"$eq":' .. platId.. '}, "day":{ "$gt" : ' .. startDay.. ', "$lte" : ' .. endDay.. '}}}','{"$group":{"_id":"$platid", "profit":{"$sum":"$profitchips"}}}'))
    local platInfo = info[1]
    if platInfo ~= nil then
	profit = platInfo.profit
	payout = bet + profit
    end
    unilight.info("查询plat总数据" .. startDay .. " ->" .. endDay .. "  " .. dau)
    return dau, betusers, bet, payout, profit
end

-- 公共调用 获取 所有玩家指定时间段内所有游戏 的 所有投注数据 (兼容分页查询)
--
function CmdGamePlayInfoGetByBetween(timestamp1, timestamp2, skip, limit)
	local filter = unilight.a(unilight.gt("timestamp", timestamp1), unilight.le("timestamp", timestamp2), unilight.eq("type", 1))
	if skip ~= nil then
		local info = unilight.chainResponseSequence(unilight.startChain().Table(TABLE_NAME).Filter(filter).Skip(skip).Limit(limit))
		local infoNum = unilight.startChain().Table(TABLE_NAME).Filter(filter).Count()
		local maxpage = math.ceil(infoNum/limit)
		return info, maxpage
	else
		local info = unilight.chainResponseSequence(unilight.startChain().Table(TABLE_NAME).Filter(filter))
		return info
	end
end

-- 公共调用 获取该玩家在指定时间段内的所有游戏 的 所有投注数据 (兼容分页查询)
function CmdGamePlayInfoGetByUidBetween(uid, timestamp1, timestamp2, skip, limit)
	local filter = unilight.a(unilight.gt("timestamp", timestamp1), unilight.le("timestamp", timestamp2), unilight.eq("type", 1), unilight.field("uid").Eq(uid))
	if skip ~= nil then
		local info = unilight.chainResponseSequence(unilight.startChain().Table(TABLE_NAME).Filter(filter).Skip(skip).Limit(limit))
		local infoNum = unilight.startChain().Table(TABLE_NAME).Filter(filter).Count()
		local maxpage = math.ceil(infoNum/limit)
		return info, maxpage
	else
		local info = unilight.chainResponseSequence(unilight.startChain().Table(TABLE_NAME).Filter(filter))
		return info
	end
end

function CmdRecordUserBeBanker(uid, gameId, carryBankerChips, remainderBankerChips, bWinAll, roundId, openSource, remainder, pump)
	openSource = openSource or 0

	local userInfo = chessuserinfodb.RUserInfoGet(uid)
	if userInfo == nil then
		unilight.error("chessprofitbet.CmdRecordUserBeBanker err " .. uid .. " is null")
		return 
	end

	-- 兼容 百家乐、28gang、百人牛牛 接入捕鱼大厅时 数据记录应该转换为币
	if go.getconfigint("zone_type") == 1 then
		if gameId == 173 or gameId == 174 or gameId == 167 then
			carryBankerChips 		= math.floor(carryBankerChips/RoomMgr.ONE_COIN_TO_CHIP)
			remainderBankerChips 	= math.floor(remainderBankerChips/RoomMgr.ONE_COIN_TO_CHIP)

			-- 此时的remainder 应为为该玩家所有的coin
			remainder = userInfo.fish.goldroom.coin + math.floor(userInfo.property.chips/RoomMgr.ONE_COIN_TO_CHIP)
		end
	end

	local time = os.time()
	local _id = string.format("%08d", sequence)
	_id = tostring(time) .. _id

	local bProfit = false
	if remainderBankerChips > carryBankerChips then
		bProfit = true
	end

	local laccount = go.accountmgr.GetAccountById(uid)
	local platAccount = laccount.JsMessage.GetPlataccount() 

	local record = {
		_id = _id,
		type = 2,
		uid = uid,
		roundid = roundId,
		nickname = userInfo.base.nickname,
		gameid = gameId,
		carrybankerchips = carryBankerChips,
		bwinall = bWinAll,
		remainderbankerchips = remainderBankerChips,
		bprofit = bProfit, 
		opensource = openSource,
		pump = pump,
		platid = userInfo.base.platid,
		subplatid = userInfo.base.subplatid,
		time = chessutil.FormatDateGet(),
		timestamp = time,
		remainder = remainder or userInfo.property.chips,
		profitchips = remainderBankerChips - carryBankerChips,		-- 存多个字段 兼容 输赢排行榜
		plataccount = platAccount 									-- 捕鱼后台系统 需要这个字段用于显示
	}
	unilight.savedata(TABLE_NAME, record)
end

function CmdGameBankerNmuberGetByGameIdUid(uid, gameId, timestamp)
	if timestamp == nil then
		unilight.info(" 统计相关：timestamp is null, default is 0" )
		timestamp = 0
	end

	local count = unilight.startChain().Table(TABLE_NAME).Filter(unilight.a(unilight.field("gameid").Eq(gameId), unilight.gt("timestamp", timestamp), unilight.eq("type", 2), unilight.field("uid").Eq(uid))).Count()
	return count
end

-- 公共调用,玩家做庄，并赢取所有人时
function CmdGameWinAllBeBossNmuberGetByGameIdUid(uid, gameId, timestamp)
	if timestamp == nil then
		unilight.info(" 统计相关：timestamp is null, default is 0" )
		timestamp = 0
	end
	local count = unilight.startChain().Table(TABLE_NAME).Filter(unilight.a(unilight.eq("gameid", gameId),unilight.gt("timestamp", timestamp), unilight.eq("type", 2), unilight.eq("uid", uid), unilight.field("bwinall").Eq(true))).Count()
	return count
end

-- 公共调用 获取 所有玩家指定时间段内指定游戏 的 所有庄家数据 
function CmdGameBankerInfoGetByGameIdBetween(gameId, timestamp1, timestamp2, openSource)
	openSource = openSource or 0
	local filter = unilight.a(unilight.field("gameid").Eq(gameId), unilight.gt("timestamp", timestamp1), unilight.le("timestamp", timestamp2), unilight.eq("type", 2))
	if openSource ~= 0 then
		filter = unilight.a(filter, unilight.eq("opensource", openSource))
	end
	local info = unilight.getByFilter(TABLE_NAME, filter, 10000000)
	return info
end

-- 公共调用 获取该玩家在指定时间段内的指定游戏 的 所有庄家数据  (支持分页查询)
function CmdGameBankerInfoGetByGameIdUidBetween(uid, gameId, timestamp1, timestamp2, skip, limit, openSource)
	openSource = openSource or 0
	local filter = unilight.a(unilight.eq("gameid", gameId), unilight.gt("timestamp", timestamp1), unilight.le("timestamp", timestamp2), unilight.eq("type", 2), unilight.eq("uid", uid))
	if openSource ~= 0 then
		filter = unilight.a(filter, unilight.eq("opensource", openSource))
	end	
	if skip ~= nil then
		local info = unilight.chainResponseSequence(unilight.startChain().Table(TABLE_NAME).Filter(filter).OrderBy(unilight.asc("timestamp")).Skip(skip).Limit(limit))
		local infoNum = unilight.startChain().Table(TABLE_NAME).Filter(filter).Count()
		local maxpage = math.ceil(infoNum/limit)
		return info, maxpage
	else
		local info = unilight.chainResponseSequence(unilight.startChain().Table(TABLE_NAME).Filter(filter).OrderBy(unilight.asc("timestamp")))
		return info
	end
end

-- 公共调用 获取 所有玩家指定时间段内所有游戏 的 所有庄家数据 
function CmdGameBankerInfoGetByBetween(timestamp1, timestamp2)
	local info = unilight.getByFilter(TABLE_NAME, unilight.a(unilight.gt("timestamp", timestamp1), unilight.le("timestamp", timestamp2), unilight.eq("type", 2)), 10000000)
	return info
end

-- 公共调用 获取该玩家在指定时间段内的所有游戏 的 所有庄家数据 
function CmdGameBankerInfoGetByUidBetween(uid, timestamp1, timestamp2)
	local info = unilight.getByFilter(TABLE_NAME, unilight.a(unilight.gt("timestamp", timestamp1), unilight.le("timestamp", timestamp2), unilight.eq("type", 2), unilight.field("uid").Eq(uid)), 10000000)
	return info
end


-----------------------------获取所有统计数据不区分坐庄还是玩家投注---------------------------------
-- 公共调用 获取 所有玩家指定时间段内指定游戏 的 所有数据 (兼容分页查询)
function CmdStaticInfoGetByGameIdBetween(gameId, timestamp1, timestamp2, skip, limit, openSource)
	openSource = openSource or 0
	local filter = unilight.a(unilight.eq("gameid", gameId), unilight.gt("timestamp", timestamp1), unilight.le("timestamp", timestamp2))
	-- 如果指定开奖来源
	if openSource ~= 0 then
		filter = unilight.a(filter, unilight.eq("opensource", openSource))
	end
	if skip ~= nil then
		local info = unilight.chainResponseSequence(unilight.startChain().Table(TABLE_NAME).Filter(filter).OrderBy(unilight.asc("timestamp")).Skip(skip).Limit(limit))
		local infoNum = unilight.startChain().Table(TABLE_NAME).Filter(filter).Count()
		local maxpage = math.ceil(infoNum/limit)
		return info, maxpage
	else
		local info = unilight.chainResponseSequence(unilight.startChain().Table(TABLE_NAME).Filter(filter).OrderBy(unilight.asc("timestamp")))
		return info
	end
end
-----------------------------过滤一局多结算--------------------------------------

-- 由于slot一局游戏 可能出现多次筹码变化 因此没有投注的筹码统计 认为其不是一局游戏--

-- 获取slot 在指定时间内的 非等同局数的筹码统计
function GetSlotInvalidPlayNmuberGetByGameIdUidBetween(uid, timestamp1, timestamp2)
	local count = unilight.startChain().Table(TABLE_NAME).Filter(unilight.field("gameid").Eq(166), unilight.gt("timestamp", timestamp1), unilight.le("timestamp", timestamp2), unilight.a(unilight.eq("type", 1), unilight.field("uid").Eq(uid), unilight.field("betchips").Eq(0))).Count()
	return count
end

-- 获取slot 非等同局数的筹码统计
function GetSlotInvalidPlayNmuberGetByGameIdUid(uid, timestamp)
	if timestamp == nil then
		unilight.info(" 统计相关：timestamp is null, default is 0" )
		timestamp = 0
	end
	local count = unilight.startChain().Table(TABLE_NAME).Filter(unilight.field("gameid").Eq(166), unilight.gt("timestamp", timestamp), unilight.a(unilight.eq("type", 1), unilight.field("uid").Eq(uid), unilight.field("betchips").Eq(0))).Count()
	return count
end
