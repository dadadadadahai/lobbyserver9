--玩家登录、退出商店、退出充值界面时，客户端主动请求信息
Net.CmdSuperSaleInfoCmd_C = function(cmd, laccount)
    local res = {}
    local description = "ok"  --状态描述
    local time --剩余时间
    res["do"] = "Cmd.SuperSaleInfoCmd_S"
    local uid = laccount.Id
    local userInfo = chessuserinfodb.RUserInfoGet(uid)

    if userInfo.superSale.isFirst == true then
        --玩家第一次参加特卖
        --生成特卖
        SuperSaleMgr.CreateSuperSale(uid)
        userInfo = chessuserinfodb.RUserInfoGet(uid)
        userInfo.superSale.isFirst = false
        unilight.savedata("userinfo", userInfo)
    elseif userInfo.superSale.endTime == 0 and userInfo.superSale.nextStartTime > os.time() then
        description = "特卖开始的随机时间未到"
    elseif userInfo.superSale.endTime == 0 and userInfo.superSale.nextStartTime <= os.time() and userInfo.superSale.hasSuperSale == false then
        --生成特卖
        SuperSaleMgr.CreateSuperSale(uid)
        userInfo = chessuserinfodb.RUserInfoGet(uid)
    end

    --剩余时间
    if userInfo.superSale.endTime > os.time() then
        time = userInfo.superSale.endTime - os.time()
    else
        time = userInfo.superSale.nextStartTime
        description = "特卖显示时间已经结束"
    end
    if description ~= "ok" then
        res["data"] = {
            desc = description
        }
    else
        res["data"] = {
            originalMoney = userInfo.superSale.originalMoney,
            discountsMoney = userInfo.superSale.discountsMoney,
            gold = userInfo.superSale.gold,
            reward = userInfo.superSale.reward,
            remainTime = time,
            shopID = userInfo.superSale.shopID,
            desc = description,
        }
    end
    return res
end

--特卖结束
Net.CmdSuperSaleEndCmd_C = function(cmd, laccount)
    local superSaleCfg = import "table/table_supersale_config"
    local res = {}
    res["do"] = "Cmd.SuperSaleEndCmd_S"
    local uid = laccount.Id
    local userInfo = chessuserinfodb.RUserInfoGet(uid)
    --随机下次开始的时间
    local randTime = math.random(superSaleCfg[20].minTime, superSaleCfg[20].maxTime)

    --重置玩家superSale数据
    --记录结束时间
    userInfo.superSale.lastEndTime = os.time()--这次结束时间
    --下次开始时间
    local nextTime = randTime * 60 + userInfo.superSale.lastEndTime

    userInfo.superSale.nextStartTime = nextTime--下次特卖开始时间
    userInfo.superSale.hasSuperSale = false--玩家当前是否有特卖
    userInfo.superSale.originalMoney = 0--原始金额
    userInfo.superSale.discountsMoney = 0--优惠后的金额
    userInfo.superSale.gold = 0--金币
    userInfo.superSale.reward = {}--额外奖励
    userInfo.superSale.endTime = 0--特卖结束时间(时间限制)
    userInfo.superSale.shopID = 0--特卖的商品ID
    unilight.savedata("userinfo", userInfo)

    res["data"] = {
        nextStartTime = nextTime,
        desc = "ok"
    }
    return res
end