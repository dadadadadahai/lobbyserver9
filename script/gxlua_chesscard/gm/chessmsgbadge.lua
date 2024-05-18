-- 徽章等级相关gm请求
UserBadgeLevelList = {}
-- 请求徽章等级满足要求的个数
GmSvr.PmdRequestBettingLevelPmd_C = function(cmd, laccount)
    local filter = unilight.gt('uid',0)
    -- 根据玩家ID
    if cmd.data.charid ~= nil and cmd.data.charid > 0 then
        filter = unilight.a(filter,unilight.eq("uid",cmd.data.charid))
    end
    -- 根据发放时间判断
    if cmd.data.begintime ~= nil and cmd.data.begintime ~= "" then
        local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        filter = unilight.a(filter,unilight.ge("datetime",starttime))
    end
    -- 根据发放时间判断
    if cmd.data.endtime ~= nil and cmd.data.endtime ~= "" then
        local endtime = chessutil.TimeByDateGet(cmd.data.endtime)
        filter = unilight.a(filter,unilight.le("datetime",endtime))
    end
    local order = unilight.desc("datetime")
    local logInfos = unilight.chainResponseSequence(unilight.startChain().Table(Badge.DB_Log_Name).Filter(filter).OrderBy(order).Skip((cmd.data.curpage-1)*cmd.data.perpage).Limit(cmd.data.perpage))
    if table.empty(logInfos) then
        local res = {
            data = {
                maxpage = 0,
                perpage = cmd.data.perpage,
                curpage = cmd.data.curpage,
                data = {},
                receivegold = 0,
            }
        }
        return res
    end
    local infoNum = unilight.startChain().Table(Badge.DB_Log_Name).Filter(filter).Count()
    local maxpage = math.ceil(infoNum/cmd.data.perpage)
    local res = {
        data = {
            batch = cmd.data.batch,
            code = cmd.data.code,
            maxpage = maxpage,
            perpage = cmd.data.perpage,
            curpage = cmd.data.curpage,
            data = {},
        }
    }
    res.data.receivegold = 0
    res.data.receivenum = 0
    for _, logInfo in ipairs(logInfos) do
        table.insert(res.data.data,{
            charid          = logInfo.uid,                                                  -- uid
            datetime        = chessutil.FormatDateGet(logInfo.datetime,"%Y-%m-%d"),         -- 发放时间
            oncelevel       = logInfo.level,                                                -- 领取时等级
            curlevel        = GetPlayerBadgeLevel(logInfo.uid),                             -- 当前等级
            day             = logInfo.day,                                                  -- 领取项
            receivegold     = logInfo.receivegold,                                          -- 领取金额
            allbet          = logInfo.allbet,                                               -- 领取时近七日总下注
        })
        -- 统计合计数量
        res.data.receivegold = res.data.receivegold + logInfo.receivegold
        res.data.receivenum = res.data.receivenum + 1
    end
    -- 清空缓存
    UserBadgeLevelList = {}
    return res
end

-- 获取玩家当前等级
function GetPlayerBadgeLevel(uid)
    if UserBadgeLevelList[uid] ~= nil then
        return UserBadgeLevelList[uid]
    end
    local level = 0
    -- 获取今日合计下注金额/数量
	local sumBetMoneyInfo = DayBetMoney.GetSumBetMoney(uid,os.time() - Badge.dayTime,os.time())
    for id, info in ipairs(Badge.Table_BadgeLevel) do
		if sumBetMoneyInfo.sumBetMoney >= info.min and sumBetMoneyInfo.sumBetMoney <= info.max then
			level = id
		end
	end
    UserBadgeLevelList[uid] = level
    return level
end