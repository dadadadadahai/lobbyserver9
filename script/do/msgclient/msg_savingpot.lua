--处理玩家请求存钱罐信息
Net.CmdSavingPotInfoCmd_C = function(cmd, laccount)
    local tableParameterParameter = import "table/table_parameter_parameter"
    local res = {}
    local desc = "ok"--消息状态描述
    res["do"] = "Cmd.SavingPotInfoCmd_S"
    local uid = laccount.Id
    --获取玩家数据
    local userInfo = unilight.getdata("userinfo",uid)

    if userInfo.property.level < 0 then
        --todo 测试用
        --tableParameterParameter[201].Parameter then
        --判断玩家等级是否达到六级
        desc = "等级不足，解锁存钱罐失败"
        unilight.error(string.format("<Net.CmdSavingPotInfoCmd_C>玩家等级不足以开启存钱罐，玩家%d的等级为%d：", uid, userInfo.property.level))
    else
        --玩家刚打碎存钱罐,需要重新计算数据
        if userInfo.savingPot.gold == 0 then
            desc = SavingPotMgr.CalculateMoneyForSavingPot(uid)
            --重新获取玩家数据
           userInfo = unilight.getdata("userinfo",uid)
            unilight.info(string.format("<Net.CmdSavingPotInfoCmd_C>玩家%d生成存钱罐信息成功", uid))
        end
    end

    if desc ~= "ok" then
        res["data"] = {
            desc = desc
        }
    else
        res["data"] = {
            lotteryProgress = userInfo.savingPot.lotteryProgress,
            gold = userInfo.savingPot.gold,
            isUpperLimit = userInfo.savingPot.isUpperLimit,
            couponValue = userInfo.savingPot.couponValue,
            discountGold = userInfo.savingPot.discountGold,
            price = userInfo.savingPot.payMoney,
            shopID = userInfo.savingPot.shopID,
            desc = desc
        }
    end
    return res
end

