--双王之战相关协议


--101请求抽奖
Net.CmdGetPickGameLotteryDrawCmd_C = function(cmd, laccount)
    local res = {}
    --获取抽奖位置
    local pos = cmd.data.pos
    local uid = laccount.Id
    local pickGameInfo = godstatueMgr.CmdOpenBoxPickGame(uid,pos)
    res["do"] = "Cmd.GetPickGameLotteryDrawCmd_S"
    local data = {
        items = {}

    }
    local newItem={
    goodId = pickGameInfo.items[pos].goodId,
    goodNum = pickGameInfo.items[pos].goodNum,
    isFree = pickGameInfo.items[pos].isFree,
    pos = pickGameInfo.items[pos].pos,
    isCan = pickGameInfo.items[pos].isCan,                    --是否升级
    }

    table.insert(data.items,newItem)
    res["data"]=data
	return res
end

--102请求神像信息
Net.CmdGetGodStatueInfoCmd_C = function (cmd,laccount)
    local res = {}
    local uid = laccount.Id
    local godStatueInfo =  godstatueMgr.CmdGetGodStatueInfo(uid)
    res["do"] = "Cmd.GetGodStatueInfoCmd_S"
    local data = {
        lv_left = godStatueInfo.leftGodLv,
        lv_right = godStatueInfo.rightGodLv,
        free_count = godStatueInfo.freeCount,
        buy_count = godStatueInfo.buyCount,
        leftPickCount = godStatueInfo.leftPickCount,
        leftStatue = {},
        rightStatue = {},
        state =godStatueInfo.state
    }

    for k, v in pairs(godStatueInfo.leftBadege) do
        table.insert(data.leftStatue,v)
    end

    for k, v in pairs(godStatueInfo.rightBadge) do
        table.insert(data.rightStatue,v)
    end
    res["data"] = data
    return res
    
end

--103请求购买pickGame游戏次数
Net.CmdBuyPickGameCountCmd_C = function (cmd,laccount)
    local res = {}
    local uid = laccount.Id
    res["do"] = "Cmd.BuyPickGameCountCmd_S"
    local  rest = godstatueMgr.CmdBuyPickGameCount(uid)
    res["data"]={
        buyCount = rest
    }    
    
    return res
end

--104请求神像升级
Net.CmdGodStatueUpLvCmd_C = function (cmd,laccount)
    local res = {}
    local uid = laccount.Id
    local type = cmd.data.type
    local godstatueInfo = godstatueMgr.CmdUpLvGodStatue(uid,type)
    res["do"] = "Cmd.GodStatueUpLvCmd_S"
    res["data"] = {
        left_old_lv = godstatueInfo.leftGodLv-1,
        left_new_lv = godstatueInfo.leftGodLv,
        right_old_lv = godstatueInfo.rightGodLv-1,
        right_new_lv = godstatueInfo.rightGodLv
    }
    return res
    
end

--105获取当天奖励信息
Net.CmdGetPickGameRewardDayCmd_C = function (cmd,laccount)
    local res = {}
    local uid  = laccount.Id
    local pickGameInfo = godstatueMgr.CmdGetPickGameInfo(uid)
    res["do"] = "Cmd.GetPickGameRewardDayCmd_S"
    local data = {
        items = {}
    }
    for k, v in pairs(pickGameInfo.items) do
        table.insert(data.items,v)
    end
    res["data"]=data
    return res
end

--106 获取付费奖励池信息
Net.CmdGetBuyPickGameRewardInfoCmd_C = function (cmd,laccount)
    local res = {}
    local uid  = laccount.Id
    local buyItems = godstatueMgr.OpenBuyPickGameByRate(uid,1)
    res["do"]="Cmd.GetBuyPickGameRewardInfoCmd_S"
    local data={
        items = {}
    }

    for k, v in pairs(buyItems) do
      table.insert(data.items,v)
    end
    res["data"]=data
    return res
end

--107 请求领取奖励 
Net.CmdGetReceiveCmd_C = function (cmd,laccount)
    local res = {}
    local uid  = laccount.Id
    local items = godstatueMgr.GetReceive(uid)
    res["do"] = "Cmd.GetReceiveCmd_S"
    res["data"]={
        goods = items
    }
    return res
end