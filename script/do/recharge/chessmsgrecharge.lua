-- 用于处理充值类消息

-- 充值信息列表获取
Net.CmdRechargeInfoRequestSdkPmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.RechargeInfoReturnSdkPmd_S"
	local rechargeInfo = {}
	local index = 0
	for id, info in ipairs(TableShopConfig) do
		if info.shopType == 1 then
			index = index + 1
			-- 获取指定商品在道具中 具体值代表多少chips
			local chips = TableGoodsConfig[info.shopGoods.goodId].giftGoods[1].goodNum * info.shopGoods.goodNum
			local rechargeItem = {
				id 			= index,
				rmb 		= info.price,
				chips 		= chips,
			}
			table.insert(rechargeInfo, rechargeItem)
		end
	end
	res.data = {
		resultCode 		= 0,
		desc 			= "成功",
		rechargeInfo 	= rechargeInfo,
	}
	return res
end

-- 请求充值
Net.PmdCreatePlatOrderRequestSdkPmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Pmd.CreatePlatOrderReturnSdkPmd_S"
	if cmd.data == nil or cmd.data.goodid == nil then
		res.data = {
			resultCode = 1,
			desc = "参数缺少"
		}
		return res
	end	
	
	local uid = laccount.Id
	local userInfo = unilight.getdata("userinfo", uid)
	-- 风驰捕鱼接入bug 如果存在userdata.fish ~= nil and userdata.fish.recharge.roomtype ~= nil 则不给领取红包
	if userInfo.fish ~= nil and userInfo.fish.recharge.roomtype ~= nil then
		unilight.error("当前玩家请求官方充值 货币类型不一致 有刷币风险:" .. uid)
		res.data.resultCode = 3
		res.data.desc = "当前货币类型有误"
		return res
	end

	-- 检测当日充值是否超过3000 
	local curTime  = os.time()
	local zeroTime = curTime - curTime%(24*60*60) - 8*60*60  
	local sumRecharge = chessrechargemgr.CmdUserSumRechargeGetByUid(uid, zeroTime, curTime)
	if sumRecharge >= 3000 then
		res.data = {
			resultCode = 2,
			desc = "充值失败 当日充值超过3000元"
		}
		return res		
	end

	local rev = cmd.data
	local uid = laccount.Id
	local bOk, desc = chessrechargemgr.CmdCreatePlatOrderRequest(laccount, rev)
	if bOk == false then
		unilight.error(desc)
	end
end

-- 第三方平台积分信息查询
Net.PmdRequestQueryPlatPointSdkPmd_C = function(cmd, laccount)
	chessrechargemgr.CmdRequestQueryPlatPoint(laccount)
end

-- 从第三方平台兑入
Net.PmdRequestRedeemPlatPointSdkPmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Pmd.ReturnRedeemPlatPointSdkPmd_S"
	if cmd.data == nil or cmd.data.goodid == nil or cmd.data.money == nil or cmd.data.money <= 0 then
		res.data = {
			ret = 1,
			retdesc = "参数缺少"
		}
		return res
	end
	local goodId = tonumber(cmd.data.goodid)
	local money = tonumber(cmd.data.money)
	local rmb = money
	if goodId ~= 1000 then
		local shopId = MapRechargeId2ShopId[goodId]
		rmb = chessrechargemgr.MapShopIdToRmb[shopId]
	end
	local extData = cmd.data.extdata

	-- 这是直接带入带出模式 约定goodid = 1000
	if money ~= rmb and goodId ~= 1000 then
		res.data = {
			ret = 1,
			retdesc = "商品id与金额不符"
		}
		return res
	end
	if goodId == 1000 then
		rmb = money
	end
	chessrechargemgr.CmdRequestRedeemPlatPoint(laccount, goodId, rmb, extData)
end

-- 从本平台兑出至第三方
Net.PmdRequestRedeemBackPlatPointSdkPmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Pmd.ReturnRedeemBackPlatPointSdkPmd_S"
	if cmd.data == nil or cmd.data.point == nil then
		res.data = {
			ret = 1,
			retdesc = "参数缺少"
		}
		return res
	end

	local uid = laccount.Id
	local extData = cmd.data.extdata
	local goodId = 1000 
	local remainder = chessuserinfodb.RUserChipsGet(uid)
	chips = remainder
	local money = chips 
	if chips > remainder or chips < 1 then
		res.data = {
			ret = 3,
			retdesc = "金币不足，不能兑换"
		}
		unilight.info("remainder " .. remainder .. "    exchangepoint  " .. chips)
		return res
	end
	chessrechargemgr.CmdRequestRedeemBackPlatPoin(laccount, chips, money, extData)
end

-- 苹果充值成功查询
Net.PmdRechargeQueryRequestIOSSdkPmd_C = function(cmd, laccount)
	local platData = {
		myaccid = laccount.Id,
		platid = laccount.JsMessage.GetPlatid(),
		session = laccount.JsMessage.GetSession(),
	}
	cmd.data.data = platData 
	cmd.data.roleid = laccount.Id
    local resStr = json.encode(encode_repair(cmd.data))
    local bok = go.buildProtoFwdServer("*Pmd.RechargeQueryRequestIOSSdkPmd_C", resStr, "LS")
    if bok == true then
        unilight.info("苹果支付查询转发sdkserver".. resStr)
    else
        unilight.error("苹果支付查询转发失败sdkserver".. resStr)
    end
end
