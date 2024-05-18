module('LossRebate',package.seeall)
DB_Name = 'lossrebate'
DB_Log_Name = "lossrebatelog"
local tableMailConfig = import "table/table_mail_config"
table_lossRebate_proportion = require 'table/table_losssrebate_proportion'
function Get(uid)
    local datainfo = unilight.getdata(DB_Name,uid)
    if table.empty(datainfo) then
        datainfo={
            _id = uid,
            todayRechargeNum = 0,                                           -- 今日累计充值
            yestedayLossChips = 0,                                          -- 昨日损失金币
            lastChangeTime = chessutil.ZeroTodayTimestampGet(),             -- 上次更新时间
            yestedayReward = 0,                                             -- 昨日奖励
        }
        unilight.savedata(DB_Name,datainfo)
    end
    return datainfo
end
-- 界面信息
function GetInfo(uid)
    local datainfo = Get(uid)
    -- 玩家当前金币
    local userChips = chessuserinfodb.RUserChipsGet(uid)
    -- 今日预计返利金额
    local todayReward = 0
    -- 判断数据刷新
    local yestedayRewardFlag = isRefresh(uid,datainfo)
    local todayRechargeNum = 0
    if datainfo.yestedayReward <= 0 then
        yestedayRewardFlag = false
    end
    if datainfo.todayRechargeNum - userChips > 0 then
        todayRechargeNum = datainfo.todayRechargeNum - userChips
    end
    -- 预计今日可领取金额
    for _, info in ipairs(table_lossRebate_proportion) do
        if todayRechargeNum >= info.min and todayRechargeNum <= info.max then
            todayReward = math.floor((todayRechargeNum) * (info.proportion / 10000))
            break
        end
    end
    -- 计算损失金额
    local res = {
        todayRechargeNum = todayRechargeNum,                            -- 今日损失金币
        yestedayLossChips = datainfo.yestedayLossChips,                 -- 昨日损失金币
        yestedayReward = datainfo.yestedayReward,                       -- 昨日返利(可领取金额)
        todayReward = todayReward,                                      -- 今日预计返利
        table_lossRebate_proportion = table_lossRebate_proportion,
        yestedayRewardFlag = yestedayRewardFlag,                        -- 昨日奖励是否领取
    }
    unilight.savedata(DB_Name,datainfo)
    return res
end

-- 领取奖励
function GetReward(uid)
    local datainfo = Get(uid)
    local yestedayReward = datainfo.yestedayReward
    if datainfo.yestedayReward > 0 then
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, datainfo.yestedayReward, Const.GOODS_SOURCE_TYPE.LOSSREBATE)
        AddLog(uid,datainfo.yestedayLossChips,datainfo.yestedayReward)
        -- 保存统计
        local userInfo = unilight.getdata('userinfo',uid)
        userInfo.property.totallossrebatechips = userInfo.property.totallossrebatechips + datainfo.yestedayReward
        unilight.savedata('userinfo',userInfo)
        -- 发送邮件
        ----------------------------------------------- 未给配置表 -----------------------------------------------
        local mailInfo = {}
        local mailConfig = tableMailConfig[35]
        mailInfo.charid = uid
        mailInfo.subject = mailConfig.subject
        mailInfo.content = string.format(mailConfig.content,datainfo.yestedayReward/100)
        mailInfo.type = 0
        mailInfo.attachment = {}
        mailInfo.extData = {}
        ChessGmMailMgr.AddGlobalMail(mailInfo)
        datainfo.yestedayReward = 0
        datainfo.yestedayLossChips = 0
        datainfo.lastChangeTime = chessutil.ZeroTodayTimestampGet()
        unilight.savedata(DB_Name,datainfo)
    end
    return {chips = yestedayReward}
end

-- 增加今日总充值
function AddTodayRechargeNum(uid,addNum)
    local datainfo = Get(uid)


    datainfo.todayRechargeNum = datainfo.todayRechargeNum + addNum
    unilight.savedata(DB_Name,datainfo)
end

-- 判断是否刷新
function isRefresh(uid,datainfo)
    datainfo = datainfo or Get(uid)
    -- 判断时间刷新
    local disDay = chessutil.DateDayDistanceByTimeGet(datainfo.lastChangeTime,chessutil.ZeroTodayTimestampGet())
    -- 玩家当前金币
    local userChips = chessuserinfodb.RUserChipsGet(uid)
    if disDay == 1 then
        local yestodayChips = 0
        if datainfo.todayRechargeNum - userChips > 0 then
            yestodayChips = datainfo.todayRechargeNum - userChips
        end
        local yestedayLossChips = datainfo.yestedayLossChips
        datainfo.yestedayLossChips = yestodayChips
        -- 如果有以前的奖励未领取则下发奖励
        if datainfo.yestedayReward > 0 then
            -- 增加奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, datainfo.yestedayReward, Const.GOODS_SOURCE_TYPE.LOSSREBATE)
            -- 保存统计
            local userInfo = unilight.getdata('userinfo',uid)
            userInfo.property.totallossrebatechips = userInfo.property.totallossrebatechips + datainfo.yestedayReward
            unilight.savedata('userinfo',userInfo)
            -- 发送邮件
            ----------------------------------------------- 未给配置表 -----------------------------------------------
            local mailInfo = {}
            local mailConfig = tableMailConfig[35]
            mailInfo.charid = uid
            mailInfo.subject = mailConfig.subject
            mailInfo.content = string.format(mailConfig.content,datainfo.yestedayReward/100)
            mailInfo.type = 0
            mailInfo.attachment = {}
            mailInfo.extData = {}
            mailInfo.recordtime = chessutil.ZeroTodayTimestampGet(datainfo.lastChangeTime) + 3600 * 24
            ChessGmMailMgr.AddGlobalMail(mailInfo)
            AddLog(uid,yestedayLossChips,datainfo.yestedayReward,chessutil.ZeroTodayTimestampGet(datainfo.lastChangeTime) + 3600 * 24)
        end

        datainfo.yestedayReward = 0
        --计算实际返利金额
        for _, info in ipairs(table_lossRebate_proportion) do
            if datainfo.yestedayLossChips >= info.min and datainfo.yestedayLossChips <= info.max then
                datainfo.yestedayReward = math.floor(datainfo.yestedayLossChips * (info.proportion / 10000))
                break
            end
        end
        datainfo.todayRechargeNum = 0
        datainfo.lastChangeTime = chessutil.ZeroTodayTimestampGet()
    elseif disDay > 1 then
        local yestodayChips = 0
        if datainfo.todayRechargeNum - userChips > 0 then
            yestodayChips = datainfo.todayRechargeNum - userChips
        end
        local yestodayReward = 0
        --计算实际返利金额
        for _, info in ipairs(table_lossRebate_proportion) do
            if yestodayChips >= info.min and yestodayChips <= info.max then
                yestodayReward = math.floor(yestodayChips * (info.proportion / 10000))
                break
            end
        end
        local sumChips = datainfo.yestedayReward + yestodayReward
        sumChips = math.floor(sumChips)
        if sumChips > 0 then
            -- 增加奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, sumChips, Const.GOODS_SOURCE_TYPE.LOSSREBATE)
            -- 保存统计
            local userInfo = unilight.getdata('userinfo',uid)
            userInfo.property.totallossrebatechips = userInfo.property.totallossrebatechips + datainfo.yestedayReward
            unilight.savedata('userinfo',userInfo)
            -- 发送邮件
            ----------------------------------------------- 未给配置表 -----------------------------------------------
            local mailInfo = {}
            local mailConfig = tableMailConfig[35]
            mailInfo.charid = uid
            mailInfo.subject = mailConfig.subject
            mailInfo.content = string.format(mailConfig.content,sumChips/100)
            mailInfo.type = 0
            mailInfo.attachment = {}
            mailInfo.extData = {}
            mailInfo.recordtime = chessutil.ZeroTodayTimestampGet(datainfo.lastChangeTime) + 3600 * (24 + 1)
            ChessGmMailMgr.AddGlobalMail(mailInfo)
            AddLog(uid,yestodayChips,sumChips,chessutil.ZeroTodayTimestampGet(datainfo.lastChangeTime) + 3600 * (24 + 1))
        end
        -- 重置数据
        datainfo.yestedayReward = 0                                             -- 昨日奖励
        datainfo.yestedayLossChips = 0
        datainfo.todayRechargeNum = 0
        datainfo.lastChangeTime = chessutil.ZeroTodayTimestampGet()
    else
        return true
    end
    unilight.savedata(DB_Name,datainfo)
    return false
end

-- 添加日志记录
function AddLog(uid,lossChips,gold,timesecond)
    local datainfo = {
        uid = uid,
        datetime = timesecond or os.time(),
        newloss = lossChips,
        receivegold = gold,
    }
    unilight.savedata(DB_Log_Name,datainfo)
end