--烹饪基本信息
Net.CmdCookingBaseInfoCmd_C=function (cmd,laccount)
    local data=cmd.data
    local uid=laccount.Id
    local res={}
    res['do']='Cmd.CookingBaseInfoCmd_S'
    res['data'] = cookingmgr.CookingBaseInfoCmd_C(data,uid)
    return res
end
--食材币兑换购物篮
Net.CmdCookingBuyBasketCmd_C=function (cmd,laccount)
    local data=cmd.data
    local uid=laccount.Id
    local res={}
    res['do']='Cmd.CookingBuyBasketCmd_S'
    res['data'] = cookingmgr.CookingBuyBasketCmd_C(data,uid)
    return res
end
--领取合成菜肴奖励
Net.CmdCookingRecvFoodRewardCmd_C=function (cmd,laccount)
    local data=cmd.data
    local uid=laccount.Id
    local res={}
    res['do']='Cmd.CookingRecvFoodRewardCmd_S'
    res['data'] = cookingmgr.CookingRecvFoodRewardCmd_C(data,uid)
    return res
end
--领取过关奖励
Net.CmdCookingPassCmd_C=function (cmd,laccount)
    local data=cmd.data
    local uid=laccount.Id
    local res={}
    res['do']='Cmd.CookingPassCmd_S'
    res['data'] = cookingmgr.CookingPassCmd_C(data,uid)
    return res
end
--通关加倍需要花费绿钻数,原始金币数量
Net.CmdCookingGetMulLvCmd_C=function(cmd,laccount)
    local data=cmd.data
    local uid=laccount.Id
    local res={}
    res['do']='Cmd.CookingGetMulLvCmd_S'
    res['data'] = cookingmgr.CookingGetMulLvCmd_C(data,uid)
    return res
end
--领取任务奖励
Net.CmdCookingRecvTaskrewardCmd_C=function(cmd,laccount)
    local data=cmd.data
    local uid=laccount.Id
    local res={}
    res['do']='Cmd.CookingRecvTaskrewardCmd_S'
    res['data'] = cookingmgr.CookingRecvTaskrewardCmd_C(data,uid)
    return res
end
--界面展示过关金币呈现
Net.CmdCookingGuankaGoldCmd_C=function (cmd,laccount)
    local data=cmd.data
    local uid=laccount.Id
    local res={}
    res['do']='Cmd.CookingGuankaGoldCmd_S'
    res['data'] = cookingmgr.CookingGuankaGoldCmd_C(data,uid)
    return res
end
--万能币兑换任意食材
Net.CmdCookingExchangeFoodCmd_C=function (cmd,laccount)
    local data=cmd.data
    local uid=laccount.Id
    local res={}
    res['do']='Cmd.CookingExchangeFoodCmd_S'
    res['data'] = cookingmgr.CookingExchangeFoodCmd_C(data,uid)
    return res
end
--获取当前拥有的食材信息
Net.CmdCookingGetFoodsInfoCmd_C=function (cmd,laccount)
    local data=cmd.data
    local uid=laccount.Id
    local res={}
    res['do']='Cmd.CookingGetFoodsInfoCmd_S'
    res['data'] = cookingmgr.CookingGetFoodsInfoCmd_C(data,uid)
    return res
end
--多余食材结算消息
Net.CmdCookingSurplusFoodsCmd_C=function (cmd,laccount)
    local data=cmd.data
    local uid=laccount.Id
    local res={}
    res['do']='Cmd.CookingSurplusFoodsCmd_S'
    res['data'] = cookingmgr.CookingSurplusFoodsCmd_C(data,uid)
    return res
end
--请求当前任务信息
Net.CmdCookkingGetTaskInfoCmd_C=function (cmd,laccount)
    local data=cmd.data
    local uid=laccount.Id
    local res={}
    res['do']='Cmd.CookkingGetTaskInfoCmd_S'
    res['data'] = cookingmgr.CookkingGetTaskInfoCmd_C(data,uid)
    return res
end
--获取烹饪币
Net.CmdCookingGetFoodCoinCmd_C =function (cmd,laccount)
    local data=cmd.data
    local uid=laccount.Id
    local res={}
    res['do']='Cmd.CookingGetFoodCoinCmd_S'
    res['data'] = cookingmgr.CookingGetFoodCoinCmd_C(data,uid)
    return res
end