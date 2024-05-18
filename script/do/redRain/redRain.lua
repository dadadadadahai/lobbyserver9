--红包雨处理
module('redRain', package.seeall)
Table_RedRainTime = require "table/table_redRain_time"
Table_RedRainTimeNum = require "table/table_redRain_timeNum"
Table_RedRainGoldNum = require "table/table_redRain_goldNum"
DB_Name = "redrain"
DB_GrantLog_Name = "redraingrantlog"
DB_GetLog_Name = "redraingetlog"
local tableMailConfig = import "table/table_mail_config"
-- GM命令是否触发
GmFlag = 0
-- GM
gmStartTime = 0
gmEndTime = 0

--红包雨id,应该是一个时间戳
redId = 0
-- 本轮首次红包雨ID
firstRedId = 0
-- 本轮开始时间
startTime = 0
-- 本轮末次红包雨ID
endRedId = 0
-- 本轮结束时间
endTime = 0
--产生红包雨时间列表
timeList = {}
-- 玩家领取记录
history = {}
-- 每次红包持续时间
local duration = 3 * 60
--每秒计时器,,判断是否出发红包雨
function redLoop()
    -- 今日凌晨时间戳
    local timeToDay = chessutil.ZeroTodayTimestampGet()
    -- 距离今日凌晨的时间秒
    local times = os.time() - timeToDay

    -- 结束那一秒开始判断
    if endRedId ~= 0 and os.time() >= endRedId + duration then
        -- 结束逻辑

        -- 发送邮件
        local filter = unilight.a(unilight.ge("redId", startTime),unilight.le("redId", endTime))
        local datainfo = unilight.chainResponseSequence(unilight.startChain().Table(DB_Name).Filter(filter))
        -- 生成时间
        local timestring = tostring(os.date("%H:%M", startTime)).."-"..tostring(os.date("%H:%M", endTime))
        local totalGoldNum = 0
        for _, info in ipairs(datainfo) do
            if info.goldNum > 0 then
                local mailInfo = {}
                local mailConfig = tableMailConfig[39]
                mailInfo.charid = info._id
                mailInfo.subject = mailConfig.subject
                mailInfo.content = string.format(mailConfig.content,timestring,info.redRainNum,info.goldNum/100)
                mailInfo.type = 0
                mailInfo.attachment = {}
                mailInfo.extData = {}
                ChessGmMailMgr.AddGlobalMail(mailInfo)
                -- 增加日志总发放金额
                totalGoldNum = totalGoldNum + info.goldNum
            end
        end
        -- 添加日志
        local period = 0
        for id, info in ipairs(Table_RedRainTime) do
            if startTime == info.startTime and endTime == info.endTime then
                period = id
                break
            end
        end
        local startTime = startTime - timeToDay
        local endTime = endTime - timeToDay
        AddGrantLog(startTime,endTime,table.len(datainfo),totalGoldNum)

        -- 全部初始化
        firstRedId = 0
        endRedId = 0
        startTime = 0
        endTime = 0
        timeList = {}
        return
    end

    -- 判断是否开始发放红包雨
    local timeInfo
    for _, info in ipairs(Table_RedRainTime) do
        if times >= info.startTime and times <= info.endTime then
            timeInfo = info
            break
        end
    end
    if GmFlag == 1 then
        timeInfo = {
            startTime = os.time() - timeToDay,
            endTime = os.time() - timeToDay + duration,
        }
        gmStartTime = timeInfo.startTime
        gmEndTime = timeInfo.endTime
        GmFlag = 2
    end
    -- 未到匹配时间直接退出
    if table.empty(timeInfo) and (gmStartTime == 0 and gmEndTime == 0) then
        return
    end
    if gmStartTime ~= 0 and gmEndTime ~= 0 then
        timeInfo = {
            startTime = gmStartTime,
            endTime = gmEndTime,
        }
    end
    -- 如果是本轮时间第一次进入红包雨判断则需要分化时间
    if redId < timeInfo.startTime + timeToDay and table.empty(timeList) then
        -- 初始化本轮信息
        timeList = {}
        startTime = timeInfo.startTime + timeToDay
        endTime = timeInfo.endTime + timeToDay
        -- 随机本轮个数
        local timeNum = math.random(Table_RedRainTimeNum[1].minNum,Table_RedRainTimeNum[1].maxNum)
        if GmFlag == 2 then
            timeNum = 1
            timeList = {os.time() - timeToDay + 1}
            firstRedId = timeList[1] + timeToDay
        else
            -- 每一个区间多少秒
            local sectionTimes = math.floor((timeInfo.endTime - timeInfo.startTime) / timeNum)
            -- 随机本轮每次触发时间
            for num = 1, timeNum do
                if table.empty(timeList) then
                    table.insert(timeList,math.random(sectionTimes) + timeInfo.startTime)
                    firstRedId = timeList[1] + timeToDay
                else
                    -- 判断本次最早随机时间
                    local minNum = (num - 1) * sectionTimes
                    if minNum < timeList[#timeList] - timeInfo.startTime + duration then
                        minNum = timeList[#timeList] - timeInfo.startTime + duration + 1
                    end
                    table.insert(timeList,math.random(minNum,num * sectionTimes) + timeInfo.startTime)
                end
            end
        end
        endRedId = timeList[#timeList] + timeToDay
    end
    ---判断更新红包雨ID
    if (not table.empty(timeList)) and os.time() >= timeList[1] + timeToDay then
        redId = timeList[1] + timeToDay
        table.remove(timeList,1)
    else
        -- 未到时间则直接返回
        return
    end
    for key,zontask in pairs(ZoneInfo.GlobalZoneInfoMap) do
        --广播到服务器
        zontask:SendCmdToMe('Cmd.RedCmd_S',{endTime = redId + duration, redId = redId, firstRedId = firstRedId, endRedId = endRedId, timeList = timeList, GmFlag = GmFlag})
    end
    local doInfo='Cmd.RedTriggerCmd_Brd'
    --广播到玩家
    chesstcplib.TcpMsgSendEveryOne(doInfo, {endTime = redId + duration})
end

-- 获取信息
function GetRedRainInfo(uid)
	-- 获取任务转盘模块数据库信息
	local redrainInfo = unilight.getdata(DB_Name,uid)
	-- 没有则初始化信息
	if table.empty(redrainInfo) then
		redrainInfo = {
            _id = uid,
            redId = 0,                                              --上次领取红包雨ID
            redRainNum = 0,                                         --本轮领取红包个数合计
            goldNum = 0,                                            --本轮领取金币合计
            firstRedId = 0,                                         --本轮红包雨开始时间
            endRedId = 0,                                           --本轮红包雨结束时间
		}
		unilight.savedata(DB_Name,redrainInfo)
	end
	return redrainInfo
end

-- 场景
function RedRainInfo(uid)
    -- 今日凌晨时间戳
    local timeToDay = chessutil.ZeroTodayTimestampGet()
    local redrainInfo = GetRedRainInfo(uid)
    -- 首次初始化信息
    if redrainInfo.redId > 0 and redrainInfo.redId < firstRedId then
        redrainInfo = {
            _id = uid,
            redId = 0,                                              --上次领取红包雨ID
            redRainNum = 0,                                         --本轮领取红包个数合计
            goldNum = 0,                                            --本轮领取金币合计
		}
    end
    unilight.savedata(DB_Name,redrainInfo)
    local endtime = 0   --结束时间(时间戳为距离今日凌晨的)
    if not (redId <= redrainInfo.redId or redId + duration < os.time()) then
        endtime = redId + duration
    end
    local tableRedRainTime = {}
    for _, info in ipairs(Table_RedRainTime) do
        table.insert(tableRedRainTime,{startTime = info.startTime + timeToDay,endTime = info.endTime + timeToDay,})
    end

    local res = {
        endTime = endtime,
        tableRedRainTime = tableRedRainTime,
    }
    return res
end

-- 领取
function RedRainGet(uid)
    -- 玩家信息
    local userInfo = unilight.getdata('userinfo',uid)
    -- 随机可领取金额
    local goldNum = 0
    -- 根据配置表查询信息
    for _, info in ipairs(Table_RedRainGoldNum) do
        if userInfo.property.totalRechargeChips >= info.rechargeMin and userInfo.property.totalRechargeChips <= info.rechargeMax then
            goldNum = math.random(info.goldMin, info.goldMax)
            break
        end
    end
    local redrainInfo = GetRedRainInfo(uid)
    if GmFlag == 2 then
        goldNum = 100
        GmFlag = 0
        gmStartTime = 0
        gmEndTime = 0
    end
    -- 判断红包是否过期
    if os.time() > redId + duration then
        local res = {
            goldNum = 0,
        }
        return res
    end
    if redId <= redrainInfo.redId or goldNum <= 0 then
        local res = {
            goldNum = 0,
        }
        return res
    end
    if goldNum > 0 then
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, goldNum, Const.GOODS_SOURCE_TYPE.REDRAIN)
        userInfo.property.totalredrainchips = userInfo.property.totalredrainchips + goldNum
        unilight.savedata('userinfo',userInfo)
        WithdrawCash.AddBet(uid, goldNum)
        redrainInfo.goldNum = redrainInfo.goldNum + goldNum
        redrainInfo.redRainNum = redrainInfo.redRainNum + 1
        redrainInfo.redId = redId
    end
    unilight.savedata(DB_Name,redrainInfo)
    local res = {
        goldNum = goldNum,
    }
    -- 添加日志
    -- 今日凌晨时间戳
    local timeToDay = chessutil.ZeroTodayTimestampGet()
    AddGetLog(uid,startTime - timeToDay,endTime - timeToDay,goldNum)
    return res
end

-- 添加发放日志
function AddGrantLog(startTime,endTime,receivenum,totalGoldNum)
    local datainfo = {
        startTime                   = startTime,
        endTime                     = endTime,
        datetime                    = os.time(),
        receivenum                  = receivenum,
        grantgold                   = totalGoldNum,
    }
    unilight.savedata(DB_GrantLog_Name,datainfo)
end

-- 添加领取日志
function AddGetLog(uid,startTime,endTime,gold)
    local datainfo = {
        charid                      = uid,
        datetime                    = os.time(),
        startTime                   = startTime,
        endTime                     = endTime,
        gold                        = gold,
    }
    unilight.savedata(DB_GetLog_Name,datainfo)
end