--请求获得收集列表 
Net.CmdAllListRequestCollectCmd_C = function (cmd, laccount)
	local uid = laccount.Id 
	CollectMgr.GetCollectList(uid, cmd.data.round)
end


--请求获得第几期奖励
Net.CmdRequestRewardCollectCmd_C = function (cmd, laccount)
	local uid = laccount.Id 
	local res = {}
	res["do"] = "Cmd.RequestRewardCollectCmd_S"

	if cmd.data == nil or cmd.data.round == nil or cmd.data.type == nil then
        res["data"] = {
            errno = 1,
            desc = "参数错误"
        }
        return res
    end

    CollectMgr.GetCollectReward(uid, cmd.data.round, cmd.data.type)
end


--请求获得历史期列表
Net.CmdRoundListRequestCollectCmd_C = function (cmd, laccount)
    local res = {}
	res["do"] = "Cmd.RoundListRequestCollectCmd_S"

    local roundList = CollectMgr.GetHistoryList(uid)
    res["data"] = {
        errno = 0,
        desc = "",
        roundList = roundList,
    }

    return res
end

--获得历史获得道具列表
Net.CmdItemHistoryCollectCmd_C = function(cmd, laccount)
	local uid = laccount.Id 
	local res = {}
	res["do"] = "Cmd.ItemHistoryCollectCmd_S"
    local itemList = CollectMgr.GetItemHistoryList(uid)
    res["data"] = {
        itemList = itemList
    }
    return res
end

--wild对换请求还缺失的道具列表
Net.CmdReqMissItemListCollectCmd_C = function(cmd, laccount)
    local uid = laccount.Id
	local msg  = CollectMgr.GetCollectMissItem(uid, cmd.data.round)
    return msg

end


--wild对换特定道具
Net.CmdWildConvertCollectCmd_C = function(cmd, laccount)
	local uid = laccount.Id 
	local res = {}
	res["do"] = "Cmd.WildConvertCollectCmd_S"
	if cmd.data == nil or cmd.data.round == nil or cmd.data.tarItemId == nil or cmd.data.srcItemId == nil then
        res["data"] = {
            errno = 1,
            desc = "参数错误"
        }
        return res
    end
	CollectMgr.WildToCollectItem(uid, cmd.data.round, cmd.data.srcItemId, cmd.data.tarItemId)
    
end


--请求打列商城列表
Net.CmdGetShopListCollectCmd_C = function(cmd, laccount)
    local uid = laccount.Id
    CollectShopMgr.GetShopList(uid)
end


--刷新商品列表
Net.CmdReqRefreshShopListCollectCmd_C = function(cmd, laccount)
    local uid = laccount.Id
    CollectShopMgr.ReqRefreshShopList(uid)
end

--今天每日奖励
Net.CmdGetDailyRewardCollectCmd_C = function(cmd, laccount)
    local uid = laccount.Id
    CollectShopMgr.GetFreeReward(uid)
end

--购买商品
Net.CmdReqBuyShopIdCollectCmd_C = function(cmd, laccount)
    local uid = laccount.Id
    local shopId = cmd.data.shopId
    local num    = cmd.data.num
    CollectShopMgr.BuyShopId(uid, shopId, num)
end
