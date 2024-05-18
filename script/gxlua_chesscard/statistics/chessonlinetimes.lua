module('ChessOnlineTimes', package.seeall) 
-- 玩家各个游戏上线时长统计

TABLE_NAME = "userOnlineTimes"

-- 数据表初始化
function CreateDb()
	unilight.createdb(TABLE_NAME, "uid")
end

-- 初始化 玩家 各个游戏在线时长 统计表
function InitUserOnlineTimes(uid)
	local time = os.time()

	local userInfo = chessuserinfodb.RUserInfoGet(uid)
	if userInfo == nil then
		unilight.error("ChessOnlineTimes.CmdRecordUserOnlineTimes err " .. uid .. " is null")
		return 
	end

	local onlineTime = {
		uid = uid,
		platid = userInfo.base.platid,
		subplatid = userInfo.base.subplatid,
		onlinetime = {},						-- gameid:{todaytimes, totaltimes, timestamp} 
	}
	unilight.savedata(TABLE_NAME, onlineTime)

	return onlineTime
end

-- 更新在线时长
-- 指定游戏 上线时间 下线时间 
function UpdateOnlineTimes(uid, gameId, upTimes, downTimes)
	local onlineTime = unilight.getdata(TABLE_NAME, uid)
	if onlineTime == nil then 
		onlineTime = InitUserOnlineTimes(uid)
	end

	-- 获取该gameid下的数据 无则初始化
	local theGameOnlineTime = onlineTime.onlinetime[gameId]
	if theGameOnlineTime == nil then
		theGameOnlineTime = {
			todaytimes = 0,
			totaltimes = 0,
			timestamp  = os.time(),
		}
	end

	-- 各种时长增幅
	local addTotaltimes = downTimes - upTimes
	local addTodaytimes = 0
	-- 获取当天零点时间
	local temp = os.date("*t", os.time())
	local zeroTime = os.time({year=temp.year, month=temp.month, day=temp.day, hour=0})
	if upTimes < zeroTime then
		addTodaytimes = downTimes - zeroTime
	else
		addTodaytimes = downTimes - upTimes
	end

	theGameOnlineTime.totaltimes = theGameOnlineTime.totaltimes + addTotaltimes 
	-- 如果上次记录的时间 不是今天 则今天在线时间清零后 再加上当前的
	if theGameOnlineTime.timestamp < zeroTime then 
		theGameOnlineTime.todaytimes = addTodaytimes
	else
		theGameOnlineTime.todaytimes = theGameOnlineTime.todaytimes + addTodaytimes
	end

	-- 更新记录时间
	theGameOnlineTime.timestamp  = os.time()

	-- 存档 
	onlineTime.onlinetime[gameId] = theGameOnlineTime
	unilight.savedata(TABLE_NAME, onlineTime)

	return onlineTime
end

-- 获取指定游戏在线时长
function GetOnlineTimesByUidGameId(uid, gameId)
	-- 在大厅位置 获取时  先更新一下 最新的时间数据 
	local onlineTime = UpdateOnlineTimes(uid, gameId, os.time(), os.time())

	local theGameOnlineTime = onlineTime.onlinetime[gameId]

	return theGameOnlineTime.todaytimes, theGameOnlineTime.totaltimes
end

