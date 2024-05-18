module("SavingPotMgr", package.seeall)
local savingPotCfg = import "table/table_savingpot_config"
local couponCfg = import "table/table_savingpot_coupon"
local totalCfg = import "table/table_savingpot_total"
local itemCfg = import "table/table_item_config"


--计算存钱罐的优惠券值、优惠金币、存钱罐价格等
function CalculateMoneyForSavingPot(uid)
    local trueMoney = 0 --充值实际金额
    local couponValue = 0--优惠券值
    local discountGold = 0--优惠金币
    local initGold = 0--存钱罐初始金币
    local upperLimitBase = 0 --存钱罐金币上限基础值
    local shopID = 0--购买的这个商品的ID

    --获取玩家数据
    local userInfo = chessuserinfodb.RUserInfoGet(uid)
    if userInfo == nil then
        unilight.error("<CalculateMoneyForSavingPot>userInfo为空,玩家：" .. uid)
        return "获取的玩家信息为空"
    end

    local standardMoney = savingPotCfg[1]["base"] + userInfo.property.vipLevel ^ (1 / 2) * savingPotCfg[1]["moneyCoefficient"]

    --设置随机种子
    math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 9)))

    local arrVal = {}
    local arrProb = {}
    --随机优惠券值
    --将优惠券值和其权重数分别存入不同的数组中（优惠券值和其对应的权重的下标相同）
    for k, v in pairs(couponCfg) do
        arrVal[k] = v["couponRatio"]
        arrProb[k] = v["couponProbRatio"]
    end
    --随机的优惠券值下标
    local index = RandomCouponIndex(arrProb)
    if index == 0 then
        unilight.error("<CalculateMoneyForSavingPot>请求存钱罐信息时，获取权重下标失败，玩家：" .. uid)
        return
    end
    --随机到的优惠券值
    couponValue = arrVal[index]

    for k, v in pairs(couponCfg) do
        if v.couponRatio == couponValue then
            --将优惠券加入背包
            BackpackMgr.GetRewardGood(uid, v.itemID, 1, Const.GOODS_SOURCE_TYPE.SAVINGPOT_CONFIG_RANDOM)
        end
    end

    --生成随机数
    local randNum = math.random(savingPotCfg[1]["goldLowerLimit"] * 10, savingPotCfg[1]["goldUpperLimit"] * 10) / 10
    --随机金额
    local randMoney = standardMoney * randNum * 100
    unilight.info(string.format("<CalculateMoneyForSavingPot>玩家%d的随机金额为:%d", uid, randMoney))

    --根据商店配置表中的价格，向下取最大金额
    local arr = {}
    local shopList = ShopMgr.GetShopListByType(Const.SHOP_TYPE.SAVINGPOT)
    for k, v in pairs(shopList) do
        table.insert(arr, v)
    end
    table.sort(arr, function(a, b)
        return a.price > b.price
    end)

    for k, v in ipairs(arr) do
        if randMoney == v.price then
            trueMoney = v["price"]
            upperLimitBase = v["shopGoods"][1]["goodNum"]
            shopID = v["ID"]
            break
        elseif randMoney > arr[1].price or randMoney < arr[#arr].price then
            if randMoney > arr[1].price then
                trueMoney = arr[1]["price"]
                upperLimitBase = arr[1]["shopGoods"][1]["goodNum"]
                shopID = arr[1]["ID"]
            else
                trueMoney = arr[#arr]["price"]
                upperLimitBase = arr[#arr]["shopGoods"][1]["goodNum"]
                shopID = arr[#arr]["ID"]
            end
            break
        elseif randMoney < v.price and randMoney > arr[k + 1].price then
            trueMoney = arr[k + 1]["price"]
            upperLimitBase = arr[k + 1]["shopGoods"][1]["goodNum"]
            shopID = arr[k + 1]["ID"]
            break
        end
    end
    local base = savingPotCfg[1]["extremityCoefficient"] * 0.01 * upperLimitBase
    local upperLimit = chessuserinfodb.GetChipsAddition(uid, base)

    --根据公式计算存钱罐的初始金币()
    local baseValue = upperLimitBase * savingPotCfg[1]["resetCoefficient"] * 0.01
    initGold = chessuserinfodb.GetChipsAddition(uid, baseValue)
    if initGold == nil then
        unilight.error("<CalculateMoneyForSavingPot>存钱罐中计算玩家的重置金币出错，玩家：" .. uid)
        return "存钱罐中计算玩家的重置金币出错"
    end

    --查找背包里所有的存钱罐优惠券
    local couponArr = BackpackMgr.GetItemListByType(uid, Const.GOODS_SOURCE_TYPE.SAVINGPOT_COUPON)
    for _, goodInfo in pairs(couponArr) do
        local k = goodInfo.goodId
        couponValue = couponValue + tonumber(itemCfg[k].para2) * goodInfo.goodNum
    end
    userInfo.savingPot.gold = initGold
    --优惠后的金币
    discountGold = userInfo.savingPot.gold + couponValue * 0.01 * userInfo.savingPot.gold

    unilight.info(string.format("<CalculateMoneyForSavingPot>计算出的玩家%d的重置金币为:%d", uid, initGold))

    if initGold >= upperLimit then
        unilight.error(string.format("重置金币：%d,上限：%d", initGold, upperLimit))
        unilight.error("<CalculateMoneyForSavingPot>存钱罐的重置初始金币大于上限,玩家：" .. uid)

        return "存钱罐的重置初始金币大于上限"
    end

    --保存更改信息

    userInfo.savingPot.shopID = shopID
    userInfo.savingPot.isUpperLimit = false
    userInfo.savingPot.upperLimit = upperLimit
    userInfo.savingPot.couponValue = couponValue
    userInfo.savingPot.discountGold = discountGold
    userInfo.savingPot.payMoney = trueMoney
    unilight.savedata("userinfo", userInfo)

    --判断获取充值金额等信息
    if userInfo.savingPot.couponValue == nil or userInfo.savingPot.couponValue == nil or userInfo.savingPot.payMoney == nil then
        unilight.error("<Net.SavingPotInfoCmd_C>存钱罐请求中，计算充值金额等信息有误，玩家：" .. uid)
        return "存钱罐请求时，计算充值金额等信息有误"
    end

    return "ok"
end


--随机优惠券值，返回下标
function RandomCouponIndex(arrProb)
    local total = 0 --总权重值
    local index = 0--随机到的权重值下标
    for k, v in ipairs(arrProb) do
        total = total + v
    end
    --随机数
    local randNum = math.random(1, total)
    for k, v in ipairs(arrProb) do
        if randNum <= v then
            index = k
            break
        end
        randNum = randNum - v
    end
    return index
end

--计算子游戏每次SPIN时往存钱罐里加入的金币，并保存数据
function AddGoldToSavingPot(uid, betGold)
    --betGold为玩家单次SPIN的下注金币
    local increaseCoef --增长系数
    local userInfo = chessuserinfodb.RUserInfoGet(uid)
    --获取玩家的等级系数
    local levelCoe = levelmgr.GetXs(uid)
    if levelCoe == 0 then
        unilight.error("<AddGoldToSavingPot>存钱罐中计算玩家的等级系数出错，玩家：" .. uid)
        return
    end
    --获取玩家vip金币系数
    local goldCoe = vipCoefficientMgr.GoldCoefficientForVip(uid)
    if levelCoe == 0 then
        unilight.error("<AddGoldToSavingPot>存钱罐中计算玩家的vip金币系数出错,玩家:" .. uid)
        return
    end

    --比例
    ratio = userInfo.savingPot.gold / levelCoe / goldCoe / userInfo.savingPot.upperLimit * 100
    print("比例：" .. ratio)
    for k, v in ipairs(totalCfg) do
        if ratio > savingPotCfg[1]["extremityCoefficient"] then
            --极限系数不增长
            increaseCoef = 0
        elseif ratio == v["totalRatio"] then
            increaseCoef = v["totalAddRatio"]
        elseif ratio > v["totalRatio"] and ratio < totalCfg[k + 1]["totalRatio"] then
            increaseCoef = v["totalAddRatio"]
        end
    end

    --存钱罐增加的金币
    addGold = betGold * increaseCoef
    if userInfo.savingPot.gold >= userInfo.savingPot.upperLimit then
        --存钱罐金币超过上限（为保险起见）
        userInfo.savingPot.gold = userInfo.savingPot.upperLimit
        userInfo.savingPot.isUpperLimit = true --金币已达上限
    elseif userInfo.savingPot.gold < userInfo.savingPot.upperLimit then
        --存钱罐金币没超过上限
        if userInfo.savingPot.gold + addGold >= userInfo.savingPot.upperLimit then
            --存钱罐金币没超过上限，但本次增加之后会超过上限
            userInfo.savingPot.gold = userInfo.savingPot.upperLimit
            userInfo.savingPot.isUpperLimit = true --金币已达上限
        else
            userInfo.savingPot.gold = userInfo.savingPot.gold + addGold
            userInfo.savingPot.isUpperLimit = false
        end
    end
    --保存更改信息
    chessuserinfodb.WUserInfoUpdate(uid, userInfo)

    --推送改变后的存钱罐金币
    local laccount = go.roomusermgr.GetRoomUserById(uid)
    local send = {}
    send["do"] = "Cmd.SavingPotAddGoldCmd_S"
    send["data"] = {
        gold = userInfo.savingPot.gold,
        desc = "ok"
    }

end



--玩家付款成功时给客户端发消息进行数据处理，并发送存钱罐进程奖励
function AfterBuySavingPotReward(uid, shopId)
    local exchangeReward = {}--奖励物品
    local rewardCfg = import "table/table_savingpot_reward"
    local send = {}
    send["do"] = "Cmd.AfterBuySavingPotRewardCmd_S"
    local laccount = go.roomusermgr.GetRoomUserById(uid)
    --获取玩家数据
    local userInfo = chessuserinfodb.RUserInfoGet(uid)
    --判断该商品是否为存钱罐
    if userInfo.savingPot.shopID ~= shopId then
        return
    end
    unilight.info("<AfterBuySavingPotReward>玩家正在购买存钱罐,玩家uid:" .. uid)

    --查找背包里所有的存钱罐优惠券
    local couponArr = BackpackMgr.GetItemListByType(uid, Const.GOODS_SOURCE_TYPE.SAVINGPOT_COUPON)
    --使用优惠券（具体的计算在生成存钱罐信息的时候已近完成）
    for _, goodInfo in pairs(couponArr) do
        local k = goodInfo.goodId
        BackpackMgr.UseItem(uid, k, goodInfo.goodNum, "砸碎存钱罐")
    end

    summary = {}
    --存钱罐任务进度及奖励
    if userInfo.savingPot.lotteryProgress < 4 then
        --进程分为四档
        userInfo.savingPot.lotteryProgress = userInfo.savingPot.lotteryProgress + 1
        --对应进度的奖励
        exchangeReward = rewardCfg[userInfo.savingPot.lotteryProgress]["reward"]
        --给玩家添加奖励
        for k, v in pairs(exchangeReward) do
            summary = BackpackMgr.GetRewardGood(uid, v["goodId"], v["goodNum"], Const.GOODS_SOURCE_TYPE.SAVINGPOT_PROGRESS, summary)
        end
    elseif userInfo.savingPot.lotteryProgress == 4 then
        --第四档会有不一样的奖励
        --对应进度的奖励
        exchangeReward = rewardCfg[userInfo.savingPot.lotteryProgress]["reward"]
        local byWaterReward = {}--黄钻活动奖励
        --todo 此处后续还增加黄钻活动的奖励
        --todo 获取黄钻奖励是哪一个

        --将黄钻奖励插入表中
        -- table.insert(exchangeReward, byWaterReward) --todo
        --给玩家添加奖励
        for k, v in pairs(exchangeReward) do
            summary = BackpackMgr.GetRewardGood(uid, v["goodId"], v["goodNum"], Const.GOODS_SOURCE_TYPE.SAVINGPOT_PROGRESS, summary)
        end
        userInfo.savingPot.lotteryProgress = 0
    end

    local ProgressReward = {}
    for k, v in pairs(summary) do
        table.insert(ProgressReward, { goodId = k, goodNum = v })
    end

    send["data"] = {
        lotteryProgress = userInfo.savingPot.lotteryProgress,
        reward = ProgressReward,
        desc = "ok"
    }
    unilight.success(laccount, send)

    --重置存钱罐信息
    userInfo.savingPot.gold = 0--存钱罐中存在的金币
    userInfo.savingPot.upperLimit = 0--金币上限
    userInfo.savingPot.isUpperLimit = false--是否已达存钱罐金币上限
    userInfo.savingPot.shopID = 0--购买存钱罐时支付商品的ID
    userInfo.savingPot.couponValue = 0--优惠券值
    userInfo.savingPot.discountGold = 0--优惠后的金币
    userInfo.savingPot.payMoney = 0--需要支付的钱

    --保存更改信息
    chessuserinfodb.WUserInfoUpdate(uid, userInfo)
end
