--徽章处理
module('Badge', package.seeall)
Table_BadgeLevel = require "table/table_badge_level"
Table_BadgeReward = require "table/table_badge_reward"
local tableMailConfig = import "table/table_mail_config"
-- 显示天数
local onDayTime = 60 * 60 * 24
-- 因为包含当天所以减一天
dayTime = (#Table_BadgeReward - 1) * onDayTime
DB_Log_Name = "badgelog"
-- 界面信息
function BadgeInfo(uid)
	local userInfo = unilight.getdata('userinfo',uid)
	print("==============================================================")
	print(os.time() - dayTime - onDayTime)
	print(os.time())
	-- 获取今日合计下注金额/数量
	local sumBetMoneyInfo = DayBetMoney.GetSumBetMoney(uid,os.time() - dayTime - onDayTime,os.time())
	-- 获取昨日合计下注金额/数量
	local sumYesterdayBetMoneyInfo = DayBetMoney.GetSumBetMoney(uid,os.time() - dayTime - onDayTime,os.time() - onDayTime)
	-- 今日未领取
	local todayIsNoGet = userInfo.status.badgeGetDays[chessutil.ZeroTodayTimestampGet()] == nil
	-- 判断是否需要重置
	if (todayIsNoGet and table.len(userInfo.status.badgeGetDays) > #Table_BadgeReward) then
		-- 签到满了
		userInfo.status.badgeGetDays = {}
		unilight.savedata('userinfo',userInfo)
	elseif table.len(userInfo.status.badgeGetDays) > 1 and userInfo.status.badgeGetDays[chessutil.ZeroTodayTimestampGet() - onDayTime] == nil then
		-- 签到一天以上 但是昨天没签到的 算是断签
		userInfo.status.badgeGetDays = {}
		unilight.savedata('userinfo',userInfo)
	elseif table.len(userInfo.status.badgeGetDays) == 1 and userInfo.status.badgeGetDays[chessutil.ZeroTodayTimestampGet() - onDayTime] == nil and userInfo.status.badgeGetDays[chessutil.ZeroTodayTimestampGet()] == nil then
		-- 只签到一天 并且今天和昨天都没有签到的 算是断签
		userInfo.status.badgeGetDays = {}
		unilight.savedata('userinfo',userInfo)
	end
	local flag = false
	if todayIsNoGet and sumYesterdayBetMoneyInfo.sumBetMoney > Table_BadgeLevel[1].max and table.len(userInfo.status.badgeGetDays) < #Table_BadgeReward then
		flag = true
	end
	local level = 1
	for id, info in ipairs(Table_BadgeLevel) do
		if sumBetMoneyInfo.sumBetMoney >= info.min and sumBetMoneyInfo.sumBetMoney <= info.max then
			level = id
		end
	end
	if sumBetMoneyInfo.sumBetMoney > Table_BadgeLevel[#Table_BadgeLevel].max then
		sumBetMoneyInfo.sumBetMoney = Table_BadgeLevel[#Table_BadgeLevel].max
	end
	if sumYesterdayBetMoneyInfo.sumBetMoney > Table_BadgeLevel[#Table_BadgeLevel].max then
		sumYesterdayBetMoneyInfo.sumBetMoney = Table_BadgeLevel[#Table_BadgeLevel].max
	end
	dump(sumBetMoneyInfo,"徽章处理sumBetMoneyInfo",10)
	dump(sumYesterdayBetMoneyInfo,"徽章处理sumYesterdayBetMoneyInfo",10)
	local res = {
		sumBetMoney = sumBetMoneyInfo.sumBetMoney,																-- 合计下注金额
		sumBetNum = sumBetMoneyInfo.sumBetNum,																	-- 合计下注次数
		continuesDay = table.len(userInfo.status.badgeGetDays),													-- 连续领取天数
		rewardList = GetRewardList(uid,sumBetMoneyInfo.sumBetMoney,sumYesterdayBetMoneyInfo.sumBetMoney),		-- 等级
		level = level,																							-- 等级
		flag = flag,																							-- 是否可领取
	}
	return res
end

-- 领取奖励
function GetBadgeReward(uid)
	local userInfo = unilight.getdata('userinfo',uid)
	-- 今日领取过不再领取
	if userInfo.status.badgeGetDays[chessutil.ZeroTodayTimestampGet()] ~= nil then
		return
	end
	-- 获取合计下注金额
	local sumBetMoneyInfo = DayBetMoney.GetSumBetMoney(uid,chessutil.ZeroTodayTimestampGet() - dayTime - onDayTime,chessutil.ZeroTodayTimestampGet() - onDayTime)
	-- 不满足第二档次及以上 不给钱
	if sumBetMoneyInfo.sumBetMoney <= Table_BadgeLevel[1].max then
		return
	end
	local goldNum = math.floor(sumBetMoneyInfo.sumBetMoney * (Table_BadgeReward[table.len(userInfo.status.badgeGetDays) + 1].reward / 10000))

	userInfo.status.badgeGetDays[chessutil.ZeroTodayTimestampGet()] = goldNum
	userInfo.property.totalbadgechips = userInfo.property.totalbadgechips + goldNum
	unilight.savedata('userinfo',userInfo)

	if goldNum > 0 then
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, goldNum, Const.GOODS_SOURCE_TYPE.BADGE)
		-- 发送邮件
		local mailInfo = {}
		local mailConfig = tableMailConfig[37]
		mailInfo.charid = uid
		mailInfo.subject = mailConfig.subject
		mailInfo.content = string.format(mailConfig.content,goldNum/100)
		mailInfo.type = 0
		mailInfo.attachment = {}
		mailInfo.extData = {}
		ChessGmMailMgr.AddGlobalMail(mailInfo)
		-- 获取当前等级
		local level = 1
		for id, info in ipairs(Table_BadgeLevel) do
			if sumBetMoneyInfo.sumBetMoney >= info.min and sumBetMoneyInfo.sumBetMoney <= info.max then
				level = id
			end
		end
		-- 添加日志
		AddLog(uid,level,table.len(userInfo.status.badgeGetDays),goldNum,sumBetMoneyInfo.sumBetMoney)
    end
	local res = {
		goldNum = goldNum,
	}
	return res
end

-- 生成领取金额列表
function GetRewardList(uid,sumBetMoney,sumYesterdayBetMoney)
	local userInfo = unilight.getdata('userinfo',uid)
	local rewardList = {}
	-- 距离初始天数的距离  今天没领取就是长度 已经领取了就是长度减一
	local differenceFirstTime = 0
	if userInfo.status.badgeGetDays[chessutil.ZeroTodayTimestampGet()] == nil then
		-- 今日未领取
		differenceFirstTime = table.len(userInfo.status.badgeGetDays)
	else
		-- 今日已领取
		differenceFirstTime = table.len(userInfo.status.badgeGetDays) - 1
	end
	-- 获取初始天数时间戳
	local firstTime = chessutil.ZeroTodayTimestampGet() - (differenceFirstTime) * onDayTime
	for id = 1, #Table_BadgeReward do
		if userInfo.status.badgeGetDays[firstTime + (id - 1) * onDayTime] ~= nil then
			print("1111111=",id)
			-- 领取过的天数
			table.insert(rewardList,math.floor(userInfo.status.badgeGetDays[firstTime + (id - 1) * onDayTime]))
		elseif userInfo.status.badgeGetDays[chessutil.ZeroTodayTimestampGet()] == nil and id == differenceFirstTime + 1 then
			print("2222222=",id)
			-- 未领取并且是今天的这一行
			if sumYesterdayBetMoney <= 0 then
				table.insert(rewardList,math.floor(sumBetMoney * (Table_BadgeReward[id].reward / 10000)))
			else
				table.insert(rewardList,math.floor(sumYesterdayBetMoney * (Table_BadgeReward[id].reward / 10000)))
			end
		else
			print("333333=",id)
			-- 未领取
			table.insert(rewardList,math.floor(sumBetMoney * (Table_BadgeReward[id].reward / 10000)))
		end
	end
	return rewardList
end

-- 添加日志记录
function AddLog(uid,level,day,receivegold,allbet)
	local datainfo = {
		uid = uid,
		level = level,
		day = day,
		receivegold = receivegold,
		allbet = allbet,
		datetime = os.time(),
	}
	unilight.savedata(DB_Log_Name,datainfo)
end