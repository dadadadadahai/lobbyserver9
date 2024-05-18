module('nvipmgr',package.seeall)
UserTable ='userinfo'
Table = 'nVip'
DB_Log_Name = 'nviplog'
TableWeekCardLog = 'weekCardLog'
table_nvip_level = require 'table/table_nvip_level'
local tableMailConfig = import "table/table_mail_config"
--VIPCARD
--VIPCARD_Day
function Get(uid)
    local datainfo = unilight.getdata(Table,uid)
    if table.empty(datainfo) then
        datainfo={
            _id = uid,
            levelChips = 0,             -- 等级可领取金额
            weekChips = 0,              -- 每周可领取金额
            monthChips = 0,             -- 每月可领取金额
            weekTimes = 0,              -- 上次领取周奖励时间
            monthTimes = 0,             -- 上次领取月奖励时间
            vipLevel = 0,               -- 等级
            history = {},               -- 历史记录
            levelRewardHistory = {},    -- 等级领取记录
        }
        unilight.savedata(Table,datainfo)
    end
    return datainfo
end
--返回用户vip周卡信息
function GetVipInfoCmd_C(uid)
    local datainfo = Get(uid)
    local timenow = os.time()
    -- 今日所在周的初始时间
    local weekFirstTimes = chessutil.ZeroWeekTimestampGet()
    -- 获取玩家当前下注
    local userinfo = unilight.getdata('userinfo',uid)
    local userBetChips = userinfo.gameData.slotsBet
    if userinfo.property.totalRechargeChips <= 0 then
        userBetChips = 0
    end
    -- 配置表
    local tableInfo
    -- 是否修改标识
    local changeFlag = false
    -- 获取所在配置信息
    for id, info in ipairs(table_nvip_level) do
        -- 如果当前档次没领取
        if datainfo.levelRewardHistory[info.vipLevel] == nil then
            -- 判断是否当前等级大于等于此等级
            if userBetChips >= info.charge then
                datainfo.levelChips = datainfo.levelChips + info.levelReward
                -- 保存记录
                datainfo.levelRewardHistory[info.vipLevel] = info.levelReward
                changeFlag = true
                if (id == #table_nvip_level or userBetChips < table_nvip_level[id + 1].charge) then
                    tableInfo = info
                    datainfo.vipLevel = info.vipLevel
                    local userInfo = unilight.getdata('userinfo',uid)
                    userInfo.property.vipLevel = info.vipLevel
                    unilight.savedata('userinfo',userInfo)
                end
            end
        end
        if userBetChips >= info.charge and (id == #table_nvip_level or userBetChips < table_nvip_level[id + 1].charge) then
            tableInfo = info
        end
    end
    if table.empty(tableInfo) then
        return
    end
    -- 判断是否可领取
    if weekFirstTimes > datainfo.weekTimes then
        -- 计算相差周数
        local differWeekNum = chessutil.DateDayDistanceByTimeGet(weekFirstTimes, datainfo.weekTimes) / 7
        datainfo.weekTimes = weekFirstTimes
        datainfo.weekChips = datainfo.weekChips + (tableInfo.weekReward * differWeekNum)
        changeFlag = true
    end
    -- 判断是否可领取
    local differMonthNum = DifferMonth(datainfo.monthTimes,timenow)
    if differMonthNum >= 1 then
        datainfo.monthTimes = timenow
        datainfo.monthChips = datainfo.monthChips + (tableInfo.monthReward * differMonthNum)
        changeFlag = true
    end
    if changeFlag then
        unilight.savedata(Table,datainfo)
    end
    local res={
        errno = 0,
        _id = datainfo._id,
        chips = datainfo.levelChips + datainfo.weekChips + datainfo.monthChips,                 -- 玩家可领取金额
        history = datainfo.history,                                                             -- 领取历史记录
        userBetChips = userBetChips,                                                            -- 玩家累计下注
        level = datainfo.vipLevel,                                                              -- VIP等级
    }
    return res
end
-- 领取奖励
function RecvVipRewardCmd_C(uid)
    local datainfo = Get(uid)
    -- 领取判断
    if datainfo.levelChips + datainfo.weekChips + datainfo.monthChips <= 0 then
        local res = {
            chips = 0,
        }
        return res
    end
    local sumChips = datainfo.levelChips + datainfo.weekChips + datainfo.monthChips
    -- 等级奖励领取
    if datainfo.levelChips > 0 then
        -- 添加记录
        table.insert(datainfo.history,1,{time = os.time(),type = 1,chips = datainfo.levelChips})
        AddLog(uid,datainfo.vipLevel,"等级奖励",datainfo.levelChips)
        datainfo.levelChips = 0
    end
    -- 每周奖励领取
    if datainfo.weekChips > 0 then
        -- 添加记录
        table.insert(datainfo.history,1,{time = os.time(),type = 2,chips = datainfo.weekChips})
        AddLog(uid,datainfo.vipLevel,"每周奖励",datainfo.weekChips)
        datainfo.weekChips = 0
    end
    -- 每月奖励领取
    if datainfo.monthChips > 0 then
        -- 添加记录
        table.insert(datainfo.history,1,{time = os.time(),type = 3,chips = datainfo.monthChips})
        AddLog(uid,datainfo.vipLevel,"每月奖励",datainfo.monthChips)
        datainfo.monthChips = 0
    end
    -- 清理多余记录
    if table.len(datainfo.history) >= 12 then
        for i = 0, 12 - table.len(datainfo.history) do
            table.remove(datainfo.history,1)
        end
    end
    -- 增加奖励
    BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, sumChips, Const.GOODS_SOURCE_TYPE.NVIP)
    -- 保存统计
    local userInfo = unilight.getdata('userinfo',uid)
    userInfo.property.totalvipchips = userInfo.property.totalvipchips + sumChips
    unilight.savedata('userinfo',userInfo)
    -- 发送邮件
    local mailInfo = {}
    local mailConfig = tableMailConfig[38]
    mailInfo.charid = uid
    mailInfo.subject = mailConfig.subject
    mailInfo.content = string.format(mailConfig.content,sumChips/100)
    mailInfo.type = 0
    mailInfo.attachment = {}
    mailInfo.extData = {}
    ChessGmMailMgr.AddGlobalMail(mailInfo)

    unilight.savedata(Table,datainfo)
    local res = {
        chips = sumChips,
        history = datainfo.history,                                                             -- 领取历史记录
    }
    return res
end

-- 判断是否是新的一月
function DifferMonth(time1,time2)
    temp1 = os.date("*t", time1)
	temp2 = os.date("*t", time2)
    -- if temp1.year < temp2.year then
    --     return true
    -- elseif temp1.year == temp2.year and temp1.month < temp2.month then
    --    return true
    -- else
    --     return false 
    -- end
    return (temp2.year - temp1.year) * 12 + temp2.month - temp1.month
end

-- 添加日志记录
function AddLog(uid,level,content,gold)
    local datainfo = {
        uid = uid,
        datetime = os.time(),
        level = level,
        content = content,
        gold = gold,
    }
    unilight.savedata(DB_Log_Name,datainfo)
end