module('vipCoefficientMgr', package.seeall)

tableVipConf = require "table/table_vip_coefficient"
baseData = require "table/table_vip_week_basedata"


--获取玩家vip等级
function GetUserLevel(uid)
    --获取玩家数据
    local userInfo = chessuserinfodb.RUserInfoGet(uid)
    local buffId = Const.BUFF_TYPE_ID.VIP_LIMIT
    local vipLevel = 1--默认等级为1
    --玩家是否有vip体验卡
    if BuffMgr.GetBuffByBuffId(uid, buffId) ~= nil then
        vipLevel = userInfo.property.vipLevel + 1--体验卡的等级永远为当前vip等级+1
    else
        vipLevel = userInfo.property.vipLevel
    end
    return vipLevel
end

--vip金币系数
function GoldCoefficientForVip(uid)
    local vipLevel = GetUserLevel(uid)
    local goldCoeff = tableVipConf[vipLevel]["vipGoldCoef"]--金币系数
    return goldCoeff
end

--玩家vip对应等级的免费系数（免费系数）
function FreeCoefficientForVip (uid)
    local vipLevel = GetUserLevel(uid)
    local freeCoeff = tableVipConf[vipLevel]["vipFreeCoeff"]-- 免费系数
    return freeCoeff
end

--玩家vip对应等级的现金系数（现金系数）
function CashCoefficientForVip(uid)
    local vipLevel = GetUserLevel(uid)
    local cashCoeff = tableVipConf[vipLevel]["vipCashCoeff"]-- 现金系数
    return cashCoeff
end


--玩家vip对应等级的优惠券系数（优惠券系数）
function CouponCoefficientForVip(uid)
    local vipLevel = GetUserLevel(uid)
    local couponCoeff = tableVipConf[vipLevel]["vipCouponCoeff"]-- 优惠券系数
    return couponCoeff
end


--玩家vip对应等级的vip分变化（vip分系数）
function ExpCoefficientForVip(uid, score)
    local vipLevel = GetUserLevel(uid)
    --获取玩家数据
    local userInfo = chessuserinfodb.RUserInfoGet(uid)
    local ExpCoeff = tableVipConf[vipLevel]["vipScoreCoeff"]-- vip分系数
    local addExp = score * ExpCoeff
    userInfo.property.vipExp = userInfo.property.vipExp + addExp
    if addExp + userInfo.property.vipExp >= tableVipConf[userInfo.property.vipLevel + 1]["vipScore"] then
        userInfo.property.vipLevel = userInfo.property.vipLevel + 1--升到下一等级
    end
    chessuserinfodb.WUserInfoUpdate(uid, userInfo)
    ExchangeVipExp(uid)
end

--玩家的等级达到LV8时，每周一下午四点都会进行衰减经验
function DampingVipExpForVLight(uid)
    --获取玩家数据
    local userInfo = chessuserinfodb.RUserInfoGet(uid)
    -- local weekTime = chessutil.GetMorningWeekNo()
   -- local num = weekTime - userInfo.property.lastVipWeekNo
    --  num=0
    -- --不到一周不衰减
    -- if num < 1 then
    --     return
    -- end
    --衰减所需的等级
    if userInfo.property.vipLevel == baseData[1]["vipLevel"] then
        userInfo.property.vipExp = userInfo.property.vipExp - baseData[1]["percent"] / 100 * userInfo.property.vipExp * num
        if userInfo.property.vipExp < tableVipConf[userInfo.vipLevel - 1]["vipScoreCoeff"] then
            --vip等级掉级
            userInfo.property.vipLevel = userInfo.property.vipLevel - 1
        end
        --记录本次衰减的时间
        userInfo.property.lastVipWeekNo = chessutil.GetMorningWeekNo()
        chessuserinfodb.WUserInfoUpdate(uid, userInfo)
        ExchangeVipExp(uid)
    end
end


--推送玩家的 vip经验变更消息
function ExchangeVipExp(uid)
    --获取玩家数据
    local userInfo = chessuserinfodb.RUserInfoGet(uid)
    local laccount = go.roomusermgr.GetRoomUserById(uid)
    local send = {}
    local nextExp = tableVipConf[userInfo.property.vipLevel + 1]["vipScore"]
    send["do"] = "Cmd.VipExpExchangeCmd_S"
    send["data"] = {
        vipLevel = userInfo.property.vipLevel,
        vipExp = userInfo.property.vipExp,
        nextLevelExp = nextExp,
    }
    unilight.success(laccount, send)
end

--判断玩家vip体验卡剩余时间
function RemainTimeForLimitVip(uid, buffId)
    local remainTime = 0
    local buff = BuffMgr.GetBuffByBuffId(uid, buffId)
    if buff ~= nil then
        remainTime = buff.remainTime - os.time()
    end
    return remainTime
end

--[[--每周金币奖励
function WeeklyReward(uid)
    local userInfo = chessuserinfodb.RUserInfoGet(uid)
   local  goldCoeff=GoldCoefficientForVip(uid)  --金币系数
    local originalValue=(userInfo.vipExp+baseData[1]["baseNum"])*userInfo[1]["originalCoeff"]--原始值

    local trueGold =originalValue * goldCoeff*(等级系数)--实际金币
    return trueGold
end]]