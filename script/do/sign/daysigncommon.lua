-- 每日签到模块
module('DaySign', package.seeall)
DaySign = DaySign or {}
-- 每日签到数据表
DaySign.DB_Name = "userinfo"
DaySign.Table_Item = require "table/table_sign_item"
DaySign.Table_Other = require "table/table_sign_other"
-- 公共调用
DaySign.DayTimes = DaySign.Table_Item[#DaySign.Table_Item].days
-- 获取签到信息
DaySign.GetSignInfo = function(uid)
    -- 获取玩家信息
    local userInfo = unilight.getdata(DaySign.DB_Name,uid)
    if userInfo.daySign == nil then
        userInfo.daySign = {}
        unilight.savedata(DaySign.DB_Name,userInfo)
    end
    -- 获取奖励列表
    local signScoreList = {}
    for i, v in ipairs(DaySign.Table_Item) do
        table.insert(signScoreList,{days = v.days, score = v.score})
    end
    local signFlag = false
    -- 获取当前时间
    local date = chessutil.DateByFormatDateGet(chessutil.FormatDateGet())
	local yearMonthDay = tonumber(date.year..date.month..date.day)
    -- 根据当前时间插入是否签到信息
    if table.len(userInfo.daySign) < DaySign.DayTimes and userInfo.daySign[yearMonthDay] == nil then
        signFlag = true
    elseif table.len(userInfo.daySign) >= DaySign.DayTimes and userInfo.daySign[yearMonthDay] == nil then
        signFlag = true
        -- 判断是否清理签到次数
        userInfo.daySign = {}
        unilight.savedata(DaySign.DB_Name,userInfo)
    end
    local res = {
        errno = ErrorDefine.SUCCESS,
        desc = "获取签到信息成功",
        signScoreList = signScoreList,
        signDay = table.len(userInfo.daySign),
        signFlag = signFlag,
        -- 剩余时间 = 当天凌晨 + 一天时间 - 当前时间
        time = chessutil.ZeroTodayTimestampGet() + (24 * 60 * 60) - os.time(),
    }
    return res
end
-- 获取签到日期结果
DaySign.GetSignDays = function(uid)
    -- -- 判断VIP等级是否可以签到
    -- if DaySign.Table_Other[1].vipLevel > nvipmgr.GetVipLevel(uid) then
    --     local res = {
    --         errno = ErrorDefine.SIGN_VIPLEVEL_ERROR,
    --         desc = "玩家当前VIP等级不足签到需求",
    --     }
    --     return res
    -- end
    -- 获取玩家信息
    local userInfo = unilight.getdata(DaySign.DB_Name,uid)
    local signDays = table.len(userInfo.daySign)
    -- 判断是否可以继续签到
    if signDays >= DaySign.DayTimes then
        local res = {
            errno = ErrorDefine.SIGN_FULLMAX_ERROR,
            desc = "当前签到次数超过总签到次数",
        }
        return res
    end
    -- 获取当前时间
    local date = chessutil.DateByFormatDateGet(chessutil.FormatDateGet())
	local yearMonthDay = tonumber(date.year..date.month..date.day)
    -- 根据当前时间插入是否签到信息
    if userInfo.daySign[yearMonthDay] ~= nil then
        local res = {
            errno = ErrorDefine.SIGN_HAVESIGN_ERROR,
            desc = "今日已经签到",
        }
        unilight.savedata(DaySign.DB_Name,userInfo)
        return res
    end
    -- 增加签到次数
    signDays = signDays + 1
    local score = 0
    -- 获取奖励金额
    for i, v in ipairs(DaySign.Table_Item) do
        if v.days == signDays then
            score = v.score
            break
        end
    end
    -- 进行签到
    userInfo.daySign[yearMonthDay] = score
    unilight.savedata(DaySign.DB_Name,userInfo)
    -- 赠送金币
    chessuserinfodb.WPresentChange(uid, Const.PACK_OP_TYPE.ADD, score, "每日签到")
    --增加金额
    BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, score, Const.GOODS_SOURCE_TYPE.SIGN)
    -- 兑换流水增加
    -- WithdrawCash.AddBet(uid, score)



    local res = {
        errno = ErrorDefine.SUCCESS,
        desc = "签到成功",
        score = score,
        -- 剩余时间 = 当天凌晨 + 一天时间 - 当前时间
        time = chessutil.ZeroTodayTimestampGet() + (24 * 60 * 60) - os.time(),
    }
    return res
end
--------------------------------------------------    获取签到次数    --------------------------------------------------
DaySign.GetSignNum = function(uid)
    -- 获取玩家信息
    local userInfo = unilight.getdata(DaySign.DB_Name,uid)
    -- 返回签到进度次数
    return table.len(userInfo.daySign)
end