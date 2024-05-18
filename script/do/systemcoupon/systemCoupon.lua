-- 系统优惠券相关
module('SystemCoupon', package.seeall)

-- 用户表
DB_USERINFO_NAME = "userinfo"

-- 系统优惠券相关配置表
TableItemConfig = import "table/table_item_config"

TableCouponSet = import "table/table_coupon_set"
TableCouponGoldGeneral = import "table/table_coupon_goldGel"
TableCouponEmeralGeneral = import "table/table_coupon_emeraldGel"
TableCouponGoldNotGeneral = import "table/table_coupon_goldNotGel"

-- 优惠券类型列表
GoldGeneralType = 5
EmeraldGeneralType = 15
GoldNotGeneralType = 6

-- 优惠券刷新类别

GeneralType = 1
NotGeneralType = 2

-- 系统优惠券变量表
-- 通用最小间隔m
GeneralMinInterval = TableCouponSet[1].generalMinInterval
-- 通用最大间隔m
GeneralMaxInterval = TableCouponSet[1].generalMaxInterval
-- 非通用最小间隔m
NotGeneralMinInterval = TableCouponSet[1].notGeneralMinInterval
-- 非通用最大间隔m
NotGeneralMaxInterval = TableCouponSet[1].notGeneralMaxInterval
-- 通用金币最大百分比
GoldGeneralMaxRate = TableCouponSet[1].goldGeneralMaxRate
-- 通用绿钻最大百分比
EmeraldGeneralMaxRate = TableCouponSet[1].emeraldGeneralMaxRate
-- 非通用金币最大百分比
GoldNotGeneralMaxRate = TableCouponSet[1].goldNotGeneralMaxRate

-- 玩家数据库系统优惠券相关信息初始化
function SystemCouponInfoGet(uid)
    -- 玩家系统优惠券据库信息
	local userInfo = unilight.getdata(DB_USERINFO_NAME, uid)
    -- 是否有修改
	local bUpdate = false
	if table.empty(userInfo.systemCouponInfo) then
		userInfo.systemCouponInfo = {            
            ["generalRefreshTime"] = math.modf((os.time() + chessutil.NotRepeatRandomNumbers(GeneralMinInterval,GeneralMaxInterval,1)[1] * 60) / 60) * 60,
            ["notGeneralRefreshTime"] = math.modf((os.time() + chessutil.NotRepeatRandomNumbers(NotGeneralMinInterval,NotGeneralMaxInterval,1)[1] * 60) / 60) * 60
		}
		bUpdate = true
	end
	if bUpdate then
		unilight.update(DB_USERINFO_NAME, uid, userInfo)
	end
	return userInfo.systemCouponInfo
end

-- 玩家获取优惠券
function GetSystemCoupon(uid, type)
    local CouponRates = GetSystemCouponTotalPercentage(uid)

    if type == GeneralType then
        -- 金币通用中的优惠券随机列表
        local goldCoinGeneralCoupons = {}
        -- 绿宝石通用中的优惠券随机列表
        local emeraldGeneralCoupons = {}
        for i, v in ipairs(TableCouponGoldGeneral) do
            if v.totalPercentage > CouponRates.goldCoinGeneralCouponRate then
                break
            end
            goldCoinGeneralCoupons = v.coupons
        end
    
        for i, v in ipairs(TableCouponEmeralGeneral) do
            if v.totalPercentage > CouponRates.emeraldGeneralCouponRate then
                break
            end
            emeraldGeneralCoupons = v.coupons
        end
        
        -- 添加通用优惠券 一次只能获取一张
        if not table.empty(goldCoinGeneralCoupons) then
            local reward = RandomCoupons(goldCoinGeneralCoupons, 1)[1]
            BackpackMgr.GetRewardGood(uid, reward, 1, Const.GOODS_SOURCE_TYPE.SYSTEM_COUPON)
        end
        if not table.empty(emeraldGeneralCoupons) then
            local reward = RandomCoupons(emeraldGeneralCoupons, 1)[1]
            BackpackMgr.GetRewardGood(uid, reward, 1, Const.GOODS_SOURCE_TYPE.SYSTEM_COUPON)
        end

    elseif type == NotGeneralType then
        -- 金币非通用中的优惠券随机列表
        local goldCoinNotGeneralCoupons = {}
        
        for i, v in ipairs(TableCouponGoldNotGeneral) do
            -- 金币非通用随机对应档次的折扣
            local coupon = v.coupons[math.random(#v.coupons)]
            table.insert(goldCoinNotGeneralCoupons, coupon)
        end
    
        -- 循环添加非通用优惠券 每个档次一张
        for i, v in ipairs(goldCoinNotGeneralCoupons) do
            BackpackMgr.GetRewardGood(uid, v, 1, Const.GOODS_SOURCE_TYPE.SYSTEM_COUPON)
        end
        
    else
        unilight.error("优惠券刷新类别错误")
        return
    end


end


-- 玩家使用优惠券
function UseSystemCoupons(uid,coupons)
    -- 三种优惠券的计算使用百分比
    local GoldGeneralUseNum = 0
    local EmeraldGeneralUseNum = 0
    local GoldNotGeneralUseNum = 0
    
    -- 循环优惠券列表整理优惠券类别
    for i, v in ipairs(coupons) do
        if not BackpackMgr.CheckItemEnough(uid, v, 1) then
            unilight.error("优惠券背包数量不足")
            return
        end
         -- 如果优惠券是金币通用
        if TableItemConfig[v].goodType == GoldGeneralType then
            GoldGeneralUseNum = GoldGeneralUseNum + 1
        -- 如果优惠券是绿宝石通用
        elseif TableItemConfig[v].goodType == EmeraldGeneralType then
            EmeraldGeneralUseNum = EmeraldGeneralUseNum + 1
        -- 如果优惠券是金币非通用
        elseif TableItemConfig[v].goodType == GoldNotGeneralType then
            GoldNotGeneralUseNum = GoldNotGeneralUseNum + 1
        end
    end
    
    -- 判断获取到的优惠券类型是否重复
    if GoldGeneralUseNum > 1 or EmeraldGeneralUseNum > 1 or GoldNotGeneralUseNum > 1 then
        unilight.error("同种优惠券只能使用一张")
        return
    end

    -- 如果使用成功 扣除优惠券
    for i, v in ipairs(coupons) do
        BackpackMgr.UseItem(uid,v,1)
    end

    -- 更新数据库刷新时间
    local userInfo = unilight.getdata(DB_USERINFO_NAME, uid)
    if userInfo.systemCouponInfo == nil then
        userInfo.systemCouponInfo = SystemCouponInfoGet(uid)
    end
    userInfo.systemCouponInfo.generalRefreshTime = math.modf((os.time() + chessutil.NotRepeatRandomNumbers(GeneralMinInterval,GeneralMaxInterval,1)[1] * 60) / 60) * 60
    userInfo.systemCouponInfo.notGeneralRefreshTime = math.modf((os.time() + chessutil.NotRepeatRandomNumbers(NotGeneralMinInterval,NotGeneralMaxInterval,1)[1] * 60) / 60) * 60
    unilight.update(DB_USERINFO_NAME, uid, userInfo)

    return true
end

-- 玩家优惠券时间管理
function TimeCoupon(uid)
    local userInfo = unilight.getdata(DB_USERINFO_NAME, uid)
    if userInfo == nil then
        return
    end
    if userInfo.systemCouponInfo == nil then
        userInfo.systemCouponInfo = SystemCouponInfoGet(uid)
    end
    local updateFlag = false
    -- 如果通用优惠券需要刷新
    if os.time() >= userInfo.systemCouponInfo.generalRefreshTime then
        GetSystemCoupon(uid, GeneralType)
        -- 更新数据库刷新时间
        userInfo.systemCouponInfo.generalRefreshTime = math.modf((os.time() + chessutil.NotRepeatRandomNumbers(GeneralMinInterval,GeneralMaxInterval,1)[1] * 60) / 60) * 60
        updateFlag = true
    end
    -- 如果非通用优惠券需要刷新
    if os.time() >= userInfo.systemCouponInfo.notGeneralRefreshTime then
        GetSystemCoupon(uid, NotGeneralType)
        userInfo.systemCouponInfo.notGeneralRefreshTime = math.modf((os.time() + chessutil.NotRepeatRandomNumbers(NotGeneralMinInterval,NotGeneralMaxInterval,1)[1] * 60) / 60) * 60
        updateFlag = true
    end
    if updateFlag then
        unilight.update(DB_USERINFO_NAME, uid, userInfo)
    end
end

-- 通过优惠券随机列表中随机出num个优惠券
function RandomCoupons(coupons, num)
    -- 随机排列优惠券列表
    for i,v in pairs(coupons) do
        local r = math.random(#coupons)
        local temp = coupons[i]
        coupons[i] = coupons[r]
        coupons[r] = temp
    end
    num = num or #coupons
    for i = #coupons,num+1, -1 do
        coupons[i] = nil
    end
    return coupons
end

-- 获取玩家优惠券总比
function GetSystemCouponTotalPercentage(uid)

    -- 金币通用优惠券总比例
    local goldCoinGeneralCouponRate = 0
    -- 绿宝石通用优惠券总比例
    local emeraldGeneralCouponRate = 0
    -- 金币非通用优惠券总比例
    local goldCoinNotGeneralCouponRate = 0

    -- 金币通用优惠券
    for i, v in ipairs(BackpackMgr.GetItemListByType(uid,GoldGeneralType)) do
        goldCoinGeneralCouponRate = goldCoinGeneralCouponRate + TableItemConfig[v.goodId].para2 * v.goodNum
    end

    -- 绿宝石通用优惠券
    for i, v in ipairs(BackpackMgr.GetItemListByType(uid,EmeraldGeneralType)) do
        emeraldGeneralCouponRate = emeraldGeneralCouponRate + TableItemConfig[v.goodId].para2 * v.goodNum
    end

    -- 金币非通用优惠券
    for i, v in ipairs(BackpackMgr.GetItemListByType(uid,GoldNotGeneralType)) do
        goldCoinNotGeneralCouponRate = goldCoinNotGeneralCouponRate + TableItemConfig[v.goodId].para2 * v.goodNum
    end


    -- 打包返回值
    local res = {
        goldCoinGeneralCouponRate = goldCoinGeneralCouponRate,
        emeraldGeneralCouponRate = emeraldGeneralCouponRate,
        goldCoinNotGeneralCouponRate = goldCoinNotGeneralCouponRate,
    }
    return res
end
