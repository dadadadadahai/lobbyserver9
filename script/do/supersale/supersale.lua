module("SuperSaleMgr", package.seeall)
local shopCfg = import "table/table_shop_config"
local superSaleCfg = import "table/table_supersale_config"
local saleRangeCfg = import "table/table_supersale_range"
local saleProbCfg = import "table/table_supersale_prob_"
local saleNumberCfg = import "table/table_supersale_time"
local saleRandomCfg = import "table/table_supersale_random"

--创建superSale
function CreateSuperSale(uid)
    local userInfo = unilight.getdata("userinfo", uid)
    --设置随机种子
    math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 9)))
    local oldMoney = 0 --原始金额
    local trueMoney = 0-- 实际金额
    local gold = 0--发放的金币（old金币）
    local extAward = {}--额外奖励（实际金额的额外奖励）
    local shopID=0--充值的商品ID
    local number = userInfo.superSale.rechargeNum--玩家购买特惠的次数

    if number < table.len(saleNumberCfg) then
        oldMoney = saleNumberCfg[number + 1].oldMoney
        trueMoney = saleNumberCfg[number + 1].curMoney
    else
        --随机一组金额
        local randNum = math.random(table.len(saleRandomCfg))
        oldMoney = saleRandomCfg[randNum].oldMoney
        trueMoney = saleRandomCfg[randNum].curMoney
    end

    
    local shopList = ShopMgr.GetShopListByType(Const.SHOP_TYPE.SUPERSALE) or {}
    for index, cfg in pairs(shopList) do
        if cfg.price == oldMoney then
            shopID=cfg.ID
            local tmpGold = cfg.shopGoods[1]["goodNum"]
            --玩家实际得到的金币
            gold = chessuserinfodb.GetChipsAddition(uid, tmpGold)
        end
        if cfg.price == trueMoney then
            extAward=cfg.extGoods
        end
    end

    --结束时间
    time = os.time() + superSaleCfg[20].LimitTime * 60

    userInfo.superSale.hasSuperSale = true--玩家当前是否有特卖
    userInfo.superSale.originalMoney = oldMoney--原始金额
    userInfo.superSale.discountsMoney = trueMoney--优惠后的金额
    userInfo.superSale.gold = gold--金币
    userInfo.superSale.reward = extAward--额外奖励
    userInfo.superSale.endTime = time--特卖e结束时间
    userInfo.superSale.shopID = shopID--特卖的商品ID
    userInfo.superSale.nextStartTime = 0--下次开始时间
    --保存玩家的superSale信息
    unilight.savedata("userinfo", userInfo)

    unilight.info(string.format("玩家%d生成特惠信息成功,详细信息：%s",uid,table2json(userInfo.superSale)))

-- 金额需要计算的版本
--[[
    --标准金额
    local standardMoney = (superSaleCfg[20].ID + userInfo.property.vipExp ^ (1 / 2)) * superSaleCfg[20].moneyCoefficient
    --随机数
    local randNum = math.random(superSaleCfg[20].goldLowerLimit * 10, superSaleCfg[20].goldUpperLimit * 10) / 10
    --随机金额
    local randMoney = standardMoney * randNum * 100
    --实际充值商品
    local result = FindPrice(randMoney)
    if result == nil then
        unilight.error("<CreateSuperSale>没有查找到金额1，玩家：" .. uid)
        return
    end
    --实际充值金额
    local trueMoney = result.price
    unilight.info(string.format("玩家%d随机到的实际充值金额：%d", uid, trueMoney))

    local probArr = {}--存放概率的数组
    --从配置中取概率数组
    if userInfo.property.vipLevel < 1 then
        userInfo.property.vipLevel = 1
        probArr = saleProbCfg[1].probability
        unilight.error("<CreateSuperSale>出现玩家vip等级小于1，将重置为1，玩家：" .. uid)
    elseif userInfo.property.vipLevel < 5 then
        probArr = saleProbCfg[userInfo.property.vipLevel].probability
    elseif userInfo.property.vipLevel >= 5 then
        probArr = saleProbCfg[5].probability
    end
    --按权重随机范围ID,返回的index为范围ID
    local rangeID = SavingPotMgr.RandomCouponIndex(probArr)

    --随机指定范围的折扣
    local discount = math.random(saleRangeCfg[rangeID].minDiscount, saleRangeCfg[rangeID].maxDiscount)
    unilight.info("随机的折扣为：" .. discount * 0.01)

    --原充值金额
    local oldRandMoney = trueMoney / (discount * 0.01)
    --获取原始充值商品
    local result2 = FindPrice(oldRandMoney)
    if result2 == nil then
        unilight.error("<CreateSuperSale>没有查找到金额2，玩家：" .. uid)
        return
    end
    --原始充值金额
    oldMoney = result2.price
    unilight.info(string.format("玩家%d随机到的原始充值金额：%d", uid, oldMoney))
    --玩家获得的金币
    local gold = chessuserinfodb.GetChipsAddition(uid, result2.shopGoods[1]["goodNum"])
    --结束时间
    time = os.time() + superSaleCfg[20].LimitTime * 60

    userInfo.superSale.hasSuperSale = true--玩家当前是否有特卖
    userInfo.superSale.originalMoney = oldMoney--原始金额
    userInfo.superSale.discountsMoney = trueMoney--优惠后的金额
    userInfo.superSale.gold = gold--金币
    userInfo.superSale.reward = result.extGoods--额外奖励
    userInfo.superSale.endTime = time--特卖结束时间
    userInfo.superSale.shopID = result.ID--特卖的商品ID
    userInfo.superSale.nextStartTime = 0--下次开始时间
    --保存玩家的superSale信息
    unilight.savedata("userinfo", userInfo)]]
end


--通过随机金额查找对应的实际金额
function FindPrice(randMoney)
    local arr = {}
    local resultArr = {} --查找到的结果

    local shopList = ShopMgr.GetShopListByType(Const.SHOP_TYPE.SUPERSALE)
    for k, v in pairs(shopList) do
        --存钱罐
        table.insert(arr, v)
    end
    --按价格从大到小排序
    table.sort(arr, function(a, b)
        return a.price > b.price
    end)

    --开始查找
    for k, v in ipairs(arr) do
        if randMoney == v.price then
            resultArr = v
            break
        elseif randMoney > arr[1].price or randMoney < arr[#arr].price then
            if randMoney > arr[1].price then
                resultArr = arr[1]
            else
                resultArr = arr[#arr]
            end
            break
        elseif randMoney < v.price and randMoney > arr[k + 1].price then
            a = randMoney - arr[k + 1].price
            b = v.price - randMoney
            if a - b > 0 then
                resultArr = v
                break
            elseif a - b < 0 then
                resultArr = arr[k + 1]
                break
            else
                resultArr = arr[k + 1]
                break
            end
        end
    end

    return resultArr
end


--记录玩家充值特卖的次数
function AddSuperSaleNumber(uid, shopID)
    --判断玩家购买的商品是不是特卖的商品
    if shopCfg[shopID].shopType ~= Const.SHOP_TYPE.SUPERSALE then
        return
    end

    local userInfo = unilight.getdata("userinfo", uid)
    --增加购买次数
    userInfo.superSale.rechargeNum = userInfo.superSale.rechargeNum + 1
    unilight.savedata("userinfo", userInfo)
    unilight.info(string.format("玩家%d本次购买的是特惠商品，商品ID:%d",uid,shopID))
end
