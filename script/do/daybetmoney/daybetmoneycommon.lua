module('DayBetMoney', package.seeall)
DB_Name = 'daybetmoney'

-- 记录保存天数
local saveDayTimes = 30
-- 获取下注记录信息
function GetDayBetMoneyInfo(uid)
	-- 获取数据库信息
	local dayBetMoneyInfo = unilight.getdata(DB_Name,uid)
	-- 没有则初始化信息
	if table.empty(dayBetMoneyInfo) then
		dayBetMoneyInfo = {
			_id = uid,                                      -- 玩家ID
			betMoneyMap = {},								-- 每日下注金额
			betNumMap = {},									-- 每日下注次数
		}
		unilight.savedata(DB_Name,dayBetMoneyInfo)
	end
	-- 初始化每日列表
	local todayTime = chessutil.ZeroTodayTimestampGet()
	if dayBetMoneyInfo.betMoneyMap[todayTime] == nil then
		dayBetMoneyInfo.betMoneyMap[todayTime] = 0
		dayBetMoneyInfo.betNumMap[todayTime] = 0
		-- 清理数据
		for time, info in pairs(dayBetMoneyInfo.betMoneyMap) do
			if time < todayTime - (saveDayTimes * 24 * 3600) then
				dayBetMoneyInfo.betMoneyMap[time] = nil
			end
		end
		for time, info in pairs(dayBetMoneyInfo.betNumMap) do
			if time < todayTime - (saveDayTimes * 24 * 3600) then
				dayBetMoneyInfo.betNumMap[time] = nil
			end
		end
		unilight.savedata(DB_Name,dayBetMoneyInfo)
	end
	return dayBetMoneyInfo
end

-- 添加流水
function AddDayBetMoney(uid,addNum)
	local dayBetMoneyInfo = GetDayBetMoneyInfo(uid)
	dayBetMoneyInfo.betMoneyMap[chessutil.ZeroTodayTimestampGet()] = dayBetMoneyInfo.betMoneyMap[chessutil.ZeroTodayTimestampGet()] + addNum
	dayBetMoneyInfo.betNumMap[chessutil.ZeroTodayTimestampGet()] = dayBetMoneyInfo.betNumMap[chessutil.ZeroTodayTimestampGet()] + 1
	unilight.savedata(DB_Name,dayBetMoneyInfo)
end

-- 统计流水合计
function GetSumBetMoney(uid,startTime,endTime)
	local dayBetMoneyInfo = GetDayBetMoneyInfo(uid)
	local startBeforeTime = chessutil.ZeroTodayTimestampGet(startTime)
	local endBeforeTime = chessutil.ZeroTodayTimestampGet(endTime)
	local sumBetMoney = 0
	local sumBetNum = 0
	local pointTime = startBeforeTime
	for day = 1, chessutil.DateDayDistanceByTimeGet(startBeforeTime, endBeforeTime) + 1 do
		-- 容错判断
		if pointTime > endBeforeTime then
			break
		end
		dayBetMoneyInfo.betMoneyMap[pointTime] = dayBetMoneyInfo.betMoneyMap[pointTime] or 0
		sumBetMoney = sumBetMoney + dayBetMoneyInfo.betMoneyMap[pointTime]
		dayBetMoneyInfo.betNumMap[pointTime] = dayBetMoneyInfo.betNumMap[pointTime] or 0
		sumBetNum = sumBetNum + dayBetMoneyInfo.betNumMap[pointTime]
		pointTime = pointTime + 60 * 60 * 24
	end
	local res = {
		sumBetMoney = sumBetMoney,
		sumBetNum = sumBetNum,
	}
	return res
end