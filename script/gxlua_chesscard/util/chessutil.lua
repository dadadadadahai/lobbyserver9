module('chessutil', package.seeall)

--2017/1/2
--北京2017/1/2 00:00:00
-- iStandTime = 1483286400

-- iStandTime = os.time({year=2017, month=1, day=2, hour=0, minute = 0, second = 0})

-- 通过日期(yyyy-mm-dd hh:mm:ss) 得到go.time.Sec()类型的秒
function TimeByDateGet(date)
	local a = StrSplit(date, " ")
	local b = StrSplit(a[1], "-")
	local c = StrSplit(a[2], ":")
	local time = os.time{year=tonumber(b[1]), month=tonumber(b[2]), day=tonumber(b[3]), hour=tonumber(c[1]), min=tonumber(c[2]), sec=tonumber(c[3])}
	return time
end

-- 通过日期(yyyy-mm-dd/hh:mm:ss) 得到go.time.Sec()类型的秒	仅用于GM命令时 空格被用于分割参数 因此不能正常传时间
function TimeBySpecialDateGet(date)
	local a = StrSplit(date, "/")
	local b = StrSplit(a[1], "-")
	local c = StrSplit(a[2], ":")
	local time = os.time{year=tonumber(b[1]), month=tonumber(b[2]), day=tonumber(b[3]), hour=tonumber(c[1]), min=tonumber(c[2]), sec=tonumber(c[3])}
	return time
end

function DateByFormatDateGet(date)
	local a = StrSplit(date, " ")
	local b = StrSplit(a[1], "-")
	local c = StrSplit(a[2], ":")
	local date = {year=b[1], month=b[2], day=b[3], hour=c[1], min=c[2], sec=c[3]}
	return date	
end

--取得当前date，格式：(yyyy-mm-dd hh:mm:ss)
function FormatDateGet(seconds,dateformat)
	seconds = seconds or os.time()
	dateformat = dateformat or "%Y-%m-%d %H:%M:%S"
	seconds = tonumber(seconds)
	return os.date(dateformat, seconds)
end

function FormatDate2Get(time)
	local date = DateByFormatDateGet(FormatDateGet(time))
	return tostring(date.year) .. date.month .. date.day .. date.hour .. date.min .. date.sec
end

-- 取得当前日期2
function FormatDayGet2(time)
	seconds = time or go.time.Sec()
	dateFormat = "%Y%m%d"
	return os.date(dateFormat, seconds)
end

-- 取得当前日期
function FormatDayGet(time)
	seconds = time or go.time.Sec()
	dateFormat = "%Y-%m-%d"
	return os.date(dateFormat, seconds)
end

-- 获取指定时间 凌晨的时间戳
function ZeroTodayTimestampGetByTime(time)
	local zeroToday = ZeroTodayTimestampGet(time)
	return zeroToday
end

-- 获取当天凌晨的时间戳
function ZeroTodayTimestampGet(timeStamp)
    if not timeStamp then
        timeStamp = os.time()
    end
    --获得时间格式
    local formatTime = os.date("*t", timeStamp)
    formatTime.hour = 0
    formatTime.min = 0
    formatTime.sec = 0
    local curTimestamp = GetTimeByFormat(timeStamp, 0,0,0)
    return curTimestamp
end
local secondsInOneDay = 24 * 60 * 60
-- 获取距离当前N天凌晨0点的时间戳
function getTimestampForLastNDaysMidnight(day)
	if day < 0 then
		day = 0
	end
	if type(day) ~= "number" then
		day = 0
	end
	local currentTime = ZeroTodayTimestampGet()
	timestamp = currentTime -  ((day) * secondsInOneDay  )
	return timestamp
end

-- 获取当周第一天凌晨的时间戳
function ZeroWeekTimestampGet(currentTime)
	currentTime = currentTime or os.time()
	local currentWeek = tonumber(os.date("%w", currentTime))

	-- 默认获取到的是 周四的0点
	local zeroWeek = currentTime - (currentTime+8*60*60)%(7*24*60*60)
	
	if currentWeek >= 1 and currentWeek <= 3 then
		-- 如果当前时间为周四之前 则当前获取到的为上周的周四 则周一0点需要加上4天
		zeroWeek = zeroWeek + 4*24*60*60
	else
		-- 如果当前时间为周四之后 则当前获取到的为本周的周四 则周一0点需要减去3天
		zeroWeek = zeroWeek - 3*24*60*60
	end
	return zeroWeek
end

-- 判断两个时间相距天数
function DateDayDistanceByTimeGet(lasttime, current)
	current = current or go.time.Sec()
	local daySeconds = 3600 * 24
	local lastTime = math.floor(tonumber(lasttime)/daySeconds)
	local current = math.floor(tonumber(current)/daySeconds)
	return math.abs(current - lastTime)
end

function DateDayDistanceByDateGet(last, current)
	local lastTime = TimeByDateGet(last)
	local currentTime = TimeByDateGet(current)
	return DateDayDistanceByTimeGet(lastTime, currentTime)
end

function StrSplit(str, pat)
	local t = {}
	local fpat = "(.-)" .. pat
	local last_end = 1
	local s, e, cap = str:find(fpat, 1)
	while s do
		if s ~= 1 or cap ~= "" then
			table.insert(t, cap)
		end	
		last_end = e + 1
		s, e, cap = str:find(fpat, last_end)
	end	
	if last_end <= #str then
		cap = str:sub(last_end)
		table.insert(t, cap)
	end

	return t
end

-- 1到max之间生成n个随机数，返回的数组长度为0表示生成失败
-- 最终取出来的值 包含max
function RandNNumbers(max, n) 
	local  retList = {}
	local  retMap = {}
	if max <= 0 or  n > max then
		unilight.error("机器人投注筹码生成有误  RandNNumbers：" .. max .. "," .. n)
		return retList
	end
	for i=1,n do
		for try=1,100 do
			local value = math.random(1, max)
			if retMap[value]  == nil then
				retMap[value] = true
				retList[i] = value
				break
			end
		end
		if retList[i] == nil then
			for value=1,max do
				if retMap[value]  == nil then
					retMap[value] = true
					retList[i] = value
					break
				end
			end
		end
	end
	return retList
end

-- min到max之间生成n个不重复随机数
-- 最终取出来的值 包含max
function NotRepeatRandomNumbers(min, max, n)
	-- --必须写这个，或者有其他的写法，这个是设置时间的，没有这个每次随即出来的数都会一样
	-- math.randomseed(tostring(os.time()):reverse():sub(1, 7)) --设置时间种子
	local tb = {}
	while #tb < n do 
		local istrue = false
		local num = math.random( min,max )
		if #tb ~= nil then
			for i = 1 ,#tb do
				if tb[i] == num then
					istrue = true
				end
			end
		end
		if istrue == false then
			table.insert( tb, num )
		end
	end
	return tb
end


--计算是否有跨天,指定的小时数
--currentTime 当前秒数
--lastTime --上次更新的秒数
--hourSec  --要检查的秒数，例如1点=3600
function CheckCrossDay(curTime, lastTime, hourSec)
	local iRet = false
	local curDay = math.floor(curTime / 86400)
	local lastDay = math.floor(lastTime / 86400)
	local curDate = os.date("*t", curTime)
	local targetSec = os.time({day=curDate.day, month=curDate.month, year=curDate.year, hour=0, minute=0, second=0}) + hourSec
	if curDay ~= lastDay and curTime >= targetSec then
		iRet = true
	end
	return iRet
end

--获和当前周几
function GetWeekDay(iTime)
    local iTime = iTime or os.time()
    local wDay = tonumber(os.date("%w",iTime))
    if wDay == 0 then
        return 7
    else
        return wDay
    end
end

--0点算天
function GetMorningDayNo(iSec)
    local iSec = iSec or os.time()
    local iTime = iSec - iStandTime
    local iDayMorningNo = math.floor((iTime) / (3600*24))
    return iDayMorningNo
end

--0点算天开始时间截,iNo+1是结束时间截
function GetMorningDayNo2Time(iNo)
    local iSec = (iNo*86400) + iStandTime
    return iSec
end

--0点算星期
function GetMorningWeekNo(iSec)
    local iSec = iSec or os.time()
    local iTime = iSec - iStandTime
    local iWeekNo = math.floor((iTime)/(7*3600*24))
    return iWeekNo
end

--0点算周开始时间截,iNo+1是结束时间截
function GetMorningWeekNo2Time(iNo)
    local iSec = (iNo*604800) + iStandTime
    return iSec
end

--生成随机字符串
function GetRandomStr(n) 
    local t = {
        "0","1","2","3","4","5","6","7","8","9",
        "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
        "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
    }    
    local s = ""
    for i =1, n do
        s = s .. t[math.random(#t)]        
    end;
    return s
end

--获得指定时间的时间戳
function GetTimeByFormat(timestamp, hour, min, sec)
    timestamp = timestamp or os.time()
    hour = hour or 0
    min = min or 0
    sec = sec or 0
    local date = os.date("*t", timestamp)
    --这里返回的是你指定的时间点的时间戳
    return os.time({year=date.year, month=date.month, day=date.day, hour=hour, minute = min, second = sec})
end

