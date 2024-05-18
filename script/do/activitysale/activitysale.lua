module("ActivitySaleMgr", package.seeall)
local shopCfg = import "table/table_shop_config"
local activitySaleAllCfg = import "table/table_activity_sale"
local activitySaleCurCfg=import "table/table_activitysale_cur"

--获取商品信息
function GetGoodsInfo(uid)
    OpenActivitySale(uid,2)
    local activitySale = unilight.getdata("activitysale", uid)
    if activitySale.endTime < os.time() or activitySale.isOpen==false then
        unilight.info("活动特卖时间结束,玩家:" .. uid)
    end
    local goodsInfo = {}
    for i,j in pairs(activitySaleCurCfg) do
        for m,n in pairs(activitySaleAllCfg) do
            if j.shopID==n.shopID then
            unilight.error("商品状态:"..table2json(activitySale))
            unilight.error("j的值为:"..table2json(j))
            local shopList = ShopMgr.GetShopListByType(Const.SHOP_TYPE.ACTIVITYSALE)
                for k, v in pairs(shopList) do
                    if j.shopID==v.ID then
                        --计算在比例、等级系数和vip系数后玩家能得到的金币（充值项的金币计算是=金币基础值 * vip系数 * 等级系数 * （1 + 额外百分比/100））
                        local tmpGold = chessuserinfodb.GetChipsAddition(uid, v.shopGoods[1]["goodNum"])
                        local trueGold=tmpGold*(1+n.ratio/100)
                        table.insert(goodsInfo, { BuyOrder=i,shopID = v.ID, price = v.price, gold = trueGold,goodsState=activitySale.canBuyArr[j.ID].state,ratio=n.ratio})
                        break
                    end
                end
            end
        end
    end
    unilight.info("<GetGoodsInfo>商品信息:"..uid,table2json(goodsInfo))
    return goodsInfo
end

--设置购买记录
function RecordDataToSale(shopID, uid)
    local desc = "ok"
    local has = false
    local activitySale = unilight.getdata("activitysale", uid)
    if activitySale == nil or activitySale.isOpen ~= true then
        return "activitySale没有开启"
    end

    for k, v in pairs(activitySale.canBuyArr) do
        if v["shopID"] == shopID then
            if v["state"] == Const.GOODS_STATE.BOUGHT then
                desc = "玩家已经购买过该商品"
                has = true
                break
            elseif v["state"] == Const.GOODS_STATE.LOCKING then
                desc = "玩家还不能购买该商品"
                has = true
                break
            else
                --将该商品设置为已经购买
                v["state"] = Const.GOODS_STATE.BOUGHT
                --解锁下一个商品
                activitySale.canBuyArr[k+1].state=Const.GOODS_STATE.CAN_BUY
                unilight.savedata("activitysale", activitySale)
                has = true
                break
            end
        end
    end

    if has == false then
        desc = "shopID错误或不存在该商品"
    end

    return desc
end


--activitySale的开启
--    CAN_BUY = 1; --可以买
--    BOUGHT = 2; --已经买了
--    LOCKING = 3; --上锁中
--type为活动特卖类型，1为汉堡（任选购买），2为含免费礼包（只能依次购买）
function OpenActivitySale(uid, type)
    local activitySale = unilight.getdata("activitysale", uid)
    --初始化玩家的数据，并提前存入玩家本次能购买的所有商品
    if activitySale == nil then
        activitySale = {
            _id = uid,
            activityType = type, --当前开启的活动类型
            isOpen = true, --此活动是否开启
            endTime = os.time() + 24 * 60 * 60, --活动结束时间,活动时间是一天
            canBuyArr = {}, --各商品是否可以购买
        }
        for k, v in ipairs(activitySaleCurCfg) do
            if type == 1 then
                --初始值为能购买（一个账号在生命期内，一个商品只能购一次）
                table.insert(activitySale.canBuyArr, { shopID = v.shopID, state = Const.GOODS_STATE.CAN_BUY })
            elseif type == 2 then
                --只能从第一个开始购买，必须完成当前一个礼包，才能够解锁下一个。每个礼包限购1次
                if k == 1 then
                    --将第一个初始化为可以购买
                   activitySale.canBuyArr[k]={shopID = v.shopID, state = Const.GOODS_STATE.CAN_BUY }
                else
                    --将其他初始化为不可以购买
                    activitySale.canBuyArr[k]={ shopID = v.shopID, state = Const.GOODS_STATE.LOCKING }
                end
            end
        end
        unilight.savedata("activitysale", activitySale)
    else
        activitySale.isOpen = true
        unilight.savedata("activitysale", activitySale)
    end
    unilight.info("开启activitySale成功,玩家:" .. uid)
end

--activitySale的关闭
function CloseActivitySale(uid)
    local activitySale = unilight.getdata("activitysale", uid)
    activitySale.isOpen = false
    activitySale.activityType=nil
    activitySale.activityType = nil
    activitySale.canBuyArr = nil
    unilight.savedata("activitysale", activitySale)
    unilight.info("关闭activitySale成功,玩家:" .. uid)
end



