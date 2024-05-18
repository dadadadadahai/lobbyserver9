--获取需要显示的商品信息
Net.CmdActivitySaleInfoCmd_C = function(cmd, laccount)
    local res = {}
    local description = "ok"
    res["do"] = "Cmd.ActivitySaleInfoCmd_S"
    local uid = laccount.Id
    local goodsInfo = ActivitySaleMgr.GetGoodsInfo(uid)
    if goodsInfo == nil then
        description = "获取商品信息失败"
        unilight.info("<Net.CmdActivitySaleInfoCmd_C>没有到获取goodsInfo，玩家：" .. uid)
    end

    unilight.info(table2json(goodsInfo))

    if description ~= "ok" then
        res["data"] = {
            desc = description
        }
    else
        res["data"] = {
            info = goodsInfo,
            desc = description,
        }
    end
    return res
end


--购买之前
Net.CmdActivitySaleBuyOneGoodsCmd_C = function(cmd, laccount)
    local res = {}
    res["do"] = "Cmd.ActivitySaleBuyOneGoodsCmd_S"
    local uid = laccount.Id
    --计算金币、记录数据
    local description = ActivitySaleMgr.RecordDataToSale(cmd.data.shopID, uid)

    res["data"] = {
        desc = description
    }

    return res
end

--免费商品的发放
Net.CmdFreeGoodsCmd_C = function(cmd, laccount)
    local description = ""
    local shopCfg = import "table/table_shop_config"
    local res = {}
    res["do"] = "Cmd.FreeGoodsCmd_S"
    local uid = laccount.Id
    --ActivitySaleMgr.OpenActivitySale(uid,2)
    local activitySale = unilight.getdata("activitysale", uid)
print("商品信息："..table2json(activitySale.canBuyArr))
    for k, v in pairs(activitySale.canBuyArr) do
        print("====================1=====================")
        if v.shopID == cmd.data.shopID then
            print("====================2=====================")
            if v.state == Const.GOODS_STATE.LOCKING then
                description = "商品上锁中，不能购买"
                unilight.error(string.format("<Net.CmdFreeGoodsCmd_C>玩家%d正在购买上锁中的商品,商品ID:%d",uid,cmd.data.shopID))
            elseif v.state == Const.GOODS_STATE.BOUGHT then
                description = "该商品已经购买过了"
                unilight.error(string.format("<Net.CmdFreeGoodsCmd_C>玩家%d正在购买已经购买过的商品,商品ID:%d",uid,cmd.data.shopID))
            elseif v.state == Const.GOODS_STATE.CAN_BUY then
                print("====================3=====================")
                --判断是否是免费商品
                if shopCfg[cmd.data.shopID].price == 0 then
                    local moneyNum = shopCfg[cmd.data.shopID].shopGoods[1].goodNum
                    local moneyID = shopCfg[cmd.data.shopID].shopGoods[1].goodId
                    --计算在等级系数和vip系数后玩家能得到的金币
                    local tmpGold = chessuserinfodb.GetChipsAddition(uid, moneyNum)
                    --发放金币
                    BackpackMgr.GetRewardGood(uid, moneyID, tmpGold, 0, Const.GOODS_SOURCE_TYPE.ACTIVITY_SALE)
                    for i, j in pairs(shopCfg[cmd.data.shopID].extGoods) do
                        --发放额外商品
                        BackpackMgr.GetRewardGood(uid, j.goodId, j.goodNum, 0, Const.GOODS_SOURCE_TYPE.ACTIVITY_SALE)
                    end
                    --修改商品的状态
                    v.state = Const.GOODS_STATE.BOUGHT
                    activitySale.canBuyArr[k+1].state=Const.GOODS_STATE.CAN_BUY
                    unilight.savedata("activitysale",activitySale)
                    description = "ok"
                    unilight.info(string.format("<Net.CmdFreeGoodsCmd_C>玩家%d购买免费商品成功,商品ID:%d",uid,cmd.data.shopID))
                end
            end
        end
    end
    print("====================4=====================")


    res["data"] = {
        desc = description
    }
    return res
end