

-- 打开商城列表
Net.CmdRequestOpenShopCmd_C = function(cmd, laccount)
	local uid = laccount.Id 

	local res = {}
	res["do"] = "Cmd.RequestOpenShopCmd_S"

	if cmd.data == nil or cmd.data.shopType == nil then
		res["data"] = {
			ret 	= 1,
			desc 	= "参数有误", 
		}
		return res
	end

	local shopTypeList = ShopMgr.GetShopTypeItemList(uid, cmd.data.shopType, cmd.data.discountId)
	res["data"] = {
		ret 		= 0,
		desc 		= "成功",
		shopType    = cmd.data.shopType,
		shopInfo    = shopTypeList,
	}

    --商城首充特惠信息
    --ShopMgr.SendDisCountInfoToMe(uid)
	return res
end

-- 购买商品
Net.CmdBuyGoodsShopCmd_C = function(cmd, laccount)
	local uid = laccount.Id 

	local res = {}
	res["do"] = "Cmd.BuyGoodsShopCmd_S"

	if cmd.data == nil or cmd.data.shopId == nil or cmd.data.shopNbr == nil then
		res["data"] = {
			errno 	= ErrorDefine.ERROR_PARAM,
			desc 	= "参数有误", 
		}
		return res
	end

    if unilight.getdebuglevel() == 0 then
		res["data"] = {
			errno 	= 2,
			desc 	= "非调试模式不能购买", 
		}
        return res
    end

	ShopMgr.BuyGoods(uid, cmd.data.shopId)
end

--请求领取今日奖励 
Net.CmdDailyRewardShopCmd_C = function (cmd, laccount)
	local uid = laccount.Id 

	local res = {}
	res["do"] = "Cmd.DailyRewardShopCmd_S"
	local ret, desc, gold  = ShopMgr.GetDailyRewardGold(uid)
	res["data"] = {
		ret = ret,
		desc = desc,
		gold = gold,
	}
	return res
end


--获得充值记录
Net.CmdGetHistoryShopCmd_C = function (cmd, laccount)
    ShopMgr.CmdGetRechargeHistory(laccount.Id)
end

--获得充值渠道列表
Net.CmdReqRechargePlatShopCmd_C = function (cmd, laccount)
    ShopMgr.CmdGetRechargePlat(laccount.Id)
end


--获得限时特惠信息
Net.CmdDiscountLimitInfoShopCmd_C = function(cmd, laccount)
    -- ShopMgr.SendLimitDiscountInfoToMe(laccount.Id)
end



