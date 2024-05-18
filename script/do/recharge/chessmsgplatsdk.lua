-- 用来处理平台sdk
LoginClientTask = LoginClientTask or {}
-- 请求平台帐号中剩余点数返回
LoginClientTask.ReturnQueryPlatPointSdkPmd_S = function(task, cmd)
	local uid = cmd.GetData().GetMyaccid()
	local platId = cmd.GetData().GetPlatid()
	local balancePoint = cmd.GetBalance()
	local gameOrder = cmd.GetGameorder()
	local ret = cmd.GetRet()
	local retDesc = cmd.GetRetdesc()
	if ret ~= 0 then
		unilight.error("ReturnQueryPlatPointSdkPmd_S return error res:  " .. retDesc)
	end	
	-- 返回
	local accountTcp = go.roomusermgr.GetRoomUserById(uid)
    accountTcp = accountTcp or go.accountmgr.GetAccountById(uid)
	if accountTcp == nil then
		unilight.error("laccount is null  积分查询uid: " .. uid)
		return 
	end
	local remainder = chessuserinfodb.RUserChipsGet(uid)  
	res = {}
	res["do"] = "Pmd.ReturnQueryPlatPointSdkPmd_S"
	res.data = {
		data = {myaccid = uid},
		balance = balancePoint,
		gameorder = gameOrder,
		ret = ret,
		retdesc = retDesc, 
		money = remainder,
	}
    unilight.info("return qurery platpoint " .. table.tostring(res))
	unilight.success(accountTcp, res)	
end

-- 兑换积分返回
LoginClientTask.ReturnRedeemPlatPointSdkPmd_S = function(task, cmd)
	local uid = cmd.GetData().GetMyaccid()
	local platId = cmd.GetData().GetPlatid()
	local gameOrder = cmd.GetGameorder()
	local goodId = cmd.GetGoodid()
	local balancePoint = cmd.GetBalance()
	local money = cmd.GetMoney()
	local ret = cmd.GetRet()
	local retDesc = cmd.GetRetdesc()
	local rmb = money 
	local bOk = false
	local res = ""
	local remainderChips = 0
	local rechargeChips = 0
	if ret ~= 0 then
		unilight.debug("ReturnRedeemPlatPointSdkPmd_S return error")
		unilight.debug("ret  " ..ret.."   desc:  ".. retDesc)
	else	
		bOk, res, remainderChips, rechargeChips = RechargeReturnOk(uid, rmb, platId, gameOrder, gameOrder, goodId, 1)
		if bOk == false then
			unilight.error(res)
		end
	end
	local accountTcp = go.roomusermgr.GetRoomUserById(uid)
    accountTcp = accountTcp or go.accountmgr.GetAccountById(uid)
	if accountTcp == nil then
		unilight.error("accountTcp is null ReturnRedeemPlatPoingSdkPmd_s" .. uid)
		return
	end
	res = {}
	res["do"] = "Pmd.ReturnRedeemPlatPointSdkPmd_S"
	res.data = {
		data = {myaccid = uid},
		gameorder = gameOrder,
		goodid = goodId,
		money = remainderChips,
		balance = balancePoint,
		ret = ret,
		retdesc = retDesc,
	}
	unilight.success(accountTcp, res)
end

-- 金币兑出返回
LoginClientTask.ReturnRedeemBackPlatPointSdkPmd_S = function(task, cmd)
	local uid = cmd.GetData().GetMyaccid()
	local platId = cmd.GetData().GetPlatid()
	local gameOrder = cmd.GetGameorder()
	local platOrder = gameOrder
	local balancePoint = cmd.GetBalance()
	local money = cmd.GetMoney()
	local ret = cmd.GetRet()
	local retDesc = cmd.GetRetdesc()
	local rmb = money
	local reduceChips = 0
	local remainder = 0
	local bOk = false
	local res = ""
	if ret ~= 0 then
		unilight.debug("ReturnRedeemBackPlatPointSdkPmd_S return error")
		unilight.debug("ret  " ..ret.."   desc:  ".. retDesc)
	else
		bOk, res, remainder, reduceChips = RedeemBackOk(uid, rmb, platId, gameOrder, platOrder, balancePoint)
		if bOk == false then
			unilight.error(res)
			return
		end
	end
		--返回吧 
		local accountTcp = go.roomusermgr.GetRoomUserById(uid)
		if accountTcp == nil then
			unilight.error("laccount is null 但已兑换出去rmb:" .. rmb .. "  uid: " .. uid)
			return 
		end
		local remainderChips = tostring(remainderChips)
		res = {}
		res["do"] = "Pmd.ReturnRedeemBackPlatPointSdkPmd_S"
		res.data = {
			gameorder = gameOrder,
			balance = balancePoint,
			money = remainder, 
			ret = ret,
			retdesc = retDesc,
		}

		unilight.success(accountTcp, res)
end

-- 创建订单号返回
LoginClientTask.CreatePlatOrderReturnSdkPmd_S = function(task, cmd)
	local uid = cmd.GetData().GetMyaccid()
	local platId = cmd.GetData().GetPlatid()
	local gameOrder = cmd.GetGameorder()
	local roleId = cmd.GetRoleid()
	local originalMoney = cmd.GetOriginalmoney()
	local orderMoney = cmd.GetOrdermoney()
	local goodId = chessrechargemgr.MapPayIdToShopId[cmd.GetGoodid()] or cmd.GetGoodid() -- 先看下是否对应着rmb道具id
	local goodNum = cmd.GetGoodnum()
	local result = cmd.GetResult()
	local noticeUrl = cmd.GetNoticeurl()
	local platOrder = cmd.GetPlatorder()
	local sign = cmd.GetData().GetExtdata()
	local redirectUrl = cmd.GetRedirecturl()
	local payPlatId = cmd.GetPayplatid()
	local appGoodId= cmd.GetAppgoodid()
	local extData = cmd.GetExtdata()
	local rmb = orderMoney
	if result ~= 0 then
		unilight.error("from sdk: CreatePlatOrderReturnSdkPmd_S,获取URL失败 订单号为：" .. gameOrder)
	else	
		UserRechargeCreateOrderLog(gameOrder, platOrder, uid, payPlatId, rmb, "通过支付平台")
	end
	local accountTcp = go.roomusermgr.GetRoomUserById(uid)
	if accountTcp == nil then
		unilight.error("accoutTcp is nil createplatorderReturn uid :" .. uid)
		return 
	end
	res = {}
	res["do"] = "Pmd.CreatePlatOrderReturnSdkPmd_S"
	res.data = {
			data = {myaccid = uid},
			gameorder	  = gameOrder,
			roleid		  = roleId,
			originalmoney = originalMoney,
			ordermoney	  = orderMoney,
			goodid		  = goodId,
			goodnum		  = goodNum,
			result		  = result,
			noticeurl	  = noticeUrl,
			platorder	  = platOrder,
			sign          = sign,
			redirecturl   = redirectUrl,
			payplatid     = payPlatId,
			appgoodid       = appGoodId,
			extdata       = extData,
	}
	unilight.success(accountTcp, res)
end

-- 代理通知游戏服有玩家充值
LoginClientTask.NotifyRechargeRequestSdkPmd_S = function(task, cmd)
	local uid = cmd.GetData().GetMyaccid()
	local gameOrder = cmd.GetGameorder()
	local platOrder = cmd.GetPlatorder()
	local roleId = cmd.GetRoleid()
	local platId = cmd.GetData().GetPlatid()
	local rmb = cmd.GetOrdermoney()
	local originalmoney = cmd.GetOriginalmoney()
	local goodId = chessrechargemgr.MapPayIdToShopId[cmd.GetGoodid()] or cmd.GetGoodid()
	local goodNum = cmd.GetGoodnum()
	local extData = cmd.GetExtdata()
	local typ = cmd.GetType()
	local result = cmd.GetResult()
	local bOk = false
	local res = ""
	local remainderChips = 0
	local rechargeChips = 0
	if result ~= 0 then -- 失败
		unilight.error("支付失败: 订单号：" .. gameOrder .. "  支付金额： " .. rmb)
	else
		-- 美元接泰国(rmb是1美分) 默认9006里面只有美分
		local gameId = go.gamezone.Gameid
		if gameId == 9006 then
			bOk, res, remainderChips, rechargeChips = DollarRechargeReturnOk(uid, rmb, platId, gameOrder, platOrder)
		else
			bOk, res, remainderChips, rechargeChips = RechargeReturnOk(uid, rmb, platId, gameOrder, platOrder, goodId, goodNum)
		end
		if bOk == false then
			unilight.error(res)
		end
	end

	-- 成功才回复
	if bOk then
		--返回吧 
		local accountTcp = go.roomusermgr.GetRoomUserById(uid)
		if accountTcp == nil then
			unilight.error("laccount is null 但已充值到位rmb:" .. rmb .. "  uid: " .. uid)
			return 
		end
		local remainderChips = tostring(remainderChips)
		res = {}
		res["do"] = "Pmd.NotifyRechargeRequestSdkPmd_S"
		res.data = {
			platorder = platOrder,
			gameorder = gameOrder,
			roleid = roleId,
			originalmoney = originalMoney,
			ordermoney = rmb,
			goodid = goodId,
			goodnum = goodNum,
			result = result,
			extdata = remainderChips,
		}
		unilight.success(accountTcp, res)
	end
end

-- 查询角色列表
LoginClientTask.SearchUserListSdkPmd_CS = function(task, cmd)
	res = cmd
	local plataccount = cmd.GetData().GetPlataccount()
	if plataccount ~= nil then
		local userDatas = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Filter(unilight.eq("base.plataccount", plataccount)))
		if userDatas ~= nil and table.len(userDatas) ~= 0 then
			local userInfo = {
				roleid = userDatas[1].uid,
				rolename = userDatas[1].base.nickname,
			}
			res.data.users = {userInfo}	
		end
	end

    local resStr = json.encode(encode_repair(res.data))
    local bok = go.buildProtoFwdServer("*Pmd.SearchUserListSdkPmd_CS", resStr, "LS")
    if bok == true then
        unilight.info("查询角色列表返回sdkserver".. resStr)
    else
        unilight.error("查询角色列表返回失败sdkserver".. resStr)
    end
end

function DollarRechargeReturnOk(uid, rmb, platId, gameOrder, platOrder)
	local tableDollarInfo = TableDollarExchange[rmb] -- 对应表格数据
	if tableDollarInfo == nil then
		res = "美元充值 不存在该表格数据: cent: " .. rmb
		return false, res
	else
		local dollar 		= tableDollarInfo.dollar
		local rechargeChips = tableDollarInfo.chips

		local marks = "成功：玩家:".. uid .."platId为= " .. platId .. "充值：" .. rechargeChips .. "dollar: " .. dollar
		unilight.info(marks)
		local remainderChips = chessuserinfodb.WChipsRecharge(uid, rechargeChips)	
		-- 更新订单信息
		UserRechargeOkLog(gameOrder, platOrder, uid, rmb,  "到帐成功")
		return true, "", remainderChips, rechargeChips					
	end	
end

function RechargeReturnOk(uid, rmb, platId, gameOrder, platOrder, goodId, goodNum)
	local rmbYuan = rmb/100

	-- goodId 1-100 为金币充值  101开始为rmb购买道具 1000为第三方金币1：1互相兑换
	if goodId <= 100 then
		local id = chessrechargemgr.MapRmb2RechargeId[rmb]
		if id == nil then
			local res = "收到充值结果，但是rmb找不到对应的goodid" .. uid .."   rmb:" ..rmbYuan 
			return false, res
		end
		local rechargeChips = UserReChargeChipsGetByUid(uid, id)
		local marks = "成功：玩家:".. uid .."platId为= " .. platId .. "充值：" .. rechargeChips .. "rmb: " .. rmbYuan 
		unilight.info(marks)
		local remainderChips = chessuserinfodb.WChipsRecharge(uid, rechargeChips)	
		-- 更新订单信息
		UserRechargeOkLog(gameOrder, platOrder, uid, rmb,  "到帐成功")
		return true, "", remainderChips, rechargeChips		
	elseif goodId == 1000 then
		local rechargeChips = rmb 
		local marks = "成功：玩家:".. uid .."platId为= " .. platId .. "带入：" .. rechargeChips
		unilight.info(marks)
		local remainderChips = chessuserinfodb.WChipsRecharge(uid, rechargeChips)	
		-- 更新订单信息
		UserRechargeOkLog(gameOrder, platOrder, uid, rmb,  "带入金币成功")
		return true, "", remainderChips, rechargeChips		
		
	else
		-- 从表格中 获取该商品的具体信息
		local tableShop = TableShopConfig[goodId - 100] 
		if tableShop.priceType ~= 1 then
			local res = "收到充值结果，但是该道具不是rmb道具   道具goodId为： " .. goodId 
			return false, res
		end
		if tableShop.price * goodNum ~= rmb then
			local res = "收到充值结果，但是购买道具需求金额:" .. tableShop.price * goodNum .. " 跟 充值金额:" .. rmb .. "不匹配"
			return false, res
		end

		-- 物品获取
		local summary = {}
		summary = BackpackMgr.GetRewardGood(uid, tableShop.shopGoods.goodId, tableShop.shopGoods.goodNum * goodNum, Const.GOODS_SOURCE_TYPE.SHOP, summary)

		-- 获取物品 汇总整理返回
		local shopItem = {}
		for k,v in pairs(summary) do
			local item = {
				goodId 	= k,
				goodNum = v, 
			}
			table.insert(shopItem, item)
		end	

		local remainder = chessuserinfodb.RUserChipsGet(uid)

		-- 购买成功 先通知前端获取到了那些道具
		local accountTcp = go.roomusermgr.GetRoomUserById(uid)
		if accountTcp == nil then
			unilight.error("laccount is null 但已充值到位rmb:" .. rmb .. "  uid: " .. uid)
			return 
		end
		res = {}
		res["do"] = "Cmd.BuyGoodsShopCmd_S"
		res["data"] = {
			ret 		= 0,
			desc 		= "通过rmb购买商品成功",
			remainder	= remainder,
			shopItem	= shopItem, 
		}	
		unilight.success(accountTcp, res)
		-- 更新订单信息
		UserRechargeOkLog(gameOrder, platOrder, uid, rmb,  "rmb购买商品成功")
		return true, "", remainder, 0
	end
end

function RedeemBackOk(uid, rmb, platId, gameOrder, platOrder)
	local rechargeChips = 0
	if platId == 365 then
		rechargeChips = rmb
	else	
		local rmbYuan = rmb/100
		local id = chessrechargemgr.MapRmb2RechargeId[rmb]
		if id == nil then
			local res = "收到充值结果，但是rmb找不到对应的goodid" .. uid .."   rmb:" ..rmbYuan 
			return false, res
		end
		rechargeChips = UserReChargeChipsGetByUid(uid, id)
	end
	local marks = "积分兑换出去成功：玩家:".. uid .."platId为= " .. platId .. "兑换出去：" .. rechargeChips
	unilight.info(marks)
	local remainderChips = chessuserinfodb.WChipsRedeemBack(uid, rechargeChips)	
	-- 更新订单信息
	UserRechargeOkLog(gameOrder, platOrder, uid, rmb,  "兑换出去成功")
	return true, "", remainderChips, rechargeChips
end


function UserRechargeCreateOrderLog(gameOrder, platOrder, uid, payPlatId, rmb, marks)
	local rmbYuan = rmb/100
	local platInfo = chessuserinfodb.RUserPlatInfoGet(uid) 
	if platInfo == nil then
		unilight.error("UserRechargeCreateOrderLog玩家不存在" .. uid)
		return false
	end
	local userInfo = chessuserinfodb.RUserInfoGet(uid)

	local log = {
		gameorder = gameOrder,
		platorder = platOrder,
		uid = uid,
		nickname = userInfo.base.nickname,
		platid = platInfo.platId,
		plataccount = platInfo.platAccount,
		subplatid = platInfo.subPlatId,
		payplatid = payPlatId,
		rmb = rmbYuan,
		bok = 1,
		marks = marks,
		-- createtime = chessutil.FormatDate2Get(),
		createtime = os.time(),
	}
	unilight.savedata("gameorder", log)
	unilight.info("玩家创建订单成功：" .. uid .. "   gameorder " .. gameOrder .. "  rmb:" .. rmbYuan)
end

function UserRechargeOkLog(gameOrder, platOrder, uid, rmb, flag)
	local rmbYuan = rmb/100
	local log = unilight.getdata("gameorder", gameOrder) 
	if table.empty(log)then
		local filter = unilight.eq("platorder", platOrder)
		log = unilight.getByFilter("gameorder", filter, 1)	
	end
	if table.empty(log)then
		unilight.error("遇见了未创建订单，但是支付成功的实例" .. gameOrder .. "UID" .. uid .. "  rmb:" .. rmb)
		return false 
    end
	
	local userInfo = chessuserinfodb.RUserInfoGet(uid)

	log.bok = 2
	log.flag = flag 
	-- log.rechargetime = chessutil.FormatDate2Get()
	log.rechargetime = os.time()
	log.remainder = userInfo.property.chips
	log.timestamp = os.time()
	log.rmb = rmbYuan -- 订单中最终充值金额以这个为准  如果为接入泰国的 此时实际为美金
	unilight.savedata("gameorder", log)
	unilight.info("充值成功：" .. uid .. "   gameorder " .. gameOrder .. "  rmb:" .. rmbYuan)
end

-- 获取玩家此次充值获取的金币
function UserReChargeChipsGetByUid(uid, goodId)
	--  用来判断首次充值送礼(首充功能中途加入 所以老用户 从功能加入后 第一次充值也给予首充奖励)
	local userInfo = chessuserinfodb.RUserInfoGet(uid)

	-- goodId 为1--9 应该映射回 shopId
	local shopId 	= chessrechargemgr.MapRechargeId2ShopId[goodId]
	local shopInfo 	= TableShopConfig[shopId - 100]
	local chips 	= TableGoodsConfig[shopInfo.shopGoods.goodId].giftGoods[1].goodNum * shopInfo.shopGoods.goodNum
	
	-- 首充
	if userInfo.recharge.first == nil or userInfo.recharge.firstTime == nil then
		if shopInfo.firstShopGoods.goodId ~= 0 then
			-- 暂时不知道 策划表格如何配置 略过
			-- chips = TableGoodsConfig[shopInfo.firstShopGoods.goodId].giftGoods[1].goodNum * shopInfo.firstShopGoods.goodNum
		end
		userInfo.recharge.first = shopInfo.price				-- 记录首充的金额	首充礼包用	
		userInfo.recharge.firstTime = os.time()					-- 记录首充的时间	运营转盘用
		unilight.savedata("userinfo", userInfo)

		-- 完成首充加10积分
		LuckyTurnTableMgr.GetIntegral(uid, 20)
	end
	return chips
end
